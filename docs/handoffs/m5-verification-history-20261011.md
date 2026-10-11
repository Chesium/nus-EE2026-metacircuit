# Active M5 resume — 2026-10-11 Singapore

State: active; M4 complete, M5 unfinished. Fresh live quota 2026-10-10T19:06:00Z
99% five-hour /32% weekly; resets 2026-10-11T00:05:41Z /2026-10-14T15:27:22Z.
Default strict prepare <10%/<6%, stop <3%/<2%; root owns60second team cadence.
Branch verification HEAD f894fa8dcb487ff02c8f671e4126cc84cf169363; existing dirty
M4/M5 changes preserved. Frozen contract verified254 entries with accepted asset
provenance changes. No previous simulation/Vivado jobs active on initial inspection.
Root owns gate/policy/evidence/plan and production fixes after coordination.

| New role | Separate handoff | Ownership | State/recreation |
|---|---|---|---|
| /root/m5_frontend | [Frontend resume](m5/agents/frontend-resume-20261011.md) | frontend observer/runner/tests, supplemental stimulus | running; restored-source, staged-abort and broader maps |
| /root/m5_solver | [Solver resume](m5/agents/solver-resume-20261011.md) | actual-IP solver fixtures/XSim and new frontend loop | running; >2nodes,units,capacity,real frontend/defaultbaud |
| /root/m5_qor | [QoR resume](m5/agents/qor-resume-20261011.md) | Vivado runner/docs, isolated candidate/proof | running; justified guard area optimization and immutable measurement |

## Root checkpoint (current resume)

A-008 production top fix SHA4e62e63dd68ba9e946006a86129d48c39dd7570710a73451f0fd1fba68c2bb16
now keeps map/store writes and synchronous read drain busy. Native/Docker focused
first-ready witnesses and broader supplemental maps/staged cancellation pass;
full frontend agent reports pending final freeze. Root nativeM3 session93708,
DockerM3 42746; all-fourM2 wrappers native8912/Docker51888 running. Captures under
`golden/out/m5-a008/{m2,m3}-{native,docker}-20261011`; wrapper job.json records exact
owned childPGID. No optimization applied to production.

Root isolated full design candidate at golden/out/m5-shadow-functional-source,
top93bc76d3019d3d1e5a8949a00e32d217d934b4ece5289ec26e1421b7a2a001fb;
only top differs versus corrected production. Main golden oracle/runners copied
byte-identically into candidate/golden (oracle-snapshot.json), native fullM3
regression active31612 under golden/out/m5-shadow-functional/m3-native-20261011. Native/Docker43-frame seed12 cold locksteps passed (sessions83466/71336) under golden/out/m5-shadow-functional/wire-native-20261011.
QoR agent independent structural/temporal proof passes; original candidate synth
reduces24117LUT to10505, FF13677 to4302, WNS-5.176 to-4.388. Corrected-baseline
matched measurement pair and routed candidate remain pending. Invalid initial
selector candidate and superseded original route retained/rejected.

Root gate now preflights actualQoR before expensive corpus, compares tool/settings/
source-IP inventories/constraints/clocks, checks adapterconfig, pins seeds1,7,2026,11,12
64ops/gen2 and command3600s/total21600s executionlimits.12 gate corruption/budget
controls pass. Explicit synthresource-comparison mode requires retained matched
real failedBasys3 routecapacity witness; candidate still needs complete cleanroute.
No fullreadiness claimed. docs/m5-decisions.md records A-008 and near-singular
actualsolver physicalaccuracyfailure(3.72%); no tolerance widening.

Owned monitor57306 writes sanitized /tmp/metacircuit-m5-usage-20261011.json every45s.
Latest observed19:16:48Z54%fivehour25%weekly, healthy; thresholds unchanged.

Three direct children, no descendants. Frontend original/candidate scope completed;
/root/m5_frontend reused for new coverage-policy task with separate
[coverage handoff](m5/agents/coverage-resume-20261011.md), ownership NEW
verify_coverage_m5.py/policy/tests/docs only. Root unitgate12controls pass;
finalfast gates native50873/Docker22174 running. All-fourM2native/Docker passed
298frames61checkpoints each on A008 fixedsource. Root direct19:23:02Z33%/22%;
monitor19:25:58Z23%/20%, healthy. Actualgeneral solver59solves300lines passes;
near-singular3.72% error and augmented33dimension capacityrejection mismatch
retained separately, no solver source/oracle change. Final actualfrontend primary/
negative still active. Final current75-input QoR routepair active under agent docs.
No production optimization adopted while full readiness remains unqualified. All assignments require separate
handoffs and freeze/document/end on quota alert. Historical documents below retain
prior results and recreations; do not rerun completed foundational roles.

