// Property/keypad behavior from the property-panel verification documents and
// keypad's public layout. Ambiguities are recorded in M2_ASSUMPTIONS.md.
import { ComponentKind, UNIT_NAMES, kindFromSprite } from './constants.ts';
import { bcdToString, cellAddr, decodeCell, stringToBcd } from './encoding.ts';
import { insideCanvas, screenToCell } from './geometry.ts';
import type { Component, GoldenState, MouseSnapshot } from './state.ts';

const KEYS = ['1', '2', '3', 'M', 'k', '4', '5', '6', 'm', 'u', '7', '8', '9', 'n', 'p', '.', '0', '\b', '\x7f'];

/** Public keypad geometry; DEL and RST each span one and a half columns. */
export function keypadHit(x: number, y: number): number {
  if (x < 485 || x >= 640 || y < 352 || y >= 480) return -1;
  const row = Math.floor((y - 352) / 32);
  const col = Math.floor((x - 485) / 31);
  if (row === 3 && col >= 2) return x < 593 ? 17 : 18;
  return row * 5 + col;
}

function componentText(c: Component): string {
  if (c.displayText !== undefined) return c.displayText;
  if (c.valueBcd === 0 && c.unit === 0) return '';
  const digits = bcdToString(c.valueBcd);
  return (kindFromSprite(c.leftSprite) === ComponentKind.Resistor ? digits : digits.slice(1)) + (UNIT_NAMES[c.unit] ?? '');
}

export function selectedProperties(s: GoldenState) {
  const p = s.selectedCell;
  const word = p ? s.cells[cellAddr(p.col, p.row)]! : 0;
  const cell = decodeCell(word);
  const slot = p ? s.componentIndexMap[cellAddr(p.col, p.row)]! : -1;
  const c = s.components[slot] ?? null;
  return {
    hasSelection: p !== null,
    cellEnabled: cell.enabled,
    sprite: cell.sprite,
    rotation: cell.rotation,
    kind: kindFromSprite(cell.sprite),
    col: p?.col ?? 0,
    row: p?.row ?? 0,
    anchorCol: c?.col ?? p?.col ?? 0,
    anchorRow: c?.row ?? p?.row ?? 0,
    valueBcd: c?.valueBcd ?? 0,
    unit: c?.unit ?? 0,
    valueText: c ? componentText(c) : '',
    index: c ? slot : -1,
  };
}

/** Press-only property selection and immediate keypad value writes. */
export function propertyPress(s: GoldenState, m: MouseSnapshot): void {
  if (insideCanvas(m.x, m.y)) {
    s.selectedCell = screenToCell(m.x, m.y, s.panX, s.panY);
    s.valueEditActive = false;
    return;
  }
  const selected = selectedProperties(s);
  const c = s.components[selected.index] ?? null;
  if (s.selectedCell && m.x >= 224 && m.x < 336 && m.y >= 24 && m.y < 44 && c) {
    s.valueEditActive = true;
    return;
  }
  const key = keypadHit(m.x, m.y);
  if (key >= 0) {
    const ch = KEYS[key]!;
    if (ch === '\x7f' && !c) {
      s.cells.fill(0);
      s.componentIndexMap.fill(0x1ff);
      s.components.fill(null);
    } else if (c && s.valueEditActive) {
      const text = componentText(c);
      const next = ch === '\x7f' ? '' : ch === '\b' ? text.slice(0, -1) : text.length < 8 ? text + ch : text;
      if (next !== text || ch === '\x7f') updateValue(c, next);
    }
    return;
  }
  s.valueEditActive = false;
  if (!(s.selectedCell && m.y < 64)) s.selectedCell = null;
}

/** Fixed-width field: three positions for resistance, two for other parts. */
function updateValue(c: Component, text: string): void {
  const width = kindFromSprite(c.leftSprite) === ComponentKind.Resistor ? 3 : 2;
  const digits = text.replace(/[^0-9]/g, '').slice(0, width);
  c.valueBcd = stringToBcd(digits.padEnd(width, '0'));
  c.inputDigits = digits.length;
  c.displayText = text;
  c.unit = 0;
  for (const ch of text) {
    const unit = Object.entries(UNIT_NAMES).find(([, label]) => label === ch && label !== '');
    if (unit) c.unit = Number(unit[0]);
  }
}
