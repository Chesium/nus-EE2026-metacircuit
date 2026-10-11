"""Corruption checks for M4's saved-corpus reporter, using accepted RAM format."""
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).parent))
import functional_m4 as reporter


class CorpusEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / 'reference').mkdir()
        (self.root / 'rtl').mkdir()
        self.names = {'cellsRender': 'cells_render', 'cellsShadow': 'cells_shadow',
                      'values': 'values_shadow', 'valueUnits': 'value_units_shadow',
                      'componentStore': 'component_store', 'componentIndexMap': 'component_index_map'}
        checkpoint = {'label': 'boot', 'frame': 0, 'state': 'boot.state.json', 'ram': 'boot.ram.json'}
        self.write('reference/checkpoints.json', {'scenario': 'fixture', 'frameCount': 1,
                                                'names': self.names, 'checkpoints': [checkpoint]})
        self.write('reference/boot.state.json', {'frame': 0, 'tool': 'pan', 'toolIndex': 0,
                                               'wireVariant': 'wire', 'modeSelect': 15,
                                               'pan': {'x': 0, 'y': 0}, 'components': [], 'cells': []})
        dumps, paths = [], {}
        for key, width in [('cellsRender', 16), ('cellsShadow', 16), ('values', 12),
                           ('valueUnits', 4), ('componentStore', 40), ('componentIndexMap', 9)]:
            name = self.names[key]
            dump = {'name': name, 'frame': 0, 'width': width, 'depth': 288,
                    'words': ['0x1ff' if key == 'componentIndexMap' else '0x0'] * 288}
            dumps.append(dump)
            self.write('rtl/' + name + '.json', dump)
            paths[name] = [{'frame': 0, 'path': name + '.json'}]
        self.write('reference/boot.ram.json', dumps)
        probes = {'tool_idx': 0, 'wire_variant': 0, 'mode_select': 15, 'grid_pos_x': 0,
                  'grid_pos_y': 0, 'init_done': 1, 'interaction_idle': 1,
                  'interaction_frame_drop': 0, 'component_store_busy': 0, 'component_count': 0}
        self.write('rtl/report.json', {'ok': True, 'monitors': {'vga': {'frames': [
            {'index': 0, 'probes': probes}]}}, 'dumps': paths, 'stimulus': []})
        scenario = {'name': 'fixture', 'steps': [{'op': 'wait', 'frames': 1},
                                              {'op': 'checkpoint', 'label': 'boot'}]}
        self.write('scenario.json', scenario)
        self.write('case.json', {'seed': 1, 'scenario': scenario, 'blocks': []})
        self.write('canonical.json', {'name': 'fixture', 'frameCount': 1, 'frames': [
            {'x': 320, 'y': 240, 'left': False, 'middle': False, 'right': False}],
            'checkpoints': [{'label': 'boot', 'frame': 0}]})
        (self.root / 'stim.toml').write_text('# no changes\n')
        parent = {'ok': True, 'scenario': 'fixture', 'actual': str(self.root / 'rtl'),
                  'frameCount': 1, 'summary': {'checkpoints': 1, 'passed': 1, 'failed': 0},
                  'errors': [], 'checkpoints': [{'label': 'boot', 'frame': 0, 'ok': True, 'differences': []}]}
        self.write('summary.json', {'ok': True, 'seed': 1, 'runtime': 'native', 'frames_completed': 1,
                                   'first_divergence': None, 'comparisons': [parent],
                                   'initialization': {'seed': 1, 'seed_explicit': True, 'rand_reset': 2,
                                                      'x_initial': 'unique', 'x_assign': 'unique'}})

    def write(self, name, value):
        (self.root / name).write_text(json.dumps(value) + '\n')

    def change(self, name, edit):
        value = json.loads((self.root / name).read_text())
        edit(value)
        self.write(name, value)

    def test_intact_actual_format_evidence_passes_real_accepted_comparator(self):
        coverage, evidence = reporter.collect(self.root)
        self.assertIn('canvas:empty', coverage['reached'])
        self.assertTrue(evidence['accepted_comparator_rechecked'])
        self.assertIn('rtl/component_store.json', evidence['sha256'])
        self.assertIn('reference/boot.state.json', evidence['sha256'])

    def test_failing_parent_cannot_hide_behind_passing_child(self):
        self.change('summary.json', lambda s: s['comparisons'][0].update(ok=False))
        with self.assertRaisesRegex(ValueError, 'parent comparator'):
            reporter.collect(self.root)

    def test_parent_infrastructure_errors_are_rejected(self):
        self.change('summary.json', lambda s: s['comparisons'][0].update(errors=['late input']))
        with self.assertRaisesRegex(ValueError, 'parent comparator'):
            reporter.collect(self.root)

    def test_divergence_despite_saved_pass_is_rejected(self):
        self.change('summary.json', lambda s: s.update(first_divergence={'frame': 0}))
        with self.assertRaisesRegex(ValueError, 'divergence'):
            reporter.collect(self.root)

    def test_seed_and_runtime_are_validated(self):
        original = json.loads((self.root / 'summary.json').read_text())
        for delta in ({'seed': 2}, {'seed': True}, {'runtime': 'unknown'}):
            with self.subTest(delta=delta):
                self.write('summary.json', {**original, **delta})
                with self.assertRaisesRegex(ValueError, 'seed or invalid runtime'):
                    reporter.collect(self.root)

    def test_missing_canonical_checkpoint_is_rejected(self):
        self.change('canonical.json', lambda c: c.update(checkpoints=[]))
        with self.assertRaisesRegex(ValueError, 'canonical checkpoints'):
            reporter.collect(self.root)

    def test_missing_or_duplicated_parent_checkpoint_is_rejected(self):
        original = json.loads((self.root / 'summary.json').read_text())
        self.write('summary.json', {**original, 'comparisons': []})
        with self.assertRaisesRegex(ValueError, 'checkpoint evidence'):
            reporter.collect(self.root)
        self.write('summary.json', {**original, 'comparisons': original['comparisons'] * 2})
        with self.assertRaisesRegex(ValueError, 'checkpoint evidence'):
            reporter.collect(self.root)

    def test_parent_pass_count_disagreement_is_rejected(self):
        self.change('summary.json', lambda s: s['comparisons'][0]['summary'].update(passed=0))
        with self.assertRaisesRegex(ValueError, 'parent comparator'):
            reporter.collect(self.root)

    def test_missing_frame_and_late_stimulus_are_rejected(self):
        original = json.loads((self.root / 'rtl/report.json').read_text())
        self.change('rtl/report.json', lambda r: r['monitors']['vga'].update(frames=[]))
        with self.assertRaisesRegex(ValueError, 'simulation or late'):
            reporter.collect(self.root)
        self.write('rtl/report.json', {**original, 'stimulus': [{'late': True}]})
        with self.assertRaisesRegex(ValueError, 'simulation or late'):
            reporter.collect(self.root)

    def test_saved_pass_cannot_hide_mutated_actual_memory(self):
        self.change('rtl/values_shadow.json', lambda d: d['words'].__setitem__(0, '0x123'))
        with self.assertRaisesRegex(ValueError, 'accepted comparator rejected'):
            reporter.collect(self.root)

    def test_saved_pass_cannot_hide_mutated_reference_state(self):
        self.change('reference/boot.state.json', lambda s: s['cells'].append(
            {'col': 0, 'row': 0, 'sprite': 0, 'spriteName': 'Wire', 'rotation': 0,
             'meta': 0, 'componentSlot': None}))
        with self.assertRaisesRegex(ValueError, 'accepted comparator rejected'):
            reporter.collect(self.root)

    def test_saved_pass_cannot_hide_mutated_actual_probe(self):
        self.change('rtl/report.json', lambda r: r['monitors']['vga']['frames'][0]['probes'].update(init_done=0))
        with self.assertRaisesRegex(ValueError, 'accepted comparator rejected'):
            reporter.collect(self.root)


if __name__ == '__main__':
    unittest.main()
