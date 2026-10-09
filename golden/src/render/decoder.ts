// GM-6: recover visible cell facts from pixels, independently of RAM/state
// decoding and the renderer. Only sprite/palette/geometry/cursor asset tables
// are shared. A framebuffer cannot reveal metadata or distinguish symmetric
// rotations, and this API deliberately preserves those ambiguities.

export interface DecoderCanvasAssets {
  sprites: { id: number; name?: string; rows: string[] }[];
  palette: { index: number; rgb12: string }[];
  geometry: {
    canvas_x0: number; canvas_y0: number; canvas_w: number; canvas_h: number;
    cell_size: number; grid_w: number; grid_h: number;
  };
}

export interface DecoderCursorAssets {
  sprites_as_displayed: { hover: string[]; pressed: string[] };
  placement: { sprite_origin_offset: [number, number]; visible_columns: [number, number] };
  colors: Record<string, { rgb12: string }>;
}

/** Uint16 data is row-major RGB444; byte data is row-major RGBA8888. */
export interface PixelFrame {
  width: number;
  height: number;
  data: Uint16Array | Uint8Array | Uint8ClampedArray;
}

export interface PixelRect { x: number; y: number; width: number; height: number }

export interface VisibleDecodeOptions {
  panX?: number;
  panY?: number;
  mouse?: { x: number; y: number; left: boolean };
  /** With mouse provided, opaque cursor pixels are excluded by default. */
  drawCursor?: boolean;
  excludeRects?: PixelRect[];
  /** Explicit colours to mask, e.g. flow yellow 0xff0. No colours are masked by default. */
  maskColors?: number[];
}

export interface VisibleCellCandidate {
  /** null means no observable sprite. Enable/metadata are not inferred. */
  sprite: number | null;
  spriteName: string;
  rotation: number | null;
  /** RGB444; null means this colour was completely hidden/clipped. */
  foreground: number | null;
  background: number | null;
}

export interface PixelMismatch {
  x: number; y: number; actual: number; expected: number;
}

export interface VisibleCell {
  col: number;
  row: number;
  status: 'decoded' | 'ambiguous' | 'unknown' | 'occluded';
  /** Exact matches, or equally good nearest candidates when status is unknown. */
  candidates: VisibleCellCandidate[];
  evidence: {
    sampledPixels: number;
    maskedPixels: number;
    clippedPixels: number;
    mismatchedPixels: number;
    /** At most 8 pixel witnesses for the first nearest candidate. */
    mismatches: PixelMismatch[];
  };
}

export interface VisibleDecodeResult {
  cells: VisibleCell[];
  errors: string[];
}

interface Template { sprite: number | null; spriteName: string; rotation: number | null; bits: Uint8Array }
interface Sample { x: number; y: number; offset: number; color: number }
interface Match { candidate: VisibleCellCandidate; errors: number; fg: number | null; bg: number | null; template: Template }

const hex = (c: number) => `0x${c.toString(16).padStart(3, '0')}`;

/** Match the cell interiors; borders remain the responsibility of exact pixel comparison.
 * Both outer rows/columns are excluded because grid and sprite priority can
 * conceal sprite bits there. Partial/panned cells retain every visible interior
 * sample, including pixels on the canvas clipping edge.
 */
export class VisibleCellDecoder {
  private readonly templates: Template[];
  private readonly palette: Set<number>;

  constructor(private readonly canvas: DecoderCanvasAssets, private readonly cursor?: DecoderCursorAssets) {
    const n = canvas.geometry.cell_size;
    if (n !== 32) throw new Error(`cell decoder requires 32x32 GM-4 sprites, got ${n}`);
    this.palette = new Set(canvas.palette.map((c) => Number.parseInt(c.rgb12, 16)));
    this.templates = [{ sprite: null, spriteName: 'empty', rotation: null, bits: new Uint8Array(n * n) }];
    for (const sprite of canvas.sprites) {
      if (sprite.rows.length !== n || sprite.rows.some((r) => r.length !== n || /[^01]/.test(r))) {
        throw new Error(`invalid GM-4 sprite ${sprite.id}: expected 32 binary rows of width 32`);
      }
      for (let rotation = 0; rotation < 4; rotation++) {
        const bits = new Uint8Array(n * n);
        // Inverse destination-to-source transforms from the GM-4 rotation facts.
        for (let y = 0; y < n; y++) for (let x = 0; x < n; x++) {
          const source = [[y, x], [n - 1 - x, y], [n - 1 - y, n - 1 - x], [x, n - 1 - y]][rotation]!;
          bits[y * n + x] = Number(sprite.rows[source[0]!]![source[1]!]);
        }
        this.templates.push({ sprite: sprite.id, spriteName: sprite.name ?? `sprite${sprite.id}`, rotation, bits });
      }
    }
  }

