// Seeded random canvases and netlists for backend tests.
import { spawnSync } from 'node:child_process';
import { makeCell } from '../src/core/encoding.ts';
import { LEFT_HALF_SPRITES, PAIR_DELTA, Sprite } from '../src/core/constants.ts';
import type { PlacedComponent } from '../src/backend/netlist.ts';

export function rng(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export const pick = <T>(r: () => number, xs: readonly T[]): T => xs[Math.floor(r() * xs.length)]!;
export const int = (r: () => number, lo: number, hi: number) => lo + Math.floor(r() * (hi - lo + 1));

const CONDUCTORS = [Sprite.Wire, Sprite.Elbow, Sprite.Tee, Sprite.Junction, Sprite.Cross, Sprite.Ground];
const LEFTS = [...LEFT_HALF_SPRITES];

export interface RandomCanvas { width: number; height: number; cells: Uint16Array; components: PlacedComponent[] }

/** Components first (so they find room), then conductors in a share of the remaining cells. */
export function randomCanvas(r: () => number, width: number, height: number, density = 0.6): RandomCanvas {
  const cells = new Uint16Array(width * height);
  const components: PlacedComponent[] = [];
  const tries = int(r, 0, Math.ceil((width * height) / 8));
  for (let k = 0; k < tries; k++) {
    const col = int(r, 0, width - 1), row = int(r, 0, height - 1), rotation = int(r, 0, 3);
    const [dx, dy] = PAIR_DELTA[rotation]!;
    const pc = col + dx, pr = row + dy;
    if (pc < 0 || pr < 0 || pc >= width || pr >= height) continue;
    if (cells[row * width + col] || cells[pr * width + pc]) continue;
    const leftSprite = pick(r, LEFTS);
    cells[row * width + col] = makeCell(leftSprite, rotation);
    cells[pr * width + pc] = makeCell(leftSprite + 1, rotation);
    components.push({ leftSprite, col, row, rotation, valueBcd: int(r, 0, 0x999), unit: int(r, 0, 5), slot: k });
  }
  for (let a = 0; a < cells.length; a++) {
    if (cells[a] || r() > density) continue;
    // Few grounds, so grounded and floating regions both occur.
    const sprite = r() < 0.08 ? Sprite.Ground : pick(r, CONDUCTORS.slice(0, 5));
    cells[a] = makeCell(sprite, int(r, 0, 3));
  }
  return { width, height, cells, components };
}

export function python(): string | null {
  for (const exe of ['python3', 'python']) {
    if (spawnSync(exe, ['--version']).status === 0) return exe;
  }
  return null;
}

export function runPython(script: string, args: string[], input: unknown): unknown {
  const exe = python();
  if (!exe) throw new Error('python not available');
  const res = spawnSync(exe, [script, ...args], { input: JSON.stringify(input), encoding: 'utf8', maxBuffer: 1 << 28 });
  if (res.status !== 0) throw new Error(`${script} failed (${res.status}): ${res.stderr}`);
  return JSON.parse(res.stdout);
}
