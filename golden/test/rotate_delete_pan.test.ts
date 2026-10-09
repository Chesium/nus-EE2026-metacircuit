import { describe, expect, it } from 'vitest';
import {
  COMPONENT_INDEX_INVALID, PAN_MIN_Y, Sprite, Tool, cellAddr, clearCanvas, decodeCell, initialState, makeConfig, screenToCell,
} from '../src/core/index.ts';
import { DEFAULT_CONFIG } from '../src/core/config.ts';
import { expandScenario } from '../src/scenario/expand.ts';
import { drive, empty, trace } from './helpers.ts';

type S = ReturnType<typeof initialState>;
const cellAt = (s: S, col: number, row: number) => decodeCell(s.cells[cellAddr(col, row)]!);
const live = (s: S) => s.components.filter(Boolean).length;

describe('rotate', () => {
  it('rotates a wire-family cell by one step per click, wrapping after 3', () => {
    let s = drive(['click_tool wire', 'click_tool wire', 'click_tool wire', 'click_cell 2 2', 'click_tool rotate']);
    const rots: number[] = [];
    for (let i = 0; i < 4; i++) {
      s = drive(['click_cell 2 2'], s);
      rots.push(cellAt(s, 2, 2).rotation);
    }
    expect(rots).toEqual([1, 2, 3, 0]);
    expect(cellAt(s, 2, 2).sprite).toBe(Sprite.Elbow);
  });

  it('does nothing on an empty cell', () => {
    const s = drive(['click_tool rotate', 'click_cell 2 2']);
    expect(s.cells.every((w) => w === 0)).toBe(true);
  });

  it('rotates a component about its anchor, also when its right half is clicked', () => {
    let s = drive(['click_tool resistor', 'click_cell 5 5', 'click_tool rotate', 'click_cell 6 5']);
    expect(s.components[0]).toMatchObject({ col: 5, row: 5, rotation: 1 });
    expect(cellAt(s, 5, 5)).toMatchObject({ sprite: Sprite.ResLeft, rotation: 1 });
    expect(cellAt(s, 5, 6)).toMatchObject({ sprite: Sprite.ResRight, rotation: 1 });
    expect(cellAt(s, 6, 5).enabled).toBe(false);
    expect(s.componentIndexMap[cellAddr(6, 5)]).toBe(COMPONENT_INDEX_INVALID);
    expect(s.componentIndexMap[cellAddr(5, 6)]).toBe(0);
    s = drive(['click_cell 5 6'], s); // rot 2: right half at column - 1
    expect(cellAt(s, 4, 5)).toMatchObject({ sprite: Sprite.ResRight, rotation: 2 });
    s = drive(['click_cell 5 5'], s); // rot 3: right half at row - 1
    expect(cellAt(s, 5, 4)).toMatchObject({ sprite: Sprite.ResRight, rotation: 3 });
    s = drive(['click_cell 5 5'], s); // back to rot 0
    expect(cellAt(s, 6, 5)).toMatchObject({ sprite: Sprite.ResRight, rotation: 0 });
    expect(s.cells.filter((w) => w !== 0)).toHaveLength(2);
  });

  it('is blocked when the new right-half cell is occupied or off the grid', () => {
    let s = drive(['click_tool resistor', 'click_cell 5 5', 'click_tool wire', 'click_cell 5 6', 'click_tool rotate', 'click_cell 5 5']);
    expect(s.components[0]!.rotation).toBe(0);
    s = drive(['drag screen 300 340 to 300 40 over 10', 'assume_pan 0 -224', 'click_tool resistor', 'click_cell 3 15', 'click_tool rotate', 'click_cell 3 15']);
    expect(s.components[0]).toMatchObject({ col: 3, row: 15 });
    expect(s.components[0]!.rotation).toBe(0); // row 16 does not exist
  });

  it('repeats every rotateFramesPerStep frames while held', () => {
    // Hold for 20 frames on a wire: steps on press frame, +8, +16.
    const states = trace(['click_tool wire', 'click_cell 2 2', 'click_tool rotate', 'move 144 144', 'wait 1', 'down', 'wait 20', 'up', 'wait 1']);
    const rot = states.map((s) => cellAt(s, 2, 2).rotation);
    const press = states.findIndex((s, i) => i > 0 && s.prevMouse.left && !states[i - 1]!.prevMouse.left && s.prevMouse.x === 144 && s.tool === Tool.Rotate);
    expect(rot[press]).toBe(1);
    expect(rot[press + 7]).toBe(1);
    expect(rot[press + 8]).toBe(2);
    expect(rot[press + 16]).toBe(3);
    expect(rot.at(-1)).toBe(3);
  });

  it('honours a configured period', () => {
    const s = drive(['click_tool wire', 'click_cell 2 2', 'click_tool rotate', 'move 144 144', 'wait 1', 'down', 'wait 6', 'up', 'wait 1'], empty(), makeConfig({ rotateFramesPerStep: 3 }));
    expect(cellAt(s, 2, 2).rotation).toBe(2); // press, +3 (frame 6 of the hold is press+5)
  });
});

