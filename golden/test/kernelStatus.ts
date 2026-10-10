// Tests that compare the golden rules with simpyhls kernels or fixtures that
// the D-015/D-019/D-020/D-021 kernel branch changed. With KERNEL_FIX_LANDED
// false they are declared as expected failures (`it.fails`), for checkouts
// whose simpyhls submodule still holds the kernels as written (57ffb08) or
// whose test/fixtures/solver_dc.json was generated from them.
//
// The kernel branch has landed (simpyhls 78efdf8, verification 06ce3cf) and the
// fixture was regenerated with `npm run fixtures:solver`, so the flag is true and
// these are plain tests. On an old checkout, set it to false (an expected
// failure that starts passing is then reported, the signal to flip it back).
import { it } from 'vitest';

export const KERNEL_FIX_LANDED = process.env.GOLDEN_KERNELS_FIXED !== '0';

/** `it` once the kernel fixes have landed; until then an expected failure. */
export const itAfterKernelFix: typeof it.fails = KERNEL_FIX_LANDED ? it : it.fails;
