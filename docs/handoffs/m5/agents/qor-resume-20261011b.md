# M5 QoR BCD and generated-clock resume

Updated: 2026-10-10 19:59 UTC. State: assigned work ended normally; M5 unfinished.
Author /root/m5_qor_resume, parent /root; no descendants.
Main handoff: [m5-verification.md](../../m5-verification.md).

Workspace /home/chesium/ee2026_ws/nus-EE2026-metacircuit, verification branch,
HEAD f894fa8dcb487ff02c8f671e4126cc84cf169363. Preserve shared dirty state.
Resume prior [QoR handoff](qor-resume-20261011.md). Own runner/Tcl/proof tools/tests,
docs/m5-vivado.md and NEW isolated QoR sources/results; no production RTL edits.

Fresh initial quota 2026-10-10 19:35:56 UTC: 97% five-hour, 100% weekly;
resets 2026-10-11 00:35:03 UTC and 2026-10-17 19:35:03 UTC. Default thresholds,
root owns 60-second team checks. Immediate latched shutdown on document/stop/unavailable.

Prior matched real baseline capacity failure and candidate route remain unchanged.
Candidate area fit is established, setup WNS -1.657ns and full readiness false.
Root authorized separate generated pixel-clock retained-DCP diagnostic and
matched new isolated BCD cone optimization/proof with objective frozen before
measurements. Original XDC must remain preserved; no external I/O delays invented.

Pixel RTL ClockDivider FREQ25MHz yields CounterMax1; initialized count0/clk_out0.
Output first rises at second system rising edge, falls at fourth, rises sixth.
Proposed generated clock uses source CLK100MHZ and edges {3 7 11}, period40ns,
without any timing exception. Diagnostic evidence must not masquerade as original
matched measurements or full signoff.

Next: capture generated-clock diagnostic from retained route DCP; replace serial
8-character BCD scan with balanced prefix/rank selection and prove arbitrary
input equivalence before matched synth/route measurement. No active owned job yet.

## Safe checkpoint 2026-10-10 19:42 UTC

Completed derived pixel diagnostic, source-identical original DCP/XDC preserved.
Report `golden/out/qor/pixel-clock-diagnostic-20261011/report.json`: no_clock2,
unconstrained1, missing input10/output44;115new hold failures,WHS-2.486ns.
Remaining latch root coord_len assigned only inside !show_hint_layout. Detailed
primary-source board/interface audit and all unresolved contracts in docs/m5-vivado.md.

NEW BCD canonical tool tools/verify_bcd_rank_m5.py, tests/test_verify_bcd_rank_m5.py.
SAT arbitrary input complete83output cone PASS; exact labeled negative FAIL as
expected. Final proof dirs bcd-rank-proof-final-20261011 and
bcd-rank-proof-negative-final-20261011;26combined tests PASS (6+12+8).
Tool Yosys0.33 is extracted, not globally installed, at
/tmp/m5-qor-yosys-tools/extracted/usr/bin/yosys; Ubuntu package yosys0.33-5build2.
Recreate by apt download then dpkg-deb -x if temporary tool is absent.

Baseline top93bc76d3019d3d1e5a8949a00e32d217d934b4ece5289ec26e1421b7a2a001fb.
Candidate top3da5807ad5ceb75db1332eed61b6699b97616712183cfabe2625c24bc09b1bbf.
New objective aeeecba0aa7db764f9f0aaf1b407259a33269a1581323bce3c04e2ccba7e93df
was frozen before both matched launches.75input files differ only top; source
roots bcd-rank-{baseline,candidate}-source-20261011. No production RTL edits.

OWNED ACTIVE Vivado jobs (inspect job.json and ps before cancellation):
- baseline bcd-rank-baseline-routed-20261011, exec session60018, PGID3420492.
- candidate bcd-rank-candidate-routed-20261011, exec session88482, PGID3420622.
Both currently synthesis timing optimization. Diagnostic and SAT jobs finished.
Next await actual outcomes, strict scratch-source parse and frozen objective
comparison; preserve failures; do not integrate candidate automatically.
Latest fresh own quota19:40:01UTC81%five-hour/97%weekly; root checks60s.
No descendants; parent informed of all findings/jobs.

