# Verification plan: golden model + framescope

Living document for making MetaCircuit deterministically testable without hardware.
Track progress here: tick TODOs, append to the log, and move questions from
"to be made" to "made" when settled. IDs are stable; never reuse one.

Last updated: 2026-10-10 (M3 prerequisites done; decisions D-015 to D-025)

## Goal

There is no Basys 3 any more. The focus is agentic observability and automated
testing of the RTL: an agent (or CI) should be able to drive the design with
mouse input and decide, deterministically, whether what it shows is correct.

That needs a ground truth. The plan is a human-validated software model of
MetaCircuit (the *golden model*) that produces reference states and frames, and
[framescope](../../framescope) to simulate the RTL with Verilator and capture
the same observables for comparison.

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
| M3 | Backend in the loop: netlist over UART matches golden; solver replies; voltage display checked | prerequisites done: FS-6, FS-7, RTL-4, RTL-5, GM-7, GM-8, and D-015..D-021 implemented in the golden model, kernels and RTL; M3 scenarios and runner not started |
| M4 | Lockstep sessions, coverage, agent interface (MCP) | not started |

M1 needs FS-1..FS-3, RTL-1..RTL-3, GM-1..GM-3 and SC-1..SC-2. It does not need the renderer.

## TODO

Priority: P0 blocks M1, P1 is needed by M2/M3, P2 is later.

### framescope (FS)

- [x] FS-1 (P0) Sub-frame event timing: `[[event]] frame = N, line = L` so inputs can change in the back porch, after the RTL's VSYNC capture edge.
- [x] FS-2 (P0) Per-frame probes: sample named internal expressions at a fixed point in each frame (frame counter, `mode_select`, `grid_pos_x/y`, init-done) and report them in the frame JSON. Needed to align RTL frames with golden frames.
- [x] FS-3 (P0) Memory dumps: write CellStore / ComponentStore contents at the end of chosen frames (JSON or hex) for state-level comparison.
- [x] FS-4 (P0) `framescope compare`: frames vs reference PNGs with region masks; diff PNG, per-region pixel counts, bounding boxes. Already listed as planned in framescope's `docs/architecture.md`.
- [x] FS-5 (P0) Batch runner: many scenarios against one build, parallel processes, one JSON summary.
- [x] FS-6 (P1) Speed: checkpoint after boot (Verilator `--savable`), restore per scenario; option to skip PNG encoding; try `--threads`. Baseline: ~1.1 s per frame, so a 300-frame scenario is ~5.5 min. Done (framescope `m3-speed`): Verilator compiled with `-Os` by default; `-O2` is now the default (~0.72-0.85 s/frame, CRC-identical); `--checkpoint N` boot checkpoints with `--savable` (~3-4 s saved per run); `--profile`. Threads were slower.
- [x] FS-7 (P1) UART monitor (decode `RsTx` lines into the report) and RX driver (scripted lines, or a host process such as `src/uart_link`'s simulated solver). framescope branch `m3-uart`: `protocol = "uart"` monitor, `[[uart]]` stimulus, `--host LINK=CMD` lockstep host with deterministic reply timing.
- [ ] FS-8 (P1) Seeded X-initialisation (`+verilator+rand+reset`) to expose reset bugs that `--x-initial fast` hides.
- [ ] FS-9 (P1) Long-lived session over stdio: step frames, poke inputs, read probes; lockstep with the golden model, stop at first divergence.
- [ ] FS-10 (P2) PS/2 device model, plus an SV port of Digilent `Mouse_Control.vhd` / `Ps2Interface.vhd` (or GHDL-synth to Verilog), to test the real mouse path instead of the stub.
- [ ] FS-11 (P2) Coverage: which modes and commands a scenario exercised (probes or Verilator coverage).
- [ ] FS-12 (P2) MCP server on top of sessions.

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
- [ ] INF-4 CI: framescope unit tests + metacircuit integration test on the pinned container (Verilator 5.020); native 5.046 as a second job.

### M3 follow-ups (M3)

- [ ] M3-1 (P1) Implement D-023 (rows only for terminal-touched regions) in the golden extraction, the extraction kernel and the regenerated RTL.
- [ ] M3-2 (P1) Implement D-024 (`@ER` code 85 for an aborted snapshot) in the frontend RTL and the golden UART model.
- [ ] M3-3 (P1) M3 scenarios with `SW[5]=1` and the solver host, including the D-025 out-of-order placement and slot-reuse check, and a `verify:m3` runner comparing netlist lines, snapshot ids, replies and 7-segment/voltage probes (D-017) against the golden model.
- [ ] M3-4 (P2) On-screen voltage readout with a golden renderer (D-017).
- [ ] M3-5 (P2) Restore an anchor-half selection checkpoint in `m2_full_ui`/`m2_recorded`: `voltage_micro` now clicks the boot source's partner half (D-015).

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
