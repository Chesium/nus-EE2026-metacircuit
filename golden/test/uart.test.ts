import { describe, expect, it } from 'vitest';
import {
  decodeRecord, encodeAbortedNetlist, encodeError, encodeNetlist, encodeRecord, encodeVoltages, float32Bits, parseUartStream, xorChecksum,
  type UartRecord,
} from '../src/backend/uart.ts';
import { ElementKind, GROUND_NODE, type Netlist, type VoltageSnapshot } from '../src/backend/types.ts';
import { int, pick, python, rng, runPython } from './backendRandom.ts';

const sum = (payload: string) => xorChecksum(payload).toString(16).toUpperCase().padStart(2, '0');
const crlf = (...lines: string[]) => lines.map((l) => `${l}\r\n`).join('');

function voltages(frame: number, status: number, bits: number[]): VoltageSnapshot {
  return { frame, status, voltages: new Float32Array(Uint32Array.from(bits).buffer) };
}

describe('uart_link record encoding', () => {
  it('checksums the payload by XOR, matching the README example', () => {
    expect(xorChecksum('NB,0012,03,01')).toBe(0x21);
    expect(encodeRecord({ type: 'NB', frame: 0x12, elemCount: 3, nodeCount: 1 })).toBe('@NB,0012,03,01*21\r\n');
  });

  it('writes every record type with fixed-width uppercase hex fields', () => {
    const recs: UartRecord[] = [
      { type: 'NC', frame: 0xabcd, idx: 0x1f, kind: 3, n0: GROUND_NODE, n1: 0x0a, valueBcd: 0x999, unit: 5 },
      { type: 'NE', frame: 0, elemCount: 0, nodeCount: 0 },
      { type: 'VB', frame: 1, nodeCount: 2, status: 0 },
      { type: 'VN', frame: 1, node: 0, valueBits: 0xbf800000 },
      { type: 'VE', frame: 1, nodeCount: 2, status: 0xfe },
      { type: 'ER', frame: 0xffff, code: 0x81, arg: 0x0102 },
    ];
    expect(recs.map((r) => encodeRecord(r).split('*')[0])).toEqual([
      '@NC,ABCD,1F,03,FF,0A,999,05', '@NE,0000,00,00', '@VB,0001,02,00', '@VN,0001,00,BF800000', '@VE,0001,02,FE', '@ER,FFFF,81,0102',
    ]);
    for (const r of recs) expect(decodeRecord(encodeRecord(r))).toEqual(r);
  });

  it('rejects fields that do not fit, instead of masking them as protocol.py does', () => {
    expect(() => encodeRecord({ type: 'NC', frame: 0, idx: 0, kind: 1, n0: 0, n1: 0, valueBcd: 0x1000, unit: 0 })).toThrow(RangeError);
    expect(() => encodeRecord({ type: 'NB', frame: 0x10000, elemCount: 0, nodeCount: 0 })).toThrow(RangeError);
    expect(() => encodeRecord({ type: 'VN', frame: 0, node: -1, valueBits: 0 })).toThrow(RangeError);
    expect(() => encodeRecord({ type: 'ER', frame: 0, code: 1.5, arg: 0 })).toThrow(RangeError);
    expect(() => encodeNetlist({ frame: 0, nodeCount: 0xff, elements: [] })).toThrow(/0xFE/);
  });

  it('encodes netlist and voltage snapshots as begin, items, end', () => {
    const n: Netlist = { frame: 5, nodeCount: 2, elements: [{ idx: 0, kind: ElementKind.Resistor, n0: 0, n1: 1, valueBcd: 0x470, unit: 4 }] };
    expect(encodeNetlist(n)).toBe(crlf('@NB,0005,01,02*26', '@NC,0005,00,01,00,01,470,04*13', '@NE,0005,01,02*21'));
    expect(encodeVoltages(voltages(5, 0, [0x40a00000, 0x00000000]))).toBe(
      crlf('@VB,0005,02,00*3F', '@VN,0005,00,40A00000*44', '@VN,0005,01,00000000*30', '@VE,0005,02,00*38'));
    expect(encodeError(5, 3, 1)).toBe('@ER,0005,03,0001*3C\r\n');
  });

  it('keeps float32 bit patterns exactly, including NaN payloads and negative zero', () => {
    const bits = [0x7fc00001, 0x80000000, 0xff800000, 0x00000001];
    const v = voltages(9, 0, bits);
    expect(Array.from(float32Bits(v.voltages))).toEqual(bits);
    const back = parseUartStream(encodeVoltages(v)).voltages[0]!;
    expect(Array.from(float32Bits(back.voltages))).toEqual(bits);
  });
});

