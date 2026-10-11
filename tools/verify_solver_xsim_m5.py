#!/usr/bin/env python3
"""Run actual SolverBoard RTL+actual configured-parameter FP products in XSim."""
import argparse
import json
from pathlib import Path
import re
import shutil
from fractions import Fraction
import random
from verify_solver_m5 import ROOT, command, sha256, solver_fixtures, packet
from verify_fp_m5 import VIVADO, configuration_audit


def actual_sources(fma_override=None, solver_top=None):
    files = ['common/StampingCombPkg.sv', 'common/StampingNetlistStore.sv', 'common/SimpleRam.v',
             'matrix/SolverMatrixStore.sv', 'matrix/SolverVectorStore.sv',
             'floating_point/fpo_fma.v', 'floating_point/fpo_div.v',
             'solver/solve_core_dc.sv', 'solver_board/UartRx.v',
             'uart/UartTx.v', 'uart/Hex7SegMux.v',
             'solver_board/UartLineAssembler.sv', 'solver_board/UartPacketParser.sv',
             'solver_board/BcdUnitToFp32Rom.sv', 'solver_board/SolverDcPipeline.sv',
             'solver_board/SolverUartLineTransmitter.sv', 'solver_board/SolverBoard_top.sv']
    sources = [ROOT / 'src/design' / f for f in files] + [ROOT / 'src/testbench/M5SolverUartXsim.sv']
    if fma_override is not None:
        sources = [Path(fma_override).resolve() if p.name == 'fpo_fma.v' else p for p in sources]
    if solver_top is not None:
        sources = [Path(solver_top).resolve() if p.name == 'SolverBoard_top.sv' else p for p in sources]
    return sources


UNIT_SCALE = [Fraction(1), Fraction(1, 1000), Fraction(1, 10**6),
              Fraction(1, 10**9), Fraction(1000), Fraction(10**6), Fraction(10**9)]


def rational_mna(elements, node_count):
    """Exact physical MNA oracle, independent of RTL elimination/FP/ROM data."""
    voltages = [e for e in elements if e[0] == 3]
    dim = node_count + len(voltages)
    a = [[Fraction(0) for _ in range(dim + 1)] for _ in range(dim)]
    vi = node_count
    for kind, n0, n1, value, unit in elements:
        value = Fraction(value) * UNIT_SCALE[unit]
        ends = [(n, sign) for n, sign in ((n0, 1), (n1, -1)) if n != 255]
        if kind == 1:
            for n, sign in ends:
                for m, other in ends:
                    a[n][m] += sign * other / value
        elif kind == 2:
            for n, sign in ends:
                a[n][-1] -= sign * value
        elif kind == 3:
            for n, sign in ends:
                a[n][vi] += sign
                a[vi][n] += sign
            a[vi][-1] = value
            vi += 1
        else:
            raise ValueError('unsupported kind')
    # Gauss-Jordan with first nonzero pivot, intentionally independent of RTL LU.
    for col in range(dim):
        pivot = next((r for r in range(col, dim) if a[r][col]), None)
        if pivot is None:
            raise ValueError('singular physical circuit')
        a[col], a[pivot] = a[pivot], a[col]
        divisor = a[col][col]
        a[col] = [v / divisor for v in a[col]]
        for r in range(dim):
            if r != col:
                factor = a[r][col]
                a[r] = [v - factor * w for v, w in zip(a[r], a[col])]
    return [row[-1] for row in a[:node_count]]


