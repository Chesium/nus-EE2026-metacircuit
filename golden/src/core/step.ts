// Frame-stepped interaction semantics (GM-2). Behaviour follows structure.md,
// README.md and the final report; every gap is an assumption in ASSUMPTIONS.md.

import {
  CELL_COUNT, COMPONENT_INDEX_INVALID, COMPONENT_TOOL_SPRITES, PAN_MAX_X, PAN_MAX_Y, PAN_MIN_X, PAN_MIN_Y,
  SCREEN_H, SCREEN_W, Tool, WIRE_VARIANT_SPRITE, Sprite, rightSpriteFor,
} from './constants.ts';
import { DEFAULT_CONFIG, type GoldenConfig } from './config.ts';
import { EMPTY_CELL, cellAddr, decodeCell, makeCell } from './encoding.ts';
import { inGrid, insideCanvas, pairCell, screenToCell, toolbarHit } from './geometry.ts';
import { cloneState, defaultMouse, type Component, type GoldenState, type MouseSnapshot } from './state.ts';
import { propertyPress } from './properties.ts';

export function sanitizeMouse(m: MouseSnapshot): MouseSnapshot {
  const clamp = (v: number, hi: number) => Math.min(Math.max(Math.trunc(v), 0), hi);
  return { x: clamp(m.x, SCREEN_W - 1), y: clamp(m.y, SCREEN_H - 1), left: !!m.left, middle: !!m.middle, right: !!m.right };
}

const clamp = (v: number, lo: number, hi: number) => Math.min(Math.max(v, lo), hi);

/** Advance the model by one frame using this frame's mouse snapshot. Pure: returns a new state. */
export function step(prev: GoldenState, mouseIn: MouseSnapshot, cfg: GoldenConfig = DEFAULT_CONFIG): GoldenState {
  const s = cloneState(prev);
  const m = applyLatency(s, sanitizeMouse(mouseIn), cfg.inputLatencyFrames);
  const pm = s.prevMouse;
  const pressed = m.left && !pm.left;

  if (pressed) {
    propertyPress(s, m);
    const hit = toolbarHit(m.x, m.y);
    if (hit >= 0) {
      s.gesture = 'toolbar';
      selectTool(s, hit);
    } else if (insideCanvas(m.x, m.y)) {
      s.gesture = 'canvas';
    } else {
      s.gesture = 'outside';
    }
  }

  if (m.left && s.gesture === 'canvas') canvasAction(s, m, pm, pressed, cfg);

  if (!m.left) {
    s.gesture = 'none';
    s.rotateHoldoff = 0;
  }
  s.prevMouse = m;
  s.frame += 1;
  return s;
}

/** Run a whole per-frame input sequence from a state; returns the final state. */
export function run(initial: GoldenState, frames: MouseSnapshot[], cfg: GoldenConfig = DEFAULT_CONFIG): GoldenState {
  let s = initial;
  for (const m of frames) s = step(s, m, cfg);
  return s;
}

function applyLatency(s: GoldenState, m: MouseSnapshot, latency: number): MouseSnapshot {
  if (latency <= 0) return m;
  while (s.latencyQueue.length < latency) s.latencyQueue.unshift(defaultMouse());
  s.latencyQueue.push(m);
  return s.latencyQueue.shift()!;
}

// ---------------------------------------------------------------- toolbar (A-004, A-007)

function selectTool(s: GoldenState, idx: number): void {
  if (idx === Tool.Wire && s.tool === Tool.Wire) {
    s.wireVariant = (s.wireVariant + 1) & 3;
  } else {
    s.tool = idx as Tool;
  }
}

// ---------------------------------------------------------------- canvas

function canvasAction(s: GoldenState, m: MouseSnapshot, pm: MouseSnapshot, pressed: boolean, cfg: GoldenConfig): void {
  if (s.tool === Tool.Pan) {
    // A-013: the press frame anchors the drag; later frames move the grid with the mouse.
    if (!pressed) {
      s.panX = clamp(s.panX + (m.x - pm.x), PAN_MIN_X, PAN_MAX_X);
      s.panY = clamp(s.panY + (m.y - pm.y), PAN_MIN_Y, PAN_MAX_Y);
    }
    return;
  }

  const cell = screenToCell(m.x, m.y, s.panX, s.panY);

  switch (s.tool) {
    case Tool.Wire:
    case Tool.Ground: {
      if (!cell || !(pressed || cfg.singleCellPaintWhileHeld)) return;
      const sprite = s.tool === Tool.Ground ? Sprite.Ground : WIRE_VARIANT_SPRITE[s.wireVariant as 0 | 1 | 2 | 3];
      placeSingle(s, cell.col, cell.row, sprite);
      return;
    }
    case Tool.Resistor:
    case Tool.Inductor:
    case Tool.Capacitor:
    case Tool.VoltageSource:
    case Tool.CurrentSource:
      if (cell && pressed) placeComponent(s, cell.col, cell.row, COMPONENT_TOOL_SPRITES[s.tool]!.left, cfg);
      return;
    case Tool.Rotate: {
      const period = Math.max(1, cfg.rotateFramesPerStep);
      let fire = false;
      if (pressed) {
        fire = true;
        s.rotateHoldoff = period;
      } else {
        s.rotateHoldoff -= 1;
        if (s.rotateHoldoff <= 0) {
          fire = true;
          s.rotateHoldoff = period;
        }
      }
      if (fire && cell) rotateAt(s, cell.col, cell.row);
      return;
    }
    case Tool.Delete:
      if (cell && (pressed || cfg.deleteWhileHeld)) deleteAt(s, cell.col, cell.row);
      return;
    default:
      return;
  }
}

