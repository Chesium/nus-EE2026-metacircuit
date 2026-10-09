import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { cellPortMask, deriveConnectivity, labelPortGrid, nodePaletteIndex } from '../src/core/connectivity.ts';
import { Sprite } from '../src/core/constants.ts';
import { initialState } from '../src/core/state.ts';

const word = (sprite: number, rotation = 0) => 1 | sprite << 1 | rotation << 7;

describe('independent node connectivity and colours', () => {
  it('matches the documented 8x8 netlist example, including seven nodes and ground terminals', () => {
    const source = readFileSync('../notebooks/data/netlist_test_data.txt', 'utf8').trim().split('\n\n');
    const ports = source[0]!.split(/\s+/).map((s) => Number.parseInt(s, 2));
    const expected = source[1]!.trim().split(/\s+/).map(Number);
    expect(ports).toHaveLength(64);
    const result = labelPortGrid(ports, 8, 8);
    expect(Array.from(result.nodeIds)).toEqual(expected);
    expect(result.nodeCount).toBe(7);
  });

  it('assigns boot wires and ground to two coloured nodes while leaving component halves uncoloured', () => {
    const state = initialState();
    const result = deriveConnectivity(state.cells);
    expect(result.nodeCount).toBe(2);
    for (const row of [2, 3, 4, 5, 6, 7]) expect(result.nodeIds[row * 18 + 2]).toBe(1);
    for (const row of [2, 3, 4, 5, 6]) expect(result.nodeIds[row * 18 + 5]).toBe(2);
    for (const row of [2, 4, 6]) for (const col of [3, 4]) {
      expect(result.nodeIds[row * 18 + col]).toBe(0);
      expect(result.cellBgColor[row * 18 + col]).toBe(0);
    }
    expect(result.cellBgColor[2 + 3 * 18]).toBe(1);
    expect(result.cellBgColor[5 + 3 * 18]).toBe(2);
    expect(Array.from(result.cellFgColor).every((c) => c === 15)).toBe(true);
  });

  it('requires reciprocal ports and does not connect adjacent unmatched conductors', () => {
    expect(Array.from(labelPortGrid([0b0100, 0b0010], 2, 1).nodeIds)).toEqual([1, 2]);
    expect(Array.from(labelPortGrid([0b0100, 0b0001], 2, 1).nodeIds)).toEqual([1, 1]);
    expect(Array.from(labelPortGrid([0b1000, 0b0010], 1, 2).nodeIds)).toEqual([1, 1]);
  });

  it('keeps opposite grid edges and adjacent row endpoints separate', () => {
    expect(Array.from(labelPortGrid([0b0001, 0b0100, 0b0001, 0b0100], 2, 2).nodeIds)).toEqual([1, 2, 3, 4]);
    expect(Array.from(labelPortGrid([0b0010, 0b1000], 1, 2).nodeIds)).toEqual([1, 2]);
  });

  it('rotates wire, elbow, tee and ground ports according to the interface directions', () => {
    const expected: [number, number[]][] = [
      [Sprite.Wire, [0b0101, 0b1010, 0b0101, 0b1010]],
      [Sprite.Elbow, [0b0110, 0b1100, 0b1001, 0b0011]],
      [Sprite.Tee, [0b0111, 0b1110, 0b1101, 0b1011]],
      [Sprite.Ground, [0b0001, 0b0010, 0b0100, 0b1000]],
      [Sprite.Junction, [15, 15, 15, 15]],
      [Sprite.Cross, [15, 15, 15, 15]],
    ];
    for (const [sprite, masks] of expected) expect([0, 1, 2, 3].map((r) => cellPortMask(word(sprite, r)))).toEqual(masks);
  });

  it('ignores disabled cells, component halves and metadata', () => {
    expect(cellPortMask(0xfffe)).toBe(0);
    for (let sprite = 5; sprite < 15; sprite++) expect(cellPortMask(word(sprite))).toBe(0);
    expect(cellPortMask(word(Sprite.Elbow, 1) | 0xfe00)).toBe(cellPortMask(word(Sprite.Elbow, 1)));
  });

  it('recomputes merged/split node numbering after topology changes', () => {
    const cells = Uint16Array.from([word(Sprite.Wire), 0, word(Sprite.Wire)]);
    expect(Array.from(deriveConnectivity(cells, 3, 1).nodeIds)).toEqual([1, 0, 2]);
    cells[1] = word(Sprite.Wire);
    expect(Array.from(deriveConnectivity(cells, 3, 1).nodeIds)).toEqual([1, 1, 1]);
    cells[0] = 0;
    expect(Array.from(deriveConnectivity(cells, 3, 1).nodeIds)).toEqual([0, 1, 1]);
  });

  it('wraps node colours through 1..13 without using hover/foreground entries', () => {
    expect([0, 1, 13, 14, 26, 27].map(nodePaletteIndex)).toEqual([0, 1, 13, 1, 13, 1]);
    const result = labelPortGrid(new Uint8Array(18 * 16).fill(0b1000), 18, 16);
    expect(result.nodeCount).toBe(18 * 16);
    expect(result.nodeIds.at(-1)).toBe(288);
    // The software oracle retains full IDs; RTL byte-overflow is not copied.
    expect(nodePaletteIndex(result.nodeIds.at(-1)!)).toBe(2);
  });

  it('rejects inconsistent grid dimensions and invalid node indices', () => {
    expect(() => labelPortGrid([1], 2, 2)).toThrow('dimensions');
    expect(() => labelPortGrid([], 0, 0)).toThrow('dimensions');
    expect(() => nodePaletteIndex(-1)).toThrow('non-negative integer');
  });
});
