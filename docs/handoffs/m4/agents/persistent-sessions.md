# Subagent handoff: persistent sessions (FS-9)

Updated: 2026-10-10T02:45:00Z
State: documented and work ended (assignment completed; root integration remains)
Author: persistent-sessions subagent
Parent/main handoff: [M4 coordinator](../../m4-verification.md)
Former agent ID and parent role: `/root/persistent_sessions`, child of `/root`.

## Self-contained assignment for a replacement agent

Implement generic FS-9 persistent framescope JSON-lines sessions for frame
stepping, atomic input poke, probes, memory reads and safe stop. User authorized
parallel work on M4, optional MCP out of scope. This assignment is implemented
in isolated worktree `/home/chesium/ee2026_ws/framescope-m4-session`, branch
`m4-session`. Base HEAD is `de04a24f8212eedf218040dcc923daff2d7b857b`.

Root should integrate `/tmp/framescope-m4-session.patch` into main framescope,
resolving overlap with concurrent FS-8/FS-11 changes in CLI, harness and docs.
Root agreed to add FS-8 `seed` support after applying this baseline patch:
`Session(..., seed=N)`, initialization_options provenance, binary `--seed` and
`--rand-reset`, CLI `session --seed`. Seed/coverage agent implements the
MetaCircuit client in main `golden/tools/lockstep_m4.py` against this API.

Acceptance: run `FRAMESCOPE_RUNTIME=native uv run python -m unittest discover
-s tests -p test_session.py -v`, then the same with `FRAMESCOPE_RUNTIME=docker`.
The six tests have already passed in this worktree. Retest merged seed-aware
Session and new client. No broad MetaCircuit session qualification has been run
by this agent.

## Saved work and verification

Owned modified files: `CLAUDE.md`, `README.md`, `docs/architecture.md`,
`src/framescope/cli.py`, `src/framescope/harness/harness.cpp`, and new
`src/framescope/session.py`, `tests/test_session.py`. No commits. The two new
files have intent-to-add entries to include them in `git diff`; no tracked
changes were staged. Package patch: `/tmp/framescope-m4-session.patch`.

Commands/results:

- Native test_session six tests passed in 2.428s.
- Docker pinned Verilator 5.020 test_session six tests passed in 7.115s.
- Tests cover uninterrupted-vs-stepped frame CRC/memory equality, signed probes,
  position poke-vs-stimulus equality, atomic validation, dead sync time bound,
  one-response-per-line errors and owned process cleanup on stop/EOF.
- `git diff --check` passed.

Protocol: stdin requests `{id,op}`; operations `step` (`frames` default1),
`poke` (`values`, optional `line`/`pixel`), `probes`, `memory` (`name`), `stop`.
Responses echo id, ok, completed_frames, t_ps, signed probes, raw C++ events;
`memory` adds parsed dump JSON. No unsolicited startup response. At completed
frames N, frame N is in progress and last completed frame/memory index is N-1.
Startup occurs at time0 before sync learning and frame0 line10. Timed poke queues
into ordinary position-stimulus handling; MetaCircuit should use line10 after
VSYNC capture. Immediate poke sets inputs atomically/evals once at paused time.
Step pauses after monitor/probe samples before next frame stimulus; 40ms times
(count+2) per-step simulated-time guard detects dead sync.

## In progress, uncertainties and owned jobs

No remaining owned jobs, tools or subprocesses. Session supports cold runs,
all/none PNG saving, no checkpoint, FST trace or hosted UART subprocesses. These
remain ordinary-run replay features and are documented. Root integrates seed
settings and may integrate coverage provenance after merge. Do not claim seeded
or full MetaCircuit client acceptance from these tiny tests.

## Descendant handoffs and stopped states

No descendants were spawned. This agent's active assignment ends after sending
this document to the parent; completion does not claim permanent termination.

## Quota trigger and completion acknowledgement

Initial live read at 2026-10-10T02:39:27.730899Z: five-hour46%, weekly68%,
resets2026-10-10T06:21:23Z / 2026-10-14T15:27:22Z. Coordinator owns team60s timer;
latest relayed read at02:44:05Z: five-hour27%, weekly65%. Default thresholds
prepare<18%5h or<8%weekly; stop<10%5h or<5%weekly, no overrides. Assignment
completed normally without a quota trigger. Patch and document sent to root.
