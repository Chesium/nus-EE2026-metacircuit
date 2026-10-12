# Verification plan: golden model + framescope

Living document for making MetaCircuit deterministically testable without hardware.
Track progress here: tick TODOs, append to the log, and move questions from
"to be made" to "made" when settled. IDs are stable; never reuse one.

Last updated: 2026-10-10 (client date; M4 accepted baseline complete, M5 qualification in progress)

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
| M5 | Final milestone: prepared for large-scale autonomous refactoring with preserved behavior and measured FPGA improvements | in progress: frontend contract/adapter qualified; scoped stalls pass both runtimes; real frontend synthesis characterized but over Basys 3 LUT capacity and route fails; solver/IP, global invariants, coverage policy and full acceptance remain |

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

- [x] M5-1 (P1) Freeze the accepted baseline and contract: start from metacircuit `2ff7f3a`, simpyhls `0d6f22a` and the framescope revision pinned by M3 evidence. Pin golden behavior, visual payloads, scenarios, constraints and known limitations; define exact output timing versus bounded internal latency. Record the modules and input ranges covered by readiness.
- [x] M5-2 (P1) Stable semantic observation adapter: expose logical cells/components, UI state, netlist events and accepted voltages independently of instance names, FSM encodings, slot packing or physical RAM banks. Validate adapters against the frozen baseline. Preserve semantic guarantees and required atomicity while allowing implementation layout to change.
- [ ] M5-3 (P1) Seeded randomized tests against actual RTL, using FS-8/FS-11: interaction sequences, rapid edits, dense circuits, boundaries/capacity limits and configurable memory stalls. Check every frame where the contract defines a result; use continuous properties elsewhere. Save seed, inputs and first divergence, reduce failures to replayable scenarios, and require the reduced case to reproduce in a cold run. Current source (2026-10-12): native 5 seeds × 64 operations pass with coverage (3784 frames/325 checkpoints); Docker seeds 1/7/2026/11 pass (2990/260), seed 12 pending a healthy Docker host.
- [ ] M5-4 (P1) Continuous invariants and progress bounds: stalled request data stays stable, commands are neither lost nor duplicated, rejected edits produce no partial writes, cell/component maps agree, queues stay in range, replies commit atomically and accepted work finishes within specified bounds. Add targeted old/new equivalence or formal proofs for suitable modules; preserve proof assumptions and report unsupported/inconclusive checks separately from passes. Done when the gate's continuous invariant observers (canvas/controller, frontend, supplemental, restart, flood queue, domains) and the six scoped proofs (FIFO order, guard and component progress, reply parser, banks and integrity) pass on both runtimes. Global atomicity/progress theorems and general formal proofs are outside M5 (D-031).
- [ ] M5-5 (P1) Extend backend verification to the generated RTL and real solver pipeline: feed randomized extraction/solver fixtures through RTL, and exercise the frontend-to-`SolverBoard_top` UART path. Validate floating-point primitive behavior and latency against the configured IP before using stand-ins as acceptance evidence. The M3 Python-host result alone does not qualify solver datapath changes. Done when the actual-IP solver benches, FP characterization, generated extraction and frontend-to-solver UART checks pass in the gate. Ill-conditioned accuracy is a recorded design limitation (BUG-2) checked only for regression. SolverBoard synthesis/QoR and the original-XCI IP upgrade move to QOR-2 (D-031).
- [ ] M5-6 (P1) Script Vivado 2025.2 synthesis and routed implementation for Basys 3 (`xc7a35tcpg236-1`), with explicit tops, source/IP manifests and clock/I/O constraints. Record per-module and total LUT/FF/BRAM/DSP use, critical-path logic levels, WNS/TNS, hold timing, clock/CDC checks and unconstrained paths. Preserve reports, checkpoints, warnings and exact run settings in a machine-readable summary. Done once the current baseline is characterized; timing closure is not required (D-030). Comparisons use the frozen `tools/qor/basys3_m5_timing.xdc` (production constraints plus the derived pixel clock); the production XDC stays unchanged. Baseline setup violations, missing I/O delays and other findings are recorded as known debt for TIM-1.
- [ ] M5-7 (P1) Unified autonomous acceptance gate: fixed regression corpus plus seeded RTL tests, invariants/equivalence, coverage requirements and Vivado deltas. Return a nonzero exit for any mandatory failure, missing/stale evidence or unexplained coverage exclusion. Coverage (D-031): 64/64 functional bins are mandatory; line/branch/toggle coverage is reported on every run and a changed module may not lose coverage against the recorded baseline. Record the optimization objective and allowed area/latency/timing tradeoffs before evaluating the candidate; a functional pass alone cannot qualify an optimization. Timing is a no-regression rule against the recorded baseline (D-030): hold WNS >= 0, setup WNS no worse than baseline (0 ns tolerance), and no new check_timing, DRC or CDC findings.
- [ ] M5-8 (P1) Demonstrate readiness: the unchanged baseline passes the declared functional contract, its synthesis/timing status is characterized (not closed), deliberate behavioral and report/coverage corruptions fail the gate, a seeded failure is reduced and replayed, and one bounded optimization passes with a measured gain (its objective may declare a setup WNS tolerance before measurement; the default is 0 ns). Archive `docs/m5-verification.json` with the scope, thresholds, seeds, coverage gaps/exclusions, results and source/tool/constraint hashes.
- [ ] M5-9 (P1) Gate turnaround for iterative experiments: the scoped and full stages run independent checks concurrently (`acceptance_m5.py --jobs`, default a quarter of the CPUs so native and Docker gates can run side by side), with explicit dependencies only where evidence flows (FP characterization before solver checks, every seeded run before the coverage audit) and critical-path checks first. The seeded corpus runs one frozen-comparator invocation per seed. Per-command time limits (`command_timeout_overrides`) replace the single 1-hour limit. Target: one full gate per runtime in about an hour instead of about four, with the same commands and evidence checks (D-032).
- [ ] TIM-1 (P2, after M5) Timing closure: setup WNS >= 0 on the frozen comparison constraints, external input/output delays, reviewed CDC waivers and qualification of the production XDC. Not an M5 prerequisite (D-030).
- [ ] QOR-2 (P2, after M5) SolverBoard_top synthesis/routed QoR with its own manifest and constraints, including upgrading or regenerating the floating-point XCIs locked at 2018.2/rev6 for Vivado 2025.2. Required before solver datapath optimization experiments; not an M5 prerequisite (D-031).

