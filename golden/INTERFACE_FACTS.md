# Interface facts taken from the RTL

Under D-007 the golden model may take *interface facts* from the RTL (layout,
constants, data encodings, data tables), but not behaviour. This file lists every
fact used, with its source. Line numbers are at commit `34dc50e`
(`src/design/rendering/GlobalRender_top.v` is abbreviated `GR`).

Only `localparam`/`parameter` declarations, pure encoding/table functions, RAM
instantiations, instance parameter lists and the boot data table were read.
`src/design/interaction/*` and the interaction/command/pan/hover/flood logic were
not studied. See "Incidental exposure" at the end for what was seen by accident.

| ID | Fact | Value used | Source | Used in |
|----|------|-----------|--------|---------|
| IF-001 | Screen size and bar sizes | 640x480; top bar 64, left bar 64, right bar 156, bottom bar 128 | `GR:28-33` | `constants.ts` |
| IF-002 | Canvas cell size | 32 px | `GR:34` | `constants.ts` |
| IF-003 | Grid size and address width | 18 columns x 16 rows = 288 cells; address 9 bits; address = row*18 + col | `GR:35-38`, `GR:259` (`canvas_addr_to_i/j`), `GR:632` (`component_position_from_addr`) | `constants.ts`, `encoding.ts` |
| IF-004 | "No component" index | all ones, 9 bits (0x1FF) | `GR:39` | `state.ts`, `export.ts` |
| IF-005 | Canvas rectangle | (64, 64), 576x288 | `GR:40-43`; instance parameters of `circuit_canvas_inst` `GR:1152-1156` | `geometry.ts` |
| IF-006 | Pan offset (`grid_pos_x/y`) range and meaning | signed offset added to the grid origin; x in [0, 0], y in [-224, 0] | `CircuitCanvas.v:44-49` (`min_grid_x/y`); `grid_pos_x/y_out` port, `CircuitCanvas.v:40-41` | `constants.ts`, `step.ts` |
| IF-007 | Toolbar button geometry | 10 buttons, x0 14, w 36, h 24, gap 2, y0 72 + 26*i | `ToolbarVGA.v:8-13`, `ToolbarVGA.v:41` (`button_y0`); instantiated with defaults, `GR:3240` | `constants.ts` |
| IF-008 | Button hit box | `x0 <= x < x0+W`, `y0 <= y < y0+H` (half-open) | `ButtonVGA.v:57-60` (`inside_button`) | `geometry.ts` |
| IF-009 | Toolbar order (tool index) | 0 pan, 1 wire family, 2 R, 3 L, 4 C, 5 V, 6 I, 7 ground, 8 rotate, 9 delete | `GR:528` (`toolbar_mode_select` cases and comments); `GR:1162` (`mouse_left_click` enabled only for tool 0, i.e. pan) | `constants.ts` |
| IF-010 | Reset values of tool and variant | tool 0, variant 0 | `ToolbarVGA.v:26-27` | `constants.ts` |
| IF-011 | Wire variant codes | 0 wire, 1 junction, 2 elbow, 3 tee | `GR:528` (`toolbar_mode_select`, tool 1) | `constants.ts` |
| IF-012 | Sprite ids | 0 Wire, 1 Elbow, 2 Tee, 3 Junction, 4 Cross, 5/6 RL/RR, 7/8 VL/VR, 9/10 IL/IR, 11/12 LL/LR, 13/14 CL/CR, 15 Ground | `GR:554-568`; `CircuitCanvas.v:908` (`GetRow`) | `constants.ts` |
| IF-013 | Sprites written by each placement tool | tool 1 sprite 0; 2 -> 5/6; 3 -> 11/12; 4 -> 13/14; 5 -> 7/8; 6 -> 9/10; 7 -> 15; all at rotation 0 | `GR:402` (`toolbar_first_cell_data`), `GR:418` (`toolbar_second_cell_data`), `GR:432` (`toolbar_tool_uses_two_cells`) | `constants.ts` |
| IF-014 | Interaction mode codes | wire 0, junction 1, elbow 2, tee 3, R 4, V 5, I 6, rotate 7, delete 8, L 9, C 10, ground 11, none 0xF | `GR:528` (`toolbar_mode_select`) | `constants.ts` (`modeSelect`), semantic export |
| IF-015 | Component kind codes | 0 wire, 1 ground, 2 R, 3 C, 4 L, 5 V, 6 I; sprite -> kind table | `GR:570-576`, `component_type_from_sprite` (`GR:616`) | `constants.ts` |
| IF-016 | Unit codes | 0 none, 1 M, 2 k, 3 m, 4 u, 5 n, 6 p | `GR:577-583` | `constants.ts` |
| IF-017 | CellStore word (16 bit) | `{mode[15:9], rotation[8:7], sprite[6:1], enable[0]}` | `GR:394` (`make_cell_data`); RAM `circuit_canvas_ram_inst` 16 x 288, `GR:1095`; field names `CircuitCanvas.v` cell decode | `encoding.ts` |
| IF-018 | ComponentStore word (40 bit) | `{unit[39:36], index[35:27], type[26:23], rotation[22:21], value[20:9], pos_y[8:5], pos_x[4:0]}`; value = 3 BCD digits (12 bit); type = sprite[3:0] | `GR:584` (`COMPONENT_STORE_ENTRY_W`), `GR:783` (`make_component_store_entry`), `GR:632` (`component_position_from_addr`), `GR:709` (`component_store_type_from_sprite`) | `encoding.ts` |
| IF-019 | Memories and depths | `circuit_canvas_ram` 16 x 288; `component_index_map_ram` 9 x 288; `component_store_ram` 40 x 288 (also fg/bg colour RAMs 4 x 288, not modelled in M1) | `GR:1095-1110`, `GR:1715`, `GR:1719` | `export.ts` |
| IF-020 | Rotation code -> right-half direction | 0 +1 (right), 1 +18 (down), 2 -1 (left), 3 -18 (up) | `GR:838` (`component_pair_addr_from_origin`) | `constants.ts` (`PAIR_DELTA`) |
| IF-021 | Rotate repeat period | `RotateFramesPerStep = 8` (instance parameter) | `GR:3176` | `constants.ts`, `config.ts` |
| IF-022 | Canvas colours | background idx 0 = 0x222, fg idx 15 = 0xFFF, hover idx 14 = 0x280, grid 0x666; default fg/bg idx 15/0 | `CircuitCanvas.v:177-179`, `:955-958` (`palette_idx_to_rgb12`); `GR:59-60` | placeholder renderer |
| IF-023 | Screen background | 0xECC | `GR:27` | placeholder renderer |
| IF-024 | Toolbar button colours | face F4E7D5, border C9AE8E, selected D96B3B, pressed A54924 (RGB888, truncated to 4 bit) | `ToolbarVGA.v:405-409` | placeholder renderer |
| IF-025 | Sprite rotation transform | `GetXX`/`GetYY`: rot 0 identity, 1 = 90 deg clockwise, 2 = 180, 3 = 90 counter-clockwise | `CircuitCanvas.v:870-900` | placeholder renderer |
| IF-026 | Boot circuit (data table) | 17 cell words written after the canvas clear (addresses 38..128, values 0x010 / 0x100) | `GR:3490-3660` (init sequence, `init_cycles == CANVAS_CELL_COUNT + 0..16`) | `bootCircuit.ts` |
| IF-027 | Mouse range set at boot | max x 639, max y 479 | `GR:3472-3475` | `step.ts` (`sanitizeMouse`) |
| IF-028 | framescope memory dumps (FS-3): format, names, encodings | one JSON per memory and frame, `{"name","frame","width","depth","words"}`, words in address order (addr = i + 18*j), zero-padded hex, written to `dumps/<name>/frame_NNNN.json`. Memories (288 words each): `cells_render`, `cells_shadow` (16 bit: [0] occupied, [6:1] sprite, [8:7] rotation, [9] current-flow direction, [15:10] unused), `cell_fg_color`, `cell_bg_color` (4-bit palette index), `values_shadow` (12-bit, 3 BCD digits), `value_units_shadow` (4 bit, same unit codes as IF-016), `component_store` (40 bit, as IF-018, type = sprite id of the origin cell; entries at or above the `component_count` probe are stale and must not be compared), `component_index_map` (9 bit, 0x1FF = none) | coordinator message; `/home/chesium/ee2026_ws/framescope/examples/metacircuit/framescope.toml:111-185` (`[[dump]]` entries) and `:88-89` (`component_count` probe), framescope `77ff7aa` | `export.ts` (`DEFAULT_DUMP_NAMES`, `decodeMemories`), `cli/main.ts` |
| IF-029 | Input-to-effect latency (RTL-3, measured with framescope, inputs changed on line 10) | 1 frame: an input change during frame N is first visible in frame N+1 (cursor, hover, toolbar, canvas edits; the cell RAM write lands in the vertical blanking before frame N+1). Dumps are taken at the end of each frame; frame 0 is the first captured frame | coordinator message (measurement) | `config.ts` (`inputLatencyFrames = 1`), web shell cursor |

