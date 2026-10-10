// M3 acceptance: independent scenario states -> UART records, solver replies,
// voltage RAM and the display. No RTL-derived state is used as a reference.
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { extractNetlist, type ExtractionResult } from '../backend/netlist.ts';
import { SnapshotIdTracker } from '../backend/snapshot.ts';
import { simulateUartSolver } from '../backend/solve.ts';
import { decodeRecord, encodeError, encodeRecord, encodeVoltages, netlistRecords, type UartRecord } from '../backend/uart.ts';
import { initialState } from '../core/state.ts';
import { step } from '../core/step.ts';
import { expandScenario } from '../scenario/expand.ts';
import type { Scenario } from '../scenario/types.ts';

export interface M3Options {
  buttons?: { frame: number; input: string; value: number }[];
  faults?: boolean;
  requireAborts?: boolean;
  requireStale?: boolean;
}
export type M3Scenario = Scenario & { m3?: M3Options };
interface Line { index: number; text: string; end: string; errors: number; terminated: boolean; t_ms: number; end_t_ms: number }
interface Sent { source: string; text: string; reply_to: number; t_ms: number; end_t_ms: number }
interface Frame { index: number; t_ms: number; probes: Record<string, number> }
interface Report {
  ok: boolean;
  monitors: {
    vga: { frames: Frame[] };
    uart: { lines: Line[]; sent: Sent[]; errors: unknown[]; pending: unknown; stats: { unsent?: unknown[] } };
  };
  stimulus: { late?: boolean }[];
}
const read = <T>(path: string): T => JSON.parse(readFileSync(path, 'utf8')) as T;
const replyText = (r: ExtractionResult): string => {
  const solved = simulateUartSolver(r.netlist);
  return solved.status ? encodeError(solved.frame, solved.status, solved.errorArg) : encodeVoltages(solved);
};

