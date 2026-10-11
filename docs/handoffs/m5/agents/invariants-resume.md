# Subagent handoff: M5 controller/guard invariants resume

Updated: 2026-10-10T14:08:00Z
State: completed scoped assignment, work ended; full M5-4 remains incomplete
Author: /root/m5_invariants_resume
Parent: [main M5 handoff](../../m5-verification.md), /root coordinator
No descendants were created.

## Self-contained replacement assignment

Workspace `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branch `verification`,
HEAD `f894fa8dcb487ff02c8f671e4126cc84cf169363`. User authorizes parallel M4/M5
work under codex-usage-guard defaults. Initial fresh live quota is mandatory on
resume; coordinator owns 60-second team checks. This role owns only
`src/testbench/M5CanvasInvariants.sv`,
`golden/tools/verify_invariants_m5.py`,
`golden/tools/test_verify_invariants_m5.py`, `docs/m5-invariants.md`, and this
handoff. Other repository changes pre-exist or belong to the team. No commits,
pushes, RTL edits, frozen inputs or shared plan/evidence edits were made here.

The scoped task is complete: qualify real controller read/write and guard
read/write stalls, strengthen useful command/map checks, preserve exact
assumptions, and run native/Docker plus negative controls. Do not recreate this
role merely to rerun completed checks. Future unfinished M5-4 work is formal or
targeted equivalence, independently stored production maps/global queues,
frame-visible/global reply and accepted multiwrite atomicity, all-frame safety
and specified architectural progress bounds. Coordinate scope and new file
ownership before extending those checks; do not mark unsupported scope passed.

## Saved work and evidence

A separate `M5CanvasInvariants_test` top leaves the existing M1 testbench and
production interaction RTL unchanged. Bound request monitors check both real
interfaces each rising edge. The new top has exact independent expected memory
write events, full settled 288-word map and component geometry checks, rejection
no-write cases, reply environment checks and a schedule-specific watchdog.

A directed rotate read stalls through the actual guard/memory path. Genuine
controller write backpressure comes from a same-mode second edit issued after
controller_done while the previous guard edit validates under a memory hold.
No hierarchical signal force or synthetic ready gate was used. This one
bounded overlap is expressly declared; arbitrary overlap/mode changes are not
qualified. First background write is held 12 cycles; two directed memory holds
last 20 cycles. Reply delay variants are 1, 3 and 9 cycles after acceptance plus
registered visibility. The watchdog `64+4*delay` is finite directed simulation
allowance after entering settle, not a proven/specification architecture bound.

Commands completed successfully:

```sh
python3 golden/tools/verify_invariants_m5.py --runtime native --out golden/out/m5-invariants/resume-native-v2
python3 golden/tools/verify_invariants_m5.py --runtime docker --out golden/out/m5-invariants/resume-docker-v2
python3 -m unittest discover -s golden/tools -p test_verify_invariants_m5.py -v
git diff --check
```

Native Verilator 5.046 and Docker Verilator 5.020 both report `ok:true` with the
current runner hash `e3349d7262996a32460292eb7924281c94583af0a6d3e53e6faceae2e5a4df57`.
Bench hash `4a4e534fbab97f085efc47938980156fc641591bbccf8bdaa6766e38d7e8ff14`.
Every delay/runtime has 42 settled checks, 16 exact writes and 21 reads/replies.
Maximum settle counts are 26/30/52 at delays 1/3/9. Both runtime observations
match exactly:

| Reply delay | Controller stalled reads/writes | Guard stalled reads/writes |
|---|---|---|
| 1 | 18 / 26 | 51 / 14 |
| 3 | 18 / 32 | 55 / 14 |
| 9 | 18 / 42 | 52 / 13 |

Four negative controls fail specifically as expected in each runtime: observed
request-address corruption, observed committed-data corruption, settled-map
observation corruption and withheld memory reply. Their exit code is nonzero
and exact assertion labels are required; unrelated crashes are rejected.
The 14 Python tests cover fail-closed report acceptance and Docker writable
output mapping inside/outside the source tree.

Failed exploratory reports are preserved, not accepted: `resume-initial` built
but failed expectation scheduling before a release frame, subsequently fixed;
`resume-docker-final` failed a pre-existing runner output mapping bug because an
output directory below the repository mapped into read-only `/source`. Fixed
by prioritizing the writable `/out` mount, with regression tests. Intermediate
`resume-fixed1`, `resume-native-final`, and `resume-{native,docker}-qualified`
reports are historical and may have old runner identity. Accept the final `v2`
reports only after checking source hashes against current files.

## Limitations and remaining work

The queue monitor is local to the three-entry guard and depends on its audited
state encoding. It is not a global queue proof. Component pairing derives from
logical cell RAM geometry, not an independently stored production map. The
memory reply count checks the explicit one-outstanding memory environment;
production reply atomicity is unsupported. Settled map checks do not establish
all-frame continuous map consistency. Rejected directed edits have no accepted
writes; successful multiword edits intentionally commit sequentially, and atomic
visibility to other consumers is unsupported. Formal/equivalence, arbitrary
stalls, globally specified bounds, solver/IP, PS/2 and CDC were not run.
No production RTL issue was found in the tested scope.

## Jobs, quota and completion

All owned native/Docker runner sessions finished. Most recent Docker session
97375 completed exit0; there are no owned background jobs or descendants.
Earlier sessions 82217/59355/73363/78337/4068 all completed; no process was killed.
No user daemon or unrelated worker was targeted.

Initial fresh check 2026-10-10T14:00:27.825896Z: OK, 98% five-hour / 47% weekly.
Latest direct check 2026-10-10T14:07:41.787428Z: OK, 77% five-hour / 43% weekly;
resets 2026-10-10T18:59:37Z and 2026-10-14T15:27:22Z. No quota shutdown triggered.
Default prepare below10%/6%, hard stop below3%/2%; coordinator owns team timer.
This role ended normal scoped work and sent the document/evidence to the parent.
