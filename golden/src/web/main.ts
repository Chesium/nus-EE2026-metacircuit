/// <reference types="vite/client" />
// Web shell (early SC-3 slice): drives the golden core with real mouse input,
// one snapshot per 60 Hz frame, and records/replays sessions as scenarios.

import {
  COMPONENT_KIND_NAMES, GRID_W, SCREEN_H, SCREEN_W, TOOL_NAMES, Tool, WIRE_VARIANT_NAMES, kindFromSprite, modeSelect,
} from '../core/constants.ts';
import { DEFAULT_CONFIG } from '../core/config.ts';
import { describeCell, formatValue, toHex } from '../core/encoding.ts';
import { componentWord, diffSemantic, exportRamDumps, semanticState, type SemanticState } from '../core/export.ts';
import { screenToCell } from '../core/geometry.ts';
import { defaultMouse, initialState, liveComponents, type GoldenState, type MouseSnapshot } from '../core/state.ts';
import { step } from '../core/step.ts';
import { expandScenario, framesToScenario } from '../scenario/expand.ts';
import { runScenario } from '../scenario/run.ts';
import type { CanonicalScenario, Checkpoint, Scenario } from '../scenario/types.ts';
import { makeFramebuffer } from '../render/framebuffer.ts';
import { AssetRenderer, bundleFromRecord } from '../render/assetRenderer.ts';
import { PlaceholderRenderer } from '../render/placeholder.ts';
import { DEFAULT_RENDER_OPTIONS, type Renderer } from '../render/renderer.ts';

const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;
const FRAME_MS = 1000 / 60;

// ---------------------------------------------------------------- state

let state: GoldenState = initialState();
let paused = false;

type Mode = 'live' | 'replay';
let mode: Mode = 'live';

// Live mouse: latest position and buttons, plus presses that happened since the last sample.
const live = { x: SCREEN_W / 2, y: SCREEN_H / 2, buttons: { left: false, middle: false, right: false } };
const pressedSince = { left: false, middle: false, right: false };

// Recording.
let recording: { frames: MouseSnapshot[]; checkpoints: Checkpoint[] } | null = null;
let lastRecording: { frames: MouseSnapshot[]; checkpoints: Checkpoint[] } | null = null;

// Replay.
interface Replay {
  sc: CanonicalScenario;
  index: number;
  playing: boolean;
  expected: Map<string, SemanticState>;
  results: Map<string, string[]>; // label -> diffs (empty = match)
}
let replay: Replay | null = null;

// Renderers: the GM-4 asset renderer when golden/assets/*.json exist, else placeholder graphics.
const assetJson = import.meta.glob('../../assets/*.json', { eager: true, import: 'default' }) as Record<string, unknown>;
const assetRecord = Object.fromEntries(
  Object.entries(assetJson).map(([path, json]) => [path.replace(/^.*\/|\.json$/g, ''), json]),
);
const assetLoad = bundleFromRecord(assetRecord);
const renderers: Renderer[] = [];
if (assetLoad.bundle) {
  try {
    renderers.push(new AssetRenderer(assetLoad.bundle));
  } catch (err) {
    console.warn('asset renderer failed, using placeholder graphics', err);
  }
} else {
  console.info(`asset renderer unavailable: ${assetLoad.problem}`);
}
renderers.push(new PlaceholderRenderer());
let renderer: Renderer = renderers[0]!;
const fb = makeFramebuffer();
const canvas = $<HTMLCanvasElement>('screen');
const ctx = canvas.getContext('2d')!;
const image = ctx.createImageData(SCREEN_W, SCREEN_H);

// ---------------------------------------------------------------- mouse input

const BUTTON_NAMES = ['left', 'middle', 'right'] as const;

function toScreen(e: PointerEvent): { x: number; y: number } {
  const r = canvas.getBoundingClientRect();
  const x = Math.floor(((e.clientX - r.left) * SCREEN_W) / r.width);
  const y = Math.floor(((e.clientY - r.top) * SCREEN_H) / r.height);
  return { x: Math.min(Math.max(x, 0), SCREEN_W - 1), y: Math.min(Math.max(y, 0), SCREEN_H - 1) };
}

