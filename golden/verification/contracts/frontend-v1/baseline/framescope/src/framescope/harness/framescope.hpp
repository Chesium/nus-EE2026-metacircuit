// Core types of the framescope simulation harness.
//
// The generated `fs_bind()` registers the design's clocks, inputs, outputs,
// virtual inputs and protocol monitors on a Harness; `Harness::run()` then
// drives the Verilator model and streams JSON events on stdout.
#pragma once

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "json.hpp"
#include "state.hpp"

namespace fs {

// A Verilator top-level port of at most 64 bits.
struct PortRef {
  void* ptr = nullptr;
  int bytes = 0;
  int width = 0;

  uint64_t get() const {
    switch (bytes) {
      case 1: return *static_cast<const uint8_t*>(ptr);
      case 2: return *static_cast<const uint16_t*>(ptr);
      case 4: return *static_cast<const uint32_t*>(ptr);
      default: return *static_cast<const uint64_t*>(ptr);
    }
  }

  void set(uint64_t v) const {
    if (width < 64) v &= (uint64_t{1} << width) - 1;
    switch (bytes) {
      case 1: *static_cast<uint8_t*>(ptr) = static_cast<uint8_t>(v); break;
      case 2: *static_cast<uint16_t*>(ptr) = static_cast<uint16_t>(v); break;
      case 4: *static_cast<uint32_t*>(ptr) = static_cast<uint32_t>(v); break;
      default: *static_cast<uint64_t*>(ptr) = v; break;
    }
  }
};

template <class T>
PortRef port(T& ref, int width) {
  static_assert(sizeof(T) <= 8, "ports wider than 64 bits are not supported");
  return PortRef{static_cast<void*>(&ref), static_cast<int>(sizeof(T)), width};
}

enum class SavePolicy { All, Last, List, None };

// A set of frame indices given as all | last | none | 0,3,5 (--save, --dump).
struct FrameSelect {
  SavePolicy mode = SavePolicy::All;
  std::vector<uint64_t> list;

  void parse(const std::string& s);
  bool selected(uint64_t index, uint64_t target_frames) const;
};

class Monitor;

// Run-wide settings that monitors need.
struct RunContext {
  std::string out_dir;
  uint64_t target_frames = 1;
  FrameSelect save;
  bool save_raster = false;
  // The first monitor that provides frames: frame/line/pixel reference for
  // stimulus and for other monitors' event positions (null if there is none).
  const Monitor* primary = nullptr;

  bool should_save(uint64_t index) const { return save.selected(index, target_frames); }
};

// A protocol decoder attached to wrapper taps. Monitors see the model after
// every evaluation and detect their own sampling-clock edges.
class Monitor {
 public:
  virtual ~Monitor() = default;
  virtual const std::string& name() const = 0;
  virtual void sample(uint64_t t_ps) = 0;
  virtual uint64_t frames() const = 0;
  // Raster position of the latest sample inside the frame in progress (index
  // frames()): line 0 starts at the frame's start edge, line L >= 1 at the L-th
  // line-start edge after it; pixel counts samples since the line started.
  // False before the first frame starts. Drives line-timed stimulus.
  virtual bool position(int64_t& line, int64_t& pixel) const { return false; }
  // False for monitors without frames (e.g. a UART link): they never become
  // the frame reference and their frames() is ignored.
  virtual bool provides_frames() const { return true; }
  // Called once after inputs have their initial values, before time 0.
  virtual void begin() {}
  // Monitors that drive a design input: the next time at which they need
  // drive() to run (before that instant's evaluation), and the hook itself.
  virtual uint64_t next_drive_ps() const { return UINT64_MAX; }
  virtual void drive(uint64_t t_ps) {}
  // Queues bytes to transmit no earlier than `not_before_ps` (stimulus or host
  // replies); false if this monitor cannot send.
  virtual bool send(const std::vector<uint8_t>& data, uint64_t not_before_ps, int gap_bits,
                    const std::string& source, int64_t id) {
    return false;
  }
  // Lets the run driver answer this monitor's events over stdin (--host).
  virtual bool attach_host() { return false; }
  virtual JsonObj summary() const = 0;
  // Boot checkpoints: write / read the monitor's complete decoding state.
  // A monitor that does not implement them makes the run non-checkpointable.
  virtual bool save_state(StateWriter&) const { return false; }
  virtual bool load_state(StateReader&) { return false; }
  void attach(const RunContext* ctx) { ctx_ = ctx; }

