#!/usr/bin/env python3
"""Qualify scoped M5 controller/guard invariants; never claim global readiness."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

REPO = Path(__file__).resolve().parents[2]
IMAGE = 'framescope-toolchain:6501155dc903'
DELAYS = (1, 3, 9)
CHANNEL_FIELDS = ('stalled_reads', 'stalled_writes', 'accepted_reads', 'accepted_writes')
SCENARIO_FIELDS = ('settled_checks', 'commits', 'reads', 'replies', 'max_progress',
                   'directed_read_stall', 'directed_write_stall', 'response_delay')
NEGATIVES = {
    'request-corruption': 'guard.background stalled request changed',
    'commit-corruption': 'commit sequence mismatch',
    'map-corruption': 'settled map mismatch',
    'reply-loss': 'bounded progress/reply drain',
}


def runtime_path(p, runtime, out):
    """Output under the repo still maps to the writable /out mount."""
    if runtime == 'native':
        return str(p)
    if p.is_relative_to(out):
        return '/out/' + str(p.relative_to(out))
    return '/source/' + str(p.relative_to(REPO))


def evaluate_normal(log, exit_code, delay):
    """Require exercised channels and independent write/map/progress checks."""
    channel_rows = re.findall(r'M5_INVARIANT_CHANNEL (\S+) ' +
                              ' '.join(field + r'=(\d+)' for field in CHANNEL_FIELDS), log)
    channels = {row[0]: dict(zip(CHANNEL_FIELDS, map(int, row[1:]))) for row in channel_rows}
    scenario_rows = re.findall(r'M5_INVARIANT_SCENARIO ' +
                               ' '.join(field + r'=(\d+)' for field in SCENARIO_FIELDS), log)
    scenario = dict(zip(SCENARIO_FIELDS, map(int, scenario_rows[0]))) if len(scenario_rows) == 1 else {}
    ok = bool(exit_code == 0 and 'M5CanvasInvariants_test passed.' in log
              and 'M5_INVARIANT_FAILURE' not in log and len(channel_rows) == 2
              and set(channels) == {'guard.background', 'controller.request'}
              and all(all(count > 0 for count in row.values()) for row in channels.values())
              and scenario.get('settled_checks') == 42 and scenario.get('commits') == 16
              and scenario.get('reads') == scenario.get('replies') == 21
              and scenario.get('response_delay') == delay
              and 0 < scenario.get('max_progress', 0) <= 64 + 4 * delay
              and scenario.get('directed_read_stall', 0) > 0
              and scenario.get('directed_write_stall', 0) > 0)
    return {'ok': ok, 'exit': exit_code, 'channels': channels, 'scenario': scenario}


def evaluate_negative(log, exit_code, kind):
    # A crash or unrelated assertion is not successful negative qualification.
    return bool(exit_code != 0 and 'M5_INVARIANT_FAILURE ' + NEGATIVES[kind] in log
                and 'M5CanvasInvariants_test passed.' not in log)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime', choices=['native', 'docker'], default='native')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    sources = sorted((REPO / 'src/design/interaction').glob('*.v')) + [
        REPO / 'src/testbench/M5CanvasInvariants.sv']

    def invoke(argv, label, timeout=180):
        if args.runtime == 'docker':
            argv = ['docker', 'run', '--rm', '-v', f'{REPO}:/source:ro', '-v', f'{out}:/out',
                    '-w', '/out', IMAGE] + argv
        with (out / f'{label}.log').open('w') as log:
            try:
                return subprocess.run(argv, stdout=log, stderr=subprocess.STDOUT, timeout=timeout).returncode
            except subprocess.TimeoutExpired:
                log.write('\nM5_RUNNER_TIMEOUT\n')
                return 124
            except OSError as exc:
                log.write(f'M5_RUNNER_EXEC_FAILURE {type(exc).__name__}\n')
                return 127

    def path(p):
        return runtime_path(p, args.runtime, out)

    work = out / 'build'
    version_code = invoke(['verilator', '--version'], 'tool')
    build_code = invoke(['verilator', '--binary', '--timing', '--assert', '-Wno-fatal',
                         '--top-module', 'M5CanvasInvariants_test', '--Mdir', path(work),
                         *[path(p) for p in sources]], 'build')
    summary = {
        'schema_version': 2, 'ok': False, 'runtime': args.runtime,
        'tool_version': (out / 'tool.log').read_text().strip(),
        'source_hashes': {str(p.relative_to(REPO)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources},
        'runner_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'tool_exit': version_code, 'build_exit': build_code,
        'scope': 'directed controller/guard simulation only; safety monitors run every rising edge; map/component checks at each settled boundary',
        'qualified_checks': ['both channels: valid/address/write/meaningful write data stable across stalls',
                             'logical address bounds and local guard storage bounds',
                             'ordered exact committed write ledger: omissions/duplicates/rejections',
                             'all 288 settled cells and paired component layout',
                             'single outstanding read and drained read/reply conservation',
                             'directed simulation completion watchdog'],
        'assumptions': ['10ns clock and synchronous reset; zero initial logical memory',
                        'fixed sampled input frames, normally serialized through done+idle',
                        'one directed same-mode two-edit overlap: next edit only after controller_done while guard remains busy',
                        'one outstanding memory read; response delay 1/3/9 cycles after acceptance plus synchronous visibility',
                        'cycle%7 backpressure, directed 20-cycle memory holds and first background write held 12 cycles',
                        'watchdog 64+4*reply_delay clocks after release/start of settle; schedule-specific allowance, no architecture-wide bound'],
        'unsupported': ['formal proof/old-new equivalence', 'arbitrary stalls or architectural progress bound',
                        'global queues and independently stored production component maps',
                        'global/frame-visible reply or multiwrite atomicity', 'solver datapath/IP',
                        'all-frame invariants, PS/2 and CDC'],
        'negative_control': 'observation corruption or reply withholding in testbench only; production RTL unchanged',
    }
    if version_code == 0 and build_code == 0:
        binary = path(work / 'VM5CanvasInvariants_test')
        runs = {}
        for delay in DELAYS:
            label = f'normal-delay{delay}'
            code = invoke([binary, f'+m5-response-delay={delay}'], label)
            runs[str(delay)] = evaluate_normal((out / f'{label}.log').read_text(), code, delay)
        controls = {}
        for kind in NEGATIVES:
            label = 'negative-' + kind
            code = invoke([binary, '+m5-inject-' + kind], label)
            controls[kind] = {'exit': code, 'detected': evaluate_negative((out / f'{label}.log').read_text(), code, kind)}
        summary.update(runs=runs, negative_controls=controls)
        summary['ok'] = all(run['ok'] for run in runs.values()) and all(control['detected'] for control in controls.values())
    (out / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    print(json.dumps({'ok': summary['ok'], 'summary': str(out / 'summary.json')}))
    return 0 if summary['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
