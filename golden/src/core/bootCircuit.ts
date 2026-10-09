// The default circuit the RTL writes into the canvas at boot (a data table, IF-026):
// GlobalRender_top.v, the init sequence at init_cycles == CANVAS_CELL_COUNT + 0..16.
// Each entry: [cell address, 16-bit cell word, 3-digit BCD value, unit code].
// The words are kept exactly, including metadata bit 9 (the flow-direction bit).
//
// Decoded (col,row): (2,2) Elbow r1, (3,2)-(4,2) voltage source r0 value 010,
// (5,2) Elbow r2, (2,3) Wire r1, (5,3) Wire r1, (2,4) Tee r1, (3,4)-(4,4) resistor
// r0 value 100, (5,4) Tee r3, (2,5) Wire r1, (5,5) Wire r1, (2,6) Tee r1,
// (3,6)-(4,6) resistor r0 value 100, (5,6) Elbow r3, (2,7) Ground r1.

export const BOOT_CIRCUIT: ReadonlyArray<readonly [addr: number, word: number, valueBcd: number, unit: number]> = [
  [38, 0x0083, 0x000, 0],
  [39, 0x000f, 0x010, 0],
  [40, 0x0011, 0x010, 0],
  [41, 0x0103, 0x000, 0],
  [56, 0x0281, 0x000, 0],
  [59, 0x0081, 0x000, 0],
  [74, 0x0285, 0x000, 0],
  [75, 0x020b, 0x100, 0],
  [76, 0x020d, 0x100, 0],
  [77, 0x0185, 0x000, 0],
  [92, 0x0281, 0x000, 0],
  [95, 0x0081, 0x000, 0],
  [110, 0x0085, 0x000, 0],
  [111, 0x020b, 0x100, 0],
  [112, 0x020d, 0x100, 0],
  [113, 0x0183, 0x000, 0],
  [128, 0x009f, 0x000, 0],
];
