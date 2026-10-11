#!/usr/bin/env python3
"""M5-5 actual generated RTL qualification; unvalidated FP never passes readiness."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
import signal
import random
import re
import struct
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TB = ROOT / 'src/testbench'


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def ip_configuration(path):
    values = {}
    for element in ET.parse(path).iter():
        if element.tag.rsplit('}', 1)[-1] == 'configurableElementValue':
            key = next((v for k, v in element.attrib.items() if k.endswith('referenceId')), '')
            values[key] = element.text or ''
    keys = ['Operation_Type', 'C_Latency', 'C_Rate', 'Flow_Control', 'A_Precision_Type',
            'Result_Precision_Type', 'Has_ARESETn', 'Has_RESULT_TREADY']
    return {'path': str(Path(path).relative_to(ROOT)), 'sha256': sha256(path),
            'parameters': {k: values.get('PARAM_VALUE.' + k) for k in keys}}


def packet(payload):
    checksum = 0
    for ch in payload:
        checksum ^= ord(ch)
    return '@' + payload + f'*{checksum:02X}'


def fp32(value):
    return struct.unpack('>I', struct.pack('>f', value))[0]


def extraction_fixtures(seed, count):
    """Independent isolated-component geometry oracle; no RTL helper functions."""
    rng = random.Random(seed)
    cases = []
    modes = ['wire', 'ground', 'open', 'nonfacing']
    # 320 mandatory combinations plus randomized repeat positions/sparse ids.
    combos = [(kind, rot, a, b) for kind in (5, 7, 9, 11, 13)
              for rot in range(4) for a in modes for b in modes]
    rng.shuffle(combos)
    for case_id in range(max(count, len(combos))):
        kind, rot, a, b = combos[case_id % len(combos)]
        dx, dy = ((1, 0), (0, 1), (-1, 0), (0, -1))[rot]
        x, y = rng.randrange(1, 5), rng.randrange(1, 5)
        # Partner must be in bounds; endpoints may fall outside the grid.
        cells, regions = [0] * 36, [0] * 36
        cells[y * 6 + x] = 1 | (kind << 1) | (rot << 7)
        cells[(y + dy) * 6 + x + dx] = 1 | ((kind + 1) << 1) | (rot << 7)
        raw = rng.sample(range(1, 240), 2)
        ends = []
        for side, mode in enumerate((a, b)):
            ex, ey = (x - dx, y - dy) if side == 0 else (x + 2 * dx, y + 2 * dy)
            mode = mode if 0 <= ex < 6 and 0 <= ey < 6 else 'open'
            ends.append({'x': ex, 'y': ey, 'mode': mode, 'region': raw[side]})
            if mode == 'open':
                continue
            er = (rot + 2) % 4 if side == 0 else rot
            if mode in ('wire', 'nonfacing'):
                er = (rot + (mode == 'nonfacing')) % 2
            cells[ey * 6 + ex] = 1 | ((15 if mode == 'ground' else 0) << 1) | (er << 7)
            regions[ey * 6 + ex] = raw[side]
        connected = sorted((e for e in ends if e['mode'] == 'wire'), key=lambda e: (e['y'], e['x']))
        row = {e['region']: i for i, e in enumerate(connected)}
        next_row = len(row)
        nodes = []
        # D-015 current source n0 is beyond partner; D-019 open rows n0 first.
        ordered = ends[::-1] if kind == 9 else ends
        for end in ordered:
            if end['mode'] == 'ground':
                nodes.append(255)
            elif end['mode'] == 'wire':
                nodes.append(row[end['region']])
            else:
                nodes.append(next_row)
                next_row += 1
        cases.append({'id': case_id, 'type': kind, 'rotation': rot, 'x': x, 'y': y,
                      'cells': cells, 'regions': regions, 'nodes': nodes, 'ends': ends})
    return cases


def solver_fixtures(seed, count):
    rng = random.Random(seed)
    fixtures = []
    for i in range(count):
        fid = i + 1
        resistance = 2 ** rng.randrange(10)
        source = 2 ** rng.randrange(7)
        mode = i % 3
        if mode == 0:  # Ideal source and arbitrary parallel load: V = source.
            elems, nodes = [(3, 0, 255, source), (1, 0, 255, resistance)], [fp32(source)]
        elif mode == 1:  # Equal divider: V0=source, V1=source/2; pivoted MNA.
            elems = [(3, 0, 255, source), (1, 0, 1, resistance), (1, 1, 255, resistance)]
            nodes = [fp32(source), fp32(source / 2)]
        else:  # Current from node to ground or reverse; Ohm's law fixes sign.
            reverse = bool(rng.randrange(2))
            elems = [(2, 255 if reverse else 0, 0 if reverse else 255, source), (1, 0, 255, resistance)]
            nodes = [fp32(source * resistance * (1 if reverse else -1))]
        tx = [packet(f'NB,{fid:04X},{len(elems):02X},{len(nodes):02X}')]
        tx.extend(packet(f'NC,{fid:04X},{j:02X},{k:02X},{a:02X},{b:02X},{v:03d},00')
                  for j, (k, a, b, v) in enumerate(elems))
        tx.append(packet(f'NE,{fid:04X},{len(elems):02X},{len(nodes):02X}'))
        rx = [packet(f'VB,{fid:04X},{len(nodes):02X},00')]
        rx.extend(packet(f'VN,{fid:04X},{j:02X},{v:08X}') for j, v in enumerate(nodes))
        rx.append(packet(f'VE,{fid:04X},{len(nodes):02X},00'))
        fixtures.append({'id': fid, 'mode': mode, 'elements': elems, 'nodes': nodes, 'tx': tx, 'rx': rx})
    return fixtures


def write_fixtures(out, extraction, solver):
    lines = []
    for f in extraction:
        lines.append(f'comp_type=8\'d{f["type"]}; comp_rot=2\'d{f["rotation"]}; comp_x=8\'d{f["x"]}; comp_y=8\'d{f["y"]};')
        lines.extend(f'cells[{j}]=16\'h{v:04x}; regions[{j}]=8\'h{f["regions"][j]:02x};' for j, v in enumerate(f['cells']))
        lines.append(f'run_fixture({f["id"]},8\'d{f["nodes"][0]},8\'d{f["nodes"][1]});')
    (out / 'M5SolverExtractionFixtures.svh').write_text('\n'.join(lines) + '\n')
    lines = []
    for f in solver:
        lines.extend(f'send_uart_line("{s}");' for s in f['tx'])
        lines.extend(f'expect_line("{s}");' for s in f['rx'])
    (out / 'M5SolverUartFixtures.svh').write_text('\n'.join(lines) + '\n')
    (out / 'fixtures.json').write_text(json.dumps({'extraction': extraction, 'solver': solver}, indent=2) + '\n')


def sources():
    design = ROOT / 'src/design'
    packages = sorted(design.rglob('*Pkg.sv')) + [TB / 'sim_models/Fp32SimPkg.sv']
    other = sorted(p for p in design.rglob('*') if p.suffix in ('.v', '.sv') and not p.name.endswith('Pkg.sv'))
    return packages + other + [TB / 'sim_models/FloatingPointIpModels.sv']


def command(cmd, cwd, log, timeout):
    start = time.monotonic()
    base = {'command': list(map(str, cmd)), 'cwd': str(cwd), 'log': str(log)}
    try:
        with log.open('w') as fh:
            process = subprocess.Popen(cmd, cwd=cwd, stdout=fh, stderr=subprocess.STDOUT,
                                       start_new_session=True)
            try:
                returncode = process.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                # This isolated process group belongs to this runner only.
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait()
                return {**base, 'returncode': None, 'timeout': timeout,
                        'owned_process_group_stopped': True}
        return {**base, 'returncode': returncode,
                'seconds': round(time.monotonic() - start, 3)}
    except OSError as error:
        log.write_text(str(error) + '\n')
        return {**base, 'returncode': None, 'error': str(error)}


def readiness(report):
    # Current runner intentionally has no route to promoting unvalidated FP.
    # Missing actual configured primitive characterization is always a blocker.
    blockers = ['configured floating-point primitive behavior/latency/exception characterization absent',
                'solver benches use nonqualified floating-point stand-ins (provisional evidence only)']
    for name, item in report.get('benches', {}).items():
        if not item.get('passed'):
            blockers.append(name + ': actual RTL regression failed or incomplete')
        if not item.get('negative_control_detected'):
            blockers.append(name + ': negative observation control missing or not detected')
    if len(report.get('benches', {})) != 3:
        blockers.append('all three extraction/UART/frontend benches are required')
    return {'ready': False, 'blockers': blockers}


def extraction_qualification(report, expected_cases):
    """Scoped generated-RTL evidence; unrelated faults and FP claims cannot pass."""
    item = report.get('benches', {}).get('M5SolverExtraction', {})
    version = {'native': '5.046', 'docker': '5.020'}.get(report.get('runtime'))
    return bool(version and 'Verilator ' + version + ' ' in report.get('tool_version', '')
        and report.get('tool', {}).get('returncode') == 0
        and report.get('source_drift') == []
        and item.get('passed') is True and item.get('negative_control_detected') is True
        and item.get('observed_cases') == expected_cases
        and type(item.get('stall_cycles')) is int and item['stall_cycles'] > 0)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, default=ROOT / 'golden/out/m5-solver/current')
    parser.add_argument('--seed', type=int, default=20261010)
    parser.add_argument('--extraction-cases', type=int, default=320)
    parser.add_argument('--solver-cases', type=int, default=36)
    parser.add_argument('--jobs', type=int, default=4)
    parser.add_argument('--timeout', type=int, default=180)
    parser.add_argument('--fixtures-only', action='store_true')
    parser.add_argument('--runtime', choices=('native', 'docker'), default='native')
    parser.add_argument('--extraction-only', action='store_true',
                        help='qualify actual generated extraction; no FP/solver stand-in acceptance')
    args = parser.parse_args()
    if args.solver_cases < 3 or args.extraction_cases < 1 or args.jobs < 1 or args.timeout < 1:
        parser.error('positive limits required; solver cases must be >=3')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    extraction, solver = extraction_fixtures(args.seed, args.extraction_cases), solver_fixtures(args.seed, args.solver_cases)
    write_fixtures(out, extraction, solver)
    src = sources()
    tracked = src + [TB / (n + '.sv') for n in ('M5SolverExtraction', 'M5SolverUart', 'M5SolverFrontend')]
    report = {'schema': 'metacircuit.m5-solver.v1', 'seed': args.seed, 'runtime': args.runtime,
              'fixture_counts': {'extraction': len(extraction), 'solver': len(solver)},
              'ip': {n: ip_configuration(ROOT / f'src/ip/floating_point_{n}/floating_point_{n}.xci') for n in ('fma', 'div')},
              'standins': {'fma_latency': 4, 'div_latency': 6, 'exceptions_modeled': False, 'validated': False},
              'source_sha256': {str(p.relative_to(ROOT)): sha256(p) for p in tracked},
              'fixture_sha256': sha256(out / 'fixtures.json'), 'benches': {}}
    tracked += [ROOT / "tools/verify_solver_m5.py", ROOT / "src/design/solver_board/bcd_unit_to_fp32_rom.mem"]
    report["source_sha256"] = {str(p.relative_to(ROOT)): sha256(p) for p in tracked}
    def execute(argv, cwd, log, timeout):
        cid = log.with_suffix('.cid')
        if args.runtime == 'docker':
            def translate(value):
                value = str(value)
                # Output takes precedence over its enclosing read-only source.
                for source, target in ((out, '/out'), (ROOT, '/source')):
                    value = value.replace(str(source) + '/', target + '/')
                    if value == str(source): value = target
                return value
            argv = ['docker', 'run', '--rm', '--cidfile', str(cid),
                    '-v', f'{ROOT}:/source:ro', '-v', f'{out}:/out',
                    '-w', translate(cwd), 'framescope-toolchain:6501155dc903',
                    *[translate(arg) for arg in argv]]
        result = command(argv, cwd, log, timeout)
        if args.runtime == 'docker' and cid.exists() and result.get('returncode') is None:
            subprocess.run(['docker', 'rm', '-f', cid.read_text().strip()], capture_output=True)
        return result
    report['tool'] = execute(['verilator', '--version'], ROOT, out / 'verilator-version.log', 10)
    report['tool_version'] = (out / 'verilator-version.log').read_text().strip()
    benches = [('M5SolverExtraction', 'CORRUPT_EXTRACTION')]
    if not args.extraction_only:
        benches += [('M5SolverUart', 'CORRUPT_SOLVER'), ('M5SolverFrontend', 'CORRUPT_FRONTEND')]
    for name, control in ([] if args.fixtures_only else benches):
        work = out / name
        work.mkdir(exist_ok=True)
        cmd = ['verilator', '--binary', '--timing', '-O2', '--top-module', name, '-Wno-fatal', '-Wno-MULTIDRIVEN', '-j', str(args.jobs), '--Mdir', str(work), '-I' + str(out), *map(str, src), str(TB / (name + '.sv'))]
        item = {'build': execute(cmd, ROOT, out / (name + '-build.log'), args.timeout), 'passed': False, 'negative_control_detected': False}
        if item['build']['returncode'] == 0:
            exe = str(work / ('V' + name))
            item['run'] = execute([exe], ROOT / 'src/design/solver_board', out / (name + '-run.log'), args.timeout)
            text = Path(item['run']['log']).read_text()
            item['passed'] = item['run']['returncode'] == 0 and name + ' passed.' in text
            item['negative'] = execute([exe, '+' + control], ROOT / 'src/design/solver_board', out / (name + '-negative.log'), args.timeout)
            negative_text = Path(item['negative']['log']).read_text()
            # A timeout or unrelated build/runtime failure never qualifies a fault control.
            item['negative_control_detected'] = item['negative']['returncode'] not in (0, None) and 'mismatch' in negative_text
            if name == 'M5SolverExtraction':
                item['negative_control_detected'] = (item['negative']['returncode'] not in (0, None)
                    and 'extraction mismatch case=0 ' in negative_text
                    and name + ' passed.' not in negative_text)
                item['observed_cases'] = len(re.findall(r'^EXTRACTION case=', text, re.M))
                item['stall_cycles'] = sum(map(int, re.findall(r'stalls=(\d+)', text)))
            elif name == 'M5SolverUart':
                item['observed_reply_lines'] = len(re.findall(r'^SOLVER_REPLY ', text, re.M))
        if name == 'M5SolverFrontend' and 'run' in item:
            item['accepted_events'] = re.findall(r'^FRONTEND .+$', Path(item['run']['log']).read_text(), re.M)
        report['benches'][name] = item
        print(name + ': ' + ('provisional PASS' if item['passed'] else 'FAIL'), flush=True)
    report['acceptance'] = readiness(report)
    report['source_drift'] = [str(p.relative_to(ROOT)) for p in tracked if sha256(p) != report['source_sha256'][str(p.relative_to(ROOT))]]
    if report['source_drift']:
        report['acceptance']['blockers'].append('sources changed during qualification: ' + ', '.join(report['source_drift']))
    report['extraction_qualified'] = bool(args.extraction_only and not args.fixtures_only
        and extraction_qualification(report, len(extraction)))
    report['extraction_scope'] = 'Actual generated extraction and seeded fixture/stall checks only; no FP or solver qualification.'
    report['artifact_sha256'] = {p.name: sha256(p) for p in out.glob('*.log')}
    report['artifact_sha256'].update({p.name: sha256(p) for p in out.glob('*.svh')})
    report_path = out / 'report.json'
    report_path.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'report': str(report_path), 'extraction_qualified': report['extraction_qualified'], **report['acceptance']}))
    return 0 if args.extraction_only and report['extraction_qualified'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
