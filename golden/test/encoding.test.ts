import { describe, expect, it } from 'vitest';
import {
  CELL_COUNT, decodeCell, decodeComponent, decodeMemories, diffSemantic, encodeCell, encodeComponent, exportRamDumps,
  bcdToString, stringToBcd, semanticState, toHex,
} from '../src/core/index.ts';
import { drive, empty } from './helpers.ts';

describe('cell words', () => {
  it('packs {meta[15:9], rot[8:7], sprite[6:1], en[0]}', () => {
    expect(encodeCell({ enabled: true, sprite: 5, rotation: 0, meta: 0 })).toBe(0b0000000_00_000101_1);
    expect(encodeCell({ enabled: true, sprite: 15, rotation: 3, meta: 0 })).toBe(0b0000000_11_001111_1);
    expect(encodeCell({ enabled: false, sprite: 0, rotation: 0, meta: 0x7f })).toBe(0xfe00);
  });

  it('round-trips every field combination', () => {
    for (let sprite = 0; sprite < 64; sprite += 7) {
      for (let rotation = 0; rotation < 4; rotation++) {
        for (const meta of [0, 1, 0x55, 0x7f]) {
          for (const enabled of [false, true]) {
            const c = { enabled, sprite, rotation, meta };
            expect(decodeCell(encodeCell(c))).toEqual(c);
          }
        }
      }
    }
  });
});

describe('component words', () => {
  it('packs {unit[39:36], index[35:27], type[26:23], rot[22:21], value[20:9], y[8:5], x[4:0]}', () => {
    const w = encodeComponent({ unit: 0xf, index: 0, type: 0, rotation: 0, value: 0, x: 0, y: 0 });
    expect(w).toBe(0xf000000000n);
    expect(encodeComponent({ unit: 0, index: 0x1ff, type: 0, rotation: 0, value: 0, x: 0, y: 0 })).toBe(0x1ffn << 27n);
    expect(encodeComponent({ unit: 0, index: 0, type: 5, rotation: 2, value: 0x123, x: 17, y: 15 })).toBe(
      (5n << 23n) | (2n << 21n) | (0x123n << 9n) | (15n << 5n) | 17n,
    );
  });

  it('round-trips', () => {
    const cases = [
      { unit: 3, index: 287, type: 13, rotation: 3, value: 0x999, x: 17, y: 15 },
      { unit: 0, index: 0, type: 5, rotation: 0, value: 0, x: 0, y: 0 },
      { unit: 6, index: 100, type: 9, rotation: 1, value: 0x470, x: 9, y: 8 },
    ];
    for (const c of cases) expect(decodeComponent(encodeComponent(c))).toEqual(c);
  });

  it('formats BCD values', () => {
    expect(bcdToString(0x123)).toBe('123');
    expect(stringToBcd('47')).toBe(0x047);
  });
});

