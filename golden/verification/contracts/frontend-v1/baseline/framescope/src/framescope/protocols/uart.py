"""UART link: decode a design's serial TX pin, drive its RX input.

One [[monitor]] with protocol = "uart" is one serial link:

  * signals.tx (optional): a design output (any 1-bit SV expression) that the
    harness decodes into bytes and lines;
  * drive (optional): a 1-bit top-level input that the harness drives with
    bytes from [[uart]] stimulus tables or from a host process (`run --host`).

Bits are timed from simulated time (1e12 / baud ps per bit), not from a design
clock, so the monitor is independent of how the design divides its clock.
"""

from __future__ import annotations

from collections.abc import Callable

from .. import FramescopeError
from ..manifest import IDENT, MonitorSpec
from .base import Protocol, Tap, cpp_str

_PARITY = {"none": 0, "even": 1, "odd": 2}
_LINE_END = {"lf": 0x0A, "cr": 0x0D, "none": -1}
DEFAULTS = {
    "data_bits": 8, "parity": "none", "stop_bits": 1, "idle": 1, "line_end": "lf", "max_line": 1024,
    "log_bytes": False, "reply_delay_bits": 10,
}


def _ms(ps: int | None) -> float | None:
    return None if ps is None else round(ps / 1e9, 6)


def _pos(ev: dict, prefix: str = "") -> dict:
    return {f"{prefix}{k}": ev.get(f"{prefix}{k}") for k in ("frame", "line", "pixel")}


def split_line(data: bytes, line_end: str) -> tuple[str, str]:
    """(text without the terminator, terminator) of one received line."""
    term = b""
    if line_end == "lf" and data.endswith(b"\n"):
        term = b"\r\n" if data.endswith(b"\r\n") else b"\n"
    elif line_end == "cr" and data.endswith(b"\r"):
        term = b"\r"
    body = data[: len(data) - len(term)]
    return body.decode("ascii", errors="backslashreplace"), term.decode("ascii")


def payload_bytes(spec: dict, where: str) -> bytes:
    """The bytes of a [[uart]] table or host reply: exactly one of text, hex, bytes."""
    given = [k for k in ("text", "hex", "bytes") if k in spec]
    if len(given) != 1:
        raise FramescopeError(f"{where}: give exactly one of text/hex/bytes")
    v = spec[given[0]]
    if given[0] == "text":
        if not isinstance(v, str):
            raise FramescopeError(f"{where}: text must be a string")
        return v.encode("utf-8")
    if given[0] == "hex":
        if not isinstance(v, str):
            raise FramescopeError(f"{where}: hex must be a string of hex digit pairs")
        try:
            return bytes.fromhex(v)
        except ValueError:
            raise FramescopeError(f"{where}: hex {v!r} is not a string of hex digit pairs") from None
    if not isinstance(v, list) or not all(isinstance(b, int) and not isinstance(b, bool) and 0 <= b <= 255 for b in v):
        raise FramescopeError(f"{where}: bytes must be a list of integers 0..255")
    return bytes(v)


