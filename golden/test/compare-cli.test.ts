import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync, unlinkSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { DEFAULT_DUMP_NAMES, exportRamDumps, initialState, semanticState } from '../src/core/index.ts';
import { compareRun } from '../src/cli/compare.ts';

const directories: string[] = [];
afterEach(() => {
  vi.restoreAllMocks();
  for (const d of directories.splice(0)) rmSync(d, { recursive: true, force: true });
});

function fixture() {
  vi.spyOn(process.stdout, 'write').mockReturnValue(true);
  const root = mkdtempSync(join(tmpdir(), 'm1-compare-'));
  directories.push(root);
  const ref = join(root, 'reference'), rtl = join(root, 'rtl');
  mkdirSync(ref); mkdirSync(rtl);
  const write = (path: string, object: unknown) => writeFileSync(path, JSON.stringify(object));
  const state = initialState();
  const dumps = exportRamDumps(state, undefined, 2);
  write(join(ref, 'checkpoints.json'), { scenario: 'boot', frameCount: 3, names: DEFAULT_DUMP_NAMES,
    checkpoints: [{ label: 'boot', frame: 2, ram: 'boot.ram.json', state: 'boot.state.json' }] });
  write(join(ref, 'boot.ram.json'), dumps);
  write(join(ref, 'boot.state.json'), semanticState(state, 2));
  const probes = { tool_idx: 0, wire_variant: 0, mode_select: 15, grid_pos_x: 0, grid_pos_y: 0,
    init_done: 1, interaction_idle: 1, interaction_frame_drop: 0, component_store_busy: 0, component_count: 3 };
  for (const d of dumps) write(join(rtl, `${d.name}.json`), d);
  const report = { ok: true, stimulus: [{ late: false }], monitors: { vga: { frames: [0, 1, 2].map((index) => ({ index, probes })) } },
    dumps: Object.fromEntries(dumps.map((d) => [d.name, [{ frame: 2, path: `${d.name}.json` }]])) };
  write(join(rtl, 'report.json'), report);
  return {
    run: () => compareRun(rtl, ref),
    result: () => JSON.parse(readFileSync(join(rtl, 'state-compare.json'), 'utf8')),
    report, writeReport: () => write(join(rtl, 'report.json'), report), rtl,
  };
}

describe('comparison command evidence and exit status', () => {
  it('writes a machine-readable passing result', () => {
    const f = fixture();
    expect(f.run()).toBe(0);
    expect(f.result()).toMatchObject({ ok: true, summary: { checkpoints: 1, passed: 1, failed: 0 } });
  });
  it('fails when a required memory file is missing', () => {
    const f = fixture();
    unlinkSync(join(f.rtl, 'cells_shadow.json'));
    expect(f.run()).toBe(1);
    expect(f.result()).toMatchObject({ ok: false, summary: { failed: 1 } });
  });
  it.each(['simulation', 'shortRun', 'lateStimulus'] as const)('fails for %s even when checkpoint RAM matches', (failure) => {
    const f = fixture();
    if (failure === 'simulation') f.report.ok = false;
    if (failure === 'shortRun') f.report.monitors.vga.frames.shift();
    if (failure === 'lateStimulus') f.report.stimulus[0]!.late = true;
    f.writeReport();
    expect(f.run()).toBe(1);
    expect(f.result().errors).not.toHaveLength(0);
  });
});
