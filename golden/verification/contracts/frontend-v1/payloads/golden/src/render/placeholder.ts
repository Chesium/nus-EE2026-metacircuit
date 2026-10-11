// Placeholder renderer: layout, colours and rotation transform follow the RTL
// interface facts, but sprite and icon bitmaps are hand-drawn stand-ins until
// the GM-4 assets exist. Not pixel-exact; never compare its pixels to the RTL.

import {
  BOTTOM_BAR_H, CANVAS_H, CANVAS_W, CANVAS_X0, CANVAS_Y0, CELL_SIZE, GRID_H, GRID_W, LEFT_BAR_W, RIGHT_BAR_W,
  SCREEN_H, SCREEN_W, Sprite, TOOLBAR_COUNT, TOP_BAR_H, Tool, WIRE_VARIANT_SPRITE, buttonRect,
} from '../core/constants.ts';
import { decodeCell } from '../core/encoding.ts';
import { screenToCell } from '../core/geometry.ts';
import type { GoldenState, MouseSnapshot } from '../core/state.ts';
import {
  type Bitmap, type Framebuffer, blankBitmap, bmArc, bmCircle, bmLine, fillRect, rgb888to444, setPx, strokeRect,
} from './framebuffer.ts';
import type { RenderOptions, Renderer } from './renderer.ts';

// Colours (RGB444). Sources in INTERFACE_FACTS.md (IF-022..IF-024).
const BACKGROUND = 0xecc;
const PANEL = 0xddb; // placeholder: top bar / keyboard area tint (not from the RTL)
const CELL_BG = 0x222; // palette idx 0
const HOVER_BG = 0x280; // palette idx 14 (HoverBgColorIdx)
const SPRITE_FG = 0xfff; // palette idx 15
const GRID = 0x666;
const BTN_FACE = rgb888to444(0xf4e7d5);
const BTN_BORDER = rgb888to444(0xc9ae8e);
const BTN_SELECTED = rgb888to444(0xd96b3b);
const BTN_PRESSED = rgb888to444(0xa54924);
const ICON = 0x333; // placeholder icon colour

// ---------------------------------------------------------------- stand-in bitmaps (rotation 0)

const MID = 15; // centre line (2-px wide stroke at rows 14..17 with brush 4)
const W = 4; // stroke width

function single(draw: (b: Bitmap) => void): Bitmap {
  const b = blankBitmap(32, 32);
  draw(b);
  return b;
}

/** 64x32 two-cell symbol; split into left (anchor) and right halves. */
function double(draw: (b: Bitmap) => void): [Bitmap, Bitmap] {
  const b = blankBitmap(64, 32);
  draw(b);
  return [b.map((r) => r.slice(0, 32)), b.map((r) => r.slice(32, 64))];
}

const lead = (b: Bitmap) => {
  bmLine(b, 0, MID, 18, MID, W);
  bmLine(b, 46, MID, 63, MID, W);
};

const [RL, RR] = double((b) => {
  lead(b);
  const pts = [18, 21, 25, 29, 33, 37, 41, 46];
  for (let i = 0; i < pts.length - 1; i++) {
    bmLine(b, pts[i]!, i === 0 ? MID : i % 2 ? MID - 8 : MID + 8, pts[i + 1]!, i + 1 === pts.length - 1 ? MID : (i + 1) % 2 ? MID - 8 : MID + 8, 3);
  }
});
const [LL, LR] = double((b) => {
  lead(b);
  for (let i = 0; i < 3; i++) bmArc(b, 22.5 + i * 9.5, MID, 4.5, Math.PI, 2 * Math.PI, 3);
});
const [CL, CR] = double((b) => {
  bmLine(b, 0, MID, 28, MID, W);
  bmLine(b, 36, MID, 63, MID, W);
  bmLine(b, 28, MID - 10, 28, MID + 10, 3);
  bmLine(b, 36, MID - 10, 36, MID + 10, 3);
});
const [VL, VR] = double((b) => {
  bmLine(b, 0, MID, 20, MID, W);
  bmLine(b, 44, MID, 63, MID, W);
  bmCircle(b, 32, MID, 11, 3);
  bmLine(b, 24, MID, 28, MID, 2); // "+" on the anchor side
  bmLine(b, 26, MID - 2, 26, MID + 2, 2);
  bmLine(b, 36, MID, 40, MID, 2); // "-"
});
const [IL, IR] = double((b) => {
  bmLine(b, 0, MID, 20, MID, W);
  bmLine(b, 44, MID, 63, MID, W);
  bmCircle(b, 32, MID, 11, 3);
  bmLine(b, 26, MID, 38, MID, 2);
  bmLine(b, 38, MID, 34, MID - 4, 2);
  bmLine(b, 38, MID, 34, MID + 4, 2);
});

