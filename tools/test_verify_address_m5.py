"""Trusted helper extraction and fail-closed exhaustive evidence tests."""
import hashlib
import unittest

from verify_address_m5 import (FROZEN, TRUSTED_REFERENCE_SHA256, accept_normal,
                               extract_candidate, extract_reference)

VALID = 'M5_ADDRESS_EQUIVALENCE checks=512 invalid_checks=224 helpers=4\nM5AddressEquivalence_test passed.\n'


class AddressEquivalenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = FROZEN.read_text()

    def test_reference_identity(self):
        self.assertEqual(hashlib.sha256(FROZEN.read_bytes()).hexdigest(), TRUSTED_REFERENCE_SHA256)

    def test_reference_exact_original_arithmetic(self):
        wrapper = extract_reference(self.source)
        self.assertIn('pos_x = cell_addr % CANVAS_GRID_W;', wrapper)
        self.assertIn('pos_y = cell_addr / CANVAS_GRID_W;', wrapper)
        self.assertIn('pos_y[3:0], pos_x[4:0]', wrapper)

    def test_reference_rejects_other_dimensions(self):
        for name, value in (('CANVAS_GRID_W', 19), ('CANVAS_GRID_H', 17)):
            import re
            mutated = re.sub(name + r'\s*=\s*\d+', name + f' = {value}', self.source, count=1)
            with self.assertRaises(ValueError):
                extract_reference(mutated)

    def test_reference_rejects_width_or_count_drift(self):
        for original, mutated in (('$clog2(CANVAS_CELL_COUNT)', '8'),
                                  ('CANVAS_GRID_W * CANVAS_GRID_H', '512')):
            with self.assertRaises(ValueError):
                extract_reference(self.source.replace(original, mutated, 1))

    def test_missing_or_duplicate_helper(self):
        for source in (self.source.replace('function [4:0] canvas_addr_to_i;', 'function [4:0] renamed;', 1),
                       self.source + '\nfunction [4:0] canvas_addr_to_i; begin canvas_addr_to_i=0; end endfunction'):
            with self.assertRaises(ValueError):
                extract_reference(source)

    def test_candidate_shared_decoder_dependency(self):
        decoder = '\nfunction [8:0] decode_canvas_address; input [8:0] addr; begin decode_canvas_address=addr; end endfunction\n'
        self.assertIn(decoder.strip(), extract_candidate(self.source + decoder))
        with self.assertRaises(ValueError):
            extract_candidate(self.source + decoder + decoder)

    def test_complete_exhaustive_evidence(self):
        self.assertTrue(accept_normal(VALID, 0))

    def test_invalid_domain_may_not_be_skipped(self):
        self.assertFalse(accept_normal(VALID.replace('checks=512', 'checks=288'), 0))
        self.assertFalse(accept_normal(VALID.replace('invalid_checks=224', 'invalid_checks=0'), 0))

    def test_helpers_and_row_count_required(self):
        self.assertFalse(accept_normal(VALID.replace('helpers=4', 'helpers=3'), 0))
        self.assertFalse(accept_normal(VALID + VALID, 0))
        self.assertFalse(accept_normal('', 0))

    def test_failed_or_inconsistent_report_rejected(self):
        self.assertFalse(accept_normal(VALID, 1))
        self.assertFalse(accept_normal(VALID + 'M5_ADDRESS_FAILURE addr=511\n', 0))


if __name__ == '__main__':
    unittest.main()
