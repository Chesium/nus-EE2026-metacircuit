# `design2` UI Port Plan

## Goal
- Port, refactor, or redesign the UI pieces needed for the `design2` architecture under `src/design2/ui`.
- Keep `src/design` intact as legacy reference.
- End with a production-oriented UI stack that is testable, timing-safe, and decoupled from the old monolithic top-level rendering flow.

## Non-Goals
- Do not preserve every legacy debug/demo UI panel.
- Do not reintroduce `GlobalRender_top`-style coupling between rendering, interaction, backend, and UI.
- Do not optimize for visual polish before the UI data flow and testability are correct.

## Current Starting Point
- Implemented now:
  - `ToolbarController.sv` only exposes tool selection from `SW[3:0]`.
  - `ComponentPropertyPanel.sv` is a minimal colored strip with button-driven commands.
  - `MetaCircuit_top.sv` composites `mouse > property panel > canvas > background` directly.
- Present but unused:
  - `DynamicTextBox.v`
  - `DynamicTextDisplay.v`
  - `FontROM.v`
  - `TextBox.v`
  - `TextDisplay.v`
- Missing in `design2`:
  - rendered toolbar UI
  - proper property editor UI
  - text/dashboard integration
  - reusable UI layer compositor
  - keyboard/text entry editing path
  - selection detail widgets
  - cursor/preview/selection overlays
  - thorough UI-focused tests

## Design Principles
- UI modules should be read-only on the pixel side whenever possible.
- Interaction intent should become canonical commands, not direct store mutations from UI modules.
- System-domain state and pixel-domain presentation must be separated explicitly.
- All cross-domain UI signals must go through deliberate CDC/synchronization.
- Prefer small, composable modules over one giant UI renderer.
- Every new UI module should have at least one direct unit-style test or integration-style test.

## Proposed Target Hierarchy
- `src/design2/ui/common`
  - shared colors, layout constants, text rendering adapters
- `src/design2/ui/toolbar`
  - toolbar renderer
  - toolbar hit-test/decode
  - tool metadata/constants
- `src/design2/ui/property`
  - property panel renderer
  - selection summary view
  - parameter editor controller
  - value formatting / unit formatting helpers
- `src/design2/ui/text`
  - refactored text primitives adapted from `FontROM`, `TextDisplay`, `DynamicTextDisplay`, `TextBox`, `DynamicTextBox`
- `src/design2/ui/overlay`
  - selection highlight
  - placement preview
  - cursor/tool hint overlay
- `src/design2/ui/compositor`
  - final UI layer mux/compositor

## Stage 0: Freeze Scope And References
### Deliverables
- Identify which legacy UI files are authoritative references vs which are legacy clutter.
- Record the exact design2 UI requirements we want to keep.

### Tasks
- Read the current `src/design/Dashboard` and rendering-side UI modules again and classify them:
  - port mostly as-is
  - port but heavily refactor
  - rewrite from scratch
  - leave behind
- Decide the minimum production UI feature set for design2 v1:
  - rendered toolbar
  - selected-component panel
  - parameter edit controls
  - status hints
  - selection/placement overlay

### Exit Criteria
- A short mapping document exists in this file and can guide implementation file-by-file.

### Stage 0 Output: Reference Classification
- `src/design/rendering/ButtonVGA.v`
  - Class: port mostly as-is
  - Why: it is already a reasonably self-contained pixel renderer primitive with useful selected/pressed visual states and only light interface cleanup needed
- `src/design/rendering/ToolbarVGA.v`
  - Class: port but heavily refactor
  - Why: it contains the best existing visual reference for tool layout and iconography, but it mixes rendering, hover detection, and selected-tool state in one module
- `src/design/Dashboard/ComponentPropertyPanel.v`
  - Class: port but heavily refactor
  - Why: it is the richest behavior reference for the property UI, but it is tightly coupled to legacy ComponentStore addressing, legacy keyboard flow, and pixel-domain edit handling
