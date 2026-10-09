// M1 compares state, independently of the renderer and component slot allocation.
import { CELL_COUNT, COMPONENT_INDEX_INVALID, modeSelect } from '../core/constants.ts';
import { cellAddr, decodeCell, fromHex } from '../core/encoding.ts';
import { DEFAULT_DUMP_NAMES, decodeMemories, diffSemantic, type DumpNames, type RamDump, type SemanticState } from '../core/export.ts';
import { inGrid } from '../core/geometry.ts';

export interface ActualCheckpoint {
  frame: number;
  probes: Record<string, number>;
  dumps: RamDump[];
}

/** Missing/invalid evidence fails rather than silently decoding an empty store. */
export function compareCheckpoint(
  expected: { frame: number; dumps: RamDump[]; semantic: SemanticState },
  actual: ActualCheckpoint,
  names: DumpNames = DEFAULT_DUMP_NAMES,
): string[] {
  const differences: string[] = [];
  if (actual.frame !== expected.frame) differences.push(`frame is ${actual.frame}, expected ${expected.frame}`);
  for (const ref of expected.dumps) {
    const matches = actual.dumps.filter((d) => d.name === ref.name);
    const d = matches[0];
    if (matches.length !== 1 || !d) {
      differences.push(`expected exactly one dump for ${ref.name}, found ${matches.length}`);
      continue;
    }
    if (d.frame !== expected.frame || d.width !== ref.width || d.depth !== CELL_COUNT || d.words.length !== CELL_COUNT) {
      differences.push(`${d.name}: invalid frame, width, depth or word count`);
    } else if (d.words.some((w) => !/^0x[0-9a-f]+$/i.test(w) || fromHex(w) >= (1n << BigInt(d.width)))) {
      differences.push(`${d.name}: invalid memory word`);
    }
  }
  const requiredProbes = {
    tool_idx: expected.semantic.toolIndex,
    wire_variant: ['wire', 'junction', 'elbow', 'tee'].indexOf(expected.semantic.wireVariant),
    mode_select: expected.semantic.modeSelect,
    grid_pos_x: expected.semantic.pan.x,
    grid_pos_y: expected.semantic.pan.y,
    init_done: 1,
    interaction_idle: 1,
    interaction_frame_drop: 0,
    component_store_busy: 0,
    component_count: expected.semantic.components.length,
  };
  for (const [key, value] of Object.entries(requiredProbes)) {
    if (actual.probes[key] !== value) differences.push(`probe ${key} is ${actual.probes[key]}, expected ${value}`);
  }
  const count = actual.probes.component_count;
  if (!Number.isInteger(count) || count! < 0 || count! > CELL_COUNT) differences.push('invalid component_count');
  // Avoid interpreting malformed evidence. Probe mismatches can still have useful state diffs.
  if (differences.some((d) => d.includes('dump') || d.includes('invalid'))) return differences;

  const get = (name: string) => actual.dumps.find((d) => d.name === name)!;
  const render = get(names.cellsRender);
  const shadow = get(names.cellsShadow);
  render.words.forEach((word, addr) => {
    if (fromHex(word) !== fromHex(shadow.words[addr]!)) differences.push(`mirrored cell RAMs differ at address ${addr}`);
  });
  for (const name of [names.values, names.valueUnits]) {
    const ref = expected.dumps.find((d) => d.name === name)!;
    get(name).words.forEach((word, addr) => {
      if (fromHex(word) !== fromHex(ref.words[addr]!)) differences.push(`${name}[${addr}] is ${word}, expected ${ref.words[addr]}`);
    });
  }
  const decoded = decodeMemories(actual.dumps, names, { componentCount: count });
  differences.push(...diffSemantic(expected.semantic, decoded));
  const map = get(names.componentIndexMap).words.map((w) => Number(fromHex(w)));
  const owners = new Map<number, number>();
  const anchors = new Set<string>();
  for (const c of decoded.components) {
    const anchor = `${c.col},${c.row}`;
    if (anchors.has(anchor)) differences.push(`duplicate component anchor (${anchor})`);
    anchors.add(anchor);
    if (c.indexField !== c.slot) differences.push(`component slot ${c.slot} has index field ${c.indexField}`);
    for (const [half, p] of c.cells.entries()) {
      if (!inGrid(p.col, p.row)) {
        differences.push(`component slot ${c.slot} has out-of-grid half (${p.col},${p.row})`);
        continue;
      }
      const addr = cellAddr(p.col, p.row);
      if (owners.has(addr)) differences.push(`components overlap at (${p.col},${p.row})`);
      owners.set(addr, c.slot);
      const cell = decodeCell(Number(fromHex(render.words[addr]!)));
      if (!cell.enabled || cell.sprite !== c.storeType + half || cell.rotation !== c.rotation) {
        differences.push(`component slot ${c.slot} disagrees with cell (${p.col},${p.row})`);
      }
    }
  }
  map.forEach((slot, addr) => {
    const wanted = owners.get(addr) ?? COMPONENT_INDEX_INVALID;
    if (slot !== wanted) differences.push(`component_index_map[${addr}] is ${slot}, expected ${wanted}`);
  });
  if (modeSelect(actual.probes.tool_idx!, actual.probes.wire_variant!) !== actual.probes.mode_select) {
    differences.push('toolbar and interaction mode probes disagree');
  }
  return differences;
}
