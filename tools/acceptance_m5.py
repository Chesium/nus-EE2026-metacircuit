#!/usr/bin/env python3
"""Shared local/CI acceptance entry point; partial evidence never means readiness."""
from __future__ import annotations
import argparse
from datetime import datetime, timezone
import hashlib
import json
import math
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
CONTRACT_SHA = '475a48362f0f353104abfde654c25f7bdc60acc266c7a774ca6b256d315b540e'
CONTRACT = ROOT / 'golden/verification/contracts/frontend-v1'
IMAGE = 'framescope-toolchain:6501155dc903'
POLICY_SHA = 'ef809ac14dacb25448639573cc72317b02e84ce1f82750c4d1df0403c5479ab2'


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def inventory(root):
    """Includes added files, so old evidence cannot qualify an expanded RTL tree."""
    return {str(p.relative_to(root)): sha(p) for folder in ('src/design', 'src/ip', 'src/constraint')
            for p in sorted((root / folder).rglob('*'))
            if p.is_file() and p.suffix.lower() in ('.v', '.sv', '.vhd', '.vh', '.svh', '.xci', '.xdc', '.mem')}


def verification_inventory(root):
    """Pin the executable observers and runners actually used during this gate."""
    files = set()
    for folder in ('tools', 'golden/tools'):
        files.update(p for p in (root / folder).rglob('*')
                     if p.is_file() and p.suffix in ('.py', '.ts', '.json', '.tcl'))
    files.update((root / 'src/testbench').glob('M5*.sv'))
    return {str(p.relative_to(root)): sha(p) for p in sorted(files)}


def baseline_identity(root, contract, supplement=None):
    accepted = {e['path']: e['sha256'] for e in contract['entries'] if e['group'] == 'baseline_rtl'}
    accepted.update(supplement or {})
    actual = {str(p.relative_to(root)): sha(p) for p in sorted((root / 'src/design').rglob('*'))
              if p.is_file() and p.suffix.lower() in ('.v', '.sv', '.vhd', '.mem')}
    if actual != accepted:
        raise ValueError('saved baseline captures require exact frozen RTL inventory; use full mode for a candidate')


def validate_objective(objective, baseline, candidate, baseline_capacity_verified=False):
    """Require a declared gain and explicit limits; no inferred timing waivers."""
    required = {'metric', 'minimum_gain', 'maximum_resources', 'minimum_wns_ns', 'minimum_whs_ns'}
    optional = {'comparison_stage', 'setup_wns_tolerance_ns'}
    if not required <= set(objective) <= required | optional:
        raise ValueError('objective must declare metric, gain, resource limits and setup/hold floors')
    stage = objective.get('comparison_stage', 'routed')
    if stage not in ('synth', 'routed') or (stage == 'synth' and objective['metric'] == 'wns_ns'):
        raise ValueError('comparison stage must be routed, or synth for a resource objective')
    metric = objective['metric']
    if metric not in ('lut', 'ff', 'bram', 'dsp', 'wns_ns'):
        raise ValueError('unsupported optimization metric')
    def number(value):
        if type(value) not in (int, float) or not math.isfinite(value):
            raise ValueError('non-finite or invalid optimization number')
        return value
    tolerance = number(objective.get('setup_wns_tolerance_ns', 0))
    if tolerance < 0:
        raise ValueError('setup WNS tolerance must be nonnegative')
    gain_floor = number(objective['minimum_gain'])
    if gain_floor <= 0:
        raise ValueError('optimization requires a positive measured gain')
    limits = objective['maximum_resources']
    if set(limits) != {'lut', 'ff', 'bram', 'dsp'} or any(number(v) < 0 for v in limits.values()):
        raise ValueError('all resource limits must be explicit and nonnegative')
    errors = []
    for name, result, needed in (('baseline', baseline, stage), ('candidate', candidate, 'routed')):
        verified_capacity_baseline = name == 'baseline' and stage == 'synth' and baseline_capacity_verified
        if ((not verified_capacity_baseline and (result.get('evidence_status') != 'complete' or result.get('errors')))
                or needed not in result.get('stages', {})):
            errors.append(name + ' lacks complete ' + needed + ' evidence')
    if stage == 'synth' and not baseline_capacity_verified:
        errors.append('synth resource comparison requires verified baseline routed capacity failure')
    if errors:
        return {'ok': False, 'errors': errors}
    b, c = baseline['stages'][stage], candidate['stages'][stage]
    physical = candidate['stages']['routed']
    for resource, limit in limits.items():
        if number(c['resources'][resource]) > limit:
            errors.append('candidate exceeds ' + resource + ' limit')
        if number(physical['resources'][resource]) > limit:
            errors.append('routed candidate exceeds ' + resource + ' limit')
    for field, floor in (('wns_ns', 'minimum_wns_ns'), ('whs_ns', 'minimum_whs_ns')):
        if number(physical['timing'][field]) < number(objective[floor]):
            errors.append('candidate misses ' + field + ' floor')
    gain = (number(c['timing'][metric]) - number(b['timing'][metric]) if metric == 'wns_ns'
            else number(b['resources'][metric]) - number(c['resources'][metric]))
    if gain < gain_floor:
        errors.append('declared optimization gain not achieved')
    # Timing closure is not required; validate_timing_policy forbids regressions instead.
    return {'ok': not errors, 'errors': errors, 'metric': metric, 'gain': gain, 'objective': objective}


