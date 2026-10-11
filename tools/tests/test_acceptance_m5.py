import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from acceptance_m5 import Gate, baseline_identity, inventory, verification_inventory, validate_objective, validate_qor_pair, validate_capacity_failure


def qor(lut=100, wns=1):
    return {'evidence_status': 'complete', 'errors': [], 'timing_clean': True,
            'stages': {'routed': {'resources': {'lut': lut, 'ff': 50, 'bram': 2, 'dsp': 0},
                                  'timing': {'wns_ns': wns, 'whs_ns': 0.1}}}}


class AcceptanceControls(unittest.TestCase):
    def setUp(self):
        self.objective = {'metric': 'lut', 'minimum_gain': 5,
                          'maximum_resources': {'lut': 100, 'ff': 50, 'bram': 2, 'dsp': 0},
                          'minimum_wns_ns': 0, 'minimum_whs_ns': 0}

    def test_gain_with_explicit_limits(self):
        result = validate_objective(self.objective, qor(), qor(90))
        self.assertTrue(result['ok'])
        self.assertEqual(result['gain'], 10)

    def test_behavioral_pass_cannot_substitute_for_report(self):
        for mutation in ({'evidence_status': 'incomplete'}, {'errors': ['corrupt report']}, {'stages': {}},
                         {'timing_clean': False}):
            candidate = qor(90); candidate.update(mutation)
            self.assertFalse(validate_objective(self.objective, qor(), candidate)['ok'])

    def test_tradeoff_and_gain_failures(self):
        for candidate in (qor(99), qor(101), qor(90, -0.1)):
            self.assertFalse(validate_objective(self.objective, qor(), candidate)['ok'])
        candidate = qor(90); candidate['stages']['routed']['resources']['ff'] = 51
        self.assertFalse(validate_objective(self.objective, qor(), candidate)['ok'])

    def test_objective_must_be_explicit_and_finite(self):
        for field, value in (('minimum_gain', 0), ('minimum_gain', True), ('minimum_gain', float('nan')),
                             ('metric', 'arbitrary'), ('minimum_wns_ns', float('inf'))):
            objective = copy.deepcopy(self.objective); objective[field] = value
            with self.assertRaises(ValueError):
                validate_objective(objective, qor(), qor(90))
        for field in self.objective:
            objective = copy.deepcopy(self.objective); del objective[field]
            with self.assertRaises(ValueError):
                validate_objective(objective, qor(), qor(90))

    def test_timing_objective_has_correct_direction(self):
        objective = {**self.objective, 'metric': 'wns_ns', 'minimum_gain': 0.2}
        self.assertTrue(validate_objective(objective, qor(100, 1), qor(100, 1.3))['ok'])
        self.assertFalse(validate_objective(objective, qor(100, 1), qor(100, 0.7))['ok'])

    def test_capacity_comparison_still_requires_routed_clean_candidate(self):
        objective = {**self.objective, 'comparison_stage': 'synth'}
        baseline, candidate = qor(), qor(90)
        baseline['stages']['synth'] = copy.deepcopy(baseline['stages'].pop('routed'))
        candidate['stages']['synth'] = copy.deepcopy(candidate['stages']['routed'])
        self.assertFalse(validate_objective(objective, baseline, candidate)['ok'])
        self.assertTrue(validate_objective(objective, baseline, candidate, True)['ok'])
        baseline.update(evidence_status='incomplete', errors=['Vivado exited unsuccessfully'])
        self.assertTrue(validate_objective(objective, baseline, candidate, True)['ok'])
        self.assertFalse(validate_objective(objective, baseline, candidate)['ok'])
        candidate['stages']['routed']['resources']['lut'] = 101
        self.assertFalse(validate_objective(objective, baseline, candidate, True)['ok'])
        candidate['stages'].pop('routed')
        self.assertFalse(validate_objective(objective, baseline, candidate, True)['ok'])
        with self.assertRaises(ValueError):
            validate_objective({**objective, 'metric': 'wns_ns'}, baseline, candidate, True)

    def test_capacity_witness_cannot_hide_corruption_or_other_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); b, f = root / 'b', root / 'f'; b.mkdir(); f.mkdir()
            manifest = {'top': 'GlobalRender_top', 'part': 'xc7a35tcpg236-1', 'sources': ['top.v'],
                        'ips': [], 'constraints': ['clock.xdc'], 'settings': {}, 'requested_stage': 'synth',
                        'hashes': {p:'fixed' for p in ('top.v','clock.xdc','tools/vivado_qor.py','tools/vivado_qor.tcl','metacircuit.tcl')}}
            baseline = {'manifest':manifest, 'stages':{'synth':{'clocks':[['sys_clk_pin','10','0']]}}}
            failure = copy.deepcopy(baseline)
            failure['manifest']['requested_stage'] = 'routed'
            failure.update(run={'returncode':1}, errors=['missing/empty artifact: routed.dcp',
                           'Vivado exited unsuccessfully','Vivado logged ERROR: 3'])
            for path in (b,f): (path/'settings.txt').write_text('same pinned build')
            log = ('ERROR: [DRC UTLZ-1] This design requires 22138 of such cell types but only 20800 compatible sites\n'
                   'ERROR: [Vivado_Tcl 4-23] Error(s) found during DRC. Placer not run.\n'
                   "ERROR: [Common 17-39] 'place_design' failed due to earlier errors.\n")
            (f/'vivado.log').write_text(log)
            self.assertEqual(validate_capacity_failure(baseline, failure, b, f), [])
            for error in ('corrupt artifact: vivado.log', 'missing source hash: top.v',
                          'stale source hash: top.v', 'missing/empty artifact: synth.dcp'):
                changed = copy.deepcopy(failure); changed['errors'].append(error)
                self.assertTrue(validate_capacity_failure(baseline, changed, b, f), error)
            (f/'vivado.log').write_text(log.replace('22138', '10000'))
            self.assertTrue(validate_capacity_failure(baseline, failure, b, f))
            (f/'vivado.log').write_text(log.replace('[DRC UTLZ-1]', '[DRC OTHER]'))
            self.assertTrue(validate_capacity_failure(baseline, failure, b, f))

    def test_changed_or_added_rtl_rejects_saved_baseline(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); folder = root / 'src/design'; folder.mkdir(parents=True)
            source = folder / 'top.v'; source.write_text('module top; endmodule\n')
            hashes = inventory(root)
            contract = {'entries': [{'group': 'baseline_rtl', 'path': 'src/design/top.v',
                                     'sha256': hashes['src/design/top.v']}]}
            baseline_identity(root, contract)
            source.write_text('module top; wire changed; endmodule\n')
            with self.assertRaises(ValueError): baseline_identity(root, contract)
            source.write_text('module top; endmodule\n')
            (folder / 'added.v').write_text('module added; endmodule\n')
            self.assertNotEqual(hashes, inventory(root))
            with self.assertRaises(ValueError): baseline_identity(root, contract)

    def test_zero_exit_without_true_result_does_not_pass(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            gate = Gate(out, out, 'native')
            evidence = out / 'result.json'
            self.assertFalse(gate.command('missing', [sys.executable, '-c', 'pass'], evidence=evidence)['ok'])
            for value in (False, 1, 'true', None):
                evidence.write_text(json.dumps({'ok': value}))
                self.assertFalse(gate.command('invalid-' + str(value), [sys.executable, '-c', 'pass'], evidence=evidence)['ok'])
            evidence.write_text(json.dumps({'scoped': {'passed': True}}))
            self.assertTrue(gate.command('present', [sys.executable, '-c', 'pass'], evidence=evidence, verdict='scoped.passed')['ok'])

    def test_full_requires_actual_frontend_and_supplemental_reports(self):
        # Other phases are assumed passing so an incomplete real UART loop is
        # the sole failure. A zero XSim exit cannot substitute for its verdict.
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            gate = Gate(out, out, 'native')
            gate.policy = {'seed_corpus': [1], 'stress_operations': 1, 'stress_generator': 2}
            gate.peer_coverage = []
            frontend = out / 'actual-solver-frontend-xsim/report.json'
            frontend.parent.mkdir()
            actual_command = gate.command
            calls = {}

            def command(name, argv, **kwargs):
                calls[name] = (argv, kwargs)
                if name == 'actual-solver-frontend-xsim':
                    return actual_command(name, [sys.executable, '-c', 'pass'], **kwargs)
                item = {'name': name, 'ok': True}
                gate.checks.append(item)
                return item

            with patch.object(gate, 'command', side_effect=command):
                for verdict in (None, False, True):
                    if verdict is not None:
                        frontend.write_text(json.dumps({'scoped_actual_frontend_passed': verdict}))
                    gate.checks.clear()
                    gate.full()
                    self.assertEqual(all(c['ok'] for c in gate.checks), verdict is True)
            argv, kwargs = calls['actual-solver-frontend-xsim']
            self.assertEqual(kwargs['verdict'], 'scoped_actual_frontend_passed')
            self.assertIn('--fp-report', argv)
            self.assertEqual(argv[argv.index('--timeout') + 1], '1800')
            self.assertIn('--bench', calls['frontend-supplemental'][0])
            self.assertEqual(calls['frontend-supplemental'][1]['evidence'], out / 'frontend-supplemental/summary.json')
            self.assertIn('restart', calls['frontend-restart'][0])
            self.assertEqual(calls['generated-extraction'][1]['verdict'], 'extraction_qualified')
            self.assertIn('--extraction-only', calls['generated-extraction'][0])
            self.assertEqual(calls['frontend-domains'][1]['evidence'], out / 'frontend-domains/summary.json')
            self.assertEqual(calls['flood-queue-safety'][1]['evidence'], out / 'flood-queue-safety/report.json')
            self.assertIn('--runtime',calls['flood-queue-safety'][0])

    def test_full_rejects_missing_or_failed_capacity_recovery(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            gate = Gate(out, out, 'native')
            gate.policy = {'seed_corpus': [1], 'stress_operations': 1, 'stress_generator': 2}
            gate.peer_coverage = []
            evidence = out / 'actual-solver-capacity/report.json'
            evidence.parent.mkdir()
            actual_command = gate.command

            def command(name, argv, **kwargs):
                if name == 'actual-solver-capacity':
                    self.assertIn('--fp-report', argv)
                    self.assertEqual(kwargs['verdict'], 'capacity_recovery_passed')
                    return actual_command(name, [sys.executable, '-c', 'pass'], **kwargs)
                item = {'name': name, 'ok': True}
                gate.checks.append(item)
                return item

            with patch.object(gate, 'command', side_effect=command):
                for verdict in (None, False, 1, True):
                    if verdict is not None:
                        evidence.write_text(json.dumps({'capacity_recovery_passed': verdict}))
                    gate.checks.clear()
                    gate.full()
                    self.assertEqual(all(c['ok'] for c in gate.checks), verdict is True)

    def test_changed_observer_or_runner_rejects_run_identity(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            paths = ['tools/runner.py', 'tools/policy.json', 'golden/tools/adapter.ts',
                     'src/testbench/M5Observed.sv']
            for name in paths:
                path = root / name; path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('original')
            before = verification_inventory(root)
            for name in paths:
                path = root / name
                path.write_text('trivial pass replacement')
                self.assertNotEqual(before, verification_inventory(root), name)
                path.write_text('original')
            added = root / 'src/testbench/M5Added.sv'
            added.write_text('new observer')
            self.assertNotEqual(before, verification_inventory(root))
            added.unlink()
            (root / paths[0]).unlink()
            self.assertNotEqual(before, verification_inventory(root))

    def test_qor_gain_cannot_hide_changed_measurement_policy(self):
        manifest = {'top': 'GlobalRender_top', 'part': 'xc7a35tcpg236-1',
                    'sources': ['src/design/top.v'], 'ips': [], 'constraints': ['clock.xdc'],
                    'settings': {'threads': 4}, 'requested_stage': 'routed',
                    'hashes': {p: 'pinned' for p in ('src/design/top.v', 'clock.xdc',
                               'tools/vivado_qor.py', 'tools/vivado_qor.tcl', 'metacircuit.tcl')}}
        baseline = qor(); baseline['manifest'] = manifest
        baseline['stages']['routed']['clocks'] = [['sys_clk_pin', '10.000', '0']]
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            b, c = root / 'b', root / 'c'
            b.mkdir(); c.mkdir()
            for folder in (b, c): (folder / 'settings.txt').write_text('Vivado pinned build')
            candidate = copy.deepcopy(baseline)
            candidate['manifest']['hashes']['src/design/top.v'] = 'optimized'
            self.assertEqual(validate_qor_pair(baseline, candidate, b, c), [])
            for field, value in (('top', 'Other'), ('part', 'larger'), ('sources', []),
                                 ('ips', ['new.xci']), ('constraints', []),
                                 ('settings', {'threads': 8}), ('requested_stage', 'synth')):
                changed = copy.deepcopy(candidate); changed['manifest'][field] = value
                self.assertTrue(validate_qor_pair(baseline, changed, b, c), field)
            for path in ('clock.xdc', 'tools/vivado_qor.py', 'tools/vivado_qor.tcl', 'metacircuit.tcl'):
                changed = copy.deepcopy(candidate); changed['manifest']['hashes'][path] = 'changed'
                self.assertTrue(validate_qor_pair(baseline, changed, b, c), path)
            changed = copy.deepcopy(candidate)
            changed['stages']['routed']['clocks'][0][1] = '20.000'
            self.assertTrue(validate_qor_pair(baseline, changed, b, c))
            (c / 'settings.txt').write_text('different tool build')
            self.assertTrue(validate_qor_pair(baseline, candidate, b, c))

    def test_scoped_safety_requires_all_six_fresh_reports(self):
        expected = {'flood-queue-order', 'guard-progress', 'component-progress',
                    'reply-parser-control', 'reply-banks', 'reply-integrity'}
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            gate = Gate(out, out, 'native')
            calls = []
            def collect(name, command, **kwargs):
                calls.append((name, command, kwargs['evidence']))
            with patch.object(gate, 'command', side_effect=collect):
                gate.scoped_safety()
            self.assertEqual({name for name, _, _ in calls}, expected)
            for name, command, evidence in calls:
                self.assertEqual(evidence, out / name / 'report.json')
                self.assertIn('--out', command)
            bank = next(command for name, command, _ in calls if name == 'reply-banks')
            self.assertIn('--source', bank)
            serial = next(command for name, command, _ in calls if name == 'reply-integrity')
            self.assertEqual(serial[serial.index('--runtime') + 1], 'native')

    def test_new_scoped_reports_cannot_pass_missing_or_false_evidence(self):
        names = ('flood-queue-order', 'guard-progress', 'component-progress',
                 'reply-parser-control', 'reply-banks', 'reply-integrity')
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            gate = Gate(out, out, 'native')
            for name in names:
                evidence = out / (name + '.json')
                result = gate.command(name, [sys.executable, '-c', 'pass'], evidence=evidence)
                self.assertFalse(result['ok'], name)
                evidence.write_text(json.dumps({'ok': False}))
                result = gate.command(name + '-false', [sys.executable, '-c', 'pass'], evidence=evidence)
                self.assertFalse(result['ok'], name)

    def test_runtime_budget_rejects_timeout_and_stops_its_process(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            gate = Gate(out, out, 'native')
            gate.policy = {'command_timeout_seconds': .05, 'total_timeout_seconds': 1}
            with self.assertRaisesRegex(ValueError, 'runtime budget'):
                gate.command('timeout', [sys.executable, '-c', 'import time; time.sleep(20)'])
            self.assertFalse(gate.checks[0]['ok'])
            self.assertEqual(gate.checks[0]['exit_code'], 124)

    def test_exhausted_total_budget_does_not_start_another_command(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            gate = Gate(out, out, 'native')
            gate.policy = {'command_timeout_seconds': 1, 'total_timeout_seconds': 0}
            marker = out / 'must-not-exist'
            with self.assertRaisesRegex(ValueError, 'runtime budget'):
                gate.command('not-started', [sys.executable, '-c',
                             'from pathlib import Path; Path(' + repr(str(marker)) + ').touch()'])
            self.assertFalse(marker.exists())


if __name__ == '__main__':
    unittest.main()
