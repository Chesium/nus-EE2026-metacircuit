"""Video timing presets and comparison against measured timing."""

from __future__ import annotations

from dataclasses import dataclass

from . import FramescopeError


@dataclass(frozen=True)
class VideoTiming:
    h_active: int
    h_fp: int
    h_sync: int
    h_bp: int
    v_active: int
    v_fp: int
    v_sync: int
    v_bp: int
    hsync_positive: bool = False
    vsync_positive: bool = False
    pclk_hz: float = 0.0

    @property
    def h_total(self) -> int:
        return self.h_active + self.h_fp + self.h_sync + self.h_bp

    @property
    def v_total(self) -> int:
        return self.v_active + self.v_fp + self.v_sync + self.v_bp


# VESA DMT / CEA-861 modes.
PRESETS: dict[str, VideoTiming] = {
    "640x480@60": VideoTiming(640, 16, 96, 48, 480, 10, 2, 33, False, False, 25.175e6),
    "800x600@60": VideoTiming(800, 40, 128, 88, 600, 1, 4, 23, True, True, 40.0e6),
    "1024x768@60": VideoTiming(1024, 24, 136, 160, 768, 3, 6, 29, False, False, 65.0e6),
    "1280x720@60": VideoTiming(1280, 110, 40, 220, 720, 5, 5, 20, True, True, 74.25e6),
    "1920x1080@60": VideoTiming(1920, 88, 44, 148, 1080, 4, 5, 36, True, True, 148.5e6),
}

_FIELDS = ("h_active", "h_fp", "h_sync", "h_bp", "v_active", "v_fp", "v_sync", "v_bp")


def resolve(spec: object) -> VideoTiming | None:
    """A preset name, an inline table of the fields above, or None."""
    if spec is None:
        return None
    if isinstance(spec, str):
        if spec not in PRESETS:
            raise FramescopeError(f"unknown timing preset '{spec}'; known: {sorted(PRESETS)}")
        return PRESETS[spec]
    if isinstance(spec, dict):
        missing = [f for f in _FIELDS if f not in spec]
        if missing:
            raise FramescopeError(f"inline timing is missing {missing}")
        allowed = set(_FIELDS) | {"hsync_positive", "vsync_positive", "pclk_hz"}
        unknown = sorted(set(spec) - allowed)
        if unknown:
            raise FramescopeError(f"inline timing has unknown key(s) {unknown}")
        return VideoTiming(**spec)
    raise FramescopeError(f"timing must be a preset name or a table, got {spec!r}")


def compare(t: VideoTiming, measured: dict, pclk_tolerance: float = 0.005) -> list[dict]:
    """Differences between a preset and one frame's measured timing."""
    out: list[dict] = []
    checks = [("h_total", t.h_total), ("h_sync", t.h_sync), ("v_total", t.v_total), ("v_sync", t.v_sync)]
    if "h_active" in measured:
        checks += [(f, getattr(t, f)) for f in _FIELDS if f not in ("h_sync", "v_sync")]
    for field, expected in checks:
        if measured.get(field) != expected:
            out.append({"field": field, "expected": expected, "measured": measured.get(field), "severity": "mismatch"})

    for field, positive in (("hsync_polarity", t.hsync_positive), ("vsync_polarity", t.vsync_positive)):
        expected = "positive" if positive else "negative"
        if measured.get(field) != expected:
            out.append({"field": field, "expected": expected, "measured": measured.get(field), "severity": "mismatch"})

    if measured.get("distinct_line_lengths", 1) > 1:
        out.append({
            "field": "line_length",
            "expected": t.h_total,
            "measured": [measured.get("line_len_min"), measured.get("line_len_max")],
            "severity": "mismatch",
            "note": "line length varies within the frame",
        })

    rate = measured.get("pixel_rate_hz") or 0.0
    if t.pclk_hz and rate:
        dev = (rate - t.pclk_hz) / t.pclk_hz
        if abs(dev) > pclk_tolerance:
            out.append({
                "field": "pixel_rate_hz",
                "expected": t.pclk_hz,
                "measured": round(rate, 1),
                "deviation_pct": round(dev * 100, 3),
                "severity": "warning",
            })
    return out
