# M3 netlist assumptions

These extend the M1 and M2 assumptions. They cover component node extraction
(GM-7, extraction half: `src/backend/netlist.ts`) and the uart_link netlist
export and parser (GM-8: `src/backend/uart.ts`). None of them has been
validated by a human yet.

Behaviour sources (D-007): `src/uart_link/README.md` and `protocol.py` (wire
format), `structure.md` (pipeline: flooding, then node extraction, then
stamping), the netlist convention diagram
`assets/metacircuit-netlist-convention.png`, `notebooks/flooding.ipynb`, the
M2 reciprocal-port graph (`src/core/connectivity.ts`, D-014), and the reference
kernels `simpyhls/examples/flooding_core.dsl.py` and
`extract_component_nodes.dsl.py`. The final report says nothing about node
extraction.

The RTL was read only for the interface facts that the spec leaves open, listed
under "RTL interface facts" at the end. Behaviour was not taken from it, but the
reading exposed some of it; that is listed there too.

The differential test against the simpyhls kernels (`test/simpyhls-diff.test.ts`)
reproduces the kernels exactly with the golden's `dslCompat` mode. With the
golden rules, the remaining differences come from M3-A002 and M3-A003 only. On
the 400 mixed-size random circuits in the test, 198 agree and 202 differ.

---

### M3-A001 Which components become elements, and their kind codes

- **Chosen:** every live two-cell component (R, L, C, V, I) is one element.
  Kind codes are the README's: resistor `01`, DC current source `02`, DC voltage
  source `03`, capacitor `04`, inductor `05`. Ground cells and wires are not
  elements. A ground connects a node to `FF`.
- **Why:** README kind table; `extract_component_nodes` handles only
  "true two-terminal components" and finds grounds in the cell grid.
- **Check:** nothing.

### M3-A002 A terminal connects only through a facing port

- **Chosen:** terminal 0 is the cell beyond the anchor (left) half, and
  terminal 1 is the cell beyond the partner half. A terminal joins the region of
  that cell only if the cell has a port facing the component. Otherwise the
  terminal is floating (M3-A007).
- **Why:** the convention diagram draws every wire that ends at a resistor with
  a port pointing into the resistor. M2's accepted graph (D-014) needs
  reciprocal ports everywhere else, and a component end is drawn as a stub
  pointing along its axis.
- **Differs from simpyhls:** `extract_component_nodes` reads `fetchR` of the
  neighbouring cell without checking its ports. A vertical wire passing the end
  of a horizontal resistor counts as connected there.
- **Check:** draw a resistor with a vertical wire just beyond one end. Should that
  end be connected?

### M3-A003 Grounded regions

- **Chosen:** a region is grounded when it contains an enabled ground cell. A
  ground cell joins a region only through its single reciprocal port (M2 graph).
  So a ground pointing at a perpendicular wire grounds nothing, and a ground
  whose port faces a component terminal grounds that terminal.
- **Why:** the M2 graph already decides which node a ground belongs to (ground
  "participates in a numbered node", `connectivity.ts`), and the node colours
  were accepted.
- **Differs from simpyhls:** the kernel grounds the region of the cell the
  ground's port points at, whether or not that cell's port points back. If that
  cell is a component half (region 0), nothing is grounded, and the ground cell's
  own region becomes an ordinary row.
- **Check:** place a ground that points at a wire not facing it, or at a resistor
  end. Is that node ground?

### M3-A004 Solver row numbering

- **Chosen:** every non-grounded raw region gets a row, in order of its first
  cell in row-major order (row 0, 1, ...). This includes regions that no
  component touches, such as a lone wire. Raw regions themselves are numbered
  row-major, so they match `flooding_core` exactly. That is checked on every
  random circuit.
