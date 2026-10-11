// `golden netlist`: golden netlist references (GM-8) for M3, from scenario inputs
// alone, mirroring reference.ts for pixels. `golden uart-decode`: parse a UART
// capture (e.g. the RTL's RsTx text) into snapshots for comparison.

import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { extractNetlist, snapshotUart, type ExtractOptions, type ExtractionResult } from '../backend/netlist.ts';
import { NETLIST_SNAPSHOT_STATE_LAG_FRAMES, SnapshotIdTracker } from '../backend/snapshot.ts';
import { parseUartStream } from '../backend/uart.ts';
import { DEFAULT_CONFIG, type GoldenConfig } from '../core/config.ts';
import { initialState } from '../core/state.ts';
import { step } from '../core/step.ts';
import type { CanonicalScenario } from '../scenario/types.ts';

export interface NetlistPoint { label: string; frame: number }

export interface NetlistReference extends NetlistPoint {
  /** Snapshot id (D-016), also the netlist's `frame` field unless opts.frame overrides it. */
  snapshotId: number;
  /** Frame during which the frontend transmits this snapshot (frame + NETLIST_SNAPSHOT_STATE_LAG_FRAMES). */
  txFrame: number;
  result: ExtractionResult;
  uart: string;
}

/** Netlists of the golden state at the given points (default: the scenario's
 * checkpoints). The `frame` field is the snapshot id (D-016): 0001 at the first
 * frame, plus one for every frame whose netlist-relevant content changed. */
export function netlistReferences(
  sc: CanonicalScenario, cfg: GoldenConfig = DEFAULT_CONFIG, points: readonly NetlistPoint[] = sc.checkpoints,
  opts: ExtractOptions = {},
): NetlistReference[] {
  const byFrame = new Map<number, NetlistPoint[]>();
  for (const p of points) {
    if (!Number.isInteger(p.frame) || p.frame < 0 || p.frame >= sc.frames.length) {
      throw new Error(`frame ${p.frame} is outside the scenario (0..${sc.frames.length - 1})`);
    }
    byFrame.set(p.frame, [...(byFrame.get(p.frame) ?? []), p]);
  }
  const out: NetlistReference[] = [];
  const ids = new SnapshotIdTracker();
  let state = initialState();
  sc.frames.forEach((mouse, frame) => {
    state = step(state, mouse, cfg);
    const snapshotId = ids.next(state);
    for (const p of byFrame.get(frame) ?? []) {
      const result = extractNetlist(state, { ...opts, frame: opts.frame ?? snapshotId });
      out.push({ ...p, snapshotId, txFrame: frame + NETLIST_SNAPSHOT_STATE_LAG_FRAMES, result, uart: snapshotUart(result) });
    }
  });
  return out;
}

/** JSON form of an extraction: the netlist plus the evidence behind it. */
export function extractionJson(r: ExtractionResult): unknown {
  return {
    netlist: r.netlist,
    rejection: r.rejection,
    issues: r.issues,
    regionCount: r.regionCount,
    groundRegions: r.groundRegions,
    rowOfRegion: r.rowOfRegion,
    elements: r.elements,
  };
}

/** Write <NN>_<label>.netlist.json / .uart per point and an index netlists.json. */
export function writeNetlistReferences(sc: CanonicalScenario, out: string, refs: readonly NetlistReference[]): void {
  mkdirSync(out, { recursive: true });
  const index = refs.map((r, i) => {
    const stem = `${String(i).padStart(2, '0')}_${r.label.replace(/[^\w.-]+/g, '_')}`;
    writeFileSync(join(out, `${stem}.netlist.json`), JSON.stringify({
      label: r.label, frame: r.frame, snapshotId: r.snapshotId, txFrame: r.txFrame, ...extractionJson(r.result) as object,
    }, null, 1) + '\n');
    writeFileSync(join(out, `${stem}.netlist.uart`), r.uart);
    return {
      label: r.label, frame: r.frame, snapshotId: r.snapshotId, txFrame: r.txFrame,
      json: `${stem}.netlist.json`, uart: `${stem}.netlist.uart`,
      elements: r.result.netlist.elements.length, nodeCount: r.result.netlist.nodeCount,
      rejected: r.result.rejection !== null, issues: r.result.issues.map((x) => x.type),
    };
  });
  writeFileSync(join(out, 'netlists.json'), JSON.stringify({
    scenario: sc.name, frameCount: sc.frameCount, snapshotStateLagFrames: NETLIST_SNAPSHOT_STATE_LAG_FRAMES, netlists: index,
  }, null, 1) + '\n');
}

/** Parse a comma-separated frame list into points labelled frame_NNNN. */
export function parseFrameList(text: string): NetlistPoint[] {
  return text.split(',').filter((s) => s.trim()).map((s) => {
    const frame = Number(s.trim());
    if (!Number.isInteger(frame) || frame < 0) throw new Error(`invalid frame ${JSON.stringify(s)}`);
    return { label: `frame_${String(frame).padStart(4, '0')}`, frame };
  });
}

/** Decode a UART capture file to JSON (voltages as numbers and float32 bits). */
export function decodeUartCapture(path: string): unknown {
  const parsed = parseUartStream(readFileSync(path, 'latin1'));
  return {
    netlists: parsed.netlists,
    voltages: parsed.voltages.map((v) => ({
      frame: v.frame, status: v.status, voltages: Array.from(v.voltages),
      bits: Array.from(new Uint32Array(v.voltages.buffer, v.voltages.byteOffset, v.voltages.length), (b) => b.toString(16).toUpperCase().padStart(8, '0')),
    })),
    errors: parsed.errors,
    problems: parsed.problems,
  };
}
