// Binary serialization of harness-side state for boot checkpoints (the
// Verilator model itself is saved with VerilatedSave, see main.cpp).
// Values are written in host byte order: a checkpoint is only restored by the
// binary that wrote it.
#pragma once

#include <cstdint>
#include <cstring>
#include <map>
#include <string>
#include <type_traits>
#include <vector>

namespace fs {

class StateWriter {
 public:
  template <class T>
  void pod(const T& v) {
    static_assert(std::is_trivially_copyable<T>::value, "pod() needs a trivially copyable type");
    const auto* p = reinterpret_cast<const uint8_t*>(&v);
    buf_.insert(buf_.end(), p, p + sizeof v);
  }
  void str(const std::string& s) {
    pod<uint64_t>(s.size());
    buf_.insert(buf_.end(), s.begin(), s.end());
  }
  template <class T>
  void vec(const std::vector<T>& v) {
    pod<uint64_t>(v.size());
    for (const T& x : v) pod(x);
  }
  void bytes(const std::vector<uint8_t>& v) {
    pod<uint64_t>(v.size());
    buf_.insert(buf_.end(), v.begin(), v.end());
  }
  void map(const std::map<int, int>& m) {
    pod<uint64_t>(m.size());
    for (const auto& kv : m) {
      pod(kv.first);
      pod(kv.second);
    }
  }
  const std::vector<uint8_t>& data() const { return buf_; }

 private:
  std::vector<uint8_t> buf_;
};

// Reads what StateWriter wrote; ok() turns false on any overrun.
class StateReader {
 public:
  explicit StateReader(std::vector<uint8_t> data) : buf_(std::move(data)) {}
  template <class T>
  void pod(T& v) {
    static_assert(std::is_trivially_copyable<T>::value, "pod() needs a trivially copyable type");
    if (!take(sizeof v)) return;
    std::memcpy(&v, &buf_[pos_ - sizeof v], sizeof v);
  }
  void str(std::string& s) {
    uint64_t n = 0;
    pod(n);
    if (!take(n)) return;
    s.assign(reinterpret_cast<const char*>(&buf_[pos_ - n]), n);
  }
  template <class T>
  void vec(std::vector<T>& v) {
    uint64_t n = 0;
    pod(n);
    if (n > buf_.size()) { ok_ = false; return; }
    v.assign(n, T{});
    for (auto& x : v) pod(x);
  }
  void vec(std::vector<bool>& v) {
    std::vector<uint8_t> b;
    vec(b);
    v.assign(b.begin(), b.end());
  }
  void bytes(std::vector<uint8_t>& v) {
    uint64_t n = 0;
    pod(n);
    if (!take(n)) return;
    v.assign(buf_.begin() + (pos_ - n), buf_.begin() + pos_);
  }
  void map(std::map<int, int>& m) {
    uint64_t n = 0;
    pod(n);
    m.clear();
    for (uint64_t i = 0; i < n && ok_; ++i) {
      int k = 0, v = 0;
      pod(k);
      pod(v);
      m[k] = v;
    }
  }
  bool ok() const { return ok_; }
  bool at_end() const { return pos_ == buf_.size(); }

 private:
  bool take(uint64_t n) {
    if (!ok_ || n > buf_.size() - pos_) {
      ok_ = false;
      return false;
    }
    pos_ += n;
    return true;
  }
  std::vector<uint8_t> buf_;
  size_t pos_ = 0;
  bool ok_ = true;
};

}  // namespace fs
