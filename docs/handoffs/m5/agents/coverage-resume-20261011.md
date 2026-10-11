# Subagent handoff: M5 coverage policy

State: documented and work ended after latched quota shutdown; /root/m5_frontend reused by
/root for coverage. Parent [main handoff](../../m5-verification.md). No descendants.
Workspace /home/chesium/ee2026_ws/nus-EE2026-metacircuit, verification branch,
HEAD f894fa8dcb487ff02c8f671e4126cc84cf169363; preserve all existing dirty work.
Own NEW tools/verify_coverage_m5.py, tools/m5_coverage_policy.json,
tools/tests/test_verify_coverage_m5.py, docs/m5-coverage.md and this handoff only.
No production, oracle, harness, shared gate/evidence or earlier frontend edits.

Fresh startup19:23:21Z quota31%/22%; latest direct19:29:28.609947Z9%/18% DOCUMENT,
resets2026-10-11T00:05:41Z/2026-10-14T15:27:22Z. Default prepare<10%/<6%,
stop<3%/<2%; root owns60secondtimer. No descendants. DOCUMENT trigger latched team shutdown; all substantive work frozen.

Tool/policy implemented: pinned accepted FS11 raw parser, source/runtime/tool,
both artifact splits, recomputed summaries and successful enclosing simulation
record checked. Complete uncapped per-module/type gap/exclusion counts; full
readiness requires native+Docker, zero eligible gaps and reviewed input scopes.
Requirements explicitly unreviewed; only harness/stub exclusions allowed with
reasons. --audit-only returns0 for valid evidence while readyfalse remains.
Historical source requires explicit source-root, never qualifies changed current.

Retained original native+Docker audit exit0, oktrue/readyfalse:
golden/out/m5-coverage/retained-original-audit/summary.json. Source root trusted
frozen golden/verification/contracts/frontend-v1/payloads, top254c8842...
Native line10044/1413/8631, toggle45514/11452/34062; Docker line10044/1347/8697,
toggle22756/5816/16940 (eligible/reached/uncovered). Full branch/exclusions retained.
12 bounded acceptance/provenance/corruption tests pass:
`python3 -m unittest discover -s tools/tests -p test_verify_coverage_m5.py -v`.
Final retained report with final policy: retained-original-final-audit/summary.json,
exit0 oktrue readyfalse. Full readiness invocation retained-original-full-negative
exits1 despite integrity oktrue because gaps/unreviewed requirements remain.
Current-source invocation retained-stale-current-negative exits1 okfalse for stale
original source; historical coverage cannot qualify current readiness-fixed RTL.

Fresh candidate budget: only4boot/idle frames, explicit copied candidate tools
and source93bc76...; no broad corpus. Initial copied-run default framescope path
failed before simulation (retained raw-candidate-{native,docker} directories).
Corrected --framescope absolute jobs sessions97712(native, completedexit0) and
65982(Docker, completedexit1), outputs
golden/out/m5-coverage/raw-candidate-{native,docker}-v2. Native initialguard command
session51748 exited1 for missing default harness path, Docker likewise exited1.
Native four-frame seeded boot/idle comparison and raw FS11 coverage completed
with summary oktrue. Docker failed before simulation with the retained actual
Verilator Internal Error: attempted to destroy locked Thread Pool,
`.framescope-m4/build/4618e212aff4580f/build.log`. No successful Docker raw
coverage exists for this attempt; no retry was launched after quota trigger.
Candidate raw native evidence has not been audited by the new tool; qualification
remains unfinished, because quota entered DOCUMENT before a new audit batch. Both corrected jobs ended before shutdown; no owned jobs remain. Do not launch
broad corpus or candidate qualification during latched shutdown.

Next resume requires fresh live quota and current user authorization. Read actual
artifacts/state, audit native raw-candidate-native-v2 against explicit
`golden/out/m5-shadow-functional-source` source root; Docker current coverage needs
a fresh bounded rerun/recovery after the documented builder failure. Full policy
will remain non-ready because module reachability/input/exclusion reviews and
broad required stimulus are incomplete. Root must integrate the policy into its
shared gate separately; this role did not edit gate/evidence/plan files. Root integrates policy separately.
Full scope gap/reachability/functional corpus obligations remain incomplete.

## Frozen files and final shutdown acknowledgement

Tool SHA
`2ca0342ba9b2ce784e5dd0bd06c7e08489b20ecf98af00af281ec0f5e4267ad5`.
Policy SHA
`e17bd44bf40209446a0f5dcd60cf0a24146792ccf04ba4e6c9e04083e66abff8`.
Tests passed before trigger; no implementation/tests/qualification/delegation
after DOCUMENT. Final native/Docker raw sessions97712/65982 and audit sessions
65058/90820/49959 all ended; no owned background jobs or descendants remain.
No user CLI/daemon/session targeted; no permanent termination claimed.
Parent received exact hashes/results/quota alert, acknowledged latched shutdown
and will aggregate last. Earlier frontend handoff remains unchanged and complete.
Policy defaults prepare<10%/<6%, stop<3%/<2%, independent windows. Resets
2026-10-11T00:05:41Z / 2026-10-14T15:27:22Z. Next concrete coverage action is
qualify the saved native candidate raw report, after fresh quota/resume.
