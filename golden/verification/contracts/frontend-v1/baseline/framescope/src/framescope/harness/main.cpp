// Entry point: builds the Verilator model of the generated framescope_top
// wrapper, lets the generated fs_bind() register ports and monitors, and runs.
#include <memory>
#include <cstdlib>
#include <cstring>

#include "Vframescope_top.h"
#include "framescope.hpp"
#include "verilated.h"
#ifdef FS_TRACE
#include "verilated_fst_c.h"
#endif
#ifdef FS_COVERAGE
#include "verilated_cov.h"
#endif
#ifdef FS_SAVABLE
#include "verilated_save.h"
#endif

void fs_bind(fs::Harness& h, Vframescope_top& top);

int main(int argc, char** argv) {
  // Configure RNG before constructing the model: generated constructor code
  // initializes otherwise uninitialized registers/memories through this context.
  int seed = 1, rand_reset = 0;
  bool checkpoint = false;
  for (int i = 1; i < argc; ++i) {
    if (!std::strcmp(argv[i], "--checkpoint-load") || !std::strcmp(argv[i], "--checkpoint-save")) checkpoint = true;
    if (std::strcmp(argv[i], "--seed") && std::strcmp(argv[i], "--rand-reset")) continue;
    const bool is_seed = !std::strcmp(argv[i], "--seed");
    const char* name = argv[i];
    char* end = nullptr;
    const char* value = i + 1 < argc ? argv[++i] : "";
    const long long n = std::strtoll(value, &end, 10);
    if (!*value || *value < '0' || *value > '9' || !end || *end ||
        (is_seed ? n < 1 || n > 2147483647 : n < 0 || n > 2)) {
      fs::emit(fs::JsonObj().str("event", "error").str("message", std::string("invalid value for ") + name));
      return 2;
    }
    (is_seed ? seed : rand_reset) = static_cast<int>(n);
  }
  if (checkpoint && rand_reset != 0) {
    fs::emit(fs::JsonObj().str("event", "error").str("message", "randomized runs cannot save or restore checkpoints"));
    return 2;
  }
  auto vctx = std::make_unique<VerilatedContext>();
  vctx->randSeed(seed);
  vctx->randReset(rand_reset);
#ifdef FS_TRACE
  vctx->traceEverOn(true);
#endif
  auto top = std::make_unique<Vframescope_top>(vctx.get(), "TOP");

  fs::Harness harness;
  fs_bind(harness, *top);

  fs::Model model;
  model.eval = [&] { top->eval(); };
  model.set_time = [&](uint64_t t) { vctx->time(t); };
#ifdef FS_COVERAGE
  vctx->coveragep()->forcePerInstance(true);
  model.coverage_write = [&](const std::string& path) { vctx->coveragep()->write(path.c_str()); };
  model.coverage_zero = [&] { vctx->coveragep()->zero(); };
#endif
#ifdef FS_TRACE
  std::unique_ptr<VerilatedFstC> tfp;
  model.trace_open = [&](const std::string& path) {
    tfp = std::make_unique<VerilatedFstC>();
    top->trace(tfp.get(), 99);
    tfp->open(path.c_str());
    return tfp->isOpen();
  };
  model.trace_dump = [&](uint64_t t) {
    if (tfp) tfp->dump(t);
  };
  model.trace_close = [&] {
    if (tfp) {
      tfp->close();
      tfp.reset();
    }
  };
#endif

#ifdef FS_SAVABLE
  // Boot checkpoints: the context (time, $random state, ...) and the model.
  model.save = [&](const std::string& path) {
    VerilatedSave os;
    os.open(path.c_str());
    if (!os.isOpen()) return false;
    os << vctx.get() << *top;
    os.close();
    return true;
  };
  model.restore = [&](const std::string& path) {
    VerilatedRestore os;
    os.open(path.c_str());
    if (!os.isOpen()) return false;
    os >> vctx.get() >> *top;
    os.close();
    return true;
  };
#endif

  const int rc = harness.run(argc, argv, model);
  top->final();
  return rc;
}