 protected:
  const RunContext* ctx_ = nullptr;
};

// Hooks into the Verilator model, filled in by main.cpp.
struct Model {
  std::function<void()> eval;
  std::function<void(uint64_t)> set_time;
  std::function<bool(const std::string&)> trace_open;  // empty without --trace builds
  std::function<void(uint64_t)> trace_dump;
  std::function<void()> trace_close;
  std::function<void(const std::string&)> coverage_write;
  std::function<void()> coverage_zero;
  // Model + VerilatedContext state; empty unless built with --savable (FS_SAVABLE).
  std::function<bool(const std::string&)> save;
  std::function<bool(const std::string&)> restore;
};

// Values that sim-only stub modules read through the framescope_dpi package.
class VirtualInputs {
 public:
  int handle(const std::string& name);
  bool has(const std::string& name) const { return index_.count(name) != 0; }
  int64_t get(int handle) const;
  void set(const std::string& name, int64_t value);
  std::vector<std::string> undeclared() const;
  void declare(const std::string& name, int64_t value);
  void save_state(StateWriter& w) const;
  bool load_state(StateReader& r);

 private:
  std::vector<int64_t> values_;
  std::vector<std::string> names_;
  std::vector<bool> declared_;
  std::unordered_map<std::string, int> index_;
};

VirtualInputs& virtual_inputs();

// Emits `request` (an event the run driver must answer) and reads one reply
// line from stdin. False on end of input.
bool host_request(const JsonObj& request, std::string& reply);

// Filled by the fs_dump_begin/fs_dump_word DPI imports while the wrapper's
// exported fs_dump_memory() walks one memory.
struct DumpBuffer {
  int mem = -1;
  int width = 0;
  int depth = 0;
  int chunks = 0;  // 64-bit chunks per word, least significant first
  std::vector<uint64_t> data;
};

DumpBuffer& dump_buffer();

class Harness {
 public:
  void add_clock(const std::string& name, PortRef p, uint64_t period_ps, uint64_t offset_ps);
  void add_input(const std::string& name, PortRef p, uint64_t initial);
  void add_output(const std::string& name, PortRef p);
  void add_virtual_input(const std::string& name, int64_t initial);
  void add_monitor(std::unique_ptr<Monitor> m);
  // A named expression sampled once per frame: `value` holds it zero-extended
  // to 64 bits, `bits` its width ($bits in the wrapper).
  void add_probe(const std::string& name, PortRef value, PortRef bits);
  // A memory the wrapper can walk: `dumper(id)` calls the exported SV function.
  void add_dump(const std::string& name, int id);
  void set_dumper(std::function<void(int)> dumper) { dumper_ = std::move(dumper); }

  // Parses the command line, runs the simulation, returns the exit code.
  int run(int argc, char** argv, Model& model);

 private:
  struct Clock {
    std::string name;
    PortRef port;
    uint64_t half_ps;
    uint64_t next_ps;
    bool level;
  };
  struct Input {
    PortRef port;
    uint64_t initial;
  };
  enum class Trigger { Time, Frame, Position };
  struct StimEvent {
    Trigger trigger;
    uint64_t at;  // ps, or frame index (Frame, Position)
    int64_t line, pixel;  // Position only
    std::string name;
    int64_t value;
    // Byte stimulus for a link monitor ("u" lines): bytes, idle bits between
    // them, and the [[uart]] table index (value).
    Monitor* link = nullptr;
    std::vector<uint8_t> data;
    int gap_bits = 0;
  };
  struct Probe {
    std::string name;
    PortRef value, bits;
    int width = 0;
  };
  struct Dump {
    std::string name;
    int id;
  };

  bool load_stimulus(const std::string& path);
  bool apply(const StimEvent& e, uint64_t t_ps);
  Monitor* find_monitor(const std::string& name) const;
  void emit_probes(uint64_t frame, uint64_t t_ps);
  bool write_dump(const Dump& d, uint64_t frame, uint64_t t_ps, const std::string& out_dir);
  // Boot checkpoints (checkpoint.cpp): `dir`/model.bin (VerilatedSave) and
  // `dir`/harness.bin (clocks, time, virtual inputs, monitors).
  struct RunState {
    uint64_t t = 0, evals = 0, frames = 0;
  };
  bool save_checkpoint(const std::string& dir, const RunState& rs, Model& model);
  bool load_checkpoint(const std::string& dir, RunState& rs, Model& model);

  std::vector<Clock> clocks_;
  std::unordered_map<std::string, Input> inputs_;
  std::unordered_map<std::string, PortRef> outputs_;
  std::vector<std::unique_ptr<Monitor>> monitors_;
  std::vector<StimEvent> time_events_;
  std::vector<StimEvent> frame_events_;
  std::vector<StimEvent> position_events_;
  std::vector<Probe> probes_;
  std::vector<Dump> dumps_;
  std::function<void(int)> dumper_;
};

}  // namespace fs
