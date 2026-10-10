// GM-7 differential test: golden extraction vs the simpyhls reference kernels
// (flooding_core.dsl.py, extract_component_nodes.dsl.py) on random circuits.
//
// Two kernel sets are run (D-007, D-022):
//  - the kernels as written before the decisions, frozen in
//    test/fixtures/kernels-as-written (simpyhls 57ffb08). The golden's
//    dslCompat mode reproduces them exactly, and every golden-rule difference
//    must be explained by a decision (M3-A002/D-021 reciprocal terminals,
//    M3-A003/D-021 grounds, D-015 current-source terminals, D-019 floating rows).
//  - the live kernels of the simpyhls checkout. Their flooding must number
//    regions exactly as the golden does. Once the kernel branch implementing
//    D-015/D-019/D-021 lands, their extraction must agree with the golden rules
//    exactly; until then those tests are expected failures (kernelStatus.ts).
import { existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { extractFromCanvas, type ExtractionResult } from '../src/backend/netlist.ts';
import { ElementKind } from '../src/backend/types.ts';
import { cellPortMask } from '../src/core/connectivity.ts';
import { initialState, liveComponents } from '../src/core/state.ts';
import { GRID_H, GRID_W } from '../src/core/constants.ts';
import { python, randomCanvas, rng, runPython, int, type RandomCanvas } from './backendRandom.ts';
import { itAfterKernelFix } from './kernelStatus.ts';

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
type Kernels = 'as-written' | 'live';

function runKernels(canvases: RandomCanvas[], mode: 'dsl' | 'exec', kernels: Kernels): DslResult[] {
  const cases = canvases.map((c) => {
    // Element idx order is the golden's (anchor row-major), so per-idx results compare directly.
    const ordered = extractFromCanvas(c).elements;
    return {
      width: c.width, height: c.height, cells: Array.from(c.cells), ports: Array.from(c.cells, cellPortMask),
      components: ordered.map((e) => ({ type: e.leftSprite, x: e.col, y: e.row, rotation: e.rotation })),
    };
  });
  const args = ['--simpyhls', SIMPYHLS!, ...(mode === 'exec' ? ['--exec'] : []), ...(kernels === 'as-written' ? ['--as-written'] : [])];
  return (runPython(SCRIPT, args, { cases }) as { results: DslResult[] }).results;
}

const nodesOf = (r: ExtractionResult) => ({ node0: r.netlist.elements.map((e) => e.n0), node1: r.netlist.elements.map((e) => e.n1) });
const kernelNodes = (d: DslResult) => ({ node0: d.node0, node1: d.node1 });

/** As-written kernels: exact against dslCompat; golden-rule differences classified by decision. */
function compareAsWritten(canvases: RandomCanvas[], dsl: DslResult[]) {
  const stats = { cases: canvases.length, elements: 0, agree: 0, differ: 0, causeTerminal: 0, causeGround: 0, causeCurrentSource: 0, causeFloating: 0 };
  canvases.forEach((c, i) => {
    const d = dsl[i]!;
    const golden = extractFromCanvas(c);
    const compat = extractFromCanvas(c, { dslCompat: true });
    expect(Array.from(golden.regions), `case ${i} regions`).toEqual(d.regions);
    expect(nodesOf(compat), `case ${i} dslCompat nodes`).toEqual(kernelNodes(d));
    stats.elements += golden.netlist.elements.length;
    if (JSON.stringify(nodesOf(golden)) === JSON.stringify(kernelNodes(d))) { stats.agree++; return; }
    stats.differ++;
    // The golden's raw regions per terminal, in the as-written (anchor-first) order.
    const anchorFirst = golden.elements.map((e, k) =>
      golden.netlist.elements[k]!.kind === ElementKind.CurrentDc ? [e.raw[1], e.raw[0]] : e.raw);
    const terminal = anchorFirst.some((raw, k) => raw.some((r, t) => r !== compat.elements[k]!.raw[t]));
    const ground = JSON.stringify(golden.groundRegions) !== JSON.stringify(compat.groundRegions);
    const current = golden.netlist.elements.some((e) => e.kind === ElementKind.CurrentDc);
    const floating = golden.issues.some((x) => x.type === 'floating-terminal');
    expect(terminal || ground || current || floating, `case ${i}: disagreement not explained by D-015/D-019/D-021`).toBe(true);
    stats.causeTerminal += Number(terminal);
    stats.causeGround += Number(ground);
    stats.causeCurrentSource += Number(current);
    stats.causeFloating += Number(floating);
  });
  return stats;
}

/** Live kernels: flooding numbering must equal the golden's (holds before and after the kernel fixes). */
function expectSameRegions(canvases: RandomCanvas[], dsl: DslResult[]) {
  canvases.forEach((c, i) => expect(Array.from(extractFromCanvas(c).regions), `case ${i} regions`).toEqual(dsl[i]!.regions));
}

/** Live kernels after D-015/D-019/D-021: node0/node1 exactly the golden rules'. */
function expectFullAgreement(canvases: RandomCanvas[], dsl: DslResult[]) {
  const differ: number[] = [];
  canvases.forEach((c, i) => {
    if (JSON.stringify(nodesOf(extractFromCanvas(c))) !== JSON.stringify(kernelNodes(dsl[i]!))) differ.push(i);
  });
  expect(differ, 'cases where the live extraction kernel differs from the golden rules').toEqual([]);
}

function bootCanvas(): RandomCanvas {
  const s = initialState();
  return { width: GRID_W, height: GRID_H, cells: s.cells, components: liveComponents(s).map(({ slot, c }) => ({ ...c, slot })) };
}
function smallSet(): RandomCanvas[] {
  const r = rng(0x5eed);
  return Array.from({ length: 42 }, (_, i) => i < 2 ? randomCanvas(r, GRID_W, GRID_H, 0.5) : randomCanvas(r, int(r, 2, 7), int(r, 2, 6)));
}
function mixedSet(): RandomCanvas[] {
  const r = rng(0xc1c0);
  return Array.from({ length: 400 }, (_, i) =>
    i % 10 === 0 ? randomCanvas(r, GRID_W, GRID_H, 0.5) : randomCanvas(r, int(r, 2, 12), int(r, 2, 10), 0.3 + 0.6 * r()));
}

/** Live kernel results are computed once per set and shared by the region and agreement tests. */
const liveCache = new Map<string, DslResult[]>();
function live(name: string, canvases: RandomCanvas[], mode: 'dsl' | 'exec'): DslResult[] {
  if (!liveCache.has(name)) liveCache.set(name, runKernels(canvases, mode, 'live'));
  return liveCache.get(name)!;
}

describe.skipIf(!available)('simpyhls kernels as written (frozen, test/fixtures/kernels-as-written)', () => {
  it('dslCompat reproduces the boot circuit at full grid size through the DSL interpreter', () => {
    const c = bootCanvas();
    const [d] = runKernels([c], 'dsl', 'as-written');
    expect(Array.from(extractFromCanvas(c).regions)).toEqual(d!.regions);
    expect(nodesOf(extractFromCanvas(c, { dslCompat: true }))).toEqual(kernelNodes(d!));
  }, 120_000);

  it('dslCompat reproduces 42 random circuits through the DSL interpreter; differences follow the decisions', () => {
    const canvases = smallSet();
    const stats = compareAsWritten(canvases, runKernels(canvases, 'dsl', 'as-written'));
    console.info('simpyhls as-written diff (run_python):', JSON.stringify(stats));
    expect(stats.agree).toBeGreaterThan(0);
  }, 120_000);

  it('dslCompat reproduces 400 random circuits up to full size (plain exec); differences follow the decisions', () => {
    const canvases = mixedSet();
    const stats = compareAsWritten(canvases, runKernels(canvases, 'exec', 'as-written'));
    console.info('simpyhls as-written diff (exec, mixed):', JSON.stringify(stats));
    expect(stats.agree).toBeGreaterThan(stats.cases / 5);
    expect(stats.differ).toBeGreaterThan(0); // the decided rule differences do occur
  }, 300_000);
});

describe.skipIf(!available)('simpyhls kernels, live checkout (D-015, D-019, D-021)', () => {
  it('flooding_core numbers regions as the golden does (boot, 42 DSL-interpreted, 400 exec)', () => {
    expectSameRegions([bootCanvas()], live('boot', [bootCanvas()], 'dsl'));
    expectSameRegions(smallSet(), live('small', smallSet(), 'dsl'));
    expectSameRegions(mixedSet(), live('mixed', mixedSet(), 'exec'));
  }, 300_000);

  it('extraction agrees exactly with the golden rules on the boot circuit (DSL interpreter; already true before the fixes)', () => {
    expectFullAgreement([bootCanvas()], live('boot', [bootCanvas()], 'dsl'));
  }, 120_000);

  itAfterKernelFix('extraction agrees exactly with the golden rules on 42 random circuits (DSL interpreter)', () => {
    expectFullAgreement(smallSet(), live('small', smallSet(), 'dsl'));
  }, 120_000);

  itAfterKernelFix('extraction agrees exactly with the golden rules on 400 random circuits (plain exec)', () => {
    expectFullAgreement(mixedSet(), live('mixed', mixedSet(), 'exec'));
  }, 300_000);
});
