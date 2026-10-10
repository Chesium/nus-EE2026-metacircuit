// GM-7 differential tests: the golden DC solver against the simpyhls DSL
// kernels run in Python and against src/uart_link's simulated solver
// (frontend_tester.py), using fixtures from tools/gen_solver_fixtures.py
// (`npm run fixtures:solver`):
//   solver_dc_as_written.json  frozen kernel before the D-020 pivot fix; checks
//                              the golden's { pivot: 'dsl' } option
//   solver_dc.json             the simpyhls checkout's kernel; checks the
//                              defaults (fixed pivot search). Until the kernel
//                              branch lands and the fixture is regenerated it
//                              still holds the as-written results, so those
//                              tests are expected failures (kernelStatus.ts).
import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import type { Netlist } from '../src/backend/types.ts';
import { DivisionByZero, f64Arith } from '../src/backend/arith.ts';
import type { PivotSearch } from '../src/backend/lu.ts';
import {
  decodeNetlist, runDslDc, simulateUartSolver, solveDc, solveReference64, STATUS_OK, STATUS_SOLVE_ERROR,
  type SolveResult,
} from '../src/backend/solve.ts';
import { stampDc, type DcElement } from '../src/backend/stamp.ts';
import { itAfterKernelFix } from './kernelStatus.ts';

interface Fixture {
  kernels: 'live' | 'as-written';
  solveCoreDcSha256: string;
  seed: number;
  randomCases: number;
  cases: {
    name: string;
    category: string;
    netlist: Netlist;
    expect?: { node: number; value: number }[];
    uart: { lines: string[]; status?: number; bits?: string[]; error?: { code: number; arg: number } };
    dsl?: Record<'py' | 'f32' | 'f32-unfused', { x?: string[]; error?: string }>;
    transient?: { x?: string[]; error?: string };
  }[];
}

const load = (name: string): Fixture => JSON.parse(readFileSync(new URL(`./fixtures/${name}`, import.meta.url), 'utf8'));
const fx = load('solver_dc.json');
const fxAsWritten = load('solver_dc_as_written.json');

const dv = new DataView(new ArrayBuffer(8));
const hex32 = (v: number) => (dv.setFloat32(0, v), dv.getUint32(0).toString(16).toUpperCase().padStart(8, '0'));
const hex64 = (v: number) => (dv.setFloat64(0, v), dv.getBigUint64(0).toString(16).toUpperCase().padStart(16, '0'));
const fromHex64 = (h: string) => (dv.setBigUint64(0, BigInt(`0x${h}`)), dv.getFloat64(0));
const fromHex32 = (h: string) => (dv.setUint32(0, Number.parseInt(h, 16)), dv.getFloat32(0));
/** Bit equality, except that any NaN equals any NaN (payloads are not modelled). */
const sameBits = (got: string, want: string, fromHex: (h: string) => number) =>
  got === want || (Number.isNaN(fromHex(got)) && Number.isNaN(fromHex(want)));

function decoded(nl: Netlist): DcElement[] {
  const d = decodeNetlist(nl, 'wire');
  if (!Array.isArray(d)) throw new Error(`fixture netlist not decodable: ${d.reason}`);
  return d;
}

function runOrError(nl: Netlist, mode: 'py' | 'f32' | 'f32-unfused', pivot: PivotSearch): number[] | 'ZeroDivisionError' {
  try {
    return runDslDc(nl.nodeCount, decoded(nl), mode, pivot);
  } catch (e) {
    if (e instanceof DivisionByZero) return 'ZeroDivisionError';
    throw e;
  }
}

/** Every simulated-solver reply of the fixture, predicted bit for bit (VN bits, VB status, ER code/arg). */
function uartMismatches(f: Fixture, solve: (nl: Netlist) => SolveResult): string[] {
  const mismatches: string[] = [];
  for (const c of f.cases) {
    const g = solve(c.netlist);
    if (c.uart.error) {
      if (g.status !== c.uart.error.code || g.errorArg !== c.uart.error.arg) {
        mismatches.push(`${c.name}: want ER ${c.uart.error.code}/${c.uart.error.arg}, got ${g.status}/${g.errorArg} (${g.reason})`);
      }
      continue;
    }
    if (g.status !== c.uart.status) {
      mismatches.push(`${c.name}: want status ${c.uart.status}, got ${g.status} (${g.reason})`);
      continue;
    }
    const got = Array.from(g.voltages, hex32);
    const want = c.uart.bits!;
    if (got.length !== want.length || got.some((h, i) => !sameBits(h, want[i]!, fromHex32))) {
      mismatches.push(`${c.name}: want ${want.join(' ')}, got ${got.join(' ')}`);
    }
  }
  return mismatches;
}

