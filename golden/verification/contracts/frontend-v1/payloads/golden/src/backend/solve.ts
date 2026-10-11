// DC solve: Netlist -> VoltageSnapshot.
//
//   solveDc(netlist)            golden spec solve (wire unit codes, R/I/V/C/L,
//                               float32 DSL-order LU with the residual pivot search
//                               the kernel documents, structural singularity check)
//   simulateUartSolver(netlist) bit-exact prediction of src/uart_link's simulated
//                               solver (frontend_tester.SimpyhlsDcSolver, D-012),
//                               including the ER replies it sends instead; it
//                               runs solve_core_dc with the fixed pivot search
//                               (D-020) unless { pivot: 'dsl' } asks for the
//                               kernel as written before the fix
//   solveReference64(netlist)   independent textbook float64 Gaussian elimination,
//                               for tolerance sanity checks only
//
// Status codes (M3-S013): 0x00 success; 0x03 the netlist is rejected (bad field,
// uart_link ERROR_BAD_FIELD); 0x04 the circuit is ill-posed or the solve failed
// (frontend_tester STATUS_SOLVE_ERROR). When status is nonzero there are no
// voltages; the simulated solver then replies `ER,<frame>,<status>,<errorArg>`
// instead of VB/VN/VE.

import { ElementKind, GROUND_NODE, type Netlist, type NetlistElement, type VoltageSnapshot } from './types.ts';
import { arithFor, DivisionByZero, type ArithMode } from './arith.ts';
import { stampDc, type DcElement } from './stamp.ts';
import { luSolveDsl, type PivotSearch } from './lu.ts';
import { bcdToInt, decodeValue, WIRE_UNIT_SCALE, type UnitTable } from './value.ts';

export const STATUS_OK = 0x00;
export const STATUS_BAD_FIELD = 0x03;
export const STATUS_SOLVE_ERROR = 0x04;

/** Largest non-ground row count the protocol can carry (`node_count` 00..FE). */
export const MAX_NODE_COUNT = 0xfe;
/** frontend_tester.py capacity check: node_count > 0x20 is rejected. */
export const UART_SIM_MAX_NODE_COUNT = 0x20;

export type SolveFailure =
  | 'node-count'
  | 'element-index'
  | 'node-range'
  | 'kind'
  | 'bcd'
  | 'unit'
  | 'zero-resistance'
  | 'floating-node'
  | 'source-loop'
  | 'division-by-zero'
  | 'non-finite'
  | 'f32-overflow';

export interface SolveResult extends VoltageSnapshot {
  /** ER packet argument when status != 0 (frontend_tester: 0x0001 bad field, 0x0000 solve error). */
  errorArg: number;
  reason: SolveFailure | null;
  /** Offending element idx, when the failure is tied to one. */
  element?: number;
  /** Offending node rows (floating-node). */
  nodes?: number[];
  /** Full MNA solution as float64 numbers (node voltages then branch currents), when solved. */
  x: number[] | null;
}

export interface SolveOptions {
  /** Arithmetic model (default 'f32': float32 datapath, fused fma). */
  arith?: ArithMode;
  /** Unit code table used to decode values (default 'wire': NetlistElement.unit is the protocol code). */
  units?: UnitTable;
  /** Reject floating nodes and V/L loops before solving (default true). */
  structural?: boolean;
  /** LU pivot search (default 'residual'; 'dsl' is the kernel as written, M3-S012). */
  pivot?: PivotSearch;
  /** How V/I terminals are read (default DSL_SOURCE_CONVENTION, the solver convention D-015 keeps; M3-S005). */
  sources?: SourceConvention;
}

/**
 * Source polarity (D-015, M3-S005). The DSL kernels, the notebook and
 * solver_tester.py all use: V raises n0 above n1 (v(n0) - v(n1) = V), and I
 * flows n0 -> n1 through the source (it leaves the source into n1). D-015 keeps
 * this convention and puts the sprite's marks on the terminals in extraction
 * instead (V: n0 = "+", I: n0 = the arrow's tail). A non-default convention
 * swaps n0/n1 of that kind before stamping.
 */
export interface SourceConvention {
  voltagePositive: 'n0' | 'n1';
  currentInto: 'n1' | 'n0';
}
export const DSL_SOURCE_CONVENTION: SourceConvention = { voltagePositive: 'n0', currentInto: 'n1' };