describe('RAM dumps', () => {
  it('have the framescope FS-3 shape with zero-padded hex', () => {
    const dumps = exportRamDumps(empty(), undefined, 7);
    expect(dumps.map((d) => [d.name, d.width, d.depth, d.frame])).toEqual([
      ['cells_render', 16, CELL_COUNT, 7],
      ['cells_shadow', 16, CELL_COUNT, 7],
      ['values_shadow', 12, CELL_COUNT, 7],
      ['value_units_shadow', 4, CELL_COUNT, 7],
      ['component_store', 40, CELL_COUNT, 7],
      ['component_index_map', 9, CELL_COUNT, 7],
    ]);
    expect(dumps[0]!.words[0]).toBe('0x0000');
    expect(dumps[2]!.words[0]).toBe('0x000');
    expect(dumps[3]!.words[0]).toBe('0x0');
    expect(dumps[4]!.words[0]).toBe('0x0000000000');
    expect(dumps[5]!.words[0]).toBe('0x1ff');
    for (const d of dumps) expect(d.words).toHaveLength(CELL_COUNT);
    expect(toHex(0xabn, 40)).toBe('0x00000000ab');
  });

  it('use configurable names', () => {
    const names = { componentStore: 'cs', componentIndexMap: 'map' };
    expect(exportRamDumps(empty(), names).map((d) => d.name)).toEqual([
      'cells_render', 'cells_shadow', 'values_shadow', 'value_units_shadow', 'cs', 'map',
    ]);
  });

  it('decode back to the same semantic state (JSON round trip)', () => {
    const s = drive([
      'click_tool resistor', 'click_cell 3 3', 'click_tool rotate', 'click_cell 3 3',
      'click_tool voltage', 'click_cell 8 2', 'click_tool wire', 'click_cell 1 1', 'click_tool ground', 'click_cell 1 2',
    ]);
    const dumps = JSON.parse(JSON.stringify(exportRamDumps(s)));
    const dec = decodeMemories(dumps);
    const sem = semanticState(s);
    expect(dec.cells).toEqual(sem.cells);
    expect(dec.components).toEqual(sem.components);
    expect(sem.components.map((c) => [c.kind, c.col, c.row, c.rotation, c.value])).toEqual([
      ['resistor', 3, 3, 1, '000'],
      ['voltage', 8, 2, 0, '000'],
    ]);
    expect(sem.components[0]!.cells).toEqual([{ col: 3, row: 3 }, { col: 3, row: 4 }]);
    expect(diffSemantic(dec, sem)).toEqual([]);
  });

  it('writes component values to both cells and honours componentCount when decoding', async () => {
    const { initialState } = await import('../src/core/index.ts');
    const dumps = exportRamDumps(initialState(), undefined, 0);
    const values = dumps.find((d) => d.name === 'values_shadow')!.words;
    expect([values[39], values[40], values[75], values[76], values[38]]).toEqual(['0x010', '0x010', '0x100', '0x100', '0x000']);
    // RTL-style dump: entries at or above the count are stale and ignored.
    const cs = dumps.find((d) => d.name === 'component_store')!;
    cs.words[5] = '0x0002a00063';
    expect(decodeMemories(dumps, undefined, { componentCount: 3 }).components).toHaveLength(3);
    expect(decodeMemories(dumps).components).toHaveLength(4);
  });

  it('semantic diff reports cell and component differences and ignores slot order by default', () => {
    const a = semanticState(drive(['click_tool resistor', 'click_cell 1 1', 'click_cell 1 3']));
    const b = semanticState(drive(['click_tool resistor', 'click_cell 1 3', 'click_cell 1 1']));
    expect(diffSemantic(a, b)).toEqual([]);
    expect(diffSemantic(a, b, { ignoreCellMeta: true, ignoreSlots: false }).length).toBeGreaterThan(0);
    const c = semanticState(drive(['click_tool resistor', 'click_cell 1 1']));
    const d = diffSemantic(a, c);
    expect(d).toContain('cell (1,3) is empty, expected RL rot 0');
    expect(d.some((x) => x.startsWith('component 1,3: absent'))).toBe(true);
  });
});

describe('boot circuit', () => {
  it('loads the RTL default circuit into both stores', async () => {
    const { initialState } = await import('../src/core/index.ts');
    const sem = semanticState(initialState(), 0);
    expect(sem.cells).toHaveLength(17);
    expect(sem.cells.find((c) => c.col === 2 && c.row === 7)).toMatchObject({ spriteName: 'Ground', rotation: 1 });
    expect(sem.cells.find((c) => c.col === 3 && c.row === 4)).toMatchObject({ spriteName: 'RL', meta: 1, componentSlot: 1 });
    // D-015: the source is turned 180 degrees, + half (VL, anchor) at (4,2) facing the right rail.
    expect(sem.cells.find((c) => c.col === 3 && c.row === 2)).toMatchObject({ spriteName: 'VR', rotation: 2, meta: 0, componentSlot: 0 });
    expect(sem.cells.find((c) => c.col === 4 && c.row === 2)).toMatchObject({ spriteName: 'VL', rotation: 2, meta: 0, componentSlot: 0 });
    expect(sem.components.map((c) => [c.kind, c.col, c.row, c.rotation, c.value])).toEqual([
      ['voltage', 4, 2, 2, '010'], ['resistor', 3, 4, 0, '100'], ['resistor', 3, 6, 0, '100'],
    ]);
    expect([initialState().cells[39], initialState().cells[40]]).toEqual([0x0111, 0x010f]);
    const store = exportRamDumps(initialState()).find((d) => d.name === 'component_store')!.words;
    expect(store[0]).toBe('0x0003c02044'); // {unit 0, index 0, type 7, rot 2, value 010, y 2, x 4}
    const values = exportRamDumps(initialState()).find((d) => d.name === 'values_shadow')!.words;
    expect([values[39], values[40]]).toEqual(['0x010', '0x010']);
  });
});
