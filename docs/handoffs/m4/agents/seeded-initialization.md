# Subagent handoff: M4 FS-8 seeded initialization

Updated: 2026-10-10 02:41:20 UTC
State: completed; documented and active work ended
Author: seeded_initialization subagent
Parent/main handoff: [m4-verification.md](../../m4-verification.md)
Former agent ID and parent role: /root/seeded_initialization; parent /root

## Self-contained assignment for a replacement agent

Implement generic reproducible seeded initialization in framescope as part of
MetaCircuit M4 FS-8. Implementation and validation are complete. Coordinator
should review/apply `/home/chesium/ee2026_ws/framescope-m4-seed.patch` to the
chosen framescope checkout; do not rerun this completed assignment unnecessarily.
No commits or pushes were performed.

Owned isolated checkout: `/home/chesium/ee2026_ws/framescope-m4-seed`, branch
`m4-seed`, based on HEAD `de04a24f8212eedf218040dcc923daff2d7b857b`.
Source checkout: `/home/chesium/ee2026_ws/framescope`.
Owned files: README.md, docs/architecture.md; src/framescope/{manifest,build,run,
batch,cli,checkpoint}.py; src/framescope/harness/{main,harness}.cpp;
tests/{test_manifest,test_seed}.py. All changes are uncommitted. test_seed.py has
intent-to-add staging solely so the complete patch includes the new file.

Public API:

- `[build] x_initial = "0" | "fast" | "unique"` (default fast);
  `x_assign = "0" | "1" | "fast" | "unique"` (default fast).
- `run --seed N` and `batch --seed N`, integer 1..2147483647. Omitted seed = 1.
  Runtime-only seeds reuse the build binary; initialization modes change its key.
- Either unique mode configures context randReset(2), otherwise randReset(0).
  main.cpp sets randSeed/randReset before constructing the Verilator model.
- `sim.initialization` includes seed, seed_explicit, rand_reset, x_initial,
  x_assign; build.options records modes; batch summary includes initialization.
- Explicit seed or unique mode conservatively bypasses all checkpoint creation
  and restoration, with checkpoint.reason/warnings. checkpoint.ensure independently
  rejects unique modes; direct binary nonzero random-reset checkpoint requests fail.
- Raw design.verilator_args --x-initial/--x-assign are rejected to protect recorded
  provenance. Default fast/fast behavior otherwise remains available.

## Saved work and verification

Patch: `/home/chesium/ee2026_ws/framescope-m4-seed.patch` includes all 12 owned
files (including the new seed fixture/test); `git diff --check` passed.

Commands from the owned worktree, all successful:

- `FRAMESCOPE_INTEGRATION=0 PYTHONPATH=src python3 -m unittest discover -s tests -v`
  passed 114 tests, 26 skipped (before seed fixture was added).
- `FRAMESCOPE_RUNTIME=native PYTHONPATH=src python3 -m unittest discover -s tests -v`
  passed 121 tests, 7 optional metacircuit skips, 44.356 s (before one additional
  independent-mode test was added).
- `FRAMESCOPE_RUNTIME=native PYTHONPATH=src python3 -m unittest discover -s tests -p test_seed.py -v`
  passed final 8 tests, 5.851 s on native Verilator 5.046.
- `FRAMESCOPE_RUNTIME=docker PYTHONPATH=src python3 -m unittest discover -s tests -p test_seed.py -v`
  passed final 8 tests, 18.964 s on pinned image framescope-toolchain:6501155dc903
  (Verilator 5.020).
- `FRAMESCOPE_RUNTIME=docker PYTHONPATH=src python3 -m unittest discover -s tests -p test_checkpoint.py -v`
  passed 13 tests, one optional metacircuit skip, 42.282 s.

Tiny fixture proves repeated-seed frame CRC/probe/RAM repeatability, different-seed
variation, unchanged explicitly reset state/initialized ROM, independent initial
and explicit-X modes, cache separation/reuse, validation, and run/batch checkpoint
bypass. Broad expensive metacircuit tests were intentionally left to the coordinator.
Full Docker suite was not run; targeted seeded and checkpoint coverage passed.

Official Verilator mode semantics were checked in
https://verilator.org/guide/latest/exe_verilator.html and
https://verilator.org/guide/latest/exe_sim.html; docs include the option-reference
link. x_initial has no supported "1" mode, unlike x_assign.

## In progress, uncertainties and owned jobs

No owned test/tool jobs remain running. Sessions 27323, 18488, 36313, 40730,
23643 and 33172 completed successfully. Test scratch directories were cleaned by
their TemporaryDirectory lifecycle. Parent-created `.framescope-m4/` introspection
artifacts are untracked in this checkout and were preserved; they are excluded
from the implementation patch. The parent is validating actual MetaCircuit
scenarios and has independently found/fixed a boot initialization omission at
addresses 1/2; it requested no further RTL investigation by this subagent.

Limit: repeatability is promised within the same model/build/toolchain, not across
Verilator versions or thread configurations. Checkpoint RNG preservation remains
unverified, so randomized/explicitly seeded checkpoint restore is conservatively
bypassed. This is intentional scope, not a partially implemented unsafe restore.

