"""Compares frames against reference PNGs, with named region masks.

A mask file (TOML, or JSON with the same structure) holds an optional global
tolerance and named regions made of rectangles:

    tolerance = 0                    # max |actual - reference| per channel; or [r, g, b]

    [[region]]
    name = "canvas"
    mode = "include"                 # include | exclude | report
    rect = [96, 32, 544, 448]        # x, y, w, h  (or { x = .., y = .., w = .., h = .. })

    [[region]]
    name = "cursor"
    mode = "exclude"
    rects = [[300, 200, 16, 16], [0, 0, 8, 8]]

Compared area = union of `include` regions (the whole frame when there are
none) minus every `exclude` region. `report` regions only add a per-region
breakdown. A frame passes (`ok`) when no compared pixel differs by more than the
tolerance; differences outside the compared area are counted as ignored.
"""

from __future__ import annotations

import json
import re
import tomllib
from bisect import bisect_left
from dataclasses import dataclass, field
from pathlib import Path

from . import FramescopeError, png
from .png import Image

MODES = ("include", "exclude", "report")
MASK_FILE = "masks.toml"  # picked up from a reference directory when no mask file is given
DIFF_SUFFIX = ".diff.png"

# Diff image colours.
_DIFF = b"\xff\x00\xff"      # compared pixel that differs: magenta
_IGNORED = b"\x00\x8c\x8c"   # differing pixel outside the compared area: teal
_BOX = b"\xff\xff\x00"       # outline around the largest difference components: yellow
_DIM = bytes(v * 3 // 10 for v in range(256))       # compared area: actual at 30%
_DIM_MASKED = bytes(v // 10 for v in range(256))    # area not compared: actual at 10%

Span = tuple[int, int]  # half-open [x0, x1)


@dataclass(frozen=True)
class Rect:
    x: int
    y: int
    w: int
    h: int


@dataclass
class Region:
    name: str
    mode: str
    rects: list[Rect]


@dataclass
class Masks:
    regions: list[Region] = field(default_factory=list)
    tolerance: tuple[int, int, int] = (0, 0, 0)
    path: Path | None = None


def parse_tolerance(value: object, where: str = "tolerance") -> tuple[int, int, int]:
    if isinstance(value, str):
        parts = [p.strip() for p in value.split(",")]
        try:
            value = [int(p) for p in parts] if len(parts) > 1 else int(parts[0])
        except ValueError:
            raise FramescopeError(f"{where}: expected N or R,G,B, got {value!r}") from None
    if isinstance(value, int) and not isinstance(value, bool):
        value = [value] * 3
    if (not isinstance(value, list) or len(value) != 3
            or not all(isinstance(v, int) and not isinstance(v, bool) and 0 <= v <= 255 for v in value)):
        raise FramescopeError(f"{where}: expected an integer 0..255 or a list [r, g, b] of them")
    return (value[0], value[1], value[2])


def load_masks(path: str | Path) -> Masks:
    p = Path(path)
    try:
        text = p.read_text(encoding="utf-8")
    except FileNotFoundError:
        raise FramescopeError(f"mask file not found: {p}") from None
    try:
        data = json.loads(text) if p.suffix.lower() == ".json" else tomllib.loads(text)
    except (json.JSONDecodeError, tomllib.TOMLDecodeError) as e:
        raise FramescopeError(f"{p}: {e}") from None
    masks = parse_masks(data, p.name)
    masks.path = p.resolve()
    return masks


def parse_masks(data: object, where: str = "masks") -> Masks:
    if not isinstance(data, dict):
        raise FramescopeError(f"{where}: expected a table at the top level")
    unknown = sorted(set(data) - {"tolerance", "region", "regions"})
    if unknown:
        raise FramescopeError(f"{where}: unknown key(s) {unknown}; allowed: region, tolerance")
    tol = parse_tolerance(data.get("tolerance", 0), f"{where}: tolerance")
    items = data.get("region", data.get("regions", []))
    if not isinstance(items, list):
        raise FramescopeError(f"{where}: region must be an array of tables ([[region]])")
    regions: list[Region] = []
    for i, item in enumerate(items):
        at = f"{where} region #{i + 1}"
        if not isinstance(item, dict):
            raise FramescopeError(f"{at}: expected a table")
        bad = sorted(set(item) - {"name", "mode", "rect", "rects"})
        if bad:
            raise FramescopeError(f"{at}: unknown key(s) {bad}; allowed: name, mode, rect, rects")
        name = item.get("name")
        if not isinstance(name, str) or not name:
            raise FramescopeError(f"{at}: name is required")
        at = f"{where} region '{name}'"
        if any(r.name == name for r in regions):
            raise FramescopeError(f"{at}: duplicate region name")
        mode = item.get("mode")
        if mode not in MODES:
            raise FramescopeError(f"{at}: mode must be one of {list(MODES)}, got {mode!r}")
        if ("rect" in item) == ("rects" in item):
            raise FramescopeError(f"{at}: give exactly one of rect / rects")
        raw = [item["rect"]] if "rect" in item else item["rects"]
        if not isinstance(raw, list) or not raw:
            raise FramescopeError(f"{at}: rects must be a non-empty list")
        regions.append(Region(name, mode, [_rect(r, at) for r in raw]))
    return Masks(regions, tol)


def _rect(r: object, where: str) -> Rect:
    if isinstance(r, dict):
        if set(r) != {"x", "y", "w", "h"}:
            raise FramescopeError(f"{where}: a rect table needs exactly x, y, w, h")
        r = [r["x"], r["y"], r["w"], r["h"]]
    if not isinstance(r, list) or len(r) != 4 or not all(isinstance(v, int) and not isinstance(v, bool) for v in r):
        raise FramescopeError(f"{where}: a rect is [x, y, w, h] (integers), got {r!r}")
    x, y, w, h = r
    if x < 0 or y < 0 or w <= 0 or h <= 0:
        raise FramescopeError(f"{where}: rect {r} needs x, y >= 0 and w, h > 0")
    return Rect(x, y, w, h)


# --- span arithmetic --------------------------------------------------------


def _row_spans(rects: list[Rect], y: int, width: int) -> list[Span]:
    spans = sorted((max(0, r.x), min(width, r.x + r.w)) for r in rects if r.y <= y < r.y + r.h and r.x < width)
    merged: list[Span] = []
    for a, b in spans:
        if b <= a:
            continue
        if merged and a <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(merged[-1][1], b))
        else:
            merged.append((a, b))
    return merged


def _subtract(spans: list[Span], cut: list[Span]) -> list[Span]:
    out: list[Span] = []
    for a, b in spans:
        for c, d in cut:
            if d <= a or c >= b:
                continue
            if c > a:
                out.append((a, c))
            a = max(a, d)
            if a >= b:
                break
        if a < b:
            out.append((a, b))
    return out


def _count_in(xs: list[int], spans: list[Span]) -> tuple[int, int, int]:
    """(count, min x, max x) of the sorted xs that fall inside spans."""
    n, lo_x, hi_x = 0, -1, -1
    for a, b in spans:
        lo, hi = bisect_left(xs, a), bisect_left(xs, b)
        if hi > lo:
            n += hi - lo
            lo_x = xs[lo] if lo_x < 0 else min(lo_x, xs[lo])
            hi_x = max(hi_x, xs[hi - 1])
    return n, lo_x, hi_x


class _Box:
    __slots__ = ("x0", "y0", "x1", "y1", "n")

    def __init__(self) -> None:
        self.x0 = self.y0 = 1 << 30
        self.x1 = self.y1 = -1
        self.n = 0

    def add(self, x0: int, x1: int, y: int, n: int) -> None:
        """x0..x1 inclusive on row y, n pixels."""
        self.x0, self.x1 = min(self.x0, x0), max(self.x1, x1)
        self.y0, self.y1 = min(self.y0, y), max(self.y1, y)
        self.n += n

    def to_json(self) -> dict | None:
        if self.n == 0:
            return None
        return {"x": self.x0, "y": self.y0, "w": self.x1 - self.x0 + 1, "h": self.y1 - self.y0 + 1}


# --- comparison -------------------------------------------------------------

_CHUNK = 16  # pixels compared per bytes slice before falling back to single pixels


def _diff_xs(a: bytes, b: bytes, width: int, tol: tuple[int, int, int]) -> list[int]:
    """Sorted x of pixels differing by more than tol in any channel (rows already known unequal)."""
    xs: list[int] = []
    exact = tol == (0, 0, 0)
    tr, tg, tb = tol
    step = 3 * _CHUNK
    for c0 in range(0, 3 * width, step):
        c1 = min(c0 + step, 3 * width)
        if a[c0:c1] == b[c0:c1]:
            continue
        for i in range(c0, c1, 3):
            if a[i : i + 3] == b[i : i + 3]:
                continue
            if exact or abs(a[i] - b[i]) > tr or abs(a[i + 1] - b[i + 1]) > tg or abs(a[i + 2] - b[i + 2]) > tb:
                xs.append(i // 3)
    return xs


def _runs(xs: list[int]) -> list[Span]:
    """Inclusive runs of consecutive x."""
    runs: list[Span] = []
    for x in xs:
        if runs and x == runs[-1][1] + 1:
            runs[-1] = (runs[-1][0], x)
        else:
            runs.append((x, x))
    return runs


def _components(rows: dict[int, list[int]]) -> list[dict]:
    """8-connected components of the diff pixels, from horizontal runs and union-find."""
    parent: list[int] = []
    runs: list[tuple[int, int, int]] = []  # (y, x0, x1)

    def find(i: int) -> int:
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    prev_y, prev_ids = -2, []
    for y in sorted(rows):
        ids = []
        for x0, x1 in _runs(rows[y]):
            rid = len(runs)
            runs.append((y, x0, x1))
            parent.append(rid)
            ids.append(rid)
        if prev_y == y - 1:
            j = 0
            for rid in ids:
                _, a, b = runs[rid]
                while j < len(prev_ids) and runs[prev_ids[j]][2] < a - 1:
                    j += 1
                k = j
                while k < len(prev_ids) and runs[prev_ids[k]][1] <= b + 1:
                    ra, rb = find(rid), find(prev_ids[k])
                    if ra != rb:
                        parent[max(ra, rb)] = min(ra, rb)
                    k += 1
        prev_y, prev_ids = y, ids

    boxes: dict[int, _Box] = {}
    first: dict[int, tuple[int, int]] = {}
    for rid, (y, x0, x1) in enumerate(runs):
        root = find(rid)
        box = boxes.get(root)
        if box is None:
            box = boxes[root] = _Box()
            first[root] = (x0, y)
        box.add(x0, x1, y, x1 - x0 + 1)
    out = [{"bbox": b.to_json(), "pixels": b.n, "_first": first[r]} for r, b in boxes.items()]
    out.sort(key=lambda c: (-c["pixels"], c["bbox"]["y"], c["bbox"]["x"]))
    return out


def _hex(img: Image, x: int, y: int) -> str:
    return "#%02x%02x%02x" % img.pixel(x, y)


def compare_images(actual: Image, reference: Image, masks: Masks | None = None, *,
                   tolerance: tuple[int, int, int] | None = None, max_boxes: int = 8,
                   diff_png: Path | None = None) -> dict:
    """Compares two images; writes a diff PNG to `diff_png` when they are not identical."""
    masks = masks or Masks()
    tol = tolerance if tolerance is not None else masks.tolerance
    if (actual.width, actual.height) != (reference.width, reference.height):
        return {
            "ok": False, "identical": False,
            "error": f"size mismatch: actual {actual.width}x{actual.height}, "
                     f"reference {reference.width}x{reference.height}",
        }
    w, h = actual.width, actual.height
    includes = [r for reg in masks.regions if reg.mode == "include" for r in reg.rects]
    excludes = [r for reg in masks.regions if reg.mode == "exclude" for r in reg.rects]
    full = [(0, w)]

    def compared_spans(y: int) -> list[Span]:
        base = _row_spans(includes, y, w) if includes else full
        return _subtract(base, _row_spans(excludes, y, w)) if excludes else base

    region_boxes = {reg.name: _Box() for reg in masks.regions}
    region_area = {reg.name: 0 for reg in masks.regions}
    for reg in masks.regions:
        for y in range(h):
            region_area[reg.name] += sum(b - a for a, b in _row_spans(reg.rects, y, w))

    compared_px = 0
    identical = True
    diff_rows: dict[int, list[int]] = {}     # compared differing pixels
    ignored_rows: dict[int, list[int]] = {}  # differing pixels outside the compared area
    spans_by_row: list[list[Span]] = []
    for y in range(h):
        spans = compared_spans(y)
        spans_by_row.append(spans)
        compared_px += sum(b - a for a, b in spans)
        ra, rb = actual.rows[y], reference.rows[y]
        if ra == rb:
            continue
        identical = False
        xs = _diff_xs(ra, rb, w, tol)
        if not xs:
            continue
        inside = [x for x in xs if _in_spans(x, spans)] if spans != full else xs
        if len(inside) != len(xs):
            ins = set(inside)
            ignored_rows[y] = [x for x in xs if x not in ins]
        if inside:
            diff_rows[y] = inside
        for reg in masks.regions:
            rows = ignored_rows if reg.mode == "exclude" else diff_rows
            if y in rows:
                n, x0, x1 = _count_in(rows[y], _row_spans(reg.rects, y, w))
                if n:
                    region_boxes[reg.name].add(x0, x1, y, n)

    diff_px = sum(len(v) for v in diff_rows.values())
    ignored_px = sum(len(v) for v in ignored_rows.values())
    overall = _Box()
    for y, xs in diff_rows.items():
        overall.add(xs[0], xs[-1], y, len(xs))
    comps = _components(diff_rows) if diff_rows else []
    shown = comps[:max_boxes]
    for c in shown:
        x, y = c.pop("_first")
        c["sample"] = {"x": x, "y": y, "actual": _hex(actual, x, y), "reference": _hex(reference, x, y)}

    result: dict = {
        "ok": diff_px == 0,
        "identical": identical,
        "width": w,
        "height": h,
        "compared_pixels": compared_px,
        "diff_pixels": diff_px,
        "ignored_diff_pixels": ignored_px,
        "bbox": overall.to_json(),
        "components": shown,
        "components_total": len(comps),
    }
    if masks.regions:
        result["regions"] = {
            reg.name: {"mode": reg.mode, "pixels": region_area[reg.name],
                       "diff_pixels": region_boxes[reg.name].n, "bbox": region_boxes[reg.name].to_json()}
            for reg in masks.regions
        }
    if diff_png is not None and not identical:
        png.write(diff_png, _diff_image(actual, spans_by_row, diff_rows, ignored_rows, shown), level=3)
        result["diff_png"] = str(diff_png)
    return result


def _in_spans(x: int, spans: list[Span]) -> bool:
    for a, b in spans:
        if x < a:
            return False
        if x < b:
            return True
    return False


def _diff_image(actual: Image, spans_by_row: list[list[Span]], diff_rows: dict[int, list[int]],
                ignored_rows: dict[int, list[int]], comps: list[dict]) -> Image:
    w, h = actual.width, actual.height
    rows: list[bytearray] = []
    for y in range(h):
        src = actual.rows[y]
        spans = spans_by_row[y]
        if spans == [(0, w)]:
            row = bytearray(src.translate(_DIM))
        else:
            row = bytearray(src.translate(_DIM_MASKED))
            for a, b in spans:
                row[3 * a : 3 * b] = src[3 * a : 3 * b].translate(_DIM)
        for x in ignored_rows.get(y, ()):
            row[3 * x : 3 * x + 3] = _IGNORED
        for x in diff_rows.get(y, ()):
            row[3 * x : 3 * x + 3] = _DIFF
        rows.append(row)
    for c in comps:  # outline one pixel outside each box
        b = c["bbox"]
        x0, y0, x1, y1 = b["x"] - 1, b["y"] - 1, b["x"] + b["w"], b["y"] + b["h"]
        for y in (y0, y1):
            if 0 <= y < h:
                for x in range(max(0, x0), min(w, x1 + 1)):
                    rows[y][3 * x : 3 * x + 3] = _BOX
        for x in (x0, x1):
            if 0 <= x < w:
                for y in range(max(0, y0), min(h, y1 + 1)):
                    rows[y][3 * x : 3 * x + 3] = _BOX
    return Image(w, h, [bytes(r) for r in rows])


# --- files and directories --------------------------------------------------

_FRAME = re.compile(r"(\d+)\.png$")


def _pngs(root: Path) -> list[Path]:
    return sorted(p for p in root.rglob("*.png") if p.is_file() and not p.name.endswith(DIFF_SUFFIX))


def match_frames(actual: Path, reference: Path) -> tuple[list[tuple[str, Path | None, Path]], list[str]]:
    """Pairs every reference PNG with an actual PNG: same path relative to the
    directories, else the same file name if it is unique under `actual`.
    Returns ([(name, actual or None, reference)], unmatched actual names)."""
    by_name: dict[str, list[Path]] = {}
    actual_pngs = _pngs(actual)
    for p in actual_pngs:
        by_name.setdefault(p.name, []).append(p)
    pairs, used = [], set()
    for ref in _pngs(reference):
        rel = ref.relative_to(reference)
        cand = actual / rel
        if not cand.is_file():
            same = by_name.get(ref.name, [])
            cand = same[0] if len(same) == 1 else None
        if cand is not None:
            used.add(cand)
        pairs.append((rel.as_posix(), cand, ref))
    unmatched = [p.relative_to(actual).as_posix() for p in actual_pngs if p not in used]
    return pairs, unmatched


def compare_paths(actual: str | Path, reference: str | Path, *, masks: str | Path | None = None,
                  tolerance: tuple[int, int, int] | None = None, out: str | Path | None = None,
                  diff: bool = True, max_boxes: int = 8) -> dict:
    """Compares two PNG files, or every reference PNG under a directory with
    its counterpart under another (e.g. a run directory). Writes diff PNGs and
    compare.json under `out` (default: <actual dir>/compare)."""
    actual, reference = Path(actual).resolve(), Path(reference).resolve()
    for p, what in ((actual, "actual"), (reference, "reference")):
        if not p.exists():
            raise FramescopeError(f"{what} not found: {p}")
    if actual.is_dir() != reference.is_dir():
        raise FramescopeError("give two PNG files or two directories")
    if masks is None and reference.is_dir() and (reference / MASK_FILE).is_file():
        masks = reference / MASK_FILE
    m = load_masks(masks) if masks is not None else Masks()
    tol = tolerance if tolerance is not None else m.tolerance

    if actual.is_dir():
        pairs, unmatched = match_frames(actual, reference)
        if not pairs:
            raise FramescopeError(f"no reference PNGs under {reference}")
        out_dir = Path(out).resolve() if out else actual / "compare"
    else:
        pairs, unmatched = [(actual.name, actual, reference)], []
        out_dir = Path(out).resolve() if out else actual.parent / "compare"

    frames = []
    for name, act, ref in pairs:
        entry: dict = {"name": name, "actual": str(act) if act else None, "reference": str(ref)}
        mt = _FRAME.search(name)
        if mt:
            entry["index"] = int(mt.group(1))
        if act is None:
            entry.update(ok=False, identical=False, error="no matching actual frame")
        else:
            target = out_dir / (name[: -len(".png")] + DIFF_SUFFIX) if diff else None
            try:
                entry.update(compare_images(png.read(act), png.read(ref), m, tolerance=tol,
                                            max_boxes=max_boxes, diff_png=target))
            except png.PngError as e:
                entry.update(ok=False, identical=False, error=str(e))
        frames.append(entry)

    failed = [f["name"] for f in frames if not f["ok"]]
    result = {
        "ok": not failed,
        "actual": str(actual),
        "reference": str(reference),
        "masks": str(m.path) if m.path else None,
        "tolerance": list(tol),
        "out_dir": str(out_dir),
        "summary": {
            "frames": len(frames),
            "passed": len(frames) - len(failed),
            "failed": len(failed),
            "identical": sum(1 for f in frames if f.get("identical")),
            "missing": sum(1 for f in frames if f["actual"] is None),
            "diff_pixels": sum(f.get("diff_pixels", 0) for f in frames),
            "failed_frames": failed,
        },
        "frames": frames,
        "unmatched_actual": len(unmatched),  # actual PNGs without a reference (not a failure)
    }
    if diff or out:
        out_dir.mkdir(parents=True, exist_ok=True)
        (out_dir / "compare.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    return result
