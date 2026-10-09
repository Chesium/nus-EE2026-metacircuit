// State export (GM-3): RAM dumps in the framescope FS-3 shape, plus a semantic
// decode a comparator can diff without caring about slot order or metadata bits.

import {
  CELL_COUNT, CELL_WORD_W, COMPONENT_INDEX_INVALID, COMPONENT_WORD_W, INDEX_MAP_WORD_W, SPRITE_NAMES, TOOL_NAMES,
  WIRE_VARIANT_NAMES, kindFromSprite, COMPONENT_KIND_NAMES, modeSelect,
} from './constants.ts';
import {
  addrToColRow, decodeCell, decodeComponent, encodeComponent, formatValue, toHex, fromHex,
} from './encoding.ts';
import { pairCell } from './geometry.ts';
import type { Component, GoldenState } from './state.ts';

/** One memory dump object, identical in shape to framescope's FS-3 output. */
export interface RamDump {
  name: string;
  frame: number;
  width: number;
  depth: number;
  words: string[];
}

/**
 * Memory names used in dumps. Defaults are framescope's metacircuit dump names
 * (IF-028). The per-cell colour RAMs (cell_fg_color, cell_bg_color) are not
 * modelled in M1 and are not exported.
 */
export interface DumpNames {
  cellsRender: string;
  cellsShadow: string;
  values: string;
  valueUnits: string;
  componentStore: string;
  componentIndexMap: string;
}

export const DEFAULT_DUMP_NAMES: Readonly<DumpNames> = Object.freeze({
  cellsRender: 'cells_render',
  cellsShadow: 'cells_shadow',
  values: 'values_shadow',
  valueUnits: 'value_units_shadow',
  componentStore: 'component_store',
  componentIndexMap: 'component_index_map',
});

const VALUE_WORD_W = 12;
const UNIT_WORD_W = 4;

/** ComponentStore word for a slot (0 for a free slot). The index field holds the slot number (A-016). */
export function componentWord(c: Component | null, slot: number): bigint {
  if (!c) return 0n;
  return encodeComponent({
    unit: c.unit,
    index: slot,
    type: c.leftSprite & 0xf,
    rotation: c.rotation,
    value: c.valueBcd,
    x: c.col,
    y: c.row,
  });
}

/**
 * RAM dumps of the state. `frame` is the frame number the dump is labelled
 * with (by default the index of the last stepped frame, i.e. state.frame - 1).
 */
export function exportRamDumps(s: GoldenState, names: Partial<DumpNames> = DEFAULT_DUMP_NAMES, frame = s.frame - 1): RamDump[] {
  const n: DumpNames = { ...DEFAULT_DUMP_NAMES, ...names };
  const cells = Array.from(s.cells, (w) => toHex(w, CELL_WORD_W));
  const map = Array.from(s.componentIndexMap, (w) => toHex(w, INDEX_MAP_WORD_W));
  const comps = s.components.map((c, slot) => toHex(componentWord(c, slot), COMPONENT_WORD_W));
  // Per-cell values: both cells of a component hold its value, other cells 0 (A-021).
  const values = new Array<number>(CELL_COUNT).fill(0);
  const units = new Array<number>(CELL_COUNT).fill(0);
  s.componentIndexMap.forEach((slot, addr) => {
    const c = slot === COMPONENT_INDEX_INVALID ? null : s.components[slot];
    if (c) {
      values[addr] = c.valueBcd;
      units[addr] = c.unit;
    }
  });
  const mk = (name: string, width: number, words: string[]): RamDump => ({ name, frame, width, depth: CELL_COUNT, words });
  return [
    mk(n.cellsRender, CELL_WORD_W, cells),
    mk(n.cellsShadow, CELL_WORD_W, cells.slice()),
    mk(n.values, VALUE_WORD_W, values.map((v) => toHex(v, VALUE_WORD_W))),
    mk(n.valueUnits, UNIT_WORD_W, units.map((v) => toHex(v, UNIT_WORD_W))),
    mk(n.componentStore, COMPONENT_WORD_W, comps),
    mk(n.componentIndexMap, INDEX_MAP_WORD_W, map),
  ];
}

// ---------------------------------------------------------------- semantic state

export interface SemanticCell {
  col: number;
  row: number;
  sprite: number;
  spriteName: string;
  rotation: number;
  meta: number;
  componentSlot: number | null;
}

export interface SemanticComponent {
  slot: number;
  kind: string;
  storeType: number;
  col: number;
  row: number;
  rotation: number;
  cells: { col: number; row: number }[];
  value: string; // e.g. "000" + unit letter
  valueBcd: number;
  unit: number;
  indexField: number;
}

export interface SemanticState {
  frame: number;
  tool: string;
  toolIndex: number;
  wireVariant: string;
  modeSelect: number;
  pan: { x: number; y: number };
  cells: SemanticCell[]; // enabled cells only, row-major
  components: SemanticComponent[]; // live slots, ascending
}

export interface DecodeOptions {
  /**
   * Number of valid ComponentStore entries (framescope probe `component_count`).
   * When given, only words 0..count-1 are decoded: the RTL leaves stale entries
   * above the count (IF-028). When omitted (golden dumps), all-zero words are free slots.
   */
  componentCount?: number;
}

