#!/usr/bin/env python3
"""Extract MetaCircuit's visual assets from the RTL into JSON (verification plan GM-4).

Run from the repository root:

    python3 golden/tools/extract_assets.py            # write golden/assets/*.json
    python3 golden/tools/extract_assets.py --out DIR  # write somewhere else
    python3 golden/tools/extract_assets.py --check    # exit 1 if golden/assets is stale

Python 3 standard library only. The output is deterministic: the same RTL gives
byte-identical JSON. Provenance is the last git commit that touched the source
files plus each file's SHA-256 (not `git rev-parse HEAD`, which would change the
output on every unrelated commit).

The extractor fails (exit 2, message on stderr) when the RTL no longer has the
structure it expects (a function, table, parameter or expression is missing or
changed shape). It never writes partial output: every file is built in memory
first and written only when all of them succeed.

Formats are documented in golden/assets/README.md.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
DEFAULT_OUT = REPO / "golden" / "assets"
SCHEMA_VERSION = 1
GENERATOR = "golden/tools/extract_assets.py"

CIRCUIT_CANVAS = "src/design/rendering/CircuitCanvas.v"
GLOBAL_RENDER = "src/design/rendering/GlobalRender_top.v"
TOOLBAR = "src/design/rendering/ToolbarVGA.v"
BUTTON = "src/design/rendering/ButtonVGA.v"
KEYBOARD = "src/design/rendering/KeyboardVGA.v"
MOUSE_VHD = "src/design/rendering/MouseDisplay.vhd"
FONT_ROM = "src/design/Dashboard/FontROM.v"
PROP_PANEL = "src/design/Dashboard/ComponentPropertyPanel.v"


class ExtractError(Exception):
    pass


def fail(msg: str):
    raise ExtractError(msg)


# --------------------------------------------------------------------------
# Source files
# --------------------------------------------------------------------------

_V_COMMENT = re.compile(r'"(?:\\.|[^"\\\n])*"|//[^\n]*|/\*.*?\*/', re.S)
_VHD_COMMENT = re.compile(r'"[^"\n]*"|--[^\n]*')


def _blank(m: re.Match) -> str:
    s = m.group(0)
    if s.startswith('"'):
        return s
    return re.sub(r"[^\n]", " ", s)


class Source:
    """One RTL file with comments blanked out (line numbers preserved)."""

    def __init__(self, rel: str):
        self.rel = rel
        path = REPO / rel
        if not path.is_file():
            fail(f"{rel}: file not found")
        data = path.read_bytes()
        self.sha256 = hashlib.sha256(data).hexdigest()
        self.raw = data.decode("utf-8", errors="replace")
        pat = _VHD_COMMENT if rel.endswith(".vhd") else _V_COMMENT
        self.text = pat.sub(_blank, self.raw)
        self.ranges: dict[str, list[int]] = {}

    def line(self, pos: int) -> int:
        return self.text.count("\n", 0, pos) + 1

    def record(self, name: str, start: int, end: int):
        rng = [self.line(start), self.line(max(start, end - 1))]
        if name in self.ranges:
            old = self.ranges[name]
            rng = [min(old[0], rng[0]), max(old[1], rng[1])]
        self.ranges[name] = rng

    def search(self, pattern: str, what: str, flags=re.S, start: int = 0, end: int | None = None):
        rx = re.compile(pattern, flags)
        m = rx.search(self.text, start, len(self.text) if end is None else end)
        if not m:
            fail(f"{self.rel}: cannot find {what} (pattern {pattern!r})")
        return m

    def block(self, name: str, start_pat: str, end_word: str, what: str, start: int = 0):
        """Text from a start pattern to the next end keyword (inclusive); records the range."""
        m = self.search(start_pat, what, start=start)
        e = re.compile(r"\b%s\b" % end_word).search(self.text, m.end())
        if not e:
            fail(f"{self.rel}: {what} has no closing {end_word}")
        self.record(name, m.start(), e.end())
        return self.text[m.start():e.end()], m.start()

    def function(self, name: str, label: str | None = None):
        return self.block(label or name,
                          r"\bfunction\s+(?:automatic\s+)?(?:\[[^\]]*\]\s*)?(?:integer\s+)?%s\s*;" % name,
                          "endfunction", f"function {name}")

    def require(self, pattern: str, what: str, within: str | None = None, label: str | None = None):
        """Asserts that a whitespace-insensitive code shape exists; records where."""
        rx = _ws_pattern(pattern)
        hay = self.text if within is None else within
        m = re.search(rx, hay, re.S)
        if not m:
            fail(f"{self.rel}: expected code shape not found ({what}): {pattern}")
        if within is None and label:
            self.record(label, m.start(), m.end())
        return m

    def info(self) -> dict:
        return {"path": self.rel, "sha256": self.sha256,
                "line_ranges": {k: self.ranges[k] for k in sorted(self.ranges)}}


def _ws_pattern(code: str) -> str:
    """Turns a code snippet into a regex that ignores whitespace differences."""
    out = []
    for tok in re.findall(r"\w+|\S", code):
        out.append(re.escape(tok))
    return r"\s*".join(out)


# --------------------------------------------------------------------------
# Verilog values
# --------------------------------------------------------------------------

_LIT = re.compile(r"(\d+)\s*'\s*([bBdDhH])\s*([0-9a-fA-F_]+)")
LITERAL_NOTES: list[dict] = []


def parse_literal(tok: str, src: Source | None = None, pos: int | None = None, ctx: str = "") -> tuple[int, int]:
    """Parses a sized Verilog literal; returns (width, value). Records width mismatches."""
    m = _LIT.fullmatch(tok.strip())
    if not m:
        fail(f"{src.rel if src else '?'}: not a sized literal: {tok!r} ({ctx})")
    width = int(m.group(1))
    base = {"b": 2, "d": 10, "h": 16}[m.group(2).lower()]
    digits = m.group(3).replace("_", "")
    value = int(digits, base)
    if value >= (1 << width):
        fail(f"{src.rel if src else '?'}: literal {tok} overflows its width ({ctx})")
    if base == 2 and len(digits) != width and src is not None:
        LITERAL_NOTES.append({
            "file": src.rel, "line": src.line(pos) if pos is not None else None, "context": ctx,
            "literal": tok.strip(),
            "note": f"{len(digits)} binary digits in a {width}-bit literal; Verilog zero-extends "
                    f"on the left, so the pattern is shifted right by {width - len(digits)} pixel(s) "
                    f"relative to how it is written. Extracted value follows Verilog semantics.",
        })
    return width, value


def bits(value: int, width: int) -> str:
    return format(value, f"0{width}b")


def eval_int(expr: str, env: dict, what: str) -> int:
    """Evaluates a Verilog integer constant expression (names, literals, + - * / % >> parens)."""
    e = expr.strip()
    e = _LIT.sub(lambda m: str(int(m.group(3).replace("_", ""),
                                   {"b": 2, "d": 10, "h": 16}[m.group(2).lower()])), e)
    toks = re.findall(r"\$clog2|\d+|[A-Za-z_]\w*|>>|<<|[-+*/%()]|\S", e)
    out = []
    for t in toks:
        if t.isdigit() or t in ("+", "-", "*", "%", "(", ")", ">>", "<<"):
            out.append(t)
        elif t == "$clog2":
            out.append("clog2")
        elif t == "/":
            out.append("//")
        elif re.fullmatch(r"[A-Za-z_]\w*", t):
            if t not in env:
                fail(f"cannot evaluate {what}: unknown name {t!r} in {expr!r}")
            out.append(str(int(env[t])))
        else:
            fail(f"cannot evaluate {what}: unsupported token {t!r} in {expr!r}")
    try:
        return int(eval(" ".join(out), {"__builtins__": {}}, {"clog2": lambda v: max(0, (int(v) - 1).bit_length())}))  # noqa: S307 (validated tokens)
    except Exception as exc:  # pragma: no cover
        fail(f"cannot evaluate {what}: {expr!r} ({exc})")


def parse_module_params(src: Source, module: str) -> dict[str, str]:
    """Header `parameter` defaults of a module, as raw expression strings (in order)."""
    m = src.search(r"\bmodule\s+%s\s*#\s*\(" % module, f"module {module} parameter list")
    depth, i = 1, m.end()
    while depth and i < len(src.text):
        depth += {"(": 1, ")": -1}.get(src.text[i], 0)
        i += 1
    src.record(f"module {module} parameters", m.start(), i)
    hdr = src.text[m.end():i - 1]
    params = {}
    for pm in re.finditer(r"\bparameter\s+(?:integer\s+|\[[^\]]*\]\s*)?(\w+)\s*=\s*([^,]+?)\s*(?=,\s*parameter\b|$)",
                          hdr.strip(), re.S):
        params[pm.group(1)] = pm.group(2).strip()
    if not params:
        fail(f"{src.rel}: no parameters parsed for module {module}")
    return params


def parse_instance(src: Source, module: str, inst: str) -> tuple[dict[str, str], dict[str, str]]:
    """Returns (parameter overrides, port connections) of `module #(...) inst (...)`."""
    m = src.search(r"\b%s\s*(#\s*\()?" % module + r"(?=[\s\S]*?\b%s\s*\()" % inst,
                   f"instance {inst} of {module}")
    # Find the instance name after the module name, then the parameter block between.
    im = re.compile(r"\b%s\s*\(" % inst).search(src.text, m.start())
    if not im:
        fail(f"{src.rel}: instance {inst} not found")
    head = src.text[m.start():im.start()]
    params = {}
    if "#" in head:
        body = head[head.index("#"):]
        body = body[body.index("(") + 1: body.rindex(")")]
        for pm in re.finditer(r"\.(\w+)\s*\(((?:[^()]|\([^()]*\))*)\)", body):
            params[pm.group(1)] = pm.group(2).strip()
    depth, i = 1, im.end()
    while depth and i < len(src.text):
        depth += {"(": 1, ")": -1}.get(src.text[i], 0)
        i += 1
    ports = {}
    for pm in re.finditer(r"\.(\w+)\s*\(((?:[^()]|\((?:[^()]|\([^()]*\))*\))*)\)", src.text[im.end():i - 1]):
        ports[pm.group(1)] = " ".join(pm.group(2).split())
    src.record(f"instance {inst}", m.start(), i)
    return params, ports


def resolve_params(defaults: dict[str, str], overrides: dict[str, str], parent_env: dict, what: str) -> dict[str, int]:
    env: dict[str, int] = {}
    for name, expr in defaults.items():
        if name in overrides:
            env[name] = eval_int(overrides[name], parent_env, f"{what}.{name} override")
        else:
            env[name] = eval_int(expr, env, f"{what}.{name} default")
    unknown = set(overrides) - set(defaults)
    if unknown:
        fail(f"{what}: instance overrides unknown parameters {sorted(unknown)}")
    return env


def parse_localparams(src: Source, names: list[str] | None = None, start: int = 0, end: int | None = None,
                      env: dict | None = None) -> dict[str, int]:
    """Evaluates `localparam [..]|integer NAME = expr` declarations in order (first definition wins)."""
    env = dict(env or {})
    seen = set()
    rx = re.compile(r"\blocalparam\s+(?:signed\s+)?(?:integer\s+|\[[^\]]*\]\s*)?((?:\w+\s*=\s*[^,;]+,\s*)*\w+\s*=\s*[^,;]+);")
    for m in rx.finditer(src.text, start, len(src.text) if end is None else end):
        for dm in re.finditer(r"(\w+)\s*=\s*([^,;]+)", m.group(1)):
            name, expr = dm.group(1), dm.group(2).strip()
            if name in seen:
                continue
            seen.add(name)
            try:
                env[name] = eval_int(expr, env, name)
            except ExtractError:
                if names and name in names:
                    raise
                continue
            if names and name in names:
                src.record(f"localparam {name}", m.start(), m.end())
    if names:
        missing = [n for n in names if n not in env]
        if missing:
            fail(f"{src.rel}: localparams not found or not constant: {missing}")
    return env


# --------------------------------------------------------------------------
# Colours
# --------------------------------------------------------------------------

def rgb888_to_444(c: int) -> int:
    """The RTL's rgb888_to_444: keeps the high nibble of each channel."""
    return (((c >> 20) & 0xF) << 8) | (((c >> 12) & 0xF) << 4) | ((c >> 4) & 0xF)


