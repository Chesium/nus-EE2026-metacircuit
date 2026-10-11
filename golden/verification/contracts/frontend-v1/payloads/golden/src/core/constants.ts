// Interface constants taken from the RTL (layout, encodings, data tables).
// Every value here is listed with its source in golden/INTERFACE_FACTS.md
// (IF-xxx). Behaviour is NOT derived from the RTL; see golden/ASSUMPTIONS.md.

// ---------------------------------------------------------------- screen
export const SCREEN_W = 640; // IF-001
export const SCREEN_H = 480; // IF-001

// ---------------------------------------------------------------- canvas
export const CELL_SIZE = 32; // IF-002
export const GRID_W = 18; // IF-003 (columns)
export const GRID_H = 16; // IF-003 (rows)
export const CELL_COUNT = GRID_W * GRID_H; // 288
export const CANVAS_ADDR_W = 9; // IF-003: $clog2(288)
export const COMPONENT_INDEX_INVALID = (1 << CANVAS_ADDR_W) - 1; // IF-004: all ones (0x1FF)

export const TOP_BAR_H = 64; // IF-001
export const LEFT_BAR_W = 64; // IF-001
export const RIGHT_BAR_W = 156; // IF-001
export const BOTTOM_BAR_H = 128; // IF-001

export const CANVAS_X0 = LEFT_BAR_W; // 64, IF-005
export const CANVAS_Y0 = TOP_BAR_H; // 64, IF-005
export const CANVAS_W = GRID_W * CELL_SIZE; // 576, IF-005
export const CANVAS_H = SCREEN_H - TOP_BAR_H - BOTTOM_BAR_H; // 288, IF-005

// Pan offset (the RTL's grid_pos_x/y): signed pixel offset of the grid origin
// relative to the canvas origin, clamped to [MIN, 0]. IF-006.
export const PAN_MIN_X = CANVAS_W > GRID_W * CELL_SIZE ? 0 : CANVAS_W - GRID_W * CELL_SIZE; // 0
export const PAN_MIN_Y = CANVAS_H > GRID_H * CELL_SIZE ? 0 : CANVAS_H - GRID_H * CELL_SIZE; // -224
export const PAN_MAX_X = 0;
export const PAN_MAX_Y = 0;

// ---------------------------------------------------------------- toolbar
// Button rectangles: x in [BTN_X0, BTN_X0+BTN_W), y in [y0(i), y0(i)+BTN_H),
// y0(i) = BTN_Y0 + i*(BTN_H+BTN_GAP). IF-007, IF-008.
export const TOOLBAR_COUNT = 10;
export const BTN_X0 = 14;
export const BTN_W = 36;
export const BTN_H = 24;
export const BTN_GAP = 2;
export const BTN_Y0 = 72;

export function buttonRect(idx: number): { x0: number; y0: number; x1: number; y1: number } {
  const y0 = BTN_Y0 + idx * (BTN_H + BTN_GAP);
  return { x0: BTN_X0, y0, x1: BTN_X0 + BTN_W, y1: y0 + BTN_H };
}

/** Toolbar button order (index = selected_tool_idx). IF-009. */
export enum Tool {
  Pan = 0,
  Wire = 1, // wire family; the variant selects wire/junction/elbow/tee
  Resistor = 2,
  Inductor = 3,
  Capacitor = 4,
  VoltageSource = 5,
  CurrentSource = 6,
  Ground = 7,
  Rotate = 8,
  Delete = 9,
}

export const TOOL_NAMES: Record<Tool, string> = {
  [Tool.Pan]: 'pan',
  [Tool.Wire]: 'wire',
  [Tool.Resistor]: 'resistor',
  [Tool.Inductor]: 'inductor',
  [Tool.Capacitor]: 'capacitor',
  [Tool.VoltageSource]: 'voltage',
  [Tool.CurrentSource]: 'current',
  [Tool.Ground]: 'ground',
  [Tool.Rotate]: 'rotate',
  [Tool.Delete]: 'delete',
};

/** Reset value of the selected tool and wire variant. IF-010. */
export const INITIAL_TOOL = Tool.Pan;
export const INITIAL_WIRE_VARIANT = 0;

/** Wire-family variant codes (selected_wire_variant). IF-011. */
export enum WireVariant {
  Wire = 0,
  Junction = 1,
  Elbow = 2,
  Tee = 3,
}
export const WIRE_VARIANT_NAMES = ['wire', 'junction', 'elbow', 'tee'] as const;

// ---------------------------------------------------------------- sprites (IF-012)
export enum Sprite {
  Wire = 0,
  Elbow = 1,
  Tee = 2,
  Junction = 3,
  Cross = 4,
  ResLeft = 5,
  ResRight = 6,
  VoltLeft = 7,
  VoltRight = 8,
  CurrLeft = 9,
  CurrRight = 10,
  IndLeft = 11,
  IndRight = 12,
  CapLeft = 13,
  CapRight = 14,
  Ground = 15,
}

export const SPRITE_NAMES: Record<number, string> = {
  0: 'Wire',
  1: 'Elbow',
  2: 'Tee',
  3: 'Junction',
  4: 'Cross',
  5: 'RL',
  6: 'RR',
  7: 'VL',
  8: 'VR',
  9: 'IL',
  10: 'IR',
  11: 'LL',
  12: 'LR',
  13: 'CL',
  14: 'CR',
  15: 'Ground',
};