/** Decode raw memories (from the golden or from framescope dumps) into semantic state. */
export function decodeMemories(
  dumps: RamDump[],
  names: Partial<DumpNames> = DEFAULT_DUMP_NAMES,
  opts: DecodeOptions = {},
): Pick<SemanticState, 'cells' | 'components'> {
  const n: DumpNames = { ...DEFAULT_DUMP_NAMES, ...names };
  const get = (name: string) => dumps.find((d) => d.name === name);
  const cellDump = get(n.cellsRender) ?? get(n.cellsShadow);
  const mapDump = get(n.componentIndexMap);
  const compDump = get(n.componentStore);
  const cells: SemanticCell[] = [];
  if (cellDump) {
    cellDump.words.forEach((w, addr) => {
      const c = decodeCell(Number(fromHex(w)));
      if (!c.enabled) return;
      const { col, row } = addrToColRow(addr);
      const slot = mapDump ? Number(fromHex(mapDump.words[addr]!)) : COMPONENT_INDEX_INVALID;
      cells.push({
        col, row, sprite: c.sprite, spriteName: SPRITE_NAMES[c.sprite] ?? `sprite${c.sprite}`,
        rotation: c.rotation, meta: c.meta, componentSlot: slot === COMPONENT_INDEX_INVALID ? null : slot,
      });
    });
  }
  const components: SemanticComponent[] = [];
  if (compDump) {
    compDump.words.forEach((w, slot) => {
      const word = fromHex(w);
      if (opts.componentCount !== undefined ? slot >= opts.componentCount : word === 0n) return; // stale / free (A-016)
      const f = decodeComponent(word);
      const kind = kindFromSprite(f.type);
      components.push({
        slot, kind: COMPONENT_KIND_NAMES[kind] ?? `kind${kind}`, storeType: f.type, col: f.x, row: f.y,
        rotation: f.rotation, cells: [{ col: f.x, row: f.y }, pairCell(f.x, f.y, f.rotation)],
        value: formatValue(f.value, f.unit), valueBcd: f.value, unit: f.unit, indexField: f.index,
      });
    });
  }
  return { cells, components };
}

export function semanticState(s: GoldenState, frame = s.frame - 1): SemanticState {
  const { cells, components } = decodeMemories(exportRamDumps(s, DEFAULT_DUMP_NAMES, frame));
  return {
    frame,
    tool: TOOL_NAMES[s.tool],
    toolIndex: s.tool,
    wireVariant: WIRE_VARIANT_NAMES[s.wireVariant & 3]!,
    modeSelect: modeSelect(s.tool, s.wireVariant),
    pan: { x: s.panX, y: s.panY },
    cells,
    components,
  };
}

// ---------------------------------------------------------------- semantic diff

export interface DiffOptions {
  /** Ignore the 7 metadata bits [15:9] of cell words (flow/colour bits; not modelled in M1). */
  ignoreCellMeta: boolean;
  /** Compare components as a multiset keyed by anchor, ignoring slot numbers and the index field. */
  ignoreSlots: boolean;
}

export const DEFAULT_DIFF_OPTIONS: DiffOptions = { ignoreCellMeta: true, ignoreSlots: true };

/** Human-readable differences between two decoded memory sets (expected vs actual). */
export function diffSemantic(
  expected: Pick<SemanticState, 'cells' | 'components'>,
  actual: Pick<SemanticState, 'cells' | 'components'>,
  opts: DiffOptions = DEFAULT_DIFF_OPTIONS,
): string[] {
  const out: string[] = [];
  const cellKey = (c: SemanticCell) => `${c.col},${c.row}`;
  const cellDesc = (c?: SemanticCell) =>
    c ? `${c.spriteName} rot ${c.rotation}${opts.ignoreCellMeta ? '' : ` meta ${c.meta}`}` : 'empty';
  const em = new Map(expected.cells.map((c) => [cellKey(c), c]));
  const am = new Map(actual.cells.map((c) => [cellKey(c), c]));
  const keys = [...new Set([...em.keys(), ...am.keys()])].sort((a, b) => {
    const [ac, ar] = a.split(',').map(Number);
    const [bc, br] = b.split(',').map(Number);
    return ar! - br! || ac! - bc!;
  });
  for (const k of keys) {
    const e = em.get(k);
    const a = am.get(k);
    if (cellDesc(e) !== cellDesc(a)) out.push(`cell (${k}) is ${cellDesc(a)}, expected ${cellDesc(e)}`);
  }
  const compKey = (c: SemanticComponent) => (opts.ignoreSlots ? `${c.col},${c.row}` : `slot ${c.slot}`);
  const compDesc = (c?: SemanticComponent) =>
    c ? `${c.kind} at (${c.col},${c.row}) rot ${c.rotation} value ${c.value}${opts.ignoreSlots ? '' : ` index ${c.indexField}`}` : 'absent';
  const ec = new Map(expected.components.map((c) => [compKey(c), c]));
  const ac = new Map(actual.components.map((c) => [compKey(c), c]));
  for (const k of [...new Set([...ec.keys(), ...ac.keys()])].sort()) {
    const e = ec.get(k);
    const a = ac.get(k);
    if (compDesc(e) !== compDesc(a)) out.push(`component ${k}: ${compDesc(a)}, expected ${compDesc(e)}`);
  }
  return out;
}
