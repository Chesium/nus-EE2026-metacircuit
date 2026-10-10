# M3 solver assumptions (GM-7, solver half)

The golden DC solver lives in `golden/src/backend/{value,arith,stamp,lu,solve}.ts`. It
consumes the shared `Netlist` (`types.ts`) produced by extraction (`netlist.ts`,
documented in [`M3_ASSUMPTIONS.md`](M3_ASSUMPTIONS.md)) and returns a
`VoltageSnapshot` (extended as `SolveResult`). Behaviour is derived from
`src/uart_link/README.md`, `protocol.py`, `frontend_tester.py`, `solver_tester.py`,
the simpyhls DSL kernels (reference algorithms), `notebooks/circuitsim.ipynb`,
`structure.md` and the final report. The RTL was not read (D-007).

Items marked **Settled (D-0xx)** follow a decision in `docs/verification-plan.md`.
The others await human validation; items marked **open** need a decision.

## Entry points

| Function | Purpose |
|----------|---------|
| `solveDc(netlist, opts)` | Golden spec solve. Defaults: wire unit table, R/I/V/C/L, float32 datapath with fused fma, DSL-order LU with the residual pivot search (M3-S012), structural singularity check, DSL source polarity. |
| `simulateUartSolver(netlist, opts)` | Bit-exact prediction of the D-012 simulated solver's reply, including its `ER` rejections. Default: `solve_core_dc` with the fixed pivot search (D-020); `{ pivot: 'dsl' }` predicts the kernel as written before the fix. |
| `solveReference64(netlist)` | Independent textbook float64 MNA with Gaussian elimination. Used only for sanity checks. |
| `runDslDc`, `stampDc`, `luSolveDsl`, `analyseStructure` | Building blocks. They are parameterised by arithmetic model (`py`, `f64`, `f32`, `f32-unfused`) and by pivot search (`dsl`, `residual`). |

Fixtures: `npm run fixtures:solver` (in `golden/`; `-- --check` verifies,
`-- --simpyhls <checkout>/simpyhls` picks a checkout) writes two files from the
same 339 netlists:

- `test/fixtures/solver_dc.json` from the simpyhls checkout's `solve_core_dc.dsl.py`
  (which frontend_tester also runs). Re-run it once the D-020 kernel fix lands.
- `test/fixtures/solver_dc_as_written.json` from the kernel as written before
  D-020, frozen in `test/fixtures/kernels-as-written/` (simpyhls 57ffb08);
  frontend_tester is pointed at the frozen kernel for it.

Each file records `kernels` and the kernel's sha256. Tests:
`test/solver.test.ts` and `test/solver-differential.test.ts`. The comparisons
of the defaults against `solver_dc.json` (simulated solver bit for bit, and
`runDslDc(..., 'residual')` in the `py`, `f32`, `f32-unfused` flavours) are
expected failures until the kernel fix lands and the fixture is regenerated
(`test/kernelStatus.ts`).

## Value and unit table

`value = bcd_digits * scale`, computed in float64. `bcd_digits` is the three packed
nibbles read as 0..999.

| Wire code (`NetlistElement.unit`) | Prefix | Scale | Frontend code (IF-016) |
|---|---|---|---|
| 00 | none | 1 | 0 |
| 01 | milli | 1e-3 | 3 (`m`) |
| 02 | micro | 1e-6 | 4 (`u`) |
| 03 | nano | 1e-9 | 5 (`n`) |
| 04 | kilo | 1e3 | 2 (`k`) |
| 05 | mega | 1e6 | 1 (`M`) |
| 06 | giga | 1e9 | (no frontend key) |
| FF / 07..FE | invalid (pico has no wire code, M3-A009) | status 03 | 6 (`p`) |

SI units by kind: R in ohm, I in A, V in V, C in F, L in H.

## Stamping conventions (`solve_core_dc.dsl.py`)

