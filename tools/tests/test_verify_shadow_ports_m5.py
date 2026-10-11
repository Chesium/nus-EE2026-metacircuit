import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from verify_shadow_ports_m5 import Statements, audit, max_writes, transform, reviewed_a008_reference

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / 'golden/verification/contracts/frontend-v1/payloads/src/design/rendering/GlobalRender_top.v'


class ShadowPortTests(unittest.TestCase):
    def test_pinned_exact_normalization(self):
        reference = REFERENCE.read_text()
        report = audit(reference, transform(reference))
        self.assertEqual([r['original_sites'] for r in report['arrays']], [20, 23, 23])
        self.assertTrue(report['ok'])

    def test_missing_write_enable_default_rejected(self):
        reference = REFERENCE.read_text()
        broken = transform(reference).replace("        value_shadow_data_we = 1'b0;\n", '')
        with self.assertRaisesRegex(ValueError, 'canonical'):
            audit(reference, broken)

    def test_changed_read_rejected(self):
        reference = REFERENCE.read_text()
        broken = transform(reference).replace('uart_cell_ram_rdata <= canvas_shadow_data',
                                              'uart_cell_ram_rdata <= value_shadow_data')
        with self.assertRaisesRegex(ValueError, 'canonical'):
            audit(reference, broken)

    def test_changed_reference_rejected(self):
        reference = REFERENCE.read_text() + '\n'
        with self.assertRaisesRegex(ValueError, 'pinned'):
            audit(reference, transform(reference))

    def test_only_reviewed_a008_reference_admitted(self):
        fixed = reviewed_a008_reference(REFERENCE.read_text())
        self.assertEqual(audit(fixed, transform(fixed))['reference_identity'], 'reviewed-A-008-write-drain')
        with self.assertRaisesRegex(ValueError, 'pinned'):
            audit(fixed.replace('component_store_write_drain', 'arbitrary_flag'), transform(fixed))

    def test_exclusive_branches_have_one_write(self):
        tree = Statements('if (a) begin canvas_shadow_data[addr] <= x; end else '
                          'if (b) canvas_shadow_data[addr2] <= y;').statement()
        self.assertEqual(max_writes(tree, 'canvas_shadow_data'), 1)

    def test_two_addresses_in_same_branch_count_two(self):
        tree = Statements('begin canvas_shadow_data[addr] <= x; '
                          'if (b) canvas_shadow_data[addr2] <= y; end').statement()
        self.assertEqual(max_writes(tree, 'canvas_shadow_data'), 2)

    def test_nested_address_write_counted(self):
        tree = Statements('value_shadow_data[init_cycles[CANVAS_ADDR_W-1:0]] <= x;').statement()
        self.assertEqual(max_writes(tree, 'value_shadow_data'), 1)


if __name__ == '__main__':
    unittest.main()