- **Why:** this is the compaction policy written in `extract_component_nodes.dsl.py`
  ("every other nonzero raw region is assigned in first-seen row-major order
  starting from 0").
- **Consequence:** a wire island earlier in row-major order than the circuit
  leaves an empty row, which makes the matrix singular (reported as an
  `empty-row` issue, M3-A012). Example: `m2_node_colours` checkpoint
  `horizontal_wire_unjoined`. A possible alternative is to number only the
  regions that element terminals touch.
- **Check:** decide whether wire islands may take solver rows.

### M3-A005 `node_count`

- **Chosen:** `node_count` is the highest row used by any element terminal plus
  one, or 0 if no terminal uses a row. Unused rows after that are not sent. Empty
  rows before it are kept (M3-A004).
- **Why:** the README says "number of non-ground solver rows". With M3-A004's
  numbering, that is the smallest system that holds every terminal. The RTL
  agrees (see RTL interface facts).
- **Check:** nothing beyond M3-A004.

### M3-A006 Element order and `idx`

- **Chosen:** elements are sorted by the cell address of their anchor (left
  half), `row * 18 + col`, and `idx` = 0, 1, ... in that order. Golden
  ComponentStore slots, which keep holes (A-011), and the position of the partner
  cell do not affect the order. `elem_count` is the number of elements.
- **Why:** the protocol needs dense `idx` values. The golden's slots differ from
  the RTL's packed store (A-011). The property panel's component identifier is
  already the row-major rank of the anchors (IF-034). The kernels give each
  store index its own result, so their order is free.
- **Check:** compare against the RTL's NC order on scenarios where components
  were deleted and added again.

### M3-A007 Floating terminals

- **Chosen:** a terminal with no connection (empty cell, a cell not facing the
  component, off the grid, or another component's half) is sent as `FF`
  (ground). The element is kept. A `floating-terminal` issue is reported.
- **Why:** `extract_component_nodes` leaves `u8_node0/1 = 255` when the raw
  region is 0.
- **Concern:** this is electrically wrong. A resistor with one end open becomes
  a load to ground, and a source with one end open drives ground. A possible
  alternative is a new row per floating terminal, or dropping the element.
- **Check:** human decision. This is the most consequential M3 choice.

### M3-A008 Unit codes on the wire

- **Chosen:** the NC `unit` field carries the README's solver-board mapping (`00`
  base, `01` milli, `02` micro, `03` nano, `04` kilo, `05` mega, `06` giga). It
  is translated from the frontend codes (IF-016: 0 none, 1 M, 2 k, 3 m, 4 u,
  5 n, 6 p): none -> 00, m -> 01, u -> 02, n -> 03, k -> 04, M -> 05.
  `NetlistElement.unit` (types.ts) holds the wire code. Only its doc comment
  changed.
- **Why:** the README contradicts itself here. The field list says "4-bit
  frontend unit code", but the solver (`frontend_tester.py`, the M3 solver
  under D-012) decodes the field with the solver-board mapping. Only the
  translated codes give the solver the right values.
- **Check:** confirm. The RTL translates the same way.

### M3-A009 Pico has no protocol code

- **Chosen:** a component with unit pico cannot be sent. The whole snapshot is
  rejected, and the frontend sends `@ER,<frame>,82,<arg>` with `arg =
  (frontend_unit << 8) | idx` for the first such element in idx order. The
  element's `unit` is 0xFF in the extracted netlist.
- **Why:** the protocol defines ER records "when a snapshot is rejected". The
  code and arg layout are RTL interface facts. Sending a wrong unit would be
  silently wrong.
- **Check:** confirm, or extend the protocol with a pico code.

### M3-A010 Capacitors and inductors are sent

- **Chosen:** C and L elements are sent with kinds `04`/`05`, as the protocol
  allows. The host solver rejects them, as documented in README "Notes". The
  extraction option `supportedKinds` reproduces a frontend that rejects them
  itself (`@ER,<frame>,81,<idx>`). It is off by default.
- **Why:** the spec puts the rejection on the solver side.
- **Known difference:** the RTL rejects them on the frontend (ER 81; see RTL
  interface facts). M3 scenarios with C or L will differ until a human picks a
  side.
- **Check:** human decision.

### M3-A011 More rows than the protocol can carry

- **Chosen:** golden region and row ids are 16-bit (up to 288 regions, as in M2).
  If `node_count` would exceed `FE`, the snapshot is rejected with the
  golden-defined code `@ER,<frame>,84,<node_count>`. This needs pathological
  canvases, such as a checkerboard of non-joining wires.
- **Why:** the README limits `node_count` to `00..FE`. The kernels' `u8` region
  counter would wrap and merge regions, so no faithful netlist exists.
- **Check:** decide what the RTL should do (it has no such code).

### M3-A012 Degenerate circuits are sent unchanged

- **Chosen:** an element whose two terminals are on the same node (including
  `FF`/`FF`), a circuit where no element terminal reaches a ground, and empty
  rows (M3-A004) are all sent as extracted. The golden reports them as issues
  (`shorted-element`, `no-ground`, `empty-row`) so the solver's status reply can
  be explained. The netlist does not change. A `no-ground` circuit still numbers
  every node.