canvas.addEventListener('pointermove', (e) => {
  Object.assign(live, toScreen(e));
});
canvas.addEventListener('pointerdown', (e) => {
  Object.assign(live, toScreen(e));
  const b = BUTTON_NAMES[e.button];
  if (b) {
    live.buttons[b] = true;
    pressedSince[b] = true;
  }
  canvas.setPointerCapture(e.pointerId);
  e.preventDefault();
});
canvas.addEventListener('pointerup', (e) => {
  Object.assign(live, toScreen(e));
  const b = BUTTON_NAMES[e.button];
  if (b) live.buttons[b] = false;
});
canvas.addEventListener('contextmenu', (e) => e.preventDefault());
canvas.addEventListener('auxclick', (e) => e.preventDefault());

function sampleLive(): MouseSnapshot {
  const snap: MouseSnapshot = {
    x: live.x,
    y: live.y,
    left: live.buttons.left || pressedSince.left,
    middle: live.buttons.middle || pressedSince.middle,
    right: live.buttons.right || pressedSince.right,
  };
  pressedSince.left = pressedSince.middle = pressedSince.right = false;
  return snap;
}

// ---------------------------------------------------------------- stepping

function stepOnce(): void {
  let snap: MouseSnapshot;
  if (mode === 'replay' && replay) {
    if (replay.index >= replay.sc.frameCount) {
      replay.playing = false;
      return;
    }
    snap = replay.sc.frames[replay.index]!;
  } else {
    snap = sampleLive();
  }
  const frame = state.frame;
  state = step(state, snap, DEFAULT_CONFIG);
  if (recording) recording.frames.push(snap);
  if (mode === 'replay' && replay) {
    replay.index += 1;
    for (const cp of replay.sc.checkpoints) {
      if (cp.frame === frame) {
        const exp = replay.expected.get(cp.label)!;
        replay.results.set(cp.label, diffSemantic(exp, semanticState(state, frame), { ignoreCellMeta: false, ignoreSlots: false }));
      }
    }
    if (replay.index >= replay.sc.frameCount) replay.playing = false;
  }
}

function running(): boolean {
  return mode === 'replay' ? !!replay?.playing : !paused;
}

let acc = 0;
let lastT: number | null = null;
function tick(t: number): void {
  if (lastT === null) lastT = t;
  acc += t - lastT;
  lastT = t;
  if (acc > FRAME_MS * 4) acc = FRAME_MS * 4; // tab was hidden or the machine stalled
  while (acc >= FRAME_MS) {
    acc -= FRAME_MS;
    if (running()) stepOnce();
  }
  draw();
  requestAnimationFrame(tick);
}

// ---------------------------------------------------------------- drawing

function draw(): void {
  // Draw the mouse the model has applied (with the 1-frame latency, the previous
  // frame's sample), as the RTL does for the cursor, hover and toolbar press.
  const mouse: MouseSnapshot = state.prevMouse;
  renderer.render(state, mouse, fb, DEFAULT_RENDER_OPTIONS);
  image.data.set(fb.data);
  ctx.putImageData(image, 0, 0);
  updatePanel(mouse);
}

