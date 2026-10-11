#!/usr/bin/env python3
"""Characterize existing configuration-matched rev21 products; never upgrade IP."""
from __future__ import annotations
import argparse
from fractions import Fraction
import json
from pathlib import Path
import random
import re
import xml.etree.ElementTree as ET
from verify_solver_m5 import ROOT, command, sha256

VIVADO = Path('/opt/amd/2025.2/Vivado')
MANUAL = 'https://docs.amd.com/api/khub/documents/ym1A7qsltTGP_saZFTrikQ/content'


def power2(e):
    return Fraction(1 << e) if e >= 0 else Fraction(1, 1 << -e)


def unpack(word):
    sign = word >> 31
    exponent, fraction = (word >> 23) & 255, word & 0x7fffff
    if exponent == 255:
        return sign, 'nan' if fraction else 'inf', None
    if exponent == 0:  # PG060: denormalized inputs become signed zero.
        return sign, 'zero', Fraction(0)
    value = Fraction((1 << 23) + fraction) * power2(exponent - 150)
    return sign, 'normal', -value if sign else value


def rounded(value, zero_sign=0):
    if not value:
        return zero_sign << 31, 0
    sign = int(value < 0)
    value = abs(value)
    e = value.numerator.bit_length() - value.denominator.bit_length()
    if value < power2(e):
        e -= 1
    if e < -126:  # AMD pre-round denormal result flush rule.
        return sign << 31, 1
    scaled = value * power2(23 - e)
    q, remainder = divmod(scaled.numerator, scaled.denominator)
    doubled = remainder * 2
    if doubled > scaled.denominator or (doubled == scaled.denominator and q & 1):
        q += 1
    if q == 1 << 24:
        q >>= 1
        e += 1
    if e > 127:
        return (sign << 31) | 0x7f800000, 2
    return (sign << 31) | ((e + 127) << 23) | (q - (1 << 23)), 0


def reference_fma(a, b, c):
    sa, ka, va = unpack(a)
    sb, kb, vb = unpack(b)
    sc, kc, vc = unpack(c)
    invalid = (ka == 'inf' and kb == 'zero') or (ka == 'zero' and kb == 'inf')
    if invalid:
        return 0x7fc00000, 4
    if 'nan' in (ka, kb, kc):
        return 0x7fc00000, 0
    if ka == 'inf' or kb == 'inf':
        if kc == 'inf' and sc != (sa ^ sb):
            return 0x7fc00000, 4
        return ((sa ^ sb) << 31) | 0x7f800000, 0
    if kc == 'inf':
        return (sc << 31) | 0x7f800000, 0
    product = va * vb
    zero_sign = sa ^ sb if not product and not vc and sc == (sa ^ sb) else 0
    return rounded(product + vc, zero_sign)


def reference_div(a, b):
    sa, ka, va = unpack(a)
    sb, kb, vb = unpack(b)
    sign = sa ^ sb
    if 'nan' in (ka, kb):
        return 0x7fc00000, 0
    if (ka == kb == 'inf') or (ka == kb == 'zero'):
        return 0x7fc00000, 4
    if ka == 'inf':
        return (sign << 31) | 0x7f800000, 0
    if kb == 'inf' or ka == 'zero':
        return sign << 31, 0
    if kb == 'zero':
        return (sign << 31) | 0x7f800000, 8
    return rounded(va / vb, sign)


def fixtures(seed, random_cases):
    rng = random.Random(seed)
    fma = [
        (0x3f800000, 0x40000000, 0x40400000),  # exact5
        (0x3f800001, 0x3f7ffffe, 0xbf800000),  # fused cancellation
        (0x3f800000, 0x3f800000, 0x33800000),  # tie to even1
        (0x3f800001, 0x3f800000, 0x33800000),  # odd tie rounds up
        (0x7f7fffff, 0x40000000, 0),  # overflow
        (0x00800000, 0x3f000000, 0),  # underflow
        (0x00000001, 0x7f7fffff, 0x3f800000),  # denormal inputflush
        (0x80000001, 0x3f800000, 0x80000000),  # signeddenormal zero
        (0x80000000, 0x3f800000, 0x80000000),  # signedzero
        (0, 0x7f800000, 0),  # invalid0*inf
        (0x7f800000, 0x3f800000, 0xff800000),  # oppositeinf invalid
        (0x7fc12345, 0x3f800000, 0),  # quietNaN
        (0x7f812345, 0x3f800000, 0),  # signalingNaN treatedquiet
        (0x7f800000, 0x40000000, 0),  # infinity
        (0x3f800000, 0x3f800000, 0xbf800000),  # exactzero cancellation
    ]
    div = [
        (0x3f800000, 0x40000000), (0x3f800000, 0x40400000),
        (0x7f7fffff, 0x00800000), (0x00800000, 0x40000000),
        (0x3f800000, 0), (0xbf800000, 0),
        (0, 0), (0x7f800000, 0x7f800000),
        (0x7fc12345, 0x3f800000), (0x7f812345, 0x3f800000),
        (0x80000000, 0x3f800000), (0x00000001, 0x3f800000),
        (0x3f800000, 0x80000001), (0x3f800000, 0xff800000),
        (0xff800000, 0x3f800000),
    ]
    # Uniform normal operands across signs/exponents/mantissas include extreme
    # magnitude ratios, overflow, underflow and cancellation-sensitive cases.
    normal = lambda: (rng.randrange(2) << 31) | (rng.randrange(1, 255) << 23) | rng.getrandbits(23)
    fma.extend((normal(), normal(), normal()) for _ in range(random_cases))
    div.extend((normal(), normal()) for _ in range(random_cases))
    result = {}
    for name, operands, oracle in [('fma', fma, reference_fma), ('div', div, reference_div)]:
        result[name] = []
        for i, words in enumerate(operands):
            expected, flags = oracle(*words)
            result[name].append({'id': i, 'operands': words, 'expected': expected,
                                 'flags': flags, 'gap': rng.randrange(4) if i >= 15 else i % 3})
    return result


