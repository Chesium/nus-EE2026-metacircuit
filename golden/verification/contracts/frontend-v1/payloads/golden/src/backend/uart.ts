// uart_link record codec (GM-8): netlist (`@NB/@NC/@NE`), voltage (`@VB/@VN/@VE`)
// and error (`@ER`) records, per src/uart_link/README.md and protocol.py.
//
// Framing: `@<payload>*<checksum>\r\n`; payload fields are comma separated,
// fixed-width uppercase hex; checksum = XOR of the payload's ASCII bytes.
// The encoder is stricter than protocol.py: it rejects out-of-range fields
// instead of masking them. The decoder accepts only uppercase hex fields.

import type { Netlist, VoltageSnapshot } from './types.ts';

export type UartRecord =
  | { type: 'NB'; frame: number; elemCount: number; nodeCount: number }
  | { type: 'NC'; frame: number; idx: number; kind: number; n0: number; n1: number; valueBcd: number; unit: number }
  | { type: 'NE'; frame: number; elemCount: number; nodeCount: number }
  | { type: 'VB'; frame: number; nodeCount: number; status: number }
  | { type: 'VN'; frame: number; node: number; valueBits: number }
  | { type: 'VE'; frame: number; nodeCount: number; status: number }
  | { type: 'ER'; frame: number; code: number; arg: number };

export type RecordType = UartRecord['type'];

/** Field names and hex widths after the tag, in wire order. */
export const RECORD_LAYOUT: Readonly<Record<RecordType, readonly (readonly [string, number])[]>> = {
  NB: [['frame', 4], ['elemCount', 2], ['nodeCount', 2]],
  NC: [['frame', 4], ['idx', 2], ['kind', 2], ['n0', 2], ['n1', 2], ['valueBcd', 3], ['unit', 2]],
  NE: [['frame', 4], ['elemCount', 2], ['nodeCount', 2]],
  VB: [['frame', 4], ['nodeCount', 2], ['status', 2]],
  VN: [['frame', 4], ['node', 2], ['valueBits', 8]],
  VE: [['frame', 4], ['nodeCount', 2], ['status', 2]],
  ER: [['frame', 4], ['code', 2], ['arg', 4]],
};

export const CRLF = '\r\n';

export class UartParseError extends Error {}

export function xorChecksum(payload: string): number {
  let sum = 0;
  for (let i = 0; i < payload.length; i++) {
    const c = payload.charCodeAt(i);
    if (c > 0x7f) throw new UartParseError('payload is not ASCII');
    sum ^= c;
  }
  return sum;
}

const hex = (value: number, width: number) => value.toString(16).toUpperCase().padStart(width, '0');

export function recordPayload(rec: UartRecord): string {
  const layout = RECORD_LAYOUT[rec.type];
  if (!layout) throw new TypeError(`unknown record type ${String((rec as { type: unknown }).type)}`);
  const fields = layout.map(([name, width]) => {
    const value = (rec as unknown as Record<string, number>)[name];
    if (!Number.isInteger(value) || value! < 0 || value! >= 16 ** width) {
      throw new RangeError(`${rec.type}.${name} = ${value} does not fit ${width} hex digits`);
    }
    return hex(value!, width);
  });
  return [rec.type, ...fields].join(',');
}

/** One record as wire text, including the trailing CRLF. */
export function encodeRecord(rec: UartRecord): string {
  const payload = recordPayload(rec);
  return `@${payload}*${hex(xorChecksum(payload), 2)}${CRLF}`;
}

export function netlistRecords(n: Netlist): UartRecord[] {
  const elemCount = n.elements.length;
  if (elemCount > 0xff) throw new RangeError(`${elemCount} elements exceed elem_count`);
  if (n.nodeCount > 0xfe) throw new RangeError(`node_count ${n.nodeCount} exceeds 0xFE`);
  const { frame, nodeCount } = n;
  return [
    { type: 'NB', frame, elemCount, nodeCount },
    ...n.elements.map((e): UartRecord => ({ type: 'NC', frame, idx: e.idx, kind: e.kind, n0: e.n0, n1: e.n1, valueBcd: e.valueBcd, unit: e.unit })),
    { type: 'NE', frame, elemCount, nodeCount },
  ];
}

