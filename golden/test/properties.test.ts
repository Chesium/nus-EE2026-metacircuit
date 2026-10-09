import { describe, expect, it } from 'vitest';
import { initialState, cloneState } from '../src/core/state.ts';
import { keypadHit, selectedProperties } from '../src/core/properties.ts';
import { exportRamDumps } from '../src/core/export.ts';
import { step } from '../src/core/step.ts';
import { drive } from './helpers.ts';

const selectResistor = ['click_cell 4 4', 'click 280 34', 'click 620 464', 'wait 1'];

describe('property selection and frame-locked keypad', () => {
  it('selects either component half and shows clicked position with anchor value', () => {
    const s = drive(['click_cell 4 4', 'wait 1'], initialState());
    expect(selectedProperties(s)).toMatchObject({ hasSelection: true, col: 4, row: 4, anchorCol: 3, valueBcd: 0x100, valueText: '100', index: 1 });
    expect(s.valueEditActive).toBe(false);
  });

  it('handles one-frame clicks, units and backspace without corrupting digits', () => {
    let s = drive([...selectResistor, 'click 500 368', 'click 531 368', 'click 562 368', 'click 624 368', 'wait 1'], initialState());
    expect(selectedProperties(s)).toMatchObject({ valueBcd: 0x123, unit: 2, valueText: '123k' });
    s = drive(['click 570 464', 'wait 1'], s);
    expect(selectedProperties(s)).toMatchObject({ valueBcd: 0x123, unit: 0, valueText: '123' });
    s = drive(['click 570 464', 'wait 1'], s);
    expect(selectedProperties(s)).toMatchObject({ valueBcd: 0x120, unit: 0, valueText: '12' });
  });

  it('holds selection across keypad use and writes both cell values', () => {
    const s = drive([...selectResistor, 'click 500 368', 'wait 1'], initialState());
    expect(s.selectedCell).toEqual({ col: 4, row: 4 });
    expect(s.valueEditActive).toBe(true);
    const exported = exportRamDumps(s);
    expect(exported.find((m) => m.name === 'values_shadow')!.words[75]).toBe('0x100');
    expect(exported.find((m) => m.name === 'values_shadow')!.words[76]).toBe('0x100');
  });

  it('preserves reference immutability and applies the common one-frame latency', () => {
    const before = drive(selectResistor, initialState());
    const pressed = { x: 531, y: 368, left: true, middle: false, right: false };
    const first = step(before, pressed);
    expect(selectedProperties(first).valueText).toBe('');
    const next = step(first, { ...pressed, left: false });
    expect(selectedProperties(next).valueText).toBe('2');
    expect(selectedProperties(before).valueText).toBe('');
    const copy = cloneState(next);
    copy.selectedCell!.col = 1;
    expect(next.selectedCell!.col).toBe(4);
  });

  it('does not repeat keys held down and ignores keypad values outside editing', () => {
    let s = drive(['click_cell 3 4', 'click 500 368', 'wait 1'], initialState());
    expect(selectedProperties(s).valueText).toBe('100');
    s = drive(['click 280 34', 'click 620 464', { op: 'click', x: 500, y: 368, hold: 8 }, 'wait 1'], s);
    expect(selectedProperties(s).valueText).toBe('1');
  });

  it('inspects empty cells and clears canvas with RST when no editable component is selected', () => {
    let s = drive(['click_cell 0 0', 'wait 1'], initialState());
    expect(selectedProperties(s)).toMatchObject({ hasSelection: true, cellEnabled: false, index: -1 });
    s = drive(['click 620 464', 'wait 1'], s);
    expect(s.cells.every((word) => word === 0)).toBe(true);
    expect(s.components.every((c) => c === null)).toBe(true);
  });

  it('uses exact merged action hit boxes', () => {
    expect(keypadHit(485, 352)).toBe(0);
    expect(keypadHit(592, 479)).toBe(17);
    expect(keypadHit(593, 479)).toBe(18);
    expect(keypadHit(484, 352)).toBe(-1);
  });
});