export function compareBackend(scenario: M3Scenario, runDir: string, output: string) {
  const sc = expandScenario(scenario), report = read<Report>(join(runDir, 'report.json'));
  const errors: string[] = [];
  const fail = (message: string) => errors.push(message);
  const frames = report.monitors.vga.frames;
  const uart = report.monitors.uart;
  if (!report.ok || frames.length !== sc.frameCount) fail('failed or incomplete simulation');
  if (!report.stimulus || report.stimulus.some(e => e.late)) fail('missing or late stimulus');
  if (uart.errors.length) fail('UART framing/parity errors');
  const ids = new SnapshotIdTracker(), refs: ExtractionResult[] = [];
  const byId = new Map<number, ExtractionResult>();
  let state = initialState();
  for (const mouse of sc.frames) {
    state = step(state, mouse);
    const ref = extractNetlist(state, { frame: ids.next(state) });
    refs.push(ref); byId.set(ref.netlist.frame, ref);
  }
  // Every complete TX line must be the golden record in the golden order.
  // Snapshots can span frames; the id fixes their content until NE or ER 85.
  let open: { ref: ExtractionResult; next: number } | null = null;
  let completed = 0, aborted = 0, rejected = 0, replies = 0;
  const expectedReplies = new Map<number, string>();
  const seenIds = new Map<number, number>();
  for (const line of uart.lines) {
    if (!line.terminated) continue; // final partial UART byte/line is a capture boundary
    if (line.errors || line.end !== '\r\n') { fail(`TX line ${line.index}: bad framing`); continue; }
    let record: UartRecord;
    try { record = decodeRecord(line.text); } catch (e) { fail(`TX line ${line.index}: ${String(e)}`); continue; }
    const ref = byId.get(record.frame);
    if (!ref) { fail(`TX line ${line.index}: unknown snapshot id ${record.frame}`); continue; }
    const check = (expected: UartRecord) => {
      if (line.text + line.end !== encodeRecord(expected)) fail(`TX line ${line.index}: ${line.text}, expected ${encodeRecord(expected).trim()}`);
    };
    if (record.type === 'NB') {
      if (open) fail(`TX line ${line.index}: new NB without closing previous snapshot`);
      if (ref.rejection) fail(`TX line ${line.index}: rejected netlist was transmitted`);
      check(netlistRecords(ref.netlist)[0]!);
      open = { ref, next: 1 };
    } else if (record.type === 'NC' || record.type === 'NE') {
      if (!open || open.ref.netlist.frame !== record.frame) { fail(`TX line ${line.index}: record without matching NB`); continue; }
      const expected = netlistRecords(open.ref.netlist)[open.next++];
      if (!expected) fail(`TX line ${line.index}: extra component/end`); else check(expected);
      if (record.type === 'NE') {
        if (open.next !== ref.netlist.elements.length + 2) fail(`TX line ${line.index}: missing components`);
        completed++; seenIds.set(record.frame, Math.min(seenIds.get(record.frame) ?? Infinity, line.end_t_ms)); replies++;
        let text = replyText(ref);
        if (scenario.m3?.faults && replies === 1) text += encodeError(0, 4, 0) + '@VB,0000,01,00*00\r\n';
        expectedReplies.set(line.index, text);
        open = null;
      }
    } else if (record.type === 'ER') {
      if (record.code === 0x85) {
        if (!open || open.ref.netlist.frame !== record.frame) fail(`TX line ${line.index}: abort without matching NB`);
        else check({ type: 'ER', frame: record.frame, code: 0x85, arg: open.next - 1 });
        aborted++; open = null;
      } else {
        if (open) fail(`TX line ${line.index}: rejection inside open snapshot`);
        if (!ref.rejection) fail(`TX line ${line.index}: unexpected frontend error`);
        else check({ type: 'ER', frame: record.frame, code: ref.rejection.code, arg: ref.rejection.arg });
        rejected++; seenIds.set(record.frame, Math.min(seenIds.get(record.frame) ?? Infinity, line.end_t_ms));
      }
    } else fail(`TX line ${line.index}: unexpected ${record.type}`);
  }
  if (!completed) fail('no complete netlists');
  if (scenario.m3?.requireAborts && !aborted) fail('scenario did not exercise ER 85');
  const answered = new Set<number>();
  for (const sent of uart.sent) {
    if (sent.source !== 'host') { fail('unexpected non-host RX data'); continue; }
    if (sent.text !== expectedReplies.get(sent.reply_to)) fail(`RX reply to TX line ${sent.reply_to} differs from golden solver`);
    if (answered.has(sent.reply_to)) fail(`duplicate RX reply to TX line ${sent.reply_to}`);
    answered.add(sent.reply_to);
  }
  const endTime = frames.at(-1)!.t_ms;
  for (const line of uart.lines) if (expectedReplies.has(line.index) && line.end_t_ms < endTime - 30 && !answered.has(line.index)) {
    fail(`missing solver reply to TX line ${line.index}`);
  }

  // Independent receive model: process the actual RX wire timing, but only
  // after its bytes have been verified against the golden solver above.
  // IDs become current when extraction commits, rather than at the mouse
  // capture edge. UART headers witness that commit; their content and id have
  // already been checked against the independent golden state. This matters
  // when a reply arrives during the few milliseconds of post-edit flooding.
  const commits = uart.lines.flatMap(line => {
    try {
      const r = decodeRecord(line.text);
      if (r.type === 'NB' || (r.type === 'ER' && r.code !== 0x85)) {
        const frame = frames.findIndex(f => line.t_ms < f.t_ms);
        if (r.frame !== refs[Math.max(0, frame)]!.netlist.frame) fail(`TX header ${line.index}: id does not describe current golden frame`);
        return [{ time: line.t_ms, id: r.frame }];
      }
    } catch { /* recorded as a TX error above */ }
    return [];
  });
  const idAt = (time: number) => {
    let id = 1;
    for (const commit of commits) if (commit.time <= time) id = commit.id;
    return id;
  };
  const receive: { time: number; text: string }[] = [];
  for (const sent of uart.sent) {
    let bytes = 0;
    for (const text of sent.text.split('\r\n').slice(0, -1)) {
      bytes += text.length + 2;
      receive.push({ time: sent.t_ms + bytes * 10 / 115.2, text });
    }
  }
  receive.sort((a, b) => a.time - b.time);
  let rxIndex = 0, valid = 0, replyFrame = 0, status = 0, count = 0, bank = 0, stale = 0;
  const banks = [Array<number>(32).fill(0), Array<number>(32).fill(0)];
  let bits = banks[0]!;
  let stage: { frame: number; count: number; status: number; bits: number[] } | null = null;
  const checkpoints = sc.checkpoints.map(c => {
    const f = frames[c.frame]!, p = f.probes, differences: string[] = [];
    while (rxIndex < receive.length && receive[rxIndex]!.time < f.t_ms - 0.001) {
      const event = receive[rxIndex++]!;
      let r: UartRecord;
      try { r = decodeRecord(event.text); } catch { stage = null; status = 0x83; continue; }
      const current = r.frame === idAt(event.time);
      if (r.type === 'ER') {
        stage = null;
        if (current) { valid = 0; replyFrame = r.frame; status = r.code; } else stale++;
      } else if (r.type === 'VB') {
        if (current) stage = { frame: r.frame, count: r.nodeCount, status: r.status, bits: [] };
        else { stage = null; stale++; }
      } else if (r.type === 'VN' && stage?.frame === r.frame) {
        stage.bits[r.node] = r.valueBits; banks[bank ^ 1]![r.node] = r.valueBits;
      }
      else if (r.type === 'VE' && stage?.frame === r.frame) {
        if (current) {
          valid = 1; replyFrame = stage.frame; status = stage.status; count = stage.count; bank ^= 1; bits = banks[bank]!;
        } else stale++;
        stage = null;
      }
    }
    const eq = (name: string, value: number) => { if (p[name] !== value) differences.push(`${name} ${p[name]}, expected ${value}`); };
    const ref = refs[c.frame]!;
    eq('uart_client', 1); eq('snapshot_id_valid', 1); eq('snapshot_id', ref.netlist.frame);
    if ((seenIds.get(ref.netlist.frame) ?? Infinity) > f.t_ms) differences.push('no completed netlist or rejection by checkpoint');
    eq('reply_valid', valid); eq('reply_frame', replyFrame); eq('reply_status', status); eq('reply_node_count', count); eq('reply_bank', bank);
    eq('reply_stale_count', stale);
    let upper = 0, node = 0;
    for (const b of scenario.m3?.buttons ?? []) if (b.frame <= c.frame && b.value) {
      if (b.input === 'BTNU') upper = 1;
      if (b.input === 'BTND') upper = 0;
      if (b.input === 'BTNL') node = Math.max(0, node - 1);
      if (b.input === 'BTNR') node = Math.min(Math.max(0, count - 1), node + 1);
    }
    eq('reply_view_upper', upper); eq('reply_view_node', node);
    if (bits.length) {
      eq('voltage_node0', bits[0]!);
      eq('seg_value', upper ? bits[node]! >>> 16 : bits[node]! & 0xffff);
      try {
        const words = read<{ words: string[] }>(join(runDir, 'dumps', `voltages_bank${bank}`, `frame_${String(c.frame).padStart(4, '0')}.json`)).words;
        bits.forEach((v, n) => { if (parseInt(words[n]!, 16) !== v) differences.push(`voltage RAM node ${n} differs from golden`); });
      } catch (e) { differences.push(`missing voltage RAM: ${String(e)}`); }
    }
    // LED status, valid, error, view mode and node are semantic. Activity bits
    // [4:2] reflect UART timing and are deliberately tested separately by the
    // report's serial timings rather than inferred from the solver outcome.
    eq('leds', (p.leds! & 0x1c) | (status << 8) | (valid << 7) | (Number(status !== 0) << 6) | (upper << 5) | (node & 3));
    if (ref.rejection) eq('netlist_error_code', ref.rejection.code);
    else {
      try {
        for (const [terminal, name] of [['n0', 'netlist_n0'], ['n1', 'netlist_n1']] as const) {
          const words = read<{ words: string[] }>(join(runDir, 'dumps', name, `frame_${String(c.frame).padStart(4, '0')}.json`)).words;
          ref.netlist.elements.forEach((e, idx) => { if (parseInt(words[idx]!, 16) !== e[terminal]) differences.push(`${name}[${idx}] differs from golden`); });
        }
      } catch (e) { differences.push(`missing extracted-node RAM: ${String(e)}`); }
    }
    return { ...c, snapshotId: ref.netlist.frame, ok: differences.length === 0, differences };
  });
  if (scenario.m3?.requireStale && !stale) fail('scenario did not deliver a stale reply');
  const result = { ok: !errors.length && checkpoints.every(c => c.ok), errors, checkpoints,
    summary: { checkpoints: checkpoints.length, passed: checkpoints.filter(c => c.ok).length, txLines: uart.lines.filter(l => l.terminated).length,
      completed, aborted, rejected, solverReplies: uart.sent.length, staleReplies: stale, captureEndedInsideSnapshot: open !== null, pendingUart: uart.pending !== null } };
  writeFileSync(output, JSON.stringify(result, null, 2) + '\n');
  return result;
}
