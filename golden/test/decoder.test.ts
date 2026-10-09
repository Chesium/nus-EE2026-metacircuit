import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import {
  type DecoderCanvasAssets, type DecoderCursorAssets, type PixelFrame, VisibleCellDecoder, diffVisibleCells,
} from '../src/render/decoder.ts';
import { makeFramebuffer, setPx } from '../src/render/framebuffer.ts';

const canvas = JSON.parse(readFileSync('assets/canvas.json', 'utf8')) as DecoderCanvasAssets;
const cursor = JSON.parse(readFileSync('assets/cursor.json', 'utf8')) as DecoderCursorAssets;
const decoder = new VisibleCellDecoder(canvas, cursor);

function blank(): PixelFrame {
  return { width: 640, height: 480, data: new Uint16Array(640 * 480).fill(0x222) };
}

// Fixture uses a source-to-destination transform, rather than the decoder's
// destination-to-source lookup. Neither renderer nor state decoder is involved.
function draw(frame: PixelFrame, col: number, row: number, sprite: number, rotation: number, options: {
  panX?: number; panY?: number; foreground?: number; background?: number;
} = {}) {
  const fg = options.foreground ?? 0xfff;
  const bg = options.background ?? 0x222;
  const x0 = 64 + (options.panX ?? 0) + col * 32;
  const y0 = 64 + (options.panY ?? 0) + row * 32;
  const bits = canvas.sprites.find((s) => s.id === sprite)!.rows;
  for (let y = 1; y < 31; y++) for (let x = 1; x < 31; x++) put(x0 + x, y0 + y, bg);
  for (let r = 0; r < 32; r++) for (let c = 0; c < 32; c++) {
    if (bits[r]![c] !== '1') continue;
    let dx = c; let dy = r;
    if (rotation === 1) { dx = 31 - r; dy = c; }
    if (rotation === 2) { dx = 31 - c; dy = 31 - r; }
    if (rotation === 3) { dx = r; dy = 31 - c; }
    if (dx > 0 && dx < 31 && dy > 0 && dy < 31) put(x0 + dx, y0 + dy, fg);
  }
  function put(x: number, y: number, color: number) {
    if (x < 64 || x >= 640 || y < 64 || y >= 352) return;
    (frame.data as Uint16Array)[y * frame.width + x] = color;
  }
}

function cell(result: ReturnType<VisibleCellDecoder['decode']>, col: number, row: number) {
  return result.cells.find((c) => c.col === col && c.row === row)!;
}

