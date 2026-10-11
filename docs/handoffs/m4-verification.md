# M4 completed; M5 continuation

Final M4 [machine-readable evidence](../m4-verification.json) records64/64 bins per
runtime, eightdirected1946frames/158checkpoints and finalseed/regression/coverage/
negative replay checks. All M4 agents completed, no owned simulation jobs remain.
Continue from [M5 coordinator handoff](m5-verification.md) under fresh livequota.

The notes below are historical implementation records; current milestones are
recorded in verification-plan.md and the M5 handoff.

# Task handoff: M4 verification

Updated: 2026-10-10T06:26:27.512567+00:00
State: M4 completed in declared scope; continuation moved to docs/handoffs/m5-verification.md

## Current session

Fresh quota 2026-10-10T06:25:33Z: 93% five-hour, 61% weekly; default Codex thresholds prepare <10%/<6%, stop <3%/<2%. Root checks every 60 seconds while team runs. Resets 2026-10-10T11:24:08Z / 2026-10-14T15:27:22Z. Prior sessions are preserved below as history.

Team root + three direct children, no descendants; coverage_bins and regression_qualification completed, functional_corpus monitoring Docker dense:

| Role | Separate handoff | Owned work | Status / recreate |
|---|---|---|---|
| /root/functional_corpus | [functional corpus](m4/agents/functional-corpus.md) | stress generator/CLI/tests and new directed fixtures | running; unfinished only |
| /root/coverage_bins | [coverage bins](m4/agents/coverage-bins.md) | verify_m4.py/test_verify_m4.py and new union tool | running; unfinished only |
| /root/regression_qualification | [regression qualification](m4/agents/regression-qualification.md) | M2/M3 both runtimes, broader cold seeds, fresh output artifacts | running; unfinished only |

Root owns main evidence/docs, lockstep client and RTL triage. Root fresh quota 2026-10-10T06:30Z remains healthy (last 78%/59%). Root jobs: fixed Docker witness retry50819, full seed12 rerun65899, final coverage native/Docker sequential80515, golden suite33751, concurrency Docker97539. Main fixes: A-007 ToolbarVGA retains wire variant; reduced23frame fixture retained (before native failed, after native passes5/5). Original seed12 separate cold replay verified same failure and all6 identical memories in cold-replay-verification.json. framescope build serialized with .build.lock after observed shared cache race; native concurrency test passed. Child coverage classifier completed64bins with witnesses, now reviewing collision edge cases. Functional directed corpus simulations and M2/M3 regressions active; see child handoffs. Seed11 long v2 run passes 727 frames/65 checkpoints. Seed12 fails frame617/operation48 (wire_variant and placed sprite mismatch); root is reducing toolbar variant reselection. No previous owned jobs remain; new jobs tracked by child documents. No commits/pushes.

## Resume here (current)

Inspect only pending Docker dense compact531frames. All other M4 runs finished: fixed seed12x64 passes794frames/65checkpoints; M3 both runtimes482frames/42checkpoints; native/Docker final coverage23frames/5checkpoints each and101module groups. All three short directed cases pass both runtimes and the
strict final-source union is61/64; only dense/full/capacity bins remain. Final M2
passes298frames/61checkpoints per runtime with identical pixels/probes/dumps;
six new cold seeds pass234frames/30checkpoints per runtime. Golden224tests and
17Python tests pass. Native framescope135tests pass(7opt-in skips), Docker also passed135tests(7skips). Reduced scratch pre-fix23frame FST replay reproduced=true, same failure/init/all6RAMs.
Once all complete, recompute union using golden/tools/functional_m4.py, update
m4-verification.json/plan/scope and determine M4 complete before beginning M5.
Quota latest06:43:55Z42%five-hour/53%weekly, defaults unchanged.

## Objective and user constraints

