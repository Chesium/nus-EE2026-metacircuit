// Renderer interface. The placeholder renderer (placeholder.ts) draws clear but
// non-authoritative graphics; a pixel-exact renderer built from the GM-4 assets
// (golden/assets/*.json) plugs in behind the same interface (GM-5).

import type { GoldenState, MouseSnapshot } from '../core/state.ts';
import type { Framebuffer } from './framebuffer.ts';

export interface RenderOptions {
  /** Draw the hardware-style cursor at the mouse snapshot position. */
  drawCursor: boolean;
  /** Highlight the canvas cell under the cursor. */
  hover: boolean;
}

export interface Renderer {
  readonly name: string;
  /** True if the output is meant to match the RTL pixel for pixel. */
  readonly authoritative: boolean;
  render(state: GoldenState, mouse: MouseSnapshot, fb: Framebuffer, opts: RenderOptions): void;
}

export const DEFAULT_RENDER_OPTIONS: RenderOptions = { drawCursor: true, hover: true };
