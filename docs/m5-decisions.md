# M5 baseline decisions

## A-008: component readiness advertised before RAM retirement

A real full-top command-port fixture places the last origin at address287 with
rotation2, so its partner index is address286. On the original accepted M4
source, the first pre-NBA edge with `!component_store_busy` observes map286=511
(invalid), expected0, while map write enable is1/address286. Both native5.046 and
Docker5.020 reproduce this at exactly58,792,165ns in supplemental runs. A reduced
cold witness reproduces without UART traffic. This is a latent ready-boundary
bug discovered beyond the settled M4 scope, not a new placement rule.

The fix includes registered map/store write strobes in busy and adds one clock
of drain after them. SimpleRam writes/read output update by NBA and reads old
data on a write edge; the drain also lets the selected-index read refresh before
consumers accept readiness. Full canvas/map contents and interaction rules remain.
Original topSHA254c8842d72c6c4801ef015c8c3274687a970c8794f9d09e6d966ced42657a66;
correctedSHA4e62e63dd68ba9e946006a86129d48c39dd7570710a73451f0fd1fba68c2bb16.
Frozen oracle/assets/constraints remain unchanged. First-ready memory and selected
read regressions pass onbothruntimes; the complete M2 corpus passes onbothruntimes; exact-frame/UART M3 regressions
are in progress. See frontend resume handoff for cold witnesses and specific
observer corruption controls. Later optimization measurements must compare
against this corrected baseline separately from the defect fix.

## Solver numerical robustness: recorded gap

Actual configured vendor-FP SolverBoard passes the declared well-conditioned
analytic/general fixture scope. A separate near-singular probe misses the newly
stated physical rational-MNA accuracy policy: expected999001/1998001 (about0.50000025),
observed0.5185897, status00 with no FP exception (about3.72% relative error).
The empirical general-circuit tolerance is not widened to accept this result.
This physical accuracy check is new scoped evidence; it does not change frozen
frontend semantics or claim a universal numerical error bound. Broad ill-conditioned
solver readiness remains open. Retained failure: golden/out/m5-solver-xsim/near-singular-20261011/.

## Solver augmented dimension: recorded capacity gap

An actual-IP probe with32electrical nodes,31resistors and1voltage source uses
33MNA unknowns, beyond the matrix dimension32. The parser independently accepts
up to32nodes and32elements; existing STATUS_CAPACITY03 is declared but unused.
The probe expects that inferred capacity rejection but receives
`@VB,FF40,20,05*3B` after a real solve with FP exception1 instead. Retained report:
`golden/out/m5-solver-capacity-xsim/augmented33-20261011/report.json` (exit1).
The passing inclusive capacity fixtures constrain node_count+voltage_sources<=32;
this failure is outside their declared scope. No solver RTL or frozen contract
was changed to fit the new test. Capacity/error handling readiness remains open.

## Flood queue reset-free lifetime: retained module limitation

Native5.046 and Docker5.020 witnesses enqueue/pop one item at a time without
clear. At DEPTH1152, item1152 returns zero instead of `0a693`: the 11-bit head/
tail increment past the array limit and wrap only at2048. DEPTH1 and3 fail at
their first invalid index; DEPTH4 passes. Every corruption control detects the
first item. Reports: `golden/out/m5-flood-queue/{native,docker}-lifetime-20261011b/`.
Production source remains unchanged.

This is a generic FIFO limitation, not demonstrated frontend corruption. The
wrapper clears per flood, while the serial core sets a cell visited before up to
four port enqueues. That suggests at most4*288=1152 lifetime additions per stable
run. The complete bound, reset/epoch assumptions and integrated reachability of
the failing lifetime remain verification obligations; no counter is waived.

## Isolated augmented-capacity rejection candidate

