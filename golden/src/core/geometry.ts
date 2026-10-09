// Screen geometry: toolbar hit-testing and screen <-> grid mapping.

import {
  CANVAS_H, CANVAS_W, CANVAS_X0, CANVAS_Y0, CELL_SIZE, GRID_H, GRID_W, PAIR_DELTA, TOOLBAR_COUNT, buttonRect,
} from './constants.ts';

export function insideCanvas(x: number, y: number): boolean {
  return x >= CANVAS_X0 && x < CANVAS_X0 + CANVAS_W && y >= CANVAS_Y0 && y < CANVAS_Y0 + CANVAS_H;
}

/** Index of the toolbar button under (x, y), or -1. */
export function toolbarHit(x: number, y: number): number {
  for (let i = 0; i < TOOLBAR_COUNT; i++) {
    const r = buttonRect(i);
    if (x >= r.x0 && x < r.x1 && y >= r.y0 && y < r.y1) return i;
  }
  return -1;
}

export function buttonCenter(idx: number): { x: number; y: number } {
  const r = buttonRect(idx);
  return { x: Math.floor((r.x0 + r.x1) / 2), y: Math.floor((r.y0 + r.y1) / 2) };
}

export function inGrid(col: number, row: number): boolean {
  return col >= 0 && col < GRID_W && row >= 0 && row < GRID_H;
}

/**
 * Grid cell under the screen point, given the pan offset (grid_pos_x/y), or
 * null when the point is outside the canvas or outside the grid. A-005.
 */
export function screenToCell(x: number, y: number, panX: number, panY: number): { col: number; row: number } | null {
  if (!insideCanvas(x, y)) return null;
  const gx = x - CANVAS_X0 - panX;
  const gy = y - CANVAS_Y0 - panY;
  const col = Math.floor(gx / CELL_SIZE);
  const row = Math.floor(gy / CELL_SIZE);
  return inGrid(col, row) ? { col, row } : null;
}

/** Screen point at the centre of a grid cell for the given pan offset (may be off-canvas). */
export function cellCenter(col: number, row: number, panX = 0, panY = 0): { x: number; y: number } {
  return {
    x: CANVAS_X0 + panX + col * CELL_SIZE + CELL_SIZE / 2,
    y: CANVAS_Y0 + panY + row * CELL_SIZE + CELL_SIZE / 2,
  };
}

/** The second cell of a two-cell component anchored at (col,row) with this rotation. */
export function pairCell(col: number, row: number, rotation: number): { col: number; row: number } {
  const [dx, dy] = PAIR_DELTA[rotation & 3]!;
  return { col: col + dx, row: row + dy };
}
