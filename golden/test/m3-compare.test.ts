import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { afterEach, expect, it } from 'vitest';
import { compareBackend, type M3Scenario } from '../src/cli/compare-backend.ts';
import { extractNetlist } from '../src/backend/netlist.ts';
import { initialState } from '../src/core/state.ts';
import { simulateUartSolver } from '../src/backend/solve.ts';
import { encodeNetlist, encodeVoltages } from '../src/backend/uart.ts';
const folders: string[] = [];
afterEach(() => { for (const folder of folders.splice(0)) rmSync(folder, { recursive: true, force: true }); });
const scenario: M3Scenario = { name: 'boot', steps: ['wait 2', 'checkpoint boot'] };
function fixture() {
  const folder = mkdtempSync(join(tmpdir(), 'm3-compare-')); folders.push(folder);
  const n = extractNetlist(initialState(), { frame: 1 }).netlist;
  const lines = encodeNetlist(n).trimEnd().split('\r\n').map((text, index) => ({ index, text, end: '\r\n', errors: 0, terminated: true, t_ms: index * 0.2, end_t_ms: index * 0.2 + 0.1 }));
  const report = { ok: true, stimulus: [], monitors: {
    vga: { frames: [20, 40].map((t_ms, index) => ({ index, t_ms, probes: {
      uart_client: 1, snapshot_id_valid: 1, snapshot_id: 1, reply_valid: 1, reply_frame: 1, reply_status: 0,
      reply_node_count: 1, reply_bank: 1, reply_stale_count: 0, reply_view_upper: 0, reply_view_node: 0,
      voltage_node0: 0x41200000, seg_value: 0, leds: 128,
    } })) },
    uart: { lines, sent: [{ source: 'host', text: encodeVoltages(simulateUartSolver(n)), reply_to: 4, t_ms: 2, end_t_ms: 7.46875 }], errors: [], pending: null, stats: {} },
  } };
  for (const [name, words] of Object.entries({ voltages_bank1: ['41200000', ...Array<string>(31).fill('00000000')], netlist_n0: ['00', 'FF', 'FF'], netlist_n1: ['FF', '00', '00'] })) {
    mkdirSync(join(folder, 'dumps', name), { recursive: true });
    writeFileSync(join(folder, 'dumps', name, 'frame_0001.json'), JSON.stringify({ words }));
  }
  const run = () => {
    writeFileSync(join(folder, 'report.json'), JSON.stringify(report));
    return compareBackend(scenario, folder, join(folder, 'compare.json'));
  };
  return { report, run, folder };
}
it('accepts independently predicted UART, solver bits, voltage RAM and display', () => {
  expect(fixture().run().ok).toBe(true);
});
it('fails a changed netlist line even with a valid checksum', () => {
  const f = fixture();
  f.report.monitors.uart.lines[1]!.text = '@NC,0001,00,03,FF,00,010,00*12';
  expect(f.run().errors.join('\n')).toContain('expected @NC');
});
it('fails an incorrect solver response and missing reply evidence', () => {
  const f = fixture();
  f.report.monitors.uart.sent[0]!.text = f.report.monitors.uart.sent[0]!.text.replace('41200000*32', '40A00000*42');
  expect(f.run().errors.join('\n')).toContain('differs from golden solver');
  f.report.monitors.uart.sent = [];
  expect(f.run().errors.join('\n')).toContain('missing solver reply');
});
it('fails incorrect snapshot, displayed value and voltage RAM', () => {
  const f = fixture(), p = f.report.monitors.vga.frames[1]!.probes;
  p.snapshot_id = 2; p.seg_value = 1;
  writeFileSync(join(f.folder, 'dumps', 'voltages_bank1', 'frame_0001.json'), JSON.stringify({ words: Array<string>(32).fill('40A00000') }));
  const result = f.run();
  expect(result.ok).toBe(false);
  expect(result.checkpoints[0]!.differences).toEqual(expect.arrayContaining([
    'snapshot_id 2, expected 1', 'seg_value 1, expected 0', 'voltage RAM node 0 differs from golden',
  ]));
});