Implement M4 from `docs/verification-plan.md`, with maximal useful parallel work:
seeded initialization, RTL/functional coverage, reproducible actual-RTL stress
and persistent golden lockstep. MCP is optional. Preserve the accepted oracle
and RTL semantics; triage observed discrepancies. User explicitly invoked the
codex-usage-guard skill with default thresholds and 60-second team cadence.
No commits/pushes or unrelated configuration edits requested or performed.

## Earlier-session resume notes (historical)

Session 2 (Claude Code, solo, no subagents) completed the recorded next checks:

- Combined framescope suite after the FS-8/FS-9/FS-11 merge: native 133 tests OK
  (7 skips), Docker 133 tests OK (7 skips). All skips are the opt-in
  `FRAMESCOPE_METACIRCUIT_TEST=1` cases. No framescope source was changed.
- Persistent editing session: `python3 tools/lockstep_m4.py --scenario
  scenarios/m1_canvas_tools.json --seed 1 --runtime native --out
  out/m4-lockstep/m1-canvas-native` passes 267 frames, 25/25 settled checkpoints,
  no divergence, cold seeded start (x unique, rand-reset 2).
- Both recorded in `docs/m4-verification.json` (`checks` and `remaining`).

- Real-RTL negative witness: `--metacircuit <scratch copy>` (new lockstep option)
  with `RotateCellData` rotation reversed stops at `rotate_wire` frame 121 after
  13 passing checkpoints; `--replay-failure` cold replay reproduces word-identical
  memories. Mutant copy lived in the session scratchpad only; repo RTL untouched.
  Report: `golden/out/m4-lockstep/m1-canvas-rotate-mutant/summary.json`.

- Docker persistent session found a framescope limitation: seeded cold boot on
  Docker 5.020 seed 1 completes frame 0 at 123.7 ms simulated (native 86.5 ms),
  but a session step allowed only (frames+2)*40 = 120 ms -> `max_time` at frame 0
  (`out/m4-lockstep/m1-canvas-docker`, kept as the failing record). Same seed gives
  different random initial state per Verilator version. Fix (uncommitted):
  framescope `session.py` step accepts optional `max_time_ms` (validated, like
  `run --max-time-ms`), new test `test_step_time_budget_override`; session tests
  7/7 native and Docker. `lockstep_m4.py` frame 0 uses `BOOT_STEP_MAX_TIME_MS = 1000`.

- Docker M1 lockstep rerun passes 267 frames, 25/25 (`m1-canvas-docker-2`).
- 16-operation stress cases (`out/m4-lockstep/cases16/seed-{1,7,2026}.json`,
  `npm run stress -- --seed N --operations 16 --out ...`) pass the native
  persistent session: 155/155/147 frames, 17/17 checkpoints each.

- Functional bins expanded (`verify_m4.functional_coverage`, test
  `test_edit_bins_need_consecutive_passing_checkpoints`); lockstep summaries now
  include them. Union over the four passing native sessions: 34/48 reached;
  gaps in `golden/out/m4-lockstep/functional-bins-union.json`.

- Full framescope suites after the session change: native and Docker 134 tests
  OK each (7 opt-in skips). Golden: tsc clean, 218 vitest tests, Python tool tests OK.
- Generator v2 (`npm run stress -- --version 2`, `verify:m4 --generator 2`): pan
  to bottom rows (row 15 weighted) and repeated rotation of its own components;
  v1 output unchanged (tested). v2 seeds 1/7/2026 x16 ops running natively into
  `out/m4-lockstep/stress16v2-seed*-native`; v1 16-op Docker runs into
  `stress16-seed*-docker`. Inspect their `summary.json` (`ok`, `functional_coverage`).

- Recorded: v1 16-op Docker 155/155/147 frames, 17/17 each; v2 16-op native
  170/184/192 frames, 17/17 each; bin union 37/48 (bottom edge now reached).
  Two 64-op v2 cases (seeds 11, 12) launched in parallel into
  `out/m4-lockstep/stress64v2-seed{11,12}-native`.

