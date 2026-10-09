// Renderer built from the GM-4 assets (golden/assets/*.json, format in
// golden/assets/README.md). It follows the documented pixel rules, including the
// canvas one-pixel data lag, property text's extra register, and the cursor's
// displayed sprites. Colour RAMs and independent keypad/caret samples can be
// supplied by the caller; otherwise node colours come from the independent
// settled connectivity graph. See INTERFACE_FACTS IF-030–034.

import { decodeCell } from '../core/encoding.ts';
import { deriveConnectivity } from '../core/connectivity.ts';
import { selectedProperties } from '../core/properties.ts';
import { screenToCell } from '../core/geometry.ts';
import type { GoldenState, MouseSnapshot } from '../core/state.ts';
import { type Framebuffer, fillRect, setPx } from './framebuffer.ts';
import type { PropertyPanelSnapshot, RenderOptions, Renderer } from './renderer.ts';

// ---------------------------------------------------------------- asset JSON shapes (subset we use)

interface Color { rgb12: string }
type Rows = string[];
type StateColors = Record<'normal' | 'selected' | 'pressed' | 'selected_pressed', Record<string, Color>>;

export interface AssetBundle {
  canvas: {
    schema_version: number;
    sprites: { id: number; rows: Rows }[];
    palette: { index: number; rgb12: string }[];
    colors: { grid: Color; flow_yellow: Color; default_fg_idx: number; default_bg_idx: number; hover_bg_idx: number };
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
    property_panel_colors: Record<string, Color>;
    property_panel_layout: Record<string, number>;
  };
  font8x8: { glyphs: Record<string, Rows> };
}

