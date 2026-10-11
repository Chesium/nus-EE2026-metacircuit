"""VGA (and any parallel RGB + HSYNC/VSYNC output, e.g. DVI before TMDS encoding)."""

from __future__ import annotations

from collections.abc import Callable

from .. import FramescopeError, timing
from ..manifest import MonitorSpec
from .base import Protocol, Tap, cpp_str

_POLARITY = {"auto": -1, "negative": 0, "positive": 1}
# Order must match fs::VgaPins.
_PINS = (("pclk", 1), ("pclk_en", 1), ("hsync", 1), ("vsync", 1), ("red", 8), ("green", 8), ("blue", 8), ("de", 1))


class VgaProtocol(Protocol):
    name = "vga"
    required = ("pclk", "hsync", "vsync", "red", "green", "blue")
    optional = ("pclk_en", "de")
    option_keys = frozenset({"timing", "de_delay", "hsync_polarity", "vsync_polarity"})
    cpp_header = "vga_monitor.hpp"

    def validate(self, mon: MonitorSpec) -> None:
        super().validate(mon)
        timing.resolve(mon.options.get("timing"))
        delay = mon.options.get("de_delay", 0)
        if not isinstance(delay, int) or isinstance(delay, bool) or not 0 <= delay <= 63:
            raise FramescopeError(f"monitor '{mon.name}': de_delay must be an integer in 0..63")
        if delay and "de" not in mon.signals:
            raise FramescopeError(f"monitor '{mon.name}': de_delay needs signals.de")
        for key in ("hsync_polarity", "vsync_polarity"):
            if mon.options.get(key, "auto") not in _POLARITY:
                raise FramescopeError(f"monitor '{mon.name}': {key} must be one of {sorted(_POLARITY)}")

    def taps(self, mon: MonitorSpec) -> list[Tap]:
        s = mon.signals
        taps = [
            Tap("pclk", 1, s["pclk"]),
            Tap("pclk_en", 1, s.get("pclk_en", "1'b1")),
            Tap("hsync", 1, s["hsync"]),
            Tap("vsync", 1, s["vsync"]),
            Tap("de", 1, s.get("de", "1'b0")),
        ]
        for c in ("red", "green", "blue"):
            taps.append(Tap(c, 8, f"fs_expand8(64'({s[c]}), $bits({s[c]}))"))
        return taps

    def cpp_bind(self, mon: MonitorSpec, member: Callable[[str], str]) -> str:
        t = timing.resolve(mon.options.get("timing"))
        lines = [
            "  {",
            "    fs::VgaConfig c;",
            f"    c.name = {cpp_str(mon.name)};",
            f"    c.has_de = {'true' if 'de' in mon.signals else 'false'};",
            f"    c.de_delay = {int(mon.options.get('de_delay', 0))};",
            f"    c.hsync_active = {_POLARITY[mon.options.get('hsync_polarity', 'auto')]};",
            f"    c.vsync_active = {_POLARITY[mon.options.get('vsync_polarity', 'auto')]};",
        ]
        if t:
            fields = (t.h_active, t.h_fp, t.h_sync, t.h_bp, t.v_active, t.v_fp, t.v_sync, t.v_bp)
            lines.append(f"    c.timing = fs::VideoTiming{{{', '.join(map(str, fields))}, true}};")
        pins = ", ".join(f"fs::port({member(sig)}, {w})" for sig, w in _PINS)
        lines += [
            f"    fs::VgaPins p{{{pins}}};",
            "    h.add_monitor(std::make_unique<fs::VgaMonitor>(c, p));",
            "  }",
        ]
        return "\n".join(lines)

    def analyze(self, mon: MonitorSpec, frames: list[dict], summary: dict, sim: dict, events=()) -> dict:
        preset_spec = mon.options.get("timing")
        t = timing.resolve(preset_spec)
        measured = frames[-1]["measured"] if frames else None
        violations = timing.compare(t, measured) if (t and measured) else []
        stable = True
        if len(frames) > 1:
            def shape(m: dict) -> dict:
                return {k: v for k, v in m.items() if not k.endswith("_hz")}
            stable = all(shape(f["measured"]) == shape(frames[0]["measured"]) for f in frames)

        return {
            "protocol": self.name,
            "frames": [
                {
                    "index": f["index"],
                    "t_ms": round(f["t_ps"] / 1e9, 3),
                    "png": f.get("png"),
                    "raster_png": f.get("raster_png"),
                    "width": f["width"],
                    "height": f["height"],
                    "active_source": f["active_source"],
                    "crc32": f["crc32"],
                    "nonblack_pixels": f["nonblack_pixels"],
                }
                for f in frames
            ],
            "timing": {
                "preset": preset_spec if isinstance(preset_spec, str) else ("inline" if t else None),
                "measured": measured,
                "stable_across_frames": stable,
                "violations": violations,
            },
            "stats": summary,
            "diagnosis": self._diagnose(mon, frames, summary, sim),
        }

    def _diagnose(self, mon: MonitorSpec, frames: list[dict], s: dict, sim: dict) -> list[str]:
        sig = mon.signals
        notes = []
        if not s:
            return ["monitor reported no summary (simulation aborted?)"]
        if s.get("pclk_edges", 0) == 0:
            notes.append(
                f"pixel clock '{sig['pclk']}' never rose. For clock-enable designs set pclk to the system "
                "clock and pclk_en to the pixel strobe."
            )
        elif s.get("pixels", 0) == 0:
            notes.append(f"pclk_en '{sig.get('pclk_en')}' was never high on a pclk edge.")
        if s.get("pixels", 0) and s.get("hsync_toggles", 0) < 3:
            notes.append(f"HSYNC '{sig['hsync']}' toggled {s.get('hsync_toggles', 0)} times: check the mapping and reset.")
        if s.get("pixels", 0) and s.get("vsync_toggles", 0) < 3:
            notes.append(
                f"VSYNC '{sig['vsync']}' toggled {s.get('vsync_toggles', 0)} times. The monitor needs one full "
                "VSYNC period to learn polarity before frame 0 starts; raise --max-time-ms if the design is slow to start."
            )
        if frames and all(f["nonblack_pixels"] == 0 for f in frames):
            notes.append("every captured frame is black: check reset, the RGB mapping, and de/de_delay if DE is tapped.")
        if s.get("has_de") and frames and s.get("de_samples", 0) == 0:
            notes.append(f"DE '{sig.get('de')}' never asserted inside a frame.")
        if frames and frames[-1]["active_source"] == "none":
            notes.append("no active-area crop: add signals.de or a timing preset; raster images include blanking.")
        if sim.get("stop_reason") == "max_time" and len(frames) < sim.get("frames_requested", 0):
            notes.append(f"stopped at the time limit after {len(frames)} of {sim['frames_requested']} frames.")
        return notes