Unknowns 0..nodeCount-1 are node voltages, indexed by solver row. After them comes
one branch current per V or L, allocated densely in ascending `idx` order. The
system is `A x = J`, with A stored row-major. Ground (`FF`) terms are skipped.

- **R**: `g = 1/R`; `A[n0][n0] += g`, `A[n0][n1] -= g`, `A[n1][n0] -= g`, `A[n1][n1] += g`.
- **I**: current flows n0 -> n1 through the source: `J[n0] -= I`, `J[n1] += I`.
- **V**: row a: `A[a][n0] += 1`, `A[a][n1] -= 1`, `J[a] += V`, so `v(n0) - v(n1) = V`. Column a: `A[n0][a] -= 1`, `A[n1][a] += 1`.
- **C**: open circuit. No stamp and no unknown.
- **L**: short circuit, stamped exactly as a 0.0 V source with its own branch unknown.

The primitive order matches the kernel, which matters for float accumulation.

## Numeric policy

- **Bit-exact where the arithmetic model matches.** `simulateUartSolver` (model
  `py`) reproduces every reply bit of frontend_tester.py. `runDslDc` with `py`,
  `f32` or `f32-unfused` reproduces `solve_core_dc.dsl.py` executed by simpyhls
  `run_python` with the corresponding primitives. NaN payloads are not modelled:
  any NaN matches any NaN.
- **Backward error between models.** float32 results are not compared elementwise
  with float64. A source circulating through a V source can make node voltages
  tiny next to the branch currents. The test
  is instead the normwise backward error `||J - A x|| / (||A|| ||x|| + ||J||)`.
  float32 must reach at most 1e-5 (observed at most 7e-8). float64 must reach at
  most 1e-14 and agree with the textbook solver to 1e-9 on well-scaled circuits.
- For M3 (D-012), the display should be predicted from `simulateUartSolver`. That
  prediction is exact, so no tolerance is needed. `solveDc` is the spec reference.
  Its differences from the simulated solver are listed under the differential
  results.

## Differential results (339 netlists: 39 hand-written, 300 random, seed 20261010)

Against the kernel as written (`solver_dc_as_written.json`):

- simulated solver vs golden `simulateUartSolver({ pivot: 'dsl' })`: 339/339 replies
  identical. That is 227 `VB/VN/VE` bit for bit, 48 `ER 03/0001` and 64 `ER 04/0000`.
- `solve_core_dc.dsl.py` (`run_python`) vs golden `runDslDc(..., 'dsl')`: 293 R/I/V
  netlists, bit-identical in all three flavours (`py`, `f32` fused, `f32-unfused`).
  This includes 64 runs that raise ZeroDivisionError.

Against the fixed kernel (D-020): pending. With the as-written kernel still in
the checkout, the default `simulateUartSolver()` differs from the recorded replies
in 47 cases and `runDslDc(..., 'residual')` from the recorded results in 87
(`py`), 92 (`f32`) and 95 (`f32-unfused`) cases, all where the two pivot searches
choose different rows. Agreement is expected once the fixed kernel's fixture is
generated, provided the fix computes U(0..j-1, j) with the column loop's formula
and primitive order (M3-S012).

Independent of the fixtures:

- `solve_core_transient.dsl.py` at `dt = inf` vs golden C/L stamps: 41 netlists
  identical (up to the sign of zero). The transient kernel has the same pivot
  search; the test accepts either search, since D-020 names only `solve_core_dc`.
- solver_tester.py's two built-in cases (5 V into 3k/2k gives 5 V and 2 V; 2 mA into
  1k gives 2 V) pass in both `simulateUartSolver` and `solveDc`.
- Golden spec vs the as-written simulated solver: 94 of the 339 outcomes differ.
  Moving from it to the spec one factor at a time, the outcome changes in: 37
  cases from the fixed pivot search (D-020, the `simulateUartSolver` default);
  43 from accepting C/L, idx gaps and more than 0x20 nodes (M3-S008, M3-S016);
  3 from the structural check (M3-S013); 22 from float32 arithmetic (M3-S011,
  M3-S015). Unit tables agree now that `unit` is the wire code.
