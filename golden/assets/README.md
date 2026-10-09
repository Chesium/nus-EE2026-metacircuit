# golden/assets: visual assets extracted from the RTL

These JSON files hold the bitmaps, colours and geometry that the MetaCircuit RTL
draws, so the golden model (verification plan GM-5, GM-6) can render frames that
match the RTL pixel for pixel. Per decision D-007 the assets are shared with the
RTL on purpose: a wrong bitmap in the RTL is wrong in the golden model too, and
asset bugs are out of scope for RTL/golden comparison.

They are generated. Do not edit them by hand.

```sh
python3 golden/tools/extract_assets.py           # regenerate (from the repo root)
python3 golden/tools/extract_assets.py --check   # exit 1 if any file is stale
python3 -m unittest golden/tools/test_extract_assets.py -v
```

The extractor uses only the Python 3 standard library and gives byte-identical
output for the same RTL. If the RTL changes shape (a function, table, parameter or
expression the extractor relies on is missing or different), it exits with status 2
and a message naming the file and construct, and writes nothing. It never writes
partial data.

| File | Contents | RTL sources |
|------|----------|-------------|
| `canvas.json` | 16 circuit sprites (32x32), sprite ids, rotation transforms, cell word layout, 16-entry palette, grid/hover/flow colours, canvas geometry | `CircuitCanvas.v`, `GlobalRender_top.v` |
| `toolbar.json` | 10 tool buttons: geometry, tool order and names, 24x24 icons, button style per state | `ToolbarVGA.v`, `ButtonVGA.v`, `GlobalRender_top.v` |
| `cursor.json` | 28x28 mouse cursor (normal and pressed), colours, placement relative to the mouse | `MouseDisplay.vhd` |
| `keypad.json` | 19-key on-screen keypad: layout, labels, per-key role maps, colours per state, 5x7 and 3x5 glyphs | `KeyboardVGA.v`, `ButtonVGA.v`, `GlobalRender_top.v` |
| `screen.json` | Top-level composition: background, bar colours and regions, layer priority, property panel colour constants | `GlobalRender_top.v`, `ComponentPropertyPanel.v` |
| `font8x8.json` | 8x8 ASCII font (32..126) used by the property panel text | `Dashboard/FontROM.v` |

`CompactDigitROM.v` is not extracted: nothing on the VGA path uses it (only
`MatrixDisplay.v`, which is not instantiated). The keypad does not use
`FontROM.v`. Its labels come from `ButtonVGA.v`'s `glyph5x7`.

## Conventions shared by all files

- **Screen coordinates** are the RTL's `x_pos`/`y_pos` (0..639, 0..479). These are
  also framescope PNG pixel coordinates: the metacircuit manifest sets
  `de_delay = 2`, which removes the two output register stages. Every layer is drawn
  at its nominal position, with two exceptions: the cursor is shifted 2 px right
  (`cursor.json`), and the canvas has a one-pixel data lag (see `canvas.json`).
- **Bitmap rows** are arrays of strings. `rows[0]` is the top row. Within a row,
  character 0 is the **leftmost** pixel. The strings are the RTL's binary
  literals written MSB first, so character `c` of a W-bit row is bit `W-1-c`.
  This is how the RTL indexes them (`row[31 - x]`, `row_bits[23 - x]`,
  `row_bits(27 - x)`, `pixel_row[7 - col]`). The exception is the canvas sprites:
  see rotation below.
- **Colours** are objects `{"rgb12": "0xRGB", "rgb24": "#rrggbb"}`. `rgb12` is the
  4-bit-per-channel value on the VGA pins. `rgb24` replicates each nibble
  (`0xA` -> `0xAA`), which is what framescope writes to PNGs (`fs_expand8` in
  `framescope/src/framescope/codegen.py` replicates bits; for 4-bit channels that is
  `v * 17`). Where the RTL gives a 24-bit colour and truncates it with
  `rgb888_to_444` (keeps the high nibble), the original is kept as `rtl_rgb888`.
  Always compare using `rgb12` or `rgb24`, never `rtl_rgb888`.
- **`source`** block in every file: `generator`, `rtl_commit` (the last commit that
  touched any listed file, `git log -1 --format=%H -- <files>`), and for each file
  its `path`, `sha256` and `line_ranges` (named 1-based inclusive `[first, last]`
  line ranges the extractor read). We record the last commit to touch the files,
  not `git rev-parse HEAD`, because HEAD changes on every unrelated commit. With
  HEAD the output would never stay byte-identical.
- **`rtl_literal_notes`** in every file: RTL literals whose digit count differs
  from their declared width (see "RTL oddities" below). The extracted data follows
  Verilog semantics: a literal with too few digits is zero-extended on the left.
