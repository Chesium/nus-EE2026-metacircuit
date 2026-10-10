#!/usr/bin/env python3
"""Differential fixtures for the golden DC solver (GM-7, M3).

For every netlist (hand-written edge cases plus seeded random circuits) this
records what the reference implementations compute, so the golden TypeScript
solver can be compared bit for bit without Python at test time:

  uart        src/uart_link/frontend_tester.py, the D-012 simulated solver: the
              netlist is UART-encoded, fed line by line to FrontendTester, and
              the reply lines (VB/VN/VE or ER) are recorded.
  dsl         simpyhls/examples/solve_core_dc.dsl.py executed as plain Python
              (simpyhls run_python), values decoded with the wire unit
              table (same as frontend_tester), in three primitive flavours:
                py           frontend_tester's own primitives (Python floats)
                f32          float32 primitives, correctly rounded fused fma
                f32-unfused  float32 primitives, fma rounded twice
              Recorded for R/I/V-only netlists.
  transient   solve_core_transient.dsl.py with par_dt = inf, par_time = 0 (the
              DC limit of its C/L companion models), py flavour. Recorded for
              netlists containing C or L.

Two kernel sets, two fixture files (both written by default; `npm run
fixtures:solver` in golden/, `npm run fixtures:solver -- --check` to verify):

  live        the simpyhls checkout's solve_core_dc.dsl.py (also run by
              frontend_tester) -> golden/test/fixtures/solver_dc.json. Re-run
              this after kernel changes such as the D-020 pivot fix.
  as-written  the kernel as written before D-020, frozen in
              golden/test/fixtures/kernels-as-written/solve_core_dc.dsl.py
              (simpyhls 57ffb08) -> golden/test/fixtures/solver_dc_as_written.json.
              frontend_tester runs this frozen kernel too, so the golden's
              { pivot: 'dsl' } mode stays checked after the fix lands.
  The transient kernel (C/L DC limit) comes from the checkout and is recorded
  in the live fixture only.

Usage (from the repo root or golden/):
  python3 golden/tools/gen_solver_fixtures.py [--simpyhls DIR] [--kernels live|as-written|both]
  python3 golden/tools/gen_solver_fixtures.py --check

--simpyhls defaults to $SIMPYHLS_DIR, else the simpyhls submodule, else the
nearest ancestor checkout with a populated one (git worktrees). Runs on Python
3.12+ (simpyhls declares 3.14 but uses nothing newer); stdlib only.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import ctypes
import json
import math
import random
import struct
import sys
from fractions import Fraction
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
FIXTURES = REPO / "golden" / "test" / "fixtures"
OUT = {"live": FIXTURES / "solver_dc.json", "as-written": FIXTURES / "solver_dc_as_written.json"}
AS_WRITTEN_KERNELS = FIXTURES / "kernels-as-written"
GND = 0xFF
SEED = 20261010
RANDOM_CASES = 300

# NetlistElement.unit is the wire code (uart_link "solver-board mapping").
WIRE_UNIT_SCALE = {0: 1.0, 1: 1e-3, 2: 1e-6, 3: 1e-9, 4: 1e3, 5: 1e6, 6: 1e9}
KIND_NAME = {1: "R", 2: "I", 3: "V", 4: "C", 5: "L"}


# --------------------------------------------------------------------------- float32 helpers


def f32(x: float) -> float:
    """Round a float64 to float32 (C cast: nearest-even, overflow to inf)."""
    return ctypes.c_float(float(x)).value


def bits32(x: float) -> int:
    return struct.unpack(">I", struct.pack(">f", f32(x)))[0]


def from_bits32(b: int) -> float:
    return struct.unpack(">f", struct.pack(">I", b & 0xFFFFFFFF))[0]


def hex32(x: float) -> str:
    return f"{bits32(x):08X}"


def hex64(x: float) -> str:
    return f"{struct.unpack('>Q', struct.pack('>d', float(x)))[0]:016X}"


def _neighbours32(y: float) -> list[float]:
    b = bits32(y)
    out = [y]
    for nb in ((b + 1) & 0xFFFFFFFF, (b - 1) & 0xFFFFFFFF):
        v = from_bits32(nb)
        if math.isfinite(v):
            out.append(v)
    return out


def round_fraction_f32(q: Fraction) -> float:
    """Correctly rounded (nearest, ties to even) float32 of an exact rational."""
    y = f32(float(q))
    if not math.isfinite(y):
        return y
    best = None
    for c in _neighbours32(y):
        d = abs(Fraction(c) - q)
        key = (d, bits32(c) & 1)
        if best is None or key < best[0]:
            best = (key, c)
    return best[1]


def fma32_fused(a: float, b: float, c: float) -> float:
    a, b, c = float(a), float(b), float(c)
    if not (math.isfinite(a) and math.isfinite(b) and math.isfinite(c)):
        return f32(a * b + c)
    q = Fraction(a) * Fraction(b) + Fraction(c)
    if q == 0:
        product_is_neg_zero = (a == 0 or b == 0) and (math.copysign(1, a) * math.copysign(1, b) < 0)
        if (a == 0 or b == 0) and c == 0 and product_is_neg_zero and math.copysign(1, c) < 0:
            return -0.0
        return 0.0
    return round_fraction_f32(q)


def ieee_div(a: float, b: float) -> float:
    a, b = float(a), float(b)
    if b == 0:
        if a == 0 or math.isnan(a):
            return math.nan
        return math.copysign(math.inf, a) * math.copysign(1.0, b)
    return a / b


# --------------------------------------------------------------------------- reference loading


class Refs:
    def __init__(self, simpyhls: Path, kernel_dir: Path) -> None:
        if not (simpyhls / "examples" / "solve_core_dc.dsl.py").is_file():
            raise SystemExit(f"simpyhls checkout not found at {simpyhls} (use --simpyhls)")
        sys.path.insert(0, str(simpyhls))
        sys.path.insert(0, str(REPO))
        from compiler.ast_to_hir import lower_source  # type: ignore
        from compiler.hir_to_lir import lower_func  # type: ignore
        from compiler.sim_runtime import PrimitiveModel, SimulationHarness, run_python  # type: ignore
        import src.uart_link.frontend_tester as ft  # type: ignore
        import src.uart_link.protocol as proto  # type: ignore
        import src.uart_link.solver_tester as st  # type: ignore

        ft.SIMPYHLS_ROOT = simpyhls  # frontend_tester reads the kernel from here
        self.PrimitiveModel = PrimitiveModel
        self.SimulationHarness = SimulationHarness
        self.run_python = run_python
        self.ft = ft
        self.proto = proto
        self.st = st
        self.solve_core_dc = (kernel_dir / "solve_core_dc.dsl.py").read_text()
        self.solve_core_transient = (simpyhls / "examples" / "solve_core_transient.dsl.py").read_text()
        # frontend_tester's simulated solver runs the same solve_core_dc source.
        lowered = lower_func(lower_source(self.solve_core_dc))
        ft._lowered_solve_core_dc = lambda: lowered
        self.solve_core_dc_sha256 = hashlib.sha256(self.solve_core_dc.encode()).hexdigest()

    # ------------------------------------------------------------ simulated solver

    def uart(self, nl: dict) -> dict:
        proto = self.proto
        frame = nl["frame"]
        comps = tuple(
            proto.NetlistComponent(frame, e["idx"], e["kind"], e["n0"], e["n1"], e["valueBcd"], e["unit"])
            for e in nl["elements"]
        )
        snap = proto.NetlistSnapshot(frame, len(comps), nl["nodeCount"], comps)

        class Endpoint:
            def __init__(self) -> None:
                self.writes: list[bytes] = []

            def readline(self) -> bytes:
                return b""

            def write(self, data: bytes) -> int:
                self.writes.append(data)
                return len(data)

            def flush(self) -> None:
                pass

        ep = Endpoint()
        tester = self.ft.FrontendTester(ep)
        for line in proto.encode_snapshot(snap):
            tester.handle_line(line)
        lines = [w.decode("ascii").rstrip("\r\n") for w in ep.writes]
        packets = [proto.decode_line(w) for w in ep.writes]
        out: dict = {"lines": lines}
        if len(packets) == 1 and isinstance(packets[0], proto.ErrorPacket):
            out["error"] = {"code": packets[0].code, "arg": packets[0].arg}
            return out
        assembler = proto.SnapshotAssembler()
        result = None
        for p in packets:
            result = assembler.push(p) or result
        assert isinstance(result, proto.VoltageSnapshot), lines
        out["status"] = result.status
        out["bits"] = [f"{v.value_bits:08X}" for v in sorted(result.values, key=lambda v: v.node)]
        return out

    # ------------------------------------------------------------ DSL kernels

    def _primitives(self, flavour: str) -> dict:
        ft = self.ft
        base = ft._solve_primitives()
        if flavour == "py":
            return base
        PM = self.PrimitiveModel
        prims = dict(base)
        prims.update(
            {
                "fetchElemVal0": PM("fetchElemVal0", lambda tb, idx: f32(tb.state["elements"][idx][4]), latency=1),
                "store_A": PM("store_A", lambda tb, i, j, v: tb.state["A"][i].__setitem__(j, f32(v)), latency=1),
                "store_LU": PM("store_LU", lambda tb, i, j, v: tb.state["LU"][i].__setitem__(j, f32(v)), latency=1),
                "store_J": PM("store_J", lambda tb, i, v: tb.state["J"].__setitem__(i, f32(v)), latency=1),
                "store_Y": PM("store_Y", lambda tb, i, v: tb.state["Y"].__setitem__(i, f32(v)), latency=1),
                "store_X": PM("store_X", lambda tb, i, v: tb.state["X"].__setitem__(i, f32(v)), latency=1),
                "accumA": PM(
                    "accumA",
                    lambda tb, i, j, delta: tb.state["A"][i].__setitem__(j, f32(float(tb.state["A"][i][j]) + float(delta))),
                    latency=1,
                ),
                "accumJ": PM(
                    "accumJ",
                    lambda tb, i, delta: tb.state["J"].__setitem__(i, f32(float(tb.state["J"][i]) + float(delta))),
                    latency=1,
                ),
                "neg_comb": PM("neg_comb", lambda tb, v: -float(v)),
                "abs_comb": PM("abs_comb", lambda tb, v: abs(float(v))),
                "div": PM("div", lambda tb, a, b: f32(ieee_div(a, b)), latency=4),
            }
        )
        if flavour == "f32":
            prims["fma"] = PM("fma", lambda tb, a, b, c: fma32_fused(a, b, c), latency=3)
        elif flavour == "f32-unfused":
            prims["fma"] = PM("fma", lambda tb, a, b, c: f32(f32(float(a) * float(b)) + float(c)), latency=3)
        else:
            raise ValueError(flavour)
        return prims

    def dsl_dc(self, nl: dict, flavour: str) -> dict:
        elements = decode_frontend(nl)
        dim = nl["nodeCount"] + sum(1 for e in elements if e[1] == "V")
        harness = self.SimulationHarness(
            params={"par_elem_n": len(elements), "par_node_n": nl["nodeCount"]},
            primitives=self._primitives(flavour),
            initial_state=self.ft._make_state(dim, elements),
        )
        try:
            result = self.run_python(self.solve_core_dc, harness)
        except ZeroDivisionError:
            return {"error": "ZeroDivisionError"}
        xs = result.final_state["X"]
        return {"x": [hex64(v) for v in xs] if flavour == "py" else [hex32(v) for v in xs]}

    def dsl_transient_dc_limit(self, nl: dict) -> dict:
        elements = decode_frontend(nl)
        kind_code = {"R": 1, "I": 2, "V": 3, "C": 4, "L": 5}
        dim = nl["nodeCount"] + sum(1 for e in elements if e[1] in ("V", "L"))
        PM = self.PrimitiveModel
        prims = dict(self.ft._solve_primitives())
        prims.update(
            {
                "fetchElemKind": PM("fetchElemKind", lambda tb, idx: tb.state["elements"][idx][1], latency=1),
                "fetchElemVal1": PM("fetchElemVal1", lambda tb, idx: 0.0, latency=1),
                "fetchElemVal2": PM("fetchElemVal2", lambda tb, idx: 0.0, latency=1),
                "fetchElemVal3": PM("fetchElemVal3", lambda tb, idx: 0.0, latency=1),
                "fetch_prevX": PM("fetch_prevX", lambda tb, i: tb.state["prevX"][i], latency=1),
                "store_prevX": PM("store_prevX", lambda tb, i, v: tb.state["prevX"].__setitem__(i, v), latency=1),
                "sin_comb": PM("sin_comb", lambda tb, v: math.sin(v)),
                "pwm_gate_comb": PM("pwm_gate_comb", lambda tb, time, period, duty: 0),
            }
        )
        state = {
            "elements": [(idx, kind_code[k], n0, n1, float(v)) for idx, k, n0, n1, v in elements],
            "A": [[-123.0] * dim for _ in range(dim)],
            "J": [-123.0] * dim,
            "LU": [[-123.0] * dim for _ in range(dim)],
            "Y": [-123.0] * dim,
            "X": [-123.0] * dim,
            "prevX": [0.0] * dim,
        }
        harness = self.SimulationHarness(
            params={
                "par_elem_n": len(elements),
                "par_node_n": nl["nodeCount"],
                "par_dt": math.inf,
                "par_time": 0.0,
            },
            primitives=prims,
            initial_state=state,
        )
        try:
            result = self.run_python(self.solve_core_transient, harness)
        except ZeroDivisionError:
            return {"error": "ZeroDivisionError"}
        return {"x": [hex64(v) for v in result.final_state["X"]]}


def bcd_int(v: int) -> int | None:
    d = [(v >> 8) & 0xF, (v >> 4) & 0xF, v & 0xF]
    if v < 0 or v > 0xFFF or any(x > 9 for x in d):
        return None
    return d[0] * 100 + d[1] * 10 + d[2]


def spec_decodable(nl: dict) -> bool:
    n = nl["nodeCount"]
    for e in nl["elements"]:
        if e["kind"] not in KIND_NAME or e["unit"] not in WIRE_UNIT_SCALE or bcd_int(e["valueBcd"]) is None:
            return False
        if any(x != GND and not (0 <= x < n) for x in (e["n0"], e["n1"])):
            return False
    return True


def decode_frontend(nl: dict) -> list[tuple]:
    out = []
    for e in sorted(nl["elements"], key=lambda e: e["idx"]):
        value = float(bcd_int(e["valueBcd"])) * WIRE_UNIT_SCALE[e["unit"]]
        out.append((e["idx"], KIND_NAME[e["kind"]], e["n0"], e["n1"], value))
    return out


# --------------------------------------------------------------------------- cases


def el(idx, kind, n0, n1, bcd, unit=0):
    return {"idx": idx, "kind": kind, "n0": n0, "n1": n1, "valueBcd": bcd, "unit": unit}


def nl(frame, node_count, *elements):
    return {"frame": frame, "nodeCount": node_count, "elements": list(elements)}


def edge_cases(refs: Refs) -> list[dict]:
    cases: list[dict] = []

    def add(name, category, netlist):
        cases.append({"name": name, "category": category, "netlist": netlist})

    for case in refs.st.default_cases().values():
        s = case.snapshot
        add(
            f"solver_tester:{case.name}",
            "solver_tester",
            {
                "frame": s.frame,
                "nodeCount": s.node_count,
                "elements": [el(c.idx, c.kind, c.n0, c.n1, c.value_bcd, c.unit) for c in s.components],
            },
            )
        cases[-1]["expect"] = [{"node": v.node, "value": v.value} for v in case.expected_voltages]

    R, I, V, C, L = 1, 2, 3, 4, 5
    # Boot circuit (IF-026): 10 V source across two 100 ohm resistors; node 0 is
    # the right rail. Since D-015 the boot netlist is V n0 = rail (+10 V); the
    # pre-D-015 table extracted V n0 = ground (-10 V).
    add("boot:v_n0_ground", "boot", nl(0x10, 1, el(0, V, GND, 0, 0x010), el(1, R, 0, GND, 0x100), el(2, R, 0, GND, 0x100)))
    add("boot:v_n0_rail", "boot", nl(0x11, 1, el(0, V, 0, GND, 0x010), el(1, R, 0, GND, 0x100), el(2, R, 0, GND, 0x100)))
    add("divider_kilo", "units", nl(0x20, 2, el(0, V, 0, GND, 0x005), el(1, R, 0, 1, 0x003, 4), el(2, R, 1, GND, 0x002, 4)))
    add("mixed_units_ik", "units", nl(0x21, 1, el(0, I, GND, 0, 0x002, 3), el(1, R, 0, GND, 0x001, 2)))
    add("unit6_giga", "units", nl(0x22, 1, el(0, I, GND, 0, 0x001, 6), el(1, R, 0, GND, 0x001, 1)))
    add("unit_ff_pico", "invalid", nl(0x38, 1, el(0, V, 0, GND, 0x001, 0xFF), el(1, R, 0, GND, 0x001)))
    add("unit7_invalid", "invalid", nl(0x23, 1, el(0, V, 0, GND, 0x001, 7), el(1, R, 0, GND, 0x001)))
    add("bcd_nibble_A", "invalid", nl(0x24, 1, el(0, V, 0, GND, 0x0A5), el(1, R, 0, GND, 0x001)))
    add("node_out_of_range", "invalid", nl(0x25, 1, el(0, V, 1, GND, 0x005), el(1, R, 0, GND, 0x001)))
    add("kind6_unknown", "invalid", nl(0x26, 1, el(0, 6, 0, GND, 0x005), el(1, R, 0, GND, 0x001)))
    add("blank_resistor", "ill-posed", nl(0x27, 1, el(0, V, 0, GND, 0x005), el(1, R, 0, GND, 0x000)))
    add("blank_resistor_grounded", "ill-posed", nl(0x28, 1, el(0, V, 0, GND, 0x005), el(1, R, 0, GND, 0x010), el(2, R, GND, GND, 0x000)))
    add("blank_sources", "blank", nl(0x29, 1, el(0, V, 0, GND, 0x000), el(1, I, GND, 0, 0x000), el(2, R, 0, GND, 0x100)))
    add("floating_pair", "ill-posed", nl(0x2A, 2, el(0, R, 0, 1, 0x100)))
    add("floating_triangle_current", "ill-posed",
        nl(0x2B, 3, el(0, R, 0, 1, 0x001), el(1, R, 1, 2, 0x002), el(2, R, 2, 0, 0x003), el(3, I, 0, 2, 0x001)))
    add("floating_island", "ill-posed",
        nl(0x2C, 3, el(0, V, 0, GND, 0x005), el(1, R, 0, GND, 0x001), el(2, R, 1, 2, 0x007, 2), el(3, R, 2, 1, 0x003, 2)))
    add("node_only_current_source", "ill-posed", nl(0x2D, 1, el(0, I, GND, 0, 0x001)))
    add("no_ground_ring", "ill-posed", nl(0x2E, 3, el(0, R, 0, 1, 0x010), el(1, R, 1, 2, 0x020), el(2, R, 2, 0, 0x030)))
    add("parallel_v_sources", "ill-posed", nl(0x2F, 1, el(0, V, 0, GND, 0x005), el(1, V, 0, GND, 0x005), el(2, R, 0, GND, 0x001)))
    add("v_self_loop_ground", "ill-posed", nl(0x30, 1, el(0, V, GND, GND, 0x005), el(1, R, 0, GND, 0x001)))
    add("v_self_loop_node", "ill-posed", nl(0x31, 1, el(0, V, 0, 0, 0x000), el(1, R, 0, GND, 0x001)))
    add("empty_netlist", "trivial", nl(0x32, 0))
    add("lone_node_no_elements", "ill-posed", nl(0x33, 1))
    add("ground_only_resistor", "trivial", nl(0x34, 0, el(0, R, GND, GND, 0x100)))
    add("idx_gap", "uart-only", nl(0x35, 1, el(0, V, 0, GND, 0x005), el(2, R, 0, GND, 0x001)))
    add("idx_unsorted", "rv", nl(0x36, 2, el(2, R, 1, GND, 0x002), el(0, V, 0, GND, 0x005), el(1, R, 0, 1, 0x003)))
    chain = [el(0, V, 0, GND, 0x099)] + [el(i + 1, R, i, i + 1, 0x010 + i % 9) for i in range(33)] + [el(34, R, 33, GND, 0x100)]
    add("chain_34_nodes", "uart-only", nl(0x37, 34, *chain))
    add("cap_parallel", "cl", nl(0x40, 1, el(0, V, 0, GND, 0x005), el(1, R, 0, GND, 0x001), el(2, C, 0, GND, 0x010, 4)))
    add("cap_series_floats", "cl", nl(0x41, 2, el(0, V, 0, GND, 0x005), el(1, C, 0, 1, 0x010, 4), el(2, R, 1, 1, 0x001)))
    add("cap_series_into_r", "cl", nl(0x42, 2, el(0, V, 0, GND, 0x005), el(1, C, 0, 1, 0x010, 4), el(2, R, 1, GND, 0x001)))
    add("inductor_short", "cl",
        nl(0x43, 2, el(0, V, 0, GND, 0x005), el(1, L, 0, 1, 0x010, 3), el(2, R, 1, GND, 0x002, 2)))
    add("inductor_parallel_v", "cl", nl(0x44, 1, el(0, V, 0, GND, 0x005), el(1, L, 0, GND, 0x010, 3), el(2, R, 0, GND, 0x001)))
    add("inductor_divider", "cl",
        nl(0x45, 3, el(0, I, GND, 0, 0x002, 3), el(1, L, 0, 1, 0x001), el(2, R, 1, GND, 0x001, 2), el(3, R, 1, 2, 0x050), el(4, L, 2, GND, 0x002)))
    add("inductor_self_loop", "cl", nl(0x46, 1, el(0, V, 0, GND, 0x005), el(1, L, 0, 0, 0x001), el(2, R, 0, GND, 0x001)))
    add("notebook_test2", "rv",
        nl(0x50, 4, el(0, V, 0, GND, 0x001), el(1, R, 0, 1, 0x050), el(2, R, 1, 2, 0x050), el(3, R, 2, 3, 0x050),
           el(4, R, 2, GND, 0x027), el(5, R, 1, 3, 0x091)))
    add("notebook_test3", "rv",
        nl(0x51, 3, el(0, I, 0, 1, 0x020, 3), el(1, I, 1, 2, 0x060, 3), el(2, R, 0, 1, 0x130), el(3, R, 1, 2, 0x100),
           el(4, R, 2, GND, 0x200), el(5, R, 1, GND, 0x150)))
    add("ill_conditioned_giga_milli", "rv",
        nl(0x52, 2, el(0, V, 0, GND, 0x999), el(1, R, 0, 1, 0x001, 6), el(2, R, 1, GND, 0x999, 1), el(3, R, 0, GND, 0x999, 1)))
    return cases


def random_case(rng: random.Random, k: int) -> dict:
    """Random R/I/V(/C/L) circuit. "nice" cases use wire units base/kilo only."""
    category = rng.choices(["nice", "wide", "cl", "loose"], weights=[45, 25, 20, 10])[0]
    n = rng.randint(1, 8)
    units_pool = [0, 4] if category == "nice" else list(range(7))
    R, I, V, C, L = 1, 2, 3, 4, 5

    def unit():
        return rng.choice(units_pool)

    def bcd(lo=0):
        d = rng.randint(lo, 999)
        return ((d // 100) << 8) | (((d // 10) % 10) << 4) | (d % 10)

    parent = list(range(n + 1))  # V/L forest, ground = n

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    def row(x):
        return n if x == GND else x

    def node_or_gnd(limit=None):
        pool = list(range(n if limit is None else limit)) + [GND]
        return rng.choice(pool)

    elems: list[tuple] = []
    order = list(range(n))
    rng.shuffle(order)
    connected = [GND]
    for v in order:
        other = rng.choice(connected)
        a, b = (v, other) if rng.random() < 0.5 else (other, v)
        roll = rng.random()
        if category == "loose" and roll < 0.15:
            pass  # leave this node attached only through later elements, if any
        elif roll < 0.25 and find(row(a)) != find(row(b)):
            parent[find(row(a))] = find(row(b))
            kind = L if category == "cl" and rng.random() < 0.4 else V
            elems.append((kind, a, b, bcd(), unit()))
        else:
            elems.append((R, a, b, bcd(1), unit()))
        connected.append(v)
    for _ in range(rng.randint(0, 6)):
        a, b = node_or_gnd(), node_or_gnd()
        roll = rng.random()
        if roll < 0.4:
            elems.append((R, a, b, bcd(1), unit()))
        elif roll < 0.7:
            elems.append((I, a, b, bcd(), unit()))
        elif category == "cl" and roll < 0.85:
            elems.append((C, a, b, bcd(), rng.randint(0, 6)))
        elif find(row(a)) != find(row(b)) or category == "loose":
            if find(row(a)) != find(row(b)):
                parent[find(row(a))] = find(row(b))
            kind = L if category == "cl" and rng.random() < 0.5 else V
            elems.append((kind, a, b, bcd(), unit()))
    rng.shuffle(elems)
    return {
        "name": f"random:{k:03d}",
        "category": f"random-{category}",
        "netlist": nl(0x1000 + k, n, *(el(i, *e) for i, e in enumerate(elems))),
    }


def build(refs: Refs, seed: int, count: int, kernels: str) -> dict:
    rng = random.Random(seed)
    cases = edge_cases(refs) + [random_case(rng, k) for k in range(count)]
    for case in cases:
        netlist = case["netlist"]
        case["uart"] = refs.uart(netlist)
        if spec_decodable(netlist):
            kinds = {e["kind"] for e in netlist["elements"]}
            if kinds <= {1, 2, 3}:
                case["dsl"] = {fl: refs.dsl_dc(netlist, fl) for fl in ("py", "f32", "f32-unfused")}
            elif kernels == "live":  # the transient kernel is not frozen
                case["transient"] = refs.dsl_transient_dc_limit(netlist)
    return {
        "description": "GM-7 differential fixtures for golden/src/backend (generated by golden/tools/gen_solver_fixtures.py; do not edit)",
        "kernels": kernels,
        "solveCoreDcSha256": refs.solve_core_dc_sha256,
        "seed": seed,
        "randomCases": count,
        "cases": cases,
    }


def find_simpyhls() -> Path:
    if os.environ.get("SIMPYHLS_DIR"):
        return Path(os.environ["SIMPYHLS_DIR"])
    for base in (REPO, *REPO.parents):
        cand = base / "simpyhls"
        if (cand / "examples" / "solve_core_dc.dsl.py").is_file():
            return cand
    return REPO / "simpyhls"


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--simpyhls", type=Path, default=None)
    ap.add_argument("--kernels", choices=("live", "as-written", "both"), default="both")
    ap.add_argument("--out", type=Path, default=None, help="output file (only with a single --kernels set)")
    ap.add_argument("--seed", type=int, default=SEED)
    ap.add_argument("--count", type=int, default=RANDOM_CASES)
    ap.add_argument("--check", action="store_true", help="fail if a fixture differs from a fresh generation")
    args = ap.parse_args(argv)
    sets = ("live", "as-written") if args.kernels == "both" else (args.kernels,)
    if args.out and len(sets) > 1:
        ap.error("--out needs --kernels live or --kernels as-written")
    simpyhls = (args.simpyhls or find_simpyhls()).resolve()
    status = 0
    for kernels in sets:
        kernel_dir = simpyhls / "examples" if kernels == "live" else AS_WRITTEN_KERNELS
        out = args.out or OUT[kernels]
        refs = Refs(simpyhls, kernel_dir)
        text = json.dumps(build(refs, args.seed, args.count, kernels), indent=1) + "\n"
        print(f"{kernels}: solve_core_dc sha256 {refs.solve_core_dc_sha256[:16]} from {kernel_dir}")
        if args.check:
            current = out.read_text() if out.exists() else ""
            if current != text:
                print(f"{out} is out of date", file=sys.stderr)
                status = 1
            else:
                print(f"{out} is up to date")
            continue
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text)
        print(f"wrote {out}")
    return status


if __name__ == "__main__":
    raise SystemExit(main())
