// Opt-in wall-clock breakdown of a run (`--profile`): where the time goes
// between the model's eval(), the monitors, PNG encoding, checksums, probes
// and dumps. Off by default; when on, each timed section costs two
// steady_clock reads (~40 ns), so per-eval sections inflate the total a little.
#pragma once

#include <chrono>

#include "json.hpp"

namespace fs {

struct Profile {
  enum Section { Eval, Monitor, Png, Checksum, Probes, Dump, Checkpoint, Count };
  bool on = false;
  double seconds[Count] = {};
  uint64_t calls[Count] = {};

  JsonObj json(double wall) const {
    static const char* names[Count] = {"eval", "monitor", "png", "checksum", "probes", "dump", "checkpoint"};
    JsonObj o;
    double sum = 0;
    for (int i = 0; i < Count; ++i) {
      o.obj(names[i], JsonObj().num("s", seconds[i]).u64("calls", calls[i]));
      // PNG and checksum time is spent inside the monitor's sample().
      if (i != Png && i != Checksum) sum += seconds[i];
    }
    o.num("other_s", wall - sum).num("wall_s", wall);
    return o;
  }
};

inline Profile& profile() {
  static Profile p;
  return p;
}

// Times one section when profiling is on.
class ProfileScope {
 public:
  explicit ProfileScope(Profile::Section s) : s_(s), on_(profile().on) {
    if (on_) t0_ = std::chrono::steady_clock::now();
  }
  ~ProfileScope() {
    if (!on_) return;
    Profile& p = profile();
    p.seconds[s_] += std::chrono::duration<double>(std::chrono::steady_clock::now() - t0_).count();
    ++p.calls[s_];
  }
  ProfileScope(const ProfileScope&) = delete;
  ProfileScope& operator=(const ProfileScope&) = delete;

 private:
  Profile::Section s_;
  bool on_;
  std::chrono::steady_clock::time_point t0_;
};

}  // namespace fs
