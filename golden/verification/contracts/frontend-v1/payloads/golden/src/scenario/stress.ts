import { GRID_H, GRID_W } from '../core/constants.ts';
import { expandScenario } from './expand.ts';
import type { Scenario, Step } from './types.ts';

/** Versioned PRNG; no ambient randomness, so a saved seed reproduces input bytes. */
export function random32(seed: number): () => number {
  if (!Number.isInteger(seed) || seed < 1 || seed > 0x7fffffff) throw new Error('seed must be 1..2147483647');
  let state = seed >>> 0;
  return () => {
    state ^= state << 13; state ^= state >>> 17; state ^= state << 5;
    return state >>> 0;
  };
}

export interface StressCase {
  version: 1 | 2;
  seed: number;
  blocks: Step[][];
  scenario: Scenario;
  corpus?: DirectedCorpus;
}

export const DIRECTED_CORPORA = ['rotations', 'properties', 'boundaries', 'dense'] as const;
export type DirectedCorpus = typeof DIRECTED_CORPORA[number];

export function scenarioFromBlocks(seed: number, blocks: Step[][], version: 1 | 2 = 1): Scenario {
  return {
    name: version === 1 ? `m4_seed_${seed}` : `m4_v${version}_seed_${seed}`,
    description: `M4 v${version} cold-start canvas stress; settled state checks use the accepted M1 latency. No solver/stall/PS2 qualification.`,
    steps: [
      { op: 'wait', frames: 3 }, { op: 'checkpoint', label: 'boot' },
      ...blocks.flatMap((block, i): Step[] => [
        ...block, { op: 'wait', frames: 2 }, { op: 'checkpoint', label: `operation_${i}` },
      ]),
    ],
  };
}

export function generateStress(seed: number, operations = 16, version: 1 | 2 = 1): StressCase {
  if (!Number.isInteger(operations) || operations < 1 || operations > 1000) throw new Error('operations must be 1..1000');
  if (version === 2) return generateStressV2(seed, operations);
  if (version !== 1) throw new Error('version must be 1 or 2');
  const rnd = random32(seed);
  const tools = ['wire', 'ground', 'resistor', 'inductor', 'capacitor', 'voltage', 'current', 'rotate', 'delete'];
  const blocks: Step[][] = [];
  for (let i = 0; i < operations; i++) {
    const tool = tools[rnd() % tools.length]!;
    // Weight visible boundaries and boot-circuit collisions alongside free space.
    const col = [0, GRID_W - 1, 1 + rnd() % (GRID_W - 2), 4][rnd() % 4]!;
    const row = [0, 8, 1 + rnd() % 7, 4][rnd() % 4]!;
    const hold = rnd() % 5 === 0 ? 9 : 1;
    blocks.push([
      { op: 'click_tool', tool },
      { op: 'click_cell', cell: [col, row], hold },
    ]);
  }
  return { version: 1, seed, blocks, scenario: scenarioFromBlocks(seed, blocks) };
}

const PAN_BOTTOM = -224; // PAN_MIN_Y: rows 7-15 visible
const COMPONENT_TOOLS = ['resistor', 'inductor', 'capacitor', 'voltage', 'current'];

/**
 * v2 adds what v1 left uncovered: panning to the bottom rows (row 15 weighted),
 * and repeated rotation of components this case itself placed. v1 stays byte-identical.
 * Pan blocks set `assume_pan` for later clicks; a reduced case that drops one stays
 * replayable, its clicks just land where the stale assumption maps them.
 */
function generateStressV2(seed: number, operations: number): StressCase {
  const rnd = random32(seed);
  const tools = ['wire', 'ground', ...COMPONENT_TOOLS, 'rotate', 'delete'];
  const blocks: Step[][] = [];
  const placed: [number, number][] = [];
  let panned = false;
  for (let i = 0; i < operations; i++) {
    const kind = rnd() % 8;
    if (kind === 0) {
      panned = !panned;
      blocks.push(panned
        ? [{ op: 'click_tool', tool: 'pan' }, { op: 'drag', from: { screen: [300, 340] }, to: { screen: [300, 40] }, frames: 15 },
          { op: 'assume_pan', x: 0, y: PAN_BOTTOM }]
        : [{ op: 'click_tool', tool: 'pan' }, { op: 'drag', from: { screen: [300, 70] }, to: { screen: [300, 340] }, frames: 15 },
          { op: 'assume_pan', x: 0, y: 0 }]);
      continue;
    }
    if (kind === 1 && placed.length) {
      const cell = placed[rnd() % placed.length]!;
      const block: Step[] = [{ op: 'click_tool', tool: 'rotate' }];
      for (let n = 1 + rnd() % 3; n > 0; n--) block.push({ op: 'click_cell', cell, hold: 1 }, { op: 'wait', frames: 2 });
      blocks.push(block);
      continue;
    }
    const tool = tools[rnd() % tools.length]!;
    const col = [0, GRID_W - 1, 1 + rnd() % (GRID_W - 2), 4][rnd() % 4]!;
    const row = panned ? [GRID_H - 1, 7 + rnd() % 9, GRID_H - 1, 12][rnd() % 4]! : [0, 8, 1 + rnd() % 7, 4][rnd() % 4]!;
    const hold = rnd() % 5 === 0 ? 9 : 1;
    if (COMPONENT_TOOLS.includes(tool)) placed.push([col, row]);
    blocks.push([{ op: 'click_tool', tool }, { op: 'click_cell', cell: [col, row], hold }]);
  }
  return { version: 2, seed, blocks, scenario: scenarioFromBlocks(seed, blocks, 2) };
}

