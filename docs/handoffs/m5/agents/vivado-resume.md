# M5 Vivado resume assignment

Owner `/root/m5_vivado_resume`, parent `/root`; no descendants.
Workspace `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branch verification,
HEAD f894fa; preserve earlier M4/M5 dirty files. Own only tools/vivado_qor.py,
tools/vivado_qor.tcl, tools/tests/test_vivado_qor.py, docs/m5-vivado.md and this document.
Prior assignment: [vivado.md](vivado.md).

Fresh quota 2026-10-10 14:00:18 UTC: five-hour 98%, weekly47%; reset
18:59:37 UTC and 2026-10-14 15:27:22 UTC. Default thresholds unchanged;
root owns 60-second team timer. No active owned jobs at this checkpoint.

Audited frontend conservative closure (including disabled generate branches):
41 sources reachable; original fpo_div/fpo_fma/fpo_tofixed wrappers are unreachable,
so all three locked2018.2 XCI can be omitted from GlobalRender_top only. Real MouseCtl,
Ps2Interface and MouseDisplay remain. Runtime closure drift must fail before launch.
Original full manifest files including omitted sources/IP remain hashed.
Runner now rejects any logged ERROR, locked reachable IP, and unresolved synthesis
black boxes. Project IP flow uses create_ip_run/launch_runs/wait_on_run.
Tests/current real measurement pending; no success is claimed.

Next: run tools/tests, freeze runner, launch new empty frontend routed directory,
inspect actual reports/API failures, preserve findings without changing RTL/IP/XDC.

## Real run checkpoint

Ten tools/tests passed. Launched frozen routed frontend run in
`golden/out/qor/frontend-baseline-resume` with session5371, Python runner PID2487973,
owned Vivado process group2488147 (launcher PID2488147, actual VivadoPID2488237).
Signal runnerPID2487973 to forward termination to owned group only; verify command
and PGID first. Settings/compile-order/audit saved; synthesis currently ongoing.
No tracked RTL/IP/constraints altered.

## Checkpoint after real routed failure

Session5371 ended naturally exit1; no owned jobs remain from group2488147.
Final synth: LUT24117/20800=115.95%, FF13677,BRAM10,DSP0; WNS-5.176ns,
TNS-9647.644ns,setup4568/31308 endpoints, WHS0.045ns,hold0.
Actual place_design precondition DRC UTLZ-1 requires22138LUT>20800 after opt;
placer not run, no route. Three logged ERRORs reject measurement. Saved reports
and synth.dcp complete; requested_stage stays routed and summary incomplete.
No constraints/DRC severity/IP/RTL changed.

Runner now snapshots75 original manifest inputs into out/inputs and executes
saved Tcl/source/XDC. Default parser validates saved hashes; explicit root or
--check-working-tree checks current checkout. Per-instance hierarchy rows and
DRC rule/severity/count parse from real reports;12 own tests pass (full tools
suite26 including root gate tests). Inclusive hierarchy rows must not be summed.

Fresh frozen synth baseline launched in golden/out/qor/baseline-final-synth,
session9415, owned VivadoPGID2516961. All75 snapshot hashes verified before root
was notified production RTL could change. This run is solely synth characterization;
original failed routed attempt is retained. Active synth job has not finished.
Next: inspect final reports, parser and source provenance; send root complete
baseline summary and next candidate measurement command. Root owns production
optimization edits; original snapshot remains available for historical compare.

## Checkpoint 2026-10-10 14:13 UTC

Immutable baseline-final-synth session9415 finished naturally rc0;
summary complete/errors[],timing_clean=false. All final reports and DCP retained.
Metrics match prior synth24117LUT13677FF10BRAM0DSP; hierarchy/DRC parsed. Group2516961
has no active work. Root now owns address-arithmetic production candidate and
functional/proof validation.

Candidate-address-synth active session46057, owned VivadoPGID2538079. All75 input
snapshot hashes verified; ONLY GlobalRender_top.v differs from immutable baseline.
Objective saved by root before run: LUT gain>=1, all resource ceilings at baseline,
WNS>=-5.176ns, WHS>=0; provisional synthesis objective, readiness false.
Latest fresh quota14:13:15UTC57%five-hour40%weekly; root team timer continues.
Next: inspect finalized candidate summary; compare constraints/settings/hash diff
and measured exact objective. If area fits, obtain fresh routed candidate without
waivers; report blockers and job state. No RTL/IP/XDC edits by this agent.

## Final checkpoint 2026-10-10 14:18 UTC

Current assignment complete to tooling + honest characterization limits; M5-6
and M5 readiness are NOT marked complete because actual route is blocked and
clock/I/O/CDC/DRC readiness remains unresolved. No descendants ever spawned.

Candidate session46057 finished naturally rc0, evidence complete/errors[],
timing_clean=false. Actual synth LUT24471(+354),FF13668(-9),BRAM10,DSP0;
WNS-6.262(-1.086ns),TNS-10316.741, WHS0.045 unchanged. Objective FAILS
minimum gain, resource ceiling and setup; hold passes. UTLZ-1 Error still present.
No route launched because candidate does not fit Basys3. Root notified to reject
and revert candidate; root owns RTL/functional/proof decision. Agent edited no RTL.
Comparison saved in golden/out/qor/candidate-address-synth/comparison.json with
objective SHA256029ec1b25a33a1370691ce867f341cb9e2681ee6483c001837c70cfb75315e45.
Only GlobalRender_top.v differed; runner/XDC/settings were identical.

Independent --parse-only baseline passed exit0; candidate --parse-only
--check-working-tree passed exit0 before any root revert. Historical baseline
uses saved inputs, so candidate changes do not invalidate its characterization.
All owned job groups2488147,2516961,2538079 ended; ps of2538079 now empty.
No jobs remain owned by this assignment. No commit/push performed.

Fresh quota14:18:43UTC42%five-hour38%weekly; reset18:59:37UTC and
2026-10-14 15:27:22UTC. Normal checkpoint, not a quota shutdown.

Recreation assignment: retain runner/tests/docs, failed routed evidence and both
complete immutable synth snapshots. Root should revert rejected address candidate
and choose another separately frozen objective/source candidate. Measure with
python3 tools/vivado_qor.py --out golden/out/qor/FRESH-CANDIDATE --stage synth
and --check-working-tree parse-only validation. Use baseline-final-synth summary
for provisional area/timing compare; required routed gate must continue failing
until actual constrained placement/routing succeeds. Resolve real pixel clock,
I/O timings and CDC/DRC qualification without silently weakening constraints.
Do not upgrade solver IP or claim solver qualification from frontend omission.