- `schema` / `schema_version` (currently 1) identify the format. A change that is
  not backwards compatible bumps the version.

## canvas.json

### Sprites

`sprites` is a list ordered by sprite id 0..15:
`{"id", "name" (RTL function), "top_level_localparam" (SPRITE_* name in GlobalRender_top, null for id 4 Cross), "rows"}`.
Each `rows` value is 32 strings of 32 `'0'`/`'1'`. `'1'` is a foreground pixel.

| id | name | id | name |
|----|------|----|------|
| 0 | Wire | 8 | VR (voltage source, right half) |
| 1 | Elbow | 9 | IL (current source, left) |
| 2 | Tee | 10 | IR |
| 3 | Junction | 11 | LL (inductor, left) |
| 4 | Cross | 12 | LR |
| 5 | RL (resistor, left half) | 13 | CL (capacitor, left) |
| 6 | RR | 14 | CR |
| 7 | VL | 15 | Ground |

Two-cell components use a left and a right sprite in neighbouring cells. Ids
16..63 (the field is 6 bits) draw nothing.

### Rotation

The cell word's 2-bit rotation code `ro` selects how the sprite is sampled. The
pixel at cell offset `(dx, dy)` takes its value from `sprites[id].rows[src_row][src_col]`.
`dx = 0` is the cell's left column and `dy = 0` its top row, both 0..31.
`rotation.codes[ro]` gives:

| ro | src_row | src_col | effect on the image |
|----|---------|---------|---------------------|
| 0 | `dy` | `dx` | identity (rows are drawn as written) |
| 1 | `31 - dx` | `dy` | rotate 90 degrees clockwise |
| 2 | `31 - dy` | `31 - dx` | rotate 180 degrees |
| 3 | `dx` | `31 - dy` | rotate 90 degrees counter-clockwise |

Each entry also has a linear form (`src_row_linear`, `src_col_linear`:
`const + dx*coef_dx + dy*coef_dy`) for code, and the raw RTL expressions
(`rtl_GetYY` = source row, `rtl_GetXX` = source *bit index*). The RTL computes
`GetRow(id, GetYY(dx,dy,ro))[GetXX(dx,dy,ro)]`, a bit index into the 32-bit word,
and the string column is `31 - bit`. So rotation 0 has `GetXX = 31 - dx` but
`src_col = dx`. The extractor checks the table above against a direct simulation
of `GetXX`/`GetYY` for all 1024 offsets, and checks that each is a bijection and a
rotation. Example: the Wire sprite is a horizontal band (rows 13..18). With
`ro = 1` it becomes a vertical band (columns 13..18), as in the RTL frames.

### Cell word, palette and colours

- `cell_word.fields`: `enable` bit 0, `type` (sprite id) bits 6:1, `rotation` bits
  8:7, `mode` bits 15:9. `flow_bit` (bit 9) sets the flow-animation direction. The
  renderer ignores the other mode bits. Cell `(i, j)` is at address `i + j*grid_w`.
- `palette`: 16 entries `{index, rgb12, rgb24}`. Entry 15 is the RTL's `default`
  case (white). Each cell has 4-bit foreground and background palette indices,
  stored in separate RAMs.
- `colors`: `grid` (0x666), `flow_yellow` (0xFF0), `default_fg_idx` 15,
  `default_bg_idx` 0, `hover_bg_idx` 14, and the top level's defaults for the
  colour RAMs.
- `geometry`: canvas at (64, 64), 576x288, cells 32 px, grid 18x16 cells (taken from
  the `circuit_canvas_inst` parameter overrides in `GlobalRender_top.v`).
  `pan_offset_range` gives the clamp for `grid_pos`: x is fixed at 0 because the
  grid is exactly as wide as the canvas; y ranges over -224..0.

### Pixel rule

`pixel_rule` in the JSON has the full text. In short, for a pixel inside the canvas:

1. `ax = x - 64 - grid_pos_x`, `ay = y - 64 - grid_pos_y`, cell `(i, j) = (ax div 32, ay div 32)`,
   offset `(dx, dy) = (ax mod 32, ay mod 32)`. A cell outside the 18x16 grid reads as empty, with fg 15 and bg 0.
2. `visible = enable && sprite bit at (dx, dy) && dx != 31 && dy != 31`. The sprite's
   last row and column are never shown.
3. `grid = dx == 0 || dy == 0 || dx == 31 || dy == 31` (`GridMarginWidth = 2`; grid lines
   are always on, since `display_grid` is unused).
