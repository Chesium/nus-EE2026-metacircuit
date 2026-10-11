# M5-5 generated extraction and solver qualification

`python3 tools/verify_solver_m5.py --out golden/out/m5-solver/qualification`
executes actual generated `extract_component_nodes.sv`, actual generated
`solve_core_dc.sv` through `SolverDcPipeline`/`SolverBoard_top`, and an actual
wired `GlobalRender_top` ↔ `SolverBoard_top` UART loop. The command currently
returns **1**, even if every regression succeeds: configured floating-point IP
has not been characterized, so solver readiness is **false**.

The report records the seed, exact generated fixtures/includes, command lines,
tool version, logs, source/configuration/ROM/artifact SHA256 identities, runtime
results and negative controls. Sources changing during the run invalidate its
evidence. Generated fixture artifacts are sufficient to reproduce the sampled
inputs and analytical expectations; an assertion records the first failing case.
`--fixtures-only` writes fixtures and blocked readiness without building RTL.
No frozen oracle, RTL, IP configuration or accepted reference is modified.

## Evidence and declared scope

The extraction corpus has at least 320 cases: every combination of five
component kinds (R/V/I/L/C), four rotations and four terminal modes at both
ends (facing wire, facing ground, open, nonfacing wire). Seeded placement changes
boundary endpoints and sparse region IDs. Expected rows derive independently
from row-major connected terminal positions, grounded regions, current-source
polarity and floating-row ordering. Every case runs actual generated extraction
with responses delayed deterministically 0..7 cycles; checks enforce in-range
requests, no duplicate primitive requests and exactly one write per terminal.
Each start/done primitive captures arguments on `start`, matching the real
fetchers. Arguments are allowed to change afterward. This bench qualifies the
extraction kernel with controlled primitive latency; it does not qualify the
flooding algorithm or board memory/CDC timing.

The UART corpus contains 36 seeded netlists by default. Actual solver-board
UART RX, parser, BCD/unit ROM conversion, stores, stamping, pivoted solve and
UART TX execute. Independent analytical expectations cover ideal voltage
sources with parallel loads, equal resistor dividers and both current-source
polarities. Integer powers of two avoid tolerance-based comparisons: every
returned binary32 word and UART checksum must match exactly. Current corpus
sizes are one/two electrical nodes and two/three elements; singular, extreme,
full-capacity and arbitrary general-netlist systems remain unqualified.

The physically connected full frontend/solver bench has no Python solver host.
It checks boot node0=10V, stable repeated responses, then deletes the right-rail
wire through frontend mouse outputs. The resulting real solver reply must
advance the content ID to2 and commit node0=10V/node1=0V. VGA frame events are
recorded. MouseCtl/MouseDisplay are explicit simulation stubs; PS/2 and CDC
qualification remain outside this scope. These loop checks qualify transport
and frontend handling only provisionally while FP remains unvalidated.

Each bench reruns cold with an injected sampled-output corruption. The normal
comparison must detect it by a nonzero assertion exit; a timeout or unrelated
failure does not satisfy the control. Watchdogs are harness deadlock limits,
not claimed contract progress bounds or formal proofs. Failure reduction beyond
the isolated extraction fixture/first UART transaction is still future work.

## Floating-point blocker

The existing Verilator stand-ins (`FloatingPointIpModels.sv`) explicitly omit
real IP bit-level behavior and exception flags. They use FMA latency4 and divide
latency6. Original configured `src/ip` XCI declares FMA latency16 and divide
latency28, binary32, nonblocking flow, no reset and no output backpressure.
The runner audits those original XCIs; `src/ip_new` is a separate configuration
and cannot silently replace them. Changing a JSON `validated` field cannot
promote these stand-ins to acceptance.

