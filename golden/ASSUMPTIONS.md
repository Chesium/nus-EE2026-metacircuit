# Golden model assumptions

Behaviour the golden model needs but the spec does not pin down, or where the
sources disagree. Sources consulted for behaviour: `structure.md`, `README.md`,
`llm.md`, the final report, the proposal, and the photos in `assets/`
(D-007). Each entry says what was chosen, why, and what a human tester should
check on the web shell (and, later, against the RTL). IDs are stable; never reuse
one. Configurable choices name their `GoldenConfig` field (`src/core/config.ts`).

When a mismatch with the RTL is triaged, record the outcome here (and in the
verification plan's log): either the golden changes, or the RTL is filed as wrong.

Human validation of the M1 golden behavior is accepted as passed by the user
(2026-10-08). This includes A-019's geometry: rotation 0 points right, and one
clockwise turn points down. A-011 remains a storage-layout difference accepted
for semantic comparison; RTL slots may be packed while golden slots have holes.
M2-only behavior (property editing, keypad and flow rendering) is not covered by
this M1 acceptance.

M1 RTL triage (2026-10-08): the first comparison passed 12/25 checkpoints and
failed first at `blocked_placements`. The accepted golden behavior was retained.
`CanvasCommandGuard` now checks both placement cells before writing (A-009),
protects components and preserves same-sprite rotations during painting (A-008),
and checks a rotation's destination before moving either half (A-012).
`InteractionController` now starts gestures only in the canvas (A-006), stamps
two-cell parts once per press (A-009), and ignores right/middle-only input
(A-002). Rotating a component copies its value/unit and display text to the new
partner before clearing the old one (A-021). All 25 native and Docker RTL checkpoints pass,
including the boot resistor's nonzero value after rotation. Slot allocation
(A-011) and stale trailing RTL store words (A-016) remain accepted layout
differences; map ownership and live entry index fields are checked strictly.

---

### A-001 Frame stepping

- **Chosen:** `step(state, mouse)` is called once per frame with that frame's
  mouse snapshot. "The state at frame N" is the state after `step` for frame N
  (golden frames count from 0, the same as framescope's: frame 0 is the first
  captured frame). With the measured latency (A-003) that state is
  `step(state_{N-1}, mouse_{N-1})`. RAM dumps are labelled with that frame index
  and correspond to framescope's end-of-frame dumps. The stim compiler's
  `--frame-offset` defaults to 0.
- **Why:** D-008 (inputs change once per frame, captured once per frame); frame
  numbering confirmed by the coordinator (IF-029).
- **Check:** nothing for the tester.

### A-002 Mouse model and initial position

- **Chosen:** absolute position clamped to 0..639 x 0..479 plus left/middle/right
  (D-010). Before frame 0 the mouse is at (320, 240) with no buttons, the defaults
  of framescope's virtual inputs. Middle and right buttons have no effect in M1.
- **Why:** the spec only describes left-button interaction.
- **Check:** right/middle clicks on the canvas or toolbar do nothing.

### A-003 Input-to-effect latency is 1 frame (measured)

- **Chosen:** `inputLatencyFrames = 1`: an input change during frame N first shows
  in frame N+1, for the cursor, hover, toolbar press/selection and canvas edits
  alike. The web shell draws the mouse the model has applied (the previous frame's
  sample). The scenario keeps `wait 2` before every checkpoint as margin.
- **Why:** measured value from RTL-3 (IF-029). Originally 0 as a placeholder.
- **Check:** nothing for the tester (16.7 ms is not noticeable).

### A-004 Tool selection on press

- **Chosen:** a left-button press edge inside a toolbar button selects that tool.
  The hit box is the button rectangle, `[x0, x0+36) x [y0, y0+24)` with
  `y0 = 72 + 26*i` (the 2 px gaps between buttons select nothing). The release
  does not matter. Holding the button and sliding onto another button does not
  select it.
- **Why:** report: "Toolbar with mode-based interaction; each tool is mapped to a
  distinct drawing state". Press-to-select is the most common choice for tool palettes.
- **Check:** does the tool change on press or only on release? Does a press in the
  gap between two buttons do anything?

### A-005 Canvas hit-testing

- **Chosen:** canvas actions need the cursor inside the canvas rectangle
  (x 64..639, y 64..351). The cell is `col = floor((x - 64 - panX) / 32)`,
  `row = floor((y - 64 - panY) / 32)`. Cell borders belong to the cell to their
  right/below.
- **Why:** layout constants (IF-001, IF-005, IF-006); the mapping follows the
  pan definition.
- **Check:** clicking on a grid line places into the cell right/below it.

### A-006 A canvas gesture must start in the canvas

- **Chosen:** a press that starts outside the canvas (toolbar, panels) does nothing
  on the canvas, even if the button is then dragged into the canvas. A gesture
  that starts in the canvas keeps going (painting, erasing, panning) while the
  button stays down, also outside the canvas, where cell actions simply have no
  cell.
- **Why:** usual drag semantics for editors; avoids accidental edits after a
  toolbar click.
- **Check:** press on a toolbar button, drag into the canvas with the button held:
  nothing should be drawn.

### A-007 Wire-button variant cycling

- **Chosen:** the toolbar has one wire button for four variants (codes: 0 wire,
  1 junction, 2 elbow, 3 tee). Clicking it while the wire tool is already selected
  advances the variant 0 -> 1 -> 2 -> 3 -> 0. Clicking it from another tool selects
  the wire tool with the variant it had before. Selecting other tools keeps the
  variant. Boot variant: 0.
- **Why:** structure.md lists elbow/tee/junction modes but the photos show 10
  toolbar buttons with one wire button whose icon shows different variants
  (wire in `demo.jpg`, elbow in `before-assessment.jpg`, tee in
  `dummy-waveform.jpg` while the pan tool is selected), so the variant is a
  property of the wire button that persists while other tools are selected. The
  cycle order is the code order (IF-011).
- **Check:** the cycle order, and whether re-selecting the wire button from
  another tool resets the variant. Note: an RTL fragment seen by accident may
  bear on this (INTERFACE_FACTS.md, "Incidental exposure", X-1). The choice above
  was made from the photos.

### A-008 Single-cell tools paint while the button is held

- **Chosen:** wire-family and ground tools write the cell under the cursor on the
  press frame and on every later frame of the same gesture
  (`singleCellPaintWhileHeld = true`), so dragging draws a run of cells. Write
  rules: an empty cell or a cell with a different non-component sprite gets the
  tool's sprite at rotation 0. A cell that already has the same sprite is left
  alone (it keeps its rotation). A component cell is never overwritten.
- **Why:** structure.md: "modify the cell where the cursor located to a
  horizontal wire". It gives no click-only rule, and for drawing wires a drag is
  the natural gesture.
- **Check:** does dragging with the wire tool draw several cells, or only the
  first? Does drawing over a rotated wire of the same kind reset its rotation?
  Can a wire overwrite a ground? Can a wire overwrite part of a resistor?

### A-009 Two-cell components are stamped once per press

- **Chosen:** R, L, C, V and I place on the press edge only. The anchor (left
  half) goes to the clicked cell, rotation 0, the right half one column to the
  right. If either cell is occupied (by anything) or the right half would fall
  outside the grid (column 17), nothing happens: no shifting, no overwriting.
- **Why:** structure.md: "the anchor position will be set to the cell index where
  the mouse cursor is at and the rotation bits are set to the default 00";
  overwriting an existing part silently would lose circuit data.
- **Check:** click a resistor onto an existing wire or component, and onto the
  last column. Does anything appear?

### A-010 Default value of a new component

- **Chosen:** value BCD `000`, unit code 0 (none).
- **Why:** in `demo.jpg` and `netlist-parsing-correctly.jpg` the UART netlist
  shows `V=000 U=0` for resistors whose value was never edited.
- **Check:** place a resistor and select it in the property panel (M2): is the
  value 000?

### A-011 ComponentStore slot allocation

- **Chosen:** a new component takes the smallest free slot; deleting a component
  frees its slot, so the store can have holes (structure.md, verbatim). Depth is
  288 (IF-019).
- **Why:** structure.md: "when creating components, it would try to find the
  smallest empty element to store that new component".
- **Check:** delete a component, place another: does it take the freed slot
  (`slot_reuse` checkpoint)? Note: the RTL may build its store differently (see
  X-3 in INTERFACE_FACTS.md). That is why the default semantic diff compares
  components as a set keyed by anchor and ignores slot numbers.

### A-012 Rotate

- **Chosen:** a press on a cell adds one step: rotation `(r + 1) mod 4`, which is
  90 degrees clockwise under the sprite transform. Holding the button repeats the
  step every `rotateFramesPerStep = 8` frames (IF-021): on the press frame, then
  press + 8, press + 16, and so on, on whatever cell is under the cursor at that
  moment. On a component (either half) the whole component rotates about its
  anchor. If the new right-half cell is occupied by something else or outside the
  grid, nothing happens. An empty cell does nothing.
- **Why:** structure.md describes rotate as editing the rotation bits on click.
  The parameter name `RotateFramesPerStep` implies a repeat rate while held.
- **Check:** one click gives exactly one quarter turn. Holding gives one turn
  about every 0.13 s. Which way does it turn? Rotating a resistor next to a wall
  or another part.

### A-013 Pan

- **Chosen:** only with the pan tool (button 0). A press inside the canvas
  anchors the drag. On each later frame of the gesture the grid offset moves by
  the mouse delta (content follows the hand, 1:1), clamped to x = 0 and
  y in [-224, 0] (IF-006). The drag continues when the cursor leaves the canvas.
- **Why:** report: "Panning: allows the grid to move and show the rest of the
  circuit canvas"; structure.md: "panning the canvas when user is dragging inside
  the canvas window". Grab-and-drag is the usual hand-tool direction.
- **Check:** direction (drag up shows lower rows?), speed (1:1?), and the stops at
  the top and bottom. Does horizontal dragging do anything (it should not: the grid
  is exactly as wide as the canvas)?

### A-014 Delete

- **Chosen:** a press deletes the cell under the cursor; on a component (either
  half) the whole component is deleted and its slot freed. While the button is
  held, every cell crossed is deleted too (`deleteWhileHeld = true`).
- **Why:** structure.md's delete mode. Erase-while-dragging mirrors A-008.
- **Check:** does dragging with delete erase several cells?

### A-015 Clear and reset

- **Chosen:** M1 has no mouse-driven "clear all". `clearCanvas()` (core helper)
  empties both stores and keeps tool and pan. The web shell's Reset returns to
  the power-on state (A-017).
- **Why:** none of the documents describes a clear control on screen. The RTL
  clears the canvas during its init sequence, so a hardware reset is the only clear.
- **Check:** is there any clear action reachable with the mouse on the hardware?

### A-016 Dump encoding choices not fixed by the RTL interface

- **Chosen:** ComponentStore word: `index` field = slot number, `type` field = the
  sprite id of the anchor (origin) cell (IF-028; e.g. 5 for a resistor), free slot =
  all zeros. ComponentIndexMap = 0x1FF for cells that are not part of a component.
  Cell bits [15:9] (bit 9 = current-flow direction, [15:10] unused) are written as
  0 by every golden edit; boot cells keep their table values. `cells_render` and
  `cells_shadow` are exported with identical contents. The colour RAMs
  (`cell_fg_color`, `cell_bg_color`) are not exported. Memory names default to
  framescope's (IF-028) and can be overridden with `--names`.
- **Why:** the `index` field's meaning is not given by the interface. The flow bit
  and the colours come from logic the golden does not model in M1.
- **Check:** for the comparator: mask cell bits [15:9] and the `index` field until
  confirmed (the default `diffSemantic` options do this). For RTL dumps, pass the
  `component_count` probe to `decodeMemories` so stale entries are ignored.

### A-017 Power-on state

- **Chosen:** frame 0 starts from the RTL's boot circuit (IF-026: a voltage source,
  two resistors, wires, tees, elbows and a ground in columns 2..5, rows 2..7).
  Its components occupy slots 0..2 in table order. Tool = pan, wire variant 0,
  pan offset (0, 0). The RTL's init sequence finishes before the first frame.
