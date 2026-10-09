// GM-7 solver unit tests: value decoding, stamping conventions, status codes,
// arithmetic models and the documented DSL pivot-search defect.
import { describe, expect, it } from 'vitest';
import { ElementKind, GROUND_NODE as FF, type Netlist, type NetlistElement } from '../src/backend/types.ts';
import { bcdToInt, decodeValue, FRONTEND_UNIT_SCALE, isBlankValue, WIRE_UNIT_SCALE } from '../src/backend/value.ts';
import { DivisionByZero, f32Arith, f32UnfusedArith, f64Arith, fma32, pyArith } from '../src/backend/arith.ts';
import { mnaDimension, stampDc, type DcElement } from '../src/backend/stamp.ts';
import { luSolveDsl } from '../src/backend/lu.ts';
import {
  analyseStructure, DSL_SOURCE_CONVENTION, simulateUartSolver, solveDc, solveReference64,
  STATUS_BAD_FIELD, STATUS_OK, STATUS_SOLVE_ERROR,
} from '../src/backend/solve.ts';
import { extractNetlist, protocolUnitOf, UNIT_UNSUPPORTED } from '../src/backend/netlist.ts';
import { initialState } from '../src/core/state.ts';
import { Unit } from '../src/core/constants.ts';

const R = ElementKind.Resistor, I = ElementKind.CurrentDc, V = ElementKind.VoltageDc, C = ElementKind.Capacitor, L = ElementKind.Inductor;
const el = (idx: number, kind: ElementKind, n0: number, n1: number, valueBcd: number, unit = 0): NetlistElement =>
  ({ idx, kind, n0, n1, valueBcd, unit });
const net = (nodeCount: number, ...elements: NetlistElement[]): Netlist => ({ frame: 7, nodeCount, elements });
const bits32 = (v: number) => {
  const dv = new DataView(new ArrayBuffer(4));
  dv.setFloat32(0, v);
  return dv.getUint32(0).toString(16).toUpperCase().padStart(8, '0');
};

describe('value decoding', () => {
  it('reads three packed BCD digits as an integer', () => {
    expect(bcdToInt(0x000)).toBe(0);
    expect(bcdToInt(0x010)).toBe(10);
    expect(bcdToInt(0x999)).toBe(999);
    expect(bcdToInt(0x0a0)).toBeNull();
    expect(bcdToInt(0x1000)).toBeNull();
    expect(isBlankValue(0, 0)).toBe(true);
  });

  it('uses the wire unit table by default and digits * 1eN in float64', () => {
    expect(WIRE_UNIT_SCALE).toEqual({ 0: 1, 1: 1e-3, 2: 1e-6, 3: 1e-9, 4: 1e3, 5: 1e6, 6: 1e9 });
    expect(decodeValue(0x003, 0x04)).toEqual({ ok: true, digits: 3, scale: 1e3, value: 3000 });
    expect(decodeValue(0x003, 0x01)).toMatchObject({ ok: true, value: 3 * 1e-3 });
    expect(decodeValue(0x0a5, 0)).toEqual({ ok: false, reason: 'bcd' });
    expect(decodeValue(0x001, 0x07)).toEqual({ ok: false, reason: 'unit' });
    expect(decodeValue(0x001, UNIT_UNSUPPORTED)).toEqual({ ok: false, reason: 'unit' });
  });

  it('agrees with the extractor: every translatable frontend unit keeps its scale on the wire', () => {
    for (const fu of [Unit.None, Unit.Mega, Unit.Kilo, Unit.Milli, Unit.Micro, Unit.Nano]) {
      expect(WIRE_UNIT_SCALE[protocolUnitOf(fu)]).toBe(FRONTEND_UNIT_SCALE[fu]);
    }
    expect(protocolUnitOf(Unit.Pico)).toBe(UNIT_UNSUPPORTED);
  });
});

