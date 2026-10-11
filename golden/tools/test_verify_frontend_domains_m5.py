"""Fail-closed acceptance controls for separate actual RTL domain fixtures."""
import unittest
from verify_frontend_domains_m5 import evaluate,evaluate_negative,NEGATIVES,LAYOUTS,VALUES,SELECTIONS,PHASES

VALID='''M5FrontendDomains_test passed
M5_FRONTEND_DOMAINS layouts=15 keyboard_events=41 selections=8 phases=4 blocked_clocks=20 capacity=144
M5_FRONTEND_OBSERVER ready_checks=16 bank_checks=0 commits=0 stage_writes=0 stale_events=0 aborts=0 sys_clocks=20000
M5_FRONTEND_PROGRESS completed=15 max_cycles=726 bound=870 selected_read_checks=8
M5_FRONTEND_RESTART completed=15 max_cycles=1442 bound=1744 edit_clocks=1300
M5_FRONTEND_QUEUE depth=1152 clocks=20000 adds=0 pops=0
'''
VALID+=''.join(f'M5_DOMAINS_LAYOUT {label} count={count}\n' for label,count in LAYOUTS)
VALID+=''.join(f'M5_DOMAINS_VALUE {label} origin={origin} partner={partner} bcd={bcd} unit={unit}\n' for label,origin,partner,bcd,unit in VALUES)
VALID+=''.join(f'M5_DOMAINS_SELECTION {label} addr={addr} enabled={enabled}\n' for label,addr,enabled in SELECTIONS)
VALID+=''.join(f'M5_DOMAINS_PHASE {label} phase={phase}\n' for label,phase in PHASES)

class DomainEvidenceTests(unittest.TestCase):
    def test_full_finite_scope(self):
        result=evaluate(VALID,0);self.assertTrue(result['ok']);self.assertEqual(result['domain']['capacity'],144)

    def test_each_literal_case_missing_duplicate_or_reordered_fails(self):
        for prefix in ('M5_DOMAINS_LAYOUT','M5_DOMAINS_VALUE','M5_DOMAINS_SELECTION','M5_DOMAINS_PHASE'):
            rows=[r for r in VALID.splitlines() if r.startswith(prefix)]
            for row in rows:
                self.assertFalse(evaluate(VALID.replace(row+'\n',''),0)['ok'])
                self.assertFalse(evaluate(VALID+row+'\n',0)['ok'])
            swapped=VALID.replace(rows[0]+'\n','SWAP\n').replace(rows[1]+'\n',rows[0]+'\n').replace('SWAP\n',rows[1]+'\n')
            self.assertFalse(evaluate(swapped,0)['ok'])

    def test_wrong_capacity_zero_keyboard_or_missing_stall_fails(self):
        for old,new in [('capacity=144','capacity=143'),('keyboard_events=41','keyboard_events=0'),
                        ('blocked_clocks=20','blocked_clocks=0'),('phases=4','phases=3'),('selections=8','selections=7'),
                        ('layouts=15','layouts=14')]:self.assertFalse(evaluate(VALID.replace(old,new),0)['ok'])

    def test_literal_value_unit_geometry_selection_and_count_fails(self):
        for old,new in [('bcd=123 unit=1','bcd=124 unit=1'),('bcd=045 unit=2','bcd=045 unit=3'),
                        ('origin=2 partner=20','origin=2 partner=21'),('last-origin addr=287','last-origin addr=286'),
                        ('disabled addr=0 enabled=0','disabled addr=0 enabled=1'),('capacity-144 count=144','capacity-144 count=143')]:
            self.assertFalse(evaluate(VALID.replace(old,new),0)['ok'])

    def test_current_source_bounds_and_completion_required(self):
        for old,new in [('bound=870','bound=871'),('bound=1744','bound=1745'),('max_cycles=726','max_cycles=871'),
                        ('max_cycles=1442','max_cycles=1745'),('max_cycles=726','max_cycles=0'),
                        ('max_cycles=1442','max_cycles=0'),('completed=15 max_cycles=1442','completed=14 max_cycles=1442'),
                        ('edit_clocks=1300','edit_clocks=0'),('selected_read_checks=8','selected_read_checks=0')]:
            self.assertFalse(evaluate(VALID.replace(old,new),0)['ok'])

    def test_missing_duplicate_or_malformed_summary_fails(self):
        for row in VALID.splitlines():
            if row.startswith(('M5_FRONTEND_','M5FrontendDomains')):
                self.assertFalse(evaluate(VALID.replace(row+'\n',''),0)['ok'])
                if row.startswith('M5_FRONTEND_'):self.assertFalse(evaluate(VALID+row+'\n',0)['ok'])
        self.assertFalse(evaluate(VALID.replace('capacity=144','capacity=unknown'),0)['ok'])

    def test_no_uart_or_queue_qualification_claimed(self):
        for old,new in [('bank_checks=0','bank_checks=1'),('commits=0','commits=1'),('stage_writes=0','stage_writes=1'),
                        ('stale_events=0','stale_events=1'),('aborts=0','aborts=1'),('adds=0','adds=1'),('pops=0','pops=1')]:
            self.assertFalse(evaluate(VALID.replace(old,new),0)['ok'])

    def test_observed_assertion_failed_exit_or_wrong_queue_fails(self):
        self.assertFalse(evaluate(VALID,1)['ok'])
        for label in ('M5_DOMAINS_FAILURE','M5_FRONTEND_FAILURE'):
            self.assertFalse(evaluate(VALID+'\n'+label,0)['ok'])
        for old,new in [('depth=1152','depth=256'),('sys_clocks=20000','sys_clocks=0'),('ready_checks=16','ready_checks=15')]:
            self.assertFalse(evaluate(VALID.replace(old,new),0)['ok'])

    def test_each_negative_requires_its_specific_assertion(self):
        for kind,label in NEGATIVES.items():
            self.assertTrue(evaluate_negative(label,1,kind));self.assertFalse(evaluate_negative(label,0,kind))
            self.assertFalse(evaluate_negative('unrelated crash',139,kind))
            self.assertFalse(evaluate_negative(label+'\nM5FrontendDomains_test passed',1,kind))
            for other,other_label in NEGATIVES.items():
                if other!=kind:self.assertFalse(evaluate_negative(other_label,1,kind))

if __name__=='__main__':unittest.main()