/** Directed, seeded companions to v1/v2; the original generators stay unchanged. */
export function generateDirectedStress(seed: number, corpus: DirectedCorpus): StressCase {
  const rnd = random32(seed);
  if (!DIRECTED_CORPORA.includes(corpus)) throw new Error(`unknown directed corpus: ${corpus}`);
  const blocks: Step[][] = [];
  const tool = (name: string): Step => ({ op: 'click_tool', tool: name });
  const cell = (col: number, row: number, hold = 1): Step => ({ op: 'click_cell', cell: [col, row], hold });
  const key = (x: number, y: number): Step => ({ op: 'click', x, y });
  // RST with an empty selected cell clears all stores, including the boot circuit.
  blocks.push([tool('pan'), cell(0, 0), key(620, 464)]);
  if (corpus === 'rotations') {
    const start = rnd() % COMPONENT_TOOLS.length;
    for (let i = 0; i < COMPONENT_TOOLS.length; i++) {
      const kind = COMPONENT_TOOLS[(start + i) % COMPONENT_TOOLS.length]!;
      const col = 3 + (i % 3) * 5, row = 2 + Math.floor(i / 3) * 4;
      blocks.push([tool(kind), cell(col, row)]);
      for (let rotation = 1; rotation < 4; rotation++) blocks.push([tool('rotate'), cell(col, row)]);
    }
  } else if (corpus === 'properties') {
    const kind = COMPONENT_TOOLS[rnd() % COMPONENT_TOOLS.length]!;
    blocks.push([tool(kind), cell(8, 3)]);
    // Select both halves with the pan tool; editing via partner must update its anchor slot.
    blocks.push([tool('pan'), cell(8, 3)]);
    blocks.push([cell(9, 3)]);
    blocks.push([cell(9, 3), key(280, 34), key(620, 464), key(500, 368), key(531, 368)]);
    // Each unit begins from the same literal digits, avoiding concatenated suffix assumptions.
    for (const [x, y] of [[593, 368], [624, 368], [593, 400], [624, 400], [593, 432], [624, 432]]) {
      blocks.push([key(x!, y!)]);
      blocks.push([key(570, 464)]); // delete suffix, preserving digits and returning unit to None
    }
    blocks.push([key(570, 464)]); // delete a digit
    blocks.push([key(500, 464), key(531, 464)]); // decimal and zero literal
    blocks.push([key(620, 464)]); // selected-component reset retains the component
    blocks.push([key(280, 54)]); // close editing
  } else if (corpus === 'boundaries') {
    const kind = COMPONENT_TOOLS[rnd() % COMPONENT_TOOLS.length]!;
    blocks.push([tool(kind), cell(GRID_W - 1, 0)]); // partner outside canvas: settled stores unchanged
    blocks.push([tool(kind), cell(0, 0)]);
    blocks.push([tool(kind), cell(0, 0)]); // occupied anchor: reject
    blocks.push([tool('wire'), cell(GRID_W - 1, 0, 9)]);
    blocks.push([tool('rotate'), cell(GRID_W - 1, 0, 9)]);
    blocks.push([tool('delete'), cell(1, 0)]); // deleting partner removes both halves
    blocks.push([tool(kind), cell(0, 0)]); // freed component slot reused
    blocks.push([tool('pan'), { op: 'drag', from: { screen: [300, 340] }, to: { screen: [300, 40] }, frames: 15 },
      { op: 'assume_pan', x: 0, y: PAN_BOTTOM }]);
    blocks.push([tool('ground'), cell(0, GRID_H - 1)]);
    blocks.push([tool(kind), cell(GRID_W - 2, GRID_H - 1)]);
    blocks.push([tool('rotate'), cell(GRID_W - 2, GRID_H - 1)]); // downward partner outside canvas: reject
  } else {
    // The 288-cell canvas admits 144 two-cell components, below the 288-slot store depth.
    // Fill every logical cell; this qualifies canvas occupancy, never physical store exhaustion.
    const kind = COMPONENT_TOOLS[rnd() % COMPONENT_TOOLS.length]!;
    for (let row = 0; row < GRID_H; row++) {
      if (row === 9) blocks.push([tool('pan'), { op: 'drag', from: { screen: [300, 340] }, to: { screen: [300, 40] }, frames: 15 },
        { op: 'assume_pan', x: 0, y: PAN_BOTTOM }]);
      const block: Step[] = row === 0 || row === 9 ? [tool(kind)] : [];
      for (let col = 0; col < GRID_W; col += 2) {
        block.push(cell(col, row));
      }
      blocks.push(block);
    }
    blocks.push([tool('resistor'), cell(0, GRID_H - 1)]); // full canvas rejects another placement
    blocks.push([tool('delete'), cell(1, GRID_H - 1)]);
    blocks.push([tool('resistor'), cell(0, GRID_H - 1)]); // fill the freed pair again
  }
  const scenario = scenarioFromBlocks(seed, blocks, 2);
  scenario.name = `m4_directed_${corpus}_seed_${seed}`;
  scenario.description = `M4 directed ${corpus} corpus, seed ${seed}; accepted settled canvas state contract. No solver/stall/PS2 qualification.`;
  return { version: 2, seed, corpus, blocks, scenario };
}

export function frameCount(sc: Scenario): number { return expandScenario(sc).frameCount; }
