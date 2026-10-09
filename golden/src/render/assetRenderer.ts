// Renderer built from the GM-4 assets (golden/assets/*.json, format in
// golden/assets/README.md). It follows the documented pixel rules, including the
// canvas one-pixel data lag and the cursor's displayed sprites. Not modelled yet
// (so not authoritative): property-panel text, flood node colours (fg/bg colour
// RAMs are taken as the defaults), the flow animation, and the keypad's 20 Hz lag.

import { decodeCell } from '../core/encoding.ts';
import { screenToCell } from '../core/geometry.ts';
import type { GoldenState, MouseSnapshot } from '../core/state.ts';
import { type Framebuffer, fillRect, setPx } from './framebuffer.ts';
import type { RenderOptions, Renderer } from './renderer.ts';

// ---------------------------------------------------------------- asset JSON shapes (subset we use)

interface Color { rgb12: string }
type Rows = string[];
type StateColors = Record<'normal' | 'selected' | 'pressed' | 'selected_pressed', Record<string, Color>>;

export interface AssetBundle {
  canvas: {
    schema_version: number;
    sprites: { id: number; rows: Rows }[];
    palette: { index: number; rgb12: string }[];
    colors: { grid: Color; default_fg_idx: number; default_bg_idx: number; hover_bg_idx: number };
    geometry: { canvas_x0: number; canvas_y0: number; canvas_w: number; canvas_h: number; cell_size: number; grid_w: number; grid_h: number };
  };
  toolbar: {
    region: { x0: number; y0: number; w: number; h: number; background: Color };
    buttons: { index: number; x0: number; y0: number; w: number; h: number; icon_x0: number; icon_y0: number; icon: number | { by_wire_variant: Record<string, number> } }[];
    icons: Record<string, { rows: Rows }>;
    icon_format: { color: Color };
    button_style: { role_map: Rows; state_colors: StateColors };
  };
  cursor: {
    sprites_as_displayed: { hover: Rows; pressed: Rows };
    colors: Record<string, Color>;
    placement: { sprite_origin_offset: [number, number]; visible_columns: [number, number] };
  };
  keypad: {
    region: { x0: number; y0: number; w: number; h: number; background: Color };
    keys: { enabled: boolean; x0: number; y0: number; w: number; h: number; role_map?: Rows; state_colors?: StateColors }[];
  };
  screen: {
    background: Color;
    bars: {
      top_bar: { fill: Color; grid_line: Color; boxes: [number, number, number, number][]; box_fill: Color };
      right_bar: { fill: Color; grid_line: Color; frames: { rects: [number, number, number, number][]; color: Color } };
    };
    property_panel_colors: { COLOR_BG: Color };
  };
}

export const ASSET_FILES = ['canvas', 'toolbar', 'cursor', 'keypad', 'screen'] as const;

/** Build a bundle from {name: parsed JSON}; returns null (with the reason) when something is missing. */
export function bundleFromRecord(rec: Record<string, unknown>): { bundle: AssetBundle | null; problem?: string } {
  const missing = ASSET_FILES.filter((f) => !rec[f]);
  if (missing.length) return { bundle: null, problem: `missing asset files: ${missing.map((m) => `${m}.json`).join(', ')}` };
  const b = rec as unknown as AssetBundle;
  if (b.canvas.schema_version !== 1) return { bundle: null, problem: `unsupported canvas.json schema_version ${b.canvas.schema_version}` };
  return { bundle: b };
}

const c12 = (c: Color | string) => parseInt(typeof c === 'string' ? c : c.rgb12, 16);

// ---------------------------------------------------------------- renderer

export class AssetRenderer implements Renderer {
  readonly name = 'assets';
  readonly authoritative = false;
  private readonly sprites: Uint8Array[]; // per id: 32*32 bits, row-major [row*32+col]
  private readonly palette: number[];
  private readonly icons: Map<number, Uint8Array>;