describe('delete', () => {
  it('deletes a single cell', () => {
    const s = drive(['click_tool ground', 'click_cell 1 1', 'click_tool delete', 'click_cell 1 1']);
    expect(s.cells.every((w) => w === 0)).toBe(true);
  });

  it('deletes the whole component from either half and frees its slot', () => {
    let s = drive(['click_tool capacitor', 'click_cell 2 2', 'click_cell 2 4', 'click_tool delete', 'click_cell 3 2']);
    expect(s.components[0]).toBeNull();
    expect(s.components[1]).toMatchObject({ row: 4 });
    expect(cellAt(s, 2, 2).enabled).toBe(false);
    expect(cellAt(s, 3, 2).enabled).toBe(false);
    expect(s.componentIndexMap[cellAddr(2, 2)]).toBe(COMPONENT_INDEX_INVALID);
    // Next placement reuses the smallest free slot.
    s = drive(['click_tool voltage', 'click_cell 8 8'], s);
    expect(s.components[0]).toMatchObject({ leftSprite: Sprite.VoltLeft, col: 8, row: 8 });
  });

  it('erases while held', () => {
    let s = drive(['click_tool wire', 'drag cell 1 1 to 8 1 over 8', 'click_tool resistor', 'click_cell 3 2']);
    s = drive(['click_tool delete', 'drag cell 2 1 to 3 2 over 4'], s);
    expect(cellAt(s, 1, 1).enabled).toBe(true);
    expect(cellAt(s, 2, 1).enabled).toBe(false);
    expect(live(s)).toBe(0);
    expect(drive(['click_tool delete', 'drag cell 4 1 to 6 1 over 4'], s, makeConfig({ deleteWhileHeld: false })).cells[cellAddr(5, 1)]).not.toBe(0);
  });

  it('clearCanvas empties both stores but keeps tool and pan', () => {
    const s = clearCanvas(drive(['click_tool resistor', 'click_cell 1 1', 'click_tool wire', 'click_cell 5 5']));
    expect(s.cells.every((w) => w === 0)).toBe(true);
    expect(live(s)).toBe(0);
    expect(s.tool).toBe(Tool.Wire);
  });
});

describe('pan', () => {
  it('moves the grid with the mouse while dragging with the pan tool', () => {
    const s = drive(['drag screen 300 250 to 300 150 over 10']);
    expect([s.panX, s.panY]).toEqual([0, -100]);
  });

  it('clamps to [-224, 0] vertically and 0 horizontally', () => {
    let s = drive(['drag screen 300 340 to 100 70 over 12']);
    expect([s.panX, s.panY]).toEqual([0, -224]);
    expect(PAN_MIN_Y).toBe(-224);
    s = drive(['drag screen 300 70 to 600 340 over 12'], s);
    expect([s.panX, s.panY]).toEqual([0, 0]);
  });

  it('keeps panning when the drag leaves the canvas, and ignores drags that start outside it', () => {
    expect(drive(['drag screen 300 340 to 300 40 over 10']).panY).toBe(-224);
    expect(drive(['drag screen 300 20 to 300 300 over 10']).panY).toBe(0);
    expect(drive(['drag screen 300 450 to 300 100 over 10']).panY).toBe(0);
  });

  it('does not pan with other tools', () => {
    expect(drive(['click_tool rotate', 'drag screen 300 300 to 300 100 over 10']).panY).toBe(0);
  });

  it('maps screen points to cells through the pan offset', () => {
    expect(screenToCell(64, 64, 0, 0)).toEqual({ col: 0, row: 0 });
    expect(screenToCell(639, 351, 0, 0)).toEqual({ col: 17, row: 8 });
    expect(screenToCell(64, 64, 0, -224)).toEqual({ col: 0, row: 7 });
    expect(screenToCell(63, 100, 0, 0)).toBeNull();
    expect(screenToCell(100, 352, 0, 0)).toBeNull();
    const s = drive(['drag screen 300 340 to 300 40 over 10', 'click_tool ground', 'assume_pan 0 -224', 'click_cell 4 15']);
    expect(cellAt(s, 4, 15).sprite).toBe(Sprite.Ground);
  });
});

describe('latency', () => {
  it('delays the effect of input by inputLatencyFrames', () => {
    const steps = ['click_tool ground', 'click_cell 2 2', 'wait 4'];
    const s0 = trace(steps, makeConfig({ inputLatencyFrames: 0 }));
    const s2 = trace(steps, makeConfig({ inputLatencyFrames: 2 }));
    const first = (ss: S[]) => ss.findIndex((s) => s.cells[cellAddr(2, 2)] !== 0);
    expect(first(s2) - first(s0)).toBe(2);
  });

  it('defaults to the measured 1 frame: a press during frame N shows in frame N+1', () => {
    expect(DEFAULT_CONFIG.inputLatencyFrames).toBe(1);
    const sc = expandScenario({ name: 't', steps: ['click_tool ground', 'click_cell 2 2', 'wait 2'] });
    const pressFrame = sc.frames.findIndex((f, i) => f.left && f.x === 144 && !sc.frames[i - 1]!.left);
    const states = trace(['click_tool ground', 'click_cell 2 2', 'wait 2']);
    expect(states[pressFrame]!.cells[cellAddr(2, 2)]).toBe(0);
    expect(states[pressFrame + 1]!.cells[cellAddr(2, 2)]).not.toBe(0);
  });
});