/** float32 bit patterns of a voltage vector, without NaN canonicalisation. */
export function float32Bits(values: Float32Array): Uint32Array {
  return new Uint32Array(values.buffer, values.byteOffset, values.length).slice();
}

export function voltageRecords(v: VoltageSnapshot): UartRecord[] {
  const nodeCount = v.voltages.length;
  if (nodeCount > 0xfe) throw new RangeError(`node_count ${nodeCount} exceeds 0xFE`);
  const { frame, status } = v;
  return [
    { type: 'VB', frame, nodeCount, status },
    ...Array.from(float32Bits(v.voltages), (valueBits, node): UartRecord => ({ type: 'VN', frame, node, valueBits })),
    { type: 'VE', frame, nodeCount, status },
  ];
}

export const encodeRecords = (records: readonly UartRecord[]): string => records.map(encodeRecord).join('');
export const encodeNetlist = (n: Netlist): string => encodeRecords(netlistRecords(n));
export const encodeVoltages = (v: VoltageSnapshot): string => encodeRecords(voltageRecords(v));
export const encodeError = (frame: number, code: number, arg: number): string => encodeRecord({ type: 'ER', frame, code, arg });

const HEX_FIELD = /^[0-9A-F]+$/;

/** Decode one line. Surrounding whitespace (the CRLF) is ignored, as in protocol.py. */
export function decodeRecord(line: string): UartRecord {
  const text = line.trim();
  const star = text.lastIndexOf('*');
  if (!text.startsWith('@') || star < 0) throw new UartParseError('invalid framing');
  const payload = text.slice(1, star);
  const sumText = text.slice(star + 1);
  if (sumText.length !== 2 || !HEX_FIELD.test(sumText)) throw new UartParseError(`invalid checksum field ${JSON.stringify(sumText)}`);
  const expected = xorChecksum(payload);
  if (Number.parseInt(sumText, 16) !== expected) {
    throw new UartParseError(`checksum mismatch: got ${sumText}, expected ${hex(expected, 2)}`);
  }
  const [tag, ...fields] = payload.split(',');
  const layout = RECORD_LAYOUT[tag as RecordType];
  if (!layout || fields.length !== layout.length) throw new UartParseError(`unsupported payload ${JSON.stringify(payload)}`);
  const rec: Record<string, number | string> = { type: tag! };
  layout.forEach(([name, width], i) => {
    const f = fields[i]!;
    if (f.length !== width || !HEX_FIELD.test(f)) throw new UartParseError(`expected ${width} uppercase hex chars for ${name}, got ${JSON.stringify(f)}`);
    rec[name] = Number.parseInt(f, 16);
  });
  return rec as unknown as UartRecord;
}

export interface ParsedLine { line: number; text: string; record?: UartRecord; error?: string }

export interface ParsedStream {
  lines: ParsedLine[];
  netlists: Netlist[];
  voltages: VoltageSnapshot[];
  errors: Extract<UartRecord, { type: 'ER' }>[];
  /** Framing, checksum, terminator and sequencing problems, in stream order. */
  problems: string[];
}

/** Parse a captured stream (e.g. the RTL's RsTx bytes as text) into snapshots.
 * Sequencing follows protocol.py's SnapshotAssembler; where it would raise, a
 * problem is recorded and the open snapshot is discarded. Lines must end in CRLF.
 */