function applySourceConvention(e: DcElement, c: SourceConvention): DcElement {
  const swap = (e.kind === ElementKind.VoltageDc && c.voltagePositive === 'n1')
    || (e.kind === ElementKind.CurrentDc && c.currentInto === 'n0');
  return swap ? { ...e, n0: e.n1, n1: e.n0 } : e;
}

function fail(
  frame: number, status: number, reason: SolveFailure,
  extra: { element?: number; nodes?: number[]; errorArg?: number } = {},
): SolveResult {
  const r: SolveResult = {
    frame, status, voltages: new Float32Array(0), reason, x: null,
    errorArg: extra.errorArg ?? (status === STATUS_BAD_FIELD ? 0x0001 : 0x0000),
  };
  if (extra.element !== undefined) r.element = extra.element;
  if (extra.nodes !== undefined) r.nodes = extra.nodes;
  return r;
}

/** Elements in ascending idx order (stable); this is the stamping order. */
export function sortedElements(netlist: Netlist): NetlistElement[] {
  return [...netlist.elements].sort((a, b) => a.idx - b.idx);
}

const isNode = (n: number, nodeCount: number) => n === GROUND_NODE || (Number.isInteger(n) && n >= 0 && n < nodeCount);
const KNOWN_KINDS = new Set<number>([
  ElementKind.Resistor, ElementKind.CurrentDc, ElementKind.VoltageDc, ElementKind.Capacitor, ElementKind.Inductor,
]);

// ------------------------------------------------------------------ structure

export interface StructureReport {
  /** Rows with no DC path (through R, V or L) to ground. */
  floatingNodes: number[];
  /** idx of the first V/L element that closes a loop of V/L elements, else null. */
  sourceLoop: number | null;
}

/**
 * Structural solvability of the DC MNA system for positive resistances: the
 * matrix is nonsingular iff every node reaches ground through R/V/L elements
 * and the V/L elements contain no loop (an element from a node to itself is a
 * loop). C is open and I adds no matrix entry.
 */
export function analyseStructure(nodeCount: number, elements: readonly DcElement[]): StructureReport {
  const parent = Array.from({ length: nodeCount + 1 }, (_, i) => i);
  const find = (i: number): number => {
    while (parent[i] !== i) {
      parent[i] = parent[parent[i]!]!;
      i = parent[i]!;
    }
    return i;
  };
  const row = (n: number) => (n === GROUND_NODE ? nodeCount : n);
  let sourceLoop: number | null = null;
  for (const e of elements) {
    if (e.kind !== ElementKind.VoltageDc && e.kind !== ElementKind.Inductor) continue;
    const a = find(row(e.n0));
    const b = find(row(e.n1));
    if (a === b) {
      sourceLoop ??= e.idx;
    } else {
      parent[a] = b;
    }
  }
  for (const e of elements) {
    if (e.kind !== ElementKind.Resistor) continue;
    const a = find(row(e.n0));
    const b = find(row(e.n1));
    if (a !== b) parent[a] = b;
  }
  const g = find(nodeCount);
  const floatingNodes: number[] = [];
  for (let n = 0; n < nodeCount; n++) if (find(n) !== g) floatingNodes.push(n);
  return { floatingNodes, sourceLoop };
}

// ------------------------------------------------------------------ spec solve

/** Decode and validate a netlist into DC elements (spec rules), or a failure. */
export function decodeNetlist(
  netlist: Netlist, units: UnitTable = 'wire', sources: SourceConvention = DSL_SOURCE_CONVENTION,
): DcElement[] | SolveResult {
  const { frame, nodeCount } = netlist;
  if (!Number.isInteger(nodeCount) || nodeCount < 0 || nodeCount > MAX_NODE_COUNT) {
    return fail(frame, STATUS_BAD_FIELD, 'node-count');
  }
  const out: DcElement[] = [];
  for (const e of sortedElements(netlist)) {
    const element = e.idx;
    if (!isNode(e.n0, nodeCount) || !isNode(e.n1, nodeCount)) return fail(frame, STATUS_BAD_FIELD, 'node-range', { element });
    if (!KNOWN_KINDS.has(e.kind)) return fail(frame, STATUS_BAD_FIELD, 'kind', { element });
    const v = decodeValue(e.valueBcd, e.unit, units);
    if (!v.ok) return fail(frame, STATUS_BAD_FIELD, v.reason, { element });
    out.push(applySourceConvention({ idx: e.idx, kind: e.kind, n0: e.n0, n1: e.n1, value: v.value }, sources));
  }
  return out;
}

