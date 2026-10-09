// Component node extraction (GM-7, extraction half): golden canvas -> Netlist.
//
// Spec sources (D-007): the reciprocal-port netlist convention
// (assets/metacircuit-netlist-convention.png), the M2 settled node graph
// (core/connectivity.ts, D-014), the reference kernels
// simpyhls/examples/{flooding_core,extract_component_nodes}.dsl.py and the
// uart_link protocol (src/uart_link/README.md). Rules and every choice the
// spec leaves open are recorded in golden/M3_ASSUMPTIONS.md (M3-Axxx).
//
// Rules, in order:
//  1. Raw regions are the connected components of the reciprocal-port graph,
//     numbered 1.. by their first row-major cell (labelPortGrid; identical to
//     flooding_core's numbering). Component halves have no ports.
//  2. A region is grounded when it contains an enabled ground cell (M3-A003).
//  3. Every non-grounded region gets a solver row in first-seen row-major order
//     starting at 0, whether or not a component touches it (M3-A004, the
//     extract_component_nodes compaction policy). nodeCount = highest row used
//     by an element terminal + 1, or 0 (M3-A005).
//  4. Element idx = rank of the component's anchor (left-half) cell address,
//     row-major, over live two-cell components (M3-A006).
//  5. n0 is the terminal beyond the anchor half, n1 the terminal beyond the
//     partner half (extract_component_nodes' term0/term1). A terminal joins the
//     region of the cell next to it only if that cell has a port facing the
//     component (M3-A002). Floating terminals become GROUND_NODE (M3-A007).

import { GROUND_NODE, ElementKind, type Netlist, type NetlistElement } from './types.ts';
import { encodeError, encodeNetlist } from './uart.ts';
import { cellPortMask, labelPortGrid, portToward, singlePortDelta } from '../core/connectivity.ts';
import { GRID_H, GRID_W, PAIR_DELTA, Sprite, Unit } from '../core/constants.ts';
import { liveComponents, type Component, type GoldenState } from '../core/state.ts';

/** Protocol unit codes (src/uart_link/README.md "solver-board mapping"). */
export const enum ProtocolUnit {
  Base = 0x00,
  Milli = 0x01,
  Micro = 0x02,
  Nano = 0x03,
  Kilo = 0x04,
  Mega = 0x05,
  Giga = 0x06,
}

/** Marks an element whose frontend unit has no protocol code (pico; M3-A009). */
export const UNIT_UNSUPPORTED = 0xff;

/** Frontend error codes in `@ER` records sent instead of a netlist (M3-A009, M3-A010). */
export const FRONTEND_ERROR_UNSUPPORTED_KIND = 0x81;
export const FRONTEND_ERROR_UNSUPPORTED_UNIT = 0x82;
/** Golden-defined: more non-ground rows than the 8-bit protocol can carry. */
export const FRONTEND_ERROR_NODE_OVERFLOW = 0x84;

/** Largest node_count the protocol allows (README: `00..FE`). */
export const MAX_NODE_COUNT = 0xfe;

const KIND_OF_LEFT_SPRITE: Partial<Record<number, ElementKind>> = {
  [Sprite.ResLeft]: ElementKind.Resistor,
  [Sprite.CurrLeft]: ElementKind.CurrentDc,
  [Sprite.VoltLeft]: ElementKind.VoltageDc,
  [Sprite.CapLeft]: ElementKind.Capacitor,
  [Sprite.IndLeft]: ElementKind.Inductor,
};

const PROTOCOL_UNIT: Partial<Record<number, ProtocolUnit>> = {
  [Unit.None]: ProtocolUnit.Base,
  [Unit.Milli]: ProtocolUnit.Milli,
  [Unit.Micro]: ProtocolUnit.Micro,
  [Unit.Nano]: ProtocolUnit.Nano,
  [Unit.Kilo]: ProtocolUnit.Kilo,
  [Unit.Mega]: ProtocolUnit.Mega,
};

export function elementKindOf(leftSprite: number): ElementKind {
  const kind = KIND_OF_LEFT_SPRITE[leftSprite];
  if (kind === undefined) throw new Error(`sprite ${leftSprite} is not a two-terminal component anchor`);
  return kind;
}

/** Frontend unit code (IF-016) -> protocol unit code, or UNIT_UNSUPPORTED. */
export function protocolUnitOf(frontendUnit: number): number {
  return PROTOCOL_UNIT[frontendUnit] ?? UNIT_UNSUPPORTED;
}

export type ExtractionIssue =
  | { type: 'floating-terminal'; idx: number; terminal: 0 | 1; col: number; row: number }
  | { type: 'shorted-element'; idx: number; node: number }
  | { type: 'no-ground' }
  | { type: 'empty-row'; row: number }
  | { type: 'unsupported-unit'; idx: number; frontendUnit: number }
  | { type: 'unsupported-kind'; idx: number; kind: ElementKind }
  | { type: 'node-overflow'; nodeCount: number };

