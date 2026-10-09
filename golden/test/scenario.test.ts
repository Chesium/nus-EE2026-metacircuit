import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { Tool, buttonCenter, cellCenter } from '../src/core/index.ts';
import { ScenarioError, expandScenario, framesToScenario, parseStepString } from '../src/scenario/expand.ts';
import { runScenario } from '../src/scenario/run.ts';
import { compileStim, parseStim } from '../src/scenario/stim.ts';
import type { Scenario } from '../src/scenario/types.ts';

const sc = (steps: Scenario['steps'], extra: Partial<Scenario> = {}): Scenario => ({ name: 't', steps, ...extra });

describe('expander', () => {
  it('applies raw steps at the frame cursor and advances on wait', () => {
    const c = expandScenario(sc(['move 100 200', 'wait 2', 'down', 'wait 1', 'up left', 'down right', 'wait 1']));
    expect(c.frameCount).toBe(4);
    expect(c.frames.map((f) => [f.x, f.y, +f.left, +f.right])).toEqual([
      [100, 200, 0, 0], [100, 200, 0, 0], [100, 200, 1, 0], [100, 200, 0, 1],
    ]);
  });

  it('starts from the framescope default mouse unless initialMouse is given', () => {
    expect(expandScenario(sc(['wait 1'])).frames[0]).toEqual({ x: 320, y: 240, left: false, middle: false, right: false });
    expect(expandScenario(sc(['wait 1'], { initialMouse: { x: 5 } })).frames[0]!.x).toBe(5);
  });

  it('expands click_tool to move / press / release on separate frames', () => {
    const c = expandScenario(sc(['click_tool resistor']));
    const p = buttonCenter(Tool.Resistor);
    expect(c.frames).toEqual([
      { x: p.x, y: p.y, left: false, middle: false, right: false },
      { x: p.x, y: p.y, left: true, middle: false, right: false },
      { x: p.x, y: p.y, left: false, middle: false, right: false },
    ]);
    expect(expandScenario(sc(['click_tool resistor hold 3'])).frameCount).toBe(5);
  });

  it('click_cell targets the cell centre under the assumed pan', () => {
    const a = expandScenario(sc(['click_cell 2 3'])).frames[0]!;
    expect([a.x, a.y]).toEqual([64 + 2 * 32 + 16, 64 + 3 * 32 + 16]);
    const b = expandScenario(sc(['assume_pan 0 -100', 'click_cell 2 5'])).frames[0]!;
    const e = cellCenter(2, 5, 0, -100);
    expect([b.x, b.y]).toEqual([e.x, e.y]);
    const d = expandScenario(sc([{ op: 'click_cell', screen: [10, 11] }])).frames[0]!;
    expect([d.x, d.y]).toEqual([10, 11]);
  });

  it('drag interpolates over n frames between press and release', () => {
    const c = expandScenario(sc(['drag screen 100 100 to 200 300 over 4']));
    expect(c.frameCount).toBe(4 + 3);
    expect(c.frames.map((f) => [f.x, f.y, +f.left])).toEqual([
      [100, 100, 0], [100, 100, 1], [125, 150, 1], [150, 200, 1], [175, 250, 1], [200, 300, 1], [200, 300, 0],
    ]);
  });

  it('checkpoints mark the last stepped frame', () => {
    const c = expandScenario(sc(['wait 3', 'checkpoint a', 'click_tool wire', 'checkpoint b']));
    expect(c.checkpoints).toEqual([{ label: 'a', frame: 2 }, { label: 'b', frame: 5 }]);
  });

  it('rejects bad scenarios', () => {
    expect(() => expandScenario(sc(['checkpoint a']))).toThrow(ScenarioError);
    expect(() => expandScenario(sc(['wait 1', 'move 1 1', 'checkpoint a']))).toThrow(/no wait/);
    expect(() => expandScenario(sc(['wait 1', 'checkpoint a', 'wait 1', 'checkpoint a']))).toThrow(/duplicate/);
    expect(() => expandScenario(sc(['click_tool nonsense']))).toThrow(/unknown tool/);
    expect(() => parseStepString('jump 1 2')).toThrow(/unknown step/);
    expect(() => parseStepString('drag cell 1 2 3 4 over 5')).toThrow(/bad drag/);
    expect(() => expandScenario(sc(['wait -1']))).toThrow();
  });

  it('accepts object and string steps interchangeably', () => {
    const a = expandScenario(sc(['drag cell 1 1 to 3 1 over 2', 'checkpoint x']));
    const b = expandScenario(sc([{ op: 'drag', from: { cell: [1, 1] }, to: { cell: [3, 1] }, frames: 2 }, { op: 'checkpoint', label: 'x' }]));
    expect(b).toEqual(a);
  });

  it('commits trailing input changes as one final frame', () => {
    expect(expandScenario(sc(['wait 1', 'move 5 5'])).frameCount).toBe(2);
  });

  it('turns recorded frames back into an equivalent scenario', () => {
    const c = expandScenario(sc(['click_tool resistor', 'click_cell 3 3', 'checkpoint placed', 'drag screen 300 300 to 300 200 over 5', 'wait 4', 'checkpoint end']));
    const back = expandScenario(framesToScenario('rec', c.frames, c.checkpoints));
    expect(back.frames).toEqual(c.frames);
    expect(back.checkpoints).toEqual(c.checkpoints);
  });
});