### Known design issues (BUG)

Design defects found by the harness. They are tracked here, fixed through the rebaseline path, and do not block M5 (D-031).

- [ ] BUG-1 (P2) Matrix-store epoch alias: after 65,536 or more continuous reset clocks an unwritten cell can return stale region data instead of zero (`docs/m5-invariants.md`, `golden/out/m5-epoch-qualification-20261011d/`). The valid-only correction passed its store ledger and proofs but has not been integrated.
- [ ] BUG-2 (P2) Solver accuracy on ill-conditioned circuits: the near-singular probe returns 0.5185897 for an expected 0.50000025 (about 3.7% relative error, no FP exception). The gate checks that this error does not grow (`docs/m5-decisions.md`, solver numerical robustness).
- [ ] BUG-3 (P3) Coverage corpus limits: the regression corpus leaves many lines, branches and toggles unreached (per-module counts in the coverage baseline). Expanding the corpus is optional future work; it is not a pass condition.

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
| D-030 | 2026-10-11 | M5 characterizes timing but does not close it. Optimizations are compared under the frozen `tools/qor/basys3_m5_timing.xdc` against the recorded current baseline (10149 LUT/4197 FF/10 BRAM, setup WNS -1.953 ns, hold +0.027 ns); hold must stay clean, setup WNS may not get worse (0 ns tolerance), and check_timing/DRC/CDC findings may not increase. Closure moves to TIM-1. | M5 delivers the verification/observability harness for later optimization experiments; requiring a timing-clean design blocked M5 on optimization work itself. |
| D-031 | 2026-10-11 | M5's goal is the verification/observability harness for later autonomous timing/resource optimization experiments, not a defect-free or fully proven design. Readiness comes only from checks that run. Coverage: 64/64 functional bins required; structural coverage is measured on the native runtime over the whole cold run, boot and scenario (Docker 5.020 coverage runs at ~17 s/frame, ~18 h per corpus) and reported, and changed modules may not lose coverage against the recorded baseline; Docker runs the same corpus uninstrumented. M5-4 is the gate's continuous observers plus the six scoped proofs; global/general proofs are out of scope. M5-5 excludes SolverBoard synthesis (QOR-2); ill-conditioned accuracy is checked for regression only. Design defects become BUG items fixed through the rebaseline path. An optimization objective may declare a setup tolerance (default 0 ns). | Earlier runs treated design defects, 100% structural coverage and global formal theorems as M5 blockers, so the harness could not be declared ready. |
| D-032 | 2026-10-12 | The acceptance gate runs independent checks in parallel with a bounded worker pool and explicit dependencies; only ordering changes, not the checks or their evidence. The seeded corpus is split into one `verify_m4.py` call per seed because the comparator is frozen by the contract. Per-command time limits are configured in the policy. | Each check is a single-threaded simulation and the gate ran them one after another (~4 h per runtime with the native coverage corpus alone ~2¼ h), which is too slow for iterative optimization experiments. |
| D-033 | 2026-10-12 | The gate retries `framescope-tests` once when every error in its unittest log is the pinned Docker Verilator 5.020 crash `Internal Error: attempted to destroy locked Thread Pool` and there are no assertion failures. The first attempt's log is kept and the retry is recorded in the report. | The crash appears when that Verilator compiles with `-j 0` on a loaded host (seen twice while the native gate's parallel stage ran); framescope is pinned by the contract, so its compile flags cannot change. |

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
do not call it timing-clean. Timing closure is not an M5 goal (D-030): the gate
rejects any regression against the recorded baseline instead of requiring
non-negative slack, and closure is tracked as TIM-1. Declare
which resources or paths an optimization targets and what increases in other
resources or internal latency are allowed. Final reports must show both the
baseline and candidate values, their deltas, and compliance with that policy.

