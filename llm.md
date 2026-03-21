# Project Notes For AI Agents

## Current high-level split

- The project is already split into a **frontend / rendering path** and a **backend / matrix-compute path**.
- The frontend path is the part currently intended for FPGA hardware bring-up.
- The backend path is currently isolated and mainly testable through simulation, not integrated into the live VGA/mouse frontend yet.

## Active frontend path

### Main live top module

- [`src/design/rendering/CircuitCanvas_top.v`](c:/C/EE2026/git_test/metacircuit/src/design/rendering/CircuitCanvas_top.v) is the current hardware-facing top for the circuit canvas demo.
- It instantiates:
  - `ClockDivider` to generate the 25 MHz VGA pixel clock.
  - `VGAControl` for 640x480 timing.
  - `MouseCtl` and `MouseDisplay` for PS/2 mouse input and cursor overlay.
  - `SimpleRam` as a 16 x 16 cell backing store for canvas content.
  - `CircuitCanvas` as the actual grid/cell renderer.

### What the top currently does

- The top clears the whole 256-entry canvas RAM at startup, then writes a small hardcoded demo pattern into selected cells.
- Mouse max X/Y are also configured during the startup cycle sequence.
- Final VGA color priority is:
  1. blanking outside active video -> black
  2. mouse cursor overlay
  3. switch-selected VGA test patterns on `SW[0]` / `SW[1]`
  4. `CircuitCanvas` output if `rendered`
  5. pink background outside the canvas

### Important current limitation

- `CircuitCanvas_top.v` currently **does not edit canvas RAM from interaction logic**.
- The visible circuit is still loaded by fixed startup writes in the top module.
- Mouse input is used for cursor display and canvas panning, not for persistent draw/place operations yet.

## CircuitCanvas renderer

### Core behavior

- [`src/design/rendering/CircuitCanvas.v`](c:/C/EE2026/git_test/metacircuit/src/design/rendering/CircuitCanvas.v) is a RAM-backed tile renderer for a 16 x 16 grid with `CellSize = 32`.
- Default canvas size is `400 x 300`, so only part of the full 16 x 16 grid is visible at once.
- Left mouse drag pans the grid by changing signed offsets `grid_pos_x` / `grid_pos_y`.
- Panning is clamped so the view cannot move beyond the grid bounds.
- Hovering over a cell changes the background color of that cell.

### Cell storage format

- Each visible cell is encoded in 16 bits:
  - bits `[15:9]`: mode / metadata field
  - bits `[8:7]`: rotation
  - bits `[6:1]`: sprite ID / cell type
  - bit `[0]`: enable
- `cell_mode` is decoded but not currently used by the renderer logic.
- The comments mention selected/component metadata, but the active implementation only really uses:
  - `cell_rotation`
  - `cell_type`
  - `cell_enable`

### Sprite decoding

- `GetRow()` maps sprite IDs to hand-written bitmap functions embedded directly in `CircuitCanvas.v`.
- Current IDs are:
  - `0`: `Wire`
  - `1`: `Elbow`
  - `2`: `Tee`
  - `3`: `Junction`
  - `4`: `Cross`
  - `5`: `RL`
  - `6`: `RR`
  - `7`: `VL`
  - `8`: `VR`
  - `9`: `IL`
  - `10`: `IR`
  - `11`: `LL`
  - `12`: `LR`
  - `13`: `CL`
  - `14`: `CR`
- Rotation is handled by `GetXX()` / `GetYY()` before indexing the sprite bitmap.

### RAM read pipeline detail

- `SimpleRam` uses a synchronous read, so `CircuitCanvas` includes a small prefetch/latch scheme:
  - it tracks the requested cell,
  - compares against the last incoming RAM cell,
  - latches data when it arrives,
  - and reuses the latched value while requesting the next cell.
- If you change canvas storage or timing, be careful not to break this read-latency assumption.

### Current interaction scope

- `mouse_left_click` only drives drag-to-pan behavior today.
- There is no committed cell placement, wire routing, selection FSM, or canvas write-back path in `CircuitCanvas.v`.
- `display_grid` is passed in, but the current color assignment always draws the grid-style borders; the flag is not meaningfully used yet.

## Backend / matrix path

### LU block status

- [`src/design/matrix/LUdecomp.v`](c:/C/EE2026/git_test/metacircuit/src/design/matrix/LUdecomp.v) is a standalone FSM-based LU decomposition engine.
- It reads matrix `A` through a RAM read port and writes/reads the combined `LU` matrix through another RAM interface.
- It depends on the floating-point wrappers:
  - `src/design/floating_point/fpo_fma.v`
  - `src/design/floating_point/fpo_div.v`
- The implementation is currently a compute module with no linkage to the rendering frontend.

### How LU is tested today

- [`src/testbench/LU_test.sv`](c:/C/EE2026/git_test/metacircuit/src/testbench/LU_test.sv) is the active validation path.
- The testbench:
  - instantiates two `SimpleRam` blocks for input/output matrices,
  - loads `lu_test_input_4x4.mem`,
  - pulses `start`,
  - waits for `done`,
  - compares the output RAM contents against `lu_test_expected_4x4.mem`,
  - uses mixed absolute/relative floating-point tolerance.
- In practice, this means the backend is currently **simulation-driven**, not part of the board-level demo path.

## Existing but mostly scaffold-level modules

- `src/design/interaction/CanvasInteraction.v` is only a stub.
- `src/design/interaction/CommandEngine.v` is only a stub.
- `src/design/store/CellVisStore.v` is only a stub.
- These look like the intended direction for a cleaner interaction / command / storage architecture, but they are not wired into the active frontend yet.

## Practical guidance for future agents

- If the task is about what currently runs on FPGA/VGA, start from `CircuitCanvas_top.v` and `CircuitCanvas.v`.
- If the task is about solver/backend progress, start from `LUdecomp.v` and `LU_test.sv`.
- Do not assume frontend interaction modules are complete just because the folders exist; most of that path is still scaffolding.
- Do not assume the canvas cell metadata comment is fully implemented; the live renderer mostly cares about `enable + rotation + sprite_id`.
- If adding real editing behavior, the missing piece is a write path from interaction logic into canvas RAM, likely separated from rendering.
- If integrating frontend and backend later, keep the rendering cell-store and matrix-solver memories conceptually separate unless there is a deliberate architecture change.
