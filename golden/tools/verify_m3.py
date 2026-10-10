#!/usr/bin/env python3
"""Verify scenario state, UART netlists, simulated solver replies and voltage displays."""
import argparse
import datetime
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys


def main():
    golden = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime', choices=['native', 'docker', 'auto'], default='native')
    parser.add_argument('--framescope', type=Path, default=golden.parent.parent / 'framescope')
    parser.add_argument('--out', type=Path)
    parser.add_argument('--scenario', type=Path, action='append', help='repeat to run multiple scenarios; default all M3 scenarios')
    parser.add_argument('--actual', type=Path, help='compare existing capture (one scenario only)')
    args = parser.parse_args()
    scenarios = args.scenario or sorted((golden / 'scenarios').glob('m3_*.json'))
    if args.actual and len(scenarios) != 1:
        parser.error('--actual requires exactly one --scenario')
    output = (args.out or golden / 'out/m3' / (datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d-%H%M%S') + '-' + args.runtime)).resolve()
    output.mkdir(parents=True, exist_ok=False)
    results = []
    for path in scenarios:
        path = path.resolve()
        scenario = json.loads(path.read_text())
        folder = output / scenario['name']
        folder.mkdir()
        reference, stimulus = folder / 'reference', folder / 'stim.toml'
        actual = args.actual.resolve() if args.actual else folder / 'rtl'
        npm = ['npm', 'run', 'golden', '--']
        for command in (['run', str(path), '--out', str(reference)], ['stim', str(path), '-o', str(stimulus)], ['netlist', str(path), '--out', str(reference)]):
            subprocess.run(npm + command, cwd=golden, check=True, stdout=subprocess.DEVNULL)
        index = json.loads((reference / 'checkpoints.json').read_text())
        with stimulus.open('a') as stream:
            for button in scenario.get('m3', {}).get('buttons', []):
                stream.write(f"\n[[event]]\nframe = {button['frame']}\nline = 10\nset = {{ {button['input']} = {button['value']} }}\n")
        if not args.actual:
            host = shlex.join(['python3', str(golden / 'tools/m3_solver_host.py')] + (['--faults'] if scenario.get('m3', {}).get('faults') else []))
            command = ['uv', 'run', 'framescope', '--runtime', args.runtime, 'run', '-c', 'examples/metacircuit', '-n', str(index['frameCount']),
                       '-s', str(stimulus), '--set', 'SW=32', '--host', 'uart=' + host, '--save', 'none',
                       '--dump', ','.join(str(c['frame']) for c in index['checkpoints']), '-o', str(actual)]
            print(f"Simulating {scenario['name']}: {index['frameCount']} frames ({args.runtime}); {folder / 'simulation.log'}", flush=True)
            with (folder / 'simulation.log').open('w') as log:
                run = subprocess.run(command, cwd=args.framescope.resolve(), env={**os.environ, 'METACIRCUIT': str(golden.parent)}, stdout=log, stderr=subprocess.STDOUT)
            if run.returncode:
                print((folder / 'simulation.log').read_text()[-8000:], file=sys.stderr)
                return run.returncode
        state = subprocess.run(npm + ['compare', str(actual), '--reference', str(reference), '-o', str(folder / 'state-compare.json')], cwd=golden)
        backend = subprocess.run(['npx', 'tsx', 'tools/m3_compare.ts', str(path), str(actual), str(folder / 'backend-compare.json')], cwd=golden)
        result = dict(scenario=scenario['name'], runtime=args.runtime, ok=state.returncode == 0 and backend.returncode == 0,
                      frameCount=index['frameCount'], actual=str(actual), reference=str(reference),
                      state=json.loads((folder / 'state-compare.json').read_text()), backend=json.loads((folder / 'backend-compare.json').read_text()))
        (folder / 'summary.json').write_text(json.dumps(result, indent=2) + '\n')
        results.append(result)
    summary = dict(ok=all(r['ok'] for r in results), runtime=args.runtime, scenarios=results)
    (output / 'summary.json').write_text(json.dumps(summary, indent=2) + '\n')
    print(json.dumps(dict(ok=summary['ok'], summary=str(output / 'summary.json')), indent=2))
    return 0 if summary['ok'] else 1


if __name__ == '__main__':
    sys.exit(main())
