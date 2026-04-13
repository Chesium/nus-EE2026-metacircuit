from __future__ import annotations

import pathlib
import struct


UNIT_SCALES = {
    0x00: 1.0,
    0x01: 1e-3,
    0x02: 1e-6,
    0x03: 1e-9,
    0x04: 1e3,
    0x05: 1e6,
    0x06: 1e9,
}

ROM_WORDS = 1 << 13


def float_to_bits(value: float) -> int:
    return struct.unpack(">I", struct.pack(">f", float(value)))[0]


def main() -> None:
    out_path = pathlib.Path(__file__).with_name("bcd_unit_to_fp32_rom.mem")
    words = [0] * ROM_WORDS
    for unit_code, scale in UNIT_SCALES.items():
        for decimal_value in range(1000):
            addr = (unit_code << 10) | decimal_value
            words[addr] = float_to_bits(decimal_value * scale)
    out_path.write_text("\n".join(f"{word:08X}" for word in words) + "\n", encoding="ascii")


if __name__ == "__main__":
    main()
