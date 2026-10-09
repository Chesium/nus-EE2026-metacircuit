import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';

describe('pixel decoder diagnostics CLI', () => {
  it('reads relative raw RGBA files and reports corruption with a failing status', () => {
    const dir = mkdtempSync(join(tmpdir(), 'golden-decoder-'));
    try {
      const raw = Buffer.alloc(640 * 480 * 4);
      for (let i = 0; i < raw.length; i += 4) { raw[i] = 0x22; raw[i + 1] = 0x22; raw[i + 2] = 0x22; raw[i + 3] = 255; }
      writeFileSync(join(dir, 'reference.rgba'), raw);
      writeFileSync(join(dir, 'actual.rgba'), raw);
      const manifest = join(dir, 'manifest.json');
      const output = join(dir, 'diagnostic.json');
      writeFileSync(manifest, JSON.stringify({ frames: [{ frame: 7, width: 640, height: 480, referenceRaw: 'reference.rgba', actualRaw: 'actual.rgba' }] }));
      const run = () => spawnSync(process.execPath, ['--import', 'tsx', 'tools/decode_pixels.ts', manifest, '-o', output], { encoding: 'utf8' });
      expect(run().status).toBe(0);
      expect(JSON.parse(readFileSync(output, 'utf8')).summary).toEqual({ frames: 1, failed: 0, mismatchedCells: 0 });
      const offset = ((64 + 3 * 32 + 10) * 640 + 64 + 2 * 32 + 10) * 4;
      raw[offset] = 255; raw[offset + 1] = 0; raw[offset + 2] = 0;
      writeFileSync(join(dir, 'actual.rgba'), raw);
      expect(run().status).toBe(1);
      const result = JSON.parse(readFileSync(output, 'utf8'));
      expect(result.ok).toBe(false);
      expect(result.frames[0].errors[0]).toContain('cell (2,3) has 1 unclassified actual pixels');
    } finally { rmSync(dir, { recursive: true, force: true }); }
  });
});