- `src/design/Dashboard/FontROM.v`
  - Class: port mostly as-is
  - Why: it is a stable asset-style dependency and should remain the backing glyph source unless later replaced deliberately
- `src/design/Dashboard/TextDisplay.v`
  - Class: port but refactor
  - Why: useful as a static text primitive, but its interface should be normalized to the design2 pixel-render contract
- `src/design/Dashboard/DynamicTextDisplay.v`
  - Class: port but refactor
  - Why: still useful for variable text fields, but it should be cleaned up around explicit string/value inputs and screen clipping rules
- `src/design/Dashboard/TextBox.v`
  - Class: port but refactor
  - Why: useful as a building block for framed labels and value fields, but it should be decoupled from legacy layout assumptions
- `src/design/Dashboard/DynamicTextBox.v`
  - Class: port but refactor
  - Why: useful for composed text boxes, but it should become a clean presentation primitive rather than a semi-specialized dashboard widget
- `src/design/Dashboard/CompactDigitROM.v`
  - Class: leave behind for v1, keep as optional reference
  - Why: no current design2 requirement depends on a dedicated compact digit path, and using it too early would complicate the text stack
- `src/design/Dashboard/DashBoard.v`
  - Class: leave behind
  - Why: it belongs to the old composite dashboard approach and does not fit the smaller composable design2 hierarchy
- `src/design/Dashboard/MatrixDisplay.v`
  - Class: leave behind
  - Why: matrix/debug visualization is explicitly out of scope for the production UI v1 refactor
- `src/design/rendering/KeyboardVGA.v`
  - Class: leave behind for v1, revisit in numeric-edit stage
  - Why: keyboard-backed editing is useful later, but it should not shape the initial property-panel architecture
- `src/design/rendering/KeyboardVGA_top.v`
  - Class: leave behind
  - Why: demo/top-level wrapper only
- `src/design/rendering/MouseDisplay.vhd`
  - Class: already active in design2
  - Why: this is already part of the current production path and does not need a UI-port decision beyond normal cleanup later
- `src/design/rendering/CircuitCanvas.v`
  - Class: already ported as rendering, not a UI-stage target
  - Why: it remains a canvas renderer reference, but Stage 0 is only about UI-facing modules
- `src/design/rendering/GlobalRender_top.v`
  - Class: leave behind
  - Why: legacy monolithic integration reference only
- `src/design/rendering/WaveformPlot.v`
  - Class: leave behind
  - Why: debug/demo UI
- `src/design/rendering/WaveformPlot_top.v`
  - Class: leave behind
  - Why: debug/demo top
- `src/design/rendering/DummyDataGenerate.v`
  - Class: leave behind
  - Why: demo support logic
- `src/design/rendering/VGAtest_top.v`
  - Class: leave behind
  - Why: bring-up/demo top

### Stage 0 Output: Current `design2` UI Audit
- Active production-path UI pieces today:
  - `src/design2/ui/ToolbarController.sv`
  - `src/design2/ui/ComponentPropertyPanel.sv`
- Copied into `design2` but not meaningfully integrated yet:
  - `src/design2/ui/FontROM.v`
  - `src/design2/ui/TextDisplay.v`
  - `src/design2/ui/DynamicTextDisplay.v`
  - `src/design2/ui/TextBox.v`
  - `src/design2/ui/DynamicTextBox.v`
- Stage 0 conclusion:
  - the current `design2` UI should be treated as a scaffold, not as the final architecture
  - the copied text modules are valid source material, but they still need interface normalization and test coverage before they become shared infrastructure

### Stage 0 Output: Design2 UI v1 Minimum Scope
- Required in the first full production UI path:
  - a rendered toolbar with visible selected-tool state
  - a selected-component property panel that shows at least type, value, rotation, and anchor coordinates
  - panel-side button controls for increment, decrement, rotate, and delete
  - a clear empty-state panel when nothing is selected
  - selection highlight overlay on the canvas
  - placement preview overlay for component-placement modes
  - a reusable text rendering stack used by both toolbar and property UI
  - a reusable compositor so `MetaCircuit_top` stops doing ad hoc UI layering
