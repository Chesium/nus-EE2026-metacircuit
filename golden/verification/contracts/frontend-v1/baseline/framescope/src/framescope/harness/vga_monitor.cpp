#include "vga_monitor.hpp"

#include <algorithm>
#include <cstdio>

#include "png.hpp"
#include "profile.hpp"

namespace fs {
namespace {

constexpr int kMaxW = 4096;
constexpr int kMaxH = 4096;
constexpr size_t kStride = static_cast<size_t>(kMaxW) * 3;

void ensure_rows(std::vector<uint8_t>& buf, int rows) {
  const size_t need = kStride * static_cast<size_t>(rows);
  if (buf.size() < need) buf.resize(need, 0);
}

void put(std::vector<uint8_t>& buf, int x, int y, uint8_t r, uint8_t g, uint8_t b) {
  if (x < 0 || y < 0 || x >= kMaxW || y >= kMaxH) return;
  ensure_rows(buf, y + 1);
  uint8_t* p = &buf[kStride * y + static_cast<size_t>(x) * 3];
  p[0] = r;
  p[1] = g;
  p[2] = b;
}

int mode(const std::map<int, int>& hist) {
  int best = -1, count = -1;
  for (const auto& kv : hist) {
    if (kv.second > count) {
      best = kv.first;
      count = kv.second;
    }
  }
  return best;
}

const char* polarity(int active) { return active < 0 ? "unknown" : (active ? "positive" : "negative"); }

uint64_t count_nonblack(const uint8_t* img, int w, int h) {
  uint64_t n = 0;
  for (int y = 0; y < h; ++y) {
    const uint8_t* row = img + kStride * y;
    for (int x = 0; x < w * 3; x += 3) n += (row[x] | row[x + 1] | row[x + 2]) != 0;
  }
  return n;
}

}  // namespace

void VgaMonitor::SyncTrack::update(int raw) {
  if (prev >= 0 && raw != prev) {
    len[prev] = run;
    run = 0;
    ++toggles;
  }
  ++run;
  prev = raw;
  // The first run starts before the simulation does, so wait for a complete
  // run of each level before deciding which one is the sync pulse.
  if (active < 0 && toggles >= 3) active = len[0] < len[1] ? 0 : 1;
}

VgaMonitor::VgaMonitor(VgaConfig cfg, VgaPins pins) : cfg_(std::move(cfg)), pins_(pins) {
  hs_.active = cfg_.hsync_active;
  vs_.active = cfg_.vsync_active;
  cfg_.de_delay = std::clamp(cfg_.de_delay, 0, 63);
}

void VgaMonitor::sample(uint64_t t_ps) {
  const bool pclk = pins_.pclk.get() & 1;
  const bool rise = pclk && !last_pclk_;
  last_pclk_ = pclk;
  if (!rise) return;
  ++pclk_edges_;
  if (!(pins_.pclk_en.get() & 1)) return;
  on_pixel(t_ps);
}

void VgaMonitor::on_pixel(uint64_t t_ps) {
  ++pixels_;
  const int hs_raw = static_cast<int>(pins_.hsync.get() & 1);
  const int vs_raw = static_cast<int>(pins_.vsync.get() & 1);
  hs_.update(hs_raw);
  vs_.update(vs_raw);
  bool de = false;
  if (cfg_.has_de) {
    de_hist_ = (de_hist_ << 1) | (pins_.de.get() & 1);
    de = (de_hist_ >> cfg_.de_delay) & 1;
  }
  if (hs_.active < 0 || vs_.active < 0) return;

  const bool hs = hs_raw == hs_.active;
  const bool vs = vs_raw == vs_.active;
  if (hs && !prev_hs_) {
    begin_line();
  } else if (!hs && prev_hs_ && line_started_) {
    cur_hsync_w_ = x_;
  }
  if (vs && !prev_vs_) {
    if (in_frame_) finish_frame(t_ps);
    start_frame(t_ps);
  } else if (!vs && prev_vs_ && in_frame_ && !vs_ended_) {
    vs_width_px_ = frame_px_;
    vs_ended_ = true;
  }
  prev_hs_ = hs;
  prev_vs_ = vs;
  if (in_frame_) {
    pos_line_ = y_;
    pos_px_ = line_px_++;
  }

  if (in_frame_) {
    ++frame_px_;
    const auto r = static_cast<uint8_t>(pins_.red.get());
    const auto g = static_cast<uint8_t>(pins_.green.get());
    const auto b = static_cast<uint8_t>(pins_.blue.get());
    put(raster_, x_, y_, r, g, b);
    if (de) {
      ++de_samples_;
      if (!line_de_) {
        line_de_ = true;
        ax_ = 0;
        if (!frame_de_) {
          frame_de_ = true;
          de_first_x_ = x_;
          de_first_line_ = y_;
        }
        ++active_rows_;
      }
      put(active_, ax_, active_rows_ - 1, r, g, b);
      ++ax_;
    }
  }
  ++x_;
}

void VgaMonitor::begin_line() {
  if (in_frame_ && line_started_) {
    ++line_len_[x_];
    if (cur_hsync_w_ >= 0) ++hsync_w_[cur_hsync_w_];
    if (line_de_) ++de_run_[ax_];
  }
  cur_hsync_w_ = -1;
  line_px_ = 0;
  line_started_ = true;
  line_de_ = false;
  x_ = 0;
  if (in_frame_) ++y_;
}

void VgaMonitor::start_frame(uint64_t t_ps) {
  in_frame_ = true;
  frame_t0_ = t_ps;
  frame_px_ = 0;
  vs_width_px_ = 0;
  vs_ended_ = false;
  y_ = 0;
  line_px_ = 0;
  line_len_.clear();
  hsync_w_.clear();
  de_run_.clear();
  line_de_ = false;
  frame_de_ = false;
  active_rows_ = 0;
  std::fill(raster_.begin(), raster_.end(), 0);
  std::fill(active_.begin(), active_.end(), 0);
}

void VgaMonitor::finish_frame(uint64_t t_ps) {
  const uint64_t index = frames_;
  const int h_total = mode(line_len_);
  const int h_sync = mode(hsync_w_);
  const int v_total = y_;
  const int v_sync = h_total > 0 ? static_cast<int>((vs_width_px_ + h_total / 2) / h_total) : -1;
  const double dur_ps = static_cast<double>(t_ps - frame_t0_);

  JsonObj m;
  m.i64("h_total", h_total).i64("h_sync", h_sync).i64("v_total", v_total).i64("v_sync", v_sync)
      .u64("v_sync_px", vs_width_px_).str("hsync_polarity", polarity(hs_.active))
      .str("vsync_polarity", polarity(vs_.active))
      .num("pixel_rate_hz", dur_ps > 0 ? frame_px_ * 1e12 / dur_ps : 0.0)
      .num("frame_rate_hz", dur_ps > 0 ? 1e12 / dur_ps : 0.0)
      .i64("line_len_min", line_len_.empty() ? -1 : line_len_.begin()->first)
      .i64("line_len_max", line_len_.empty() ? -1 : line_len_.rbegin()->first)
      .u64("distinct_line_lengths", line_len_.size());

  const uint8_t* img = nullptr;
  int img_w = 0, img_h = 0;
  const char* source = "none";
  if (cfg_.has_de && frame_de_) {
    const int h_active = mode(de_run_);
    const int h_bp = de_first_x_ - h_sync;
    const int v_bp = de_first_line_ - v_sync;
    m.i64("h_active", h_active).i64("h_fp", h_total - h_sync - h_bp - h_active).i64("h_bp", h_bp)
        .i64("v_active", active_rows_).i64("v_fp", v_total - v_sync - v_bp - active_rows_).i64("v_bp", v_bp);
    img_w = std::clamp(h_active, 0, kMaxW);
    img_h = std::clamp(active_rows_, 0, kMaxH);
    ensure_rows(active_, img_h);
    img = active_.data();
    source = "de";
  } else if (cfg_.timing.valid && h_sync >= 0 && v_sync >= 0) {
    const int x0 = h_sync + cfg_.timing.h_bp;
    const int y0 = v_sync + cfg_.timing.v_bp;
    if (x0 < kMaxW && y0 < kMaxH) {
      img_w = std::clamp(cfg_.timing.h_active, 0, kMaxW - x0);
      img_h = std::clamp(cfg_.timing.v_active, 0, kMaxH - y0);
      ensure_rows(raster_, y0 + img_h);
      img = raster_.data() + kStride * y0 + static_cast<size_t>(x0) * 3;
      source = "timing";
    }
  }
  const int raster_w = std::clamp(line_len_.empty() ? 0 : line_len_.rbegin()->first, 0, kMaxW);
  const int raster_h = std::clamp(v_total, 0, kMaxH);
  ensure_rows(raster_, raster_h);

  const bool save = ctx_ && ctx_->should_save(index);
  char stem[64];
  snprintf(stem, sizeof stem, "%04llu.png", static_cast<unsigned long long>(index));
  const std::string dir = (ctx_ ? ctx_->out_dir : std::string(".")) + "/" + cfg_.name + "/";

  JsonObj ev;
  ev.str("event", "frame").str("monitor", cfg_.name).u64("index", index).u64("t_ps", t_ps)
      .str("active_source", source).i64("width", img_w).i64("height", img_h);
  if (save && img && img_w > 0 && img_h > 0) {
    ProfileScope prof(Profile::Png);
    const std::string path = dir + "frame_" + stem;
    if (write_png_rgb(path, img, img_w, img_h, kStride)) ev.str("png", path);
  }
  if (save && (!img || (ctx_ && ctx_->save_raster)) && raster_w > 0 && raster_h > 0) {
    ProfileScope prof(Profile::Png);
    const std::string path = dir + "raster_" + stem;
    if (write_png_rgb(path, raster_.data(), raster_w, raster_h, kStride)) ev.str("raster_png", path);
  }
  const uint8_t* crc_img = img ? img : raster_.data();
  const int crc_w = img ? img_w : raster_w;
  const int crc_h = img ? img_h : raster_h;
  char crc[16];
  uint64_t nonblack = 0;
  {
    ProfileScope prof(Profile::Checksum);
    snprintf(crc, sizeof crc, "%08x", crc32_rgb(crc_img, crc_w, crc_h, kStride));
    nonblack = count_nonblack(crc_img, crc_w, crc_h);
  }
  ev.str("crc32", crc).u64("nonblack_pixels", nonblack).obj("measured", m);
  emit(ev);
  ++frames_;
}

bool VgaMonitor::position(int64_t& line, int64_t& pixel) const {
  if (!in_frame_) return false;
  line = pos_line_;
  pixel = pos_px_;
  return true;
}

// Every member except the configuration and pin bindings. The raster buffers
// are mostly zero at a frame boundary, so they compress well.
template <class IO>
void VgaMonitor::state_io(IO& w) {
  w.pod(last_pclk_);
  w.pod(pclk_edges_);
  w.pod(pixels_);
  w.pod(de_samples_);
  w.pod(hs_);
  w.pod(vs_);
  w.pod(prev_hs_);
  w.pod(prev_vs_);
  w.pod(de_hist_);
  w.pod(line_started_);
  w.pod(in_frame_);
  w.pod(x_);
  w.pod(y_);
  w.pod(line_px_);
  w.pod(pos_line_);
  w.pod(pos_px_);
  w.pod(frame_t0_);
  w.pod(frame_px_);
  w.pod(vs_width_px_);
  w.pod(vs_ended_);
  w.pod(cur_hsync_w_);
  w.map(line_len_);
  w.map(hsync_w_);
  w.map(de_run_);
  w.pod(line_de_);
  w.pod(frame_de_);
  w.pod(ax_);
  w.pod(de_first_x_);
  w.pod(de_first_line_);
  w.pod(active_rows_);
  w.pod(frames_);
  w.bytes(raster_);
  w.bytes(active_);
}

bool VgaMonitor::save_state(StateWriter& w) const {
  const_cast<VgaMonitor*>(this)->state_io(w);  // StateWriter only reads
  return true;
}

bool VgaMonitor::load_state(StateReader& r) {
  state_io(r);
  return r.ok();
}

JsonObj VgaMonitor::summary() const {
  JsonObj s;
  s.str("protocol", "vga").u64("frames", frames_).u64("pclk_edges", pclk_edges_).u64("pixels", pixels_)
      .u64("hsync_toggles", hs_.toggles).u64("vsync_toggles", vs_.toggles)
      .str("hsync_polarity", polarity(hs_.active)).str("vsync_polarity", polarity(vs_.active))
      .boolean("has_de", cfg_.has_de).u64("de_samples", de_samples_).boolean("in_frame", in_frame_)
      .i64("partial_frame_lines", in_frame_ ? y_ : 0);
  return s;
}

}  // namespace fs
