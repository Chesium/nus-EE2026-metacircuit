// The default circuit the RTL writes into the canvas at boot (a data table, IF-026):
// GlobalRender_top.v, the init sequence at init_cycles == CANVAS_CELL_COUNT + 0..16.
// Each entry: [cell address, 16-bit cell word, 3-digit BCD value, unit code].
// The words are kept exactly, including metadata bit 9 (the flow-direction bit).
//
// Decoded (col,row): (2,2) Elbow r1, (3,2)-(4,2) voltage source value 010 (anchor
// (4,2) VL r2, partner (3,2) VR r2), (5,2) Elbow r2, (2,3) Wire r1, (5,3) Wire r1,
// (2,4) Tee r1, (3,4)-(4,4) resistor r0 value 100, (5,4) Tee r3, (2,5) Wire r1,
// (5,5) Wire r1, (2,6) Tee r1, (3,6)-(4,6) resistor r0 value 100, (5,6) Elbow r3,
// (2,7) Ground r1.
//
// D-015 turned the voltage source 180 degrees so that its + half (the anchor, VL)
// faces the right rail: the netlist is V n0 = right rail (row 0), n1 = ground,
// and node 0 solves to +10 V. Words derived from the cell encoding (IF-017:
// {meta[15:9], rot[8:7], sprite[6:1], en[0]}) and A-019's rotation codes
// (rotation 2 puts the partner at -x):
//   addr 39 = (3,2): VR (8) rot 2 -> 0x0111;  addr 40 = (4,2): VL (7) rot 2 -> 0x010f.
// Bit 9 follows the convention of the other boot words, which the flow renderer
// reads as a screen direction (horizontal: 0 = +x, 1 = -x; vertical: 0 = +y,
// 1 = -y): it marks the conventional current of the solved circuit. With + on
// the right rail, current leaves the source into (5,2), runs down the right
// rail (0x0081, bit 9 = 0), right to left through both resistors (0x020b/0x020d,
// bit 9 = 1), up the left rail (0x0281, bit 9 = 1) and through the source from
// (3,2) to (4,2), i.e. +x: bit 9 = 0 on both halves. Every other word is
// unchanged; they already describe this current loop (the old table, with the
// + half facing the grounded left rail, solved to -10 V against its own flow bits).
// The ComponentStore entry is {VL, col 4, row 2, rotation 2, value 010, unit 0}.

export const BOOT_CIRCUIT: ReadonlyArray<readonly [addr: number, word: number, valueBcd: number, unit: number]> = [
  [38, 0x0083, 0x000, 0],
  [39, 0x0111, 0x010, 0],
  [40, 0x010f, 0x010, 0],
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
