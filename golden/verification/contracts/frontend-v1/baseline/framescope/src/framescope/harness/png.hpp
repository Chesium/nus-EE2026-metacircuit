// RGB8 image output for monitors.
#pragma once

#include <cstddef>
#include <cstdint>
#include <string>

namespace fs {

// Writes an 8-bit RGB PNG; `stride` is the byte distance between rows.
bool write_png_rgb(const std::string& path, const uint8_t* rgb, int width, int height, size_t stride);

// CRC-32 over the visible bytes of an RGB image (row padding excluded).
uint32_t crc32_rgb(const uint8_t* rgb, int width, int height, size_t stride);

}  // namespace fs
