import tempfile
import unittest
from pathlib import Path

from helpers import EXAMPLES, PATTERN_PORTS, write

from framescope import FramescopeError, manifest
from framescope.stimulus import compile_lines


class StimulusTest(unittest.TestCase):
    def setUp(self):
        self.m = manifest.load(EXAMPLES / "pmod_pattern")

    def test_reset_sets_and_events(self):
        lines = compile_lines(self.m, PATTERN_PORTS, EXAMPLES / "pmod_pattern" / "stim_button.toml", ["btn=0x0"])
        self.assertEqual(lines, ["t 0 rst_n 0", "t 200000 rst_n 1", "t 0 btn 0", "f 1 btn 1", "f 2 btn 0"])

    def test_time_units(self):
        with tempfile.TemporaryDirectory() as tmp:
            stim = write(Path(tmp) / "s.toml", '[[event]]\nus = 1.5\nset = { btn = true }\n')
            self.assertEqual(compile_lines(self.m, PATTERN_PORTS, stim, [])[-1], "t 1500000 btn 1")

    def test_rejects_clock_and_unknown_names(self):
        with self.assertRaisesRegex(FramescopeError, "not a settable input"):
            compile_lines(self.m, PATTERN_PORTS, None, ["clk=1"])
        with self.assertRaisesRegex(FramescopeError, "not a settable input"):
            compile_lines(self.m, PATTERN_PORTS, None, ["mouse.x=3"])

    def _compile(self, text: str, m=None):
        with tempfile.TemporaryDirectory() as tmp:
            stim = write(Path(tmp) / "s.toml", text)
            return compile_lines(m or self.m, PATTERN_PORTS, stim, [])

    def test_line_and_pixel(self):
        lines = self._compile('[[event]]\nframe = 3\nline = 10\nset = { btn = 1 }\n'
                              '[[event]]\nframe = 0\nline = 524\npixel = 799\nset = { btn = 0 }\n')
        self.assertEqual(lines[-2:], ["p 3:10:0 btn 1", "p 0:524:799 btn 0"])

    def test_line_and_pixel_ranges(self):
        # 640x480@60: 525 lines of 800 pixels
        for text, msg in [
            ("frame = 1\nline = 525", r"line 525 is out of range 0..524 \(monitor 'vga' timing\)"),
            ("frame = 1\nline = 1\npixel = 800", r"pixel 800 is out of range 0..799"),
            ("frame = 1\nline = -1", "non-negative integer"),
            ("frame = 1\nline = 2.5", "non-negative integer"),
            ("frame = 1\nline = true", "non-negative integer"),
            ("frame = -1", "non-negative integer"),
            ("frame = 1\npixel = 3", "pixel needs line"),
            ("us = 1\nline = 3", "need a frame trigger"),
            ("frame = 1\nline = 3\ncolumn = 3", "unknown key"),
        ]:
            with self.subTest(text=text), self.assertRaisesRegex(FramescopeError, msg):
                self._compile(f"[[event]]\n{text}\nset = {{ btn = 1 }}\n")

    def test_line_limit_without_timing_preset(self):
        del self.m.monitors[0].options["timing"]
        self.assertEqual(self._compile("[[event]]\nframe = 0\nline = 4095\nset = { btn = 1 }\n")[-1], "p 0:4095:0 btn 1")
        with self.assertRaisesRegex(FramescopeError, r"0..4095 \(the raster limit\)"):
            self._compile("[[event]]\nframe = 0\nline = 4096\nset = { btn = 1 }\n")

    def test_line_example(self):
        lines = compile_lines(self.m, PATTERN_PORTS, EXAMPLES / "pmod_pattern" / "stim_line.toml", [])
        self.assertEqual(lines[2:], ["p 0:135:0 btn 1", "p 1:2:0 btn 0", "p 1:300:200 btn 1"])

    def test_rejects_ambiguous_trigger(self):
        with tempfile.TemporaryDirectory() as tmp:
            stim = write(Path(tmp) / "s.toml", '[[event]]\nframe = 1\nns = 5\nset = { btn = 1 }\n')
            with self.assertRaisesRegex(FramescopeError, "exactly one"):
                compile_lines(self.m, PATTERN_PORTS, stim, [])


if __name__ == "__main__":
    unittest.main()
