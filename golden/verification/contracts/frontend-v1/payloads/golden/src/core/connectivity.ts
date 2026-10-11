// Settled node-colour reference. Connectivity comes from the reciprocal-port
// graph in assets/metacircuit-netlist-convention.png; node numbering follows
// the row-major convention in notebooks/flooding.ipynb. This uses graph unions,
// independently of the RTL flooding state machine and its cycle timing.

import { GRID_H, GRID_W, Sprite } from './constants.ts';

/** Four-bit interface masks: bit 3 down, bit 2 right, bit 1 up, bit 0 left.
 * Base orientations are table facts (BackendFetchers.v decode_p_from_cell).
 * A component's two halves are not conductors; ground has one terminal and
 * participates in a numbered node, rather than forcing that node's ID to zero.
 */
const BASE_PORTS: Partial<Record<number, number>> = {
  [Sprite.Wire]: 0b0101,
  [Sprite.Elbow]: 0b0110,
  [Sprite.Tee]: 0b0111,
  [Sprite.Junction]: 0b1111,
  [Sprite.Cross]: 0b1111,
  [Sprite.Ground]: 0b0001,
};

export interface NodeMap {
  /** Row-major numbered nodes; zero means no conducting port. */
  nodeIds: Uint16Array;
  nodeCount: number;
}

export interface Connectivity extends NodeMap {
  ports: Uint8Array;
  /** Palette indices, ready for AssetRenderer's per-cell colour inputs. */
  cellFgColor: Uint8Array;
  cellBgColor: Uint8Array;
}

export const PORT_DOWN = 0b1000;
export const PORT_RIGHT = 0b0100;
export const PORT_UP = 0b0010;
export const PORT_LEFT = 0b0001;

/** The port bit pointing from a cell toward its neighbour at (+dx, +dy). */
export function portToward(dx: number, dy: number): number {
  if (dx === 1 && dy === 0) return PORT_RIGHT;
  if (dx === -1 && dy === 0) return PORT_LEFT;
  if (dx === 0 && dy === 1) return PORT_DOWN;
  if (dx === 0 && dy === -1) return PORT_UP;
  throw new Error(`not a unit grid direction: (${dx}, ${dy})`);
}

/** Unit step (dx, dy) of a single-port cell's port, e.g. a ground cell's terminal. */
export function singlePortDelta(mask: number): readonly [number, number] | null {
  switch (mask & 15) {
    case PORT_RIGHT: return [1, 0];
    case PORT_LEFT: return [-1, 0];
    case PORT_DOWN: return [0, 1];
    case PORT_UP: return [0, -1];
    default: return null;
  }
}

export function cellPortMask(word: number): number {
  if (!(word & 1)) return 0;
  const base = BASE_PORTS[(word >>> 1) & 63] ?? 0;
  const rotation = (word >>> 7) & 3;
  return ((base << rotation) | (base >>> (4 - rotation))) & 15;
}

/** Unassigned node zero uses the default background; numbered nodes wrap
 * through indices 1..13, reserving 14 for hover and 15 for foreground.
 */
export function nodePaletteIndex(node: number): number {
  if (!Number.isInteger(node) || node < 0) throw new Error('node must be a non-negative integer');
  return node === 0 ? 0 : (node - 1) % 13 + 1;
}

/** Number connected components by each component's first row-major address.
 * Bounds are checked before creating edges, so ports at the viewport's outer
 * edges cannot wrap to the next row or to an opposite side of the grid.
 */
export function labelPortGrid(ports: ArrayLike<number>, width: number, height: number): NodeMap {
  if (!Number.isInteger(width) || !Number.isInteger(height) || width <= 0 || height <= 0 ||
      width * height !== ports.length || ports.length > 65535) throw new Error('invalid port grid dimensions');
  const count = ports.length;
  const parent = Int32Array.from({ length: count }, (_, i) => i);
  const find = (address: number): number => {
    let root = address;
    while (parent[root] !== root) root = parent[root]!;
    while (parent[address] !== address) {
      const next = parent[address]!;
      parent[address] = root;
      address = next;
    }
    return root;
  };
  const union = (a: number, b: number) => {
    const ar = find(a); const br = find(b);
    if (ar !== br) parent[Math.max(ar, br)] = Math.min(ar, br);
  };
  for (let address = 0; address < count; address++) {
    const mask = ports[address]! & 15;
    const col = address % width;
    const row = Math.floor(address / width);
    if (col + 1 < width && mask & 0b0100 && ports[address + 1]! & 0b0001) union(address, address + 1);
    if (row + 1 < height && mask & 0b1000 && ports[address + width]! & 0b0010) union(address, address + width);
  }
  const nodeIds = new Uint16Array(count);
  const nodeForRoot = new Map<number, number>();
  for (let address = 0; address < count; address++) {
    if (!(ports[address]! & 15)) continue;
    const root = find(address);
    if (!nodeForRoot.has(root)) nodeForRoot.set(root, nodeForRoot.size + 1);
    nodeIds[address] = nodeForRoot.get(root)!;
  }
  return { nodeIds, nodeCount: nodeForRoot.size };
}

/** Derive settled per-cell node colours from the golden canvas alone.
 * This intentionally has no RAM dumps, flood probes, or hardware event timing
 * inputs; callers choose when the settled colours become visible.
 */
export function deriveConnectivity(cells: ArrayLike<number>, width = GRID_W, height = GRID_H): Connectivity {
  const ports = Uint8Array.from(cells, cellPortMask);
  const nodes = labelPortGrid(ports, width, height);
  return {
    ...nodes, ports,
    cellFgColor: new Uint8Array(cells.length).fill(15),
    cellBgColor: Uint8Array.from(nodes.nodeIds, nodePaletteIndex),
  };
}
