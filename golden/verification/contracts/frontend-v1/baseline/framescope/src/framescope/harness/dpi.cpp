// DPI functions imported by rtl/framescope_dpi_pkg.sv. Sim-only stub modules
// use fs_input_* to read values the harness sets from stimulus ("virtual
// inputs"); the generated wrapper uses fs_dump_* to hand memory contents to the
// harness (see Harness::write_dump).
#include "framescope.hpp"

extern "C" int fs_input_handle(const char* name) { return fs::virtual_inputs().handle(name); }

extern "C" long long fs_input_get(int handle) { return fs::virtual_inputs().get(handle); }

extern "C" void fs_dump_begin(int mem, int width, int depth) {
  fs::DumpBuffer& b = fs::dump_buffer();
  b.mem = mem;
  b.width = width;
  b.depth = depth < 0 ? 0 : depth;
  b.chunks = width > 0 ? (width + 63) / 64 : 1;
  b.data.assign(static_cast<size_t>(b.depth) * b.chunks, 0);
}

extern "C" void fs_dump_word(int mem, int index, int chunk, long long value) {
  fs::DumpBuffer& b = fs::dump_buffer();
  if (mem != b.mem || index < 0 || index >= b.depth || chunk < 0 || chunk >= b.chunks) return;
  b.data[static_cast<size_t>(index) * b.chunks + chunk] = static_cast<uint64_t>(value);
}
