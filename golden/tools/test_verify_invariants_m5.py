"""Fail-closed checks for scoped invariant evidence acceptance."""
import unittest

from pathlib import Path
from verify_invariants_m5 import REPO, evaluate_negative, evaluate_normal, runtime_path


VALID = '''M5_INVARIANT_SCENARIO settled_checks=42 commits=16 reads=21 replies=21 max_progress=30 directed_read_stall=19 directed_write_stall=19 response_delay=3
M5CanvasInvariants_test passed.
M5_INVARIANT_CHANNEL controller.request stalled_reads=18 stalled_writes=26 accepted_reads=4 accepted_writes=25
M5_INVARIANT_CHANNEL guard.background stalled_reads=50 stalled_writes=12 accepted_reads=21 accepted_writes=16
'''


class InvariantAcceptanceTests(unittest.TestCase):
    def check_rejected(self, log=VALID, code=0, delay=3):
        self.assertFalse(evaluate_normal(log, code, delay)['ok'])

    def test_docker_output_nested_in_readonly_repo(self):
        out = REPO / 'golden/out/m5-invariants/example'
        self.assertEqual(runtime_path(out / 'build/bin', 'docker', out), '/out/build/bin')
        self.assertEqual(runtime_path(REPO / 'src/design/test.v', 'docker', out), '/source/src/design/test.v')
        self.assertEqual(runtime_path(out / 'build/bin', 'native', out), str(out / 'build/bin'))

    def test_docker_output_outside_repo(self):
        out = Path('/tmp/m5-out')
        self.assertEqual(runtime_path(out / 'build/bin', 'docker', out), '/out/build/bin')

    def test_complete_scoped_report(self):
        self.assertTrue(evaluate_normal(VALID, 0, 3)['ok'])

    def test_missing_channel(self):
        self.check_rejected(VALID.split('M5_INVARIANT_CHANNEL guard.background')[0])

    def test_duplicate_channel(self):
        self.check_rejected(VALID + VALID.splitlines()[-1] + '\n')

    def test_no_upstream_stalls(self):
        self.check_rejected(VALID.replace('stalled_reads=18', 'stalled_reads=0'))
        self.check_rejected(VALID.replace('stalled_writes=26', 'stalled_writes=0'))

    def test_no_memory_write_stalls(self):
        self.check_rejected(VALID.replace('stalled_writes=12', 'stalled_writes=0'))

    def test_omitted_or_duplicate_commit(self):
        for count in (15, 17):
            self.check_rejected(VALID.replace('commits=16', f'commits={count}'))

    def test_reply_loss_or_duplication(self):
        for count in (20, 22):
            self.check_rejected(VALID.replace('replies=21', f'replies={count}'))

    def test_wrong_delay(self):
        self.check_rejected(delay=9)

    def test_missing_or_duplicate_scenario(self):
        self.check_rejected('\n'.join(VALID.splitlines()[1:]))
        self.check_rejected(VALID + VALID.splitlines()[0] + '\n')

    def test_progress_outside_bound(self):
        self.check_rejected(VALID.replace('max_progress=30', 'max_progress=77'))

    def test_exit_or_assertion_is_failure(self):
        self.check_rejected(code=1)
        self.check_rejected(VALID + 'M5_INVARIANT_FAILURE extra\n')

    def test_negative_control_requires_specific_failure(self):
        self.assertTrue(evaluate_negative('M5_INVARIANT_FAILURE commit sequence mismatch', 1, 'commit-corruption'))
        self.assertFalse(evaluate_negative('unrelated crash', 1, 'commit-corruption'))
        self.assertFalse(evaluate_negative('M5_INVARIANT_FAILURE commit sequence mismatch', 0, 'commit-corruption'))
        self.assertFalse(evaluate_negative('M5_INVARIANT_FAILURE commit sequence mismatch\nM5CanvasInvariants_test passed.', 1, 'commit-corruption'))


if __name__ == '__main__':
    unittest.main()
