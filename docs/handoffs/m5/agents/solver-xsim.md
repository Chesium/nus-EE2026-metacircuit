# M5 actual-IP solver pipeline qualification handoff

Parent `/root` authorized continuation from completed FP characterization into
actual SolverBoard UART with the pinned config-equivalent existing products.
No descendants. Main workspace branchverification/HEADf894fa preserveddirtytree.
Owned new files: `tools/verify_solver_xsim_m5.py`, `tools/tests/test_verify_solver_xsim_m5.py`,
`src/testbench/M5SolverUartXsim.sv`, this handoff, solver-doc addendum.
Earlier solver/FP files are documented in [solver](solver-qualification.md) and
[FP](fp-qualification.md); no production RTL/IP/configuration modified.

Fresh phase quota2026-10-10T14:17:59Z44%five-hour/38%weekly, ok; defaults retained.
Parent owns60second team cadence; freeze/document on latched quota alert.

Work: explicit actual solver source manifest, copied unmodified ROM in isolated
XSim output, existing36seeded analytical circuits and exact bit/line expectations,
actual16/28cycle FP probes inpipeline, malformedchecksum parser/recovery and
current-only singular-circuit realexception propagation. Copied bench provides
cold observation corruption. Prior FP characterization report/hashes mandatory.

Initial `golden/out/m5-solver-xsim/qualification-20261010` build failed because
new explicit source manifest omittedSimpleRam; retained failure. Added real
SimpleRam to manifest; no designchange. Historical fixed attempt/session47566:
`python3 tools/verify_solver_xsim_m5.py --out golden/out/m5-solver-xsim/qualification-fixed-20261010 --timeout 180`.
Fixed session47566 completedexit1: actual production `fpo_fma.v` declares4bit
`tuser` but real configuredFMA VHDL declares3bits; XSim rejectsVRFC10-9380 mixed
language portwidth atfpo_fma.v:46. Root notified and owns the minimalproduction
wirewidth correction. Verilatorstand-ins exposed4bits and hid thisbug.
No active ownedjob.20Python tests pass (8solver+9FP+3XSimsetup). Latestlivequota
14:22:40Z29%five-hour/36%weekly, ok. Rerun actualpipeline afterrootfix. Report schema
`metacircuit.m5-solver-xsim.v1`: `scoped_actual_pipeline_passed`, `observed`,
`configuration_audit`, `fp_characterization`, `source_sha256`, `operations`,
`acceptance.full_m5_ready=false` regardless scopedpass. No original-XCI synthesis
acceptance; revision21generatedproducts vs6originalXCI flagged.

Next: inspect actual run/negative logs, correct only harness/setup bugs, report
any actualRTL defects toparent. Scope36circuits (1/2electricalnodes,2/3elements),
parser checksum/recovery and1singularcase; not32capacity/generalnets. Full
frontend ↔solver loop currently runs only unvalidatedVerilator stand-ins; its
actualIP XSim qualification remainsoutside this bounded followup.

## Final candidate checkpoint

Root authorizedisolated candidate minimalFMA widthfix while productioncaptures
finish. Final command/session1390 completedexit0:
`python3 tools/verify_solver_xsim_m5.py --out golden/out/m5-solver-xsim/qualification-candidate-20261010 --fma-wrapper golden/out/m5-solver-xsim/qualification-candidate-20261010/fpo_fma.v --timeout 180`.
`report.json` scoped_actual_pipeline_passed=true, coldresponsecontrol detected,
noeffective source drift;38solves/127replylines.36analytic+1recovery+1singular;
primary244FMA/173divide actualresultsall16/28latency. ParserbadchecksumER01/0003
and recovery pass. Singularcurrent-only circuitfp_exception1/status05/-infinity.
21Python tests pass (8solver+9FP+4XSimsetup). No active ownedjob or descendants.

CandidateeffectiveSHA256:
9c1daa50bb18196ff22615da92bcf8a3b0697647e821db45376d735948f05ec7.
OriginalproductionSHA atstart:
b623a6ab1db3cd99c906ac27d7da4be41b74756418cdad3c3928c29193f9cdf8.
Report `source_overrides` containsallpaths/hashes, minimal_width_fix_verified=true,
production_identity_matches_at_end=false (roothasnotyetappliedproductionfix).
Root notified; requireproductionhashmatchbefore usingcandidateasfinalRTL evidence.
Runner explicitlyallows onlyexactoriginalwrapper with3bittuser changed.

Nextconcretestep: rootappliesexactcandidate/compareshash afteritscapturesfinish,
then integratesnewactualpipeline report honestly. FullfrontendactualIP,
32node/capacity/generalcircuit coverage and originallockedXCI synthesis remain.
The completedFP runnerreport remains valid (FMAwrapper isnot its dependency).

## Production reconciliation and direct verification

Root appliedexactFMA widthcorrection and confirmed currentproductionSHA equals
candidate9c1daa50... (fullhashabove). Originalcandidate report ishistorical and
retainsproduction_identity_matches_at_end=false truthfully foritsrun time.
Freshlivecheck14:26:36Z18%five-hour/34%weekly ok. Bounded directproduction rerun
launchedsession20894 (nooverride):
`python3 tools/verify_solver_xsim_m5.py --out golden/out/m5-solver-xsim/qualification-direct-final-20261010 --timeout 180`.
Directsession20894 completedexit0; source_overrides={} and productionFMA
SHA2569c1daa50bb18196ff22615da92bcf8a3b0697647e821db45376d735948f05ec7
recordedunderrealproductionpath. Allsame38solves/127replylines, primary244FMA/
173divide configuredlatencies, checksumerror/recovery/singularFPstatus andcold
observationcontrolpass. Noeffective source drift. Nocurrentownedjob ordescendant. Analyticalscopeunit00;
UART accelerated10MHz whileclockremains100MHz. Default115200 transportwithactual
IP andotherunits remainunqualified; actualprimitive16/28latencychecked.