- Explicitly deferred from v1:
  - keyboard/numeric entry editing
  - matrix or waveform debug displays
  - dashboard-style demo panels
  - any feature that depends on coordinate-based ComponentStore addressing instead of canonical `comp_idx`

### Stage 0 Output: Authority Notes For Later Stages
- Visual reference authority:
  - toolbar look and tool ordering should primarily follow `src/design/rendering/ToolbarVGA.v`
  - button visual treatment should primarily follow `src/design/rendering/ButtonVGA.v`
  - property-panel content and edit affordances should primarily follow `src/design/Dashboard/ComponentPropertyPanel.v`
- Architectural authority:
  - no legacy UI module is authoritative for state ownership or command flow
  - all editing behavior must be recast into the design2 command bus and canonical `comp_idx` selection model
  - all pixel-domain modules must remain read-only presentation modules with explicit synchronized inputs

## Stage 1: Establish Shared UI Infrastructure
### Deliverables
- Common UI constants and layout packages under `src/design2/ui/common` and `src/design2/ui/text`.
- One canonical way to render text in design2.

### Tasks
- Create a `UiThemePkg.sv`:
  - colors
  - panel geometry
  - toolbar dimensions
  - z-order constants
- Create a `UiTextPkg.sv`:
  - character sizing
  - text alignment options
  - string field widths
- Refactor and port text primitives:
  - `FontROM`
  - `TextDisplay`
  - `DynamicTextDisplay`
  - `TextBox`
  - `DynamicTextBox`
- Normalize interfaces:
  - pixel clock only
  - `video_on`, `hcount`, `vcount`
  - `rendered`, `rgb`
- Remove legacy assumptions baked into old modules:
  - hardcoded screen regions
  - direct coupling to legacy store addresses
  - hidden dependence on old top-level signals

### Tests
- Add text rendering unit tests:
  - glyph fetch sanity
  - clipping at screen edges
  - single-line rendering
  - dynamic text substitution
- Add compile/elaboration tests for each text primitive in isolation.

### Exit Criteria
- All future UI modules can render labels and numbers through a shared text API.

### Stage 1 Output
- Added shared UI packages:
  - `src/design2/ui/common/UiThemePkg.sv`
  - `src/design2/ui/common/UiTextPkg.sv`
- Added the normalized shared text stack:
  - `src/design2/ui/text/FontROM.v`
  - `src/design2/ui/text/UiTextLineRenderer.sv`
  - `src/design2/ui/text/TextDisplay.sv`
  - `src/design2/ui/text/TextBox.sv`
  - `src/design2/ui/text/DynamicTextBox.sv`
  - `src/design2/ui/text/DynamicTextDisplay.sv`
- Canonical Stage 1 text interface now is:
  - `clk_pixel`
  - `video_on`
  - `hcount`, `vcount`
  - `start_x`, `start_y`
  - `region_width`
  - `scale`
  - `align`
  - `text_rgb`
  - `rendered`, `rgb`
- Stage 1 architectural note:
  - text rendering now flows through one shared line renderer instead of each text module duplicating glyph lookup and pixel-coordinate math
  - `TextBox` and `DynamicTextBox` are now thin wrappers over the same canonical renderer
  - `DynamicTextDisplay` now formats numeric content into the same canonical text path instead of keeping its own separate rendering logic
- Verification completed for Stage 1:
  - added `src/testbench/Design2_TextRender_test.sv`
  - added `src/testbench/Design2_TextPrimitiveSmoke_test.sv`
  - updated `metacircuit-design2.tcl` to include the new shared UI files and tests
  - local Vivado `xvlog` parse passed
  - local Vivado `xelab` elaboration passed
  - local Vivado `xsim` runs passed for both new Stage 1 tests

