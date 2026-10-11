"""UART links end to end through a real runtime (skipped when none is available).

examples/uart_echo greets every frame with "HELLO xx\\r\\n" and echoes what it
receives upper-cased. Loopback runs decode the harness's own transmitter by
pointing a second monitor's tx at the driven input, so encoder and decoder
are checked for each frame format.
"""

import json
import os
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

from helpers import EXAMPLES, write
from test_integration import RT, _quiet

from framescope import manifest
from framescope.run import run

ECHO = EXAMPLES / "uart_echo"
ECHO_RTL = (ECHO / "rtl" / "uart_echo_top.sv").as_posix()
BIT_PS = 1e12 / 115200  # report times (t_ms) have 1 ns resolution, hence delta=1_000 ps


def _lines(report, link="uart"):
    return [ln["text"] for ln in report["monitors"][link]["lines"]]


@unittest.skipIf(RT is None, "no framescope runtime available")
class UartEchoTest(unittest.TestCase):
    def test_scripted_bytes_echo_and_break(self):
        m = manifest.load(ECHO)
        with tempfile.TemporaryDirectory(dir=m.work_dir.parent) as out:
            report = run(m, RT, _quiet, frames=3, out=Path(out), save="none", stim=ECHO / "stim_echo.toml")
            self.assertTrue(report["ok"], report)
            u = report["monitors"]["uart"]
            self.assertEqual(_lines(report), ["HELLO 00", "HELLO 01", "PING", "HELLO 02", "ABC", "HELLO 03"])
            hello = [ln for ln in u["lines"] if ln["text"].startswith("HELLO")]
            self.assertEqual(hello[0]["frame"], None)  # before frame 0: the VGA monitor is learning sync
            for i, ln in enumerate(hello[1:]):
                self.assertEqual((ln["frame"], ln["line"], ln["end"], ln["errors"]), (i, 0, "\r\n", 0))
                self.assertEqual(ln["terminated"], "eol")
                # 10 bytes; the design's bytes are 8681 clocks apart, the last one ends 10 ideal bits in
                self.assertAlmostEqual((ln["end_t_ms"] - ln["t_ms"]) * 1e9, 9 * 86_810_000 + 10 * BIT_PS, delta=1_000)

            ping, abc, crlf, bang = u["sent"]
            self.assertEqual([s["text"] for s in u["sent"]], ["ping\r\n", "abc", "\r\n", "!"])
            self.assertEqual([s["stim"] for s in u["sent"]], [0, 1, 2, 3])
            self.assertEqual((ping["frame"], ping["line"], ping["pixel"]), (0, 100, 0))
            self.assertEqual(ping["trigger"], {"frame": 0, "line": 100, "pixel": 0})
            self.assertAlmostEqual((ping["end_t_ms"] - ping["t_ms"]) * 1e9, 60 * BIT_PS, delta=1_000)
            # Same trigger: "\r\n" waits for "abc", then has 2 idle bits between its bytes.
            self.assertEqual(crlf["t_ms"], abc["end_t_ms"])
            self.assertAlmostEqual((crlf["end_t_ms"] - crlf["t_ms"]) * 1e9, 22 * BIT_PS, delta=1_000)
            self.assertEqual(crlf["queued_t_ms"], abc["queued_t_ms"])

            # The break is one framing error on a 0x00 byte, in frame 2 after line 300.
            [err] = u["errors"]
            self.assertEqual((err["kind"], err["value"], err["frame"]), ("framing", 0, 2))
            self.assertGreaterEqual(err["line"], 300)
            self.assertEqual(u["stats"]["framing_errors"], 1)
            self.assertEqual(u["stats"]["min_pulse_ps"], 868 * 10_000)  # the design's 868-clock bit
            probes = [f["probes"] for f in report["monitors"]["vga"]["frames"]]
            self.assertEqual([p["rx_count"] for p in probes], [6, 11, 12])
            self.assertEqual(probes[2]["last_rx"], ord("!"))

    def test_host_lockstep_is_deterministic(self):
        m = manifest.load(ECHO)
        cmd = {"uart": [sys.executable, str(ECHO / "ack_host.py")]}
        reports = []
        for _ in range(2):
            with tempfile.TemporaryDirectory(dir=m.work_dir.parent) as out:
                r = run(m, RT, _quiet, frames=2, out=Path(out), save="none", hosts=cmd,
                        stim=ECHO / "stim_echo.toml")
                self.assertTrue(r["ok"], r)
                self.assertTrue(Path(r["monitors"]["uart"]["host"]["log"]).is_file())
                reports.append(r)
        a, b = (r["monitors"]["uart"] for r in reports)
        self.assertEqual(_lines(reports[0]), ["HELLO 00", "ACK 00", "HELLO 01", "ACK 01", "PING", "HELLO 02", "ACK 02", "ABC"])
        self.assertEqual((a["lines"], a["sent"]), (b["lines"], b["sent"]))
        self.assertEqual(a["host"]["requests"], len(a["lines"]))
        self.assertEqual(a["host"]["exit_code"], 0)
        by_index = {ln["index"]: ln for ln in a["lines"]}
        replies = [s for s in a["sent"] if s["source"] == "host"]
        self.assertEqual([s["text"] for s in replies], ["ack 00\r\n", "ack 01\r\n", "ack 02\r\n"])
        for s in replies:
            line = by_index[s["reply_to"]]
            # reply_delay_bits = 10 after the line's end, independent of wall-clock time
            self.assertAlmostEqual((s["t_ms"] - line["end_t_ms"]) * 1e9, 10 * BIT_PS, delta=1_000)

    def test_host_failure_is_an_error(self):
        m = manifest.load(ECHO)
        with tempfile.TemporaryDirectory(dir=m.work_dir.parent) as out:
            bad = write(Path(out) / "bad.py", "import sys\nfor _ in sys.stdin:\n    print('oops', flush=True)\n")
            r = run(m, RT, _quiet, frames=2, out=Path(out) / "run", save="none", hosts={"uart": [sys.executable, str(bad)]})
            self.assertFalse(r["ok"])
            self.assertIn("non-JSON line 'oops'", r["errors"][0])

    def test_checkpoint_matches_cold_run(self):
        m = manifest.load(ECHO)
        reports = []
        for ck in (None, 1, 1):  # cold, boot + restore, cached restore
            with tempfile.TemporaryDirectory(dir=m.work_dir.parent) as out:
                r = run(m, RT, _quiet, frames=3, out=Path(out), save="none", stim=ECHO / "stim_echo.toml",
                        checkpoint=ck)
                self.assertTrue(r["ok"], r)
                reports.append(r)
        cold, boot, cached = reports
        self.assertIsNone(cold["checkpoint"])
        self.assertTrue(boot["checkpoint"]["restored"] and cached["checkpoint"]["restored"])
        self.assertFalse(cached["checkpoint"]["created"])
        self.assertGreater(len([ln for ln in boot["monitors"]["uart"]["lines"] if ln["t_ms"] < boot["checkpoint"]["t_ms"]]), 0)
        for r in (boot, cached):
            self.assertEqual(r["monitors"]["uart"], cold["monitors"]["uart"])
            self.assertEqual([f["crc32"] for f in r["monitors"]["vga"]["frames"]],
                             [f["crc32"] for f in cold["monitors"]["vga"]["frames"]])
            self.assertEqual([f.get("probes") for f in r["monitors"]["vga"]["frames"]],
                             [f.get("probes") for f in cold["monitors"]["vga"]["frames"]])

    def test_checkpoint_refused_when_a_host_missed_lines(self):
        m = manifest.load(ECHO)
        with tempfile.TemporaryDirectory(dir=m.work_dir.parent) as out:
            r = run(m, RT, _quiet, frames=3, out=Path(out), save="none", checkpoint=1,
                    hosts={"uart": [sys.executable, str(ECHO / "ack_host.py")]})
            self.assertTrue(r["ok"], r)
            self.assertFalse(r["checkpoint"]["restored"])
            self.assertIn("UART link 'uart' received", r["checkpoint"]["reason"])
            self.assertEqual(_lines(r)[:2], ["HELLO 00", "ACK 00"])  # ran from time 0

    def _loopback(self, monitors: str, stim: str, frames=1):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            cfg = write(tmp / "framescope.toml", textwrap.dedent(f"""
                [design]
                top = "uart_echo_top"
                sources = ["{ECHO_RTL}"]
                [clocks]
                clk = 100e6
                [reset]
                port = "rst_n"
                active = 0
                [[monitor]]
                name = "vga"
                protocol = "vga"
                timing = "640x480@60"
                [monitor.signals]
                pclk = "clk"
                pclk_en = "dut.pix_stb"
                red = "vga_r"
                green = "vga_g"
                blue = "vga_b"
                hsync = "hsync"
                vsync = "vsync"
            """) + textwrap.dedent(monitors))
            write(tmp / "stim.toml", textwrap.dedent(stim))
            report = run(manifest.load(cfg), RT, _quiet, frames=frames, save="none", stim=tmp / "stim.toml")
            self.assertTrue(report["ok"], report)
            return report

    def test_loopback_7e2_and_parity_mismatch(self):
        fmt = 'baud = 115200\ndata_bits = 7\nparity = "even"\nstop_bits = 2\n'
        report = self._loopback(f"""
            [[monitor]]
            name = "out"
            protocol = "uart"
            drive = "rx"
            {fmt}
            [[monitor]]
            name = "seen"
            protocol = "uart"
            {fmt}
            [monitor.signals]
            tx = "rx"
            [[monitor]]
            name = "odd"
            protocol = "uart"
            baud = 115200
            data_bits = 7
            parity = "odd"
            stop_bits = 2
            [monitor.signals]
            tx = "rx"
        """, """
            [[uart]]
            us = 100
            bytes = [0x41, 0x43, 0x7f, 0x00, 0x0a]
        """)
        seen, odd = report["monitors"]["seen"], report["monitors"]["odd"]
        self.assertEqual(seen["lines"][0]["text"], "AC\x7f\x00")
        self.assertEqual((seen["stats"]["parity_errors"], seen["stats"]["framing_errors"], seen["errors"]), (0, 0, []))
        self.assertEqual(seen["lines"][0]["t_ms"], 0.1)
        # 5 bytes of 1 + 7 + 1 + 2 bits
        self.assertAlmostEqual(seen["lines"][0]["end_t_ms"], 0.1 + 55 * BIT_PS / 1e9, places=6)
        self.assertEqual(odd["stats"]["parity_errors"], 5)
        self.assertEqual([e["kind"] for e in odd["errors"]], ["parity"] * 5)
        self.assertEqual(odd["lines"][0]["errors"], 5)
        self.assertEqual(report["monitors"]["out"]["stats"]["sent_bytes"], 5)

    def test_loopback_inverted_bytes_framing_and_length(self):
        report = self._loopback("""
            [[monitor]]
            name = "out"
            protocol = "uart"
            baud = 115200
            idle = 0
            drive = "rx"
            [[monitor]]
            name = "raw"
            protocol = "uart"
            baud = 115200
            idle = 0
            line_end = "none"
            [monitor.signals]
            tx = "rx"
            [[monitor]]
            name = "short"
            protocol = "uart"
            baud = 115200
            idle = 0
            max_line = 3
            [monitor.signals]
            tx = "rx"
            [[monitor]]
            name = "fast"
            protocol = "uart"
            baud = 230400
            idle = 0
            [monitor.signals]
            tx = "rx"
        """, """
            [[uart]]
            ms = 0.2
            text = "hello\\n"

            [[uart]]
            ms = 1
            bytes = [0]
        """)
        raw = report["monitors"]["raw"]
        self.assertEqual([b["value"] for b in raw["bytes"]], list(b"hello\n\0"))
        self.assertEqual(raw["lines"], [])
        self.assertEqual(raw["bytes"][1]["t_ms"], round(0.2 + 10 * BIT_PS / 1e9, 6))
        short = report["monitors"]["short"]
        self.assertEqual([(ln["text"], ln["terminated"]) for ln in short["lines"]], [("hel", "length"), ("lo", "eol")])
        self.assertEqual(short["pending"], {"text": "\x00", "bytes": 1})
        # A zero byte at half the bit time: the stop bit is sampled inside the data bits.
        fast = report["monitors"]["fast"]
        self.assertGreater(fast["stats"]["framing_errors"], 0)
        self.assertTrue(any("~115200 baud, configured 230400" in d for d in fast["diagnosis"]), fast["diagnosis"])

    def test_link_without_video(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            cfg = write(tmp / "framescope.toml", textwrap.dedent(f"""
                [design]
                top = "uart_echo_top"
                sources = ["{ECHO_RTL}"]
                [clocks]
                clk = 100e6
                [reset]
                port = "rst_n"
                active = 0
                [[monitor]]
                name = "uart"
                protocol = "uart"
                baud = 115200
                drive = "rx"
                [monitor.signals]
                tx = "tx"
            """))
            write(tmp / "s.toml", '[[uart]]\nus = 50\ntext = "hi\\r\\n"\n')
            report = run(manifest.load(cfg), RT, _quiet, frames=1, save="none", stim=tmp / "s.toml", max_time_ms=1)
            self.assertTrue(report["ok"], report)
            self.assertEqual(report["sim"]["stop_reason"], "max_time")
            self.assertEqual(_lines(report), ["HI"])
            self.assertIsNone(report["monitors"]["uart"]["lines"][0]["frame"])


def _xor(payload: str) -> int:
    c = 0
    for b in payload.encode("ascii"):
        c ^= b
    return c


@unittest.skipIf(RT is None or os.environ.get("FRAMESCOPE_METACIRCUIT_TEST") != "1",
                 "set FRAMESCOPE_METACIRCUIT_TEST=1 (needs the metacircuit checkout)")
class MetacircuitUartTest(unittest.TestCase):
    def _check_netlist(self, lines):
        """Checksums, and complete NB, NC x3, NE snapshots (the boot circuit: V + 2 R); returns their ids."""
        ids, tags = [], []
        for ln in lines:
            self.assertEqual((ln["end"], ln["errors"]), ("\r\n", 0))
            payload, _, ck = ln["text"][1:].rpartition("*")
            self.assertEqual(int(ck, 16), _xor(payload), ln["text"])
            fields = payload.split(",")
            tags.append(fields[0])
            if fields[0] == "NE":
                self.assertEqual(tags, ["NB", "NC", "NC", "NC", "NE"])
                ids.append(int(fields[1], 16))
                tags = []
        self.assertGreater(len(ids), 0)
        return ids

    def test_netlist_and_scripted_reply(self):
        m = manifest.load(EXAMPLES / "metacircuit")
        stim = EXAMPLES / "metacircuit" / "stim_uart_reply.toml"
        report = run(m, RT, _quiet, frames=2, save="none", dump="last", sets=["SW=32"], stim=stim)
        self.assertTrue(report["ok"], report)
        u = report["monitors"]["uart"]
        self.assertEqual(self._check_netlist(u["lines"])[0], 1)
        frames = report["monitors"]["vga"]["frames"]
        self.assertEqual([f["probes"]["reply_valid"] for f in frames], [0, 1])
        p = frames[1]["probes"]
        self.assertEqual((p["reply_frame"], p["reply_node_count"], p["reply_status"]), (1, 1, 0))
        self.assertEqual((p["snapshot_id"], p["snapshot_id_valid"], p["reply_stale_count"]), (1, 1, 0))
        bank = f"voltages_bank{p['reply_bank']}"
        words = json.loads(Path(report["dumps"][bank][0]["path"]).read_text())["words"]
        self.assertEqual(words[0], "0x40000000")  # 2.0 V on node 0
        self.assertEqual(p["voltage_node0"], 0x40000000)
        self.assertEqual(p["uart_client"], 1)
        self.assertGreaterEqual(p["netlist_sent_count"], 1)

    def test_stale_reply_is_dropped(self):
        m = manifest.load(EXAMPLES / "metacircuit")
        text = (EXAMPLES / "metacircuit" / "stim_uart_reply.toml").read_text()
        stale = []
        for line in text.splitlines():
            if line.startswith("text = "):
                body = line[len('text = "'):-1].replace("\\r\\n", "\n").split("\n")[:-1]
                pls = [b[1:].rpartition("*")[0].replace(",0001,", ",0005,") for b in body]
                line = 'text = "' + "".join(f"@{pl}*{_xor(pl):02X}\\r\\n" for pl in pls) + '"'
            stale.append(line)
        with tempfile.TemporaryDirectory() as tmp:
            stim = write(Path(tmp) / "stale.toml", "\n".join(stale) + "\n")
            report = run(m, RT, _quiet, frames=2, save="none", sets=["SW=32"], stim=stim)
        self.assertTrue(report["ok"], report)
        self.assertIn("@VB,0005,", report["monitors"]["uart"]["sent"][0]["text"])
        p = report["monitors"]["vga"]["frames"][1]["probes"]
        self.assertEqual((p["reply_valid"], p["reply_stale_count"], p["reply_stale_frame"]), (0, 1, 5))

    def test_simulated_solver_host(self):
        root = Path(os.environ.get("METACIRCUIT", EXAMPLES.parents[1] / "nus-EE2026-metacircuit"))
        if not (root / "src" / "uart_link" / "frontend_tester.py").is_file():
            self.skipTest("no src/uart_link in the metacircuit checkout")
        m = manifest.load(EXAMPLES / "metacircuit")
        cmd = [sys.executable, str(EXAMPLES / "metacircuit" / "uart_solver_host.py")]
        report = run(m, RT, _quiet, frames=2, save="none", sets=["SW=32"], hosts={"uart": cmd})
        self.assertTrue(report["ok"], report)
        u = report["monitors"]["uart"]
        self._check_netlist(u["lines"])
        replies = [s for s in u["sent"] if s["source"] == "host"]
        self.assertGreaterEqual(len(replies), 1)
        self.assertTrue(replies[0]["text"].startswith("@VB,0001,01,00*"), replies[0])
        p = report["monitors"]["vga"]["frames"][-1]["probes"]
        self.assertEqual((p["reply_valid"], p["reply_status"], p["reply_node_count"]), (1, 0, 1))
        self.assertGreaterEqual(p["reply_frame"], 1)

    def test_solver_host_after_checkpoint_matches_cold_run(self):
        # SW[5] turns on in frame 2, after a frame-1 checkpoint: no UART traffic
        # before it, so the restored run (with a fresh host) equals a cold run.
        m = manifest.load(EXAMPLES / "metacircuit")
        cmd = [sys.executable, str(EXAMPLES / "metacircuit" / "uart_solver_host.py")]
        with tempfile.TemporaryDirectory() as tmp:
            stim = write(Path(tmp) / "sw5.toml", "[[event]]\nframe = 2\nline = 10\nset = { SW = 32 }\n")
            cold = run(m, RT, _quiet, frames=5, save="none", stim=stim, hosts={"uart": cmd})
            warm = run(m, RT, _quiet, frames=5, save="none", stim=stim, hosts={"uart": cmd}, checkpoint=1)
        self.assertTrue(cold["ok"] and warm["ok"], (cold, warm))
        self.assertTrue(warm["checkpoint"]["restored"], warm["checkpoint"])
        cu, wu = cold["monitors"]["uart"], warm["monitors"]["uart"]
        self.assertGreater(len(cu["lines"]), 0)
        self.assertGreater(len([s for s in cu["sent"] if s["source"] == "host"]), 0)
        for key in ("lines", "sent", "errors", "pending", "stats"):
            self.assertEqual(wu[key], cu[key], key)
        self.assertEqual(wu["host"]["requests"], cu["host"]["requests"])
        self.assertEqual([f["probes"] for f in warm["monitors"]["vga"]["frames"]],
                         [f["probes"] for f in cold["monitors"]["vga"]["frames"]])


if __name__ == "__main__":
    unittest.main()
