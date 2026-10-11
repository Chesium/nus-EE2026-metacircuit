from __future__ import annotations

import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
EXAMPLES = REPO / "examples"
sys.path.insert(0, str(REPO / "src"))

from framescope.ports import Port  # noqa: E402

# Ports of examples/pmod_pattern as Verilator reports them.
PATTERN_PORTS = [
    Port("clk", "input", 0, 0, False),
    Port("rst_n", "input", 0, 0, False),
    Port("btn", "input", 0, 0, False),
    Port("ja", "output", 7, 0, True),
    Port("jb", "output", 7, 0, True),
]


def write(path: Path, text: str) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    return path
