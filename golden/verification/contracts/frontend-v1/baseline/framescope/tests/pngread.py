"""Compatibility shim: the PNG reader now lives in framescope.png."""

from __future__ import annotations

import helpers  # noqa: F401  (puts src/ on sys.path)

from framescope.png import Image, read  # noqa: F401
