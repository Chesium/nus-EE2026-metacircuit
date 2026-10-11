#!/usr/bin/env python3
"""Exhaustive two-state equivalence for fixed 18-column address arithmetic."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

REPO = Path(__file__).resolve().parents[1]
SOURCE = REPO / 'src/design/rendering/GlobalRender_top.v'
FROZEN = REPO / 'golden/verification/contracts/frontend-v1/payloads/src/design/rendering/GlobalRender_top.v'
TRUSTED_REFERENCE_SHA256 = '254c8842d72c6c4801ef015c8c3274687a970c8794f9d09e6d966ced42657a66'
BENCH = REPO / 'src/testbench/M5AddressEquivalence.sv'
IMAGE = 'framescope-toolchain:6501155dc903'
HELPERS = ('canvas_addr_to_i', 'canvas_addr_to_j', 'component_position_from_addr',
           'component_addr_from_position')


def extract_functions(source):
    for name, expected in (('CANVAS_GRID_W', '18'), ('CANVAS_GRID_H', '16')):
        found = re.findall(r'localparam\s+integer\s+' + name + r'\s*=\s*(\d+)\s*;', source)
        if found != [expected]:
            raise ValueError(f'unsupported or ambiguous {name}')
    if not re.search(r'localparam\s+integer\s+CANVAS_CELL_COUNT\s*=\s*CANVAS_GRID_W\s*\*\s*CANVAS_GRID_H\s*;', source):
        raise ValueError('unsupported cell count')
    if not re.search(r'localparam\s+integer\s+CANVAS_ADDR_W\s*=\s*\$clog2\(CANVAS_CELL_COUNT\)\s*;', source):
        raise ValueError('unsupported address width')
    functions = []
    for name in HELPERS:
        matches = re.findall(r'\bfunction\s+(?:\[[^\]]+\]\s+)?' + name + r'\s*;.*?\bendfunction\b', source, re.S)
        if len(matches) != 1:
            raise ValueError(f'missing or ambiguous helper {name}')
        functions.append(matches[0])
    return '\n'.join(functions)


def extract_reference(source):
    return '''module M5AddressReference(input wire [8:0] addr, input wire [8:0] candidate_position,
output wire [8:0] position, roundtrip, candidate_roundtrip, inverse,
output wire [4:0] col, output wire [3:0] row);
localparam integer CANVAS_GRID_W=18, CANVAS_GRID_H=16, CANVAS_ADDR_W=9;
''' + extract_functions(source) + '''
assign position = component_position_from_addr(addr);
assign col = canvas_addr_to_i(addr);
assign row = canvas_addr_to_j(addr);
assign roundtrip = component_addr_from_position(position);
assign candidate_roundtrip = component_addr_from_position(candidate_position);
assign inverse = component_addr_from_position(addr);
endmodule
'''


def extract_candidate(source):
    functions = extract_functions(source)
    for name in ('canvas_position_from_addr', 'decode_canvas_address'):
        dependency = re.findall(r'\bfunction\s+\[[^\]]+\]\s+' + name + r'\s*;.*?\bendfunction\b', source, re.S)
        if len(dependency) > 1:
            raise ValueError('ambiguous dependency ' + name)
        if dependency:
            functions += '\n' + dependency[0]
    return '''module M5AddressCandidateLive(input wire [8:0] addr,
output wire [8:0] position, inverse, output wire [4:0] col, output wire [3:0] row);
localparam integer CANVAS_GRID_W=18, CANVAS_GRID_H=16, CANVAS_ADDR_W=9;
''' + functions + '''
assign position = component_position_from_addr(addr);
assign col = canvas_addr_to_i(addr);
assign row = canvas_addr_to_j(addr);
assign inverse = component_addr_from_position(addr);
endmodule
'''


def accept_normal(log, code):
    rows = re.findall(r'M5_ADDRESS_EQUIVALENCE checks=(\d+) invalid_checks=(\d+) helpers=(\d+)', log)
    return bool(code == 0 and rows == [('512', '224', '4')]
                and 'M5AddressEquivalence_test passed.' in log and 'M5_ADDRESS_FAILURE' not in log)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime', choices=('native', 'docker'), required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--candidate-source', type=Path, help='Extract actual candidate helpers, otherwise test proposed bench helper')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    source_bytes = FROZEN.read_bytes()
    if hashlib.sha256(source_bytes).hexdigest() != TRUSTED_REFERENCE_SHA256:
        raise ValueError('frozen reference differs from trusted source identity')
    reference = extract_reference(source_bytes.decode())
    reference_path = out / 'reference.sv'
    reference_path.write_text(reference)
    candidate_path = args.candidate_source.resolve() if args.candidate_source else None
    candidate_bytes = candidate_path.read_bytes() if candidate_path else None
    candidate_generated = out / 'candidate.sv'
    if candidate_path:
        candidate_generated.write_text(extract_candidate(candidate_bytes.decode()))
    def path(p):
        if args.runtime == 'native': return str(p)
        if p.is_relative_to(out): return '/out/' + str(p.relative_to(out))
        return '/source/' + str(p.relative_to(REPO))
    def invoke(command, name):
        if args.runtime == 'docker':
            command = ['docker', 'run', '--rm', '-v', f'{REPO}:/source:ro', '-v', f'{out}:/out',
                       '-w', '/out', IMAGE] + command
        with (out / (name + '.log')).open('w') as log:
            try:
                return subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, timeout=180).returncode
            except (OSError, subprocess.TimeoutExpired) as exc:
                log.write('\nM5_ADDRESS_RUNNER_FAILURE ' + type(exc).__name__ + '\n')
                return 124
    version = invoke(['verilator', '--version'], 'tool')
    build = invoke(['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
                    '--top-module', 'M5AddressEquivalence_test', '--Mdir', path(out / 'build'),
                    path(reference_path), path(BENCH),
                    *(['+define+M5_USE_LIVE_ADDRESS_CANDIDATE', path(candidate_generated)] if candidate_path else [])], 'build')
    summary = {'schema_version': 1, 'ok': False, 'runtime': args.runtime,
               'source_sha256': hashlib.sha256(source_bytes).hexdigest(),
               'reference_source': str(FROZEN.relative_to(REPO)), 'reference_identity_pinned': True,
               'candidate_source': str(candidate_path) if candidate_path else 'proposed helper in bench',
               'candidate_source_sha256': hashlib.sha256(candidate_bytes).hexdigest() if candidate_path else None,
               'bench_sha256': hashlib.sha256(BENCH.read_bytes()).hexdigest(),
               'runner_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
               'reference_sha256': hashlib.sha256(reference.encode()).hexdigest(),
               'tool_version': (out / 'tool.log').read_text().strip(), 'tool_exit': version, 'build_exit': build,
               'scope': 'exhaustive combinational two-state equivalence, all 512 9-bit inputs, including 224 out-of-grid addresses; col/row/packed position and unchanged reverse-helper composition',
               'unsupported': ['four-state X/Z equivalence', 'whole design equivalence', 'measured area/timing improvement'] + ([] if candidate_path else ['actual production candidate integration']),
               'candidate': 'five compare/subtract stages: 288,144,72,36,18; preserve low four quotient bits and remainder'}
    if version == 0 and build == 0:
        binary = path(out / 'build/VM5AddressEquivalence_test')
        normal = invoke([binary], 'normal')
        negative = invoke([binary, '+m5-inject-address-corruption'], 'negative')
        log = (out / 'negative.log').read_text()
        caught = bool(negative != 0 and 'M5_ADDRESS_FAILURE addr=287 ' in log)
        summary.update(normal_exit=normal, negative_exit=negative, negative_detected=caught)
        summary['ok'] = accept_normal((out / 'normal.log').read_text(), normal) and caught
    summary['source_unchanged_during_run'] = FROZEN.read_bytes() == source_bytes and (not candidate_path or candidate_path.read_bytes() == candidate_bytes)
    summary['ok'] = summary['ok'] and summary['source_unchanged_during_run']
    (out / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    print(json.dumps({'ok': summary['ok'], 'summary': str(out / 'summary.json')}))
    return 0 if summary['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
