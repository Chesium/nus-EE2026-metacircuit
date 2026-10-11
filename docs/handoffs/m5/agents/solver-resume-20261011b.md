# M5 solver/frontend resume — 2026-10-11b

Assignment from root: resume actual default115200 frontend with per-frame diagnostics and unchanged stimulus/watchdogs under 1800s execution timeout, then advance capacity/numerical qualification. No production RTL/IP/oracle edits, no descendants. Preserve prior [resume](solver-resume-20261011.md), reports, shared dirty tree. Workspace `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branch `verification`, historical HEAD `f894fa8dcb487ff02c8f671e4126cc84cf169363` (inspect on resume).

Own `tools/verify_solver_frontend_xsim_m5.py`, `src/testbench/M5SolverFrontendXsim.sv`, `tools/probe_solver_capacity_xsim_m5.py`, `tools/verify_solver_xsim_m5.py`, `tools/tests/test_verify_solver_xsim_m5.py`, `docs/m5-solver.md`, this handoff. Root owns production/gate/evidence.

Fresh initial quota 2026-10-10T19:35:48.857088Z: ok, 98% five-hour /100% weekly. Defaults prepare strictly below10%/6%, stop below3%/2%. Root owns60s team timer; any document/stop/unavailable signal freezes this role and triggers job cleanup/handoff. No descendants.

Added per-VSYNC snapshot/reply/status/stage/stale/solver/pipeline/mouse/toolbar diagnostics and duplicate/stimulus phase markers. No added frames or stimulus timing changes. Runner records diagnostics separately from accepted events. Primary session56874 running:

```
python3 tools/verify_solver_frontend_xsim_m5.py --out golden/out/m5-solver-frontend-xsim/diagnostics-20261011b --timeout 1800
```

Compiled/elaborated0; run underway. At first observed frame1 all initialized states0; bench legitimate SW15 reset unchanged. Owned runnerPID3407865, run PGID3410405 /xsimkPID3410650 (reinspect command lineage before cleanup; PIDreuse possible). Source hashes recorded by runner report at end; pinning happens before compile. Root requested to avoid production drift while run progresses.

Updated isolated capacity probe to fork TX/receive concurrently before NC rejection can occur, validate exact19character ER format/XOR checksum, parse error argument without prescribing its meaning, assert rejection before any solve. Added cold observation corruption control if primary passes. Full send still completes before finish. Derived bench only, no production overrides.

10 scoped tests pass:
`python3 -m unittest discover -s tools/tests -p test_verify_solver_xsim_m5.py`.

Capacity session49621 running:
```
python3 tools/probe_solver_capacity_xsim_m5.py --out golden/out/m5-solver-capacity-xsim/concurrent-20261011b --timeout 180
```
Expected baseline failure: historical dimension33 probe emitted VBstatus05. Current rerun ensures concurrent receiver does not miss an early capacity error if root later fixes production. No evidence yet of production fix or capacity qualification.

Next self-contained assignment: fresh quota, inspect both owned sessions/report/logs and actual sources; diagnose frontend from frame/state sequence without widening contract or adding settle frames. Relay production defects before any production edits (root owns). Capacity probe must retain checksum/concurrent policy; do not claim pass from prefix alone. Reconcile source drift explicitly. Numerical near-singular physical error3.72% remains a scoped failure with original2e-4 bound unchanged; rational oracle/general-controls historical report is complete and should not be rerun merely to recover past evidence. Never overwrite historical reports.

## Capacity/diagnostic checkpoint

Concurrent-controls capacity session68324 completed exit1; primary XSim0 despite
Fatal; runner now checks positive pass marker before starting cold control.
Final current probe evidence `golden/out/m5-solver-capacity-xsim/concurrent-controls-20261011b/report.json`
has no source drift, rejection=false, mismatch=true, negative=false/not run.
Actual reply remains `@VB,FF40,20,05*3B`; actual solve ran with FPexception1.
Historical initial concurrent session49621 also exit1; its negative flag was
nonqualifying because baseline itself mismatched. Preserved unchanged; use final
concurrent-controls report for current policy. Both capacity jobs complete.

Exact-rational physical MNA conditioning diagnostic saved in
`golden/out/m5-solver-xsim/conditioning-audit-20261011b/report.json`: raw infinity
condition near-singular~1,999,002 vs connected-bridges~10–95. Mixed units make
raw metric scaling-dependent. Only diagnostic; no oracle, accuracy threshold,
production or acceptance changes. Source fixture hash retained in report.

Frontend primary56874 still running; boot accepted frame3=10V; frame diagnostics
show initialized state then normal staged reply. No production defect identified
from this loop yet; no added settle frames. Latest direct quota19:38:37Z87%/98%,
ok; parent timer remains authoritative.

Source checkpoint SHA256 (current working files, not substitute for per-run pins):

```json
{
  "src/testbench/M5SolverFrontendXsim.sv": "11968c655f788c8f6d14f0d7b3393f04454008f3603e0fa4c1941cc3f5096fd0",
  "tools/verify_solver_frontend_xsim_m5.py": "3be7456369d165472a36f2b0cc2b4cc48dea933fe0e872428e9eb0e229b213a4",
  "tools/probe_solver_capacity_xsim_m5.py": "7e91842889925b87908abc3d461f6f2d058b5c00891f9e30659faef296e4ac1f",
  "tools/tests/test_verify_solver_xsim_m5.py": "7db9813e6924cd76b6bb50a9bda5ed513db76b4d1ecfc3f3e2ed711179b1102f",
  "src/design/rendering/GlobalRender_top.v": "4e62e63dd68ba9e946006a86129d48c39dd7570710a73451f0fd1fba68c2bb16",
  "src/design/floating_point/fpo_fma.v": "9c1daa50bb18196ff22615da92bcf8a3b0697647e821db45376d735948f05ec7"
}
```

## Root-authorized isolated guard extension

Root prepared `golden/out/m5-capacity-candidate-source/SolverBoard_top.sv`,
SHA77a637aaf93df02f6adc1dbd50375eeb0fc5d1f08063811300d294597e5ee78b;
proposal.json records exact diff. Production unchanged. Candidate counts accepted
kind03 rows per NB snapshot and checks node_count+count at NE, rejecting>32 with
ER03/16-bit augmented dimension before solver_start. Parser independently
checks matching NB/NE counts and sequential NC. Added explicit --solver-top to
capacity and broad solver runners: only SolverBoard source substituted, original
and effective source identities/provenance pinned and override reported. Twelve
scoped solver-XSim Python tests pass (single manifest substitution checks).

Current owned jobs in addition to frontend56874:

```
python3 tools/probe_solver_capacity_xsim_m5.py --out golden/out/m5-solver-capacity-xsim/candidate-guard-20261011b --solver-top golden/out/m5-capacity-candidate-source/SolverBoard_top.sv --timeout 180
python3 tools/verify_solver_xsim_m5.py --out golden/out/m5-solver-xsim/candidate-capacity-supported-20261011b --solver-top golden/out/m5-capacity-candidate-source/SolverBoard_top.sv --timeout 600
```

Capacity session42490, broad session61753. Candidate probe now prescribes exact
ER03/0021 argument, validates checksum before control, and sends corrupted
observation through a common exact comparator; baseline invalid reply cannot
qualify that negative. Broad supported corpus remains unchanged. Root requested
both actual-IP evidence scopes; no production or oracle changes by this role.
Latest direct quota2026-10-10T19:43:07Z68%/95%,ok. Frontend duplicate stable frame5
10V; next same original six mouse injections remain underway.

Candidate capacity session42490 completed exit0; report
`golden/out/m5-solver-capacity-xsim/candidate-guard-20261011b/report.json`: scoped
capacity rejection=true, exact`@ER,FF40,03,0021*3F`, no solve events, cold corruption
control detected after valid baseline; no source drift; override remains explicit.
Primary rejection at1.093685ms simulation; actual configured FP compiled and
elaborated but rejection correctly triggers no FP operations. Broad candidate
session61753 still running; primary now at full32-node supported traversal.
Frontend56874 frame7 still running, first mouse stimulus scheduled on frame6.

Candidate broad session61753 completed exit0: scoped_actual_pipeline=true,59
solves/300UART lines, both cold corruption controls and numerical boundary controls
pass, source drift empty, explicit SolverBoard override. All300 SOLVER_REPLY log
lines byte-identical to historical unchanged-production general-controls report.
Candidate rejection and supported corpus jointly cover the inferred guard scope;
production remains unchanged and must be reconciled before claiming direct
production-capacity evidence. Latest direct quota19:47:12Z56%/93%,ok.
Remaining owned job is frontend56874 atframe7/pressed-tool stimulus; no others.

## Actual default-baud primary pass

Frontend primary completed XSim0 in977s at186.901850ms simulation. Actual events:
bootframe3=41200000, duplicate stableframe5=41200000, splitrailframe12=41200000/00000000.
52FMA/53divide actual configured16/28cycles. All six original injections and
watchdogs unchanged. CORRUPT_FRONTEND cold phase now running within session56874;
report scoped result must await this specific negative and source-drift check.
The900s prior execution limit was insufficient to complete this same stimulus in
current environment; no settle frames were added. VSYNC diagnostics run#1ns after
falling edge and precede the frontend's subsequent pixel-clock capture, so their
mouse fields show the previous capture. Persistence proved by frame8 hover and
frame9 pressed mouse/tool9; frame12 accepted edited reply.

Frontend56874 completed exit0: scoped_actual_frontend_passed=true, specific cold
boot-voltage control=true, source drift empty. Accepted bootframe3/duplicate5/
splitrail12,52FMA/53DIV. Report `diagnostics-20261011b/report.json`. Cold negative
154s, primary977s. No active frontend job remains. Latest direct quota19:56:01Z
27%/89%,ok.

Root subsequently authorized isolated capacity recovery/multiple-V witness
without repo tool/bench edits (gates pinned). Generated script/bench/fixtures at
`golden/out/m5-solver-capacity-xsim/recovery-candidate-20261011b`. Four cold phases:
rejectdim33/oneV, exactlinear-chain dimension32 recovery31..1V, rejectdim33/twoV,
exactzeroVsource dimension32 recovery32grounded resistors. Check expected perphase
solve-start counts, exactUART lines/checksums, same corruption comparator.
Initial preflight blocked before compiling: old FP report source drift now flags
`tools/verify_solver_m5.py` after root's extraction-only helper extension. Saved
`preflight-fp-stale-report.json` unchanged. Root notified; waiting fresh FP report
path. Generated script takes optional first positional FP report path; requires
real source match and never relaxes stale FP gate. No recovery job yet.

Frontend/solver candidate earlier startupFP checks preceded helper extension.
Frontend end report checks its own source pins but does not recheck FP helper
manifest at end; current unified gate must require a fresh FP characterization
policy report. No existing report rewritten to hide drift.

Final implementation-freeze identities (root gate batch):

```json
{
  "tools/verify_solver_frontend_xsim_m5.py": "3be7456369d165472a36f2b0cc2b4cc48dea933fe0e872428e9eb0e229b213a4",
  "src/testbench/M5SolverFrontendXsim.sv": "11968c655f788c8f6d14f0d7b3393f04454008f3603e0fa4c1941cc3f5096fd0",
  "tools/probe_solver_capacity_xsim_m5.py": "1b3c0b9e9f21eb296ef03a667c2573afedd8e11cd9c431898a3a40efe92eb07b",
  "tools/verify_solver_xsim_m5.py": "304162958b024634144bf9131e0589bb9c5515e578a219924851e2b9a09dc921",
  "tools/tests/test_verify_solver_xsim_m5.py": "e6dc6d0a871ae2916b425df37d269c416703c2c47f1d74f14e7dbe6f15f17954"
}
```

Owned primary/negative PIDs absent: `{"3407865": false, "3410405": false, "3410650": false, "3506415": false, "3506714": false}`. All prior scoped
solver/capacity sessions completed. No descendants/background monitor.
Recovery blocked before compile and has no owned job. Current direct quota
19:58:24Z19%/87%,ok. Future assignment: freshquota, current FP report identity,
run isolated recovery script with that report path; retain preflight-stale report
and original scope reports. Root owns deciding production integration.

## Recovery resumed with fresh FP

Root supplied fresh `golden/out/m5-fp/fresh-helper-20261011b/report.json`; current
helper characterization valid,527FMA/527DIV and4controls. Direct freshquota
19:59:25Z15%/87%,ok. Started bounded recovery session76952:

```
python3 golden/out/m5-solver-capacity-xsim/recovery-candidate-20261011b/run_recovery.py /home/chesium/ee2026_ws/nus-EE2026-metacircuit/golden/out/m5-fp/fresh-helper-20261011b/report.json
```

Compile began(vhdl0). All derivation/bench only under golden/out, repo tool/bench
freeze retained. Timeout180 perstep; source/report identities generated and
fresh FP drift checked before compile. Stop only this owned job if team quota
alert arrives; no new phases after alert. Historical stale preflight preserved.

## Final scoped completion and next assignment

Recovery76952 completed exit0: capacity_recovery_passed=true, fresh FP valid,
no source drift, two exact ER03/0021 rejections(oneV/32nodes andtwoV/31nodes),
no solve perreject; two exact status00 dimension32 recoveries(chain31..1V and
32zero grounded nodes), exactly2 actual solves. Cold observation corruption
specifically detected aftervalid baseline. Primary63s/negative4s. Report:
`golden/out/m5-solver-capacity-xsim/recovery-candidate-20261011b/report.json`.
Derived driver/bench/fixtures remain golden/out only; repo implementation freeze
retained. Historical stale preflight report preserved. Parent notified.

No active owned job, descendant or background monitor remains. All actual UART/
frontend/capacity sessions complete. Last direct quota20:00:43Z12%five-hour/86%weekly,
ok; root owns subsequent60schecks and latched team shutdown below10%/6%.
This role is ending normally after its assigned bounded work. No substantive
work after any guard alert; root ends last if shutdown triggers.

Next self-contained recreation assignment, only if user resumes and delegation
is still authorized: fresh quota; inspect sharedverification tree and root main
handoff before editing. Own the same runner/bench/docs files listed above;
root owns production RTL and acceptance. Review isolated guard proposal SHA
77a637aaf93df02f6adc1dbd50375eeb0fc5d1f08063811300d294597e5ee78b and final candidate
reject/supported/recovery reports. If root integrates the exact candidate into
production, qualify the direct current identity using explicit fresh FP report
`--fp-report golden/out/m5-fp/fresh-helper-20261011b/report.json`, preserve all old
reports and reconcile source/policy pins honestly. Root decides whether another
full current-production frontend run is required (existing scoped frontend report
pins old production SolverBoard, now complete). Do not rerun completed broad
corpora only to recover history. Next remaining numerical work is a conditioning/
accuracy policy or production algorithm work by root; original2e-4 bound and the
3.72% near-singular miss remain unchanged. Broader randomized/general nets,
physical PS/2/board, original-XCI synthesis and full M5 readiness remain explicit
limitations, not implied by scopedpasses.

Final freshquota2026-10-10T20:01:40.777026Z11%five-hour/86%weekly,ok. Reset times
2026-10-11T00:35:03Z/2026-10-17T19:35:03Z. Known recovery runnerPID3540162,
runPGID3541114,xsimk3541294 all absent from/proc at finalinspection. No ownedjob.
