"""Independent arithmetic witnesses and generated-product provenance checks."""
import importlib.util
from fractions import Fraction
from pathlib import Path
import random
import struct
import sys
import tempfile
import unittest

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
spec = importlib.util.spec_from_file_location('fp_m5', TOOLS / 'verify_fp_m5.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)


def bits(value):
    return struct.unpack('>I', struct.pack('>f', value))[0]


class ActualFpQualificationTests(unittest.TestCase):
    def test_fused_cancellation_retains_product_low_bits(self):
        # (1+2^-23)*(1-2^-23)-1 = -2^-46, lost by binary32 mul/add.
        self.assertEqual(m.reference_fma(0x3f800001, 0x3f7ffffe, 0xbf800000),
                         (bits(-2.0**-46), 0))
        self.assertEqual(bits(struct.unpack('>f', struct.pack('>I', 0x3f800001))[0] *
                              struct.unpack('>f', struct.pack('>I', 0x3f7ffffe))[0]), bits(1.0))

    def test_round_nearest_even_both_tie_parities(self):
        self.assertEqual(m.rounded(Fraction(1) + Fraction(1, 1 << 24)), (0x3f800000, 0))
        self.assertEqual(m.rounded(Fraction(1) + Fraction(3, 1 << 24)), (0x3f800002, 0))
        self.assertEqual(m.rounded(-Fraction(1) - Fraction(3, 1 << 24)), (0xbf800002, 0))

    def test_flush_input_subnormal_signed_zero(self):
        self.assertEqual(m.reference_fma(1, 0x7f7fffff, 0x3f800000), (0x3f800000, 0))
        self.assertEqual(m.reference_div(0x80000001, 0x3f800000), (0x80000000, 0))
        self.assertEqual(m.reference_div(0x3f800000, 0x80000001), (0xff800000, 8))

    def test_exception_bits_overflow_underflow_invalid_dividezero(self):
        self.assertEqual(m.reference_fma(0x7f7fffff, 0x40000000, 0), (0x7f800000, 2))
        self.assertEqual(m.reference_fma(0x00800000, 0x3f000000, 0), (0, 1))
        self.assertEqual(m.reference_fma(0, 0x7f800000, 0), (0x7fc00000, 4))
        self.assertEqual(m.reference_div(0x3f800000, 0), (0x7f800000, 8))
        self.assertEqual(m.reference_div(0, 0), (0x7fc00000, 4))
        self.assertEqual(m.reference_div(0x7f800000, 0x7f800000), (0x7fc00000, 4))

    def test_signaling_nan_is_quiet_without_invalid(self):
        self.assertEqual(m.reference_fma(0x7f800001, 0x3f800000, 0), (0x7fc00000, 0))
        self.assertEqual(m.reference_div(0x7f800001, 0x3f800000), (0x7fc00000, 0))

    def test_rational_oracle_matches_independent_small_integer_arithmetic(self):
        rng = random.Random(1024)
        for _ in range(500):
            a, b, c = rng.randrange(-128, 128), rng.randrange(1, 128), rng.randrange(-128, 128)
            # Products/sums are exact in host binary64, isolating final fp32 rounding.
            self.assertEqual(m.reference_fma(bits(a), bits(b), bits(c)), (bits(a * b + c), 0))
            self.assertEqual(m.reference_div(bits(a), bits(b)), (bits(a / b), 0))

    def test_fixtures_pin_edges_and_seeded_random_cases(self):
        a, b = m.fixtures(10, 512), m.fixtures(10, 512)
        self.assertEqual(a, b)
        self.assertNotEqual(a, m.fixtures(11, 512))
        self.assertEqual({k: len(v) for k, v in a.items()}, {'fma': 527, 'div': 527})
        self.assertEqual({x['flags'] for x in a['fma']}, {0, 1, 2, 4})
        self.assertEqual({x['flags'] for x in a['div']}, {0, 1, 2, 4, 8})
        self.assertEqual({x['gap'] for x in a['fma']}, {0, 1, 2, 3})

    def test_product_configuration_matches_while_revision_identity_does_not(self):
        for name, latency in [('fma', '16'), ('div', '28')]:
            audit = m.configuration_audit(name)
            self.assertTrue(audit['configuration_matches'])
            self.assertEqual(len(audit['comparisons']), 70)
            self.assertEqual(audit['unmapped_model_parameters'], [])
            self.assertEqual(audit['comparisons']['C_LATENCY'], {'xci': latency, 'generated': latency})
            self.assertEqual(audit['original_xci_revision'], 6)
            self.assertEqual(audit['generated_revision'], 21)
            self.assertFalse(audit['revision_identity_matches'])

    def test_changed_generated_latency_is_rejected_without_changing_original(self):
        original_root = m.ROOT
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            directory = root / 'src/ip/floating_point_fma'
            (directory / 'sim').mkdir(parents=True)
            original = original_root / 'src/ip/floating_point_fma'
            (directory / 'floating_point_fma.xci').write_bytes((original / 'floating_point_fma.xci').read_bytes())
            product = (original / 'sim/floating_point_fma.vhd').read_text().replace('C_LATENCY => 16', 'C_LATENCY => 17')
            (directory / 'sim/floating_point_fma.vhd').write_text(product)
            try:
                m.ROOT = root
                audit = m.configuration_audit('fma')
                self.assertFalse(audit['configuration_matches'])
                self.assertEqual(set(audit['mismatches']), {'C_LATENCY'})
            finally:
                m.ROOT = original_root


if __name__ == '__main__':
    unittest.main()