---

# Task handoff: M5 verification and refactor readiness

Updated: 2026-10-10T14:43:45.996964+00:00
State: paused for quota; verified safe checkpoint, M4 complete, M5 incomplete

## Objective and constraints

User authorized resuming M4 from its handoff, then M5 with useful parallel agents,
under codex-usage-guard defaults. M4 was already complete in declared settled
frontend scope. Continue M5-3..M5-8/INF-4, preserving accepted oracle, visual
payloads, exact specified frontend timing and constraints. No physical board.
No commits/pushes or unrelated configuration changes. Full readiness is not
claimed from a scoped pass. [Earlier coordinating history](m5-verification-history-20261010.md)
and [M4 handoff](m4-verification.md) preserve prior work and initial M5 foundations.

## Resume here

Obtain fresh live quota, inspect actual trees/jobs and read all linked current
agent documents before implementation. The accepted frontend helper source is
restored to SHA254c8842d72c6c4801ef015c8c3274687a970c8794f9d09e6d966ced42657a66.
Both address candidates failed measured objectives; do not reinstate them.
Production FMA wrapper now correctly has3exception bits and its stand-in port
is aligned. Actual-IP direct production XSim passes; stand-in arithmetic/latency
still differs from configured hardware and cannot qualify solver changes.

Next concrete work:

1. Inspect final native/Docker gate reports listed below. Verify trusted contract:
   `python3 golden/tools/freeze_contract.py verify --expected-contract-sha256 475a48362f0f353104abfde654c25f7bdc60acc266c7a774ca6b256d315b540e`.
2. Rerun production frontend observers on the restored source in fresh directories:
   `python3 golden/tools/verify_frontend_invariants_m5.py --runtime native --out golden/out/m5-frontend-invariants/NEW-native`, then Docker.
   Existing observer reports passed on rejected addresscandidate1; retain their
   exact historical provenance. Add staged-abort stimulus and broader production
   map layouts, rather than treating zero exercised cases as passes.
3. Extend actual SolverBoard/XSim from1/2node analytic circuits to larger/general
   circuits, unit variants, capacity/boundaries and the real frontend link. Read
   solver-xsim/FP handoffs. Pin real generated products and configured-IP revision
   evidence; original XCIrev6 versus existing productsrev21 remains explicit.
4. Audit immutable Vivado hierarchy/critical-path reports to choose a justified
   optimization, and specify clock/I/O/CDC assumptions without weakening accepted
   constraints. Baseline synthesis24117LUT exceeds20800device capacity; actual
   placement fails. Both attempted address arithmetic rewrites worsened area/WNS.
   A promising future hypothesis is proving reserved shadow-cell high bits always
   zero in accepted scope before narrowing storage/read cones; this has NOT been
   implemented, proven or measured and is not authorization to assume it true.
5. Complete continuous/global safety, architectural progress/formal assumptions,
   line/toggle coverage requirements/exclusions, fresh full corpus and mandatory
   FPGA/QoR gate. Full gate currently has explicit unsupported requirements and
   returnsnonzero. Do not mark M5 complete from the existing partial evidence.

## Workspace and saved changes

- Main `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`: verification,
  HEADf894fa8dcb487ff02c8f671e4126cc84cf169363, dirty/uncommitted M4+M5 work.
- Harness `/home/chesium/ee2026_ws/framescope`: m1-harness,
  HEADde04a24f8212eedf218040dcc923daff2d7b857b, prior dirty M4 work preserved;
  this resume did not change harness source.
- Historical framescope-m4-{seed,coverage,session} worktrees preserved.
- New root files: tools/acceptance_m5.py, tools/m5_acceptance_policy.json,
  tools/tests/test_acceptance_m5.py, .github/workflows/verification.yml,
  docs/m5-acceptance.md; adapter timestamp support/tests and docs extended;
  evidence/plan/handoff updated. Frozen contract/reference bytes unchanged.
- Root production change this resume: fpo_fma.v tuser width4->3, actual vendor
  port width; SHA9c1daa50bb18196ff22615da92bcf8a3b0697647e821db45376d735948f05ec7.
  Test stand-in FMA port also3bits. GlobalRender_top retains original M4 changes
  only; candidate address helper modifications reverted completely.