- 64-op v2 (Claude session 2): seed 11 passes 727 frames, 65/65; seed 12 failed
  at operation_48 (frame 617, wire variant). CORRECTION: the later passing cold runs
  (`out/m4/wire-variant-ddmin/baseline-run`, `out/m4/wire-variant-witness-native-2/-3`)
  ran after the concurrent Codex team changed `ToolbarVGA.v` to retain the variant
  (A-007, see "Current session"). The failure was real on the old RTL; the
  "session-only" explanation I wrote earlier is wrong. The Codex team's own seed-12
  rerun passes 794 frames / 65 checkpoints. My reducer artifacts under
  `out/m4/wire-variant-ddmin/` are obsolete.

Next, in order: (2) find why the persistent session diverges from cold batch on
seed 12 (`out/m4-lockstep/stress64v2-seed12-native`): rerun its lockstep to check
determinism; compare session RTL probes per frame with a cold run's report
(`framescope run ... -n 618 --seed 12` from `replay.json`, add probes) around
frames 590-605; check whether the session poke frame/line equals the batch event
time and whether session stepping (`step 1` + poke) differs at frame boundaries
(e.g. inputs applied after the 15-frame pan drag or around held clicks).
(3) Only if a real RTL/golden difference remains, reduce it with
cold-reproducible runs and ask the user about wire-variant semantics.

### Session 1 notes

First obtain a fresh live quota check and inspect the working trees. Generic
FS-8/FS-9/FS-11 agent work is already integrated into main framescope; do not
reapply their baseline patches. Read all three linked agent handoffs and the
coordinator integration results below. Old IDs are historical.

Session 1 asked to run combined framescope regressions and a persistent editing
scenario next; both are done in session 2 (see above).
From `/home/chesium/ee2026_ws/framescope`:

```sh
FRAMESCOPE_RUNTIME=native PYTHONPATH=src python3 -m unittest discover -s tests -v
FRAMESCOPE_RUNTIME=docker PYTHONPATH=src python3 -m unittest discover -s tests -v
```

From `/home/chesium/ee2026_ws/nus-EE2026-metacircuit/golden`:

```sh
npm run verify:m4 -- --seeds 1,7,2026 --operations 16 --runtime native
npm run verify:m4 -- --seeds 1 --operations 4 --coverage --runtime docker
python3 tools/lockstep_m4.py --help
```

Choose a fresh `--out` directory. Inspect the lockstep CLI to run an ordinary
accepted editing scenario or a saved seeded case. Expand named behavior bins,
retaining uncovered/excluded bins honestly. M4 is not complete merely because
tooling exists. M5 contracts/adapters/invariants/solver/Vivado gate remain later
work. Read `golden/M4_ASSUMPTIONS.md` for current qualification limits.

## Workspace and saved work

- Main `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`: branch `verification`,
  HEAD `f894fa8dcb487ff02c8f671e4126cc84cf169363` unchanged, initially clean.
  Modified verification plan/package scripts/GlobalRender_top; new generator,
  stress runner, lockstep client, tests, retained boot fixture, scope document,
  `docs/m4-verification.json` and these handoffs. All uncommitted.
- Main harness `/home/chesium/ee2026_ws/framescope`: branch `m1-harness`, HEAD
  `de04a24f8212eedf218040dcc923daff2d7b857b` unchanged, initially clean.
  All three agents' diffs merged with shared-file conflicts resolved. Added
  `Session(seed=N)`, seed/provenance CLI plumbing and explicit rejection of
  coverage-enabled sessions (use ordinary runs for artifacts).
  Modified generic build/manifest/run/batch/checkpoint/CLI/harness/docs; new
  coverage/session modules and their tests plus seed tests. `.framescope-m4/`
  is an owned untracked build cache, preserved; `.gitignore` was not modified.