## Safe checkpoint 2026-10-10 19:48 UTC

Matched BCD pair completed naturally rc0; both strict scratch hashes PASS.
Baseline route10086LUT/4166FF/WNS-1.701/hold0.042; candidate
10240LUT/4164FF/WNS-2.689/hold0.012. Positive synth gain-141LUT,
resource ceilings and setup objective fail; comparison/rejection.json explicitly
reject integration. Structural SAT equivalence still valid. Both prior PGIDs
3420492/3420622 ended; no earlier active jobs remain.

Root authorized fresh dual-clock shadow characterization. OnlyXDC differs from
matched shadow baseline: append exact derived40nsclock, no timing exceptions.
New source root dualclock-shadow-source-20261011; objective/proposal frozen before
launch, objective07fa63fea714b941558364bd81941d022c19cf079d5093bd34b499e0dadd67cf.
All75source hashes frozen. This is characterization only, with external pads,
coord_len inferredlatch and synchronization unqualified; full readiness false.
Owned ACTIVE output dualclock-shadow-routed-20261011, execsession78826,
Vivado PGID3473545. Next await actual route, strict snapshot parse, evaluate
predeclared target and compare exposed system/pixel hold results. Preserve failed
results honestly. Latest own freshquota19:47:49UTC54%five-hour/93%weekly.

## Safe checkpoint 2026-10-10 19:50 UTC

Dual-clock synth completed and confirms generated clock binding: primary10ns,
pixel40ns.10493LUT/4303FF/10BRAM/0DSP;WNS-4.361,holdWNS-1.648 with152
hold failures; no_clock2, unconstrained1, missing inputs10/outputs44. Placement
is running under both related clocks. Sole owned Python runner PID3473232,
child PGID3473545; session78826. If team shutdown is ordered, verify ps ownership
and signal Python3473232 so its handler stops only its Vivado group and writes
honest incomplete evidence; do not touch root's solver/observer jobs. Latest own
quota19:50:33UTC45%five-hour/91%weekly. No descendants. Numeric target results
pending; no production changes or acceptance.

## Safe checkpoint 2026-10-10 19:54 UTC

Dual-clock shadow route completed naturally rc0, strict scratch hashes PASS.
10081LUT/4167FF/10BRAM/0DSP. System setupWNS-1.816 (484failures), overall
hold+0.011 with zero hold failures. Pixel hold+0.106, sys-to-pixel+0.256,
pixel-to-sys+0.011; all115previously hidden hold failures repaired by actual
implementation, no exceptions. Pixel/crossdomain setup positive. no_clock2,
unconstrained1, missinginput10/output44. Numeric setup target and fullreadiness
false. Characterization.json records results. PGID3473545 is empty; no old jobs.

Parent explicitly assigned NEW old-text prefix then final appended-digit
candidate. Keep generator/proof under golden/out until root's verification
inventory gates finish; no new repository tools/testbench edits during freeze.
Generator golden/out/qor/bcd-prefix-tool-20261011.py SHA
fcd783b4c089c60ebd2f91f95c72d1f7c01045828360df2eb45c815377db97ea.
Exact83output arbitrary-input SAT PASS; labeled prefix-BCD xor1 negative detects
counterexample. Proof dirs bcd-prefix-proof-20261011 / bcd-prefix-proof-negative-20261011.
No latency/settleframe changes or selectedvalue consistency assumptions.

New candidate top ab175da0372ab5a4e0c362d48a154c24e2f508ea4f7e332011f02886a13c913d.
New objective 8acf1d522528deeb4a417425d71c133a8fcd048435ba5083abdc4137313a03cc
requires positive synthLUTgain, routedsetupWNS>=0/hold>=0 and ceilings
12000LUT/4500FF/10BRAM/0DSP. Frozen before candidate launch. Both roots use exact
same strengthened dualclockXDC. Existing dualclock-shadow-routed-20261011 baseline
is reused ONLY after verifying all75inputhashes exactly match new baseline root,
including runner/Tcl/XDC; identical tool/settings/part/stages verified. Frozen
proposal bcd-prefix-proposal-20261011.json records allpair hashes and reuse scope.

