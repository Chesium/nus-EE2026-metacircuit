import json
import tempfile
import unittest
from pathlib import Path

from helpers import write

from framescope import FramescopeError, png
from framescope.compare import compare_images, compare_paths, load_masks, parse_masks, parse_tolerance
from framescope.png import Image

W, H = 64, 48
GREY = (100, 100, 100)


def _image(fill=GREY, dots=()):
    rows = [bytearray(bytes(fill) * W) for _ in range(H)]
    for x, y, rgb in dots:
        rows[y][3 * x : 3 * x + 3] = bytes(rgb)
    return Image(W, H, [bytes(r) for r in rows])


def _block(x0, y0, w, h, rgb=(255, 0, 0)):
    return [(x, y, rgb) for y in range(y0, y0 + h) for x in range(x0, x0 + w)]


class MaskParsingTest(unittest.TestCase):
    def test_toml_and_json(self):
        with tempfile.TemporaryDirectory() as tmp:
            t = write(Path(tmp) / "m.toml", """
tolerance = [1, 2, 3]
[[region]]
name = "canvas"
mode = "include"
rect = [8, 8, 40, 30]
[[region]]
name = "anim"
mode = "exclude"
rects = [[0, 0, 4, 4], { x = 10, y = 10, w = 2, h = 2 }]
""")
            m = load_masks(t)
            self.assertEqual(m.tolerance, (1, 2, 3))
            self.assertEqual([(r.name, r.mode, len(r.rects)) for r in m.regions],
                             [("canvas", "include", 1), ("anim", "exclude", 2)])
            self.assertEqual(m.regions[1].rects[1].w, 2)
            self.assertEqual(m.path, t.resolve())
            j = write(Path(tmp) / "m.json", json.dumps({"region": [{"name": "a", "mode": "report", "rect": [0, 0, 1, 1]}]}))
            self.assertEqual(load_masks(j).regions[0].mode, "report")

    def test_errors(self):
        cases = [
            ({"region": [{"name": "a", "rect": [0, 0, 1, 1]}]}, "mode must be one of"),
            ({"region": [{"name": "a", "mode": "include"}]}, "exactly one of rect / rects"),
            ({"region": [{"name": "a", "mode": "include", "rect": [0, 0, 0, 1]}]}, "w, h > 0"),
            ({"region": [{"name": "a", "mode": "include", "rect": [0, 0, 1]}]}, r"\[x, y, w, h\]"),
            ({"region": [{"name": "a", "mode": "exclude", "rect": [0, 0, 1, 1]}] * 2}, "duplicate"),
            ({"region": [{"name": "a", "mode": "exclude", "rect": [0, 0, 1, 1], "colour": 1}]}, "unknown key"),
            ({"regoin": []}, "unknown key"),
            ({"tolerance": 300}, "0..255"),
        ]
        for data, msg in cases:
            with self.assertRaisesRegex(FramescopeError, msg, msg=str(data)):
                parse_masks(data)

    def test_tolerance_strings(self):
        self.assertEqual(parse_tolerance("2"), (2, 2, 2))
        self.assertEqual(parse_tolerance("1,2,3"), (1, 2, 3))
        with self.assertRaises(FramescopeError):
            parse_tolerance("1,2")


