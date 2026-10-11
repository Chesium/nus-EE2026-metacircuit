#!/usr/bin/env python3
"""Capture isolated Vivado measurements; strict evidence verification is separate from timing success."""
from __future__ import annotations
import argparse
import hashlib
import json
import re
import os
import signal
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT_SOURCES = [
    'src/design/solver/BackendFetchers.v',
    'src/design/rendering/ButtonVGA.v',
    'src/design/Keyboard/Calculator.v',
    'src/design/rendering/CircuitCanvas.v',
    'src/design/common/ClockDivider.v',
    'src/design/Dashboard/ComponentPropertyPanel.v',
    'src/design/rendering/DummyDataGenerate.v',
    'src/design/Dashboard/DynamicTextBox.v',
    'src/design/common/FloodQueueStore.v',
    'src/design/Dashboard/FontROM.v',
    'src/design/interaction/InteractionController.v',
    'src/design/interaction/CanvasCommandGuard.v',
    'src/design/interaction/InteractionFrameCapture.v',
    'src/design/rendering/KeyboardVGA.v',
    'src/design/driver/Oled_Display.v',
    'src/design/common/PingPongBuffer.v',
    'src/design/matrix/ResultMatrixStore.v',
    'src/design/common/SimpleDualRam.v',
    'src/design/common/SimpleRam.v',
    'src/design/rendering/ToolbarVGA.v',
    'src/design/uart/UartTx.v',
    'src/design/uart/FrontendNetlistLineTransmitter.sv',
    'src/design/uart/FrontendVoltagePacketParser.sv',
    'src/design/driver/VGAControl.v',
    'src/design/matrix/VisitedMatrixStore.v',
    'src/design/rendering/WaveformPlot.v',
    'src/design/interaction/WireDrawMode.v',
    'src/design/Keyboard/one_bit_adder.v',
    'src/design/common/ExtractComponentNodesCombPkg.sv',
    'src/design/solver/FloodingBackendWrapper.sv',
    'src/design/common/FloodingCombPkg.sv',
    'src/design/solver/extract_component_nodes.sv',
    'src/design/solver/flooding_core.sv',
    'src/design/rendering/MouseDisplay.vhd',
    'src/design/driver/Mouse_Control.vhd',
    'src/design/driver/Ps2Interface.vhd',
    'src/design/rendering/GlobalRender_top.v',
    'src/design/uart/Hex7SegMux.v',
    'src/design/solver_board/UartRx.v',
    'src/design/floating_point/fpo_div.v',
    'src/design/floating_point/fpo_fma.v',
    'src/design/solver_board/BcdUnitToFp32Rom.sv',
    'src/design/solver_board/SolverDcPipeline.sv',
    'src/design/matrix/SolverMatrixStore.sv',
    'src/design/solver_board/SolverUartLineTransmitter.sv',
    'src/design/matrix/SolverVectorStore.sv',
    'src/design/common/StampingCombPkg.sv',
    'src/design/common/StampingNetlistStore.sv',
    'src/design/solver_board/UartLineAssembler.sv',
    'src/design/solver_board/UartPacketParser.sv',
    'src/design/solver/solve_core_dc.sv',
    'src/design/solver_board/SolverBoard_top.sv',
    'src/design/Dashboard/TextBox.v',
    'src/design/Dashboard/CompactDigitROM.v',
    'src/design/Dashboard/MatrixDisplay.v',
    'src/design/uart/UART_FrameDemo_top.v',
    'src/design/Keyboard/Keyboard.v',
    'src/design/floating_point/fpo_tofixed.v',
    'src/design/matrix/lu_core.sv',
    'src/design/common/ClockDividerMs.v',
    'src/design/matrix/LUdecomp.v',
    'src/design/matrix/bmatrixStore.v',
    'src/design/Dashboard/TextDisplay.v',
    'src/design/matrix/PortGridStore.v',
    'src/design/common/CanvasBufferRam.v',
    'src/design/matrix/matrixStore.v',
    'src/design/Dashboard/DynamicTextDisplay.v',
    'src/design/solver_board/bcd_unit_to_fp32_rom.mem',
]
PROJECT_IPS = [
    'src/ip/floating_point_fma/floating_point_fma.xci',
    'src/ip/floating_point_div/floating_point_div.xci',
    'src/ip/floating_point_to_fixed_16_16/floating_point_to_fixed_16_16.xci',
]
# Conservative source closure includes generate branches even when disabled by defaults.
EXCLUDED_SOURCES = {
    'src/design/floating_point/fpo_div.v', 'src/design/floating_point/fpo_fma.v',
    'src/design/floating_point/fpo_tofixed.v',
    'src/design/solver_board/BcdUnitToFp32Rom.sv', 'src/design/solver_board/SolverDcPipeline.sv',
    'src/design/matrix/SolverMatrixStore.sv', 'src/design/solver_board/SolverUartLineTransmitter.sv',
    'src/design/matrix/SolverVectorStore.sv', 'src/design/common/StampingCombPkg.sv',
    'src/design/common/StampingNetlistStore.sv', 'src/design/solver_board/UartPacketParser.sv',
    'src/design/solver/solve_core_dc.sv', 'src/design/solver_board/SolverBoard_top.sv',
    'src/design/Dashboard/TextBox.v', 'src/design/Dashboard/CompactDigitROM.v',
    'src/design/Dashboard/MatrixDisplay.v', 'src/design/uart/UART_FrameDemo_top.v',
    'src/design/matrix/lu_core.sv', 'src/design/common/ClockDividerMs.v',
    'src/design/matrix/LUdecomp.v', 'src/design/matrix/bmatrixStore.v',
    'src/design/Dashboard/TextDisplay.v', 'src/design/matrix/PortGridStore.v',
    'src/design/common/CanvasBufferRam.v', 'src/design/matrix/matrixStore.v',
    'src/design/Dashboard/DynamicTextDisplay.v', 'src/design/solver_board/bcd_unit_to_fp32_rom.mem',
}
SOURCES = [p for p in PROJECT_SOURCES if p not in EXCLUDED_SOURCES]
IPS = []  # Floating-point XCI are referenced only by the excluded fpo wrappers.
CONSTRAINTS = ['src/constraint/basys3.xdc']
PART = 'xc7a35tcpg236-1'
TOP = 'GlobalRender_top'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def tcl_quote(path):
    # Repository paths containing braces/newlines would change Tcl semantics.
    if any(c in str(path) for c in '{}\n\r'):
        raise ValueError('unsupported Tcl path characters')
    return '{' + str(path) + '}'