/** A snapshot the frontend cannot send: it sends `@ER,<frame>,<code>,<arg>` instead. */
export interface Rejection { code: number; arg: number; reason: string }

export interface ElementTrace {
  idx: number;
  /** Golden ComponentStore slot (A-011), when extracted from a GoldenState. */
  slot: number | null;
  leftSprite: number;
  col: number;
  row: number;
  rotation: number;
  frontendUnit: number;
  /** Terminal cells (beyond the anchor half, beyond the partner half). */
  terminals: [{ col: number; row: number }, { col: number; row: number }];
  /** Raw region of each terminal (0 = floating). */
  raw: [number, number];
}

export interface ExtractionResult {
  netlist: Netlist;
  /** Per-cell raw region id (row-major), 0 = no conducting port. */
  regions: Uint16Array;
  regionCount: number;
  groundRegions: number[];
  /** Raw region -> solver row, for every non-grounded region. */
  rowOfRegion: Record<number, number>;
  elements: ElementTrace[];
  issues: ExtractionIssue[];
  rejection: Rejection | null;
}

export interface PlacedComponent extends Component { slot?: number }

export interface ExtractOptions {
  /** Netlist `frame` field (16 bit). */
  frame?: number;
  /** Kinds the frontend sends; others reject the snapshot with 0x81 (default: all, M3-A010). */
  supportedKinds?: ReadonlySet<ElementKind>;
  /** Differential testing only: mimic the DSL kernels' non-reciprocal terminal and
   * ground lookups (see M3-A002, M3-A003). Never used for references. */
  dslCompat?: boolean;
}

export interface CanvasInput {
  cells: ArrayLike<number>;
  width?: number;
  height?: number;
  components: readonly PlacedComponent[];
}

export function extractFromCanvas(input: CanvasInput, opts: ExtractOptions = {}): ExtractionResult {
  const width = input.width ?? GRID_W;
  const height = input.height ?? GRID_H;
  const { cells } = input;
  if (cells.length !== width * height) throw new Error('cell array does not match the grid size');
  const ports = Uint8Array.from(cells, cellPortMask);
  const { nodeIds: regions, nodeCount: regionCount } = labelPortGrid(ports, width, height);
  const inGrid = (col: number, row: number) => col >= 0 && row >= 0 && col < width && row < height;
  const addr = (col: number, row: number) => row * width + col;

  // Rule 2: grounded regions.
  const grounded = new Set<number>();
  for (let a = 0; a < cells.length; a++) {
    const word = cells[a]!;
    if (!(word & 1) || ((word >>> 1) & 63) !== Sprite.Ground) continue;
    if (!opts.dslCompat) {
      grounded.add(regions[a]!);
      continue;
    }
    // DSL: the region of the cell the ground's port points at, reciprocal or not.
    const col = a % width, row = Math.floor(a / width);
    const [dx, dy] = singlePortDelta(ports[a]!)!;
    if (inGrid(col + dx, row + dy) && regions[addr(col + dx, row + dy)]) grounded.add(regions[addr(col + dx, row + dy)]!);
  }

  // Rule 3: compaction of non-ground regions into solver rows.
  const rowOfRegion: Record<number, number> = {};
  let nextRow = 0;
  for (let a = 0; a < regions.length; a++) {
    const raw = regions[a]!;
    if (raw && !grounded.has(raw) && rowOfRegion[raw] === undefined) rowOfRegion[raw] = nextRow++;
  }

  // Rule 4: element order.
  const ordered = [...input.components].sort((p, q) => addr(p.col, p.row) - addr(q.col, q.row));
  const issues: ExtractionIssue[] = [];
  const traces: ElementTrace[] = [];
  const elements: NetlistElement[] = [];
  let maxRow = -1;
  let grounding = false;
  const usedRows = new Set<number>();
  ordered.forEach((c, idx) => {
    const [dx, dy] = PAIR_DELTA[c.rotation & 3]!;
    const terminals: ElementTrace['terminals'] = [
      { col: c.col - dx, row: c.row - dy },
      { col: c.col + 2 * dx, row: c.row + 2 * dy },
    ];
    // Port that the terminal cell must have to face the component (rule 5).
    const facing = [portToward(dx, dy), portToward(-dx, -dy)];
    const raw = terminals.map(({ col, row }, k) => {
      if (!inGrid(col, row)) return 0;
      const a = addr(col, row);
      return opts.dslCompat || ports[a]! & facing[k]! ? regions[a]! : 0;
    }) as [number, number];
    const nodes = raw.map((r, k) => {
      if (r === 0) {
        issues.push({ type: 'floating-terminal', idx, terminal: k as 0 | 1, ...terminals[k]! });
        return GROUND_NODE;
      }
      if (grounded.has(r)) {
        grounding = true;
        return GROUND_NODE;
      }
      const row = rowOfRegion[r]!;
      maxRow = Math.max(maxRow, row);
      usedRows.add(row);
      return row;
    });
    if (nodes[0] === nodes[1]) issues.push({ type: 'shorted-element', idx, node: nodes[0]! });
    const kind = elementKindOf(c.leftSprite);
    elements.push({ idx, kind, n0: nodes[0]!, n1: nodes[1]!, valueBcd: c.valueBcd & 0xfff, unit: protocolUnitOf(c.unit) });
    traces.push({
      idx, slot: c.slot ?? null, leftSprite: c.leftSprite, col: c.col, row: c.row, rotation: c.rotation,
      frontendUnit: c.unit, terminals, raw,
    });
  });
  // Solver-relevant shape problems (M3-A012); the netlist is still sent.
  if (elements.length && !grounding) issues.push({ type: 'no-ground' });
  const nodeCount = maxRow + 1;
  for (let row = 0; row < nodeCount; row++) if (!usedRows.has(row)) issues.push({ type: 'empty-row', row });

  // Snapshot rejection, first failing element in idx order (M3-A009..A011).
  let rejection: Rejection | null = null;
  for (const e of elements) {
    if (opts.supportedKinds && !opts.supportedKinds.has(e.kind)) {
      issues.push({ type: 'unsupported-kind', idx: e.idx, kind: e.kind });
      rejection ??= { code: FRONTEND_ERROR_UNSUPPORTED_KIND, arg: e.idx, reason: `element ${e.idx} kind ${e.kind} not sent by the frontend` };
    }
    if (e.unit === UNIT_UNSUPPORTED) {
      const frontendUnit = traces[e.idx]!.frontendUnit;
      issues.push({ type: 'unsupported-unit', idx: e.idx, frontendUnit });
      rejection ??= { code: FRONTEND_ERROR_UNSUPPORTED_UNIT, arg: (frontendUnit & 0xf) << 8 | e.idx, reason: `element ${e.idx} unit ${frontendUnit} has no protocol code` };
    }
  }
  if (nodeCount > MAX_NODE_COUNT) {
    issues.push({ type: 'node-overflow', nodeCount });
    rejection ??= { code: FRONTEND_ERROR_NODE_OVERFLOW, arg: nodeCount, reason: `${nodeCount} non-ground rows exceed ${MAX_NODE_COUNT}` };
  }
  if (elements.length > 0xff) throw new Error('more than 255 elements cannot occur on an 18x16 canvas');

  return {
    netlist: { frame: (opts.frame ?? 0) & 0xffff, nodeCount, elements },
    regions, regionCount,
    groundRegions: [...grounded].sort((p, q) => p - q),
    rowOfRegion, elements: traces, issues, rejection,
  };
}

