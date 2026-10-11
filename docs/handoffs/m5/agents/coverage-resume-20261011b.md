# Subagent handoff: M5 coverage resume (2026-10-11b)

State: completed bounded resume assignment and work ended. Parent [M5 handoff](../../m5-verification.md).
Role /root/m5_coverage_resume; no descendants.
Workspace `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branch verification,
HEAD f894fa8dcb487ff02c8f671e4126cc84cf169363; preserve all existing dirty work.
Own tools/verify_coverage_m5.py, tools/m5_coverage_policy.json,
tools/tests/test_verify_coverage_m5.py, docs/m5-coverage.md and this handoff.
Root owns shared gate/policy pins/evidence/plan and all production edits.
Earlier [coverage handoff](coverage-resume-20261011.md) remains preserved.

Fresh quota check 2026-10-10T19:35:39.505318Z: five-hour98%, weekly100%; defaults
prepare<10%/<6%, stop<3%/<2%; resets2026-10-11T00:35:03Z/2026-10-17T19:35:03Z.
Root owns the60secondteam timer; relay alerts immediately and freeze/document/end
at DOCUMENT/STOP/UNAVAILABLE, descendants first if any.

Saved native candidate audit completed exit0 integrityoktrue/readinessfalse:
`golden/out/m5-coverage/candidate-native-resume-audit/summary.json`;
source-root `golden/out/m5-shadow-functional-source`. Raw native evidence
`raw-candidate-native-v2/case-0/rtl/coverage/coverage.json`. Native scenario eligible/
reached/uncovered: line10046/1376/8670, branch2108/735/1373,
toggle45640/10662/34978. These four boot/idle frames do not qualify broad inputs.

Owned Docker bounded retry session65286, command:
`python3 golden/out/m5-shadow-functional-source/golden/tools/verify_m4.py --framescope /home/chesium/ee2026_ws/framescope --runtime docker --coverage --case golden/out/m5-coverage/raw-candidate-docker-v2/replay.json --out golden/out/m5-coverage/raw-candidate-docker-resume-v3`.
Fresh output avoids claiming earlier failed build passed. Docker has advanced past
Verilator into C++ compilation; earlier ThreadPool failure appears transient.
No production/harness changes made to recover it.

Next steps: finish Docker job, audit genuine report against explicit candidate
source root, improve per-module scope identity and gap review. Parameterized
Verilator names (InteractionController__pi2, FloodQueueStore__D480,
WireDrawMode__pi3) currently miss exact requirement names; bind requirements to
reviewed source paths and retain raw names. Report all named functional scope
obligations and honest uncovered status; do not waive thresholds/exclusions or
claim simulation counters prove asynchronous CDC or actual solver IP.

## Final checkpoint and recreation assignment

Fresh Docker retry completed exit0, source top93bc76d3019d3d1e5a8949a00e32d217d934b4ece5289ec26e1421b7a2a001fb, four seed1 cold frames and2/2 settled checkpoints.
Recovered transient ThreadPool failure without tool/source modifications.
Combined final integrity audit exit0 oktrue/readyfalse:
`golden/out/m5-coverage/candidate-both-reviewed-scope-audit/summary.json`.
Native scenario eligible/reached/uncovered: branch2108/735/1373,
line10046/1376/8670, toggle45640/10662/34978. Docker branch1732/587/1145,
line10046/1310/8736, toggle22819/5316/17503. Both101module/hierarchy rows retained.
Full policy negative exit1 oktrue/readyfalse:
`candidate-both-full-negative/summary.json`. Stale-current negative exit1
okfalse/readyfalse: `candidate-stale-current-negative-resume/summary.json`.
Both under `golden/out/m5-coverage/`. Historical/frozen evidence cannot qualify
later production changes.

Owned implementation now matches canonical required module plus reviewed source
suffix for parameter specializations while preserving raw module/hierarchy names.
Missing required line/branch/toggle instrumentation fails readiness. Policy lists
per-module named input obligations; raw counters explicitly do not establish
functional input witnesses. Complete source review corrected capture/queue/wire
input-domain descriptions; input-domain review is distinct from reachability,
which remains false for all modules. No gaps/exclusions waived.15focused controls
pass after final edits: `python3 -m unittest discover -s tools/tests -p test_verify_coverage_m5.py -v`.
Tool SHA534a8694400da4389cdfdc466c5694d4592c1c68d84c115ce2414e2bf8827514,
policy SHA f88e8509d4f37db7615628a2a30f7a2033485480bcc0133d5400eae610ca15a8.
Root notified for gate pin integration.

Static queue risk sent to root (root owns production): integrated DEPTH1152
(__D480 hex) head/tail increment at PTR_WIDTH11 wraps2048 rather than1152.
Must verify reset-free lifetime/FIFO order beyond1152 operations and do not
exclude its counters as unreachable. Root may fix production separately; those
changes require fresh source-correct evidence. No production RTL or shared gate/
evidence/plan files edited by this agent.

Next replacement assignment: after fresh live quota, preserve current dirty tree,
read this and earlier handoff, inspect root queue decision/current source hashes,
collect bounded source-correct broad corpus coverage on both runtimes with
absolute framescope path, and review per-module reachability/gap obligations.
The scope input obligations are definitions, not functional passing bins. All
frontend/solver/UART/stall/capacity coverage readiness remains incomplete; do not
claim the four-frame provenance retry is full M5 qualification. Own the same4
files only and coordinate gate pins with root.

All owned sessions7927,65286,33109,78231,41520,62482 completed; no owned jobs
remain, no descendants ever spawned. No unrelated sessions/containers stopped.
Final live quota2026-10-10T19:39:58.819852Z81%five-hour/97%weekly, statusOK,
resets2026-10-11T00:35:03Z/2026-10-17T19:35:03Z. Policy unchanged and no quota
shutdown triggered in this resume. Parent owns periodic team timer.

Parent follow-up: native reset-free FIFO bench confirmed depth1152 sequence1152
returns0 versus expected0a693; depth1/3 fail at their first out-of-range index,
depth4 control passes. Parent owns tools/verify_flood_queue_m5.py and
src/testbench/M5FloodQueueLifetime.sv; Docker crosscheck was active in that
message. Integrated >DEPTH enqueue lifetime between clear remains unproven and
no production fix was applied. Replacement coverage role must read root's final
queue evidence rather than treating this historical message as a final Docker
result. Coverage tool/policy hashes remain frozen for root gate integration.
