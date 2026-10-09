// Scalar arithmetic models for the DSL solver primitives (neg_comb, abs_comb,
// gt_comb, fma, div, and the += of accumA/accumJ).
//
// The simpyhls DSL names its registers f32_*, but its Python simulation has no
// type semantics, so the uart_link simulated solver (frontend_tester.py) runs
// in Python float64 with Python int constants (M3-S010). Each model below lets
// the same DSL-order solver reproduce one of those behaviours bit for bit:
//
//   py           Python semantics: float64, plus Python ints for the DSL's
//                literal constants (f32_0 = 0, f32_5 = 1) and anything computed
//                only from them. Ints differ from floats in one observable way:
//                -(0) is +0, so signed zeros differ from IEEE. Division by an
//                exact zero raises (ZeroDivisionError). fma is a*b+c, unfused.
//   f64          plain IEEE float64, unfused fma, x/0 -> +-inf/NaN.
//   f32          IEEE float32 for every primitive result, fma fused (one
//                rounding), x/0 -> +-inf/NaN. Models a float32 FPGA datapath.
//   f32-unfused  as f32 but fma rounds the product and the sum separately.

export type ArithMode = 'py' | 'f64' | 'f32' | 'f32-unfused';

export class DivisionByZero extends Error {
  constructor() {
    super('division by zero');
    this.name = 'DivisionByZero';
  }
}

export interface Arith<T> {
  readonly mode: ArithMode;
  /** DSL literal `f32_0 = 0` (clear value). */
  readonly zero: T;
  /** DSL literal `f32_5 = 1` (resistor numerator, voltage-source coupling). */
  readonly one: T;
  /** fetchElemVal0: an element value given as a float64. */
  fromValue(x: number): T;
  neg(a: T): T;
  abs(a: T): T;
  gt(a: T, b: T): boolean;
  /** accumA / accumJ: mem += delta. */
  add(a: T, b: T): T;
  fma(a: T, b: T, c: T): T;
  div(a: T, b: T): T;
  toNumber(a: T): number;
}

// ------------------------------------------------------------------ py

/** Python int is modelled as bigint, Python float as number. */
export type PyNum = number | bigint;

const pyNum = (a: PyNum): number => (typeof a === 'bigint' ? Number(a) : a);

export const pyArith: Arith<PyNum> = {
  mode: 'py',
  zero: 0n,
  one: 1n,
  fromValue: (x) => x,
  neg: (a) => -a,
  abs: (a) => (typeof a === 'bigint' ? (a < 0n ? -a : a) : Math.abs(a)),
  gt: (a, b) => pyNum(a) > pyNum(b),
  add: (a, b) => (typeof a === 'bigint' && typeof b === 'bigint' ? a + b : pyNum(a) + pyNum(b)),
  fma: (a, b, c) =>
    typeof a === 'bigint' && typeof b === 'bigint' && typeof c === 'bigint'
      ? a * b + c
      : pyNum(a) * pyNum(b) + pyNum(c),
  div: (a, b) => {
    const d = pyNum(b);
    if (d === 0) throw new DivisionByZero();
    return pyNum(a) / d;
  },
  toNumber: pyNum,
};

// ------------------------------------------------------------------ f64

export const f64Arith: Arith<number> = {
  mode: 'f64',
  zero: 0,
  one: 1,
  fromValue: (x) => x,
  neg: (a) => -a,
  abs: Math.abs,
  gt: (a, b) => a > b,
  add: (a, b) => a + b,
  fma: (a, b, c) => a * b + c,
  div: (a, b) => a / b,
  toNumber: (a) => a,
};

// ------------------------------------------------------------------ f32

const f32 = Math.fround;
const f32Buf = new Float32Array(1);
const u32Buf = new Uint32Array(f32Buf.buffer);

/** Next float32 towards +inf (x finite float32). */
function nextUp32(x: number): number {
  if (x === 0) return 1.401298464324817e-45;
  f32Buf[0] = x;
  u32Buf[0] = x > 0 ? u32Buf[0]! + 1 : u32Buf[0]! - 1;
  return f32Buf[0]!;
}

/** Next float32 towards -inf (x finite float32). */
function nextDown32(x: number): number {
  return -nextUp32(-x);
}

/**
 * Correctly rounded float32 fused multiply-add for float32 inputs. The product
 * of two float32 values is exact in float64; the float64 sum is fixed up with
 * an exact TwoSum error term when it lands exactly on a float32 rounding
 * midpoint (the only case where rounding twice differs from rounding once).
 */
export function fma32(a: number, b: number, c: number): number {
  const p = a * b;
  const s = p + c;
  const r = f32(s);
  if (!Number.isFinite(s) || !Number.isFinite(r) || r === s) return r;
  const bb = s - p;
  const err = (p - (s - bb)) + (c - bb);
  if (err === 0) return r;
  const o = r < s ? nextUp32(r) : nextDown32(r);
  if (s !== (r + o) / 2) return r;
  const hi = Math.max(r, o);
  const lo = Math.min(r, o);
  return err > 0 ? hi : lo;
}

export const f32Arith: Arith<number> = {
  mode: 'f32',
  zero: 0,
  one: 1,
  fromValue: (x) => f32(x),
  neg: (a) => -a,
  abs: Math.abs,
  gt: (a, b) => a > b,
  add: (a, b) => f32(a + b),
  fma: fma32,
  div: (a, b) => f32(a / b),
  toNumber: (a) => a,
};

export const f32UnfusedArith: Arith<number> = {
  ...f32Arith,
  mode: 'f32-unfused',
  fma: (a, b, c) => f32(f32(a * b) + c),
};

// Arith<T> is invariant in T (T appears in both argument and result position).
export function arithFor(mode: ArithMode): Arith<any> {
  switch (mode) {
    case 'py': return pyArith;
    case 'f64': return f64Arith;
    case 'f32': return f32Arith;
    case 'f32-unfused': return f32UnfusedArith;
  }
}
