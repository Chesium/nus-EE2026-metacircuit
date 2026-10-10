// Netlist snapshot ids (D-016, M3-A013).
//
// The frontend sends one snapshot per frame. Its `frame` field is a snapshot id
// that starts at FIRST_SNAPSHOT_ID for the first snapshot after boot and
// increments (16 bit, wrapping) only on frames whose netlist-relevant canvas
// content differs from the previous snapshot's. The frontend accepts a solver
// reply only if its id equals the current snapshot id.
//
// Netlist-relevant content: every cell's type, rotation and enable bits
// (CellStore word bits [8:0]; the metadata bits [15:9] are not part of it), and
// the set of components with their kind, anchor position, rotation, value and
// unit. Store slot order and literal display text are not part of it.

import { CELL_COUNT } from '../core/constants.ts';
import { liveComponents, type GoldenState } from '../core/state.ts';

/** Id of the first snapshot after boot (D-016). */
export const FIRST_SNAPSHOT_ID = 0x0001;

/**
 * Frame alignment between golden states and transmitted snapshots: the
 * snapshot transmitted during frame k describes the golden state of frame
 * k - NETLIST_SNAPSHOT_STATE_LAG_FRAMES. Golden state k already holds the
 * effect of an input changed in frame k-1's back porch (inputLatencyFrames = 1,
 * RTL-3), and RTL-4 measured that such an edit goes out in the netlist TX
 * during frame k, so the lag is 0: snapshot k = state k.
 */
export const NETLIST_SNAPSHOT_STATE_LAG_FRAMES = 0;

/** Canonical, slot-independent key of the netlist-relevant canvas content. */
export function netlistContentKey(s: GoldenState): string {
  const cells: number[] = [];
  for (let a = 0; a < CELL_COUNT; a++) cells.push(s.cells[a]! & 0x1ff);
  const components = liveComponents(s)
    .map(({ c }) => [c.row * 64 + c.col, c.leftSprite, c.rotation, c.valueBcd, c.unit])
    .sort((p, q) => p[0]! - q[0]! || p[1]! - q[1]!);
  return JSON.stringify([cells, components]);
}

/** Assigns snapshot ids to consecutive per-frame snapshots (D-016). */
export class SnapshotIdTracker {
  private id = 0;
  private key: string | null = null;

  /** Id of the snapshot describing `s`, the state of the next frame in sequence. */
  next(s: GoldenState): number {
    const key = netlistContentKey(s);
    if (this.key === null) this.id = FIRST_SNAPSHOT_ID;
    else if (key !== this.key) this.id = (this.id + 1) & 0xffff;
    this.key = key;
    return this.id;
  }

  get current(): number {
    return this.id;
  }
}
