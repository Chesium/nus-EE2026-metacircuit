# M5 floating-point characterization subagent handoff

Parent `/root` assigned bounded actual existing-product qualification after
solver work. No descendants. Workspace
`/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branch `verification`,
HEAD `f894fa8dcb487ff02c8f671e4126cc84cf169363`, preserved dirty shared tree.

Owned NEW files: `tools/verify_fp_m5.py`, `tools/tests/test_verify_fp_m5.py`,
`src/testbench/M5FpCharacterization.sv`, `docs/m5-fp.md`, this handoff.
Existing solver role files remain owned as recorded in
[solver handoff](solver-qualification.md). No existing RTL/IP/oracle/configuration
modified, no upgrade/regeneration, no commits/pushes, no descendants.

Completed: existing ignored `src/ip` products audited against tracked XCIs;
actual isolated XSim elaboration+simulation works. All70 original MODELPARAM
values per core match wrapper maps (77generated generic assignments); no missing
or mismatched original model parameters. Headers identifyproductrev21 versus
originalXCIrev6/2018.2; revision mismatch remains explicit and synthesis remains
unqualified. Existing installed IP library use is pinned by full-file SHA256;
original ignored wrapper products and tool binaries are also pinned.

Actual test command:
`python3 tools/verify_fp_m5.py --out golden/out/m5-fp/characterization-final-20261010 --random-cases 512`.
Result exit0 for scoped characterization, **not overall M5 acceptance**.
527FMA +527DIV edge/seeded-rational cases match result+flags bitexact;
measured configured latency16/28 on every result. Four cold controls detected
FMA data corruption, divideflag corruption, expectedFMA17/expectedDIV29 latency.
XSim returns0 even on$fatal; runner requires fatal witness and absent passmarker.
Full artifacts/report/commands/tool+source+library+fixture hashes retained.

Python tests: `python3 -m unittest discover -s tools/tests -p 'test_verify_*m5.py'`
passes17 (9FP+8solver). Oracle exact rational rounding independently tested for
both tieparities/fused cancellation, signeddenormal flushing, exceptionbits,
NaN quieting,500smallinteger host checks, seed determinism and configuration
mutation rejection. Manual semantics source linked in docs/m5-fp.md.

All owned sessions complete: probe67088/78334, firstcharacterization24567,
final45262; no active owned job or descendant. No user/project cache touched.
Generated evidence directories ignored byGit, including probe and initial run.

ActualSolverBoard UART followup completed againsttheseproducts; see
[direct actual-pipeline handoff](solver-xsim.md),38solves/127lines.
Concrete next step: extendactualfront-end UART loop against these pinned,
configuration-equivalent existing actualIP products in isolated XSim. Preserve
revision21vs6 mismatch and avoid original-XCI synthesis/readiness claim. Existing
Verilator stand-ins remainwrong latency4/6, zeroexceptions and differentdenormals;
current tools/verify_solver_m5.py remains deliberately blocked/exit1. Further
mixed input-valid skew patterns, broader randomized circuits and solver capacity/
error systems remain unqualified. Docker solver role optional and unimplemented.

Quota fresh phasecheck2026-10-10T14:09:24Z69%five-hour/42%weekly; latest direct
check14:14:19Z54%/40%, ok. Defaults preparebelow10%/6%, stopbelow3%/2%; parent
owns60second team timer; stop on latched alert. Ended normally with no quota
trigger and no background jobs. Root must endlast if later team shutdown occurs.