def color(v12: int, source888: int | None = None) -> dict:
    """RGB444 value plus its 24-bit expansion by nibble replication (framescope's fs_expand8)."""
    r, g, b = (v12 >> 8) & 0xF, (v12 >> 4) & 0xF, v12 & 0xF
    d = {"rgb12": f"0x{v12:03X}", "rgb24": f"#{r * 17:02x}{g * 17:02x}{b * 17:02x}"}
    if source888 is not None:
        d["rtl_rgb888"] = f"#{source888:06X}"
    return d


# --------------------------------------------------------------------------
# Git provenance
# --------------------------------------------------------------------------

def git_last_commit(paths: list[str]) -> str:
    try:
        out = subprocess.run(["git", "log", "-1", "--format=%H", "--", *paths], cwd=REPO,
                             capture_output=True, text=True, check=True).stdout.strip()
    except (OSError, subprocess.CalledProcessError) as exc:
        fail(f"git log failed: {exc}")
    if not re.fullmatch(r"[0-9a-f]{40}", out):
        fail(f"git log returned no commit for {paths}")
    return out


def source_block(sources: list[Source]) -> dict:
    return {
        "generator": GENERATOR,
        "rtl_commit": git_last_commit([s.rel for s in sources]),
        "rtl_commit_meaning": "last git commit that touched any of the files below "
                              "(`git log -1 --format=%H -- <files>`); file contents are pinned by sha256",
        "files": [s.info() for s in sources],
    }


# --------------------------------------------------------------------------
# canvas.json
# --------------------------------------------------------------------------

SPRITE_FUNCS = ["Wire", "Elbow", "Tee", "Junction", "Cross", "RL", "RR", "VL", "VR",
                "IL", "IR", "LL", "LR", "CL", "CR", "Ground"]

# The eight 32x32 dihedral transforms, as dest(dx,dy) <- source[row][col].
_DIHEDRAL = {
    "identity": (lambda dx, dy: (dy, dx)),
    "rotate 90 degrees clockwise": (lambda dx, dy: (31 - dx, dy)),
    "rotate 180 degrees": (lambda dx, dy: (31 - dy, 31 - dx)),
    "rotate 90 degrees counter-clockwise": (lambda dx, dy: (dx, 31 - dy)),
    "mirror left-right": (lambda dx, dy: (dy, 31 - dx)),
    "mirror top-bottom": (lambda dx, dy: (31 - dy, dx)),
    "transpose (mirror on main diagonal)": (lambda dx, dy: (dx, dy)),
    "anti-transpose (mirror on anti-diagonal)": (lambda dx, dy: (31 - dx, 31 - dy)),
}


def _lin(expr: str, what: str) -> tuple[int, str, int]:
    """'dx' | 'dy' | '31 - dx' | '31 - dy' -> (const, var, sign)."""
    m = re.fullmatch(r"\s*(?:(\d+)\s*-\s*)?(dx|dy)\s*", expr)
    if not m:
        fail(f"{CIRCUIT_CANVAS}: {what}: unsupported expression {expr!r}")
    if m.group(1) is None:
        return 0, m.group(2), 1
    if int(m.group(1)) != 31:
        fail(f"{CIRCUIT_CANVAS}: {what}: expected '31 - {m.group(2)}', got {expr!r}")
    return 31, m.group(2), -1


def _lin_str(const: int, var: str, sign: int) -> str:
    if sign == 1 and const == 0:
        return var
    if sign == -1:
        return f"{const} - {var}"
    fail("internal: unexpected linear form")


def _lin_obj(const: int, var: str, sign: int) -> dict:
    return {"const": const, "dx": sign if var == "dx" else 0, "dy": sign if var == "dy" else 0}


