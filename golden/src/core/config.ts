// Tunable behaviour knobs of the golden model. Defaults are the choices recorded
// in golden/ASSUMPTIONS.md; each knob names the assumption it implements.

import { ROTATE_FRAMES_PER_STEP } from './constants.ts';

export interface GoldenConfig {
  /**
   * Input-to-effect latency in frames (D-008, RTL-3, IF-029). step() for frame k
   * applies the mouse snapshot of frame k - L, so with the measured L = 1 the
   * state (and RAM dump) of frame k is step(state_{k-1}, mouse_{k-1}): an input
   * change during frame N first shows in frame N+1. Frame indices match
   * framescope's (frame 0 = first captured frame). A-003.
   */
  inputLatencyFrames: number;
  /** Frames between repeated rotations while the button is held on the rotate tool (IF-021, A-012). */
  rotateFramesPerStep: number;
  /** Single-cell tools (wire family, ground) keep drawing while the button is held (A-008). */
  singleCellPaintWhileHeld: boolean;
  /** Delete keeps erasing while the button is held (A-014). */
  deleteWhileHeld: boolean;
  /** Default value (3-digit BCD) and unit code of a newly placed component (A-010). */
  defaultValueBcd: number;
  defaultUnit: number;
}

export const DEFAULT_CONFIG: Readonly<GoldenConfig> = Object.freeze({
  inputLatencyFrames: 1,
  rotateFramesPerStep: ROTATE_FRAMES_PER_STEP,
  singleCellPaintWhileHeld: true,
  deleteWhileHeld: true,
  defaultValueBcd: 0x000,
  defaultUnit: 0,
});

export function makeConfig(partial: Partial<GoldenConfig> = {}): GoldenConfig {
  return { ...DEFAULT_CONFIG, ...partial };
}
