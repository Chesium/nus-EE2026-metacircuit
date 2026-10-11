# Subagent handoff: generic RTL coverage (FS-11)

Updated: 2026-10-10T02:43:30Z
State: documented and work ended; assignment implementation complete, root integration pending
Author: /root/rtl_coverage
Parent/main handoff: [M4 coordinator](../../m4-verification.md)
Former agent ID and parent role: /root/rtl_coverage, child of /root; no descendants

## Self-contained assignment for a replacement agent

Implement generic framescope FS-11 line/branch, toggle and explicit user coverage,
boot/scenario artifact split at a frame boundary, reproducible tool/source
provenance and compatible merging with per-module gaps. Project functional bins
and acceptance policy belong in MetaCircuit. This implementation is complete in
isolated worktree `/home/chesium/ee2026_ws/framescope-m4-coverage`, branch
`m4-coverage`, starting HEAD `de04a24f8212eedf218040dcc923daff2d7b857b`.
No commits were made. Complete patch: `/tmp/framescope-m4-coverage.patch`.

Next concrete step: root integrates patch with the seed agent changes, resolves
shared-file conflicts, then runs actual MetaCircuit coverage with `[build]
coverage=true` and `run --coverage-from 3` (cold run). Verify run coverage.complete,
phase artifacts/hashes, named DUT modules in summary, and a compatible merge.
Read current main handoff before repeating any root validation.

Owned modifications: README.md; src/framescope/{coverage.py,build.py,cli.py,
manifest.py,run.py}; src/framescope/harness/{framescope.hpp,harness.cpp,main.cpp};
tests/test_coverage.py. The isolated worktree contains no unrelated user edits.
All changes are uncommitted. Apply the patch from the target framescope checkout
with `git apply /tmp/framescope-m4-coverage.patch`; merge conflicts with seed agent
are expected in BuildOptions/parser, build_args/options, run signature/argv,
harness model callbacks and main.cpp.

## Saved work and verification

Interface: `[build] coverage=true` instruments `--coverage-line`,
`--coverage-toggle`, `--coverage-user`. `run --coverage-from FRAME` defaults to
frame0's first recognized start. At the boundary, boot.dat is written and counters
zeroed before scenario frame/position stimulus is evaluated; model state and
previous toggle history remain. `--checkpoint` with coverage is rejected.

`report.coverage` contains report path, schema_version1, provenance (build_id,
tool_version, runtime, runtime_identity, source SHA256s, top, build_options),
boundary {frame,t_ps,event}, complete boolean, artifacts {boot,scenario} each
{path,sha256,summary}, source_paths map. complete requires successful run,
recognized boundary and both phases. Crash/timeout evidence remains incomplete.
`coverage-merge` accepts run directories or coverage.json files, defaults to
scenario scope, validates completeness/hashes/provenance/point sets/duplicates,
emits merged-scenario.dat plus coverage-merge.json. Cross-tool-version merging
is deliberately rejected because point granularity differs.

Summary groups module/hierarchy/source and type. Each type has eligible/reached/
uncovered counts, gaps list capped64, gaps_omitted and excluded=[] with explicit
note that tool-pruned/pragma-disabled points cannot be inferred. Full point
counts remain in raw .dat. Generated wrapper/DPI groups remain visible. Older
Verilator reports branch flow as v_line; newer version emits branch distinctly.
No aggregate percentage or acceptance criterion is inferred.

Actual validation:
- `FRAMESCOPE_RUNTIME=native PYTHONPATH=src python3 -m unittest discover -s tests -p test_coverage.py -v`: PASS5, latest log `/tmp/fs-m4-coverage-native.log`, 4.717s; native Verilator5.046.
- `FRAMESCOPE_RUNTIME=docker PYTHONPATH=src python3 -m unittest discover -s tests -p test_coverage.py -v`: PASS5, latest log `/tmp/fs-m4-coverage-docker.log`; pinned Docker Verilator5.020.
- Tests verify boot-only branch disappears from scenario after zeroing, explicit
  cover property reaches its named bin, repeated compatible merge doubles all
  counts, rendered frame CRCs match uninstrumented run, incomplete timeout rejects
  merge, bad config/window/checkpoint/dat/hash/duplicate/provenance rejects.
- `FRAMESCOPE_INTEGRATION=0 PYTHONPATH=src python3 -m unittest discover -s tests -v`:
  PASS117 tests, 28 integration tests skipped; `/tmp/fs-m4-coverage-unit.log`.
- `git diff --check`: PASS.
- Docker's initial build failed because5.020 takes const char* for write(); fixed
  with path.c_str(), later full coverage suite PASS.

The final two defensive parser/dependency-order adjustments (UnicodeError handled;
declared source order retained before include dependency hashes) were not followed
by another broad test run. They do not change harness code. Parent integration
validation remains necessary; actual MetaCircuit coverage was not run by this
agent. Raw earlier tiny artifacts in `/tmp/fs-m4-coverage-cold` and fixture
`/tmp/fs-m4-coverage-fixture` are exploratory; authoritative tests use isolated
TemporaryDirectory fixtures and clean them up.

## In progress, uncertainties and owned jobs

No active build, simulator or test jobs remain. All owned exec sessions completed.
The coverage helper includes recognized HDL include dependencies (.sv/.v/.svh/
.vh/.inc under declared include_dirs) in cache/provenance; arbitrary extension
includes are not discovered automatically. Source files should not be mutated
while a build/run is underway. Functional exclusions and readiness policy must be
supplied by the project, not inferred from absence of instrumented points.

## Descendant handoffs and stopped states

No descendants. Agent ended active work normally after delivering patch and
this document. This is completion of the current turn, not permanent termination.

## Quota trigger and completion acknowledgement

No quota threshold triggered this agent's normal completion. Latest own fresh
check 2026-10-10T02:43:03.701845Z: five-hour31%, weekly66%, resets respectively
2026-10-10T06:21:23Z and2026-10-14T15:27:22Z. Parent reported30%/65% at02:43:13Z.
Defaults inherited: prepare strictly below18% five-hour or8% weekly; stop strictly
below10% or5%; root owns 60-second active-team timer and latched shutdown.
Patch path and public report API were sent to root. Handoff path sent with final
completion message. Resume requires a fresh quota read before substantive work.

## Coordinator integration note

Root integrated the coverage patch with FS-8/FS-9, passed merged native coverage tests and actual seeded MetaCircuit coverage. See the main handoff for current saved state; do not reapply this baseline patch.
