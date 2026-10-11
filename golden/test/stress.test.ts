import { describe, expect, it } from 'vitest';
import { createHash } from 'node:crypto';
import { expandScenario } from '../src/scenario/expand.ts';
import { runScenario } from '../src/scenario/run.ts';
import { DIRECTED_CORPORA, generateDirectedStress, generateStress, random32, scenarioFromBlocks } from '../src/scenario/stress.ts';

describe('M4 replayable stress', () => {
  it('pins the PRNG stream and reproduces inputs', () => {
    const rng = random32(1);
    expect([rng(), rng(), rng()]).toEqual([270369, 67634689, 2647435461]);
    expect(generateStress(2026)).toEqual(generateStress(2026));
    expect(generateStress(2026)).not.toEqual(generateStress(2027));
  });
  it('retains boot and settled checkpoints when operation blocks are removed', () => {
    const c = generateStress(7, 8);
    const full = expandScenario(c.scenario);
    const reduced = expandScenario(scenarioFromBlocks(c.seed, [c.blocks[2]!, c.blocks[5]!]));
    expect(reduced.checkpoints.map((p) => p.label)).toEqual(['boot', 'operation_0', 'operation_1']);
    expect(reduced.frames.slice(0, 3)).toEqual(full.frames.slice(0, 3));
    expect(runScenario(reduced).checkpoints).toHaveLength(3);
    expect(reduced.frameCount).toBeLessThan(full.frameCount);
  });
  it('v2 pans to the bottom rows and re-rotates its own components; v1 is unchanged', () => {
    const v1 = generateStress(2026);
    expect(generateStress(2026, 16, 1)).toEqual(v1);
    expect(v1.version).toBe(1);
    const v2 = generateStress(7, 64, 2);
    expect(v2).toEqual(generateStress(7, 64, 2));
    expect(v2.version).toBe(2);
    const steps = v2.blocks.flat();
    expect(steps.some((s) => s.op === 'assume_pan' && s.y === -224)).toBe(true);
    expect(steps.some((s) => s.op === 'click_cell' && s.cell?.[1] === 15)).toBe(true);
    expect(v2.blocks.some((b) => b[0]?.op === 'click_tool' && b[0].tool === 'rotate'
      && b.filter((s) => s.op === 'click_cell').length > 1)).toBe(true);
    expect(runScenario(expandScenario(generateStress(2026, 12, 2).scenario)).checkpoints).toHaveLength(13);
    expect(() => generateStress(1, 4, 3 as 2)).toThrow();
  });
  it('rejects invalid seed and unbounded workload', () => {
    for (const seed of [0, -1, 1.5, NaN, 0x80000000]) expect(() => random32(seed)).toThrow();
    expect(() => generateStress(1, 0)).toThrow();
    expect(() => generateStress(1, 1001)).toThrow();
  });
  it('preserves the saved v1 and v2 input bytes', () => {
    const hash = (version: 1 | 2) => createHash('sha256').update(JSON.stringify(generateStress(2026, 16, version))).digest('hex');
    expect(hash(1)).toBe('ea0d408fdfa1761dfd46f051b3e63e0c89069306cd240f148247da7eb585fed4');
    expect(hash(2)).toBe('59c3c40f1d36a82dd0a4a21b03652bf312437d4858e653f8963b782607a927f2');
  });
  it('directed rotations reach every kind at each orientation without collisions', () => {
    const run = runScenario(expandScenario(generateDirectedStress(2026, 'rotations').scenario));
    const reached = new Set(run.checkpoints.flatMap((cp) => cp.semantic.components.map((c) => `${c.kind}:${c.rotation}`)));
    for (const kind of ['resistor', 'inductor', 'capacitor', 'voltage', 'current']) {
      for (let rotation = 0; rotation < 4; rotation++) expect(reached.has(`${kind}:${rotation}`)).toBe(true);
    }
    expect(run.final.components.filter(Boolean)).toHaveLength(5);
  });
  it('directed partner editing covers every unit and resets the retained component', () => {
    const run = runScenario(expandScenario(generateDirectedStress(2026, 'properties').scenario));
    const values = run.checkpoints.flatMap((cp) => cp.semantic.components.filter((c) => c.col === 8 && c.row === 3));
    expect(new Set(values.map((c) => c.unit))).toEqual(new Set([0, 1, 2, 3, 4, 5, 6]));
    expect(values.some((c) => c.valueBcd === 0x12)).toBe(true);
    expect(values.some((c) => c.valueBcd === 0x10)).toBe(true);
    const component = run.final.components.find(Boolean)!;
    expect(component.valueBcd).toBe(0);
    expect(component.unit).toBe(0);
    expect(run.final.selectedCell).toEqual({ col: 9, row: 3 });
    expect(run.final.valueEditActive).toBe(false);
  });
  it('directed boundaries reject partial writes and reuse the deleted pair slot', () => {
    const run = runScenario(expandScenario(generateDirectedStress(2026, 'boundaries').scenario));
    const states = run.checkpoints.map((cp) => cp.semantic);
    expect(states[1]!.cells).toHaveLength(0);
    expect(states[2]!.cells).toHaveLength(0); // attempted right-edge component
    expect(states[4]!.components).toEqual(states[3]!.components); // occupied anchor
    expect(states[7]!.components).toHaveLength(0); // delete via partner
    expect(states[8]!.components[0]!.slot).toBe(states[3]!.components[0]!.slot);
    expect(states.at(-1)!.components).toEqual(states.at(-2)!.components); // blocked downward rotation
    expect(states.at(-1)!.cells.some((c) => c.row === 15)).toBe(true);
  });
  it('directed density fills all logical cells, rejects one more, then repairs the freed pair', () => {
    const run = runScenario(expandScenario(generateDirectedStress(7, 'dense').scenario));
    const states = run.checkpoints.map((cp) => cp.semantic);
    const full = states.at(-4)!;
    expect(full.cells).toHaveLength(288);
    expect(full.components).toHaveLength(144);
    expect(states.at(-3)!.components).toEqual(full.components);
    expect(states.at(-2)!.cells).toHaveLength(286);
    expect(states.at(-1)!.cells).toHaveLength(288);
    expect(states.at(-1)!.components).toHaveLength(144);
  });
  it('directed cases are reproducible and validate their seed and corpus', () => {
    for (const corpus of DIRECTED_CORPORA) expect(generateDirectedStress(7, corpus)).toEqual(generateDirectedStress(7, corpus));
    expect(() => generateDirectedStress(0, 'rotations')).toThrow();
    expect(() => generateDirectedStress(1, 'unknown' as 'rotations')).toThrow();
  });
});