def audit_reachability(root):
    """Conservative declaration/reference closure; Vivado elaboration validates binding.

    Includes disabled generate branches. This is an auditable omission check,
    not a general HDL parser or a replacement for elaboration.
    """
    declarations, texts = {}, {}
    for path in PROJECT_SOURCES:
        if Path(path).suffix == '.mem':
            continue
        text = (root / path).read_text()
        text = re.sub(r'/\*.*?\*/|//[^\n]*|--[^\n]*', '', text, flags=re.S)
        texts[path] = text
        for name in re.findall(r'^\s*(?:module|entity|package)\s+([A-Za-z_]\w*)', text, re.M | re.I):
            declarations[name.lower()] = path
    pending, reachable, edges = [TOP.lower()], set(), {}
    while pending:
        name = pending.pop()
        path = declarations[name]
        if path in reachable:
            continue
        reachable.add(path)
        dependencies = []
        for target, target_path in declarations.items():
            if target_path == path:
                continue
            patterns = [r'\b' + re.escape(target) + r'\s*(?:#\s*\(|\w+\s*\()',
                        r'\b' + re.escape(target) + r'::',
                        r'\b' + re.escape(target) + r'\s*(?:generic|port)\s+map']
            if any(re.search(pattern, texts[path], re.I) for pattern in patterns):
                dependencies.append(target)
                pending.append(target)
        edges[path] = sorted(dependencies)
    if reachable != set(SOURCES):
        raise ValueError('frontend source reachability changed; audit manifest before measuring: ' +
                         str(sorted(reachable.symmetric_difference(SOURCES))))
    wrappers = ['src/design/floating_point/fpo_div.v', 'src/design/floating_point/fpo_fma.v',
                'src/design/floating_point/fpo_tofixed.v']
    return {'method': 'conservative declaration/reference closure, all generate branches included',
            'edges': edges, 'excluded_sources': sorted(EXCLUDED_SOURCES),
            'excluded_ips': PROJECT_IPS, 'ip_reference_wrappers': wrappers,
            'qualification': 'Vivado top elaboration must have no unresolved black boxes'}


