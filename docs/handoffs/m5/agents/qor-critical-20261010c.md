# M5 selected-pair critical path and coordinate latch qualification

Updated: 2026-10-11 01:22 UTC. State: assignment completed normally;
M5 full readiness remains unfinished. No active owned jobs or descendants.
Author /root/m5_qor_critical; parent /root; no descendants.
Main handoff: [m5-verification.md](../../m5-verification.md).

## Self-contained replacement assignment

Workspace `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branch verification,
HEAD `f894fa8dcb487ff02c8f671e4126cc84cf169363`. Preserve all shared dirty work;
no commits/push/production edits. Read [previous QoR](qor-resume-20261011b.md).
Own isolated QoR output roots and docs/m5-vivado.md; coordinate any shared runner
changes with root's frozen inventory. Rejected BCD candidates remain rejected.
No timing exceptions or clock weakening. Root owns sixty-second team quota timer;
document/stop/unavailable starts immediate latched checkpoint/shutdown.

Seek bounded measured improvement preserving the frozen frontend contract. Three
independent exact-source proposals: signed 11-bit pair arithmetic (full -18..529
range, all512base addresses retained), direct-range pair arithmetic, and default coord_len=0 eliminating the
hint-branch inferred latch. Both use the exact related10ns/40ns shadow XDC;
production XDC and sources unchanged. Async pads/output budgets remain unqualified;
new synchronizers would alter latency and require separate approved contracts.

## Saved work and verification

`golden/out/qor/pair-narrow-tool-20261010c.py` reconstructs the pinned reviewed
shadow source, changes only pair_addr_for_cell integer delta/tmp into signed11bit
temporaries with explicit zero extension and signed bounds. Candidate top
`f86f59a278fd7168aa505636437c0bcc036fb010569b68c6a9fe13e0134f40a8`.
Yosys0.33 SAT PASS for arbitrary512addresses/64types/4rotations; XOR1negative
counterexample PASS. Report `pair-narrow-proof-20261010c/report.json`.
Exact unchanged remainder transfers equality; no range/coordinate assumptions.

`pair-narrow-objective-20261010c.json` SHA256
`44a0d7f516d2ff5dfd6efcaa77f18e32b37b02427c7a85f48d358a05cc1887bc`
frozen before launch: synth LUTgain>=1, routed ceilings10081LUT/4167FF/10BRAM/0DSP,
WNS>=-1.716ns (at least0.1ns improvement), hold>=0, no_clock<=2/unconstrained<=1.
All75baseline input hashes exactly match original dualclock-shadow-routed-20261011;
only top differs in candidate. Proposal retains hashes/settings and reuse scope.
This provisional objective cannot establish100MHz/fullreadiness.

`coord-default-tool-20261010c.py` generates separate panel-only candidate, adding
exactly coord_len=0 at the combinational block start. Actual-source DynamicTextBox
next-state proof preserves timing/output registers; reference blank data with any
stale length compared with candidate blank data/length0; all nonhint inputs equal.
SAT proof and visible-A counterexample control PASS. Candidate panel identity
45ca2444a42286dce2cb0c71b1364762a8ec60b825277f94f086cc2337c73786.
Actual full panel source/dependencies after Yosys proc show exactly1baseline
dlatch versus0candidate; latch-inventory.json records checks/logs. Separate
source-root has unchanged top and XDC.

`coord-default-objective-20261010c.json` SHA256
f448071ada8bcc6bdb00c74352747d8a86a04daeb345797445e859afbda21856
was frozen before second route: no_clock=0/unconstrained=0, hold>=0, setup>=-2.0ns,
ceilings12000LUT/4500FF/10BRAM/0DSP. Explicit permitted0.184ns setup degradation
vs baseline; objective only qualifies latch correction, not100MHz or fullreadiness.
All75baseline hashes exactly match retained baseline; only panel differs.

## Jobs and next step

Pair narrowing synth10493baseline versus10502candidate yieldsgain-9; predeclared
positive-LUT criterion FAIL. Final comparison/rejection saved. SynthWNS-3.789 vs-4.361 (gain0.572ns), FF4302,
BRAM9.5. Coord default synth10637LUT/4296FF/9.5BRAM,WNS-4.686 confirms actual
Vivado no_clock0/unconstrained0, still10missinginput/44missingoutput delays.

Distinct direct-range pair proposal SAT/negative PASS, top306711c4e679f971f7d1fa78fab5047e86cffe372cbd1653711bc3b8db19ce40.
`pair-range-tool-20261010c.py` generates four constant directions; bounds before
9-bit add/sub preserve every512-address result, including288->287 subtract1 and
305->287 subtract18. All75baseline hashes match; only top differs. New frozen
objective/proposal uses IDENTICAL criteria/hash44a0d7f... as narrowing; no revised
thresholds. Route launched only after prior pair/latch jobs finished.
Direct-range synth completed10628LUT/4301FF/10BRAM,WNS-4.373. Frozen positive
synthgain FAIL (-135); final comparison/rejection saved. No further proposals
planned, no production adoption.

- Pair route session35697 completed naturally rc0;75-input strict scratch hash
  validation PASS. Routed10088LUT/4165FF/9.5BRAM/0DSP,WNS-2.248,TNS-589.124,
  628setupfails,hold+0.053/0fails. Positivegain/routedLUTceiling/setup criteria FAIL;
  comparison/rejection saved. Runner55026/PGID55335 ended, no production adoption.
- Coordinate proof session32099 and coord route session94879 completed naturally
  rc0. Strict75-input hashes PASS.10250LUT/4159FF/9.5BRAM,WNS-1.585 (gain0.231),
  TNS-312.321/452fails,hold+0.022/0fails; no_clock0/unconstrained0,external10/44
  unknown. All frozen latch-objective checks PASS; comparison/qualification saved.
  LUTincreases144synth/169route retained honestly; correction prioritizes latch
  removal/fit/timing rather than positivearea. Main root owns regression/adoption.
  Runner68753/PGID69629 ended; all proof jobs finished.
- Range route session96981 completed naturally rc0, strict75-input hashes PASS.
  Routed10208LUT/4167FF/10BRAM/0DSP,WNS-2.303,TNS-525.826/499fails,hold+0.037/0fails.
  Positivegain/LUTceiling/setup criteria FAIL; comparison/rejection saved. Runner
  106188/PGID106246 ended. All three historical owned groups verified empty.
- No shared source/tool modifications, no descendants.

## Concrete next steps and reproduction

The isolated default-coordinate-length panel correction is the ONLY accepted
provisional objective; root was notified. Decide adoption only after whole-frontend
regression and explicit contract review, copying only the panel insertion from
`golden/out/qor/coord-default-candidate-source-20261010c/src/design/Dashboard/ComponentPropertyPanel.v`.
Its top is unchanged reviewed shadow; do not copy isolated strengthened XDC or
rejected arithmetic tops automatically. Hold clean and inferred latch removed;
100MHz setup and external pad/output timing remain unqualified. Real UART/button/
switch/PS2 ingress/reset-release and board receiver timing contracts need a new
explicit source/protocol scope before exceptions or added pipeline latency.

Retained source roots and candidate reports are complete; do not rerun completed
roles or overwrite historical output. Inspect any candidate with its pinned runner,
for example `python3 golden/out/qor/coord-default-candidate-source-20261010c/tools/vivado_qor.py --root golden/out/qor/coord-default-candidate-source-20261010c --out golden/out/qor/coord-default-candidate-routed-20261010c --parse-only --check-working-tree`.
All three candidate reports pass this strict check. Proofs use the extracted
Yosys0.33 binary at `/tmp/m5-qor-yosys-tools/extracted/usr/bin/yosys`; recreate
Ubuntu package yosys0.33-5build2 via apt download/dpkg-deb-x if needed. Canonical
isolated generator scripts and reports preserve SHA256 and full proof logs.
No tests/tool inventory added or modified; root's acceptance freeze unaffected.
Whitespace check passes; baseline rejection and new failures retained honestly.

## Quota

Initial fresh check2026-10-11T01:08:51Z:98%five-hour/85%weekly.
Final fresh own01:22:17Z:43%/76%; resets06:08:23Z /2026-10-17T19:35:03Z.
Default prepare<10%/<6%, stop<3%/<2%. Root owns60-second checks. Handoff path sent
to parent; assignment ends normally without a quota shutdown. No descendant
recreation is required, no owned jobs remain, no permanent client termination
claim. Parent receives this saved document and completion acknowledgement.
