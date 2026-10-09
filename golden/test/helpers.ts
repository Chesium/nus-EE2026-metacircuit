// Test helpers: drive the golden model with scenario steps.
import { makeConfig, type GoldenConfig } from '../src/core/config.ts';
import { initialState, type GoldenState } from '../src/core/state.ts';
import { step } from '../src/core/step.ts';
import { expandScenario } from '../src/scenario/expand.ts';
import type { Step } from '../src/scenario/types.ts';

/** An empty canvas (no boot circuit), so unit tests control every cell. */
export const empty = (): GoldenState => initialState({ bootCircuit: false });

/** Run steps (strings or objects) from `from` (default: empty canvas); returns the final state. */
export function drive(steps: (Step | string)[], from: GoldenState = empty(), cfg: GoldenConfig = makeConfig()): GoldenState {
  const sc = expandScenario({ name: 't', steps });
  let s = from;
  for (const m of sc.frames) s = step(s, m, cfg);
  return s;
}

/** Run steps and return every intermediate state (index i = state after frame i). */
export function trace(steps: (Step | string)[], cfg: GoldenConfig = makeConfig()): GoldenState[] {
  const sc = expandScenario({ name: 't', steps });
  const out: GoldenState[] = [];
  let s = empty();
  for (const m of sc.frames) {
    s = step(s, m, cfg);
    out.push(s);
  }
  return out;
}
