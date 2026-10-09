import { inflateSync } from 'node:zlib';
import { describe, expect, it } from 'vitest';
import { encodePng } from '../src/cli/png.ts';
import { makeFramebuffer, setPx } from '../src/render/framebuffer.ts';

describe('reference PNG encoding', () => {
  it('writes opaque RGB with expanded nibbles and unfiltered rows', () => {
    const fb = makeFramebuffer(2, 1);
    setPx(fb, 0, 0, 0x123); setPx(fb, 1, 0, 0xdef);
    const png = encodePng(fb);
    expect([...png.subarray(0, 8)]).toEqual([137, 80, 78, 71, 13, 10, 26, 10]);
    expect(png.readUInt32BE(16)).toBe(2);
    expect(png.readUInt32BE(20)).toBe(1);
    const length = png.readUInt32BE(33);
    expect(png.toString('ascii', 37, 41)).toBe('IDAT');
    expect([...inflateSync(png.subarray(41, 41 + length))]).toEqual([0, 17, 34, 51, 221, 238, 255]);
  });
  it('rejects transparent or inconsistent input instead of dropping evidence', () => {
    expect(() => encodePng(makeFramebuffer(1, 1))).toThrow('non-opaque');
    expect(() => encodePng({ width: 2, height: 1, data: new Uint8ClampedArray(4) })).toThrow('dimensions');
  });
});
