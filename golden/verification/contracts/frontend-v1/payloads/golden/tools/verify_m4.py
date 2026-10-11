#!/usr/bin/env python3
"""Cold-boot seeded RTL stress with replay artifacts and bounded failure reduction."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

GOLDEN = Path(__file__).resolve().parents[1]
REPO = GOLDEN.parent


def read(path):
    return json.loads(Path(path).read_text())


def write(path, value):
    Path(path).write_text(json.dumps(value, indent=2) + '\n')


def run_command(command, cwd, log, env=None):
    with Path(log).open('w') as stream:
        return subprocess.run(command, cwd=cwd, env=env, stdout=stream,
                              stderr=subprocess.STDOUT).returncode


def provenance(root):
    result = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=root,
                            text=True, capture_output=True, check=True)
    return {'path': str(root), 'head': result.stdout.strip(),
            'dirty': bool(subprocess.run(['git', 'status', '--porcelain'], cwd=root,
                                        text=True, capture_output=True, check=True).stdout)}


def prepare_manifest(framescope, output, coverage):
    """Preserve example-relative stub paths when moving the manifest to artifacts."""
    example = framescope / 'examples/metacircuit'
    text = (example / 'framescope.toml').read_text()
    stubs = sorted((example / 'stubs').glob('*.sv'))
    if not stubs:
        raise ValueError('no simulation mouse stubs found')
    text = text.replace('"stubs/*.sv"', ', '.join(json.dumps(str(p)) for p in stubs))
    # Existing example has no [build]; fail closed if this assumption changes.
    if '[build]' in text:
        raise ValueError('example [build] changed; update M4 manifest adapter')
    text += '\n[build]\n'
    text += 'work_dir = ' + json.dumps(str(framescope / '.framescope-m4')) + '\n'
    text += 'x_initial = "unique"\nx_assign = "unique"\n'
    if coverage:
        text += 'coverage = true\n'
    target = output / 'framescope.toml'
    target.write_text(text)
    return target


def evaluate(case_path, target, args, config):
    target.mkdir(parents=True, exist_ok=False)
    case = read(case_path)
    scenario = target / 'scenario.json'
    write(scenario, case['scenario'])
    reference = target / 'reference'
    stimulus = target / 'stim.toml'
    npm = ['npm', 'run', 'golden', '--']
    for name, command in [
        ('reference', npm + ['run', str(scenario), '--out', str(reference)]),
        ('stimulus', npm + ['stim', str(scenario), '-o', str(stimulus)]),
    ]:
        if run_command(command, GOLDEN, target / f'{name}.log'):
            return {'ok': False, 'kind': 'reference_error', 'directory': str(target)}
    index = read(reference / 'checkpoints.json')
    command = ['uv', 'run', 'framescope', '--runtime', args.runtime, 'run',
               '-c', str(config), '-n', str(index['frameCount']), '-s', str(stimulus),
               '--seed', str(case['seed']), '--save', 'none', '--dump',
               ','.join(str(c['frame']) for c in index['checkpoints']), '-o', str(target / 'rtl')]
    if args.coverage:
        command += ['--coverage-from', '3']
    env = {**os.environ, 'METACIRCUIT': str(REPO)}
    print(f"seed {case['seed']}: {index['frameCount']} cold RTL frames -> {target}", flush=True)
    code = run_command(command, args.framescope, target / 'simulation.log', env)
    if code:
        return {'ok': False, 'kind': 'simulation_error', 'exit_code': code, 'directory': str(target)}
    compare_path = target / 'state-compare.json'
    code = run_command(npm + ['compare', str(target / 'rtl'), '--reference', str(reference),
                             '-o', str(compare_path)], GOLDEN, target / 'comparison.log')
    comparison = read(compare_path) if compare_path.exists() else None
    if comparison is None:
        return {'ok': False, 'kind': 'comparison_error', 'directory': str(target)}
    first = next((c for c in comparison['checkpoints'] if not c['ok']), None)
    result = {'ok': code == 0 and comparison['ok'], 'kind': 'state', 'directory': str(target),
              'seed': case['seed'], 'frames': index['frameCount'], 'checks': comparison['summary'],
              'first_divergence': first, 'errors': comparison['errors'],
              'scenario_sha256': hashlib.sha256(scenario.read_bytes()).hexdigest()}
    report = read(target / 'rtl/report.json')
    result['initialization'] = report.get('sim', {}).get('initialization')
    result['coverage'] = report.get('coverage')
    # Startup qualification must prove the requested initialization was applied.
    initialization = result['initialization'] or {}
    if (initialization.get('seed') != case['seed'] or initialization.get('x_initial') != 'unique'
            or initialization.get('rand_reset') != 2):
        result['ok'] = False
        result['errors'].append('missing or incompatible seeded-initialization provenance')
    if args.coverage:
        coverage = result['coverage'] or {}
        if not coverage.get('complete') or coverage.get('boundary', {}).get('frame') != 3:
            result['ok'] = False
            result['errors'].append('missing/incomplete boot-scenario coverage split')
        for scope in ('boot', 'scenario'):
            artifact = coverage.get('artifacts', {}).get(scope, {})
            path = Path(artifact.get('path', ''))
            if not path.is_absolute():
                path = target / 'rtl' / path
            if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != artifact.get('sha256'):
                result['ok'] = False
                result['errors'].append(f'missing or stale {scope} coverage artifact')
    result['functional_coverage'] = functional_coverage(reference, comparison, case.get('blocks'), rtl=target / 'rtl')
    if first:
        frames = report['monitors']['vga']['frames']
        trace = [f for f in frames if first['frame'] - 3 <= f['index'] <= first['frame']]
        write(target / 'first-divergence.json', {**first, 'trace_window': trace,
                                               'seed': case['seed'], 'scenario': str(scenario)})
    write(target / 'result.json', result)
    return result


PLACE_TOOLS = {'wire', 'ground', 'resistor', 'inductor', 'capacitor', 'voltage', 'current'}
COMPONENT_KINDS = ['resistor', 'inductor', 'capacitor', 'voltage', 'current']


def functional_coverage(reference, comparison, blocks=None, rtl=None):
    """Count verified endpoint states and edits, retaining an auditable first witness.

    M1 ignores physical slots; slot reuse therefore additionally needs actual RTL
    component-store dumps. UI selection is not part of the accepted comparator.
    Input-dependent bins use visible clicks under the verified endpoint pan and
    are withheld for blocks containing a drag (whose intermediate pan is unknown).
    """
    reference = Path(reference)
    index = read(reference / 'checkpoints.json')
    eligible = {f'tool:{t}' for t in ['pan', 'wire', 'ground', *COMPONENT_KINDS, 'rotate', 'delete']}
    eligible |= {f'component:{k}:rotation:{r}' for k in COMPONENT_KINDS for r in range(4)}
    eligible |= {f'component:unit:{u}' for u in range(7)}
    eligible |= {f'edge:{e}' for e in ['left', 'right', 'top', 'bottom']}
    eligible |= {f'edit:placed:{k}' for k in COMPONENT_KINDS}
    eligible |= {'edit:deleted_component', 'edit:rotated_component', 'edit:slot_reuse',
                 'edit:placed_cell', 'edit:rotated_cell', 'edit:deleted_cell',
                 'edit:blocked_placement', 'edit:boundary_blocked', 'edit:capacity_blocked',
                 'edit:property_value', 'edit:property_unit', 'edit:property_from_partner',
                 'input:held_click', 'input:partner_half', 'store:empty', 'canvas:empty',
                 'canvas:dense', 'canvas:full'}
    witnesses = {}
    observed = {}
    for c in comparison['checkpoints']:
        if c['label'] in observed:
            raise ValueError('duplicate comparison checkpoint: ' + c['label'])
        observed[c['label']] = c
    if len({c['label'] for c in index['checkpoints']}) != len(index['checkpoints']):
        raise ValueError('duplicate reference checkpoint label')
    rtl_report = read(Path(rtl) / 'report.json') if rtl is not None else None
    assumptions = []
    assumed = [0, 0]
    for block in blocks or []:
        assumptions.append(list(assumed))
        for step in block:
            if step.get('op') == 'assume_pan':
                assumed = [step['x'], step['y']]
    previous = None
    previous_slots = None
    freed = set()
    for c in index['checkpoints']:
        verdict = observed.get(c['label'])
        if (not verdict or verdict.get('ok') is not True
                or (verdict.get('frame') is not None and verdict['frame'] != c.get('frame'))):
            previous = previous_slots = None
            freed.clear()
            continue
        state = read(reference / c['state'])
        def hit(name, reason):
            if name in eligible:
                witnesses.setdefault(name, {'checkpoint': c['label'], 'frame': c.get('frame', state.get('frame')),
                                            'reason': reason})
        hit('tool:' + state['tool'], 'verified selected tool')
        for component in state['components']:
            hit(f"component:{component['kind']}:rotation:{component['rotation']}", 'verified component orientation')
            hit(f"component:unit:{component.get('unit')}", 'verified component and per-cell unit memories')
        for cell in state['cells']:
            if cell['col'] == 0: hit('edge:left', 'occupied logical edge')
            if cell['col'] == 17: hit('edge:right', 'occupied logical edge')
            if cell['row'] == 0: hit('edge:top', 'occupied logical edge')
            if cell['row'] == 15: hit('edge:bottom', 'occupied logical edge')
        if not state['components']: hit('store:empty', 'zero verified component count')
        occupied = {(x['col'], x['row']) for x in state['cells']}
        if not occupied: hit('canvas:empty', 'zero occupied logical cells')
        if len(occupied) >= 144: hit('canvas:dense', 'at least half of 288 logical cells occupied')
        if len(occupied) == 288: hit('canvas:full', 'all 288 logical cells occupied')
        slots = None
        if rtl_report is not None:
            # Only slots < verified component_count are live; seeded tail RAM is random/stale.
            name = index['names']['componentStore']
            dumps = [d for d in rtl_report['dumps'][name] if d['frame'] == c['frame']]
            if len(dumps) != 1:
                raise ValueError('expected one actual component-store dump at passing checkpoint')
            path = Path(dumps[0]['path'])
            dump = read(path if path.is_absolute() else Path(rtl) / path)
            if (dump['frame'] != c['frame'] or dump['width'] != 40 or dump['depth'] != 288
                    or len(dump['words']) != 288):
                raise ValueError('invalid actual component-store dump')
            slots = {i: (int(w, 16) & 31, (int(w, 16) >> 5) & 15)
                     for i, w in enumerate(dump['words'][:len(state['components'])])}
            if set(slots.values()) != {(x['col'], x['row']) for x in state['components']}:
                raise ValueError('actual component-store anchors differ from passing reference')
        block = None
        clicks = []
        if blocks is not None and c['label'].startswith('operation_'):
            suffix = c['label'].removeprefix('operation_')
            i = int(suffix) if suffix.isdecimal() else -1
            if 0 <= i < len(blocks):
                block = blocks[i]
                if previous is not None and not any(s.get('op') == 'drag' for s in block):
                    assumed = assumptions[i]
                    pan = previous.get('pan', {'x': 0, 'y': 0})
                    click_tool = previous['tool']
                    for step in block:
                        if step.get('op') == 'assume_pan': assumed = [step['x'], step['y']]
                        if step.get('op') == 'click_tool': click_tool = step['tool']
                        if step.get('op') != 'click_cell' or step.get('button', 'left') != 'left': continue
                        if 'screen' in step:
                            x, y = step['screen']
                        elif 'cell' in step:
                            cp = step.get('pan', assumed)
                            x, y = 80 + 32 * step['cell'][0] + cp[0], 80 + 32 * step['cell'][1] + cp[1]
                        else: continue
                        if 64 <= x < 640 and 64 <= y < 352:
                            clicks.append(((int((x - 64 - pan['x']) // 32), int((y - 64 - pan['y']) // 32)),
                                           {**step, 'active_tool': click_tool}))
        if any(s.get('hold', 1) > 1 for _, s in clicks): hit('input:held_click', 'visible held left canvas click')
        if previous is not None:
            # Semantic identity follows anchors, since the oracle deliberately ignores slots.
            before = {(x.get('col', x['slot']), x.get('row', -1)): x for x in previous['components']}
            after = {(x.get('col', x['slot']), x.get('row', -1)): x for x in state['components']}
            partner_slots = set()
            for anchor, component in before.items():
                halves = component.get('cells', [])
                if len(halves) == 2 and any(key == (halves[1]['col'], halves[1]['row']) for key, _ in clicks):
                    hit('input:partner_half', 'visible click on verified prior component partner half; UI selection not checked')
                    partner_slots.add(anchor)
            for anchor, component in after.items():
                old = before.get(anchor)
                if old is None or old['kind'] != component['kind']:
                    hit('edit:placed:' + component['kind'], 'new component between consecutive passing endpoints')
                    if slots is not None and any(slot in freed and pos == anchor for slot, pos in slots.items()):
                        hit('edit:slot_reuse', 'new anchor occupies an actual RTL slot freed at an earlier passing endpoint')
                else:
                    if old['rotation'] != component['rotation']: hit('edit:rotated_component', 'verified component orientation changed')
                    changed = False
                    for field, name in [('valueBcd', 'value'), ('unit', 'unit')]:
                        if old.get(field) != component.get(field):
                            hit('edit:property_' + name, 'verified component property memory changed')
                            changed = True
                    if changed and anchor in partner_slots: hit('edit:property_from_partner', 'partner-half click followed by verified property change on same component')
            if before.keys() - after.keys(): hit('edit:deleted_component', 'prior anchor absent at next passing endpoint')
            if slots is not None and previous_slots is not None:
                freed |= previous_slots.keys() - slots.keys()
                freed -= slots.keys()
            cells_before = {(x['col'], x['row']): x for x in previous['cells'] if x.get('componentSlot') is None}
            cells_after = {(x['col'], x['row']): x for x in state['cells'] if x.get('componentSlot') is None}
            for key, cell in cells_after.items():
                old = cells_before.get(key)
                if old is None: hit('edit:placed_cell', 'new noncomponent cell')
                elif old['sprite'] == cell['sprite'] and old['rotation'] != cell['rotation']:
                    hit('edit:rotated_cell', 'verified noncomponent orientation changed')
            if cells_before.keys() - cells_after.keys(): hit('edit:deleted_cell', 'prior noncomponent cell absent')
            if (clicks and previous['cells'] == state['cells']
                    and previous['components'] == state['components']):
                prior_occupied = {(x['col'], x['row']) for x in previous['cells']}
                protected = {(x['col'], x['row']) for x in previous['cells'] if x.get('componentSlot') is not None}
                for key, step in clicks:
                    tool = step['active_tool']
                    if tool not in PLACE_TOOLS: continue
                    boundary = tool in COMPONENT_KINDS and key[0] == 17
                    # A-008 permits repainting noncomponent cells. Same-sprite
                    # repaint is idempotent, not a blocked collision witness.
                    collision = (key in prior_occupied or (key[0] + 1, key[1]) in prior_occupied
                                 if tool in COMPONENT_KINDS else key in protected)
                    if boundary or collision:
                        hit('edit:blocked_placement', 'visible placement attempt with boundary/component protection and unchanged endpoint memories')
                        if boundary: hit('edit:boundary_blocked', 'two-cell placement attempted on right logical edge')
                        if len(prior_occupied) == 288 and tool in COMPONENT_KINDS:
                            hit('edit:capacity_blocked', 'two-cell placement attempt while all 288 logical cells occupied')
        previous, previous_slots = state, slots
    reached = set(witnesses)
    return {'schema_version': 2,
            'evidence': 'passing RTL settled checkpoints decoded by accepted golden comparator; edits require consecutive passing endpoints; physical slot reuse additionally uses actual RTL dumps',
            'eligible': sorted(eligible), 'reached': sorted(reached), 'uncovered': sorted(eligible - reached),
            'witnesses': witnesses,
            'definitions': {'canvas:dense': '>=144 occupied logical cells (50% of canvas)',
                            'canvas:full': '288 occupied logical cells; at most 144 two-cell components',
                            'input:partner_half': 'input target on prior verified partner; does not qualify UI selection',
                            'edit:capacity_blocked': 'canvas occupancy limit, not physical component-store exhaustion'},
            'excluded': {'solver/UART/stalls/PS2': 'outside settled canvas scope; M5/FS-10 required',
                         'physical component-store exhaustion': '288 store slots exceed the 144 two-cell logical canvas limit',
                         'property UI selection/text/caret': 'M1 comparator verifies property RAM but not selection or panel probes/pixels',
                         'transient state timing': 'settled checkpoints only; continuous invariants remain M5-4'}}


def functional_union(coverages):
    """Union compatible recalculated reports; reject unexplained or incompatible bins."""
    if not coverages:
        raise ValueError('no functional coverage reports')
    first = coverages[0]
    eligible = set(first['eligible'])
    reached = set()
    witnesses = {}
    for report in coverages:
        if (report.get('schema_version') != first.get('schema_version') or set(report['eligible']) != eligible
                or report['excluded'] != first['excluded'] or report.get('definitions') != first.get('definitions')):
            raise ValueError('incompatible functional coverage scope')
        hits = set(report['reached'])
        if hits - eligible or set(report['uncovered']) != eligible - hits:
            raise ValueError('invalid functional coverage partition')
        if hits != set(report.get('witnesses', {})):
            raise ValueError('missing functional bin witnesses')
        reached |= hits
        for name, witness in report['witnesses'].items(): witnesses.setdefault(name, witness)
    return {**first, 'reached': sorted(reached), 'uncovered': sorted(eligible - reached), 'witnesses': witnesses}

def reduce_failure(case_path, initial, output, args, config):
    """Bounded single-block deletion; preserves the first difference class and cold-replays."""
    current = read(case_path)
    witness = initial['first_divergence']['differences'][0].split(' is ')[0]
    attempts = 0
    position = 0
    while position < len(current['blocks']) and attempts < args.reduce_runs:
        keep = [i for i in range(len(current['blocks'])) if i != position]
        candidate = output / f'reduce-{attempts}.json'
        command = ['npx', 'tsx', 'src/cli/stress.ts', '--source', str(case_path),
                   '--keep', ','.join(map(str, keep)), '--out', str(candidate)]
        if run_command(command, GOLDEN, output / 'reducer.log'):
            break
        result = evaluate(candidate, output / f'reduce-{attempts}', args, config)
        attempts += 1
        first = result.get('first_divergence')
        if first and any(d.split(' is ')[0] == witness for d in first['differences']):
            current = read(candidate)
            case_path = candidate
        else:
            position += 1
    reduced = output / 'reduced.json'
    write(reduced, current)
    # This is a separate cold run, never a checkpoint restore.
    replay = evaluate(reduced, output / 'reduced-cold-replay', args, config)
    reproduced = bool(replay.get('first_divergence') and any(
        d.split(' is ')[0] == witness for d in replay['first_divergence']['differences']))
    return {'attempts': attempts, 'blocks': len(current['blocks']),
            'cold_reproduced': reproduced, 'case': str(reduced), 'replay': replay}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--framescope', type=Path, default=REPO.parent / 'framescope')
    parser.add_argument('--runtime', choices=['native', 'docker'], default='native')
    parser.add_argument('--seeds', default='1,7,2026')
    parser.add_argument('--operations', type=int, default=16)
    parser.add_argument('--generator', type=int, choices=[1, 2], default=1, help='stress generator version')
    parser.add_argument('--coverage', action='store_true')
    parser.add_argument('--reduce-runs', type=int, default=0, help='max extra cold runs per failing seed')
    parser.add_argument('--case', type=Path, help='replay a saved stress/reduced case instead of generating seeds')
    parser.add_argument('--out', type=Path)
    args = parser.parse_args()
    args.framescope = args.framescope.resolve()
    if not 1 <= args.operations <= 1000 or not 0 <= args.reduce_runs <= 100:
        parser.error('operations must be 1..1000 and reduce-runs 0..100')
    seeds = [int(s) for s in args.seeds.split(',')]
    if not seeds or any(s < 1 or s > 2147483647 for s in seeds) or len(seeds) != len(set(seeds)):
        parser.error('seeds must be distinct integers 1..2147483647')
    output = (args.out or GOLDEN / 'out/m4' / datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d-%H%M%S')).resolve()
    output.mkdir(parents=True, exist_ok=False)
    config = prepare_manifest(args.framescope, output, args.coverage)
    cases = []
    if args.case:
        target = output / 'replay.json'
        write(target, read(args.case.resolve()))
        cases.append(target)
    else:
        for seed in seeds:
            target = output / f'seed-{seed}.json'
            if run_command(['npx', 'tsx', 'src/cli/stress.ts', '--seed', str(seed), '--operations',
                            str(args.operations), '--version', str(args.generator), '--out', str(target)], GOLDEN, output / f'generate-{seed}.log'):
                raise RuntimeError('scenario generation failed')
            cases.append(target)
    results = []
    for i, case in enumerate(cases):
        result = evaluate(case, output / f'case-{i}', args, config)
        if result.get('first_divergence') and args.reduce_runs:
            result['reduction'] = reduce_failure(case, result, output / f'case-{i}', args, config)
        results.append(result)
    summary = {'ok': all(r['ok'] for r in results), 'version': 1, 'runtime': args.runtime,
               'scope': 'M1 canvas state at settled checkpoints; cold randomized initialization',
               'metacircuit': provenance(REPO), 'framescope': provenance(args.framescope),
               'coverage_requested': args.coverage, 'results': results}
    write(output / 'summary.json', summary)
    print(json.dumps({'ok': summary['ok'], 'summary': str(output / 'summary.json')}, indent=2))
    return 0 if summary['ok'] else 1


if __name__ == '__main__':
    sys.exit(main())