- Isolated `/home/chesium/ee2026_ws/framescope-m4-seed`, branch `m4-seed`;
  `/home/chesium/ee2026_ws/framescope-m4-coverage`, branch `m4-coverage`;
  `/home/chesium/ee2026_ws/framescope-m4-session`, branch `m4-session`.
  All based on unchanged de04a24. Agent edits are uncommitted; intent-to-add
  entries include new files in saved patches. Preserve these worktrees for audit.
- Original patches: `/home/chesium/ee2026_ws/framescope-m4-seed.patch`,
  `/tmp/framescope-m4-coverage.patch`, `/tmp/framescope-m4-session.patch`.
  Main merged state supersedes the individual baseline patches.
- No pre-existing user changes existed in the two edited main checkouts.

## Completed and verified

Durable evidence: [m4-verification.json](../m4-verification.json).

- Golden typecheck passes; all 217 tests pass including three new stress tests.
  Three Python runner tests pass; four lockstep client tests pass.
- FS-8 tiny seeded tests native/Docker: eight each; full native agent suite
  passed 121 tests (seven optional MetaCircuit skips); Docker checkpoint suite
  passed 13 (one optional skip). Seed modes are cache-keyed and runtime seeds
  reuse builds. Unique modes or explicit seeds bypass checkpoints.
- FS-11 coverage native/Docker: five tests each. Merge rejects incomplete,
  tampered, duplicate or incompatible artifacts; boot/scenario split preserves
  exact source/tool provenance and per-module gaps.
- FS-9 session native/Docker: six tests each. Atomic timed pokes use existing
  frame/line/pixel event path; signed probes/memory metadata match cold runs;
  malformed requests, simulated-time limits and EOF cleanup tested.
- After root's merge, native session six tests and coverage five tests pass;
  earlier seed+coverage merged nonintegration suite passed127 tests/33 skips.
  These do not replace full post-merge cross-runtime acceptance.
- Root fixed startup RAM clear: mouse setmax cycles1/2 formerly skipped clearing
  those two addresses. Now mouse setup runs alongside clear, at the same times.
  Cold seed1 originally failed at frame2 with mirrored RAM/value/unit mismatches.
  Bounded reducer removed all operations; separate three-frame cold replay
  reproduced original failure. Regression retained at
  `golden/test/fixtures/m4_boot_seed1.json`.
- Fixed native cold seeds1/7/2026, four operations each:121 frames,15/15 settled
  checkpoints pass. `golden/out/m4/seed-fixed-native/summary.json`.
- Fixed Docker reduced boot:3 frames,1 checkpoint pass.
  `golden/out/m4/boot-fixed-docker/summary.json`.
- Full native accepted M1 scenario after RTL fix:267 frames,25/25 checkpoints
  pass. `golden/out/m4/m1-fixed-native/state-compare.json`.
- Actual native MetaCircuit seeded coverage:11 frames,2/2 checkpoints, complete
  boot/scenario artifacts,101 module/hierarchy groups with remaining gaps.
  `golden/out/m4/coverage-native/summary.json` and its RTL coverage/coverage.json.
- Actual native persistent seeded boot:3 frames,1/1 checkpoint pass;
  `golden/out/m4-lockstep/boot-native/summary.json`. Accepted comparator negative
  control with only init_done corrupted fails as expected. Longer persistent
  editing and actual first-divergence RTL/trace replay still not run.
- Main checkout diffs have no whitespace errors or merge conflict markers.

## Remaining and owned jobs

All launched root jobs finished: original failure session35310, reduction35241,
fixed native stress11363, Docker boot34994, M1 regression10305, coverage55427,
merged session tests96044, merged coverage tests43214, golden suite2516 and
checks12332/89021. The client's native boot job86315 finished under its agent.
Process inspection found no active owned simulation/runner jobs. No jobs were
left running and no unrelated user processes were stopped.