describe('DC stamping (solve_core_dc.dsl.py layout)', () => {
  const dc = (idx: number, kind: ElementKind, n0: number, n1: number, value: number): DcElement => ({ idx, kind, n0, n1, value });

  it('R: +-1/R block; I: J[n0] -= I, J[n1] += I; V: aux row/col after the nodes', () => {
    const s = stampDc(2, [dc(0, V, 0, FF, 5), dc(1, R, 0, 1, 4), dc(2, I, 1, 0, 2)], f64Arith);
    expect(s.dim).toBe(3);
    expect(s.aux).toEqual([2, null, null]);
    expect(s.A).toEqual([
      [0.25, -0.25, -1],
      [-0.25, 0.25, 0],
      [1, 0, 0],
    ]);
    expect(s.J).toEqual([2, -2, 5]);
  });

  it('C is open (no stamp); L is a 0 V source with its own aux, numbered in idx order with V', () => {
    const els = [dc(0, L, 0, 1, 1e-3), dc(1, C, 0, FF, 1e-6), dc(2, V, 1, FF, 3)];
    expect(mnaDimension(2, els)).toBe(4);
    const s = stampDc(2, els, f64Arith);
    expect(s.aux).toEqual([2, null, 3]);
    expect(s.A).toEqual([
      [0, 0, -1, 0],
      [0, 0, 1, -1],
      [1, -1, 0, 0],
      [0, 1, 0, 0],
    ]);
    expect(s.J).toEqual([0, 0, 0, 3]);
  });

  it('sign conventions: V raises n0 above n1; I pushes current into n1', () => {
    expect(solveDc(net(1, el(0, V, 0, FF, 0x005), el(1, R, 0, FF, 0x001))).voltages[0]).toBe(5);
    expect(solveDc(net(1, el(0, V, FF, 0, 0x005), el(1, R, 0, FF, 0x001))).voltages[0]).toBe(-5);
    expect(solveDc(net(1, el(0, I, FF, 0, 0x002, 1), el(1, R, 0, FF, 0x001, 4))).voltages[0]).toBeCloseTo(2, 6);
    expect(solveDc(net(1, el(0, I, 0, FF, 0x002, 1), el(1, R, 0, FF, 0x001, 4))).voltages[0]).toBeCloseTo(-2, 6);
  });

  it('inductor shorts, capacitor opens', () => {
    const r = solveDc(net(2, el(0, V, 0, FF, 0x005), el(1, L, 0, 1, 0x010, 3), el(2, R, 1, FF, 0x002, 4), el(3, C, 1, FF, 0x010)));
    expect(Array.from(r.voltages)).toEqual([5, 5]);
    expect(r.x).toHaveLength(4); // two branch currents (V, L)
    const open = solveDc(net(2, el(0, V, 0, FF, 0x005), el(1, C, 0, 1, 0x010), el(2, R, 1, FF, 0x002)));
    expect(Array.from(open.voltages)).toEqual([5, 0]);
  });
});

describe('boot circuit', () => {
  it('extracts and solves to -10 V on the right rail (V terminal n0 is the grounded rail)', () => {
    const { netlist } = extractNetlist(initialState());
    expect(netlist.elements.map((e) => [e.kind, e.n0, e.n1])).toEqual([[V, FF, 0], [R, FF, 0], [R, FF, 0]]);
    const spec = solveDc(netlist);
    expect(spec.status).toBe(STATUS_OK);
    expect(Array.from(spec.voltages)).toEqual([-10]);
    expect(spec.x![1]).toBeCloseTo(0.2, 6); // aux current
    const sim = simulateUartSolver(netlist);
    expect(Array.from(sim.voltages, bits32)).toEqual(['C1200000']);
    for (const arith of ['py', 'f64', 'f32', 'f32-unfused'] as const) {
      expect(Array.from(solveDc(netlist, { arith }).voltages)).toEqual([-10]);
    }
  });

  it('the Q-009 source convention is one switch: n1-positive V sources give +10 V', () => {
    const { netlist } = extractNetlist(initialState());
    expect(DSL_SOURCE_CONVENTION).toEqual({ voltagePositive: 'n0', currentInto: 'n1' });
    expect(Array.from(solveDc(netlist, { sources: { voltagePositive: 'n1', currentInto: 'n1' } }).voltages)).toEqual([10]);
    const i = net(1, el(0, I, FF, 0, 0x002, 1), el(1, R, 0, FF, 0x001, 4));
    expect(solveDc(i, { sources: { voltagePositive: 'n0', currentInto: 'n0' } }).voltages[0]).toBeCloseTo(-2, 6);
  });
});

