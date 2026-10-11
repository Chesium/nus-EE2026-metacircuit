# Regression qualification agent handoff

Updated: 2026-10-10T06:49Z. State: assignment complete; no owned jobs or descendants.

## Assignment and ownership

Qualify the startup-clear fix against all accepted M2/M3 scenarios on native and pinned Docker, inspect prior 64-operation seeds, and expand cold seed evidence. Root discovered and fixed the accepted A-007 toolbar defect during this run; final qualification covers both fixes. Own this handoff and new ignored regression artifacts only. No RTL, golden oracle, shared verification runner, main documentation, commit or push edits made by this role.

Shared main checkout `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branch `verification`; sibling `/home/chesium/ee2026_ws/framescope`, branch `m1-harness`. User explicitly authorized parallel delegation; no descendants spawned.

## Completed evidence

Consolidated machine-readable evidence: `golden/out/m4/regression-agent-evidence.json` (`complete=true`, `ok=true`). Recreate it using `python3 golden/out/m4/regression-agent-summarize.py`. Source snapshot: `golden/out/m4/regression-agent-source-snapshot.json`; final inspection verified all recorded RTL/constraint hashes still match.

| Suite | Native | Docker | Result |
|---|---:|---:|---|
| M2 full_ui, node_colours, recorded, boot | 298 frames / 61 checkpoints | 298 / 61 | all state/UI/every pixel pass, zero pixel differences |
| M3 all five scenarios | 482 frames / 42 checkpoints | 482 / 42 | accepted state/UART/solver-host/display checks pass |
| Six new cold seeds, four operations each | 234 frames / 30 checkpoints | 234 / 30 | all pass unique initialization, explicit seed and rand-reset 2 |

New seed corpus: 2, 3, 17, 42, 65535, 2147483647. This remains settled M1 canvas scope; does not qualify solver RTL or continuous invariants.

Accepted M2+M3 cross-runtime parity: all 780 frame CRC/probes and all 1,236 checkpoint memory dumps equal. UART bytes, records and timestamps equal. Excluded only `host.log` absolute artifact pathname from UART monitor object equality, recorded explicitly in the evidence. M3 totals per runtime match accepted baseline: 2,265 TX lines; 442 completed snapshots; 439 delivered solver replies; four aborts; 36 frontend rejections; 19 stale replies.

Final-source build consistency: ordinary native `227232b1fed6389b`, Docker `761d4ec114f25928`; unique seeded native `2d05620f55ba5867`, Docker `c667b6671949d54d`. Every selected artifact uses the corresponding final key.

Toolchains: native Verilator `5.046 2026-02-28 rev v5.046-55-g1264184fb`; Docker `5.020 2024-01-01 rev (Debian 5.020-1)`. Pinned image `framescope-toolchain:6501155dc903`, ID `sha256:b43b50e943ce2841855ce5b82a1a438f97c43f0b3465b795c0f905754dbf7848`.

## Artifact selection and retained infrastructure failure

- `golden/out/m4/regression-agent-qualification-20261010`: original queue artifacts; all final-source M2 node_colours/recorded/boot and M3 here. Original full_ui started before toolbar fix and is preserved but superseded.
- `golden/out/m4/regression-agent-final-source-anchor-20261010`: final-source full_ui and seed2 on both runtimes.
- `golden/out/m4/regression-agent-cold-corpus-20261010`: seeds 17/42/65535/2147483647 selected on both runtimes. Initial native seed3 used pre-toolbar build; Docker seed3 failed infrastructure from concurrent identical build commands writing cache c667b6671949d54d. Original mixed/failing records preserved; original Docker corpus runner exits1 honestly.
- `golden/out/m4/regression-agent-final-seed3-20261010`: final-source seed3 replacements both pass, selected by aggregator. Root owns generic build serialization fix.
- `golden/out/m4/regression-agent-paused-drivers.json`: historical pause/resume state, marked resumed. Do not signal historical PIDs; no paused jobs remain.

Existing 64-operation v2 results inspected: seed11 passes 727 frames / 65 checkpoints; seed12 fails 618 completed frames, frame 617 / operation 48, 49 passing checkpoints then divergence in wire variant/mode/cell. Root owns minimized counterexample, replay, retained fixture and A-007 fix. Prior artifact directories unchanged by this role.

## Jobs and next step

Sessions 18185 (qualification),46667 (original corpus),42911 (final anchors),81137 (final seed3) all ended. Qualification/final anchors/final seed3 exit0; original corpus preserved Docker infrastructure exit1 as above. No background jobs or descendants remain. No permanent termination is claimed.

Next concrete step for coordinator: integrate consolidated acceptance and seed results into tracked `docs/m4-verification.json` and main handoff, alongside root's A-007 fix/replay and other agents' coverage evidence. Do not rerun completed qualification unless source changes require it. This role has no unfinished assignment. M4 readiness and any M5 transition remain coordinator decisions under the original plan.

## Usage guard

Fresh startup quota 2026-10-10T06:25:12Z:96% five-hour / 62% weekly. Latest fresh completion check 2026-10-10T06:48:42.975253Z:ok,34% five-hour / 52% weekly; resets 2026-10-10T11:24:09Z and2026-10-14T15:27:22Z. Default prepare thresholds <10% / <6%, stop <3% / <2%; root owns 60-second active-team timer. No usage threshold triggered this role. Assignment ended normally.