/** solve_core_dc run_python results of one primitive flavour, bit for bit. */
function dslMismatches(f: Fixture, mode: 'py' | 'f32' | 'f32-unfused', pivot: PivotSearch): { compared: number; mismatches: string[] } {
  const mismatches: string[] = [];
  let compared = 0;
  for (const c of f.cases) {
    const want = c.dsl?.[mode];
    if (!want) continue;
    compared++;
    const got = runOrError(c.netlist, mode, pivot);
    if (want.error || got === 'ZeroDivisionError') {
      if (got !== want.error) mismatches.push(`${c.name}: want ${want.error ?? 'values'}, got ${String(got)}`);
      continue;
    }
    const hex = mode === 'py' ? hex64 : hex32;
    const from = mode === 'py' ? fromHex64 : fromHex32;
    const g = got.map(hex);
    if (g.length !== want.x!.length || g.some((h, i) => !sameBits(h, want.x![i]!, from))) {
      mismatches.push(`${c.name}: want ${want.x!.join(' ')}, got ${g.join(' ')}`);
    }
  }
  return { compared, mismatches };
}

/** C/L stamps against solve_core_transient.dsl.py in its DC limit (dt = inf). */
function transientMismatches(f: Fixture, pivot: PivotSearch): string[] {
  const mismatches: string[] = [];
  for (const c of f.cases) {
    const want = c.transient;
    if (!want) continue;
    const got = runOrError(c.netlist, 'py', pivot);
    if (want.error || got === 'ZeroDivisionError') {
      if (got !== want.error) mismatches.push(`${c.name}: want ${want.error ?? 'values'}, got ${String(got)}`);
      continue;
    }
    const w = want.x!.map(fromHex64);
    // Values must be equal; signed zeros may differ (the transient kernel adds float 0.0 terms).
    if (w.length !== got.length || got.some((v, i) => !(v === w[i] || (Number.isNaN(v) && Number.isNaN(w[i]!))))) {
      mismatches.push(`${c.name}: want ${w.join(' ')}, got ${got.join(' ')}`);
    }
  }
  return mismatches;
}

describe('solver fixtures', () => {
  it('cover the intended mix, generated from the same netlists for both kernel sets', () => {
    expect([fx.kernels, fxAsWritten.kernels]).toEqual(['live', 'as-written']);
    for (const f of [fx, fxAsWritten]) {
      expect(f.cases.length).toBe(f.randomCases + 39);
      expect(f.cases.filter((c) => c.dsl).length).toBeGreaterThan(250);
      expect(f.cases.filter((c) => c.transient).length).toBeGreaterThan(30);
    }
    expect(fx.cases.map((c) => c.netlist)).toEqual(fxAsWritten.cases.map((c) => c.netlist));
  });
});

describe('golden vs uart_link simulated solver (frontend_tester.py)', () => {
  it('as written (frozen kernel): simulateUartSolver({ pivot: "dsl" }) predicts every reply bit for bit', () => {
    expect(uartMismatches(fxAsWritten, (nl) => simulateUartSolver(nl, { pivot: 'dsl' }))).toEqual([]);
  });

  itAfterKernelFix('fixed kernel (D-020): simulateUartSolver() predicts every reply bit for bit', () => {
    expect(uartMismatches(fx, (nl) => simulateUartSolver(nl))).toEqual([]);
  });

  it('meets solver_tester.py expectations for its built-in cases', () => {
    const cases = fx.cases.filter((c) => c.expect);
    expect(cases.length).toBe(2);
    for (const c of cases) {
      for (const r of [simulateUartSolver(c.netlist), simulateUartSolver(c.netlist, { pivot: 'dsl' }), solveDc(c.netlist)]) {
        expect(r.status).toBe(STATUS_OK);
        for (const e of c.expect!) {
          expect(Math.abs(r.voltages[e.node]! - e.value)).toBeLessThanOrEqual(1e-3 + 1e-3 * Math.abs(e.value));
        }
      }
    }
  });
});

