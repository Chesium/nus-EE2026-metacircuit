# M5 verification handoff

Updated: 2026-10-11T01:26:38.288551+00:00
State: paused for quota; M5 incomplete; root ends last

## Objective and user constraints

Complete M5 in docs/verification-plan.md, preserving the frozen frontend contract
and existing dirty work, using parallel subagents and codex-usage-guard defaults.
No commit or push requested. Prior checkpoint and five older child handoffs are
linked in [resume history](m5-verification-history-20261010c-start.md).
[This run's progress history](m5-verification-history-20261010c-progress.md)
preserves commands and intermediate checkpoints. Do not overwrite historical
reports or count interrupted runs as passing.

## Resume here

Fresh live quota check first, then inspect actual working trees and all six child
handoffs below. All owned children and root jobs ended; no work resumes from a
quota reset alone. Preserve historical outputs and use new paths.

1. Complete only unfinished cold native v2 seeds7/2026/11/12 with64operations on
   the unchanged reviewed shadow source. Seed1 already passes713frames/65checks.
   Four interrupted captures have no completed comparison/verdict; rerun cold,
   do not inherit initialized RAM or claim the split driver passed all five.
2. Decide composition/adoption of the panel-only coord_len correction using its
   actual-source proof, matched routed objective and complete native/Docker M2
   (298frames/61checks each). It remains isolated with old SolverBoard source;
   do not copy strengthened XDC or rejected arithmetic into production.
3. Record/qualify the separate epoch alias correction: isolated ledgers pass,
   but local synthesis adds813LUT/578FF. Full frontend/cold reset/epoch/proof and
   composed full-top route remain unrun. Generic FIFO lifetime defect stays open.
4. Broaden remaining source-correct coverage, continuous/formal/progress scope,
   related/asynchronous clocks, reset and external IO/CDC, real original-XCI
   synthesis provenance and near-singular accuracy. Full readiness must fail gaps.

## Workspace and saved work

- Main: /home/chesium/ee2026_ws/nus-EE2026-metacircuit, branch verification,
  HEAD f894fa8dcb487ff02c8f671e4126cc84cf169363. All changes uncommitted.
- Sibling /home/chesium/ee2026_ws/framescope: de04a24, pre-existing dirty harness
  preserved; no edits or repin this run. /home/chesium/ee2026_ws/pycircuit initially
  clean and untouched. Main simpyhls untouched.
- Production SolverBoard now exactly qualified candidate SHA
  77a637aaf93df02f6adc1dbd50375eeb0fc5d1f08063811300d294597e5ee78b;
  prior clean file760ab046... . Frozen frontend assets/oracle/constraints unchanged.
- Production top4e62e63..., FMA9c1daa... remain unchanged from startup.
  Reviewed isolated shadow-functional-source top93bc76... remains separate.
- Root new tools/verify_solver_capacity_m5.py and fixture tests; gate now requires
  capacity/recovery and frontend domains. Policy SHA
  5c94455e6b5ffe9ad1a53a00d55e0a8e46ab9cebed2f7e72092c3a91e50fc6af.
  Old six observer suite files were not changed.

## Completed and verified

See docs/m5-verification.json and separate child handoffs for exact artifacts.

- Production actual-IP dimension33: exact ER03/0021, no solve, cold corruption
  detected. Supported59 solves/300UART replies pass; byte equal prior candidate.
- Portable direct-production capacity regression passes two dimension33 rejects
  (one/two sources), two exact dimension32 recoveries, both cold corruption
  controls, no overrides/drift. FP report fresh-helper-20261011b stays source/tool/
  library valid with527FMA/527DIV,16/28cycles and four controls.
- Separate native/Docker frontend domains:144components,41keyboard events/all
  six suffixes,8selection transitions, bounded restart/clear backpressure;
  seven specific controls and nine parser controls pass. Zero UART/queue scope.
- Both final current-pinned fast gates pass; native production-guard-native-
  20261010c and Docker final-pinned-docker-20261010c. Docker135tests/7optional
  skips, unchanged harness. Historical ThreadPool cause remains unknown.
- Full missing-QoR/objective negative rejects before expensive regressions.
  Gate15controls and capacity3independent fixture checks pass.
- Cold shadow v2seed1x64 passes713frames/65checkpoints in original driver case0;
  seeded unique initialization recorded. Remaining four seeds unfinished.
- Isolated coord_len default passes actual-source SAT/control and latch inventory,
  removes internal latch/no-clock/unconstrained endpoints; routed setup improves
  -1.816 to-1.585ns, hold+0.022;10250LUT/4159FF/9.5BRAM. Scoped objective passes;
  setup/external IO/CDC full readiness false. Both pair proposals rejected.
- Actual wrapper ledgers reproduce1152adds/pops after reset/clear, but no arbitrary
  or cold pre-clear proof. Real65535reset-clock epoch alias returns stale region1
  for blank input on both runtimes. Isolated validity fix passes same ledgers and
  returns0; standalone store synth costs+813LUT/+578FF, BRAM unchanged. Not integrated.

## In progress and owned jobs

Root jobs; IDs are historical until checked against command/path and live lineage:

| Operation | Session / process group | Output / next step |
|---|---|---|
| actual production frontend |98545; runner65171, runPGID67874 | golden/out/m5-solver-frontend-xsim/production-capacity-guard-20261010c; await primary plus cold negative and final source drift |
| original cold corpus seeds1/7 |1094; driver59224, workPGID59226 | golden/out/m5-shadow-seed64-native-20261010c; case0passed, case1seed7active |
| stop original after seed7 |63224 | -driver/stop_after_seed7.py verifies owned59226command/cwd then SIGTERM after case1result; record split-stop.json; partial driver not five-seed PASS |
| independent seed2026 |55549; workPGID133730 | golden/out/m5-shadow-parallel-seed2026-20261010c + -driver |
| independent seed11 |92415; workPGID133729 | golden/out/m5-shadow-parallel-seed11-20261010c + -driver |
| independent seed12 |76388; workPGID133726 | golden/out/m5-shadow-parallel-seed12-20261010c + -driver |
| quota monitor |85779 | golden/out/m5-quota-20261010c/monitor.py,40second checks; observe output/state, not an automatic shutdown; update active-count.txt and stop monitor last |

Independent corpus jobs budget1800s each. Original driver budget3600s but watcher
stops after second case to avoid duplicate parallel seeds. Aggregate only actual
completed individual cases with matching seed/input/source/runtime/initialization.
Do not invent an overall runner PASS after an intentional split/SIGTERM.
Native fast gate58584 and all root capacity jobs ended normally.
Child-owned jobs and cleanup identities are in their documents below.

## Subagent handoffs and recreation manifest

Three direct children, roles reused for separate assignments; no descendants.

| Role / agent | Handoff | Ownership | State / dependencies / recreate |
|---|---|---|---|
| gate /root/m5_gate_recovery | [gate](m5/agents/gate-recovery-20261010c.md) | outputs/docs/m5-acceptance.md | completed gate; no recreation |
| FIFO same child | [FIFO](m5/agents/fifo-bound-20261010c.md) | isolated wrapper/candidate/proof/synth outputs | scoped complete; child completed with no owned jobs; broader proof/QoR/integration unfinished |
| QoR /root/m5_qor_critical | [QoR](m5/agents/qor-critical-20261010c.md) | isolated proof/QoR roots/docs/m5-vivado.md | completed scoped proposals; no rerun |
| latch regression same child | [latch](m5/agents/latch-regression-20261010c.md) | new panel-only functional root/M2 outputs | completed both298frame/61check corpora; child stopped; no rerun |
| domains /root/m5_coverage_expand | [domains](m5/agents/coverage-expand-20261010c.md) | new bench/runner/tests/doc | completed native/Docker; no rerun |
| marginal coverage same child | [coverage](m5/agents/coverage-corpus-20261010c.md) | output artifacts/docs/m5-coverage.md | completed native182/17 and Docker11/2; child stopped; broader bins remain |

Each child handoff contains a self-contained recreation assignment and exact
ownership. Root owns production, shared gate/policy, evidence and verification
plan. Old IDs are not guaranteed live on future resume. Recreate unfinished
roles only after fresh quota and actual-state inspection.

Team shutdown begun: 2026-10-11T01:32:55.396563Z, document/exit10,8%five-hour/71%weekly. All new substantive work frozen; owned descendants checkpointing, root ends last.

## Risks and decisions still needed

M5 remains incomplete: broader coverage/formal/progress/stall scope, fully
qualified related/asynchronous clocks and external IO/reset/CDC, real original
XCI synthesis provenance and near-singular numerical accuracy. Generic FIFO
reset-free defect is retained; integrated post-clear bound is scoped only.
Epoch fix and latch improvement remain isolated; production adoption requires
separate current-source regression/measurement decisions. No physical board.

## Quota policy

Last observed live check: 2026-10-11T01:26:08.639985+00:00; five-hour 28%, weekly 74%.
Resets2026-10-11T06:08:23Z /2026-10-17T19:35:03Z. Strict defaults: document
five-hour<10% OR weekly<6%; stop five-hour<3% OR weekly<2%. Running-team/documentation
checks at most60seconds; monitor uses40seconds. Document threshold latches team
shutdown, descendants before parents; root ends last. No stop trigger yet.
Fresh live check is mandatory before substantive future work.

## Safe checkpoint: production frontend primary and native coverage
Production frontend primary passed unchanged at frame3boot10V, frame5duplicate10V, frame12splitrail10V/0V; final verdict awaits cold negative and source-drift check. Current negative owns a fresh process group; old primaryPGID must not be blindly reused. Bounded native candidate coverage passed182coldframes/17checkpoints,28/64functional bins(+20over prior8), source-correct merge integritytrue/readinessfalse. Native gains77branch/481line/3623toggle points. Docker11frame fallback still pending; no fresh Docker marginal witness claimed yet. Gate/FIFO child completed normally, no owned jobs; other two children remain active.

## Final production/coverage checkpoint01:31UTC
Current production defaultbaud frontend98545 report passes final scoped_actual_frontend_passedtrue, coldcontrol and no source drift. It completed original stimulus/watchdogs unchanged; no source override. All root actual-IP jobs ended. Marginal coverage child completed both native182/17 and directedDocker11/2 coldchecks; final6report integrity audittrue/readinessfalse, native28/64bins,Docker12/64bins. Eligible/excluded sets unchanged. Earlier slow182frameDocker retry was intentionally interrupted and not promoted. All latch M2 and coverage jobs have now completed; root coldcorpus jobs were stopped for quota. Quota13%five-hour/72%weekly at01:31:34Z; prepare for ordered shutdown below10%/6%.

Quota shutdown is latched. Root is stopping unfinished owned corpus groups and watcher; no new implementation/tests or broad waits. Both latch M2 corpora completed before child observed shutdown; root will inspect saved reports/handoffs.

## Authoritative shutdown checkpoint

Team shutdown latched2026-10-11T01:32:55.396563Z at8%five-hour/71%weekly.
No implementation/tests/new phases after that trigger. All three direct children
verified completed by collaboration.list_agents; no descendants. Six separate
handoffs inspected (gate, FIFO, QoR, latch M2, domains, coverage corpus).

Both latch M2 drivers completed naturally before shutdown: native353.205s,
Docker426.318s,298frames/61checks each, zero pixel differences and preserved
oracle/source/harness/simpyhls/initialization hashes. Aggregate report
`golden/out/m5-latch-m2-20261010c/summary.json` and child cleanup.json inspected.
The correction remains isolated; production panel was not changed.

Root corpus groups59226/133730/133729/133726 receivedSIGTERM only after unique
command/cwd/group identity checks. Each group verified empty and each wrapper
ended with saved resultreturncode-15. First driver1410.670s; independent three
803.963/803.951/803.982s. Only completed seed1 result qualifies; seed7 andthree
parallel cases retain partial dumps/logs without complete reports. Split watcher
63224 ended143; quota monitor85779 self-ended atDOCUMENT. Actual frontend98545
and all capacity/fast-gate jobs ended normally. No owned jobs or containers remain.
Cleanup evidence: `golden/out/m5-quota-cleanup-20261010c.json`. No user daemon,
unrelated process/container or session targeted; no permanent termination claim.

All owned descendants stopped: yes, collaboration.list_agents confirmed all
three completed; each reports no descendants/jobs. Root stops last after this
aggregation. Last successful live check2026-10-11T01:34:01.364487Z:
4%five-hour/70%weekly,DOCUMENT/exit10. Resets06:08:23Z /Oct17T19:35:03Z;
default thresholds unchanged. Earlier running-job table is historical; all its
jobs are now stopped/completed as recorded here. No automatic resume.
