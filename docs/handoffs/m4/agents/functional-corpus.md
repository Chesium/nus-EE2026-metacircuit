# Subagent handoff: M4 functional corpus

Updated: 2026-10-10T06:51Z
State: completed; all owned jobs finished
Author: functional_corpus
Parent/main handoff: [M4 verification](../../m4-verification.md)
Former agent ID and parent: `/root/functional_corpus`, parent `/root`; no descendants

## Self-contained assignment for a replacement agent

Close M4 canvas functional gaps using reproducible directed, seeded cases without
changing accepted golden behavior or the existing v1/v2 input bytes. Main workspace
is `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, shared branch `verification`,
HEAD `f894fa8dcb487ff02c8f671e4126cc84cf169363`, with preexisting uncommitted M4 work.
This agent owns only `golden/src/scenario/stress.ts`, `golden/src/cli/stress.ts`,
`golden/test/stress.test.ts`, new corpus artifacts and this handoff. Root owns
lockstep/integration/RTL changes; `coverage_bins` owns `verify_m4.py` and bin tests.
No commit/push requested. Use default codex-usage-guard thresholds; parent owns
60-second team checks and ordered shutdown. Relay alerts immediately.

Generator, tests and cross-runtime directed qualification are complete. No agent
assignment needs recreation. Root should aggregate these results and recompute
the named bin union for main M4 acceptance. Density covers logical canvas capacity
only; M5 remains root's separate next milestone.

## Saved work and verification

`generateDirectedStress(seed, corpus)` and `npm run stress -- --directed CORPUS
--seed 2026 --out OUTPUT.json` generate ordinary StressCase version 2 cases with an
optional corpus tag. Names: `rotations`, `properties`, `boundaries`, `dense`.
Original random v1/v2 generators are unchanged; saved JSON SHA256 tests pin their
seed 2026/16-operation bytes. No oracle changes.

Final-source reports live under `golden/out/m4-lockstep/`:

| Corpus/runtime | Frames/checkpoints | Result | Output directory |
|---|---|---|---|
| rotations/native | 174/22 | pass | `corpus-agent-rotations-native-fixed` |
| properties/native | 135/22 | pass | `corpus-agent-properties-native-fixed` |
| boundaries/native | 133/13 | pass | `corpus-agent-boundaries-native-fixed` |
| properties/Docker | 135/22 | pass | `corpus-agent-properties-docker-fixed` |
| boundaries/Docker | 133/13 | pass | `corpus-agent-boundaries-docker-fixed` |
| rotations/Docker | 174/22 | pass | `corpus-agent-rotations-docker-fixed` |
| dense/native | 531/22 | pass | `corpus-agent-dense-native-compact` |
| dense/Docker | 531/22 | pass | `corpus-agent-dense-docker-compact` |

All eight runs pass: 1946 frames and 158 checkpoints total (973/79 per runtime).
`golden/out/m4-lockstep/corpus-agent-summary.json` aggregates their exact cases,
report paths, initialization and build provenance, totals and scope exclusions.

Recompute functional bins using latest classifier with `rtl=run/"rtl"` because
saved summaries may predate root/coverage integration.

- rotations: 174 frames/22 checkpoints; clear boot, every five two-cell component
  kinds at rotations 0/1/2/3 with collision-free placements.
- properties: 135 frames/22 checkpoints; seeded component kind, anchor/partner
  selection, actual edits from partner within one verified checkpoint block,
  all seven units, digit/suffix deletion, decimal literal and selected reset.
- boundaries: 133 frames/13 checkpoints; empty stores, right-edge rejection,
  occupied-anchor rejection, held wire/rotate, delete through partner, slot reuse,
  bottom-left ground, bottom-right pair and rejected downward rotation.
- dense: 531 frames/22 checkpoints; all 288 logical cells occupied by 144
  components, reject an extra placement, delete pair and reuse slot. Physical
  store exhaustion is unqualified: the 288-slot store exceeds attainable 144 pairs.

`npm test -- test/stress.test.ts`: 10/10 pass. `npm run typecheck`: pass.
Golden endpoint assertions cover actual intended states, unchanged settled stores after rejection,
all orientations/units and full occupancy. These alone are not actual RTL evidence.

Rejected placement/rotation evidence compares unchanged verified settled endpoint
memories. It does not establish continuous atomicity; that remains M5 invariants.

Cases saved under `golden/out/m4-lockstep/corpus-agent-cases/*-2026.json`; final
dense case is `dense-2026-compact.json`, grouped into one checkpoint per row.
Replay example (from golden):

```sh
npm run stress -- --directed rotations --seed 2026 --out /tmp/m4-rotations.json
python3 tools/lockstep_m4.py --case /tmp/m4-rotations.json --runtime native --out out/m4-lockstep/FRESH-NAME
```

## In progress, uncertainties and owned jobs

Four old-source native sessions were intentionally stopped early when root fixed
wire toolbar reselection; their retained `corpus-agent-*-native` summaries contain
an interrupted-session error and are not passes. No old-source job remains.

Final-source runs use output directories
`golden/out/m4-lockstep/corpus-agent-{rotations,properties,boundaries,dense}-native-fixed`.
Short native exec sessions 21222, 26307, 84601 and Docker sessions 7044, 40637,
72394 completed successfully. Native dense session 84497 completed successfully.
Docker dense session 72584 also completed successfully in
`corpus-agent-dense-docker-compact`. Previous 1213-frame native dense
session 96050 was intentionally interrupted early and its summary is not a pass.
All jobs are owned by this agent. Final native build cache key
`2d05620f55ba5867` differs from old-source `64416eb317ab6ebf`.
Parent has been told about their ownership and paths.
Docker dense runner PID 1456225 and its Docker CLI PID 1456382 finished; process
inspection confirms no owned corpus lockstep runner remains active. Docker final
build key is `c667b6671949d54d`. No divergences occurred. Interrupted early runs
remain preserved and excluded from the passing evidence.

## Descendant handoffs and stopped states

No descendants.

## Quota trigger and completion acknowledgement

Startup check 06:24:50Z: 98% five-hour/62% weekly, ok. Latest fresh check
06:49:47Z: 32%/52%, ok; resets 11:24:08Z and 2026-10-14T15:27:22Z.
Default prepare strictly below 10%/6%, stop below 3%/2%; no overrides.
No quota shutdown triggered. Agent completed normally at 06:51Z; document path
and aggregate results sent to parent. No descendants or active owned jobs.