- Of 259 structurally sound R/I/V netlists that the as-written simulated solver accepts, it
  answers 34 with `ER 04` and 2 with wrong voltages. All of these come from the
  pivot-search defect (M3-S012). A reference is not automatically right (D-007),
  and here the reference kernel itself is wrong.

## Boot circuit

Since D-015 the boot source is turned 180 degrees (anchor (4,2), rotation 2, "+"
half facing the right rail). Extraction gives `V(n0=0, n1=FF, 010)` and two
`R(FF, 0, 100)`. Node 0 solves to **+10 V** (float32 `41200000`); the branch
current is 0.2 A. The simulated solver (both pivot searches), the spec solve and
every arithmetic model agree. The old table gave `V(n0=FF, n1=0)` and -10 V.

## Assumptions

### M3-S001 The D-012 simulated solver is `frontend_tester.py`

`solver_tester.py` is a client for the hardware board S: it sends two built-in
cases and checks the replies within 1e-3. The laptop-side simulated board S that
runs `solve_core_dc.dsl.py` is `frontend_tester.SimpyhlsDcSolver`. The golden models
the latter and uses the former's two cases as fixtures.

### M3-S002 `unit` is the wire code

This follows the netlist agent's M3-A008. Extraction translates IF-016 into the
uart_link "solver-board mapping", which is also what frontend_tester uses. The
frontend table is kept (`units: 'frontend'`) only to decode ComponentStore values
directly. structure.md's 3-bit magnitude table (`000` nano .. `101` mega) is stale.

### M3-S003 BCD is the full three-digit integer, whatever the kind

Non-resistors show only two digits in the property panel, but a nonzero top
nibble still counts. Under M2-A002, digits fill the field from the left, so typing
`5` for a resistor stores `500` and the solver sees 500 ohm while the text shows
`5`. **Open (UX):** confirm that this is intended.

### M3-S004 Value conversion

`value = digits * 1eN` in float64, as frontend_tester computes it. The float32
datapath uses `Math.fround(value)`. How board S converts BCD to float in hardware
is not specified.

### M3-S005 Source polarity (**Settled, D-015**: option 2)

D-015 chose option 2 below: the solver convention stays, extraction puts n0 on
the "+" of a voltage source (unchanged) and on the arrow's tail of a current
source (beyond the partner half, a swap; M3-A017), and the boot source is turned
180 degrees so node 0 reads +10 V. `SolveOptions.sources` still defaults to
`DSL_SOURCE_CONVENTION`. The analysis that led to it:

Several sources bear on which terminal of a source is which:

- **DSL kernels** (`solve_core_dc`, `solve_core_transient`) and `circuitsim.ipynb`:
  `v(n0) - v(n1) = V`, so n0 is "+". I flows n0 -> n1 through the source, i.e.
  out of the source into n1 (the notebook says "from port i (-) to port j (+)").
- **solver_tester.py**: `V(n0=0, n1=FF, 5)` gives +5 V and `I(n0=FF, n1=0, 2 mA)`
  into 1k gives +2 V. This is the same convention.
- **Final report and structure.md**: say nothing about polarity.
- **Extraction** (M3-A007): n0 is the terminal beyond the anchor half.
- **Sprites** (shared assets, `golden/assets/canvas.json`, rotation 0): VL/VR draw a
  "+" in the anchor half and a "|" in the partner half; the "|" plausibly reads as
  a rotated "-". So the "+" terminal is n0, which matches the DSL. IL/IR draw an
  arrow pointing toward the anchor half. That means current leaves the source at
  the n0 side, the opposite of the DSL's I convention.
- **Boot circuit**: the source's "+" half faces the grounded left rail, so the
  drawing itself implies -10 V. The RTL (FS-7 smoke test), the extraction and the
  golden all produce -10 V. If the boot circuit was meant to show +10 V, the boot
  table places the source the wrong way round.

Options for Q-009:

1. Keep everything as it is (the DSL convention, with n0 on the anchor side for
   both V and I). The boot circuit shows -10 V and the I arrow contradicts the
   solve.
2. **(Recommended)** Keep the solver and protocol convention, which is consistent
   across the DSL, the notebook, solver_tester, the simulated solver and the board
   S kernels. Let extraction put n0 on the sprite's marked terminal: the "+" for V
   (unchanged) and the arrow's tail for I (n0 = partner side, a swap). If the boot
   circuit should read +10 V, rotate its source by 180 degrees in the boot table
   (IF-026 and RTL) rather than changing semantics.
3. Flip the solver convention instead (n1 positive, current into n0). This breaks
   solver_tester's cases and the DSL/board S kernels; not recommended.

The golden isolates the choice in one switch,
`SolveOptions.sources = { voltagePositive, currentInto }` (default
`DSL_SOURCE_CONVENTION`). Option 2 is an extraction change (n0/n1 of I).

### M3-S006 Blank and invalid values

- Blank (BCD 000, unit 00) is the value 0. A 0 ohm resistor gives status 04
  (`zero-resistance`, from any terminal pair). The simulated solver also replies
  `ER 04/0000`, from Python's ZeroDivisionError in `1/R`.
- V = 0 and I = 0 are valid.
- C and L values are irrelevant in DC but are still validated.
- A BCD nibble above 9, or a unit code outside 00..06, gives status 03 with ER
  arg 0001 (frontend_tester: `ERROR_BAD_FIELD`, arg 0001).

### M3-S007 Element order and aux rows

Elements are stamped in ascending `idx` order (frontend_tester sorts by idx).
Branch unknowns for V and L are numbered in that order, after the node rows.

### M3-S008 C open, L short; the simulated solver rejects C/L (**Settled, D-018**)

The C/L DC model is the `dt -> inf` limit of `solve_core_transient`'s companion
models, and was checked against that kernel. frontend_tester accepts only kinds
1..3 and replies `ER 03/0001` to any netlist containing C or L. Extraction sends C
and L only when asked to (M3-A010): by default (D-018) the frontend itself rejects
a snapshot containing C or L with `@ER` code 81, as the RTL does, so the solver
never sees one. The C/L DC model stays in `solveDc` as a non-default option, for
`supportedKinds: ALL_ELEMENT_KINDS` netlists.

### M3-S009 `stamping_core.dsl.py` conflicts with the protocol

`stamping_core.dsl.py` uses kind 4 = VCVS and 5 = NPN; the protocol uses
4 = C and 5 = L. It also expects host-precomputed conductances (`val0 = g` for R)
and preassigned aux rows (`val2` as the coupling coefficient). Its README and
`solve_preprocess.py` use the ground sentinel 65535, while the kernels use 255. The
golden follows `solve_core_dc.dsl.py`, which is what frontend_tester runs.
`solve_core.dsl.py` is identical to it apart from its name and comments. The
inline LU and substitution in `solve_core_dc.dsl.py` is `lu_core`,
`forward_sub_core` and `backward_sub_core` plus pivoting.

### M3-S010 The simulated solver computes in float64

simpyhls simulation gives no meaning to `f32_*` names. frontend_tester therefore
solves in Python floats, with Python ints for the literals `f32_0 = 0` and
`f32_5 = 1`. That changes the sign of some zeros, since `-(0)` is `+0`. Results are
rounded to float32 only by `struct.pack`. A float32 pack overflow raises and gives
`ER 04`. The kernel comments and structure.md specify single precision, so board S
hardware results will differ in low bits from the simulated solver.

### M3-S011 Arithmetic models; fused vs unfused fma (**open**)

`f32` (the default) assumes the `fma` primitive rounds once (fused). `f32-unfused`
rounds the product and the sum separately. Both match the Python float32 runs bit
for bit. Which one board S's floating-point FMA implements is not specified in the
spec documents. Division by zero follows IEEE in the float32 and float64 models and
raises in the `py` model.

