# M5 actual solver and frontend resume — 2026-10-11

Parent `/root` assigned actual production solver/general circuits, units,
capacity and default-baud frontend qualification. No descendants, production
RTL/IP/configuration/oracle edits or commits. Earlier context:
[actual solver](solver-xsim.md), [FP](fp-qualification.md),
[solver foundations](solver-qualification.md).

Workspace `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branch `verification`,
HEAD `f894fa8dcb487ff02c8f671e4126cc84cf169363`; preserved shared dirty tree.
Owned files: `tools/verify_solver_xsim_m5.py`,
`tools/tests/test_verify_solver_xsim_m5.py`, `src/testbench/M5SolverUartXsim.sv`,
`docs/m5-solver.md`, new `tools/verify_solver_frontend_xsim_m5.py`,
`src/testbench/M5SolverFrontendXsim.sv`, new
`tools/probe_solver_capacity_xsim_m5.py`, and this document. Root retains evidence,
plan, acceptance and production RTL ownership.

## Completed actual solver evidence

Final command/session 76685 completed exit 0:

```
python3 tools/verify_solver_xsim_m5.py --out golden/out/m5-solver-xsim/general-controls-20261011 --timeout 600
```

`report.json` has `scoped_actual_pipeline_passed=true`, no source override or
drift, 59 solves/300 UART lines, 45,148 FMA/1,589 divide results at actual 16/28-cycle
latency. Both original exact-line and new general 0.1% observation corruption
controls are detected; inside/outside numerical comparator boundary checks pass.
Original 36 bit-exact analytic cases and checksum error/recovery/singular status
05 remain unchanged. Two 33-element/node headers are rejected with ER02.

New independent exact-rational physical MNA oracle uses Gauss-Jordan first-nonzero
pivot, independent of RTL LU and production conversion ROM. Corpus adds four
seeded connected bridges at 3/4/6/8 nodes, source and resistor/current use of all
seven unit codes, 32 elements/31 nodes (combined MNA dimension 32), a 32-node
all-grounded homogeneous resistor system, and BCD999. New physical probe bound is
relative 2e-4 plus absolute 1e-30, explicitly empirical, not a conditioning proof
or modification of frozen frontend expectations. Exact UART framing/checksum,
finite values and status00 are required. Independent post-run exact Fraction
comparison of all 129 general UART node words found maximum relative error
1.145871926e-6 at connected_bridge_6/node2; all 32 expected-zero nodes exact zero.
Saved supplemental `numeric-error-audit.json` contains every exact physical and
binary32-observed rational value. This supplemental post-run audit does not
replace the executable fixture/control report.

Earlier session50123/general-20261011 passed the same physical corpus with only
the initial exact-line negative. Preserve its historical source/policy identity;
use final general-controls report for current controls evidence.

## Explicit accuracy failure and capacity gap

Separate cold session6067 completed exit1:

```
python3 tools/verify_solver_xsim_m5.py --out golden/out/m5-solver-xsim/near-singular-20261011 --solver-cases 3 --include-near-singular --timeout 600
```

Near-singular 1 milli versus 999 base resistor circuit gives physical V1
`999001/1998001` (~0.50000025), actual ~0.5185897: 3.72% relative error despite
status00/fp_exception0. Report scoped pass=false. Bound was not widened. This is
an ill-conditioned finite-precision physical accuracy limitation, not proof of a
frozen bit-exact solver contract mismatch. The preceding 21 general circuits
pass; checksum/recovery/singular stages after the failure are not reached.
Both cold corruption controls still execute and detect their specific faults.

Known static combined-capacity gap, reported to root: parser checks node_count
and element_count <=32 independently; solve_core adds one auxiliary MNA row per
voltage source (SV lines1161/1280); DIM32 stores reject out-of-range accesses.
STATUS_CAPACITY03 is declared but unused. Passing capacity fixtures constrain
node_count+voltage_sources<=32. Augmented dimension33 remains unqualified; no
invented error argument/rejection policy has been applied.

## Actual frontend partial evidence and timeout

Completed session82195 (exit1, owned900s timeout):

```
python3 tools/verify_solver_frontend_xsim_m5.py --out golden/out/m5-solver-frontend-xsim/reset-sourcefix-20261011 --timeout 900
```

Compiled/elaborated actual production GlobalRender_top + SolverBoard + pinned
configuration-equivalent actual vendor FP; default115200 UART, no stand-ins.
Root's stable corrected top SHA is
`4e62e63dd68ba9e946006a86129d48c39dd7570710a73451f0fd1fba68c2bb16`.
Run log now observes `FRONTEND boot accepted frame=3 voltage=41200000` (10 V).
The primary timed out at900s after the accepted boot; full duplicate/split-rail
pass marker is absent. No source drift. XSim was slow (~4.5 min to first boot).
Whether the later edit was progressing or stalled remains unobserved because
no intermediate frame/state diagnostics were printed. Do not attribute timeout
solely to performance or claim full loop qualification.
Mouse outputs are injected; physical PS/2 and visual raster equality outside
scope. Bench drives legitimate SW15 reset for40 system clocks, checks initialized
VGA counters, and includes independent simulation-time and VSYNC watchdogs.

Historical failed frontend attempts retained:
- session66945/qualification-20261011: broad compile failed on unused OLED
  forward declaration;
- session58327/qualification-nooled-20261011: unused historical bmatrix module
  compile failed;
- session41216/qualification-closure-20261011: compiled/elaborated; safely stopped
  only its owned run process group3275216 with SIGTERM after diagnosing constant
  SW15=0 left VGA counters X in four-state RTL simulation. Report false/run-15.
  Prior Verilator implicit zero initialization had hidden this harness setup gap.

Compile exclusions are explicit and unelaborated: OLED constant-disabled by
ENABLE_OLED_CALC=0; unused historical matrixStore/bmatrixStore/LUdecomp/lu_core and
fpo_tofixed. No production patch or source override.

## Verification, limits and next step

32 scoped M5 runner Python tests pass, including 8 solver-XSim tests, independent
known bridge/polarity/near-singular analytic values, Kirchhoff residuals, all-unit
and capacity dimensions, seeded determinism, checksum boundaries, and no stand-in
actual manifests. Command:
`python3 -m unittest discover -s tools/tests -p 'test_verify_*m5.py'`.

Existing generated FP products identify revision21 while original tracked XCI
identifies revision6; original-XCI synthesis remains explicitly unqualified.
Every report keeps full_m5_ready=false. Full randomized extraction/general nets,
combined capacity enforcement, conditioned numerical policy and physical board
are unfinished.

Next concrete step: add per-frame diagnostics (snapshot/reply ids, node/status,
solver state), then rerun the same frontend stimulus/watchdogs under root-authorized
execution timeout1800s, without adding simulation settle frames or changing the
accepted frontend contract:
`python3 tools/verify_solver_frontend_xsim_m5.py --out golden/out/m5-solver-frontend-xsim/NEW --timeout 1800`.
Obtain fresh quota and audit current source first. Do not rerun the completed
broad solver corpus merely to reproduce its historical report. Root owns any
production capacity/numerical changes. Before testing a future early capacity
rejection fix, update the isolated probe to receive concurrently with snapshot
transmission and validate error checksum; current probe waits after NE and
could miss a correctly emitted early rejection. Current failure witness is
valid because hardware ran the solve and emitted VB after NE.

Quota: initial2026-10-10T19:06:18Z98%five-hour/32%weekly. Latest direct check
19:18:41Z47%/24%, ok. Resets2026-10-11T00:05:41Z and2026-10-14T15:27:22Z.
Default strict prepare below10%/6%, stop below3%/2%; parent owns60s team timer.
On any document/stop/unavailable alert, freeze substantive work, document, stop
owned work and end after reporting job state. No descendants.

Root authorized a bounded augmented-dimension33 probe with intended
STATUS_CAPACITY03 rejection inferred from the declared unused constant.
New owned `tools/probe_solver_capacity_xsim_m5.py` builds a derived bench in its
isolated output (no tracked bench/production overrides), checks actual FP pins,
and sends32 nodes/32elements with1voltage source plus31chain resistors. Session8649
running at `golden/out/m5-solver-capacity-xsim/augmented33-20261011`, timeout180.
Expected policy is explicit and does not replace frozen frontend behavior.
Root permits future frontend runtime1800s for one primary/negative phase if
healthy; current900s attempt remains historical and continues unchanged.

To overlap the expensive real default-baud boot negative with primary, session67192
copies the primary compiled `xsim.dir` snapshot andROM into separate
`golden/out/m5-solver-frontend-xsim/parallel-negative-reset-sourcefix-20261011`,
pins everycopiedfile in `snapshot-sha256.json`, and runs actualXSim CORRUPT_FRONTEND
(timeout900) there. Independent cwd/logs avoid runartifact races; no source edits.
It writes its own report/negative witness, full_m5_ready=false. Primary original
runner82195 stillruns unchanged andwillproduceits normalreport ifcompleted.
Current ownedjobs82195(frontendprimary),67192(parallelcoldnegative),8649(capacity33).
Latestquota2026-10-10T19:23:35Z31%/22%,ok. Onalert freeze andstoponlyownedjobs.

Capacity session8649 completed exit1 with specific mismatch=true and no drift:
actual solve ran withfp_exception1, firstreply `@VB,FF40,20,05*3B` rather than
capacity rejection. Full reportandcoldtrace retained.9solver-XSimtests nowpass;
newpacket test proves32declared nodes,32sequential elements,oneVsource andall31
chain connections, checksumvalid throughout. No productionfix applied.

Owned-job cleanup identity checkpoint: primaryrunnerPID3287037, currentXSim
runprocessgroup3288974; isolatednegativerunnerPythonPID3341709 under shell3341706,
XSim runprocessgroup3341773. These are agent-owned only; re-inspect exactPID/
command lineage before cleanup to avoid PIDreuse. No other active owned jobs.


## Final scoped checkpoint

All owned jobs are stopped. Primary82195 report scoped_actual_frontend_passed=false,
run.returncode=null/timeout900/owned_process_group_stopped=true, source_drift=[],
and accepted_events contains only boot frame3/10V. Parallel cold negative67192
completed normally: negative_data_detected=true, XSim return0 with the required
specific boot-voltage Fatal witness,239.745s. Its separate copied-snapshot manifest
SHA is2b18aec3c8484f65eef4a35a61169602d52c95a49b73543897795175e34d459f;
negative logSHA5a44f69c0360685fea16e6931daf16ffddf9bba42a07451153ac6cf9c9869f68.
This is qualified actual default-baud boot/negative evidence, not full edited-loop
qualification. Main report deliberately remains false. Root notified.

Known owned PIDs3287037/3288974/3290087 and3341709/3341773/3342704 all absent in
/proc at final cleanup inspection. Capacity8649 completed exit1; all prior solver
sessions completed. No active job, monitor or descendant remains. No user process
was targeted. Final scoped M5 runner test command currently passes46 tests
(other roles added tests in the shared tree); this role's solver-XSim tests9 pass.
Latest fresh live quota19:28:21Z14%five-hour/19%weekly,ok; no latched quota alert
received during this child turn. This is a normal scoped handoff with explicit
unfinished full-M5 work; root remains coordinator and ends last if shutdown
triggers. Do not start another expensive phase from this historical quota result.

## Latched quota shutdown

Fresh directcheck2026-10-10T19:29:53.991753Z returned document/exit10:
7%five-hour/18%weekly (five-hour below10% prepare). Root subsequently notified
its earlier teamtrigger19:29:28Z9%/18%; shutdown remains latched. No new work or
tests after trigger. All jobs were already stopped, PIDs verified absent, and
handoff complete before this direct alert; final actions are guard notification
and this handoff append only. No descendants; root must end last. Resets remain
2026-10-11T00:05:41Z and2026-10-14T15:27:22Z. Future resume requires user instruction
and fresh live quota; reset alone is not permission to restart.
