import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import {
  FRONTEND_ERROR_NODE_OVERFLOW, FRONTEND_ERROR_UNSUPPORTED_KIND, FRONTEND_ERROR_UNSUPPORTED_UNIT, UNIT_UNSUPPORTED,
  diffNetlist, extractFromCanvas, extractNetlist, protocolUnitOf, snapshotUart, type PlacedComponent,
} from '../src/backend/netlist.ts';
import { ElementKind, GROUND_NODE, type Netlist } from '../src/backend/types.ts';
import { decodeUartCapture, netlistReferences, parseFrameList, writeNetlistReferences } from '../src/cli/netlist.ts';
import { makeCell } from '../src/core/encoding.ts';
import { GRID_H, GRID_W, PAIR_DELTA, Sprite, Unit } from '../src/core/constants.ts';
import { initialState } from '../src/core/state.ts';
import { expandScenario } from '../src/scenario/expand.ts';
import type { Scenario } from '../src/scenario/types.ts';

const FF = GROUND_NODE;

/** A small canvas builder: conductors by sprite/rotation, components by anchor. */
function canvas(width: number, height: number) {
  const cells = new Uint16Array(width * height);
  const components: PlacedComponent[] = [];
  const api = {
    cell(col: number, row: number, sprite: number, rotation = 0) { cells[row * width + col] = makeCell(sprite, rotation); return api; },
    part(col: number, row: number, leftSprite: number, rotation = 0, valueBcd = 0x100, unit: number = Unit.None, slot?: number) {
      const [dx, dy] = PAIR_DELTA[rotation]!;
      api.cell(col, row, leftSprite, rotation).cell(col + dx, row + dy, leftSprite + 1, rotation);
      components.push({ leftSprite, col, row, rotation, valueBcd, unit, ...(slot === undefined ? {} : { slot }) });
      return api;
    },
    input: () => ({ cells, width, height, components }),
    extract: (opts = {}) => extractFromCanvas(api.input(), opts),
  };
  return api;
}

describe('boot circuit netlist (written out from the spec)', () => {
  // Boot canvas (IF-026): left rail column 2 rows 2..7 with ground at (2,7);
  // right rail column 5 rows 2..6. V source (3,2)-(4,2) value 010, resistors
  // (3,4)-(4,4) and (3,6)-(4,6) value 100, all rotation 0, unit none.
  // Raw regions: left rail 1 (first at (2,2)), right rail 2 (first at (5,2)).
  // Region 1 holds the ground -> FF; region 2 -> row 0. Anchors in row-major
  // order give idx 0 = V, 1 = upper R, 2 = lower R; n0 is the left rail.
  const expected: Netlist = {
    frame: 0,
    nodeCount: 1,
    elements: [
      { idx: 0, kind: ElementKind.VoltageDc, n0: FF, n1: 0, valueBcd: 0x010, unit: 0x00 },
      { idx: 1, kind: ElementKind.Resistor, n0: FF, n1: 0, valueBcd: 0x100, unit: 0x00 },
      { idx: 2, kind: ElementKind.Resistor, n0: FF, n1: 0, valueBcd: 0x100, unit: 0x00 },
    ],
  };
  const uart = [
    '@NB,0000,03,01*22',
    '@NC,0000,00,03,FF,00,010,00*13',
    '@NC,0000,01,01,FF,00,100,00*10',
    '@NC,0000,02,01,FF,00,100,00*13',
    '@NE,0000,03,01*25',
  ].map((l) => `${l}\r\n`).join('');

  it('extracts the hand-derived netlist and region evidence', () => {
    const r = extractNetlist(initialState());
    expect(r.netlist).toEqual(expected);
    expect(r.regionCount).toBe(2);
    expect(r.groundRegions).toEqual([1]);
    expect(r.rowOfRegion).toEqual({ 2: 0 });
    expect(r.issues).toEqual([]);
    expect(r.rejection).toBeNull();
    expect(r.elements.map((e) => e.terminals)).toEqual([
      [{ col: 2, row: 2 }, { col: 5, row: 2 }],
      [{ col: 2, row: 4 }, { col: 5, row: 4 }],
      [{ col: 2, row: 6 }, { col: 5, row: 6 }],
    ]);
  });

  it('encodes to the expected uart_link text', () => {
    expect(snapshotUart(extractNetlist(initialState()))).toBe(uart);
    // frame field: the state's frame index by default, or as given
    const s = { ...initialState(), frame: 0x1235 };
    expect(extractNetlist(s).netlist.frame).toBe(0x1234);
    expect(extractNetlist(s, { frame: 0x10012 }).netlist.frame).toBe(0x0012);
  });
});

