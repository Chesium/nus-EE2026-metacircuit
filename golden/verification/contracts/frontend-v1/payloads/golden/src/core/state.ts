// Golden model state (GM-1).

import { BOOT_CIRCUIT } from './bootCircuit.ts';
import {
  CELL_COUNT, COMPONENT_INDEX_INVALID, FRAMESCOPE_MOUSE_DEFAULT, GRID_W, INITIAL_TOOL, INITIAL_WIRE_VARIANT, LEFT_HALF_SPRITES,
  PAIR_DELTA, Tool,
} from './constants.ts';

/** One mouse sample per frame, at the MouseCtl outputs (D-010). */
export interface MouseSnapshot {
  x: number; // 0..639
  y: number; // 0..479
  left: boolean;
  middle: boolean;
  right: boolean;
}

/** A two-cell component held in the ComponentStore. */
export interface Component {
  /** Store type field: sprite id of the anchor (left) half, e.g. 5 for a resistor. */
  leftSprite: number;
  col: number; // anchor column
  row: number; // anchor row
  rotation: number; // 0..3
  valueBcd: number; // 3-digit BCD
  unit: number; // Unit code
  /** Literal keypad text; absent means the initial value's display text. */
  displayText?: string;
  inputDigits?: number;
}

/** Where the current left-button gesture started (A-006). */
export type GestureOrigin = 'none' | 'canvas' | 'toolbar' | 'outside';

export interface GoldenState {
  /** Number of frames stepped so far; the state after step N has frame = N + 1. */
  frame: number;
  /** CellStore: one 16-bit word per grid cell, row-major (addr = row*18 + col). */
  cells: Uint16Array;
  /** Per-cell component slot (0x1FF for cells that are not part of a component). */
  componentIndexMap: Uint16Array;
  /** ComponentStore slots; null = free. Depth = CELL_COUNT (IF-019). */
  components: (Component | null)[];
  tool: Tool;
  wireVariant: number;
  /** Pan offset, the RTL's grid_pos_x/y: grid origin relative to canvas origin, in [MIN, 0]. */
  panX: number;
  panY: number;
  /** Mouse snapshot applied in the previous step (edge detection and pan deltas). */
  prevMouse: MouseSnapshot;
  gesture: GestureOrigin;
  /** Frames left before the next repeated rotation while held (A-012). */
  rotateHoldoff: number;
  /** Snapshots delayed by the input latency (oldest first). */
  latencyQueue: MouseSnapshot[];
  /** Property selection is a cell, so empty cells and wires can be inspected. */
  selectedCell: { col: number; row: number } | null;
  valueEditActive: boolean;
  cellFgColor?: Uint8Array;
  cellBgColor?: Uint8Array;
}

export function defaultMouse(): MouseSnapshot {
  return { ...FRAMESCOPE_MOUSE_DEFAULT };
}

export interface InitOptions {
  /** Load the RTL's default boot circuit (IF-026, A-017). Default true. */
  bootCircuit?: boolean;
}

export function initialState(opts: InitOptions = {}): GoldenState {
  const s = emptyState();
  if (opts.bootCircuit ?? true) loadBootCircuit(s);
  return s;
}

/** Write the boot table into the stores. Components get slots in table order (A-017). */
function loadBootCircuit(s: GoldenState): void {
  const value = new Map<number, [number, number]>();
  for (const [addr, word, bcd, unit] of BOOT_CIRCUIT) {
    s.cells[addr] = word;
    value.set(addr, [bcd, unit]);
  }
  let slot = 0;
  for (const [addr, word] of BOOT_CIRCUIT) {
    const sprite = (word >> 1) & 0x3f;
    if (!(word & 1) || !LEFT_HALF_SPRITES.has(sprite)) continue;
    const rotation = (word >> 7) & 3;
    const col = addr % GRID_W;
    const row = Math.floor(addr / GRID_W);
    const [dx, dy] = PAIR_DELTA[rotation]!;
    const pair = (row + dy) * GRID_W + col + dx;
    const [valueBcd, unit] = value.get(addr)!;
    s.components[slot] = { leftSprite: sprite, col, row, rotation, valueBcd, unit };
    s.componentIndexMap[addr] = slot;
    s.componentIndexMap[pair] = slot;
    slot += 1;
  }
}

function emptyState(): GoldenState {
  return {
    frame: 0,
    cells: new Uint16Array(CELL_COUNT),
    componentIndexMap: new Uint16Array(CELL_COUNT).fill(COMPONENT_INDEX_INVALID),
    components: new Array<Component | null>(CELL_COUNT).fill(null),
    tool: INITIAL_TOOL,
    wireVariant: INITIAL_WIRE_VARIANT,
    panX: 0,
    panY: 0,
    prevMouse: defaultMouse(),
    gesture: 'none',
    rotateHoldoff: 0,
    latencyQueue: [],
    selectedCell: null,
    valueEditActive: false,
  };
}

export function cloneState(s: GoldenState): GoldenState {
  return {
    ...s,
    cells: s.cells.slice(),
    componentIndexMap: s.componentIndexMap.slice(),
    components: s.components.map((c) => (c ? { ...c } : null)),
    prevMouse: { ...s.prevMouse },
    latencyQueue: s.latencyQueue.map((m) => ({ ...m })),
    selectedCell: s.selectedCell ? { ...s.selectedCell } : null,
    ...(s.cellFgColor ? { cellFgColor: s.cellFgColor.slice() } : {}),
    ...(s.cellBgColor ? { cellBgColor: s.cellBgColor.slice() } : {}),
  };
}

export function liveComponents(s: GoldenState): { slot: number; c: Component }[] {
  const out: { slot: number; c: Component }[] = [];
  s.components.forEach((c, slot) => {
    if (c) out.push({ slot, c });
  });
  return out;
}