`golden/out/m5-capacity-candidate-source/proposal.json` declares a separate safety
candidate using existing STATUS_CAPACITY03: count kind03 voltage-source unknowns
and reject node_count+source_count>32 at NE, before solver_start, with the requested
dimension as the error argument. Production and frozen frontend behavior remain
unchanged. The real-IP dimension33 probe observes exact `@ER,FF40,03,0021*3F`,
no solve start and its specific cold corruption control; supported-corpus
qualification is still running. This inferred policy is explicitly supplemental,
not a silent change to the frozen solver contract.

## Integrated augmented-capacity safety correction (2026-10-10 client date)

Root integrated the exact independently qualified candidate into production
`src/design/solver_board/SolverBoard_top.sv`: SHA77a637aaf93df02f6adc1dbd50375eeb0fc5d1f08063811300d294597e5ee78b.
The parser permits32electrical nodes; each accepted ideal voltage source adds
an auxiliary MNA unknown. At NE, requested dimension above32 now emits existing
STATUS_CAPACITY03 with the dimension argument before solver_start. Source count
clears on board reset and each accepted NB. Supported dispatch is unchanged.
This is a separately recorded safety correction using the inferred existing
status, not an optimization or a change to the immutable frontend oracle.

Fresh direct-production probe
`golden/out/m5-solver-capacity-xsim/production-guard-20261010c/report.json`
passes exactER03/0021/no solve plus cold observation corruption; no overrides
or source drift. Supported59case corpus, inclusive boundary recovery and current
defaultbaud frontend qualification are pending. Historical candidate/provenance
reports remain preserved and do not substitute for those current-source runs.

## Integrated FIFO wrap and panel latch corrections (2026-10-11 client date)

Production FloodQueueStore now wraps accepted head/tail increments at DEPTH-1,
with all count, acknowledgment, rejection and RAM old-read behavior unchanged.
The retained original lifetime defect at non-power-of-two depth1/3/1152 remains
archived. Both pinned runtimes pass the unchanged lifetime witness and independent
ordered-queue overlap ledger at depths1/3/4/1152, including full/empty simultaneous
requests, back-to-back handshakes and70real reset/clear boundaries per depth.
Actual-source Yosys0.33 proves reset base from arbitrary prior state and one-step
range/count preservation from arbitrary valid states at all four depths; the
original fails the induction for1/3/1152 and passes4. No cold pre-reset or arbitrary
formal data-order claim. Evidence golden/out/m5-fifo-wrap-20261011d/. Maintained
verification tools/verify_flood_queue_safety_m5.py and verify_flood_queue_range_m5.py
retain specific controls and source identity. Integrated source SHA
6e80cfbf5b6b456462822014b15808814b2c6b0208ad7ef0bbd4da4c664adfb8.

Production ComponentPropertyPanel now initializes combinational coord_len to0.
This is the sole insertion from the isolated45ca244...candidate, supported by
actual-source renderer-cone SAT/control and full M2 (298frames/61checkpoints on
each runtime) plus related-clock scoped routed qualification. Its output registers
retain timing; zero-character hint data produces identical text observations for
any prior length. Source SHA45ca2444a42286dce2cb0c71b1364762a8ec60b825277f94f086cc2337c73786.
Production top and XDC remain unchanged at this integration checkpoint. These
are separately qualified corrections; current production full frontend/QoR tests
remain required and full M5 readiness stays false.

## Adopted shadow write normalization (2026-10-11 client date)

Production GlobalRender_top now exactly matches the independently reviewed
93bc76d3019d3d1e5a8949a00e32d217d934b4ece5289ec26e1421b7a2a001fb source.
The canonical transformation preserves exclusive branch decisions, widths and
expressions, old-memory reads and same-edge NBA writes, while selecting one
physical write port per shadow array. Fresh actual-source structural induction
audit passes against the A-008 corrected4e62e63...source; temporal/control tests
and earlier completeM2/M3 qualify the isolated source. Five coldnativev2seeds
x64operations now complete (seed1historical713frames/65checks plus remaining
3071frames/260checks); no interrupted run is promoted. New isolated panel+shadow
+currentguard nativeM3 also passes482frames/42checks with exact initialization
and source/harness/simpyhls pins; it predates the queue correction. Current
queue/panel/guard/shadow composedM2 and related-clock QoR remain running, and
current actual-IP/frontend/gates still require fresh qualification. No epoch
bitmap, strengthened XDC or rejected arithmetic proposal was adopted. Full
readiness remains false, including global timing/IO/CDC and current coverage.