def cdc_findings(text):
    """Critical/warning CDC rule counts; an all-safe report has none."""
    if 'All paths are Safely Timed' in text:
        return {}
    rows = re.findall(r'^\s*(?:Critical|Warning)\s+(CDC-\d+)\s+(\d+)', text, re.M)
    if not rows:
        raise ValueError('unrecognized CDC report summary')
    found = {}
    for rule, count in rows:
        found[rule] = found.get(rule, 0) + int(count)
    return found


def validate_timing_policy(policy, baseline, candidate, baseline_dir, candidate_dir, root=ROOT, objective=None):
    """No timing regression against the recorded baseline under the frozen comparison XDC.

    Timing closure is out of M5 scope: the baseline's own setup violations and
    missing I/O delays are recorded debt. A candidate must keep hold clean and
    must not worsen setup WNS beyond the tolerance declared in the objective
    (policy default otherwise), nor add check_timing, DRC or CDC findings.
    """
    b, c = baseline['stages'].get('routed'), candidate['stages'].get('routed')
    if not b or not c:
        return ['timing policy requires routed baseline and candidate']
    errors = []
    recorded = policy['baseline']
    for key in ('resources', 'constraint_checks'):
        if b[key] != recorded[key]:
            errors.append('baseline QoR is not the recorded timing baseline: ' + key)
    for key in ('wns_ns', 'whs_ns'):
        if b['timing'][key] != recorded['timing'][key]:
            errors.append('baseline QoR is not the recorded timing baseline: ' + key)
    xdc = policy['comparison_constraint']
    for name, result in (('baseline', baseline), ('candidate', candidate)):
        if result['manifest']['hashes'].get(xdc['path']) != xdc['sha256']:
            errors.append(name + ' was not measured with the frozen comparison constraints')
    for path, expected in candidate['manifest']['hashes'].items():
        if path != xdc['path'] and sha(root / path) != expected:
            errors.append('candidate QoR input differs from the checkout under test: ' + path)
    timing = c['timing']
    if timing['whs_ns'] < 0 or timing['hold_failing_endpoints'] != 0:
        errors.append('candidate has hold violations')
    tolerance = (objective or {}).get('setup_wns_tolerance_ns', policy['setup_wns_tolerance_ns'])
    if timing['wns_ns'] < b['timing']['wns_ns'] - tolerance:
        errors.append('candidate setup WNS %.3f ns is worse than baseline %.3f ns by more than %.3f ns'
                      % (timing['wns_ns'], b['timing']['wns_ns'], tolerance))
    for check, count in c['constraint_checks'].items():
        if count > b['constraint_checks'].get(check, 0):
            errors.append('candidate adds check_timing findings: ' + check)
    known = {finding['rule'] for finding in b['drc']['findings']}
    for finding in c['drc']['findings']:
        if finding['rule'] not in known:
            errors.append('candidate adds DRC rule: ' + finding['rule'])
    try:
        before = cdc_findings((Path(baseline_dir) / 'routed_cdc.rpt').read_text())
        after = cdc_findings((Path(candidate_dir) / 'routed_cdc.rpt').read_text())
        for rule, count in after.items():
            if count > before.get(rule, 0):
                errors.append('candidate adds CDC findings: ' + rule)
    except (OSError, ValueError) as exc:
        errors.append('CDC comparison failed: ' + str(exc))
    return errors


