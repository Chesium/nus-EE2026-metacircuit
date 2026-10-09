// GM-7 differential test: golden extraction vs the simpyhls reference kernels
// (flooding_core.dsl.py, extract_component_nodes.dsl.py) on random circuits.
// Disagreements are "either side may be wrong" (D-007); the expected ones are
// documented in M3_ASSUMPTIONS.md (M3-A002, M3-A003) and reproduced exactly by
// the golden's dslCompat mode, so any other difference fails the test.
import { existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { extractFromCanvas, type ExtractionResult } from '../src/backend/netlist.ts';
import { cellPortMask } from '../src/core/connectivity.ts';
import { initialState, liveComponents } from '../src/core/state.ts';
import { GRID_H, GRID_W } from '../src/core/constants.ts';
import { python, randomCanvas, rng, runPython, int, type RandomCanvas } from './backendRandom.ts';

const SCRIPT = 'tools/simpyhls_backend.py';

function findSimpyhls(): string | null {
  if (process.env.SIMPYHLS_DIR) return process.env.SIMPYHLS_DIR;
  for (let dir = resolve('..'); ; dir = dirname(dir)) {
    if (existsSync(join(dir, 'simpyhls', 'examples', 'flooding_core.dsl.py'))) return join(dir, 'simpyhls');
    if (dirname(dir) === dir) return null;
  }
}
const SIMPYHLS = findSimpyhls();
const available = python() !== null && SIMPYHLS !== null;

interface DslResult { regions: number[]; node0: number[]; node1: number[] }

function runKernels(canvases: RandomCanvas[], mode: 'dsl' | 'exec'): DslResult[] {
  const cases = canvases.map((c) => {
    // Element idx order is the golden's (anchor row-major), so per-idx results compare directly.
    const ordered = extractFromCanvas(c).elements;
    return {
      width: c.width, height: c.height, cells: Array.from(c.cells), ports: Array.from(c.cells, cellPortMask),
      components: ordered.map((e) => ({ type: e.leftSprite, x: e.col, y: e.row, rotation: e.rotation })),
    };
  });
  const args = ['--simpyhls', SIMPYHLS!, ...(mode === 'exec' ? ['--exec'] : [])];
  return (runPython(SCRIPT, args, { cases }) as { results: DslResult[] }).results;
}

const nodesOf = (r: ExtractionResult) => ({ node0: r.netlist.elements.map((e) => e.n0), node1: r.netlist.elements.map((e) => e.n1) });

function compare(canvases: RandomCanvas[], dsl: DslResult[]) {
  const stats = { cases: canvases.length, elements: 0, agree: 0, differ: 0, causeTerminal: 0, causeGround: 0, elementDiffs: 0 };
  canvases.forEach((c, i) => {
    const d = dsl[i]!;
    const golden = extractFromCanvas(c);
    const compat = extractFromCanvas(c, { dslCompat: true });
    // 1. flooding_core numbering == the reciprocal-port graph's row-major labels.
    expect(Array.from(golden.regions), `case ${i} regions`).toEqual(d.regions);
    // 2. The DSL's lookups, modelled by dslCompat, reproduce the kernel exactly.
    expect(nodesOf(compat), `case ${i} dslCompat nodes`).toEqual({ node0: d.node0, node1: d.node1 });
    // 3. Golden rules vs kernel: classify every disagreement.
    stats.elements += golden.netlist.elements.length;
    const g = nodesOf(golden);
    const same = JSON.stringify(g) === JSON.stringify({ node0: d.node0, node1: d.node1 });
    if (same) { stats.agree++; return; }
    stats.differ++;
    g.node0.forEach((n, k) => { stats.elementDiffs += Number(n !== d.node0[k]) + Number(g.node1[k] !== d.node1[k]); });
    const terminal = golden.elements.some((e, k) => e.raw.some((r, t) => r !== compat.elements[k]!.raw[t]));
    const ground = JSON.stringify(golden.groundRegions) !== JSON.stringify(compat.groundRegions);
    expect(terminal || ground, `case ${i}: disagreement not explained by M3-A002/M3-A003`).toBe(true);
    stats.causeTerminal += Number(terminal);
    stats.causeGround += Number(ground);
  });
  return stats;
}

describe.skipIf(!available)('simpyhls reference kernels (differential)', () => {
  it('agrees on the boot circuit at full grid size through the DSL interpreter', () => {
    const s = initialState();
    const canvas: RandomCanvas = {
      width: GRID_W, height: GRID_H, cells: s.cells,
      components: liveComponents(s).map(({ slot, c }) => ({ ...c, slot })),
    };
    const [d] = runKernels([canvas], 'dsl');
    const golden = extractFromCanvas(canvas);
    expect(Array.from(golden.regions)).toEqual(d!.regions);
    expect(nodesOf(golden)).toEqual({ node0: d!.node0, node1: d!.node1 });
  }, 120_000);

  it('agrees, up to the documented rules, on 42 random circuits through the DSL interpreter', () => {
    const r = rng(0x5eed);
    const canvases = Array.from({ length: 42 }, (_, i) =>
      i < 2 ? randomCanvas(r, GRID_W, GRID_H, 0.5) : randomCanvas(r, int(r, 2, 7), int(r, 2, 6)));
    const stats = compare(canvases, runKernels(canvases, 'dsl'));
    console.info('simpyhls diff (run_python):', JSON.stringify(stats));
    expect(stats.agree).toBeGreaterThan(0);
  }, 120_000);

  it('agrees, up to the documented rules, on 400 random circuits up to full size (plain exec)', () => {
    const r = rng(0xc1c0);
    const canvases = Array.from({ length: 400 }, (_, i) =>
      i % 10 === 0 ? randomCanvas(r, GRID_W, GRID_H, 0.5) : randomCanvas(r, int(r, 2, 12), int(r, 2, 10), 0.3 + 0.6 * r()));
    const stats = compare(canvases, runKernels(canvases, 'exec'));
    console.info('simpyhls diff (exec, mixed):', JSON.stringify(stats));
    expect(stats.agree).toBeGreaterThan(stats.cases / 4);
    expect(stats.differ).toBeGreaterThan(0); // the documented rule differences do occur
  }, 300_000);
});
