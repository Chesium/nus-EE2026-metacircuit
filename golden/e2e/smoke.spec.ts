// Smoke test: load the shell, pick the resistor tool, place one on the canvas,
// and check the side panel. Clicks go through real pointer events on the canvas.
import { expect, test, type Page } from '@playwright/test';
import { readFileSync } from 'node:fs';
import { expandScenario } from '../src/scenario/expand.ts';
import { runScenario } from '../src/scenario/run.ts';
import type { Scenario } from '../src/scenario/types.ts';

/** Click at a 640x480 screen coordinate on the (scaled) canvas. */
async function clickScreen(page: Page, x: number, y: number): Promise<void> {
  const box = (await page.getByTestId('screen').boundingBox())!;
  const px = box.x + ((x + 0.5) * box.width) / 640;
  const py = box.y + ((y + 0.5) * box.height) / 480;
  await page.mouse.move(px, py);
  await page.waitForTimeout(60); // let a few frames sample the new position before pressing
  await page.mouse.down();
  await page.waitForTimeout(60);
  await page.mouse.up();
  await page.waitForTimeout(60);
}

test('select a tool and place a component', async ({ page }) => {
  await page.goto('/');
  const panel = page.getByTestId('panel');
  await expect(page.getByTestId('tool')).toHaveText('pan');
  await expect(page.getByTestId('frame')).not.toHaveText('0'); // the loop is running

  // Resistor button: index 2, x 14..49, y 72 + 2*26 = 124..147.
  await clickScreen(page, 31, 135);
  await expect(page.getByTestId('tool')).toHaveText('resistor');

  // The boot circuit holds 3 components (columns 2-5). Cell (8, 2): centre (64 + 8*32 + 16, 64 + 2*32 + 16) = (336, 144).
  await expect(page.getByTestId('component-count')).toHaveText('3');
  await clickScreen(page, 336, 144);
  await expect(page.getByTestId('component-count')).toHaveText('4');
  await expect(panel.getByTestId('components')).toContainText('(8, 2)');
  await expect(page.getByTestId('cell')).toContainText('(8, 2)');
  await expect(page.getByTestId('cell-sprite')).toContainText('RL');

  const sem = await page.evaluate(() => window.__golden.semantic());
  expect(sem.components).toHaveLength(4);
  expect(sem.components.find((c) => c.col === 8)).toMatchObject({ kind: 'resistor', row: 2, rotation: 0, slot: 3 });
  expect(sem.cells.filter((c) => c.row === 2 && c.col >= 8).map((c) => c.spriteName)).toEqual(['RL', 'RR']);
});

test('replaying the M1 scenario matches the headless run at every checkpoint', async ({ page }) => {
  await page.goto('/');
  await page.getByTestId('screen').waitFor();
  await page.locator('#file-scenario').setInputFiles('scenarios/m1_canvas_tools.json');
  await page.locator('#btn-replay-play').click();
  const cps = page.getByTestId('checkpoints');
  await expect(cps.locator('li')).toHaveCount(25);
  await expect(cps.locator('li.pending')).toHaveCount(0, { timeout: 15_000 });
  await expect(cps.locator('li.mismatch')).toHaveCount(0);
  await expect(cps.locator('li.match')).toHaveCount(25);
});

test('record and download preserves every M1 input frame and checkpoint', async ({ page }, testInfo) => {
  const source = expandScenario(JSON.parse(readFileSync('scenarios/m1_canvas_tools.json', 'utf8')) as Scenario);
  const expected = runScenario(source);
  await page.goto('/');
  await page.getByTestId('screen').waitFor();
  await page.evaluate(() => {
    window.__golden.setPaused(true);
    (document.getElementById('btn-record') as HTMLButtonElement).click();
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
    if (source.checkpoints.some((c) => c.frame === frame)) {
      await page.locator('#btn-mark').evaluate((el) => (el as HTMLButtonElement).click());
      const sem = await page.evaluate(() => window.__golden.semantic());
      expect(sem).toEqual(expected.checkpoints.find((c) => c.frame === frame)!.semantic);
    }
  }
  const downloadPromise = page.waitForEvent('download');
  await page.locator('#btn-download-rec').evaluate((el) => (el as HTMLButtonElement).click());
  const download = await downloadPromise;
  const path = testInfo.outputPath('m1-recorded.json');
  await download.saveAs(path);
  const recorded = expandScenario(JSON.parse(readFileSync(path, 'utf8')) as Scenario);
  expect(recorded.frames).toEqual(source.frames);
  expect(recorded.checkpoints.map((c) => c.frame)).toEqual(source.checkpoints.map((c) => c.frame));
  expect(runScenario(recorded).final).toEqual(expected.final);
});
