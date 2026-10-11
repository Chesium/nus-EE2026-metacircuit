import unittest

from helpers import REPO  # noqa: F401  (puts src/ on sys.path)

from framescope import FramescopeError, timing

VESA_640 = {
    "h_total": 800, "h_sync": 96, "v_total": 525, "v_sync": 2,
    "hsync_polarity": "negative", "vsync_polarity": "negative",
    "pixel_rate_hz": 25.175e6, "distinct_line_lengths": 1,
}


class TimingTest(unittest.TestCase):
    def test_exact_mode_has_no_violations(self):
        self.assertEqual(timing.compare(timing.PRESETS["640x480@60"], VESA_640), [])

    def test_25mhz_pixel_clock_is_a_warning(self):
        v = timing.compare(timing.PRESETS["640x480@60"], {**VESA_640, "pixel_rate_hz": 25e6})
        self.assertEqual([(x["field"], x["severity"]) for x in v], [("pixel_rate_hz", "warning")])

    def test_off_by_one_line_and_porches(self):
        measured = {**VESA_640, "h_total": 801, "h_active": 640, "h_fp": 14, "h_bp": 51,
                    "v_active": 480, "v_fp": 11, "v_bp": 32}
        fields = [x["field"] for x in timing.compare(timing.PRESETS["640x480@60"], measured)]
        self.assertEqual(fields, ["h_total", "h_fp", "h_bp", "v_fp", "v_bp"])

    def test_polarity_and_unstable_lines(self):
        measured = {**VESA_640, "hsync_polarity": "positive", "distinct_line_lengths": 2,
                    "line_len_min": 799, "line_len_max": 800}
        fields = [x["field"] for x in timing.compare(timing.PRESETS["640x480@60"], measured)]
        self.assertEqual(fields, ["hsync_polarity", "line_length"])

    def test_resolve(self):
        self.assertIsNone(timing.resolve(None))
        inline = timing.resolve({"h_active": 4, "h_fp": 1, "h_sync": 1, "h_bp": 1,
                                 "v_active": 2, "v_fp": 1, "v_sync": 1, "v_bp": 1})
        self.assertEqual((inline.h_total, inline.v_total), (7, 5))
        with self.assertRaisesRegex(FramescopeError, "unknown timing preset"):
            timing.resolve("640x480@75")


if __name__ == "__main__":
    unittest.main()