- **Why:** the protocol has no way to mark them, and the kernels send them.
- **Check:** see what the solver replies for `m2_node_colours` checkpoints
  `ground_removed` and `rails_shorted`.

### M3-A013 The `frame` field and when snapshots are sent

- **Chosen:** the golden sets `frame` to the golden frame index of the state
  (A-001) modulo 2^16. The CLI uses each checkpoint's frame. The RTL instead
  counts its snapshots (see RTL interface facts), so comparisons should ignore
  `frame` (`diffNetlist(..., { ignoreFrame: true })`) and compare the newest
  complete snapshot captured after the checkpoint's state has settled.
- **Why:** the README only requires that `frame` is echoed.
- **Check:** M3 runner design (FS-7).

### M3-A014 Values are passed through

- **Chosen:** `value_bcd` is the component's 12-bit stored BCD value, as is.
  For a newly placed blank component that is `000`. M2-A002's literal text
  (dots, extra digits) does not affect it.
- **Why:** README: "12-bit packed BCD value from board F".
- **Check:** nothing.

### M3-A015 Codec strictness

- **Chosen:** the TS encoder produces byte-identical output to `protocol.py`
  for every in-range field. This is checked on random netlists, voltage and error
  records. It throws on out-of-range fields, where `protocol.py` masks them, and
  on `node_count > FE`. The decoder accepts only uppercase hex and exact field
  widths. Around a line it ignores whitespace, as `protocol.py` does.
  `protocol.py` also accepts lowercase hex (tested). The stream parser follows
  `SnapshotAssembler`, but reports problems (missing CRLF, broken sequences,
  bytes outside records) instead of raising.
- **Why:** the README says "uppercase hexadecimal with fixed width", and a
  verifier should flag anything else.
- **Check:** nothing.

### M3-A016 Executing the kernels in Python

- **Chosen:** `tools/simpyhls_backend.py` runs the DSL sources unchanged. It
  uses simpyhls's own DSL interpreter (`compiler.sim_runtime.run_python`), or
  plain `exec` with `--exec` (same source, faster). The primitive models follow
  the notebook (flooding) and simpyhls's extraction test harness. Reads outside
  the grid return region 0 or visited.
- **Why:** the kernels' bounds checks (`u8_term0_x < grid_width`) rely on `u8`
  wraparound. In plain Python a coordinate of -1 passes the check, and simpyhls's
  own test harness (`result_grid[j][i]`) would then read the last column through
  negative indexing. That is an artefact of the Python model, not of the
  kernel, but simpyhls's tests do not cover components on the grid edge.
- **Check:** nothing.

## RTL interface facts (consulted 2026-10-10)

Read only to settle fields the spec leaves open: the port list of
`src/design/uart/FrontendNetlistLineTransmitter.sv` and, in
`src/design/rendering/GlobalRender_top.v`, the functions
`frontend_protocol_kind_from_store_type`, `frontend_protocol_kind_supported`,
`frontend_protocol_unit_from_component_unit`, the `FRONTEND_STATUS_*` codes
and the netlist header sequencing (roughly lines 700-760, 1292-1295, 2370-2560).

- **RF-1** Kind mapping R 01, I 02, V 03, C 04, L 05 (agrees with M3-A001).
- **RF-2** Unit translation none 00, m 01, u 02, n 03, k 04, M 05, other
  "unsupported" (agrees with M3-A008 and M3-A009).
- **RF-3** Frontend ER codes `81` unsupported kind (`arg = idx`), `82`
  unsupported unit (`arg = {unit, idx}`), `83` reply parse error. Used in
  M3-A009. `84` is golden-only (M3-A011).

Behaviour seen while reading these (not adopted, recorded for comparison):

- **RX-1** The RTL frontend accepts only kinds 01..03 and sends ER 81 for C or L
  (differs from M3-A010).
- **RX-2** The RTL's `node_count` is the highest terminal node index + 1, or 0
  (agrees with M3-A005, which was derived independently).
- **RX-3** `elem_count` is the RTL component-store count. NC `idx` is the store
  index (order unknown; see M3-A006 and X-3 in INTERFACE_FACTS.md). `frame` is a
  snapshot counter that increments per snapshot. A snapshot starts each frame
  once flooding and colours have settled (M3-A013).
