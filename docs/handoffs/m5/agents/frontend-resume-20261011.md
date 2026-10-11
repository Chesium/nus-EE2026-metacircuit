# Subagent handoff: M5 resumed frontend observations

State: scoped assignment completed; work ended. Full M5-4 remains incomplete.
Author /root/m5_frontend; parent /root and [main handoff](../../m5-verification.md).
No descendants. Main workspace
`/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branch `verification`,
HEAD `f894fa8dcb487ff02c8f671e4126cc84cf169363`.

## Assignment and ownership

Resume M5-4 restored-source qualification, staged abort traffic and wider real
map boundaries, with independent first-ready observations and specific negatives.
Own `src/testbench/M5FrontendInvariants.sv`, NEW
`src/testbench/M5FrontendSupplemental_test.sv`,
`golden/tools/verify_frontend_invariants_m5.py`, corresponding test and
`docs/m5-frontend-invariants.md`, this separate handoff. No production RTL,
frozen bench/oracle, shared evidence/plan or other role files edited by this role.
No commits/pushes. Preserve prior dirty M4/M5 tree. This scoped work does not
complete all M5-4. Root separately owns production readiness fix and integration.

## Saved work and verification

Original scoped observer/runner reran on restored production SHA
`254c8842d72c6c4801ef015c8c3274687a970c8794f9d09e6d966ced42657a66`:
`golden/out/m5-frontend-invariants/{native,docker}-restored-20261011/summary.json`
both `ok:true`, sessions83821/91198 exited0. 2 ready checks,12 bank checks,3 commits,
5 staged nodes,2 stale events,0 aborts,26,318,579 clocks,370 queue adds/pops and
four original specific negatives caught. These predate new instrumentation.

NEW full-top supplemental uses actual UART pins/default baud and drives exact
accepted background command traffic. It bypasses mouse/controller/guard and
fixed selection crossing; it never writes RAM or shadow arrays directly.
Independent fixture constants check all map words/populated entries at advertised
pre-NBA readiness. Six layouts: empty, all five indexed types/four rotations with
corner cells, horizontal/vertical last-cell partner, deletion, last-origin287
partner286. All fixture values/units are zero. Five explicit partial-stage abort
cases plus current stage replacement check preserved published bank/data/status
against literal10 V/DEADBEEF. Observer now checks every-clock stage lifecycle,
selected synchronous read at stable address and a fresh-clear/quiescent870 clock
local source-derived progress bound. Edits/dirty restarts cancel progress tracking.
Eight specific observer negatives, each requiring its own failure label.

Found real defect on accepted last-origin map; parent fixed production. Corrected
native/Docker pre-fix reports
`{native,docker}-prefixed-boundary-20261011/summary.json` are deliberatelyfalse:
both at 58,792,165ns, first ready busy 0, map286 observed 511 expected 0 while
w_en 1/w_addr 286, synchronous selected read 511. Five earlier fixture layouts and
five abort cases passed first. All six then-present negatives caught. Source stable
through each run. Historical initial Docker exploratory fixture failure was an
old Verilator force-expression reevaluation discrepancy; explicit force at each
command plus exact accepted-command assertions resolved it. Do not confuse that
stimulus issue with the subsequent matching real RTL boundary defect.

Root's accepted production busy fix adds map/store registered write strobes and
synchronous read drain, source SHA
`4e62e63dd68ba9e946006a86129d48c39dd7570710a73451f0fd1fba68c2bb16`.
Final commands:

```sh
python3 golden/tools/verify_frontend_invariants_m5.py --runtime native --bench supplemental --out golden/out/m5-frontend-invariants/native-fixed-supplemental-20261011
python3 golden/tools/verify_frontend_invariants_m5.py --runtime docker --bench supplemental --out golden/out/m5-frontend-invariants/docker-fixed-supplemental-20261011
python3 golden/tools/verify_frontend_invariants_m5.py --runtime native --out golden/out/m5-frontend-invariants/native-fixed-frozen-20261011
python3 golden/tools/verify_frontend_invariants_m5.py --runtime docker --out golden/out/m5-frontend-invariants/docker-fixed-frozen-20261011
python3 -m unittest discover -s golden/tools -p test_verify_frontend_invariants_m5.py -v
```

Native/Docker supplemental sessions 21041/4680 both finished exit0, `ok:true` and all 8
negatives caught; sources unchanged. Identical 7 ready checks,20 bank checks,2 commits,
8 staged nodes,2 stale events,6 aborts,6 layouts/5 explicit abort cases,
5,879,221 clocks,72 queue adds/pops,6 fresh quiescent rebuilds max 582 cycles<=870,
7 selected reads. Native frozen 78541 exit0 `ok:true` all 8 negatives caught; Docker 89416
finished exit0, `ok:true` with all 8 negatives caught and sources unchanged. Frozen normal
both:2 ready,12 bankchecks,3 commits,5 stagednodes,2 stale,0 aborts,
26,318,579 clocks,370 queueadds/pops;1 quiescent rebuild max 579/870,1 selected read.
15 Python acceptance/negative tests pass; git diff --check passes.

Minimal +m5-boundary-only fixed compiled native/Docker witnesses both exit0,
logs `minimal-boundary.log` in respective fixed-supplemental directories.
First-ready map/read both 0; 1871 clocks, no UART commits/queue exercise. This fast
witness is distinct from full supplemental acceptance and cannot replace it.

Final observer SHA
`6b480737bddaae8e19e9cfd4ba74e71a60cc55927a663df3e7a8e1f7ac111ccd`;
supplemental SHA
`6cbf29c8dde80a363e335866b02b0054b2f409923403be6da40c5ee62abc8538`;
runner SHA`bc7e2dc8895ed10065e1f7330369a73afb440275070d0682179cf8f8e2aa526d`.
Frozen bench unchanged SHA
`2aee8f0593ced1dfe1f89af2d1a62587166ae648dc292e2108b83e070003bb1c`.

## Remaining scope and next step

Root integrates final scoped evidence while retaining full M5-4 incompleteness.
Future frontend work: arbitrary mid-rebuild dirty restart/global progress,
all-frame safety/formal/global equivalence, maximum capacity layouts, general
nonzero values/units, arbitrary stalled/overlapping/duplicate semantic packets,
physical canvas RAM equivalence and actual PS2/CDC. Fixed selection is a test
fixture; arbitrary UI selection transitions remain unqualified. Queue observation
does not prove FIFO order, all queues or arbitrary lifetime wrapping. Additional
fixtures bypass UI guard; do not claim UI reachability beyond initial visible canvas.
Root runs independent frozen M2/M3 exact frame/UART/QoR requirements separately.

## Quota and jobs

Fresh initial 2026-10-10T19:06:12Z OK 98% five-hour/32% weekly.
Latest direct 19:16:52.550768Z OK 53%/25%, reset 2026-10-11T00:05:41Z and
2026-10-14T15:27:22Z. Defaults prepare<10%/<6%,stop<3%/<2%; parent owns
60 second team timer. No quota trigger. No descendants. All owned native/Docker restored, exploratory, final supplemental, final frozen
and minimal-boundary jobs finished. No owned jobs remain. Do not kill user
workers/daemon; root authorized existing work only. No permanent termination
claimed. Final handoff and complete evidence sent to parent; parent owns integration.

## Follow-up phase: isolated shadow candidate (completed)

Parent explicitly requested the same observers on isolated candidate
`golden/out/m5-shadow-functional-source/src/design`, top SHA
`93bc76d3019d3d1e5a8949a00e32d217d934b4ece5289ec26e1421b7a2a001fb`;
no source edits. Fresh quota 19:18:24.190310Z OK 48% five-hour/24% weekly before phase.
Added explicit runner `--design-root` with independent read-only Docker `/design`
mount and selected-directory/source-hash provenance. Baseline final reports retain
previous runnerSHA bc7e2d...; new reports pin updated runner independently.
Fifteen existing fail-closed parser controls pass after path-option change.

Completed candidate directories in `golden/out/m5-frontend-invariants`:
- native-shadow-supplemental-20261011, session 78434 (exit0).
- docker-shadow-supplemental-20261011, session 42679 (exit0).
- native-shadow-frozen-20261011, session 72384 (exit0).
- docker-shadow-frozen-20261011, session 59909 (exit0).

All four reports `ok:true`, source stability true and all eight specific negatives
caught. Saved hashes verified against every live selected candidate/bench source.
Normal observations and progress match the readiness-fixed baseline exactly:
frozen 2 ready/3 commits/0 aborts/26,318,579 clocks, 1 local rebuild max579;
supplemental 7 ready/2 commits/6 aborts/5,879,221 clocks, 6 local rebuilds max582. No production,
observer or supplemental source mutation after launches. Root runs independent
cold corpus/QoR/solver work; full M5 remains incomplete. No owned jobs or descendants remain; role completed its authorized scopes.
Latest direct quota 2026-10-10T19:22:00.531197Z OK 36% five-hour/22% weekly.
No quota trigger; source/runner read-back verification and `git diff --check` pass.
Final current runner SHA
`6c306d871539158a52bcfeba6adf234d017efac7930fe06218d12f2c19741793`.
Parent notified with this document and final report paths; parent owns integration.
