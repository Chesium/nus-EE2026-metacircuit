// VGA monitor: rebuilds frames from sync + RGB taps the way a display would,
// and measures the timing it actually sees at the pins.
#pragma once

#include <map>
#include <vector>

#include "framescope.hpp"

namespace fs {

struct VideoTiming {
  int h_active = 0, h_fp = 0, h_sync = 0, h_bp = 0;
  int v_active = 0, v_fp = 0, v_sync = 0, v_bp = 0;
  bool valid = false;
};

struct VgaPins {
  PortRef pclk, pclk_en, hsync, vsync, red, green, blue, de;
};

struct VgaConfig {
  std::string name;
  bool has_de = false;
  int de_delay = 0;       // pixel clocks between the DE tap and the RGB pins
  int hsync_active = -1;  // 1: active-high, 0: active-low, -1: detect
  int vsync_active = -1;
  VideoTiming timing;     // crops the active area when there is no DE tap
};

class VgaMonitor : public Monitor {
 public:
  VgaMonitor(VgaConfig cfg, VgaPins pins);
  const std::string& name() const override { return cfg_.name; }
  void sample(uint64_t t_ps) override;
  uint64_t frames() const override { return frames_; }
  bool position(int64_t& line, int64_t& pixel) const override;
  JsonObj summary() const override;
  bool save_state(StateWriter& w) const override;
  bool load_state(StateReader& r) override;

 private:
  // Tracks one sync line; the active level is the shorter of two complete runs.
  struct SyncTrack {
    int prev = -1;
    uint64_t run = 0;
    uint64_t len[2] = {0, 0};
    uint64_t toggles = 0;
    int active = -1;
    void update(int raw);
  };

  void on_pixel(uint64_t t_ps);
  void begin_line();
  void start_frame(uint64_t t_ps);
  void finish_frame(uint64_t t_ps);
  template <class IO>
  void state_io(IO& io);  // checkpoint fields, shared by save_state and load_state

  VgaConfig cfg_;
  VgaPins pins_;
  bool last_pclk_ = false;
  uint64_t pclk_edges_ = 0, pixels_ = 0, de_samples_ = 0;
  SyncTrack hs_, vs_;
  bool prev_hs_ = false, prev_vs_ = false;
  uint64_t de_hist_ = 0;

  // Raster position: x counts pixels since the HSYNC leading edge, y counts
  // lines since the line in which VSYNC asserted.
  bool line_started_ = false, in_frame_ = false;
  int x_ = 0, y_ = 0;
  // Stimulus position of the latest sample: line y_, pixel = samples since the
  // line's HSYNC leading edge (or, on line 0, since the VSYNC leading edge).
  int64_t line_px_ = 0, pos_line_ = 0, pos_px_ = 0;
  uint64_t frame_t0_ = 0, frame_px_ = 0, vs_width_px_ = 0;
  bool vs_ended_ = false;
  int cur_hsync_w_ = -1;
  std::map<int, int> line_len_, hsync_w_, de_run_;
  bool line_de_ = false, frame_de_ = false;
  int ax_ = 0, de_first_x_ = 0, de_first_line_ = 0, active_rows_ = 0;
  uint64_t frames_ = 0;
  std::vector<uint8_t> raster_, active_;
};

}  // namespace fs
