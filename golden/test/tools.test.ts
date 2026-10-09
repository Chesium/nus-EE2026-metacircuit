import { describe, expect, it } from 'vitest';
import { COMPONENT_INDEX_INVALID, Sprite, Tool, buttonRect, cellAddr, decodeCell, initialState, makeConfig } from '../src/core/index.ts';
import { drive, empty } from './helpers.ts';

const cellAt = (s: ReturnType<typeof initialState>, col: number, row: number) => decodeCell(s.cells[cellAddr(col, row)]!);

describe('toolbar', () => {
  it('boots with the pan tool and plain wire variant', () => {
    const s = empty();
    expect(s.tool).toBe(Tool.Pan);
    expect(s.wireVariant).toBe(0);
  });

  it('selects each tool by clicking its button', () => {
    const names = ['pan', 'wire', 'resistor', 'inductor', 'capacitor', 'voltage', 'current', 'ground', 'rotate', 'delete'];
    names.forEach((n, i) => {
      if (n === 'pan') return;
      expect(drive([`click_tool ${n}`]).tool).toBe(i);
    });
    expect(drive(['click_tool resistor', 'click_tool pan']).tool).toBe(Tool.Pan);
  });

  it('selects on the press edge, with the button rectangle edges exclusive at the far side', () => {
    const r = buttonRect(Tool.Delete);
    expect(drive([`click ${r.x0} ${r.y0}`]).tool).toBe(Tool.Delete);
    expect(drive([`click ${r.x1 - 1} ${r.y1 - 1}`]).tool).toBe(Tool.Delete);
    expect(drive([`click ${r.x1} ${r.y0}`]).tool).toBe(Tool.Pan);
    expect(drive([`click ${r.x0} ${r.y1}`]).tool).toBe(Tool.Pan); // gap between buttons
    // Holding the button and sliding onto another button does not select it.
    const r2 = buttonRect(Tool.Resistor);
    expect(drive([`move ${r.x0 + 2} ${r.y0 + 2}`, 'wait 1', 'down', 'wait 1', `move ${r2.x0 + 2} ${r2.y0 + 2}`, 'wait 2', 'up', 'wait 1']).tool).toBe(Tool.Delete);
  });

  it('cycles wire -> junction -> elbow -> tee -> wire when the selected wire button is clicked again', () => {
    expect(drive(['click_tool wire']).wireVariant).toBe(0);
    expect(drive(['click_tool wire', 'click_tool wire']).wireVariant).toBe(1);
    expect(drive(['click_tool wire', 'click_tool wire', 'click_tool wire']).wireVariant).toBe(2);
    expect(drive(Array(4).fill('click_tool wire')).wireVariant).toBe(3);
    expect(drive(Array(5).fill('click_tool wire')).wireVariant).toBe(0);
  });

  it('keeps the wire variant while another tool is selected', () => {
    const s = drive(['click_tool wire', 'click_tool wire', 'click_tool resistor', 'click_tool wire']);
    expect(s.tool).toBe(Tool.Wire);
    expect(s.wireVariant).toBe(1);
  });
});

