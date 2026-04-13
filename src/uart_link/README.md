# UART Link Protocol

This folder contains the first host-side protocol and relay tools for the
two-board split architecture:

- Board `F` (frontend) sends extracted netlists to board `S`
- Board `S` (solver) sends solved node voltages back to board `F`
- A laptop relay sits between them during bring-up

## Design Goals

- Easy to inspect in a serial console
- Easy to generate later in Verilog
- Strong enough framing to avoid silent desync
- Simple enough to test thoroughly in Python first

## Framing

Each UART record is one ASCII line:

```text
@<payload>*<checksum>\r\n
```

- `@` starts a record
- `<payload>` is comma-separated ASCII fields
- `*` separates payload from checksum
- `<checksum>` is two uppercase hex digits
- checksum is the XOR of every ASCII byte in `<payload>`

Example:

```text
@NB,0012,03,01*21\r\n
```

## Record Types

All numeric fields are uppercase hexadecimal with fixed width.

### Netlist Snapshot: `F -> S`

Begin record:

```text
@NB,<frame:4>,<elem_count:2>,<node_count:2>*CC
```

Component record:

```text
@NC,<frame:4>,<idx:2>,<kind:2>,<n0:2>,<n1:2>,<value_bcd:3>,<unit:2>*CC
```

End record:

```text
@NE,<frame:4>,<elem_count:2>,<node_count:2>*CC
```

Field meanings:

- `frame`: request/frame identifier echoed back by board `S`
- `elem_count`: number of indexed components in the snapshot
- `node_count`: number of non-ground solver rows, `00..FE`
- `kind`: solver-facing element kind code
- `n0`, `n1`: node indices, `FF` means ground
- `value_bcd`: 12-bit packed BCD value from board `F`
- `unit`: 4-bit frontend unit code carried in an 8-bit field

Suggested initial kind codes:

- `01` resistor
- `02` DC current source
- `03` DC voltage source
- `04` capacitor
- `05` inductor

### Voltage Snapshot: `S -> F`

Begin record:

```text
@VB,<frame:4>,<node_count:2>,<status:2>*CC
```

Node voltage record:

```text
@VN,<frame:4>,<node:2>,<value_bits:8>*CC
```

End record:

```text
@VE,<frame:4>,<node_count:2>,<status:2>*CC
```

Field meanings:

- `node`: solver row index `00..FE`
- `value_bits`: IEEE-754 float32 bits in hex
- `status`: `00` means success; nonzero reserved for solver/parse errors

### Error Record

Used by the relay or by either board when a snapshot is rejected:

```text
@ER,<frame:4>,<code:2>,<arg:4>*CC
```

## Snapshot Semantics

- Board `F` sends complete snapshots, not incremental edits
- Board `S` treats each snapshot as a full solve request
- `frame` is echoed back unchanged in the response
- Board `F` should ignore late responses whose `frame` no longer matches the
  newest outstanding request

## Suggested Bring-Up Flow

1. Board `F` sends `NB`, `NC...`, `NE`
2. Laptop relay validates and forwards to board `S`
3. Board `S` parses, converts BCD+unit to float32, solves
4. Board `S` sends `VB`, `VN...`, `VE`
5. Laptop relay validates and forwards to board `F`

## Python Modules

- `protocol.py`: packet dataclasses, encoding/decoding, snapshot assembly
- `relay.py`: serial relay and in-memory relay harness for testing
- `solver_tester.py`: automatic hardware tester for board `S` on a single COM port
- `frontend_tester.py`: laptop-side simulated board `S` that receives frontend netlists, runs the local simpyhls DC solver, and sends `VB/VN/VE` replies back
- `tests/`: unit tests for protocol and relay behavior

## Solver Board Hardware Test

For standalone board `S` bring-up, the automatic tester can send built-in
snapshots directly to one COM port and validate the returned `VB/VN/VE`
response:

```text
python -m src.uart_link.solver_tester --list
python -m src.uart_link.solver_tester --port COM16
python -m src.uart_link.solver_tester --port COM16 --case voltage_divider_5v_3k_2k
```

The current built-in cases are designed to match the existing solver-board
UART protocol and the known-good hardware smoke tests.

## Frontend Board Test Against Simulated Solver

To test board `F` before wiring in the real solver board, the laptop can act as
a simulated board `S`. The tester below listens on one COM port, assembles
`NB/NC/NE`, runs the local `simpyhls/examples/solve_core_dc.dsl.py` flow, and
sends `VB/VN/VE` back to the frontend:

```text
python -m src.uart_link.frontend_tester --port COM16
python -m src.uart_link.frontend_tester --port COM16 --once
```

Notes:

- The current host solver accepts only `R`, `I`, and `V` kind codes.
- BCD + unit conversion follows the solver-board mapping:
  - `00` base
  - `01` milli
  - `02` micro
  - `03` nano
  - `04` kilo
  - `05` mega
  - `06` giga
- Unsupported kinds or invalid BCD/unit fields return an `ER` packet so the
  frontend can show a receive-side error without needing board `S`.
