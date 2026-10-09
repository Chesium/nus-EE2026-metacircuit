#!/usr/bin/env python3
"""Run focused M1 interaction tests with the native Verilator."""
from pathlib import Path
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[2]
sources = [str(p) for p in (repo / 'src/design/interaction').glob('*.v')]
for name in ['InteractionController_test', 'CanvasCommandGuard_test']:
    with tempfile.TemporaryDirectory(prefix='metacircuit-rtl-test-') as work:
        build = subprocess.run(['verilator', '--binary', '--timing', '--top-module', name,
                                '-Wno-fatal', '--Mdir', work, *sources,
                                str(repo / 'src/testbench' / (name + ('.sv' if name == 'CanvasCommandGuard_test' else '.v')))],
                               capture_output=True, text=True)
        if build.returncode:
            raise RuntimeError(build.stdout + build.stderr)
        subprocess.run([str(Path(work) / ('V' + name))], check=True)
