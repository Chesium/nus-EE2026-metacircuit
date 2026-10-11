# Subagent handoff: M5 address arithmetic equivalence

Updated: 2026-10-10 UTC, after actual candidate native/Docker qualification
State: completed bounded proof assignment; parent owns production/QoR acceptance
Author: /root/m5_invariants_resume
Parent: [M5 main handoff](../../m5-verification.md), /root coordinator
No descendants.

## Self-contained assignment and ownership

Main workspace `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branch
`verification`, HEAD `f894fa8dcb487ff02c8f671e4126cc84cf169363`.
Own files: `src/testbench/M5AddressEquivalence.sv`,
`tools/verify_address_m5.py`, `tools/test_verify_address_m5.py`, this handoff.
This agent never edited production RTL or earlier invariant files. Root applied
the candidate to `GlobalRender_top.v`; all unrelated shared dirty files remain.
No commits/pushes or configuration changes were made.

User explicitly authorized parallel M4/M5 under codex-usage-guard defaults.
Initial fresh check is mandatory on resume; parent checks every60seconds while
agents run. Recreate this role only for new arithmetic proposals, changed helper
source or new proof requirements. Its finite-domain actual-source proof is
complete. Next parent work is integration regression and measured candidate
Vivado comparison; equivalence alone does not qualify an optimization.

## Proposal and exact semantics

Three original helpers used `/ CANVAS_GRID_W` or `% CANVAS_GRID_W` with fixed
18 columns: `canvas_addr_to_i`, `canvas_addr_to_j`, and
`component_position_from_addr`. Width is nine bits for 288 logical cells.
The candidate replaces those expressions with shared packed decode from five
unsigned compare/subtract stages at 288,144,72,36,18, with four quotient bits
and five remainder bits. No new registers, retiming or ports are involved.
Root's `decode_canvas_address` is extracted verbatim in candidate proofs.

All512 nine-bit inputs matter, including224 addresses outside logical RAM.
The original quotient is truncated to four bits, rather than clamped/rejected.
For address288, original packed position is zero; for511, it is `{4'd12,5'd7}`.
First subtracting288 and omitting quotient bit4 preserves that behavior. The
inverse helper also accepts all512 packed positions, including columns18..31;
it is not clamped and can yield addresses above287. Direct inverse-helper
outputs are tested for all512 packed positions, as well as decoded-position
roundtrip composition. There is no restriction to reachable valid addresses.

The bench includes the proposed independent combinational implementation.
`--candidate-source` instead compiles copied actual production helpers and
`decode_canvas_address` dependency; this mode was used for final qualification.
The reference comes from the frozen frontend-v1 payload, whose complete source
SHA is pinned in the runner:
`254c8842d72c6c4801ef015c8c3274687a970c8794f9d09e6d966ced42657a66`.
The reference cannot silently regenerate from changed live candidate RTL.
Reference and candidate generated modules remain in each output directory.

## Verification and commands

All completed successfully:

```sh
python3 tools/verify_address_m5.py --runtime native --candidate-source src/design/rendering/GlobalRender_top.v --out golden/out/m5-address/candidate-native
python3 tools/verify_address_m5.py --runtime docker --candidate-source src/design/rendering/GlobalRender_top.v --out golden/out/m5-address/candidate-docker
python3 -m unittest discover -s tools -p test_verify_address_m5.py -v
git diff --check
```

Actual candidate helpers match the frozen original for512/512 inputs in both
runtimes: col, row, packed position, direct inverse output and inverse composition.
Normal exit0; corrupted candidate observation at address287 fails with specific
`M5_ADDRESS_FAILURE addr=287` (native exit1, Docker exit139). Specific failure
label is required; unrelated crashes are not accepted as a negative control.
Native Verilator5.046 and Docker5.020. Both JSON reports `ok:true`; each checks
that reference/candidate sources did not change during the run. Current file
hashes were compared to both final reports after completion:

- Candidate actual complete source SHA:
  `0b32341ce8cd8b9df90c70874bf2a408874cbf2402881f3cb0ce5a7008df644f`
- Bench SHA:
  `a72972c46a0ee02c560806c6ed21b95d35ca13c9597effce49cf684ab1ce9b51`
- Runner SHA:
  `72a7fa56fca5c889c3cfaa1a1f1c8d70ee8ecbeb7f995b2898d4c45b45d4fe07`
- Generated frozen reference SHA:
  `e334a133a51e56755ee1e7129444ced114d4768c3122762a92256cd189a5dfd5`

Ten Python tests verify trusted frozen identity, exact extraction, fixed geometry
and width/count assumptions, absent/duplicated helpers, shared decoder extraction,
full invalid-domain coverage and fail-closed acceptance. Preliminary `native`,
`docker`, and `native-pinned` reports are preserved as historical independent
proposal proof; only `candidate-{native,docker}` proves actual root candidate
source with current runner/bench identities.

## Measurement context and limits

Baseline frontend synthesized hierarchy reports total24117LUTs, of which8547
are attributed to `canvas_command_guard_inst`,4295 to VGAControl,4272 to the
top and2710 to extraction. The worst synthesized path has -5.176ns slack from
keyboard ASCII to netlist dirty state through digit/text cones. Flattened
hierarchy labels do not prove division18 causes those costs. Address arithmetic
was chosen as a bounded combinational proposal; LUT/timing reduction remains a
hypothesis until actual candidate Vivado reports. Root owns report validity and
comparison; this agent does not claim an FPGA improvement.

This is exhaustive combinational equivalence over the finite two-state helper
ports. Four-state X/Z equivalence, entire production design equivalence,
physical area/timing and board behavior remain unqualified. No Yosys executable
was available; no formal solver proof is claimed. The helper result does not
close global M5-4 invariant/progress requirements.

## Jobs, quota and completion

All owned runner jobs finished; latest Docker session7971 exit0. Earlier Docker
session60786 and native68011 completed. No owned background jobs or descendants
remain. No production processes were stopped. This role completes normally.

Initial direct check14:08:53.847408Z: OK71% five-hour/43% weekly.
Latest direct check14:12:54.797889Z: OK59% five-hour/41% weekly; resets
2026-10-10T18:59:37Z and2026-10-14T15:27:22Z. Default prepare below10%/6% and
hardstopbelow3%/2%. Parent owns team cadence; no quota shutdown was triggered.
Separate handoff/evidence paths sent to parent before ending this turn.
