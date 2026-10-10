// Tests that compare the golden rules with simpyhls kernels or fixtures that
// the D-015/D-019/D-020/D-021 kernel branch changes. Until that branch lands
// (and `npm run fixtures:solver` is re-run against it), the live kernels and
// test/fixtures/solver_dc.json still describe the kernels as written, so these
// tests are declared as expected failures (`it.fails`).
//
// Once the kernel branch is merged: regenerate the fixtures, then set
// KERNEL_FIX_LANDED to true (or run with GOLDEN_KERNELS_FIXED=1 to try first).
// While the flag is false, an expected failure that starts passing is reported
// as a failure, which is the signal to flip it.
import { it } from 'vitest';

export const KERNEL_FIX_LANDED = false || process.env.GOLDEN_KERNELS_FIXED === '1';

/** `it` once the kernel fixes have landed; until then an expected failure. */
export const itAfterKernelFix: typeof it.fails = KERNEL_FIX_LANDED ? it : it.fails;
