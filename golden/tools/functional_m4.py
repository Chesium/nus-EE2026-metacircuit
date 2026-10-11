#!/usr/bin/env python3
"""Recalculate witnessed functional bins from complete passing lockstep runs."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

from verify_m4 import GOLDEN, functional_coverage, functional_union, read, write


def collect(directory):
    directory = Path(directory).resolve()
    summary = read(directory / 'summary.json')
    index = read(directory / 'reference/checkpoints.json')
    case = read(directory / 'case.json')
    canonical = read(directory / 'canonical.json')
    rtl_report = read(directory / 'rtl/report.json')
    frame_count = index.get('frameCount')
    if (type(frame_count) is not int or frame_count < 1
            or type(summary.get('frames_completed')) is not int
            or type(canonical.get('frameCount')) is not int
            or any(type(c.get('frame')) is not int or not 0 <= c['frame'] < frame_count
                   for c in index.get('checkpoints', []))):
        raise ValueError(f'{directory}: invalid frame or frame count')
    seed = case.get('seed')
    if (type(seed) is not int or not 1 <= seed <= 0x7fffffff or summary.get('seed') != seed
            or type(summary.get('seed')) is not int or summary.get('runtime') not in ('native', 'docker')):
        raise ValueError(f'{directory}: inconsistent seed or invalid runtime')
    if ('first_divergence' not in summary or summary['first_divergence'] is not None
            or summary.get('error') or summary.get('errors')):
        raise ValueError(f'{directory}: divergence or infrastructure error recorded')
    if (read(directory / 'scenario.json') != case['scenario'] or canonical['name'] != case['scenario']['name']
            or index['scenario'] != canonical['name'] or canonical['frameCount'] != index['frameCount']
            or len(canonical['frames']) != index['frameCount']):
        raise ValueError(f'{directory}: inconsistent scenario or frame count')
    frames = rtl_report.get('monitors', {}).get('vga', {}).get('frames', [])
    if (rtl_report.get('ok') is not True or any(type(f.get('index')) is not int for f in frames)
            or [f.get('index') for f in frames] != list(range(index['frameCount']))
            or not isinstance(rtl_report.get('stimulus'), list)
            or any(s.get('late') is not False for s in rtl_report['stimulus'])):
        raise ValueError(f'{directory}: incomplete simulation or late/missing stimulus evidence')
    verdicts = []
    for parent in summary.get('comparisons', []):
        checks = parent.get('checkpoints', [])
        if (parent.get('ok') is not True or parent.get('errors') != [] or not checks
                or parent.get('scenario') != canonical['name']
                or Path(parent.get('actual', '')).resolve() != directory / 'rtl'
                or parent.get('summary') != {'checkpoints': len(checks), 'passed': len(checks), 'failed': 0}
                or type(parent.get('frameCount')) is not int
                or parent.get('frameCount') != max(c['frame'] for c in checks) + 1
                or any(c.get('ok') is not True or c.get('differences') != [] for c in checks)):
            raise ValueError(f'{directory}: failing or inconsistent parent comparator evidence')
        verdicts.extend(checks)
    expected = [(c['label'], c['frame']) for c in index['checkpoints']]
    actual = [(c['label'], c['frame']) for c in verdicts]
    if (summary.get('ok') is not True or summary.get('frames_completed') != index['frameCount']
            or not expected or actual != expected or not all(c.get('ok') is True for c in verdicts)):
        raise ValueError(f'{directory}: incomplete or failing checkpoint evidence')
    if ([(c['label'], c['frame']) for c in canonical['checkpoints']] != expected
            or len(set(expected)) != len(expected)
            or len({c['label'] for c in index['checkpoints']}) != len(expected)):
        raise ValueError(f'{directory}: incomplete or duplicated canonical checkpoints')
    init = summary.get('initialization', {})
    if (init.get('seed') != case['seed'] or init.get('seed_explicit') is not True
            or init.get('rand_reset') != 2 or init.get('x_initial') != 'unique'
            or init.get('x_assign') != 'unique'):
        raise ValueError(f'{directory}: missing cold seeded initialization')
    # Re-read the actual memories/probes with the accepted comparator. Hashing
    # current files alone cannot establish that a saved PASS still applies.
    with tempfile.TemporaryDirectory(prefix='m4-functional-compare-') as tmp:
        output = Path(tmp) / 'comparison.json'
        with (Path(tmp) / 'comparison.log').open('w') as log:
            result = subprocess.run(['npm', 'run', 'golden', '--', 'compare', str(directory / 'rtl'),
                                     '--reference', str(directory / 'reference'), '-o', str(output)],
                                    cwd=GOLDEN, stdout=log, stderr=subprocess.STDOUT, timeout=120)
        repeated = read(output) if output.exists() else {}
        if (result.returncode != 0 or repeated.get('ok') is not True or repeated.get('errors') != []
                or [(c['label'], c['frame']) for c in repeated.get('checkpoints', [])] != expected
                or any(c.get('ok') is not True or c.get('differences') != [] for c in repeated.get('checkpoints', []))):
            raise ValueError(f'{directory}: accepted comparator rejected current evidence')
    coverage = functional_coverage(directory / 'reference', {'checkpoints': verdicts},
                                   case.get('blocks'), rtl=directory / 'rtl')
    for witness in coverage['witnesses'].values():
        witness['run'] = str(directory)
    files = [directory / name for name in ('summary.json', 'case.json', 'scenario.json', 'canonical.json',
                                            'stim.toml', 'rtl/report.json', 'reference/checkpoints.json')]
    files += [directory / 'reference' / c[key] for c in index['checkpoints'] for key in ('state', 'ram')]
    for entries in rtl_report['dumps'].values():
        for dump in entries:
            path = Path(dump['path'])
            files.append(path.resolve() if path.is_absolute() else (directory / 'rtl' / path).resolve())
    evidence = {'directory': str(directory), 'runtime': summary['runtime'], 'seed': case['seed'],
                'frames': index['frameCount'], 'checkpoints': len(expected),
                'sha256': {str(p.relative_to(directory)): hashlib.sha256(p.read_bytes()).hexdigest()
                           for p in files}, 'accepted_comparator_rechecked': True}
    return coverage, evidence


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('runs', type=Path, nargs='+')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    try:
        paths = [p.resolve() for p in args.runs]
        if len(set(paths)) != len(paths):
            raise ValueError('duplicate run directory')
        coverages, evidence = zip(*(collect(p) for p in paths))
        report = {**functional_union(list(coverages)), 'runs': list(evidence)}
        write(args.out, report)
        print(json.dumps({'reached': len(report['reached']), 'eligible': len(report['eligible']),
                          'uncovered': report['uncovered'], 'report': str(args.out)}))
        return 0
    except (OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired) as error:
        parser.exit(1, f'functional evidence rejected: {error}\n')


if __name__ == '__main__':
    raise SystemExit(main())
