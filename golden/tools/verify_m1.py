#!/usr/bin/env python3
"""Reproduce the M1 state regression using a sibling framescope checkout."""
import argparse
import datetime
import json
import os
from pathlib import Path
import subprocess
import sys


def main():
    golden = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime', choices=['native', 'docker', 'auto'], default='native')
    parser.add_argument('--framescope', type=Path, default=golden.parent.parent / 'framescope')
    parser.add_argument('--out', type=Path)
    parser.add_argument('--scenario', type=Path, default=Path('scenarios/m1_canvas_tools.json'))
    args = parser.parse_args()
    output = (args.out or golden / 'out' / 'm1' / (datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d-%H%M%S') + '-' + args.runtime)).resolve()
    output.mkdir(parents=True, exist_ok=False)
    reference = output / 'reference'
    stimulus = output / 'stim.toml'
    actual = output / 'rtl'
    npm = ['npm', 'run', 'golden', '--']
    scenario = args.scenario.resolve()
    subprocess.run(npm + ['run', str(scenario), '--out', str(reference)], cwd=golden, check=True)
    subprocess.run(npm + ['stim', str(scenario), '-o', str(stimulus)], cwd=golden, check=True)
    index = json.loads((reference / 'checkpoints.json').read_text())
    dumps = ','.join(str(c['frame']) for c in index['checkpoints'])
    command = ['uv', 'run', 'framescope', '--runtime', args.runtime, 'run', '-c', 'examples/metacircuit',
               '-n', str(index['frameCount']), '-s', str(stimulus), '--save', 'none', '--dump', dumps, '-o', str(actual)]
    env = {**os.environ, 'METACIRCUIT': str(golden.parent)}
    print(f"Simulating {index['frameCount']} frames with {args.runtime}; log: {output / 'simulation.log'}", flush=True)
    with (output / 'simulation.log').open('w') as log:
        simulation = subprocess.run(command, cwd=args.framescope.resolve(), env=env, stdout=log, stderr=subprocess.STDOUT)
    if simulation.returncode:
        print((output / 'simulation.log').read_text()[-8000:], file=sys.stderr)
        return simulation.returncode
    return subprocess.run(npm + ['compare', str(actual), '--reference', str(reference), '-o', str(output / 'state-compare.json')], cwd=golden).returncode


if __name__ == '__main__':
    sys.exit(main())