def prepare(root, out, stage):
    if out.exists() and any(out.iterdir()):
        raise ValueError('run directory must be empty: never reuse stale reports')
    out.mkdir(parents=True, exist_ok=True)
    paths = PROJECT_SOURCES + PROJECT_IPS + CONSTRAINTS + ['tools/vivado_qor.py', 'tools/vivado_qor.tcl', 'metacircuit.tcl']
    measurement_root = out / 'inputs'
    for path in paths:
        target = measurement_root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(root / path, target)
    manifest = {
        'schema': 1, 'created_at_utc': datetime.now(timezone.utc).isoformat(),
        'root': str(root), 'measurement_root': str(measurement_root), 'top': TOP, 'part': PART, 'requested_stage': stage,
        'sources': SOURCES, 'ips': IPS, 'constraints': CONSTRAINTS,
        'reachability': audit_reachability(root),
        'hashes': {p: sha(root / p) for p in paths},
        'solver_board': {'status': 'excluded', 'reason': 'separate top/manifest and primitive qualification required'},
        'settings': {'synthesis': 'defaults, flatten_hierarchy=rebuilt', 'implementation': ['opt_design', 'place_design', 'phys_opt_design', 'route_design'], 'threads': 4, 'seed': None},
    }
    # Copy IP configuration so generated outputs cannot mutate the tracked source tree.
    copied_ips = []
    for ip in IPS:
        target = out / 'ip' / Path(ip).parent.name / Path(ip).name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(root / ip, target)
        copied_ips.append(target)
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    (out / 'manifest.tcl').write_text(
        'set qor_sources [list ' + ' '.join(tcl_quote(measurement_root / p) for p in SOURCES) + ']\n'
        'set qor_ips [list ' + ' '.join(tcl_quote(p) for p in copied_ips) + ']\n'
        'set qor_stage ' + tcl_quote(stage) + '\n')
    return manifest


def parse_utilization(text):
    result = {}
    for key, label in [('lut', 'Slice LUTs'), ('ff', 'Slice Registers'), ('bram', 'Block RAM Tile'), ('dsp', 'DSPs')]:
        match = re.search(r'^\s*\|\s*' + label + r'\*?\s*\|\s*([\d,.]+)\s*\|', text, re.M)
        if not match:
            raise ValueError('missing utilization field: ' + key)
        value = float(match[1].replace(',', ''))
        if value < 0:
            raise ValueError('negative utilization')
        result[key] = value
    return result


def parse_hierarchy(text):
    rows, stack = [], []
    for line in text.splitlines():
        if not line.lstrip().startswith('|'):
            continue
        cells = line.split('|')[1:-1]
        if len(cells) != 10 or not cells[2].strip().isdigit():
            continue
        instance = cells[0].strip()
        indent = len(cells[0]) - len(cells[0].lstrip())
        values = [int(value.strip()) for value in cells[2:]]
        direct = instance.startswith('(')
        if not direct:
            while stack and stack[-1][0] >= indent:
                stack.pop()
            stack.append((indent, instance))
        path = '/'.join(name for _, name in stack)
        rows.append({'instance': instance, 'path': path, 'module': cells[1].strip(),
                     'scope': 'direct' if direct else 'inclusive',
                     'resources': {'lut': values[0], 'ff': values[4],
                                   'bram': values[5] + values[6] / 2, 'dsp': values[7]},
                     'logic_lut': values[1], 'lutram': values[2], 'srl': values[3],
                     'ramb36': values[5], 'ramb18': values[6]})
    if not rows or rows[0]['instance'] != TOP:
        raise ValueError('missing hierarchical utilization table/top')
    return rows


def parse_drc(text):
    rows = []
    for line in text.splitlines():
        match = re.match(r'\s*\|\s*(\S+)\s*\|\s*(Error|Critical Warning|Warning|Info)\s*\|\s*(.*?)\s*\|\s*(\d+)\s*\|', line)
        if match:
            rule, severity, description, count = match.groups()
            rows.append({'rule': rule, 'severity': severity, 'description': description, 'count': int(count)})
    if 'REPORT SUMMARY' not in text:
        raise ValueError('missing DRC report summary')
    if not rows and not re.search(r'(?:No violations|Checks found:\s*0)', text, re.I):
        raise ValueError('missing DRC result categories')
    return {'status': 'requires_review', 'findings': rows}


def parse_timing(text):
    # Table follows Design Timing Summary; avoid accidentally parsing path slack.
    tail = text.split('Design Timing Summary', 1)[-1]
    match = re.search(r'WNS\(ns\).*?WHS\(ns\).*?\n\s*-+[ -]*\n\s*([-+\d.]+)\s+([-+\d.]+)\s+(\d+)\s+(\d+)\s+([-+\d.]+)\s+([-+\d.]+)\s+(\d+)\s+(\d+)', tail, re.S)
    if not match:
        raise ValueError('missing setup/hold timing summary')
    values = match.groups()
    return dict(zip(['wns_ns', 'tns_ns', 'setup_failing_endpoints', 'setup_total_endpoints', 'whs_ns', 'ths_ns', 'hold_failing_endpoints', 'hold_total_endpoints'], [float(v) if i in (0, 1, 4, 5) else int(v) for i, v in enumerate(values)]))