### Correctness fixes and rebaselining

The optimization gate compares a candidate with the recorded baseline; it is not
the path for correctness fixes, which may legitimately cost area or slack. A
correctness fix (for example a BUG item) instead records a decision in
`docs/m5-decisions.md`, passes the fast and full functional gates, and then
updates the recorded baseline in one change: the QoR baseline pins
(`qor_baseline_corrections`), the timing baseline (`qor_timing_policy.baseline`,
from a fresh routed run under the frozen comparison XDC), the coverage baseline
(`verify_coverage_m5.py --write-baseline` on a full seeded coverage run from both
runtimes) and, for solver changes, the accuracy baseline. Later optimizations are
judged against the new baseline.

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

## M5 resume checkpoint (2026-10-10)

M4 completion applies to the accepted corrected frontend baseline. M5-1 freezes
254 immutable entries under trusted frontend-v1 identity
`475a48362f0f353104abfde654c25f7bdc60acc266c7a774ca6b256d315b540e`;
M5-2 qualifies settled adapters on 18 M2/M3 captures (206 checkpoints) and eight
M4 directed captures (158 checkpoints). UI/backend independent oracles remain
mandatory. The separate gate policy pins adapter/config and supplemental inputs.

Continuous controller/guard invariants now exercise genuine read/write stalls,
three reply delays and four specific corruption/withheld-reply controls on both
runtimes. Global map/queue/reply visibility, formal assumptions and architectural
progress bounds remain outside this scoped evidence; M5-4 stays incomplete.

Actual generated extraction320 fixtures, solver UART36 analytic circuits and a
physically connected frontend-to-SolverBoard boot/edit exchange pass provisionally.
Actual configured FP qualification is being investigated with existing generated
products, while original XCI revision/provenance remains explicit. M5-5 stays open.

