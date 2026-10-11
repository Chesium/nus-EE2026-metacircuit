"""UART link: manifest/codegen/stimulus checks, report building, host protocol."""

import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

from helpers import EXAMPLES, write

from framescope import FramescopeError, codegen, host, manifest, protocols
from framescope.ports import Port
from framescope.protocols.uart import UartProtocol, payload_bytes, split_line
from framescope.run import run
from framescope.stimulus import compile_lines

ECHO_RTL = (EXAMPLES / "uart_echo" / "rtl" / "uart_echo_top.sv").as_posix()
ECHO_PORTS = [
    Port("clk", "input", 0, 0, False),
    Port("rst_n", "input", 0, 0, False),
    Port("rx", "input", 0, 0, False),
    Port("tx", "output", 0, 0, False),
    Port("vga_r", "output", 3, 0, True),
    Port("vga_g", "output", 3, 0, True),
    Port("vga_b", "output", 3, 0, True),
    Port("hsync", "output", 0, 0, False),
    Port("vsync", "output", 0, 0, False),
]
UART = UartProtocol()


def uart_only(tmp: Path, options: str) -> Path:
    return write(tmp / "framescope.toml", textwrap.dedent(f"""
        [design]
        top = "uart_echo_top"
        sources = ["{ECHO_RTL}"]
        [clocks]
        clk = 100e6
        [[monitor]]
        name = "uart"
        protocol = "uart"
        {options}
    """))


class UartManifestTest(unittest.TestCase):
    def setUp(self):
        self.m = manifest.load(EXAMPLES / "uart_echo")
        self.mon = self.m.monitors[1]

    def test_example_loads_and_validates(self):
        self.assertEqual((self.mon.name, self.mon.protocol), ("uart", "uart"))
        self.assertEqual(self.mon.signals, {"tx": "tx"})
        codegen.validate(self.m, ECHO_PORTS)
        self.assertEqual(protocols.primary(self.m).name, "vga")
        self.assertEqual([m.name for m in protocols.links(self.m, "send")], ["uart"])
        self.assertEqual([m.name for m in protocols.links(self.m, "host")], ["uart"])

    def test_option_errors(self):
        for options, msg in [
            ({}, "baud must be a positive number"),
            ({"baud": 0}, "baud must be a positive number"),
            ({"baud": 9600, "parity": "mark"}, "parity must be one of"),
            ({"baud": 9600, "data_bits": 9}, r"data_bits must be an integer 5\.\.8"),
            ({"baud": 9600, "stop_bits": 1.5}, "stop_bits must be 1 or 2"),
            ({"baud": 9600, "idle": True}, "idle must be 0 or 1"),
            ({"baud": 9600, "line_end": "crlf"}, "line_end must be one of"),
            ({"baud": 9600, "drive": "a.b"}, "drive must name"),
            ({"baud": 9600, "speed": 1}, "unknown option"),
        ]:
            with self.subTest(options=options), self.assertRaisesRegex(FramescopeError, msg):
                UART.validate(manifest.MonitorSpec("u", "uart", {"tx": "tx"}, options))
        with self.assertRaisesRegex(FramescopeError, "signals.tx .* and/or drive"):
            UART.validate(manifest.MonitorSpec("u", "uart", {}, {"baud": 9600}))

    def test_drive_must_be_a_one_bit_input(self):
        for drive, msg in [("tx", "1-bit input"), ("vga_r", "1-bit input"), ("nope", "1-bit input"), ("clk", "is a clock")]:
            self.mon.options["drive"] = drive
            with self.subTest(drive=drive), self.assertRaisesRegex(FramescopeError, msg):
                codegen.validate(self.m, ECHO_PORTS)

    def test_codegen(self):
        sv = codegen.wrapper_sv(self.m, ECHO_PORTS)
        self.assertIn("assign fs_uart_tx = tx;", sv)
        cpp = codegen.bindings_cpp(self.m, ECHO_PORTS)
        self.assertIn('#include "uart_monitor.hpp"', cpp)
        self.assertIn("c.baud = 115200.0;", cpp)
        self.assertIn("c.eol = 10;", cpp)
        self.assertIn("fs::UartPins p{fs::port(top.fs_uart_tx, 1), fs::port(top.rx, 1)};", cpp)
        self.mon.options.pop("drive")
        self.mon.options.update(parity="odd", stop_bits=2, idle=0, line_end="none")
        cpp = codegen.bindings_cpp(self.m, ECHO_PORTS)
        self.assertIn("fs::PortRef{}", cpp)
        for line in ("c.parity = 2;", "c.stop_bits = 2;", "c.idle = 0;", "c.eol = -1;", "c.log_bytes = true;",
                     "c.has_drive = false;"):
            self.assertIn(line, cpp)

    def test_tx_tap_defaults_to_idle(self):
        mon = manifest.MonitorSpec("u", "uart", {}, {"baud": 9600, "drive": "rx", "idle": 0})
        self.assertEqual(UART.taps(mon)[0].expr, "1'b0")
        self.assertFalse(UART.can_host(mon))
        self.assertTrue(UART.can_send(mon))