// ---------------------------------------------------------------- commands (exported for unit tests)

export function slotAt(s: GoldenState, col: number, row: number): number {
  const v = s.componentIndexMap[cellAddr(col, row)]!;
  return v === COMPONENT_INDEX_INVALID ? -1 : v;
}

function isEmpty(s: GoldenState, col: number, row: number): boolean {
  return s.cells[cellAddr(col, row)] === EMPTY_CELL && slotAt(s, col, row) < 0;
}

/** Wire-family / ground placement (A-008). Component cells are never overwritten. */
export function placeSingle(s: GoldenState, col: number, row: number, sprite: number): boolean {
  if (slotAt(s, col, row) >= 0) return false;
  const a = cellAddr(col, row);
  const cur = decodeCell(s.cells[a]!);
  if (cur.enabled && cur.sprite === sprite) return false; // keep its rotation
  s.cells[a] = makeCell(sprite, 0);
  return true;
}

/** Two-cell component placement at rotation 0 (A-009, A-010, A-011). */
export function placeComponent(s: GoldenState, col: number, row: number, leftSprite: number, cfg: GoldenConfig = DEFAULT_CONFIG): number {
  const p = pairCell(col, row, 0);
  if (!inGrid(p.col, p.row)) return -1;
  if (!isEmpty(s, col, row) || !isEmpty(s, p.col, p.row)) return -1;
  const slot = s.components.findIndex((c) => c === null);
  if (slot < 0 || slot >= CELL_COUNT) return -1;
  s.components[slot] = { leftSprite, col, row, rotation: 0, valueBcd: cfg.defaultValueBcd, unit: cfg.defaultUnit };
  drawComponent(s, slot);
  return slot;
}

/** Rotate the cell or component under (col,row) by one step (A-012). */
export function rotateAt(s: GoldenState, col: number, row: number): boolean {
  const slot = slotAt(s, col, row);
  if (slot >= 0) {
    const c = s.components[slot]!;
    const rot = (c.rotation + 1) & 3;
    const p = pairCell(c.col, c.row, rot);
    if (!inGrid(p.col, p.row)) return false;
    const occupant = slotAt(s, p.col, p.row);
    if (occupant !== slot && !isEmpty(s, p.col, p.row)) return false;
    eraseComponent(s, slot);
    c.rotation = rot;
    drawComponent(s, slot);
    return true;
  }
  const a = cellAddr(col, row);
  const cur = decodeCell(s.cells[a]!);
  if (!cur.enabled) return false;
  s.cells[a] = makeCell(cur.sprite, (cur.rotation + 1) & 3);
  return true;
}

/** Delete the cell or the whole component under (col,row) (A-014). */
export function deleteAt(s: GoldenState, col: number, row: number): boolean {
  const slot = slotAt(s, col, row);
  if (slot >= 0) {
    eraseComponent(s, slot);
    s.components[slot] = null;
    return true;
  }
  const a = cellAddr(col, row);
  if (s.cells[a] === EMPTY_CELL) return false;
  s.cells[a] = EMPTY_CELL;
  return true;
}

function componentCells(c: Component) {
  return [{ col: c.col, row: c.row }, pairCell(c.col, c.row, c.rotation)];
}

function drawComponent(s: GoldenState, slot: number): void {
  const c = s.components[slot]!;
  const [a, b] = componentCells(c);
  s.cells[cellAddr(a!.col, a!.row)] = makeCell(c.leftSprite, c.rotation);
  s.cells[cellAddr(b!.col, b!.row)] = makeCell(rightSpriteFor(c.leftSprite), c.rotation);
  s.componentIndexMap[cellAddr(a!.col, a!.row)] = slot;
  s.componentIndexMap[cellAddr(b!.col, b!.row)] = slot;
}

function eraseComponent(s: GoldenState, slot: number): void {
  const c = s.components[slot]!;
  for (const p of componentCells(c)) {
    s.cells[cellAddr(p.col, p.row)] = EMPTY_CELL;
    s.componentIndexMap[cellAddr(p.col, p.row)] = COMPONENT_INDEX_INVALID;
  }
}

/** "Clear": return the canvas to its boot state, keeping tool and pan (A-015). */
export function clearCanvas(prev: GoldenState): GoldenState {
  const s = cloneState(prev);
  s.cells.fill(EMPTY_CELL);
  s.componentIndexMap.fill(COMPONENT_INDEX_INVALID);
  s.components.fill(null);
  s.valueEditActive = false;
  return s;
}