Vivado2025.2 frontend synthesis with real MouseCtl and unchanged constraints
uses24117 LUT/13677 FF/10 BRAM/0 DSP; routed attempt fails UTLZ-1 after optimization
still requires22138 LUT (>20800 available). Synth WNS=-5.176ns; missing clock/I/O
constraint and CDC scope remain unqualified. A separate immutable-input synth
baseline is complete. Two finite address decoder candidates passed exhaustive
equivalence; compare/subtract candidate also passed native/Docker frontendsmoke.
Both worsened measuredLUT/WNS and were rejected. Original acceptedfrontend
arithmetic is restored; no optimization acceptance is claimed.

New `tools/acceptance_m5.py` and manual native/Docker CI workflow share development,
unchanged-baseline capture qualification and full-readiness modes. Native baseline
qualification passed before the solver-wrapper fix; finalfast gates pass onboth
runtimes. Full mode fails missing mandatory M5 scope, reports and
coverage policy; INF-4/M5-7/M5-8 stay incomplete. See docs/m5-acceptance.md and
docs/handoffs/m5-verification.md for current jobs and next steps.

Final checkpoint: both native/Docker fast gates pass, including final production
FMA exception-port correction (four bits to configured three). Actual XSim direct
production SolverBoard passes38solves/127UARTlines with16/28cycle vendor FP,
checksum recovery and singular status05/negative infinity; no source override.
Both address optimization attempts are rejected (+354/+938LUT and worseWNS);
accepted frontend arithmetic is restored. Frontend observers qualify maps/reply
banks/queue conservation in their historical candidate capture scope; restored
source and staged-abort/broader-layout runs remain. Full-readiness gate rejects
missing routed QoR/objective before expensive tests. M5 remains incomplete.

Quota checkpoint: M5 remainsincomplete; defaultguard teamshutdown at9%five-hour/33%weekly. Allagents/jobsfinished, finalfastgatespass; resume from docs/handoffs/m5-verification.md underfreshlivequota.


## M5 resume checkpoint (2026-10-11)

M4 remains complete. A-008 readiness/read-retirement defect fixed and coldwitnesses
pass onbothruntimes. Expanded frontend stage/map/progress observers qualify fixed
baseline and isolated shadowcandidate. BothM2fullcorpora and nativeM3pass;
DockerM3 stopped at quota with partialpassing reports. ActualIP59solvercases pass;
near-singularphysicalaccuracy and augmentedMNA33capacity fail explicitly.
Defaultbaud actualfrontend boot/coldnegative pass; editedlooptimeout unqualified.
Shadow write normalization saves14008synthesisLUTs and actuallyroutes10089LUT/
4166FF, but setupWNS-1.657ns and clock/I/O/CDC findings fail acceptance. Candidate
remains isolated. Executablecoveragepolicy rejects gaps/unreviewed scope. M5 is
incomplete; guard latched9%five-hour/18%weekly shutdown, separatehandoffs saved.
Continue from docs/handoffs/m5-verification.md under fresh quota.

## M5 continuation checkpoint (2026-10-11, current)

M4 remains complete. Corrected A-008 M3 now passes all five scenarios on both
runtimes (482 frames /42 checkpoints each), including the newly completed Docker
error/recovery scenario. Isolated shadow candidate native full M3 passes; its M2
corpus and Docker M3 are being completed. Current candidate coverage passes
native/Docker integrity audit, but module/input obligations and eligible gaps
keep readiness false. Parameter-specialization identity matching is corrected.

Five-phase mid-rebuild dirty-restart observations pass both runtimes, with four
specific controls and a declared quiescent deadline1744 clocks after the last
accepted edit. This is bounded directed evidence, not arbitrary-stall/formal
proof. Separate actual generated extraction qualification passes320 seeded
fixtures on both runtimes without promoting FP simulation models. Full gate now
requires those scoped reports, supplemental first-ready observations, restart
checks and the actual default-baud frontend edited loop; tool/observer inventory
changes during a gate are rejected. Final fast gates are pending new pins.