def extract_canvas(cc: Source, top: Source) -> dict:
    # ---- sprite row functions ----
    sprites_by_func = {}
    for fn in SPRITE_FUNCS:
        body, off = cc.function(fn)
        if not re.search(r"\binput\s*\[\s*4\s*:\s*0\s*\]\s*yy\s*;", body):
            fail(f"{CIRCUIT_CANVAS}: function {fn}: expected 'input [4:0] yy'")
        if not re.search(r"\bfunction\s*\[\s*31\s*:\s*0\s*\]", body):
            fail(f"{CIRCUIT_CANVAS}: function {fn}: expected 32-bit return")
        rows: dict[int, str] = {}
        for m in re.finditer(r"5'd(\d+)\s*:\s*%s\s*=\s*([^;]+);" % fn, body):
            r = int(m.group(1))
            if r in rows:
                fail(f"{CIRCUIT_CANVAS}: function {fn}: row {r} defined twice")
            w, v = parse_literal(m.group(2), cc, off + m.start(2), f"{fn} row {r}")
            if w != 32:
                fail(f"{CIRCUIT_CANVAS}: function {fn}: row {r} is {w} bits, expected 32")
            rows[r] = bits(v, 32)
        if sorted(rows) != list(range(32)):
            fail(f"{CIRCUIT_CANVAS}: function {fn}: expected rows 0..31, got {sorted(rows)}")
        dm = re.search(r"\bdefault\s*:\s*%s\s*=\s*([^;]+);" % fn, body)
        if not dm or parse_literal(dm.group(1))[1] != 0:
            fail(f"{CIRCUIT_CANVAS}: function {fn}: expected 'default: {fn} = 0'")
        sprites_by_func[fn] = [rows[r] for r in range(32)]

    # ---- GetRow: sprite id -> function ----
    body, off = cc.function("GetRow")
    id_to_func = {}
    for m in re.finditer(r"(\d+)'d(\d+)\s*:\s*GetRow\s*=\s*(\w+)\s*\(\s*yy\s*\)\s*;", body):
        sid, fn = int(m.group(2)), m.group(3)
        if sid in id_to_func:
            fail(f"{CIRCUIT_CANVAS}: GetRow: id {sid} mapped twice")
        if fn not in sprites_by_func:
            fail(f"{CIRCUIT_CANVAS}: GetRow: id {sid} -> unknown sprite function {fn}")
        id_to_func[sid] = fn
    if sorted(id_to_func) != list(range(16)):
        fail(f"{CIRCUIT_CANVAS}: GetRow: expected ids 0..15, got {sorted(id_to_func)}")
    dm = re.search(r"\bdefault\s*:\s*GetRow\s*=\s*([^;]+);", body)
    if not dm or parse_literal(dm.group(1))[1] != 0:
        fail(f"{CIRCUIT_CANVAS}: GetRow: expected an all-zero default")
    if not re.search(r"\binput\s*\[\s*5\s*:\s*0\s*\]\s*tt\s*;", body):
        fail(f"{CIRCUIT_CANVAS}: GetRow: expected 'input [5:0] tt'")

    # ---- pixel addressing: GetPixelVal, DecodeTop, sprite_pixel ----
    gp, _ = cc.function("GetPixelVal")
    cc.require("GetPixelVal = row[xx];", "GetPixelVal indexes the row word by bit number", within=gp)
    dt, _ = cc.function("DecodeTop")
    cc.require("DecodeTop = GetPixelVal(GetRow(tt, GetYY(dx, dy, ro)), GetXX(dx, dy, ro));",
               "DecodeTop composition", within=dt)
    cc.require("DecodeTop( cell_type, cell_rotation, cell_offset_x, cell_offset_y )",
               "sprite_pixel uses cell offsets", label="sprite_pixel")

    # ---- rotation: GetXX (source bit index) and GetYY (source row) ----
    rot_src = {}
    for fn in ("GetXX", "GetYY"):
        body, _ = cc.function(fn)
        if not re.search(r"\binput\s*\[\s*1\s*:\s*0\s*\]\s*ro\s*;", body):
            fail(f"{CIRCUIT_CANVAS}: {fn}: expected 'input [1:0] ro'")
        table = {}
        for m in re.finditer(r"2'b([01]{2})\s*:\s*%s\s*=\s*([^;]+);" % fn, body):
            table[int(m.group(1), 2)] = _lin(m.group(2), f"{fn} case {m.group(1)}")
        if sorted(table) != [0, 1, 2, 3]:
            fail(f"{CIRCUIT_CANVAS}: {fn}: expected cases 2'b00..2'b11, got {sorted(table)}")
        rot_src[fn] = table

    rotations = {}
    for ro in range(4):
        xc, xv, xs = rot_src["GetXX"][ro]   # source bit index = xc + xs*xv
        yc, yv, ys = rot_src["GetYY"][ro]   # source row       = yc + ys*yv
        # Row strings are MSB first: string column = 31 - bit index.
        cc_, cv, cs = 31 - xc, xv, -xs
        row_l = (yc, yv, ys)
        col_l = (cc_, cv, cs)

        def ev(l, dx, dy):
            return l[0] + l[2] * (dx if l[1] == "dx" else dy)

        # Cross-check against a literal simulation of the RTL functions.
        mapping = set()
        for dx in range(32):
            for dy in range(32):
                bit = ev((xc, xv, xs), dx, dy) & 31
                row = ev((yc, yv, ys), dx, dy) & 31
                sr, sc = ev(row_l, dx, dy), ev(col_l, dx, dy)
                if (sr, sc) != (row, 31 - bit) or not (0 <= sr < 32 and 0 <= sc < 32):
                    fail("internal: rotation declarative form disagrees with RTL simulation")
                mapping.add((sr, sc))
        if len(mapping) != 1024:
            fail(f"{CIRCUIT_CANVAS}: rotation {ro} is not a bijection on 32x32")
        desc = [name for name, f in _DIHEDRAL.items()
                if all(f(dx, dy) == (ev(row_l, dx, dy), ev(col_l, dx, dy))
                       for dx in range(32) for dy in range(32))]
        if len(desc) != 1:
            fail(f"{CIRCUIT_CANVAS}: rotation {ro} is not a dihedral transform")
        rotations[str(ro)] = {
            "src_row": _lin_str(*row_l),
            "src_col": _lin_str(*col_l),
            "src_row_linear": _lin_obj(*row_l),
            "src_col_linear": _lin_obj(*col_l),
            "description": desc[0],
            "rtl_GetYY": _lin_str(yc, yv, ys),
            "rtl_GetXX": _lin_str(xc, xv, xs),
        }

    # ---- cell word ----
    fields = {}
    for name in ("cell_mode", "cell_rotation", "cell_type", "cell_enable"):
        m = cc.search(r"\bassign\s+%s\s*=\s*cell_data\s*\[\s*(\d+)\s*(?::\s*(\d+)\s*)?\]\s*;" % name, name)
        cc.record("cell word decode", m.start(), m.end())
        hi = int(m.group(1))
        lo = int(m.group(2)) if m.group(2) else hi
        fields[name.replace("cell_", "")] = {"msb": hi, "lsb": lo}
    m = cc.search(r"\bwire\s+flow_bit\s*=\s*cell_data\s*\[\s*(\d+)\s*\]\s*;", "flow_bit")
    cc.record("flow animation", m.start(), m.end())
    fields["flow_bit"] = {"msb": int(m.group(1)), "lsb": int(m.group(1)),
                          "note": "bit 0 of mode; selects flow animation direction"}

    # ---- palette ----
    body, _ = cc.function("palette_idx_to_rgb12")
    pal = {}
    for m in re.finditer(r"4'd(\d+)\s*:\s*palette_idx_to_rgb12\s*=\s*12'h([0-9A-Fa-f]{3})\s*;", body):
        pal[int(m.group(1))] = int(m.group(2), 16)
    dm = re.search(r"\bdefault\s*:\s*palette_idx_to_rgb12\s*=\s*12'h([0-9A-Fa-f]{3})\s*;", body)
    if not dm:
        fail(f"{CIRCUIT_CANVAS}: palette_idx_to_rgb12: no default entry")
    missing = [i for i in range(16) if i not in pal]
    if missing != [15]:
        fail(f"{CIRCUIT_CANVAS}: palette_idx_to_rgb12: expected explicit entries 0..14 and default for 15, "
             f"missing {missing}")
    pal[15] = int(dm.group(1), 16)
    palette = [dict(index=i, **color(pal[i])) for i in range(16)]

    # ---- canvas constants ----
    cl = parse_localparams(cc, ["DefaultFgColorIdx", "DefaultBgColorIdx", "HoverBgColorIdx",
                                "ColorYellow", "GridColor", "GridMarginWidth", "EmptyCellData"])

    # Render-rule shapes the README describes; fail if they change.
    shapes = [
        ("at_cell_max_edge", "wire at_cell_max_edge = (cell_offset_x == (CellSize - 1)) || (cell_offset_y == (CellSize - 1));"),
        ("sprite_pixel_visible", "wire sprite_pixel_visible = sprite_pixel && !at_cell_max_edge;"),
        ("at_grid_edge", "assign at_grid_edge = cell_offset_x < GridMarginWidth / 2 || cell_offset_y < GridMarginWidth / 2 || "
                         "cell_offset_x >= CellSize - GridMarginWidth / 2 || cell_offset_y >= CellSize - GridMarginWidth / 2;"),
        ("hover background", "wire [3:0] effective_bg_color_idx = (hovering && !sprite_pixel_visible && !at_grid_edge) ? HoverBgColorIdx : cell_bg_color_idx;"),
        ("hovering", "assign hovering = required_cell_in_bounds && (mouse_cell_i < GridWidth) && (mouse_cell_j < GridHeight) && "
                     "(required_i == mouse_cell_i) && (required_j == mouse_cell_j);"),
        ("colour mux", "assign rgb = is_yellow ? ColorYellow : sprite_pixel_visible ? currentColorPos : (at_grid_edge ? GridColor : currentColorNeg);"),
        ("colour lookup", "wire [11:0] currentColorPos = palette_idx_to_rgb12(cell_fg_color_idx);"),
        ("colour lookup", "wire [11:0] currentColorNeg = palette_idx_to_rgb12(effective_bg_color_idx);"),
        ("sprite_pixel", "assign sprite_pixel = (required_cell_in_bounds && cell_enable) ?"),
        ("flow animation", "wire is_yellow = cell_enable && active_mask && (is_wire_type ? sprite_pixel_visible : is_center_line_visible);"),
        ("flow animation", "wire is_wire_type = (cell_type <= 6'd4);"),
        ("flow animation", "wire is_horz_center = (cell_offset_y >= 13 && cell_offset_y <= 18);"),
        ("flow animation", "wire is_vert_center = (cell_offset_x >= 13 && cell_offset_x <= 18);"),
        ("flow animation", "wire mask_R = mod_R < 5;"),
        ("cell data register", "cell_data <= EmptyCellData;"),
        ("cell data register", "cell_data <= incoming_data;"),
        ("cell data register", "cell_data <= cached_data;"),
        ("rendered", "assign rendered = x_pos >= CanvasPosX && x_pos < CanvasPosX + CanvasWidth && y_pos >= CanvasPosY && y_pos < CanvasPosY + CanvasHeight;"),
    ]
    for label, code in shapes:
        cc.require(code, label, label=label)
    if re.search(r"\bdisplay_grid\b", cc.text[cc.text.index("display_grid") + 12:]):
        fail(f"{CIRCUIT_CANVAS}: display_grid is now used inside CircuitCanvas; update the extractor/README")

    # ---- instance geometry in GlobalRender_top ----
    tl = parse_localparams(top, ["SCREEN_W", "SCREEN_H", "TOP_BAR_H", "LEFT_BAR_W", "BOTTOM_BAR_H",
                                 "CANVAS_CELL_SIZE", "CANVAS_GRID_W", "CANVAS_GRID_H", "CANVAS_X0", "CANVAS_Y0",
                                 "CANVAS_W", "CANVAS_H", "CANVAS_FG_DEFAULT_COLOR_IDX", "CANVAS_BG_DEFAULT_COLOR_IDX"])
    defaults = parse_module_params(cc, "CircuitCanvas")
    overrides, ports = parse_instance(top, "CircuitCanvas", "circuit_canvas_inst")
    p = resolve_params(defaults, overrides, tl, "circuit_canvas_inst")
    if ports.get("display_grid") != "1'b1":
        fail(f"{GLOBAL_RENDER}: circuit_canvas_inst.display_grid is {ports.get('display_grid')!r}, expected 1'b1")
    if p["CellSize"] != 32:
        fail("CellSize is not 32: sprites are 32x32 and offsets are truncated to 5 bits")
    min_x = 0 if p["CanvasWidth"] > p["GridWidth"] * p["CellSize"] else p["CanvasWidth"] - p["GridWidth"] * p["CellSize"]
    min_y = 0 if p["CanvasHeight"] > p["GridHeight"] * p["CellSize"] else p["CanvasHeight"] - p["GridHeight"] * p["CellSize"]
    cc.require("localparam signed [12:0] min_grid_x = (CanvasWidth > (GridWidth * CellSize)) ? 13'sd0 : (CanvasWidth - (GridWidth * CellSize));",
               "pan clamp", label="pan clamp")

    # Top-level sprite id names.
    names = {}
    for m in re.finditer(r"\blocalparam\s*\[\s*5\s*:\s*0\s*\]\s*(SPRITE_\w+)\s*=\s*6'd(\d+)\s*;", top.text):
        sid = int(m.group(2))
        if sid in names and names[sid] != m.group(1):
            fail(f"{GLOBAL_RENDER}: sprite id {sid} has two names")
        if sid not in names:
            top.record("SPRITE_* localparams", m.start(), m.end())
        names[sid] = m.group(1)
    if not names:
        fail(f"{GLOBAL_RENDER}: no SPRITE_* localparams found")

    sprites = []
    for sid in range(16):
        fn = id_to_func[sid]
        sprites.append({"id": sid, "name": fn, "top_level_localparam": names.get(sid),
                        "rows": sprites_by_func[fn]})

    return {
        "schema": "metacircuit-assets/canvas",
        "schema_version": SCHEMA_VERSION,
        "source": source_block([cc, top]),
        "sprite_format": {
            "width": 32, "height": 32,
            "rows": "rows[r] is sprite row r, r = 0 is the top row (RTL yy = r)",
            "chars": "rows[r][c] is '1' (foreground) or '0'; c = 0 is the LEFTMOST pixel when drawn with "
                     "rotation 0. Char c holds bit (31 - c) of the RTL's 32-bit row word, i.e. the strings are "
                     "the Verilog binary literals written MSB first.",
            "ids_without_sprite": "ids 16..63 (6-bit field) select GetRow's default: all pixels '0'",
        },
        "sprites": sprites,
        "rotation": {
            "convention": "For a cell drawn with rotation code ro, the destination pixel at cell offset (dx, dy) "
                          "(dx = 0 left column, dy = 0 top row, both 0..31) takes the value "
                          "sprites[id].rows[src_row][src_col], with src_row and src_col given below as "
                          "functions of dx and dy (linear form: const + dx*coef_dx + dy*coef_dy).",
            "codes": rotations,
            "rtl_semantics": "RTL: pixel = GetRow(id, GetYY(dx,dy,ro))[GetXX(dx,dy,ro)] (bit index); "
                             "string column = 31 - bit index.",
        },
        "cell_word": {
            "width": 16, "fields": fields,
            "note": "type = sprite id (6 bits); enable = 0 renders no sprite; mode bits other than flow_bit "
                    "are not used by the renderer",
        },
        "palette": palette,
        "colors": {
            "grid": color(cl["GridColor"]),
            "flow_yellow": color(cl["ColorYellow"]),
            "default_fg_idx": cl["DefaultFgColorIdx"],
            "default_bg_idx": cl["DefaultBgColorIdx"],
            "hover_bg_idx": cl["HoverBgColorIdx"],
            "top_level_fg_default_idx": tl["CANVAS_FG_DEFAULT_COLOR_IDX"],
            "top_level_bg_default_idx": tl["CANVAS_BG_DEFAULT_COLOR_IDX"],
        },
        "geometry": {
            "canvas_x0": p["CanvasPosX"], "canvas_y0": p["CanvasPosY"],
            "canvas_w": p["CanvasWidth"], "canvas_h": p["CanvasHeight"],
            "cell_size": p["CellSize"], "grid_w": p["GridWidth"], "grid_h": p["GridHeight"],
            "cell_count": p["GridWidth"] * p["GridHeight"],
            "cell_address": "addr = i + j * grid_w (i = column, j = row)",
            "grid_margin_width": cl["GridMarginWidth"],
            "grid_line_pixels": "cell offsets < grid_margin_width/2 or >= cell_size - grid_margin_width/2 "
                                f"(= offset 0 and offset {p['CellSize'] - 1})",
            "pan_offset_range": {"x": [min_x, 0], "y": [min_y, 0],
                                 "note": "grid_pos is added to the cell origin: cell (i,j) has screen origin "
                                         "(canvas_x0 + grid_pos_x + 32*i, canvas_y0 + grid_pos_y + 32*j)"},
            "display_grid": "tied to 1'b1 in GlobalRender_top and not used inside CircuitCanvas "
                            "(grid lines are always drawn)",
        },
        "pixel_rule": [
            "Applies to screen pixels with canvas_x0 <= x < canvas_x0+canvas_w and canvas_y0 <= y < canvas_y0+canvas_h.",
            "ax = x - canvas_x0 - grid_pos_x, ay = y - canvas_y0 - grid_pos_y; i = ax div 32, j = ay div 32; "
            "dx = ax mod 32, dy = ay mod 32. in_bounds = i < grid_w and j < grid_h.",
            "Out of bounds: cell word = 0, fg = default_fg_idx, bg = default_bg_idx.",
            "sprite = in_bounds and enable and sprite pixel (see rotation) ; visible = sprite and dx != 31 and dy != 31.",
            "grid = dx < 1 or dy < 1 or dx >= 31 or dy >= 31.",
            "bg_idx = hover_bg_idx if (mouse is over the same in-bounds cell and not visible and not grid) else cell bg.",
            "colour = flow_yellow if flow-highlighted, else palette[fg] if visible, else grid colour if grid, "
            "else palette[bg_idx].",
            "RTL timing quirk: the cell word/fg/bg are registered, so each pixel uses the cell data fetched for the "
            "previous pixel (x-1) while dx/dy/i/j/grid/hover come from x. Only pixels with dx == 0 can differ "
            "(they show the left neighbour cell's sprite/fg, decoded at dx = 0); at x = canvas_x0 the data is empty.",
        ],
        "flow_animation": {
            "note": "Animated current-flow highlight (logic, not an asset); masked in comparisons until the phase "
                    "is frame-locked (RTL-1). Constants for reference only.",
            "color": color(cl["ColorYellow"]),
            "band_width": 5,
            "wire_types_follow_sprite": "types 0..4 highlight sprite pixels; other types highlight the centre "
                                        "band offsets 13..18 (rows for rotation 0/2, columns for 1/3)",
        },
    }