  constructor(private readonly a: AssetBundle) {
    this.sprites = [];
    for (const s of a.canvas.sprites) this.sprites[s.id] = rowsToBits(s.rows);
    this.palette = a.canvas.palette.map((p) => c12(p.rgb12));
    this.icons = new Map(Object.entries(a.toolbar.icons).map(([k, v]) => [Number(k), rowsToBits(v.rows)]));
  }

  render(s: GoldenState, mouse: MouseSnapshot, fb: Framebuffer, opts: RenderOptions): void {
    const A = this.a;
    // Background and bars (screen.json ui_rule), then the property panel's fill over the top bar.
    fillRect(fb, 0, 0, fb.width, fb.height, c12(A.screen.background));
    this.rightBar(fb);
    fillRect(fb, 0, 0, 640, 64, c12(A.screen.property_panel_colors.COLOR_BG));
    this.toolbar(s, mouse, fb);
    this.canvas(s, mouse, fb, opts);
    this.keypad(mouse, fb);
    if (opts.drawCursor) this.cursor(mouse, fb);
  }

  private rightBar(fb: Framebuffer): void {
    const rb = this.a.screen.bars.right_bar;
    const fill = c12(rb.fill);
    const grid = c12(rb.grid_line);
    const frame = c12(rb.frames.color);
    for (let y = 64; y < 480; y++) {
      for (let x = 484; x < 640; x++) {
        let c = x % 32 === 0 || y % 32 === 0 ? grid : fill;
        for (const [x0, x1, y0, y1] of rb.frames.rects) {
          const inside = x >= x0 && x < x1 && y >= y0 && y < y1;
          const edge = x < x0 + 2 || x >= x1 - 2 || y === y0 || y === y1 - 1;
          if (inside && edge) c = frame;
        }
        setPx(fb, x, y, c);
      }
    }
  }

  private toolbar(s: GoldenState, mouse: MouseSnapshot, fb: Framebuffer): void {
    const t = this.a.toolbar;
    fillRect(fb, t.region.x0, t.region.y0, t.region.w, t.region.h, c12(t.region.background));
    const roleMap = t.button_style.role_map;
    const iconColor = c12(t.icon_format.color);
    for (const b of t.buttons) {
      const inBox = mouse.x >= b.x0 && mouse.x < b.x0 + b.w && mouse.y >= b.y0 && mouse.y < b.y0 + b.h;
      const selected = s.tool === b.index;
      const pressed = mouse.left && inBox;
      const state = selected && pressed ? 'selected_pressed' : selected ? 'selected' : pressed ? 'pressed' : 'normal';
      const colors = t.button_style.state_colors[state];
      for (let ly = 0; ly < b.h; ly++) {
        for (let lx = 0; lx < b.w; lx++) {
          const role = roleMap[ly]![lx]!;
          setPx(fb, b.x0 + lx, b.y0 + ly, c12(colors[role]!));
        }
      }
      const iconIdx = typeof b.icon === 'number' ? b.icon : b.icon.by_wire_variant[String(s.wireVariant & 3)]!;
      const bits = this.icons.get(iconIdx);
      if (bits) {
        for (let r = 0; r < 24; r++) for (let c = 0; c < 24; c++) if (bits[r * 24 + c]) setPx(fb, b.icon_x0 + c, b.icon_y0 + r, iconColor);
      }
    }
  }

