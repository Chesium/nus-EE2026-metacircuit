// UART link: decodes a design's serial TX pin into bytes and lines, and drives
// a design input with queued bytes (scripted stimulus or replies from a host
// process that sees each decoded line, in lockstep with simulated time).
#pragma once

#include <cstdint>
#include <deque>
#include <string>
#include <vector>

#include "framescope.hpp"

namespace fs {

struct UartConfig {
  std::string name;
  double baud = 115200.0;
  int data_bits = 8;     // 5..8, least significant bit first
  int parity = 0;        // 0 none, 1 even, 2 odd
  int stop_bits = 1;     // 1 or 2
  int idle = 1;          // line level when idle (= mark = data 1)
  int eol = '\n';        // byte that ends a line, -1: no line assembly
  int max_line = 1024;   // a longer line is cut here
  bool has_tx = false;   // decode pins.tx
  bool has_drive = false;  // drive pins.drive
  bool log_bytes = false;  // one uart_byte event per decoded byte
  int reply_delay_bits = 10;  // default host reply delay after a line's end
};

struct UartPins {
  PortRef tx;     // design output (wrapper tap)
  PortRef drive;  // design input driven by the link's transmitter
};

class UartMonitor : public Monitor {
 public:
  UartMonitor(UartConfig cfg, UartPins pins);
  const std::string& name() const override { return cfg_.name; }
  bool provides_frames() const override { return false; }
  uint64_t frames() const override { return 0; }
  void begin() override;
  void sample(uint64_t t_ps) override;
  uint64_t next_drive_ps() const override;
  void drive(uint64_t t_ps) override;
  bool send(const std::vector<uint8_t>& data, uint64_t not_before_ps, int gap_bits, const std::string& source,
            int64_t id) override;
  bool attach_host() override;
  JsonObj summary() const override;
  bool save_state(StateWriter& w) const override;
  bool load_state(StateReader& r) override;

 private:
  struct Where {
    uint64_t t_ps = 0;
    bool known = false;
    uint64_t frame = 0;
    int64_t line = 0, pixel = 0;
  };
  struct Chunk {
    std::vector<uint8_t> data;
    uint64_t not_before = 0;
    int gap_bits = 0;
    std::string source;
    int64_t id = 0;
    uint64_t seq = 0;
  };

  Where where(uint64_t t_ps) const;
  static void put_where(JsonObj& o, const char* prefix, const Where& w);
  static void save_chunk(StateWriter& w, const Chunk& c);
  static void load_chunk(StateReader& r, Chunk& c);
  int frame_bits() const { return 1 + cfg_.data_bits + (cfg_.parity ? 1 : 0) + cfg_.stop_bits; }
  uint64_t bit_offset(double bits) const;
  void on_bit(int k, int level, uint64_t t_ps);
  void finish_byte(uint64_t t_ps);
  void emit_line(uint64_t t_ps, const char* terminated);
  void error_event(const char* kind, int value, const Where& at);
  void request_reply(const JsonObj& line_event, uint64_t end_ps);
  int level_of(int bit) const { return bit ? cfg_.idle : !cfg_.idle; }

  UartConfig cfg_;
  UartPins pins_;
  double bit_ps_ = 0;

  // Receiver (decodes pins.tx).
  enum class Rx { WaitIdle, Idle, Bits, Done } rx_ = Rx::WaitIdle;
  int last_level_ = -1;
  uint64_t edges_ = 0, last_edge_ps_ = 0, min_pulse_ps_ = UINT64_MAX;
  Where byte_start_;
  int next_bit_ = 0;
  uint64_t next_sample_ps_ = 0, byte_end_ps_ = 0;
  uint32_t shift_ = 0;
  int ones_ = 0;
  bool framing_err_ = false, parity_err_ = false;
  uint64_t bytes_ = 0, lines_ = 0, framing_errors_ = 0, parity_errors_ = 0, glitches_ = 0, error_events_ = 0;
  std::vector<uint8_t> line_;
  Where line_start_;
  uint64_t line_errors_ = 0;
  bool host_ = false, host_ok_ = true;
  uint64_t host_requests_ = 0;

  // Transmitter (drives pins.drive).
  std::vector<Chunk> queue_;  // pending, ordered by (not_before, seq)
  uint64_t seq_ = 0;
  bool tx_active_ = false;
  Chunk cur_;
  Where cur_start_;
  uint64_t cur_queued_ = 0;
  uint64_t cur_t0_ = 0;       // start of the chunk's first start bit
  size_t cur_byte_ = 0;
  int cur_bit_ = 0;           // next level change: bit index within the byte (frame_bits() = byte done)
  uint64_t next_edge_ps_ = 0;
  uint64_t free_at_ps_ = 0;   // the line is idle from here on
  uint64_t sent_bytes_ = 0, sent_chunks_ = 0;
};

}  // namespace fs