The Vivado resume role independently confirmed original floating-point7.1
2018.2rev6 is locked against the installed Vivado2025.2rev21 catalog. Fresh original-XCI
simulation output products cannot be generated in this state. A later ignored-file
audit found existing `src/ip/floating_point_{fma,div}` simulation VHDL, encrypted
libraries, C models, DCPs and functional netlists. Their headers identify
Vivado2025.2/core revision21 (2026-03-13), unlike the original tracked XCI
revision6. Generic maps show the configured16/28 latencies and operation/exception
parameters. These are candidates for a separately pinned parameter/provenance
audit and real XSim measurement; their existence alone does not qualify them.
The existing project XSim LU cache references `src/ip_new`, so its saved results
are not trusted as original-config evidence.
There is no automatic IP upgrade in this work. Required follow-up is separately
reviewed IP qualification or availability of compatible original products/tools,
then actual primitive tests for latency, valid bubbles/reset behavior, fused
rounding, normals, subnormals/flush behavior, signed zero, NaNs/infinities,
overflow/underflow/invalid/divide-by-zero, and `tuser` exception-bit mapping.
Only after actual configuration-pinned comparison passes may a stand-in or
actual-IP backend be promoted into solver acceptance. Additional randomized
multi-component extraction, general solver systems, boundary/capacity/error
cases and failure reduction are needed before the broad M5-5 requirement is done.

## Current run

Native final run passed all320 extraction cases (191,003 delayed-response
stall cycles),36solver netlists/120reply lines and the actual frontend loop
(boot accepted atVGAframe2, edited split rail accepted atframe11). All three
cold corruption controls detected the deliberately changed observation.
Eight runner policy/fixture tests pass. Final qualification artifacts and exact results are recorded in
`golden/out/m5-solver/qualification-final-20261010/report.json` and the separate
[solver handoff](handoffs/m5/agents/solver-qualification.md). That report remains
blocked even when its three behavioral benches pass. Native Verilator5.046 is
the current toolchain; no Docker or actual-Xilinx primitive acceptance is claimed.

Runner policy/fixture tests:
`python3 -m unittest discover -s tools/tests -p test_verify_solver_m5.py`.

## Actual-IP UART pipeline follow-up

`python3 tools/verify_solver_xsim_m5.py --out golden/out/m5-solver-xsim/qualification`
uses the actual generated DC solver, actual SolverBoard UART/parser/stores/ROM,
and existing configuration-equivalent AMD revision21 products with the
[FP characterization](m5-fp.md) report mandatory. This command's success is a
scoped actual-pipeline result, while `acceptance.full_m5_ready` remainsfalse.
The original revision6 XCI synthesis and full-capacity/general circuits remain
unqualified. Its explicit source manifest contains no floating-point stand-ins.

Actual mixed-language elaboration exposed a production wrapper mismatch:
`fpo_fma.v` declared4result exception bits while the configured actual FMA VHDL
port has3. Verilator stand-ins exposed4bits and masked it. Root authorized the
minimal width correction. Candidate verification used an isolated exact copy
with only `wire [3:0]` → `wire [2:0]` changed; the report records original/effective
paths and SHA256 identities and verifies the minimal change. The three used
exception bits0..2 retain their mappings. Root owns applying the same production
change and comparing its final hash against the tested candidate.

Run:
`python3 tools/verify_solver_xsim_m5.py --out golden/out/m5-solver-xsim/qualification-candidate-20261010 --fma-wrapper golden/out/m5-solver-xsim/qualification-candidate-20261010/fpo_fma.v --timeout 180`.
Result: scopedpass/exit0,36seeded analytical circuits plus recovery and singular
cases (38solves/127reply lines). Primary solve primitives completed244FMA and
173divide operations; every observed primitive result had configured16/28
latency. UART baud is accelerated to10MHz at the unchanged100MHz board clock;
accepted analytical circuits use unit00. Default115200 transport with actual IP,
other units, full capacity and general-netlist systems remain unqualified here. A bad header checksum produced`ER01/0003`; a subsequent correct circuit
recovered. A singular current-only circuit propagated real IP exception status05
and returned negativeinfinity, unlike zero-exception stand-ins. A cold reply
corruption was detected. Initial missing-SimpleRam and production-width failing
elaboration artifacts are retained separately.

The candidate wrapper hash is
`9c1daa50bb18196ff22615da92bcf8a3b0697647e821db45376d735948f05ec7`.
At candidate-run completion production was not yet identical; its original hash
is retained in the historical report. Root subsequently applied the exact
width correction and confirmed the production hash matches the tested candidate.
A bounded direct production XSim rerun passed with no source override; final
evidence is`golden/out/m5-solver-xsim/qualification-direct-final-20261010/report.json`.
Its source pins use the real production paths and record the corrected wrapper
hash; all38solves/127lines and negative/error/latency checks passed again. See [actual-pipeline handoff](handoffs/m5/agents/solver-xsim.md)
for reconciliation and job state. This does not retroactively qualify the full
frontend loop executed with stand-ins; that loop still needs actual-IP evidence.