const SPRITES: Record<number, Bitmap> = {
  [Sprite.Wire]: single((b) => bmLine(b, 0, MID, 31, MID, W)),
  [Sprite.Elbow]: single((b) => {
    bmLine(b, 0, MID, MID, MID, W);
    bmLine(b, MID, MID, MID, 31, W);
  }),
  [Sprite.Tee]: single((b) => {
    bmLine(b, 0, MID, 31, MID, W);
    bmLine(b, MID, MID, MID, 31, W);
  }),
  [Sprite.Junction]: single((b) => {
    bmLine(b, 0, MID, MID, MID, W);
    for (let r = 0; r < 5; r++) bmCircle(b, MID, MID, r, 2);
  }),
  [Sprite.Cross]: single((b) => {
    bmLine(b, 0, MID, 31, MID, W);
    bmLine(b, MID, 0, MID, 31, W);
  }),
  [Sprite.Ground]: single((b) => {
    bmLine(b, MID, 0, MID, 16, W);
    bmLine(b, 5, 17, 26, 17, 3);
    bmLine(b, 9, 22, 22, 22, 3);
    bmLine(b, 13, 27, 18, 27, 3);
  }),
  [Sprite.ResLeft]: RL, [Sprite.ResRight]: RR,
  [Sprite.IndLeft]: LL, [Sprite.IndRight]: LR,
  [Sprite.CapLeft]: CL, [Sprite.CapRight]: CR,
  [Sprite.VoltLeft]: VL, [Sprite.VoltRight]: VR,
  [Sprite.CurrLeft]: IL, [Sprite.CurrRight]: IR,
};

const UNKNOWN = single((b) => {
  bmLine(b, 4, 4, 27, 27, 2);
  bmLine(b, 27, 4, 4, 27, 2);
});

/**
 * Sprite pixel at cell offset (dx, dy) for a rotation code, using the RTL's
 * GetXX/GetYY transform (IF-025): bitmap column c and row r are
 *   rot 0: (dx, dy)   rot 1: (dy, 31-dx)   rot 2: (31-dx, 31-dy)   rot 3: (31-dy, dx)
 */
export function spritePixel(bm: Bitmap, rotation: number, dx: number, dy: number): boolean {
  let c: number;
  let r: number;
  switch (rotation & 3) {
    case 0: c = dx; r = dy; break;
    case 1: c = dy; r = 31 - dx; break;
    case 2: c = 31 - dx; r = 31 - dy; break;
    default: c = 31 - dy; r = dx; break;
  }
  return !!bm[r]?.[c];
}

// ---------------------------------------------------------------- toolbar icons (24x24)

function icon(draw: (b: Bitmap) => void): Bitmap {
  const b = blankBitmap(24, 24);
  draw(b);
  return b;
}
function shrink(src: Bitmap, w: number, h: number): Bitmap {
  const sh = src.length;
  const sw = src[0]!.length;
  const out = blankBitmap(24, 24);
  const ox = Math.floor((24 - w) / 2);
  const oy = Math.floor((24 - h) / 2);
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    out[oy + y]![ox + x] = !!src[Math.floor((y * sh) / h)]![Math.floor((x * sw) / w)];
  }
  return out;
}
const joinHalves = (l: Bitmap, r: Bitmap): Bitmap => l.map((row, i) => [...row, ...r[i]!]);

const TOOL_ICONS: Record<number, Bitmap> = {
  [Tool.Pan]: icon((b) => {
    bmLine(b, 12, 3, 12, 20, 2);
    bmLine(b, 3, 12, 20, 12, 2);
    for (const [x, y, dx, dy] of [[12, 3, 3, 3], [12, 3, -3, 3], [12, 20, 3, -3], [12, 20, -3, -3], [3, 12, 3, 3], [3, 12, 3, -3], [20, 12, -3, 3], [20, 12, -3, -3]] as const) {
      bmLine(b, x, y, x + dx, y + dy, 2);
    }
  }),
  [Tool.Resistor]: shrink(joinHalves(RL, RR), 24, 12),
  [Tool.Inductor]: shrink(joinHalves(LL, LR), 24, 12),
  [Tool.Capacitor]: shrink(joinHalves(CL, CR), 24, 12),
  [Tool.VoltageSource]: shrink(joinHalves(VL, VR), 24, 12),
  [Tool.CurrentSource]: shrink(joinHalves(IL, IR), 24, 12),
  [Tool.Ground]: shrink(SPRITES[Sprite.Ground]!, 20, 20),
  [Tool.Rotate]: icon((b) => {
    bmArc(b, 12, 12, 7, -Math.PI * 0.4, Math.PI * 1.5, 2);
    bmLine(b, 12, 5, 16, 2, 2);
    bmLine(b, 12, 5, 16, 8, 2);
  }),
  [Tool.Delete]: icon((b) => {
    bmLine(b, 5, 5, 18, 18, 3);
    bmLine(b, 18, 5, 5, 18, 3);
  }),
};
const wireIcon = (variant: number) => shrink(SPRITES[WIRE_VARIANT_SPRITE[(variant & 3) as 0 | 1 | 2 | 3]]!, 20, 20);

