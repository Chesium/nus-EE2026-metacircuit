# MetaCircuit golden model

A software reference model of the MetaCircuit editor, used as ground truth when
testing the RTL in simulation (see [`docs/verification-plan.md`](../docs/verification-plan.md),
items GM-1..GM-3, SC-1, SC-2 and an early slice of SC-3).

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
  quirks (canvas data lag at dx = 0, cursor at +2 px with the last column hidden,
  cursor colour hold). It does not yet draw property-panel text, flood node
  colours, the flow animation or the keypad's slower update. `placeholder` is hand-drawn stand-ins. A badge shows which one
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
```

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

Out of scope for now: property panel and value editing (components carry default
values), keypad, flooding / netlist / node colours / flow animation (GM-7, GM-8),
pixel-exact rendering and the cell decoder (GM-5, GM-6; the asset renderer is a
start), UART, and comparison tooling beyond `diffSemantic`.

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