## Actual-IP general circuit and default-baud extension (2026-10-11)

The actual SolverBoard runner now adds a separate exact-rational physical MNA
oracle. It builds each matrix independently from component laws, then solves by
Gauss-Jordan with the first nonzero pivot; it does not reproduce the RTL LU
algorithm or read the production conversion ROM. The original 36 analytic circuits
retain their exact UART bit expectations. New circuits use an explicitly scoped
empirical physical accuracy bound `abs(observed-physical) <= abs(physical)*2e-4 + 1e-30`.
This is a new solver probe policy, not a change to any frozen frontend contract
or a proof of accuracy for arbitrarily conditioned circuits. Decimal unit scales
are rational physical values; actual ROM/FP rounding is included in observed
error. The absolute term only covers near-zero roundoff at far below any ordinary
unit-scale voltage. Benchmark values span approximately 1e-18 to 1e18.

The added corpus covers four seeded connected bridges at3/4/6/8 nodes,
voltage-source and resistor/current use of all seven documented unit codes,
32 elements/31 nodes (combined MNA dimension 32), a 32-node all-grounded homogeneous
resistor system, and BCD 999. It checks checksums, framing, finite values and status 00
as well as physical voltage accuracy. Headers for 33 elements and 33 nodes must be rejected
with ER02 before solving. The 32-node case has a zero RHS; it is a capacity and
matrix/address traversal witness, not a randomized 32-node connected-circuit claim.
A separate `--include-near-singular` probe uses strongly coupled 1 milli versus 999 base
resistors and must satisfy the same numerical bound; misses remain failures.

The bench includes inside/outside comparator boundary controls and a separate
`CORRUPT_GENERAL` run that alters a general voltage by 0.1%, above the 0.02% relative
bound. `CORRUPT_SOLVER` still catches corruption of the original exact node lines.
All actual configured 16/28-cycle FMA/divide latencies are observed in the production
pipeline. Reports retain effective manifests and source hashes. Existing generated
products identify revision 21 while original XCIs identify revision 6; original-IP
synthesis remains unqualified and `full_m5_ready` remains false.

`tools/verify_solver_frontend_xsim_m5.py` and `M5SolverFrontendXsim.sv` connect the
production frontend and SolverBoard at their default 115200 baud, with actual
configuration-equivalent vendor FP products. Mouse output injection selects the
accepted split-rail edit. Physical PS/2 is outside scope. Unelaborated OLED
(`ENABLE_OLED_CALC=0`) and unused historical matrix/tofixed modules are excluded
from the compile manifest; production frontend/solver sources are unmodified.
The bench checks boot/repeated 10 V and split-rail 10 V/0 V, 16/28-cycle latency, and cold boot
observation corruption. Results and limitations are recorded in the resume
handoff; an in-progress or failed run does not qualify this loop.

The broad corpus plus both corruption controls passed in
`golden/out/m5-solver-xsim/general-controls-20261011/report.json`: 59 solves,
300 UART lines, 45,148 FMA results and 1,589 divide results, all at configured
16/28-cycle latency, without source overrides or drift. The separate
`near-singular-20261011/report.json` returned failure: physical V1 is
`999001/1998001` (about 0.50000025 V), whereas hardware produced about 0.5185897 V,
a 3.72% relative error with status 00. The policy was not widened. This is a
finite-precision physical-accuracy limitation of the ill-conditioned circuit;
it does not establish a mismatch against a frozen bit-exact solver contract.
Combined dimensions above 32 (nodes plus ideal voltage-source auxiliary rows)
remain unqualified even when header node/element counts each fit their limits.

A bounded cold actual-IP augmented-capacity probe is available as
`tools/probe_solver_capacity_xsim_m5.py`. It sends 32 nodes and 32 elements
(one ideal voltage source plus 31 chain resistors), requiring 33 MNA rows.
Root authorized expecting STATUS_CAPACITY03 rejection based on the declared
capacity constant; this is an explicit probe policy, outside the frozen frontend
contract. The actual run at `m5-solver-capacity-xsim/augmented33-20261011` failed
that policy: SolverBoard ran the solve and replied `@VB,FF40,20,05*3B` (FP error)
without capacity rejection. No production fix was applied by this solver role.
The probe hashes its derived isolated bench, unchanged production sources,
fixtures and actual IP/FP characterization provenance.

