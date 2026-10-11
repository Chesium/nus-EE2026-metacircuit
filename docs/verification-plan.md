# Verification plan: golden model + framescope

Living document for making MetaCircuit deterministically testable without hardware.
Track progress here: tick TODOs, append to the log, and move questions from
"to be made" to "made" when settled. IDs are stable; never reuse one.

Last updated: 2026-10-10 (client date; M4 accepted baseline complete)

## Goal

There is no physical Basys 3 available. The focus is agentic observability and
automated testing of the RTL: an agent (or CI) should be able to drive the design
with mouse input and decide, deterministically, whether what it shows is correct.
The Basys 3 FPGA remains the synthesis/implementation target for measuring logic
depth, resource use and timing; AMD Vivado 2025.2 is installed locally under
`/opt/amd/2025.2`.

That needs a ground truth. The plan is a human-validated software model of
MetaCircuit (the *golden model*) that produces reference states and frames, and
[framescope](../../framescope) to simulate the RTL with Verilator and capture
the same observables for comparison.

The final goal is readiness for autonomous refactoring across the verified RTL
scope: preserve the accepted functions while improving measured FPGA results.
M1-M3 provide the behavioral baseline. M4 strengthens exploration and coverage;
M5 combines that evidence with stable observation interfaces, continuous
invariants and a scripted synthesis/implementation gate. Each optimization must
produce reproducible correctness and resource/timing results.

```text
                    scenario (per-frame mouse input)
                   /               |                \
   golden core (headless)     framescope stim     web shell (human / Playwright)
          |                        |                      |
 reference state + frames   RTL sim (Verilator)     human validation of the
          |                  frames, probes,         golden behaviour; recorded
          |                  RAM dumps, UART         sessions become scenarios
          \                        /
           compare: state > decoded cells > masked pixels
```

## Milestones

| ID | Milestone | Status |
|----|-----------|--------|
| M0 | Harness bring-up: framescope runs metacircuit on local Verilator; VGA timing correct | done |
| M1 | Canvas-only slice: select tool, place, rotate, delete, pan; RAM state matches golden on one recorded scenario | done: human accepted; 267 frames / 25 checkpoints pass on native and Docker, including saved web recording |
| M2 | Full-UI pixel golden: toolbar, keypad, property panel, cursor, node colours; masked pixel compare | done: human accepted; 3 scenarios (full UI, node-colour edits, web recording) pass state, UI probes, node-colour RAM and every pixel on native and Docker |
| M3 | Backend in the loop: netlist over UART matches golden; solver replies; voltage display checked | done: 5 scenarios / 482 frames / 42 checkpoints pass on native and Docker; UART records, ids, solver replies, voltage RAM, 7-segment display and LEDs checked |
| M4 | Coverage, seeded RTL stress tests and lockstep sessions; optional agent interface (MCP) | done in declared settled frontend scope: 64/64 bins per runtime, 1,946 directed frames/158 checkpoints; seeded regressions, coverage and persistent negative replay pass; MCP optional |
| M5 | Final milestone: prepared for large-scale autonomous refactoring with preserved behavior and measured FPGA improvements | not started: requires M5-1..M5-8, FS-8/FS-11 and INF-4; readiness is scoped explicitly |

M1 needs FS-1..FS-3, RTL-1..RTL-3, GM-1..GM-3 and SC-1..SC-2. It does not need the renderer.

## TODO

Priority: P0 is an immediate blocker (historical M1 blockers are complete); P1
is required for the next milestone, including M4/M5 readiness; P2 is deferred or
conditional on the modules being changed.

### framescope (FS)

