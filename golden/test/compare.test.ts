import { describe, expect, it } from 'vitest';
import { initialState, exportRamDumps, semanticState, decodeComponent, encodeComponent, toHex } from '../src/core/index.ts';
import { compareCheckpoint } from '../src/scenario/compare.ts';

function fixture() {
  const s = initialState();
  const expected = { frame: 2, dumps: exportRamDumps(s, undefined, 2), semantic: semanticState(s, 2) };
  const actual = {
    frame: 2,
    dumps: structuredClone(expected.dumps),
    probes: { tool_idx: 0, wire_variant: 0, mode_select: 15, grid_pos_x: 0, grid_pos_y: 0,
      init_done: 1, interaction_idle: 1, interaction_frame_drop: 0, component_store_busy: 0, component_count: 3 },
  };
  const memory = (name: string) => actual.dumps.find((d) => d.name === name)!;
  return { expected, actual, memory };
}

describe('M1 checkpoint comparison', () => {
  it('accepts slot permutations and stale entries, but keeps map ownership strict', () => {
    const { expected, actual, memory } = fixture();
    const store = memory('component_store');
    [store.words[0], store.words[2]] = [store.words[2]!, store.words[0]!];
    for (const slot of [0, 2]) {
      const decoded = decodeComponent(BigInt(store.words[slot]!));
      store.words[slot] = toHex(encodeComponent({ ...decoded, index: slot }), 40);
    }
    const map = memory('component_index_map');
    map.words = map.words.map((w) => w === '0x000' ? '0x002' : w === '0x002' ? '0x000' : w);
    store.words[100] = store.words[0]!; // stale slot must be ignored using component_count
    expect(compareCheckpoint(expected, actual)).toEqual([]);
    map.words[39] = '0x000';
    expect(compareCheckpoint(expected, actual)).toContain('component_index_map[39] is 0, expected 2');
  });

  it('allows flow metadata differences while rejecting sprite and mirrored-RAM differences', () => {
    const { expected, actual, memory } = fixture();
    for (const name of ['cells_render', 'cells_shadow']) memory(name).words[39] = '0x0311'; // boot VR rot 2 (0x0111) with flow bit 9 set
    expect(compareCheckpoint(expected, actual)).toEqual([]);
    memory('cells_render').words[39] = '0x020b';
    const diff = compareCheckpoint(expected, actual);
    expect(diff).toContain('mirrored cell RAMs differ at address 39');
    expect(diff).toContain('cell (3,2) is RL rot 0, expected VR rot 2');
  });

  it('rejects value loss, broken components, busy checkpoints and dropped frames', () => {
    const { expected, actual, memory } = fixture();
    memory('values_shadow').words[39] = '0x000';
    memory('component_store').words[0] = memory('component_store').words[1]!;
    actual.probes.component_store_busy = 1;
    actual.probes.interaction_frame_drop = 1;
    const diff = compareCheckpoint(expected, actual);
    expect(diff).toContain('values_shadow[39] is 0x000, expected 0x010');
    expect(diff).toContain('duplicate component anchor (3,4)');
    expect(diff).toContain('probe component_store_busy is 1, expected 0');
    expect(diff).toContain('probe interaction_frame_drop is 1, expected 0');
  });

  it.each(['missing', 'truncated', 'wrongFrame', 'overflow', 'duplicate'] as const)('fails closed for %s dump evidence', (kind) => {
    const { expected, actual, memory } = fixture();
    if (kind === 'missing') actual.dumps.pop();
    if (kind === 'truncated') memory('cells_render').words.pop();
    if (kind === 'wrongFrame') memory('cells_render').frame++;
    if (kind === 'overflow') memory('cells_render').words[0] = '0x10000';
    if (kind === 'duplicate') actual.dumps.push(structuredClone(memory('cells_render')));
    expect(compareCheckpoint(expected, actual).length).toBeGreaterThan(0);
  });

  it('rejects missing count and incorrect toolbar/pan evidence', () => {
    const { expected, actual } = fixture();
    delete (actual.probes as Record<string, number>).component_count;
    actual.probes.tool_idx = 1;
    actual.probes.grid_pos_y = -1;
    const diff = compareCheckpoint(expected, actual);
    expect(diff).toContain('invalid component_count');
    expect(diff).toContain('probe tool_idx is 1, expected 0');
    expect(diff).toContain('probe grid_pos_y is -1, expected 0');
  });
});
