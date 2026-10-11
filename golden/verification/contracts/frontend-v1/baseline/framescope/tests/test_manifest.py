import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from helpers import EXAMPLES, write

from framescope import FramescopeError, manifest

MINIMAL = """
[design]
top = "t"
root = "${ROOT}"
sources = ["*.sv"]

[clocks]
clk = 50e6
"""


class ManifestTest(unittest.TestCase):
    def test_loads_pattern_example(self):
        m = manifest.load(EXAMPLES / "pmod_pattern")
        self.assertEqual(m.top, "pattern_top")
        self.assertEqual([s.name for s in m.sources], ["pattern_top.sv"])
        self.assertEqual(m.clocks[0].period_ps, 10_000)
        self.assertEqual((m.reset.port, m.reset.active), ("rst_n", 0))
        mon = m.monitors[0]
        self.assertEqual((mon.name, mon.protocol), ("vga", "vga"))
        self.assertEqual(mon.signals["red"], "ja[3:0]")
        self.assertEqual(mon.options, {"timing": "640x480@60"})
        self.assertEqual(m.work_dir, (EXAMPLES / "pmod_pattern" / ".framescope").resolve())

    def test_vars_default_and_env_override(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            write(tmp / "a" / "x.sv", "module t; endmodule")
            write(tmp / "b" / "y.sv", "module t; endmodule")
            cfg = write(tmp / "framescope.toml", '[vars]\nROOT = "a"\n' + MINIMAL)
            self.assertEqual(manifest.load(cfg).sources[0].name, "x.sv")
            with mock.patch.dict(os.environ, {"ROOT": str(tmp / "b")}):
                self.assertEqual(manifest.load(cfg).sources[0].name, "y.sv")

    def test_undefined_var(self):
        with tempfile.TemporaryDirectory() as tmp:
            cfg = write(Path(tmp) / "framescope.toml", MINIMAL)
            with mock.patch.dict(os.environ, {}, clear=False):
                os.environ.pop("ROOT", None)
                with self.assertRaisesRegex(FramescopeError, r"\$\{ROOT\} is not set"):
                    manifest.load(cfg)

    def test_unknown_key_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            write(tmp / "x.sv", "")
            cfg = write(tmp / "framescope.toml", '[vars]\nROOT = "."\n' + MINIMAL + "\n[design2]\n")
            with self.assertRaisesRegex(FramescopeError, "unknown key"):
                manifest.load(cfg)

    def test_exclude_and_dedup(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            write(tmp / "src" / "pkg" / "aPkg.sv", "")
            write(tmp / "src" / "b.sv", "")
            write(tmp / "src" / "ip" / "c.sv", "")
            cfg = write(tmp / "framescope.toml", """
[design]
top = "t"
sources = ["src/**/*Pkg.sv", "src/**/*.sv"]
exclude = ["src/ip/**"]
[clocks]
clk = 1e6
""")
            names = [s.name for s in manifest.load(cfg).sources]
            self.assertEqual(names, ["aPkg.sv", "b.sv"])

    def _load(self, extra: str):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        write(root / "x.sv", "module t; endmodule")
        return manifest.load(write(root / "framescope.toml", '[vars]\nROOT = "."\n' + MINIMAL + extra))

    def test_pattern_example_probes_and_dumps(self):
        m = manifest.load(EXAMPLES / "pmod_pattern")
        self.assertEqual(m.probes[0], manifest.Probe("frame", "dut.frame", False))
        self.assertEqual(m.probes[-1].signed, True)
        self.assertEqual(m.dumps, [manifest.Dump("hist", "dut.hist")])

    def test_probes(self):
        m = self._load('[probes]\na = "dut.x[3:0]"\nb = { expr = " {p, q} ", signed = true }\n')
        self.assertEqual(m.probes, [manifest.Probe("a", "dut.x[3:0]"), manifest.Probe("b", "{p, q}", True)])
        self.assertEqual(self._load("").probes, [])

    def test_bad_probes(self):
        for extra, msg in [
            ('[probes]\n"1x" = "a"\n', "not a valid identifier"),
            ('[probes]\na = { expr = "a", width = 3 }\n', "unknown key"),
            ('[probes]\na = { signed = true }\n', "expr must be"),
            ('[probes]\na = ""\n', "expr must be"),
            ('[probes]\na = { expr = "a", signed = 1 }\n', "signed must be"),
        ]:
            with self.subTest(extra=extra), self.assertRaisesRegex(FramescopeError, msg):
                self._load(extra)

    def test_dumps(self):
        m = self._load('[[dump]]\nname = "a"\npath = "dut.u_ram.mem"\n'
                       '[[dump]]\nname = "b"\npath = "dut.gen_x[1].u$r.m"\n')
        self.assertEqual(m.dumps, [manifest.Dump("a", "dut.u_ram.mem"), manifest.Dump("b", "dut.gen_x[1].u$r.m")])

    def test_bad_dumps(self):
        for extra, msg in [
            ('[[dump]]\nname = "a"\npath = "u_ram.mem"\n', "hierarchical path"),
            ('[[dump]]\nname = "a"\npath = "dut"\n', "hierarchical path"),
            ('[[dump]]\nname = "a"\npath = "dut.m[i]"\n', "hierarchical path"),
            ('[[dump]]\nname = "a"\npath = "dut.m); $finish; //"\n', "hierarchical path"),
            ('[[dump]]\nname = "a b"\npath = "dut.m"\n', "identifier"),
            ('[[dump]]\nname = "a"\npath = "dut.m"\n[[dump]]\nname = "a"\npath = "dut.n"\n', "duplicate"),
            ('[[dump]]\nname = "a"\npath = "dut.m"\nwidth = 3\n', "unknown key"),
        ]:
            with self.subTest(extra=extra), self.assertRaisesRegex(FramescopeError, msg):
                self._load(extra)

    def test_build_options(self):
        from framescope.build import build_args

        m = self._load("")
        self.assertEqual(m.build, manifest.BuildOptions("-O2", (), 1))
        self.assertEqual(build_args(m), ["--x-initial", "fast", "--x-assign", "fast", "-CFLAGS", "-O2"])
        m = self._load('[build]\ncxx_opt = "-Os"\ncxx_flags = ["-march=native"]\nthreads = 2\n')
        self.assertEqual(m.build, manifest.BuildOptions("-Os", ("-march=native",), 2))
        self.assertEqual(build_args(m), ["--x-initial", "fast", "--x-assign", "fast", "-CFLAGS", "-Os", "-CFLAGS", "-march=native", "--threads", "2"])

    def test_initialization_modes(self):
        from framescope.build import build_args

        m = self._load('[build]\nx_initial = "unique"\nx_assign = "1"\n')
        self.assertTrue(m.build.randomized)
        self.assertEqual(build_args(m)[:4], ["--x-initial", "unique", "--x-assign", "1"])
        self.assertFalse(self._load('[build]\nx_initial = "0"\nx_assign = "0"\n').build.randomized)

    def test_raw_initialization_flags_rejected(self):
        for flag in ("--x-initial", "--x-assign=unique", "-x-assign"):
            with self.subTest(flag=flag), self.assertRaisesRegex(FramescopeError, r"under \[build\]"):
                with tempfile.TemporaryDirectory() as tmp:
                    tmp = Path(tmp)
                    write(tmp / "x.sv", "module t; endmodule")
                    manifest.load(write(tmp / "framescope.toml", MINIMAL.replace('root = "${ROOT}"',
                        f'verilator_args = ["{flag}", "unique"]\nroot = "."')))

    def test_bad_build_options(self):
        for extra, msg in [
            ('[build]\ncxx_opt = "O2"\n', "optimisation flag"),
            ('[build]\ncxx_opt = "-O2 -g"\n', "optimisation flag"),
            ('[build]\ncxx_flags = ["march=native"]\n', "compiler flags"),
            ('[build]\nthreads = 0\n', "positive integer"),
            ('[build]\nthreads = true\n', "positive integer"),
            ('[build]\nsavable = true\n', "unknown key"),
            ('[build]\nx_initial = "1"\n', "build.x_initial"),
            ('[build]\nx_initial = 0\n', "build.x_initial"),
            ('[build]\nx_assign = "random"\n', "build.x_assign"),
            ('[build]\nx_assign = true\n', "build.x_assign"),
        ]:
            with self.subTest(extra=extra), self.assertRaisesRegex(FramescopeError, msg):
                self._load(extra)

    def test_reserved_monitor_name(self):
        with self.assertRaisesRegex(FramescopeError, "reserved"):
            self._load('[[monitor]]\nname = "probe"\nprotocol = "vga"\n')

    def test_pattern_without_matches(self):
        with tempfile.TemporaryDirectory() as tmp:
            cfg = write(Path(tmp) / "framescope.toml", '[vars]\nROOT = "."\n' + MINIMAL)
            with self.assertRaisesRegex(FramescopeError, "matched no files"):
                manifest.load(cfg)


if __name__ == "__main__":
    unittest.main()
