#include "uart_monitor.hpp"

#include "state.hpp"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <sstream>

namespace fs {
namespace {

constexpr uint64_t kMaxErrorEvents = 200;

std::string hex_bytes(const std::vector<uint8_t>& data) {
  static const char* digits = "0123456789ABCDEF";
  std::string s;
  s.reserve(data.size() * 2);
  for (const uint8_t b : data) {
    s += digits[b >> 4];
    s += digits[b & 15];
  }
  return s;
}

bool parse_hex(const std::string& s, std::vector<uint8_t>& out) {
  out.clear();
  if (s.size() % 2) return false;
  for (size_t i = 0; i < s.size(); i += 2) {
    char buf[3] = {s[i], s[i + 1], 0};
    char* end = nullptr;
    const long v = std::strtol(buf, &end, 16);
    if (end != buf + 2) return false;
    out.push_back(static_cast<uint8_t>(v));
  }
  return true;
}

}  // namespace

UartMonitor::UartMonitor(UartConfig cfg, UartPins pins) : cfg_(std::move(cfg)), pins_(pins) {
  cfg_.data_bits = std::clamp(cfg_.data_bits, 5, 8);
  cfg_.stop_bits = std::clamp(cfg_.stop_bits, 1, 2);
  cfg_.idle &= 1;
  bit_ps_ = 1e12 / cfg_.baud;
}

uint64_t UartMonitor::bit_offset(double bits) const { return static_cast<uint64_t>(std::llround(bits * bit_ps_)); }

void UartMonitor::begin() {
  if (cfg_.has_drive) pins_.drive.set(static_cast<uint64_t>(cfg_.idle));
}

bool UartMonitor::attach_host() {
  if (!cfg_.has_tx || cfg_.eol < 0) return false;
  host_ = true;
  return true;
}

UartMonitor::Where UartMonitor::where(uint64_t t_ps) const {
  Where w;
  w.t_ps = t_ps;
  const Monitor* p = ctx_ ? ctx_->primary : nullptr;
  if (p && p->position(w.line, w.pixel)) {
    w.known = true;
    w.frame = p->frames();
  }
  return w;
}

void UartMonitor::put_where(JsonObj& o, const char* prefix, const Where& w) {
  const std::string p(prefix);
  if (w.known) {
    o.u64((p + "frame").c_str(), w.frame).i64((p + "line").c_str(), w.line).i64((p + "pixel").c_str(), w.pixel);
  } else {
    o.null((p + "frame").c_str()).null((p + "line").c_str()).null((p + "pixel").c_str());
  }
}

// ---------------------------------------------------------------- receiver

void UartMonitor::sample(uint64_t t_ps) {
  if (!cfg_.has_tx) return;
  const int v = static_cast<int>(pins_.tx.get() & 1);
  // Bit centres that passed since the previous evaluation saw the previous level.
  while (rx_ == Rx::Bits && next_sample_ps_ <= t_ps) {
    const int level = next_sample_ps_ < t_ps ? last_level_ : v;
    on_bit(next_bit_++, level, t_ps);
    next_sample_ps_ = byte_start_.t_ps + bit_offset(next_bit_ + 0.5);
  }
  const bool edge = last_level_ >= 0 && v != last_level_;
  if (edge) {
    if (edges_ > 0) min_pulse_ps_ = std::min(min_pulse_ps_, t_ps - last_edge_ps_);
    ++edges_;
    last_edge_ps_ = t_ps;
  }
  // A byte ends after its stop bits, or at the next start bit if the sender's
  // bit clock is slightly fast.
  if (rx_ == Rx::Done && (t_ps >= byte_end_ps_ || (edge && v != cfg_.idle))) finish_byte(t_ps);
  if (rx_ == Rx::WaitIdle && v == cfg_.idle) {
    rx_ = Rx::Idle;
  } else if (rx_ == Rx::Idle && edge && v != cfg_.idle) {
    rx_ = Rx::Bits;
    byte_start_ = where(t_ps);
    next_bit_ = 0;
    next_sample_ps_ = t_ps + bit_offset(0.5);
    shift_ = 0;
    ones_ = 0;
    framing_err_ = parity_err_ = false;
  }
  last_level_ = v;
}

void UartMonitor::on_bit(int k, int level, uint64_t t_ps) {
  const int bit = level == cfg_.idle ? 1 : 0;
  const int parity_at = cfg_.parity ? cfg_.data_bits + 1 : -1;
  if (k == 0) {
    if (bit) {  // the line went back to idle before the middle of the start bit
      ++glitches_;
      if (error_events_ < kMaxErrorEvents) error_event("glitch", -1, byte_start_);
      rx_ = Rx::Idle;
    }
    return;
  }
  if (k <= cfg_.data_bits) {
    shift_ |= static_cast<uint32_t>(bit) << (k - 1);
    ones_ += bit;
  } else if (k == parity_at) {
    const int total = ones_ + bit;
    parity_err_ = (cfg_.parity == 1) ? (total & 1) != 0 : (total & 1) == 0;
  } else if (!bit) {
    framing_err_ = true;  // a stop bit was not at the idle level
  }
  if (k + 1 == frame_bits()) {
    rx_ = Rx::Done;
    byte_end_ps_ = byte_start_.t_ps + bit_offset(frame_bits());
  }
  (void)t_ps;
}

void UartMonitor::error_event(const char* kind, int value, const Where& at) {
  ++error_events_;
  JsonObj ev;
  ev.str("event", "uart_error").str("monitor", cfg_.name).str("kind", kind).i64("value", value)
      .u64("t_ps", at.t_ps);
  put_where(ev, "", at);
  emit(ev);
}

void UartMonitor::finish_byte(uint64_t t_ps) {
  const uint8_t value = static_cast<uint8_t>(shift_ & ((1u << cfg_.data_bits) - 1));
  ++bytes_;
  const bool err = framing_err_ || parity_err_;
  if (framing_err_) {
    ++framing_errors_;
    if (error_events_ < kMaxErrorEvents) error_event("framing", value, byte_start_);
  }
  if (parity_err_) {
    ++parity_errors_;
    if (error_events_ < kMaxErrorEvents) error_event("parity", value, byte_start_);
  }
  if (cfg_.log_bytes) {
    JsonObj ev;
    ev.str("event", "uart_byte").str("monitor", cfg_.name).u64("index", bytes_ - 1).i64("value", value)
        .boolean("framing_error", framing_err_).boolean("parity_error", parity_err_)
        .u64("t_ps", byte_start_.t_ps).u64("end_ps", byte_end_ps_);
    put_where(ev, "", byte_start_);
    emit(ev);
  }
  rx_ = framing_err_ ? Rx::WaitIdle : Rx::Idle;
  if (cfg_.eol < 0) return;
  if (line_.empty()) {
    line_start_ = byte_start_;
    line_errors_ = 0;
  }
  line_.push_back(value);
  if (err) ++line_errors_;
  if (value == cfg_.eol) {
    emit_line(t_ps, "eol");
  } else if (static_cast<int>(line_.size()) >= cfg_.max_line) {
    emit_line(t_ps, "length");
  }
}

void UartMonitor::emit_line(uint64_t t_ps, const char* terminated) {
  JsonObj ev;
  ev.str("event", "uart_line").str("monitor", cfg_.name).u64("index", lines_).str("hex", hex_bytes(line_))
      .u64("bytes", line_.size()).u64("errors", line_errors_).str("terminated", terminated)
      .u64("t_ps", line_start_.t_ps).u64("end_ps", byte_end_ps_);
  put_where(ev, "", line_start_);
  put_where(ev, "end_", where(t_ps));
  const uint64_t end_ps = byte_end_ps_;
  ++lines_;
  line_.clear();
  if (host_ && host_ok_) {
    ev.boolean("await", true);
    request_reply(ev, end_ps);
  } else {
    emit(ev);
  }
}

// The run driver answers an awaited line with "R <delay_bits> <hex>" ("-" for
// no reply) on stdin before the simulation continues, so the reply's timing
// depends only on simulated time.
void UartMonitor::request_reply(const JsonObj& line_event, uint64_t end_ps) {
  ++host_requests_;
  std::string reply;
  if (!host_request(line_event, reply)) {
    host_ok_ = false;
    emit(JsonObj().str("event", "error").str("message", "uart '" + cfg_.name + "': no reply from the host (stdin closed)"));
    return;
  }
  std::istringstream ss(reply);
  std::string tag, hex;
  double delay_bits = -1;
  ss >> tag >> delay_bits >> hex;
  std::vector<uint8_t> data;
  if (tag != "R" || delay_bits < 0 || hex.empty() || (hex != "-" && !parse_hex(hex, data))) {
    host_ok_ = false;
    emit(JsonObj().str("event", "error").str("message", "uart '" + cfg_.name + "': bad host reply '" + reply + "'"));
    return;
  }
  if (!data.empty()) send(data, end_ps + bit_offset(delay_bits), 0, "host", static_cast<int64_t>(lines_ - 1));
}

// ------------------------------------------------------------- transmitter

bool UartMonitor::send(const std::vector<uint8_t>& data, uint64_t not_before_ps, int gap_bits,
                       const std::string& source, int64_t id) {
  if (!cfg_.has_drive) return false;
  if (data.empty()) return true;
  Chunk c{data, not_before_ps, std::max(0, gap_bits), source, id, seq_++};
  auto pos = std::upper_bound(queue_.begin(), queue_.end(), c, [](const Chunk& a, const Chunk& b) {
    return a.not_before != b.not_before ? a.not_before < b.not_before : a.seq < b.seq;
  });
  queue_.insert(pos, std::move(c));
  return true;
}

uint64_t UartMonitor::next_drive_ps() const {
  if (tx_active_) return next_edge_ps_;
  if (!queue_.empty()) return std::max(queue_.front().not_before, free_at_ps_);
  return UINT64_MAX;
}

void UartMonitor::drive(uint64_t t_ps) {
  const int fb = frame_bits();
  auto edge_time = [&](size_t byte, int bit) {
    return cur_t0_ + bit_offset(static_cast<double>(byte) * (fb + cur_.gap_bits) + bit);
  };
  while (next_drive_ps() <= t_ps) {
    if (!tx_active_) {
      cur_ = std::move(queue_.front());
      queue_.erase(queue_.begin());
      tx_active_ = true;
      cur_queued_ = cur_.not_before;
      cur_t0_ = t_ps;
      cur_byte_ = 0;
      cur_bit_ = 0;
      cur_start_ = where(t_ps);
      next_edge_ps_ = cur_t0_;
      continue;
    }
    if (cur_bit_ < fb) {
      const int k = cur_bit_++;
      const uint8_t b = cur_.data[cur_byte_];
      int bit = 1;  // stop bits
      if (k == 0) {
        bit = 0;
      } else if (k <= cfg_.data_bits) {
        bit = (b >> (k - 1)) & 1;
      } else if (cfg_.parity && k == cfg_.data_bits + 1) {
        int ones = 0;
        for (int i = 0; i < cfg_.data_bits; ++i) ones += (b >> i) & 1;
        bit = cfg_.parity == 1 ? (ones & 1) : !(ones & 1);
      }
      pins_.drive.set(static_cast<uint64_t>(level_of(bit)));
      next_edge_ps_ = edge_time(cur_byte_, cur_bit_);
      continue;
    }
    // End of the current byte's stop bits.
    ++sent_bytes_;
    const uint64_t end = next_edge_ps_;
    if (++cur_byte_ < cur_.data.size()) {
      cur_bit_ = 0;
      next_edge_ps_ = edge_time(cur_byte_, 0);
      continue;
    }
    tx_active_ = false;
    free_at_ps_ = end;
    ++sent_chunks_;
    JsonObj ev;
    ev.str("event", "uart_sent").str("monitor", cfg_.name).str("source", cur_.source).i64("id", cur_.id)
        .str("hex", hex_bytes(cur_.data)).u64("bytes", cur_.data.size()).u64("queued_ps", cur_queued_)
        .u64("t_ps", cur_t0_).u64("end_ps", end);
    put_where(ev, "", cur_start_);
    put_where(ev, "end_", where(t_ps));
    emit(ev);
  }
}

JsonObj UartMonitor::summary() const {
  std::string unsent = "[";
  auto add = [&](const Chunk& c, bool started) {
    if (unsent.size() > 1) unsent += ',';
    unsent += JsonObj().str("source", c.source).i64("id", c.id).u64("bytes", c.data.size())
                  .u64("queued_ps", c.not_before).boolean("started", started).dump();
  };
  if (tx_active_) add(cur_, true);
  for (const auto& c : queue_) add(c, false);
  unsent += "]";
  JsonObj s;
  s.str("protocol", "uart").u64("bytes", bytes_).u64("lines", lines_).u64("framing_errors", framing_errors_)
      .u64("parity_errors", parity_errors_).u64("glitches", glitches_).u64("edges", edges_)
      .i64("min_pulse_ps", min_pulse_ps_ == UINT64_MAX ? -1 : static_cast<int64_t>(min_pulse_ps_))
      .i64("level", last_level_).boolean("receiving", rx_ == Rx::Bits || rx_ == Rx::Done)
      .str("pending_hex", hex_bytes(line_)).u64("host_requests", host_requests_)
      .u64("sent_bytes", sent_bytes_).u64("sent_chunks", sent_chunks_).raw("unsent", unsent);
  return s;
}

// ------------------------------------------------------------- checkpoints

void UartMonitor::save_chunk(StateWriter& w, const Chunk& c) {
  w.bytes(c.data);
  w.pod(c.not_before);
  w.pod(c.gap_bits);
  w.str(c.source);
  w.pod(c.id);
  w.pod(c.seq);
}

void UartMonitor::load_chunk(StateReader& r, Chunk& c) {
  r.bytes(c.data);
  r.pod(c.not_before);
  r.pod(c.gap_bits);
  r.str(c.source);
  r.pod(c.id);
  r.pod(c.seq);
}

// Everything that changes while sampling or driving. The configuration and
// host attachment come from the binary and the command line, not the state.
bool UartMonitor::save_state(StateWriter& w) const {
  w.pod<int32_t>(frame_bits());
  w.pod(bit_ps_);
  w.pod(rx_);
  w.pod(last_level_);
  w.pod(edges_);
  w.pod(last_edge_ps_);
  w.pod(min_pulse_ps_);
  w.pod(byte_start_);
  w.pod(next_bit_);
  w.pod(next_sample_ps_);
  w.pod(byte_end_ps_);
  w.pod(shift_);
  w.pod(ones_);
  w.pod(framing_err_);
  w.pod(parity_err_);
  for (uint64_t v : {bytes_, lines_, framing_errors_, parity_errors_, glitches_, error_events_}) w.pod(v);
  w.bytes(line_);
  w.pod(line_start_);
  w.pod(line_errors_);
  w.pod(host_requests_);
  w.pod<uint64_t>(queue_.size());
  for (const auto& c : queue_) save_chunk(w, c);
  w.pod(seq_);
  w.pod(tx_active_);
  save_chunk(w, cur_);
  w.pod(cur_start_);
  w.pod(cur_queued_);
  w.pod(cur_t0_);
  w.pod<uint64_t>(cur_byte_);
  w.pod(cur_bit_);
  w.pod(next_edge_ps_);
  w.pod(free_at_ps_);
  w.pod(sent_bytes_);
  w.pod(sent_chunks_);
  return true;
}

bool UartMonitor::load_state(StateReader& r) {
  int32_t fb = 0;
  double bit_ps = 0;
  r.pod(fb);
  r.pod(bit_ps);
  if (!r.ok() || fb != frame_bits() || bit_ps != bit_ps_) return false;
  r.pod(rx_);
  r.pod(last_level_);
  r.pod(edges_);
  r.pod(last_edge_ps_);
  r.pod(min_pulse_ps_);
  r.pod(byte_start_);
  r.pod(next_bit_);
  r.pod(next_sample_ps_);
  r.pod(byte_end_ps_);
  r.pod(shift_);
  r.pod(ones_);
  r.pod(framing_err_);
  r.pod(parity_err_);
  for (uint64_t* v : {&bytes_, &lines_, &framing_errors_, &parity_errors_, &glitches_, &error_events_}) r.pod(*v);
  r.bytes(line_);
  r.pod(line_start_);
  r.pod(line_errors_);
  r.pod(host_requests_);
  uint64_t n = 0;
  r.pod(n);
  queue_.clear();
  for (uint64_t i = 0; i < n && r.ok(); ++i) {
    Chunk c;
    load_chunk(r, c);
    queue_.push_back(std::move(c));
  }
  r.pod(seq_);
  r.pod(tx_active_);
  load_chunk(r, cur_);
  r.pod(cur_start_);
  r.pod(cur_queued_);
  r.pod(cur_t0_);
  uint64_t cur_byte = 0;
  r.pod(cur_byte);
  cur_byte_ = static_cast<size_t>(cur_byte);
  r.pod(cur_bit_);
  r.pod(next_edge_ps_);
  r.pod(free_at_ps_);
  r.pod(sent_bytes_);
  r.pod(sent_chunks_);
  host_ok_ = true;
  return r.ok() && (!tx_active_ || cur_byte_ < cur_.data.size());
}

}  // namespace fs
