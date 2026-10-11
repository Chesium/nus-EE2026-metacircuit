"""Bounded lockstep adapter tests: comparator and early stop remain observable."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

PATH = Path(__file__).with_name('lockstep_m4.py')
SPEC = importlib.util.spec_from_file_location('lockstep_m4', PATH)
m4 = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(m4)


class FakeSession:
    def __init__(self):
        self.completed = 0
        self.calls = []

    def request(self, value):
        self.calls.append(value)
        if value['op'] == 'step':
            frame = self.completed
            self.completed += 1
            return {'ok': True, 'completed_frames': self.completed, 'probes': {'component_count': 3},
                    'events': [{'event': 'frame', 'monitor': 'vga', 'index': frame, 'crc32': '1234'}]}
        if value['op'] == 'memory':
            return {'ok': True, 'memory': {'name': value['name'], 'frame': self.completed - 1,
                                          'width': 16, 'depth': 1, 'words': ['0x0000']}}
        return {'ok': True}


class LockstepTest(unittest.TestCase):
    def fixture(self, root, failed):
        canonical = {'frameCount': 7}
        index = {'names': {'a': 'cells'}, 'checkpoints': [
            {'frame': 1, 'label': 'first'}, {'frame': 3, 'label': 'second'}, {'frame': 6, 'label': 'third'}]}
        session = FakeSession()
        compared = []

        def compare(actual, reference, checkpoint, completed, folder):
            compared.append(checkpoint['frame'])
            report = m4.read(actual / 'report.json')
            self.assertEqual(len(report['monitors']['vga']['frames']), completed)
            self.assertEqual(report['dumps']['cells'][-1]['frame'], completed - 1)
            return {'ok': checkpoint['frame'] != failed, 'checkpoints': [{'frame': checkpoint['frame']}]}

        result = m4.lockstep(session, canonical, index, {0: {'mouse.left': 1}, 4: {'mouse.left': 0}}, root,
                             compare=compare)
        return result, session, compared

    def test_first_divergence_stops_before_later_inputs_or_steps(self):
        with tempfile.TemporaryDirectory() as tmp:
            result, session, compared = self.fixture(Path(tmp), failed=3)
            self.assertFalse(result['ok'])
            self.assertEqual(result['frames_completed'], 4)
            self.assertEqual(compared, [1, 3])
            self.assertEqual(result['first_divergence']['frame'], 3)
            self.assertEqual([x['id'] for x in session.calls if x['op'] == 'poke'], ['input-0'])
            saved = m4.read(Path(tmp) / 'first-divergence.json')
            self.assertEqual([f['index'] for f in saved['trace_window']], [0, 1, 2, 3])
            requests = [json.loads(line) for line in (Path(tmp) / 'requests.jsonl').read_text().splitlines()]
            self.assertEqual(requests, session.calls)

    def test_pass_steps_all_frames_and_compares_only_checkpoints(self):
        with tempfile.TemporaryDirectory() as tmp:
            result, session, compared = self.fixture(Path(tmp), failed=-1)
            self.assertTrue(result['ok'])
            self.assertEqual(result['frames_completed'], 7)
            self.assertEqual(compared, [1, 3, 6])
            self.assertEqual(len([r for r in session.calls if r['op'] == 'memory']), 3)

    def test_boundary_mismatch_fails_closed(self):
        with self.assertRaisesRegex(RuntimeError, 'boundary'):
            m4.collect_frame({'completed_frames': 8}, 0, [], [])

    def test_replay_is_cold_bounded_trace(self):
        spec = m4.replay_spec(Path('/fs'), Path('/config'), Path('/out'), 17, 8)
        self.assertEqual((spec['trace_from'], spec['trace_frames']), (5, 4))
        self.assertIn('--seed', spec['argv'])
        self.assertNotIn('--checkpoint', spec['argv'])
        self.assertEqual(spec['argv'][spec['argv'].index('-n') + 1], '9')

    def test_cold_replay_requires_same_failure_seed_and_memory(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for folder in ('reference', 'rtl/dumps/cells', 'cold-replay/dumps/cells'):
                (root / folder).mkdir(parents=True)
            initialization = {'seed': 12, 'rand_reset': 2}
            m4.write(root / 'reference/checkpoints.json', {'names': {'logical': 'cells'}})
            report = {'ok': True, 'sim': {'initialization': initialization}}
            m4.write(root / 'cold-replay/report.json', report)
            memory = {'name': 'cells', 'frame': 2, 'width': 16, 'depth': 1, 'words': ['0x0001']}
            for directory in ('rtl', 'cold-replay'):
                m4.write(root / directory / 'dumps/cells/frame_0002.json', memory)
            failure = {'ok': False, 'checkpoints': [{'differences': ['wire variant differs']}]}
            divergence = {'frame': 2, 'checkpoint': {'label': 'bad'}, 'comparison': failure}
            verify = lambda result: m4.verify_cold_replay(root, divergence, initialization,
                                                        compare=lambda *args: result)
            self.assertTrue(verify(failure)['reproduced'])
            self.assertFalse(verify({'ok': True, 'checkpoints': [{'differences': []}]})['reproduced'])
            m4.write(root / 'cold-replay/dumps/cells/frame_0002.json', {**memory, 'words': ['0x0002']})
            self.assertFalse(verify(failure)['reproduced'])
            m4.write(root / 'cold-replay/dumps/cells/frame_0002.json', memory)
            m4.write(root / 'cold-replay/report.json', {**report, 'sim': {'initialization': {'seed': 7}}})
            self.assertFalse(verify(failure)['reproduced'])


if __name__ == '__main__':
    unittest.main()