export const ASSET_FILES = ['canvas', 'toolbar', 'cursor', 'keypad', 'screen', 'font8x8'] as const;

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
  readonly authoritative = true;
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
    this.propertyPanel(s, fb, opts);
    this.toolbar(s, mouse, fb);
    this.canvas(s, mouse, fb, opts);
    this.keypad(opts.keypadMouse ?? mouse, fb);
    if (opts.drawCursor) this.cursor(mouse, fb);
  }

  private propertyPanel(s: GoldenState, fb: Framebuffer, opts: RenderOptions): void {
    const colors = this.a.screen.property_panel_colors;
    const p = this.a.screen.property_panel_layout;
    const color = (name: string) => c12(colors[name]!);
    const x0 = p.PANEL_X! + 1, y0 = p.PANEL_Y!, w = p.PANEL_W!, h = p.PANEL_H!;
    // The panel enable/color register leaves x=0 to the unregistered top bar.
    fillRect(fb, 0, 0, 1, h, c12(this.a.screen.bars.top_bar.grid_line));
    fillRect(fb, x0, y0, w, h, color('COLOR_BG'));
    const selected = opts.propertyPanel ?? panelFromState(s);
    if (!selected) return;
    const cell = decodeCell(selected.word);
    const editable = cell.enabled && cell.sprite >= 5 && cell.sprite <= 14;
    const hint = !cell.enabled;
    const texts: { text: string; x: number; y: number; color: number }[] = [];
    const caption = color('COLOR_CAPTION'), ink = color('COLOR_TEXT');
    if (hint) {
      const text = 'Click component';
      texts.push({ text, x: x0 + Math.floor((w - text.length * 8) / 2), y: p.HINT_Y!, color: ink });
    } else {
      texts.push({ text: 'Type', x: p.TYPE_X!, y: p.TITLE_Y!, color: caption });
      texts.push({ text: 'Pos/Idx', x: p.POS_X!, y: p.TITLE_Y!, color: caption });
      texts.push({ text: SPRITE_LABELS[cell.sprite] ?? 'Click component', x: p.TYPE_X!, y: p.CONTENT_Y!, color: ink });
      const index = selected.componentIndex === null ? '---' : String(selected.componentIndex).padStart(3, '0');
      const coords = `#${index} (${String(selected.col).padStart(2, '0')}, ${String(selected.row).padStart(2, '0')})`;
      texts.push({ text: coords, x: p.POS_X!, y: p.CONTENT_Y!, color: ink });
      if (editable) {
        texts.push({ text: 'Value', x: p.VALUE_X!, y: p.TITLE_Y!, color: caption });
        texts.push({ text: selected.valueText.slice(0, 8), x: p.INPUT_X!, y: p.INPUT_Y!, color: ink });
        fillRect(fb, p.VALUE_BOX_X0! + 1, p.VALUE_BOX_Y0!, p.VALUE_BOX_X1! - p.VALUE_BOX_X0!, p.VALUE_BOX_Y1! - p.VALUE_BOX_Y0!, color('COLOR_BOX_BG'));
        for (const x of [p.SEP0_X!, p.SEP1_X!]) fillRect(fb, x + 1, p.SEP_Y0!, 1, p.SEP_Y1! - p.SEP_Y0!, color('COLOR_BORDER'));
        if (selected.editActive && (opts.caretVisible ?? capturedCaretVisible(s.frame))) {
          fillRect(fb, p.INPUT_X! + 1 + Math.min(selected.valueText.length, 7) * 8, p.VALUE_BOX_Y0! + 3, 2,
            p.VALUE_BOX_Y1! - p.VALUE_BOX_Y0! - 6, color('COLOR_BOX_ACTIVE'));
        }
      }
    }
    // DynamicTextBox adds one more pixel register than the panel rectangles.
    // With framescope de_delay=2, glyphs appear two pixels right of their origin.
    for (const text of texts) this.text(fb, text.text, text.x + (hint ? 1 : 2), text.y, text.color);
    if (editable) {
      const c = color(selected.editActive ? 'COLOR_BOX_ACTIVE' : 'COLOR_BOX_BORDER');
      rectBorder(fb, p.VALUE_BOX_X0! + 1, p.VALUE_BOX_Y0!, p.VALUE_BOX_X1! - p.VALUE_BOX_X0!, p.VALUE_BOX_Y1! - p.VALUE_BOX_Y0!, c);
    }
    rectBorder(fb, x0, y0, w, h, color('COLOR_BORDER'));
  }

  private text(fb: Framebuffer, text: string, x: number, y: number, color: number): void {
    for (let k = 0; k < text.length; k++) {
      const glyph = this.a.font8x8.glyphs[String(text.charCodeAt(k))];
      if (!glyph) continue;
      for (let r = 0; r < 8; r++) for (let c = 0; c < 8; c++) {
        if (glyph[r]![c] === '1') setPx(fb, x + k * 8 + c, y + r, color);
      }
    }
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
    const nodes = !s.cellFgColor || !s.cellBgColor ? deriveConnectivity(s.cells) : null;
    const fgColors = opts.cellFgColor ?? s.cellFgColor ?? nodes!.cellFgColor;
    const bgColors = opts.cellBgColor ?? s.cellBgColor ?? nodes!.cellBgColor;
    const phase = opts.animationPhase ?? capturedAnimationPhase(s.frame);
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
        let dataAddr = -1;
        if (x > g.canvas_x0) {
          const pax = ax - 1;
          const pi = Math.floor(pax / g.cell_size);
          word = cellAt(pi, j);
          if (pi >= 0 && pi < g.grid_w && j >= 0 && j < g.grid_h) dataAddr = pi + j * g.grid_w;
        }
        const fgIdx = dataAddr < 0 ? col.default_fg_idx : (fgColors?.[dataAddr] ?? col.default_fg_idx) & 15;
        const bgIdx = dataAddr < 0 ? col.default_bg_idx : (bgColors?.[dataAddr] ?? col.default_bg_idx) & 15;
        const fg = this.palette[fgIdx] ?? 0xfff;
        const bg = this.palette[bgIdx] ?? 0x222;
        const cell = decodeCell(word);
        const bits = cell.enabled ? this.sprites[cell.sprite] : undefined;
        const sprite = !!bits && samplePixel(bits, cell.rotation, dx, dy);
        const visible = sprite && dx !== 31 && dy !== 31;
        const isGrid = dx < 1 || dy < 1 || dx >= 31 || dy >= 31;
        let c: number;
        if (flowPixel(word, dx, dy, phase, visible)) c = c12(col.flow_yellow);
        else if (visible) c = fg;
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

const SPRITE_LABELS = ['Wire', 'Elbow', 'Tee', 'Junction', undefined, 'Resistor', 'Resistor',
  'Voltage Source', 'Voltage Source', 'Current Source', 'Current Source', 'Inductor', 'Inductor',
  'Capacitor', 'Capacitor', 'Ground'];

function panelFromState(s: GoldenState): PropertyPanelSnapshot | null {
  const ui = s as GoldenState & { selectedCell?: { col: number; row: number } | null; valueEditActive?: boolean };
  const selected = ui.selectedCell;
  if (!selected) return null;
  const addr = selected.col + selected.row * 18;
  const index = s.componentIndexMap[addr];
  const component = index === undefined || index === 0x1ff ? null : s.components[index];
  // The displayed identifier is the row-major live-component rank. Internal
  // golden slots retain the accepted smallest-free-slot semantic (A-011).
  const displayIndex = component ? s.components.filter((c) => c &&
    c.row * 18 + c.col < component.row * 18 + component.col).length : null;
  return { ...selected, word: s.cells[addr] ?? 0, componentIndex: displayIndex,
    valueText: selectedProperties(s).valueText,
    editActive: ui.valueEditActive ?? false };
}

function rectBorder(fb: Framebuffer, x: number, y: number, w: number, h: number, color: number): void {
  fillRect(fb, x, y, w, 1, color);
  fillRect(fb, x, y + h - 1, w, 1, color);
  fillRect(fb, x, y, 1, h, color);
  fillRect(fb, x + w - 1, y, 1, h, color);
}

/** Capture zero follows startup blanking: phases are 1,1,2,2,... (IF-030). */
export function capturedAnimationPhase(stateFrame: number): number {
  return (1 + Math.floor(Math.max(0, stateFrame - 1) / 2)) & 31;
}

export function capturedCaretVisible(stateFrame: number): boolean {
  return (Math.floor((Math.max(0, stateFrame - 1) + 2) / 10) & 1) === 1;
}

/** Five-pixel moving bands, continuous across adjacent cells and through elbows. */
export function flowPixel(word: number, dx: number, dy: number, phase: number, spriteVisible: boolean): boolean {
  const cell = decodeCell(word);
  if (!cell.enabled || dx === 31 || dy === 31) return false;
  const right = ((dx - phase) & 31) < 5, left = ((dx + phase) & 31) < 5;
  const down = ((dy - phase) & 31) < 5, up = ((dy + phase) & 31) < 5;
  let mask: boolean;
  if (cell.sprite === 1) {
    switch (cell.rotation) {
      case 1: mask = dx > dy ? right : up; break;
      case 2: mask = dx + dy < 31 ? right : down; break;
      case 3: mask = dx > dy ? down : left; break;
      default: mask = dx + dy < 31 ? up : left; break;
    }
  } else {
    mask = (cell.rotation & 1) ? (word & 0x200 ? up : down) : (word & 0x200 ? left : right);
  }
  const center = (cell.rotation & 1) ? dx >= 13 && dx <= 18 : dy >= 13 && dy <= 18;
  return mask && (cell.sprite <= 4 ? spriteVisible : center);
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
