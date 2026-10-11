"""End-to-end runs through a real runtime. Skipped when none is available."""

import json
import os
import tempfile
import unittest
from pathlib import Path

import pngread
from helpers import EXAMPLES, write

from framescope import FramescopeError, manifest, runtime
from framescope.run import run


def _runtime():
    if os.environ.get("FRAMESCOPE_INTEGRATION") == "0":
        return None
    try:
        return runtime.detect()
    except FramescopeError:
        return None


RT = _runtime()


def _quiet(_msg: str) -> None:
    pass


@unittest.skipIf(RT is None, "no framescope runtime available")
class PatternExampleTest(unittest.TestCase):
    def test_frames_timing_and_stimulus(self):
        m = manifest.load(EXAMPLES / "pmod_pattern")
        with tempfile.TemporaryDirectory(dir=m.work_dir.parent) as out:
            report = run(m, RT, _quiet, frames=2, out=Path(out),
                         stim=EXAMPLES / "pmod_pattern" / "stim_button.toml")
            self.assertTrue(report["ok"], report)
            vga = report["monitors"]["vga"]
            self.assertEqual([v["field"] for v in vga["timing"]["violations"]], ["pixel_rate_hz"])
            self.assertEqual(vga["timing"]["measured"]["h_total"], 800)
            f0, f1 = vga["frames"]
            self.assertNotEqual(f0["crc32"], f1["crc32"])

            img = pngread.read(f0["png"])
            self.assertEqual((img.width, img.height), (640, 480))
            for x, y in [(0, 0), (639, 0), (0, 479), (639, 479)]:
                self.assertEqual(img.pixel(x, y), (255, 255, 255), (x, y))  # border sits on the crop edges
            self.assertEqual(img.pixel(120, 100), (0, 0, 255))  # bar 1: blue
            # after the button press: checkerboard, (120 ^ 100) & 32 == 0 -> dark square
            self.assertEqual(pngread.read(f1["png"]).pixel(120, 100), (0x22, 0x22, 0x22))

    def test_line_timed_stimulus_probes_and_dumps(self):
        m = manifest.load(EXAMPLES / "pmod_pattern")
        with tempfile.TemporaryDirectory(dir=m.work_dir.parent) as out:
            report = run(m, RT, _quiet, frames=2, out=Path(out), dump="all",
                         stim=EXAMPLES / "pmod_pattern" / "stim_line.toml")
            self.assertTrue(report["ok"], report)
            self.assertEqual(report["warnings"], [])
            # Each event fired exactly at its requested position.
            self.assertEqual([(s["frame"], s["line"], s["pixel"]) for s in report["stimulus"]],
                             [(0, 135, 0), (1, 2, 0), (1, 300, 200)])
            self.assertFalse(any(s["late"] for s in report["stimulus"]))
            f0, f1 = report["monitors"]["vga"]["frames"]
            a, b = pngread.read(f0["png"]), pngread.read(f1["png"])
            # line 135 = the blanking before active row 100 (35 lines of sync + back porch)
            self.assertEqual(a.pixel(120, 99), (0, 0, 255))  # colour bars
            self.assertEqual(a.pixel(120, 100), (0x22, 0x22, 0x22))  # checkerboard
            # line 300 pixel 200 = active row 265, x 56, plus the 3-flop synchroniser
            self.assertEqual(b.pixel(120, 264), (0x88, 0x88, 0x88))
            self.assertEqual(b.pixel(57, 265), (0x88, 0x88, 0x88))
            self.assertEqual(b.pixel(58, 265), (0, 0, 0))  # bar 0 is black
            self.assertEqual(b.pixel(120, 266), (0, 0, 255))

            # Probes are sampled at the VSYNC leading edge that ends each frame.
            p0, p1 = f0["probes"], f1["probes"]
            self.assertEqual((p0["vc"], p0["hc"], p0["vc_minus_500"]), (490, 1, -10))
            self.assertEqual(p1["frame"], p0["frame"] + 1)
            self.assertEqual((p0["mode"], p1["mode"]), (1, 0))
            self.assertEqual(report["probes"]["vc_minus_500"]["width"], 11)

            dumps = report["dumps"]["hist"]
            self.assertEqual([d["frame"] for d in dumps], [0, 1])
            for d, p in zip(dumps, (p0, p1)):
                data = json.loads(Path(d["path"]).read_text())
                self.assertEqual({k: data[k] for k in ("name", "frame", "width", "depth")},
                                 {"name": "hist", "frame": d["frame"], "width": 72, "depth": 4})
                self.assertEqual(Path(d["path"]).relative_to(Path(out)).as_posix(),
                                 f"dumps/hist/frame_{d['frame']:04d}.json")
                # hist[n % 4] = {n, 56'h0, ~n} for each counted frame n < probe "frame"
                n = p["frame"] - 1
                self.assertEqual(data["words"][n % 4], f"0x{n:02x}{0:014x}{~n & 0xff:02x}")
                self.assertTrue(all(len(w) == 2 + 18 for w in data["words"]))

    def test_dead_pixel_clock_is_diagnosed(self):
        rtl = (EXAMPLES / "pmod_pattern" / "rtl" / "pattern_top.sv").as_posix()
        with tempfile.TemporaryDirectory() as tmp:
            cfg = write(Path(tmp) / "framescope.toml", f"""
[design]
top = "pattern_top"
sources = ["{rtl}"]
[clocks]
clk = 100e6
[[monitor]]
name = "vga"
protocol = "vga"
[monitor.signals]
pclk = "1'b0"
red = "ja[3:0]"
green = "jb[3:0]"
blue = "ja[7:4]"
hsync = "jb[4]"
vsync = "jb[5]"
""")
            report = run(manifest.load(cfg), RT, _quiet, frames=1, max_time_ms=2)
            self.assertFalse(report["ok"])
            self.assertEqual(report["sim"]["stop_reason"], "max_time")
            self.assertTrue(any("never rose" in d for d in report["monitors"]["vga"]["diagnosis"]))