describe('single-cell tools', () => {
  const variants: [number, Sprite][] = [[1, Sprite.Wire], [2, Sprite.Junction], [3, Sprite.Elbow], [4, Sprite.Tee]];
  for (const [clicks, sprite] of variants) {
    it(`places sprite ${sprite} after ${clicks} wire-button click(s)`, () => {
      const s = drive([...Array(clicks).fill('click_tool wire'), 'click_cell 2 3']);
      expect(cellAt(s, 2, 3)).toEqual({ enabled: true, sprite, rotation: 0, meta: 0 });
      expect(s.componentIndexMap[cellAddr(2, 3)]).toBe(COMPONENT_INDEX_INVALID);
    });
  }

  it('places ground', () => {
    const s = drive(['click_tool ground', 'click_cell 0 0']);
    expect(cellAt(s, 0, 0)).toEqual({ enabled: true, sprite: Sprite.Ground, rotation: 0, meta: 0 });
  });

  it('paints every cell crossed while the button is held', () => {
    const s = drive(['click_tool wire', 'drag cell 1 2 to 6 2 over 10']);
    for (let c = 1; c <= 6; c++) expect(cellAt(s, c, 2).sprite).toBe(Sprite.Wire);
    expect(cellAt(s, 0, 2).enabled).toBe(false);
    expect(cellAt(s, 7, 2).enabled).toBe(false);
  });

  it('places only on the press when painting is disabled', () => {
    const s = drive(['click_tool wire', 'drag cell 1 2 to 6 2 over 10'], empty(), makeConfig({ singleCellPaintWhileHeld: false }));
    expect(cellAt(s, 1, 2).enabled).toBe(true);
    expect(cellAt(s, 2, 2).enabled).toBe(false);
  });

  it('overwrites a different wire sprite but keeps the rotation of an identical one', () => {
    let s = drive(['click_tool wire', 'click_cell 3 3', 'click_tool rotate', 'click_cell 3 3']);
    expect(cellAt(s, 3, 3).rotation).toBe(1);
    s = drive(['click_tool wire', 'click_cell 3 3'], s);
    expect(cellAt(s, 3, 3)).toMatchObject({ sprite: Sprite.Wire, rotation: 1 });
    s = drive(['click_tool ground', 'click_cell 3 3'], s);
    expect(cellAt(s, 3, 3)).toMatchObject({ sprite: Sprite.Ground, rotation: 0 });
  });

  it('never overwrites a component cell', () => {
    const s = drive(['click_tool resistor', 'click_cell 3 3', 'click_tool wire', 'click_cell 4 3']);
    expect(cellAt(s, 4, 3).sprite).toBe(Sprite.ResRight);
  });

  it('does nothing for a press that starts outside the canvas and drags in', () => {
    const s = drive(['click_tool wire', 'move 30 30', 'wait 1', 'down', 'wait 1', 'move 200 200', 'wait 3', 'up', 'wait 1']);
    expect(s.cells.every((w) => w === 0)).toBe(true);
  });

  it('ignores the middle and right buttons', () => {
    const s = drive(['click_tool wire', { op: 'click_cell', cell: [2, 2], button: 'right' }, { op: 'click_cell', cell: [3, 2], button: 'middle' }]);
    expect(s.cells.every((w) => w === 0)).toBe(true);
  });
});

describe('two-cell components', () => {
  const tools: [string, Sprite][] = [
    ['resistor', Sprite.ResLeft], ['inductor', Sprite.IndLeft], ['capacitor', Sprite.CapLeft],
    ['voltage', Sprite.VoltLeft], ['current', Sprite.CurrLeft],
  ];
  for (const [name, left] of tools) {
    it(`places a ${name} at rotation 0 with its right half at column + 1`, () => {
      const s = drive([`click_tool ${name}`, 'click_cell 5 4']);
      expect(cellAt(s, 5, 4)).toEqual({ enabled: true, sprite: left, rotation: 0, meta: 0 });
      expect(cellAt(s, 6, 4)).toEqual({ enabled: true, sprite: left + 1, rotation: 0, meta: 0 });
      expect(s.componentIndexMap[cellAddr(5, 4)]).toBe(0);
      expect(s.componentIndexMap[cellAddr(6, 4)]).toBe(0);
      expect(s.components[0]).toEqual({ leftSprite: left, col: 5, row: 4, rotation: 0, valueBcd: 0, unit: 0 });
    });
  }

  it('places once per press, not while held', () => {
    const s = drive(['click_tool resistor', 'drag cell 1 1 to 9 1 over 16']);
    expect(s.components.filter(Boolean)).toHaveLength(1);
  });

  it('assigns increasing slots', () => {
    const s = drive(['click_tool resistor', 'click_cell 1 1', 'click_cell 1 2', 'click_tool voltage', 'click_cell 1 3']);
    expect(s.components.slice(0, 3).map((c) => c && [c.leftSprite, c.row])).toEqual([[5, 1], [5, 2], [7, 3]]);
  });

  it('is blocked when either target cell is occupied or the right half leaves the grid', () => {
    let s = drive(['click_tool wire', 'click_cell 4 2', 'click_tool resistor', 'click_cell 3 2', 'click_cell 4 2']);
    expect(s.components.filter(Boolean)).toHaveLength(0);
    s = drive(['click_tool resistor', 'click_cell 17 0']);
    expect(s.components.filter(Boolean)).toHaveLength(0);
    s = drive(['click_tool resistor', 'click_cell 16 0']);
    expect(s.components[0]).toMatchObject({ col: 16, row: 0 });
  });
});
