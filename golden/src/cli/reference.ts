import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { DEFAULT_CONFIG, type GoldenConfig } from '../core/config.ts';
import { initialState } from '../core/state.ts';
import { step } from '../core/step.ts';
import { ASSET_FILES, AssetRenderer, bundleFromRecord } from '../render/assetRenderer.ts';
import { makeFramebuffer } from '../render/framebuffer.ts';
import { DEFAULT_RENDER_OPTIONS } from '../render/renderer.ts';
import type { CanonicalScenario } from '../scenario/types.ts';
import { encodePng } from './png.ts';

/** Generate expected pixels from scenario inputs alone, never from RTL captures. */
export function renderReferences(sc: CanonicalScenario, out: string, cfg: GoldenConfig = DEFAULT_CONFIG): void {
  const assets = resolve(dirname(fileURLToPath(import.meta.url)), '../..', 'assets');
  const rec = Object.fromEntries(ASSET_FILES.map((name) => [name, JSON.parse(readFileSync(join(assets, `${name}.json`), 'utf8'))]));
  const { bundle, problem } = bundleFromRecord(rec);
  if (!bundle) throw new Error(problem);
  const renderer = new AssetRenderer(bundle), fb = makeFramebuffer();
  const wanted = new Set(sc.checkpoints.map((c) => c.frame));
  if (!wanted.size) throw new Error('pixel reference requires at least one checkpoint');
  const dir = join(out, 'vga');
  mkdirSync(dir, { recursive: true });
  let state = initialState();
  for (const [frame, mouse] of sc.frames.entries()) {
    state = step(state, mouse, cfg);
    if (!wanted.has(frame)) continue;
    renderer.render(state, state.prevMouse, fb, DEFAULT_RENDER_OPTIONS);
    writeFileSync(join(dir, `frame_${String(frame).padStart(4, '0')}.png`), encodePng(fb));
    writeFileSync(join(dir, `frame_${String(frame).padStart(4, '0')}.ui.json`), JSON.stringify(state, (_key, value) => ArrayBuffer.isView(value) ? Array.from(value as unknown as number[]) : value));
  }
  writeFileSync(join(out, 'pixels.json'), JSON.stringify({ scenario: sc.name, renderer: renderer.name, authoritative: renderer.authoritative, frames: [...wanted].sort((a, b) => a - b) }, null, 2) + '\n');
}