- Current asset changes are extractor provenance metadata only; payload equality
  checked before each refresh. Frozen-contract verifier allows and reports them.
- All simulation/QoR outputs under ignored golden/out are retained for audit.
  Baseline/candidate Vivado reports include immutable75input snapshots; default
  parse validates savedinputs, explicit --check-working-tree validates candidate.

## Completed and verified

[Machine-readable M5 evidence](../m5-verification.json) records scope precisely.
M5-1/2 are checked in the plan for accepted frontend contract/settled adapters.

- Trusted254entry contract verifies; immutable expected behavior maintained.
- Adapter qualifies18M2/M3captures/206checkpoints plus8M4captures/158checkpoints.
  Four M4 core runtime pairs equal; exact per-capture times retained (t_ps/t_ms),
  absolute randomized cold-start equality across runtimes is not claimed.
- Controller/guard invariants native+Docker pass delays1/3/9:42settled boundaries,
 16exact commits/21read-replies perrun, genuine read/write stalls on bothinterfaces,
 four specific negatives.14parser/path controls pass. Bounds are directed test
 watchdogs, not architecture/formal guarantees.
- Frontend observers native+Docker passed on candidate1:2genuine map-ready
 boundaries,3reply commits/5stagednodes/2stale events,12active-data checks,
 370queue pushes/pops withbounds/conservation,26318579clock observations and
 four specific negatives. Zero staged aborts and limited map layouts are gaps.
- Generated extraction320cases withrandom response stalls, provisional36solver
 analytic circuits and physically connected frontend/SolverBoard boot/edit pass;
 Verilator FP stand-ins remain unqualified.
- Actual vendor XSim527FMA+527DIV cases pass bitexactdata/flags and16/28latency,
 valid bubbles/back-to-back inputs,4specific negatives. All70modelparameters
 match original XCI; revision21products versusrevision6XCI still flagged.
- Actual production SolverBoard direct XSim:38solves/127UARTreply lines,
 244FMA/173DIV results with16/28latency,checksum error/recovery andsingularstatus05
 withnegative infinity pass; coldresponse corruption detected. No source override.
- Real Vivado frontend synthesis complete withrealVHDLMouseCtl:
 24117LUT/13677FF/10BRAM/0DSP,WNS-5.176ns,WHS0.045ns. Actual route attempt
 failsUTLZ-1 (postopt22138LUT>20800). Missing clock/I/O assumptions andCDC/DRC
 policy remain unqualified; timing_clean=false, no routed acceptance.
- Candidate1 compare/subtract:24471LUT,WNS-6.262; candidate2reciprocal:
 25055LUT,WNS-5.696. Both fail declared gain/resource/WNS objective. All512
 helper inputs (including224invalid) matched original onbothruntimes; candidate1
 actual frontend smoke78frames/29checkpoints perruntime passed. No accepted gain.
- Native unchanged-baseline gate passed64functionalbins and re-ran independent
 M2/M3comparators. Saved baseline mode now correctly rejects changed FMA source;
 candidates require fresh evidence, not reuse of old source-identity pass.
- Gate full missing-QoR/objective negative returned1 before expensive batch.
 Seven gate controls include missing/invalid JSON evenwhenprocess exits0.
 Full readiness remains incomplete; manualCI workflow hasnotbeenrun onGitHub.
- Docker gate encountered one Verilator locked-thread-pool internal builderror;
 exacttrace retained. Separate8seed tests and full135testretry passed(7opt-in
 skips). Initial finalnative gate caught an interim root test indentation error;
 fixed7control suite passes, fresh finalnative/Docker gates completedexit0 with
allchecks passing. Their reports contain actualtestcounts. Current gate preflight
full missingreports/optimizationobjective negative also fails asrequired.

## Current jobs and remaining

Root final gate sessions8204(native)/89327(Docker) completedexit0; finalfast
reports golden/out/m5-acceptance/final-fast-{native,docker}-v2/summary.json both
ok=true/ready=false. No other simulation/Vivado jobs remain from agents.
Quota monitor session90332/PID2482329 checked every45seconds, retained sanitized
/tmp/metacircuit-m5-usage-20261010.json and self-ended on document result at
14:40:11.062715Z. Root freshdirect check observed9%/33% at14:41:28.124740Z.
All implementation/tests were alreadyfinished before this firstdocument result;
subsequent actions were handoff inspection/status/aggregation only. Monitor was
conservative active-subagents=3 after teamcompletion; direct checks usedactual0.
Session90332 exit0 and absentPID2482329 verified. Finalgate sessions8204/89327
finishedexit0. Allchildjobsfinished, no activeowned workers/monitor remain.
No userdaemon/session/process targeted; no permanent agenttermination claimed.