class UartStimulusTest(unittest.TestCase):
    def setUp(self):
        self.m = manifest.load(EXAMPLES / "uart_echo")

    def _compile(self, text: str, m=None):
        with tempfile.TemporaryDirectory() as tmp:
            stim = write(Path(tmp) / "s.toml", text)
            return compile_lines(m or self.m, ECHO_PORTS, stim, [])

    def test_example(self):
        lines = compile_lines(self.m, ECHO_PORTS, EXAMPLES / "uart_echo" / "stim_echo.toml", [])
        self.assertEqual(lines[2:], [
            "up 0:100:0 uart 0 0 70696E670D0A",
            "up 1:200:0 uart 1 0 616263",
            "up 1:200:0 uart 2 2 0D0A",
            "up 2:300:0 uart 3 0 21",
        ])

    def test_triggers_and_payloads(self):
        lines = self._compile(
            '[[uart]]\nus = 1.5\nbytes = [0, 255]\n'
            '[[uart]]\nlink = "uart"\nframe = 4\nhex = "ab CD"\n'
            '[[event]]\nframe = 1\nset = { rx = 0 }\n')
        self.assertEqual(lines[2:], ["f 1 rx 0", "ut 1500000 uart 0 0 00FF", "uf 4 uart 1 0 ABCD"])

    def test_errors(self):
        for text, msg in [
            ('frame = 1\ntext = "a"\nhex = "61"', "exactly one of text/hex/bytes"),
            ('frame = 1', "exactly one of text/hex/bytes"),
            ('frame = 1\ntext = ""', "nothing to send"),
            ('frame = 1\nhex = "6"', "not a string of hex digit pairs"),
            ('frame = 1\nbytes = [256]', "integers 0..255"),
            ('frame = 1\nlink = "vga"\ntext = "a"', "link 'vga' is not a monitor that can send"),
            ('frame = 1\nline = 525\ntext = "a"', r"line 525 is out of range 0..524"),
            ('frame = 1\ngap_bits = -1\ntext = "a"', "gap_bits must be a non-negative integer"),
            ('ms = 1\nline = 2\ntext = "a"', "need a frame trigger"),
            ('ms = -1\ntext = "a"', "must be a non-negative number"),
            ('frame = 1\nset = { rx = 1 }\ntext = "a"', "unknown key"),
        ]:
            with self.subTest(text=text), self.assertRaisesRegex(FramescopeError, msg):
                self._compile(f"[[uart]]\n{text}\n")
        self.m.monitors[1].options.pop("drive")
        with self.assertRaisesRegex(FramescopeError, "no monitor can send bytes"):
            self._compile('[[uart]]\nframe = 1\ntext = "a"\n')

    def test_frame_triggers_need_a_frame_monitor(self):
        with tempfile.TemporaryDirectory() as tmp:
            m = manifest.load(uart_only(Path(tmp), 'baud = 115200\ndrive = "rx"\n[monitor.signals]\ntx = "tx"'))
            self.assertIsNone(protocols.primary(m))
            self.assertEqual(self._compile('[[uart]]\nns = 10\ntext = "a"\n', m)[-1], "ut 10000 uart 0 0 61")
            with self.assertRaisesRegex(FramescopeError, "frame triggers need a monitor that produces frames"):
                self._compile('[[uart]]\nframe = 0\ntext = "a"\n', m)
            with self.assertRaisesRegex(FramescopeError, "give --max-time-ms"):
                run(m, None, lambda _: None, frames=1)


