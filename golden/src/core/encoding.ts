// Word encodings of the RTL memories (IF-017..IF-019) plus semantic decode.

import {
  COMPONENT_KIND_NAMES, COMPONENT_WORD_W, CELL_WORD_W, GRID_W, SPRITE_NAMES,
  UNIT_NAMES, kindFromSprite,
} from './constants.ts';

// ---------------------------------------------------------------- CellStore word (16 bit)
// [15:9] metadata (not modelled in M1, always 0), [8:7] rotation, [6:1] sprite, [0] enable

export interface CellFields {
  enabled: boolean;
  sprite: number; // 6 bit
  rotation: number; // 2 bit
  meta: number; // 7 bit
}

export function encodeCell(c: CellFields): number {
  return (((c.meta & 0x7f) << 9) | ((c.rotation & 3) << 7) | ((c.sprite & 0x3f) << 1) | (c.enabled ? 1 : 0)) & 0xffff;
}

export function decodeCell(word: number): CellFields {
  return {
    enabled: (word & 1) === 1,
    sprite: (word >> 1) & 0x3f,
    rotation: (word >> 7) & 3,
    meta: (word >> 9) & 0x7f,
  };
}

export const EMPTY_CELL = 0;

export function makeCell(sprite: number, rotation: number): number {
  return encodeCell({ enabled: true, sprite, rotation, meta: 0 });
}

// ---------------------------------------------------------------- ComponentStore word (40 bit)
// {unit[39:36], index[35:27], type[26:23], rotation[22:21], value[20:9], pos_y[8:5], pos_x[4:0]}

export interface ComponentFields {
  unit: number; // 4 bit unit code (Unit)
  index: number; // 9 bit store index field
  type: number; // 4 bit store type = sprite[3:0] of the anchor (left) half
  rotation: number; // 2 bit
  value: number; // 12 bit, three BCD digits
  x: number; // 5 bit anchor column
  y: number; // 4 bit anchor row
}

const B = (n: number) => BigInt(n);

export function encodeComponent(c: ComponentFields): bigint {
  return (
    (B(c.unit & 0xf) << 36n) |
    (B(c.index & 0x1ff) << 27n) |
    (B(c.type & 0xf) << 23n) |
    (B(c.rotation & 3) << 21n) |
    (B(c.value & 0xfff) << 9n) |
    (B(c.y & 0xf) << 5n) |
    B(c.x & 0x1f)
  );
}

export function decodeComponent(word: bigint): ComponentFields {
  const f = (shift: bigint, mask: bigint) => Number((word >> shift) & mask);
  return {
    unit: f(36n, 0xfn),
    index: f(27n, 0x1ffn),
    type: f(23n, 0xfn),
    rotation: f(21n, 3n),
    value: f(9n, 0xfffn),
    y: f(5n, 0xfn),
    x: f(0n, 0x1fn),
  };
}

// ---------------------------------------------------------------- BCD value helpers

/** Three-digit BCD (12 bit) to its decimal digits string, e.g. 0x123 -> "123". */
export function bcdToString(v: number): string {
  return [(v >> 8) & 0xf, (v >> 4) & 0xf, v & 0xf].map((d) => d.toString(16)).join('');
}

export function stringToBcd(s: string): number {
  const d = s.padStart(3, '0').slice(-3);
  return (parseInt(d[0]!, 10) << 8) | (parseInt(d[1]!, 10) << 4) | parseInt(d[2]!, 10);
}

export function formatValue(value: number, unit: number): string {
  return `${bcdToString(value)}${UNIT_NAMES[unit] ?? `?${unit}`}`;
}

// ---------------------------------------------------------------- addressing

export function cellAddr(col: number, row: number): number {
  return row * GRID_W + col;
}
export function addrToColRow(addr: number): { col: number; row: number } {
  return { col: addr % GRID_W, row: Math.floor(addr / GRID_W) };
}

// ---------------------------------------------------------------- hex formatting

export function hexDigits(width: number): number {
  return Math.ceil(width / 4);
}

export function toHex(value: number | bigint, width: number): string {
  return '0x' + value.toString(16).padStart(hexDigits(width), '0');
}

export function fromHex(s: string): bigint {
  return BigInt(s);
}

// ---------------------------------------------------------------- semantic descriptions

export function describeCell(word: number) {
  const c = decodeCell(word);
  return {
    word: toHex(word, CELL_WORD_W),
    enabled: c.enabled,
    sprite: c.sprite,
    spriteName: c.enabled ? SPRITE_NAMES[c.sprite] ?? `sprite${c.sprite}` : 'empty',
    rotation: c.rotation,
    meta: c.meta,
  };
}

export function describeComponent(word: bigint) {
  const c = decodeComponent(word);
  const kind = kindFromSprite(c.type);
  return {
    word: toHex(word, COMPONENT_WORD_W),
    ...c,
    kind,
    kindName: COMPONENT_KIND_NAMES[kind] ?? `kind${kind}`,
    valueText: formatValue(c.value, c.unit),
  };
}
