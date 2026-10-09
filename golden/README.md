# MetaCircuit golden model

A software reference model of the MetaCircuit editor, used as ground truth when
testing the RTL in simulation (see [`docs/verification-plan.md`](../docs/verification-plan.md),
items GM-1..GM-6, SC-1..SC-4; M1 and M2 human validation accepted).

- **Core** (`src/core`): TypeScript, no dependencies. It runs the same way in Node and in
  the browser. `step(state, mouseSnapshot) -> state` advances one frame (D-008).
- **Scenarios** (`src/scenario`, `scenarios/`): scripted mouse input with
  checkpoints. An expander turns them into one mouse sample per frame, and a
  compiler writes framescope stimulus TOML.
- **CLI** (`src/cli`): runs scenarios headlessly and writes RAM dumps plus a decoded
  state per checkpoint.
- **Web shell** (`index.html`, `src/web`): drive the model with a real mouse, record
  sessions as scenarios, replay scenarios.

Behaviour comes from the spec documents, not from the RTL (D-007). Every gap is a
numbered assumption in [`ASSUMPTIONS.md`](ASSUMPTIONS.md). Every constant or
encoding taken from the RTL is listed in [`INTERFACE_FACTS.md`](INTERFACE_FACTS.md).

## Install

Node 22.12 or newer (developed on Node 26), npm.

```sh
cd golden
npm ci
```

Dependency versions are pinned exactly (`package.json`, `package-lock.json`). The
Playwright smoke test uses `@playwright/test` 1.63.0, which expects Chromium
revision 1243 in `~/.cache/ms-playwright` (`npx playwright install chromium` if it
is missing).

## Web shell

```sh
npm run dev        # then open the printed URL (default http://localhost:5173)
```

- The 640x480 screen is redrawn every animation frame, scaled 2x nearest-neighbour.
  The model steps at a fixed 60 frames per second and samples the mouse once per
  frame. A press shorter than one frame is held for one frame (A-020). As on the
  RTL, the cursor, hover and toolbar press show the previous frame's sample
  (1-frame latency, A-003).
- **Graphics**: `assets` (the default) uses the RTL bitmaps from
  `golden/assets/*.json` (GM-4) when they exist, including the documented RTL
  quirks (cursor at +2 px with the last column hidden, cursor colour hold),
  property-panel text, node colours and frame-locked flow animation. The keypad shares the frame-latched cursor input. `placeholder` is hand-drawn stand-ins. A badge shows which one
  is active.
- **Side panel**: frame counter, selected tool (and wire variant), interaction mode
  code, pan offset, mouse sample, the cell under the cursor (decoded word, sprite,
  rotation, component slot), and the ComponentStore list with raw 40-bit words.
- **Controls**: Pause/Resume (Space), Step 1 frame (N, while paused), Reset (R,
  back to the power-on state with the boot circuit), Record (resets, then records
  every frame), Mark checkpoint (C, while recording), Download scenario, Load
  scenario (then Play/Pause, Step, Back to live), and Download state dump (RAM JSON
  and semantic state of the current frame).
- **Replay check**: when a scenario is replayed, each checkpoint is compared with a
  headless run of the same scenario and marked `match` or `MISMATCH`.

## CLI

```sh
# Run a scenario; write <NN>_<label>.ram.json and .state.json per checkpoint,
# plus checkpoints.json, into out/m1
npm run golden -- run scenarios/m1_canvas_tools.json --out out/m1

# Compile to framescope stimulus (inputs change on line 10, the back porch; D-008)
npm run golden -- stim scenarios/m1_canvas_tools.json -o out/m1.stim.toml
npm run golden -- stim scenarios/m1_canvas_tools.json --line 10 --frame-offset 0

# Print the canonical per-frame form
npm run golden -- expand scenarios/m1_canvas_tools.json

# Compare a completed framescope run with the reference state output
npm run golden -- compare out/m1/rtl --reference out/m1/reference

# Generate independent full UI checkpoint PNGs (vga/frame_NNNN.png)
npm run golden -- render scenarios/m2_full_ui.json --out out/m2/reference
```

