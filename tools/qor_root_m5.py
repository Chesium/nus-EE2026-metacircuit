#!/usr/bin/env python3
"""Create a QoR measurement root: the checkout's Vivado inputs plus the frozen M5 comparison XDC.

The production constraint file stays unchanged. M5 timing comparisons use
tools/qor/basys3_m5_timing.xdc, which adds only the derived pixel clock, so
baseline and candidate are timed under identical, stricter constraints.
"""
from __future__ import annotations
import argparse
import hashlib
from pathlib import Path
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from vivado_qor import CONSTRAINTS, PROJECT_IPS, PROJECT_SOURCES  # noqa: E402

COMPARISON_XDC = 'tools/qor/basys3_m5_timing.xdc'
COMPARISON_XDC_SHA = 'd96ce92d4add6f8944f6761f2c4f3bc1b199a090151022b27769d52750cf7593'
TARGET = 'src/constraint/basys3.xdc'


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def create(out, root=ROOT):
    out = Path(out)
    if out.exists() and any(out.iterdir()):
        raise ValueError('measurement root must be empty')
    if TARGET not in CONSTRAINTS:
        raise ValueError('runner constraint manifest no longer contains ' + TARGET)
    if sha(root / COMPARISON_XDC) != COMPARISON_XDC_SHA:
        raise ValueError('frozen comparison XDC changed: ' + COMPARISON_XDC)
    for path in PROJECT_SOURCES + PROJECT_IPS + CONSTRAINTS + ['tools/vivado_qor.py', 'tools/vivado_qor.tcl', 'metacircuit.tcl']:
        target = out / path
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(root / path, target)
    shutil.copyfile(root / COMPARISON_XDC, out / TARGET)
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    print(create(args.out.resolve()))


if __name__ == '__main__':
    main()