## Stage 2: Build A Real Toolbar UI
### Deliverables
- On-screen toolbar renderer and toolbar interaction decoder.

### Tasks
- Replace `ToolbarController.sv` with two layers:
  - `ToolbarStateController.sv` for selected mode state
  - `ToolbarRenderer.sv` for pixel output
- Add a static tool metadata package:
  - tool id
  - display label
  - color/icon mapping
  - whether tool edits cells or components
- Implement toolbar rendering:
  - visible tool slots
  - selected-tool highlight
  - hover indication if mouse is over a tool
  - compact text labels or icons
- Implement toolbar hit-testing:
  - map pixel-space mouse to tool slot
  - generate a command or selected-mode update in system domain
- Keep hardware switch mode-selection as an optional debug fallback, not the primary UI.

### Tests
- Toolbar renderer tests:
  - correct visible regions per slot
  - selected-tool color changes
  - clipping and panel borders
- Toolbar controller tests:
  - click on each slot selects expected mode
  - clicking outside toolbar does nothing
  - switch fallback behavior works if enabled
- Integration test:
  - toolbar selection updates command generation mode in `InteractionCommandController`

### Exit Criteria
- Tool mode can be selected from the rendered UI rather than only from switches.

## Stage 3: Replace The Placeholder Property Panel
### Deliverables
- A proper property panel for selected components.

### Tasks
- Split current `ComponentPropertyPanel.sv` into:
  - `PropertyPanelRenderer.sv`
  - `PropertyPanelController.sv`
  - `SelectionSummaryView.sv`
  - `ValueEditController.sv`
- Define displayed fields:
  - component type
  - value
  - rotation
  - anchor coordinates
  - nodes when available
- Add a proper empty-state view when nothing is selected.
- Add consistent formatting helpers:
  - value to decimal text
  - units suffix handling
  - component type label
- Support command generation for:
  - increment/decrement
  - rotate
  - delete
  - future direct numeric set
- Keep system-domain editing logic and pixel-domain presentation separate.

### Tests
- Renderer tests:
  - empty-state draw
  - resistor/voltage/current/capacitor/inductor detail rendering
  - border/background/title layout
- Controller tests:
  - each button emits the expected canonical command
  - no command when no selection exists
  - selection changes update displayed component summary
- CDC tests:
  - system selection data is synchronized into pixel domain cleanly
  - no direct unsynchronized bus use remains

### Exit Criteria
- Property UI is informative and functionally useful, not just a colored strip.

## Stage 4: Add Keyboard/Numeric Entry Editing
### Deliverables
- Optional numeric edit flow for component values.

### Tasks
- Decide input mechanism:
  - buttons only for v1
  - keyboard entry for v2
- If keyboard is included:
  - port only the pieces needed from legacy keyboard UI/input path
  - keep decoding and edit-state logic in system domain
  - render current edit buffer in property panel
- Add commit/cancel semantics:
  - commit updates component value through canonical command
  - cancel preserves previous value
- Add unit handling if retained:
  - simple suffix entry
  - or fixed base-unit editing for first release

### Tests
- Editing FSM tests:
  - digit append
  - backspace
  - commit
  - cancel
  - overflow/invalid input handling
- Property integration tests:
  - selected component updates correctly after commit

### Exit Criteria
- Numeric values can be edited deterministically and are validated before command emission.

## Stage 5: Add Overlay UI
### Deliverables
- Visual overlays for interaction feedback.

### Tasks
- Add `SelectionOverlay.sv`:
  - highlight currently selected component cells
- Add `PlacementPreviewOverlay.sv`:
  - preview component footprint before placement
- Add `CursorHintOverlay.sv`:
  - optional tool-dependent cursor cue
- Add `DeleteRotateTargetOverlay.sv` if needed:
  - highlight hovered target for destructive actions
- Keep all overlay logic read-only from canonical stores + synchronized mouse/tool state.