describe('independent pixel cell decoder', () => {
  it('recognises all GM-4 sprites and rotations with inferred foreground/background colours', () => {
    const frame = blank();
    for (let sprite = 0; sprite < 16; sprite++) for (let rotation = 0; rotation < 4; rotation++) {
      const i = sprite * 4 + rotation;
      draw(frame, i % 18, Math.floor(i / 18), sprite, rotation, { foreground: 0x2b7, background: 0x280 });
    }
    const result = decoder.decode(frame);
    expect(result.errors).toEqual([]);
    expect(result.cells).toHaveLength(18 * 9);
    for (let sprite = 0; sprite < 16; sprite++) for (let rotation = 0; rotation < 4; rotation++) {
      const i = sprite * 4 + rotation;
      expect(cell(result, i % 18, Math.floor(i / 18)).candidates).toContainEqual({
        sprite, spriteName: canvas.sprites.find((s) => s.id === sprite)!.name!, rotation, foreground: 0x2b7, background: 0x280,
      });
    }
    expect(cell(result, 17, 8).candidates[0]?.sprite).toBeNull();
  });

  it('retains symmetric rotation aliases and matches them without inventing a rotation', () => {
    const horizontal = blank();
    const reverse = blank();
    draw(horizontal, 2, 3, 0, 0);
    draw(reverse, 2, 3, 0, 2);
    const decoded = decoder.decode(horizontal);
    expect(cell(decoded, 2, 3).status).toBe('ambiguous');
    expect(cell(decoded, 2, 3).candidates.map((c) => c.rotation)).toEqual([0, 2]);
    expect(diffVisibleCells(decoded, decoder.decode(reverse))).toEqual([]);
  });

  it('handles panning and clips partial cells to the canvas viewport', () => {
    const frame = blank();
    draw(frame, 4, 3, 15, 1, { panY: -73 });
    draw(frame, 4, 2, 2, 3, { panY: -73 });
    const result = decoder.decode(frame, { panY: -73 });
    expect(result.cells[0]?.row).toBe(2);
    expect(cell(result, 4, 3).candidates.some((c) => c.sprite === 15 && c.rotation === 1)).toBe(true);
    expect(cell(result, 4, 2).evidence.clippedPixels).toBeGreaterThan(0);
    expect(result.errors).toEqual([]);
  });

  it('accepts RGBA8888 frames and preserves the high-nibble RGB444 contract', () => {
    const frame = blank();
    draw(frame, 1, 1, 15, 3);
    const rgba = makeFramebuffer();
    for (let y = 0; y < frame.height; y++) for (let x = 0; x < frame.width; x++) {
      setPx(rgba, x, y, frame.data[y * frame.width + x]!);
    }
    expect(decoder.decode(rgba)).toEqual(decoder.decode(frame));
  });

  it('ignores cell boundary columns and grid borders', () => {
    const frame = blank();
    draw(frame, 3, 4, 15, 2);
    const before = decoder.decode(frame);
    for (let offset = 0; offset < 32; offset++) for (const edge of [0, 31]) {
      frame.data[(64 + 4 * 32 + offset) * 640 + 64 + 3 * 32 + edge] = 0xf00;
      frame.data[(64 + 4 * 32 + edge) * 640 + 64 + 3 * 32 + offset] = 0xf00;
    }
    expect(decoder.decode(frame)).toEqual(before);
  });

  it.each([false, true])('masks only opaque cursor pixels (pressed=%s)', (left) => {
    const frame = blank();
    draw(frame, 2, 3, 15, 0);
    const mouse = { x: 64 + 2 * 32 + 2, y: 64 + 3 * 32 + 2, left };
    const rows = left ? cursor.sprites_as_displayed.pressed : cursor.sprites_as_displayed.hover;
    rows.forEach((r, y) => [...r].forEach((ch, x) => {
      if (cursor.colors[ch]) frame.data[(mouse.y + y) * 640 + mouse.x + x + 2] = Number.parseInt(cursor.colors[ch]!.rgb12, 16);
    }));
    expect(cell(decoder.decode(frame), 2, 3).status).toBe('unknown');
    const result = decoder.decode(frame, { mouse });
    expect(result.errors).toEqual([]);
    const covered = cell(result, 2, 3);
    expect(covered.evidence.maskedPixels).toBeGreaterThan(0);
    expect(covered.candidates.some((c) => c.sprite === 15 && c.rotation === 0)).toBe(true);
  });

  it('marks a completely excluded cell as occluded and distinguishes no evidence from a successful compare', () => {
    const expected = decoder.decode(blank());
    const actual = decoder.decode(blank(), { excludeRects: [{ x: 128, y: 160, width: 32, height: 32 }] });
    expect(cell(actual, 2, 3).status).toBe('occluded');
    expect(cell(actual, 2, 3).candidates).toEqual([]);
    expect(diffVisibleCells(expected, actual)).toContain('cell (2,3) has no unmasked actual pixels');
  });

  it('reports a corrupted interior pixel with screen-coordinate evidence', () => {
    const frame = blank();
    draw(frame, 3, 4, 15, 1);
    const reference = decoder.decode(frame);
    const x = 64 + 3 * 32 + 10; const y = 64 + 4 * 32 + 10;
    frame.data[y * 640 + x] = 0xf00; // outside the extracted palette
    const actual = decoder.decode(frame);
    const damaged = cell(actual, 3, 4);
    expect(damaged.status).toBe('unknown');
    expect(damaged.evidence.mismatchedPixels).toBe(1);
    expect(damaged.evidence.mismatches).toEqual([{ x, y, actual: 0xf00, expected: 0x222 }]);
    expect(actual.errors[0]).toContain('cell (3,4)');
    expect(diffVisibleCells(reference, actual)[0]).toContain('1 unclassified actual pixels');
  });

  it('produces useful sprite, rotation and colour mismatch descriptions', () => {
    const reference = blank();
    const actual = blank();
    draw(reference, 3, 4, 5, 1);
    draw(actual, 3, 4, 6, 1, { foreground: 0xc33 });
    const errors = diffVisibleCells(decoder.decode(reference), decoder.decode(actual));
    expect(errors).toHaveLength(1);
    expect(errors[0]).toContain('cell (3,4) is RR rot 1 fg 0xc33');
    expect(errors[0]).toContain('expected RL rot 1 fg 0xfff');
  });

  it('keeps flow-colour masking explicit', () => {
    const frame = blank();
    draw(frame, 2, 3, 15, 0);
    frame.data[(64 + 3 * 32 + 10) * 640 + 64 + 2 * 32 + 10] = 0xff0;
    expect(decoder.decode(frame).errors).toHaveLength(1);
    expect(decoder.decode(frame, { maskColors: [0xff0] }).errors).toEqual([]);
  });

  it('rejects malformed frames, assets and fractional pan offsets', () => {
    expect(() => decoder.decode({ width: 640, height: 480, data: new Uint16Array(1) })).toThrow('invalid framebuffer');
    expect(() => decoder.decode(blank(), { panY: 0.5 })).toThrow('integer pixels');
    expect(() => new VisibleCellDecoder({ ...canvas, sprites: [{ id: 0, rows: ['broken'] }] })).toThrow('invalid GM-4 sprite');
  });
});
