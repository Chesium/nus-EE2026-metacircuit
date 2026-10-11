# Subagent handoff: M5 isolated epoch qualification

Updated: 2026-10-11T06:43:21.031080+00:00
State: scoped qualification complete; bitmap correction remains isolated/rejected by composed QoR; M5 incomplete.
Author /root/m5_epoch_qualification; parent /root; no descendants.
Main handoff [m5-verification.md](../../m5-verification.md).

## Self-contained assignment and ownership

Workspace `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, verification branch,
HEAD f894fa8dcb487ff02c8f671e4126cc84cf169363; preserve shared dirty work;
no commit/push. Qualify existing initialized validity bitmap correction against
unchanged full frontend corpus and broaden reset/epoch/proof evidence. Preserve
historical original alias witness and generic FIFO defect. No production,
shared gate/policy/evidence/verification-plan edits by this role.

Owned source `golden/out/m5-epoch-functional-source-20261011d`, outputs
`golden/out/m5-epoch-qualification-20261011d`, this document and appended narrow
scope in docs/m5-invariants.md. This role has finished its requested qualification;
do not rerun completed cases on resume. Any future lower-area epoch candidate
needs a new explicit bounded assignment and reset/clear/progress qualification.
Root separately owns FIFO/panel/shadow adoption and composed FPGA acceptance.

## Exact source composition and preserved contract

Complete production snapshot then only historical initialized bitmap replacements
for VisitedMatrixStore.v and ResultMatrixStore.v. No shadow normalization, panel
latch correction or new FIFO wrap correction. Production evolved afterward;
this source must never be relabeled current production. Provenance records all
source/oracle hashes and exact two-file difference, no src symlinks.

- Top src/design/rendering/GlobalRender_top.v:4e62e63dd68ba9e946006a86129d48c39dd7570710a73451f0fd1fba68c2bb16.
- SolverBoard guard:77a637aaf93df02f6adc1dbd50375eeb0fc5d1f08063811300d294597e5ee78b.
- Visited bitmap:862976b0f492ec46a14d4b510e30862443551c0e24ebb1eda47efd2295bd3220.
- Result bitmap:901dc2cbcffca37faa26f0a2c578f590a8e3644eb93545a1c5a6583a16258dc9.
- Original queue:16cdebf7a03ce1b212c25f27a6ececa91b2ceb2850809295d05fb983b00e41ba.
- Original panel:5880297db9a89662309c107fd25bffef7335cbf964447ebececb7b7d1c301554.

`oracle-contract-audit.json` verifies67copied current-required entries against
trusted contract475a48362f0f353104abfde654c25f7bdc60acc266c7a774ca6b256d315b540e.
Four asset JSON source-provenance strings differ as explicitly allowed by frozen
behavior_bytes; bitmap/layout/palette/all other asset behavior remains exact.
No oracle/stimulus/masks/tolerances/latency/initialization changed.

## Completed frontend qualification

Both pinned native and Docker full M2/M3 PASS780frames/103checkpoints each:
M2 boot/full_ui/node_colours/recorded298frames/61checks and fiveM3 scenarios
482frames/42checks. State/UI/pixels/UART/netlist/replies/display comparators stay
unchanged; M2 zero pixel differences. M3 uses unchanged Python solver host and
therefore does not qualify actual hardware solver/FP.

Native1413.904306496s, Docker1727.288080609s, both below originally declared
2400s/runtime. Final drivers confirm source/oracle/harness/simpyhls hash stability
and every capture initialization exactly seed1,seed_explicitfalse,rand_reset0,
x_initialfast,x_assignfast. These are cold accepted M2/M3 captures, not unique
M4 seeded startup proof or inherited initialized RAM.

Exact commands, per-case PIDs/PGIDs, budgets, initialization and hashes are in
native-driver/summary.json and docker-driver/summary.json. Driver command:
`python3 golden/out/m5-epoch-qualification-20261011d/run_runtime.py native`
(and docker). It runs unchanged copied golden/tools/verify_m2.py/verify_m3.py
from the isolated golden root, absolute framescope checkout preserved. No need
to rerun. Aggregate `summary.json` records scoped qualification true, accepted
optimization false, production_adopted false and ready false.

## Completed reset/epoch bench and machine proofs

Both native5.046/Docker5.020 independent logical-store checkers PASS86123clocks,
10276reads,3166accepted writes,65628reset clocks,75clear clocks. Test populates
all288cells, applies65536continuous real reset clocks, reads eachcell, then20000
repeatable random clocks with overlapping operations, invalid coordinates and
one-cycle reset/clear. Every read/write done/value checked with independently
modeled logical values and specified two-cycle read retirement. First clock
asserts reset; arbitrary powerup handshake state is not claimed.
Specific logical-value corruption fails atclock5, nativeexit1/Docker139.

Same unchanged bench reproduces baseline stale region1 atclock65830 after
65536reset clocks, expectedzero/nativeexit1. Baseline stores are separately
pinned in baseline-stores/ (Visited106aad11...,Result23829a52...). Historical
wrapper real65535reset-clock alias witness and FIFO lifetime defect stay intact;
none of the historical artifacts was overwritten. New report
store-baseline-native-report.json, store-report.json and hashed logs preserve it.

Yosys0.33 git2584903a060 at `/tmp/m5-qor-yosys-tools/extracted/usr/bin/yosys`:
actual18x16/EPOCH16unabstracted empty-generation properties PASS temporal
induction depth3 for both stores. Stronger arbitrary watched-cell properties
PASS depth2 for both: after actual synchronous reset/clear, a read of a cell
unwritten since then returnszero, even while othercells arewritten and epochs
wrap. Sole watched-cell assumption is watched_address<CELL_COUNT; all interface
inputs (including invalid coords/reset/clear duration) arbitrary defined values.

Watched proof universally cuts rd_tag/epoch, plus rd_data for Result; these
arbitrary per-cycle signals overapproximate RAM behavior. Actual bitmap and
read/handshake pipeline intact. Four assertions proved together include
unwritten-cell invalidity, read-address tracking and invalidity at response,
then no stale output. Appended formal observers only; actual statement prefix
byte-preservation checked. Missing bitmapreset/clear invalidation produces two
specific bounded SAT failures/exit1 and retained VCDs. Every script/source/tool/
log hash and exact assumptions/scope in proof/report.json. Replay individual
`.ys` scripts with the saved Yosys binary if a new assignment requires it.

These properties do not establish updated-cell data correctness formally,
arbitrary flooding count/progress or pre-first-reset cold handshake safety.
Updated-cell values/overlap semantics have independent directed simulation.
Related/asynchronous clocks, reset deassertion/physical CDC and board validation
remain unsupported. Original directed wrapper ledgers are not promoted to a
universal bound, and root's separate FIFO work is not duplicated.

## FPGA rejection and next concrete step

Historical standalone bitmap delta+813LUT/+578FF, BRAM unchanged.
Parent separately measured composed shadow+panel+bitmap route10671LUT/4740FF/
9.5BRAM/0DSP,WNS-2.699ns,hold+0.007ns,0internalunknown. Frozen scoped safety
objectiveWNS>=-2.0 FAIL; bitmap remains isolated. These are parent-supplied
measurements on a different composition, not this production-top route.
Do not silently broaden budget/objective or adopt bitmap because functional
qualification passes. A future serial BRAM scrub alternative requires explicit
reset/clear completion gating plus source latency/progress and FPGA qualification;
root did not request implementing that large new alternative in this role.
Full M5 remains incomplete. Root integrates these scoped reports and decides
future epoch correction work; completed qualification should not be repeated.

## Job cleanup, descendants and quota completion

All owned drivers/cases/Verilator builds/runs/controls/Yosys proofs and Docker
containers ended naturally; no descendants. Native driver817329/session86396,
Docker817485/session45526 now historical. Per-case groups in driverreports are
historical too; never use numeric IDs without actual command/cwd/lineage checks.
Read-only cleanup.json verifies no owned processes or containers by unique roots;
current inspection ancestry excluded (initial naive inspection matched its own
shell and was corrected). No signals sent and no unrelated daemon/job targeted.
Jobs.json nowongoingempty. No permanent termination claim.

Latest fresh own quota2026-10-11T06:42:07.553334Z:26%five-hour/88%weekly,OK.
Resets2026-10-11T11:09:37Z/2026-10-18T06:09:37Z. Defaults document<10%/<6%,
stop<3%/<2%; parent owns60secondteamtimer. No quota shutdown triggered here;
normal scoped completion. Handoff/results sent to root; agent ends active work
once parent receives this final acknowledgement.