def configuration_audit(name):
    directory = ROOT / f'src/ip/floating_point_{name}'
    xci = directory / f'floating_point_{name}.xci'
    sim = directory / f'sim/floating_point_{name}.vhd'
    values = {}
    for element in ET.parse(xci).iter():
        if element.tag.endswith('configurableElementValue'):
            key = next(v for k, v in element.attrib.items() if k.endswith('referenceId'))
            values[key] = element.text or ''
    text = sim.read_text()
    maps = {k: v.strip().strip('"') for k, v in re.findall(r'\b(C_\w+)\s*=>\s*([^,\n]+)', text)}
    comparisons = {k: {'xci': values['MODELPARAM_VALUE.' + k], 'generated': v}
                   for k, v in maps.items() if 'MODELPARAM_VALUE.' + k in values}
    mismatches = {k: v for k, v in comparisons.items() if v['xci'] != v['generated']}
    missing = sorted(k[len('MODELPARAM_VALUE.'):] for k in values if k.startswith('MODELPARAM_VALUE.')
                     and k[len('MODELPARAM_VALUE.'):] not in maps)
    revision = re.search(r'IP Revision:\s*(\d+)', text)
    xci_revision = values.get('RUNTIME_PARAM.IPREVISION')
    return {'xci': str(xci), 'product': str(sim), 'comparisons': comparisons,
            'mismatches': mismatches, 'unmapped_model_parameters': missing,
            'generated_revision': int(revision.group(1)) if revision else None,
            'original_xci_revision': int(xci_revision) if xci_revision else None,
            'generated_generic_map': maps,
            'configuration_matches': not mismatches and not missing and len(comparisons) >= 70,
            'revision_identity_matches': False}