## Descendant handoffs and stopped states

No descendants were spawned. This agent ends its active work after transmitting
this handoff and patch location to the coordinator; no permanent termination is
claimed.

## Quota trigger and completion acknowledgement

Initial fresh live check at 2026-10-10 02:37:00.780456 UTC returned ok, five-hour
55% remaining (reset 2026-10-10T06:21:23+00:00), weekly 69% remaining
(reset 2026-10-14T15:27:22+00:00). Default thresholds apply: document below 18%/8%,
stop below 10%/5%. Parent owns live 60-second team checks. No quota stop trigger
was relayed to this agent. Completed handoff and patch locations sent to parent
at completion. Future substantive work requires a fresh live quota check.

# Follow-up handoff: bounded M4 FS-9 golden lockstep client

Updated: 2026-10-10 02:47:00 UTC
State: completed; active work ended after transmitting this handoff
Author: /root/seeded_initialization; parent /root

## Replacement assignment and saved work

Root assigned a bounded follow-up to implement the MetaCircuit persistent golden
lockstep client after FS-8 was integrated in main framescope. Completed new
uncommitted files in main MetaCircuit checkout:

- `golden/tools/lockstep_m4.py`
- `golden/tools/test_lockstep_m4.py`

No package.json, README, RTL, or other agent-owned files were edited for this
follow-up. Root owns merging/updating the framescope Session API; main
`/home/chesium/ee2026_ws/framescope` now supports Session(..., seed=N),
Session.initialization and context cleanup. Old isolated session worktree remains
historical; use the integrated main package for replay.

Client interface:

```sh
python3 golden/tools/lockstep_m4.py \
  --case golden/test/fixtures/m4_boot_seed1.json \
  --framescope /home/chesium/ee2026_ws/framescope --runtime native \
  --out golden/out/m4-lockstep/another-unique-directory
```

Alternatively `--scenario path.json --seed N`; native/docker runtimes supported;
`--replay-failure` optionally runs the saved separate cold FST replay command.
Output directory must be new. It compiles reference, canonical inputs and line10
stimulus through the existing golden CLI. One persistent session receives
changed inputs at line10 then steps exactly one frame. At settled checkpoints,
it reads all accepted-comparator memories and writes a standard report view;
the unchanged offline accepted comparator runs against a reference view with
one current checkpoint and the observed frame count. It stops on the FIRST
failed comparator result, preserving requests.jsonl, canonical inputs,
first-divergence.json with recent frame/probe trace, replay.json with explicit
runtime/seed/trace-window cold replay arguments. The persistent session does
not claim to have generated an FST; trace generation is an optional cold replay.

## Verification and artifacts

- `python3 -m unittest discover -s golden/tools -p test_lockstep_m4.py -v`
  passed 4 tests. These meaningfully verify early stop prevents later inputs or
  frame stepping, passing runs compare only settled checkpoints, malformed
  frame boundaries fail closed, and replay uses bounded trace/no checkpoints.
- `python3 -m py_compile golden/tools/lockstep_m4.py` passed.
- `git diff --check` passed.
- Real golden CLI compilation of the reduced boot fixture succeeded:
  `golden/out/m4-lockstep/compiler-development`, 3 frames, 1 checkpoint.
- Adapter exercised the unchanged accepted comparator on the coordinator's
  passing boot-fixed Docker capture: 1/1 checkpoint passed. Changing only the
  captured init_done probe to 0 produced a failing comparison with the precise
  `probe init_done is 0, expected 1` difference. Artifacts:
  `golden/out/m4-lockstep/comparator-development/{pass-check,negative-check}`.
  This deliberate negative only modifies a copied development report.
- Actual persistent native MetaCircuit reduced boot scenario passed:
  `python3 golden/tools/lockstep_m4.py --case golden/test/fixtures/m4_boot_seed1.json --framescope /home/chesium/ee2026_ws/framescope --runtime native --out golden/out/m4-lockstep/boot-native`
  Summary: `golden/out/m4-lockstep/boot-native/summary.json`; exactly 3 frames,
  1/1 settled checkpoint passed, no divergence. Provenance: seed 1 explicit,
  x_initial/x_assign unique, rand_reset 2. Session 86315 finished exit 0.

No broad new test batches were launched. Native persistent boot was the requested
bounded real integration. Full randomized-operation lockstep and persistent
Docker MetaCircuit qualification were not run by this subagent. Existing FS-9
agent validated the generic session separately. The first-divergence path has
meaningful injected-loop and accepted-comparator negative validation; no real
RTL divergence remains in the reduced boot fixture after the root's startup fix.

## Jobs, descendants and completion quota

No owned jobs or descendants remain. Fresh completion live check at
2026-10-10T02:47:00.166108+00:00 returned ok, five-hour 18% remaining
(reset 2026-10-10T06:21:23+00:00), weekly 63% remaining
(reset 2026-10-14T15:27:22+00:00). Exact 18% does not cross the strict early
threshold; root was immediately told that below 18% initiates latched team
shutdown. Root continues to own the 60-second shared timer. Future substantive
follow-up requires a fresh live check. Active work ended after sending the
completed client validation and this updated document to parent.
