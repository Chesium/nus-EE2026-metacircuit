// Browser integration evidence for M2; this does not claim human acceptance.
import { expect, test } from '@playwright/test';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { ASSET_FILES, AssetRenderer, bundleFromRecord } from '../src/render/assetRenderer.ts';
import { makeFramebuffer } from '../src/render/framebuffer.ts';
import { DEFAULT_RENDER_OPTIONS } from '../src/render/renderer.ts';
import { initialState } from '../src/core/state.ts';
import { selectedProperties } from '../src/core/properties.ts';
import { semanticState } from '../src/core/export.ts';
import { step } from '../src/core/step.ts';
import { expandScenario } from '../src/scenario/expand.ts';
import type { Scenario } from '../src/scenario/types.ts';
import { encodePng } from '../src/cli/png.ts';

test('M2 real pointer input matches headless properties and all canvas pixels at every checkpoint', async ({ page }, testInfo) => {
  test.setTimeout(60_000);
  const source = expandScenario(JSON.parse(readFileSync('scenarios/m2_full_ui.json', 'utf8')) as Scenario);
  const assets = Object.fromEntries(ASSET_FILES.map((name) => [name, JSON.parse(readFileSync(`assets/${name}.json`, 'utf8'))]));
  const { bundle, problem } = bundleFromRecord(assets);
  if (!bundle) throw new Error(problem);
  const renderer = new AssetRenderer(bundle);
  const fb = makeFramebuffer();
  const checkpoints = new Map(source.checkpoints.map((cp) => [cp.frame, cp.label]));
  let expected = initialState();

  await page.goto('/');
  await page.getByTestId('screen').waitFor();
  await expect(page.locator('#renderer-badge')).toContainText('renderer: assets');
  await page.evaluate(() => {
    window.__golden.setPaused(true);
    (document.getElementById('btn-reset') as HTMLButtonElement).click();
  });
  const box = (await page.getByTestId('screen').boundingBox())!;
  let held = false;
  for (const [frame, mouse] of source.frames.entries()) {
    await page.mouse.move(box.x + ((mouse.x + 0.5) * box.width) / 640, box.y + ((mouse.y + 0.5) * box.height) / 480);
    if (mouse.left !== held) {
      if (mouse.left) await page.mouse.down();
      else await page.mouse.up();
      held = mouse.left;
    }
    await page.keyboard.press('n');
    expected = step(expected, mouse);
    const label = checkpoints.get(frame);
    if (!label) continue;

    // Panel updates and putImageData are synchronous within draw(). Waiting for
    // its displayed frame guarantees canvas pixels belong to this paused step.
    await expect(page.getByTestId('frame')).toHaveText(String(frame + 1));
    const actual = await page.evaluate(async () => {
      const state = window.__golden.state();
      const slot = state.selectedCell ? state.componentIndexMap[state.selectedCell.row * 18 + state.selectedCell.col]! : 0x1ff;
      const c = state.components[slot] ?? null;
      const canvas = document.querySelector<HTMLCanvasElement>('[data-testid="screen"]')!;
      const pixels = canvas.getContext('2d')!.getImageData(0, 0, 640, 480).data;
      const digest = await crypto.subtle.digest('SHA-256', pixels);
      return {
        semantic: window.__golden.semantic(),
        selectedCell: state.selectedCell,
        editing: state.valueEditActive,
        component: c ? { valueBcd: c.valueBcd, unit: c.unit, displayText: c.displayText } : null,
        hash: Array.from(new Uint8Array(digest), (v) => v.toString(16).padStart(2, '0')).join(''),
      };
    });
    const properties = selectedProperties(expected);
    const c = expected.components[properties.index] ?? null;
    expect(actual.semantic, `${label}: semantic state`).toEqual(semanticState(expected));
    expect(actual.selectedCell, `${label}: property selection`).toEqual(expected.selectedCell);
    expect(actual.editing, `${label}: editing state`).toBe(expected.valueEditActive);
    expect(actual.component, `${label}: selected component value`).toEqual(c ? { valueBcd: c.valueBcd, unit: c.unit, displayText: c.displayText } : null);

    renderer.render(expected, expected.prevMouse, fb, DEFAULT_RENDER_OPTIONS);
    const hash = createHash('sha256').update(fb.data).digest('hex');
    if (actual.hash !== hash) {
      await testInfo.attach(`${label}-expected`, { body: encodePng(fb), contentType: 'image/png' });
      const png = await page.getByTestId('screen').evaluate((el) => (el as HTMLCanvasElement).toDataURL('image/png').split(',')[1]!);
      await testInfo.attach(`${label}-browser`, { body: Buffer.from(png, 'base64'), contentType: 'image/png' });
    }
    expect(actual.hash, `${label}: full 640x480 pixels, including property text, keypad, cursor and node colours`).toBe(hash);
  }
});
