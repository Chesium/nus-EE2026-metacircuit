"""Deterministic fixture/oracle and fail-closed M5-5 regression policy tests."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

FILE = Path(__file__).resolve().parents[1] / 'verify_solver_m5.py'
spec = importlib.util.spec_from_file_location('solver_m5', FILE)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class SolverQualificationTests(unittest.TestCase):
    def test_extraction_corpus_covers_every_kind_rotation_pair(self):
        cases = m.extraction_fixtures(20261010, 320)
        self.assertEqual(len(cases), 320)
        self.assertEqual({(c['type'], c['rotation']) for c in cases},
                         {(t, r) for t in (5, 7, 9, 11, 13) for r in range(4)})
        self.assertTrue(any(c['nodes'] == [255, 255] for c in cases))
        self.assertTrue(any(c['nodes'] == [0, 1] for c in cases))
        self.assertTrue(any(c['nodes'] == [1, 0] for c in cases))
        self.assertTrue(any(e['x'] < 0 or e['x'] >= 6 or e['y'] < 0 or e['y'] >= 6
                            for c in cases for e in c['ends']))

    def test_current_polarity_floating_rows_are_n0_then_n1(self):
        cases = m.extraction_fixtures(4, 320)
        for c in cases:
            if c['type'] == 9 and c['ends'][0]['mode'] == 'ground' and c['ends'][1]['mode'] == 'open':
                self.assertEqual(c['nodes'], [0, 255])
                break
        else:
            self.fail('current polarity fixture missing')
        for c in cases:
            if all(e['mode'] in ('open', 'nonfacing') for e in c['ends']):
                self.assertEqual(c['nodes'], [0, 1])

    def test_corpus_reproducible_and_seed_affects_positions(self):
        self.assertEqual(m.extraction_fixtures(42, 320), m.extraction_fixtures(42, 320))
        self.assertNotEqual(m.extraction_fixtures(42, 320), m.extraction_fixtures(43, 320))
        self.assertEqual(m.solver_fixtures(42, 36), m.solver_fixtures(42, 36))
        self.assertNotEqual(m.solver_fixtures(42, 36), m.solver_fixtures(43, 36))

    def test_uart_expected_values_are_independent_circuit_laws(self):
        fixtures = m.solver_fixtures(12, 36)
        for f in fixtures:
            if f['mode'] == 0:
                self.assertEqual(f['nodes'], [m.fp32(f['elements'][0][3])])
            elif f['mode'] == 1:
                v = f['elements'][0][3]
                self.assertEqual(f['nodes'], [m.fp32(v), m.fp32(v / 2)])
            else:
                current, resistance = f['elements']
                expected = current[3] * resistance[3] * (1 if current[1] == 255 else -1)
                self.assertEqual(f['nodes'], [m.fp32(expected)])
            for line in f['tx'] + f['rx']:
                self.assertEqual(m.packet(line[1:-3]), line)

    def test_xci_audit_catches_real_latency_mismatch(self):
        fma = m.ip_configuration(m.ROOT / 'src/ip/floating_point_fma/floating_point_fma.xci')
        div = m.ip_configuration(m.ROOT / 'src/ip/floating_point_div/floating_point_div.xci')
        self.assertEqual(fma['parameters']['C_Latency'], '16')
        self.assertEqual(div['parameters']['C_Latency'], '28')
        self.assertNotEqual(int(fma['parameters']['C_Latency']), 4)
        self.assertNotEqual(int(div['parameters']['C_Latency']), 6)

    def test_all_provisional_passes_never_promote_fp_standins(self):
        report = {'benches': {name: {'passed': True, 'negative_control_detected': True}
                              for name in ('M5SolverExtraction', 'M5SolverUart', 'M5SolverFrontend')}}
        status = m.readiness(report)
        self.assertFalse(status['ready'])
        self.assertTrue(any('primitive' in b for b in status['blockers']))
        # Spoofed claim cannot bypass the policy without executable qualification.
        report['standins'] = {'validated': True}
        self.assertFalse(m.readiness(report)['ready'])
        report['benches']['M5SolverUart']['passed'] = False
        self.assertTrue(any('M5SolverUart' in b for b in m.readiness(report)['blockers']))

    def test_missing_fault_control_and_evidence_rejected(self):
        status = m.readiness({'benches': {'M5SolverExtraction': {'passed': True}}})
        self.assertFalse(status['ready'])
        self.assertTrue(any('negative' in b for b in status['blockers']))
        self.assertTrue(any('three' in b for b in status['blockers']))

    def test_extraction_scope_needs_complete_current_seeded_stall_evidence(self):
        report = {'runtime': 'docker', 'tool_version': 'Verilator 5.020 pinned',
                  'tool': {'returncode': 0}, 'source_drift': [],
                  'benches': {'M5SolverExtraction': {'passed': True,
                    'negative_control_detected': True, 'observed_cases': 320, 'stall_cycles': 7}}}
        self.assertTrue(m.extraction_qualification(report, 320))
        for field, value in [('passed', False), ('negative_control_detected', False),
                             ('observed_cases', 319), ('stall_cycles', 0), ('stall_cycles', True)]:
            changed = json.loads(json.dumps(report))
            changed['benches']['M5SolverExtraction'][field] = value
            self.assertFalse(m.extraction_qualification(changed, 320), field)
        for field, value in [('source_drift', ['changed.sv']), ('source_drift', None),
                             ('tool_version', 'Verilator 5.046 other runtime'), ('tool', {'returncode': 1})]:
            self.assertFalse(m.extraction_qualification({**report, field: value}, 320), field)
        self.assertFalse(m.readiness(report)['ready'])

    def test_fixture_artifacts_are_self_contained(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            extraction, solver = m.extraction_fixtures(1, 320), m.solver_fixtures(1, 3)
            m.write_fixtures(p, extraction, solver)
            fixture = json.loads((p / 'fixtures.json').read_text())
            self.assertEqual(fixture['extraction'], extraction)
            self.assertEqual(len(fixture['solver']), len(solver))
            self.assertEqual((p / 'M5SolverExtractionFixtures.svh').read_text().count('run_fixture('), 320)
            self.assertIn('expect_line("@VN,', (p / 'M5SolverUartFixtures.svh').read_text())


if __name__ == '__main__':
    unittest.main()