### M3-S012 Pivot-search defect in `solve_core_dc.dsl.py` (**Settled, D-020**)

The search for column j forms `A(i,j) - sum_k LU(i,k) * LU(k,j)`. But `LU(k,j)`
for k < j is only written by the column loop that follows the search, so it is
still the cleared 0. The kernel therefore pivots on raw `|A(i,j)|` of the
row-swapped A, not on the residual its comment describes, and can divide by an
exact zero pivot for a nonsingular matrix. Example: `solver.test.ts`, a 5-node
circuit with two V sources.

Impact: 34 ER 04 replies and 2 wrong replies among 259 sound netlists (above).
Board S, if generated from this kernel, would produce inf/NaN in those cases.

Fix: compute `U(0..j-1, j)` before the search, using the same formula as the
column loop. Pivot choices and bits are unchanged whenever the old search already
picked the right row. D-020 adopts this fix for the kernel, the generated RTL and
the simulated solver. The golden spec and, by default, `simulateUartSolver` use
the fixed search (`pivot: 'residual'`); `pivot: 'dsl'` reproduces the kernel as
written and is checked against the frozen copy.

### M3-S013 Status codes

| Status | Meaning |
|---|---|
| 00 | Success. |
| 03 | Netlist rejected (bad node index, kind, BCD or unit). |
| 04 | Ill-posed or failed: zero resistance, a floating node (no R/V/L path to ground, including "no ground"), a loop of V/L elements (including n0 == n1), or a non-finite or float32-overflowing result. |

On nonzero status, `voltages` is empty and the simulated solver sends
`ER,<frame>,<status>,<errorArg>` instead of VB/VN/VE. For the golden spec, the
structural check runs before solving and is exact for positive resistances.
The simulated solver has no such check: singular circuits give `ER 04` when a
pivot is exactly zero, and otherwise garbage numbers (2 floating circuits in the
fixtures).

### M3-S014 Self-loop elements are stamped (**open**)

R and I with n0 == n1 contribute nothing in exact arithmetic but are stamped as in
the kernel. In float32 they can absorb other entries. For example, a 617 MA
self-loop source wipes out a 993 uA source, giving 0 V instead of 571 V. A resistor
shorted by a wire causes relative errors of roughly eps*g/g_other. Recommendation:
extraction or the solver drops R/I/C elements with n0 == n1 (extraction already
reports them as `shorted-element`). V/L self-loops remain status 04.

### M3-S015 float32 range

Conductance spreads beyond about 1e9 (wire units nano..giga mixed) can produce an
exact zero pivot or NaN in float32, which gives status 04 `non-finite`. This
happened in 8/300 random circuits (spreads 3e9..1e19), and in float64 in 2/300.
No well-scaled circuit failed.

### M3-S016 Capacity and index rules

frontend_tester rejects `node_count > 0x20` and idx sets that are not exactly
0..n-1. The golden spec allows up to 0xFE rows and any idx set (sorted).
structure.md's 8x8 matrix and the DSL's 8-bit `u8_next_aux`, which wraps when
node_count + #V/L > 255, are not modelled.

### M3-S017 Floating terminals get their own rows (**Settled, D-019**)

Extraction gives a terminal that touches no conductor its own row (M3-A007), so
an open resistor end carries no current and a dangling component's free node has
no path to ground: the spec solve reports status 04 `floating-node`, and the
simulated solver a zero pivot (`ER 04`) or, with roundoff, numbers. Before D-019
such terminals were sent as `FF` and the floating-node check could not see them.

### M3-S018 Tooling

Python 3.14 (simpyhls's `requires-python`) is not installed here. The generator and
kernels run unchanged on the system Python 3.12, using only the stdlib (no uv
download). The generator finds simpyhls via `--simpyhls`, `$SIMPYHLS_DIR`, the
submodule or the nearest ancestor checkout with a populated one (git worktrees),
and points frontend_tester at it (or at the frozen kernel).