`run` writes, per checkpoint, `<NN>_<label>.ram.json` (all memories),
`dumps/<memory>/frame_NNNN.json` (one memory per file, the same layout as
framescope's `run --dump`), `<NN>_<label>.state.json` (decoded state), and an index
`checkpoints.json`. Options: `--latency N` (default 1, the measured RTL latency,
A-003), `--rotate-frames N` (IF-021), `--names names.json` (override memory names,
e.g. `{"componentStore": "component_store"}`).

## Tests

```sh
npm test            # Vitest unit tests (core, scenarios, stim, encodings, renderers)
npm run test:e2e    # Playwright smoke test (starts its own Vite server on port 5199)
npm run typecheck   # tsc --noEmit
npm run test:rtl    # focused interaction/controller tests, native Verilator
```

## M1 RTL regression

With a sibling `framescope` checkout containing the `m1-harness` features,
Python, uv and the native Verilator (or Docker):

```sh
npm run verify:m1
npm run verify:m1 -- --runtime docker
# The saved web-shell recording has the same inputs and checkpoint frames
npm run verify:m1 -- --scenario scenarios/m1_recorded.json
# Check every frame around toolbar selection and a canvas edit (no wait margin)
npm run verify:m1 -- --scenario scenarios/m1_latency.json
# Optional checkout/output overrides; the output directory must be new
npm run verify:m1 -- --framescope /path/to/framescope --out out/my-m1-run
```

The runner generates reference RAM and state files, compiles the stimulus, runs
the scenario with dumps at its checkpoints, and compares each checkpoint. The
default M1 scenario has 267 frames and 25 checkpoints; `m1_latency.json` checks
all 11 frames around toolbar selection and drawing to verify one-frame latency.
It sets `METACIRCUIT` to this checkout automatically. Outputs live in a new
`out/m1/<UTC timestamp>-<runtime>/` directory: `reference/`, `stim.toml`, `rtl/`,
`simulation.log` and `state-compare.json`. A mismatch returns exit status 1.
Generated stimulus includes a top-level `frames` key, so direct framescope runs
also capture the complete scenario when `-n` is omitted.

The comparison checks enabled cell sprite/rotation, component anchors/types/
rotations/values, per-cell values and units, tool/variant/mode and pan probes,
init/idle/busy/drop probes, mirrored cell RAM equality and the ComponentIndexMap's
ownership of both halves. It ignores cell flow metadata, component slot ordering,
and stale store entries beyond the `component_count` probe. Slot index fields must
still agree with each RTL entry's own slot. Missing dumps, malformed words, late
events, incomplete runs and invalid probes fail the check. Colour RAMs and pixels
belong to M2.

## State and dumps

Golden state (`src/core/state.ts`):

| Field | Meaning |
|-------|---------|
| `cells` | CellStore, 288 x 16-bit words, address = row*18 + col, `{meta[15:9], rot[8:7], sprite[6:1], en[0]}` |
| `componentIndexMap` | per cell: component slot, 0x1FF if none |
| `components` | ComponentStore, 288 slots of `{leftSprite, col, row, rotation, valueBcd, unit}` or null |
| `tool`, `wireVariant` | toolbar selection (tool 0..9, variant 0..3) |
| `panX`, `panY` | pan offset (the RTL's `grid_pos_x/y`), x = 0, y in [-224, 0] |
| `prevMouse`, `gesture`, `rotateHoldoff`, `latencyQueue` | interaction bookkeeping |

`exportRamDumps(state, names, frame)` returns one object per memory, in the same
format and with the same names as framescope's FS-3 dumps (IF-028):

```json
{"name": "cells_render", "frame": 64, "width": 16, "depth": 288, "words": ["0x0000", "..."]}
```

| Memory | Width | Content |
|--------|-------|---------|
| `cells_render`, `cells_shadow` | 16 | cell words (identical copies) |
| `values_shadow`, `value_units_shadow` | 12, 4 | per-cell value (BCD) and unit; both halves of a component (A-021) |
| `component_store` | 40 | ComponentStore slots (free = 0) |
| `component_index_map` | 9 | per-cell slot, 0x1FF = none |

The colour RAMs (`cell_fg_color`, `cell_bg_color`) are not modelled in M1.

Words are zero-padded hex (4 digits for 16 bits, 3 for 12 or 9 bits, 1 for 4 bits,
10 for 40 bits). The state of frame k is the state after `step` for frame k, which
with the measured 1-frame latency reflects the mouse up to frame k-1, exactly as
framescope's end-of-frame dump of frame k does (IF-029). `decodeMemories(dumps,
names, {componentCount})` decodes dumps from either side into semantic cells and
components. For RTL dumps, pass the `component_count` probe so stale entries are
skipped. `diffSemantic(expected, actual)` prints differences such as
`cell (3,4) is RL rot 1, expected RR rot 1`. By default it ignores cell metadata
bits and slot numbers (A-011, A-016).

## Scenario format

A scenario is JSON: `{"name", "description"?, "initialMouse"?, "steps": [...]}`.
Each step is an object (`{"op": "move", "x": 100, "y": 200}`) or a one-line
string. A frame cursor starts at 0. Steps change the mouse "now". `wait n` emits n
frames with the current mouse and advances the cursor.

| Step | Meaning |
|------|---------|
| `move X Y` | set the position (screen pixels) |
| `down [left\|middle\|right]`, `up [...]` | set a button (default left) |
| `wait N` | emit N frames |
| `click X Y [hold N]` | move (1 frame), press (N frames, default 1), release (1 frame) |
| `click_tool NAME [hold N]` | click the centre of a toolbar button: `pan wire resistor inductor capacitor voltage current ground rotate delete` |
| `click_cell COL ROW [hold N]` | click a cell centre under the assumed pan (object form also takes `"screen": [x, y]` or `"pan": [x, y]`) |
| `drag cell C1 R1 to C2 R2 over N [button]` / `drag screen X1 Y1 to X2 Y2 over N` | move to start (1 frame), press (1 frame), N interpolated frames, release (1 frame) |
| `assume_pan X Y` | pan offset used to turn later `cell` targets into screen points |
| `checkpoint LABEL` | compare state at the end of the last emitted frame |
| `# text` | comment |

Canonical form (`expand`): `{name, frameCount, frames: [{x, y, left, middle, right}], checkpoints: [{label, frame}]}`.
Stimulus: one `[[event]]` per frame with a change, `frame = N`, `line = L`,
`set = { "mouse.x" = .., "mouse.y" = .., "mouse.left" = .. }`, relative to
framescope's defaults (320, 240, no buttons). A header comment names the scenario
and lists the checkpoints. `line` needs framescope FS-1.

`scenarios/m1_canvas_tools.json` (SC-2): 267 frames and 25 checkpoints. It covers
every canvas tool, blocked placements, rotation (click, hold, blocked, boot
parts), delete (cell, component half, boot component, drag), slot reuse, and
pan with clamping and drawing while panned.

## Scope

In scope (M1, canvas slice): toolbar selection including wire variants, wire,
junction, elbow, tee, ground, R/L/C/V/I placement, rotate (with the 8-frame
repeat), delete, pan with clamping, the RTL boot circuit, RAM-dump export and
semantic decode, scenarios, stim compilation, the web shell.

M2 adds property selection, immediate value/text/unit editing, the keypad, font
rendering, cursor, flow animation and settled node colours. The independent
connectivity oracle uses reciprocal graph edges and row-major node labels; it
does not simulate the flooding engine's cycle-by-cycle progress. Dense circuits
may therefore need settling frames before colour checkpoints. Backend stamping,
DC solve and UART remain M3 work (GM-7, GM-8, FS-7).

M2 assumptions are recorded in [`M2_ASSUMPTIONS.md`](M2_ASSUMPTIONS.md); the user
accepted them after human validation (2026-10-09). The asset renderer marks its output `authoritative: true`
for the supported settled UI states. Automated agreement is evidence of consistency with the RTL, rather than human
acceptance of the chosen property/keypad semantics.

## M2 pixel regression

```sh
npm run verify:m2
npm run verify:m2 -- --runtime docker
npm run verify:m2 -- --scenario scenarios/m2_boot.json
npm run verify:m2 -- --scenario scenarios/m2_node_colours.json
npm run verify:m2 -- --scenario scenarios/m2_recorded.json
# Reuse a completed RTL capture while developing the independent reference
npm run verify:m2 -- --actual out/m2/my-run/rtl --out out/m2/new-comparison
```

The default scenario has 103 frames and 22 checkpoints. The runner generates
reference states and PNGs solely from scenario inputs, captures checkpoint RAM
and pixels, then checks M1 state, UI selection/edit/value/text probes, settled
background colour RAM and enabled-sprite foreground RAM. Finally, framescope
compares every 640x480 pixel at zero tolerance. `masks/m2_ui.toml` reports counts
for panel, toolbar, canvas, keypad and bottom background; it excludes no pixels.
An explicit `--masks` override supports diagnostic region comparisons.

`m2_node_colours.json` (78 frames, 9 checkpoints) edits connectivity on the boot
circuit and checks settled node colours after each edit: a rail split, a new
horizontal wire that does not join, rotating it to rejoin, removing ground,
re-placing it unjoined and rotating it to join, removing a resistor, and
shorting the rails. `m2_recorded.json` was downloaded from the web shell after
Playwright drove `m2_full_ui.json` through real pointer events; its inputs and
checkpoint frames are identical to that scenario (a unit test pins this).

Outputs include `summary.json`, `state-compare.json`, `ui-compare.json` and
`pixels/compare.json`, with diff PNGs on failures. Failed pixel runs also get
`decoded-cells.json`: independent sprite/rotation/colour recovery, retaining
symmetric rotation ambiguity, cursor occlusion and corruption witnesses. Its
yellow-flow mask only aids diagnosis; the exact pixel comparison still checks
those pixels. `VisibleCellDecoder` also accepts RGB444 arrays directly.

## Layout

```text
golden/
  src/core/        constants, encodings, state, step(), export, boot circuit
  src/scenario/    format types, expander, stim compiler, headless runner
  src/render/      framebuffer, renderer interface, placeholder and asset renderers
  src/cli/         golden CLI
  src/web/         web shell
  scenarios/       hand-written scenarios (m1_canvas_tools.json)
  test/            Vitest unit tests
  e2e/             Playwright smoke test
  assets/, tools/  GM-4 asset extraction (owned by another work item)
```