4. Colour, highest priority first: flow yellow (animated, see below); `palette[fg]` if
   `visible` (sprite pixels at `dx == 0` or `dy == 0` draw over the grid line);
   `grid` colour; otherwise `palette[hover_bg_idx]` if the mouse is in this cell,
   else `palette[bg]`.
5. **One-pixel data lag (RTL quirk).** The cell word and the fg/bg indices are
   registered, so each pixel uses the cell data fetched for pixel `x - 1`, while
   `dx`, `dy`, the grid test and the hover test use `x`. Only the `dx == 0` column
   of each cell is affected. There, `visible`/fg come from the *left neighbour's*
   sprite, sampled at `dx = 0` with the neighbour's rotation. At `x = 64` (the
   canvas's first column) the data is empty. Without this rule, 50 to 60 pixels of
   the default circuit differ per frame (for example, a vertical wire's grid-line
   column takes the colour of the cell to its left).

`flow_animation` lists the constants of the animated current highlight (yellow
bands 5 px wide, moving with `anim_phase`). That is renderer logic, not an asset.
It is listed for reference only and should stay masked until RTL-1.

## toolbar.json

- `region`: x 0..63, y 64..351, background 0xFDB. The toolbar covers the left bar.
- `parameters`: ToolbarVGA defaults. `GlobalRender_top` overrides none
  (`instance_overrides` is empty).
- `buttons[k]` for k = 0..9: `x0, y0, w, h` (36x24 at (14, 72 + 26k)), `icon_x0, icon_y0`,
  `icon` (index into `icons`), `tool` and `interaction_mode`. Names and mode codes
  come from `toolbar_mode_select` in `GlobalRender_top.v` and its comments. For button 1
  (wire family) `icon`, `tool` and `interaction_mode` are maps keyed by wire variant
  "0".."3" (wire, junction, elbow, tee: icons 10..13). Clicking button 1 while it is
  selected advances the variant. Button 0 is the pan tool. It is the only tool for
  which CircuitCanvas drag-panning is enabled.
- `icons["0".."13"]`: `{rtl_case, rows}`, 24 rows of 24 chars. A `'1'` draws black
  (0x000) at `(icon_x0 + c, icon_y0 + r)`, over the button including its border.
  `rtl_case` names the RTL case branch used. Icon 9 (delete) is the `default` branch.
- `button_style`: `params` (BORDER 2, EDGE_THICK 2, marker 2x2 at offset 5), `role_map`
  (24 strings of 36 chars), `role_legend`, and `state_colors[state][role]` for states
  `normal`, `selected`, `pressed`, `selected_pressed`. Roles: `B` border, `T`
  top/left bevel, `R` bottom/right bevel, `M` selected marker (face colour unless
  selected), `F` face, `X` text (unused here, since toolbar buttons have no label).
  The derived colours (lighten/darken a quarter or an eighth in 8-bit, then
  truncate to 4-bit) are computed the way `ButtonVGA.v` computes them. The extractor
  checks the RTL expressions it mirrors.
- States: `selected` = the selected tool; `pressed` = left button held while the
  mouse is in that button's box. There is no hover-only style.
- Pixel: background; inside button k:
  `state_colors[state][role_map[y - y0][x - x0]]`; then icon pixels in black.

## cursor.json

- `sprites.hover` / `sprites.pressed`: 28 strings of 28 chars, `'O'` outline (0x000),
  `'F'` fill (0xFFF), `'.'` transparent. `pressed` is used while the left button is
  held. The RTL builds these from four tables, also given under `raw_tables`
  (`'0'/'1'`, same char order): the outline (normal or pressed) wins, then `fill`,
  OR'd with `pressed_fill` when pressed.
- **`sprites_as_displayed`** gives the pixels the RTL actually shows. **Use these for
  pixel-exact rendering.** The colour register in `MouseDisplay` updates only when
  the previous pixel was enabled, so the first pixel of each horizontal run keeps
  the colour of the last pixel of the previous run in scan order. The cursor of the
  previous frame counts too; both sprites end in an outline pixel, so the result
  does not depend on the previous sprite. `as_displayed_changes` lists the pixels
  that differ: none for `hover`, 4 for `pressed`. The exception is the first frame
  after reset (uninitialised register).
- `placement`: sprite pixel `(c, r)` is drawn at screen `(mouse_x + c + 2, mouse_y + r)`.
  The 2 px offset comes from MouseDisplay's two register stages, which the rest of
  the screen does not have. Column 27 is never shown (no sprite uses it). The
  cursor is the top layer. Here `mouse_x/mouse_y` is the position on the
  `MouseDisplay` ports. Since commit 34dc50e it is latched once per frame, at the
  VSYNC leading edge.

