# Subagent handoff: M5 integrated flooding FIFO lifetime bound

Updated: 2026-10-11T01:25:17.806167+00:00
State: scoped investigation complete; formal/full-frontend/integration qualification remains incomplete
Author: /root/m5_gate_recovery
Parent: [M5 verification](../../m5-verification.md), root coordinator
No descendants.

## Self-contained replacement assignment

Read-only investigation of whether actual18x16FloodingBackendWrapper guarantees
at most1152 queue additions between clear despite edits, epoch/reset and implicit
pointer wraps. Own this handoff, optional docs/m5-invariants.md, and new isolated
artifacts under golden/out/m5-fifo-bound-20261010c only. No production RTL,
existing probes/shared evidence/gate-policy modifications. Branchverification,
HEADf894fa8dcb487ff02c8f671e4126cc84cf169363. Preserve all dirty work.

## Saved work and verification

Static audit: wrapper clears queue/visited and resets core before every run.
Generated core serializes getVisited/setVisited/storeR, marks visited before
four distinct directional adds. Epoch constant within a non-reset run; editing
fetchP data cannot clear marks. Thus a source-specific inductive argument gives
at most4*288=1152, provided actual handshake/memory safety obligations hold.
This is not a completed machine proof or generic queue correctness waiver.
Exactly1152 additions uses legal indices0..1151; tail may become1152 afterward,
but no subsequent write may occur before clear. Pop bound then also<=1152.

VisitedMatrixStore/ResultMatrixStore16-bit epoch increments every cycle of
external reset or per-run clear. Wrapping can resurrect stale visited/result
tags, reducing visits and potentially violating flooding semantics. It cannot
increase unique per-run additions when epoch remains constant. Need a retained
real-input witness and separate decision; do not infer harmlessness.

Prepared isolated production-wrapper bench
`golden/out/m5-fifo-bound-20261010c/M5FloodWrapperBound.sv` with independent
per-cell/per-port uniqueness, FIFO data ledger and actual array-address checks.
Scenarios planned: dense bound1152 twice; read-varying legal map; interrupted
reset during add activity then dense recovery; sixteen-bit epoch alias using
external reset cycles, without hierarchical force. Specific ledger corruption
control planned. Native5.046 and Docker5.020 pass directed continuous ledgers identically:
dense1152/1152/288 twice, dynamic946/946/288, reset interruption at100adds
then dense recovery1152. Total178809cycles. Specific ledger corruption yields
`M5_BOUND_FAILURE fifo_data`, nativeexit1/Docker139. Preserved initial failed
compile (reserved word cell) separately; corrected isolated bench only.

Actual external-reset epoch alias reproduced identically both runtimes:
65535 reset clocks plus per-run clear resurrect epoch12; blank input map gives
actualfetchR(0,0)=1 where independent expected0. No forced tag/epoch values.
`report.json` records source/bench/log hashes, directed bound verdicttrue,
readyfalse, formalfalse, genericFIFOfalse. Logs retained under the output root.

## In progress, uncertainties and owned jobs

Isolated candidate in `golden/out/m5-fifo-bound-20261010c/candidate` adds per-cell
validity bitmaps, cleared onreset/clear, read through unchanged RAM-address
pipeline; explicit initializationzero. Both pinned runtimes preserve exact
scenario counts/cycles and now return0 after aliased epoch onblankmap. Both
reject specific ledger corruption. Candidate-report.json contains actual source/
bench/log hashes and scoped true verdict; readyfalse/integratedfalse. Expected
pre-synthesis area estimate576validityFF was only an expectation; measured
standalone total delta is+813LUT/+578FF/0RAMB18/0RAMB36.
Historical preinitialization candidate logs retained; final reports use final
initialized candidate.

Next record separate epoch-defect decision, broaden candidate frontend/reset/
epoch qualification and measure FPGA resources/timing before integration.
Formal arbitrary-input bound remains unfinished.
Root explicitly authorized isolated correction after unchanged reproduction,
no production edits until expensive frontend source-stable runs finish.
Root owns the quota60second timer; the separate Docker fast gate completed successfully.
Standalone actual18x16 store synthesis session73313 completed exit0; allfour
module reports/checkpoints retained and hashed in store-qor-report.json.
No owned gate, FIFO, compile, simulation, container or Vivado jobs remain.
Module area measurements only; global route/IOtiming remain unqualified. Gate-role Docker fast gate just launched separately,
with its own handoff/job tracking. Static argument needs executable/formal
induction qualification; full frontend edit schedules/progress remain unproven.

## Quota and completion

New-phase live check2026-10-11T01:14:00.299775ZOK,73%five-hour/81%weekly.
Default prepare<10%/<6%, stop<3%/<2%; resets06:08:23Z /Oct17T19:35:03Z.
Latestrootcheck2026-10-11T01:16:28Z63%five-hour/79%weekly.
Relay anyalert and stop ondocument/stop/unavailable with separate saved handoff.

Live pre-QoR check2026-10-11T01:20:43.583940Z48%five-hour/77%weekly, OK.
Cold pre-first-clear emissions remain unqualified: core state and FIFO pointers/
count have no initial assignments; real top reset(~BTNC) may start high.
The inductive bound begins at an actual reset/clear, not arbitrary powerup.

Standalone synthesis session73313, former processgroup143349/Vivado143470,
completed normally; no permanent termination claim. Initial command
session39945 exited1 due Vivado read_verilog -define requiringcompile-unit mode;
failedlog preserved. Rerun uses sources_1 verilog_define and 10nsXDC before synth.

## Measured isolated correction cost and remaining assignment

Vivado2025.2, xc7a35tcpg236-1, actual18x16 parameters, same10nsclock/default
synthesis: visited42LUT/32FF/1RAMB18 ->449LUT/321FF/1RAMB18; result42LUT/31FF/
2RAMB18 ->448LUT/320FF/2RAMB18. Total+813LUT/+578FF, RAMunchanged. Estimated
synthWNS visited5.782 ->5.106ns and result3.935 ->3.935ns; synthesis timing
is not routed qualification and externalIOconstraints are absent.

Next replacement assignment: preserve both specific original defects and
correction candidates; record epoch correction decision/area budget separately;
qualify full frontend/reset/epoch scenarios under isolated candidate sources;
measure composed full-top route/resource/timing before accepting any production
change. Derive machine-checked invariant for arbitrary RAM data/reset afterfirst
clear, or retain scope as directed. Prove coldpre-first-clear safety separately.
Generic FloodQueueStore wrapping defect is not fixed or waived.

## Final role checkpoint

Latest direct live quota2026-10-11T01:25:23.775876Z:30%five-hour/74%weekly,
OK/exit0. Default strict thresholds and60second team cadence unchanged. No
quota shutdown triggered for this role. All owned tests, compiles, containers
and Vivado jobs finished; no descendants. No production RTL, accepted harness,
gate/policy, immutable contract or shared verification-plan/evidence edits by
this agent. No commits/pushes. This role handed documents/results to root and
ends active work at 2026-10-11T01:25:49.620056+00:00.
