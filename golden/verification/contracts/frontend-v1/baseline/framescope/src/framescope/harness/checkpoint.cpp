// Boot checkpoints: the harness's half of the simulation state. The model and
// its VerilatedContext go to <dir>/model.bin through Model::save/restore
// (Verilator --savable); everything the harness keeps between evaluations
// (clocks, time, eval count, virtual inputs, monitor decoding state) goes to
// <dir>/harness.bin, zlib-compressed. Both are taken at a VSYNC leading edge
// of the first monitor, after that frame boundary's probes and dumps and
// before its frame-triggered stimulus (see Harness::run).
#include <zlib.h>

#include <algorithm>
#include <cstdio>
#include <filesystem>

#include "framescope.hpp"

namespace fs {
namespace {

constexpr char kMagic[8] = {'F', 'S', 'C', 'K', 'P', 'T', '1', '\0'};

bool write_file(const std::string& path, const std::vector<uint8_t>& raw) {
  uLongf zlen = compressBound(static_cast<uLong>(raw.size()));
  std::vector<uint8_t> z(zlen);
  if (compress2(z.data(), &zlen, raw.data(), static_cast<uLong>(raw.size()), 1) != Z_OK) return false;
  FILE* f = fopen(path.c_str(), "wb");
  if (!f) return false;
  const uint64_t n = raw.size();
  fwrite(kMagic, 1, sizeof kMagic, f);
  fwrite(&n, sizeof n, 1, f);
  fwrite(z.data(), 1, zlen, f);
  return fclose(f) == 0;
}

bool read_file(const std::string& path, std::vector<uint8_t>& raw) {
  FILE* f = fopen(path.c_str(), "rb");
  if (!f) return false;
  char magic[sizeof kMagic];
  uint64_t n = 0;
  std::vector<uint8_t> z;
  bool ok = fread(magic, 1, sizeof magic, f) == sizeof magic && std::equal(magic, magic + sizeof magic, kMagic) &&
            fread(&n, sizeof n, 1, f) == 1;
  if (ok) {
    uint8_t buf[1 << 16];
    size_t got;
    while ((got = fread(buf, 1, sizeof buf, f)) > 0) z.insert(z.end(), buf, buf + got);
    raw.resize(n);
    uLongf len = static_cast<uLongf>(n);
    ok = uncompress(raw.data(), &len, z.data(), static_cast<uLong>(z.size())) == Z_OK && len == n;
  }
  fclose(f);
  return ok;
}

}  // namespace

void VirtualInputs::save_state(StateWriter& w) const {
  w.vec(values_);
  w.pod<uint64_t>(names_.size());
  for (const auto& n : names_) w.str(n);
  w.vec(declared_);
}

bool VirtualInputs::load_state(StateReader& r) {
  std::vector<int64_t> values;
  std::vector<bool> declared;
  uint64_t n = 0;
  r.vec(values);
  r.pod(n);
  std::vector<std::string> names(r.ok() && n == values.size() ? n : 0);
  for (auto& s : names) r.str(s);
  r.vec(declared);
  if (!r.ok() || names.size() != values.size() || declared.size() != values.size()) return false;
  values_ = std::move(values);
  names_ = std::move(names);
  declared_ = std::move(declared);
  index_.clear();
  for (size_t i = 0; i < names_.size(); ++i) index_.emplace(names_[i], static_cast<int>(i));
  return true;
}

bool Harness::save_checkpoint(const std::string& dir, const RunState& rs, Model& model) {
  auto fail = [](const std::string& msg) {
    emit(JsonObj().str("event", "error").str("message", "checkpoint: " + msg));
    return false;
  };
  if (!model.save) return fail("the binary was built without --savable");
  std::error_code ec;
  std::filesystem::create_directories(dir, ec);
  StateWriter w;
  w.pod<uint64_t>(clocks_.size());
  for (const auto& c : clocks_) {
    w.pod(c.half_ps);
    w.pod(c.next_ps);
    w.pod(c.level);
  }
  w.pod(rs.t);
  w.pod(rs.evals);
  w.pod(rs.frames);
  virtual_inputs().save_state(w);
  w.pod<uint64_t>(monitors_.size());
  for (const auto& m : monitors_) {
    w.str(m->name());
    if (!m->save_state(w)) return fail("monitor '" + m->name() + "' does not support checkpoints");
  }
  if (!write_file(dir + "/harness.bin", w.data())) return fail("cannot write " + dir + "/harness.bin");
  if (!model.save(dir + "/model.bin")) return fail("cannot write " + dir + "/model.bin");
  emit(JsonObj().str("event", "checkpoint").str("state", "saved").str("path", dir).u64("frame", rs.frames)
           .u64("t_ps", rs.t).u64("evals", rs.evals));
  return true;
}

bool Harness::load_checkpoint(const std::string& dir, RunState& rs, Model& model) {
  auto fail = [](const std::string& msg) {
    emit(JsonObj().str("event", "error").str("message", "checkpoint: " + msg));
    return false;
  };
  if (!model.restore) return fail("the binary was built without --savable");
  std::vector<uint8_t> raw;
  if (!read_file(dir + "/harness.bin", raw)) return fail("cannot read " + dir + "/harness.bin");
  StateReader r(std::move(raw));
  uint64_t nclocks = 0;
  r.pod(nclocks);
  if (nclocks != clocks_.size()) return fail("clock count differs from the binary's");
  for (auto& c : clocks_) {
    uint64_t half = 0;
    r.pod(half);
    r.pod(c.next_ps);
    r.pod(c.level);
    if (half != c.half_ps) return fail("clock '" + c.name + "' has a different period");
  }
  r.pod(rs.t);
  r.pod(rs.evals);
  r.pod(rs.frames);
  if (!virtual_inputs().load_state(r)) return fail("corrupt virtual-input state");
  uint64_t nmon = 0;
  r.pod(nmon);
  if (nmon != monitors_.size()) return fail("monitor count differs from the binary's");
  for (auto& m : monitors_) {
    std::string name;
    r.str(name);
    if (name != m->name()) return fail("monitor '" + name + "' is not '" + m->name() + "'");
    if (!m->load_state(r)) return fail("cannot restore monitor '" + m->name() + "'");
  }
  if (!r.ok() || !r.at_end()) return fail("corrupt " + dir + "/harness.bin");
  if (!model.restore(dir + "/model.bin")) return fail("cannot read " + dir + "/model.bin");
  for (const auto& c : clocks_) c.port.set(c.level);  // also restored with the model; keep them in step
  emit(JsonObj().str("event", "checkpoint").str("state", "restored").str("path", dir).u64("frame", rs.frames)
           .u64("t_ps", rs.t).u64("evals", rs.evals));
  return true;
}

}  // namespace fs