## keypad.json

- `region`: (485, 352), 155x128, background 0xFFE (never visible: the keys tile the
  whole region).
- `keys[0..19]`: `id, enabled, x0, y0, w, h, label, ascii, kind, face_rtl_color`. Each
  enabled key also has `text_cols`, `small_text`, `role_map` (h strings of w chars,
  with the label already rendered as `X` pixels) and `state_colors` (same roles and
  states as the toolbar). Key 19 is disabled (`KEY_COUNT = 19`). Keys 17 (DEL, 46
  px) and 18 (RST, 47 px) share the last three columns of row 3.
- States: `selected` = the mouse is over the key. `pressed` = over the key with the
  left button held, which is always also selected, so use `selected_pressed`. The
  keypad reads the mouse through the 20 Hz `clk_nav` domain, so its state lags the
  pixel-domain mouse by several frames.
- `glyphs.glyph5x7` / `glyphs.glyph3x5`: label fonts (rows top first, char 0
  leftmost) for reference. Labels are drawn at scale 2 (`FONT5_SCALE`), centred
  with `(W - text_w) >> 1`, `(H - text_h) >> 1`, and a one-glyph-cell gap between
  characters.

## screen.json

Background 0xECC; `blanking` 0x000; top/left/right bar regions with fill, grid-line
colour (screen `x mod 32 == 0 || y mod 32 == 0`), the top bar's four boxes, and the
right bar's three white frame outlines. `layer_priority` is the final output mux
order: cursor > keypad > canvas > waveforms (disabled) > property panel > bars and
background. In practice the property panel (enabled, 640x64, `COLOR_BG` 0xECC)
covers the top bar, the toolbar covers the left bar, and the canvas and keypad
cover most of the right bar. Only column x = 484 for y >= 352 shows it (0xDDD).
`property_panel_colors` are the panel's constants. `property_panel_layout` holds
the absolute panel, caption, value-box and separator coordinates. Its text content
is dynamic and not extracted. The panel's registered enable/color shifts its
layer one pixel right; the text has a further one-pixel register delay. Column 0
therefore retains the top-bar grid colour. The renderer consumes `font8x8.json`
for panel glyphs and frame-locked caret/flow phases (INTERFACE_FACTS IF-030–033).

## font8x8.json

`glyphs["32".."126"]`: 8 rows of 8 chars (char 0 leftmost = bit 7). ROM address = ASCII - 32.

## How this was validated

A scratch script (not committed) decoded every visible canvas cell of real RTL
frames from framescope (`examples/metacircuit` runs: the default circuit, a click
on the resistor tool, and a second run that hovers and presses keypad key "5" and
cycles the wire tool to variant 1). The cells were decoded into (sprite, rotation,
fg, bg) from these assets. The script then re-rendered the canvas, toolbar, keypad,
cursor and the bottom background from the JSON and compared every pixel with the
PNGs. Result: 0 mismatching pixels, excluding the animated yellow flow pixels.
This needs the canvas data-lag rule and `sprites_as_displayed` for the pressed
cursor. Exercised: rotations 0..3, sprites Wire, Elbow, Tee, RL, RR, VL, VR and
Ground, palette entries 0, 1, 2, 14 and 15, grid, hover, toolbar states normal,
selected and selected_pressed, toolbar icons 0, 2..9, 10 and 11, both cursors, and
keypad states normal, selected and selected_pressed. The cursor tables were also
compared with the SV port in framescope (`stubs/MouseDisplay.sv`): identical.

## RTL oddities noticed (not fixed; assets follow the RTL)

- `ToolbarVGA.v` has four 24-bit icon rows written with 23 binary digits (icon 5
  rows 16 and 17, icon 6 row 17, delete icon row 15). Verilog zero-extends them, so
  those rows are shifted one pixel right. The minus bar of the voltage-source icon,
  for example, sits off-centre. See `toolbar.json` `rtl_literal_notes`.
- Pressed cursor: `fill_row` (the normal cursor's fill) still applies when pressed.
  This leaves four stray fill pixels outside the pressed outline: (row, col) (4,4),
  (4,5), (5,4) and (23,12). Because of the colour-hold quirk, three of them show
  black, and the outline pixel (4,7) shows white.
- Canvas: one-pixel data lag at `dx == 0` (above). Sprite row 31 and column 31 are
  never drawn. `display_grid` is unused.
- Toolbar icon 1 is never shown. Button 1 always uses icons 10..13, and icon 10
  has the same bitmap as icon 1.
- Right bar grid line and fill both truncate to 0xDDD.