function finish(frame: number, nodeCount: number, x: number[]): SolveResult {
  if (x.some((v) => !Number.isFinite(v))) return fail(frame, STATUS_SOLVE_ERROR, 'non-finite');
  const voltages = new Float32Array(nodeCount);
  for (let n = 0; n < nodeCount; n++) {
    const v = Math.fround(x[n]!);
    if (!Number.isFinite(v)) return fail(frame, STATUS_SOLVE_ERROR, 'f32-overflow', { nodes: [n] });
    voltages[n] = v;
  }
  return { frame, status: STATUS_OK, voltages, errorArg: 0, reason: null, x };
}

/** Run the DSL-order stamping + LU on decoded elements; X as float64 numbers. */
export function runDslDc(
  nodeCount: number, elements: readonly DcElement[], mode: ArithMode, pivot: PivotSearch = 'dsl',
): number[] {
  const ar = arithFor(mode);
  const sys = stampDc(nodeCount, elements, ar);
  const { X } = luSolveDsl(sys.A, sys.J, ar, pivot);
  return X.map((v) => ar.toNumber(v));
}

/** Golden spec DC solve. */
export function solveDc(netlist: Netlist, opts: SolveOptions = {}): SolveResult {
  const { arith = 'f32', units = 'wire', structural = true, pivot = 'residual', sources = DSL_SOURCE_CONVENTION } = opts;
  const { frame, nodeCount } = netlist;
  const decoded = decodeNetlist(netlist, units, sources);
  if (!Array.isArray(decoded)) return decoded;
  const zeroR = decoded.find((e) => e.kind === ElementKind.Resistor && e.value === 0);
  if (zeroR) return fail(frame, STATUS_SOLVE_ERROR, 'zero-resistance', { element: zeroR.idx });
  if (structural) {
    const s = analyseStructure(nodeCount, decoded);
    if (s.sourceLoop !== null) return fail(frame, STATUS_SOLVE_ERROR, 'source-loop', { element: s.sourceLoop });
    if (s.floatingNodes.length) return fail(frame, STATUS_SOLVE_ERROR, 'floating-node', { nodes: s.floatingNodes });
  }
  let x: number[];
  try {
    x = runDslDc(nodeCount, decoded, arith, pivot);
  } catch (err) {
    if (err instanceof DivisionByZero) return fail(frame, STATUS_SOLVE_ERROR, 'division-by-zero');
    throw err;
  }
  return finish(frame, nodeCount, x);
}

// ------------------------------------------------------------------ simulated solver

export interface UartSolverOptions {
  /** solve_core_dc's pivot search: 'residual' (default) is the kernel after the
   * D-020 fix, 'dsl' the kernel as written before it (M3-S012). */
  pivot?: PivotSearch;
}

/**
 * Predict frontend_tester.SimpyhlsDcSolver's reply (the D-012 simulated
 * solver): its input checks (ER 03/0001), the wire unit table, R/I/V
 * only, solve_core_dc (fixed pivot search by default, D-020) in Python
 * float64 (ZeroDivisionError and float32 pack overflow -> ER 04/0000), no
 * structural check. Voltages are the float64 results rounded to float32, as
 * struct.pack('>f') does.
 */
