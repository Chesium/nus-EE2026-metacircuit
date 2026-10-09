#!/usr/bin/env python3
"""Run focused interaction, keypad and canvas tests with the native Verilator."""
from pathlib import Path
import re
import subprocess
import sys
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


# RTL-4: the frontend UART loop on the full GlobalRender_top (SW[5] = 1), built
# from the same source list as framescope's metacircuit manifest. The bench
# checks the netlist, the voltage store, the 7-segment value and the latency;
# here every captured RsTx/RsRx line is re-decoded with src/uart_link/protocol.py.
sys.path.insert(0, str(repo))
from src.uart_link import protocol  # noqa: E402

design = repo / 'src/design'
full_sources = sorted(str(p) for p in design.rglob('*Pkg.sv'))
full_sources += sorted(str(p) for p in design.rglob('*') if p.suffix in ('.v', '.sv')
                       and not p.name.endswith('Pkg.sv') and 'floating_point' not in p.parts)
name = 'GlobalRenderUartLoop_test'
with tempfile.TemporaryDirectory(prefix='metacircuit-rtl-test-') as work:
    build = subprocess.run(['verilator', '--binary', '--timing', '-O2', '--top-module', name,
                            '-Wno-fatal', '-Wno-lint', '-Wno-style', '-Wno-MULTIDRIVEN', '-j', '0',
                            '--Mdir', work, *full_sources, str(repo / 'src/testbench' / (name + '.sv'))],
                           capture_output=True, text=True)
    if build.returncode:
        raise RuntimeError(build.stdout + build.stderr)
    run = subprocess.run([str(Path(work) / ('V' + name))], capture_output=True, text=True)
    print(run.stdout, end='')
    if run.returncode or f'{name} passed' not in run.stdout:
        raise RuntimeError(f'{name} failed:\n{run.stderr}')

tx = [m.group(1) for m in re.finditer(r'^TXLINE \d+ .* (@\S+)$', run.stdout, re.M)]
rx = [m.group(1) for m in re.finditer(r'^RXLINE \d+ .* (@\S+)$', run.stdout, re.M)]
assembler = protocol.SnapshotAssembler()
snapshots = []
for line in tx:
    snapshot = assembler.push(protocol.decode_line(line))
    if snapshot is not None:
        snapshots.append(snapshot)
assert len(snapshots) >= 5 and all(isinstance(s, protocol.NetlistSnapshot) for s in snapshots), snapshots
undecodable = []
for line in rx:
    try:
        protocol.decode_line(line)
    except protocol.PacketError:
        undecodable.append(line)
assert undecodable == ['@VB,0000,01,00*00'], undecodable  # the bench's deliberate bad checksum
print(f'{name}: protocol.py decoded {len(tx)} RsTx lines ({len(snapshots)} snapshots) and {len(rx) - 1} RsRx lines')
