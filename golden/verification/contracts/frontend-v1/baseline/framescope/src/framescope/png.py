"""Stdlib-only PNG reading and writing, enough for frame comparison.

Reads 8-bit, non-interlaced PNGs of colour type greyscale, RGB, palette,
greyscale+alpha and RGBA, with all five row filters, and converts them to
opaque RGB. Pixels that are not fully opaque are rejected: frames are compared
as RGB, and silently dropping alpha would hide a broken reference. Writes 8-bit
RGB with filter 0 (like the C++ harness).

Images are a list of rows of `bytes` (3 bytes per pixel), which keeps whole-row
comparison a single bytes equality test.
"""

from __future__ import annotations

import struct
import zlib
from dataclasses import dataclass
from pathlib import Path

from . import FramescopeError

SIGNATURE = b"\x89PNG\r\n\x1a\n"
_CHANNELS = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}
_COLOUR_NAMES = {0: "greyscale", 2: "RGB", 3: "palette", 4: "greyscale+alpha", 6: "RGBA"}


class PngError(FramescopeError):
    """The file is not a PNG framescope can read."""


@dataclass
class Image:
    width: int
    height: int
    rows: list[bytes]  # height rows of 3 * width bytes (R, G, B)

    @classmethod
    def new(cls, width: int, height: int, fill: tuple[int, int, int] = (0, 0, 0)) -> Image:
        row = bytes(fill) * width
        return cls(width, height, [row] * height)

    def pixel(self, x: int, y: int) -> tuple[int, int, int]:
        row = self.rows[y]
        return row[3 * x], row[3 * x + 1], row[3 * x + 2]


def read(path: str | Path) -> Image:
    p = Path(path)
    try:
        data = p.read_bytes()
    except FileNotFoundError:
        raise PngError(f"PNG not found: {p}") from None
    return decode(data, str(p))


def write(path: str | Path, img: Image, level: int = 6) -> Path:
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes(encode(img, level))
    return p


def encode(img: Image, level: int = 6) -> bytes:
    if img.width <= 0 or img.height <= 0 or len(img.rows) != img.height:
        raise PngError("cannot encode an empty or inconsistent image")
    stride = 3 * img.width
    if any(len(r) != stride for r in img.rows):
        raise PngError("every row must hold 3 * width bytes")
    raw = b"".join(b"\0" + bytes(r) for r in img.rows)
    ihdr = struct.pack(">IIBBBBB", img.width, img.height, 8, 2, 0, 0, 0)
    return SIGNATURE + _chunk(b"IHDR", ihdr) + _chunk(b"IDAT", zlib.compress(raw, level)) + _chunk(b"IEND", b"")


def decode(data: bytes, where: str = "PNG") -> Image:
    if data[:8] != SIGNATURE:
        raise PngError(f"{where}: not a PNG file")
    pos, idat, header, palette, trns = 8, [], None, None, None
    while pos + 8 <= len(data):
        length, kind = struct.unpack(">I4s", data[pos : pos + 8])
        body = data[pos + 8 : pos + 8 + length]
        if len(body) != length:
            raise PngError(f"{where}: truncated {kind.decode('latin-1')} chunk")
        if kind == b"IHDR":
            header = struct.unpack(">IIBBBBB", body[:13])
        elif kind == b"PLTE":
            palette = body
        elif kind == b"tRNS":
            trns = body
        elif kind == b"IDAT":
            idat.append(body)
        elif kind == b"IEND":
            break
        pos += 12 + length
    if header is None:
        raise PngError(f"{where}: missing IHDR")
    width, height, depth, colour, _compression, _filter, interlace = header
    if colour not in _CHANNELS:
        raise PngError(f"{where}: invalid colour type {colour}")
    if depth != 8:
        raise PngError(f"{where}: {depth}-bit {_COLOUR_NAMES[colour]} is not supported (only 8-bit channels)")
    if interlace:
        raise PngError(f"{where}: interlaced (Adam7) PNGs are not supported")
    if width == 0 or height == 0:
        raise PngError(f"{where}: empty image")
    if colour == 3 and not palette:
        raise PngError(f"{where}: palette image without PLTE")
    try:
        raw = zlib.decompress(b"".join(idat))
    except zlib.error as e:
        raise PngError(f"{where}: corrupt image data ({e})") from None

    bpp = _CHANNELS[colour]
    stride = width * bpp
    if len(raw) < (stride + 1) * height:
        raise PngError(f"{where}: image data too short for {width}x{height}")
    to_rgb = _converter(colour, width, palette, trns, where)
    rows: list[bytes] = []
    prev = bytes(stride)
    for y in range(height):
        start = y * (stride + 1)
        ftype = raw[start]
        line = raw[start + 1 : start + 1 + stride]
        if ftype == 0:
            cur = line
        elif ftype == 1:
            cur = _unfilter_sub(line, bpp)
        elif ftype == 2:
            cur = _add_bytes(line, prev)
        elif ftype == 3:
            cur = _unfilter_average(line, prev, bpp)
        elif ftype == 4:
            cur = _unfilter_paeth(line, prev, bpp)
        else:
            raise PngError(f"{where}: row {y} has invalid filter type {ftype}")
        rows.append(to_rgb(cur, y))
        prev = cur
    return Image(width, height, rows)


