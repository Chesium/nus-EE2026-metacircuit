// A 640x480 RGBA framebuffer plus the few raster primitives the renderers need.
// Pure TypeScript, so renders work headlessly in Node as well as in the browser.

import { SCREEN_H, SCREEN_W } from '../core/constants.ts';

export interface Framebuffer {
  width: number;
  height: number;
  /** RGBA, 8 bits per channel, row-major (same layout as ImageData.data). */
  data: Uint8ClampedArray;
}

export function makeFramebuffer(width = SCREEN_W, height = SCREEN_H): Framebuffer {
  return { width, height, data: new Uint8ClampedArray(width * height * 4) };
}

/** Expand a 12-bit RGB444 colour (as used by the RTL) to [r, g, b] 8-bit. */
export function rgb444(c: number): [number, number, number] {
  const e = (n: number) => (n << 4) | n;
  return [e((c >> 8) & 0xf), e((c >> 4) & 0xf), e(c & 0xf)];
}

/** Quantise a 24-bit RGB888 colour to RGB444 the way the RTL does (top nibble of each channel). */
export function rgb888to444(c: number): number {
  return (((c >> 20) & 0xf) << 8) | (((c >> 12) & 0xf) << 4) | ((c >> 4) & 0xf);
}

const NIBBLE = (n: number) => (n << 4) | n;

export function setPx(fb: Framebuffer, x: number, y: number, c444: number): void {
  if (x < 0 || y < 0 || x >= fb.width || y >= fb.height) return;
  const i = (y * fb.width + x) * 4;
  fb.data[i] = NIBBLE((c444 >> 8) & 0xf);
  fb.data[i + 1] = NIBBLE((c444 >> 4) & 0xf);
  fb.data[i + 2] = NIBBLE(c444 & 0xf);
  fb.data[i + 3] = 255;
}

/** Read back a pixel as RGB444 (tests, comparisons). */
export function getPx(fb: Framebuffer, x: number, y: number): number {
  const i = (y * fb.width + x) * 4;
  return ((fb.data[i]! >> 4) << 8) | ((fb.data[i + 1]! >> 4) << 4) | (fb.data[i + 2]! >> 4);
}

export function fillRect(fb: Framebuffer, x0: number, y0: number, w: number, h: number, c444: number): void {
  const [r, g, b] = rgb444(c444);
  const xa = Math.max(0, x0);
  const ya = Math.max(0, y0);
  const xb = Math.min(fb.width, x0 + w);
  const yb = Math.min(fb.height, y0 + h);
  for (let y = ya; y < yb; y++) {
    let i = (y * fb.width + xa) * 4;
    for (let x = xa; x < xb; x++, i += 4) {
      fb.data[i] = r;
      fb.data[i + 1] = g;
      fb.data[i + 2] = b;
      fb.data[i + 3] = 255;
    }
  }
}

export function strokeRect(fb: Framebuffer, x0: number, y0: number, w: number, h: number, t: number, c444: number): void {
  fillRect(fb, x0, y0, w, t, c444);
  fillRect(fb, x0, y0 + h - t, w, t, c444);
  fillRect(fb, x0, y0, t, h, c444);
  fillRect(fb, x0 + w - t, y0, t, h, c444);
}

/** A 1-bit bitmap: rows of booleans, bitmap[row][col]. */
export type Bitmap = boolean[][];

export function blankBitmap(w: number, h: number): Bitmap {
  return Array.from({ length: h }, () => new Array<boolean>(w).fill(false));
}

export function bmSet(bm: Bitmap, x: number, y: number, brush = 1): void {
  const r = Math.floor(brush / 2);
  for (let dy = -r; dy < brush - r; dy++) {
    for (let dx = -r; dx < brush - r; dx++) {
      const row = bm[y + dy];
      if (row && x + dx >= 0 && x + dx < row.length) row[x + dx] = true;
    }
  }
}

export function bmLine(bm: Bitmap, x0: number, y0: number, x1: number, y1: number, brush = 1): void {
  const steps = Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0), 1);
  for (let i = 0; i <= steps; i++) {
    bmSet(bm, Math.round(x0 + ((x1 - x0) * i) / steps), Math.round(y0 + ((y1 - y0) * i) / steps), brush);
  }
}

export function bmCircle(bm: Bitmap, cx: number, cy: number, r: number, brush = 1): void {
  const n = Math.max(16, Math.ceil(2 * Math.PI * r));
  for (let i = 0; i < n; i++) {
    const a = (2 * Math.PI * i) / n;
    bmSet(bm, Math.round(cx + r * Math.cos(a)), Math.round(cy + r * Math.sin(a)), brush);
  }
}

export function bmArc(bm: Bitmap, cx: number, cy: number, r: number, a0: number, a1: number, brush = 1): void {
  const n = Math.max(8, Math.ceil(Math.abs(a1 - a0) * r));
  for (let i = 0; i <= n; i++) {
    const a = a0 + ((a1 - a0) * i) / n;
    bmSet(bm, Math.round(cx + r * Math.cos(a)), Math.round(cy + r * Math.sin(a)), brush);
  }
}
