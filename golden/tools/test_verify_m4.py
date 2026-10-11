"""M4 evidence must fail closed and functional bins require observed passing state."""
import importlib.util
import copy
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('verify_m4', Path(__file__).with_name('verify_m4.py'))
m4 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m4)


class FunctionalCoverageTests(unittest.TestCase):
    def coverage(self, states, blocks=None, failed=(), rtl_words=None):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            checkpoints = [{'label': f'operation_{i}', 'frame': i, 'state': f'{i}.json'}
                           for i in range(len(states))]
            m4.write(root / 'checkpoints.json', {'checkpoints': checkpoints,
                                                'names': {'componentStore': 'component_store'}})
            for i, state in enumerate(states):
                m4.write(root / f'{i}.json', state)
            if rtl_words is not None:
                dumps = []
                for i, words in enumerate(rtl_words):
                    path = root / f'dump-{i}.json'
                    m4.write(path, {'frame': i, 'width': 40, 'depth': 288,
                                    'words': words + ['0xdeadbeef00'] * (288 - len(words))})
                    dumps.append({'frame': i, 'path': str(path)})
                m4.write(root / 'report.json', {'dumps': {'component_store': dumps}})
            return m4.functional_coverage(root, {'checkpoints': [
                {'label': c['label'], 'frame': c['frame'], 'ok': i not in failed}
                for i, c in enumerate(checkpoints)]}, blocks, rtl=root if rtl_words is not None else None)

    def test_properties_and_partner_require_verified_endpoint_changes(self):
        component = {'slot': 0, 'col': 2, 'row': 1, 'kind': 'resistor', 'rotation': 0,
                     'cells': [{'col': 2, 'row': 1}, {'col': 3, 'row': 1}], 'valueBcd': 0x100, 'unit': 0}
        initial = {'tool': 'pan', 'components': [component], 'cells': []}
        edited = copy.deepcopy(initial)
        edited['components'][0].update(valueBcd=0x123, unit=6)
        blocks = [[], [{'op': 'click_cell', 'cell': [3, 1]}, {'op': 'click', 'x': 280, 'y': 34}]]
        result = self.coverage([initial, edited], blocks)
        for name in ('component:unit:6', 'edit:property_value', 'edit:property_unit',
                     'input:partner_half', 'edit:property_from_partner'):
            self.assertIn(name, result['reached'])
            self.assertEqual(result['witnesses'][name]['frame'], 1)
        self.assertNotIn('edit:property_from_partner', self.coverage([initial, edited], blocks, failed=(0,))['reached'])
        blocks[1][0]['pan'] = [0, -224]  # The intended partner click is physically outside the canvas.
        self.assertNotIn('input:partner_half', self.coverage([initial, edited], blocks)['reached'])

    def test_density_capacity_and_toolbar_only_noop(self):
        full = {'tool': 'resistor', 'components': [], 'cells': [
            {'col': col, 'row': row, 'sprite': 0, 'rotation': 0, 'componentSlot': None}
            for row in range(16) for col in range(18)]}
        blocks = [[], [{'op': 'click_tool', 'tool': 'resistor'}, {'op': 'click_cell', 'cell': [17, 0]}]]
        result = self.coverage([full, full], blocks)
        for name in ('canvas:dense', 'canvas:full', 'edit:blocked_placement',
                     'edit:boundary_blocked', 'edit:capacity_blocked'):
            self.assertIn(name, result['reached'])
        blocks[1].pop()
        self.assertNotIn('edit:blocked_placement', self.coverage([full, full], blocks)['reached'])

    def test_same_wire_repaint_is_not_blocked_and_tool_follows_click_order(self):
        wire = {'col': 1, 'row': 1, 'sprite': 0, 'rotation': 0, 'componentSlot': None}
        state = {'tool': 'wire', 'components': [], 'cells': [wire]}
        blocks = [[], [{'op': 'click_tool', 'tool': 'wire'}, {'op': 'click_cell', 'cell': [1, 1]}]]
        self.assertNotIn('edit:blocked_placement', self.coverage([state, state], blocks)['reached'])
        blocks[1].append({'op': 'click_tool', 'tool': 'resistor'})
        selected = copy.deepcopy(state)
        selected['tool'] = 'resistor'
        self.assertNotIn('edit:blocked_placement', self.coverage([state, selected], blocks)['reached'])
        protected = copy.deepcopy(state)
        protected['cells'][0]['componentSlot'] = 0
        protected['components'] = [{'slot': 0, 'col': 1, 'row': 1, 'kind': 'resistor', 'rotation': 0}]
        self.assertIn('edit:blocked_placement', self.coverage([protected, protected], blocks)['reached'])

    def test_actual_slots_ignore_random_tail_and_reset_after_failed_endpoint(self):
        c = lambda slot, col: {'slot': slot, 'col': col, 'row': 1, 'kind': 'resistor', 'rotation': 0}
        states = [{'tool': 'pan', 'components': [c(7, 1)], 'cells': []},
                  {'tool': 'delete', 'components': [], 'cells': []},
                  {'tool': 'resistor', 'components': [c(9, 3)], 'cells': []}]
        words = [['0x21'], [], ['0x23']]
        self.assertIn('edit:slot_reuse', self.coverage(states, rtl_words=words)['reached'])
        self.assertNotIn('edit:slot_reuse', self.coverage(states, failed=(1,), rtl_words=words)['reached'])
        self.assertNotIn('edit:slot_reuse', self.coverage(states)['reached'])

    def test_packed_store_compaction_does_not_infer_freed_occupied_slot(self):
        c = lambda slot, col: {'slot': slot, 'col': col, 'row': 1, 'kind': 'resistor', 'rotation': 0}
        state = lambda components: {'tool': 'pan', 'components': components, 'cells': []}
        # Delete first anchor. The survivor moves from RTL slot1 to slot0.
        # Reintroducing an earlier anchor shifts that survivor back to slot1;
        # the new anchor occupies continuously-live slot0, not the freed slot1.
        states = [state([c(0, 1), c(1, 3)]), state([c(1, 3)]), state([c(0, 1), c(1, 3)])]
        words = [['0x21', '0x23'], ['0x23'], ['0x21', '0x23']]
        self.assertNotIn('edit:slot_reuse', self.coverage(states, rtl_words=words)['reached'])
        # Appending a later anchor instead uses the proven-freed actual slot1.
        states[-1] = state([c(1, 3), c(2, 5)])
        words[-1] = ['0x23', '0x25']
        self.assertIn('edit:slot_reuse', self.coverage(states, rtl_words=words)['reached'])

    def test_golden_slot_renumbering_is_not_a_semantic_placement(self):
        initial = {'tool': 'pan', 'cells': [], 'components': [
            {'slot': 0, 'col': 1, 'row': 1, 'kind': 'resistor', 'rotation': 0}]}
        renumbered = copy.deepcopy(initial)
        renumbered['components'][0]['slot'] = 9
        result = self.coverage([initial, renumbered])
        self.assertNotIn('edit:placed:resistor', result['reached'])
        self.assertNotIn('edit:deleted_component', result['reached'])

    def test_comparison_frame_identity_and_unique_labels(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            m4.write(root / 'checkpoints.json', {'checkpoints': [
                {'label': 'boot', 'frame': 2, 'state': 'boot.json'}]})
            m4.write(root / 'boot.json', {'tool': 'pan', 'components': [], 'cells': []})
            verdict = {'label': 'boot', 'frame': 3, 'ok': True}
            self.assertEqual(m4.functional_coverage(root, {'checkpoints': [verdict]})['reached'], [])
            with self.assertRaisesRegex(ValueError, 'duplicate'):
                m4.functional_coverage(root, {'checkpoints': [verdict, verdict]})

    def test_union_rejects_missing_witness_and_incompatible_scope(self):
        report = self.coverage([{'tool': 'pan', 'components': [], 'cells': []}])
        self.assertEqual(m4.functional_union([report, report])['reached'], report['reached'])
        bad = copy.deepcopy(report)
        bad['witnesses'].clear()
        with self.assertRaisesRegex(ValueError, 'witness'):
            m4.functional_union([report, bad])
        bad = copy.deepcopy(report)
        bad['excluded'].clear()
        with self.assertRaisesRegex(ValueError, 'incompatible'):
            m4.functional_union([report, bad])

    def test_failed_checkpoints_cannot_claim_bins(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            m4.write(root / 'checkpoints.json', {'checkpoints': [
                {'label': 'failed', 'state': 'state.json'}]})
            m4.write(root / 'state.json', {'tool': 'rotate', 'components': [
                {'kind': 'resistor', 'rotation': 3}], 'cells': [{'col': 0, 'row': 15}]})
            missing = m4.functional_coverage(root, {'checkpoints': [{'label': 'failed', 'ok': False}]})
            self.assertEqual(missing['reached'], [])
            observed = m4.functional_coverage(root, {'checkpoints': [{'label': 'failed', 'ok': True}]})
            self.assertIn('component:resistor:rotation:3', observed['reached'])
            self.assertIn('edge:bottom', observed['reached'])
            self.assertIn('edge:top', observed['uncovered'])

    def test_edit_bins_need_consecutive_passing_checkpoints(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            r = lambda slot, rot: {'slot': slot, 'kind': 'resistor', 'rotation': rot, 'col': 1, 'row': 1}
            occupied = [{'col': 1, 'row': 1, 'sprite': 5, 'rotation': 0, 'componentSlot': 0}]
            states = [{'tool': 'resistor', 'components': [r(0, 0)], 'cells': []},
                      {'tool': 'rotate', 'components': [r(0, 1)], 'cells': []},
                      {'tool': 'delete', 'components': [], 'cells': []},
                      {'tool': 'resistor', 'components': [r(0, 0)], 'cells': occupied},
                      {'tool': 'resistor', 'components': [r(0, 0)], 'cells': occupied}]
            m4.write(root / 'checkpoints.json', {'checkpoints': [
                {'label': f'operation_{i}', 'state': f'{i}.json'} for i in range(len(states))]})
            for i, state in enumerate(states):
                m4.write(root / f'{i}.json', state)
            blocks = [[{'op': 'click_tool', 'tool': s['tool']}, {'op': 'click_cell', 'cell': [1, 1], 'hold': 1}]
                      for s in states]
            blocks[4][1]['hold'] = 9
            ok = lambda failed=(): {'checkpoints': [{'label': f'operation_{i}', 'ok': i not in failed}
                                                    for i in range(len(states))]}
            full = m4.functional_coverage(root, ok(), blocks)['reached']
            for name in ['edit:rotated_component', 'edit:deleted_component', 'edit:placed:resistor',
                         'edit:blocked_placement', 'input:held_click', 'store:empty']:
                self.assertIn(name, full)
            # A failed endpoint breaks the chain: no edit bin may span it.
            broken = m4.functional_coverage(root, ok(failed=(2,)), blocks)['reached']
            for name in ['edit:deleted_component', 'edit:slot_reuse', 'store:empty']:
                self.assertNotIn(name, broken)
            self.assertNotIn('input:held_click', m4.functional_coverage(root, ok(), None)['reached'])
            self.assertNotIn('edit:slot_reuse', full)  # Golden slots do not establish RTL reuse.

    def test_manifest_keeps_design_and_stub_paths(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            example = root / 'examples/metacircuit'
            (example / 'stubs').mkdir(parents=True)
            (example / 'stubs/MouseCtl.sv').write_text('module MouseCtl; endmodule')
            (example / 'framescope.toml').write_text('[design]\nextra_sources = ["stubs/*.sv"]\n')
            output = root / 'out'
            output.mkdir()
            path = m4.prepare_manifest(root, output, True)
            import tomllib
            data = tomllib.loads(path.read_text())
            self.assertEqual(data['design']['extra_sources'], [str(example / 'stubs/MouseCtl.sv')])
            self.assertTrue(data['build']['coverage'])
            self.assertEqual(data['build']['x_initial'], 'unique')

    def test_changed_manifest_assumptions_fail(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            example = root / 'examples/metacircuit'
            (example / 'stubs').mkdir(parents=True)
            (example / 'stubs/a.sv').touch()
            (example / 'framescope.toml').write_text('[build]\nthreads=2\n')
            with self.assertRaisesRegex(ValueError, 'changed'):
                m4.prepare_manifest(root, root, False)


if __name__ == '__main__':
    unittest.main()