# --------------------------------------------------------------------------
# ButtonVGA model (shared by toolbar and keypad)
# --------------------------------------------------------------------------

def _lighten_q(c):
    out = 0
    for sh in (16, 8, 0):
        ch = (c >> sh) & 0xFF
        out |= ((ch + ((0xFF - ch) >> 2)) & 0xFF) << sh
    return out


def _darken_q(c):
    out = 0
    for sh in (16, 8, 0):
        ch = (c >> sh) & 0xFF
        out |= ((ch - (ch >> 2)) & 0xFF) << sh
    return out


def _darken_e(c):
    out = 0
    for sh in (16, 8, 0):
        ch = (c >> sh) & 0xFF
        out |= ((ch - (ch >> 3)) & 0xFF) << sh
    return out


def check_button_source(btn: Source) -> dict:
    """Verifies the ButtonVGA logic the model below mirrors; returns glyph tables."""
    for code, what in [
        ("r = c[23:16] + ((8'hFF - c[23:16]) >> 2);", "lighten_rgb_quarter"),
        ("darken_rgb_quarter = {c[23:16] - (c[23:16] >> 2),", "darken_rgb_quarter"),
        ("darken_rgb_eighth = {c[23:16] - (c[23:16] >> 3),", "darken_rgb_eighth"),
        ("rgb888_to_444 = {c[23:20], c[15:12], c[7:4]};", "rgb888_to_444"),
        ("if (selected) face_color = lighten_rgb_quarter(FACE_RGB);", "state colours"),
        ("if (pressed) face_color = darken_rgb_eighth(face_color);", "state colours"),
        ("top_left_edge_color = darken_rgb_eighth(face_color); bottom_right_edge_color = darken_rgb_quarter(face_color);",
         "state colours"),
        ("top_left_edge_color = lighten_rgb_quarter(face_color); bottom_right_edge_color = darken_rgb_quarter(face_color);",
         "state colours"),
        ("is_border = (local_x < BORDER) || (local_y < BORDER) || (local_x >= (W - BORDER)) || (local_y >= (H - BORDER));",
         "geometry"),
        ("is_selected_marker = selected && (local_x >= MARKER_OFFSET) && (local_x < (MARKER_OFFSET + MARKER_W)) && "
         "(local_y >= MARKER_OFFSET) && (local_y < (MARKER_OFFSET + MARKER_H));", "geometry"),
        ("is_top_edge = (local_y >= BORDER) && (local_y < (BORDER + EDGE_THICK)) && (local_x >= BORDER) && (local_x < (W - BORDER));",
         "geometry"),
        ("is_left_edge = (local_x >= BORDER) && (local_x < (BORDER + EDGE_THICK)) && (local_y >= BORDER) && (local_y < (H - BORDER));",
         "geometry"),
        ("is_right_edge = (local_x >= (W - BORDER - EDGE_THICK)) && (local_x < (W - BORDER)) && (local_y >= BORDER) && (local_y < (H - BORDER));",
         "geometry"),
        ("is_bottom_edge = (local_y >= (H - BORDER - EDGE_THICK)) && (local_y < (H - BORDER)) && (local_x >= BORDER) && (local_x < (W - BORDER));",
         "geometry"),
        ("text_w = (TEXT_COLS * (5 * FONT5_SCALE)) + ((TEXT_COLS - 1) * FONT5_SCALE); text_h = 7 * FONT5_SCALE;", "text"),
        ("text_w = (TEXT_COLS * (3 * FONT3_SCALE)) + ((TEXT_COLS - 1) * FONT3_SCALE); text_h = 5 * FONT3_SCALE;", "text"),
        ("text_x0 = (W - text_w) >> 1; text_y0 = (H - text_h) >> 1;", "text"),
        ("if (row_bits_5x7[4 - glyph_col]) is_text = 1'b1;", "text"),
        ("glyph_col = (glyph_local_x - (6 * FONT5_SCALE)) / FONT5_SCALE;", "text"),
        ("glyph_col = (glyph_local_x - (12 * FONT5_SCALE)) / FONT5_SCALE;", "text"),
        ("if (is_border && pressed) pixel_rgb = rgb888_to_444(PRESSED_BORDER_RGB); "
         "else if (is_border && selected) pixel_rgb = rgb888_to_444(SELECTED_BORDER_RGB); "
         "else if (is_border) pixel_rgb = rgb888_to_444(BORDER_RGB); "
         "else if (is_text) pixel_rgb = rgb888_to_444(TEXT_RGB); "
         "else if (is_top_edge || is_left_edge) pixel_rgb = rgb888_to_444(top_left_edge_color); "
         "else if (is_right_edge || is_bottom_edge) pixel_rgb = rgb888_to_444(bottom_right_edge_color); "
         "else if (is_selected_marker) pixel_rgb = rgb888_to_444(SELECTED_MARKER_RGB); "
         "else pixel_rgb = rgb888_to_444(face_color);", "layer priority"),
        ("assign inside_button = enabled && (x >= X0) && (x < (X0 + W)) && (y >= Y0) && (y < (Y0 + H));", "inside_button"),
    ]:
        btn.require(code, what, label=f"ButtonVGA {what}")
    btn.function("lighten_rgb_quarter")
    btn.function("darken_rgb_quarter")
    btn.function("darken_rgb_eighth")

    glyphs = {}
    for fn, n_rows, n_cols in (("glyph5x7", 7, 5), ("glyph3x5", 5, 3)):
        body, off = btn.function(fn)
        table = {}
        for m in re.finditer(r'"(.)"\s*:\s*%s\s*=\s*([^;]+);' % fn, body):
            w, v = parse_literal(m.group(2), btn, off + m.start(2), f"{fn} {m.group(1)!r}")
            if w != n_rows * n_cols:
                fail(f"{BUTTON}: {fn} {m.group(1)!r} has width {w}")
            s = bits(v, w)
            table[m.group(1)] = [s[r * n_cols:(r + 1) * n_cols] for r in range(n_rows)]
        dm = re.search(r"\bdefault\s*:\s*%s\s*=\s*([^;]+);" % fn, body)
        if not dm or parse_literal(dm.group(1))[1] != 0 or not table:
            fail(f"{BUTTON}: {fn}: table or blank default not found")
        glyphs[fn] = table
        rb, _ = btn.function(fn + "_row")
        # Row r = bits [w-1-r*n_cols : w-n_cols-r*n_cols], i.e. MSB-first rows.
        top_hi = n_rows * n_cols - 1
        btn.require(f"{fn}_row = g[{top_hi}:{top_hi - n_cols + 1}];", f"{fn}_row row 0 is the MSB group", within=rb)
    return glyphs


def button_colors(face, border, sel_border, sel_marker, pressed_border, text) -> dict:
    states = {}
    for name, sel, prs in (("normal", 0, 0), ("selected", 1, 0), ("pressed", 0, 1), ("selected_pressed", 1, 1)):
        f = face
        if sel:
            f = _lighten_q(f)
        if prs:
            f = _darken_e(f)
        if prs:
            tl, br = _darken_e(f), _darken_q(f)
        else:
            tl, br = _lighten_q(f), _darken_q(f)
        b = pressed_border if prs else (sel_border if sel else border)
        st = {
            "B": color(rgb888_to_444(b), b),
            "X": color(rgb888_to_444(text), text),
            "T": color(rgb888_to_444(tl), tl),
            "R": color(rgb888_to_444(br), br),
            "M": color(rgb888_to_444(sel_marker), sel_marker) if sel else color(rgb888_to_444(f), f),
            "F": color(rgb888_to_444(f), f),
        }
        states[name] = st
    return states


