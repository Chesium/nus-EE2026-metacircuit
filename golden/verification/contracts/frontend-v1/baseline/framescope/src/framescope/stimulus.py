"""Compiles reset, --set overrides and stimulus TOML into the harness's line format.

Stimulus files hold [[event]] tables, each with one trigger (frame, ns, us or
ms) and a `set` table of input or virtual-input values:

    [[event]]
    frame = 2                       # when the first monitor has completed 2 frames
    set = { "mouse.x" = 120, BTNC = 1 }

    [[event]]
    frame = 3                       # frame 3 of the first monitor ...
    line = 10                       # ... at its 10th HSYNC leading edge after VSYNC
    pixel = 0                       # ... plus this many pixel clocks (optional)
    set = { "mouse.left" = 1 }

[[uart]] tables queue bytes on a UART link monitor (one with `drive`), with
the same triggers:

    [[uart]]
    link = "uart"                   # monitor name; optional with a single link
    frame = 3                       # or frame + line (+ pixel), or ns/us/ms
    line = 40
    text = "@VB,0001,01,00*78\\r\\n"  # or hex = "40 41" or bytes = [64, 65]
    gap_bits = 0                    # idle bits between bytes (optional)

Harness line format: "t <ps> NAME VALUE", "f <frame> NAME VALUE",
"p <frame>:<line>:<pixel> NAME VALUE", and for bytes
"ut|uf|up <when> LINK <index> <gap_bits> <HEX>".
"""

from __future__ import annotations

import tomllib
from pathlib import Path

from . import FramescopeError, protocols, timing
from .manifest import Manifest
from .ports import Port

_TIME_UNITS_PS = {"ns": 1_000, "us": 1_000_000, "ms": 1_000_000_000}
# Bounds when the first monitor has no timing preset (the VGA monitor's raster limit).
_MAX_LINES = 4096
_MAX_PIXELS = 4096


def raster_limits(m: Manifest) -> tuple[int, int, str]:
    """(lines per frame, pixels per line, source) that bound line/pixel offsets."""
    ref = protocols.primary(m)
    if ref is not None:
        try:
            t = timing.resolve(ref.options.get("timing"))
        except FramescopeError:
            t = None
        if t is not None:
            return t.v_total, t.h_total, f"monitor '{ref.name}' timing"
    return _MAX_LINES, _MAX_PIXELS, "the raster limit"


def compile_lines(m: Manifest, ports: list[Port], stim: Path | None, sets: list[str]) -> list[str]:
    clocks = {c.name for c in m.clocks}
    names = {p.name for p in ports if p.direction == "input" and p.name not in clocks} | set(m.virtual_inputs)

    def check(name: str, where: str) -> None:
        if name not in names:
            raise FramescopeError(f"{where}: '{name}' is not a settable input; known: {sorted(names)}")

    lines: list[str] = []
    if m.reset:
        r = m.reset
        lines.append(f"t 0 {r.port} {r.active}")
        lines.append(f"t {round(r.duration_ns * 1000)} {r.port} {1 - r.active}")
    for item in sets:
        name, sep, value = item.partition("=")
        if not sep:
            raise FramescopeError(f"--set expects NAME=VALUE, got '{item}'")
        check(name, "--set")
        lines.append(f"t 0 {name} {_value(value, '--set')}")

    if stim is not None:
        try:
            data = tomllib.loads(stim.read_text(encoding="utf-8"))
        except FileNotFoundError:
            raise FramescopeError(f"stimulus file not found: {stim}") from None
        except tomllib.TOMLDecodeError as e:
            raise FramescopeError(f"{stim}: {e}") from None
        for i, ev in enumerate(_tables(data, "event", stim)):
            where = f"{stim.name} event #{i + 1}"
            kind, when = _trigger(m, ev, where, {"set"})
            for name, value in ev.get("set", {}).items():
                check(name, where)
                lines.append(f"{kind} {when} {name} {_value(value, where)}")
        uart = _tables(data, "uart", stim)
        senders = [mon.name for mon in protocols.links(m, "send")]
        for i, ev in enumerate(uart):
            where = f"{stim.name} [[uart]] #{i + 1}"
            kind, when = _trigger(m, ev, where, {"link", "text", "hex", "bytes", "gap_bits"})
            link = ev.get("link")
            if link is None:
                if len(senders) != 1:
                    raise FramescopeError(f"{where}: name the link (one of {senders})" if senders else
                                          f"{where}: no monitor can send bytes (add `drive` to a uart monitor)")
                link = senders[0]
            elif link not in senders:
                raise FramescopeError(f"{where}: link '{link}' is not a monitor that can send; known: {senders}")
            data_bytes = protocols.uart.payload_bytes(ev, where)
            if not data_bytes:
                raise FramescopeError(f"{where}: nothing to send")
            gap = _nonneg_int(ev.get("gap_bits", 0), f"{where}: gap_bits")
            lines.append(f"u{kind} {when} {link} {i} {gap} {data_bytes.hex().upper()}")
    return lines


