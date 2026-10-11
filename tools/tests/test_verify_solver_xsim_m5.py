"""Actual-IP solver fixture and closed source-manifest regression checks."""
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
spec = importlib.util.spec_from_file_location('solver_xsim', TOOLS / 'verify_solver_xsim_m5.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


class SolverXsimTests(unittest.TestCase):
    def test_manifest_has_real_required_datapath_no_standins(self):
        paths = m.actual_sources()
        self.assertTrue(all(p.is_file() for p in paths))
        self.assertEqual(len(paths), len(set(paths)))
        self.assertIn('SimpleRam.v', [p.name for p in paths])
        self.assertIn('solve_core_dc.sv', [p.name for p in paths])
        self.assertIn('SolverBoard_top.sv', [p.name for p in paths])
        self.assertFalse(any('sim_models' in str(p) or 'FloatingPointIpModels' in p.name for p in paths))

    def test_effective_wrapper_override_changes_only_one_manifest_entry(self):
        baseline = m.actual_sources()
        with tempfile.TemporaryDirectory() as d:
            candidate = Path(d) / 'fpo_fma.v'
            replaced = m.actual_sources(candidate)
            differences = [(a, b) for a, b in zip(baseline, replaced) if a != b]
            self.assertEqual(len(differences), 1)
            self.assertEqual(differences[0][0].name, 'fpo_fma.v')
            self.assertEqual(differences[0][1], candidate.resolve())

    def test_solver_capacity_candidate_changes_only_solver_top(self):
        baseline = m.actual_sources()
        candidate = Path('/tmp/isolated/SolverBoard_top.sv')
        effective = m.actual_sources(solver_top=candidate)
        delta = [(a,b) for a,b in zip(baseline,effective) if a!=b]
        self.assertEqual(len(delta),1)
        self.assertEqual(delta[0][0].name,'SolverBoard_top.sv')
        self.assertEqual(delta[0][1],candidate.resolve())

    def test_real_uart_fixture_checksum_corruption_is_exactly_one_byte(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            data = m.write_fixtures(p, 20261010, 36)
            bad = data['bad_checksum']
            good = m.packet(bad[1:-3])
            self.assertEqual(good[:-2], bad[:-2])
            self.assertEqual(int(good[-2:], 16) ^ int(bad[-2:], 16), 1)
            self.assertEqual(len(data['analytical']), 36)
            lines = (p / 'M5SolverUartFixtures.svh').read_text()
            self.assertIn(m.packet('ER,FF10,01,0003'), lines)
            self.assertIn(m.packet('VB,FF30,01,05'), lines)
            self.assertIn('expect_nonfinite("@VN,FF30,00,")', lines)
            self.assertIn(m.packet('VE,FF30,01,05'), lines)
            self.assertEqual(json.loads((p / 'fixtures.json').read_text())['singular']['expected_status'], 5)
            # Successful circuit repeated after malformed header gives an exact recovery witness.
            self.assertEqual(lines.count(data['analytical'][0]['tx'][0]), 2)

    def test_actual_solver_corpus_seeded_and_exact(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            first = m.write_fixtures(p, 12, 36)
            fixture_bytes = (p / 'M5SolverUartFixtures.svh').read_bytes()
            self.assertEqual(first, m.write_fixtures(p, 12, 36))
            self.assertEqual(fixture_bytes, (p / 'M5SolverUartFixtures.svh').read_bytes())
            self.assertNotEqual(first, m.write_fixtures(p, 13, 36))
            for circuit in first['analytical']:
                for line in circuit['tx'] + circuit['rx']:
                    self.assertEqual(m.packet(line[1:-3]), line)

    def test_rational_oracle_known_bridge_and_source_polarity(self):
        from fractions import Fraction
        circuit = [(3, 0, 255, 8, 0), (1, 0, 1, 4, 0),
                   (1, 1, 2, 4, 0), (1, 2, 255, 8, 0)]
        self.assertEqual(m.rational_mna(circuit, 3), [8, 6, 4])
        circuit[0] = (3, 255, 0, 8, 0)
        self.assertEqual(m.rational_mna(circuit, 3), [-8, -6, -4])
        self.assertEqual(m.rational_mna([(2, 255, 0, 1, 1), (1, 0, 255, 2, 1)], 1),
                         [Fraction(2, 10**6)])
        with self.assertRaisesRegex(ValueError, 'singular'):
            m.rational_mna([(2, 0, 255, 1, 0)], 1)

    def test_general_corpus_capacity_units_and_kirchhoff_residual(self):
        from fractions import Fraction
        fixtures = m.general_fixtures(19)
        self.assertEqual(len(fixtures), 21)
        self.assertEqual(fixtures, m.general_fixtures(19))
        self.assertNotEqual(fixtures, m.general_fixtures(20))
        self.assertEqual({e[4] for f in fixtures for e in f['elements']}, set(range(7)))
        self.assertTrue(any(f['node_count']==32 for f in fixtures))
        self.assertTrue(any(len(f['elements'])==32 and f['node_count']==31 for f in fixtures))
        for f in fixtures:
            self.assertLessEqual(f['node_count']+sum(e[0]==3 for e in f['elements']), 32)
            self.assertLessEqual(len(f['elements']), 32)
            values = [Fraction(v) for v in f['expected_rational']]
            constrained = {n for k,a,b,v,u in f['elements'] if k==3 for n in (a,b)}
            for node in range(f['node_count']):
                if node in constrained:
                    continue
                current = Fraction(0)
                for kind,a,b,v,u in f['elements']:
                    va=Fraction(0) if a==255 else values[a]
                    vb=Fraction(0) if b==255 else values[b]
                    flow = (va-vb)/(v*m.UNIT_SCALE[u]) if kind==1 else v*m.UNIT_SCALE[u]
                    if a==node: current+=flow
                    if b==node: current-=flow
                self.assertEqual(current, 0, f['label'])
            for line in f['tx']:
                self.assertEqual(m.packet(line[1:-3]), line)

    def test_near_singular_accuracy_probe_keeps_exact_physics(self):
        from fractions import Fraction
        fixtures = m.general_fixtures(19, near_singular=True)
        self.assertEqual(len(fixtures), 22)
        near = fixtures[-1]
        self.assertEqual(near['label'], 'near_singular_coupled_milli_vs999')
        self.assertEqual([Fraction(v) for v in near['expected_rational']],
                         [1, Fraction(999001, 1998001), Fraction(999000, 1998001)])

    def test_augmented_capacity_probe_exceeds_combined_dimension_only(self):
        import probe_solver_capacity_xsim_m5 as probe
        tx = probe.capacity_packets()
        self.assertEqual(len(tx), 34)
        self.assertEqual(tx[0], m.packet('NB,FF40,20,20'))
        self.assertEqual(tx[-1], m.packet('NE,FF40,20,20'))
        components = [line[1:-3].split(',') for line in tx[1:-1]]
        self.assertEqual(sum(c[3]=='03' for c in components), 1)
        self.assertEqual([int(c[2],16) for c in components], list(range(32)))
        self.assertEqual({int(c[5],16) for c in components[1:]}, set(range(1,32)))
        for line in tx:
            self.assertEqual(m.packet(line[1:-3]), line)

    def test_actual_frontend_manifest_has_no_standins(self):
        import verify_solver_frontend_xsim_m5 as frontend
        sources = frontend.actual_frontend_sources()
        self.assertIn('GlobalRender_top.v', [p.name for p in sources])
        self.assertIn('SolverBoard_top.sv', [p.name for p in sources])
        self.assertIn('fpo_fma.v', [p.name for p in sources])
        self.assertNotIn('FloatingPointIpModels.sv', [p.name for p in sources])
        self.assertTrue(all(p.is_file() for p in sources))

    def test_capacity_probe_listens_during_transmission(self):
        import probe_solver_capacity_xsim_m5 as probe
        text = probe.capacity_include(probe.capacity_packets())
        self.assertTrue(text.startswith('fork\n'))
        self.assertIn('\n  begin\n    expect_capacity();\n  end\njoin\n', text)
        self.assertEqual(text.count('send_uart_line('), 34)
        self.assertIn('if(solvestart!=-1)', text)

    def test_capacity_top_override_is_explicit_and_single_source(self):
        import probe_solver_capacity_xsim_m5 as probe
        bench = Path('/tmp/M5SolverCapacityXsim.sv')
        candidate = Path('/tmp/isolated/SolverBoard_top.sv')
        original = probe.capacity_sources(bench)
        effective = probe.capacity_sources(bench,candidate)
        delta = [(a,b) for a,b in zip(original,effective) if a!=b]
        self.assertEqual(len(delta),1)
        self.assertEqual(delta[0][0].name,'SolverBoard_top.sv')
        self.assertEqual(delta[0][1],candidate.resolve())
        self.assertEqual(effective[-1],bench)


if __name__ == '__main__':
    unittest.main()
