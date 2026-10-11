#include "png.hpp"

#include <zlib.h>

#include <cstdio>
#include <filesystem>
#include <vector>

namespace fs {
namespace {

void put_u32(std::vector<uint8_t>& v, uint32_t x) {
  v.push_back(static_cast<uint8_t>(x >> 24));
  v.push_back(static_cast<uint8_t>(x >> 16));
  v.push_back(static_cast<uint8_t>(x >> 8));
  v.push_back(static_cast<uint8_t>(x));
}

void write_chunk(FILE* f, const char type[4], const std::vector<uint8_t>& data) {
  std::vector<uint8_t> buf;
  put_u32(buf, static_cast<uint32_t>(data.size()));
  buf.insert(buf.end(), type, type + 4);
  buf.insert(buf.end(), data.begin(), data.end());
  const uint32_t crc = crc32(0, buf.data() + 4, static_cast<uInt>(buf.size() - 4));
  put_u32(buf, crc);
  fwrite(buf.data(), 1, buf.size(), f);
}

}  // namespace

bool write_png_rgb(const std::string& path, const uint8_t* rgb, int width, int height, size_t stride) {
  if (width <= 0 || height <= 0) return false;
  std::error_code ec;
  std::filesystem::create_directories(std::filesystem::path(path).parent_path(), ec);

  const size_t row = static_cast<size_t>(width) * 3;
  std::vector<uint8_t> raw;
  raw.reserve((row + 1) * height);
  for (int y = 0; y < height; ++y) {
    raw.push_back(0);  // filter: none
    const uint8_t* src = rgb + stride * y;
    raw.insert(raw.end(), src, src + row);
  }
  uLongf zlen = compressBound(static_cast<uLong>(raw.size()));
  std::vector<uint8_t> z(zlen);
  if (compress2(z.data(), &zlen, raw.data(), static_cast<uLong>(raw.size()), 3) != Z_OK) return false;
  z.resize(zlen);

  FILE* f = fopen(path.c_str(), "wb");
  if (!f) return false;
  static const uint8_t sig[8] = {0x89, 'P', 'N', 'G', '\r', '\n', 0x1a, '\n'};
  fwrite(sig, 1, sizeof sig, f);
  std::vector<uint8_t> ihdr;
  put_u32(ihdr, static_cast<uint32_t>(width));
  put_u32(ihdr, static_cast<uint32_t>(height));
  ihdr.insert(ihdr.end(), {8, 2, 0, 0, 0});  // 8-bit, truecolour, deflate, no filter, no interlace
  write_chunk(f, "IHDR", ihdr);
  write_chunk(f, "IDAT", z);
  write_chunk(f, "IEND", {});
  return fclose(f) == 0;
}

uint32_t crc32_rgb(const uint8_t* rgb, int width, int height, size_t stride) {
  uLong crc = crc32(0, nullptr, 0);
  for (int y = 0; y < height; ++y) crc = crc32(crc, rgb + stride * y, static_cast<uInt>(width * 3));
  return static_cast<uint32_t>(crc);
}

}  // namespace fs