def _tables(data: dict, key: str, stim: Path) -> list[dict]:
    items = data.get(key, [])
    if not isinstance(items, list) or not all(isinstance(t, dict) for t in items):
        raise FramescopeError(f"{stim.name}: {key} must be an array of tables ([[{key}]])")
    return items


def _trigger(m: Manifest, ev: dict, where: str, payload: set[str]) -> tuple[str, str]:
    """("t", ps) | ("f", frame) | ("p", "frame:line:pixel") for one table."""
    triggers = [k for k in ("frame", *_TIME_UNITS_PS) if k in ev]
    if len(triggers) != 1:
        raise FramescopeError(f"{where}: give exactly one of frame/ns/us/ms")
    unknown = set(ev) - {triggers[0], "line", "pixel"} - payload
    if unknown:
        raise FramescopeError(f"{where}: unknown key(s) {sorted(unknown)}")
    at = ev[triggers[0]]
    if triggers[0] != "frame":
        if "line" in ev or "pixel" in ev:
            raise FramescopeError(f"{where}: line/pixel offsets need a frame trigger")
        if isinstance(at, bool) or not isinstance(at, (int, float)) or at < 0:
            raise FramescopeError(f"{where}: {triggers[0]} must be a non-negative number")
        return "t", str(round(float(at) * _TIME_UNITS_PS[triggers[0]]))
    if protocols.primary(m) is None:
        raise FramescopeError(f"{where}: frame triggers need a monitor that produces frames (e.g. vga)")
    frame = _nonneg_int(at, f"{where}: frame")
    if "line" not in ev:
        if "pixel" in ev:
            raise FramescopeError(f"{where}: pixel needs line")
        return "f", str(frame)
    lines_max, pixels_max, source = raster_limits(m)
    line = _nonneg_int(ev["line"], f"{where}: line")
    pixel = _nonneg_int(ev.get("pixel", 0), f"{where}: pixel")
    if line >= lines_max:
        raise FramescopeError(f"{where}: line {line} is out of range 0..{lines_max - 1} ({source})")
    if pixel >= pixels_max:
        raise FramescopeError(f"{where}: pixel {pixel} is out of range 0..{pixels_max - 1} ({source})")
    return "p", f"{frame}:{line}:{pixel}"


def _nonneg_int(v: object, where: str) -> int:
    if isinstance(v, bool) or not isinstance(v, int) or v < 0:
        raise FramescopeError(f"{where} must be a non-negative integer, got {v!r}")
    return v


def _value(v: object, where: str) -> int:
    if isinstance(v, bool):
        return int(v)
    if isinstance(v, int):
        return v
    if isinstance(v, str):
        try:
            return int(v, 0)
        except ValueError:
            pass
    raise FramescopeError(f"{where}: value {v!r} is not an integer")
