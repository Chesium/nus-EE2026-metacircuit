# M4 functional coverage classifier handoff

Updated: 2026-10-10T06:41:37+00:00. Assignment completed; no owned jobs or descendants.

## Assignment and ownership

Resume M4 from the coordinator handoff; own only `golden/tools/verify_m4.py`,
`golden/tools/test_verify_m4.py` and this document in shared checkout
`/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branch `verification`, unchanged
HEAD `f894fa8dcb487ff02c8f671e4126cc84cf169363`. All new tool files remain
untracked/uncommitted with the wider M4 work. Preserve other agents' changes.
Root owns docs/reports and lockstep; functional_corpus owns generator/directed
fixtures. No commits/pushes or source RTL changes by this role.

## Completed

- Expanded functional coverage from 48 to 64 explicitly eligible bins. Added
  seven verified component units, value/unit changes, partner-half input and
  successful property edit via partner, empty/dense/full logical canvas, boundary
  rejection and rejection at full logical canvas occupancy.
- Every hit includes its first checkpoint label, frame and reason in `witnesses`.
  Density means >=144 occupied cells, full means all288. Physical component-store
  exhaustion remains excluded because288 slots cannot fill with at most144
  nonoverlapping two-cell components. UI panel/selection/pixels remain excluded:
  the accepted comparator verifies property RAM but not selection probes.
- Semantic component transitions now follow anchors, not golden slot allocation.
  Actual physical `edit:slot_reuse` requires `rtl=output/'rtl'` and the actual
  component-store dump. Only slots below verified component_count are read;
  seeded random/stale tail words do not count. A failing/missing/wrong-frame
  checkpoint clears both edit history and freed slots, and duplicate comparison
  labels fail closed.
- Input-dependent bins require visible left canvas clicks mapped using the prior
  verified pan. Blocks with drags withhold these bins because intermediate pan
  is not verified. Toolbar-only noops no longer claim blocked placement.
- Added `functional_union(coverages)` rejecting incompatible eligible sets,
  exclusions/definitions/schema or partitions and missing per-bin witnesses.
  Root should update the lockstep functional_coverage call with `rtl=target/'rtl'`;
  batch evaluate already supplies it.

## Historical evidence inspected

- Native64-operation v2 seed11: summary passes727 frames and65/65 checkpoints.
- Native64-operation v2 seed12: fails operation_48 at frame617 after49 passes;
  wire_variant/mode_select0 expected1, cell(17,5) Wire expected Junction.
  `cold_replay_exit=0` only proves simulation completed, not comparator equivalence.
  Root owns triage and has reduced/reproduced the ToolbarVGA reselection defect;
  this role launched no simulation or replay jobs.
- Recalculated8 passing native runs: accepted M1 scenario, v1 seeds1/7/2026x16,
  v2 seeds1/7/2026x16 and seed11x64. Union40/64 under stricter classifier;
  failed seed12 run excluded. Artifact for root to consume:
  `/tmp/m4-functional-union-recomputed.json` (each first witness also has run).
  All definitions/exclusions included. Current gaps: full/dense/empty canvas,
  nondefault units/properties,9 missing component rotations and store empty.
  The new directed corpus is expected to fill these; this is not a claim that
  those simulations have passed yet.

## Validation

`python3 -m unittest discover -s golden/tools -p test_verify_m4.py -v`:
12 tests pass, covering failing endpoints, physical reuse with random tail,
failed-chain reset, partner/property edits, invisibly mapped clicks, canvas
capacity, toolbar-only noops, golden slot renumbering, checkpoint frame identity,
duplicate labels, unions and manifest assumptions. Followup additionally verifies
same-wire repaint does not count as blocked, tool-at-click ordering and packed
RTL store compaction (continuously occupied slots are not inferred freed).
`python3 -m py_compile golden/tools/verify_m4.py` passes; `git diff --check` passes.
Historical runs recomputed successfully with actual RTL dumps.

## Remaining and recreation assignment

No unfinished implementation or owned background jobs. Root must recompute final
union after directed corpus sessions finish and update reports; read each
summary's actual comparator results rather than assuming completion is pass.
Directed cases are owned by functional_corpus at
`golden/out/m4-lockstep/corpus-agent-cases/{rotations,properties,boundaries,dense}-2026.json`.
No role recreation needed unless actual directed runs reveal classifier defects.
If recreating: own verify_m4.py/test_verify_m4.py only, use the64-bin schema,
recompute from full references plus flattened comparison checkpoints and case
blocks, and pass rtl directory to prove physical reuse. Keep UI panel and
physical-slot exhaustion exclusions honest. Broader M5 invariants/backend/Vivado
remain outside this role.

## Usage guard

Fresh initial live check: 2026-10-10T06:25:00Z, OK97% five-hour/62% weekly.
Latest live check: 2026-10-10T06:29:41.153914Z, OK78% five-hour/59% weekly;
five-hour reset2026-10-10T11:24:09Z; weekly reset2026-10-14T15:27:22Z.
Followup live check: 2026-10-10T06:30:38.925935Z, OK76% five-hour/59% weekly.
Default thresholds prepare<10% five-hour/<6% weekly, stop<3%/<2%; root owns60s
team cadence. No quota-triggered shutdown occurred in this role. No descendants
were spawned and no jobs remain.

## Reduced reselection cold-witness followup (completed)

Root assigned a bounded23-frame negative/cold-replay witness for
`golden/test/fixtures/m4_wire_reselection_seed12.json`. Repository RTL and accepted
golden remain unchanged. Scratch source copy:
`/tmp/m4-reselection-prefix-rtl-htzimw2f/src` from current repository source tree,
with only original ToolbarVGA nonwire-to-wire reset restored:

```diff
                 if (selected_tool_idx == 4'd1) begin
                     selected_wire_variant <= selected_wire_variant + 1'b1;
+                end else begin
+                    selected_wire_variant <= 2'd0;
                 end
```

Scratch `mutation.diff` and `source-hashes.json` preserve mutation and exact source
hashes. Recreate by copying current src to a NEW scratch directory and apply only
this diff; retain repository startup clearing fix and other user/agent changes.
Fresh live quota2026-10-10T06:32:42.121610Z: OK69% five-hour/58% weekly.

Completed job: exec session76556, native lockstep plus `--replay-failure`, output
`golden/out/m4-lockstep/reselection-reduced-cold-witness`, log
`/tmp/m4-reselection-reduced-cold-witness.log`. Command:

```sh
python3 golden/tools/lockstep_m4.py \
  --case golden/test/fixtures/m4_wire_reselection_seed12.json --runtime native \
  --metacircuit /tmp/m4-reselection-prefix-rtl-htzimw2f --replay-failure \
  --out golden/out/m4-lockstep/reselection-reduced-cold-witness
```

Await job and inspect summary.cold_replay.reproduced, comparator differences,
word-identical six RAM dumps, and FST/report/source hashes. Expected lockstep exit1
is success of this negative witness only when independent cold replay proves
reproduction. No descendants and no other owned jobs.

Completed result: expected negative lockstep exit1,23frames,4/5checkpoint passes,
then operation_3 at frame22 with exact differences:
`probe wire_variant is 0, expected 1`; `probe mode_select is 0, expected 1`.
Separate cold replay exits0, and summary.cold_replay.reproduced=true. Comparator
repeats those exact differences; same_initialization=true; all six RAM dumps
(cells_render, cells_shadow, values_shadow, value_units_shadow, component_store,
component_index_map) word-identical. This verifies the minimized saved case,
independently of root's earlier full617-frame witness.

Artifact SHA256 values (complete list also saved in output/witness-artifact-hashes.json):
- `golden/out/m4-lockstep/reselection-reduced-cold-witness/summary.json`: `a318686c420cef7ecf067b76b7daaca2f2b453e8d6b20eef7ec61fe0ae4daeb1`
- `golden/out/m4-lockstep/reselection-reduced-cold-witness/first-divergence.json`: `413dfb461d0fe91d21ebd7ddd4f0219743c10f7c2095cc5cdd2c637c808962ec`
- `golden/out/m4-lockstep/reselection-reduced-cold-witness/rtl/report.json`: `6f1ae2d9e13fd691f161659f8b5dedd82cb94f476f3a89904ace97156901afe8`
- `golden/out/m4-lockstep/reselection-reduced-cold-witness/cold-replay/report.json`: `b207e9a46d441e6002f8c82222d4567486d86ba721ae6275fedf9836d8b3d90c`
- `golden/out/m4-lockstep/reselection-reduced-cold-witness/cold-replay/trace.fst`: `a4fc9f047ea04c0dbfdaef6be30c3793b8b877a5faa838c0f440156bd4a516d9`
- `golden/out/m4-lockstep/reselection-reduced-cold-witness/cold-replay-check/state-compare.json`: `b480fe1fde65fa0fdb5f5811703b926fcef222b9f826faf5c1dea7da39b5d113`
- `/tmp/m4-reselection-prefix-rtl-htzimw2f/mutation.diff`: `92b9a323638c3195d19373125977f8775dc563baac434f0ce92290e77c6b7f82`
- `/tmp/m4-reselection-prefix-rtl-htzimw2f/source-hashes.json`: `7819c3d081e44c0e97d8dab5b3279c208126a9dc7b83986332f070ba229446f4`
- `/tmp/m4-reselection-prefix-rtl-htzimw2f/src/design/rendering/ToolbarVGA.v`: `739f6699ba3288a0d5067b3aa6c9f26a6a8ea46b13049b2416853ba81f7a6813`

Job76556 finished; no owned processes/jobs or descendants remain. No repository
RTL/client changes were made. Scratch and all negative evidence preserved.
Next step belongs to root: cite this reduced pre-fix cold reproduction beside
fixed native/Docker reduced passes in docs/m4-verification.json and main handoff.

## Saved-corpus reporter review (completed)

Root delegated ownership of `golden/tools/functional_m4.py` and new
`golden/tools/test_functional_m4.py` for a bounded M4 evidence review. Root will
retain the final generated reports. No RTL/client or M5 gate work undertaken.
Fresh check2026-10-10T06:37:37.761208Z: OK55% five-hour/55% weekly.

Found and fixed material false acceptance: saved child checkpoints were trusted
without rejecting failing parent comparators, infrastructure errors or nonnull
first divergence. Seed mismatches and invalid runtime labels were accepted.
Current reporter also verifies complete canonical/checkpoint identity, frame
counts and contiguous captured frames, scenario equality, parent pass counts,
empty child differences, missing/duplicate checks and late/missing stimulus.
Boolean frame counters/seeds are rejected as invalid numeric provenance.

A saved PASS and newly calculated hashes alone do not establish the present RAM
files still match that PASS. Reporter now runs the unchanged accepted offline M1
comparator once per run in a cleaned temporary directory (bounded120s timeout;
no simulation). This detects mutated actual memory/probes or global reference
state even if the saved summary still says PASS. Evidence SHA256s now cover all
consumed actual RAM dumps/reference states/reference RAM expectations plus
summary/case/scenario/canonical/stimulus/report/index. `accepted_comparator_rechecked`
records the fresh offline check. Runtime is validated as native/docker metadata;
this reporter does not independently reconstruct toolchain execution provenance
or claim M5 optimization acceptance.

Validation:12 reporter tests pass using a reproducible tiny actual-format empty
canvas snapshot with all six288-word RAMs, real accepted comparator (no mock),
and corruptions of parent pass/errors/counts, divergence, seed/runtime, missing
or duplicate checkpoints, missing frame/late stimulus, actual RAM/probe and
global reference state. Python compile and git diff checks pass. No broad RTL
simulations were launched. Offline reporter on fixed reduced native23-frame
actual artifacts passes. Three final directed native runs (rotations/properties/
boundaries) rechecked and union61/64 with only dense/full/capacity bins missing;
output `/tmp/m4-reporter-reviewed-directed.json`. Root awaits dense run for final
aggregation. Tests job90586 and reporter35925 completed; no owned jobs/descendants.

Next root action: rerun `functional_m4.py` over all final accepted native/Docker
runs to record stronger artifact hashes/fresh accepted comparator checks, keeping
negative witness runs outside passing corpus. No recreation needed for this
role unless final aggregation exposes an evidence compatibility defect.