## A-009: malformed voltage records counted as a complete reply

On the current shadow/FIFO/panel/capacity composition, real cold115200RsRx
witnesses send a current-id VB declaring two nodes, two valid-checksum VN
records for node0, and matching VE. RTL counts two records and commits the
partially populated inactive bank. The same failure occurs when the second
record is node2, outside the declared two-node range but below the physical32
limit. Both native5.046 and Docker5.020 reproduce these specific failures.
The immutable golden parseUartStream rejects both byte streams; its algorithm
and the valid packet contract remain unchanged. Missing-node VE already fails
closed on the baseline and remains a regression.

The isolated correction tracks32distinct nodes, accepts a staged write only
once and below the declared count, and cancels malformed staging with existing
reply-parse status83 while preserving the previous primary bank/values. Normal
packets, reversed legal order, empty replies, stale IDs and valid recovery retain
their existing behavior. Actual UART/independent-decoder checks and a parser
control/range plus receiver-mask/commit proof pass in their declared scopes.
RAM payload and arbitrary UI/reply overlap are not promoted to formal theorems.
Artifacts: golden/out/m5-reply-integrity-20261011e and m5-reply-banks-20261011e.
The combined correction is integrated after fullM2/M3 plusfivecoldsmoke checks and bothfresh14check fastgates; actualvendorFPfrontend also passes. FullM5 readiness remains incomplete.

## A-010: 32-node display count truncated to five bits

The physical receiver accepts all32nodes, but next-node navigation compares
against node_count[4:0], which turns32into0; commit selection reset has the same
truncation. Cold UART plus physical BTNR fixtures reproduce inability to move
from node0 on both runtimes. The corrected comparisons extend the five-bit view
index to eight bits and use the full node count. All31next selections, node31
nonwrap and selection retention on another32node commit pass, using the actual
synchronous RAM view read path. Eleven fixtures/101UART lines also retain the
malformed-packet cases, recovery, reversed order and empty replies. No parser
event, snapshot-id, memory or view-state injection is used. Actual snapshot ID
comes from the cold frontend; only the unchanged mouse device stub is present.
This is a display boundary correction, not a new numerical solver rule.

The combined correction passes its predeclared scoped route objective:
10149LUT/4197FF/10BRAM/0DSP, setup-1.953ns/hold+0.027ns, internalunknowns0/0.
Compared with10092/4157/9.5/-1.333, increases+57LUT/+40FF/+0.5BRAM and setup
degradation0.620ns are retained honestly within unchanged12000/4500/10/0 and
-2.0/0 caps/floors. This is correctness qualification, not a positive-area or
full100MHz/IO/CDC acceptance claim. The combined correction is integrated under this scoped correctness qualification; fullM5 readiness remains incomplete.

## M5 timing scope (2026-10-11 client date)

Plan decision D-030. M5 characterizes timing and forbids regressions; it does
not require timing closure. The acceptance gate no longer requires
`timing_clean` (which the QoR runner never set, so full mode could not pass).

- Comparison constraints: `tools/qor/basys3_m5_timing.xdc`
  (`d96ce92d…`), the production XDC plus the generated 25 MHz pixel clock,
  related to the 100 MHz master with no exceptions. Create a measurement root
  with `tools/qor_root_m5.py`. The production XDC is unchanged.
