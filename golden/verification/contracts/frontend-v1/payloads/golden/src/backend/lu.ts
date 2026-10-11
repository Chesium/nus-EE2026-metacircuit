// Dense LU with partial row pivoting, forward and backward substitution, in
// exactly the primitive order of simpyhls/examples/solve_core_dc.dsl.py
// stages 3-5. Stage 3's column update is lu_core.dsl.py with a pivot search
// and row swap added; stages 4 and 5 are forward_sub_core.dsl.py and
// backward_sub_core.dsl.py. Running it with a given Arith reproduces that
// arithmetic bit for bit (M3-S011).
//
// Packed LU: U on and above the diagonal, L strictly below it (unit diagonal
// implicit). Rows of A, of the already computed L columns, and of J are swapped
// together when a pivot is chosen.
//
// Pivot search (M3-S012). As written, the kernel's search for column j forms
// A(i,j) - sum_{k<j} LU(i,k) * LU(k,j), but LU(k,j) for k < j (column j of U)
// is only computed by the column loop that follows the search, so it still
// holds the cleared 0: the kernel pivots on |A(i,j)| of the row-swapped A, not
// on the residual its comment describes, and can pick an exact zero pivot for a
// nonsingular matrix. pivot: 'dsl' reproduces that bit for bit; 'residual'
// first computes U(0..j-1, j) (the same column-loop formula, which does not
// depend on the pivot), so the search sees the true residuals. Everything else
// is unchanged, so the two agree whenever their pivot choices agree.

import type { Arith } from './arith.ts';

export interface LuSolution<T> {
  LU: T[][];
  /** Pivot row chosen for each column (pivot[j] === j means no swap). */
  pivot: number[];
  Y: T[];
  X: T[];
}

export type PivotSearch = 'dsl' | 'residual';

/**
 * Solve A x = J in place (A and J are modified by row swaps, as in the DSL).
 * Arith.div may throw (the 'py' model raises on an exact zero divisor).
 */
export function luSolveDsl<T>(A: T[][], J: T[], ar: Arith<T>, pivotSearch: PivotSearch = 'dsl'): LuSolution<T> {
  const dim = J.length;
  const LU: T[][] = Array.from({ length: dim }, () => Array.from({ length: dim }, () => ar.zero));
  const Y: T[] = Array.from({ length: dim }, () => ar.zero);
  const X: T[] = Array.from({ length: dim }, () => ar.zero);
  const pivots: number[] = [];

  /** -( -A[i][j] + sum_k LU[i][k] * LU[k][j] ), k < m, accumulated by fma. */
  const residual = (i: number, j: number, m: number): T => {
    let f1 = ar.neg(A[i]![j]!);
    for (let k = 0; k < m; k++) f1 = ar.fma(LU[i]![k]!, LU[k]![j]!, f1);
    return f1;
  };

  for (let j = 0; j < dim; j++) {
    if (pivotSearch === 'residual') {
      for (let i = 0; i < j; i++) LU[i]![j] = ar.neg(residual(i, j, i));
    }
    // Pivot search over the would-be U(i, j) residuals, i >= j.
    let pivot = j;
    let best = ar.abs(ar.neg(residual(j, j, j)));
    for (let i = j + 1; i < dim; i++) {
      const cand = ar.abs(ar.neg(residual(i, j, j)));
      if (ar.gt(cand, best)) {
        best = cand;
        pivot = i;
      }
    }
    pivots.push(pivot);

    if (pivot !== j) {
      const rj = A[j]!;
      A[j] = A[pivot]!;
      A[pivot] = rj;
      for (let k = 0; k < j; k++) {
        const t = LU[j]![k]!;
        LU[j]![k] = LU[pivot]![k]!;
        LU[pivot]![k] = t;
      }
      const t = J[j]!;
      J[j] = J[pivot]!;
      J[pivot] = t;
    }

    // Column j of packed LU.
    for (let i = 0; i < dim; i++) {
      let f1 = residual(i, j, i > j ? j : i);
      if (i > j) f1 = ar.div(f1, LU[j]![j]!);
      LU[i]![j] = ar.neg(f1);
    }
  }

  // Forward substitution: L y = J.
  for (let i = 0; i < dim; i++) {
    let f1: T = J[i]!;
    for (let k = 0; k < i; k++) f1 = ar.fma(LU[i]![k]!, ar.neg(Y[k]!), f1);
    Y[i] = f1;
  }

  // Backward substitution: U x = y.
  for (let i = dim - 1; i >= 0; i--) {
    let f1: T = Y[i]!;
    for (let k = i + 1; k < dim; k++) f1 = ar.fma(LU[i]![k]!, ar.neg(X[k]!), f1);
    X[i] = ar.div(f1, LU[i]![i]!);
  }

  return { LU, pivot: pivots, Y, X };
}