def validate_qor_pair(baseline, candidate, baseline_dir, candidate_dir, capacity_comparison=False):
    """Reject gains obtained by changing tools, constraints or the measured scope."""
    errors = []
    b, c = baseline['manifest'], candidate['manifest']
    for field in ('top', 'part', 'sources', 'ips', 'constraints', 'settings'):
        if b[field] != c[field]:
            errors.append('QoR comparison changed ' + field)
    if not capacity_comparison and b['requested_stage'] != c['requested_stage']:
        errors.append('QoR comparison changed requested_stage')
    if set(b['hashes']) != set(c['hashes']):
        errors.append('QoR comparison changed input inventory')
    fixed = set(b['constraints']) | set(b['ips']) | {
        'tools/vivado_qor.py', 'tools/vivado_qor.tcl', 'metacircuit.tcl'}
    for path in sorted(fixed):
        if b['hashes'].get(path) != c['hashes'].get(path) or path not in b['hashes']:
            errors.append('QoR comparison changed pinned input: ' + path)
    if (Path(baseline_dir) / 'settings.txt').read_bytes() != (Path(candidate_dir) / 'settings.txt').read_bytes():
        errors.append('QoR comparison changed actual tool/build/settings')
    for stage in ('synth', 'routed'):
        if capacity_comparison and stage == 'routed':
            continue
        if baseline['stages'].get(stage, {}).get('clocks') != candidate['stages'].get(stage, {}).get('clocks'):
            errors.append('QoR comparison changed clocks: ' + stage)
    return errors


def validate_capacity_failure(baseline, failure, baseline_dir, failure_dir):
    """A retained real UTLZ-1 failure permits a declared synth resource comparison."""
    errors = validate_qor_pair(baseline, failure, baseline_dir, failure_dir, True)
    if failure['manifest']['requested_stage'] != 'routed' or failure.get('run', {}).get('returncode', 0) == 0:
        errors.append('baseline capacity witness is not a failed routed attempt')
    if baseline['manifest']['hashes'] != failure['manifest']['hashes']:
        errors.append('baseline capacity witness has different inputs')
    if baseline['stages'].get('synth') != failure['stages'].get('synth'):
        errors.append('baseline capacity witness has different synthesis metrics')
    allowed = ('missing/empty artifact: routed', 'missing artifact hash: routed', 'routed: [Errno 2]',
               'Vivado exited unsuccessfully', 'Vivado logged ERROR: 3')
    if not failure.get('errors') or any(not error.startswith(allowed) for error in failure['errors']):
        errors.append('baseline capacity witness contains unexpected evidence errors')
    log = (Path(failure_dir) / 'vivado.log').read_text()
    logged = re.findall(r'^\s*ERROR:.*$', log, re.M)
    labels = ('[DRC UTLZ-1]', '[Vivado_Tcl 4-23]', '[Common 17-39]')
    if len(logged) != 3 or any(label not in line for label, line in zip(labels, logged)):
        errors.append('baseline capacity witness lacks exact place_design failure')
    match = re.search(r'This design requires (\d+) of such cell types but only (\d+) compatible sites', log)
    if not match or not int(match[1]) > int(match[2]) == 20800:
        errors.append('baseline capacity witness lacks Basys 3 LUT over-utilization')
    return errors


def qor_preflight(baseline_dir, candidate_dir, objective_path, root=ROOT, baseline_failure_dir=None,
                  baseline_corrections=None, timing_policy=None):
    """Validate real reports before launching the expensive candidate corpus."""
    from vivado_qor import summarize
    baseline = summarize(Path(baseline_dir).resolve())
    # Inputs are checked against the checkout in validate_timing_policy, except the comparison XDC.
    candidate = summarize(Path(candidate_dir).resolve())
    objective = json.loads(Path(objective_path).read_text())
    capacity = objective.get('comparison_stage') == 'synth'
    capacity_errors = []
    if capacity:
        if baseline_failure_dir is None:
            capacity_errors.append('missing baseline routed capacity-failure witness')
        else:
            failure = summarize(Path(baseline_failure_dir).resolve())
            capacity_errors = validate_capacity_failure(baseline, failure, baseline_dir, baseline_failure_dir)
    result = validate_objective(objective, baseline, candidate, capacity and not capacity_errors)
    result['errors'].extend(capacity_errors)
    if capacity:
        result['baseline_characterization'] = {'evidence_status': baseline.get('evidence_status'),
                                               'errors': baseline.get('errors'), 'comparison_stage': 'synth',
                                               'routed_capacity_verified': not capacity_errors}
    if result['ok']:
        result['errors'].extend(validate_qor_pair(baseline, candidate, baseline_dir, candidate_dir, capacity))
        if timing_policy is None:
            result['errors'].append('missing timing no-regression policy')
        else:
            result['errors'].extend(validate_timing_policy(timing_policy, baseline, candidate,
                                                           baseline_dir, candidate_dir, root, objective))
        frozen = json.loads((CONTRACT / 'contract.json').read_text())
        accepted = {e['path']: e['sha256'] for e in frozen['entries'] if e['group'] == 'baseline_rtl'}
        for path, expected in (baseline_corrections or {}).items():
            if path not in accepted or not re.fullmatch('[a-f0-9]{64}', expected):
                raise ValueError('invalid separately pinned baseline correction: ' + path)
            accepted[path] = expected
        for path in baseline['manifest']['sources']:
            if baseline['manifest']['hashes'][path] != accepted.get(path):
                result['errors'].append('QoR baseline differs from frozen accepted source: ' + path)
    result['ok'] = not result['errors']
    return result