@unittest.skipIf(RT is None or os.environ.get("FRAMESCOPE_METACIRCUIT_TEST") != "1",
                 "set FRAMESCOPE_METACIRCUIT_TEST=1 (needs the metacircuit checkout)")
class MetacircuitExampleTest(unittest.TestCase):
    def test_frontend_renders(self):
        m = manifest.load(EXAMPLES / "metacircuit")
        report = run(m, RT, _quiet, frames=1, save="none")
        self.assertTrue(report["ok"], report)
        vga = report["monitors"]["vga"]
        self.assertEqual((vga["frames"][0]["width"], vga["frames"][0]["height"]), (640, 480))
        self.assertGreater(vga["frames"][0]["nonblack_pixels"], 100_000)

    def test_probes_and_dumps(self):
        m = manifest.load(EXAMPLES / "metacircuit")
        report = run(m, RT, _quiet, frames=1, save="none", dump="last")
        self.assertTrue(report["ok"], report)
        probes = report["monitors"]["vga"]["frames"][0]["probes"]
        self.assertEqual((probes["init_done"], probes["component_store_busy"]), (1, 0))
        self.assertEqual((probes["mouse_x"], probes["mouse_y"]), (320, 240))
        self.assertLessEqual(probes["grid_pos_y"], 0)

        def words(name):
            [d] = report["dumps"][name]
            data = json.loads(Path(d["path"]).read_text())
            self.assertEqual((data["frame"], data["depth"]), (0, 288))
            return [int(w, 16) for w in data["words"]]

        cells = words("cells_render")
        self.assertEqual(cells, words("cells_shadow"))  # mirrored copies
        self.assertGreater(sum(1 for c in cells if c & 1), 0)  # the boot circuit
        store = words("component_store")
        for entry in store[: probes["component_count"]]:
            pos = entry & 0x1FF
            origin = cells[(pos & 31) + 18 * (pos >> 5)]
            self.assertEqual((entry >> 23) & 15, (origin >> 1) & 15)  # type = origin sprite


if __name__ == "__main__":
    unittest.main()