def general_fixtures(seed, near_singular=False):
    rng = random.Random(seed)
    fixtures = []
    def add(label, node_count, elems):
        fid = 0x1000 + len(fixtures)
        values = rational_mna(elems, node_count)
        tx = [packet(f'NB,{fid:04X},{len(elems):02X},{node_count:02X}')]
        tx += [packet(f'NC,{fid:04X},{j:02X},{k:02X},{a:02X},{b:02X},{v:03d},{u:02X}')
               for j, (k, a, b, v, u) in enumerate(elems)]
        tx += [packet(f'NE,{fid:04X},{len(elems):02X},{node_count:02X}')]
        fixtures.append({'id': fid, 'label': label, 'node_count': node_count, 'elements': elems,
                         'expected_rational': [str(v) for v in values], 'tx': tx})
    for nodes in (3, 4, 6, 8):
        elems = [(3, 0, 255, rng.randrange(2, 20), 0)]
        elems += [(1, j, j+1, rng.randrange(1, 20), 0) for j in range(nodes-1)]
        elems += [(1, nodes-1, 255, rng.randrange(1, 20), 0),
                  (1, 0, nodes-1, rng.randrange(1, 20), 0),
                  (2, 255, nodes//2, 1, 1)]
        add(f'connected_bridge_{nodes}', nodes, elems)
    for unit in range(7):
        # Every scale is used for resistors/current/source across separate circuits.
        add(f'voltage_unit_{unit}', 3, [(3, 0, 255, 8, unit), (1, 0, 1, 4, 0),
                                     (1, 1, 2, 4, 0), (1, 2, 255, 8, 0)])
        add(f'resistor_current_unit_{unit}', 3,
            [(2, 255, 0, 1, unit), (1, 0, 255, 2, unit),
             (1, 0, 1, 4, unit), (1, 1, 2, 4, unit), (1, 2, 255, 8, unit)])
    # Inclusive element/node limits; combined MNA dimension remains at most32.
    add('capacity_32_elements_31_nodes', 31,
        [(3, 0, 255, 31, 0)] + [(1, j, j+1, 1, 0) for j in range(30)] + [(1, 30, 255, 1, 0)])
    add('capacity_32_nodes', 32, [(1, j, 255, 1, 0) for j in range(32)])
    add('bcd_999', 3, [(3, 0, 255, 999, 0), (1, 0, 1, 999, 0),
                      (1, 1, 2, 999, 0), (1, 2, 255, 999, 0)])
    if near_singular:
        add('near_singular_coupled_milli_vs999', 3, [(3, 0, 255, 1, 0),
             (1, 0, 1, 999, 0), (1, 1, 2, 1, 1), (1, 2, 255, 999, 0)])
    return fixtures


def write_fixtures(out, seed, count, near_singular=False):
    data = solver_fixtures(seed, count)
    lines = []
    for f in data:
        lines.extend(f'send_uart_line("{s}");' for s in f['tx'])
        lines.extend(f'expect_line("{s}");' for s in f['rx'])
    general = general_fixtures(seed, near_singular)
    for f in general:
        lines.append(f'$display("GENERAL_CASE {f["label"]}");')
        lines.extend(f'send_uart_line("{s}");' for s in f['tx'])
        lines.append(f'expect_line("{packet(f"VB,{f["id"]:04X},{f["node_count"]:02X},00")}");')
        for j, value in enumerate(f['expected_rational']):
            lines.append(f'expect_voltage("@VN,{f["id"]:04X},{j:02X},", {float(Fraction(value)):.17e});')
        lines.append(f'expect_line("{packet(f"VE,{f["id"]:04X},{f["node_count"]:02X},00")}");')
    boundaries = [('NB,FF20,21,01', 'ER,FF20,02,2101'),
                  ('NB,FF21,01,21', 'ER,FF21,02,0121')]
    for tx, rx in boundaries:
        lines += [f'send_uart_line("{packet(tx)}");', f'expect_line("{packet(rx)}");']
    bad = packet('NB,FF10,01,01')
    bad = bad[:-2] + f'{int(bad[-2:],16)^1:02X}'
    lines += [f'send_uart_line("{bad}");', f'expect_line("{packet("ER,FF10,01,0003")}");']
    # A clean transaction after parser error proves normal recovery.
    recovery = data[0]
    lines.extend(f'send_uart_line("{s}");' for s in recovery['tx'])
    lines.extend(f'expect_line("{s}");' for s in recovery['rx'])
    # Singular: current-only one-node circuit. No finite physical solution;
    # require actual primitive exception propagation and nonfinite node output.
    singular_tx = [packet('NB,FF30,01,01'), packet('NC,FF30,00,02,00,FF,001,00'), packet('NE,FF30,01,01')]
    lines.extend(f'send_uart_line("{s}");' for s in singular_tx)
    lines += [f'expect_line("{packet("VB,FF30,01,05")}");', 'expect_nonfinite("@VN,FF30,00,");',
              f'expect_line("{packet("VE,FF30,01,05")}");']
    (out / 'M5SolverUartFixtures.svh').write_text('\n'.join(lines) + '\n')
    fixture = {'analytical': data, 'general': general, 'boundaries': boundaries, 'bad_checksum': bad, 'recovery': recovery,
               'singular': {'tx': singular_tx, 'expected_status': 5, 'expected_node_class': 'nonfinite'}}
    (out / 'fixtures.json').write_text(json.dumps(fixture, indent=2) + '\n')
    return fixture


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', required=True, type=Path)
    parser.add_argument('--seed', type=int, default=20261010)
    parser.add_argument('--solver-cases', type=int, default=36)
    parser.add_argument('--include-near-singular', action='store_true', help='also probe ill-conditioned physical accuracy without relaxing tolerance')
    parser.add_argument('--timeout', type=int, default=600)
    parser.add_argument('--fma-wrapper', type=Path, help='explicit minimal-width candidate wrapper; hashed and audited')
    parser.add_argument('--solver-top', type=Path, help='explicit isolated SolverBoard_top candidate; production/effective paths and hashes recorded')
    parser.add_argument('--fp-report', type=Path, default=ROOT / 'golden/out/m5-fp/characterization-final-20261010/report.json')
    args = parser.parse_args()
    if args.solver_cases < 3 or args.timeout < 1:
        parser.error('solver-cases >=3 and positive timeout required')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    fixture = write_fixtures(out, args.seed, args.solver_cases, args.include_near_singular)
    audit = {n: configuration_audit(n) for n in ('fma', 'div')}
    sources = actual_sources(args.fma_wrapper,args.solver_top)
    overrides = {}
    if args.fma_wrapper is not None:
        original = ROOT / 'src/design/floating_point/fpo_fma.v'
        effective = args.fma_wrapper.resolve()
        expected = original.read_bytes().replace(b'wire [ 3:0] m_axis_result_tuser', b'wire [ 2:0] m_axis_result_tuser')
        valid_override = effective.read_bytes() == expected
        overrides['src/design/floating_point/fpo_fma.v'] = {
            'original': str(original), 'effective': str(effective),
            'original_sha256': sha256(original), 'effective_sha256': sha256(effective),
            'minimal_width_fix_verified': valid_override,
        }
        if not valid_override:
            parser.error('wrapper override must be exactly the original file with FMA tuser width3')
    original_top = ROOT / 'src/design/solver_board/SolverBoard_top.sv'
    if args.solver_top is not None:
        overrides['src/design/solver_board/SolverBoard_top.sv'] = {
            'original':str(original_top), 'effective':str(args.solver_top.resolve()),
            'original_sha256':sha256(original_top), 'effective_sha256':sha256(args.solver_top),
            'basis':'root-authorized isolated augmented-capacity guard candidate; production unchanged',
        }
    rom = ROOT / 'src/design/solver_board/bcd_unit_to_fp32_rom.mem'
    shutil.copyfile(rom, out / rom.name)
    fp = json.loads(args.fp_report.read_text())
    fp_valid = fp.get('characterization_passed') is True and all(fp.get('negative_controls', {}).values())
    fp_drift = [p for p, digest in fp.get('source_tool_library_sha256', {}).items()
                if not Path(p).is_file() or sha256(p) != digest]
    tracked = sources + [original_top, rom, Path(__file__)]
    pins = {str(p): sha256(p) for p in tracked}
    report = {'schema': 'metacircuit.m5-solver-xsim.v1', 'seed': args.seed,
              'fixture_count': len(fixture['analytical']), 'general_fixture_count': len(fixture['general']), 'fixture_sha256': sha256(out / 'fixtures.json'),
              'configuration_audit': audit, 'source_sha256': pins, 'source_overrides': overrides,
              'fp_characterization': {'path': str(args.fp_report.resolve()), 'sha256': sha256(args.fp_report),
                                      'valid': bool(fp_valid and not fp_drift), 'source_drift': fp_drift},
              'numeric_policy': {'relative_error': 0.0002, 'absolute_error': 1e-30, 'basis': 'new scoped empirical physical-accuracy bound, not a conditioning proof or frozen frontend expectation', 'near_singular_included': args.include_near_singular}, 'operations': {}}
    cmds = [('vhdl', [str(VIVADO / 'bin/xvhdl'), '--work', 'xil_defaultlib', *[a['product'] for a in audit.values()]]),
            ('sv', [str(VIVADO / 'bin/xvlog'), '--sv', '--work', 'xil_defaultlib', '-i', str(out), *map(str, sources)]),
            ('elaborate', [str(VIVADO / 'bin/xelab'), 'xil_defaultlib.M5SolverUartXsim', '-s', 'm5solver', '-L', 'floating_point_v7_1_21', '--timescale', '1ns/1ps', '-mt', '4']),
            ('run', [str(VIVADO / 'bin/xsim'), 'm5solver', '-runall']),
            ('negative_data', [str(VIVADO / 'bin/xsim'), 'm5solver', '-runall', '-testplusarg', 'CORRUPT_SOLVER']),
            ('negative_general', [str(VIVADO / 'bin/xsim'), 'm5solver', '-runall', '-testplusarg', 'CORRUPT_GENERAL'])]
    if fp_valid and not fp_drift and all(a['configuration_matches'] for a in audit.values()):
        for name, cmd in cmds:
            item = command(cmd, out, out / (name + '.log'), args.timeout)
            report['operations'][name] = item
            print(name, item['returncode'], flush=True)
            if item['returncode'] != 0 or re.search(r'^ERROR:', (out / (name + '.log')).read_text(), re.M):
                break
    text = (out / 'run.log').read_text() if (out / 'run.log').exists() else ''
    negative = (out / 'negative_data.log').read_text() if (out / 'negative_data.log').exists() else ''
    report['observed'] = {'reply_lines': len(re.findall('^SOLVER_REPLY ', text, re.M)),
                          'solve_events': re.findall(r'^ACTUAL_SOLVE .+$', text, re.M),
                          'parser_checksum_error_detected': packet('ER,FF10,01,0003') in text,
                          'singular_fp_exception_detected': packet('VB,FF30,01,05') in text}
    general_negative = (out / 'negative_general.log').read_text() if (out / 'negative_general.log').exists() else ''
    report['negative_general_detected'] = 'Fatal:' in general_negative and 'general voltage mismatch' in general_negative and 'M5SolverUartXsim passed.' not in general_negative
    report['observed']['general_cases'] = re.findall(r'^GENERAL_CASE (.+)$', text, re.M)
    report['observed']['capacity_rejections'] = [packet(rx) for tx, rx in fixture['boundaries'] if packet(rx) in text]
    report['negative_data_detected'] = 'Fatal:' in negative and ' mismatch expected ' in negative and 'M5SolverUartXsim passed.' not in negative
    report['source_drift'] = [p for p, digest in pins.items() if sha256(p) != digest]
    passed = ('M5SolverUartXsim passed.' in text and report['negative_data_detected']
              and report['negative_general_detected'] and report['fp_characterization']['valid'] and not report['source_drift'])
    for item in overrides.values():
        item['production_identity_matches_at_end'] = sha256(item['original']) == item['effective_sha256']
    report['scoped_actual_pipeline_passed'] = bool(passed)
    report['acceptance'] = {'full_m5_ready': False, 'original_xci_synthesis_qualified': False,
                            'scope': 'actual generated DC solver+actual rev21 configuration-equivalent IP; 1/2-node exact plus3/4/6/8/31/32-node independent rational MNA circuits',
                            'blockers': ['revision21products vs originalXCIrevision6 mismatch remains',
                                         'broader randomized/general-netlist and ill-conditioned accuracy/actual frontend scope incomplete']}
    report['artifact_sha256'] = {p.name: sha256(p) for p in out.glob('*.log')}
    report['artifact_sha256']['M5SolverUartFixtures.svh'] = sha256(out / 'M5SolverUartFixtures.svh')
    (out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'scoped_actual_pipeline_passed': passed, 'report': str(out / 'report.json'), 'observed': report['observed']}))
    return 0 if passed else 1


if __name__ == '__main__':
    raise SystemExit(main())
