#include "framescope.hpp"
#include "profile.hpp"

#include <algorithm>
#include <chrono>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <sstream>
#include <tuple>

namespace fs {

void FrameSelect::parse(const std::string& s) {
  list.clear();
  if (s == "all") { mode = SavePolicy::All; return; }
  if (s == "last") { mode = SavePolicy::Last; return; }
  if (s == "none") { mode = SavePolicy::None; return; }
  mode = SavePolicy::List;
  std::stringstream ss(s);
  std::string item;
  while (std::getline(ss, item, ',')) list.push_back(std::strtoull(item.c_str(), nullptr, 0));
}

bool FrameSelect::selected(uint64_t index, uint64_t target_frames) const {
  switch (mode) {
    case SavePolicy::All: return true;
    case SavePolicy::None: return false;
    case SavePolicy::Last: return index + 1 == target_frames;
    case SavePolicy::List: return std::find(list.begin(), list.end(), index) != list.end();
  }
  return false;
}

int VirtualInputs::handle(const std::string& name) {
  auto it = index_.find(name);
  if (it != index_.end()) return it->second;
  const int h = static_cast<int>(values_.size());
  values_.push_back(0);
  names_.push_back(name);
  declared_.push_back(false);
  index_.emplace(name, h);
  return h;
}

int64_t VirtualInputs::get(int handle) const {
  if (handle < 0 || handle >= static_cast<int>(values_.size())) return 0;
  return values_[handle];
}

void VirtualInputs::set(const std::string& name, int64_t value) { values_[handle(name)] = value; }

void VirtualInputs::declare(const std::string& name, int64_t value) {
  const int h = handle(name);
  values_[h] = value;
  declared_[h] = true;
}

std::vector<std::string> VirtualInputs::undeclared() const {
  std::vector<std::string> out;
  for (size_t i = 0; i < names_.size(); ++i)
    if (!declared_[i]) out.push_back(names_[i]);
  return out;
}

VirtualInputs& virtual_inputs() {
  static VirtualInputs vi;
  return vi;
}

bool host_request(const JsonObj& request, std::string& reply) {
  emit(request);
  return static_cast<bool>(std::getline(std::cin, reply));
}

DumpBuffer& dump_buffer() {
  static DumpBuffer b;
  return b;
}

void Harness::add_clock(const std::string& name, PortRef p, uint64_t period_ps, uint64_t offset_ps) {
  const uint64_t half = std::max<uint64_t>(1, period_ps / 2);
  clocks_.push_back(Clock{name, p, half, offset_ps + half, false});
}

void Harness::add_input(const std::string& name, PortRef p, uint64_t initial) {
  inputs_[name] = Input{p, initial};
}

void Harness::add_output(const std::string& name, PortRef p) { outputs_[name] = p; }

void Harness::add_virtual_input(const std::string& name, int64_t initial) {
  virtual_inputs().declare(name, initial);
}

void Harness::add_monitor(std::unique_ptr<Monitor> m) { monitors_.push_back(std::move(m)); }

void Harness::add_probe(const std::string& name, PortRef value, PortRef bits) {
  probes_.push_back(Probe{name, value, bits, 0});
}

void Harness::add_dump(const std::string& name, int id) { dumps_.push_back(Dump{name, id}); }

void Harness::emit_probes(uint64_t frame, uint64_t t_ps) {
  ProfileScope prof(Profile::Probes);
  JsonObj values;
  for (const auto& p : probes_) {
    uint64_t v = p.value.get();
    if (p.width < 64) v &= (uint64_t{1} << p.width) - 1;
    values.u64(p.name.c_str(), v);
  }
  emit(JsonObj().str("event", "probes").u64("frame", frame).u64("t_ps", t_ps).obj("values", values));
}

namespace {

// Zero-padded hex of one word, most significant chunk first.
std::string hex_word(const uint64_t* chunks, int nchunks, int width) {
  std::string s = "0x";
  for (int c = nchunks - 1; c >= 0; --c) {
    const int bits = std::min(64, width - 64 * c);
    uint64_t v = chunks[c];
    if (bits < 64) v &= (uint64_t{1} << bits) - 1;
    char buf[24];
    snprintf(buf, sizeof buf, "%0*llx", (bits + 3) / 4, static_cast<unsigned long long>(v));
    s += buf;
  }
  return s;
}

}  // namespace

bool Harness::write_dump(const Dump& d, uint64_t frame, uint64_t t_ps, const std::string& out_dir) {
  ProfileScope prof(Profile::Dump);
  DumpBuffer& b = dump_buffer();
  b = DumpBuffer{};
  dumper_(d.id);
  if (b.mem != d.id || b.width <= 0 || b.depth < 0) {
    emit(JsonObj().str("event", "error").str("message", "dump '" + d.name + "' produced no data"));
    return false;
  }
  char stem[32];
  snprintf(stem, sizeof stem, "frame_%04llu.json", static_cast<unsigned long long>(frame));
  const std::string dir = out_dir + "/dumps/" + d.name;
  const std::string path = dir + "/" + stem;
  std::error_code ec;
  std::filesystem::create_directories(dir, ec);
  FILE* f = fopen(path.c_str(), "wb");
  if (!f) {
    emit(JsonObj().str("event", "error").str("message", "cannot write " + path));
    return false;
  }
  const std::string head = JsonObj().str("name", d.name).u64("frame", frame).i64("width", b.width)
                               .i64("depth", b.depth).dump();
  std::string out = head.substr(0, head.size() - 1) + ",\"words\":[";
  for (int i = 0; i < b.depth; ++i) {
    out += i ? ",\n  \"" : "\n  \"";
    out += hex_word(&b.data[static_cast<size_t>(i) * b.chunks], b.chunks, b.width);
    out += '"';
  }
  out += "\n]}\n";
  fwrite(out.data(), 1, out.size(), f);
  fclose(f);
  emit(JsonObj().str("event", "dump").str("name", d.name).u64("frame", frame).u64("t_ps", t_ps)
           .i64("width", b.width).i64("depth", b.depth).str("path", path));
  return true;
}

Monitor* Harness::find_monitor(const std::string& name) const {
  for (const auto& m : monitors_)
    if (m->name() == name) return m.get();
  return nullptr;
}

// Stimulus lines: "t <ps> <name> <value>", "f <frame> <name> <value>", or
// "p <frame>:<line>:<pixel> <name> <value>" (position of the frame monitor).
// Byte stimulus for a link monitor: "ut|uf|up <when> <monitor> <id> <gap_bits> <hex>".
bool Harness::load_stimulus(const std::string& path) {
  std::ifstream in(path);
  if (!in) {
    emit(JsonObj().str("event", "error").str("message", "cannot open stimulus file " + path));
    return false;
  }
  std::string line;
  int lineno = 0;
  while (std::getline(in, line)) {
    ++lineno;
    if (line.empty() || line[0] == '#') continue;
    std::istringstream ss(line);
    std::string kind, at, name, value;
    ss >> kind >> at >> name >> value;
    StimEvent e{Trigger::Time, 0, 0, 0, name, static_cast<int64_t>(std::strtoll(value.c_str(), nullptr, 0))};
    bool ok = !name.empty() && !value.empty();
    if (kind.size() == 2 && kind[0] == 'u') {
      std::string hex;
      ss >> e.gap_bits >> hex;
      e.link = find_monitor(name);
      for (size_t i = 0; ok && i + 1 < hex.size(); i += 2)
        e.data.push_back(static_cast<uint8_t>(std::strtoul(hex.substr(i, 2).c_str(), nullptr, 16)));
      ok = ok && !hex.empty() && hex.size() % 2 == 0;
      if (ok && !e.link) {
        emit(JsonObj().str("event", "error").str("message", "stimulus names unknown link monitor '" + name + "'"));
        return false;
      }
      kind = kind.substr(1);
    }
    if (kind == "t" || kind == "f") {
      e.trigger = kind == "t" ? Trigger::Time : Trigger::Frame;
      e.at = std::strtoull(at.c_str(), nullptr, 0);
    } else if (kind == "p") {
      unsigned long long fr = 0;
      long long ln = 0, px = 0;
      e.trigger = Trigger::Position;
      ok = ok && std::sscanf(at.c_str(), "%llu:%lld:%lld", &fr, &ln, &px) == 3 && ln >= 0 && px >= 0;
      e.at = fr;
      e.line = ln;
      e.pixel = px;
    } else {
      ok = false;
    }
    if (!ok) {
      emit(JsonObj().str("event", "error").str("message", "bad stimulus line " + std::to_string(lineno)));
      return false;
    }
    if (e.link && !e.link->send({}, 0, 0, "", 0)) {  // an empty send only checks the capability
      emit(JsonObj().str("event", "error").str("message", "monitor '" + name + "' cannot send bytes"));
      return false;
    }
    if (!e.link && !inputs_.count(name) && !virtual_inputs().has(name)) {
      emit(JsonObj().str("event", "error").str("message", "stimulus names unknown input '" + name + "'"));
      return false;
    }
    (e.trigger == Trigger::Time ? time_events_ : e.trigger == Trigger::Frame ? frame_events_ : position_events_)
        .push_back(e);
  }
  auto by_at = [](const StimEvent& a, const StimEvent& b) { return a.at < b.at; };
  auto by_pos = [](const StimEvent& a, const StimEvent& b) {
    return std::tie(a.at, a.line, a.pixel) < std::tie(b.at, b.line, b.pixel);
  };
  std::stable_sort(time_events_.begin(), time_events_.end(), by_at);
  std::stable_sort(frame_events_.begin(), frame_events_.end(), by_at);
  std::stable_sort(position_events_.begin(), position_events_.end(), by_pos);
  return true;
}

bool Harness::apply(const StimEvent& e, uint64_t t_ps) {
  if (e.link) {
    // Transmission starts at the link's next drive() (this instant if idle).
    if (!e.link->send(e.data, t_ps, e.gap_bits, "stim", e.value)) {
      emit(JsonObj().str("event", "error").str("message", "monitor '" + e.name + "' cannot send bytes"));
    }
    return false;
  }
  auto it = inputs_.find(e.name);
  if (it != inputs_.end()) {
    it->second.port.set(static_cast<uint64_t>(e.value));
  } else {
    virtual_inputs().set(e.name, e.value);
  }
  return true;
}

namespace {

struct Options {
  std::string out_dir = ".";
  uint64_t frames = 1;
  uint64_t max_time_ps = 0;
  std::string stim;
  std::string save = "all";
  std::string dump = "none";
  bool raster = false;
  bool profile = false;
  bool session = false;
  std::string checkpoint_save;  // directory: save the state at the end (after --frames)
  std::string checkpoint_load;  // directory: start from a saved state instead of time 0
  std::string trace;
  uint64_t trace_from = 0;
  uint64_t trace_frames = 1;
  std::vector<std::string> hosts;
  std::string coverage;
  uint64_t coverage_from = 0;
};

bool parse_args(int argc, char** argv, Options& o) {
  for (int i = 1; i < argc; ++i) {
    const std::string a = argv[i];
    auto next = [&](const char* what) -> const char* {
      if (i + 1 >= argc) {
        emit(JsonObj().str("event", "error").str("message", std::string("missing value for ") + what));
        return nullptr;
      }
      return argv[++i];
    };
    const char* v = nullptr;
    if (a == "--out") { if (!(v = next("--out"))) return false; o.out_dir = v; }
    else if (a == "--frames") { if (!(v = next("--frames"))) return false; o.frames = std::strtoull(v, nullptr, 0); }
    else if (a == "--max-time-ps") { if (!(v = next("--max-time-ps"))) return false; o.max_time_ps = std::strtoull(v, nullptr, 0); }
    else if (a == "--stim") { if (!(v = next("--stim"))) return false; o.stim = v; }
    else if (a == "--save") { if (!(v = next("--save"))) return false; o.save = v; }
    else if (a == "--dump") { if (!(v = next("--dump"))) return false; o.dump = v; }
    else if (a == "--raster") { o.raster = true; }
    else if (a == "--profile") { o.profile = true; }
    else if (a == "--session") { o.session = true; }
    else if (a == "--checkpoint-save") { if (!(v = next("--checkpoint-save"))) return false; o.checkpoint_save = v; }
    else if (a == "--checkpoint-load") { if (!(v = next("--checkpoint-load"))) return false; o.checkpoint_load = v; }
    else if (a == "--trace") { if (!(v = next("--trace"))) return false; o.trace = v; }
    else if (a == "--trace-from") { if (!(v = next("--trace-from"))) return false; o.trace_from = std::strtoull(v, nullptr, 0); }
    else if (a == "--trace-frames") { if (!(v = next("--trace-frames"))) return false; o.trace_frames = std::strtoull(v, nullptr, 0); }
    // main.cpp consumes/validates RNG settings before model construction.
    else if (a == "--seed" || a == "--rand-reset") { if (!next(a.c_str())) return false; }
    else if (a == "--coverage") { if (!(v = next("--coverage"))) return false; o.coverage = v; }
    else if (a == "--coverage-from") { if (!(v = next("--coverage-from"))) return false; o.coverage_from = std::strtoull(v, nullptr, 0); }
    else if (a == "--host") { if (!(v = next("--host"))) return false; o.hosts.push_back(v); }
    else {
      emit(JsonObj().str("event", "error").str("message", "unknown argument " + a));
      return false;
    }
  }
  return true;
}

}  // namespace

int Harness::run(int argc, char** argv, Model& model) {
  Options opt;
  if (!parse_args(argc, argv, opt)) return 2;
  if (!opt.stim.empty() && !load_stimulus(opt.stim)) return 2;
  if (!opt.trace.empty() && !model.trace_open) {
    emit(JsonObj().str("event", "error").str("message", "binary was built without tracing; rebuild with --trace"));
    return 2;
  }
  if (!opt.coverage.empty() && (!model.coverage_write || !opt.checkpoint_load.empty() || !opt.checkpoint_save.empty())) {
    emit(JsonObj().str("event", "error").str("message", "coverage requires an instrumented cold run without checkpoints"));
    return 2;
  }
  const bool restoring = !opt.checkpoint_load.empty();
  if (restoring && !opt.trace.empty()) {
    emit(JsonObj().str("event", "error").str("message", "--trace cannot be combined with --checkpoint-load"));
    return 2;
  }

  profile().on = opt.profile;
  RunContext ctx;
  ctx.out_dir = opt.out_dir;
  ctx.target_frames = opt.frames;
  ctx.save_raster = opt.raster;
  ctx.save.parse(opt.save);
  FrameSelect dump_select;
  dump_select.parse(opt.dump);
  if (dump_select.mode != SavePolicy::None && !dumps_.empty() && !dumper_) {
    emit(JsonObj().str("event", "error").str("message", "memory dumps are declared but the binary has no dumper"));
    return 2;
  }
  Monitor* primary = nullptr;
  for (auto& m : monitors_) {
    if (!primary && m->provides_frames()) primary = m.get();
  }
  ctx.primary = primary;
  for (auto& m : monitors_) m->attach(&ctx);
  for (const auto& name : opt.hosts) {
    Monitor* m = find_monitor(name);
    if (!m || !m->attach_host()) {
      emit(JsonObj().str("event", "error").str("message", "--host " + name + ": no such monitor, or it cannot use a host"));
      return 2;
    }
  }
  const uint64_t max_time = opt.max_time_ps ? opt.max_time_ps : UINT64_MAX;

  for (auto& kv : inputs_) kv.second.port.set(kv.second.initial);
  for (auto& c : clocks_) c.port.set(0);
  for (auto& m : monitors_) m->begin();

  const auto wall0 = std::chrono::steady_clock::now();
  uint64_t t = 0, evals = 0;
  size_t ti = 0, fi = 0, pi = 0;
  uint64_t last_frames = 0;
  bool tracing = false;
  bool scenario_coverage = false;
  auto update_coverage = [&](uint64_t f) {
    int64_t line, pixel;
    if (!opt.coverage.empty() && !scenario_coverage && primary &&
        f == opt.coverage_from && primary->position(line, pixel)) {
      model.coverage_write(opt.coverage + "/boot.dat");
      model.coverage_zero();
      scenario_coverage = true;
      emit(JsonObj().str("event", "coverage_boundary").u64("frame", f).u64("t_ps", t));
    }
  };
  const char* stop_reason = "frames";

  auto apply_frame_events = [&](uint64_t f) {
    bool any = false;
    while (fi < frame_events_.size() && frame_events_[fi].at <= f) {
      const StimEvent& e = frame_events_[fi++];
      any |= apply(e, t);
      if (e.link) {
        emit(JsonObj().str("event", "send").str("monitor", e.name).i64("id", e.value).u64("frame", e.at)
                 .u64("at_frame", f).u64("t_ps", t));
      }
    }
    return any;
  };
  // Position events fire at the first sample at or past (frame, line, pixel).
  auto apply_position_events = [&](uint64_t f) {
    if (pi >= position_events_.size() || !primary) return false;
    int64_t line = 0, pixel = 0;
    if (!primary->position(line, pixel)) return false;
    bool any = false;
    while (pi < position_events_.size()) {
      const StimEvent& e = position_events_[pi];
      if (std::tie(e.at, e.line, e.pixel) > std::make_tuple(f, line, pixel)) break;
      any |= apply(e, t);
      emit(JsonObj().str("event", e.link ? "send" : "stim").str(e.link ? "monitor" : "name", e.name)
               .i64(e.link ? "id" : "value", e.value).u64("frame", e.at)
               .i64("line", e.line).i64("pixel", e.pixel).u64("at_frame", f).i64("at_line", line)
               .i64("at_pixel", pixel).u64("t_ps", t));
      ++pi;
    }
    return any;
  };
  auto update_trace = [&](uint64_t f) {
    if (opt.trace.empty()) return;
    if (!tracing && f == opt.trace_from && f < opt.trace_from + opt.trace_frames) {
      tracing = model.trace_open(opt.trace);
      emit(JsonObj().str("event", "trace").str("state", tracing ? "open" : "failed").u64("frame", f).u64("t_ps", t));
    } else if (tracing && f >= opt.trace_from + opt.trace_frames) {
      model.trace_close();
      tracing = false;
      emit(JsonObj().str("event", "trace").str("state", "closed").u64("frame", f).u64("t_ps", t));
    }
  };

  if (restoring) {
    // Resume at the frame boundary where the checkpoint was saved. Stimulus
    // that fired before it is part of the saved state (the host checks that
    // this run's stimulus agrees with the checkpoint's up to that point).
    RunState rs;
    ProfileScope prof(Profile::Checkpoint);
    if (!load_checkpoint(opt.checkpoint_load, rs, model)) return 2;
    t = rs.t;
    evals = rs.evals;
    last_frames = rs.frames;
    if (!primary || last_frames >= opt.frames) {
      emit(JsonObj().str("event", "error").str("message", "checkpoint is at frame " + std::to_string(last_frames) +
                                                             "; --frames must be larger"));
      return 2;
    }
    while (ti < time_events_.size() && time_events_[ti].at <= t) ++ti;
    while (fi < frame_events_.size() && frame_events_[fi].at < last_frames) ++fi;
    while (pi < position_events_.size() && position_events_[pi].at < last_frames) ++pi;
    model.set_time(t);
  } else {
    while (ti < time_events_.size() && time_events_[ti].at == 0) apply(time_events_[ti++], 0);
    apply_frame_events(0);
    model.set_time(0);
    model.eval();
    ++evals;
  }
  for (auto& p : probes_) {
    p.width = static_cast<int>(p.bits.get());
    if (p.width < 1 || p.width > 64) {
      emit(JsonObj().str("event", "error").str("message", "probe '" + p.name + "' is " + std::to_string(p.width) +
                                                             " bits wide; probes take 1 to 64 bits"));
      return 2;
    }
  }
  update_trace(0);
  if (tracing) model.trace_dump(0);

  JsonObj widths;
  for (const auto& p : probes_) widths.i64(p.name.c_str(), p.width);
  emit(JsonObj().str("event", "start").u64("clocks", clocks_.size()).u64("monitors", monitors_.size())
           .u64("target_frames", opt.frames).u64("max_time_ps", opt.max_time_ps).obj("probe_widths", widths));
  if (restoring) {
    // The rest of the boundary iteration that the checkpoint interrupted.
    bool changed = apply_frame_events(last_frames);
    changed |= apply_position_events(last_frames);
    if (changed) {
      model.eval();
      ++evals;
    }
  }

  if (!primary && !opt.max_time_ps) {
    emit(JsonObj().str("event", "error").str("message", "no monitors configured and no --max-time-ps given"));
    return 2;
  }
  if (clocks_.empty()) {
    emit(JsonObj().str("event", "error").str("message", "no clocks configured"));
    return 2;
  }

  // A session pauses after frame observations, before the next frame's
  // stimulus. Commands never advance clocks except for an explicit step.
  uint64_t session_target = 0, session_deadline = UINT64_MAX;
  auto session_result = [&](bool ok, const std::string& error = "") {
    JsonObj values;
    for (const auto& p : probes_) {
      uint64_t v = p.value.get();
      if (p.width < 64) v &= (uint64_t{1} << p.width) - 1;
      values.u64(p.name.c_str(), v);
    }
    JsonObj r;
    r.str("event", "session_result").boolean("ok", ok).u64("completed_frames", last_frames)
     .u64("t_ps", t).obj("probes", values);
    if (!error.empty()) r.str("error", error);
    emit(r);
  };
  auto session_commands = [&]() {
    session_result(true);
    std::string line;
    while (std::getline(std::cin, line)) {
      std::istringstream ss(line);
      std::string op;
      ss >> op;
      if (op == "step") {
        uint64_t count = 0, budget = 0;
        ss >> count >> budget;
        if (!count || !budget || count > UINT64_MAX - last_frames || budget > UINT64_MAX - t) {
          session_result(false, "invalid step count or time budget");
          continue;
        }
        session_target = last_frames + count;
        session_deadline = t + budget;
        return true;
      }
      if (op == "stop") {
        session_result(true);
        return false;
      }
      if (op == "poke" || op == "poke_at") {
        // Python validates the whole mapping before sending it, then we set
        // all inputs before evaluating once (atomic combinational update).
        size_t count = 0;
        int64_t line = -1, pixel = -1;
        if (op == "poke_at") ss >> line >> pixel;
        ss >> count;
        std::vector<std::pair<std::string, int64_t>> values;
        bool valid = count > 0;
        for (size_t i = 0; i < count; ++i) {
          std::string name; int64_t value = 0;
          ss >> name >> value;
          valid = valid && !ss.fail() && (inputs_.count(name) || virtual_inputs().has(name));
          values.emplace_back(name, value);
        }
        if (!valid) { session_result(false, "invalid poke"); continue; }
        if (op == "poke_at") {
          for (const auto& kv : values)
            position_events_.push_back(StimEvent{Trigger::Position, last_frames, line, pixel, kv.first, kv.second});
          std::stable_sort(position_events_.begin() + pi, position_events_.end(),
                          [](const StimEvent& a, const StimEvent& b) {
            return std::tie(a.at, a.line, a.pixel) < std::tie(b.at, b.line, b.pixel);
          });
        } else {
          for (const auto& kv : values) apply(StimEvent{Trigger::Time, t, 0, 0, kv.first, kv.second}, t);
          model.eval(); ++evals;
        }
        session_result(true);
      } else if (op == "probes") {
        session_result(true);
      } else if (op == "memory") {
        std::string name; ss >> name;
        auto d = std::find_if(dumps_.begin(), dumps_.end(), [&](const Dump& d) { return d.name == name; });
        if (d == dumps_.end() || !dumper_) session_result(false, "unknown memory");
        else session_result(write_dump(*d, last_frames ? last_frames - 1 : 0, t, opt.out_dir));
      } else session_result(false, "unknown session command");
    }
    return false;  // EOF stops the owned simulator safely.
  };
  if (opt.session && !primary) {
    emit(JsonObj().str("event", "error").str("message", "session requires a frame monitor"));
    return 2;
  }
  bool session_running = !opt.session || session_commands();
  if (!session_running) stop_reason = "session_stop";
  while (session_running) {
    uint64_t next = UINT64_MAX;
    for (const auto& c : clocks_) next = std::min(next, c.next_ps);
    if (ti < time_events_.size()) next = std::min(next, time_events_[ti].at);
    for (const auto& m : monitors_) next = std::min(next, m->next_drive_ps());
    next = std::max(next, t);  // bytes queued at this instant start now
    if (next > std::min(max_time, session_deadline)) {
      stop_reason = "max_time";
      break;
    }
    t = next;
    for (auto& c : clocks_) {
      if (c.next_ps == t) {
        c.level = !c.level;
        c.port.set(c.level);
        c.next_ps += c.half_ps;
      }
    }
    while (ti < time_events_.size() && time_events_[ti].at <= t) apply(time_events_[ti++], t);
    for (auto& m : monitors_) m->drive(t);
    model.set_time(t);
    {
      ProfileScope prof(Profile::Eval);
      model.eval();
    }
    ++evals;
    if (tracing) model.trace_dump(t);
    {
      ProfileScope prof(Profile::Monitor);
      // The frame monitor first, so other monitors see this sample's position.
      if (primary) primary->sample(t);
      for (auto& m : monitors_) {
        if (m.get() != primary) m->sample(t);
      }
    }

    if (primary) {
      const uint64_t f = primary->frames();
      update_coverage(f);
      bool changed = false;
      if (f != last_frames) {
        // Frame f-1 just ended at this VSYNC leading edge: sample its probes
        // and dump memories before any stimulus for frame f is applied.
        last_frames = f;
        if (!probes_.empty()) emit_probes(f - 1, t);
        if (dump_select.selected(f - 1, opt.frames)) {
          for (const auto& d : dumps_) {
            if (!write_dump(d, f - 1, t, opt.out_dir)) return 2;
          }
        }
        update_trace(f);
        if (opt.session && f >= session_target) {
          if (!session_commands()) { stop_reason = "session_stop"; break; }
        }
        if (!opt.session && f >= opt.frames) {
          if (!opt.checkpoint_save.empty()) {
            ProfileScope prof(Profile::Checkpoint);
            if (pi < position_events_.size() && position_events_[pi].at < f) {
              emit(JsonObj().str("event", "error").str("message", "checkpoint: a line-timed event for frame " +
                                                                     std::to_string(position_events_[pi].at) +
                                                                     " has not fired yet"));
              return 2;
            }
            if (!save_checkpoint(opt.checkpoint_save, RunState{t, evals, f}, model)) return 2;
          }
          break;
        }
        changed = apply_frame_events(f);
      }
      changed |= apply_position_events(f);
      if (changed) {
        model.eval();
        ++evals;
      }
    }
  }

  if (tracing) model.trace_close();
  if (!opt.coverage.empty()) {
    model.coverage_write(opt.coverage + (scenario_coverage ? "/scenario.dat" : "/boot.dat"));
    if (!scenario_coverage) {
      emit(JsonObj().str("event", "error").str("message", "coverage scenario boundary was not reached"));
    }
  }
  const double wall = std::chrono::duration<double>(std::chrono::steady_clock::now() - wall0).count();
  for (auto& m : monitors_) {
    emit(JsonObj().str("event", "monitor_summary").str("monitor", m->name()).obj("summary", m->summary()));
  }
  std::string undeclared = "[";
  for (const auto& n : virtual_inputs().undeclared()) {
    if (undeclared.size() > 1) undeclared += ',';
    undeclared += json_str(n);
  }
  undeclared += "]";
  JsonObj end;
  end.str("event", "end").str("stop_reason", stop_reason).u64("t_ps", t).u64("evals", evals).num("wall_s", wall)
      .raw("undeclared_virtual_inputs", undeclared);
  if (opt.profile) end.obj("profile", profile().json(wall));
  emit(end);
  return 0;
}

}  // namespace fs
