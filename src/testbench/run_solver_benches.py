#!/usr/bin/env python3
"""Build and run the focused solver benches with Verilator.

Usage: python3 src/testbench/run_solver_benches.py [bench ...]

The Xilinx floating-point IP is replaced by sim_models/FloatingPointIpModels.sv
(double-precision arithmetic rounded to binary32) and the benches convert
binary32 with sim_models/Fp32SimPkg.sv, since Verilator promotes shortreal.
Exits 1 unless every bench passes.
"""
from pathlib import Path
import subprocess
import sys
import tempfile

repo = Path(__file__).resolve().parents[2]
design = repo / 'src/design'
tb = repo / 'src/testbench'
pkgs = sorted(str(p) for p in design.rglob('*Pkg.sv')) + [str(tb / 'sim_models/Fp32SimPkg.sv')]
others = sorted(str(p) for p in design.rglob('*') if p.suffix in ('.v', '.sv')
                and not p.name.endswith('Pkg.sv'))
others.append(str(tb / 'sim_models/FloatingPointIpModels.sv'))
extra = {
    'SolveCore_test': [str(tb / 'legacy_rtl/StampingLegacyCombPkg.sv'), str(tb / 'legacy_rtl/solve_core.sv')],
}
cwd = {'SolverBoard_top_test': design / 'solver_board'}
names = sys.argv[1:] or ['ExtractComponentNodes_test', 'SolveCoreDc_test', 'SolveCore_test',
                         'FloodingCore_test', 'SolverBoard_top_test']
results = {}
for name in names:
    with tempfile.TemporaryDirectory(prefix='m3-bench-', dir=None) as work:
        cmd = ['verilator', '--binary', '--timing', '-O2', '--top-module', name, '-Wno-fatal',
               '-Wno-lint', '-Wno-style', '-Wno-MULTIDRIVEN', '-j', '0', '--Mdir', work,
               *pkgs, *extra.get(name, []), *others, str(tb / f'{name}.sv')]
        build = subprocess.run(cmd, capture_output=True, text=True)
        if build.returncode:
            results[name] = 'BUILD FAILED'
            print(build.stdout[-4000:], build.stderr[-4000:])
            continue
        run = subprocess.run([str(Path(work) / f'V{name}')], capture_output=True, text=True,
                             cwd=str(cwd.get(name, repo)), timeout=3000)
        print(run.stdout[-3000:], run.stderr[-2000:])
        results[name] = 'PASS' if run.returncode == 0 and f'{name} passed' in run.stdout else 'FAIL'
for k, v in results.items():
    print(f'{k}: {v}')
sys.exit(0 if all(v == "PASS" for v in results.values()) else 1)
