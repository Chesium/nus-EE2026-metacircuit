"""Seeded power-on state on a tiny raster, through native or pinned Docker."""

import json
import tempfile
import unittest
from dataclasses import replace
from pathlib import Path
from unittest import mock

from helpers import EXAMPLES, write
from test_integration import RT, _quiet

from framescope import FramescopeError, manifest
from framescope.batch import batch
from framescope.cli import _parser
from framescope.run import initialization_options, run

RTL = """
module seed_top(input logic clk, input logic rst,
                output logic hs, vs, de, output logic [7:0] r, g, b);
  logic [3:0] x, y;
  logic [31:0] reset_state, unreset_state;
  logic [31:0] ram [0:7];
  logic [31:0] rom [0:7];
  logic [31:0] explicit_x;
  initial begin
    explicit_x = 'x;
    for (int i = 0; i < 8; i++) rom[i] = 32'h12340000 + i;
  end
  always_ff @(posedge clk) begin
    if (rst) begin x <= 0; y <= 0; reset_state <= 32'habcdef01; end
    else begin
      if (x == 15) begin x <= 0; y <= y == 9 ? 0 : y + 1; end
      else x <= x + 1;
      // These retain arbitrary power-on values; reset logic never touches them.
      unreset_state <= unreset_state + 1;
      ram[0] <= ram[0] + 1;
    end
  end
  assign hs = x < 2;
  assign vs = y < 2;
  assign de = x >= 4 && x < 12 && y >= 4 && y < 8;
  assign r = unreset_state[7:0];
  assign g = ram[1][7:0];
  assign b = explicit_x[7:0];
endmodule
"""

CONFIG = """
[design]
top = "seed_top"
sources = ["seed_top.sv"]
[clocks]
clk = 1e6
[reset]
port = "rst"
active = 1
duration_ns = 3000
[[monitor]]
name = "vga"
protocol = "vga"
hsync_polarity = "positive"
vsync_polarity = "positive"
[monitor.signals]
pclk = "clk"
hsync = "hs"
vsync = "vs"
de = "de"
red = "r"
green = "g"
blue = "b"
[probes]
reset_state = "dut.reset_state"
unreset_state = "dut.unreset_state"
explicit_x = "dut.explicit_x"
[[dump]]
name = "ram"
path = "dut.ram"
[[dump]]
name = "rom"
path = "dut.rom"
[build]
x_initial = "unique"
x_assign = "unique"
"""


class SeedOptionsTest(unittest.TestCase):
    def test_options_and_validation(self):
        m = manifest.load(EXAMPLES / "pmod_pattern")
        self.assertEqual(initialization_options(m, None), {
            "seed": 1, "seed_explicit": False, "rand_reset": 0, "x_initial": "fast", "x_assign": "fast"})
        m.build = replace(m.build, x_assign="unique")
        self.assertEqual(initialization_options(m, 2147483647)["rand_reset"], 2)
        for bad in (0, -1, 2147483648, True, "123", 1.5):
            with self.subTest(seed=bad), self.assertRaisesRegex(FramescopeError, "--seed"):
                initialization_options(m, bad)

    def test_cli_accepts_run_and_batch_seed(self):
        self.assertEqual(_parser().parse_args(["run", "--seed", "42"]).seed, 42)
        self.assertEqual(_parser().parse_args(["batch", "--seed", "17", "stim.toml"]).seed, 17)

    def test_invalid_seed_does_not_build(self):
        m = manifest.load(EXAMPLES / "pmod_pattern")
        with mock.patch("framescope.run.build") as build:
            with self.assertRaisesRegex(FramescopeError, "--seed"):
                run(m, None, _quiet, frames=1, seed=0)
            build.assert_not_called()


