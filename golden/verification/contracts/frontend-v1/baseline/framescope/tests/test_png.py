import random
import struct
import tempfile
import unittest
import zlib
from pathlib import Path

from helpers import REPO  # noqa: F401  (puts src/ on sys.path)

from framescope import png


def _paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    return a if pa <= pb and pa <= pc else (b if pb <= pc else c)


def _filter(ftype: int, line: bytes, prev: bytes, bpp: int) -> bytes:
    out = bytearray(len(line))
    for i, x in enumerate(line):
        a = line[i - bpp] if i >= bpp else 0
        b = prev[i]
        c = prev[i - bpp] if i >= bpp else 0
        pred = (0, a, b, (a + b) // 2, _paeth(a, b, c))[ftype]
        out[i] = (x - pred) & 0xFF
    return bytes(out)


def _encode(width: int, height: int, colour: int, rows: list[bytes], filters=(0,), depth=8, interlace=0,
            extra: list[tuple[bytes, bytes]] = ()) -> bytes:
    """A PNG with the given raw scanlines, cycling through `filters` row by row."""
    bpp = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[colour]
    raw, prev = b"", bytes(len(rows[0]))
    for y, row in enumerate(rows):
        ftype = filters[y % len(filters)]
        raw += bytes([ftype]) + _filter(ftype, row, prev, bpp)
        prev = row
    ihdr = struct.pack(">IIBBBBB", width, height, depth, colour, 0, 0, interlace)
    body = png._chunk(b"IHDR", ihdr)
    for kind, data in extra:
        body += png._chunk(kind, data)
    return png.SIGNATURE + body + png._chunk(b"IDAT", zlib.compress(raw)) + png._chunk(b"IEND", b"")


class PngTest(unittest.TestCase):
    def setUp(self):
        rnd = random.Random(7)
        self.w, self.h = 37, 11
        self.rgb = [bytes(rnd.randrange(256) for _ in range(3 * self.w)) for _ in range(self.h)]

    def test_write_read_round_trip(self):
        img = png.Image(self.w, self.h, self.rgb)
        with tempfile.TemporaryDirectory() as tmp:
            path = png.write(Path(tmp) / "sub" / "a.png", img)
            back = png.read(path)
        self.assertEqual((back.width, back.height), (self.w, self.h))
        self.assertEqual(back.rows, self.rgb)
        self.assertEqual(back.pixel(1, 2), tuple(self.rgb[2][3:6]))

    def test_all_filter_types(self):
        for filters in [(0,), (1,), (2,), (3,), (4,), (0, 1, 2, 3, 4)]:
            data = _encode(self.w, self.h, 2, self.rgb, filters)
            self.assertEqual(png.decode(data).rows, self.rgb, filters)

    def test_rgba_grey_and_palette_convert_to_rgb(self):
        rgba = [bytes(b for i in range(self.w) for b in (*row[3 * i : 3 * i + 3], 255)) for row in self.rgb]
        self.assertEqual(png.decode(_encode(self.w, self.h, 6, rgba, (4, 1))).rows, self.rgb)

        grey = [bytes(range(y, y + 5)) for y in range(3)]
        img = png.decode(_encode(5, 3, 0, grey, (3,)))
        self.assertEqual(img.pixel(4, 2), (6, 6, 6))
        ga = [bytes(v for g in row for v in (g, 255)) for row in grey]
        self.assertEqual(png.decode(_encode(5, 3, 4, ga, (2,))).rows, img.rows)

        plte = bytes([10, 20, 30, 40, 50, 60])
        img = png.decode(_encode(3, 1, 3, [bytes([0, 1, 1])], extra=[(b"PLTE", plte)]))
        self.assertEqual(img.rows[0], bytes([10, 20, 30, 40, 50, 60, 40, 50, 60]))

    def test_rejects_unsupported(self):
        rgba = [bytes([1, 2, 3, 255, 4, 5, 6, 128])]
        with self.assertRaisesRegex(png.PngError, r"pixel \(1, 0\) is not opaque"):
            png.decode(_encode(2, 1, 6, rgba))
        with self.assertRaisesRegex(png.PngError, "16-bit"):
            png.decode(_encode(1, 1, 2, [bytes(6)], depth=16))
        with self.assertRaisesRegex(png.PngError, "interlaced"):
            png.decode(_encode(1, 1, 2, [bytes(3)], interlace=1))
        with self.assertRaisesRegex(png.PngError, "not a PNG"):
            png.decode(b"GIF89a")
        with self.assertRaisesRegex(png.PngError, "palette index"):
            png.decode(_encode(1, 1, 3, [bytes([5])], extra=[(b"PLTE", bytes(3))]))
        with self.assertRaisesRegex(png.PngError, "not found"):
            png.read("/nonexistent/x.png")


if __name__ == "__main__":
    unittest.main()