describe('uart_link decoding', () => {
  it('rejects bad framing, checksums, widths, tags and lowercase hex', () => {
    expect(() => decodeRecord('NB,0012,03,01*21')).toThrow(/framing/);
    expect(() => decodeRecord('@NB,0012,03,01*22')).toThrow(/checksum mismatch/);
    expect(() => decodeRecord('@NB,0012,03,01*2')).toThrow(/checksum field/);
    expect(() => decodeRecord(`@NB,012,03,01*${sum('NB,012,03,01')}`)).toThrow(/4 uppercase hex/);
    expect(() => decodeRecord(`@NB,00ab,03,01*${sum('NB,00ab,03,01')}`)).toThrow(/uppercase hex/);
    expect(() => decodeRecord(`@XX,0000*${sum('XX,0000')}`)).toThrow(/unsupported payload/);
    expect(() => decodeRecord(`@NB,0000,00*${sum('NB,0000,00')}`)).toThrow(/unsupported payload/);
  });

  it('assembles snapshots and reports sequencing problems', () => {
    const net = encodeNetlist({ frame: 1, nodeCount: 1, elements: [{ idx: 0, kind: 1, n0: 0, n1: GROUND_NODE, valueBcd: 0x100, unit: 0 }] });
    const volt = encodeVoltages(voltages(1, 0, [0x40a00000]));
    const ok = parseUartStream(net + volt + encodeError(2, 0x81, 0));
    expect(ok.problems).toEqual([]);
    expect(ok.netlists).toEqual([{ frame: 1, nodeCount: 1, elements: [{ idx: 0, kind: 1, n0: 0, n1: GROUND_NODE, valueBcd: 0x100, unit: 0 }] }]);
    expect(Array.from(ok.voltages[0]!.voltages)).toEqual([5]);
    expect(ok.errors).toEqual([{ type: 'ER', frame: 2, code: 0x81, arg: 0 }]);
    expect(ok.lines).toHaveLength(7);

    const lines = net.split('\r\n').filter(Boolean);
    const bad = parseUartStream([
      lines[1], // NC without NB
      lines[0], lines[2], // NB then NE: count mismatch
      lines[0], lines[1], lines[1], lines[2], // too many components
      'garbage',
      lines[0], // NB
    ].join('\r\n') + '\n' + lines[0]);
    expect(bad.netlists).toEqual([]);
    expect(bad.problems).toEqual([
      'line 1: netlist component without matching begin',
      'line 3: netlist component count mismatch',
      'line 7: netlist component count mismatch',
      'line 8: invalid framing',
      'line 9: line not terminated by CRLF',
      'line 10: NB for frame 1 discards open netlist 1',
      'line 10: incomplete final line',
      'end of stream inside netlist 1',
    ]);
  });
});