OWNED ACTIVE new output bcd-prefix-candidate-routed-20261011, execsession pending
initial launch result below. No other owned jobs or descendants. Parent already
has dualclock result. Freshquota19:54:33UTC31%five-hour/89%weekly. Immediate stop/
handoff on prepare/document signal remains latched; no production integration.

New prefix runner details: exec session93483, Python PID3520072, Vivado
PGID3520189. Verify command ownership before cleanup; signal Python3520072 if
shutdown requires cancellation, letting the owned-runner handler kill only that
Vivado group and retain honest incomplete route evidence. No other owned jobs.
Prefix current next step: inspect actual synth/route, preserve all reports even
if frozen positive-area/100MHz setup target fails. Root gates currently freeze
repository verification tool inventory; keep generator in golden/out unless
parent explicitly ends that freeze. No descendants or production edits.

## Final saved checkpoint 2026-10-10 19:59 UTC

State: assigned characterization/proof work complete; broader M5 readiness remains
unfinished. This agent ends normally after saving handoff; no quota threshold
shutdown was triggered during this role. No descendants or active owned jobs.

Final prefix route completed naturally rc0. Strict75-input scratch hash checks
PASS.10207LUT/4160FF/9.5BRAM/0DSP, setupWNS-1.399/TNS-363.328 with472setup
failures; hold+0.011 with zero failures. Compared with exact reused dual-clock
baseline, setup improves0.417ns and BRAM saves0.5, but synth gain is-131LUT
(10493baseline/10624candidate). Predeclared positive-LUT and nonnegative-setup
criteria FAIL; resource and hold criteria PASS. comparison/rejection.json reject
integration; no objectives changed after measurement. PGID3520189 verified empty;
all earlier owned groups also ended. No production RTL/XDC edits by this agent.

Completed this resume: separate derivedpixel diagnostic exposing115hold failures;
legitimate strengthened-XDC route repairing all115hold failures; primary-source
board/interface audit documenting remaining inferredlatch and unqualified
asynchronouspads/outputcontracts; two exact83bit SAT-proven BCD proposals with
labeled counterexample controls and frozen objectives; honest complete matched
reports rejecting both proposals. Sixnew rank-proof tests +12runner +8shadow
proof tests passed. Prefix proof is isolated generator/artifact under golden/out;
repo inventory remains unchanged during root's gates. docs/m5-vivado.md has every
result and external primary-source citations.

Next concrete independent work: focus on now-critical selected-cell coordinate
and pair-address path (17levels, nineCARRY4), prove arbitrary-input source
narrowing without dropping out-of-range address512-space semantics, and freeze
new objective before matched dual-clock measurements. Separately correct and
verify ComponentPropertyPanel coord_len combinational default/latch, and design
qualified RsRx/button/switch/PS2 ingress plus actual board/interface timing scope.
Current best reviewed shadow source is dualclock-shadow-source-20261011 top93bc...
with strengthenedXDC d96ce92d4add6f8944f6761f2c4f3bc1b199a090151022b27769d52750cf7593;
its actual holdfixed route still has setup-1.816 and no full readiness. Prefix
candidate ab175... remains rejected but retained for future proposed combinations.
Root owns whole-frontend regression, production integration and acceptance gate.
Do not adopt prefix or generated XDC automatically. If promoting isolatedprefix
generator into repo tools, coordinate end of root's verification inventory freeze
and rerun/pin the inventory before evidence integration. No descendant recreation
is required.

Final freshquota 2026-10-10 19:59:29UTC:15%five-hour/87%weekly; reset times
unchanged. Default thresholds unchanged, parent owns60-second team checks. No
ownedjobs or descendants remain. Parent receives this document and completion
acknowledgement; normal completion is not permanent host/client termination.
