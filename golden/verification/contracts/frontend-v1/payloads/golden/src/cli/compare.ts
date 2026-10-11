import { readFileSync, writeFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { type DumpNames, type RamDump, type SemanticState } from '../core/export.ts';
import { compareCheckpoint } from '../scenario/compare.ts';

interface ReferenceIndex {
  scenario: string;
  frameCount: number;
  names: DumpNames;
  checkpoints: { label: string; frame: number; ram: string; state: string }[];
}
interface FrameReport {
  index: number;
  probes: Record<string, number>;
}
interface Report {
  ok: boolean;
  monitors: Record<string, { frames: FrameReport[] }>;
  dumps: Record<string, { frame: number; path: string }[]>;
  stimulus: { late: boolean }[];
}
const readJson = <T>(path: string): T => JSON.parse(readFileSync(path, 'utf8')) as T;

export function compareRun(runDir: string, referenceDir: string, output?: string): number {
  const reference = readJson<ReferenceIndex>(join(referenceDir, 'checkpoints.json'));
  const report = readJson<Report>(join(runDir, 'report.json'));
  const frames = report.monitors.vga?.frames ?? [];
  const errors: string[] = [];
  if (!report.ok) errors.push('framescope simulation failed');
  if (frames.length !== reference.frameCount) errors.push(`captured ${frames.length} frames, expected ${reference.frameCount}`);
  if (!reference.checkpoints.length) errors.push('reference has no checkpoints');
  if (!report.stimulus || report.stimulus.some((s) => s.late)) errors.push('missing stimulus evidence or late events');
  const checkpoints = reference.checkpoints.map((c) => {
    let differences: string[];
    try {
      const frame = frames.find((f) => f.index === c.frame);
      if (!frame) throw new Error(`missing frame ${c.frame}`);
      const dumps = Object.values(reference.names).flatMap((name) => {
        const entries = report.dumps[name]?.filter((d) => d.frame === c.frame) ?? [];
        return entries.map((d) => readJson<RamDump>(resolve(runDir, d.path)));
      });
      differences = compareCheckpoint({
        frame: c.frame,
        dumps: readJson<RamDump[]>(join(referenceDir, c.ram)),
        semantic: readJson<SemanticState>(join(referenceDir, c.state)),
      }, { frame: frame.index, probes: frame.probes, dumps }, reference.names);
    } catch (error) {
      differences = [`invalid checkpoint evidence: ${String(error)}`];
    }
    return { label: c.label, frame: c.frame, ok: differences.length === 0, differences };
  });
  const result = {
    ok: errors.length === 0 && checkpoints.every((c) => c.ok),
    scenario: reference.scenario,
    actual: resolve(runDir), reference: resolve(referenceDir),
    frameCount: reference.frameCount,
    summary: { checkpoints: checkpoints.length, passed: checkpoints.filter((c) => c.ok).length, failed: checkpoints.filter((c) => !c.ok).length },
    errors, checkpoints,
  };
  writeFileSync(output ?? join(runDir, 'state-compare.json'), JSON.stringify(result, null, 2) + '\n');
  for (const c of checkpoints) {
    process.stdout.write(`${c.ok ? 'PASS' : 'FAIL'} frame ${String(c.frame).padStart(3)} ${c.label}\n`);
    for (const d of c.differences) process.stdout.write(`  ${d}\n`);
  }
  for (const error of errors) process.stdout.write(`ERROR ${error}\n`);
  process.stdout.write(`${result.summary.passed}/${checkpoints.length} checkpoints passed\n`);
  return result.ok ? 0 : 1;
}