Broader seed corpus/long sessions, systematically observed functional bins
(units, all rotations/edges, collisions, partner selection, slot reuse, dense
and capacity limits, held buttons), stalls/UART race scenarios, continuous
invariants and real solver pipeline qualification remain. M2/M3 full suites
were not rerun this task. Sessions currently reject coverage-enabled manifests;
coverage artifacts require ordinary runs. Seeded boot checkpoints deliberately
remain unsupported. Full post-merge Docker/native suites are the next check.

## Subagent handoffs and recreation manifest

| Logical role / former agent ID | Parent | Handoff | Ownership | Status | Dependencies | Recreate? |
|---|---|---|---|---|---|---|
| seeded_initialization / /root/seeded_initialization | root | [seed and lockstep](m4/agents/seeded-initialization.md) | framescope-m4-seed; main golden/tools/lockstep_m4.py and test | completed, stopped state verified | FS-9 for client | no, original tasks complete |
| rtl_coverage / /root/rtl_coverage | root | [coverage](m4/agents/rtl-coverage.md) | framescope-m4-coverage | completed, stopped state verified | none | no, original task complete |
| persistent_sessions / /root/persistent_sessions | root | [session](m4/agents/persistent-sessions.md) | framescope-m4-session | completed, stopped state verified | root seed plumbing integrated | no, original task complete |

Team topology: root with three direct children; no nested descendants.
`collaboration.list_agents` verified all three completed after the trigger.
All child documents inspected and contain assignment/results/remaining scope.
Their original integration instructions are superseded by this main handoff.
If delegation is still authorized on resume, use new focused assignments:
(1) isolated-worktree combined harness cross-runtime regression/fix;
(2) main golden persistent editing/negative-witness qualification, owning only
new client tests/fixtures; (3) stress generator/functional-bin expansion owning
scenario/stress.ts and verify_m4.py. Avoid overlapping writes and repeat only
unfinished validation, not the completed generic feature implementations.

Team shutdown began:2026-10-10T02:47:51.923157Z, live result document / exit10.
All owned descendants stopped:yes, completion states verified by agent inventory;
child handoffs and final acknowledgements confirmed no descendants or jobs.
No permanent termination is claimed; completed agents are inactive.

## Risks and decisions

OPEN (session 2): persistent-session-only divergence (v2 seed 12, frame 603);
cold batch passes the same inputs. Lockstep results are not fully trustworthy
until explained; see Resume here.

M4 is exploratory canvas evidence, not M5 refactor readiness. Functional bins
only claim states supported by passing RTL checkpoints; uncovered bins remain
explicit. The startup fix has native M1 and seeded/cold evidence, but full M2/M3
and post-merge combined Docker acceptance remain unrun. No approval is required
for the already-authorized remaining work; a later user resume and fresh quota
check are needed because the usage policy ended this run.

## Quota and stopping policy

NOTE: Claude session 2 accidentally replaced this section's previous content (the
concurrent Codex team's quota notes; their latest figures, 06:43:55Z 42% five-hour /
53% weekly, also appear under "Resume here (current)"). Only Claude's quota is below.

Claude session 2 uses `~/.claude/skills/claude-usage-guard` (Claude plan quota, not Codex).

- Latest live check: 2026-10-10T09:44:25Z, ok (exit 0); five-hour 81% remaining
  (reset 2026-10-10T10:40Z); weekly 8% remaining (reset 2026-10-11T00:59Z, 08:59 SGT).
- Weekly is exactly at the documentation threshold (strict <8%); session 2
  checkpointed and ended here rather than continue toward it.
- Thresholds: document <18% five-hour OR <8% weekly; stop <10% / <5%.
- Session 1 (Codex) quota history: paused at document / exit 10, five-hour 15%.
- Jobs: the session-2 usage watcher is the only background job; no simulations running.

Next agent must obtain a fresh live quota check and inspect actual workspace
and job state before substantive work, under the latest user resume instructions.