class CompareImagesTest(unittest.TestCase):
    def test_identical(self):
        r = compare_images(_image(), _image())
        self.assertTrue(r["ok"] and r["identical"])
        self.assertEqual((r["diff_pixels"], r["bbox"], r["components"]), (0, None, []))
        self.assertEqual(r["compared_pixels"], W * H)

    def test_counts_bbox_components_and_samples(self):
        dots = _block(5, 5, 3, 2) + _block(30, 20, 1, 1, (0, 255, 0)) + [(31, 21, (0, 255, 0))]  # diagonal: 8-connected
        r = compare_images(_image(dots=dots), _image())
        self.assertFalse(r["ok"])
        self.assertEqual(r["diff_pixels"], 8)
        self.assertEqual(r["bbox"], {"x": 5, "y": 5, "w": 27, "h": 17})
        self.assertEqual(r["components_total"], 2)
        big, small = r["components"]
        self.assertEqual((big["bbox"], big["pixels"]), ({"x": 5, "y": 5, "w": 3, "h": 2}, 6))
        self.assertEqual(big["sample"], {"x": 5, "y": 5, "actual": "#ff0000", "reference": "#646464"})
        self.assertEqual((small["bbox"], small["pixels"]), ({"x": 30, "y": 20, "w": 2, "h": 2}, 2))

    def test_max_boxes_caps_components(self):
        dots = [(x, 10, (0, 0, 0)) for x in range(0, 40, 2)]
        r = compare_images(_image(dots=dots), _image(), max_boxes=3)
        self.assertEqual((len(r["components"]), r["components_total"]), (3, 20))

    def test_masks_include_exclude_report(self):
        masks = parse_masks({"region": [
            {"name": "canvas", "mode": "include", "rect": [0, 0, 32, 48]},
            {"name": "anim", "mode": "exclude", "rect": [10, 10, 5, 5]},
            {"name": "corner", "mode": "report", "rect": [0, 0, 8, 8]},
        ]})
        # one diff in the excluded box, one right of the canvas, one in the corner
        dots = [(12, 12, (0, 0, 0)), (40, 40, (0, 0, 0)), (2, 3, (0, 0, 0))]
        r = compare_images(_image(dots=dots), _image(), masks)
        self.assertFalse(r["ok"])
        self.assertFalse(r["identical"])
        self.assertEqual((r["diff_pixels"], r["ignored_diff_pixels"]), (1, 2))
        self.assertEqual(r["compared_pixels"], 32 * 48 - 25)
        self.assertEqual(r["regions"]["anim"], {"mode": "exclude", "pixels": 25, "diff_pixels": 1,
                                                "bbox": {"x": 12, "y": 12, "w": 1, "h": 1}})
        self.assertEqual(r["regions"]["canvas"]["diff_pixels"], 1)
        self.assertEqual(r["regions"]["corner"]["diff_pixels"], 1)

        r = compare_images(_image(dots=dots[:2]), _image(), masks)
        self.assertTrue(r["ok"])  # only ignored differences
        self.assertFalse(r["identical"])

    def test_tolerance(self):
        a = _image(dots=[(1, 1, (102, 100, 100)), (2, 2, (100, 100, 97))])
        self.assertEqual(compare_images(a, _image(), tolerance=(2, 0, 0))["diff_pixels"], 1)
        self.assertTrue(compare_images(a, _image(), tolerance=(2, 0, 3))["ok"])
        masks = parse_masks({"tolerance": 3})
        self.assertTrue(compare_images(a, _image(), masks)["ok"])
        self.assertFalse(compare_images(a, _image(), masks, tolerance=(0, 0, 0))["ok"])

    def test_size_mismatch(self):
        r = compare_images(_image(), Image.new(W, H + 1))
        self.assertFalse(r["ok"])
        self.assertIn("size mismatch", r["error"])

    def test_diff_png(self):
        masks = parse_masks({"region": [{"name": "anim", "mode": "exclude", "rect": [40, 0, 24, 48]}]})
        a = _image(dots=_block(10, 10, 2, 2) + [(50, 5, (0, 0, 0))])
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "d" / "x.diff.png"
            r = compare_images(a, _image(), masks, diff_png=out)
            self.assertEqual(r["diff_png"], str(out))
            d = png.read(out)
        self.assertEqual(d.pixel(10, 10), (255, 0, 255))      # compared difference
        self.assertEqual(d.pixel(50, 5), (0, 140, 140))       # ignored difference
        self.assertEqual(d.pixel(9, 9), (255, 255, 0))        # box outline
        self.assertEqual(d.pixel(30, 30), (30, 30, 30))       # compared area dimmed
        self.assertEqual(d.pixel(60, 30), (10, 10, 10))       # excluded area dimmed more


class ComparePathsTest(unittest.TestCase):
    def test_directories(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            run, ref = root / "run", root / "ref"
            png.write(run / "vga" / "frame_0000.png", _image())
            png.write(run / "vga" / "frame_0001.png", _image(dots=[(3, 4, (0, 0, 0))]))
            png.write(run / "vga" / "frame_0002.png", _image())
            png.write(ref / "vga" / "frame_0000.png", _image())  # same relative path
            png.write(ref / "frame_0001.png", _image())          # flat: matched by unique file name
            png.write(ref / "frame_0009.png", _image())          # no actual frame
            write(ref / "masks.toml", '[[region]]\nname = "top"\nmode = "report"\nrect = [0, 0, 64, 8]\n')

            r = compare_paths(run, ref)
            self.assertFalse(r["ok"])
            self.assertEqual(r["masks"], str((ref / "masks.toml").resolve()))
            frames = {f["name"]: f for f in r["frames"]}
            self.assertEqual(set(frames), {"vga/frame_0000.png", "frame_0001.png", "frame_0009.png"})
            self.assertTrue(frames["vga/frame_0000.png"]["identical"])
            f1 = frames["frame_0001.png"]
            self.assertEqual((f1["index"], f1["diff_pixels"], f1["regions"]["top"]["diff_pixels"]), (1, 1, 1))
            self.assertTrue(Path(f1["diff_png"]).is_file())
            self.assertEqual(Path(f1["diff_png"]), (run / "compare" / "frame_0001.diff.png").resolve())
            self.assertEqual(frames["frame_0009.png"]["error"], "no matching actual frame")
            s = r["summary"]
            self.assertEqual((s["frames"], s["passed"], s["failed"], s["missing"]), (3, 1, 2, 1))
            self.assertEqual(r["unmatched_actual"], 1)
            self.assertTrue((run / "compare" / "compare.json").is_file())

            # a previous run directory as the reference: its diff PNGs are skipped
            r = compare_paths(run, run, out=root / "self")
            self.assertTrue(r["ok"])
            self.assertEqual(r["summary"]["frames"], 3)

    def test_files_and_bad_inputs(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            a = png.write(root / "a.png", _image())
            b = png.write(root / "b.png", _image())
            r = compare_paths(a, b, diff=False)
            self.assertTrue(r["ok"])
            self.assertFalse((root / "compare").exists())
            with self.assertRaisesRegex(FramescopeError, "two PNG files or two directories"):
                compare_paths(a, root)
            with self.assertRaisesRegex(FramescopeError, "not found"):
                compare_paths(root / "nope.png", b)
            (root / "bad.png").write_bytes(b"nope")
            r = compare_paths(a, root / "bad.png")
            self.assertFalse(r["ok"])
            self.assertIn("not a PNG", r["frames"][0]["error"])


if __name__ == "__main__":
    unittest.main()