@unittest.skipIf(RT is None, "no framescope runtime available")
class SeedIntegrationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.work = tempfile.TemporaryDirectory()
        cls.root = Path(cls.work.name)
        write(cls.root / "seed_top.sv", RTL)
        cls.m = manifest.load(write(cls.root / "framescope.toml", CONFIG))

    @classmethod
    def tearDownClass(cls):
        cls.work.cleanup()

    def capture(self, name, **kwargs):
        report = run(self.m, RT, _quiet, frames=2, out=self.root / name, dump="all", save="all", **kwargs)
        self.assertTrue(report["ok"], report)
        dumps = {name: [json.loads(Path(d["path"]).read_text())["words"] for d in entries]
                 for name, entries in report["dumps"].items()}
        frames = report["monitors"]["vga"]["frames"]
        return report, dumps, [(f["crc32"], f["probes"]) for f in frames]

    def test_repeatability_diversity_reset_and_initialized_rom(self):
        a, ad, af = self.capture("seed17a", seed=17)
        b, bd, bf = self.capture("seed17b", seed=17)
        c, cd, cf = self.capture("seed91", seed=91)
        self.assertEqual((ad, af), (bd, bf))
        self.assertTrue(b["build"]["cached"])
        self.assertEqual(a["build"]["build_dir"], c["build"]["build_dir"])
        self.assertNotEqual(ad["ram"], cd["ram"])
        self.assertNotEqual([p["unreset_state"] for _, p in af], [p["unreset_state"] for _, p in cf])
        self.assertNotEqual([p["explicit_x"] for _, p in af], [p["explicit_x"] for _, p in cf])
        self.assertNotEqual([crc for crc, _ in af], [crc for crc, _ in cf])
        for dumps, frames in ((ad, af), (cd, cf)):
            self.assertEqual(dumps["rom"], [[f"0x{0x12340000 + i:08x}" for i in range(8)]] * 2)
            self.assertEqual([p["reset_state"] for _, p in frames], [0xabcdef01] * 2)
        self.assertEqual(a["sim"]["initialization"], {
            "seed": 17, "seed_explicit": True, "rand_reset": 2, "x_initial": "unique", "x_assign": "unique"})
        self.assertEqual(a["build"]["options"]["x_initial"], "unique")

    def test_default_seed_and_checkpoint_bypass(self):
        a, ad, af = self.capture("default")
        b, bd, bf = self.capture("default_ck", checkpoint=1)
        self.assertEqual((ad, af), (bd, bf))
        self.assertEqual(a["sim"]["initialization"]["seed"], 1)
        self.assertFalse(a["sim"]["initialization"]["seed_explicit"])
        self.assertFalse(b["build"]["savable"])
        self.assertFalse(b["checkpoint"]["restored"])
        self.assertIn("RNG", b["checkpoint"]["reason"])
        self.assertFalse((self.m.work_dir / "checkpoints").exists())

    def test_batch_forwards_seed_without_boot_checkpoint(self):
        stim = write(self.root / "batch_stim.toml", "frames = 2\n")
        report = batch(self.m, RT, _quiet, scenarios=[stim], out=self.root / "batch", jobs=1,
                       dump="all", save="none", seed=17, checkpoint=1)
        self.assertTrue(report["ok"], report)
        self.assertEqual(report["initialization"]["seed"], 17)
        self.assertFalse(report["build"]["savable"])
        [scenario] = report["scenarios"]
        child = json.loads(Path(scenario["report"]).read_text())
        self.assertEqual(child["sim"]["initialization"]["seed"], 17)
        self.assertFalse(scenario["checkpoint"]["restored"])

    def test_initial_and_assignment_modes_are_independent(self):
        original = self.m.build
        try:
            self.m.build = replace(original, x_initial="unique", x_assign="0")
            _, ad, af = self.capture("initial_only17", seed=17)
            _, bd, bf = self.capture("initial_only91", seed=91)
            self.assertNotEqual(ad["ram"], bd["ram"])
            self.assertEqual([p["explicit_x"] for _, p in af + bf], [0] * 4)
            self.m.build = replace(original, x_initial="0", x_assign="unique")
            _, cd, cf = self.capture("assignment_only17", seed=17)
            _, dd, df = self.capture("assignment_only91", seed=91)
            self.assertEqual(cd["ram"], dd["ram"])
            self.assertNotEqual([p["explicit_x"] for _, p in cf], [p["explicit_x"] for _, p in df])
        finally:
            self.m.build = original

    def test_build_modes_separate_cache_and_seeded_fast_checkpoint_bypassed(self):
        original = self.m.build
        try:
            self.m.build = replace(original, x_initial="0", x_assign="0")
            a, dumps, frames = self.capture("zero", seed=17, checkpoint=1)
            self.assertEqual(dumps["ram"][0][1:], ["0x00000000"] * 7)
            self.assertEqual([p["explicit_x"] for _, p in frames], [0] * 2)
            self.assertEqual(a["sim"]["initialization"]["rand_reset"], 0)
            self.assertFalse(a["checkpoint"]["restored"])
            self.m.build = original
            b, _, _ = self.capture("unique_cache", seed=17)
            self.assertNotEqual(a["build"]["build_dir"], b["build"]["build_dir"])
        finally:
            self.m.build = original


if __name__ == "__main__":
    unittest.main()
