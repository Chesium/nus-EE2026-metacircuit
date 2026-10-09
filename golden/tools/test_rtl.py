#!/usr/bin/env python3
"""Run focused interaction, keypad and canvas tests with the native Verilator."""
from pathlib import Path
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[2]
sources = [str(p) for p in (repo / 'src/design/interaction').glob('*.v')]
special_sources = {
    'KeyboardVGA_test': ['rendering/KeyboardVGA.v', 'rendering/ButtonVGA.v'],
    'CircuitCanvas_left_edge_test': ['rendering/CircuitCanvas.v', 'common/SimpleRam.v'],
}
for name in ['InteractionController_test', 'CanvasCommandGuard_test', 'KeyboardVGA_test', 'CircuitCanvas_left_edge_test']:
    test_sources = [str(repo / 'src/design' / p) for p in special_sources[name]] if name in special_sources else sources
    with tempfile.TemporaryDirectory(prefix='metacircuit-rtl-test-') as work:
        build = subprocess.run(['verilator', '--binary', '--timing', '--top-module', name,
                                '-Wno-fatal', '--Mdir', work, *test_sources,
                                str(repo / 'src/testbench' / (name + ('.v' if name in ('InteractionController_test', 'CircuitCanvas_left_edge_test') else '.sv')))],
                               capture_output=True, text=True)
        if build.returncode:
            raise RuntimeError(build.stdout + build.stderr)
        subprocess.run([str(Path(work) / ('V' + name))], check=True)