### Tests
- Overlay renderer tests:
  - selection highlight appears on correct cells
  - preview follows mouse and rotation
  - overlay clipping at canvas boundary
- Integration tests:
  - selected component from CellStore/ComponentStore appears correctly in overlay
  - preview tool changes with toolbar mode

### Exit Criteria
- The UI gives users immediate visual feedback for selection and placement actions.

## Stage 6: Introduce A UI Compositor
### Deliverables
- A reusable UI composition module rather than ad hoc layering in the top.

### Tasks
- Create `UiCompositor.sv` that merges:
  - toolbar
  - property panel
  - overlays
  - canvas
  - mouse cursor
- Define stable z-order rules.
- Remove direct RGB priority logic from `MetaCircuit_top.sv`.

### Tests
- Layer priority tests:
  - cursor overrides panel/canvas
  - panel overrides canvas
  - overlays blend/override as designed
- Top integration test:
  - the top only wires producers into the compositor and no longer contains custom layer logic

### Exit Criteria
- UI layering is centralized and easy to extend without touching the top.

## Stage 7: Clean Up Legacy-Carryover Modules
### Deliverables
- Remove unused UI files from active design2 build path or finish porting them properly.

### Tasks
- Review copied-but-unused files under `src/design2/ui`.
- Either:
  - integrate them fully into the new text/dashboard stack
  - move them to a `legacy_ref` note in comments/docs
  - or delete from design2 if they are dead weight
- Ensure compile order only includes modules actually used by the new UI path.

### Tests
- Build smoke test after cleanup.
- Confirm no missing module references remain.

### Exit Criteria
- `design2/ui` reflects the real architecture instead of being a mixture of active and orphaned ports.

## Stage 8: Full UI Integration Testing
### Deliverables
- Thorough test coverage for the production UI path.

### Test Matrix
- Toolbar selection changes interaction mode.
- Canvas click selects component and property panel updates.
- Property panel actions emit correct canonical commands.
- Component rotation/delete from panel updates projected canvas on next frame.
- Overlay selection matches selected component footprint.
- Empty-state panel renders correctly with no selection.
- Toolbar and property panel do not corrupt frame timing or frame-swap sequencing.
- CDC sanity:
  - no raw sys-domain buses used directly in pixel-domain modules
  - mouse and selection buses cross domains only through named synchronizers

### Suggested Testbench Structure
- `Design2_Toolbar_test.sv`
- `Design2_PropertyPanel_test.sv`
- `Design2_TextRender_test.sv`
- `Design2_Overlay_test.sv`
- `Design2_UiCompositor_test.sv`
- `Design2_UiIntegration_test.sv`

### Verification Modes
- Parse/elaboration tests in Vivado for every new UI module.
- Focused simulation tests for controller FSMs and rendering boundary conditions.
- One top-level smoke implementation after each major stage.

### Exit Criteria
- UI behavior is regression-tested and stable enough to support backend integration work.

## Recommended Execution Order
1. Stage 1: shared text/common UI infrastructure
2. Stage 2: toolbar UI
3. Stage 3: property panel rewrite
4. Stage 5: overlays
5. Stage 6: compositor
6. Stage 4: keyboard/numeric edit flow
7. Stage 7: cleanup
8. Stage 8: full regression pass

## Risks And Watchpoints
- CDC mistakes between `CLK100MHZ` and `clk_pixel` will quietly become timing failures again.
- Reusing legacy text modules without interface cleanup may reintroduce hidden coupling.
- A visually rich toolbar/property panel can bloat pixel-path logic if text and layout are overly combinational.
- Keyboard input can expand scope quickly; keep it optional until the simpler button-driven flow is solid.

## Done Definition
- `design2` has a rendered toolbar, a real property editor, visible selection/preview overlays, and a reusable compositor.
- UI modules are organized cleanly under `src/design2/ui`.
- The production top no longer contains ad hoc UI drawing logic beyond wiring modules together.
- UI behavior has dedicated tests and the routed design still meets timing.