def _chunk(kind: bytes, body: bytes) -> bytes:
    return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body))


def _converter(colour: int, width: int, palette: bytes | None, trns: bytes | None, where: str):
    opaque_row = b"\xff" * width

    def check_alpha(alpha: bytes, y: int) -> None:
        if alpha != opaque_row:
            x = next(i for i, a in enumerate(alpha) if a != 255)
            raise PngError(f"{where}: pixel ({x}, {y}) is not opaque (alpha {alpha[x]}); "
                           "framescope compares opaque RGB images")

    if colour == 2:
        return lambda row, y: bytes(row)
    if colour == 6:
        def rgba(row: bytes, y: int) -> bytes:
            check_alpha(row[3::4], y)
            out = bytearray(3 * width)
            out[0::3], out[1::3], out[2::3] = row[0::4], row[1::4], row[2::4]
            return bytes(out)
        return rgba
    if colour in (0, 4):
        step = 1 if colour == 0 else 2

        def grey(row: bytes, y: int) -> bytes:
            if step == 2:
                check_alpha(row[1::2], y)
            g = row[0::step]
            out = bytearray(3 * width)
            out[0::3] = out[1::3] = out[2::3] = g
            return bytes(out)
        return grey

    assert palette is not None
    entries = [palette[i : i + 3] for i in range(0, len(palette) - len(palette) % 3, 3)]
    transparent = {i for i, a in enumerate(trns or b"") if a != 255}

    def indexed(row: bytes, y: int) -> bytes:
        try:
            out = b"".join([entries[i] for i in row])
        except IndexError:
            raise PngError(f"{where}: row {y} uses a palette index beyond PLTE") from None
        if transparent and not transparent.isdisjoint(row):
            x = next(i for i, v in enumerate(row) if v in transparent)
            raise PngError(f"{where}: pixel ({x}, {y}) is not opaque (palette tRNS); "
                           "framescope compares opaque RGB images")
        return out
    return indexed


# Byte-wise addition mod 256 on whole rows at once (SWAR on Python ints): the
# low seven bits of every byte add without crossing into the next byte, and the
# top bit is the XOR of the operands' top bits and the carry into it.
_SWAR_CACHE: dict[int, tuple[int, int, int]] = {}


def _swar_masks(n: int) -> tuple[int, int, int]:
    masks = _SWAR_CACHE.get(n)
    if masks is None:
        masks = (int.from_bytes(b"\x7f" * n, "little"), int.from_bytes(b"\x80" * n, "little"), (1 << (8 * n)) - 1)
        _SWAR_CACHE[n] = masks
    return masks


def _swar_add(a: int, b: int, low: int, high: int) -> int:
    return ((a & low) + (b & low)) ^ ((a ^ b) & high)


def _add_bytes(a: bytes, b: bytes) -> bytes:
    n = len(a)
    low, high, _ = _swar_masks(n)
    s = _swar_add(int.from_bytes(a, "little"), int.from_bytes(b, "little"), low, high)
    return s.to_bytes(n, "little")


def _unfilter_sub(line: bytes, bpp: int) -> bytes:
    """Prefix sum with stride bpp, as a log-step (Hillis-Steele) scan."""
    n = len(line)
    low, high, full = _swar_masks(n)
    x = int.from_bytes(line, "little")
    k = bpp
    while k < n:
        x = _swar_add(x, (x << (8 * k)) & full, low, high)
        k *= 2
    return x.to_bytes(n, "little")


def _unfilter_average(line: bytes, prev: bytes, bpp: int) -> bytes:
    out = bytearray(line)
    for i in range(bpp):
        out[i] = (out[i] + (prev[i] >> 1)) & 0xFF
    for i in range(bpp, len(out)):
        out[i] = (out[i] + ((out[i - bpp] + prev[i]) >> 1)) & 0xFF
    return bytes(out)


def _unfilter_paeth(line: bytes, prev: bytes, bpp: int) -> bytes:
    out = bytearray(line)
    for i in range(bpp):
        out[i] = (out[i] + prev[i]) & 0xFF
    for i in range(bpp, len(out)):
        a, b, c = out[i - bpp], prev[i], prev[i - bpp]
        pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
        if pa <= pb and pa <= pc:
            pred = a
        elif pb <= pc:
            pred = b
        else:
            pred = c
        out[i] = (out[i] + pred) & 0xFF
    return bytes(out)