describe('golden vs simpyhls solve_core_dc.dsl.py (run_python)', () => {
  for (const mode of ['py', 'f32', 'f32-unfused'] as const) {
    it(`as written (frozen kernel): pivot "dsl" matches the ${mode} primitive flavour bit for bit`, () => {
      const r = dslMismatches(fxAsWritten, mode, 'dsl');
      expect(r.compared).toBeGreaterThan(250);
      expect(r.mismatches).toEqual([]);
    });

    itAfterKernelFix(`fixed kernel (D-020): pivot "residual" matches the ${mode} primitive flavour bit for bit`, () => {
      const r = dslMismatches(fx, mode, 'residual');
      expect(r.compared).toBeGreaterThan(250);
      expect(r.mismatches).toEqual([]);
    });
  }

  it('C/L stamps equal solve_core_transient.dsl.py in its DC limit (dt = inf), with its pivot search as written or fixed', () => {
    // D-020 names solve_core_dc only; the transient kernel has the same search and may or may not be fixed with it.
    const byPivot = { dsl: transientMismatches(fx, 'dsl'), residual: transientMismatches(fx, 'residual') };
    expect(byPivot.dsl.length === 0 || byPivot.residual.length === 0, JSON.stringify(byPivot)).toBe(true);
  });
});

// ------------------------------------------------------------------ spec vs references

/** |a - b| <= tol * max(1, max_n |ref_n|): node voltages share one scale. */
function close(a: ArrayLike<number>, b: ArrayLike<number>, tol: number): boolean {
  if (a.length !== b.length) return false;
  let scale = 1;
  for (let i = 0; i < b.length; i++) scale = Math.max(scale, Math.abs(b[i]!));
  for (let i = 0; i < a.length; i++) if (!(Math.abs(a[i]! - b[i]!) <= tol * scale)) return false;
  return true;
}

/**
 * Normwise backward error of x for the float64 system A x = J:
 * ||J - A x|| / (||A|| ||x|| + ||J||), infinity norms.
 */
function backwardError(nl: Netlist, x: number[]): number {
  const s = stampDc(nl.nodeCount, decoded(nl), f64Arith);
  let res = 0;
  let na = 0;
  let nx = 0;
  let nj = 0;
  for (let i = 0; i < s.dim; i++) {
    let acc = -s.J[i]!;
    let row = 0;
    for (let j = 0; j < s.dim; j++) {
      acc += s.A[i]![j]! * x[j]!;
      row += Math.abs(s.A[i]![j]!);
    }
    res = Math.max(res, Math.abs(acc));
    na = Math.max(na, row);
    nj = Math.max(nj, Math.abs(s.J[i]!));
  }
  for (const v of x) nx = Math.max(nx, Math.abs(v));
  const den = na * nx + nj;
  return den === 0 ? 0 : res / den;
}

const hasSelfLoop = (nl: Netlist) => nl.elements.some((e) => e.n0 === e.n1 && (e.kind === 1 || e.kind === 2));
const randomCases = fx.cases.filter((c) => c.category.startsWith('random'));
const structuralReasons = new Set(['floating-node', 'source-loop', 'zero-resistance']);
const wideUnits = new Set(['random-wide', 'random-cl', 'random-loose']);

describe('golden spec solve', () => {
  it('float64 DSL-order LU (residual pivot) is backward stable and matches the textbook solver', () => {
    const bad: string[] = [];
    let n = 0;
    for (const c of fx.cases) {
      const r = solveDc(c.netlist, { arith: 'f64' });
      if (r.status !== STATUS_OK) continue;
      n++;
      const eta = backwardError(c.netlist, r.x!);
      if (!(eta <= 1e-14)) bad.push(`${c.name}: eta ${eta}`);
      // Forward agreement only where wide unit spreads cannot make the system ill-conditioned.
      if (wideUnits.has(c.category)) continue;
      const ref = solveReference64(c.netlist);
      if (!ref.x || !close(r.x!, ref.x, 1e-9)) bad.push(`${c.name}: ${r.x!.join(' ')} vs ${ref.x?.join(' ')}`);
    }
    expect(n).toBeGreaterThan(250);
    expect(bad).toEqual([]);
  });

  for (const arith of ['f32', 'f32-unfused'] as const) {
    it(`${arith} solutions are backward stable (eta <= 1e-5) unless a self-loop element absorbs precision`, () => {
      const bad: string[] = [];
      let n = 0;
      for (const c of fx.cases) {
        const r = solveDc(c.netlist, { arith });
        if (r.status !== STATUS_OK || hasSelfLoop(c.netlist)) continue;
        n++;
        const eta = backwardError(c.netlist, r.x!);
        if (!(eta <= 1e-5)) bad.push(`${c.name}: eta ${eta}`);
      }
      expect(n).toBeGreaterThan(180);
      expect(bad).toEqual([]);
    });
  }

  it('solves every structurally sound well-scaled circuit; extreme unit spreads may fail only with status 04', () => {
    const failures: Record<string, string[]> = { f64: [], f32: [], 'f32-unfused': [] };
    for (const c of randomCases) {
      for (const arith of ['f64', 'f32', 'f32-unfused'] as const) {
        const r = solveDc(c.netlist, { arith });
        if (r.status === STATUS_OK || structuralReasons.has(r.reason!)) continue;
        expect(r.status).toBe(STATUS_SOLVE_ERROR);
        expect(c.category).not.toBe('random-nice');
        failures[arith]!.push(c.name);
      }
    }
    // Pinned (deterministic fixtures); conductance spreads 3e9..1e19 (M3-S015).
    expect(failures).toEqual(EXPECTED_NUMERIC_FAILURES);
  });

});