- [x] FS-1 (P0) Sub-frame event timing: `[[event]] frame = N, line = L` so inputs can change in the back porch, after the RTL's VSYNC capture edge.
- [x] FS-2 (P0) Per-frame probes: sample named internal expressions at a fixed point in each frame (frame counter, `mode_select`, `grid_pos_x/y`, init-done) and report them in the frame JSON. Needed to align RTL frames with golden frames.
- [x] FS-3 (P0) Memory dumps: write CellStore / ComponentStore contents at the end of chosen frames (JSON or hex) for state-level comparison.
- [x] FS-4 (P0) `framescope compare`: frames vs reference PNGs with region masks; diff PNG, per-region pixel counts, bounding boxes. Already listed as planned in framescope's `docs/architecture.md`.
- [x] FS-5 (P0) Batch runner: many scenarios against one build, parallel processes, one JSON summary.
- [x] FS-6 (P1) Speed: checkpoint after boot (Verilator `--savable`), restore per scenario; option to skip PNG encoding; try `--threads`. Baseline: ~1.1 s per frame, so a 300-frame scenario is ~5.5 min. Done (framescope `m3-speed`): Verilator compiled with `-Os` by default; `-O2` is now the default (~0.72-0.85 s/frame, CRC-identical); `--checkpoint N` boot checkpoints with `--savable` (~3-4 s saved per run); `--profile`. Threads were slower.
- [x] FS-7 (P1) UART monitor (decode `RsTx` lines into the report) and RX driver (scripted lines, or a host process such as `src/uart_link`'s simulated solver). framescope branch `m3-uart`: `protocol = "uart"` monitor, `[[uart]]` stimulus, `--host LINK=CMD` lockstep host with deterministic reply timing.
- [x] FS-8 (P1, M5 prerequisite) Seeded initialization: validated `[build] x_initial/x_assign` modes and `run/batch --seed`, pre-construction Verilator random reset, recorded `sim.initialization`, separate build keys and conservative checkpoint bypass. Tiny native 5.046 and Docker 5.020 seeded suites pass (8 tests each). Cold MetaCircuit seeds exposed skipped startup clear at cells 1/2; reduced/replayed witness and fix recorded under M4. Checkpoint reuse for seeded runs remains deliberately disabled.
- [x] FS-9 (P1) Long-lived JSON-lines session over stdio: frame steps, immediate/timed atomic input pokes, signed probes, memory reads and stop. Six tiny-design tests pass on native/Docker; main-checkout native tests also pass after FS-8 integration. `golden/tools/lockstep_m4.py` uses line-10 pokes and the unchanged comparator, stops at first divergent settled checkpoint and saves replay/trace metadata. Cold seed-1 MetaCircuit boot passes; longer editing sessions remain M4 expansion.
- [ ] FS-10 (P2) PS/2 device model, plus an SV port of Digilent `Mouse_Control.vhd` / `Ps2Interface.vhd` (or GHDL-synth to Verilog), to test the real mouse path instead of the stub.
- [x] FS-11 (P1, M5 prerequisite; promoted from P2) Verilator branch/line flow, toggle and explicit user coverage: `[build] coverage=true`, `run --coverage-from`, compatible artifact merges, tool/source provenance, boot/scenario split and bounded per-module gap reports. Five tests pass on each native/Docker runtime and the merged native checkout; an actual 11-frame MetaCircuit seeded run passes two state checkpoints with complete coverage. Initial named functional bins are reported by the canvas stress runner; systematic behavior-bin expansion and acceptance policy remain M4/M5 work. Sessions currently reject coverage-enabled manifests; use batch runs for artifacts.
- [ ] FS-12 (P2) MCP server on top of sessions. Optional convenience; the CLI/JSON gate is sufficient for M5.

### RTL design-for-test (RTL)

- [x] RTL-1 (P0) Make `global_anim_phase` frame-locked. Today it advances every 1,000,000 pixel clocks (40 ms) while a frame is 420,000 clocks, so the phase changes mid-frame on a different line each time (`src/design/rendering/GlobalRender_top.v:1101`). Advance on VSYNC every N frames instead (D-009).
- [x] RTL-2 (P0) Latch the cursor position once per frame for `MouseDisplay`, so an input change mid-frame cannot tear the cursor.
- [x] RTL-3 (P0) Measure and document the input-to-effect latency (mouse change, then capture, then command, then ping-pong swap, then visible) as a spec constant the golden model uses.
- [x] RTL-4 (P1) Make the frontend UART path testable in simulation: it is gated by `SW[5]` and `RsRx` idles, so no solver ever replies and the voltage display is never exercised. Set `SW[5]` from the stimulus (`--set SW=32`); flooding now re-runs after edits in UART mode (`5312d7c`); `GlobalRenderUartLoop_test.sv` closes the loop.
- [x] RTL-5 (P1) Make the framescope mouse stub honour `setmax_x/y` and `setx/sety` like the Digilent controller, or confirm it is out of scope for M1-M3 (D-010). Out of scope: the top pulses `setmax` once at boot and ties `setx/sety` to 0; no stub change needed.

### Golden model (GM)

- [x] GM-1 (P0) Core state model (TypeScript, `golden/`; D-005, D-006): CellStore, ComponentStore, tool mode, pan offset, property-panel state; `step(state, mouse_snapshot) -> state` at frame granularity, matching the RTL's per-frame mouse capture.
- [x] GM-2 (P0) Interaction semantics for M1: tool selection, draw wire/junction/elbow/tee/ground, place R/L/C/V/I, rotate (incl. `RotateFramesPerStep` holdoff), delete, pan with clamping. Source of truth: `structure.md` and the final report, not a transliteration of `InteractionController.v` (D-007).
- [x] GM-3 (P0) State export in the same format as the FS-3 RAM dumps.
- [x] GM-4 (P1) Asset extraction script: sprite functions and palette in `CircuitCanvas.v`, `FontROM.v`, toolbar and keypad icons, cursor bitmaps, into JSON.
- [x] GM-5 (P1) Renderer: `render(state, t) -> 640x480 RGB444`, pixel-exact, from the GM-4 assets. Full UI, font, flow/caret phases and independent settled node colours implemented; M2 human validation accepted.
- [x] GM-6 (P1) Cell decoder: classify each visible grid cell of a frame into (sprite, rotation, colour) using the GM-4 assets, so mismatches read as "cell (3,4) is RL rot 1, expected RR rot 1". Preserves symmetric rotation ambiguity and cursor occlusion; corruption witnesses feed the M2 runner.
- [x] GM-7 (P1) Backend: flooding, component node extraction, stamping, DC solve; differential test against the simpyhls DSL kernels (`simpyhls/examples/*.dsl.py`) on random circuits. M2's settled connectivity/colour slice is implemented independently; Extraction (`9709b47`) and DC solver (`fd599c0`) done; bit-exact against `frontend_tester.SimpyhlsDcSolver` on 339 netlists. Assumptions in `golden/M3_ASSUMPTIONS.md`, `golden/M3_SOLVER_ASSUMPTIONS.md`.
- [x] GM-8 (P1) Netlist export in the `src/uart_link` protocol format, to compare against the RTL's UART output (FS-7). Byte-identical to `protocol.py`; `npm run golden -- netlist` / `uart-decode`.

### Scenarios and web shell (SC)

- [x] SC-1 (P0) Scenario format: per-frame mouse states plus macros (`click_tool`, `click_cell`, `drag`); compilers to golden input and to framescope `stim.toml`.
- [x] SC-2 (P0) One hand-written M1 scenario that exercises every canvas tool.
- [x] SC-3 (P1) Web shell: 640x480 canvas drawn with `putImageData`, scaled nearest-neighbour; mouse mapped to per-frame snapshots; record and replay sessions as scenario files.
- [x] SC-4 (P1) Playwright tests that replay scenarios in the web shell and check against the headless golden output. Three tests pass, including full M1 recording/download and replay.
- [x] SC-5 (P1, M1) Human test sessions on the web shell; triage every M1 RTL/golden mismatch (D-007). Human acceptance supplied by the user; all observed M1 differences resolved. M2 human validation accepted by the user (2026-10-09).

### Infrastructure (INF)

- [ ] INF-1 Merge `fix/vga-timing` (metacircuit) and `native-verilator-json-ports` (framescope) into their default branches.
- [x] INF-2 framescope's `examples/metacircuit/framescope.toml` defaults `METACIRCUIT` to the sibling `../../../nus-EE2026-metacircuit` checkout. Environment overrides still work.
- [ ] INF-3 One framescope test run under the docker runtime failed once with an error that did not reproduce in 10 later runs; traceback was not captured. Watch for it.
- [x] RTL-6 (P1) Keypad uses the cursor's frame-latched mouse on `clk_pixel`; short single-frame presses and hover/pressed styling are deterministic. Caret also toggles every ten frames, replacing its free-running pixel counter.
- [ ] INF-4 (P1, M5 prerequisite) One acceptance entry point used locally and by CI: framescope/golden tests, focused RTL benches and integration regressions on pinned Docker 5.020, with native 5.046 as a second job. Use fast checks during development and full checks for acceptance. Run Vivado on a runner with the installed toolchain, or consume local reports whose source/constraint/tool hashes match the candidate; missing mandatory checks fail readiness.

### M3 follow-ups (M3)

- [x] M3-1 (P1) Implement D-023 (rows only for terminal-touched regions) in the golden extraction, the extraction kernel and the regenerated RTL. Live-kernel differential tests, 11 kernel tests and the extraction RTL bench pass; the UART wire-island checkpoint preserves the boot solve.
- [x] M3-2 (P1) Implement D-024 (`@ER` code 85 for an aborted snapshot) in the frontend RTL and the golden UART model. Both codecs validate the abort id/count; four real interrupted snapshots close correctly on both runtimes.
- [x] M3-3 (P1) M3 scenarios with `SW[5]=1` and the solver host, including the D-025 out-of-order placement and slot-reuse check, and a `verify:m3` runner comparing netlist lines, snapshot ids, replies and 7-segment/voltage probes (D-017) against the golden model. Five scenarios pass all 42 checkpoints on both runtimes; evidence in `m3-verification.json`.
- [ ] M3-4 (P2, post-M3) On-screen voltage readout with a golden renderer (D-017).
- [x] M3-5 (P2) Restore an anchor-half selection checkpoint in `m2_full_ui`/`m2_recorded`: `voltage_anchor_selected` checks (4,2), while `voltage_micro` still uses the partner half (3,2), D-015. New web recording downloaded through real pointer events; 107 frames / 23 checkpoints pass every pixel on both runtimes.

### Autonomous refactor readiness (M5)

- [ ] M5-1 (P1) Freeze the accepted baseline and contract: start from metacircuit `2ff7f3a`, simpyhls `0d6f22a` and the framescope revision pinned by M3 evidence. Pin golden behavior, visual payloads, scenarios, constraints and known limitations; define exact output timing versus bounded internal latency. Record the modules and input ranges covered by readiness.
- [ ] M5-2 (P1) Stable semantic observation adapter: expose logical cells/components, UI state, netlist events and accepted voltages independently of instance names, FSM encodings, slot packing or physical RAM banks. Validate adapters against the frozen baseline. Preserve semantic guarantees and required atomicity while allowing implementation layout to change.
- [ ] M5-3 (P1) Seeded randomized tests against actual RTL, using FS-8/FS-11: interaction sequences, rapid edits, dense circuits, boundaries/capacity limits and configurable memory stalls. Check every frame where the contract defines a result; use continuous properties elsewhere. Save seed, inputs and first divergence, reduce failures to replayable scenarios, and require the reduced case to reproduce in a cold run.
- [ ] M5-4 (P1) Continuous invariants and progress bounds: stalled request data stays stable, commands are neither lost nor duplicated, rejected edits produce no partial writes, cell/component maps agree, queues stay in range, replies commit atomically and accepted work finishes within specified bounds. Add targeted old/new equivalence or formal proofs for suitable modules; preserve proof assumptions and report unsupported/inconclusive checks separately from passes.
- [ ] M5-5 (P1) Extend backend verification to the generated RTL and real solver pipeline: feed randomized extraction/solver fixtures through RTL, and exercise the frontend-to-`SolverBoard_top` UART path. Validate floating-point primitive behavior and latency against the configured IP before using stand-ins as acceptance evidence. The M3 Python-host result alone does not qualify solver datapath changes.
- [ ] M5-6 (P1) Script Vivado 2025.2 synthesis and routed implementation for Basys 3 (`xc7a35tcpg236-1`), with explicit tops, source/IP manifests and clock/I/O constraints. Record per-module and total LUT/FF/BRAM/DSP use, critical-path logic levels, WNS/TNS, hold timing, clock/CDC checks and unconstrained paths. Preserve reports, checkpoints, warnings and exact run settings in a machine-readable summary.
- [ ] M5-7 (P1) Unified autonomous acceptance gate: fixed regression corpus plus seeded RTL tests, invariants/equivalence, coverage requirements and Vivado deltas. Return a nonzero exit for any mandatory failure, missing/stale evidence or unexplained coverage exclusion. Record the optimization objective and allowed area/latency/timing tradeoffs before evaluating the candidate; a functional pass alone cannot qualify an optimization.
- [ ] M5-8 (P1) Demonstrate readiness: the unchanged baseline passes the declared functional contract, its synthesis/timing status is characterized, deliberate behavioral and report/coverage corruptions fail the gate, a seeded failure is reduced and replayed, and one bounded optimization passes with a measured gain. Archive `docs/m5-verification.json` with the scope, thresholds, seeds, coverage gaps/exclusions, results and source/tool/constraint hashes.

## Decisions made

| ID | Date | Decision | Rationale |
|----|------|----------|-----------|
| D-001 | 2026-10-09 | Verification moves fully to simulation; there is no hardware target. | No Basys 3 available; focus is agentic observability and automated testing. |
| D-002 | 2026-10-09 | framescope is the RTL observability harness, run natively on the local Verilator (5.046) as well as in its pinned container (5.020). | Port introspection now uses `--json-only` with an `--xml-only` fallback (framescope `b0cecf0`). Frame CRCs are identical under both toolchains. |
| D-003 | 2026-10-09 | `VGAControl` produces standard 640x480@60 timing: 800x525, porches 16/96/48 and 10/2/33, sync aligned with the RGB pipeline (`RGB_LATENCY`). | Was 801 clocks per line, sync 2 px early, and column 639 always black. Fixed in `c5fee06`; frames identical otherwise. |
| D-004 | 2026-10-09 | Ground truth comes from a golden software model of MetaCircuit, validated by humans and Playwright, that generates references for framescope comparison. | User direction. Implementation choices are D-005 to D-012. |
| D-005 | 2026-10-09 | (Q-001) The golden core is written in TypeScript and runs headless in Node (reference generation, CI) and in the browser (web shell). | Interaction and rendering logic only exists in Verilog, so it is new code in any language; the reusable Python backend is small enough to port and differential-test (GM-7). Pyodide is heavy and lags CPython, while simpyhls targets Python 3.14. |
| D-006 | 2026-10-09 | (Q-002) The golden model, scenarios and web shell live in this repo under `golden/`. framescope stays design-agnostic and only gains generic features (FS-*). | The golden model describes MetaCircuit specifically. |
| D-007 | 2026-10-09 | (Q-003) Golden behaviour is derived from the spec documents and human testing, not by reading the RTL. Every RTL/golden mismatch is treated as "either side may be wrong" and its resolution is recorded in the log. Assets extracted from the RTL (GM-4) are shared on purpose. | A model transliterated from the RTL would share its bugs. Asset bugs are therefore out of scope for this check. |
| D-008 | 2026-10-09 | (Q-004) Inputs change in the vertical back porch, after the RTL's VSYNC capture edge (needs FS-1). The input-to-effect latency measured in RTL-3 becomes a named constant in the golden model. | Changing inputs on the capture edge makes latency depend on synchroniser delays; changing them in blanking also avoids cursor tearing. |
| D-009 | 2026-10-09 | (Q-005) `global_anim_phase` becomes frame-locked (RTL-1), advancing every N frames with N chosen to stay close to today's 25 Hz phase rate (N = 2 gives 30 Hz, N = 3 gives 20 Hz). | The small change in animation speed is acceptable in exchange for deterministic frames. |
| D-010 | 2026-10-09 | (Q-006) Mouse input is modelled as absolute position and buttons at the `MouseCtl` outputs (the framescope stub) for M1-M3. PS/2 packets through a ported controller (FS-10) come later, as a separate test of the driver. | Keeps scenarios simple and identical across golden, framescope and web shell. |
| D-011 | 2026-10-09 | (Q-007) Comparison order: state first (RAM dumps, probes, UART netlist), then decoded cells, then masked pixels with zero tolerance inside masks. Animation regions stay masked until RTL-1 lands. | State mismatches say what is wrong; pixel diffs only say that something is. |
| D-012 | 2026-10-09 | (Q-008) For M3 the solver is `src/uart_link`'s simulated solver, driven through a framescope UART RX driver (FS-7). Co-simulating `SolverBoard_top` (with floating-point IP models) comes later as a separate integration test. | Reuses an existing host-side model and avoids modelling the Xilinx floating-point IP up front. |
| D-013 | 2026-10-08 | Keypad uses the cursor's frame-latched mouse; caret toggles every ten VSYNC edges. | Deterministic one-frame input latency and stable per-frame pixels replace free-running UI clocks. |
| D-014 | 2026-10-08 | M2 colour references come from a reciprocal-port graph with row-major node numbering; default pixel masks exclude nothing. | The graph is independent of the RTL flood FSM. Stable checkpoints verify every pixel; dense-circuit flooding transients remain outside the current settled-colour regression. |
| D-015 | 2026-10-10 | Source polarity: for a voltage source `n0` is the + terminal (`v(n0) - v(n1) = V`); a current source drives current from `n0` to `n1` through the source, and extraction makes `n0` the terminal at the arrow's tail (beyond the partner half, since the arrow points towards the anchor half). The boot voltage source is turned 180 degrees so its + half faces the right rail: anchor at (4,2) with rotation 2, partner at (3,2), value 010, so node 0 reads +10 V. | Keeps the solver kernels, `solver_tester.py` and the voltage sprite consistent; only the current-source terminal order and the boot table change. |
| D-016 | 2026-10-10 | Snapshot id and reply acceptance: a snapshot is still sent every frame, but its frame id increments only when netlist-relevant canvas content (cell type/rotation/enable, component kind/position/rotation/value/unit) changed since the previous snapshot; the frontend accepts a reply only if its id equals the current snapshot id. | Meets the protocol's "ignore late responses", recovers from dropped lines, and makes the id predictable for the golden model (1 + number of content-changing frames since boot). |
| D-017 | 2026-10-10 | M3's "voltage display checked" uses the 7-segment display and LEDs through probes. An on-screen voltage readout is later work (new item). | It is the only voltage display the design has today. |
| D-018 | 2026-10-10 | Capacitors and inductors: the frontend reports a snapshot containing one as `@ER` code 81 (current RTL behaviour), and the golden model does the same. | Both the RTL and the simulated solver reject C/L today; the golden C/L DC model stays available as an option for later. |
| D-019 | 2026-10-10 | A floating component terminal (no facing port beyond it) gets its own solver row instead of ground. These rows are numbered after all region rows, in element `idx` order, `n0` before `n1`. | Electrically correct: an open resistor end carries no current, while a dangling current source makes the system singular and is reported. |
| D-020 | 2026-10-10 | `solve_core_dc.dsl.py`'s pivot search is fixed to compute the current U column before searching it; generated RTL and the simulated solver follow. | The as-written search pivots on stale zeros and divided by zero on 34 of 259 solvable fixture circuits. |
| D-021 | 2026-10-10 | Extraction connects a terminal only through a facing port (M3-A002) and a region is ground only if it contains a ground cell (M3-A003). The extraction kernel and generated RTL follow the golden rules. | Matches the reciprocal-port graph accepted for M2 (D-014). |
| D-022 | 2026-10-10 | Decision order for M3 work: each decision is written here first, then implemented independently in the golden model and in the kernels/RTL, and the M3 comparison checks that both agree (D-007). | Keeps the golden model independent of the RTL. |
| D-023 | 2026-10-10 | (Q-016) Solver rows are given only to regions touched by at least one component terminal, numbered by each region's first cell in row-major order; wire islands that no component touches get no row. Floating-terminal rows (D-019) follow them. Applies to the golden extraction, the extraction kernel and the generated RTL. | A stray wire would otherwise make every circuit singular. |
| D-024 | 2026-10-10 | (Q-017) A snapshot aborted by an edit after `@NB` is closed with `@ER,<id>,85,<lines>` (frontend error code 85, `arg` = number of `@NC` lines already sent) instead of stopping silently; the next snapshot follows as usual. | The host sees why a snapshot is incomplete; long netlists (five or more components) can be aborted routinely. |
| D-025 | 2026-10-10 | (Q-018) Element `idx` and `@NC` order are the anchor's row-major rank on both sides; the RTL ComponentStore must keep that order, as all dumps so far show. The first M3 scenario places parts out of order and reuses freed slots to check it; a divergence is an RTL bug under this decision. | One order fixes `@NC` order and floating-row numbers, and it is independent of slot allocation (A-011). |
| D-026 | 2026-10-09 | Refactor optimization retains the Basys 3 synthesis target (`xc7a35tcpg236-1`) and uses local AMD Vivado 2025.2 under `/opt/amd/2025.2`. | User direction; clarifies D-001: physical-board testing is unavailable, while FPGA implementation remains measurable. |
| D-027 | 2026-10-09 | Optimization runs use a frozen accepted contract and visual payloads, with semantic observation adapters that are checked against the baseline. Source-provenance metadata may change without changing reference behavior. | Prevents a renderer rewrite or adapter edit from changing both the implementation and its expected result together; permits module and memory reorganization. |
| D-028 | 2026-10-09 | A refactor is accepted only with both functional evidence and measured FPGA results under fixed constraints. Declare the objective, budgets and permitted latency changes before evaluating it. Behavioral changes are separate decisions, not automatic oracle updates. | Agents need an executable acceptance rule for preserving functions and evaluating area/timing tradeoffs. |
| D-029 | 2026-10-09 | M5 is the final readiness milestone. Seeded initialization, RTL/functional coverage, actual-RTL stress tests, invariants and the unified gate are prerequisites; sessions/MCP improve ergonomics but are not readiness blockers. | Strengthens evidence before broad architectural work without requiring all optional M4 tooling first. |

## Decisions to be made

Q-009 to Q-015 (M3 prerequisites) settled with the recommendations as D-015 to D-021; Q-016 to Q-018 settled as D-023 to D-025.

None open. Add new questions here as `Q-019`, `Q-020`, ... with options and a recommendation.

## Reference

Run framescope on this repo with the local Verilator:

```sh
cd ../framescope
FRAMESCOPE_RUNTIME=native METACIRCUIT=$PWD/../nus-EE2026-metacircuit \
  uv run framescope run -c examples/metacircuit -n 5 -s examples/metacircuit/stim_click.toml
```

Baseline numbers (2026-10-09, native Verilator 5.046):

- Build ~5 s; boot plus first frame ~3.2 s; then ~1.1 s per frame.
- Timing report: no violations except the expected 25 MHz vs 25.175 MHz pixel-clock warning.
- `stim_click.toml` (select resistor tool, move into the canvas) renders the expected tool highlight and cursor position.

## Log

- 2026-10-09: framescope native runtime fixed for Verilator 5.046 (framescope `b0cecf0`, branch `native-verilator-json-ports`). All 32 framescope tests pass on native 5.046 and docker 5.020, including the metacircuit integration test.
- 2026-10-09: framescope's timing report exposed the `VGAControl` off-by-one; fixed with sync/blanking alignment (`c5fee06`, branch `fix/vga-timing`). Column 639 now renders; all other pixels unchanged across a 5-frame click scenario.
- 2026-10-09: Plan written (this document).
- 2026-10-09: Q-001 to Q-008 settled with the recommended options (D-005 to D-012).
- 2026-10-09: RTL-1/RTL-2 (`34dc50e`): pixel-domain mouse latched at the VSYNC edge; animation steps every 2 frames. Idle frames now come in identical CRC pairs.
- 2026-10-09: framescope FS-1..FS-5 on branch `m1-harness` (merge `77ff7aa`): line-timed events, probes, memory dumps, `compare`, `batch`. 70 tests pass on native and docker.
- 2026-10-09: RTL-3 measured: an input changed in frame N's back porch is visible in frame N+1 (cursor, hover, toolbar, canvas edits; the edit lands in vertical blanking, no tearing). Dumps at the end of frame N+1 show it.
- 2026-10-09: framescope findings: CellStore is mirrored, not double-buffered; boot clear skips cells 1 and 2; ComponentStore entries above the count are stale; horizontal pan range is 0.
- 2026-10-09: Golden v1 in `golden/` (GM-1..GM-4, SC-1, SC-2): 71 unit tests, 2 Playwright tests, assets pixel-exact against RTL frames. 21 assumptions in `golden/ASSUMPTIONS.md` await human testing.
- 2026-10-08 (client date): User accepted the M1 human testing pass, including A-019's right/down/left/up rotation codes. Recorded in `golden/ASSUMPTIONS.md`.
- 2026-10-08 (client date): First full M1 RTL comparison: 267 frames, 12/25 checkpoints pass. First divergence at `blocked_placements`. RTL allowed overlapping placements, rotation into occupied cells, and lost the partner's nonzero value when rotating a boot resistor. The accepted golden interaction model was retained.
- 2026-10-08 (client date): Added `CanvasCommandGuard` to validate all destination cells before committing a placement or rotation. `InteractionController` now tracks canvas gesture origin, stamps components once per press and ignores right/middle-only input. Rotation copies value/unit/display text from the anchor to the new partner before clearing the old cell. Two focused RTL benches pass, including memory backpressure and rejection without partial writes. Vivado's source list includes the guard. Asset metadata regenerated; bitmap payloads unchanged.
- 2026-10-08 (client date): M1 achieved. Native Verilator 5.046 and Docker 5.020 each pass all 25 checkpoints over 267 frames; all 267 frame CRCs and all 200 memory dumps agree across runtimes. No late stimulus events or dropped interaction frames. Both the hand-written scenario and the saved web recording pass state comparisons. 86 golden tests, 3 Playwright tests, 20 asset tests, 2 RTL benches, and 70 framescope tests per runtime pass; typecheck/build/extraction checks pass. Evidence: [`m1-verification.json`](m1-verification.json).
- 2026-10-08 (client date): Confirmed cursor/toolbar/pan probes against the golden at every frame on both toolchains (267/267 each). Added `m1_latency.json`, with a RAM/probe checkpoint every frame and no wait margin: native passes 11/11, proving toolbar selection and the guarded canvas write still appear exactly one frame after the back-porch input change.
- 2026-10-08 (client date): M2 blockers implemented with three parallel agents: property/keypad core and RTL-6, full UI renderer and frame-locked caret, independent pixel cell decoder and node-colour graph. Fixed DEL removing a digit when deleting a unit suffix; `123k -> 123` now preserves BCD. Added full UI font/layout assets and blank-value rendering for newly placed components. Updated framescope's sibling checkout default and UI/text/colour probes.
- 2026-10-08 (client date): M2 automated pass: native 5.046 and Docker 5.020 each pass 103 frames / 22 checkpoints for state, UI/text probes, node-colour RAM and all 307,200 pixels per checkpoint at zero tolerance. All 103 CRCs and 176 memory dumps agree across runtimes. M1 still passes 267 frames / 25 checkpoints. 129 golden tests, 4 Playwright tests (including real-pointer M2 full-image hashing), 20 extraction tests, 3 focused RTL benches and 70 native framescope tests (2 environment-dependent skips) pass; typecheck/build/assets pass. Evidence: [`m2-verification.json`](m2-verification.json). M2 human acceptance remains pending.
- 2026-10-09: User accepted the M2 human validation (M2-A001..M2-A004, full-UI rendering, node colours); recorded in `golden/M2_ASSUMPTIONS.md`.
- 2026-10-09: Reproduced the M2 automated pass independently (native, 22/22 pixel-identical). Added `m2_node_colours.json` (connectivity edits with settled-colour checkpoints) and `m2_recorded.json` (web-shell recording of `m2_full_ui`, pinned equal to the source by a unit test and a Playwright record/download test). All three scenarios pass on native 5.046 and Docker 5.020 with zero differing pixels; frame CRCs and memory dumps are identical across runtimes, and the recording's RTL capture equals the hand-written scenario's.
- 2026-10-09: Asset provenance fix: `extract_assets.py` no longer records an `rtl_commit` field. It was always one commit behind when assets and RTL changes are committed together, which made `--check` and the byte-identical test fail after commit `9322a76`. Per-file sha256 pins the sources. Asset bitmap/colour data unchanged.
- 2026-10-09: M2 achieved. 130 golden unit tests, 5 Playwright tests, 20 asset tests, 3 RTL benches and 70 native framescope tests pass; typecheck and build pass. Evidence: [`m2-verification.json`](m2-verification.json).
- 2026-10-10: M3 prerequisites with five parallel agents. framescope FS-7 (`m3-uart`): UART monitor, scripted RX and lockstep host; 93 tests pass on native and Docker. Golden extraction/UART codec (`9709b47`, 161 tests) and DC solver (`fd599c0`, 193 tests, bit-exact against the simulated solver on 339 netlists). RTL-4 (`5312d7c`): flooding re-runs after edits with `SW[5]`, full-loop UART bench; M1 25/25 and M2 22/22 + 9/9 still pass. Boot netlist matches the golden byte for byte apart from the frame id. Findings settled as D-015..D-021: source polarity (boot read -10 V), stale replies accepted, voltage only on the 7-segment display, C/L handling, floating terminals grounded, kernel pivot bug, extraction rules vs simpyhls.
- 2026-10-10: D-015..D-021 implemented independently on both sides. Frontend RTL (`59ca445`): content-based snapshot ids, stale replies dropped and counted, boot source flipped (cells 39/40 = `0x0111`/`0x010F`, ComponentStore entry 0 = `0x0003C02044`). Kernels (`06ce3cf`, simpyhls `78efdf8` on local branch `m3-kernel-fixes`, not pushed): pivot fix in four solver kernels, facing-port terminals, ground by containment, floating-terminal rows, current-source orientation; solver RTL regenerated by `src/design/solver/regenerate_simpyhls.py` (it reproduces the old SV), and Verilator stand-ins for the floating-point IP let all five solver benches run. Golden (`7369a63`, `da6a5ff`): same decisions, independently derived boot words identical to the RTL's; bit-exact against the fixed simulated solver on 339 netlists and the fixed extraction kernel on 442 canvases. framescope `m3` (FS-6 + FS-7 merged, `m1-harness` fast-forwarded to it): 112 tests pass on native and Docker; checkpoints work with UART links. Regression on native 5.046 with the new boot circuit: M1 25/25, 25/25 (recorded), 11/11 (latency); M2 22/22, 9/9, 22/22 (recorded), 6/6 (boot), zero differing pixels; 207 golden unit tests, 5 Playwright tests, 5 RTL benches, 5 solver benches pass.

- 2026-10-09 (client date): M3 achieved. Implemented D-023 independently in the golden extraction and the simpyhls kernel, regenerated the extraction RTL, and updated the kernel's independent reference tests. Implemented D-024 in the frontend transmitter and both UART codecs: finish the in-flight line, send ER 85 with the interrupted id and completed NC count, then resume fresh snapshots. Added `verify:m3` and five scenarios for ordering/slot reuse, wire islands, values/units, connectivity, C/L/pico rejection, solver errors/recovery, stale/corrupt replies, physical display controls and current-source polarity (-0.1 V at 2 mA). Native 5.046 and Docker 5.020 each pass 482 frames / 42 checkpoints: 2,265 TX lines, 442 complete netlists, 439 delivered solver replies, four explicit aborts, 36 frontend rejections and 19 stale replies. All 482 frame CRCs/probes, UART TX/RX records and timings, and 504 RAM dumps are identical across runtimes. The receive model uses independently checked header timing to witness the extraction commit; mouse capture alone does not make an id current. Restored M2 anchor selection and its web recording: 107 frames / 23 checkpoints pass state/UI/colours/every pixel on both runtimes. M1 latency 11/11, 214 golden tests, five Playwright tests, 20 UART tests, 11 extraction-kernel tests, 20 asset tests, five frontend benches and five solver benches pass; typecheck/build/assets/regeneration checks pass. Evidence: [`m3-verification.json`](m3-verification.json). The simpyhls kernel/test changes are committed at `0d6f22a`; evidence pins their hashes. The new on-screen voltage renderer remains post-M3 P2 work under D-017.

- 2026-10-09 (client date): Added the final M5 milestone for large-scale autonomous refactor readiness. Promoted FS-11 to P1 and specified FS-8, frozen contracts/assets, stable semantic observations, actual-RTL stress tests with reduction, invariants/equivalence, solver-pipeline verification and a combined functional/Vivado acceptance gate. The user confirmed AMD 2025.2 is installed at `/opt/amd/2025.2`; the local Vivado executable and existing Basys 3 part selection were checked. This entry records a plan, not implementation or new verification results.

- 2026-10-10 (client date): Resumed M4 in parallel under default Codex quota guard. Added directed rotations/properties/boundaries/dense cases while retaining pinned v1/v2 generator bytes. Seed12x64 exposed the accepted A-007 wire reselection rule missing in ToolbarVGA; retained23frame witness, verified independent cold/FST failure and matching6RAMs, corrected RTL without changing golden. Native/Docker reduced fixed cases pass. Functional classifier now records64eligible bins and actual physical slot evidence. Golden224tests/17Python checks and framescope135tests per runtime pass(7opt-in skips). Final M2 passes298frames/61checkpoints per runtime with every pixel/CRC/probe/dump matching; six new cold seeds pass234frames/30checkpoints per runtime. Long/dense runs and M3 remain pending, so M4 is not yet marked complete.

## M1 acceptance and regression

Run from `golden/`:

```sh
npm run verify:m1 -- --runtime native
npm run verify:m1 -- --runtime docker
npm run verify:m1 -- --scenario scenarios/m1_recorded.json
npm run verify:m1 -- --scenario scenarios/m1_latency.json
```

The runner generates references, compiles stimulus, captures the checkpoint
memories/probes and writes `state-compare.json`. Missing evidence, mismatched
state, busy/drop flags or late stimulus events fail the command. The comparison
checks cells, components, values/units, toolbar and pan probes, mirrored RAMs,
and live slot/index-map consistency; slot ordering and flow metadata are ignored
under A-011/A-016. No pixel comparison is used to claim M1 completion.

The saved `golden/scenarios/m1_recorded.json` was downloaded from the web shell
after Playwright drove all accepted M1 inputs through real pointer events while
stepping frames. Its canonical inputs and checkpoint frame numbers are identical
to `m1_canvas_tools.json`; both reference sets were compared with the same native
and Docker RTL captures. This equivalence is also a unit regression.

Local full artifacts are in `golden/out/m1/rtl-fixed-native/` and
`golden/out/m1/rtl-fixed-docker/`, with the recorded reference/comparisons beside
them. Generated runs are ignored by Git. The tracked evidence JSON records the
results, toolchains and source hashes; the runner reproduces the full artifacts.
The existing 25 MHz timing warning remains expected. Boot-clear skipped cells,
and backend UART remain separate work. Keypad frame locking and full UI/pixel
verification were subsequently implemented for M2 below.

## M2 automated verification and remaining acceptance

Run from `golden/`:

```sh
npm run verify:m2
npm run verify:m2 -- --runtime docker
npm run verify:m2 -- --scenario scenarios/m2_boot.json
```

`m2_full_ui.json` checks 103 frames / 22 checkpoints, including toolbar/keypad
hover, either-half selection, active caret, reset, one-frame digit press latency,
BCD and unit editing, suffix/digit deletion, literal decimal text, ground summary,
outside selection, canvas clear and a newly placed blank-value component. The
runner checks M1 state first, then selection/value/text probes and independently
derived node-colour RAM, then full 640x480 PNGs. The default mask file defines
report regions only: no pixel is excluded and channel tolerance is zero.

References use the independent TypeScript model and reciprocal connectivity
graph. RTL palette snapshots were used separately during renderer triage, and
are not inputs to regression reference generation. The cell decoder diagnoses
failures from pixels while retaining symmetric rotations and cursor occlusion;
its flow-colour exclusion applies only to diagnosis, never acceptance pixels.

The M2 browser regression drives all scenario frames through real pointer events
and checks semantic properties and a full ImageData hash at every checkpoint.
That verifies web/headless agreement; it does not replace human validation.
[`golden/M2_ASSUMPTIONS.md`](../golden/M2_ASSUMPTIONS.md) records the property/keypad
choices requiring that pass. Dense-circuit flooding transients and more than 255
isolated nodes are not covered by this settled-colour regression; the independent
graph uses wider IDs so it can expose the RTL's eight-bit node limit.

`m2_node_colours.json` (78 frames / 9 checkpoints) edits connectivity on the
boot circuit and checks the settled colours after each edit: a rail split, an
unjoined horizontal wire, rejoining it by rotation, ground removal, an unjoined
re-placed ground and its rotation to join, resistor removal, and a rail short.
`m2_recorded.json` is the web-shell recording of `m2_full_ui.json` (real pointer
events through Playwright); its inputs and checkpoint frames equal the source,
and its RTL capture is identical to the source's frame for frame.

M2 is achieved: the user accepted the human validation of the full UI on
2026-10-09, and all three scenarios pass state, UI probes, node-colour RAM and
every pixel at zero tolerance on native Verilator 5.046 and Docker 5.020, with
identical frame CRCs and memory dumps across runtimes. Evidence is recorded in
[`m2-verification.json`](m2-verification.json).

## M3 acceptance and regression

Run from `golden/` with the sibling framescope checkout containing FS-6/FS-7:

```sh
npm run verify:m3
npm run verify:m3 -- --runtime docker
npm run verify:m3 -- --scenario scenarios/m3_backend.json
npm run verify:m3 -- --scenario scenarios/m3_backend.json --actual out/m3/my-run/m3_backend/rtl
```

The default runs all five M3 scenarios with `SW=32` and the actual D-012
simulated solver host. The independent golden state determines extraction,
component order, snapshot ids, frontend rejection records and solver replies.
The runner checks M1 state first, every complete TX line byte for byte, and every
delivered RX reply bit for bit. At checkpoints it checks extracted-node RAM,
active voltage RAM, accepted/stale reply state, display node/half/value and LED
status/view bits. TX/RX activity LED bits depend on serial timing and are outside
the semantic LED comparison; the full-loop RTL bench separately decodes the
physical multiplexed 7-segment pins.

| Scenario | Frames | Checkpoints | Checks |
|----------|--------|-------------|--------|
| `m3_backend` | 139 | 12 | Boot +10 V, wire island, source value/unit edits, out-of-order placement, slot reuse, four ER 85 closures |
| `m3_connectivity` | 114 | 9 | Split/rejoin rails, reciprocal terminals, floating rows, ground removal/restoration, shorted rails, solver errors |
| `m3_errors` | 124 | 8 | Real solve delayed past an edit, stale ER, bad checksum, C/L/pico rejection, zero resistance, recovery |
| `m3_display` | 38 | 7 | BTNL/BTNR/BTNU/BTND; upper/lower float32 halves of 10 V and 0 V nodes |
| `m3_current_source` | 67 | 6 | Arrow-tail n0, 2 mA toward ground gives -0.1 V (`BDCCCCCD`), both display halves |

Snapshot transmission can span video frames. An edit after NB closes a prefix
with ER 85, and all completed prefix records and the abort count are checked.
UART header timing, after its content and id pass independent comparison,
witnesses when extraction commits for accepting replies. A final capture
boundary may leave a byte, snapshot or queued response pending; this is reported
and does not excuse any complete-line mismatch or missing checkpoint evidence.
The current scenarios end between complete TX snapshots; three final solver
responses fall beyond the finite capture windows across the five runs.

M3 is achieved under D-017: 482 frames / 42 checkpoints pass on native 5.046
and Docker 5.020. Every frame CRC/probe, UART TX/RX line and timestamp, and all
504 checkpoint memory dumps agree across runtimes. References, stimulus, RTL
captures and comparison reports live in ignored `golden/out/m3/`; tracked
[`m3-verification.json`](m3-verification.json) records results, source hashes and
artifact paths. Corruption tests prove the runner fails changed netlist/reply
bytes, snapshot ids, voltage RAM, display values and missing reply evidence.
The restored M2 recording also remains equal to its source at every input frame
and checkpoint. On-screen voltage rendering (M3-4) is later work; the accepted
voltage display for this milestone is the existing board display.

## M4/M5 plan: autonomous refactor readiness

M4 is complete in its declared settled frontend scope. Evidence is recorded in
[m4-verification.json](m4-verification.json), with commands and exclusions in
[M4_ASSUMPTIONS.md](../golden/M4_ASSUMPTIONS.md). Each runtime reaches64/64 named
functional bins; directed cases pass973frames/79checkpoints per runtime, six new
cold seeds pass234frames/30checkpoints per runtime, and fixed seed12x64 passes
794frames/65checkpoints natively. Native/Docker coverage artifacts validate five
checkpoints and report gaps for101module/hierarchy groups. Both complete M2/M3
regressions pass on final source, preserving pixels/UART/semantic state.
The startup clear and A-007 toolbar defects have retained reduced cold-replayed
witnesses; accepted golden behavior was preserved. Continuous transients,
stalls, actual solver RTL and FPGA optimization acceptance remain M5 work.

M1-M3 support incremental refactoring today. They are not yet sufficient to
qualify a rewrite as broad as `design2`: checkpoint comparisons can miss
transients, randomized kernel tests execute software rather than generated RTL,
M3 bypasses the hardware solver through its Python host, and observation paths
encode the current hierarchy and RAM layout. There is also no combined gate for
functional correctness, exercised RTL paths and FPGA resource/timing results.

### Work order and responsibilities

| Stage | Work | Output |
|-------|------|--------|
| 1 | M5-1/M5-2: freeze the contract and establish semantic observation adapters | Pinned baseline, immutable visual payloads, documented timing/latency rules and verified-scope manifest |
| 2 | FS-8/FS-11 and M5-3: seeded startup, RTL coverage and reproducible stress tests | Per-module coverage gaps, named functional bins, seeded scenarios and minimized counterexamples |
| 3 | M5-4/M5-5: invariants, targeted equivalence and actual backend RTL verification | Continuous safety/progress checks, proof results/assumptions and RTL solver evidence |
| 4 | M5-6: automate Basys 3 implementation measurements | Reproducible baseline/candidate resource and timing reports |
| 5 | M5-7/M5-8 and INF-4: integrate and demonstrate acceptance | One local/CI gate, negative-control results, one verified optimization and `m5-verification.json` |

Generic initialization, coverage, trace and session capabilities belong in
framescope. MetaCircuit contracts, adapters, generators, reducers, assertions
and acceptance policy belong in this repository; kernel/compiler changes remain
in simpyhls with regenerated RTL checked against their pinned source. FS-9 can
accelerate stepping and first-divergence diagnosis after the basic gate works.
FS-12/MCP and the new on-screen voltage renderer are optional for readiness.

### Behavior and coverage requirements

The contract must preserve the accepted interaction rules, pixel output,
netlist content/order/ids and reply/display behavior. Distinguish semantic
state from physical implementation details: renaming an instance, changing an
FSM encoding or repacking RAM must not silently drop a check. Preserve
atomicity, transaction ordering, frame-visible effects and specified progress
bounds through the semantic adapter. Any permitted retiming must be represented
in the contract before candidate results are evaluated; waiting arbitrarily
longer for a settled checkpoint is not a substitute for checking latency.

Freeze bitmap/font/palette/layout payloads and the accepted golden algorithms
for an optimization run. The asset extractor can update provenance or diagnose
the candidate, but must not replace the reference payload with candidate-derived
data. Likewise, changes to masks, tolerances, seeds, coverage exclusions or
observation adapters must remain visible in the acceptance report. Known
baseline defects require separate recorded decisions and regression cases;
old/new equivalence does not make a known defect the intended behavior.

Functional coverage must name the important combinations, including component
kind/rotation/unit, all canvas edges, blocked placements, partner selection,
slot reuse, empty and near-capacity stores, floating/grounded terminals, held
buttons, stalls, edits during flooding/extraction/each UART phase, stale replies
and malformed/incomplete packets. Add continuous checks between frame samples
for protocol and memory invariants; compare frame results wherever the contract
defines them. Record eligible, reached, uncovered and excluded bins per module,
with reasons for exclusions. A high aggregate line/toggle percentage alone
cannot establish readiness.

The gate must define and pin a seed corpus and runtime budget, plus a mechanism
for adding new seeds and retaining every minimized failure as a regression.
Use fast module benches for large fixture populations and full-frame scenarios
for integrated behavior. The initialization mode, random seed and any checkpoint
state must be recorded together; startup tests must not inherit a baseline's
already-initialized RAM and thereby conceal a candidate reset bug.

### AMD toolchain and FPGA measurements

The locally available executable is:

```text
/opt/amd/2025.2/Vivado/bin/vivado
```

Target part: `xc7a35tcpg236-1` (Basys 3). The existing frontend is
`GlobalRender_top`; solver-board work uses `SolverBoard_top` and its own source/IP
manifest and constraints. Existing project Tcl and `solver_board_synth.tcl`
provide starting points, not a completed refactor gate. The scripts must use
portable paths, the actual synthesis sources (including VHDL/IP where needed),
and the correct top-specific constraints. Simulation mouse/FP stand-ins are
not substitutes for the FPGA implementation source manifest.

Plan a repository-owned batch Tcl runner and report parser. For example, the
future invocation would have this shape; the script below is **not yet
implemented**:

```sh
/opt/amd/2025.2/Vivado/bin/vivado -mode batch \
  -source tools/vivado_qor.tcl -tclargs GlobalRender_top golden/out/qor/baseline
```

Measure synthesis first for development feedback, then routed implementation
for acceptance. Record clock periods/generated clocks, I/O timing, clock-domain
crossings, unconstrained paths, critical-path logic and routing contributions,
setup/hold timing and LUT/FF/BRAM/DSP use. Source, constraint and IP hashes,
Vivado build, part, strategy, run seed where supported and implementation
settings must match the recorded comparison policy. A pass cannot be produced
by weakening clocks, adding unjustified timing exceptions or changing the
source/top manifest. HDL line count and simulation wall time are not FPGA
resource or timing metrics.

Characterize the untouched baseline first. If it already misses timing or
contains unresolved constraint/CDC issues, record that status explicitly and
establish a bounded improvement target; do not call it timing-clean. Declare
which resources or paths an optimization targets and what increases in other
resources or internal latency are allowed. Final reports must show both the
baseline and candidate values, their deltas, and compliance with that policy.

### Final milestone acceptance and scope

M5 is complete only when M5-1..M5-8, FS-8/FS-11 and INF-4 have executable evidence.
The unified runner must emit machine-readable results, fail for missing/stale
mandatory evidence, and preserve a replayable scenario plus a trace window for
a simulation failure and the associated reports for a synthesis/timing failure. Validate the gate with deliberately corrupted output/adapter/coverage
or resource-report cases, not only successful runs. Demonstrate it with one
bounded optimization under the same frozen contract and measured objective.
`docs/m5-verification.json` must identify the verified module/input scope and
any outstanding limitations; the M5 status remains **not started** until work
begins and is not declared achieved merely because tools were added.

Solver datapath changes require M5-5 evidence from actual RTL, including the
configured floating-point primitive assumptions. PS/2 driver changes require
FS-10 or equivalent device-level verification before that scope is qualified.
Clock/reset/CDC changes require corresponding clock-domain and timing evidence.
Modules outside the recorded verified scope cannot inherit readiness from a
passing frontend suite. Physical-board validation is unavailable and is not
claimed by this milestone.

Once ready, autonomous work proceeds by selecting a measured bottleneck,
recording its objective/budgets, making a bounded change, running focused checks,
and then passing the full gate before accepting each implementation change. The agent can
repeat this across a large refactor without changing the accepted oracle to
fit the candidate. Intentional functionality changes are tracked separately
from implementation optimizations.
