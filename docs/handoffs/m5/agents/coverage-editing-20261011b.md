# Subagent handoff: bounded editing coverage

Updated: 2026-10-10T19:57:12Z (2026-10-11 client date).
State: bounded assignment completed; active work ended normally.
Author: /root/m5_coverage_resume, parent /root. No descendants.
Parent [M5 handoff](../../m5-verification.md).
Workspace `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branch `verification`,
HEAD `f894fa8dcb487ff02c8f671e4126cc84cf169363`; preserve the existing dirty tree.
Owned only new output artifacts, `docs/m5-coverage.md` and this handoff.
Coverage/frontend tools, policy pins, production RTL and prior handoffs remained
unchanged. Root owns shared gates/evidence/production and overall M5 completion.

## Completed assignment and exact evidence

Collected one genuine editing case on isolated
`golden/out/m5-shadow-functional-source`, top SHA
`93bc76d3019d3d1e5a8949a00e32d217d934b4ece5289ec26e1421b7a2a001fb`.
Copied generator version 2, seed 1, operations 1 places a capacitor at [4,0].
Generated control artifacts and reference first; `reference/checkpoints.json`
confirmed 11 frames before any RTL launch, within the authorized <=16 frame bound.
The first mkdir used the wrong cwd and failed before generation/RTL; absolute
paths corrected it without source changes. Actual RTL witnesses come from the
subsequent comparator, not the preliminary golden reference.

Control directory: `golden/out/m5-coverage/editing-control-20261011b`.
It retains `seed-1.json`, `seed-1.scenario.json`, reference, `run_bounded.py`,
job PID/PGID/command/start/end/exit records and Docker ownership/removal record.
Launch commands were:
`python3 golden/out/m5-coverage/editing-control-20261011b/run_bounded.py native`
and the corresponding `docker` command. The artifact wrapper launched copied
`golden/out/m5-shadow-functional-source/golden/tools/verify_m4.py`, absolute
framescope `/home/chesium/ee2026_ws/framescope`, `--coverage --seeds 1 --generator 2
--operations 1 --case <control>/seed-1.json`, with fresh output per runtime and
separate process groups. Each job had a 1200 second wall budget.

Native and Docker runs both completed exit 0, 11 frames, 2/2 passing checkpoints,
with no divergence. Outputs:
`golden/out/m5-coverage/raw-candidate-editing-{native,docker}-20261011b/summary.json`.
Elapsed native 50.11 seconds, Docker 279.25 seconds. Actual accepted RTL endpoint
witnesses show capacitor placement at `operation_0`, frame 10, after boot frame 2:
17 cells/3 components -> 19 cells/4 components. Functional coverage reaches 8/64
settled-canvas bins, with four new witnesses: `tool:capacitor`,
`component:capacitor:rotation:0`, `edge:top`, `edit:placed:capacitor`. The remaining
56 bins are uncovered. This single edit does not establish continuous behavior,
UART, stalls, capacity, solver or full M5 readiness.

## Source-correct audits and exact changes

Frozen `tools/verify_coverage_m5.py` audited all four inputs against explicit
`golden/out/m5-shadow-functional-source`: earlier native idle
`raw-candidate-native-v2`, earlier Docker idle `raw-candidate-docker-resume-v3`,
and both new editing reports (`case-0/rtl/coverage/coverage.json` in each).
Same-runtime counters merged; native/Docker stayed separate. Final audit:
`golden/out/m5-coverage/candidate-editing-merged-audit-20261011b/summary.json`,
exit 0, `ok:true`, `ready:false`, no validation errors or missing runtimes.
Instrumented, eligible and excluded sets remained unchanged; all 101
module/hierarchy rows and complete point lists were retained per runtime.

| Runtime | Type | Eligible | Reached | Uncovered | Newly reached over idle |
|---|---|---:|---:|---:|---:|
| Native | Branch | 2108 | 823 | 1285 | 88 |
| Native | Line | 10046 | 1759 | 8287 | 383 |
| Native | Toggle | 45640 | 13510 | 32130 | 2848 |
| Docker | Branch | 1732 | 645 | 1087 | 58 |
| Docker | Line | 10046 | 1695 | 8351 | 385 |
| Docker | Toggle | 22819 | 6936 | 15883 | 1620 |

Structured deltas: `editing-control-20261011b/final-marginal-gain.json`.
The earlier partial native merge is preserved in
`candidate-editing-native-merged-audit-20261011b`; it intentionally retains only
idle Docker evidence and is superseded by the final four-report merge.
Full readiness invocation deliberately returned exit 1, `ok:true, ready:false`,
in `candidate-editing-full-negative-20261011b/summary.json` under the coverage base.
Every reachability review remains incomplete and no threshold/exclusion changed.
Counters are instrumentation points, not every HDL source line. Later production
changes require fresh source-correct evidence; historical candidate coverage does
not qualify current production.

## Closed jobs and frozen pins

Native launcher session 32680, runner PID/PGID 3486043 ended exit 0.
Docker launcher session 80018, runner PID/PGID 3486042 ended exit 0.
Both process groups were independently verified absent after completion.
Owned Docker CID
`ec19231afe8de21e1f3287d085611de3f0f7f9dfae9f18910cd2b2bcd168b6ba`
was identified by fresh output mounts and subsequently verified removed.
Audit sessions 67301, 35449 and 85812 ended. No owned jobs or descendants remain;
no unrelated sessions/processes/containers were stopped. Historical IDs are not
assumed live on resume.

Read-back confirmed unchanged coverage tool SHA
`534a8694400da4389cdfdc466c5694d4592c1c68d84c115ce2414e2bf8827514`
and policy SHA
`f88e8509d4f37db7615628a2a30f7a2033485480bcc0133d5400eae610ca15a8`.
Frontend observer/bench/runner pins remain as recorded in
[frontend expansion](frontend-expansion-20261011b.md). Owned document diff check
passed; no implementation change required repeating prior unit suites.

## Replacement assignment and quota

After a fresh live quota read, preserve the tree and read prior role documents and
root's final scope decisions. Collect additional bounded seeds/operations aimed
at remaining functional bins; inspect frame count first, record cold seed,
source/runtime/tool/budget and actual passing RTL witnesses. Merge only compatible
same-runtime raw coverage. Do not rerun this completed one-operation case without
changed source or requirements. Remaining input combinations, near-capacity and
queue lifetime/order, memory stalls, edits during backend/UART phases, malformed/
stale/incomplete replies, actual solver/IP and physical PS2/CDC remain required.
All policy module gap/reachability obligations remain open; full M5 is incomplete.

Fresh startup 49%/92%, prelaunch 46%/92%; final direct check
2026-10-10T19:57:12.143824Z: 24% five-hour / 88% weekly, status OK.
Default prepare <10%/<6%, stop <3%/<2%; root owns the 60 second team timer.
Resets: 2026-10-11T00:35:03Z / 2026-10-17T19:35:03Z.
No quota shutdown triggered in this role. Parent receives evidence, exact changes,
job closure and this document; root ends the overall team last.