def button_role_map(W, H, BORDER, EDGE, MOFF, MW, MH, text_cols, small, s5, s3, labels, glyphs) -> list[str]:
    """Per-pixel role of a ButtonVGA button, mirroring its always block (12-bit wraparound ignored:
    all coordinates here are small and non-negative)."""
    if small:
        text_w = text_cols * (3 * s3) + (text_cols - 1) * s3
        text_h = 5 * s3
    else:
        text_w = text_cols * (5 * s5) + (text_cols - 1) * s5
        text_h = 7 * s5
    tx0 = (W - text_w) >> 1
    ty0 = (H - text_h) >> 1
    rows = []
    for ly in range(H):
        row = []
        for lx in range(W):
            border = lx < BORDER or ly < BORDER or lx >= W - BORDER or ly >= H - BORDER
            marker = MOFF <= lx < MOFF + MW and MOFF <= ly < MOFF + MH
            top = BORDER <= ly < BORDER + EDGE and BORDER <= lx < W - BORDER
            left = BORDER <= lx < BORDER + EDGE and BORDER <= ly < H - BORDER
            right = W - BORDER - EDGE <= lx < W - BORDER and BORDER <= ly < H - BORDER
            bottom = H - BORDER - EDGE <= ly < H - BORDER and BORDER <= lx < W - BORDER
            is_text = False
            if text_cols != 0 and tx0 <= lx < tx0 + text_w and ty0 <= ly < ty0 + text_h:
                gx, gy = lx - tx0, ly - ty0
                if small:
                    sc, n, tab = s3, 3, glyphs["glyph3x5"]
                else:
                    sc, n, tab = s5, 5, glyphs["glyph5x7"]
                grow = gy // sc
                for k in range(3):
                    if k >= text_cols:
                        break
                    lo, hi = k * (n + 1) * sc, (k * (n + 1) + n) * sc
                    if lo <= gx < hi:
                        col = (gx - lo) // sc
                        g = tab.get(labels[k])
                        if g is not None and grow < len(g) and g[grow][col] == "1":
                            is_text = True
                        break
            if border:
                ch = "B"
            elif is_text:
                ch = "X"
            elif top or left:
                ch = "T"
            elif right or bottom:
                ch = "R"
            elif marker:
                ch = "M"
            else:
                ch = "F"
            row.append(ch)
        rows.append("".join(row))
    return rows


ROLE_LEGEND = {
    "B": "border (BORDER px ring); colour depends on state",
    "X": "label text pixel",
    "T": "top/left bevel edge",
    "R": "bottom/right bevel edge",
    "M": "selected marker; drawn as the face colour unless the button is selected",
    "F": "face",
}


def _lit_or_int(expr: str, env: dict, what: str) -> int:
    return eval_int(expr, env, what)


# --------------------------------------------------------------------------
# toolbar.json
# --------------------------------------------------------------------------

