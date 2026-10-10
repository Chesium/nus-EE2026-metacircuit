import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import {
  ALL_ELEMENT_KINDS, FRONTEND_ERROR_NODE_OVERFLOW, FRONTEND_ERROR_UNSUPPORTED_KIND, FRONTEND_ERROR_UNSUPPORTED_UNIT,
  FRONTEND_SUPPORTED_KINDS, UNIT_UNSUPPORTED,
  diffNetlist, extractFromCanvas, extractNetlist, protocolUnitOf, snapshotUart, type PlacedComponent,
} from '../src/backend/netlist.ts';
import {
  FIRST_SNAPSHOT_ID, NETLIST_SNAPSHOT_STATE_LAG_FRAMES, SnapshotIdTracker, netlistContentKey,
} from '../src/backend/snapshot.ts';
import { ElementKind, GROUND_NODE, type Netlist } from '../src/backend/types.ts';
import { decodeUartCapture, netlistReferences, parseFrameList, writeNetlistReferences } from '../src/cli/netlist.ts';
import { makeCell } from '../src/core/encoding.ts';
import { GRID_H, GRID_W, PAIR_DELTA, Sprite, Unit } from '../src/core/constants.ts';
import { cloneState, initialState } from '../src/core/state.ts';
import { step } from '../src/core/step.ts';
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
  // Boot canvas (IF-026, D-015): left rail column 2 rows 2..7 with ground at
  // (2,7); right rail column 5 rows 2..6. V source anchor (4,2) rotation 2,
  // partner (3,2), value 010; resistors (3,4)-(4,4) and (3,6)-(4,6) rotation 0,
  // value 100; unit none. Raw regions: left rail 1 (first at (2,2)), right rail
  // 2 (first at (5,2)). Region 1 holds the ground -> FF; region 2 -> row 0.
  // Anchors in row-major order give idx 0 = V (address 40), 1 = upper R, 2 =
  // lower R. V's n0 (beyond the anchor, the + half) is the right rail; the
  // resistors' n0 is the left rail.
  const expected: Netlist = {
    frame: 0,
    nodeCount: 1,
    elements: [
      { idx: 0, kind: ElementKind.VoltageDc, n0: 0, n1: FF, valueBcd: 0x010, unit: 0x00 },
      { idx: 1, kind: ElementKind.Resistor, n0: FF, n1: 0, valueBcd: 0x100, unit: 0x00 },
      { idx: 2, kind: ElementKind.Resistor, n0: FF, n1: 0, valueBcd: 0x100, unit: 0x00 },
    ],
  };
  const uart = [
    '@NB,0000,03,01*22',
    '@NC,0000,00,03,00,FF,010,00*13',
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
      [{ col: 5, row: 2 }, { col: 2, row: 2 }],
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

  it("puts a current source's n0 at the arrow's tail, beyond the partner half, for every rotation (D-015)", () => {
    for (let rotation = 0; rotation < 4; rotation++) {
      const [dx, dy] = PAIR_DELTA[rotation]!;
      const c = canvas(7, 7).part(3, 3, Sprite.CurrLeft, rotation);
      c.cell(3 - dx, 3 - dy, Sprite.Ground, (rotation + 2) & 3); // ground beyond the anchor half (the arrow's head)
      c.cell(3 + 2 * dx, 3 + 2 * dy, Sprite.Wire, dx ? 0 : 1); // wire beyond the partner half (the tail)
      const r = c.extract();
      expect(r.netlist.elements[0], `rotation ${rotation}`).toMatchObject({ kind: ElementKind.CurrentDc, n0: 0, n1: FF });
      expect(r.elements[0]!.terminals).toEqual([{ col: 3 + 2 * dx, row: 3 + 2 * dy }, { col: 3 - dx, row: 3 - dy }]);
      // The as-written kernel reads n0 beyond the anchor half for every kind.
      expect(c.extract({ dslCompat: true }).elements[0]!.terminals).toEqual([{ col: 3 - dx, row: 3 - dy }, { col: 3 + 2 * dx, row: 3 + 2 * dy }]);
    }
  });

  it('joins a terminal only to a neighbour whose port faces the component (M3-A002)', () => {
    // R at (1,0)-(2,0); (0,0) horizontal wire faces it (region 1, row 0), (3,0)
    // vertical wire does not (region 2, row 1, untouched), so n1 floats and
    // gets its own row 2 after both region rows (D-019).
    const r = canvas(4, 2).part(1, 0, Sprite.ResLeft).cell(0, 0, Sprite.Wire, 0).cell(3, 0, Sprite.Wire, 1).extract();
    expect(r.netlist.elements[0]).toMatchObject({ n0: 0, n1: 2 });
    expect(r.issues).toContainEqual({ type: 'floating-terminal', idx: 0, terminal: 1, col: 3, row: 0, node: 2 });
    expect(r.netlist.nodeCount).toBe(3);
    // The as-written kernel reads the neighbour's region regardless.
    expect(canvas(4, 2).part(1, 0, Sprite.ResLeft).cell(0, 0, Sprite.Wire, 0).cell(3, 0, Sprite.Wire, 1)
      .extract({ dslCompat: true }).netlist.elements[0]).toMatchObject({ n0: 0, n1: 1 });
  });

  it('gives each floating terminal its own row after all region rows, in idx order, n0 before n1 (D-019)', () => {
    // Regions: 1 = wire (0,0) (row 0), 2 = grounded junction pair (2,2)-(3,2).
    // Elements in anchor order: idx 0 R (4,0)-(5,0) both ends open; idx 1 I
    // (0,1) rot 1 (partner (0,2)), n0 beyond the partner = (0,3) open, n1
    // beyond the anchor = (0,0) the wire; idx 2 R (4,2)-(5,2): n0 (3,2) ground, n1 open.
    const c = canvas(7, 4).cell(0, 0, Sprite.Wire, 1).part(4, 0, Sprite.ResLeft)
      .part(0, 1, Sprite.CurrLeft, 1).cell(2, 2, Sprite.Ground, 2).cell(3, 2, Sprite.Junction)
      .part(4, 2, Sprite.ResLeft);
    const r = c.extract();
    expect(r.rowOfRegion).toEqual({ 1: 0 });
    expect(r.netlist.elements.map((e) => [e.idx, e.kind, e.n0, e.n1])).toEqual([
      [0, ElementKind.Resistor, 1, 2], [1, ElementKind.CurrentDc, 3, 0], [2, ElementKind.Resistor, FF, 4],
    ]);
    expect(r.netlist.nodeCount).toBe(5);
    expect(r.issues.filter((i) => i.type === 'floating-terminal').map((i) => i.type === 'floating-terminal' && [i.idx, i.terminal, i.node]))
      .toEqual([[0, 0, 1], [0, 1, 2], [1, 0, 3], [2, 1, 4]]);
    expect(r.issues.some((i) => i.type === 'empty-row')).toBe(false);
    // A dangling source is now visible to the solver's floating-node check instead of driving ground.
    expect(snapshotUart(r)).toMatch(/^@NB,0000,03,05\*/);
  });

  it('treats terminals off the grid as floating, without wrapping to the opposite edge', () => {
    // R at (0,1) rotation 0: n0 would be (-1,1). Column 3 holds wires facing
    // left that a wrapped index would read: (3,0) region 1 -> row 0, and
    // (2,1)-(3,1) region 2 -> row 1, which is n1. n0 floats: row 2 (D-019).
    const r = canvas(4, 3).part(0, 1, Sprite.ResLeft).cell(3, 0, Sprite.Wire).cell(3, 1, Sprite.Wire).cell(2, 1, Sprite.Wire).extract();
    expect(r.netlist.elements[0]).toMatchObject({ n0: 2, n1: 1 });
    expect(r.netlist.nodeCount).toBe(3);
    expect(r.issues).toEqual([
      { type: 'floating-terminal', idx: 0, terminal: 0, col: -1, row: 1, node: 2 },
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
    expect(r.netlist.elements[0]).toMatchObject({ n0: 0, n1: 1 }); // n1 off the grid: its own row (D-019)
    expect(r.issues).toContainEqual({ type: 'no-ground' });
    // The DSL grounds the region the ground points at.
    expect(base().extract({ dslCompat: true }).netlist.elements[0]).toMatchObject({ n0: FF });
  });

  it('grounds a terminal through a ground cell facing the component directly', () => {
    const r = canvas(3, 1).cell(0, 0, Sprite.Ground, 2).part(1, 0, Sprite.ResLeft).extract();
    expect(r.netlist.elements[0]).toMatchObject({ n0: FF, n1: 0 }); // n1 off the grid: row 0 (D-019)
    expect(r.issues.map((i) => i.type)).toEqual(['floating-terminal']);
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
    const r = canvas(6, 1).part(0, 0, Sprite.ResLeft).part(3, 0, Sprite.ResLeft, 0, 0x047, Unit.Pico).extract({ frame: 7 });
    expect(r.netlist.elements[1]!.unit).toBe(UNIT_UNSUPPORTED);
    expect(r.rejection).toMatchObject({ code: FRONTEND_ERROR_UNSUPPORTED_UNIT, arg: 0x0601 });
    expect(snapshotUart(r)).toBe('@ER,0007,82,0601*31\r\n');
  });

  it('rejects a snapshot with a capacitor or inductor (ER 81, arg idx) by default; sending C/L is an option (D-018)', () => {
    expect([...FRONTEND_SUPPORTED_KINDS]).toEqual([ElementKind.Resistor, ElementKind.CurrentDc, ElementKind.VoltageDc]);
    for (const sprite of [Sprite.IndLeft, Sprite.CapLeft]) {
      const c = canvas(6, 1).part(0, 0, Sprite.ResLeft).part(3, 0, sprite);
      const r = c.extract({ frame: 0x12 });
      expect(r.rejection).toMatchObject({ code: FRONTEND_ERROR_UNSUPPORTED_KIND, arg: 1 });
      expect(r.issues).toContainEqual({ type: 'unsupported-kind', idx: 1, kind: sprite === Sprite.IndLeft ? ElementKind.Inductor : ElementKind.Capacitor });
      expect(snapshotUart(r)).toMatch(/^@ER,0012,81,0001\*[0-9A-F]{2}\r\n$/);
      expect(c.extract({ supportedKinds: ALL_ELEMENT_KINDS }).rejection).toBeNull();
    }
  });

  it('rejects more non-ground rows than the 8-bit protocol carries (M3-A011)', () => {
    // Checkerboard of horizontal/vertical wires: no two neighbours are reciprocal,
    // so every cell is its own region; a resistor near the end lands on row > 0xFE.
    const c = canvas(GRID_W, GRID_H);
    for (let row = 0; row < GRID_H; row++) for (let col = 0; col < GRID_W; col++) c.cell(col, row, Sprite.Wire, (row + col) & 1);
    // n0 (13,15) is a horizontal wire (row+col even) on row 283; n1 (16,15) is a
    // vertical one that does not face the resistor, so it floats and gets row 286
    // after all 286 region rows (D-019).
    c.part(14, 15, Sprite.ResLeft);
    const r = c.extract();
    expect(r.regionCount).toBe(GRID_W * GRID_H - 2);
    expect(r.netlist.elements[0]).toMatchObject({ n0: 283, n1: 286 });
    expect(r.netlist.nodeCount).toBe(287);
    expect(r.rejection).toMatchObject({ code: FRONTEND_ERROR_NODE_OVERFLOW, arg: 287 });
    expect(snapshotUart(r)).toMatch(/^@ER,0000,84,011F\*[0-9A-F]{2}\r\n$/);
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
    expect(at('boot').netlist.elements.map((e) => [e.n0, e.n1])).toEqual([[0, FF], [FF, 0], [FF, 0]]);
    expect(at('right_rail_split').netlist.elements.map((e) => [e.n0, e.n1])).toEqual([[0, FF], [FF, 0], [FF, 1]]);
    expect(at('rotated_wire_rejoins').netlist.nodeCount).toBe(1);
    // Left rail (first at (2,2)) is row 0, right rail row 1.
    expect(at('ground_removed').netlist.elements.map((e) => [e.n0, e.n1])).toEqual([[1, 0], [0, 1], [0, 1]]);
    expect(at('ground_removed').issues).toEqual([{ type: 'no-ground' }]);
    expect(at('ground_rotated_joins').netlist.elements.map((e) => e.n0)).toEqual([0, FF, FF]);
    expect(at('lower_resistor_removed').netlist.elements.map((e) => e.kind)).toEqual([3, 1]);
    expect(at('rails_shorted').netlist).toMatchObject({ nodeCount: 0, elements: [{ n0: FF, n1: FF }, { n0: FF, n1: FF }] });
  });

  it('numbers snapshots from 0001, counting only frames whose canvas content changed (D-016)', () => {
    // Every checkpoint follows exactly one canvas edit; rails_shorted places two wires.
    expect(refs.map((r) => [r.label, r.snapshotId])).toEqual([
      ['boot', 1], ['right_rail_split', 2], ['horizontal_wire_unjoined', 3], ['rotated_wire_rejoins', 4],
      ['ground_removed', 5], ['ground_restored_unjoined', 6], ['ground_rotated_joins', 7],
      ['lower_resistor_removed', 8], ['rails_shorted', 10],
    ]);
    expect(refs.every((r) => r.result.netlist.frame === r.snapshotId)).toBe(true);
    expect(refs.every((r) => r.txFrame === r.frame + NETLIST_SNAPSHOT_STATE_LAG_FRAMES)).toBe(true);
    expect(NETLIST_SNAPSHOT_STATE_LAG_FRAMES).toBe(0);
    expect(refs[0]!.uart.startsWith('@NB,0001,03,01*')).toBe(true);
  });

  it('writes netlist references and decodes them back', () => {
    const dir = mkdtempSync(join(tmpdir(), 'm3-netlist-'));
    try {
      const points = parseFrameList('2, 38');
      expect(points).toEqual([{ label: 'frame_0002', frame: 2 }, { label: 'frame_0038', frame: 38 }]);
      writeNetlistReferences(sc, dir, netlistReferences(sc, undefined, points));
      const index = JSON.parse(readFileSync(join(dir, 'netlists.json'), 'utf8'));
      expect(index.netlists.map((n: { uart: string; issues: string[]; snapshotId: number }) => [n.uart, n.issues, n.snapshotId]))
        .toEqual([['00_frame_0002.netlist.uart', [], 1], ['01_frame_0038.netlist.uart', ['no-ground'], 5]]);
      expect(index.snapshotStateLagFrames).toBe(NETLIST_SNAPSHOT_STATE_LAG_FRAMES);
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

describe('snapshot ids (D-016)', () => {
  const mouse = (x: number, y: number, left = false) => ({ x, y, left, middle: false, right: false });

  it('start at 0001 and change only with netlist-relevant content', () => {
    const ids = new SnapshotIdTracker();
    const s = initialState();
    expect(ids.next(s)).toBe(FIRST_SNAPSHOT_ID);
    expect(ids.next(cloneState(s))).toBe(1); // nothing changed
    const flow = cloneState(s);
    flow.cells[56] = flow.cells[56]! ^ 0x200; // metadata (flow) bit only
    expect(netlistContentKey(flow)).toBe(netlistContentKey(s));
    expect(ids.next(flow)).toBe(1);
    const text = cloneState(s);
    text.components[1] = { ...text.components[1]!, displayText: '1.0' }; // literal text, same BCD
    text.selectedCell = { col: 3, row: 4 };
    expect(ids.next(text)).toBe(1);
    const value = cloneState(s);
    value.components[1] = { ...value.components[1]!, valueBcd: 0x120 };
    expect(ids.next(value)).toBe(2);
    const unit = cloneState(value);
    unit.components[1] = { ...unit.components[1]!, unit: Unit.Kilo };
    expect(ids.next(unit)).toBe(3);
    const reslot = cloneState(unit); // same components in other slots
    [reslot.components[0], reslot.components[5]] = [reslot.components[5]!, reslot.components[0]!];
    expect(ids.next(reslot)).toBe(3);
    const wire = cloneState(reslot);
    wire.cells[0] = makeCell(Sprite.Wire, 0);
    expect(ids.next(wire)).toBe(4);
    expect(ids.current).toBe(4);
  });

  it('follow an edit with the one-frame input latency: the first frame whose state shows it carries a new id', () => {
    // Ground tool, then click (0,0) on the canvas: the press of mouse frame N is in state N+1.
    const ids = new SnapshotIdTracker();
    const frames = [mouse(32, 266), mouse(32, 266, true), mouse(32, 266), mouse(80, 80), mouse(80, 80, true), mouse(80, 80), mouse(80, 80)];
    let s = initialState();
    const seen = frames.map((m) => ids.next((s = step(s, m))));
    expect(seen).toEqual([1, 1, 1, 1, 1, 2, 2]);
  });

  it('wraps at 16 bits', () => {
    const ids = new SnapshotIdTracker();
    let s = initialState();
    ids.next(s);
    for (let k = 1; k < 0x10000; k++) {
      s = cloneState(s);
      s.cells[0] = k & 1 ? makeCell(Sprite.Wire, 0) : 0;
      ids.next(s);
    }
    expect(ids.current).toBe(0x0000);
  });
});