class UartReportTest(unittest.TestCase):
    def setUp(self):
        self.mon = manifest.load(EXAMPLES / "uart_echo").monitors[1]

    def test_split_line_and_payload(self):
        self.assertEqual(split_line(b"@NB*21\r\n", "lf"), ("@NB*21", "\r\n"))
        self.assertEqual(split_line(b"abc\n", "lf"), ("abc", "\n"))
        self.assertEqual(split_line(b"abc", "lf"), ("abc", ""))
        self.assertEqual(split_line(b"a\x80\r", "cr"), ("a\\x80", "\r"))
        self.assertEqual(payload_bytes({"text": "hi\r\n"}, "x"), b"hi\r\n")
        self.assertEqual(payload_bytes({"hex": "00 ff"}, "x"), b"\x00\xff")
        self.assertEqual(payload_bytes({"bytes": [1, 2]}, "x"), b"\x01\x02")

    def test_host_reply_lines(self):
        self.assertEqual(UART.host_reply(self.mon, {}), "R 10.0 -")
        self.assertEqual(UART.host_reply(self.mon, {"text": "ok\r\n"}), "R 10.0 6F6B0D0A")
        self.assertEqual(UART.host_reply(self.mon, {"hex": "40", "delay_bits": 0}), "R 0.0 40")
        self.assertEqual(UART.host_reply(self.mon, {"delay_bits": 3}), "R 3.0 -")
        for reply, msg in [([], "must be a JSON object"), ({"txt": "a"}, "unknown reply key"),
                           ({"text": "a", "delay_bits": -1}, "delay_bits must be"),
                           ({"text": "a", "hex": "61"}, "exactly one of")]:
            with self.subTest(reply=reply), self.assertRaisesRegex(FramescopeError, msg):
                UART.host_reply(self.mon, reply)

    def test_analyze(self):
        pos = {"frame": 2, "line": 0, "pixel": 15}
        none = {"frame": None, "line": None, "pixel": None}
        events = [
            {"event": "uart_line", "monitor": "uart", "index": 0, "hex": "48490D0A", "bytes": 4, "errors": 0,
             "terminated": "eol", "t_ps": 1_000_000, "end_ps": 2_000_000, **none,
             "end_frame": 0, "end_line": 3, "end_pixel": 4},
            {"event": "uart_line", "monitor": "uart", "index": 1, "hex": "FF0A", "bytes": 2, "errors": 1,
             "terminated": "eol", "t_ps": 3_000_000, "end_ps": 4_000_000, **pos,
             "end_frame": 2, "end_line": 1, "end_pixel": 0},
            {"event": "uart_error", "monitor": "uart", "kind": "framing", "value": 255, "t_ps": 3_000_000, **pos},
            {"event": "send", "monitor": "uart", "id": 0, "frame": 1, "line": 5, "pixel": 0,
             "at_frame": 1, "at_line": 5, "at_pixel": 1, "t_ps": 5},
            {"event": "uart_sent", "monitor": "uart", "source": "stim", "id": 0, "hex": "41", "bytes": 1,
             "queued_ps": 5, "t_ps": 5, "end_ps": 86_805_560, **pos, "end_frame": 2, "end_line": 3, "end_pixel": 1},
            {"event": "uart_sent", "monitor": "uart", "source": "host", "id": 1, "hex": "42", "bytes": 1,
             "queued_ps": 9, "t_ps": 9, "end_ps": 10, **pos, "end_frame": 2, "end_line": 3, "end_pixel": 1},
        ]
        summary = {"bytes": 6, "lines": 2, "framing_errors": 1, "parity_errors": 0, "glitches": 0, "edges": 40,
                   "min_pulse_ps": 4_340_000, "level": 1, "receiving": False, "pending_hex": "4142",
                   "unsent": [{"source": "stim", "id": 3, "bytes": 1, "queued_ps": 1, "started": False}]}
        r = UART.analyze(self.mon, [], summary, {}, events)
        self.assertEqual(r["config"]["bit_ns"], 8680.556)
        a, b = r["lines"]
        self.assertEqual((a["text"], a["end"], a["frame"], a["end_line"], a["t_ms"]), ("HI", "\r\n", None, 3, 0.001))
        self.assertNotIn("hex", a)
        self.assertEqual((b["text"], b["hex"], b["errors"]), ("\\xff", "FF0A", 1))
        self.assertEqual(r["errors"], [{"kind": "framing", "value": 255, "t_ms": 0.003, **pos}])
        s0, s1 = r["sent"]
        self.assertEqual((s0["stim"], s0["trigger"], s0["triggered_at"]),
                         (0, {"frame": 1, "line": 5, "pixel": 0}, {"frame": 1, "line": 5, "pixel": 1}))
        self.assertEqual((s1["source"], s1["reply_to"]), ("host", 1))
        self.assertEqual(r["pending"], {"text": "AB", "bytes": 2})
        self.assertNotIn("bytes", r)
        diag = " ".join(r["diagnosis"])
        self.assertIn("1 framing and 0 parity errors in 6 bytes", diag)
        self.assertIn("~230415 baud, configured 115200", diag)
        self.assertIn("2 byte(s) after the last line end", diag)
        self.assertIn("1 queued transmission(s) did not finish", diag)

    def test_diagnose_silent_line(self):
        r = UART.analyze(self.mon, [], {"edges": 0, "level": 1, "bytes": 0}, {}, [])
        self.assertIn("never left the idle level", r["diagnosis"][0])
        r = UART.analyze(self.mon, [], {"edges": 0, "level": 0, "bytes": 0}, {}, [])
        self.assertIn("non-idle level", r["diagnosis"][0])


