"""Fail-closed scoped frontend invariant evidence acceptance."""
import unittest

from verify_frontend_invariants_m5 import evaluate, evaluate_negative, NEGATIVES

VALID='''GlobalRenderUartLoop_test passed
M5_FRONTEND_OBSERVER ready_checks=2 bank_checks=12 commits=3 stage_writes=5 stale_events=2 aborts=0 sys_clocks=28000000
M5_FRONTEND_QUEUE depth=1152 clocks=28000000 adds=900 pops=900
M5_FRONTEND_PROGRESS completed=1 max_cycles=580 bound=870 selected_read_checks=1
'''

SUPPLEMENTAL=VALID.replace('GlobalRenderUartLoop_test','M5FrontendSupplemental_test').replace('ready_checks=2','ready_checks=7').replace('commits=3','commits=2').replace('stage_writes=5','stage_writes=8').replace('aborts=0','aborts=6').replace('completed=1','completed=6').replace('selected_read_checks=1','selected_read_checks=7')+'''M5_FRONTEND_SUPPLEMENTAL layouts=6 abort_cases=5
M5_SUPPLEMENTAL_LAYOUT empty count=0
M5_SUPPLEMENTAL_LAYOUT all-types-four-directions-corners count=5
M5_SUPPLEMENTAL_LAYOUT last-cell-horizontal-partner count=1
M5_SUPPLEMENTAL_LAYOUT last-cell-vertical-partner count=1
M5_SUPPLEMENTAL_LAYOUT deleted-last-cell-component count=0
M5_SUPPLEMENTAL_LAYOUT last-cell-origin count=1
M5_SUPPLEMENTAL_ABORT_CASE 1 status=83 valid=1
M5_SUPPLEMENTAL_ABORT_CASE 2 status=83 valid=1
M5_SUPPLEMENTAL_ABORT_CASE 3 status=83 valid=1
M5_SUPPLEMENTAL_ABORT_CASE 4 status=83 valid=1
M5_SUPPLEMENTAL_ABORT_CASE 5 status=05 valid=0
'''

RESTART='''M5FrontendRestart_test passed
M5_FRONTEND_OBSERVER ready_checks=8 bank_checks=0 commits=0 stage_writes=0 stale_events=0 aborts=0 sys_clocks=8000
M5_FRONTEND_QUEUE depth=1152 clocks=8000 adds=0 pops=0
M5_FRONTEND_RESTART completed=7 max_cycles=1090 bound=1744 edit_clocks=595
M5_FRONTEND_RESTART_FIXTURE cases=5 layouts=7
M5_SUPPLEMENTAL_LAYOUT restart-empty count=0
M5_SUPPLEMENTAL_LAYOUT restart-baseline count=2
M5_SUPPLEMENTAL_LAYOUT during-clear count=2
M5_SUPPLEMENTAL_LAYOUT during-scan count=2
M5_SUPPLEMENTAL_LAYOUT pending-pair count=2
M5_SUPPLEMENTAL_LAYOUT final-scan count=2
M5_SUPPLEMENTAL_LAYOUT registered-drain count=2
M5_SUPPLEMENTAL_RESTART_CASE during-clear phase=0 count=2 cycles=1090
M5_SUPPLEMENTAL_RESTART_CASE during-scan phase=1 count=2 cycles=730
M5_SUPPLEMENTAL_RESTART_CASE pending-pair phase=2 count=2 cycles=870
M5_SUPPLEMENTAL_RESTART_CASE final-scan phase=3 count=2 cycles=586
M5_SUPPLEMENTAL_RESTART_CASE registered-drain phase=4 count=2 cycles=586
'''