describe('extraction rules', () => {
  it('maps every component type to its kind code and frontend units to protocol units', () => {
    const c = canvas(10, 5);
    [Sprite.ResLeft, Sprite.CurrLeft, Sprite.VoltLeft, Sprite.CapLeft, Sprite.IndLeft].forEach((s, i) => c.part(i * 2, i, s));
    expect(c.extract().netlist.elements.map((e) => e.kind)).toEqual([1, 2, 3, 4, 5]);
    expect([Unit.None, Unit.Milli, Unit.Micro, Unit.Nano, Unit.Kilo, Unit.Mega, Unit.Pico].map(protocolUnitOf))
      .toEqual([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, UNIT_UNSUPPORTED]);
  });

  it('finds n0 beyond the anchor half and n1 beyond the partner half for every rotation', () => {
    for (let rotation = 0; rotation < 4; rotation++) {
      const [dx, dy] = PAIR_DELTA[rotation]!;
      const c = canvas(7, 7).part(3, 3, Sprite.ResLeft, rotation);
      c.cell(3 - dx, 3 - dy, Sprite.Ground, (rotation + 2) & 3); // ground pointing at the component
      c.cell(3 + 2 * dx, 3 + 2 * dy, Sprite.Wire, dx ? 0 : 1); // wire along the component axis
      const r = c.extract();
      expect(r.netlist, `rotation ${rotation}`).toEqual({ frame: 0, nodeCount: 1, elements: [{ idx: 0, kind: 1, n0: FF, n1: 0, valueBcd: 0x100, unit: 0 }] });
      expect(r.issues).toEqual([]);
    }
  });

  it('joins a terminal only to a neighbour whose port faces the component (M3-A002)', () => {
    // R at (1,0)-(2,0); (0,0) horizontal wire faces it, (3,0) vertical wire does not.
    const r = canvas(4, 2).part(1, 0, Sprite.ResLeft).cell(0, 0, Sprite.Wire, 0).cell(3, 0, Sprite.Wire, 1).extract();
    expect(r.netlist.elements[0]).toMatchObject({ n0: 0, n1: FF });
    expect(r.issues).toContainEqual({ type: 'floating-terminal', idx: 0, terminal: 1, col: 3, row: 0 });
    expect(r.netlist.nodeCount).toBe(1);
    // The DSL compatibility mode reads the neighbour's region regardless.
    expect(canvas(4, 2).part(1, 0, Sprite.ResLeft).cell(0, 0, Sprite.Wire, 0).cell(3, 0, Sprite.Wire, 1)
      .extract({ dslCompat: true }).netlist.elements[0]).toMatchObject({ n0: 0, n1: 1 });
  });

  it('treats terminals off the grid as floating, without wrapping to the opposite edge', () => {
    // R at (0,1) rotation 0: n0 would be (-1,1). Column 3 holds wires facing
    // left that a wrapped index would read: (3,0) region 1 -> row 0, and
    // (2,1)-(3,1) region 2 -> row 1, which is n1.
    const r = canvas(4, 3).part(0, 1, Sprite.ResLeft).cell(3, 0, Sprite.Wire).cell(3, 1, Sprite.Wire).cell(2, 1, Sprite.Wire).extract();
    expect(r.netlist.elements[0]).toMatchObject({ n0: FF, n1: 1 });
    expect(r.issues).toEqual([
      { type: 'floating-terminal', idx: 0, terminal: 0, col: -1, row: 1 },
      { type: 'no-ground' },
      { type: 'empty-row', row: 0 },
    ]);
  });

  it('keeps elements whose terminals share a node, and reports them', () => {
    // R at (1,1)-(2,1); both terminals on one wire loop over the top.
    const c = canvas(4, 2).part(1, 1, Sprite.ResLeft)
      // elbow masks: r0 right+up, r1 down+right, r2 down+left, r3 up+left
      .cell(0, 1, Sprite.Elbow, 0).cell(0, 0, Sprite.Elbow, 1).cell(1, 0, Sprite.Wire).cell(2, 0, Sprite.Wire)
      .cell(3, 0, Sprite.Elbow, 2).cell(3, 1, Sprite.Elbow, 3);
    const r = c.extract();
    expect(r.regionCount).toBe(1);
    expect(r.netlist.elements[0]).toMatchObject({ n0: 0, n1: 0 });
    expect(r.issues).toContainEqual({ type: 'shorted-element', idx: 0, node: 0 });
  });

  it('grounds a region only through a ground cell that belongs to it (M3-A003)', () => {
    // Ground at (0,0) points right at a vertical wire (1,0): not reciprocal, so not grounded.
    // Tee r1 at (1,1) (down, right, up) joins (1,0) and faces R (2,1)-(3,1), whose n1 is off the grid.
    const base = () => canvas(4, 3).cell(0, 0, Sprite.Ground, 2).cell(1, 0, Sprite.Wire, 1).cell(1, 1, Sprite.Tee, 1)
      .part(2, 1, Sprite.ResLeft, 0);
    const r = base().extract();
    expect(r.groundRegions).toEqual([1]);
    expect(r.netlist.elements[0]).toMatchObject({ n0: 0, n1: FF });
    expect(r.issues).toContainEqual({ type: 'no-ground' });
    // The DSL grounds the region the ground points at.
    expect(base().extract({ dslCompat: true }).netlist.elements[0]).toMatchObject({ n0: FF });
  });

  it('grounds a terminal through a ground cell facing the component directly', () => {
    const r = canvas(3, 1).cell(0, 0, Sprite.Ground, 2).part(1, 0, Sprite.ResLeft).extract();
    expect(r.netlist.elements[0]).toMatchObject({ n0: FF, n1: FF });
    expect(r.issues.map((i) => i.type)).toEqual(['floating-terminal', 'shorted-element']);
    // DSL: the ground's pointed-at cell is the component half (no region), so its own region is a row.
    expect(canvas(3, 1).cell(0, 0, Sprite.Ground, 2).part(1, 0, Sprite.ResLeft).extract({ dslCompat: true })
      .netlist.elements[0]).toMatchObject({ n0: 0 });
  });

  it('numbers every non-ground region row-major, and sizes node_count by the rows used (M3-A004, M3-A005)', () => {
    // Regions: 1 isolated wire (0,0), 2 isolated junction (3,0), 3 grounded rail from
    // (5,0) down to (4,2), 4 wire (1,2) at R's n0, 5 isolated wire (0,3) after it.
    const c = canvas(6, 4).cell(0, 0, Sprite.Wire, 1).cell(3, 0, Sprite.Junction)
      .cell(5, 0, Sprite.Ground, 3).cell(5, 1, Sprite.Wire, 1).cell(5, 2, Sprite.Elbow, 3)
      .cell(1, 2, Sprite.Wire).part(2, 2, Sprite.ResLeft).cell(4, 2, Sprite.Wire)
      .cell(0, 3, Sprite.Wire, 1);
    const r = c.extract();
    expect(r.groundRegions).toEqual([3]);
    expect(r.rowOfRegion).toEqual({ 1: 0, 2: 1, 4: 2, 5: 3 });
    expect(r.netlist.elements[0]).toMatchObject({ n0: 2, n1: FF });
    expect(r.netlist.nodeCount).toBe(3);
    expect(r.issues).toEqual([{ type: 'empty-row', row: 0 }, { type: 'empty-row', row: 1 }]);
  });

  it('orders elements by anchor address, not by store slot or partner cell (M3-A006)', () => {
    const c = canvas(6, 3)
      .part(4, 2, Sprite.ResLeft, 0, 0x001, 0, 0)
      .part(3, 0, Sprite.CapLeft, 2, 0x002, 0, 1) // partner (2,0) precedes the anchor (3,0)
      .part(1, 1, Sprite.VoltLeft, 3, 0x003, 0, 2); // partner (1,0) is in row 0
    const r = c.extract();
    expect(r.netlist.elements.map((e) => [e.idx, e.valueBcd])).toEqual([[0, 0x002], [1, 0x003], [2, 0x001]]);
    expect(r.elements.map((e) => e.slot)).toEqual([1, 2, 0]);
  });

  it('rejects snapshots with a unit that has no protocol code (pico) with ER 82', () => {
    const r = canvas(6, 1).part(0, 0, Sprite.ResLeft).part(3, 0, Sprite.CapLeft, 0, 0x047, Unit.Pico).extract({ frame: 7 });
    expect(r.netlist.elements[1]!.unit).toBe(UNIT_UNSUPPORTED);
    expect(r.rejection).toMatchObject({ code: FRONTEND_ERROR_UNSUPPORTED_UNIT, arg: 0x0601 });
    expect(snapshotUart(r)).toBe('@ER,0007,82,0601*31\r\n');
  });

  it('can reject kinds the frontend does not send (ER 81), off by default (M3-A010)', () => {
    const c = canvas(6, 1).part(0, 0, Sprite.ResLeft).part(3, 0, Sprite.IndLeft);
    expect(c.extract().rejection).toBeNull();
    const r = c.extract({ supportedKinds: new Set([ElementKind.Resistor, ElementKind.CurrentDc, ElementKind.VoltageDc]) });
    expect(r.rejection).toMatchObject({ code: FRONTEND_ERROR_UNSUPPORTED_KIND, arg: 1 });
  });

  it('rejects more non-ground rows than the 8-bit protocol carries (M3-A011)', () => {
    // Checkerboard of horizontal/vertical wires: no two neighbours are reciprocal,
    // so every cell is its own region; a resistor near the end lands on row > 0xFE.
    const c = canvas(GRID_W, GRID_H);
    for (let row = 0; row < GRID_H; row++) for (let col = 0; col < GRID_W; col++) c.cell(col, row, Sprite.Wire, (row + col) & 1);
    c.part(14, 15, Sprite.ResLeft); // terminals (13,15) and (16,15) are horizontal wires (row+col even)
    const r = c.extract();
    expect(r.regionCount).toBe(GRID_W * GRID_H - 2);
    expect(r.netlist.nodeCount).toBe(284);
    expect(r.rejection).toMatchObject({ code: FRONTEND_ERROR_NODE_OVERFLOW, arg: 284 });
    expect(snapshotUart(r)).toMatch(/^@ER,0000,84,011C\*[0-9A-F]{2}\r\n$/);
  });

  it('extracts an empty canvas as an empty snapshot', () => {
    const r = extractNetlist(initialState({ bootCircuit: false }));
    expect(r.netlist).toEqual({ frame: 0, nodeCount: 0, elements: [] });
    expect(r.issues).toEqual([]);
    expect(snapshotUart(r)).toBe('@NB,0000,00,00*20\r\n@NE,0000,00,00*27\r\n');
  });

  it('describes netlist differences field by field', () => {
    const a = extractNetlist(initialState()).netlist;
    const b: Netlist = { ...a, frame: 9, elements: a.elements.map((e, i) => (i === 1 ? { ...e, n1: 1 } : e)) };
    expect(diffNetlist(a, b)).toEqual(['frame 9, expected 0', 'element 1 n1 01, expected 00']);
    expect(diffNetlist(a, b, { ignoreFrame: true })).toEqual(['element 1 n1 01, expected 00']);
    expect(diffNetlist(a, { ...a, nodeCount: 2, elements: a.elements.slice(0, 2) })).toEqual([
      'node_count 2, expected 1', 'elem_count 2, expected 3', 'element 2 missing',
    ]);
  });
});

