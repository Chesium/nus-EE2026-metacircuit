"""Collision-free, timestamp-named output directories."""

from __future__ import annotations

from datetime import datetime
from pathlib import Path


def new_dir(parent: Path, stem: str | None = None) -> Path:
    """Creates and returns parent/<stem>, or parent/<stem>-1, -2, ... if taken.

    mkdir without exist_ok is atomic, so concurrent processes (parallel runs
    started in the same second) never share a directory. `stem` defaults to the
    current local time, YYYYMMDD-HHMMSS.
    """
    stem = stem or datetime.now().strftime("%Y%m%d-%H%M%S")
    parent.mkdir(parents=True, exist_ok=True)
    for i in range(10_000):
        d = parent / (stem if i == 0 else f"{stem}-{i}")
        try:
            d.mkdir()
            return d.resolve()
        except FileExistsError:
            continue
    raise RuntimeError(f"could not create a fresh directory under {parent}")