A separately declared capacity guard candidate rejects augmented dimension33
with ER03/0021 before solver_start and preserves300 UART reply lines over59
supported actual-IP solves. It remains isolated pending integration. Reset-free
FIFO lifetime fails at enqueue1152 on both runtimes; integrated lifetime reachability
is unresolved, because flooding clears each run and appears bounded to4enqueues
per visited cell. No production queue change is claimed.

Derived pixel-clock timing exposes previously omitted hold violations and a
coord_len latch. External asynchronous pad/reset timing remains unqualified.
A balanced BCD-text candidate fails its predeclared area objective (-141 LUT
gain); it is rejected. Proper dual-clock isolated routing is planned. M5 remains
incomplete. Current jobs, evidence and recreation assignments are recorded in
[the M5 handoff](handoffs/m5-verification.md).

Final2026-10-11checkpoint: isolated shadow fullM2/M3 passes both runtimes and
exact-frameM1passes. Actual defaultbaud frontend+vendorFP/currenthelper controls
and isolated augmented-capacity rejection/recovery pass. Full readiness remains
incomplete; final nativefastgate passes, Dockerretry retains one real ThreadPool
build error. Five64op coldcandidate seed corpus was safely interrupted before
completecase qualification. Guard latched shutdown at9%five-hour/86%weekly;
allagents/jobs stopped, separate handoffs saved. Resume from m5-verification.md.

## M5 continuation (2026-10-10 client date, current guarded run)

The independently qualified augmented-MNA capacity correction is integrated into
production SolverBoard: dimensions above32 reject with ER03 and requested
dimension before solve. Fresh actual-IP evidence passes59supported solves and
300byte-identical replies, exact dimension33 rejection, and dimension32 recovery
after one/two-voltage-source rejection. The maintained capacity runner rechecks
source/tool/library/report pins and catches two specific cold corruptions.

A separate frontend domain suite passes both pinned runtimes:144components,
41keyboard events/all6unit suffixes,8selection transitions and bounded restart/
clear backpressure fixtures. Existing six observer suites retain unchanged
source identity. The unified full gate now requires this suite and current
actual-IP capacity/recovery evidence. Current native fast gate passes; Docker
retry is underway after its unchanged135test harness suite passed. Full mode
continues to reject missing mandatory FPGA reports/objective before regressions.

Isolated coord_len default insertion passes actual-source cone equivalence and
negative controls, removes the inferred latch/no-clock/unconstrained endpoints,
and improves routed setup from-1.816ns to-1.585ns, with hold+0.022ns. It passes
its separately declared bounded objective; global setup and external I/O/CDC
still fail full readiness. Two address-path proposals fail their frozen area
objectives and remain rejected/unintegrated.

Actual-wrapper flooding ledgers qualify the directed1152enqueue bound after
real reset/clear, but do not prove arbitrary/cold pre-clear safety. A retained
real-reset16-bit epoch alias returns stale region1 for blank input, reproduced
onbothruntimes. A validity-bitmap correction passes isolated ledgers/alias
controls; production integration and full frontend/QoR qualification remain
open. Current defaultbaud frontend and cold64operation candidate corpus are
running. M5 remains incomplete; see the coordinating handoff for current state.

Final guarded checkpoint: production capacity guard,59actual-IP solves/300UART
replies, capacity rejection/recovery and actual default115200frontend edited loop
all pass fresh source/control checks. Both pinned fast gates pass. Latch-only
isolated full M2 passes298frames/61checkpoints per runtime; scoped routed objective
passes, global timing/IO still fails. Coverage reaches28/64native and12/64Docker
with unchanged thresholds/exclusions. Seed1x64 passes713frames/65checks; four
other coldcases were safely interrupted at quota and have no passing verdict.
Team shutdown latched8%five-hour/71%weekly; finalcheck4%/70%, allownedagents/jobs
stopped, separate handoffs inspected. M5 remains incomplete; continue from
[the coordinating handoff](handoffs/m5-verification.md) after a fresh live check.

## M5 continuation (2026-10-11 client date)

