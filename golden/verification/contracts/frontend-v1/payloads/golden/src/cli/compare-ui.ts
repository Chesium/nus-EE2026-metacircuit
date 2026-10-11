import { readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { deriveConnectivity } from '../core/connectivity.ts';
import { selectedProperties } from '../core/properties.ts';
import type { GoldenState } from '../core/state.ts';

export function compareUi(run: string, reference: string, output: string): number {
  const report = JSON.parse(readFileSync(join(run, 'report.json'), 'utf8'));
  const index = JSON.parse(readFileSync(join(reference, 'pixels.json'), 'utf8'));
  const checkpoints = (index.frames as number[]).map((frame) => {
    const differences: string[] = [];
    try {
      const state = JSON.parse(readFileSync(join(reference, 'vga', `frame_${String(frame).padStart(4, '0')}.ui.json`), 'utf8')) as GoldenState;
      const expected = selectedProperties(state);
      const p = report.monitors.vga.frames.find((f: { index: number }) => f.index === frame)?.probes;
      if (!p) throw new Error(`missing frame ${frame} UI probes`);
      const check = (name: string, value: number) => {
        if (!Number.isSafeInteger(p[name])) differences.push(`missing/invalid ${name}`);
        else if (p[name] !== value) differences.push(`${name}: ${p[name]}, expected ${value}`);
      };
      check('has_selection', Number(expected.hasSelection));
      check('value_edit_active', Number(state.valueEditActive));
      if (expected.hasSelection) {
        check('selected_cell_i', expected.col); check('selected_cell_j', expected.row);
        check('selected_component_valid', Number(expected.index >= 0));
        check('selected_value_bcd', expected.valueBcd); check('selected_value_unit', expected.unit);
        check('selected_component_type', expected.kind);
        check('selected_value_text_len', expected.valueText.length);
        const text = Buffer.alloc(8); text.write(expected.valueText, 0, 'ascii');
        check('selected_value_text_hi', text.readUInt32BE(0)); check('selected_value_text_lo', text.readUInt32BE(4));
      }
      const colours = deriveConnectivity(state.cells);
      for (const [name, words] of [['cell_bg_color', colours.cellBgColor], ['cell_fg_color', colours.cellFgColor]] as const) {
        const entry = report.dumps?.[name]?.find((d: { frame: number }) => d.frame === frame);
        if (!entry) throw new Error(`missing ${name} dump at frame ${frame}`);
        const dump = JSON.parse(readFileSync(resolve(run, entry.path), 'utf8'));
        if (dump.width !== 4 || dump.depth !== words.length || !Array.isArray(dump.words) || dump.words.length !== words.length) throw new Error(`malformed ${name} dump`);
        for (let address = 0; address < words.length; address++) {
          // Foreground is meaningful only where an enabled sprite consumes it.
          if (name === 'cell_fg_color' && !(state.cells[address]! & 1)) continue;
          const value = dump.words[address];
          if (typeof value !== 'string' || !/^0x[0-9a-f]$/i.test(value)) throw new Error(`invalid ${name}[${address}]`);
          if (Number.parseInt(value.slice(2), 16) !== words[address]) differences.push(`${name}[${address}]: ${value}, expected 0x${words[address]!.toString(16)}`);
        }
      }
    } catch (error) { differences.push(String(error)); }
    return { frame, ok: differences.length === 0, differences };
  });
  const result = { ok: checkpoints.length > 0 && checkpoints.every((c) => c.ok), checkpoints };
  writeFileSync(output, JSON.stringify(result, null, 2) + '\n');
  for (const c of checkpoints.filter((c) => !c.ok)) process.stdout.write(`UI FAIL frame ${c.frame}: ${c.differences.join('; ')}\n`);
  return result.ok ? 0 : 1;
}
