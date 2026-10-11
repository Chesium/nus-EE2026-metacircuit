# Subagent handoff: M5 production frontend invariant observers

Updated: 2026-10-10T14:24:08Z after final native/Docker qualification
State: completed scoped assignment, work ended; fullM5-4 remains incomplete
Author: /root/m5_invariants_resume
Parent: [M5 main handoff](../../m5-verification.md), /root coordinator
No descendants.

## Self-contained assignment and ownership

Workspace `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branchverification,
HEADf894fa8dcb487ff02c8f671e4126cc84cf169363. User authorizes parallel M4/M5 under
codex-usage-guard defaults. Root checks quota every60seconds while children run;
initial fresh guard required on resume. Own NEW files only:
`src/testbench/M5FrontendInvariants.sv`,
`golden/tools/verify_frontend_invariants_m5.py`,
`golden/tools/test_verify_frontend_invariants_m5.py`,
`docs/m5-frontend-invariants.md`, this handoff. No production RTL, frozen bench,
earlier invariant files, shared evidence or plans were changed by this role.
No commits/pushes/unrelated configuration changes.

Task: independently observe production component store/index maps and geometry
at genuine post-init !busy acceptance boundaries, local queue bounds and atomic
frontend voltage-bank commits, preserving temporal assumptions and coverage gaps.
Do not mark allM5-4 complete. Final reports are complete and sent to parent. Next parent step is integrate
scoped evidence while retaining unsupported coverage and source provenance. Future missing scope is
aborted-stage traffic, broader map layouts/last-cell cases, actualCDC/formal/
architectural progress and all-frame safety. Frozen UART bench has no staged
abort stimulus; observers explicitly report abort count0 instead of claiming it.

## Saved work and initial evidence

New bound modules compile against the complete real frontend, excluding vendor
floating-point source as the existing focused RTL script does. Request original
frozen UART bench remains unchanged. Independent map reconstruction uses primary
sprite cells, BCD/unit shadows and geometry, not RTL helper calls, checks real
store/index memories at ready boundaries without hidden extra settle. Packet
model independently predicts bank selector/metadata each sysclock, compares active
node words at packet boundaries, and forbids active-bank writes. Actual flood
queue bound/count observer runs each sysclock at productiondepth1152.

Initial native `golden/out/m5-frontend-invariants/native-initial/summary.json`
passed with2ready checks,12bank-data checks,3commits,5stagednodes,2stale events,
0aborts,26,318,579sysclocks; queue370adds/370pops. Three original specific negative
controls caught. Then added orphan-right geometry and fourth voltage-data negative;
initial report is historical, not final current-instrumentation evidence.
Nine Python acceptance/negative tests passed after final observer/runner changes.

Final commands completed (no further source edits during runs):

```sh
python3 golden/tools/verify_frontend_invariants_m5.py --runtime native --out golden/out/m5-frontend-invariants/native-final
python3 golden/tools/verify_frontend_invariants_m5.py --runtime docker --out golden/out/m5-frontend-invariants/docker-final
python3 -m unittest discover -s golden/tools -p test_verify_frontend_invariants_m5.py -v
```

Native session93751 and Docker13798 both completedexit0. Parent may restore
rejected root address candidate later. Recorded active production source for
these runs is SHA0b32341ce8cd8b9df90c70874bf2a408874cbf2402881f3cb0ce5a7008df644f.
Do not claim current-root match if root later reverts. Runner records immutable
source hashes and rejects source changes during a run. Existing root candidate
QoR/equivalence status is separate; this role establishes no measured FPGA gain.

## Final qualification

Both final reports `ok:true`, with identical observations:2real acceptance
boundaries,12active voltage-data checks,3commits,5stagednodes,2stale events,
0aborts and26,318,579sysclocks. Queue depth1152,370accepted adds/370pops.
Four negatives specifically detected in each runtime: component index-map,
voltage-bank metadata, queue count and committed voltage-data observation.
Native negativeexit1; Docker negativeexit139 with exact expected assertion label.
Normal exits0 and frozen loop errors0. Native Verilator5.046; Docker5.020.
No real RTL inconsistency was observed in this limited stimulus.

Current observer SHA:
`cc9e9aa8814e2afd1e023fd0648864c7d0fe29ea3c976671d729d43489e5bee6`.
Runner SHA:
`6241037c8b03a32e2300667bf126df6c79d62d54ad74a8e0f1cd5bbfacf71feb`.
Their hashes match both final reports. Each report states sources unchanged
through its run and retains the full source hash map. Root may later restore
production source; final reports qualify their captured source identity, not
an untested later root tree. Nine Python tests and `git diff --check` passed.

## Limits and jobs

Atomic observations are at sysclock and packet boundaries under one semantic
packet event per UART line and unique valid nodes. Aborted-stage cancellation was
not stimulated; duplicate/simultaneous packet events are not qualified. Maps
cover boot and wire deletion with3indexed components at2ready boundaries, not
arbitrary components/last-cell transitions. Local queue safety does not establish
FIFO data ordering, all queues, arbitrary non-power-of-two lifetime wraps or
architectural progress. Direct MouseCtl model means actualPS2/CDC unsupported.
No formal proof/global equivalence/all-frame renderer safety claimed.

Owned final native/Docker sessions93751/13798 completedexit0; initial native13930
completedexit0. No owned jobs or descendant agents remain. No user worker/daemon
was killed or changed. This role ended normal scoped work, not quota shutdown.

## Quota

Initial fresh14:15:43.966579Z OK51%five-hour/39%weekly.
Latest direct14:24:08.450340Z OK25%five-hour/35%weekly; resets
2026-10-10T18:59:37Z and2026-10-14T15:27:22Z. Defaults prepare below10%/6%,
hardstopbelow3%/2%; parent owns60second team timer. No quota trigger at this
completion. Final evidence/handoff paths sent to parent; main agent continues
remaining work under its own guard timer.
