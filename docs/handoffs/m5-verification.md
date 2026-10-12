# M5 verification handoff

Updated: 2026-10-12 (client date). State: **M5 complete** in the declared harness scope; no jobs running.
Previous handoffs: [2026-10-11f](m5-verification-history-20261011f.md) and the
other `m5-verification-history-*` files.

## Goal

M5 delivers the verification/observability harness for later autonomous
timing/resource optimization experiments (D-030, D-031 in
`docs/verification-plan.md`). It does not require timing closure, a defect-free
design, 100% structural coverage or global formal proofs.

## Setup on a fresh machine

- Sibling checkouts `../framescope` (with its `.venv`) and `golden/node_modules`.
- Vivado 2025.2 at `/opt/amd/2025.2` with the generated FP IP products in `src/ip/`.
- Yosys 0.33 for the scoped proofs: `tools/setup_yosys_m5.sh` unpacks the Ubuntu
  package into `~/.cache/metacircuit-m5` without root (or set `METACIRCUIT_YOSYS`).
  The gate stops at startup if it is missing. An earlier copy under `/tmp` was lost
  on a host restart.

## Optimization experiment checklist

1. Declare the objective JSON before measuring.
2. Make the RTL change on a branch. If `GlobalRender_top.v`, `ToolbarVGA.v` or
   `ComponentPropertyPanel.v` changed, run `python3 golden/tools/extract_assets.py`
   (only source hashes/line ranges change) and commit it with the candidate.
3. `tools/qor_root_m5.py --out <root>` then `tools/vivado_qor.py --root <root> --out <qor>`.
4. Run `tools/acceptance_m5.py --mode full` for native and Docker at the same time.
   Each runs its checks in parallel (`--jobs`, default a quarter of the CPUs; M5-9).
   Do not edit the checkout while any run is going: the gate fails on input or tool
   changes during checks.

## Gate rules now in force

`tools/acceptance_m5.py` (fast / baseline / full modes, native and Docker):

- **Functional:** frozen frontend-v1 contract, M1–M3 regressions, the 5-seed ×
  64-operation cold corpus, 64/64 functional bins, continuous invariant
  observers and the six scoped proofs.
- **Coverage:** structural coverage measured on native only; gaps are reported.
  A module instance whose source differs from `tools/m5_coverage_baseline.json`
  may not lose line/branch/toggle coverage. Docker runs the corpus uninstrumented.
- **Solver:** actual-IP benches, FP characterization, generated extraction,
  frontend-to-solver UART, and near-singular accuracy no worse than the recorded
  3.7179% relative error (BUG-2).
- **QoR (full mode):** routed Vivado run under the frozen comparison XDC
  `tools/qor/basys3_m5_timing.xdc` (build the input folder with
  `tools/qor_root_m5.py`). Against the recorded baseline (10149 LUT / 4197 FF /
  10 BRAM, setup WNS −1.953 ns, hold +0.027 ns): hold stays clean, setup WNS no
  worse than baseline minus the objective's declared `setup_wns_tolerance_ns`
  (default 0), no new check_timing / DRC / CDC findings, declared resource limits
  and positive gain. A routed Vivado run takes about 4 minutes.
- **Readiness** comes only from checks that ran.

Correctness fixes (BUG items) use the rebaseline path in the plan, not the
optimization gate.

## Final result

Both final full gates passed on the M5-8 candidate, run side by side:
native 44/44 checks in 59.5 min, Docker 43/43 in 55.9 min
(`golden/out/m5-acceptance/m5-8-final-{native,docker}-20261012/`). The candidate,
branch `m5-8-keypad-decode` (keypad character class registered beside its
synchronizer, cycle-equivalent), improves setup WNS from -1.953 to -1.074 ns.
It is **not** merged into `verification`: adopting it moves the recorded timing
and coverage baselines and is a separate decision.

## Next steps (outside M5)

1. Decide whether to adopt the M5-8 candidate. If yes: merge the branch, then
   rebaseline per the plan (QoR corrections, `qor_timing_policy.baseline` from
   its routed report, coverage baseline via `verify_coverage_m5.py
   --write-baseline` on a fresh native corpus).
2. Run the CI workflow once on a self-hosted runner (INF-4 remainder).
3. Follow-up items: TIM-1, QOR-2, BUG-1..3.

## Evidence on the current source (HEAD after this round)

- Native coverage corpus, seeds 1/7/2026/11/12: 3784 frames, 325/325
  checkpoints (`golden/out/m5-coverage-baseline-20261011f/native/`).
- Docker uninstrumented corpus, seeds 1/7/2026/11: 2990 frames, 260/260
  (`golden/out/m5-current-corpus-docker-20261012/docker/`).
- Coverage baseline audit ready, plus negative control
  (`.../m5-coverage-baseline-20261011f/audit-with-baseline/`).
- Solver accuracy baseline and negative control
  (`golden/out/m5-solver-accuracy-baseline-20261011g/`).
- Python tests: 223 pass.

## Known host problem

During the Docker run the host had a kernel display-driver (DRM) task blocked
for over an hour, the load average rose above 200, `/proc` reads of some
processes blocked, and the Docker daemon got stuck creating the seed 12
container. That driver and its children were stopped. Container
`f67baec20f75` (framescope-toolchain, created 2026-10-12 01:05:43 +08:00) is
left in `Created` state; `docker inspect` on it hangs. A host restart is
probably needed before more Docker runs.

## Next steps

1. After the host is healthy: remove container `f67baec20f75`, then run Docker
   seed 12 on the current source:
   `python3 golden/tools/verify_m4.py --runtime docker --framescope ../framescope --seeds 12 --operations 64 --generator 2 --out golden/out/<new>`
2. One full-mode gate run per runtime on the current source, with a candidate.
   For M5-8, pick one bounded optimization, declare its objective (metric, gain,
   resource limits, floors, optional setup tolerance), build the measurement root
   with `tools/qor_root_m5.py`, run `tools/vivado_qor.py --root <root>`, then
   `tools/acceptance_m5.py --mode full --qor <candidate> --baseline-qor golden/out/qor/reply-integrity-view32-candidate-routed-20261011e --objective <file>`.
3. Tick M5-3..M5-8 and INF-4 from that evidence and archive the final scope in
   `docs/m5-verification.json`.