Production now has exact FIFO head/tail wrap at DEPTH-1 and the panel coord_len
combinational default. Both pinned runtimes pass maintained lifetime/ordered
overlap ledgers at depths1/3/4/1152 with specific corruption controls. Actual-source
Yosys0.33 reset-base/one-step induction proves range/count preservation; original
non-power-of-two versions yield required counterexamples. Cold pre-reset safety
and arbitrary formal FIFO data order remain separate gaps. The full gate pins and
requires this queue safety verifier;15gate fixture tests pass. Fast gates and
current queue/panel/shadow composed functional/QoR qualification are underway.

The epoch bitmap's stronger watched-cell proof and both-runtime fullM2 pass remain
isolated evidence. Its composed related-clock route measures10671LUT/4740FF/
9.5BRAM/0DSP, hold+0.007, internal unknowns0/0, but WNS-2.699 fails the frozen
-2.0ns floor, so the candidate remains rejected/unintegrated. Coverage expands
to48/64native and20/64Docker functional bins; one native properties run and final
raw audit remain active. Four remaining unchanged-shadow cold64operation seeds
are progressing, not yet qualified. Full M5 remains incomplete; see the handoff
for exact evolving source scopes and guarded job state.

The remaining4coldnativev2x64cases complete794/756/727/794frames and65checks
each, all source/initialization/comparison audits pass. Together with historical
seed1 (713/65), fivecase corpus reaches3784frames/325checks. Root adopted exact
reviewed shadow-write normalization with preserved same-edge NBA behavior.
Current source also includes queue/panel corrections and the previous capacity
guard; epochbitmap/XDC/rejected arithmetic remain separate. New isolated
shadow+panel+guard native fullM3 passes482frames/42checks; current production
composedM2/QoR/actualvendorFP frontend and freshfastgates remain in progress.
Oldfastgatesfailed staleassetprovenance, and Docker additionally retains two
lockedThreadPool errors; metadata refreshed with254frozenbehavior entries passing.
A passing harness subset is not a complete gatePASS.

Current adopted queue/panel/shadow/guard fullM2 passes298frames/61checks onBOTH
runtimes, exactpixels/state/UI/source/init/harness/simpyhls preserved. Current
relatedclock scopedroute passes10092LUT/4157FF/9.5BRAM,setup-1.333/hold+0.047;
fullglobaltiming/externalIO/CDC stillfails. Both freshcurrentfastgates pass all
mandatorychecks after provenance refresh and unchangedDocker retry; original
ThreadPool failures remain recorded with unknowncause. OldFIFO/epoch isolated
shadow+panel+currentguard fullM3 passes482/42onBOTH runtimes via completed-source
audits. Oldshadowrawcoverage reaches61/64native,20/64Docker, integritytrue/
readinessfalse; currentproduction freshrawcampaign and actualIPfrontend pending.

Final currentactualdefault115200/vendorFP frontend passes bootframe3/duplicate5/
editedsplitrail12 plus specificcoldnegative and sources unchanged (52FMA/53DIV).
Both currentproduction m3_current_source fixtures also pass67frames/6checks;
currentrawcoverage scenario/boot audits pass integrity,8/64bins eachruntime,
explicitgap/readinessfalse. ProvidedisolatedrelatedclockQor cannotqualify
productionXDC and fullgate rejects itbeforetests. M5 remainsincomplete.

Guardedfinalcheckpoint: teamshutdownlatched at9%five-hour/86%weekly afterall
ownedagents/testjobs completed naturally, separatehandoffs inspected, monitor
cleanup recorded. Currentproduction fixes,fastgates/fullM2/focusedM3/actualIP
frontend/scopedQor pass; globaltiming/current64bincoverage/proofs/IPgaps remain.
M5 incomplete; resume from docs/handoffs/m5-verification.md with freshquota.

## M5 solo continuation (2026-10-11, current production)