describe('status codes', () => {
  const ok = (n: Netlist) => solveDc(n).status;
  it('rejects malformed fields with 0x03 (ER arg 0x0001)', () => {
    for (const n of [
      net(1, el(0, V, 0, FF, 0x0a5), el(1, R, 0, FF, 1)),
      net(1, el(0, V, 0, FF, 0x005, 0x07), el(1, R, 0, FF, 1)),
      net(1, el(0, V, 0, FF, 0x005, UNIT_UNSUPPORTED), el(1, R, 0, FF, 1)),
      net(1, el(0, V, 1, FF, 0x005), el(1, R, 0, FF, 1)),
      net(1, el(0, 6 as ElementKind, 0, FF, 0x005), el(1, R, 0, FF, 1)),
      net(0xff),
    ]) {
      const r = solveDc(n);
      expect([r.status, r.errorArg, r.voltages.length]).toEqual([STATUS_BAD_FIELD, 1, 0]);
    }
  });

  it('reports ill-posed circuits with 0x04: 0 ohm, floating nodes, no ground, V/L loops', () => {
    expect(solveDc(net(1, el(0, V, 0, FF, 5), el(1, R, 0, FF, 0))).reason).toBe('zero-resistance');
    expect(solveDc(net(2, el(0, R, 0, 1, 0x100)))).toMatchObject({ status: STATUS_SOLVE_ERROR, reason: 'floating-node', nodes: [0, 1] });
    expect(solveDc(net(1))).toMatchObject({ status: STATUS_SOLVE_ERROR, nodes: [0] });
    expect(solveDc(net(1, el(0, I, FF, 0, 1)))).toMatchObject({ reason: 'floating-node' });
    expect(solveDc(net(2, el(0, V, 0, FF, 5), el(1, R, 0, FF, 1), el(2, C, 0, 1, 1)))).toMatchObject({ reason: 'floating-node', nodes: [1] });
    expect(solveDc(net(1, el(0, V, 0, FF, 5), el(1, V, 0, FF, 5), el(2, R, 0, FF, 1)))).toMatchObject({ reason: 'source-loop', element: 1 });
    expect(solveDc(net(1, el(0, V, 0, FF, 5), el(1, L, 0, FF, 1), el(2, R, 0, FF, 1)))).toMatchObject({ reason: 'source-loop', element: 1 });
    expect(solveDc(net(0, el(0, V, FF, FF, 5)))).toMatchObject({ reason: 'source-loop', element: 0 });
    expect(ok(net(0))).toBe(STATUS_OK);
    expect(ok(net(0, el(0, R, FF, FF, 0x100)))).toBe(STATUS_OK);
    expect(ok(net(1, el(0, V, 0, FF, 0), el(1, I, FF, 0, 0), el(2, R, 0, FF, 0x100)))).toBe(STATUS_OK);
  });

  it('structural analysis is exactly the solvability condition', () => {
    const d = (kind: ElementKind, n0: number, n1: number): DcElement => ({ idx: 0, kind, n0, n1, value: 1 });
    expect(analyseStructure(2, [d(R, 0, FF), d(V, 1, 0)])).toEqual({ floatingNodes: [], sourceLoop: null });
    expect(analyseStructure(2, [d(R, 0, FF), d(I, 1, 0)])).toEqual({ floatingNodes: [1], sourceLoop: null });
  });

  it('the simulated solver: C/L, idx gaps and > 0x20 nodes are ER 03/0001; singular systems surface as ER 04/0000 or numbers', () => {
    expect(simulateUartSolver(net(1, el(0, C, 0, FF, 1), el(1, R, 0, FF, 1)))).toMatchObject({ status: 3, errorArg: 1, reason: 'kind' });
    expect(simulateUartSolver(net(1, el(1, R, 0, FF, 1)))).toMatchObject({ status: 3, reason: 'element-index' });
    expect(simulateUartSolver(net(0x21))).toMatchObject({ status: 3, reason: 'node-count' });
    expect(simulateUartSolver(net(2, el(0, R, 0, 1, 0x100)))).toMatchObject({ status: 4, errorArg: 0, reason: 'division-by-zero' });
    expect(simulateUartSolver(net(1, el(0, V, 0, FF, 5), el(1, R, 0, FF, 0)))).toMatchObject({ status: 4, reason: 'division-by-zero' });
  });
});

