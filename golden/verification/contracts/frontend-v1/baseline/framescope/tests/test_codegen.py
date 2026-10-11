import unittest

from helpers import EXAMPLES, PATTERN_PORTS

from framescope import FramescopeError, codegen, manifest
from framescope.ports import Port


class CodegenTest(unittest.TestCase):
    def setUp(self):
        self.m = manifest.load(EXAMPLES / "pmod_pattern")

    def test_wrapper_exposes_ports_and_taps(self):
        sv = codegen.wrapper_sv(self.m, PATTERN_PORTS)
        self.assertIn("module framescope_top (", sv)
        self.assertIn("output wire [7:0]    ja", sv)
        self.assertIn("pattern_top dut (", sv)
        self.assertIn(".jb(jb)", sv)
        self.assertIn("assign fs_vga_pclk_en = dut.pix_stb;", sv)
        self.assertIn("assign fs_vga_red = fs_expand8(64'(ja[3:0]), $bits(ja[3:0]));", sv)
        self.assertIn("assign fs_vga_de = 1'b0;", sv)

    def test_bindings(self):
        cpp = codegen.bindings_cpp(self.m, PATTERN_PORTS)
        self.assertIn('h.add_clock("clk", fs::port(top.clk, 1), 10000ULL, 0ULL);', cpp)
        # active-low reset starts asserted
        self.assertIn('h.add_input("rst_n", fs::port(top.rst_n, 1), 0ULL);', cpp)
        self.assertIn('h.add_output("ja", fs::port(top.ja, 8));', cpp)
        self.assertIn("c.timing = fs::VideoTiming{640, 16, 96, 48, 480, 10, 2, 33, true};", cpp)
        self.assertIn("c.has_de = false;", cpp)
        self.assertIn("fs::port(top.fs_vga_red, 8)", cpp)

    def test_probe_taps(self):
        sv = codegen.wrapper_sv(self.m, PATTERN_PORTS)
        self.assertIn("output wire [63:0]   fs_probe_frame", sv)
        self.assertIn("output wire [31:0]   fs_probe_frame_bits", sv)
        self.assertIn("assign fs_probe_frame = 64'($unsigned(dut.frame));", sv)
        self.assertIn("assign fs_probe_frame_bits = 32'($bits(dut.frame));", sv)
        self.assertIn("assign fs_probe_vc_minus_500 = 64'($unsigned($signed({1'b0, dut.vc}) - 11'sd500));", sv)
        cpp = codegen.bindings_cpp(self.m, PATTERN_PORTS)
        self.assertIn('h.add_probe("frame", fs::port(top.fs_probe_frame, 64), fs::port(top.fs_probe_frame_bits, 32));', cpp)

    def test_dump_function(self):
        self.m.dumps.append(manifest.Dump("cells", "dut.u.mem"))
        sv = codegen.wrapper_sv(self.m, PATTERN_PORTS)
        self.assertIn('export "DPI-C" function fs_dump_memory;', sv)
        self.assertIn("0: begin  // hist", sv)
        self.assertIn("framescope_dpi::fs_dump_begin(0, $bits(dut.hist[$low(dut.hist)]), $size(dut.hist));", sv)
        self.assertIn("framescope_dpi::fs_dump_word(1, k, c, 64'(dut.u.mem[$low(dut.u.mem) + k] >> (64 * c)));", sv)
        cpp = codegen.bindings_cpp(self.m, PATTERN_PORTS)
        self.assertIn('#include "Vframescope_top__Dpi.h"', cpp)
        self.assertIn('h.add_dump("hist", 0);', cpp)
        self.assertIn('h.add_dump("cells", 1);', cpp)
        self.assertIn('svGetScopeFromName("TOP.framescope_top")', cpp)
        self.assertIn("fs_dump_memory(id);", cpp)

    def test_no_dumps_no_dpi_export(self):
        self.m.dumps.clear()
        self.m.probes.clear()
        sv = codegen.wrapper_sv(self.m, PATTERN_PORTS)
        cpp = codegen.bindings_cpp(self.m, PATTERN_PORTS)
        self.assertNotIn("fs_dump_memory", sv + cpp)
        self.assertNotIn("fs_probe_", sv + cpp)
        self.assertNotIn("__Dpi.h", cpp)

    def test_validate_accepts_example(self):
        codegen.validate(self.m, PATTERN_PORTS)

    def test_validate_rejects_unknown_clock(self):
        ports = [p for p in PATTERN_PORTS if p.name != "clk"] + [Port("clock", "input", 0, 0, False)]
        with self.assertRaisesRegex(FramescopeError, "'clk' is not a port"):
            codegen.validate(self.m, ports)

    def test_validate_rejects_missing_monitor_signal(self):
        del self.m.monitors[0].signals["vsync"]
        with self.assertRaisesRegex(FramescopeError, "missing signals"):
            codegen.validate(self.m, PATTERN_PORTS)

    def test_de_delay_needs_de(self):
        self.m.monitors[0].options["de_delay"] = 2
        with self.assertRaisesRegex(FramescopeError, "de_delay needs signals.de"):
            codegen.validate(self.m, PATTERN_PORTS)


if __name__ == "__main__":
    unittest.main()