describe.skipIf(python() === null)('cross-check against src/uart_link/protocol.py', () => {
  const r = rng(0x0a17);
  const netlists: Netlist[] = Array.from({ length: 150 }, () => {
    const nodeCount = r() < 0.1 ? pick(r, [0, 0xfe]) : int(r, 0, 20);
    const node = () => (nodeCount === 0 || r() < 0.3 ? GROUND_NODE : int(r, 0, nodeCount - 1));
    return {
      frame: int(r, 0, 0xffff), nodeCount,
      elements: Array.from({ length: r() < 0.05 ? 0xff : int(r, 0, 12) }, (_, idx) => ({
        idx, kind: int(r, 1, 5), n0: node(), n1: node(), valueBcd: int(r, 0, 0xfff), unit: int(r, 0, 6),
      })),
    };
  });
  const snaps: VoltageSnapshot[] = Array.from({ length: 80 }, () =>
    voltages(int(r, 0, 0xffff), r() < 0.8 ? 0 : int(r, 1, 0xff), Array.from({ length: int(r, 0, 16) }, () => Math.floor(r() * 2 ** 32))));
  const errors = Array.from({ length: 40 }, () => ({ frame: int(r, 0, 0xffff), code: int(r, 0, 0xff), arg: int(r, 0, 0xffff) }));

  const req = {
    netlists: netlists.map((n) => ({
      frame: n.frame, elem_count: n.elements.length, node_count: n.nodeCount,
      components: n.elements.map((e) => ({ idx: e.idx, kind: e.kind, n0: e.n0, n1: e.n1, value_bcd: e.valueBcd, unit: e.unit })),
    })),
    voltages: snaps.map((v) => ({
      frame: v.frame, node_count: v.voltages.length, status: v.status,
      values: Array.from(float32Bits(v.voltages), (value_bits, node) => ({ node, value_bits })),
    })),
    errors,
  };
  type Res = { netlists: string[]; voltages: string[]; errors: string[]; decode: Record<string, unknown>[] };

  it('produces byte-identical text for random netlists, voltage snapshots and errors', () => {
    const res = runPython('tools/uart_protocol_ref.py', [], req) as Res;
    expect(netlists.map(encodeNetlist)).toEqual(res.netlists);
    expect(snaps.map(encodeVoltages)).toEqual(res.voltages);
    expect(errors.map((e) => encodeError(e.frame, e.code, e.arg))).toEqual(res.errors);
  });

  it('decodes the same records, and rejects the same corrupt lines', () => {
    const good = [...netlists.slice(0, 20).map(encodeNetlist), ...snaps.slice(0, 20).map(encodeVoltages), ...errors.slice(0, 5).map((e) => encodeError(e.frame, e.code, e.arg))]
      .join('').split('\r\n').filter(Boolean).map((l) => `${l}\r\n`);
    const corrupt = good.slice(0, 40).map((l, i) => {
      const body = l.slice(0, -2);
      switch (i % 4) {
        case 0: return body.slice(0, -1) + (body.endsWith('0') ? '1' : '0') + '\r\n'; // checksum
        case 1: return body.replace(',', ',0') + '\r\n'; // field width (checksum also off)
        case 2: return body.replace('@', '') + '\r\n'; // framing
        default: { // unknown tag with a valid checksum
          const payload = body.slice(1, body.lastIndexOf('*')).replace(/^[A-Z]{2}/, 'QQ');
          return `@${payload}*${sum(payload)}\r\n`;
        }
      }
    });
    const lines = [...good, ...corrupt];
    const res = runPython('tools/uart_protocol_ref.py', [], { decode: lines }) as Res;
    lines.forEach((line, i) => {
      const py = res.decode[i]!;
      let ts: UartRecord | null = null;
      try { ts = decodeRecord(line); } catch { ts = null; }
      if ('error' in py) {
        expect(ts, `line ${JSON.stringify(line)}: protocol.py rejects (${String(py.error)})`).toBeNull();
        return;
      }
      expect(ts, `line ${JSON.stringify(line)}`).not.toBeNull();
      const { type, ...fields } = py;
      const want: Record<string, unknown> = { type };
      const rename: Record<string, string> = {
        elem_count: 'elemCount', node_count: 'nodeCount', value_bcd: 'valueBcd', value_bits: 'valueBits',
      };
      for (const [k, v] of Object.entries(fields)) want[rename[k] ?? k] = v;
      expect(ts).toEqual(want);
    });
  });

  it('is stricter than protocol.py about lowercase hex (spec: uppercase)', () => {
    const line = `@NB,00ab,03,01*${sum('NB,00ab,03,01')}\r\n`;
    const res = runPython('tools/uart_protocol_ref.py', [], { decode: [line] }) as Res;
    expect(res.decode[0]).toEqual({ type: 'NB', frame: 0xab, elem_count: 3, node_count: 1 });
    expect(() => decodeRecord(line)).toThrow(/uppercase/);
  });
});


describe('D-024 interrupted netlists', () => {
  const n: Netlist = { frame: 7, nodeCount: 1, elements: [
    { idx: 0, kind: 1, n0: 0, n1: 255, valueBcd: 0x100, unit: 0 },
  ] };
  it('closes a prefix with ER 85 and accepts the following snapshot', () => {
    for (const count of [0, 1]) {
      const parsed = parseUartStream(encodeAbortedNetlist(n, count) + encodeNetlist({ ...n, frame: 8 }));
      expect(parsed.problems).toEqual([]);
      expect(parsed.errors).toEqual([{ type: 'ER', frame: 7, code: 0x85, arg: count }]);
      expect(parsed.netlists).toEqual([{ ...n, frame: 8 }]);
    }
  });
  it('rejects incorrect abort ids and component counts', () => {
    const prefix = encodeNetlist(n).split('\r\n').slice(0, 2).join('\r\n') + '\r\n';
    expect(parseUartStream(prefix + encodeError(7, 0x85, 0)).problems).toContain('line 3: abort component count mismatch');
    expect(parseUartStream(prefix + encodeError(8, 0x85, 1)).problems).toContain('line 3: abort without matching netlist begin');
  });
});