The 2026-10-11b resume adds per-VSYNC state and mouse/stimulus phase diagnostics to
actual default-baud frontend qualification without changing stimulus timing,
accepted results or settle frames. The isolated augmented-capacity probe now
listens concurrently with transmission, so an early `ER03` cannot be missed.
It requires the complete error line and XOR checksum, a hexadecimal argument,
rejection before any solve, and a cold observation corruption control for a
successful primary. The argument meaning remains outside this provisional probe
policy until production capacity handling is specified.

A supplemental exact-Fraction physical-MNA conditioning audit is retained in
`golden/out/m5-solver-xsim/conditioning-audit-20261011b/report.json`. The strongly
coupled near-singular fixture has raw infinity-norm condition number about
1,999,002, compared with about 10–95 for the four connected bridges. Multiplying
this diagnostic by binary32 unit roundoff gives about 0.119 for the near-singular
fixture. This is consistent with sensitivity to roundoff; it is not an algorithm
error bound. The matrix combines voltage/current quantities, so this raw norm
also depends on scaling and units. The audit does not change the empirical
`2e-4 + 1e-30` criterion, classify arbitrary circuits as accurate, or promote the
near-singular failure to acceptance.

Root subsequently specified an isolated capacity guard candidate: count accepted
ideal-voltage-source rows for each snapshot and reject combined dimensions above
32 at `NE`, with `ER03` and the augmented dimension as the 16-bit error argument.
Both actual-IP runners accept an explicit `--solver-top PATH` override and record
the original and effective paths/hashes. Production remains separate from that
candidate. The dimension-33 candidate probe therefore requires exact
`ER,FF40,03,0021` framing/checksum and no solve; its cold corruption control must
first observe a valid uncorrupted capacity reply, then fail the same exact
observation comparison. Candidate evidence cannot silently qualify unchanged
production sources or the frozen frontend oracle.

The actual default-115200 frontend run completed successfully in
`golden/out/m5-solver-frontend-xsim/diagnostics-20261011b/report.json`: boot at
frame 3, repeated immutable 10 V at frame 5, and split-rail 10 V/0 V at frame 12.
Its 52 FMA and 53 divide results obeyed the configured 16/28-cycle latency, and
its cold boot-voltage corruption control failed the required comparison. The
primary took 977 seconds with the original stimulus; the earlier 900-second
execution timeout was insufficient in this environment. No settle frames were
added. State diagnostics at VSYNC precede the subsequent pixel-clock capture,
so their mouse fields show the preceding captured sample. Physical PS/2, board
transport and raster equality remain outside this scope.

The isolated capacity guard candidate passed dimension-33 rejection and the
unchanged supported general corpus in `candidate-guard-20261011b/report.json`
and `candidate-capacity-supported-20261011b/report.json`. The latter's 300 UART
reply lines match the previous production corpus byte for byte. These are
explicit override results; they do not qualify unchanged production capacity
handling. A separate recovery/multiple-source derivation is retained under
`m5-solver-capacity-xsim/recovery-candidate-20261011b`; its first preflight stopped
because the historical FP characterization helper-source manifest had become
stale after the extraction-only runner extension. This failed preflight is
preserved; fresh FP provenance is required before running it. Earlier runner FP
checks occurred at startup, so current acceptance must independently verify
fresh FP policy/source identity.

The isolated recovery derivation subsequently passed using fresh current-helper
FP characterization: `m5-solver-capacity-xsim/recovery-candidate-20261011b/report.json`.
One-source/32-node and two-source/31-node snapshots both require 33 rows and
receive exact `ER03/0021` before any solve. Each rejection is followed by a
supported dimension-32 snapshot: the 31-node series chain returns exact 31..1 V,
then 32 independently grounded resistor nodes return exact zero. Exactly two
solves occur, both with status 00; the boundary recoveries detect leaked source
counts and status. A cold sampled-observation corruption fails the same
comparison. Sources have no drift, the override is explicit, and production
integration remains a separate step. The stale preflight report is preserved.