describe('scenario netlists (m2_node_colours)', () => {
  const sc = expandScenario(JSON.parse(readFileSync('scenarios/m2_node_colours.json', 'utf8')) as Scenario);
  const refs = netlistReferences(sc);
  const at = (label: string) => refs.find((r) => r.label === label)!.result;

  it('follows the connectivity edits at each checkpoint', () => {
    expect(refs.map((r) => r.label)).toEqual(sc.checkpoints.map((c) => c.label));
    expect(at('boot').netlist.elements.map((e) => [e.n0, e.n1])).toEqual([[FF, 0], [FF, 0], [FF, 0]]);
    expect(at('boot').netlist.frame).toBe(sc.checkpoints[0]!.frame);
    expect(at('right_rail_split').netlist.elements.map((e) => [e.n0, e.n1])).toEqual([[FF, 0], [FF, 0], [FF, 1]]);
    expect(at('rotated_wire_rejoins').netlist.nodeCount).toBe(1);
    expect(at('ground_removed').netlist.elements.map((e) => [e.n0, e.n1])).toEqual([[0, 1], [0, 1], [0, 1]]);
    expect(at('ground_removed').issues).toEqual([{ type: 'no-ground' }]);
    expect(at('ground_rotated_joins').netlist.elements.map((e) => e.n0)).toEqual([FF, FF, FF]);
    expect(at('lower_resistor_removed').netlist.elements.map((e) => e.kind)).toEqual([3, 1]);
    expect(at('rails_shorted').netlist).toMatchObject({ nodeCount: 0, elements: [{ n0: FF, n1: FF }, { n0: FF, n1: FF }] });
  });

  it('writes netlist references and decodes them back', () => {
    const dir = mkdtempSync(join(tmpdir(), 'm3-netlist-'));
    try {
      const points = parseFrameList('2, 38');
      expect(points).toEqual([{ label: 'frame_0002', frame: 2 }, { label: 'frame_0038', frame: 38 }]);
      writeNetlistReferences(sc, dir, netlistReferences(sc, undefined, points));
      const index = JSON.parse(readFileSync(join(dir, 'netlists.json'), 'utf8'));
      expect(index.netlists.map((n: { uart: string; issues: string[] }) => [n.uart, n.issues]))
        .toEqual([['00_frame_0002.netlist.uart', []], ['01_frame_0038.netlist.uart', ['no-ground']]]);
      const json = JSON.parse(readFileSync(join(dir, '01_frame_0038.netlist.json'), 'utf8'));
      expect(json.netlist).toEqual(at('ground_removed').netlist);
      const decoded = decodeUartCapture(join(dir, '01_frame_0038.netlist.uart')) as { netlists: Netlist[]; problems: string[] };
      expect(decoded).toMatchObject({ netlists: [at('ground_removed').netlist], problems: [] });
      writeFileSync(join(dir, 'cap.txt'), '@VB,0001,01,00*38\r\n@VN,0001,00,40A00000*40\r\n@VE,0001,01,00*3F\r\n');
      expect(decodeUartCapture(join(dir, 'cap.txt'))).toMatchObject({ voltages: [{ frame: 1, status: 0, voltages: [5], bits: ['40A00000'] }] });
      expect(() => parseFrameList('3,x')).toThrow(/invalid frame/);
      expect(() => netlistReferences(sc, undefined, [{ label: 'late', frame: sc.frames.length }])).toThrow(/outside/);
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
});