The asset renderer (`src/render/assetRenderer.ts`) also uses the GM-4 files in
`golden/assets/` (colours, bitmaps, pixel rules, validated pixel-exact against RTL
frames). It applies the three documented RTL rendering quirks: the canvas cell-data
lag at dx = 0, the cursor drawn 2 px right with its last column hidden, and the
cursor colour hold (via `sprites_as_displayed`). Those files are shared with the
RTL on purpose (D-007) and are documented in `golden/assets/README.md`.

The framescope manifest's comments also describe how the RTL rebuilds the
ComponentStore (scan order, packing) and when colour RAMs are reset. Only the
encodings and the "stale above `component_count`" comparison rule were taken from
it (as the coordinator asked); the rebuild behaviour was not adopted (A-011).

## Incidental exposure (behaviour seen by accident)

Listed for honesty, so a reviewer can judge whether an assumption might be
contaminated. None of these was used to derive behaviour.

- **X-1** `ToolbarVGA.v` around lines 380-386: while reading the button
  instantiation (geometry), the tail of the selection `always` block was visible:
  an `else` branch assigning `selected_wire_variant <= 2'd0` and
  `selected_tool_idx <= hovered_tool_idx`. The conditions were not visible. This
  may mean the RTL resets the wire variant in some case. A-007 was decided from the
  photos and was not changed.
- **X-2** A repository-wide grep for `RotateFramesPerStep` printed three lines of
  `src/design/interaction/InteractionController.v` (lines 11, 37, 501: the default
  of 20, the counter width, and `rotate_frame_holdoff <= RotateFramesPerStep - 1`).
  A-012 (rotate on press, then every N frames while held) follows from the
  parameter name and the plan's wording ("RotateFramesPerStep holdoff").
- **X-3** `GR:1339-1343` and `GR:3748` (seen while looking for how
  `make_component_store_entry` is called, to learn the default value) show that
  the RTL fills `component_store_ram` from a scan over canvas cells
  (`component_store_scan_*`, `component_store_next_index`), with values kept per
  cell (`value_shadow_data`). So the RTL store is probably derived from the cells and
  compacted, unlike structure.md. The golden keeps structure.md's smallest-free-slot
  rule (A-011). The comparator ignores slots by default; expect differences in slot
  numbers and the `index` field.
- **X-4** `golden/assets/README.md` (written by the GM-4 agent, read after A-007
  was decided) says that clicking the selected wire button advances the variant,
  and that pan is the only tool that enables canvas dragging. This agrees with A-007
  and A-013.