HOST_SCRIPT = """
import json, sys
for raw in sys.stdin:
    msg = json.loads(raw)
    if msg["event"] != "line":
        continue
    if msg["text"] == "junk":
        print("not json", flush=True)
    elif msg["text"] == "quit":
        sys.exit(3)
    elif msg["text"] == "sleep":
        import time; time.sleep(5)
    else:
        print(json.dumps({"text": msg["text"].upper()}), flush=True)
"""


class HostTest(unittest.TestCase):
    def test_parse_specs(self):
        self.assertEqual(host.parse_specs(["python3 h.py --x=1"], ["uart"]), {"uart": ["python3", "h.py", "--x=1"]})
        self.assertEqual(host.parse_specs(["b=./h -v"], ["a", "b"]), {"b": ["./h", "-v"]})
        with self.assertRaisesRegex(FramescopeError, "write LINK=CMD"):
            host.parse_specs(["./h"], ["a", "b"])
        with self.assertRaisesRegex(FramescopeError, "not a monitor that takes a host"):
            host.parse_specs(["c=./h"], ["a", "b"])
        with self.assertRaisesRegex(FramescopeError, "given twice"):
            host.parse_specs(["a=./h", "a=./g"], ["a", "b"])

    def test_request_reply_and_failures(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            script = write(tmp / "h.py", HOST_SCRIPT)
            h = host.Host("uart", [sys.executable, str(script)], tmp / "h.log", tmp, timeout_s=1.0)
            h.send({"event": "start"})
            self.assertEqual(h.request({"event": "line", "text": "ab", "index": 0}), {"text": "AB"})
            with self.assertRaisesRegex(FramescopeError, "non-JSON line 'not json'"):
                h.request({"event": "line", "text": "junk", "index": 1})
            with self.assertRaisesRegex(FramescopeError, "did not answer line 2 within 1 s"):
                h.request({"event": "line", "text": "sleep", "index": 2})
            h.kill()
            h = host.Host("uart", [sys.executable, str(script)], tmp / "h.log", tmp, timeout_s=5.0)
            with self.assertRaisesRegex(FramescopeError, r"exited \(code 3\) without answering line 0"):
                h.request({"event": "line", "text": "quit", "index": 0})
            self.assertEqual(h.close(), 3)
            with self.assertRaisesRegex(FramescopeError, "cannot start"):
                host.Host("uart", [str(tmp / "missing")], tmp / "h.log", tmp, timeout_s=1.0)


if __name__ == "__main__":
    unittest.main()
