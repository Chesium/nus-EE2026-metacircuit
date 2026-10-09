// Scenario format (SC-1). See golden/README.md "Scenario format" for the reference.

import type { MouseSnapshot } from '../core/state.ts';

export type Button = 'left' | 'middle' | 'right';
export type Point = [number, number];

/** A drag endpoint: a screen pixel, or the centre of a grid cell under an assumed pan offset. */
export type Target = { screen: Point } | { cell: Point; pan?: Point };

export type Step =
  | { op: 'move'; x: number; y: number }
  | { op: 'down'; button?: Button }
  | { op: 'up'; button?: Button }
  | { op: 'wait'; frames: number }
  | { op: 'click'; x: number; y: number; button?: Button; hold?: number }
  | { op: 'click_tool'; tool: string; hold?: number }
  | { op: 'click_cell'; cell?: Point; screen?: Point; pan?: Point; button?: Button; hold?: number }
  | { op: 'drag'; from: Target; to: Target; frames: number; button?: Button }
  | { op: 'assume_pan'; x: number; y: number }
  | { op: 'checkpoint'; label: string }
  | { op: 'comment'; text: string };

export interface Scenario {
  name: string;
  description?: string;
  /** Mouse state before frame 0. Defaults to framescope's virtual-input defaults (320, 240, no buttons). */
  initialMouse?: Partial<MouseSnapshot>;
  /** Steps as objects or as one-line strings (see parseStepString). */
  steps: (Step | string)[];
}

export interface Checkpoint {
  label: string;
  /** Compare the state at the end of this frame (0-based golden frame index). */
  frame: number;
}

/** Canonical per-frame form: exactly one mouse snapshot per frame. */
export interface CanonicalScenario {
  name: string;
  description?: string;
  frameCount: number;
  frames: MouseSnapshot[];
  checkpoints: Checkpoint[];
}