  decode(frame: PixelFrame, options: VisibleDecodeOptions = {}): VisibleDecodeResult {
    const stride = frame.data instanceof Uint16Array ? 1 : 4;
    if (!Number.isInteger(frame.width) || !Number.isInteger(frame.height) || frame.width <= 0 || frame.height <= 0 ||
        frame.data.length !== frame.width * frame.height * stride) throw new Error('invalid framebuffer dimensions/data length');
    const panX = options.panX ?? 0;
    const panY = options.panY ?? 0;
    if (!Number.isInteger(panX) || !Number.isInteger(panY)) throw new Error('cell decoder pan offsets must be integer pixels');
    const g = this.canvas.geometry;
    const n = g.cell_size;
    const cursorMask = this.cursorMask(frame.width, options);
    const maskedColors = new Set(options.maskColors ?? []);
    const cells: VisibleCell[] = [];
    const errors: string[] = [];
    const read = (x: number, y: number) => {
      const p = y * frame.width + x;
      if (stride === 1) return frame.data[p]! & 0xfff;
      const i = p * 4;
      return ((frame.data[i]! >>> 4) << 8) | ((frame.data[i + 1]! >>> 4) << 4) | (frame.data[i + 2]! >>> 4);
    };
    for (let row = 0; row < g.grid_h; row++) for (let col = 0; col < g.grid_w; col++) {
      const x0 = g.canvas_x0 + panX + col * n;
      const y0 = g.canvas_y0 + panY + row * n;
      if (x0 >= Math.min(frame.width, g.canvas_x0 + g.canvas_w) || x0 + n <= Math.max(0, g.canvas_x0) ||
          y0 >= Math.min(frame.height, g.canvas_y0 + g.canvas_h) || y0 + n <= Math.max(0, g.canvas_y0)) continue;
      const samples: Sample[] = [];
      let maskedPixels = 0;
      let clippedPixels = 0;
      for (let dy = 1; dy < n - 1; dy++) for (let dx = 1; dx < n - 1; dx++) {
        const x = x0 + dx;
        const y = y0 + dy;
        if (x < 0 || x >= frame.width || y < 0 || y >= frame.height || x < g.canvas_x0 || x >= g.canvas_x0 + g.canvas_w ||
            y < g.canvas_y0 || y >= g.canvas_y0 + g.canvas_h) { clippedPixels++; continue; }
        const color = read(x, y);
        const masked = cursorMask.has(y * frame.width + x) || maskedColors.has(color) || options.excludeRects?.some((r) =>
          x >= r.x && x < r.x + r.width && y >= r.y && y < r.y + r.height);
        if (masked) { maskedPixels++; continue; }
        samples.push({ x, y, offset: dy * n + dx, color });
      }
      let best: Match[] = [];
      let bestErrors = Infinity;
      for (const template of this.templates) {
        const match = this.match(samples, template);
        if (match === null) continue;
        if (match.errors < bestErrors) { best = [match]; bestErrors = match.errors; }
        else if (match.errors === bestErrors) best.push(match);
      }
      const status = samples.length === 0 ? 'occluded' : bestErrors > 0 ? 'unknown' : best.length > 1 ? 'ambiguous' : 'decoded';
      const first = best[0];
      const mismatches: PixelMismatch[] = [];
      if (first && bestErrors > 0) for (const s of samples) {
        const expected = first.template.bits[s.offset] ? first.fg : first.bg;
        if (expected !== null && s.color !== expected && mismatches.length < 8) mismatches.push({ x: s.x, y: s.y, actual: s.color, expected });
      }
      const cell: VisibleCell = {
        col, row, status, candidates: status === 'occluded' ? [] : best.map((m) => m.candidate),
        evidence: { sampledPixels: samples.length, maskedPixels, clippedPixels, mismatchedPixels: samples.length ? bestErrors : 0, mismatches },
      };
      cells.push(cell);
      if (status === 'unknown') errors.push(`cell (${col},${row}) has ${bestErrors}/${samples.length} unclassified pixels; nearest ${describe(cell.candidates)}`);
    }
    return { cells, errors };
  }

