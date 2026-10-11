# M5 acceptance entry point

Run the same Python entry point locally and in the manual GitHub workflow:

```sh
python3 tools/acceptance_m5.py --mode fast --runtime native --out golden/out/m5-acceptance/NEW-fast
python3 tools/acceptance_m5.py --mode baseline --runtime docker --out golden/out/m5-acceptance/NEW-baseline
python3 tools/acceptance_m5.py --mode full --runtime docker --out golden/out/m5-acceptance/NEW-full \
  --qor /absolute/candidate-reports --baseline-qor /absolute/baseline-reports \
  --objective /absolute/declared-objective.json
```

Every output directory must be new. `fast` verifies the trusted frozen contract,
adapter/comparator policy, pinned runtime, golden typecheck/tests, Python controls,
and complete framescope tests. `baseline` adds fresh independent comparison of
saved unchanged-source M2/M3 captures, strict M4 corpus evidence and all 64 named
functional bins. It requires the exact frozen RTL inventory and accepted harness
source/manifest hashes; missing ignored captures fail rather than becoming skips.
Adapter core states are compared to the saved independent golden RAM/state.

`full` runs fresh fixed M1/M2/M3 scenarios (including exact-frame M1 latency),
five cold 64-operation v2 seeds with coverage, four directed persistent sessions,
continuous invariant and solver runners (including the supplemental first-ready
map/read witnesses, five-phase dirty restart deadlines and the actual default-baud
frontend-to-SolverBoard edited loop),
then revalidates contract and source
identity. Source inventory includes new HDL, XCI, ROM and constraint files.
The gate pins `frontend-v1` and a separate policy identity; it never regenerates
accepted references or changes frozen package scripts. The supplemental policy
pins the existing solver ROM that the original freeze did not include, plus the
adapter, default configuration and M3 comparator wrapper.

The current full mode deliberately fails readiness: global invariants/proofs,
configured FP acceptance and reviewed line/toggle coverage exclusions remain
unfinished. Scoped invariant/solver successes cannot remove these requirements.
Fast/baseline may exit zero with `ready=false`; full requires `ready=true`.
This is gate infrastructure, not a claim that INF-4/M5-7/M5-8 are complete.

Full mode rejects missing mandatory QoR/objective inputs before launching the
expensive regression batch. It also parses and revalidates supplied reports before
that batch, requires complete routed evidence and a passing declared objective,
and rejects changed part, top, source/IP lists, constraints, build/settings or
clocks. The baseline's measured frontend sources must match the immutable frozen
baseline. Candidate source hashes are checked against the actual checkout again
after the corpus; a saved report cannot qualify later RTL edits.
The policy separately pins the A-008 ready/read-retirement correction for QoR's
baseline comparison, with its decision recorded in `docs/m5-decisions.md`.
This does not regenerate the original contract or permit saved unchanged-baseline
captures to stand in for a corrected-source functional run.
Subchecks for actual FP, actual SolverBoard XSim and
frontend invariants require both a successful process and a present JSON report
with its exact Boolean verdict. XSim can return zero after `$fatal`, so its own
runners inspect failures and pass markers rather than accepting the exit alone.

Optimization objectives specify `metric` (lut, ff, bram, dsp, or wns_ns), positive
`minimum_gain`, all four `maximum_resources`, `minimum_wns_ns` and
`minimum_whs_ns`. Missing/nonfinite numbers, no gain, resource-limit failures,
missing/stale/corrupted route reports and unresolved timing/CDC/DRC fail.
Vivado completeness and timing readiness are checked separately.

For a baseline that cannot fit the device, an objective may explicitly add
`"comparison_stage": "synth"` for a resource metric. Pass the retained real failed
route with `--baseline-route-attempt`. The gate requires identical baseline inputs
and synthesis metrics, the exact Basys 3 UTLZ-1 placement failure, and uncorrupted
artifacts. It compares resource gain from synthesis to synthesis, while requiring
the candidate's complete routed measurements, resource ceilings and setup/hold/
CDC readiness. Other route failures, absent witnesses and synthesis-only candidate
reports fail. This implements the plan's bounded improvement path for an infeasible
baseline without claiming that baseline was timing-clean.