let lastPanelKey = '';
function updatePanel(mouse: MouseSnapshot): void {
  const comps = liveComponents(state);
  const key = `${state.frame}|${mouse.x},${mouse.y},${+mouse.left}${+mouse.middle}${+mouse.right}|${mode}|${paused}|${replay?.playing}|${recording?.checkpoints.length}`;
  if (key === lastPanelKey) return;
  lastPanelKey = key;

  $('v-frame').textContent = String(state.frame);
  $('v-mode').textContent =
    mode === 'replay'
      ? `replay ${replay!.index}/${replay!.sc.frameCount}${replay!.playing ? '' : ' (paused)'}`
      : `live${paused ? ' (paused)' : ''}${recording ? ', recording' : ''}`;
  const toolName = TOOL_NAMES[state.tool];
  $('v-tool').textContent = state.tool === Tool.Wire ? `${toolName} / ${WIRE_VARIANT_NAMES[state.wireVariant & 3]}` : toolName;
  $('v-modecode').textContent = `0x${modeSelect(state.tool, state.wireVariant).toString(16).toUpperCase()}`;
  $('v-pan').textContent = `(${state.panX}, ${state.panY})`;
  $('v-mouse').textContent = `(${mouse.x}, ${mouse.y}) ${mouse.left ? 'L' : '-'}${mouse.middle ? 'M' : '-'}${mouse.right ? 'R' : '-'}`;

  const cell = screenToCell(mouse.x, mouse.y, state.panX, state.panY);
  if (cell) {
    const addr = cell.row * GRID_W + cell.col;
    const d = describeCell(state.cells[addr]!);
    const slot = state.componentIndexMap[addr]!;
    $('v-cell').textContent = `(${cell.col}, ${cell.row}) addr ${addr}`;
    $('v-cellword').textContent = d.word;
    $('v-cellsprite').textContent = d.enabled ? `${d.spriteName} (id ${d.sprite}), rot ${d.rotation}` : 'empty';
    $('v-cellcomp').textContent = slot === 0x1ff ? 'none (0x1ff)' : `slot ${slot}`;
  } else {
    for (const id of ['v-cell', 'v-cellword', 'v-cellsprite', 'v-cellcomp']) $(id).textContent = '-';
    $('v-cell').textContent = 'outside canvas';
  }

  $('v-compcount').textContent = String(comps.length);
  $('comp-body').innerHTML = comps
    .map(({ slot, c }) => {
      const kind = COMPONENT_KIND_NAMES[kindFromSprite(c.leftSprite)];
      return `<tr><td>${slot}</td><td>${kind}</td><td>(${c.col}, ${c.row})</td><td>${c.rotation}</td><td>${formatValue(c.valueBcd, c.unit)}</td><td>${toHex(componentWord(c, slot), 40)}</td></tr>`;
    })
    .join('');

  $('replay-box').hidden = !replay;
  if (replay) {
    $('v-replay-name').textContent = replay.sc.name;
    $('cp-list').innerHTML = replay.sc.checkpoints
      .map((cp) => {
        const res = replay!.results.get(cp.label);
        const cls = res === undefined ? 'pending' : res.length === 0 ? 'match' : 'mismatch';
        const txt = res === undefined ? 'pending' : res.length === 0 ? 'match' : `MISMATCH: ${res.slice(0, 3).join('; ')}`;
        return `<li class="${cls}" title="frame ${cp.frame}">${escapeHtml(cp.label)} @${cp.frame}: ${escapeHtml(txt)}</li>`;
      })
      .join('');
  }
  $('rec-box').hidden = !recording;
  if (recording) {
    $('v-rec-frames').textContent = String(recording.frames.length);
    $('v-rec-cps').textContent = String(recording.checkpoints.length);
  }
  syncButtons();
}

function escapeHtml(s: string): string {
  return s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[c]!);
}

// ---------------------------------------------------------------- controls

function syncButtons(): void {
  $('btn-pause').textContent = paused ? 'Resume' : 'Pause';
  ($('btn-pause') as HTMLButtonElement).disabled = mode === 'replay';
  ($('btn-step') as HTMLButtonElement).disabled = mode === 'replay' || !paused;
  $('btn-record').textContent = recording ? 'Stop recording' : 'Record';
  $('btn-record').classList.toggle('active', !!recording);
  ($('btn-record') as HTMLButtonElement).disabled = mode === 'replay';
  ($('btn-mark') as HTMLButtonElement).disabled = !recording;
  ($('btn-download-rec') as HTMLButtonElement).disabled = !lastRecording && !recording;
  ($('btn-replay-play') as HTMLButtonElement).disabled = !replay || replay.index >= replay.sc.frameCount;
  $('btn-replay-play').textContent = replay?.playing ? 'Pause' : 'Play';
  ($('btn-replay-step') as HTMLButtonElement).disabled = !replay || replay.playing || replay.index >= replay.sc.frameCount;
  ($('btn-live') as HTMLButtonElement).disabled = mode !== 'replay';
}

function reset(): void {
  state = initialState();
  lastPanelKey = '';
}

function download(name: string, text: string): void {
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([text], { type: 'application/json' }));
  a.download = name;
  a.click();
  setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}

function togglePause(): void {
  if (mode !== 'live') return;
  paused = !paused;
  lastPanelKey = '';
}
function stepIfPaused(): void {
  if (mode === 'live' && paused) {
    stepOnce();
    lastPanelKey = '';
  }
}
function markCheckpoint(): void {
  if (!recording || recording.frames.length === 0) return;
  const frame = recording.frames.length - 1;
  recording.checkpoints = recording.checkpoints.filter((c) => c.frame !== frame);
  recording.checkpoints.push({ label: `cp${recording.checkpoints.length + 1}_f${frame}`, frame });
  lastPanelKey = '';
}

