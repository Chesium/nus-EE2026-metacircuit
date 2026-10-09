// Independent cell diagnostics for verify_m2.py. Run with:
// node --import tsx tools/decode_pixels.ts manifest.json [-o result.json]
// PNG decoding stays in framescope; this tool consumes raw RGBA8888 captures.
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { parseArgs } from 'node:util';
import { fileURLToPath } from 'node:url';
import {
  type DecoderCanvasAssets, type DecoderCursorAssets, type VisibleDecodeOptions, VisibleCellDecoder, diffVisibleCells,
} from '../src/render/decoder.ts';

interface DiagnosticFrame extends VisibleDecodeOptions {
  frame: number;
  actualRaw: string;
  referenceRaw: string;
  width: number;
  height: number;
}

interface DiagnosticManifest { assetsDir?: string; frames: DiagnosticFrame[] }

const { values, positionals } = parseArgs({
  allowPositionals: true,
  options: { output: { type: 'string', short: 'o' } },
});
if (positionals.length !== 1) throw new Error('usage: decode_pixels.ts manifest.json [-o result.json]');
const manifestPath = resolve(positionals[0]!);
const manifestDir = dirname(manifestPath);
const manifest = JSON.parse(readFileSync(manifestPath, 'utf8')) as DiagnosticManifest;
if (!Array.isArray(manifest.frames) || !manifest.frames.length) throw new Error('pixel diagnostic manifest requires at least one frame');
const assetsDir = manifest.assetsDir
  ? resolve(manifestDir, manifest.assetsDir)
  : resolve(dirname(fileURLToPath(import.meta.url)), '../assets');
const canvas = JSON.parse(readFileSync(resolve(assetsDir, 'canvas.json'), 'utf8')) as DecoderCanvasAssets;
const cursor = JSON.parse(readFileSync(resolve(assetsDir, 'cursor.json'), 'utf8')) as DecoderCursorAssets;
const decoder = new VisibleCellDecoder(canvas, cursor);
const seen = new Set<number>();
const frames = manifest.frames.map((entry) => {
  if (!Number.isInteger(entry.frame) || entry.frame < 0 || seen.has(entry.frame)) throw new Error(`invalid or duplicate diagnostic frame ${entry.frame}`);
  seen.add(entry.frame);
  const opts: VisibleDecodeOptions = {
    panX: entry.panX, panY: entry.panY, mouse: entry.mouse, drawCursor: entry.drawCursor,
    excludeRects: entry.excludeRects,
    // Sprite recovery ignores the flow overlay. The separate pixel compare
    // remains exact and must not inherit this diagnostic-only mask.
    maskColors: [0xff0],
  };
  const raw = (path: string) => ({ width: entry.width, height: entry.height, data: readFileSync(resolve(manifestDir, path)) });
  const reference = decoder.decode(raw(entry.referenceRaw), opts);
  const actual = decoder.decode(raw(entry.actualRaw), opts);
  const errors = diffVisibleCells(reference, actual);
  const unknownErrors = [...reference.errors.map((e) => `reference: ${e}`), ...actual.errors.map((e) => `actual: ${e}`)];
  return { frame: entry.frame, ok: errors.length === 0 && unknownErrors.length === 0, errors, unknownErrors, reference, actual };
});
const result = {
  ok: frames.every((f) => f.ok), frames,
  summary: { frames: frames.length, failed: frames.filter((f) => !f.ok).length, mismatchedCells: frames.reduce((n, f) => n + f.errors.length, 0) },
};
const output = JSON.stringify(result, null, 2) + '\n';
if (values.output) writeFileSync(values.output, output);
else process.stdout.write(output);
process.exitCode = result.ok ? 0 : 1;
