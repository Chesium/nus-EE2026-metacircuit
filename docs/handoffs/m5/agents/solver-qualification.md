# M5 solver qualification subagent handoff

Assignment: M5-5 actual generated extraction/solver and physically connected
frontend-to-SolverBoard UART qualification. Parent `/root`; no descendants.
Workspace `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branch `verification`,
HEAD `f894fa8dcb487ff02c8f671e4126cc84cf169363`; dirty shared tree preserved.

Owned new files: `tools/verify_solver_m5.py`,
`tools/tests/test_verify_solver_m5.py`, `docs/m5-solver.md`,
`src/testbench/M5Solver{Extraction,Uart,Frontend}.sv`, this document.
No existing RTL/oracle/evidence modified. No commit/push or descendants.

Completed foundations: deterministic analytical fixture generator; 320 actual
extraction fixtures with response stalls; 36 actual solver-board UART fixtures
with120 expected reply lines; actual frontend↔SolverBoard UART boot and split-rail
edit bench; cold observation corruption control per bench; configuration/source/
ROM/artifact provenance and deliberately blocked readiness runner. Eight policy/
fixture tests pass initially. See `docs/m5-solver.md` for precise scope/limitations.

Initial run `golden/out/m5-solver/qualification-20261010` intentionally retained:
extraction failed an overstrong testbench address-stability assertion. Generated
start/done primitives capture arguments at start and need not hold them through
done; corrected the bench rather than RTL. Corrected boot-only run
`golden/out/m5-solver/qualification-fixed-20261010` passed all320 extraction cases,
36solver netlists/120reply lines and real frontend boot10V; all three negative
controls detected. Both commands return1 because actual configured FP is blocked.

Final command:
`python3 tools/verify_solver_m5.py --out golden/out/m5-solver/qualification-final-20261010 --jobs 4 --timeout 300`.
Completed session30943 with deliberate exit1 for FP qualification blockers.
`report.json`: all three `passed=true`, `negative_control_detected=true`;
extraction320cases/191003stallcycles; UART36netlists/120replylines; actual frontend
boot acceptedVGAframe2 and edited split rail acceptedframe11 withid2/10V/0V.
No source drift. Final eight Python tests pass. No active owned jobs or descendants.

Blocker: FMA/div stand-in latencies4/6 versus original XCI16/28; exception flags
always0 and arithmetic not characterized against configured IP. Vivado sibling
confirmed original2018.2rev6 IP locked under2025.2rev21; no fresh products generated,
no upgrade authorized. Root-requested read-only audit FOUND existing ignored
`src/ip/floating_point_{fma,div}` simulationVHDL/encryptedHDL/Cmodels/DCP/funcsim
netlists. Headers are2025.2/core7.1rev21, dated2026-03-13; they differ from tracked
XCIrev6. VHDL genericmaps show FMA16/div28, correct single-precision operations
and exceptionflags. Existing projectLU XSim cache compiles `src/ip_new`, not
originalconfig. Root notified; candidates require a separately pinned parameter/
provenance audit and actual simulation rather than being silently trusted. Runner readiness remainsfalse/exit1. Full M5-5 is incomplete.

Next concrete step: pin/audit existing original-directory revision21 product
parameters against originalXCI, and measure actual XSim primitive behavior+latency;
if provenance cannot be qualified, obtain reviewed
compatible actual IP simulation products; add configuration-pinned primitive
behavior/latency/exception tests before promoting solver tests. Extend extraction
beyond isolated components, solver beyond analytical 1/2-node systems, general
randomized nets/full capacity/error cases/reduction. Preserve frozen contract.

Quota defaults: documentation below10%five-hour or6%weekly, stop below3%/2%; team
shutdown latched on parent alert. Initial freshcheck2026-10-10T14:00:36Z97%/47%;
latest solver directcheck14:08:56Z71%/43%, ok. Bounded followup actualFP
characterization completed separately; see [FP handoff](fp-qualification.md). Parent owns60second team cadence.

Subsequentroot-authorizedactualFP/directpipeline work completed; linked
[FP handoff](fp-qualification.md) and [actualpipeline](solver-xsim.md).
RealFMA527+DIV527bitexactcases pass withactual16/28latencies/fourcontrols;
actualcurrentSolverBoard38solves/127replylines pass plusparserrecovery/singular
FPstatus05/negativecontrol. Rootfixed FMA exceptionwirewidth3; directactualreport
pinsrootproductionfilehash9c1daa50..., nooverride. Stand-in fullfrontendloop
remainsprovisional; fullM5/capacity/originalXCIrevision6synthesisremainunqualified.