$('btn-pause').addEventListener('click', togglePause);
$('btn-step').addEventListener('click', stepIfPaused);
$('btn-reset').addEventListener('click', () => {
  if (mode === 'replay') leaveReplay();
  recording = null;
  reset();
});
$('btn-record').addEventListener('click', () => {
  if (recording) {
    lastRecording = recording;
    recording = null;
  } else {
    reset();
    recording = { frames: [], checkpoints: [] };
  }
  lastPanelKey = '';
});
$('btn-mark').addEventListener('click', markCheckpoint);
$('btn-download-rec').addEventListener('click', () => {
  const rec = recording ?? lastRecording;
  if (!rec) return;
  const stamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const sc = framesToScenario(`session_${stamp}`, rec.frames, rec.checkpoints, defaultMouse(), 'Recorded in the golden web shell.');
  download(`${sc.name}.json`, JSON.stringify(sc, null, 2) + '\n');
});
$<HTMLInputElement>('file-scenario').addEventListener('change', async (e) => {
  const input = e.target as HTMLInputElement;
  const file = input.files?.[0];
  input.value = '';
  if (!file) return;
  try {
    loadScenario(JSON.parse(await file.text()) as Scenario);
  } catch (err) {
    alert(`Could not load scenario: ${(err as Error).message}`);
  }
});
$('btn-replay-play').addEventListener('click', () => {
  if (!replay) return;
  replay.playing = !replay.playing;
  lastPanelKey = '';
});
$('btn-replay-step').addEventListener('click', () => {
  if (replay && !replay.playing) {
    stepOnce();
    lastPanelKey = '';
  }
});
$('btn-live').addEventListener('click', leaveReplay);
$('btn-dump').addEventListener('click', () => {
  const frame = state.frame - 1;
  download(
    `golden_state_f${frame}.json`,
    JSON.stringify({ ram: exportRamDumps(state), semantic: semanticState(state) }, null, 1) + '\n',
  );
});
$<HTMLInputElement>('chk-cursor').addEventListener('change', (e) => {
  canvas.classList.toggle('os-cursor', (e.target as HTMLInputElement).checked);
});
function setScale(scale: number): void {
  canvas.style.width = `${SCREEN_W * scale}px`;
  const col = canvas.closest<HTMLElement>('.screen-col')!;
  col.style.maxWidth = col.style.flexBasis = `${SCREEN_W * scale + 2}px`;
}
$<HTMLSelectElement>('sel-scale').addEventListener('change', (e) => setScale(Number((e.target as HTMLSelectElement).value)));

window.addEventListener('keydown', (e) => {
  if (e.target instanceof HTMLInputElement || e.target instanceof HTMLSelectElement) return;
  if (e.code === 'Space') {
    e.preventDefault();
    if (mode === 'replay' && replay) replay.playing = !replay.playing;
    else togglePause();
    lastPanelKey = '';
  } else if (e.key === 'n' || e.key === 'N' || e.key === '.') {
    if (mode === 'replay' && replay && !replay.playing) stepOnce();
    else stepIfPaused();
    lastPanelKey = '';
  } else if (e.key === 'r' || e.key === 'R') {
    $('btn-reset').click();
  } else if (e.key === 'c' || e.key === 'C') {
    markCheckpoint();
  }
});

function loadScenario(sc: Scenario): void {
  const canonical = expandScenario(sc);
  const expected = new Map(runScenario(canonical).checkpoints.map((c) => [c.label, c.semantic]));
  recording = null;
  reset();
  mode = 'replay';
  replay = { sc: canonical, index: 0, playing: false, expected, results: new Map() };
  lastPanelKey = '';
}

function leaveReplay(): void {
  mode = 'live';
  replay = null;
  paused = false;
  reset();
}

// ---------------------------------------------------------------- test hook

declare global {
  interface Window {
    __golden: {
      state: () => GoldenState;
      semantic: () => SemanticState;
      loadScenario: (sc: Scenario) => void;
      setPaused: (p: boolean) => void;
    };
  }
}
window.__golden = {
  state: () => state,
  semantic: () => semanticState(state),
  loadScenario,
  setPaused: (p) => {
    paused = p;
    lastPanelKey = '';
  },
};

const RENDERER_NOTES: Record<string, string> = {
  assets: 'RTL bitmaps with property text, node colours and frame-locked flow',
  placeholder: 'stand-in graphics, not pixel-exact',
};
function updateBadge(): void {
  $('renderer-badge').textContent = `renderer: ${renderer.name} (${RENDERER_NOTES[renderer.name] ?? ''})`;
}
const selRenderer = $<HTMLSelectElement>('sel-renderer');
selRenderer.innerHTML = renderers.map((r, i) => `<option value="${i}">${r.name}</option>`).join('');
selRenderer.addEventListener('change', () => {
  renderer = renderers[Number(selRenderer.value)]!;
  updateBadge();
});
updateBadge();
setScale(2);
requestAnimationFrame(tick);