class FrontendEvidenceTests(unittest.TestCase):
    def test_restart_complete_scope(self):
        result=evaluate(RESTART,0,'restart');self.assertTrue(result['ok'])
        self.assertEqual(result['restart']['bound'],1744)
        self.assertEqual(len(result['restart_cases']),5)

    def test_restart_each_phase_and_layout_required(self):
        for line in RESTART.splitlines():
            if line.startswith(('M5_SUPPLEMENTAL_LAYOUT','M5_SUPPLEMENTAL_RESTART_CASE')):
                self.assertFalse(evaluate(RESTART.replace(line+'\n',''),0,'restart')['ok'])
                self.assertFalse(evaluate(RESTART+line+'\n',0,'restart')['ok'])

    def test_restart_deadline_and_completed_evidence_required(self):
        for old,new in [('bound=1744','bound=1745'),('max_cycles=1090','max_cycles=1745'),
                        ('completed=7','completed=0'),('edit_clocks=595','edit_clocks=0'),
                        ('cycles=1090','cycles=1745'),('cycles=730','cycles=0'),
                        ('ready_checks=8','ready_checks=7')]:
            self.assertFalse(evaluate(RESTART.replace(old,new),0,'restart')['ok'])
        marker='M5_FRONTEND_RESTART completed=7 max_cycles=1090 bound=1744 edit_clocks=595\n'
        self.assertFalse(evaluate(RESTART+marker,0,'restart')['ok'])

    def test_restart_literal_count_and_specific_assertion_required(self):
        self.assertFalse(evaluate(RESTART.replace('final-scan phase=3 count=2','final-scan phase=3 count=1'),0,'restart')['ok'])
        self.assertFalse(evaluate(RESTART,1,'restart')['ok'])
        log='M5_FRONTEND_FAILURE dirty restart progress'
        self.assertTrue(evaluate_negative(log,1,'restart-progress'))
        self.assertFalse(evaluate_negative('unrelated crash',1,'restart-progress'))
        self.assertFalse(evaluate_negative(log+'\nM5FrontendRestart_test passed',1,'restart-progress'))

    def test_scoped_complete_report(self):
        report=evaluate(VALID,0)
        self.assertTrue(report['ok'])
        self.assertEqual(report['observer']['aborts'],0)  # observed gap, not coverage

    def test_required_component_acceptance_boundaries(self):
        self.assertFalse(evaluate(VALID.replace('ready_checks=2','ready_checks=0'),0)['ok'])
        self.assertFalse(evaluate(VALID.replace('ready_checks=2','ready_checks=1'),0)['ok'])

    def test_no_commit_or_staged_data_exercise(self):
        for field,value in (('commits=3','commits=0'),('stage_writes=5','stage_writes=0'),('bank_checks=12','bank_checks=0')):
            self.assertFalse(evaluate(VALID.replace(field,value),0)['ok'])

    def test_stale_traffic_required(self):
        self.assertFalse(evaluate(VALID.replace('stale_events=2','stale_events=0'),0)['ok'])

    def test_no_queue_exercise(self):
        self.assertFalse(evaluate(VALID.replace('adds=900','adds=0'),0)['ok'])
        self.assertFalse(evaluate(VALID.replace('pops=900','pops=0'),0)['ok'])

    def test_actual_queue_geometry_required(self):
        self.assertFalse(evaluate(VALID.replace('depth=1152','depth=256'),0)['ok'])

    def test_missing_duplicate_or_malformed_observer(self):
        for log in (VALID.split('M5_FRONTEND_OBSERVER')[0],VALID+VALID,
                    VALID.replace('commits=3','commits=unknown')):
            self.assertFalse(evaluate(log,0)['ok'])

    def test_negative_requires_specific_assertion(self):
        log='M5_FRONTEND_FAILURE committed voltage data at node 0'
        self.assertTrue(evaluate_negative(log,1,'voltage-data'))
        self.assertFalse(evaluate_negative('unrelated crash',139,'voltage-data'))
        self.assertFalse(evaluate_negative(log,0,'voltage-data'))
        self.assertFalse(evaluate_negative(log+'\nGlobalRenderUartLoop_test passed',1,'voltage-data'))

    def test_failed_exit_or_observed_assertion(self):
        self.assertFalse(evaluate(VALID,1)['ok'])
        self.assertFalse(evaluate(VALID+'M5_FRONTEND_FAILURE component map\n',0)['ok'])

    def test_quiescent_progress_bound_required(self):
        for old,new in [('completed=1','completed=0'),('max_cycles=580','max_cycles=871'),
                        ('bound=870','bound=999'),('max_cycles=580','max_cycles=0')]:
            self.assertFalse(evaluate(VALID.replace(old,new),0)['ok'])
        self.assertFalse(evaluate(VALID+VALID.splitlines()[-1]+'\n',0)['ok'])

    def test_supplemental_complete_scope(self):
        report=evaluate(SUPPLEMENTAL,0,'supplemental')
        self.assertTrue(report['ok'])
        self.assertEqual(report['observer']['aborts'],6)
        self.assertEqual(report['progress']['completed'],6)

    def test_supplemental_missing_independent_abort_or_layout_cases(self):
        for line in [line for line in SUPPLEMENTAL.splitlines()
                     if line.startswith(('M5_SUPPLEMENTAL_LAYOUT','M5_SUPPLEMENTAL_ABORT_CASE'))]:
            self.assertFalse(evaluate(SUPPLEMENTAL.replace(line+'\n',''),0,'supplemental')['ok'])
            self.assertFalse(evaluate(SUPPLEMENTAL+line+'\n',0,'supplemental')['ok'])

    def test_supplemental_cancellation_and_read_coverage_required(self):
        for old,new in [('aborts=6','aborts=0'),('abort_cases=5','abort_cases=0'),
                        ('layouts=6','layouts=5'),('selected_read_checks=7','selected_read_checks=0'),
                        ('completed=6','completed=5')]:
            self.assertFalse(evaluate(SUPPLEMENTAL.replace(old,new),0,'supplemental')['ok'])

    def test_wrong_supplemental_status_or_component_counts_rejected(self):
        for old,new in [('status=05 valid=0','status=05 valid=1'),
                        ('all-types-four-directions-corners count=5','all-types-four-directions-corners count=0')]:
            self.assertFalse(evaluate(SUPPLEMENTAL.replace(old,new),0,'supplemental')['ok'])

    def test_every_specific_negative_requires_its_own_label(self):
        for kind,label in NEGATIVES.items():
            log='M5_FRONTEND_FAILURE '+label
            self.assertTrue(evaluate_negative(log,139,kind))
            self.assertFalse(evaluate_negative('unrelated crash',139,kind))
            self.assertFalse(evaluate_negative(log+'\nM5FrontendSupplemental_test passed',1,kind))


if __name__=='__main__':unittest.main()
