// Headless scenario runner: step the golden model through a canonical scenario.

import { DEFAULT_CONFIG, type GoldenConfig } from '../core/config.ts';
import { DEFAULT_DUMP_NAMES, exportRamDumps, semanticState, type DumpNames, type RamDump, type SemanticState } from '../core/export.ts';
import { initialState, type GoldenState } from '../core/state.ts';
import { step } from '../core/step.ts';
import type { CanonicalScenario } from './types.ts';

export interface CheckpointResult {
  label: string;
  frame: number;
  dumps: RamDump[];
  semantic: SemanticState;
}

export interface RunResult {
  final: GoldenState;
  checkpoints: CheckpointResult[];
}

export function runScenario(
  sc: CanonicalScenario,
  cfg: GoldenConfig = DEFAULT_CONFIG,
  names: DumpNames = DEFAULT_DUMP_NAMES,
): RunResult {
  let s = initialState();
  const byFrame = new Map<number, string[]>();
  for (const c of sc.checkpoints) byFrame.set(c.frame, [...(byFrame.get(c.frame) ?? []), c.label]);
  const checkpoints: CheckpointResult[] = [];
  sc.frames.forEach((m, frame) => {
    s = step(s, m, cfg);
    for (const label of byFrame.get(frame) ?? []) {
      checkpoints.push({ label, frame, dumps: exportRamDumps(s, names, frame), semantic: semanticState(s, frame) });
    }
  });
  return { final: s, checkpoints };
}
