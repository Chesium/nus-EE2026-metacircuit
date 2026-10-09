// Element value decoding: 12-bit packed BCD + unit code -> real value.
//
// NetlistElement.unit is the wire (protocol) unit code: src/uart_link/README.md's
// "solver-board mapping", which frontend_tester.py also uses. Netlist
// extraction translates the frontend's stored unit code (IF-016) into it
// (M3_ASSUMPTIONS.md M3-A008; pico has no wire code and is sent as 0xFF,
// M3-A009). The frontend table is kept for decoding ComponentStore values
// directly, so both readings of a component can be compared (M3-S002).

/** Wire unit codes (uart_link "solver-board mapping"), as the double literal 1eN. */
export const WIRE_UNIT_SCALE: Readonly<Record<number, number>> = {
  0x00: 1, // base
  0x01: 1e-3, // milli
  0x02: 1e-6, // micro
  0x03: 1e-9, // nano
  0x04: 1e3, // kilo
  0x05: 1e6, // mega
  0x06: 1e9, // giga
};

/** Frontend unit codes (IF-016: 0 none, 1 M, 2 k, 3 m, 4 u, 5 n, 6 p). */
export const FRONTEND_UNIT_SCALE: Readonly<Record<number, number>> = {
  0: 1, 1: 1e6, 2: 1e3, 3: 1e-3, 4: 1e-6, 5: 1e-9, 6: 1e-12,
};

export type UnitTable = 'wire' | 'frontend';

export function unitScaleTable(table: UnitTable): Readonly<Record<number, number>> {
  return table === 'wire' ? WIRE_UNIT_SCALE : FRONTEND_UNIT_SCALE;
}

/** SI unit per uart_link element kind (1 R, 2 I, 3 V, 4 C, 5 L). */
export const KIND_SI_UNIT: Readonly<Record<number, string>> = {
  1: 'ohm', 2: 'A', 3: 'V', 4: 'F', 5: 'H',
};

/**
 * Packed BCD (three nibbles, hundreds/tens/ones) to its integer 0..999.
 * Returns null when the field is wider than 12 bits or any nibble is > 9.
 */
export function bcdToInt(valueBcd: number): number | null {
  if (!Number.isInteger(valueBcd) || valueBcd < 0 || valueBcd > 0xfff) return null;
  const h = (valueBcd >> 8) & 0xf;
  const t = (valueBcd >> 4) & 0xf;
  const o = valueBcd & 0xf;
  if (h > 9 || t > 9 || o > 9) return null;
  return h * 100 + t * 10 + o;
}

/** A freshly placed component: no digits and no unit (blank value text). */
export function isBlankValue(valueBcd: number, unit: number): boolean {
  return valueBcd === 0 && unit === 0;
}

export type DecodedValue =
  | { ok: true; digits: number; scale: number; value: number }
  | { ok: false; reason: 'bcd' | 'unit' };

/**
 * Decode a value field: `value = digits * scale` in float64, exactly as
 * frontend_tester.py computes it (M3-S004). Blank (BCD 000) decodes to 0;
 * whether 0 is usable depends on the kind (0 ohm is ill-posed, M3-S006).
 */
export function decodeValue(valueBcd: number, unit: number, table: UnitTable = 'wire'): DecodedValue {
  const digits = bcdToInt(valueBcd);
  if (digits === null) return { ok: false, reason: 'bcd' };
  const scale = unitScaleTable(table)[unit];
  if (scale === undefined) return { ok: false, reason: 'unit' };
  return { ok: true, digits, scale, value: digits * scale };
}
