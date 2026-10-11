import hashlib
import json
import os
import tempfile
import unittest
from pathlib import Path

from helpers import write
from framescope import FramescopeError, coverage, manifest, runtime
from framescope.run import run

RTL = '''module tiny(input logic clk, input logic mode, output logic hs,vs,de, output logic [3:0] rgb);
 logic [3:0] x = 0, y = 0;
 always_ff @(posedge clk) begin
  if (x == 7) begin
   x <= 0;
   if (y == 5) y <= 0; else y <= y+1;
  end else x <= x+1;
 end
 assign hs = x != 0;
 assign vs = y != 0;
 assign de = x >= 2 && y >= 2;
 always_comb begin
  if (mode) rgb = x; else rgb = y;
 end
 cp_mode: cover property (@(posedge clk) mode);
endmodule
'''
CONFIG = '''[design]
top = "tiny"
sources = ["tiny.sv"]
[clocks]
clk = 1e6
[inputs]
mode = 0
[build]
coverage = true
[[monitor]]
name = "vga"
protocol = "vga"
hsync_polarity = "negative"
vsync_polarity = "negative"
[monitor.signals]
pclk = "clk"
red = "rgb"
green = "rgb"
blue = "rgb"
hsync = "hs"
vsync = "vs"
de = "de"
'''


def fixture(tmp):
    write(tmp / "tiny.sv", RTL)
    return manifest.load(write(tmp / "framescope.toml", CONFIG))


class CoverageValidationTest(unittest.TestCase):
    def test_config_and_window_errors_before_build(self):
        with tempfile.TemporaryDirectory() as td:
            m = fixture(Path(td))
            for kwargs in ({"coverage_from": -1}, {"coverage_from": 2}, {"checkpoint": 1}):
                with self.assertRaises(FramescopeError):
                    run(m, None, lambda _: None, frames=2, **kwargs)
            m.build = manifest.BuildOptions()
            with self.assertRaisesRegex(FramescopeError, "requires"):
                run(m, None, lambda _: None, frames=2, coverage_from=0)
            write(m.path, CONFIG.replace("coverage = true", 'coverage = "true"'))
            with self.assertRaisesRegex(FramescopeError, "true or false"):
                manifest.load(m.path)

    def test_bad_dat_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            p = Path(td) / "bad.dat"
            for value in ("garbage", "# SystemC::Coverage-3\n", "# SystemC::Coverage-3\nC 'bad' 4\n"):
                write(p, value)
                with self.assertRaises(FramescopeError):
                    coverage.read_points(p)

    def test_merge_incomplete_tampered_duplicate_and_mismatch(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            key = "\x01f\x02tiny.sv\x01l\x023\x01page\x02v_line/tiny\x01o\x02if"
            def report(name, count, build_id="a", complete=True):
                d = root / name
                raw = write(d / "scenario.dat", f"# SystemC::Coverage-3\nC '{key}' {count}\n")
                info = {"schema_version": 1, "complete": complete, "boundary": {"frame": 0, "t_ps": 1},
                        "provenance": {"build_id": build_id, "tool_version": "fixture", "runtime": "fixture",
                                       "runtime_identity": "fixture", "sources": [], "top": "tiny", "build_options": {}},
                        "artifacts": {"scenario": {"path": str(raw), "sha256": hashlib.sha256(raw.read_bytes()).hexdigest()}}}
                info["artifacts"]["boot"] = dict(info["artifacts"]["scenario"])
                return write(d / "coverage.json", json.dumps(info))
            a, b = report("a", 2), report("b", 3)
            result = coverage.merge([a, b], root / "merged")
            self.assertEqual(coverage.read_points(Path(result["artifact"]))[key], 5)
            self.assertEqual(result["summary"]["modules"][0]["types"]["line"]["reached"], 1)
            for inputs, message in (([a, a], "duplicate"), ([a, report("bad", 1, complete=False)], "incomplete"),
                                    ([a, report("wrong", 1, build_id="b")], "provenance")):
                with self.assertRaisesRegex(FramescopeError, message):
                    coverage.merge(inputs, root / "invalid")
            write(b.parent / "scenario.dat", "tampered")
            with self.assertRaisesRegex(FramescopeError, "hash mismatch"):
                coverage.merge([a, b], root / "invalid")


def get_runtime():
    if os.environ.get("FRAMESCOPE_INTEGRATION") == "0":
        return None
    try:
        return runtime.detect()
    except FramescopeError:
        return None


RT = get_runtime()


@unittest.skipIf(RT is None, "no runtime")
class CoverageIntegrationTest(unittest.TestCase):
    def test_boot_reset_user_points_merge_and_crc(self):
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            m = fixture(tmp)
            stim = write(tmp / "stim.toml", '[[event]]\nframe=1\nset={mode=1}\n')
            cold = run(m, RT, lambda _: None, frames=2, stim=stim, save="none", coverage_from=1, out=tmp / "first")
            self.assertTrue(cold["ok"], cold)
            self.assertTrue(cold["coverage"]["complete"])
            self.assertEqual(cold["coverage"]["boundary"]["frame"], 1)
            self.assertIn("Verilator 5.", cold["coverage"]["provenance"]["tool_version"])
            def select(scope, comment):
                points = coverage.read_points(Path(cold["coverage"]["artifacts"][scope]["path"]))
                return sum(c for k, c in points.items() if coverage.fields(k).get("o") == comment
                           and coverage.fields(k).get("l") == "13" and coverage.fields(k)["f"].endswith("tiny.sv"))
            self.assertGreater(select("boot", "else"), 0)
            self.assertEqual(select("scenario", "else"), 0)
            self.assertGreater(select("scenario", "if"), 0)
            points = coverage.read_points(Path(cold["coverage"]["artifacts"]["scenario"]["path"]))
            self.assertGreater(sum(c for k, c in points.items() if coverage.fields(k).get("o") == "cp_mode"), 0)
            again = run(m, RT, lambda _: None, frames=2, stim=stim, save="none", coverage_from=1, out=tmp / "second")
            merged = coverage.merge([Path(cold["coverage"]["report"]), Path(again["coverage"]["report"])], tmp / "merged")
            self.assertEqual(coverage.read_points(Path(merged["artifact"])), {k: 2*v for k, v in points.items()})
            m.build = manifest.BuildOptions()
            plain = run(m, RT, lambda _: None, frames=2, stim=stim, save="none", out=tmp / "plain")
            self.assertTrue(plain["ok"], plain)
            self.assertEqual([f["crc32"] for f in cold["monitors"]["vga"]["frames"]],
                             [f["crc32"] for f in plain["monitors"]["vga"]["frames"]])

    def test_missing_boundary_is_incomplete(self):
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            m = fixture(tmp)
            report = run(m, RT, lambda _: None, frames=2, coverage_from=1, max_time_ms=0.001,
                         save="none", out=tmp / "short")
            self.assertFalse(report["ok"])
            self.assertFalse(report["coverage"]["complete"])
            self.assertEqual(set(report["coverage"]["artifacts"]), {"boot"})
            with self.assertRaisesRegex(FramescopeError, "incomplete"):
                coverage.merge([Path(report["coverage"]["report"])], tmp / "invalid")