export const WIRE_VARIANT_SPRITE: Record<WireVariant, Sprite> = {
  [WireVariant.Wire]: Sprite.Wire,
  [WireVariant.Junction]: Sprite.Junction,
  [WireVariant.Elbow]: Sprite.Elbow,
  [WireVariant.Tee]: Sprite.Tee,
};

/** Two-cell component tools: (left sprite at the anchor, right sprite at the pair cell). IF-013. */
export const COMPONENT_TOOL_SPRITES: Partial<Record<Tool, { left: Sprite; right: Sprite }>> = {
  [Tool.Resistor]: { left: Sprite.ResLeft, right: Sprite.ResRight },
  [Tool.Inductor]: { left: Sprite.IndLeft, right: Sprite.IndRight },
  [Tool.Capacitor]: { left: Sprite.CapLeft, right: Sprite.CapRight },
  [Tool.VoltageSource]: { left: Sprite.VoltLeft, right: Sprite.VoltRight },
  [Tool.CurrentSource]: { left: Sprite.CurrLeft, right: Sprite.CurrRight },
};

export const LEFT_HALF_SPRITES = new Set<number>([
  Sprite.ResLeft, Sprite.VoltLeft, Sprite.CurrLeft, Sprite.IndLeft, Sprite.CapLeft,
]);
export const RIGHT_HALF_SPRITES = new Set<number>([
  Sprite.ResRight, Sprite.VoltRight, Sprite.CurrRight, Sprite.IndRight, Sprite.CapRight,
]);
export function isComponentSprite(s: number): boolean {
  return LEFT_HALF_SPRITES.has(s) || RIGHT_HALF_SPRITES.has(s);
}
export function rightSpriteFor(left: number): number {
  return left + 1; // IF-012: every right half is left+1
}

// ---------------------------------------------------------------- interaction mode codes (IF-014)
/** interaction_mode_select codes, derived from (tool, wire variant). */
export function modeSelect(tool: Tool, wireVariant: number): number {
  switch (tool) {
    case Tool.Wire:
      return [0, 1, 2, 3][wireVariant & 3]!; // wire, junction, elbow, tee
    case Tool.Resistor: return 4;
    case Tool.Inductor: return 9;
    case Tool.Capacitor: return 10;
    case Tool.VoltageSource: return 5;
    case Tool.CurrentSource: return 6;
    case Tool.Ground: return 11;
    case Tool.Rotate: return 7;
    case Tool.Delete: return 8;
    default: return 0xf; // pan / none
  }
}

// ---------------------------------------------------------------- component kinds (IF-015)
export enum ComponentKind {
  Wire = 0,
  Ground = 1,
  Resistor = 2,
  Capacitor = 3,
  Inductor = 4,
  Voltage = 5,
  Current = 6,
}
export const COMPONENT_KIND_NAMES: Record<number, string> = {
  0: 'wire', 1: 'ground', 2: 'resistor', 3: 'capacitor', 4: 'inductor', 5: 'voltage', 6: 'current',
};
export function kindFromSprite(s: number): ComponentKind {
  switch (s) {
    case Sprite.Ground: return ComponentKind.Ground;
    case Sprite.ResLeft: case Sprite.ResRight: return ComponentKind.Resistor;
    case Sprite.CapLeft: case Sprite.CapRight: return ComponentKind.Capacitor;
    case Sprite.IndLeft: case Sprite.IndRight: return ComponentKind.Inductor;
    case Sprite.VoltLeft: case Sprite.VoltRight: return ComponentKind.Voltage;
    case Sprite.CurrLeft: case Sprite.CurrRight: return ComponentKind.Current;
    default: return ComponentKind.Wire;
  }
}

// ---------------------------------------------------------------- value units (IF-016)
export enum Unit {
  None = 0,
  Mega = 1,
  Kilo = 2,
  Milli = 3,
  Micro = 4,
  Nano = 5,
  Pico = 6,
}
export const UNIT_NAMES: Record<number, string> = {
  0: '', 1: 'M', 2: 'k', 3: 'm', 4: 'u', 5: 'n', 6: 'p',
};

// ---------------------------------------------------------------- word widths (IF-017..IF-019)
export const CELL_WORD_W = 16;
export const COMPONENT_WORD_W = 40;
export const INDEX_MAP_WORD_W = CANVAS_ADDR_W;

// ---------------------------------------------------------------- rotation
/**
 * Direction of the second (right-half) cell of a two-cell component for each
 * rotation code: 0 -> +x, 1 -> +y, 2 -> -x, 3 -> -y (grid columns/rows). IF-020.
 */
export const PAIR_DELTA: ReadonlyArray<readonly [number, number]> = [
  [1, 0],
  [0, 1],
  [-1, 0],
  [0, -1],
];

/** Frames between repeated rotate steps while the button is held. IF-021. */
export const ROTATE_FRAMES_PER_STEP = 8;

// ---------------------------------------------------------------- framescope defaults
/** framescope's virtual mouse inputs at reset (examples/metacircuit/framescope.toml). */
export const FRAMESCOPE_MOUSE_DEFAULT = { x: 320, y: 240, left: false, middle: false, right: false };