M5-3/4/5/6/7/8 andINF-4 remain incomplete in full declared scope. No final full
cold corpus/regression/QoR acceptance was run; missingmandatoryobjective/reports
fail before expensive batch. M5-4 old/new formal/equivalence beyond finitehelper
proof and specifiedglobal progress notdone. PS/2physicalCDC andboardtesting are
excluded. Original-IP synthesis/provenance,actualfrontendsolvertransport,
32node/generalcapacity,abortedstagedreply,widerproductionmap qualification and
measuredacceptedoptimization remain concretework.

## Team manifest and recreation assignments

Root hadthree directchildren, each reused for separate assignments; no nested
agents. All scoped turns completed, handoffs saved andinspected; finalcollaboration
inventory verified allthree childrencompleted, no nesteddescendants. Rootendslast.
Recreate only unfinished scopes, using currentauthorizedmodels/settings.

| Role / historicalagent | Handoff | Ownership | State / unfinished recreation |
|---|---|---|---|
| m5_vivado_resume | [Vivado](m5/agents/vivado-resume.md) | vivado_qor runner/Tcl/tests/doc | complete; new measured optimization/constraints only |
| m5_vivado_resume reused | [Reciprocal](m5/agents/vivado-reciprocal.md) | isolatedcandidate2measurement | complete rejected experiment; do not reinstate |
| m5_invariants_resume | [Controller/guard](m5/agents/invariants-resume.md) | invariantbench/runner/tests/doc | scoped complete; global/formal scope unfinished |
| m5_invariants_resume reused | [Address](m5/agents/address-optimization.md) | finiteproofbench/runner/tests | complete finiteproof; no global equivalence/gain |
| m5_invariants_resume reused | [Frontend](m5/agents/frontend-invariants.md) | frontendobserver/runner/tests/doc | scoped complete; restoredsource+abort/broaderlayout followup |
| m5_solver | [Solver](m5/agents/solver-qualification.md) | actualextraction/analyticUART/bootedit benches | scoped complete; generalcircuits/capacity/units unfinished |
| m5_solver reused | [FP](m5/agents/fp-qualification.md) | actualFPcharacterization/bench/tests/doc | complete rev21characterization; originalXCI identity unfinished |
| m5_solver reused | [Actualpipeline](m5/agents/solver-xsim.md) | actualSolverBoardXSimrunner/bench/tests | scoped complete; actualfrontend/defaultbaud/capacity unfinished |

Earlier foundations complete: [contract](m5/agents/contract.md),
[adapter](m5/agents/adapter.md), [initial Vivado](m5/agents/vivado.md).
Each current child document includes self-contained ownership, exactcommands,
results and limitations. Avoid concurrentRTL/oracle/tool writes. Coordinator
replacement owns gate/policy/plan/evidence and RTL fixes; assign futurefrontend
observer,actualsolver/IP andmeasuredVivado roles separately withguardhandoffs.

## Quota policy

Fresh startup2026-10-10T13:59:42Z100%five-hour/47%weekly. Latestdirect check
14:43:46Z6%five-hour/32%weekly, document/exit10. Shutdown remainslatched
from9%/33%; no substantive work resumed. Resets2026-10-10T18:59:37Z and
2026-10-14T15:27:22Z. Defaultstrictpreparebelow10%/6%; stopbelow3%/2%.
Active team/documentation cadence60seconds; solo5minutes. Earliest monitor document at2026-10-10T14:40:11.062715Z; root freshdirect
shutdown observation2026-10-10T14:41:28.124740Z: live document/exit10,
five-hour9% remaining (<10% prepare), weekly33%. All substantive work frozen.
All three owned children already completed; their separate documents were
inspected and inventory verified. No descendants; root aggregates and ends last.
No permanent termination is claimed. No implementation/test/delegation after
trigger; only handoff/status/owned-monitor cleanup.
Nextresume requires userinstruction and freshlivequota; resetalone isnotresume.