def parse_checks(text):
    required = ['no_clock', 'unconstrained_internal_endpoints', 'no_input_delay', 'no_output_delay']
    counts = {}
    for name in required:
        match = re.search(r'checking\s+' + name + r'\s*\((\d+)\)', text, re.I)
        if not match:
            raise ValueError('missing check_timing category: ' + name)
        counts[name] = int(match[1])
    return counts


def parse_paths(text):
    paths = []
    for block in re.split(r'(?=Slack\s*\()', text)[1:]:
        level = re.search(r'Logic Levels:\s*(\d+)', block)
        delay = re.search(r'Data Path Delay:\s*([\d.]+)ns\s*\(logic\s*([\d.]+)ns.*?route\s*([\d.]+)ns', block)
        if level and delay:
            paths.append({'logic_levels': int(level[1]), 'data_path_ns': float(delay[1]), 'logic_ns': float(delay[2]), 'routing_ns': float(delay[3])})
    if not paths:
        raise ValueError('missing critical-path logic/routing detail')
    return paths


def summarize(out, root=None):
    errors = []
    summary = {'schema': 1, 'evidence_status': 'incomplete', 'stages': {}, 'errors': errors, 'timing_clean': False}
    try:
        artifact_hashes = json.loads((out / 'artifacts.json').read_text())
        for name, expected in artifact_hashes.items():
            if sha(out / name) != expected:
                errors.append('corrupt artifact: ' + name)
        manifest = json.loads((out / 'manifest.json').read_text())
        summary['manifest'] = manifest
        if manifest['top'] != TOP or manifest['part'] != PART or manifest['sources'] != SOURCES or manifest['ips'] != IPS or manifest['constraints'] != CONSTRAINTS:
            raise ValueError('top/source/IP/constraint manifest changed')
        root = Path(root or manifest.get('measurement_root', manifest['root']))
        for p, expected in manifest['hashes'].items():
            if sha(root / p) != expected:
                errors.append('stale source hash: ' + p)
        for mandatory in PROJECT_SOURCES + PROJECT_IPS + CONSTRAINTS + ['tools/vivado_qor.py', 'tools/vivado_qor.tcl', 'metacircuit.tcl']:
            if mandatory not in manifest['hashes']:
                errors.append('missing source hash: ' + mandatory)
        requested = manifest['requested_stage']
        if requested not in ('synth', 'routed'):
            raise ValueError('invalid requested stage')
        settings = (out / 'settings.txt').read_text()
        if 'Vivado v2025.2' not in settings or 'SW Build' not in settings:
            errors.append('missing/unexpected Vivado version/build')
        for stage in (['synth'] if requested == 'synth' else ['synth', 'routed']):
            required = [stage + suffix for suffix in ['.complete', '.dcp', '_utilization.rpt', '_hierarchical.rpt', '_timing.rpt', '_paths.rpt', '_clocks.rpt', '_clock_periods.tsv', '_check_timing.rpt', '_cdc.rpt', '_drc.rpt']]
            if stage == 'routed':
                required.append('routed_route_status.rpt')
            for filename in required:
                if not (out / filename).is_file() or (out / filename).stat().st_size == 0:
                    errors.append('missing/empty artifact: ' + filename)
                if filename not in artifact_hashes:
                    errors.append('missing artifact hash: ' + filename)
            try:
                checks = parse_checks((out / (stage + '_check_timing.rpt')).read_text())
                metrics = {'resources': parse_utilization((out / (stage + '_utilization.rpt')).read_text()), 'timing': parse_timing((out / (stage + '_timing.rpt')).read_text()), 'constraint_checks': checks}
                metrics['critical_paths'] = parse_paths((out / (stage + '_paths.rpt')).read_text())
                metrics['hierarchical_resources'] = {'status': 'parsed', 'report': stage + '_hierarchical.rpt', 'rows': parse_hierarchy((out / (stage + '_hierarchical.rpt')).read_text())}
                metrics['drc'] = parse_drc((out / (stage + '_drc.rpt')).read_text())
                clocks = [line.split('\t') for line in (out / (stage + '_clock_periods.tsv')).read_text().splitlines()]
                if not clocks or not any(c[0] == 'sys_clk_pin' and float(c[1]) == 10 for c in clocks):
                    errors.append('missing/changed 100 MHz primary clock: ' + stage)
                metrics['clocks'] = clocks
                cdc = (out / (stage + '_cdc.rpt')).read_text()
                metrics['cdc'] = {'status': 'requires_review', 'report': stage + '_cdc.rpt'}
                if 'CDC' not in cdc or len(cdc) < 100:
                    errors.append('invalid CDC report: ' + stage)
                # No automatic waiver inference; retain detailed CDC and DRC reports.
                timing = metrics['timing']
                metrics['timing_status'] = 'clean' if timing['wns_ns'] >= 0 and timing['whs_ns'] >= 0 and not any(checks.values()) else 'violations_or_unconstrained'
                summary['stages'][stage] = metrics
            except (OSError, ValueError, IndexError) as exc:
                errors.append(stage + ': ' + str(exc))
        if (out / 'black_boxes.rpt').read_text().splitlines()[0] != 'black_box_count=0':
            errors.append('unresolved or invalid black-box report')
        run = json.loads((out / 'run.json').read_text())
        summary['run'] = run
        if run['returncode'] != 0:
            errors.append('Vivado exited unsuccessfully')
        if not (out / 'vivado.log').is_file():
            errors.append('missing Vivado warning/error log')
        for name in ['manifest.json', 'manifest.tcl', 'settings.txt', 'run.json', 'vivado.log', 'vivado.jou', 'console.log', 'ip_status.rpt', 'compile_order.rpt', 'black_boxes.rpt']:
            if name not in artifact_hashes:
                errors.append('missing artifact hash: ' + name)
        if (out / 'vivado.log').is_file():
            log = (out / 'vivado.log').read_text(errors='replace')
            logged_errors = re.findall(r'^\s*ERROR:.*$', log, re.M)
            if logged_errors:
                errors.append('Vivado logged ERROR: ' + str(len(logged_errors)))
            summary['warnings'] = [line for line in log.splitlines() if line.startswith(('WARNING:', 'CRITICAL WARNING:', 'ERROR:'))]
    except (OSError, ValueError, KeyError, TypeError) as exc:
        errors.append(str(exc))
    if not errors:
        summary['evidence_status'] = 'complete'
    # A characterization with unresolved CDC/constraint findings is never timing-clean.
    (out / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    return summary


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--root', type=Path, default=ROOT)
    parser.add_argument('--stage', choices=['synth', 'routed'], default='routed')
    parser.add_argument('--vivado', default='/opt/amd/2025.2/Vivado/bin/vivado')
    parser.add_argument('--parse-only', action='store_true')
    parser.add_argument('--check-working-tree', action='store_true', help='also require current checkout input hashes to match')
    args = parser.parse_args()
    root, out = args.root.resolve(), args.out.resolve()
    if not args.parse_only:
        manifest = prepare(root, out, args.stage)
        measurement_root = Path(manifest['measurement_root'])
        command = [args.vivado, '-mode', 'batch', '-source', str(measurement_root / 'tools/vivado_qor.tcl'), '-log', str(out / 'vivado.log'), '-journal', str(out / 'vivado.jou'), '-tclargs', str(measurement_root), str(out)]
        start = datetime.now(timezone.utc).isoformat()
        with (out / 'console.log').open('w') as stream:
            try:
                process = subprocess.Popen(command, cwd=out, stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
                (out / 'job.json').write_text(json.dumps({'pid': process.pid, 'pgid': process.pid, 'owned': True, 'command': command}, indent=2) + '\n')
                def stop_owned(signum, frame):
                    os.killpg(process.pid, signal.SIGTERM)
                signal.signal(signal.SIGTERM, stop_owned)
                signal.signal(signal.SIGINT, stop_owned)
                rc = process.wait()
            except OSError as exc:
                stream.write(str(exc) + '\n')
                rc = 127
        (out / 'run.json').write_text(json.dumps({'command': command, 'started_at_utc': start, 'finished_at_utc': datetime.now(timezone.utc).isoformat(), 'returncode': rc}, indent=2) + '\n')
        (out / 'artifacts.json').write_text(json.dumps({str(p.relative_to(out)): sha(p) for p in sorted(out.iterdir()) if p.is_file() and p.name not in ('summary.json', 'artifacts.json')}, indent=2) + '\n')
    result = summarize(out, root if args.check_working_tree else None)
    print(json.dumps({'evidence_status': result['evidence_status'], 'errors': result['errors'], 'summary': str(out / 'summary.json')}, indent=2))
    return 0 if result['evidence_status'] == 'complete' else 1


if __name__ == '__main__':
    sys.exit(main())
