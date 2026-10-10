#!/usr/bin/env python3
"""Regenerate the simpyhls-generated solver RTL in this directory.

Usage (from the repository root, with the simpyhls submodule checked out):

    python3 src/design/solver/regenerate_simpyhls.py [--check] [kernel ...]

Kernels: flooding_core, extract_component_nodes, solve_core_dc (default: all).
Each is compiled from simpyhls/examples/<kernel>.dsl.py with the primitive
registry its simpyhls test (or workflow.ipynb, for flooding_core) uses, and the
module imports the comb package that implements its *_comb primitives.

solve_core_dc.sv additionally keeps an `import StampingCombPkg::*;` before the
module header, as the checked-in file always had. Before M3 the files were
generated this way and then hand-edited (extract_component_nodes.sv got
rotation_to_dir_comb calls in 09aa705); the kernels now call
rotation_to_dir_comb themselves, so no hand edits are needed.

--check compares instead of writing and exits 1 if a file would change.
"""
from pathlib import Path
import argparse
import sys

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
SIMPYHLS = REPO / 'simpyhls'
sys.path.insert(0, str(SIMPYHLS))
sys.path.insert(0, str(SIMPYHLS / 'tests'))

from compiler.lir_to_verilog_model import RTLModuleConfig  # noqa: E402
from compiler.primitive_rtl import PrimitiveRTLRegistry, PrimitiveRTLSpec  # noqa: E402
from compiler.workflow import compile_file  # noqa: E402
import test_extract_component_nodes  # noqa: E402
import test_solve_core  # noqa: E402


def flooding_registry() -> PrimitiveRTLRegistry:
    # simpyhls/workflow.ipynb, cell 1.
    return PrimitiveRTLRegistry([
        PrimitiveRTLSpec(name="fetchP", ports=("i", "j"), result_port="result", latency=1),
        PrimitiveRTLSpec(name="storeR", ports=("i", "j", "v"), latency=1),
        PrimitiveRTLSpec(name="getVisited", ports=("i", "j"), result_port="result", latency=1),
        PrimitiveRTLSpec(name="setVisited", ports=("i", "j"), latency=1),
        PrimitiveRTLSpec(name="addQueue", ports=("i", "j", "d"), latency=1),
        PrimitiveRTLSpec(name="popQueue", ports=(), result_port="result", latency=1),
        PrimitiveRTLSpec(name="getQueueLen", ports=(), result_port="result", latency=1),
        PrimitiveRTLSpec(name="decode_iswire_comb", ports=("p")),
        PrimitiveRTLSpec(name="getport_comb", ports=("p", "i")),
        PrimitiveRTLSpec(name="decode_i_comb", ports=("q_item")),
        PrimitiveRTLSpec(name="decode_j_comb", ports=("q_item")),
        PrimitiveRTLSpec(name="decode_d_comb", ports=("q_item")),
        PrimitiveRTLSpec(name="get_nxt_i_comb", ports=("i", "d")),
        PrimitiveRTLSpec(name="get_nxt_j_comb", ports=("j", "d")),
        PrimitiveRTLSpec(name="get_opp_dir_comb", ports=("d")),
    ])


KERNELS = {
    'flooding_core': (flooding_registry, 'FloodingCombPkg::*', False),
    'extract_component_nodes': (test_extract_component_nodes.extract_registry,
                                'ExtractComponentNodesCombPkg::*', False),
    'solve_core_dc': (test_solve_core.solve_registry, 'StampingCombPkg::*', True),
}


def generate(name: str) -> str:
    registry, package, top_import = KERNELS[name]
    artifact = compile_file(SIMPYHLS / 'examples' / f'{name}.dsl.py', registry(),
                            RTLModuleConfig(package_imports=(package,)))
    text = artifact.verilog
    if top_import:
        header = f'module {name} ('
        assert text.count(header) == 1
        text = text.replace(header, f'import {package};\n\n{header}')
    return text


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--check', action='store_true')
    parser.add_argument('kernels', nargs='*', metavar='kernel', help=', '.join(KERNELS))
    args = parser.parse_args()
    unknown = sorted(set(args.kernels) - set(KERNELS))
    if unknown:
        parser.error('unknown kernel(s): ' + ', '.join(unknown))
    stale = []
    for name in args.kernels or KERNELS:
        text = generate(name)
        path = HERE / f'{name}.sv'
        if args.check:
            if not path.exists() or path.read_text() != text:
                stale.append(path.name)
        else:
            path.write_text(text)
            print(f'wrote {path.relative_to(REPO)}')
    if stale:
        print('out of date: ' + ', '.join(stale))
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
