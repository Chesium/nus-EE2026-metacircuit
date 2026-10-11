// DC MNA stamping, following simpyhls/examples/solve_core_dc.dsl.py stages 0-2
// (the reference algorithm; see M3_SOLVER_ASSUMPTIONS.md M3-S007/M3-S008).
//
// Layout: unknowns 0..nodeCount-1 are node voltages (solver rows as sent in the
// netlist); then one branch-current unknown per voltage source *and* per
// inductor, allocated densely in element (ascending idx) order. A is row-major
// A[row][col]; the system is A x = J.
//
// Stamps (n = GROUND_NODE terms are skipped):
//   R  (n0,n1,R):  g = 1/R;  A[n0][n0] += g, A[n0][n1] -= g, A[n1][n0] -= g, A[n1][n1] += g
//   I  (n0,n1,I):  current flows n0 -> n1 through the source:  J[n0] -= I, J[n1] += I
//   V  (n0,n1,V):  row a = aux:  A[a][n0] += 1, A[a][n1] -= 1, J[a] += V   (v(n0) - v(n1) = V)
//                  col a:        A[n0][a] -= 1, A[n1][a] += 1
//   C  DC open: no stamp, no unknown.
//   L  DC short: stamped exactly like a V source of 0.0 V (own aux unknown).
//
// The R/I/V stamps are the DSL kernel's, primitive for primitive and in the
// same order (that order matters for float accumulation). C/L are the DC limit
// (dt -> inf) of solve_core_transient.dsl.py's backward-Euler companions.

import { ElementKind, GROUND_NODE } from './types.ts';
import type { Arith } from './arith.ts';

/** One element with its value already decoded to SI units (float64). */
export interface DcElement {
  idx: number;
  kind: ElementKind;
  n0: number;
  n1: number;
  value: number;
}

export interface MnaSystem<T> {
  nodeCount: number;
  dim: number;
  /** Branch-current unknown per element (V and L), else null; same order as the input. */
  aux: (number | null)[];
  A: T[][];
  J: T[];
}

const hasBranch = (k: ElementKind): boolean => k === ElementKind.VoltageDc || k === ElementKind.Inductor;

/** Stage 0: final MNA dimension. */
export function mnaDimension(nodeCount: number, elements: readonly DcElement[]): number {
  return nodeCount + elements.filter((e) => hasBranch(e.kind)).length;
}

/** Stages 1-2: clear A and J, then stamp every element in the given order. */
export function stampDc<T>(nodeCount: number, elements: readonly DcElement[], ar: Arith<T>): MnaSystem<T> {
  const dim = mnaDimension(nodeCount, elements);
  const A: T[][] = Array.from({ length: dim }, () => Array.from({ length: dim }, () => ar.zero));
  const J: T[] = Array.from({ length: dim }, () => ar.zero);
  const accA = (i: number, j: number, d: T) => { A[i]![j] = ar.add(A[i]![j]!, d); };
  const accJ = (i: number, d: T) => { J[i] = ar.add(J[i]!, d); };
  const aux: (number | null)[] = [];
  let nextAux = nodeCount;
  const G = GROUND_NODE;

  for (const e of elements) {
    const { n0, n1 } = e;
    const v = ar.fromValue(e.value);
    switch (e.kind) {
      case ElementKind.Resistor: {
        const g = ar.div(ar.one, v);
        if (n0 !== G) {
          accA(n0, n0, g);
          if (n1 !== G) {
            const ng = ar.neg(g);
            accA(n0, n1, ng);
            accA(n1, n0, ng);
          }
        }
        if (n1 !== G) accA(n1, n1, g);
        aux.push(null);
        break;
      }
      case ElementKind.CurrentDc:
        if (n0 !== G) accJ(n0, ar.neg(v));
        if (n1 !== G) accJ(n1, v);
        aux.push(null);
        break;
      case ElementKind.VoltageDc:
      case ElementKind.Inductor: {
        const a = nextAux++;
        const src = e.kind === ElementKind.VoltageDc ? v : ar.fromValue(0);
        if (n0 !== G) {
          accA(a, n0, ar.one);
          accA(n0, a, ar.neg(ar.one));
        }
        if (n1 !== G) {
          accA(a, n1, ar.neg(ar.one));
          accA(n1, a, ar.one);
        }
        accJ(a, src);
        aux.push(a);
        break;
      }
      case ElementKind.Capacitor:
        aux.push(null);
        break;
      default:
        throw new Error(`stampDc: unsupported element kind ${String(e.kind)}`);
    }
  }
  return { nodeCount, dim, aux, A, J };
}