- Recorded baseline: current production, report
  `golden/out/qor/reply-integrity-view32-candidate-routed-20261011e`:
  10149 LUT / 4197 FF / 10 BRAM / 0 DSP, setup WNS -1.953 ns (TNS -582.452,
  791 failing endpoints), hold +0.027 ns, check_timing no_clock 0 /
  unconstrained internal 0 / no_input_delay 10 / no_output_delay 44, CDC all
  paths safely timed, DRC warnings CFGBVS-1, CHECK-3, REQP-1839, REQP-1840.
- Candidate rule: hold WNS >= 0 with no failing hold endpoints; setup WNS no
  worse than baseline (0 ns tolerance); no increase in any check_timing count,
  no new DRC rule and no new or increased CDC finding. Objective resource
  limits and gain still apply.
- Known timing debt (TIM-1): negative setup slack, the 10 input / 44 output
  ports without I/O delays, and production XDC qualification.

Candidates previously rejected only against self-declared setup floors
(selected-address, valid-only epoch, row-valid, unit-tree) are not re-labelled;
they can be re-measured and judged under this rule. Accepting a candidate moves
the recorded baseline, which requires a policy update.

## M5 harness scope (2026-10-11 client date)

Plan decision D-031. M5 delivers the verification/observability harness for
later autonomous timing/resource optimization experiments. Readiness comes only
from checks that run; the acceptance gate no longer appends unconditional
readiness failures.

- Coverage: the acceptance gate requires all 64 functional bins. The coverage
  policy (schema 2) still validates provenance, both runtimes, raw artifacts and
  required module instrumentation, but structural gaps are reported rather than
  failed. A module instance whose source hash differs from the recorded
  baseline (`tools/m5_coverage_baseline.json`) may not reach a smaller fraction
  of its eligible line, branch or toggle points. The previous zero-gap rule with
  manual per-module review is withdrawn. Structural coverage is measured on the
  native runtime only: with coverage enabled, Verilator 5.020 in the pinned
  container ran at about 17 s/frame (native about 2 s/frame), so the 3784-frame
  seeded corpus would take about 18 hours per Docker run. Docker runs the same
  corpus uninstrumented for cross-runtime agreement, and `--peer-coverage` is
  removed.
- M5-4: the gate's continuous invariant observers and the six scoped proofs are
  the M5 scope. Global atomicity/progress theorems and general formal proofs are
  out of scope.
- M5-5: SolverBoard synthesis and the original-XCI upgrade move to QOR-2. The
  near-singular accuracy gap is BUG-2; `verify_solver_xsim_m5.py
  --accuracy-baseline` logs out-of-tolerance results with `+ACCURACY_PROBE`
  instead of stopping, requires that only the declared near-singular case
  misses, and fails if its relative error exceeds the recorded baseline.
- Design defects (epoch alias BUG-1, BUG-2, coverage corpus limits BUG-3) are
  tracked as BUG items and fixed through the rebaseline path in the plan.
- An optimization objective may declare `setup_wns_tolerance_ns` (finite,
  nonnegative) before measurement; without it the policy default is 0 ns.

## Coverage counted over the whole cold run (2026-10-12 client date)

The first parallel full gate on the keypad candidate failed the coverage rule:
`GlobalRender_top` line coverage fell from 108/726 to 108/729. The three new
points were the initializers of the three new `reg … = 1'b0` declarations.
Initializers execute at time zero, during boot, so a scenario-only count (after
frame 3) can never reach them; the baseline already showed the same artifact for
the existing synchronizer registers. The audit and baseline now use scope `run`:
a point is reached if either the boot or the scenario split hit it. The baseline
was regenerated from the same native corpus without new simulation
(`GlobalRender_top` lines 419/726; totals branch 1026/2114, line 2913/10047,
toggle 24984/45704), records its scope, and a baseline from another scope is
rejected. Re-auditing the candidate's existing reports gives 422/729 lines, no
coverage loss.

The same run timed out the solver-capacity XSim at its internal 180 s limit
while other checks overlapped it; the gate now passes `--timeout 1200` to the
XSim-based tools.
