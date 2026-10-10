#!/usr/bin/env python3
"""Run the simpyhls reference kernels on golden canvases (GM-7 differential test).

Reads JSON from stdin:

    {"cases": [{"width": W, "height": H,
                "cells": [16-bit cell words, row-major],
                "ports": [4-bit port masks, row-major; bit 3 down, 2 right, 1 up, 0 left],
                "components": [{"type": sprite, "x": col, "y": row, "rotation": r}, ...]}]}

and writes {"results": [{"regions": [...], "node0": [...], "node1": [...]}]}.

For each case it executes simpyhls/examples/flooding_core.dsl.py to obtain the
raw region grid, then extract_component_nodes.dsl.py over that grid, the cell
words and the components (in the given order, which is the element idx order).

Primitive models follow the kernels' own reference harnesses:
- flooding: notebooks/flooding.ipynb (port index 0 down, 1 right, 2 up, 3 left);
- extraction: simpyhls/tests/test_extract_component_nodes.py, which uses the
  hardware directions of ExtractComponentNodesCombPkg.sv (0 down, 1 right,
  2 up, 3 left; rotation_to_dir_comb maps rotation codes onto them) and the
  fetchP port table for cell_has_port_comb.
Coordinates outside the grid read as region 0 / visited. Since the D-021 kernel
fix, extract_component_nodes checks `>= 0` as well, so it never reads outside
the grid; flooding still relies on this.

By default the kernels are run through simpyhls's own DSL interpreter
(compiler.sim_runtime.run_python), which also checks that the source is valid
DSL. --exec runs the same source with plain Python exec (much faster).

simpyhls is found via --simpyhls, $SIMPYHLS_DIR, <repo>/simpyhls, or the
nearest ancestor directory containing simpyhls/examples (for git worktrees whose
submodule is not initialised). Its DSL interpreter is always used from there.

--kernels DIR reads the two kernel sources from DIR instead of
<simpyhls>/examples. --as-written selects the frozen pre-decision kernels in
golden/test/fixtures/kernels-as-written (simpyhls 57ffb08, before D-015, D-019
and D-021) together with the primitive models of their own harness at that
revision (extraction directions are the rotation codes 0 +x, 1 +y, 2 -x, 3 -y,
and get_cell_rotation_comb reads a cell's rotation).
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
AS_WRITTEN_KERNELS = REPO / "golden" / "test" / "fixtures" / "kernels-as-written"
GROUND_SPRITE = 15
TWO_TERMINAL = range(5, 15)


def find_simpyhls(explicit: str | None) -> Path:
    candidates = []
    if explicit:
        candidates.append(Path(explicit))
    if os.environ.get("SIMPYHLS_DIR"):
        candidates.append(Path(os.environ["SIMPYHLS_DIR"]))
    candidates += [p / "simpyhls" for p in (REPO, *REPO.parents)]
    for c in candidates:
        if (c / "examples" / "flooding_core.dsl.py").is_file():
            return c.resolve()
    raise SystemExit("simpyhls not found (use --simpyhls or SIMPYHLS_DIR)")


# ---------------------------------------------------------------- primitives
# Every primitive takes the simulation context `tb` first; tb.state holds the case.

def _in(tb, i, j):
    return 0 <= i < tb.state["w"] and 0 <= j < tb.state["h"]


FLOOD_STEP = ((0, 1), (1, 0), (0, -1), (-1, 0))  # notebook dir_nxt: down, right, up, left


def flood_primitives():
    def fetchP(tb, i, j):
        return tb.state["ports"][j * tb.state["w"] + i] if _in(tb, i, j) else 0

    def getVisited(tb, i, j):
        return tb.state["visited"][j * tb.state["w"] + i] if _in(tb, i, j) else True

    def setVisited(tb, i, j):
        tb.state["visited"][j * tb.state["w"] + i] = True

    def storeR(tb, i, j, v):
        tb.state["regions"][j * tb.state["w"] + i] = v

    def addQueue(tb, i, j, d):
        tb.state["queue"].insert(0, (i, j, d))

    def popQueue(tb):
        return tb.state["queue"].pop()

    def getQueueLen(tb):
        return len(tb.state["queue"])

    def getport_comb(tb, p, i):
        return (p >> (3 - i)) & 1  # bit 3 = port index 0 (down)

    def decode_iswire_comb(tb, p):
        return p != 0

    def decode_i_comb(tb, q_item):
        return q_item[0]

    def decode_j_comb(tb, q_item):
        return q_item[1]

    def decode_d_comb(tb, q_item):
        return q_item[2]

    def get_nxt_i_comb(tb, i, d):
        return i + FLOOD_STEP[d][0]

    def get_nxt_j_comb(tb, j, d):
        return j + FLOOD_STEP[d][1]

    def get_opp_dir_comb(tb, d):
        return (2, 3, 0, 1)[d]

    return {f.__name__: f for f in (
        fetchP, getVisited, setVisited, storeR, addQueue, popQueue, getQueueLen, getport_comb,
        decode_iswire_comb, decode_i_comb, decode_j_comb, decode_d_comb, get_nxt_i_comb,
        get_nxt_j_comb, get_opp_dir_comb)}


EXTRACT_STEP = ((0, 1), (1, 0), (0, -1), (-1, 0))  # hardware directions: down, right, up, left
ROTATION_TO_DIR = (1, 0, 3, 2)  # rotation 0 (+x) -> right, 1 (+y) -> down, 2 -> left, 3 -> up
# Port masks at rotation 0, bit 3 down, 2 right, 1 up, 0 left (BackendFetchers.v decode_p_from_cell).
BASE_PORTS = {0: 0b0101, 1: 0b0110, 2: 0b0111, 3: 0b1111, 4: 0b1111, GROUND_SPRITE: 0b0001}
CURRENT_SOURCE = (9, 10)


def extract_primitives():
    def comp(tb, idx):
        return tb.state["components"][idx]

    def fetchComponentType(tb, idx):
        return comp(tb, idx)["type"]

    def fetchAnchorPositionX(tb, idx):
        return comp(tb, idx)["x"]

    def fetchAnchorPositionY(tb, idx):
        return comp(tb, idx)["y"]

    def fetchComponentRotation(tb, idx):
        return comp(tb, idx)["rotation"]

    def fetchR(tb, i, j):
        return tb.state["regions"][j * tb.state["w"] + i] if _in(tb, i, j) else 0

    def fetchCell(tb, i, j):
        return tb.state["cells"][j * tb.state["w"] + i] if _in(tb, i, j) else 0

    def storeNode0(tb, idx, node_i):
        tb.state["node0"][idx] = node_i

    def storeNode1(tb, idx, node_i):
        tb.state["node1"][idx] = node_i

    def is_two_terminal_component_comb(tb, t):
        return int(t in TWO_TERMINAL)

    def is_ground_cell_comb(tb, cell):
        return int((cell & 1) == 1 and ((cell >> 1) & 0x3F) == GROUND_SPRITE)

    def is_current_source_comb(tb, t):
        return int(t in CURRENT_SOURCE)

    def rotation_to_dir_comb(tb, rot):
        return ROTATION_TO_DIR[rot]

    def cell_has_port_comb(tb, cell, d):
        if not cell & 1:
            return 0
        base, rot = BASE_PORTS.get((cell >> 1) & 0x3F, 0), (cell >> 7) & 3
        mask = ((base << rot) | (base >> (4 - rot))) & 15
        return (mask >> (3 - d)) & 1

    def get_opp_dir_comb(tb, d):
        return (2, 3, 0, 1)[d]

    def get_nxt_i_comb(tb, i, d):
        return i + EXTRACT_STEP[d][0]

    def get_nxt_j_comb(tb, j, d):
        return j + EXTRACT_STEP[d][1]

    return {f.__name__: f for f in (
        fetchComponentType, fetchAnchorPositionX, fetchAnchorPositionY, fetchComponentRotation, fetchR,
        fetchCell, storeNode0, storeNode1, is_two_terminal_component_comb, is_ground_cell_comb,
        is_current_source_comb, rotation_to_dir_comb, cell_has_port_comb, get_opp_dir_comb,
        get_nxt_i_comb, get_nxt_j_comb)}


AS_WRITTEN_STEP = ((1, 0), (0, 1), (-1, 0), (0, -1))  # rotation codes: +x, +y, -x, -y


def extract_primitives_as_written():
    """Primitive models of the frozen kernel (simpyhls 57ffb08's extraction harness)."""
    current = extract_primitives()
    keep = ("fetchComponentType", "fetchAnchorPositionX", "fetchAnchorPositionY", "fetchComponentRotation",
            "fetchR", "fetchCell", "storeNode0", "storeNode1", "is_two_terminal_component_comb",
            "is_ground_cell_comb", "get_opp_dir_comb")
    prims = {name: current[name] for name in keep}

    def get_cell_rotation_comb(tb, cell):
        return (cell >> 7) & 3

    def get_nxt_i_comb(tb, i, d):
        return i + AS_WRITTEN_STEP[d][0]

    def get_nxt_j_comb(tb, j, d):
        return j + AS_WRITTEN_STEP[d][1]

    prims.update({f.__name__: f for f in (get_cell_rotation_comb, get_nxt_i_comb, get_nxt_j_comb)})
    return prims


# ---------------------------------------------------------------- runners

class _Ctx:
    def __init__(self, state):
        self.state = state


def run_exec(source: str, fn_name: str, primitives, params: dict, state: dict) -> dict:
    ctx = _Ctx(state)
    env = {name: (lambda f: (lambda **ports: f(ctx, **ports)))(f) for name, f in primitives.items()}
    exec(compile(source, fn_name, "exec"), env)
    env[fn_name](**params)
    return ctx.state


def run_dsl(source: str, fn_name: str, primitives, params: dict, state: dict) -> dict:
    from compiler.sim_runtime import PrimitiveModel, SimulationHarness, run_python

    harness = SimulationHarness(
        params=params,
        primitives={n: PrimitiveModel(n, f) for n, f in primitives.items()},
        initial_state=state,
    )
    return run_python(source, harness).final_state


def run_case(case: dict, sources: dict, runner, extract_prims) -> dict:
    w, h = case["width"], case["height"]
    flood = runner(sources["flooding_core"], "flooding_core", flood_primitives(),
                   {"grid_height": h, "grid_width": w},
                   {"w": w, "h": h, "ports": list(case["ports"]), "visited": [False] * (w * h),
                    "regions": [0] * (w * h), "queue": []})
    n = len(case["components"])
    extract = runner(sources["extract_component_nodes"], "extract_component_nodes", extract_prims,
                     {"par_elem_n": n, "grid_height": h, "grid_width": w},
                     {"w": w, "h": h, "regions": flood["regions"], "cells": list(case["cells"]),
                      "components": case["components"], "node0": [-1] * n, "node1": [-1] * n})
    return {"regions": flood["regions"], "node0": extract["node0"], "node1": extract["node1"]}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--simpyhls", help="simpyhls checkout")
    ap.add_argument("--exec", action="store_true", help="plain exec instead of the simpyhls DSL interpreter")
    ap.add_argument("--kernels", help="directory with the kernel sources (default <simpyhls>/examples)")
    ap.add_argument("--as-written", action="store_true",
                    help="frozen pre-decision kernels and their primitive models (default --kernels: kernels-as-written)")
    args = ap.parse_args()
    root = find_simpyhls(args.simpyhls)
    sys.path.insert(0, str(root))
    default_kernels = AS_WRITTEN_KERNELS if args.as_written else root / "examples"
    kernels = Path(args.kernels).resolve() if args.kernels else default_kernels
    sources = {name: (kernels / f"{name}.dsl.py").read_text()
               for name in ("flooding_core", "extract_component_nodes")}
    runner = run_exec if args.exec else run_dsl
    prims = extract_primitives_as_written() if args.as_written else extract_primitives()
    cases = json.load(sys.stdin)["cases"]
    json.dump({"simpyhls": str(root), "kernels": str(kernels),
               "results": [run_case(c, sources, runner, prims) for c in cases]}, sys.stdout)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
