#!/usr/bin/env python3
"""Tests for extract_assets.py and the committed golden/assets JSON.

Run from the repository root:

    python3 -m unittest golden/tools/test_extract_assets.py -v
    python3 golden/tools/test_extract_assets.py
"""

from __future__ import annotations

import contextlib
import io
import json
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import extract_assets as ea  # noqa: E402

ASSETS = ea.DEFAULT_OUT
FILES = ["canvas.json", "toolbar.json", "keypad.json", "cursor.json", "screen.json", "font8x8.json"]
HEX12 = re.compile(r"0x[0-9A-F]{3}")


def load(name):
    return json.loads((ASSETS / name).read_text())


def expand(rgb12: str) -> str:
    v = int(rgb12, 16)
    return "#" + "".join(f"{((v >> s) & 0xF) * 17:02x}" for s in (8, 4, 0))


def walk_colors(obj):
    if isinstance(obj, dict):
        if "rgb12" in obj:
            yield obj
        for v in obj.values():
            yield from walk_colors(v)
    elif isinstance(obj, list):
        for v in obj:
            yield from walk_colors(v)


class Regeneration(unittest.TestCase):
    def test_byte_identical_in_memory(self):
        files = ea.build_all()
        self.assertEqual(sorted(files), sorted(FILES))
        for name, text in files.items():
            with self.subTest(file=name):
                path = ASSETS / name
                self.assertTrue(path.is_file(), f"{path} missing; run python3 golden/tools/extract_assets.py")
                self.assertEqual(path.read_text(), text,
                                 f"{name} is stale; run python3 golden/tools/extract_assets.py")

    def test_cli_writes_identical_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            r = subprocess.run([sys.executable, str(HERE / "extract_assets.py"), "--out", tmp],
                               cwd=ea.REPO, capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, r.stderr)
            for name in FILES:
                self.assertEqual((Path(tmp) / name).read_bytes(), (ASSETS / name).read_bytes(), name)

    def test_deterministic(self):
        self.assertEqual(ea.build_all(), ea.build_all())


class FailsLoudly(unittest.TestCase):
    def _with_edit(self, rel, old, new):
        real_init = ea.Source.__init__

        def patched(self_, r):
            real_init(self_, r)
            if r == rel:
                if old not in self_.text:
                    raise AssertionError(f"test setup: {old!r} not in {rel}")
                self_.text = self_.text.replace(old, new, 1)

        with mock.patch.object(ea.Source, "__init__", patched):
            with self.assertRaises(ea.ExtractError) as cm:
                ea.build_all()
        return str(cm.exception)

    def test_missing_sprite_function(self):
        msg = self._with_edit(ea.CIRCUIT_CANVAS, "function [31:0] Ground;", "function [31:0] Grnd;")
        self.assertIn("Ground", msg)

    def test_missing_sprite_row(self):
        msg = self._with_edit(ea.CIRCUIT_CANVAS, "5'd17: Wire =", "5'd99: Wire =")
        self.assertIn("Wire", msg)

    def test_changed_rotation(self):
        msg = self._with_edit(ea.CIRCUIT_CANVAS, "2'b01:   GetXX = 31 - dy;", "2'b01:   GetXX = 30 - dy;")
        self.assertIn("GetXX", msg)

    def test_changed_palette(self):
        msg = self._with_edit(ea.CIRCUIT_CANVAS, "4'd7:  palette_idx_to_rgb12", "4'd77: palette_idx_to_rgb12")
        self.assertIn("palette", msg)

    def test_changed_colour_mux(self):
        msg = self._with_edit(ea.CIRCUIT_CANVAS, "sprite_pixel_visible ? currentColorPos", "sprite_pixel ? currentColorPos")
        self.assertIn("colour mux", msg)

    def test_cli_exit_code(self):
        # A missing source file is reported with a non-zero exit and nothing written.
        with tempfile.TemporaryDirectory() as tmp, \
                mock.patch.object(ea, "CIRCUIT_CANVAS", "src/design/rendering/DoesNotExist.v"):
            err = io.StringIO()
            with contextlib.redirect_stderr(err):
                rc = ea.main(["--out", tmp])
            self.assertIn("file not found", err.getvalue())
            self.assertEqual(rc, 2)
            self.assertEqual(list(Path(tmp).iterdir()), [])