  private match(samples: Sample[], template: Template): Match | null {
    const fgCounts = new Map<number, number>();
    const bgCounts = new Map<number, number>();
    let fgTotal = 0;
    let bgTotal = 0;
    for (const s of samples) {
      const isFg = !!template.bits[s.offset];
      if (isFg) fgTotal++; else bgTotal++;
      if (!this.palette.has(s.color)) continue;
      const counts = isFg ? fgCounts : bgCounts;
      counts.set(s.color, (counts.get(s.color) ?? 0) + 1);
    }
    const dominant = (counts: Map<number, number>): [number | null, number] => {
      let color: number | null = null;
      let count = 0;
      for (const [c, k] of counts) if (k > count || k === count && (color === null || c < color)) { color = c; count = k; }
      return [color, count];
    };
    const [fg, fgCount] = dominant(fgCounts);
    const [bg, bgCount] = dominant(bgCounts);
    // A uniform interior supports the observable 'empty' class. Assigning a
    // foreground identical to the background would spuriously match every
    // sprite and tell us nothing about the image.
    if (template.sprite !== null && fg !== null && fg === bg) return null;
    return {
      template, fg, bg, errors: fgTotal - fgCount + bgTotal - bgCount,
      candidate: { sprite: template.sprite, spriteName: template.spriteName, rotation: template.rotation, foreground: fg, background: bg },
    };
  }

  private cursorMask(width: number, opts: VisibleDecodeOptions): Set<number> {
    const mask = new Set<number>();
    if (!this.cursor || !opts.mouse || opts.drawCursor === false) return mask;
    const rows = opts.mouse.left ? this.cursor.sprites_as_displayed.pressed : this.cursor.sprites_as_displayed.hover;
    const [ox, oy] = this.cursor.placement.sprite_origin_offset;
    const [lo, hi] = this.cursor.placement.visible_columns;
    rows.forEach((row, r) => {
      for (let c = lo; c <= hi && c < row.length; c++) if (this.cursor!.colors[row[c]!]) {
        const x = opts.mouse!.x + ox + c;
        const y = opts.mouse!.y + oy + r;
        if (x >= 0 && x < width && y >= 0) mask.add(y * width + x);
      }
    });
    return mask;
  }
}

function describe(candidates: VisibleCellCandidate[]): string {
  if (!candidates.length) return 'no observable candidate';
  return candidates.map((c) => `${c.spriteName}${c.rotation === null ? '' : ` rot ${c.rotation}`}` +
    `${c.foreground === null ? '' : ` fg ${hex(c.foreground)}`}${c.background === null ? '' : ` bg ${hex(c.background)}`}`).join(' or ');
}

/** Differences between pixel-derived facts. A shared symmetry alias is a match;
 * missing colour evidence is not a claim that an unseen colour is different.
 */
export function diffVisibleCells(expected: VisibleDecodeResult, actual: VisibleDecodeResult): string[] {
  const errors: string[] = [];
  const actualCells = new Map(actual.cells.map((c) => [`${c.col},${c.row}`, c]));
  for (const e of expected.cells) {
    if (e.status === 'occluded') continue;
    const a = actualCells.get(`${e.col},${e.row}`);
    if (!a) { errors.push(`cell (${e.col},${e.row}) is outside the actual visible grid`); continue; }
    if (a.status === 'occluded') { errors.push(`cell (${e.col},${e.row}) has no unmasked actual pixels`); continue; }
    if (e.status === 'unknown' || a.status === 'unknown') {
      const bad = a.status === 'unknown' ? a : e;
      errors.push(`cell (${e.col},${e.row}) has ${bad.evidence.mismatchedPixels} unclassified ${bad === a ? 'actual' : 'reference'} pixels; actual ${describe(a.candidates)}, expected ${describe(e.candidates)}`);
      continue;
    }
    const match = e.candidates.some((ec) => a.candidates.some((ac) => ec.sprite === ac.sprite && ec.rotation === ac.rotation &&
      (ec.foreground === null || ac.foreground === null || ec.foreground === ac.foreground) &&
      (ec.background === null || ac.background === null || ec.background === ac.background)));
    if (!match) errors.push(`cell (${e.col},${e.row}) is ${describe(a.candidates)}, expected ${describe(e.candidates)}`);
  }
  const expectedCells = new Set(expected.cells.map((c) => `${c.col},${c.row}`));
  for (const a of actual.cells) if (!expectedCells.has(`${a.col},${a.row}`) && a.status !== 'occluded') {
    errors.push(`cell (${a.col},${a.row}) is outside the reference visible grid`);
  }
  return errors;
}