class Gate:
    def __init__(self, out, framescope, runtime):
        self.out, self.framescope, self.runtime = out, framescope, runtime
        self.checks = []
        self.started = time.monotonic()

    def budget(self):
        policy = getattr(self, 'policy', {})
        return min(policy.get('command_timeout_seconds', 3600),
                   policy.get('total_timeout_seconds', 21600) - (time.monotonic() - self.started))

    def command(self, name, argv, cwd=ROOT, env=None, evidence=None, verdict='ok'):
        log = self.out / (name + '.log')
        print(name, flush=True)
        budget = self.budget()
        timed_out = budget <= 0
        with log.open('w') as stream:
            code = 124
            if not timed_out:
                process = subprocess.Popen([str(x) for x in argv], cwd=cwd, env=env,
                                           stdout=stream, stderr=subprocess.STDOUT, start_new_session=True)
                def interrupted(signum, frame):
                    raise KeyboardInterrupt
                previous_handler = signal.signal(signal.SIGTERM, interrupted)
                try:
                    code = process.wait(timeout=budget)
                except (subprocess.TimeoutExpired, KeyboardInterrupt):
                    timed_out = True
                    try:
                        os.killpg(process.pid, signal.SIGTERM)
                    except ProcessLookupError:
                        pass
                    try:
                        process.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        try:
                            os.killpg(process.pid, signal.SIGKILL)
                        except ProcessLookupError:
                            pass
                        process.wait()
                    # The launcher can exit while its descendants still run.
                    try:
                        os.killpg(process.pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                finally:
                    signal.signal(signal.SIGTERM, previous_handler)
        item = {'name': name, 'ok': code == 0, 'exit_code': code, 'command': [str(x) for x in argv],
                'log': str(log), 'log_sha256': sha(log), 'timeout_seconds': max(0, budget)}
        if timed_out:
            item.update(ok=False, error='command interrupted or pinned runtime budget exhausted')
        if evidence is not None:
            try:
                data = json.loads(Path(evidence).read_text())
                value = data
                for field in verdict.split('.'):
                    value = value[field]
                if value is not True:
                    raise ValueError('mandatory evidence verdict is not true')
                item.update(evidence=str(evidence), evidence_sha256=sha(evidence))
            except (OSError, ValueError, KeyError, TypeError) as exc:
                item.update(ok=False, error='missing/invalid result evidence: ' + str(exc))
        self.checks.append(item)
        if timed_out:
            raise ValueError('pinned runtime budget exhausted or command interrupted: ' + name)
        return item

    def fast(self):
        tool = (['verilator', '--version'] if self.runtime == 'native' else
                ['docker', 'run', '--rm', IMAGE, 'verilator', '--version'])
        identity = self.command('runtime-identity', tool)
        version = self.policy['runtime_versions'][self.runtime]
        if 'Verilator ' + version + ' ' not in (self.out / 'runtime-identity.log').read_text():
            identity['ok'] = False
            identity['error'] = 'runtime does not match pinned Verilator ' + version
        self.command('contract', [sys.executable, ROOT / 'golden/tools/freeze_contract.py', 'verify',
                                 '--expected-contract-sha256', CONTRACT_SHA])
        self.command('golden-typecheck', ['npm', 'run', 'typecheck'], ROOT / 'golden')
        self.command('golden-tests', ['npm', 'test'], ROOT / 'golden')
        self.command('golden-python-tests', [sys.executable, '-m', 'unittest', 'discover', '-s', 'golden/tools', '-p', 'test_*.py'])
        self.command('gate-and-qor-tests', [sys.executable, '-m', 'unittest', 'discover', '-s', 'tools/tests'])
        self.command('framescope-tests', [sys.executable, '-m', 'unittest', 'discover', '-s', 'tests'],
                     self.framescope, {**os.environ, 'PYTHONPATH': str(self.framescope / 'src'),
                                       'FRAMESCOPE_RUNTIME': self.runtime})

    def scoped_safety(self):
        """Fresh source proofs and real serial rejection checks for development/full gates."""
        for name, tool, extra in (
            ('flood-queue-order', 'verify_flood_queue_order_m5.py', []),
            ('guard-progress', 'verify_guard_progress_m5.py', []),
            ('component-progress', 'verify_component_progress_m5.py', []),
            ('reply-parser-control', 'verify_reply_parser_m5.py', []),
            ('reply-banks', 'verify_reply_banks_m5.py',
             ['--source', ROOT / 'src/design/rendering/GlobalRender_top.v']),
            ('reply-integrity', 'verify_reply_integrity_m5.py', ['--runtime', self.runtime]),
        ):
            self.command(name, [sys.executable, ROOT / 'tools' / tool, *extra,
                               '--out', self.out / name], evidence=self.out / name / 'report.json')

    def baseline(self):
        """Re-run independent comparators on exact-source saved M4 captures."""
        baseline_identity(ROOT, json.loads((CONTRACT / 'contract.json').read_text()),
                          self.policy['baseline_supplement'])
        sys.path.insert(0, str(ROOT / 'golden/tools'))
        from semantic_adapter import adapt_run, compare_reference, configuration, digest
        from functional_m4 import collect
        from verify_m4 import functional_union
        source = json.loads((ROOT / 'golden/out/m4-lockstep/corpus-agent-summary.json').read_text())
        coverage, adapters = [], []
        for item in source['runs']:
            if item['runtime'] != self.runtime:
                continue
            directory = ROOT / Path(item['summary']).parent
            case = json.loads((directory / 'case.json').read_text())
            frozen_cases = [json.loads((CONTRACT / e['stored']).read_text()) for e in
                            json.loads((CONTRACT / 'contract.json').read_text())['entries']
                            if e['group'] == 'saved_corpus' and '/corpus-agent-cases/' in e['path']]
            if case not in frozen_cases:
                raise ValueError('directed inputs differ from frozen accepted corpus')
            fresh = self.out / ('independent-' + item['corpus'])
            generation = self.command('reference-' + item['corpus'], ['npm', 'run', 'golden', '--', 'run',
                                      directory / 'scenario.json', '--out', fresh], ROOT / 'golden')
            compared_fresh = self.command('compare-' + item['corpus'], ['npm', 'run', 'golden', '--', 'compare',
                                         directory / 'rtl', '--reference', fresh,
                                         '-o', self.out / ('compare-' + item['corpus'] + '.json')], ROOT / 'golden')
            if not generation['ok'] or not compared_fresh['ok']:
                raise ValueError('fresh independent frozen-oracle comparison failed')
            covered, evidence = collect(directory)
            coverage.append(covered)
            index = json.loads((directory / 'reference/checkpoints.json').read_text())
            normalized = adapt_run(directory / 'rtl', [c['frame'] for c in index['checkpoints']])
            compared = compare_reference(normalized, fresh)
            if compared['ok'] is not True:
                raise ValueError('adapter rejects independent golden core')
            adapters.append({'corpus': item['corpus'], 'evidence': evidence, 'semantic_sha256': digest(normalized),
                             'config_sha256': digest(configuration()), 'comparison': compared})
        if {a['corpus'] for a in adapters} != {'rotations', 'properties', 'boundaries', 'dense'}:
            raise ValueError('missing directed corpus')
        union = functional_union(coverage)
        if union['uncovered'] or len(union['reached']) != 64:
            raise ValueError('missing required functional bins')
        (self.out / 'functional-adapter.json').write_text(json.dumps({'ok': True, 'runs': adapters, 'coverage': union}, indent=2) + '\n')
        self.checks.append({'name': 'functional-adapter', 'ok': True, 'bins': len(union['reached']), 'captures': len(adapters)})
        regressions = json.loads((ROOT / 'golden/out/m4/regression-agent-evidence.json').read_text())
        for section in ('m2', 'm3'):
            selected = [i for i in regressions[section] if i['runtime'] == self.runtime]
            expected = set(p.stem for p in (ROOT / 'golden/scenarios').glob(section + '_*.json'))
            if {i['scenario'] for i in selected} != expected:
                raise ValueError('missing fixed ' + section + ' corpus')
            for item in selected:
                capture = (ROOT / Path(item['summary']).parent / 'rtl').resolve()
                self.command(section + '-' + item['scenario'], [sys.executable, ROOT / ('golden/tools/verify_' + section + '.py'),
                             '--runtime', self.runtime, '--framescope', self.framescope,
                             '--scenario', ROOT / ('golden/scenarios/' + item['scenario'] + '.json'), '--actual', capture,
                             '--out', self.out / (section + '-' + item['scenario'])])

    def full(self):
        """Fresh fixed regressions and cold seeded coverage; never reuses baseline PASS."""
        for scenario in sorted((ROOT / 'golden/scenarios').glob('m[12]_*.json')):
            milestone = scenario.stem[:2]
            self.command(scenario.stem, [sys.executable, ROOT / ('golden/tools/verify_' + milestone + '.py'),
                         '--scenario', scenario, '--runtime', self.runtime, '--framescope', self.framescope,
                         '--out', self.out / scenario.stem])
        self.command('m3', [sys.executable, ROOT / 'golden/tools/verify_m3.py', '--runtime', self.runtime,
                           '--framescope', self.framescope, '--out', self.out / 'm3'])
        # Structural coverage is measured where the coverage policy requires it (native); other
        # runtimes run the same seeded corpus uninstrumented for cross-runtime agreement.
        coverage_runtimes = json.loads((ROOT / 'tools/m5_coverage_policy.json').read_text())['required_runtimes']
        measured = self.runtime in coverage_runtimes
        self.command('seeded-coverage' if measured else 'seeded-corpus',
                     [sys.executable, ROOT / 'golden/tools/verify_m4.py', '--runtime', self.runtime,
                      '--framescope', self.framescope, '--seeds', ','.join(str(x) for x in self.policy['seed_corpus']),
                      '--operations', str(self.policy['stress_operations']), '--generator', str(self.policy['stress_generator']),
                      *(['--coverage'] if measured else []),
                      '--out', self.out / ('seeded-coverage' if measured else 'seeded-corpus')])
        if measured:
            reports = sorted((self.out / 'seeded-coverage').rglob('coverage.json'))
            self.command('coverage-policy', [sys.executable, ROOT / 'tools/verify_coverage_m5.py',
                         '--framescope', self.framescope, '--out', self.out / 'coverage-policy',
                         *[arg for path in reports for arg in ('--coverage-report', path)]],
                         evidence=self.out / 'coverage-policy/summary.json', verdict='ready')
        contract = json.loads((CONTRACT / 'contract.json').read_text())
        for entry in contract['entries']:
            if entry['group'] == 'saved_corpus' and '/corpus-agent-cases/' in entry['path']:
                name = Path(entry['path']).stem
                self.command('directed-' + name, [sys.executable, ROOT / 'golden/tools/lockstep_m4.py',
                             '--case', CONTRACT / entry['stored'], '--runtime', self.runtime,
                             '--framescope', self.framescope, '--out', self.out / ('directed-' + name)])
        self.command('invariants', [sys.executable, ROOT / 'golden/tools/verify_invariants_m5.py',
                                  '--runtime', self.runtime, '--out', self.out / 'invariants'],
                     evidence=self.out / 'invariants/summary.json')
        self.command('frontend-invariants', [sys.executable, ROOT / 'golden/tools/verify_frontend_invariants_m5.py',
                     '--runtime', self.runtime, '--out', self.out / 'frontend-invariants'],
                     evidence=self.out / 'frontend-invariants/summary.json')
        self.command('frontend-supplemental', [sys.executable, ROOT / 'golden/tools/verify_frontend_invariants_m5.py',
                     '--runtime', self.runtime, '--bench', 'supplemental',
                     '--out', self.out / 'frontend-supplemental'],
                     evidence=self.out / 'frontend-supplemental/summary.json')
        self.command('frontend-restart', [sys.executable, ROOT / 'golden/tools/verify_frontend_invariants_m5.py',
                     '--runtime', self.runtime, '--bench', 'restart',
                     '--out', self.out / 'frontend-restart'],
                     evidence=self.out / 'frontend-restart/summary.json')
        self.command('flood-queue-safety', [sys.executable, ROOT / 'tools/verify_flood_queue_safety_m5.py',
                     '--runtime', self.runtime, '--out', self.out / 'flood-queue-safety'],
                     evidence=self.out / 'flood-queue-safety/report.json')
        self.command('frontend-domains', [sys.executable, ROOT / 'golden/tools/verify_frontend_domains_m5.py',
                     '--runtime', self.runtime, '--out', self.out / 'frontend-domains'],
                     evidence=self.out / 'frontend-domains/summary.json')
        self.command('actual-fp', [sys.executable, ROOT / 'tools/verify_fp_m5.py', '--out', self.out / 'actual-fp'],
                     evidence=self.out / 'actual-fp/report.json', verdict='characterization_passed')
        self.command('actual-solver-xsim', [sys.executable, ROOT / 'tools/verify_solver_xsim_m5.py',
                     '--out', self.out / 'actual-solver-xsim', '--fp-report', self.out / 'actual-fp/report.json'],
                     evidence=self.out / 'actual-solver-xsim/report.json', verdict='scoped_actual_pipeline_passed')
        self.command('solver-accuracy', [sys.executable, ROOT / 'tools/verify_solver_xsim_m5.py',
                     '--out', self.out / 'solver-accuracy', '--fp-report', self.out / 'actual-fp/report.json',
                     '--accuracy-baseline', repr(self.policy['solver_accuracy']['max_relative_error'])],
                     evidence=self.out / 'solver-accuracy/report.json', verdict='accuracy_no_regression')
        self.command('actual-solver-capacity', [sys.executable, ROOT / 'tools/verify_solver_capacity_m5.py',
                     '--out', self.out / 'actual-solver-capacity', '--fp-report', self.out / 'actual-fp/report.json'],
                     evidence=self.out / 'actual-solver-capacity/report.json', verdict='capacity_recovery_passed')
        self.command('actual-solver-frontend-xsim', [sys.executable, ROOT / 'tools/verify_solver_frontend_xsim_m5.py',
                     '--out', self.out / 'actual-solver-frontend-xsim', '--timeout', '1800',
                     '--fp-report', self.out / 'actual-fp/report.json'],
                     evidence=self.out / 'actual-solver-frontend-xsim/report.json',
                     verdict='scoped_actual_frontend_passed')
        solver = ROOT / 'tools/verify_solver_m5.py'
        if solver.exists():
            self.command('generated-extraction', [sys.executable, solver, '--runtime', self.runtime,
                         '--extraction-only', '--out', self.out / 'generated-extraction'],
                         evidence=self.out / 'generated-extraction/report.json', verdict='extraction_qualified')
        else:
            self.checks.append({'name': 'generated-extraction', 'ok': False, 'error': 'mandatory generated extraction verifier unavailable'})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mode', choices=['fast', 'baseline', 'full'], default='fast')
    parser.add_argument('--runtime', choices=['native', 'docker'], default='docker')
    parser.add_argument('--framescope', type=Path, default=ROOT.parent / 'framescope')
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--qor', type=Path)
    parser.add_argument('--baseline-qor', type=Path)
    parser.add_argument('--objective', type=Path)
    parser.add_argument('--baseline-route-attempt', type=Path,
                        help='matching retained UTLZ-1 failure for an explicit synth resource objective')
    args = parser.parse_args()
    out = args.out.resolve(); out.mkdir(parents=True, exist_ok=False)
    gate = Gate(out, args.framescope.resolve(), args.runtime)
    before = inventory(ROOT)
    verification_before = verification_inventory(ROOT)
    errors, readiness_errors = [], []
    try:
        policy_path = ROOT / 'tools/m5_acceptance_policy.json'
        if sha(policy_path) != POLICY_SHA:
            raise ValueError('acceptance policy identity changed')
        gate.policy = json.loads(policy_path.read_text())
        if args.mode != 'baseline':
            # Scoped proofs need Yosys; fail before any long check if it is missing.
            from m5_tools import yosys
            if not Path(yosys()).is_file() or 'Yosys 0.33' not in subprocess.run(
                    [yosys(), '-V'], capture_output=True, text=True).stdout:
                raise ValueError('pinned Yosys 0.33 not found; run tools/setup_yosys_m5.sh or set METACIRCUIT_YOSYS')
        if sha(ROOT / 'tools/m5_coverage_policy.json') != gate.policy['coverage_policy_sha256']:
            raise ValueError('coverage acceptance policy identity changed')
        for path, expected in gate.policy['tool_hashes'].items():
            if sha(ROOT / path) != expected:
                raise ValueError('unpinned acceptance adapter/comparator: ' + path)
        frozen = json.loads((CONTRACT / 'contract.json').read_text())
        for entry in frozen['entries']:
            if entry['group'] in ('baseline_harness', 'baseline_harness_manifest'):
                if sha(gate.framescope / entry['path']) != entry['sha256']:
                    raise ValueError('accepted harness changed: ' + entry['path'])
        if args.mode == 'full' and not all((args.qor, args.baseline_qor, args.objective)):
            raise ValueError('missing mandatory candidate/baseline routed QoR or declared optimization objective; full regression batch not started')
        if args.mode == 'full':
            comparison = qor_preflight(args.baseline_qor, args.qor, args.objective,
                                       baseline_failure_dir=args.baseline_route_attempt,
                                       baseline_corrections=gate.policy.get('qor_baseline_corrections'),
                                       timing_policy=gate.policy.get('qor_timing_policy'))
            (out / 'optimization-preflight.json').write_text(json.dumps(comparison, indent=2) + '\n')
            if comparison['ok'] is not True:
                raise ValueError('QoR preflight rejected; full regression batch not started: ' + '; '.join(comparison['errors']))
        sys.path.insert(0, str(ROOT / 'golden/tools'))
        from semantic_adapter import configuration, digest
        if digest(configuration()) != gate.policy['adapter_config_sha256']:
            raise ValueError('acceptance adapter configuration changed')
        gate.fast()
        if not all(c['ok'] for c in gate.checks):
            raise ValueError('mandatory fast check failed; see logs')
        if args.mode != 'baseline':
            gate.scoped_safety()
            if not all(c['ok'] for c in gate.checks):
                raise ValueError('mandatory scoped safety check failed; see logs')
        if args.mode == 'baseline':
            gate.baseline()
        elif args.mode == 'full':
            gate.full()
        # Readiness comes only from checks that ran; scope limits are documented, not hard-coded failures.
        if args.mode == 'full':
            if not all((args.qor, args.baseline_qor, args.objective)):
                readiness_errors.append('missing candidate/baseline routed QoR or declared optimization objective')
            else:
                comparison = qor_preflight(args.baseline_qor, args.qor, args.objective,
                                           baseline_failure_dir=args.baseline_route_attempt,
                                           baseline_corrections=gate.policy.get('qor_baseline_corrections'),
                                           timing_policy=gate.policy.get('qor_timing_policy'))
                (out / 'optimization.json').write_text(json.dumps(comparison, indent=2) + '\n')
                readiness_errors.extend(comparison['errors'])
        if before != inventory(ROOT):
            errors.append('candidate input inventory changed during checks')
        gate.command('contract-final', [sys.executable, ROOT / 'golden/tools/freeze_contract.py', 'verify',
                                       '--expected-contract-sha256', CONTRACT_SHA])
    except (OSError, ValueError, KeyError, TypeError, AssertionError) as exc:
        errors.append(str(exc))
    if verification_before != verification_inventory(ROOT):
        errors.append('verification tool/observer inventory changed during checks')
    checks_ok = bool(gate.checks) and all(c['ok'] for c in gate.checks) and not errors
    ready = args.mode == 'full' and checks_ok and not readiness_errors
    report = {'schema': 'metacircuit-acceptance/v1', 'recorded_at_utc': datetime.now(timezone.utc).isoformat(),
              'mode': args.mode, 'runtime': args.runtime, 'checks_ok': checks_ok, 'ready': ready,
              'ok': ready if args.mode == 'full' else checks_ok, 'contract_sha256': CONTRACT_SHA,
              'input_hashes': before, 'checks': gate.checks, 'errors': errors, 'readiness_errors': readiness_errors,
              'verification_input_hashes': verification_before,
              'scope': 'fast/baseline success is development/unchanged frontend qualification only; full success requires all M5 readiness'}
    (out / 'summary.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'ok': report['ok'], 'ready': ready, 'summary': str(out / 'summary.json')}))
    return 0 if report['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
