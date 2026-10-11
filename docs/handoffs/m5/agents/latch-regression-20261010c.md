# M5 latch correction full M2 regression

Updated: 2026-10-11 01:33 UTC. State: regression completed naturally; checkpoint
saved during root's latched quota shutdown. No owned jobs or descendants remain.
Author /root/m5_qor_critical; parent /root; no descendants.
Main handoff: [m5-verification.md](../../m5-verification.md).
Completed independent QoR role: [qor-critical-20261010c.md](qor-critical-20261010c.md).

## Self-contained assignment

Workspace `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, verification branch,
HEAD f894fa8dcb487ff02c8f671e4126cc84cf169363. Preserve shared dirty work. No
production edits, shared tool/policy changes or commits/push. Root owns acceptance.
Qualify the independently passing coord_len default correction with the complete
M2 corpus on native and Docker in parallel. Each runtime has1800second total
budget; use absolute framescope checkout and preserve accepted oracle/stimulus/
masks/pixels/state/UI/initialization. Existing root SolverBoard capacity guard is
not present in this isolated root; never call it current production.

New source root `golden/out/m5-latch-functional-source-20261010c` is a complete
symlink-preserving copy of `m5-shadow-functional-source`; only panel changes:
add exactly coord_len=0 to the combinational block.210regular source/oracle
files verified; only `src/design/Dashboard/ComponentPropertyPanel.v` differs,
with qualified identity45ca2444a42286dce2cb0c71b1364762a8ec60b825277f94f086cc2337c73786.
Top remains93bc76... reviewed shadow. No strengthened XDC copied. Assets, golden
oracle, scenario/stimulus generators and masks remain identical. Provenance is
`golden/out/m5-latch-functional-source-20261010c-provenance.json`.

## Saved work and running jobs

Artifact driver `golden/out/m5-latch-m2-20261010c/run_runtime.py` runs each runtime
serially across boot/full_ui/node_colours/recorded, while native and Docker run
concurrently. Full scope expected298frames/61checkpoints each. It saves exact
commands/PIDs/PGIDs/budgets, checks all candidate/source/oracle hashes, harness
source hashes and unchanged shared simpyhls, and validates initialization exactly
seed1/seed_explicitfalse/rand_reset0/x_initialfast/x_assignfast. This is the accepted
M2 initialization; no unique-seed M4 claim. Default comparator/pixel checks intact.

- Native driver PID165854, exec session70002; Docker driver PID165855, session24984.
  Current groups and completed cases are in each runtime checkpoint.json and
  jobs-checkpoint.json. Boot passes6frames/6checkpoints on BOTH runtimes including
  exact accepted initialization. Native full_ui also passes107frames/23checkpoints,
  zero differing pixels, state/UI/init preserved. Native full corpus COMPLETE:
  all4cases pass298frames/61checkpoints, hashes stable, driver165854 ended normally.
  Docker full corpus also COMPLETE: all4cases pass298frames/61checkpoints,
  source/oracle/harness/simpyhls hashes stable, accepted initialization exact.
  Driver165855 and final group189792 ended naturally. Aggregate summary.json
  records both runtime reports and source identity; fullreadiness remains false.
- Docker full_ui container5752e0ce4437 verified owned by exact output/src bind
  mounts. Other simulation container6579cacdc758 belongs to coverage peer; exclude
  it from cleanup. IDs are historical: verify current mounts/state before stopping.
- Saved reports under `golden/out/m5-latch-m2-20261010c` are complete. Each runtime
  covers6/107/78/107frames and6/23/9/23checkpoints, all state/UI/pixel checks pass
  with zero differing pixels. Native353.205s, Docker426.318s, both under1800s budget.
- Cleanup.json confirms every historical owned process group and both driverPIDs
  absent; no running container has this task's unique /fs/out0 binding. No owned
  containers required cancellation and no unrelated process/container was touched.
- On ordered quota shutdown, SIGTERM only this task's verified driver PID. Its
  signal handler forwards SIGTERM to the current owned M2 process group. Inspect
  live Docker mounts to ensure no owned simulation container survives; never stop
  other user/root/agent containers. Save partial reports and unfinished scenario.
- No descendants, no production changes; full timing/IO readiness remains false.

## Resume and quota

Initial fresh quota2026-10-11T01:24:22Z35%five-hour/75%weekly, reset06:08:23Z and
2026-10-17T19:35:03Z. Default prepare<10%/<6%, stop<3%/<2%. Root owns60second
team checks. Any document/stop/unavailable result freezes substantive work;
checkpoint owned jobs, save this document, notify parent, and end. A reset alone
does not authorize resume. Inspect actual jobs/state before any replacement run;
use new outputs and rerun only incomplete scenarios, preserving completed evidence.
The completed QoR handoff is preserved separately. Parent receives this handoff
path and final results/cleanup; active work ends after this bounded checkpoint.

Latest fresh own check01:28:35Z22%five-hour/73%weekly; no trigger yet.
Parent/peer latest01:30:22Z17%/72%, still OK. Parent directs no new phases beyond
already-running M2 corpus and immediate cleanup/handoff upon documentation signal.

Root latched shutdown01:32:55Z/01:32:57Z at8%five-hour/71%weekly, DOCUMENT/exit10.
Both drivers completed naturally before this agent received the shutdown message;
only saved-result aggregation and owned-job/container inspection happened afterward.
No new test/phase/implementation was launched. No descendants; parent notified
before ending, root aggregates last. Completed QoR handoff remains unchanged.

Next concrete step: root decides whether to adopt the panel-only default correction
using complete functional regression plus independent qualified QoR/cone proof.
No production adoption here. Do not rerun completed M2 cases or copy strengthened
XDC/rejected arithmetic candidates. Source/pixel timing/IO readiness remain false;
this isolated source lacks root's separate production SolverBoard capacity guard.
On future authorized resume, read both handoffs and perform a fresh live check,
verify actual dirty tree/job state, and recreate only unfinished root assignments.
