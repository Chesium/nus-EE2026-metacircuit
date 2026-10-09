# Verification plan: golden model + framescope

Living document for making MetaCircuit deterministically testable without hardware.
Track progress here: tick TODOs, append to the log, and move questions from
"to be made" to "made" when settled. IDs are stable; never reuse one.

Last updated: 2026-10-09

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
| M1 | Canvas-only slice: select tool, place, rotate, delete, pan; RAM state matches golden on one recorded scenario | not started |
| M2 | Full-UI pixel golden: toolbar, keypad, property panel, cursor, node colours; masked pixel compare | not started |
| M3 | Backend in the loop: netlist over UART matches golden; solver replies; voltage display checked | not started |
| M4 | Lockstep sessions, coverage, agent interface (MCP) | not started |

M1 needs FS-1..FS-3, RTL-1..RTL-3, GM-1..GM-3 and SC-1..SC-2. It does not need the renderer.

## TODO

Priority: P0 blocks M1, P1 is needed by M2/M3, P2 is later.

### framescope (FS)

- [ ] FS-1 (P0) Sub-frame event timing: `[[event]] frame = N, line = L` so inputs can change in the back porch, after the RTL's VSYNC capture edge.
- [ ] FS-2 (P0) Per-frame probes: sample named internal expressions at a fixed point in each frame (frame counter, `mode_select`, `grid_pos_x/y`, init-done) and report them in the frame JSON. Needed to align RTL frames with golden frames.
- [ ] FS-3 (P0) Memory dumps: write CellStore / ComponentStore contents at the end of chosen frames (JSON or hex) for state-level comparison.
- [ ] FS-4 (P0) `framescope compare`: frames vs reference PNGs with region masks; diff PNG, per-region pixel counts, bounding boxes. Already listed as planned in framescope's `docs/architecture.md`.
- [ ] FS-5 (P0) Batch runner: many scenarios against one build, parallel processes, one JSON summary.
- [ ] FS-6 (P1) Speed: checkpoint after boot (Verilator `--savable`), restore per scenario; option to skip PNG encoding; try `--threads`. Baseline: ~1.1 s per frame, so a 300-frame scenario is ~5.5 min.
- [ ] FS-7 (P1) UART monitor (decode `RsTx` lines into the report) and RX driver (scripted lines, or a host process such as `src/uart_link`'s simulated solver).
- [ ] FS-8 (P1) Seeded X-initialisation (`+verilator+rand+reset`) to expose reset bugs that `--x-initial fast` hides.
- [ ] FS-9 (P1) Long-lived session over stdio: step frames, poke inputs, read probes; lockstep with the golden model, stop at first divergence.
- [ ] FS-10 (P2) PS/2 device model, plus an SV port of Digilent `Mouse_Control.vhd` / `Ps2Interface.vhd` (or GHDL-synth to Verilog), to test the real mouse path instead of the stub.
- [ ] FS-11 (P2) Coverage: which modes and commands a scenario exercised (probes or Verilator coverage).
- [ ] FS-12 (P2) MCP server on top of sessions.

### RTL design-for-test (RTL)

- [ ] RTL-1 (P0) Make `global_anim_phase` frame-locked. Today it advances every 1,000,000 pixel clocks (40 ms) while a frame is 420,000 clocks, so the phase changes mid-frame on a different line each time (`src/design/rendering/GlobalRender_top.v:1101`). Advance on VSYNC every N frames instead (D-009).
- [ ] RTL-2 (P0) Latch the cursor position once per frame for `MouseDisplay`, so an input change mid-frame cannot tear the cursor.
- [ ] RTL-3 (P0) Measure and document the input-to-effect latency (mouse change, then capture, then command, then ping-pong swap, then visible) as a spec constant the golden model uses.
- [ ] RTL-4 (P1) Make the frontend UART path testable in simulation: it is gated by `SW[5]` and `RsRx` idles, so no solver ever replies and the voltage display is never exercised.
- [ ] RTL-5 (P1) Make the framescope mouse stub honour `setmax_x/y` and `setx/sety` like the Digilent controller, or confirm it is out of scope for M1-M3 (D-010).

### Golden model (GM)

- [ ] GM-1 (P0) Core state model (TypeScript, `golden/`; D-005, D-006): CellStore, ComponentStore, tool mode, pan offset, property-panel state; `step(state, mouse_snapshot) -> state` at frame granularity, matching the RTL's per-frame mouse capture.
- [ ] GM-2 (P0) Interaction semantics for M1: tool selection, draw wire/junction/elbow/tee/ground, place R/L/C/V/I, rotate (incl. `RotateFramesPerStep` holdoff), delete, pan with clamping. Source of truth: `structure.md` and the final report, not a transliteration of `InteractionController.v` (D-007).
- [ ] GM-3 (P0) State export in the same format as the FS-3 RAM dumps.
- [ ] GM-4 (P1) Asset extraction script: sprite functions and palette in `CircuitCanvas.v`, `FontROM.v`, toolbar and keypad icons, cursor bitmaps, into JSON.
- [ ] GM-5 (P1) Renderer: `render(state, t) -> 640x480 RGB444`, pixel-exact, from the GM-4 assets.
- [ ] GM-6 (P1) Cell decoder: classify each visible grid cell of a frame into (sprite, rotation, colour) using the GM-4 assets, so mismatches read as "cell (3,4) is RL rot 1, expected RR rot 1".
- [ ] GM-7 (P1) Backend: flooding, component node extraction, stamping, DC solve; differential test against the simpyhls DSL kernels (`simpyhls/examples/*.dsl.py`) on random circuits.
- [ ] GM-8 (P1) Netlist export in the `src/uart_link` protocol format, to compare against the RTL's UART output (FS-7).

### Scenarios and web shell (SC)

- [ ] SC-1 (P0) Scenario format: per-frame mouse states plus macros (`click_tool`, `click_cell`, `drag`); compilers to golden input and to framescope `stim.toml`.
- [ ] SC-2 (P0) One hand-written M1 scenario that exercises every canvas tool.
- [ ] SC-3 (P1) Web shell: 640x480 canvas drawn with `putImageData`, scaled nearest-neighbour; mouse mapped to per-frame snapshots; record and replay sessions as scenario files.
- [ ] SC-4 (P1) Playwright tests that replay scenarios in the web shell and check against the headless golden output.
- [ ] SC-5 (P1) Human test sessions on the web shell; triage every RTL/golden mismatch (D-007).

### Infrastructure (INF)

- [ ] INF-1 Merge `fix/vga-timing` (metacircuit) and `native-verilator-json-ports` (framescope) into their default branches.
- [ ] INF-2 framescope's `examples/metacircuit/framescope.toml` defaults `METACIRCUIT` to `../../../EE2026/metacircuit`; this checkout needs `METACIRCUIT=<path>/nus-EE2026-metacircuit`. Change the default or document it.
- [ ] INF-3 One framescope test run under the docker runtime failed once with an error that did not reproduce in 10 later runs; traceback was not captured. Watch for it.
- [ ] INF-4 CI: framescope unit tests + metacircuit integration test on the pinned container (Verilator 5.020); native 5.046 as a second job.

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

## Decisions to be made

None open. Add new questions here as `Q-009`, `Q-010`, ... with options and a recommendation.

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