- **Why:** the boot table is interface data; init takes about 300 clock cycles.
- **Check:** the shell shows the same circuit as the board after power-on.

### A-018 Clicks elsewhere

- **Chosen:** presses on the property panel, keypad and the empty bottom area
  change nothing in M1.
- **Why:** property editing is out of scope for M1.
- **Check:** nothing to check until M2.

### A-019 Rotation code geometry (sources disagree)

- **Chosen:** the right half of a two-cell component lies in direction 0 -> +x
  (right), 1 -> +y (down), 2 -> -x (left), 3 -> -y (up) from the anchor, as in the
  RTL's pair-address table (IF-020).
- **Why:** structure.md's example says rotation 00 puts the second cell below
  ((3,4) and (3,5)) and 11 to the left, and README.md lists "00 down, 01 right,
  10 up, 11 left". Both conflict with structure.md's own rule that new components
  are horizontal at rotation 00, and with the RTL. The golden must use the RTL
  encoding to compare dumps.
- **Check:** a fresh resistor is horizontal; one rotate makes it vertical with the
  anchor on top.

### A-020 Web shell: presses shorter than a frame

- **Chosen (shell only, not core):** a press and release within the same 16.7 ms
  frame is reported as pressed for that frame and released on the next.
- **Why:** a mouse that samples once per frame would otherwise lose fast clicks;
  the RTL also sees a button held for at least one frame in practice.
- **Check:** quick clicks register in the shell.

### A-021 Per-cell values

- **Chosen:** in the exported `values_shadow` / `value_units_shadow` memories,
  both cells of a two-cell component hold the component's value and unit; every
  other cell holds 0.
- **Why:** the boot table writes the same value to both halves of each component
  (IF-026), and the memories are per cell (IF-028).
- **Check:** nothing for the tester; compare in M2 when values become editable.
