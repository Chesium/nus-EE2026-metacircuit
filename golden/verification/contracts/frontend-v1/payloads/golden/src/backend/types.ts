// Shared backend interface between netlist extraction (GM-8) and the DC solver
// (GM-7). Field meanings follow src/uart_link/README.md, the spec for the
// frontend/solver UART protocol.

/** Solver-facing element kind codes (uart_link protocol `kind`). */
export const enum ElementKind {
  Resistor = 0x01,
  CurrentDc = 0x02,
  VoltageDc = 0x03,
  Capacitor = 0x04,
  Inductor = 0x05,
}

/** Node index meaning ground (uart_link `n0`/`n1` = FF). */
export const GROUND_NODE = 0xff;

export interface NetlistElement {
  /** Component index in the snapshot (`idx`). */
  idx: number;
  kind: ElementKind;
  /** Solver row indices 0..node_count-1, or GROUND_NODE. */
  n0: number;
  n1: number;
  /** 12-bit packed BCD value as stored by the frontend. */
  valueBcd: number;
  /** Wire (protocol) unit code, the README's solver-board mapping: 00 base,
   * 01 milli, 02 micro, 03 nano, 04 kilo, 05 mega, 06 giga. Extraction
   * translates the frontend unit code (IF-016, e.g. 2 = k) into it
   * (golden/M3_ASSUMPTIONS.md M3-A008); 0xFF marks a unit with no code. */
  unit: number;
}

/** One complete snapshot, as sent frontend -> solver. */
export interface Netlist {
  frame: number;
  /** Non-ground solver rows, 0..0xFE. */
  nodeCount: number;
  elements: NetlistElement[];
}

/** Solver reply, as sent solver -> frontend. */
export interface VoltageSnapshot {
  frame: number;
  /** 0 on success; nonzero reserved for solver/parse errors. */
  status: number;
  /** IEEE-754 float32 node voltages, indexed by solver row. */
  voltages: Float32Array;
}
