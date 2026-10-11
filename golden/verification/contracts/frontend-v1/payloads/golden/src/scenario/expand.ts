// Scenario expander: steps and macros -> canonical per-frame mouse snapshots.

import { TOOL_NAMES, Tool } from '../core/constants.ts';
import { buttonCenter, cellCenter } from '../core/geometry.ts';
import { defaultMouse, type MouseSnapshot } from '../core/state.ts';
import type { Button, CanonicalScenario, Checkpoint, Point, Scenario, Step, Target } from './types.ts';

export class ScenarioError extends Error {}

const TOOL_BY_NAME: Record<string, Tool> = Object.fromEntries(
  Object.entries(TOOL_NAMES).map(([idx, name]) => [name, Number(idx) as Tool]),
);
// Friendly aliases.
Object.assign(TOOL_BY_NAME, {
  hand: Tool.Pan, r: Tool.Resistor, l: Tool.Inductor, c: Tool.Capacitor, v: Tool.VoltageSource,
  i: Tool.CurrentSource, gnd: Tool.Ground, 'voltage-source': Tool.VoltageSource,
  'current-source': Tool.CurrentSource, erase: Tool.Delete,
});

export function toolByName(name: string): Tool {
  const t = TOOL_BY_NAME[name.toLowerCase()];
  if (t === undefined) throw new ScenarioError(`unknown tool "${name}" (known: ${Object.values(TOOL_NAMES).join(', ')})`);
  return t;
}

/**
 * Parse a one-line step:
 *   move X Y | down [button] | up [button] | wait N | click X Y [hold N]
 *   click_tool NAME [hold N] | click_cell COL ROW [hold N]
 *   drag cell C1 R1 to C2 R2 over N [button] | drag screen X1 Y1 to X2 Y2 over N [button]
 *   assume_pan X Y | checkpoint LABEL | # comment
 */
export function parseStepString(line: string): Step {
  const t = line.trim();
  if (t.startsWith('#')) return { op: 'comment', text: t.slice(1).trim() };
  const w = t.split(/\s+/);
  const num = (i: number) => {
    const v = Number(w[i]);
    if (w[i] === undefined || !Number.isFinite(v)) throw new ScenarioError(`bad number at word ${i + 1} in "${line}"`);
    return v;
  };
  const opt = (key: string) => {
    const i = w.indexOf(key);
    return i >= 0 ? num(i + 1) : undefined;
  };
  const btn = (i: number): Button | undefined => {
    const b = w[i];
    if (b === undefined) return undefined;
    if (b === 'left' || b === 'middle' || b === 'right') return b;
    throw new ScenarioError(`bad button "${b}" in "${line}"`);
  };
  switch (w[0]) {
    case 'move': return { op: 'move', x: num(1), y: num(2) };
    case 'down': return { op: 'down', button: btn(1) };
    case 'up': return { op: 'up', button: btn(1) };
    case 'wait': return { op: 'wait', frames: num(1) };
    case 'click': return { op: 'click', x: num(1), y: num(2), hold: opt('hold') };
    case 'click_tool': return { op: 'click_tool', tool: w[1] ?? '', hold: opt('hold') };
    case 'click_cell': return { op: 'click_cell', cell: [num(1), num(2)], hold: opt('hold') };
    case 'assume_pan': return { op: 'assume_pan', x: num(1), y: num(2) };
    case 'checkpoint': return { op: 'checkpoint', label: w.slice(1).join(' ') };
    case 'drag': {
      // drag cell|screen a b to c d over n [button]
      const kind = w[1];
      if ((kind !== 'cell' && kind !== 'screen') || w[4] !== 'to' || w[7] !== 'over') {
        throw new ScenarioError(`bad drag syntax "${line}"`);
      }
      const mk = (a: number, b: number): Target => (kind === 'cell' ? { cell: [a, b] } : { screen: [a, b] });
      return { op: 'drag', from: mk(num(2), num(3)), to: mk(num(5), num(6)), frames: num(8), button: btn(9) };
    }
    default:
      throw new ScenarioError(`unknown step "${line}"`);
  }
}

export function normalizeSteps(sc: Scenario): Step[] {
  return sc.steps.map((s) => (typeof s === 'string' ? parseStepString(s) : s));
}