  private canvas(s: GoldenState, mouse: MouseSnapshot, fb: Framebuffer, opts: RenderOptions): void {
    const g = this.a.canvas.geometry;
    const col = this.a.canvas.colors;
    const grid = c12(col.grid);
    const fg = this.palette[col.default_fg_idx] ?? 0xfff;
    const bg = this.palette[col.default_bg_idx] ?? 0x222;
    const hoverBg = this.palette[col.hover_bg_idx] ?? 0x280;
    const hover = opts.hover ? screenToCell(mouse.x, mouse.y, s.panX, s.panY) : null;
    const cellAt = (i: number, j: number): number =>
      i >= 0 && j >= 0 && i < g.grid_w && j < g.grid_h ? s.cells[i + j * g.grid_w]! : 0;
    for (let y = g.canvas_y0; y < g.canvas_y0 + g.canvas_h; y++) {
      const ay = y - g.canvas_y0 - s.panY;
      const j = Math.floor(ay / g.cell_size);
      const dy = ay - j * g.cell_size;
      for (let x = g.canvas_x0; x < g.canvas_x0 + g.canvas_w; x++) {
        const ax = x - g.canvas_x0 - s.panX;
        const i = Math.floor(ax / g.cell_size);
        const dx = ax - i * g.cell_size;
        // One-pixel data lag: the cell word is the one fetched for x - 1.
        let word = 0;
        if (x > g.canvas_x0) {
          const pax = ax - 1;
          word = cellAt(Math.floor(pax / g.cell_size), j);
        }
        const cell = decodeCell(word);
        const bits = cell.enabled ? this.sprites[cell.sprite] : undefined;
        const sprite = !!bits && samplePixel(bits, cell.rotation, dx, dy);
        const visible = sprite && dx !== 31 && dy !== 31;
        const isGrid = dx < 1 || dy < 1 || dx >= 31 || dy >= 31;
        let c: number;
        if (visible) c = fg;
        else if (isGrid) c = grid;
        else c = hover && hover.col === i && hover.row === j ? hoverBg : bg;
        setPx(fb, x, y, c);
      }
    }
  }

  private keypad(mouse: MouseSnapshot, fb: Framebuffer): void {
    const k = this.a.keypad;
    fillRect(fb, k.region.x0, k.region.y0, k.region.w, k.region.h, c12(k.region.background));
    for (const key of k.keys) {
      if (!key.enabled || !key.role_map || !key.state_colors) continue;
      const over = mouse.x >= key.x0 && mouse.x < key.x0 + key.w && mouse.y >= key.y0 && mouse.y < key.y0 + key.h;
      const colors = key.state_colors[over ? (mouse.left ? 'selected_pressed' : 'selected') : 'normal'];
      for (let ly = 0; ly < key.h; ly++) {
        for (let lx = 0; lx < key.w; lx++) {
          const c = colors[key.role_map[ly]![lx]!];
          if (c) setPx(fb, key.x0 + lx, key.y0 + ly, c12(c));
        }
      }
    }
  }

  private cursor(mouse: MouseSnapshot, fb: Framebuffer): void {
    const cu = this.a.cursor;
    const rows = mouse.left ? cu.sprites_as_displayed.pressed : cu.sprites_as_displayed.hover;
    const [ox, oy] = cu.placement.sprite_origin_offset;
    const [c0, c1] = cu.placement.visible_columns;
    rows.forEach((row, r) => {
      for (let c = c0; c <= c1 && c < row.length; c++) {
        const ch = row[c]!;
        const color = cu.colors[ch];
        if (color) setPx(fb, mouse.x + c + ox, mouse.y + r + oy, c12(color));
      }
    });
  }
}

function rowsToBits(rows: Rows): Uint8Array {
  const h = rows.length;
  const w = rows[0]?.length ?? 0;
  const out = new Uint8Array(w * h);
  rows.forEach((row, r) => {
    for (let c = 0; c < w; c++) out[r * w + c] = row[c] === '1' ? 1 : 0;
  });
  return out;
}

/** Sprite sampling per canvas.json rotation.codes: (src_row, src_col) for each rotation. */
function samplePixel(bits: Uint8Array, ro: number, dx: number, dy: number): boolean {
  let r: number;
  let c: number;
  switch (ro & 3) {
    case 0: r = dy; c = dx; break;
    case 1: r = 31 - dx; c = dy; break;
    case 2: r = 31 - dy; c = 31 - dx; break;
    default: r = dx; c = 31 - dy; break;
  }
  return bits[r * 32 + c] === 1;
}
