"""Optional scenario settings at the top of a stimulus TOML.

Top-level keys (they must come before the first [[event]] table):

    frames = 6                    # frames to capture for this scenario
    reference = "refs/click"      # reference PNG directory (relative to this file)
    masks = "masks/ui.toml"       # mask file for the comparison (relative to this file)

    [[event]]
    ...

`framescope run` uses `frames` when -n is not given; `framescope batch` uses all three.
"""

from __future__ import annotations

import tomllib
from dataclasses import dataclass
from pathlib import Path

from . import FramescopeError


@dataclass(frozen=True)
class ScenarioMeta:
    frames: int | None = None
    reference: Path | None = None
    masks: Path | None = None


def read_meta(stim: Path | None) -> ScenarioMeta:
    if stim is None:
        return ScenarioMeta()
    try:
        data = tomllib.loads(Path(stim).read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise FramescopeError(f"stimulus file not found: {stim}") from None
    except tomllib.TOMLDecodeError as e:
        raise FramescopeError(f"{stim}: {e}") from None
    base = Path(stim).resolve().parent
    frames = data.get("frames")
    if frames is not None and (not isinstance(frames, int) or isinstance(frames, bool) or frames < 1):
        raise FramescopeError(f"{Path(stim).name}: frames must be a positive integer")

    def path(key: str) -> Path | None:
        v = data.get(key)
        if v is None:
            return None
        if not isinstance(v, str):
            raise FramescopeError(f"{Path(stim).name}: {key} must be a path string")
        p = Path(v)
        return (p if p.is_absolute() else base / p).resolve()

    return ScenarioMeta(frames, path("reference"), path("masks"))
