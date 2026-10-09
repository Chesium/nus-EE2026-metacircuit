import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { initialState } from '../src/core/state.ts';
import { deriveConnectivity } from '../src/core/connectivity.ts';
import { compareUi } from '../src/cli/compare-ui.ts';

const directories: string[] = [];
afterEach(() => { vi.restoreAllMocks(); for (const dir of directories.splice(0)) rmSync(dir, { recursive: true, force: true }); });

function fixture() {
  vi.spyOn(process.stdout, 'write').mockReturnValue(true);
  const dir = mkdtempSync(join(tmpdir(), 'm2-ui-'));
  directories.push(dir);
  const ref = join(dir, 'reference'); mkdirSync(join(ref, 'vga'), { recursive: true });
  const state = initialState(); state.selectedCell = { col: 4, row: 4 }; state.valueEditActive = true;
  const probes: Record<string, number> = { has_selection: 1, value_edit_active: 1, selected_cell_i: 4, selected_cell_j: 4,
    selected_component_valid: 1, selected_value_bcd: 0x100, selected_value_unit: 0, selected_component_type: 2,
    selected_value_text_len: 3, selected_value_text_hi: 0x31303000, selected_value_text_lo: 0 };
  writeFileSync(join(ref, 'pixels.json'), JSON.stringify({ frames: [0] }));
  writeFileSync(join(ref, 'vga/frame_0000.ui.json'), JSON.stringify(state, (_key, value) => ArrayBuffer.isView(value) ? Array.from(value as unknown as number[]) : value));
  const result = join(dir, 'ui.json');
  const colours = deriveConnectivity(state.cells);
  const dumps = Object.fromEntries([['cell_bg_color', colours.cellBgColor], ['cell_fg_color', colours.cellFgColor]].map(([name, words]) => {
    const path = `${name}.json`;
    writeFileSync(join(dir, path), JSON.stringify({ width: 4, depth: 288, words: Array.from(words as Uint8Array, (v) => `0x${v.toString(16)}`) }));
    return [name, [{ frame: 0, path }]];
  }));
  return { probes, dir, run() { writeFileSync(join(dir, 'report.json'), JSON.stringify({ dumps, monitors: { vga: { frames: [{ index: 0, probes }] } } })); return compareUi(dir, ref, result); }, result() { return JSON.parse(readFileSync(result, 'utf8')); } };
}

describe('UI comparison evidence', () => {
  it('compares right-half selection, value and literal text', () => { const f = fixture(); expect(f.run()).toBe(0); expect(f.result().ok).toBe(true); });
  it.each(['selected_value_bcd', 'selected_value_text_hi', 'value_edit_active'])('fails a differing %s', (name) => {
    const f = fixture(); f.probes[name] = 0; expect(f.run()).toBe(1); expect(f.result().checkpoints[0].differences.join()).toContain(name);
  });
  it('rejects missing UI evidence', () => { const f = fixture(); delete f.probes.selected_value_text_lo; expect(f.run()).toBe(1); });
  it('fails incorrect independent node colours even when UI probes match', () => {
    const f = fixture(); const path = join(f.dir, 'cell_bg_color.json');
    const dump = JSON.parse(readFileSync(path, 'utf8')); dump.words[38] = '0x0'; writeFileSync(path, JSON.stringify(dump));
    expect(f.run()).toBe(1); expect(f.result().checkpoints[0].differences.join()).toContain('cell_bg_color[38]');
  });
});