Fresh direct-production full M3 passes all five accepted scenarios on both
runtimes: 482 frames and 42 checkpoints each, with unchanged source/helper/
harness and initialization pins. All frame CRCs/probes/timestamps, complete UART
monitor data/timing, host logs and 504 RAM dump files agree across runtimes; only
the validated absolute host-log output path differs. This qualifies the current
shadow/FIFO/panel/capacity composition in the accepted Python-host frontend scope.

A symbolic watched-transaction FIFO proof passes depths1/3/4/1152, preserving
rank and truncated payload through pop capture and delayed completion after real
reset/clear. It documents a single-cell RAM projection and catches read-payload
corruption. The selected-address capture timing proposal passes its extracted
cycle-equivalence proof but fails the frozen routed setup objective (-2.547ns
versus -1.333ns baseline); it is rejected and remains isolated.

A new validity-only matrix-store proposal removes finite epoch tags while
retaining resettable validity, interfaces and read latency. Both runtimes pass
the unchanged independent86123clock reset/overlap ledger and its corruption
control; watched-cell value/latency proofs pass with missing-clear controls.
Routing and integrated qualification remain pending, so production is unchanged.
Full cold/functional/current-source coverage campaigns and guard-progress proofs
continue under the usage guard. Slow Docker raw campaigns were stopped before
their declared budgets, with partial artifacts retained and no passing verdict.
M5 remains incomplete; [the handoff](handoffs/m5-verification.md) records jobs.

## M5 integrated reply-safety checkpoint (2026-10-11)

The previously unqualified receiver accepts repeated or undeclared voltage-node
indices as complete packets. Cold real115200UART witnesses reproduce both on
native/Docker; the unchanged golden decoder rejects those byte streams. A009
tracks distinct declared nodes and cancels invalid staging while preserving the
previous bank. A010 fixes32node view-count truncation. Elevenfixtures/101lines
cover rejection/recovery, reverseorder, all32words and31next-node selections,
nonwrap/selectionretention and empty replies onbothruntimes.

The integrated correction passes fullM2/M3 (780frames/103checks eachruntime,
zero pixel differences), fivecold4operation smoke cases(245/25 each), source/
oracle/mask/initialization audits, six maintained source-based safety checks,
and both fresh14check fastgates. Actual directproduction default115200/vendorFP
frontend also passes boot/duplicate/editedsplitrail plus a coldnegative and
source-final checks. Assets changed only source provenance;254frozenbehavior
entries remain valid. M5 stays incomplete.

New formal scope includes arbitrary selected FIFO transaction order under a
single-cell array projection, guard completion under declared ready/reply bounds,
and actual quiescent rebuild1744clock progress. Parser dispatch/range proof uses
independentlyarbitrary purehelperreturns; full parser processing timedout and is
not claimed. Receiver mask/count/complete-currentID commit/inactive-bank proofs
and a separate watched-node logicalRAM payload theorem record their explicit
unsupported physical/view/overlap scopes. Gate rejects missing/false results.

The reply correction's scoped route passes10149LUT/4197FF/10BRAM,
setup-1.953/hold+0.027; global100MHz/externalIO/CDC stillfails. Three independent
address/epoch proposals and a balanced unitdecoder fail their frozen timing
objectives and remain rejected. New current-source raw11frame/twocheck reports
pass integrity onbothruntimes with8/64functional bins each and substantial
eligiblecounter gaps. Pre-correction fullcold3784/325 and64functional-bin scopes
are retained under their own source hashes. Fresh post-correction fivecold64op
corpora are running and cannot inherit those old verdicts.

Continue under the usage guard from [the coordinating handoff](handoffs/m5-verification.md).

Guarded final checkpoint: newTop post-correction coldseeds1/7/2026/11 pass
2990frames/260checks perruntime with allsource/helper/init pins stable; seed12
interrupted andexcluded. Fourcase evidence isnotfivecase completion. Native/
Docker gates andactualvendorFPfrontend pass; M5 incomplete. Guard STOP at
2%five-hour/70%weekly; allownedjobs/CIDs absent. Resumeonlyseed12 thenremaining
source-correctcoverage/globaltiming/proof/IPwork from the coordinating handoff.