describe('stim compiler', () => {
  const c = expandScenario(sc(['click_tool resistor', 'click_cell 3 3', 'checkpoint placed'], { description: 'demo' }));

  it('emits a header comment and one event per frame with changes', () => {
    const toml = compileStim(c);
    expect(toml.startsWith('# Scenario: t\n# demo\n')).toBe(true);
    expect(toml).toContain('# checkpoint placed: golden frame 5, framescope frame 5');
    const p = buttonCenter(Tool.Resistor);
    expect(toml).toContain(`[[event]]\nframe = 0\nline = 10\nset = { "mouse.x" = ${p.x}, "mouse.y" = ${p.y} }`);
    expect(toml).toContain('[[event]]\nframe = 1\nline = 10\nset = { "mouse.left" = 1 }');
    expect(toml).toContain('[[event]]\nframe = 2\nline = 10\nset = { "mouse.left" = 0 }');
    expect(parseStim(toml)).toHaveLength(6);
  });

  it('honours line and frame offset', () => {
    const ev = parseStim(compileStim(c, { line: 3, frameOffset: 2 }));
    expect(ev[0]).toMatchObject({ frame: 2, line: 3 });
  });

  it('reconstructs the canonical frames (round trip)', () => {
    const big = expandScenario(JSON.parse(readFileSync('scenarios/m1_canvas_tools.json', 'utf8')));
    const events = parseStim(compileStim(big));
    let cur = { x: 320, y: 240, left: false, middle: false, right: false };
    const byFrame = new Map(events.map((e) => [e.frame, e.set]));
    for (let f = 0; f < big.frameCount; f++) {
      const set = byFrame.get(f);
      if (set) {
        cur = {
          x: set['mouse.x'] ?? cur.x, y: set['mouse.y'] ?? cur.y,
          left: set['mouse.left'] === undefined ? cur.left : set['mouse.left'] === 1,
          middle: set['mouse.middle'] === undefined ? cur.middle : set['mouse.middle'] === 1,
          right: set['mouse.right'] === undefined ? cur.right : set['mouse.right'] === 1,
        };
      }
      expect(cur).toEqual(big.frames[f]);
    }
  });
});

describe('m1_canvas_tools scenario', () => {
  const scenario = JSON.parse(readFileSync('scenarios/m1_canvas_tools.json', 'utf8')) as Scenario;
  const result = runScenario(expandScenario(scenario));
  const at = (label: string) => result.checkpoints.find((c) => c.label === label)!.semantic;

  it('exercises every canvas tool', () => {
    const sprites = new Set<string>();
    for (const cp of result.checkpoints) for (const c of cp.semantic.cells) sprites.add(c.spriteName);
    for (const s of ['Wire', 'Junction', 'Elbow', 'Tee', 'Ground', 'RL', 'RR', 'LL', 'LR', 'CL', 'CR', 'VL', 'VR', 'IL', 'IR']) {
      expect(sprites).toContain(s);
    }
    const tools = new Set(result.checkpoints.map((c) => c.semantic.tool));
    for (const t of ['wire', 'ground', 'resistor', 'inductor', 'capacitor', 'voltage', 'current', 'rotate', 'delete', 'pan']) {
      expect(tools).toContain(t);
    }
  });

  it('reaches the expected states at key checkpoints', () => {
    expect(at('boot').cells).toHaveLength(17);
    expect(at('boot').components.map((c) => [c.slot, c.kind, c.col, c.row, c.value])).toEqual([
      [0, 'voltage', 3, 2, '010'], [1, 'resistor', 3, 4, '100'], [2, 'resistor', 3, 6, '100'],
    ]);
    expect(at('current').components).toHaveLength(8);
    expect(at('blocked_placements').components).toHaveLength(8);
    expect(at('rotate_component').components.find((c) => c.slot === 3)).toMatchObject({ kind: 'resistor', col: 13, row: 1, rotation: 1 });
    expect(at('rotate_boot').components.find((c) => c.slot === 1)!.rotation).toBe(1);
    expect(at('rotate_boot').cells.find((c) => c.col === 2 && c.row === 2)).toMatchObject({ spriteName: 'Elbow', rotation: 2 });
    expect(at('rotate_hold').components.find((c) => c.slot === 6)).toMatchObject({ kind: 'voltage', col: 10, row: 3, rotation: 3 });
    expect(at('rotate_blocked').components.find((c) => c.slot === 4)).toMatchObject({ kind: 'inductor', rotation: 0 });
    expect(at('delete').components.map((c) => c.kind)).not.toContain('capacitor');
    expect(at('delete').components.map((c) => c.slot)).toEqual([0, 1, 3, 4, 6, 7]);
    expect(at('slot_reuse').components.find((c) => c.slot === 2)).toMatchObject({ kind: 'resistor', col: 13, row: 7 });
    expect(at('pan_partial').pan).toEqual({ x: 0, y: -100 });
    expect(at('pan_clamped').pan).toEqual({ x: 0, y: -224 });
    expect(at('panned_place').cells.find((c) => c.col === 5 && c.row === 12)?.spriteName).toBe('Ground');
    expect(at('pan_back').pan).toEqual({ x: 0, y: 0 });
  });
});