describe('arithmetic models', () => {
  it('fma32 rounds once where the float64 sum lands on a float32 midpoint', () => {
    const a = Math.fround(2 ** -24 * (1 + 2 ** -23));
    const b = Math.fround(1 - 2 ** -23);
    const c = Math.fround(1 + 2 ** -23);
    expect(fma32(a, b, c)).toBe(1 + 2 ** -23); // exact a*b+c is just below the midpoint
    expect(f32UnfusedArith.fma(a, b, c)).toBe(1 + 2 ** -22); // two roundings hit the tie, round to even
    expect(Math.fround(a * b + c)).toBe(1 + 2 ** -22); // as does float64-then-float32
    expect(f32Arith.fma(-0, 1, -0)).toBe(-0);
    expect(Object.is(f32Arith.fma(1, 1, -1), 0)).toBe(true);
  });

  it('py: Python ints keep -(0) == +0 and integer results; division by zero raises', () => {
    expect(pyArith.neg(pyArith.zero)).toBe(0n);
    expect(Object.is(pyArith.neg(0), -0)).toBe(true);
    expect(pyArith.fma(1n, -1n, 1n)).toBe(0n);
    expect(pyArith.div(1n, 4)).toBe(0.25);
    expect(() => pyArith.div(1, -0)).toThrow(DivisionByZero);
    expect(f64Arith.div(1, 0)).toBe(Infinity);
  });
});

describe('solve_core_dc.dsl.py pivot search (M3-S012)', () => {
  // Structurally sound: every node reaches ground, V sources form a forest.
  const circuit = net(5,
    el(0, R, FF, 2, 0x296), el(1, R, 1, FF, 0x298), el(2, R, 4, 0, 0x370),
    el(3, V, 3, 1, 0x629), el(4, V, FF, 0, 0x232, 4));

  it('as written it pivots on |A(i,j)| and divides by an exact zero pivot', () => {
    expect(solveDc(circuit, { pivot: 'dsl', arith: 'f64' }).reason).toBe('non-finite'); // passes the structural check
    expect(simulateUartSolver(circuit)).toMatchObject({ status: STATUS_SOLVE_ERROR, reason: 'division-by-zero' });
    expect(solveDc(circuit, { pivot: 'dsl' })).toMatchObject({ status: STATUS_SOLVE_ERROR, reason: 'non-finite' });
  });

  it('with U(0..j-1, j) computed before the search it solves the circuit', () => {
    const r = solveDc(circuit);
    expect(r.status).toBe(STATUS_OK);
    const ref = solveReference64(circuit).voltages!;
    Array.from(r.voltages).forEach((v, i) => expect(v).toBeCloseTo(ref[i]!, 2));
    expect(r.voltages[0]).toBeCloseTo(-232000, -1);
    expect(r.voltages[3]).toBeCloseTo(629, 3);
  });

  it('both searches agree bit for bit when they choose the same pivots', () => {
    const els: DcElement[] = [
      { idx: 0, kind: R, n0: 0, n1: FF, value: 2 }, { idx: 1, kind: R, n0: 0, n1: 1, value: 3 },
      { idx: 2, kind: R, n0: 1, n1: FF, value: 5 }, { idx: 3, kind: I, n0: FF, n1: 1, value: 1 },
    ];
    const run = (p: 'dsl' | 'residual') => {
      const s = stampDc(2, els, f32Arith);
      return luSolveDsl(s.A, s.J, f32Arith, p);
    };
    expect(run('residual').pivot).toEqual(run('dsl').pivot);
    expect(run('residual').X).toEqual(run('dsl').X);
  });
});

describe('float32 precision hazards', () => {
  it('a self-loop element (n0 == n1) is stamped as in the kernel and can absorb a small source', () => {
    // 993 uA into 575 kohm = 571 V, plus a 617 MA source with both terminals on node 0.
    const n = net(1, el(0, I, FF, 0, 0x993, 2), el(1, R, FF, 0, 0x575, 4), el(2, I, 0, 0, 0x617, 5));
    expect(solveDc(n, { arith: 'f64' }).voltages[0]).toBeCloseTo(570.98, 1);
    expect(solveDc(n).voltages[0]).toBe(0);
    expect(simulateUartSolver(n).voltages[0]).toBeCloseTo(570.98, 1);
  });
});
