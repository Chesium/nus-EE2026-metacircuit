// Minimal JSON helpers for the harness's line-delimited event stream.
#pragma once

#include <cstdint>
#include <cstdio>
#include <string>

namespace fs {

inline std::string json_str(const std::string& s) {
  std::string o = "\"";
  for (const char c : s) {
    switch (c) {
      case '"': o += "\\\""; break;
      case '\\': o += "\\\\"; break;
      case '\n': o += "\\n"; break;
      case '\r': o += "\\r"; break;
      case '\t': o += "\\t"; break;
      default:
        if (static_cast<unsigned char>(c) < 0x20) {
          char buf[8];
          snprintf(buf, sizeof buf, "\\u%04x", c);
          o += buf;
        } else {
          o += c;
        }
    }
  }
  return o + "\"";
}

// Builds a JSON object; keys keep insertion order.
class JsonObj {
 public:
  JsonObj& str(const char* k, const std::string& v) { return raw(k, json_str(v)); }
  JsonObj& boolean(const char* k, bool v) { return raw(k, v ? "true" : "false"); }
  JsonObj& i64(const char* k, int64_t v) { return raw(k, std::to_string(v)); }
  JsonObj& u64(const char* k, uint64_t v) { return raw(k, std::to_string(v)); }
  JsonObj& num(const char* k, double v) {
    char buf[32];
    snprintf(buf, sizeof buf, "%.9g", v);
    return raw(k, buf);
  }
  JsonObj& null(const char* k) { return raw(k, "null"); }
  JsonObj& obj(const char* k, const JsonObj& v) { return raw(k, v.dump()); }
  JsonObj& raw(const char* k, const std::string& v) {
    if (!body_.empty()) body_ += ',';
    body_ += json_str(k);
    body_ += ':';
    body_ += v;
    return *this;
  }
  std::string dump() const { return "{" + body_ + "}"; }

 private:
  std::string body_;
};

// Writes one event line to stdout; the Python side parses these.
inline void emit(const JsonObj& o) {
  const std::string line = o.dump();
  fwrite(line.data(), 1, line.size(), stdout);
  fputc('\n', stdout);
  fflush(stdout);
}

}  // namespace fs