export function parseUartStream(text: string): ParsedStream {
  const out: ParsedStream = { lines: [], netlists: [], voltages: [], errors: [], problems: [] };
  let netBegin: Extract<UartRecord, { type: 'NB' }> | null = null;
  let netElems: Netlist['elements'] = [];
  let voltBegin: Extract<UartRecord, { type: 'VB' }> | null = null;
  let voltNodes: Extract<UartRecord, { type: 'VN' }>[] = [];
  const raw = text.split('\n');
  const incomplete = raw[raw.length - 1] !== '';
  if (!incomplete) raw.pop();
  raw.forEach((piece, i) => {
    const n = i + 1;
    const problem = (msg: string) => out.problems.push(`line ${n}: ${msg}`);
    const entry: ParsedLine = { line: n, text: piece.replace(/\r$/, '') };
    out.lines.push(entry);
    const complete = i < raw.length - 1 || text.endsWith('\n');
    if (complete && !piece.endsWith('\r')) problem('line not terminated by CRLF');
    let rec: UartRecord;
    try {
      rec = decodeRecord(piece);
      if (piece.replace(/\r$/, '') !== piece.trim()) problem('extra whitespace around record');
    } catch (err) {
      entry.error = (err as Error).message;
      problem(entry.error);
      return;
    }
    entry.record = rec;
    switch (rec.type) {
      case 'NB':
        if (netBegin) problem(`NB for frame ${rec.frame} discards open netlist ${netBegin.frame}`);
        netBegin = rec; netElems = [];
        return;
      case 'NC':
        if (!netBegin || rec.frame !== netBegin.frame) { problem('netlist component without matching begin'); return; }
        netElems.push({ idx: rec.idx, kind: rec.kind, n0: rec.n0, n1: rec.n1, valueBcd: rec.valueBcd, unit: rec.unit });
        return;
      case 'NE': {
        const b = netBegin;
        netBegin = null;
        if (!b) { problem('netlist end without begin'); return; }
        if (rec.frame !== b.frame) { problem('netlist end frame mismatch'); return; }
        if (rec.elemCount !== b.elemCount || rec.nodeCount !== b.nodeCount) { problem('netlist end count mismatch'); return; }
        if (netElems.length !== b.elemCount) { problem('netlist component count mismatch'); return; }
        out.netlists.push({ frame: b.frame, nodeCount: b.nodeCount, elements: netElems });
        return;
      }
      case 'VB':
        if (voltBegin) problem(`VB for frame ${rec.frame} discards open voltage snapshot ${voltBegin.frame}`);
        voltBegin = rec; voltNodes = [];
        return;
      case 'VN':
        if (!voltBegin || rec.frame !== voltBegin.frame) { problem('voltage node without matching begin'); return; }
        voltNodes.push(rec);
        return;
      case 'VE': {
        const b = voltBegin;
        voltBegin = null;
        if (!b) { problem('voltage end without begin'); return; }
        if (rec.frame !== b.frame) { problem('voltage end frame mismatch'); return; }
        if (rec.nodeCount !== b.nodeCount || rec.status !== b.status) { problem('voltage end mismatch'); return; }
        if (voltNodes.length !== b.nodeCount) { problem('voltage node count mismatch'); return; }
        const bits = new Uint32Array(b.nodeCount);
        const seen = new Set<number>();
        for (const v of voltNodes) {
          if (v.node >= b.nodeCount || seen.has(v.node)) { problem(`voltage node ${v.node} out of range or repeated`); return; }
          seen.add(v.node);
          bits[v.node] = v.valueBits;
        }
        out.voltages.push({ frame: b.frame, status: b.status, voltages: new Float32Array(bits.buffer) });
        return;
      }
      case 'ER':
        if (rec.code === 0x85) {
          if (!netBegin || rec.frame !== netBegin.frame) problem('abort without matching netlist begin');
          else if (rec.arg !== netElems.length) problem('abort component count mismatch');
          netBegin = null; netElems = [];
        }
        out.errors.push(rec);
        return;
    }
  });
  if (incomplete && raw.length) out.problems.push(`line ${raw.length}: incomplete final line`);
  if (netBegin) out.problems.push(`end of stream inside netlist ${(netBegin as { frame: number }).frame}`);
  if (voltBegin) out.problems.push(`end of stream inside voltage snapshot ${(voltBegin as { frame: number }).frame}`);
  return out;
}

/** D-024: prefix of a snapshot interrupted by an edit after its begin. */
export function encodeAbortedNetlist(n: Netlist, completedComponents: number): string {
  if (!Number.isInteger(completedComponents) || completedComponents < 0 || completedComponents > n.elements.length) {
    throw new RangeError('invalid completed component count');
  }
  return encodeRecords(netlistRecords(n).slice(0, 1 + completedComponents))
    + encodeError(n.frame, 0x85, completedComponents);
}
