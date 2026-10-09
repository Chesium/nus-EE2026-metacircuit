import { existsSync, readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { initialState } from '../src/core/index.ts';
import { AssetRenderer, ASSET_FILES, bundleFromRecord } from '../src/render/assetRenderer.ts';
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
});