// ------------------------------------------------------------------ disagreement ladder

/**
 * Move from the simulated solver's behaviour to the golden spec one factor at
 * a time and count the cases whose outcome (status, or voltages beyond 1e-4 of
 * their scale) changes at each step.
 */
const LADDER: { step: string; solve: (nl: Netlist) => SolveResult }[] = [
  { step: 'uart_link simulated solver, kernel as written', solve: (nl) => simulateUartSolver(nl, { pivot: 'dsl' }) },
  { step: '+ fixed pivot search (D-020, = simulateUartSolver default)', solve: (nl) => simulateUartSolver(nl) },
  {
    step: '+ C/L kinds, idx gaps, >0x20 nodes accepted',
    solve: (nl) => solveDc(nl, { arith: 'py', pivot: 'residual', structural: false }),
  },
  {
    step: '+ structural singularity check',
    solve: (nl) => solveDc(nl, { arith: 'py', pivot: 'residual' }),
  },
  { step: '+ float32 arithmetic (= solveDc default)', solve: (nl) => solveDc(nl) },
];

const sameOutcome = (a: SolveResult, b: SolveResult) =>
  a.status === b.status && a.errorArg === b.errorArg && (a.status !== STATUS_OK || close(a.voltages, b.voltages, 1e-4));

describe('golden spec vs simulated solver', () => {
  it('the ladder ends at solveDc with its documented defaults', () => {
    for (const c of fx.cases) {
      expect(LADDER.at(-1)!.solve(c.netlist)).toEqual(
        solveDc(c.netlist, { arith: 'f32', units: 'wire', pivot: 'residual', structural: true }),
      );
    }
  });

  it('every disagreement is attributed to one documented factor', () => {
    const changed: Record<string, number> = {};
    let endToEnd = 0;
    for (const c of fx.cases) {
      const outcomes = LADDER.map((l) => l.solve(c.netlist));
      for (let i = 1; i < outcomes.length; i++) {
        const step = LADDER[i]!.step;
        if (!sameOutcome(outcomes[i - 1]!, outcomes[i]!)) changed[step] = (changed[step] ?? 0) + 1;
      }
      if (!sameOutcome(outcomes[0]!, outcomes.at(-1)!)) endToEnd++;
    }
    // Pinned breakdown (deterministic fixtures), reported in M3_SOLVER_ASSUMPTIONS.md.
    expect({ cases: fx.cases.length, endToEnd, changed }).toEqual(EXPECTED_LADDER);
  });
});

// Conductance spreads 3e9..1e19 (wire units nano..giga), past float32's working range.
const EXPECTED_NUMERIC_FAILURES = {
  f64: ['random:189', 'random:270'],
  f32: ['random:052', 'random:065', 'random:110', 'random:189', 'random:190', 'random:199', 'random:241', 'random:270'],
  'f32-unfused': ['random:052', 'random:065', 'random:110', 'random:189', 'random:190', 'random:199', 'random:241', 'random:270'],
};

const EXPECTED_LADDER = {
  cases: 339,
  endToEnd: 94,
  changed: {
    '+ fixed pivot search (D-020, = simulateUartSolver default)': 37,
    '+ C/L kinds, idx gaps, >0x20 nodes accepted': 43,
    '+ structural singularity check': 3,
    '+ float32 arithmetic (= solveDc default)': 22,
  },
};