export function expandScenario(sc: Scenario): CanonicalScenario {
  const frames: MouseSnapshot[] = [];
  const checkpoints: Checkpoint[] = [];
  let cur: MouseSnapshot = { ...defaultMouse(), ...(sc.initialMouse ?? {}) };
  let dirty = false;
  let assumedPan: Point = [0, 0];

  const wait = (n: number) => {
    if (!Number.isInteger(n) || n < 0) throw new ScenarioError(`wait needs a non-negative integer, got ${n}`);
    for (let i = 0; i < n; i++) frames.push({ ...cur });
    if (n > 0) dirty = false;
  };
  const move = (x: number, y: number) => {
    cur = { ...cur, x: Math.round(x), y: Math.round(y) };
    dirty = true;
  };
  const setBtn = (b: Button | undefined, v: boolean) => {
    cur = { ...cur, [b ?? 'left']: v };
    dirty = true;
  };
  const resolve = (t: Target): Point => {
    if ('screen' in t) return t.screen;
    const pan = t.pan ?? assumedPan;
    const c = cellCenter(t.cell[0], t.cell[1], pan[0], pan[1]);
    return [c.x, c.y];
  };
  const click = (x: number, y: number, button: Button | undefined, hold = 1) => {
    if (!Number.isInteger(hold) || hold < 1) throw new ScenarioError(`hold must be >= 1, got ${hold}`);
    move(x, y);
    wait(1);
    setBtn(button, true);
    wait(hold);
    setBtn(button, false);
    wait(1);
  };

  for (const st of normalizeSteps(sc)) {
    switch (st.op) {
      case 'move': move(st.x, st.y); break;
      case 'down': setBtn(st.button, true); break;
      case 'up': setBtn(st.button, false); break;
      case 'wait': wait(st.frames); break;
      case 'click': click(st.x, st.y, st.button, st.hold); break;
      case 'click_tool': {
        const c = buttonCenter(toolByName(st.tool));
        click(c.x, c.y, 'left', st.hold);
        break;
      }
      case 'click_cell': {
        let p: Point;
        if (st.screen) p = st.screen;
        else if (st.cell) p = resolve({ cell: st.cell, pan: st.pan });
        else throw new ScenarioError('click_cell needs "cell" or "screen"');
        click(p[0], p[1], st.button, st.hold);
        break;
      }
      case 'drag': {
        if (!Number.isInteger(st.frames) || st.frames < 1) throw new ScenarioError(`drag needs frames >= 1`);
        const a = resolve(st.from);
        const b = resolve(st.to);
        move(a[0], a[1]);
        wait(1);
        setBtn(st.button, true);
        wait(1);
        for (let i = 1; i <= st.frames; i++) {
          move(a[0] + ((b[0] - a[0]) * i) / st.frames, a[1] + ((b[1] - a[1]) * i) / st.frames);
          wait(1);
        }
        setBtn(st.button, false);
        wait(1);
        break;
      }
      case 'assume_pan': assumedPan = [st.x, st.y]; break;
      case 'checkpoint': {
        if (frames.length === 0) throw new ScenarioError(`checkpoint "${st.label}" before any frame`);
        if (dirty) throw new ScenarioError(`checkpoint "${st.label}" follows input changes with no wait`);
        if (checkpoints.some((c) => c.label === st.label)) throw new ScenarioError(`duplicate checkpoint "${st.label}"`);
        checkpoints.push({ label: st.label, frame: frames.length - 1 });
        break;
      }
      case 'comment': break;
      default: throw new ScenarioError(`unknown op ${(st as { op: string }).op}`);
    }
  }
  if (dirty) frames.push({ ...cur }); // commit trailing changes
  return { name: sc.name, description: sc.description, frameCount: frames.length, frames, checkpoints };
}

/** Turn a recorded per-frame sequence back into a compact raw scenario (used by the web shell). */
export function framesToScenario(
  name: string,
  frames: MouseSnapshot[],
  checkpoints: Checkpoint[] = [],
  initial: MouseSnapshot = defaultMouse(),
  description?: string,
): Scenario {
  const steps: string[] = [];
  let prev = initial;
  let pendingWait = 0;
  const flush = () => {
    if (pendingWait > 0) steps.push(`wait ${pendingWait}`);
    pendingWait = 0;
  };
  const cpByFrame = new Map<number, string[]>();
  for (const c of checkpoints) cpByFrame.set(c.frame, [...(cpByFrame.get(c.frame) ?? []), c.label]);
  frames.forEach((f, i) => {
    const changes: string[] = [];
    if (f.x !== prev.x || f.y !== prev.y) changes.push(`move ${f.x} ${f.y}`);
    for (const b of ['left', 'middle', 'right'] as const) {
      if (f[b] !== prev[b]) changes.push(`${f[b] ? 'down' : 'up'} ${b}`);
    }
    if (changes.length) {
      flush();
      steps.push(...changes);
    }
    pendingWait += 1;
    prev = f;
    const labels = cpByFrame.get(i);
    if (labels) {
      flush();
      for (const l of labels) steps.push(`checkpoint ${l}`);
    }
  });
  flush();
  return { name, description, initialMouse: { ...initial }, steps };
}
