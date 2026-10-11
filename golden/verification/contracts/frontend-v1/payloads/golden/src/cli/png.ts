// Node-only PNG output. Filter 0 keeps reference decoding fast in framescope.
import { deflateSync } from 'node:zlib';
import type { Framebuffer } from '../render/framebuffer.ts';

function crc32(data: Uint8Array): number {
  let crc = 0xffffffff;
  for (const byte of data) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function chunk(kind: string, body: Uint8Array): Buffer {
  const data = Buffer.concat([Buffer.from(kind, 'ascii'), body]);
  const out = Buffer.alloc(data.length + 8);
  out.writeUInt32BE(body.length, 0);
  data.copy(out, 4);
  out.writeUInt32BE(crc32(data), out.length - 4);
  return out;
}

export function encodePng(fb: Framebuffer): Buffer {
  const { width, height, data } = fb;
  if (!Number.isSafeInteger(width) || !Number.isSafeInteger(height) || width <= 0 || height <= 0 || data.length !== width * height * 4) {
    throw new Error('invalid framebuffer dimensions');
  }
  const raw = Buffer.alloc(height * (width * 3 + 1));
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
    const src = (y * width + x) * 4, dst = y * (width * 3 + 1) + 1 + x * 3;
    if (data[src + 3] !== 255) throw new Error(`non-opaque reference pixel (${x}, ${y})`);
    raw[dst] = data[src]!; raw[dst + 1] = data[src + 1]!; raw[dst + 2] = data[src + 2]!;
  }
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width, 0); header.writeUInt32BE(height, 4);
  header[8] = 8; header[9] = 2;
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', header), chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);
}