class UartProtocol(Protocol):
    name = "uart"
    required = ()
    optional = ("tx",)
    option_keys = frozenset({"baud", "drive", *DEFAULTS})
    cpp_header = "uart_monitor.hpp"
    frames = False

    def opt(self, mon: MonitorSpec, key: str):
        return mon.options.get(key, DEFAULTS.get(key))

    def validate(self, mon: MonitorSpec) -> None:
        super().validate(mon)
        where = f"monitor '{mon.name}'"
        baud = mon.options.get("baud")
        if isinstance(baud, bool) or not isinstance(baud, (int, float)) or baud <= 0:
            raise FramescopeError(f"{where}: baud must be a positive number (bits per second)")
        checks = {
            "data_bits": lambda v: isinstance(v, int) and not isinstance(v, bool) and 5 <= v <= 8,
            "parity": lambda v: v in _PARITY,
            "stop_bits": lambda v: v in (1, 2) and not isinstance(v, bool),
            "idle": lambda v: v in (0, 1) and not isinstance(v, bool),
            "line_end": lambda v: v in _LINE_END,
            "max_line": lambda v: isinstance(v, int) and not isinstance(v, bool) and 1 <= v <= 65536,
            "log_bytes": lambda v: isinstance(v, bool),
            "reply_delay_bits": lambda v: isinstance(v, (int, float)) and not isinstance(v, bool) and v >= 0,
        }
        hints = {
            "data_bits": "an integer 5..8", "parity": f"one of {sorted(_PARITY)}", "stop_bits": "1 or 2",
            "idle": "0 or 1", "line_end": f"one of {sorted(_LINE_END)}", "max_line": "an integer 1..65536",
            "log_bytes": "true or false", "reply_delay_bits": "a number >= 0",
        }
        for key, ok in checks.items():
            if key in mon.options and not ok(mon.options[key]):
                raise FramescopeError(f"{where}: {key} must be {hints[key]}")
        drive = mon.options.get("drive")
        if drive is not None and (not isinstance(drive, str) or not IDENT.match(drive)):
            raise FramescopeError(f"{where}: drive must name a 1-bit top-level input port")
        if "tx" not in mon.signals and drive is None:
            raise FramescopeError(f"{where}: give signals.tx (decode) and/or drive (transmit)")

    def check_ports(self, mon: MonitorSpec, ports: dict, clocks: set[str]) -> None:
        drive = mon.options.get("drive")
        if drive is None:
            return
        p = ports.get(drive)
        if p is None or p.direction != "input" or p.width != 1:
            raise FramescopeError(f"monitor '{mon.name}': drive '{drive}' must be a 1-bit input port of the top")
        if drive in clocks:
            raise FramescopeError(f"monitor '{mon.name}': drive '{drive}' is a clock")

    def can_send(self, mon: MonitorSpec) -> bool:
        return mon.options.get("drive") is not None

    def can_host(self, mon: MonitorSpec) -> bool:
        return "tx" in mon.signals and self.opt(mon, "line_end") != "none"

    def bit_ps(self, mon: MonitorSpec) -> float:
        return 1e12 / float(mon.options["baud"])

    def taps(self, mon: MonitorSpec) -> list[Tap]:
        return [Tap("tx", 1, mon.signals.get("tx", f"1'b{self.opt(mon, 'idle')}"))]

    def cpp_bind(self, mon: MonitorSpec, member: Callable[[str], str]) -> str:
        drive = mon.options.get("drive")
        log_bytes = self.opt(mon, "log_bytes") or self.opt(mon, "line_end") == "none"
        lines = [
            "  {",
            "    fs::UartConfig c;",
            f"    c.name = {cpp_str(mon.name)};",
            f"    c.baud = {float(mon.options['baud'])!r};",
            f"    c.data_bits = {self.opt(mon, 'data_bits')};",
            f"    c.parity = {_PARITY[self.opt(mon, 'parity')]};",
            f"    c.stop_bits = {self.opt(mon, 'stop_bits')};",
            f"    c.idle = {self.opt(mon, 'idle')};",
            f"    c.eol = {_LINE_END[self.opt(mon, 'line_end')]};",
            f"    c.max_line = {self.opt(mon, 'max_line')};",
            f"    c.has_tx = {'true' if 'tx' in mon.signals else 'false'};",
            f"    c.has_drive = {'true' if drive else 'false'};",
            f"    c.log_bytes = {'true' if log_bytes else 'false'};",
            f"    fs::UartPins p{{fs::port({member('tx')}, 1), {f'fs::port(top.{drive}, 1)' if drive else 'fs::PortRef{}'}}};",
            "    h.add_monitor(std::make_unique<fs::UartMonitor>(c, p));",
            "  }",
        ]
        return "\n".join(lines)

    # ------------------------------------------------------------ report

    def config(self, mon: MonitorSpec) -> dict:
        return {
            "baud": mon.options["baud"],
            "bit_ns": round(self.bit_ps(mon) / 1e3, 3),
            **{k: self.opt(mon, k) for k in ("data_bits", "parity", "stop_bits", "idle", "line_end",
                                             "reply_delay_bits")},
            "tx": mon.signals.get("tx"),
            "drive": mon.options.get("drive"),
        }

    def line_entry(self, mon: MonitorSpec, ev: dict) -> dict:
        data = bytes.fromhex(ev["hex"])
        text, end = split_line(data, self.opt(mon, "line_end"))
        out = {
            "index": ev["index"], "text": text, "end": end, "bytes": ev["bytes"], "errors": ev["errors"],
            "terminated": ev["terminated"], "t_ms": _ms(ev["t_ps"]), "end_t_ms": _ms(ev["end_ps"]),
            **_pos(ev), **_pos(ev, "end_"),
        }
        if any(b >= 0x80 for b in data):
            out["hex"] = ev["hex"]
        return out

    def analyze(self, mon: MonitorSpec, frames: list[dict], summary: dict, sim: dict, events=()) -> dict:
        lines = [self.line_entry(mon, e) for e in events if e.get("event") == "uart_line"]
        byte_log = [
            {"index": e["index"], "value": e["value"], "char": split_line(bytes([e["value"]]), "none")[0],
             "framing_error": e["framing_error"], "parity_error": e["parity_error"],
             "t_ms": _ms(e["t_ps"]), "end_t_ms": _ms(e["end_ps"]), **_pos(e)}
            for e in events if e.get("event") == "uart_byte"
        ]
        errors = [{"kind": e["kind"], "value": e["value"], "t_ms": _ms(e["t_ps"]), **_pos(e)}
                  for e in events if e.get("event") == "uart_error"]
        triggers = {e["id"]: e for e in events if e.get("event") == "send"}
        sent = []
        for e in events:
            if e.get("event") != "uart_sent":
                continue
            data = bytes.fromhex(e["hex"])
            entry = {
                "source": e["source"], "text": data.decode("ascii", errors="backslashreplace"), "bytes": e["bytes"],
                "queued_t_ms": _ms(e["queued_ps"]), "t_ms": _ms(e["t_ps"]), "end_t_ms": _ms(e["end_ps"]),
                **_pos(e), **_pos(e, "end_"),
            }
            if e["source"] == "stim":
                entry["stim"] = e["id"]
                trig = triggers.get(e["id"])
                if trig is not None:
                    entry["trigger"] = {k: trig[k] for k in ("frame", "line", "pixel") if k in trig}
                    entry["triggered_at"] = {k[3:]: trig[k] for k in ("at_frame", "at_line", "at_pixel") if k in trig}
            else:
                entry["reply_to"] = e["id"]
            sent.append(entry)
        pending = None
        if summary.get("pending_hex"):
            text, _ = split_line(bytes.fromhex(summary["pending_hex"]), "none")
            pending = {"text": text, "bytes": len(summary["pending_hex"]) // 2}
        out = {
            "protocol": self.name,
            "config": self.config(mon),
            "lines": lines,
            "pending": pending,
            "errors": errors,
            "sent": sent,
            "stats": summary,
            "diagnosis": self._diagnose(mon, summary, sim),
        }
        if self.opt(mon, "log_bytes") or self.opt(mon, "line_end") == "none":
            out["bytes"] = byte_log
        return out

    def _diagnose(self, mon: MonitorSpec, s: dict, sim: dict) -> list[str]:
        if not s:
            return ["monitor reported no summary (simulation aborted?)"]
        notes = []
        tx, idle = mon.signals.get("tx"), self.opt(mon, "idle")
        if tx is not None and s.get("edges", 0) == 0:
            if s.get("level") not in (None, -1, idle):
                notes.append(f"TX '{tx}' stayed at {s.get('level')}, the non-idle level, for the whole run: "
                             "check `idle` and the design's reset.")
            else:
                notes.append(f"TX '{tx}' never left the idle level: the design sent nothing "
                             "(is its transmitter enabled?).")
        bad = s.get("framing_errors", 0) + s.get("parity_errors", 0)
        if bad:
            msg = f"{s.get('framing_errors', 0)} framing and {s.get('parity_errors', 0)} parity errors in {s.get('bytes', 0)} bytes"
            pulse = s.get("min_pulse_ps", -1)
            if pulse and pulse > 0:
                est = 1e12 / pulse
                baud = float(mon.options["baud"])
                if abs(est - baud) / baud > 0.05:
                    msg += f"; the shortest pulse is {pulse / 1e6:.3f} us (~{est:.0f} baud, configured {baud:.0f})"
            notes.append(msg + ".")
        if s.get("glitches", 0):
            notes.append(f"{s['glitches']} start bit(s) shorter than half a bit were ignored.")
        if s.get("pending_hex"):
            notes.append(f"{len(s['pending_hex']) // 2} byte(s) after the last line end were never terminated "
                         "(see `pending`).")
        if s.get("receiving"):
            notes.append("a byte was still being received when the run ended.")
        unsent = s.get("unsent") or []
        if unsent:
            notes.append(f"{len(unsent)} queued transmission(s) did not finish before the run ended "
                         "(see stats.unsent); run longer or send earlier.")
        return notes

    # ------------------------------------------------------- host process

    def host_start(self, mon: MonitorSpec) -> dict:
        return {"event": "start", "link": mon.name, **self.config(mon)}

    def host_message(self, mon: MonitorSpec, ev: dict) -> dict:
        return {"event": "line", "link": mon.name, **self.line_entry(mon, ev), "hex": ev["hex"]}

    def host_reply(self, mon: MonitorSpec, reply: dict) -> str:
        """The harness's stdin line for a host's JSON reply to one line."""
        if not isinstance(reply, dict):
            raise FramescopeError(f"uart host for '{mon.name}': reply must be a JSON object, got {reply!r}")
        unknown = set(reply) - {"text", "hex", "bytes", "delay_bits"}
        if unknown:
            raise FramescopeError(f"uart host for '{mon.name}': unknown reply key(s) {sorted(unknown)}")
        delay = reply.get("delay_bits", self.opt(mon, "reply_delay_bits"))
        if isinstance(delay, bool) or not isinstance(delay, (int, float)) or delay < 0:
            raise FramescopeError(f"uart host for '{mon.name}': delay_bits must be a number >= 0")
        payload = {k: v for k, v in reply.items() if k != "delay_bits"}
        data = payload_bytes(payload, f"uart host for '{mon.name}'") if payload else b""
        return f"R {float(delay)!r} {data.hex().upper() or '-'}"
