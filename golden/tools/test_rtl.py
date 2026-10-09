#!/usr/bin/env python3
"""Run focused interaction and keypad tests with the native Verilator."""
from pathlib import Path
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[2]
sources = [str(p) for p in (repo / 'src/design/interaction').glob('*.v')]
for name in ['InteractionController_test', 'CanvasCommandGuard_test', 'KeyboardVGA_test']:
    test_sources = sources if name != 'KeyboardVGA_test' else [
        str(repo / 'src/design/rendering/KeyboardVGA.v'),
        str(repo / 'src/design/rendering/ButtonVGA.v')]
    with tempfile.TemporaryDirectory(prefix='metacircuit-rtl-test-') as work:
        build = subprocess.run(['verilator', '--binary', '--timing', '--top-module', name,
                                '-Wno-fatal', '--Mdir', work, *test_sources,
                                str(repo / 'src/testbench' / (name + ('.v' if name == 'InteractionController_test' else '.sv')))],
                               capture_output=True, text=True)
        if build.returncode:
            raise RuntimeError(build.stdout + build.stderr)
        subprocess.run([str(Path(work) / ('V' + name))], check=True)