The separate pinned policy declares cold seeds `1,7,2026,11,12`, generator 2 and
64 operations per seed. It permits at most 3,600 seconds per command and 21,600
seconds for the entire gate. An exhausted budget stops further commands, records
failure and cleans up only the command's owned process group. These are test
execution limits, not architectural latency bounds or simulation tolerances.
The default semantic adapter configuration hash is also checked at runtime.

The manual workflow requires a provisioned `metacircuit-verification` self-hosted
runner, sibling accepted framescope checkout configured through the repository
variable `FRAMESCOPE_CHECKOUT`, Node/npm dependencies, Docker image
`framescope-toolchain:6501155dc903` (Verilator 5.020), native Verilator 5.046 and
Vivado 2025.2 for separately produced reports. It runs both runtime jobs and
archives their evidence. This workflow has not been executed on GitHub.

Full mode requires a separate `--extraction-only` generated-RTL qualification on
each pinned runtime. Its 320 seeded fixtures exercise all type/rotation terminal
pairs and bounded response stalls, with a specific first-case corruption control
and source readback. It returns a scoped extraction verdict; provisional UART/
frontend benches with FP models cannot qualify the vendor-IP pipeline.

Every gate report now pins the runners, policies and M5 observer bench inventory
at launch and rejects changes during checks, in addition to the candidate HDL/IP/
constraint inventory. Supplemental policy hashes are checked separately.

Fresh Docker fast recovery (`golden/out/m5-acceptance/final-pinned-docker-20261010c/summary.json`)
passes all eight checks, including the final contract/inventory audit. The complete
framescope suite passes 135 tests with the same seven optional skips. The prior
Verilator 5.020 internal Thread Pool error did not reproduce in the original
isolated coverage test, a complete independent harness suite, or the new fast
gate. No accepted harness source, immutable harness pin or failure policy changed
to obtain these results. Its underlying cause remains unknown. Fast-mode
`checks_ok=true` and `ok=true` retain `ready=false`; M5 readiness is incomplete.


Current composed production Docker recovery (`golden/out/m5-acceptance/shadow-queue-panel-docker-20261011d/summary.json`,2026-10-11T06:38:18Z) passes all eight fast checks with `checks_ok=true`, `ok=true`, `ready=false`. It pins adopted shadow top93bc76, epoch queue6e80cf, panel45ca244, SolverBoard guard77a637 and unchanged constraints. The complete accepted Docker5.020 harness suite passes135tests/7optional skips in130.527s; golden-Python109tests pass after root refreshed screen asset provenance. Both original failing isolated harness tests also pass unchanged (coverage merge12.569s; inverted/framing/length UART loopback8.411s). The preceding two locked ThreadPool errors remain real preserved failures; their cause is unknown and no accepted harness source or failure policy was changed to obtain recovery. Independent launch/final pins cover source/IP/XDC, verification tools/policies, harness source/tests and extracted assets; all match. Every gate log digest was checked. Driver/audit/cleanup evidence is in `golden/out/m5-gate-recovery-20261011d-driver`; no owned processes or containers remain. Fast success does not establish full M5 readiness.

The continuing gate now requires six fresh scoped safety results in development
and full modes: watched FIFO order, guard conditional completion, quiescent
component progress, parser dispatch/range, receiver bank integrity and real UART
malformed rejection/recovery plus32node navigation. Baseline replay mode retains
its immutable historical scope. Each new checker/helper/bench is policy-pinned;
missing or false result files fail even with process exit0. Seventeen gate
fixture tests pass, including both controls for every new report. These checks
add qualified safety evidence; global progress, coverage/IO/CDC and original-IP
limitations still prevent full readiness. Final fresh runtime gates are pending
production correction integration.