def extract_toolbar(tb: Source, btn: Source, top: Source, glyphs: dict) -> dict:
    defaults = parse_module_params(tb, "ToolbarVGA")
    overrides, ports = parse_instance(top, "ToolbarVGA", "toolbar_vga_inst")
    p = resolve_params(defaults, overrides, {}, "toolbar_vga_inst")

    tb.require("button_y0 = BTN_Y0 + (idx * (BTN_H + BTN_GAP));", "button_y0", label="function button_y0")
    tb.require("icon_y0 = button_y0(idx) + ((BTN_H - ICON_H) / 2);", "icon_y0", label="function icon_y0")
    tb.require("if (toolbar_row_bits[23 - (x - ICON_X0)]) toolbar_bitmap_active = 1'b1;", "icon bit order",
               label="icon draw")
    tb.require("toolbar_row_bits = toolbar_bitmap_row(display_icon_idx, y - icon_y0(k));", "icon row index",
               label="icon draw")
    tb.require("if (toolbar_bitmap_active) pixel_rgb = 12'h000;", "icon colour", label="icon draw")
    tb.require("pixel_rgb = rgb888_to_444(24'hF3D9B8);", "toolbar background", label="toolbar background")
    tb.require("assign rendered = (x >= BAR_X0) && (x < (BAR_X0 + BAR_W)) && (y >= BAR_Y0) && (y < (BAR_Y0 + BAR_H));",
               "rendered", label="rendered")
    bg = int(re.search(r"pixel_rgb\s*=\s*rgb888_to_444\s*\(\s*24'h([0-9A-Fa-f]{6})", tb.text).group(1), 16)

    # ---- icon bitmaps ----
    body, off = tb.function("toolbar_bitmap_row")
    if not re.search(r"function\s*\[\s*23\s*:\s*0\s*\]", body):
        fail(f"{TOOLBAR}: toolbar_bitmap_row: expected 24-bit rows")
    branches = list(re.finditer(r"(?<![\w'])(\d+|default)\s*:\s*begin\s*case\s*\(\s*row_idx\s*\)(.*?)\bendcase\s*end",
                                body, re.S))
    if not branches:
        fail(f"{TOOLBAR}: toolbar_bitmap_row: no icon branches found")
    table = {}
    for b in branches:
        rows, default = {}, None
        for m in re.finditer(r"(?<![\w'])(\d+|default)\s*:\s*toolbar_bitmap_row\s*=\s*([^;]+);", b.group(2)):
            w, v = parse_literal(m.group(2), tb, off + b.start(2) + m.start(2), f"icon {b.group(1)} row {m.group(1)}")
            if w != 24:
                fail(f"{TOOLBAR}: icon {b.group(1)} row {m.group(1)} is {w} bits")
            if m.group(1) == "default":
                default = bits(v, 24)
            else:
                rows[int(m.group(1))] = bits(v, 24)
        if default is None:
            fail(f"{TOOLBAR}: icon branch {b.group(1)} has no default row")
        table[b.group(1)] = (rows, default)
    if "default" not in table:
        fail(f"{TOOLBAR}: toolbar_bitmap_row: no default icon branch")
    if p["ICON_W"] != 24:
        fail(f"{TOOLBAR}: ICON_W is {p['ICON_W']}, icons are 24 bits wide")

    def icon(idx: int):
        key = str(idx) if str(idx) in table else "default"
        rows, default = table[key]
        return key, [rows.get(r, default) for r in range(p["ICON_H"])]

    # ---- button -> icon mapping ----
    tb.require("display_icon_idx = k[3:0]; if (k == 1) begin case (selected_wire_variant)", "icon remap for button 1",
               label="icon draw")
    variants = {}
    vb = tb.search(r"case\s*\(\s*selected_wire_variant\s*\)(.*?)endcase", "wire variant icon case")
    for m in re.finditer(r"(?:2'd(\d)|default)\s*:\s*display_icon_idx\s*=\s*4'd(\d+)\s*;", vb.group(1)):
        variants[m.group(1) if m.group(1) is not None else "default"] = int(m.group(2))
    if sorted(variants) != ["0", "1", "2", "default"]:
        fail(f"{TOOLBAR}: wire variant icon mapping has unexpected cases {sorted(variants)}")
    variants["3"] = variants.pop("default")

    # ---- tool names from GlobalRender_top's toolbar_mode_select (names are the RTL comments) ----
    fm = top.search(r"\bfunction\s*\[\s*3\s*:\s*0\s*\]\s*toolbar_mode_select\s*;", "toolbar_mode_select")
    fe = top.text.index("endfunction", fm.end())
    top.record("function toolbar_mode_select", fm.start(), fe + len("endfunction"))
    raw = top.raw[fm.start():fe]
    modes, variant_modes = {}, {}
    for m in re.finditer(r"4'd(\d+)\s*:\s*toolbar_mode_select\s*=\s*4'd(\d+)\s*;\s*//\s*([^\n]+)", raw):
        modes[int(m.group(1))] = (int(m.group(2)), m.group(3).strip())
    for m in re.finditer(r"(?:2'd(\d)|default)\s*:\s*toolbar_mode_select\s*=\s*4'd(\d+)\s*;\s*//\s*([^\n]+)", raw):
        variant_modes[m.group(1) if m.group(1) is not None else "3"] = (int(m.group(2)), m.group(3).strip())
    dm = re.search(r"default\s*:\s*toolbar_mode_select\s*=\s*4'h([0-9A-Fa-f])\s*;", raw)
    if not modes or sorted(variant_modes) != ["0", "1", "2", "3"] or not dm:
        fail(f"{GLOBAL_RENDER}: toolbar_mode_select has an unexpected shape")
    top.require(".mouse_left_click(mouse_left_pix && (selected_toolbar_idx == 4'd0))", "pan tool is index 0",
                label="instance circuit_canvas_inst")

    # ---- ButtonVGA instance parameters inside ToolbarVGA ----
    bm = tb.search(r"\bButtonVGA\s*#\s*\((.*?)\)\s*toolbar_button_inst", "ButtonVGA instance")
    tb.record("ButtonVGA instance", bm.start(), bm.end())
    bp = {m.group(1): m.group(2).strip()
          for m in re.finditer(r"\.(\w+)\s*\(((?:[^()]|\([^()]*\))*)\)", bm.group(1))}
    bdef = parse_module_params(btn, "ButtonVGA")
    unknown = set(bp) - set(bdef)
    if unknown:
        fail(f"{TOOLBAR}: ButtonVGA overrides unknown parameters {sorted(unknown)}")
    env = dict(p)

    def bparam(name):
        expr = bp.get(name, bdef[name])
        return eval_int(expr, env, f"toolbar ButtonVGA.{name}")

    if bparam("TEXT_COLS") != 1 or bparam("LABEL0") != 0:
        fail(f"{TOOLBAR}: toolbar buttons now have labels; extractor assumes LABEL0 = 0, TEXT_COLS = 1")
    if bp.get("X0") != "BTN_X0" or bp.get("Y0") != "button_y0(btn_idx)" or bp.get("W") != "BTN_W" or bp.get("H") != "BTN_H":
        fail(f"{TOOLBAR}: ButtonVGA geometry binding changed")
    tb.require(".selected(selected_tool_idx == btn_idx[3:0])", "selected binding", label="ButtonVGA instance")
    tb.require(".pressed(mouse_left && hover_valid && (hovered_tool_idx == btn_idx[3:0]))", "pressed binding",
               label="ButtonVGA instance")
    style = {k: bparam(k) for k in ("BORDER", "EDGE_THICK", "MARKER_OFFSET", "MARKER_W", "MARKER_H",
                                    "FONT5_SCALE", "FONT3_SCALE")}
    cols = {k: bparam(k) for k in ("FACE_RGB", "BORDER_RGB", "SELECTED_BORDER_RGB", "SELECTED_MARKER_RGB",
                                   "PRESSED_BORDER_RGB", "TEXT_RGB")}
    role = button_role_map(p["BTN_W"], p["BTN_H"], style["BORDER"], style["EDGE_THICK"], style["MARKER_OFFSET"],
                           style["MARKER_W"], style["MARKER_H"], 1, bparam("SMALL_TEXT"), style["FONT5_SCALE"],
                           style["FONT3_SCALE"], ["\0", "\0", "\0"], glyphs)

    pitch = p["BTN_H"] + p["BTN_GAP"]
    buttons = []
    for k in range(p["TOOLBAR_COUNT"]):
        y0 = p["BTN_Y0"] + k * pitch
        entry = {"index": k, "x0": p["BTN_X0"], "y0": y0, "w": p["BTN_W"], "h": p["BTN_H"],
                 "icon_x0": p["ICON_X0"], "icon_y0": y0 + (p["BTN_H"] - p["ICON_H"]) // 2}
        if k == 1:
            entry["icon"] = {"by_wire_variant": {v: variants[v] for v in sorted(variants)}}
            entry["tool"] = {v: variant_modes[v][1] for v in sorted(variant_modes)}
            entry["interaction_mode"] = {v: variant_modes[v][0] for v in sorted(variant_modes)}
        else:
            entry["icon"] = k
            if k in modes:
                entry["tool"] = modes[k][1]
                entry["interaction_mode"] = modes[k][0]
            else:
                entry["tool"] = "pan (canvas drag; the only tool that enables CircuitCanvas panning)"
                entry["interaction_mode"] = int(dm.group(1), 16)
        buttons.append(entry)

    icons = {}
    for idx in range(14):
        key, rows = icon(idx)
        icons[str(idx)] = {"rtl_case": key, "rows": rows}

    return {
        "schema": "metacircuit-assets/toolbar",
        "schema_version": SCHEMA_VERSION,
        "source": source_block([tb, btn, top]),
        "region": {"x0": p["BAR_X0"], "y0": p["BAR_Y0"], "w": p["BAR_W"], "h": p["BAR_H"],
                   "background": color(rgb888_to_444(bg), bg)},
        "parameters": {k: p[k] for k in defaults},
        "instance_overrides": overrides,
        "buttons": buttons,
        "button_pitch": pitch,
        "icon_format": {
            "width": p["ICON_W"], "height": p["ICON_H"],
            "rows": "rows[r] is drawn on screen row icon_y0 + r",
            "chars": "rows[r][c] = '1' draws the icon colour at screen x = icon_x0 + c (c = 0 leftmost); "
                     "char c is bit (23 - c) of the RTL's 24-bit row word",
            "color": color(0x000),
            "priority": "icon pixels are drawn over the button (including its border)",
        },
        "icons": icons,
        "icon_notes": "icons '1' and '10' share the same bitmap; button 1 never shows icon 1 (always 10..13 by "
                      "wire variant). Icon 9 (delete) is the RTL's default branch.",
        "button_style": {
            "params": style,
            "rtl_colors": {k: f"#{v:06X}" for k, v in cols.items()},
            "role_map": role,
            "role_legend": ROLE_LEGEND,
            "state_colors": button_colors(cols["FACE_RGB"], cols["BORDER_RGB"], cols["SELECTED_BORDER_RGB"],
                                          cols["SELECTED_MARKER_RGB"], cols["PRESSED_BORDER_RGB"], cols["TEXT_RGB"]),
            "states": {
                "selected": "button index == selected tool index",
                "pressed": "mouse left held and mouse inside that button's hit box "
                           "(BTN_X0 <= mx < BTN_X0+BTN_W, y0 <= my < y0+BTN_H)",
                "hover": "no hover-only styling",
            },
        },
        "pixel_rule": "Inside the region: background; inside a button: state_colors[state][role_map[ly][lx]]; "
                      "then icon '1' pixels are drawn black on top.",
    }


# --------------------------------------------------------------------------
# keypad.json
# --------------------------------------------------------------------------

def _case_table(body: str, fn: str, conv, src: Source, what: str) -> tuple[dict[int, object], object]:
    table, default = {}, None
    for m in re.finditer(r"(?<![\w'])((?:\d+\s*,\s*)*\d+|default)\s*:\s*%s\s*=\s*([^;]+);" % fn, body):
        val = conv(m.group(2).strip())
        if m.group(1) == "default":
            default = val
        else:
            for k in m.group(1).split(","):
                table[int(k)] = val
    if not table:
        fail(f"{src.rel}: {what}: no entries")
    return table, default


def extract_keypad(kb: Source, btn: Source, top: Source, glyphs: dict) -> dict:
    tl = parse_localparams(top, ["SCREEN_W", "SCREEN_H", "RIGHT_BAR_W", "BOTTOM_BAR_H", "KEYBOARD_SCALE",
                                 "KEY_W", "KEY_H", "KEYBOARD_X", "KEYBOARD_Y", "KEYBOARD_W", "KEYBOARD_H"])
    defaults = parse_module_params(kb, "KeyboardVGA")
    overrides, _ = parse_instance(top, "KeyboardVGA", "keyboard_vga_inst")
    p = resolve_params(defaults, overrides, tl, "keyboard_vga_inst")
    lp = parse_localparams(kb, ["TOTAL_KEYS", "KEYBOARD_W", "KEYBOARD_H", "BORDER", "EDGE_THICK", "MARKER_OFFSET",
                                "MARKER_W", "MARKER_H", "FONT5_SCALE", "FONT3_SCALE", "ACTION_GAP", "DEL_W", "RST_W",
                                "PANEL_BORDER"], env=p)
    rgb = {}
    for m in re.finditer(r"\b(RGB_\w+)\s*=\s*24'h([0-9A-Fa-f]{6})", kb.text):
        rgb[m.group(1)] = int(m.group(2), 16)
        kb.record("colour palette", m.start(), m.end())
    for need in ("RGB_BG", "RGB_BORDER", "RGB_SELECTED_BORDER", "RGB_SELECTED_MARKER", "RGB_PRESSED_BORDER",
                 "RGB_TEXT", "RGB_NONE"):
        if need not in rgb:
            fail(f"{KEYBOARD}: colour {need} not found")

    def ch(v):
        m = re.fullmatch(r'"(.)"', v)
        if m:
            return m.group(1)
        return chr(parse_literal(v)[1])

    def fbody(name):
        return kb.function(name)[0]

    colors_t, colors_d = _case_table(fbody("key_color_for_id"), "key_color_for_id", lambda v: v, kb, "key colours")
    ascii_t, _ = _case_table(fbody("key_ascii_for_id"), "key_ascii_for_id", ch, kb, "key ascii")
    l0, _ = _case_table(fbody("label0_for_id"), "label0_for_id", ch, kb, "label0")
    l1, _ = _case_table(fbody("label1_for_id"), "label1_for_id", ch, kb, "label1")
    l2, _ = _case_table(fbody("label2_for_id"), "label2_for_id", ch, kb, "label2")
    tc, tcd = _case_table(fbody("text_cols_for_id"), "text_cols_for_id", int, kb, "text cols")
    st, std = _case_table(fbody("small_text_for_id"), "small_text_for_id", lambda v: parse_literal(v)[1], kb, "small")
    env = dict(p)
    env.update(lp)
    x0_t, x0_d = _case_table(fbody("button_x0_for_id"), "button_x0_for_id", lambda v: v, kb, "x0")
    w_t, w_d = _case_table(fbody("button_w_for_id"), "button_w_for_id", lambda v: v, kb, "w")
    for name, need in (("digit", "key_is_digit_for_id"), ("unit", "key_is_unit_for_id"),
                       ("action", "key_is_action_for_id")):
        fbody(need)
    kb.require(".Y0(KEYBOARD_Y0 + ((i / COLS) * KEY_H))", "button Y0", label="ButtonVGA instances")
    kb.require(".enabled(i < KEY_COUNT)", "enabled", label="ButtonVGA instances")
    kb.require(".selected(active_key_valid && (active_key_id == i[4:0]))", "selected", label="ButtonVGA instances")
    kb.require(".pressed(active_key_valid && (active_key_id == i[4:0]) && active_pressed)", "pressed",
               label="ButtonVGA instances")
    kb.require("pixel_rgb = rgb888_to_444(RGB_BG);", "background", label="pixel mux")

    kinds = {"RGB_DIGIT": "digit", "RGB_UNIT": "unit", "RGB_DOT": "dot", "RGB_DEL": "delete", "RGB_RST": "reset"}
    keys = []
    for i in range(lp["TOTAL_KEYS"]):
        enabled = i < p["KEY_COUNT"]
        e = dict(env, idx=i)
        x0 = eval_int(x0_t.get(i, x0_d), e, f"button_x0_for_id({i})")
        w = eval_int(w_t.get(i, w_d), e, f"button_w_for_id({i})")
        y0 = p["KEYBOARD_Y0"] + (i // p["COLS"]) * p["KEY_H"]
        cname = colors_t.get(i, colors_d)
        if cname not in rgb:
            fail(f"{KEYBOARD}: key {i} colour {cname} unknown")
        labels = [l0.get(i, "\0"), l1.get(i, "\0"), l2.get(i, "\0")]
        cols = tc.get(i, tcd)
        small = st.get(i, std)
        key = {"id": i, "enabled": enabled, "x0": x0, "y0": y0, "w": w, "h": p["KEY_H"],
               "label": "".join(c for c in labels if c != "\0"),
               "ascii": ord(ascii_t[i]) if i in ascii_t else 0,
               "kind": kinds.get(cname, "none"), "face_rtl_color": cname}
        if enabled:
            key["text_cols"] = cols
            key["small_text"] = bool(small)
            key["role_map"] = button_role_map(w, p["KEY_H"], lp["BORDER"], lp["EDGE_THICK"], lp["MARKER_OFFSET"],
                                              lp["MARKER_W"], lp["MARKER_H"], cols, small, lp["FONT5_SCALE"],
                                              lp["FONT3_SCALE"], labels, glyphs)
            key["state_colors"] = button_colors(rgb[cname], rgb["RGB_BORDER"], rgb["RGB_SELECTED_BORDER"],
                                                rgb["RGB_SELECTED_MARKER"], rgb["RGB_PRESSED_BORDER"], rgb["RGB_TEXT"])
        keys.append(key)

    return {
        "schema": "metacircuit-assets/keypad",
        "schema_version": SCHEMA_VERSION,
        "source": source_block([kb, btn, top]),
        "region": {"x0": p["KEYBOARD_X0"], "y0": p["KEYBOARD_Y0"], "w": lp["KEYBOARD_W"], "h": lp["KEYBOARD_H"],
                   "top_level_region": [tl["KEYBOARD_X"], tl["KEYBOARD_Y"], tl["KEYBOARD_X"] + tl["KEYBOARD_W"],
                                        tl["KEYBOARD_Y"] + tl["KEYBOARD_H"]],
                   "background": color(rgb888_to_444(rgb["RGB_BG"]), rgb["RGB_BG"])},
        "parameters": {k: p[k] for k in defaults},
        "instance_overrides": overrides,
        "derived": {k: lp[k] for k in ("DEL_W", "RST_W", "ACTION_GAP", "BORDER", "EDGE_THICK", "MARKER_OFFSET",
                                       "MARKER_W", "MARKER_H", "FONT5_SCALE")},
        "rtl_colors": {k: f"#{v:06X}" for k, v in sorted(rgb.items())},
        "keys": keys,
        "role_legend": ROLE_LEGEND,
        "states": {
            "selected": "mouse is over the key (hover); uses the nav-clock mouse",
            "pressed": "mouse is over the key and the left button is held",
        },
        "glyph_format": "glyphs[name][char] is a list of rows (top first) of '0'/'1', char 0 leftmost; drawn "
                        "scaled by FONT5_SCALE (5x7) or FONT3_SCALE (3x5); already rendered into role_map 'X'",
        "glyphs": glyphs,
        "pixel_rule": "Inside the region: background; inside an enabled key: key.state_colors[state][role_map[ly][lx]] "
                      "(later keys win on overlap; keys do not overlap here).",
    }


# --------------------------------------------------------------------------
# cursor.json
# --------------------------------------------------------------------------

def extract_cursor(md: Source) -> dict:
    tables = {}
    for fn in ("hover_row", "pressed_row", "pressed_fill_row", "fill_row"):
        body, off = md.block(fn, r"\bfunction\s+%s\s*\(\s*row_idx\s*:\s*integer\s*\)\s*return\s+std_logic_vector\s+is" % fn,
                             r"end\s+function", f"function {fn}")
        rows, other = {}, None
        for m in re.finditer(r"\bwhen\s+(\d+|others)\s*=>\s*return\s+\"([01]+)\"\s*;", body):
            if len(m.group(2)) != 28:
                fail(f"{MOUSE_VHD}: {fn} row {m.group(1)} is {len(m.group(2))} bits, expected 28")
            if m.group(1) == "others":
                other = m.group(2)
            else:
                rows[int(m.group(1))] = m.group(2)
        if other is None or not rows:
            fail(f"{MOUSE_VHD}: {fn}: rows or 'others' not found")
        tables[fn] = [rows.get(r, other) for r in range(28)]

    m = md.search(r"constant\s+CURSOR_SIZE\s*:\s*std_logic_vector\s*\(\s*11\s+downto\s+0\s*\)\s*:=\s*"
                  r"conv_std_logic_vector\s*\(\s*(\d+)\s*,\s*12\s*\)\s*;", "CURSOR_SIZE")
    md.record("CURSOR_SIZE", m.start(), m.end())
    size = int(m.group(1))
    if size != 28:
        fail(f"{MOUSE_VHD}: CURSOR_SIZE is {size}, expected 28")
    for code, what in [
        ("xdiff <= temp_diff(4 downto 0);", "xdiff is 5 bits"),
        ("ydiff <= temp_diff(4 downto 0);", "ydiff is 5 bits"),
        ("if(x_idx < 28 and y_idx < 28) then", "lookup bounds"),
        ("row_bits := pressed_row(y_idx);", "pressed outline"),
        ("row_bits := hover_row(y_idx);", "hover outline"),
        ("if(row_bits(27 - x_idx) = '1') then mousepixel <= \"00\";", "outline wins, MSB-first"),
        ("elsif(fill_bits(27 - x_idx) = '1' or (mouse_left = '1' and pressed_fill_bits(27 - x_idx) = '1')) then "
         "mousepixel <= \"01\";", "fill = fill_row OR (pressed AND pressed_fill_row)"),
        ("if(hcount >= xpos and hcount < (xpos + CURSOR_SIZE) and vcount >= ypos and vcount < (ypos + CURSOR_SIZE) and "
         "(mousepixel = \"00\" or mousepixel = \"01\")) then enable_mouse_display <= '1';", "enable register"),
        ("if(mousepixel = \"01\") then red_out <= (others => '1'); green_out <= (others => '1'); "
         "blue_out <= (others => '1'); elsif(mousepixel = \"00\") then red_out <= (others => '0'); "
         "green_out <= (others => '0'); blue_out <= (others => '0');", "colours"),
    ]:
        md.require(code, what, label=f"render: {what}")
    if not re.search(r"if\s*\(\s*enable_mouse_display\s*=\s*'1'\s*\)\s*then\s*if\s*\(\s*mousepixel", md.text):
        fail(f"{MOUSE_VHD}: colour register is no longer gated by enable_mouse_display")

    def compose(outline, fill_layers):
        out = []
        for r in range(28):
            row = []
            for c in range(28):
                if outline[r][c] == "1":
                    row.append("O")
                elif any(f[r][c] == "1" for f in fill_layers):
                    row.append("F")
                else:
                    row.append(".")
            out.append("".join(row))
        return out

    hover = compose(tables["hover_row"], [tables["fill_row"]])
    pressed = compose(tables["pressed_row"], [tables["fill_row"], tables["pressed_fill_row"]])

    def runs(sprite):
        """Visible horizontal runs in scan order: (row, first col, last col). Column 27 is never shown."""
        out = []
        for r, row in enumerate(sprite):
            c = 0
            while c < 27:
                if row[c] == ".":
                    c += 1
                    continue
                a = c
                while c + 1 < 27 and row[c + 1] != ".":
                    c += 1
                out.append((r, a, c))
                c += 1
        return out

    def as_displayed(sprite, prev_sprite):
        """Applies the colour-hold quirk: the first pixel of each run shows the colour register's held value,
        which is the last pixel of the previous run in scan order (for the first run: the last run of the
        sprite drawn in the previous frame)."""
        rows = [list(r) for r in sprite]
        rs = runs(sprite)
        pr, _, pc = runs(prev_sprite)[-1]
        held = prev_sprite[pr][pc]
        changed = []
        for r, a, b in rs:
            if rows[r][a] != held:
                changed.append([r, a])
                rows[r][a] = held
            held = sprite[r][b]
        return ["".join(r) for r in rows], changed

    disp_hover, ch_hover = as_displayed(hover, hover)
    disp_pressed, ch_pressed = as_displayed(pressed, pressed)
    for a, b in ((hover, pressed), (pressed, hover)):
        if as_displayed(a, b)[0] != as_displayed(a, a)[0]:
            fail(f"{MOUSE_VHD}: displayed cursor depends on the previous frame's sprite; extend the extractor")

    last_col_used = [name for name, s in (("hover", hover), ("pressed", pressed)) if any(row[27] != "." for row in s)]

    return {
        "schema": "metacircuit-assets/cursor",
        "schema_version": SCHEMA_VERSION,
        "source": source_block([md]),
        "cross_check": "The four tables and the pixel/enable/colour logic were compared with the SV port used in "
                       "simulation (framescope examples/metacircuit/stubs/MouseDisplay.sv) when this extractor was "
                       "written: identical. The extractor itself reads only the VHDL.",
        "size": size,
        "sprite_format": {
            "rows": "rows[r] is cursor row r (r = 0 top)",
            "chars": "'O' outline, 'F' fill, '.' transparent; char c (0 = leftmost) is bit (27 - c) of the RTL row",
            "raw_chars": "raw tables: '1'/'0', same order (char c = bit 27 - c)",
        },
        "colors": {"O": color(0x000), "F": color(0xFFF)},
        "sprites": {"hover": hover, "pressed": pressed},
        "sprites_as_displayed": {"hover": disp_hover, "pressed": disp_pressed},
        "as_displayed_changes": {"hover": ch_hover, "pressed": ch_pressed,
                                 "format": "[row, col] pixels where sprites_as_displayed differs from sprites"},
        "sprite_selection": "pressed while the (frame-latched) left mouse button is held, else hover",
        "raw_tables": {
            "hover_outline": tables["hover_row"], "pressed_outline": tables["pressed_row"],
            "fill": tables["fill_row"], "pressed_fill": tables["pressed_fill_row"],
            "composition": "outline (hover_outline or pressed_outline) wins; else fill, or pressed_fill when "
                           "pressed (so pressed fill = fill OR pressed_fill); else transparent",
        },
        "placement": {
            "screen_x": "mouse_x + c + 2",
            "screen_y": "mouse_y + r",
            "sprite_origin_offset": [2, 0],
            "sprite_origin_offset_meaning": "sprite pixel (c=0, r=0) is drawn at (mouse_x + 2, mouse_y)",
            "visible_columns": [0, 26],
            "note": "Screen coordinates are VGA x_pos/y_pos (= framescope PNG pixels with de_delay = 2). The +2 "
                    "comes from MouseDisplay's two pixel-clock register stages (mousepixel, then "
                    "enable_mouse_display) that the rest of the screen does not have; the range check is made on "
                    "the delayed hcount, so sprite column 27 is never shown (no sprite uses it: "
                    f"{'columns used: ' + ', '.join(last_col_used) if last_col_used else 'verified empty'}). "
                    "Rows have no offset. The cursor is drawn above every other layer.",
            "colour_hold_quirk": "The colour register is updated only while the previous pixel was enabled, so "
                                 "the first pixel of each horizontal run shows the colour held from the last pixel "
                                 "of the previous run in scan order (for the first run of a frame: the last run of "
                                 "the previous frame's cursor; both sprites end in an outline pixel, so this does "
                                 "not depend on the previous sprite). sprites_as_displayed has this applied and is "
                                 "what the RTL actually shows (verified against framescope frames); the very first "
                                 "frame after reset is the exception (uninitialised register).",
        },
    }


# --------------------------------------------------------------------------
# screen.json (top-level composition constants) and font8x8.json
# --------------------------------------------------------------------------

def extract_screen(top: Source, pp: Source) -> dict:
    tl = parse_localparams(top, ["BLACK", "BACKGROUND", "SCREEN_W", "SCREEN_H", "TOP_BAR_H", "LEFT_BAR_W",
                                 "RIGHT_BAR_W", "BOTTOM_BAR_H", "PROP_PANEL_X", "PROP_PANEL_Y", "PROP_PANEL_W",
                                 "PROP_PANEL_H", "ENABLE_PROP_PANEL", "ENABLE_WAVEFORMS"])
    blk, off = top.block("ui_rgb composition", r"always\s*@\s*\(\s*\*\s*\)\s*begin\s*ui_rgb\s*=\s*BACKGROUND\s*;",
                         r"end\s*always|endmodule|always", "ui_rgb always block")
    for code, what in [
        ("top_bar_active = (y_pos < TOP_BAR_H);", "top bar"),
        ("left_bar_active = (x_pos < LEFT_BAR_W) && (y_pos >= TOP_BAR_H) && (y_pos < (SCREEN_H - BOTTOM_BAR_H));", "left bar"),
        ("right_bar_active = (x_pos >= (SCREEN_W - RIGHT_BAR_W)) && (y_pos >= TOP_BAR_H);", "right bar"),
        ("grid_line_active = ((x_pos[4:0] == 5'd0) || (y_pos[4:0] == 5'd0));", "grid lines"),
        ("if (toolbar_rendered) ui_rgb = toolbar_rgb;", "toolbar over left bar"),
        ("if (frame_active) ui_rgb = 12'hFFF;", "right bar frames"),
    ]:
        top.require(code, what, within=blk)
    parts = re.split(r"end\s+else\s+if\s*\(\s*(left_bar_active|right_bar_active)\s*\)", blk)
    if len(parts) != 5:
        fail(f"{GLOBAL_RENDER}: ui_rgb block no longer has top/left/right bar branches")
    sections = {"top_bar": parts[0], "left_bar": parts[2], "right_bar": parts[4]}
    bars = {}
    for name, text in sections.items():
        lits = [int(x, 16) for x in re.findall(r"rgb888_to_444\s*\(\s*24'h([0-9A-Fa-f]{6})\s*\)", text)]
        expect = 3 if name == "top_bar" else 2
        if len(lits) != expect:
            fail(f"{GLOBAL_RENDER}: {name}: expected {expect} colours, found {len(lits)}")
        bars[name] = {"fill": color(rgb888_to_444(lits[0]), lits[0]),
                      "grid_line": color(rgb888_to_444(lits[1]), lits[1])}
        if name == "top_bar":
            bars[name]["boxes"] = [[int(a), int(b), int(c), int(d)] for a, b, c, d in re.findall(
                r"x_pos\s*>=\s*(\d+)\s*&&\s*x_pos\s*<\s*(\d+)\s*&&\s*y_pos\s*>=\s*(\d+)\s*&&\s*y_pos\s*<\s*(\d+)", text)]
            if len(bars[name]["boxes"]) != 4:
                fail(f"{GLOBAL_RENDER}: top bar: expected 4 box rectangles")
            bars[name]["box_fill"] = color(rgb888_to_444(lits[2]), lits[2])
            bars[name]["boxes_format"] = "[x0, x1, y0, y1], half-open"
    fm = re.search(r"if\s*\(\s*\(\s*\(x_pos\s*>=\s*(\d+)\s*&&\s*x_pos\s*<\s*(\d+)\s*\)\s*&&\s*\(\s*\(y_pos\s*>=\s*(\d+)\s*&&\s*y_pos\s*<\s*(\d+)\)"
                   r"\s*\|\|\s*\(y_pos\s*>=\s*(\d+)\s*&&\s*y_pos\s*<\s*(\d+)\)\s*\|\|\s*\(y_pos\s*>=\s*(\d+)\s*&&\s*y_pos\s*<\s*(\d+)\)\s*\)\s*\)\s*\)",
                   sections["right_bar"])
    if not fm:
        fail(f"{GLOBAL_RENDER}: right bar frame rectangles changed shape")
    v = [int(x) for x in fm.groups()]
    bars["right_bar"]["frames"] = {
        "rects": [[v[0], v[1], v[2], v[3]], [v[0], v[1], v[4], v[5]], [v[0], v[1], v[6], v[7]]],
        "rects_format": "[x0, x1, y0, y1], half-open; only an outline is drawn",
        "outline_rule_rtl": " ".join(re.search(r"if\s*\(\s*\(x_pos\s*<\s*\d+\).*?\)\s*begin", sections["right_bar"], re.S)
                                     .group(0).split()),
        "color": color(0xFFF),
    }

    mux = top.search(r"always\s*@\s*\(\s*posedge\s+clk_pixel\s*\)\s*begin\s*if\s*\(\s*!video_on\s*\)\s*begin\s*rgb\s*<=\s*BLACK\s*;"
                     r"(.*?)\bend\s*end\b", "final rgb priority mux")
    top.record("final rgb mux", mux.start(), mux.end())
    order = ["!video_on"] + re.findall(r"else\s+if\s*\(\s*([^)]*?)\s*\)\s*begin", mux.group(1))
    expected = ["!video_on", "mouse_display_enable", "keyboard_region_active", "circuit_canvas_rendered",
                "dynamic_wave_active", "prop_panel_rendered && video_on"]
    if order != expected:
        fail(f"{GLOBAL_RENDER}: final rgb mux order changed: {order}")

    ppc = {}
    for m in re.finditer(r"\blocalparam\s*\[\s*11\s*:\s*0\s*\]\s*(COLOR_\w+)\s*=\s*12'h([0-9A-Fa-f]{3})\s*;", pp.text):
        ppc[m.group(1)] = color(int(m.group(2), 16))
        pp.record("colour constants", m.start(), m.end())
    if "COLOR_BG" not in ppc:
        fail(f"{PROP_PANEL}: COLOR_BG not found")

    return {
        "schema": "metacircuit-assets/screen",
        "schema_version": SCHEMA_VERSION,
        "source": source_block([top, pp]),
        "screen": {"w": tl["SCREEN_W"], "h": tl["SCREEN_H"]},
        "background": color(tl["BACKGROUND"]),
        "blanking": color(tl["BLACK"]),
        "bars": {
            "top_bar": {"region": "y < %d" % tl["TOP_BAR_H"], **bars["top_bar"]},
            "left_bar": {"region": "x < %d and %d <= y < %d" % (tl["LEFT_BAR_W"], tl["TOP_BAR_H"],
                                                               tl["SCREEN_H"] - tl["BOTTOM_BAR_H"]),
                         **bars["left_bar"], "note": "the toolbar (toolbar.json) covers this whole region"},
            "right_bar": {"region": "x >= %d and y >= %d" % (tl["SCREEN_W"] - tl["RIGHT_BAR_W"], tl["TOP_BAR_H"]),
                          **bars["right_bar"]},
        },
        "grid_line_rule": "x mod 32 == 0 or y mod 32 == 0 (screen coordinates), inside a bar",
        "ui_rule": "background; top bar fill, grid lines, then boxes; left bar fill, grid lines, then toolbar; right "
                   "bar fill, grid lines, then frame outlines",
        "layer_priority": [
            "blanking (outside the visible area)", "cursor (cursor.json)", "keypad region (keypad.json)",
            "canvas region (canvas.json)", "waveforms (ENABLE_WAVEFORMS=%d)" % tl["ENABLE_WAVEFORMS"],
            "property panel (ENABLE_PROP_PANEL=%d; covers %dx%d at (%d,%d))" % (
                tl["ENABLE_PROP_PANEL"], tl["PROP_PANEL_W"], tl["PROP_PANEL_H"], tl["PROP_PANEL_X"], tl["PROP_PANEL_Y"]),
            "ui (bars and background, above)",
        ],
        "property_panel_colors": ppc,
        "property_panel_note": "The property panel (ComponentPropertyPanel.v, text via DynamicTextBox/FontROM) is "
                               "dynamic content; only its colour constants are extracted here.",
    }


def extract_font(fr: Source) -> dict:
    m = fr.search(r"\bcase\s*\(\s*char_addr\s*\)(.*)\bendcase\s*end\s*endmodule", "FontROM case")
    body = m.group(1)
    fr.record("glyph table", m.start(), m.end())
    glyphs = {}
    for gm in re.finditer(r"7'd(\d+)\s*:\s*(?:case\s*\(\s*row\s*\)(.*?)\bendcase|pixel_data\s*=\s*([^;]+);)", body, re.S):
        code = int(gm.group(1))
        if code in glyphs:
            fail(f"{FONT_ROM}: glyph {code} defined twice")
        if gm.group(3) is not None:
            w, v = parse_literal(gm.group(3), fr, None, f"glyph {code}")
            glyphs[code] = [bits(v, 8)] * 8
            continue
        rows, default = {}, None
        for rm in re.finditer(r"(?<![\w'])(\d+|default)\s*:\s*pixel_data\s*=\s*([^;]+);", gm.group(2)):
            w, v = parse_literal(rm.group(2), fr, None, f"glyph {code} row {rm.group(1)}")
            if w != 8:
                fail(f"{FONT_ROM}: glyph {code} row {rm.group(1)} is {w} bits")
            if rm.group(1) == "default":
                default = bits(v, 8)
            else:
                rows[int(rm.group(1))] = bits(v, 8)
        if any(r not in rows for r in range(8)) and default is None:
            fail(f"{FONT_ROM}: glyph {code} is missing rows and has no default")
        glyphs[code] = [rows.get(r, default) for r in range(8)]
    if sorted(glyphs) != list(range(95)):
        fail(f"{FONT_ROM}: expected glyphs 0..94, got {len(glyphs)}")
    return {
        "schema": "metacircuit-assets/font8x8",
        "schema_version": SCHEMA_VERSION,
        "source": source_block([fr]),
        "format": "glyphs[ascii] = 8 rows (top first) of 8 chars '0'/'1'; char c (0 = leftmost) is bit (7 - c) "
                  "of the ROM byte (DynamicTextBox draws pixel_row[7 - font_col]). Keys are ASCII codes 32..126 "
                  "(ROM address = ascii - 32). Used by the property panel text, not by the keypad.",
        "glyphs": {str(code + 32): glyphs[code] for code in range(95)},
    }


# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------

def build_all() -> dict[str, str]:
    LITERAL_NOTES.clear()
    cc, top, tb, btn, kb, md, fr, pp = (Source(p) for p in (CIRCUIT_CANVAS, GLOBAL_RENDER, TOOLBAR, BUTTON, KEYBOARD,
                                                            MOUSE_VHD, FONT_ROM, PROP_PANEL))
    glyphs = check_button_source(btn)
    # Build in dependency-free order; each extractor records the line ranges it read.
    canvas = extract_canvas(cc, top)
    toolbar = extract_toolbar(tb, btn, top, glyphs)
    keypad = extract_keypad(kb, btn, top, glyphs)
    cursor = extract_cursor(md)
    screen = extract_screen(top, pp)
    font = extract_font(fr)
    # Source blocks were captured when each extractor finished; refresh them so every file lists the
    # complete, final line ranges of shared sources (GlobalRender_top, ButtonVGA).
    canvas["source"] = source_block([cc, top])
    toolbar["source"] = source_block([tb, btn, top])
    keypad["source"] = source_block([kb, btn, top])
    cursor["source"] = source_block([md])
    screen["source"] = source_block([top, pp])
    font["source"] = source_block([fr])
    for obj in (canvas, toolbar, keypad, cursor, screen, font):
        files = {f["path"] for f in obj["source"]["files"]}
        obj["rtl_literal_notes"] = [n for n in LITERAL_NOTES if n["file"] in files]
    out = {}
    for name, obj in (("canvas.json", canvas), ("toolbar.json", toolbar), ("keypad.json", keypad),
                      ("cursor.json", cursor), ("screen.json", screen), ("font8x8.json", font)):
        out[name] = json.dumps(obj, indent=2, ensure_ascii=True) + "\n"
    return out


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT, help="output directory (default golden/assets)")
    ap.add_argument("--check", action="store_true", help="do not write; exit 1 if the files in --out are stale")
    args = ap.parse_args(argv)
    try:
        files = build_all()
    except ExtractError as exc:
        print(f"extract_assets: ERROR: {exc}", file=sys.stderr)
        print("extract_assets: the RTL no longer matches what the extractor expects; nothing was written.",
              file=sys.stderr)
        return 2
    if args.check:
        stale = [n for n, txt in files.items()
                 if not (args.out / n).is_file() or (args.out / n).read_text() != txt]
        for n in stale:
            print(f"extract_assets: stale: {args.out / n}", file=sys.stderr)
        return 1 if stale else 0
    args.out.mkdir(parents=True, exist_ok=True)
    for name, txt in files.items():
        path = args.out / name
        shown = path.relative_to(REPO) if path.is_relative_to(REPO) else path
        if not path.is_file() or path.read_text() != txt:
            path.write_text(txt)
            print(f"wrote {shown}")
        else:
            print(f"unchanged {shown}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
