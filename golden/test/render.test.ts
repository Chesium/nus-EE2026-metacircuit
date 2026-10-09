import { existsSync, readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { DEFAULT_CONFIG, initialState, step, Tool } from '../src/core/index.ts';
import { AssetRenderer, ASSET_FILES, bundleFromRecord, capturedAnimationPhase, capturedCaretVisible, flowPixel } from '../src/render/assetRenderer.ts';
import { getPx, makeFramebuffer } from '../src/render/framebuffer.ts';
import { PlaceholderRenderer, spritePixel } from '../src/render/placeholder.ts';
import { DEFAULT_RENDER_OPTIONS } from '../src/render/renderer.ts';

const mouse = { x: 320, y: 240, left: false, middle: false, right: false };
// Boot wire at (2,3), rotation 1 (vertical): a pixel in the middle of the band.
const WIRE_PX = { x: 64 + 2 * 32 + 15, y: 64 + 3 * 32 + 10 };

describe('placeholder renderer', () => {
  it('renders the boot state with layout colours and rotated sprites', () => {
    const fb = makeFramebuffer();
    new PlaceholderRenderer().render(initialState(), mouse, fb, DEFAULT_RENDER_OPTIONS);
    expect(getPx(fb, 0, 400)).toBe(0xecc); // background
    expect(getPx(fb, 64 + 8 * 32 + 5, 64)).toBe(0x666); // grid line
    expect(getPx(fb, 64 + 8 * 32 + 10, 64 + 10)).toBe(0x222); // empty cell
    expect(getPx(fb, 64 + 8 * 32 + 10, 64 + 5 * 32 + 10)).toBe(0x280); // hovered cell (mouse at 320,240)
    expect(getPx(fb, WIRE_PX.x, WIRE_PX.y)).toBe(0xfff);
  });

  it('samples sprites with the RTL rotation transform', () => {
    const bm = Array.from({ length: 32 }, (_, r) => Array.from({ length: 32 }, (_, c) => r === 0 && c === 31)); // top-right pixel
    expect(spritePixel(bm, 0, 31, 0)).toBe(true); // identity
    expect(spritePixel(bm, 1, 31, 31)).toBe(true); // 90 deg clockwise: top-right -> bottom-right
    expect(spritePixel(bm, 2, 0, 31)).toBe(true); // 180 deg: -> bottom-left
    expect(spritePixel(bm, 3, 0, 0)).toBe(true); // 90 deg counter-clockwise: -> top-left
  });
});

const haveAssets = ASSET_FILES.every((f) => existsSync(`assets/${f}.json`));

describe.skipIf(!haveAssets)('asset renderer (golden/assets present)', () => {
  const rec = Object.fromEntries(ASSET_FILES.map((f) => [f, JSON.parse(readFileSync(`assets/${f}.json`, 'utf8'))]));

  it('loads the bundle and renders the boot state', () => {
    const { bundle, problem } = bundleFromRecord(rec);
    expect(problem).toBeUndefined();
    const fb = makeFramebuffer();
    new AssetRenderer(bundle!).render(initialState(), mouse, fb, DEFAULT_RENDER_OPTIONS);
    expect(getPx(fb, 0, 400)).toBe(0xecc);
    expect(getPx(fb, 64 + 8 * 32 + 5, 64)).toBe(0x666);
    expect(getPx(fb, 64 + 8 * 32 + 10, 64 + 10)).toBe(0x222);
    expect(getPx(fb, WIRE_PX.x, WIRE_PX.y)).toBe(0xfff);
    // Selected toolbar button 0 uses the "selected" border colour.
    const sel = parseInt(rec.toolbar.button_style.state_colors.selected.B.rgb12, 16);
    expect(getPx(fb, 14, 72)).toBe(sel);
  });

  it('reports missing files', () => {
    expect(bundleFromRecord({ canvas: rec.canvas }).problem).toMatch(/missing asset files/);
  });

  it('renders palette RAMs aligned to each cell, including its left column, and hover priority', () => {
    const s = initialState({ bootCircuit: false });
    s.cells[0] = 1; // horizontal wire
    const fg = new Uint8Array(288).fill(15), bg = new Uint8Array(288);
    fg[0] = 1; bg[0] = 2;
    const fb = makeFramebuffer();
    const r = new AssetRenderer(bundleFromRecord(rec).bundle!);
    r.render(s, mouse, fb, { drawCursor: false, hover: false, cellFgColor: fg, cellBgColor: bg, animationPhase: 20 });
    expect(getPx(fb, 74, 79)).toBe(0xc33); // foreground
    expect(getPx(fb, 74, 74)).toBe(0xe63); // node background
    expect(getPx(fb, 64, 79)).toBe(0xc33); // the wire's own left column, at the canvas edge
    expect(getPx(fb, 96, 79)).toBe(0x666); // the next (empty) cell's left column is grid, not the wire
    expect(getPx(fb, 97, 79)).toBe(0x222); // next empty cell
    r.render(s, { ...mouse, x: 74, y: 74 }, fb, { drawCursor: false, hover: true, cellBgColor: bg });
    expect(getPx(fb, 74, 74)).toBe(0x280);
    expect(getPx(fb, 74, 64)).toBe(0x666);
  });

  it('renders selected component detail, active value border, text and caret', () => {
    const fb = makeFramebuffer();
    const r = new AssetRenderer(bundleFromRecord(rec).bundle!);
    const panel = { col: 3, row: 4, word: 11, componentIndex: 1, valueText: '100k', editActive: true };
    r.render(initialState(), mouse, fb, { drawCursor: false, hover: false, propertyPanel: panel, caretVisible: true });
    expect(getPx(fb, 0, 10)).toBe(0xedc); // panel enable leaves column zero to top bar
    expect(getPx(fb, 1, 10)).toBe(0xb86);
    expect(getPx(fb, 193, 20)).toBe(0xb86);
    expect(getPx(fb, 225, 24)).toBe(0xfd0);
    expect(getPx(fb, 226, 25)).toBe(0xfed);
    expect(getPx(fb, 265, 27)).toBe(0xfd0); // caret after four characters
    // Compare every caption glyph bit; text has one extra stage over rectangles.
    for (let row = 0; row < 8; row++) for (let col = 0; col < 8; col++) {
      expect(getPx(fb, 18 + col, 10 + row)).toBe(rec.font8x8.glyphs['84'][row][col] === '1' ? 0x754 : 0xecc);
    }
    r.render(initialState(), mouse, fb, { drawCursor: false, hover: false, propertyPanel: { ...panel, word: 0 }, caretVisible: false });
    expect(getPx(fb, 225, 24)).toBe(0xecc); // empty selection only shows centred hint
  });

  it('accepts an independently sampled keypad mouse', () => {
    const fb = makeFramebuffer();
    const key = rec.keypad.keys[0];
    new AssetRenderer(bundleFromRecord(rec).bundle!).render(initialState(), mouse, fb,
      { drawCursor: false, hover: false, keypadMouse: { ...mouse, x: key.x0 + 4, y: key.y0 + 4, left: true } });
    const role = key.role_map[0][0];
    expect(getPx(fb, key.x0, key.y0)).toBe(parseInt(key.state_colors.selected_pressed[role].rgb12, 16));
  });

  it('keeps the new component input empty until keypad text is entered', () => {
    const s = initialState({ bootCircuit: false });
    s.tool = Tool.Resistor;
    const placed = step(s, { ...mouse, x: 240, y: 176, left: true }, { ...DEFAULT_CONFIG, inputLatencyFrames: 0 });
    const fb = makeFramebuffer();
    new AssetRenderer(bundleFromRecord(rec).bundle!).render(placed, placed.prevMouse, fb, { drawCursor: false, hover: false });
    for (let y = 30; y < 38; y++) for (let x = 234; x < 258; x++) expect(getPx(fb, x, y)).toBe(0xfed);
  });
});

describe('frame-locked animation', () => {
  it('uses startup-calibrated capture phases and wraps', () => {
    expect([1, 2, 3, 4, 5, 6].map(capturedAnimationPhase)).toEqual([1, 1, 2, 2, 3, 3]);
    expect(capturedAnimationPhase(63)).toBe(0);
    expect(capturedCaretVisible(8)).toBe(false);
    expect(capturedCaretVisible(9)).toBe(true);
    expect(capturedCaretVisible(19)).toBe(false);
  });

  it('moves both directions, rotates bands and keeps component centre highlights off grid edges', () => {
    expect(flowPixel(1, 3, 15, 3, true)).toBe(true);
    expect(flowPixel(1, 2, 15, 3, true)).toBe(false);
    expect(flowPixel(0x201, 29, 15, 3, true)).toBe(true);
    expect(flowPixel(0x81, 15, 3, 3, true)).toBe(true);
    expect(flowPixel(11, 3, 15, 3, false)).toBe(true); // resistor centre through gap
    expect(flowPixel(11, 3, 12, 3, false)).toBe(false);
    expect(flowPixel(11, 31, 15, 31, false)).toBe(false);
    expect(flowPixel(0, 3, 15, 3, true)).toBe(false);
  });
});