class CanvasAssets(unittest.TestCase):
    def setUp(self):
        self.c = load("canvas.json")

    def test_sprites_are_32x32_bits(self):
        self.assertEqual([s["id"] for s in self.c["sprites"]], list(range(16)))
        for s in self.c["sprites"]:
            with self.subTest(sprite=s["name"]):
                self.assertEqual(len(s["rows"]), 32)
                for row in s["rows"]:
                    self.assertRegex(row, r"^[01]{32}$")

    def test_rotations_are_bijections(self):
        codes = self.c["rotation"]["codes"]
        self.assertEqual(sorted(codes), ["0", "1", "2", "3"])
        for ro, spec in codes.items():
            with self.subTest(rotation=ro):
                seen = set()
                for dy in range(32):
                    for dx in range(32):
                        r = spec["src_row_linear"]["const"] + spec["src_row_linear"]["dx"] * dx + spec["src_row_linear"]["dy"] * dy
                        c = spec["src_col_linear"]["const"] + spec["src_col_linear"]["dx"] * dx + spec["src_col_linear"]["dy"] * dy
                        self.assertTrue(0 <= r < 32 and 0 <= c < 32)
                        seen.add((r, c))
                self.assertEqual(len(seen), 1024)

    def test_rotation_semantics(self):
        """Rotation 1 turns the horizontal Wire vertical (as seen in RTL frames)."""
        wire = next(s for s in self.c["sprites"] if s["name"] == "Wire")["rows"]
        spec = self.c["rotation"]["codes"]["1"]
        self.assertEqual(spec["description"], "rotate 90 degrees clockwise")

        def px(dx, dy):
            r = spec["src_row_linear"]
            c = spec["src_col_linear"]
            return wire[r["const"] + r["dx"] * dx + r["dy"] * dy][c["const"] + c["dx"] * dx + c["dy"] * dy]

        self.assertEqual(wire[15][0], "1")       # rotation 0: horizontal band through the middle
        self.assertEqual(px(15, 0), "1")         # rotation 1: vertical band
        self.assertEqual(px(0, 15), "0")

    def test_palette(self):
        pal = self.c["palette"]
        self.assertEqual(len(pal), 16)
        self.assertEqual([p["index"] for p in pal], list(range(16)))
        for p in pal:
            self.assertRegex(p["rgb12"], HEX12)

    def test_geometry(self):
        g = self.c["geometry"]
        self.assertEqual((g["canvas_x0"], g["canvas_y0"], g["canvas_w"], g["canvas_h"]), (64, 64, 576, 288))
        self.assertEqual((g["grid_w"], g["grid_h"], g["cell_size"]), (18, 16, 32))


class OtherAssets(unittest.TestCase):
    def test_all_colours_expand_by_nibble_replication(self):
        for name in FILES:
            for col in walk_colors(load(name)):
                with self.subTest(file=name, color=col["rgb12"]):
                    self.assertRegex(col["rgb12"], HEX12)
                    self.assertEqual(col["rgb24"], expand(col["rgb12"]))

    def test_toolbar_icons(self):
        t = load("toolbar.json")
        self.assertEqual(len(t["buttons"]), 10)
        for k, icon in t["icons"].items():
            with self.subTest(icon=k):
                self.assertEqual(len(icon["rows"]), 24)
                for row in icon["rows"]:
                    self.assertRegex(row, r"^[01]{24}$")
        role = t["button_style"]["role_map"]
        self.assertEqual(len(role), t["parameters"]["BTN_H"])
        self.assertTrue(all(len(r) == t["parameters"]["BTN_W"] for r in role))

    def test_cursor(self):
        c = load("cursor.json")
        for group in ("sprites", "sprites_as_displayed"):
            for k, s in c[group].items():
                with self.subTest(group=group, sprite=k):
                    self.assertEqual(len(s), 28)
                    for row in s:
                        self.assertRegex(row, r"^[OF.]{28}$")
                        self.assertEqual(row[27], ".")

    def test_keypad(self):
        k = load("keypad.json")
        enabled = [key for key in k["keys"] if key["enabled"]]
        self.assertEqual(len(enabled), 19)
        covered = set()
        for key in enabled:
            self.assertEqual(len(key["role_map"]), key["h"])
            self.assertTrue(all(len(r) == key["w"] for r in key["role_map"]))
            for y in range(key["y0"], key["y0"] + key["h"]):
                for x in range(key["x0"], key["x0"] + key["w"]):
                    self.assertNotIn((x, y), covered, "keys overlap")
                    covered.add((x, y))
        r = k["region"]
        self.assertEqual(len(covered), r["w"] * r["h"])

    def test_font(self):
        f = load("font8x8.json")
        self.assertEqual(sorted(map(int, f["glyphs"])), list(range(32, 127)))
        for g in f["glyphs"].values():
            self.assertEqual(len(g), 8)
            self.assertTrue(all(re.fullmatch(r"[01]{8}", r) for r in g))

    def test_source_blocks(self):
        for name in FILES:
            src = load(name)["source"]
            self.assertRegex(src["rtl_commit"], r"^[0-9a-f]{40}$")
            for f in src["files"]:
                self.assertTrue((ea.REPO / f["path"]).is_file(), f["path"])
                for rng in f["line_ranges"].values():
                    self.assertLessEqual(rng[0], rng[1])


if __name__ == "__main__":
    unittest.main()