/** Extract the netlist of a golden state. `frame` defaults to the state's frame
 * index (the frame whose end-of-frame dump this state is, A-001). */
export function extractNetlist(s: GoldenState, opts: ExtractOptions = {}): ExtractionResult {
  const components = liveComponents(s).map(({ slot, c }) => ({ ...c, slot }));
  return extractFromCanvas(
    { cells: s.cells, width: GRID_W, height: GRID_H, components },
    { ...opts, frame: opts.frame ?? Math.max(0, s.frame - 1) },
  );
}

/** Compare two netlists field by field; returns readable differences. */
export function diffNetlist(expected: Netlist, actual: Netlist, opts: { ignoreFrame?: boolean } = {}): string[] {
  const out: string[] = [];
  const hex = (v: number) => v.toString(16).toUpperCase().padStart(2, '0');
  if (!opts.ignoreFrame && expected.frame !== actual.frame) out.push(`frame ${actual.frame}, expected ${expected.frame}`);
  if (expected.nodeCount !== actual.nodeCount) out.push(`node_count ${actual.nodeCount}, expected ${expected.nodeCount}`);
  if (expected.elements.length !== actual.elements.length) {
    out.push(`elem_count ${actual.elements.length}, expected ${expected.elements.length}`);
  }
  const n = Math.max(expected.elements.length, actual.elements.length);
  for (let i = 0; i < n; i++) {
    const e = expected.elements[i], a = actual.elements[i];
    if (!e || !a) {
      out.push(e ? `element ${i} missing` : `unexpected element ${i}`);
      continue;
    }
    for (const key of ['idx', 'kind', 'n0', 'n1', 'valueBcd', 'unit'] as const) {
      if (e[key] !== a[key]) out.push(`element ${i} ${key} ${hex(a[key])}, expected ${hex(e[key])}`);
    }
  }
  return out;
}

/** The frontend's UART output for one snapshot: `@NB/@NC/@NE`, or a single
 * `@ER` record when the snapshot is rejected (M3-A009..A011). */
export function snapshotUart(result: ExtractionResult): string {
  const r = result.rejection;
  return r ? encodeError(result.netlist.frame, r.code, r.arg) : encodeNetlist(result.netlist);
}