def write_fixtures(out, data):
    lines = []
    for name in ('fma', 'div'):
        for item in data[name]:
            args = [f"32'h{v:08x}" for v in item['operands']]
            expected = item['expected']
            lines.append(f'issue_{name}({",".join(args)},32\'h{expected:08x},4\'h{item["flags"]:x},{item["gap"]});')
        lines.append(f'@(negedge clk); {"fvalid" if name == "fma" else "dvalid"}=0;')
    (out / 'M5FpFixtures.svh').write_text('\n'.join(lines) + '\n')
    (out / 'fixtures.json').write_text(json.dumps(data, indent=2) + '\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--seed', type=int, default=20261010)
    parser.add_argument('--random-cases', type=int, default=512)
    parser.add_argument('--timeout', type=int, default=180)
    args = parser.parse_args()
    if not 1 <= args.random_cases <= 7000 or args.timeout < 1:
        parser.error('random-cases must be1..7000; timeout positive')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    data = fixtures(args.seed, args.random_cases)
    write_fixtures(out, data)
    audit = {n: configuration_audit(n) for n in ('fma', 'div')}
    paths = [Path(a['xci']) for a in audit.values()] + [Path(a['product']) for a in audit.values()]
    paths += [ROOT / 'src/testbench/M5FpCharacterization.sv', Path(__file__), ROOT / 'tools/verify_solver_m5.py']
    toolpaths = []
    for n in ('xvhdl', 'xvlog', 'xelab', 'xsim'):
        toolpaths += [VIVADO / 'bin' / n, VIVADO / 'bin/unwrapped/lnx64.o' / n]
    # Pin complete precompiled libraries used by elaboration, including FPGA
    # primitive semantics, rather than trusting a saved project simulation.
    library_dirs = [VIVADO / 'data/xsim/ip' / n for n in
                    ('floating_point_v7_1_21', 'xbip_utils_v3_0_15', 'axi_utils_v2_0_11',
                     'xbip_pipe_v3_0_11', 'mult_gen_v12_0_24')]
    library_dirs += [VIVADO / 'data/xsim/vhdl' / n for n in ('std', 'ieee', 'unisim')]
    paths += toolpaths + [VIVADO / 'data/xsim/xsim.ini']
    paths += [p for directory in library_dirs for p in directory.rglob('*') if p.is_file()]
    pins = {str(p): sha256(p) for p in paths if p.is_file()}
    report = {'schema': 'metacircuit.m5-fp.v1', 'seed': args.seed,
              'manual': MANUAL, 'oracle': 'exact rational binary32 fused/divide, nearest-even, PG060 denormal flush',
              'fixture_counts': {k: len(v) for k, v in data.items()},
              'fixture_sha256': sha256(out / 'fixtures.json'), 'configuration_audit': audit,
              'source_tool_library_sha256': pins, 'operations': {}}
    cmds = [
        ('vhdl', [str(VIVADO / 'bin/xvhdl'), '--work', 'xil_defaultlib', *[a['product'] for a in audit.values()]]),
        ('sv', [str(VIVADO / 'bin/xvlog'), '--sv', '--work', 'xil_defaultlib', '-i', str(out), str(ROOT / 'src/testbench/M5FpCharacterization.sv')]),
        ('elaborate', [str(VIVADO / 'bin/xelab'), 'xil_defaultlib.M5FpCharacterization', '-s', 'm5fp', '-L', 'floating_point_v7_1_21', '--timescale', '1ns/1ps', '-mt', '4']),
        ('run', [str(VIVADO / 'bin/xsim'), 'm5fp', '-runall']),
        ('negative_latency', [str(VIVADO / 'bin/xsim'), 'm5fp', '-runall', '-testplusarg', 'CORRUPT_LATENCY']),
        ('negative_div_latency', [str(VIVADO / 'bin/xsim'), 'm5fp', '-runall', '-testplusarg', 'CORRUPT_DIV_LATENCY']),
        ('negative_data', [str(VIVADO / 'bin/xsim'), 'm5fp', '-runall', '-testplusarg', 'CORRUPT_FP_DATA']),
        ('negative_flags', [str(VIVADO / 'bin/xsim'), 'm5fp', '-runall', '-testplusarg', 'CORRUPT_FP_FLAGS']),
    ]
    for name, cmd in cmds:
        item = command(cmd, out, out / (name + '.log'), args.timeout)
        report['operations'][name] = item
        print(name, item['returncode'], flush=True)
        if item['returncode'] != 0 and not name.startswith('negative'):
            break
        if re.search(r'^ERROR:', (out / (name + '.log')).read_text(), re.M):
            break
    text = (out / 'run.log').read_text() if (out / 'run.log').exists() else ''
    negative = (out / 'negative_latency.log').read_text() if (out / 'negative_latency.log').exists() else ''
    fma_observed = re.findall(r'^FP_FMA case=\d+ result=([0-9a-fA-F]+) flags=([0-9a-fA-F]+) latency=(\d+)', text, re.M)
    div_observed = re.findall(r'^FP_DIV case=\d+ result=([0-9a-fA-F]+) flags=([0-9a-fA-F]+) latency=(\d+)', text, re.M)
    complete = len(fma_observed) == len(data['fma']) and len(div_observed) == len(data['div'])
    negative_detected = 'FMA mismatch case=0' in negative and 'expectedlatency=17' in negative and 'M5FpCharacterization passed' not in negative
    report['observed'] = {'fma_cases': len(fma_observed), 'div_cases': len(div_observed),
                          'fma_latencies': sorted({int(v[2]) for v in fma_observed}),
                          'div_latencies': sorted({int(v[2]) for v in div_observed})}
    report['negative_latency_detected'] = negative_detected
    report['negative_controls'] = {}
    for control, witness in [('negative_latency', 'expectedlatency=17'), ('negative_div_latency', 'expectedlatency=29'), ('negative_data', 'result=40a00001 expected=40a00000'), ('negative_flags', 'flags=1 expectedflags=0')]:
        p = out / (control + '.log')
        t = p.read_text() if p.exists() else ''
        report['negative_controls'][control] = bool(witness in t and 'Fatal:' in t and ' mismatch case=0' in t and 'M5FpCharacterization passed' not in t)
    report['source_drift'] = [str(p) for p in paths if p.is_file() and sha256(p) != pins[str(p)]]
    passed = complete and 'M5FpCharacterization passed' in text and all(report['negative_controls'].values()) and not report['source_drift']
    passed = passed and all(a['configuration_matches'] for a in audit.values())
    report['characterization_passed'] = bool(passed)
    report['acceptance'] = {'original_xci_synthesis_qualified': False,
                            'standins_validated': False,
                            'scope': 'existing config-equivalent revision21 simulation products only',
                            'blockers': ['generated product rev21 vs original XCIrev6 identity mismatch',
                                         'existing stand-ins have latency4/6 and omit exception/denormal behavior']}
    report['artifact_sha256'] = {p.name: sha256(p) for p in out.glob('*.log')}
    report['artifact_sha256']['M5FpFixtures.svh'] = sha256(out / 'M5FpFixtures.svh')
    (out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'characterization_passed': passed, 'report': str(out / 'report.json'), **report['observed']}))
    return 0 if passed else 1


if __name__ == '__main__':
    raise SystemExit(main())