export function simulateUartSolver(netlist: Netlist, opts: UartSolverOptions = {}): SolveResult {
  const { pivot = 'residual' } = opts;
  const { frame, nodeCount } = netlist;
  if (nodeCount > UART_SIM_MAX_NODE_COUNT) return fail(frame, STATUS_BAD_FIELD, 'node-count');
  const elements: DcElement[] = [];
  let expected = 0;
  for (const e of sortedElements(netlist)) {
    const element = e.idx;
    if (e.idx !== expected++) return fail(frame, STATUS_BAD_FIELD, 'element-index', { element });
    if (!isNode(e.n0, nodeCount) || !isNode(e.n1, nodeCount)) return fail(frame, STATUS_BAD_FIELD, 'node-range', { element });
    if (e.kind !== ElementKind.Resistor && e.kind !== ElementKind.CurrentDc && e.kind !== ElementKind.VoltageDc) {
      return fail(frame, STATUS_BAD_FIELD, 'kind', { element });
    }
    const digits = bcdToInt(e.valueBcd);
    if (digits === null) return fail(frame, STATUS_BAD_FIELD, 'bcd', { element });
    const scale = WIRE_UNIT_SCALE[e.unit];
    if (scale === undefined) return fail(frame, STATUS_BAD_FIELD, 'unit', { element });
    elements.push({ idx: e.idx, kind: e.kind, n0: e.n0, n1: e.n1, value: digits * scale });
  }
  let x: number[];
  try {
    x = runDslDc(nodeCount, elements, 'py', pivot);
  } catch (err) {
    if (err instanceof DivisionByZero) return fail(frame, STATUS_SOLVE_ERROR, 'division-by-zero');
    throw err;
  }
  const voltages = new Float32Array(nodeCount);
  for (let n = 0; n < nodeCount; n++) {
    const v = Math.fround(x[n]!);
    if (Number.isFinite(x[n]!) && !Number.isFinite(v)) return fail(frame, STATUS_SOLVE_ERROR, 'f32-overflow', { nodes: [n] });
    voltages[n] = v;
  }
  return { frame, status: STATUS_OK, voltages, errorArg: 0, reason: null, x };
}

// ------------------------------------------------------------------ independent reference

/**
 * Textbook float64 MNA (G/B/C/D blocks) solved by row-oriented Gaussian
 * elimination with partial pivoting. Shares no code with stampDc/luSolveDsl.
 * Returns null voltages when a pivot is exactly zero.
 */
export function solveReference64(netlist: Netlist, units: UnitTable = 'wire'): { voltages: Float64Array | null; x: number[] | null } {
  const decoded = decodeNetlist(netlist, units);
  if (!Array.isArray(decoded)) return { voltages: null, x: null };
  const n = netlist.nodeCount;
  const branches = decoded.filter((e) => e.kind === ElementKind.VoltageDc || e.kind === ElementKind.Inductor);
  const dim = n + branches.length;
  const M = Array.from({ length: dim }, () => new Array<number>(dim + 1).fill(0));
  const node = (k: number) => (k === GROUND_NODE ? -1 : k);
  for (const e of decoded) {
    const p = node(e.n0);
    const q = node(e.n1);
    if (e.kind === ElementKind.Resistor) {
      const g = 1 / e.value;
      if (p >= 0) M[p]![p]! += g;
      if (q >= 0) M[q]![q]! += g;
      if (p >= 0 && q >= 0) {
        M[p]![q]! -= g;
        M[q]![p]! -= g;
      }
    } else if (e.kind === ElementKind.CurrentDc) {
      // Source current leaves the circuit at n0 and enters it at n1.
      if (p >= 0) M[p]![dim]! -= e.value;
      if (q >= 0) M[q]![dim]! += e.value;
    }
  }
  branches.forEach((e, b) => {
    const r = n + b;
    const p = node(e.n0);
    const q = node(e.n1);
    // Unknown i_b flows from n1 through the source to n0 (into the circuit at n0).
    if (p >= 0) { M[r]![p] = 1; M[p]![r]! -= 1; }
    if (q >= 0) { M[r]![q] = -1; M[q]![r]! += 1; }
    M[r]![dim] = e.kind === ElementKind.VoltageDc ? e.value : 0;
  });
  for (let c = 0; c < dim; c++) {
    let p = c;
    for (let r = c + 1; r < dim; r++) if (Math.abs(M[r]![c]!) > Math.abs(M[p]![c]!)) p = r;
    if (M[p]![c] === 0) return { voltages: null, x: null };
    [M[c], M[p]] = [M[p]!, M[c]!];
    for (let r = c + 1; r < dim; r++) {
      const f = M[r]![c]! / M[c]![c]!;
      if (f === 0) continue;
      for (let k = c; k <= dim; k++) M[r]![k]! -= f * M[c]![k]!;
    }
  }
  const x = new Array<number>(dim).fill(0);
  for (let r = dim - 1; r >= 0; r--) {
    let s = M[r]![dim]!;
    for (let k = r + 1; k < dim; k++) s -= M[r]![k]! * x[k]!;
    x[r] = s / M[r]![r]!;
  }
  return { voltages: Float64Array.from(x.slice(0, n)), x };
}
