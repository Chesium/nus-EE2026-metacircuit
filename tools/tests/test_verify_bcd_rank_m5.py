import importlib.util
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('bcd_rank', ROOT / 'tools/verify_bcd_rank_m5.py')
bcd = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bcd)
shadow_spec = importlib.util.spec_from_file_location('shadow_ports', ROOT / 'tools/verify_shadow_ports_m5.py')
shadow = importlib.util.module_from_spec(shadow_spec)
shadow_spec.loader.exec_module(shadow)
FROZEN = ROOT / 'golden/verification/contracts/frontend-v1/payloads' / bcd.SOURCE


class ExactBcdRewriteTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = shadow.transform(shadow.reviewed_a008_reference(FROZEN.read_text()))

    def test_pinned_baseline(self):
        self.assertEqual(bcd.sha(self.source), bcd.BASELINE_SHA)

    def test_arbitrary_baseline_mutation_rejected(self):
        with self.assertRaises(ValueError):
            bcd.transform(self.source + '\n')

    def test_only_reviewed_scan_replacement_and_function_addition(self):
        transformed = bcd.transform(self.source)
        start, end = self.source.index(bcd.START), self.source.index(bcd.END)
        scan = self.source[start:end]
        statement = '                {edit_value_next_digits, edit_value_next_bcd} = bcd_scan_rank8(edit_value_next_text, edit_value_next_text_len, selected_is_resistor);\n'
        reconstructed = transformed.replace(bcd.function(), '', 1).replace(statement, scan, 1)
        self.assertEqual(reconstructed, self.source)

    def test_projection_uses_actual_full_always_block(self):
        transformed = bcd.transform(self.source)
        projected = bcd.projected_module(transformed, 'candidate')
        start = transformed.index(bcd.ANCHOR)
        end = transformed.index('    // The VGA keypad', start)
        self.assertIn(transformed[start:end], projected)
        self.assertIn(bcd.extract_function(transformed, 'bcd_scan_rank8'), projected)

    def test_projection_rejects_duplicate_helper(self):
        with self.assertRaises(ValueError):
            bcd.extract_function(self.source + bcd.extract_function(self.source, 'text_append8'), 'text_append8')

    def test_balanced_prefix_has_no_overflow(self):
        for i in range(9):
            expression = bcd.balanced(["{3'd0, digit_mask[%d]}" % j for j in range(i)])
            self.assertEqual(expression.count('digit_mask['), i)
        self.assertIn("rank[8] >= 4'd3 ? 2'd3", bcd.function())


if __name__ == '__main__':
    unittest.main()