// ---------------------------------------------------------------- cursor (placeholder arrow, 12x19)

const CURSOR = [
  'X...........',
  'XX..........',
  'XoX.........',
  'XooX........',
  'XoooX.......',
  'XooooX......',
  'XoooooX.....',
  'XooooooX....',
  'XoooooooX...',
  'XooooooooX..',
  'XoooooooooX.',
  'XooooooXXXXX',
  'XoooXooX....',
  'XooX.XooX...',
  'XoX..XooX...',
  'XX....XooX..',
  'X.....XooX..',
  '.......XooX.',
  '.......XXX..',
];

// ---------------------------------------------------------------- renderer

function blit(fb: Framebuffer, bm: Bitmap, x0: number, y0: number, c: number): void {
  bm.forEach((row, y) => row.forEach((on, x) => on && setPx(fb, x0 + x, y0 + y, c)));
}

export class PlaceholderRenderer implements Renderer {
  readonly name = 'placeholder';
  readonly authoritative = false;

  render(s: GoldenState, mouse: MouseSnapshot, fb: Framebuffer, opts: RenderOptions): void {
    fillRect(fb, 0, 0, SCREEN_W, SCREEN_H, BACKGROUND);
    fillRect(fb, 0, 0, SCREEN_W, TOP_BAR_H, PANEL); // property panel area (out of scope in M1)
    fillRect(fb, SCREEN_W - RIGHT_BAR_W + 1, SCREEN_H - BOTTOM_BAR_H, RIGHT_BAR_W - 1, BOTTOM_BAR_H, PANEL); // keypad area
    this.toolbar(s, mouse, fb);
    this.canvas(s, mouse, fb, opts);
    if (opts.drawCursor) {
      CURSOR.forEach((row, y) => [...row].forEach((ch, x) => {
        if (ch === 'X') setPx(fb, mouse.x + x, mouse.y + y, 0x000);
        else if (ch === 'o') setPx(fb, mouse.x + x, mouse.y + y, mouse.left ? 0xfd6 : 0xfff);
      }));
    }
  }

  private toolbar(s: GoldenState, mouse: MouseSnapshot, fb: Framebuffer): void {
    fillRect(fb, 0, TOP_BAR_H, LEFT_BAR_W, CANVAS_H, BACKGROUND);
    for (let i = 0; i < TOOLBAR_COUNT; i++) {
      const r = buttonRect(i);
      const hovered = mouse.x >= r.x0 && mouse.x < r.x1 && mouse.y >= r.y0 && mouse.y < r.y1;
      fillRect(fb, r.x0, r.y0, r.x1 - r.x0, r.y1 - r.y0, BTN_FACE);
      const border = hovered && mouse.left ? BTN_PRESSED : s.tool === i ? BTN_SELECTED : BTN_BORDER;
      strokeRect(fb, r.x0, r.y0, r.x1 - r.x0, r.y1 - r.y0, 2, border);
      const ic = i === Tool.Wire ? wireIcon(s.wireVariant) : TOOL_ICONS[i];
      if (ic) blit(fb, ic, r.x0 + 6, r.y0, ICON);
    }
  }

  private canvas(s: GoldenState, mouse: MouseSnapshot, fb: Framebuffer, opts: RenderOptions): void {
    const hover = opts.hover ? screenToCell(mouse.x, mouse.y, s.panX, s.panY) : null;
    for (let row = 0; row < GRID_H; row++) {
      for (let col = 0; col < GRID_W; col++) {
        const x0 = CANVAS_X0 + s.panX + col * CELL_SIZE;
        const y0 = CANVAS_Y0 + s.panY + row * CELL_SIZE;
        if (x0 + CELL_SIZE <= CANVAS_X0 || y0 + CELL_SIZE <= CANVAS_Y0 || x0 >= CANVAS_X0 + CANVAS_W || y0 >= CANVAS_Y0 + CANVAS_H) continue;
        const isHover = hover && hover.col === col && hover.row === row;
        const cell = decodeCell(s.cells[row * GRID_W + col]!);
        const bm = cell.enabled ? SPRITES[cell.sprite] ?? UNKNOWN : null;
        for (let dy = 0; dy < CELL_SIZE; dy++) {
          const y = y0 + dy;
          if (y < CANVAS_Y0 || y >= CANVAS_Y0 + CANVAS_H) continue;
          for (let dx = 0; dx < CELL_SIZE; dx++) {
            const x = x0 + dx;
            if (x < CANVAS_X0 || x >= CANVAS_X0 + CANVAS_W) continue;
            let c = isHover ? HOVER_BG : CELL_BG;
            if (dx === 0 || dy === 0) c = GRID;
            else if (bm && spritePixel(bm, cell.rotation, dx, dy)) c = SPRITE_FG;
            setPx(fb, x, y, c);
          }
        }
      }
    }
  }
}

// Exposed for tests and a future asset-backed renderer.
export const PLACEHOLDER_SPRITES = SPRITES;
