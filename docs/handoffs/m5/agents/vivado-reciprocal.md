# Bounded reciprocal candidate Vivado measurement

Owner `/root/m5_vivado_resume`, parent `/root`; no descendants. This is a later
bounded continuation; prior tooling, baseline, failed route and rejected candidate1
are preserved in [vivado-resume.md](vivado-resume.md).

Own this handoff plus earlier runner/docs assignment; do not change production RTL.
Root authored isolated scratch source at
`golden/out/qor/reciprocal-candidate-source`, copied from immutable baseline inputs.
Only GlobalRender_top address helper differs: narrow16-bit reciprocal multiply114,
quotient>>11, remainder addr-q*18. Parent reports all512 address proof passes;
this agent measures only, not proving or accepting functional behavior.

Fresh live quota2026-10-10 14:20:29UTC37%five-hour37%weekly, resets18:59:37UTC
and2026-10-14 15:27:22UTC. Default thresholds unchanged; root owns60-second team timer.
Runner unchanged. New measurement output `golden/out/qor/candidate-reciprocal-synth`
requested_stage synth; original required routed failure stays preserved.

Current operation: launched synthesis using explicit --root scratch source,
copying all inputs again into measurement inputs. Job details/hash audit pending.
Objective is existing golden/out/qor/address-objective.json (LUT gain>=1,
no resource increase, WNS>=-5.176ns, hold>=0), archived by root before launch.
Next: verify input differences/job group, await final reports, compare exact
objective with baseline-final-synth. No production edits or silent waivers.

## Measurement checkpoint

Session40433, Python runnerPID2581119, isolated VivadoPGID2581162.
All75 measurement snapshot hashes match manifest, only GlobalRender_top differs
from baseline; Tcl/Python/XDC/source list/settings unchanged. Verify runner command
and owned jobPGID before cancellation; SIGTERM runner forwards only to2581162.
Synthesis has passed elaboration into cross-boundary area optimization with no
ERROR/critical warnings seen. Final utilization/timing reports pending.

## Final measured checkpoint 2026-10-10 14:24 UTC

Session40433 completed naturally rc0; immutable-input summary complete/errors[],
timing_clean=false. LUT25055(+938,+3.89%),FF13650(-27),BRAM9.5(-0.5),DSP0.
WNS-5.696(-0.520ns),TNS-8136.568 (improved aggregate),setup4600/34302 endpoints,
WHS0.045 unchanged,hold0. Declared minimum-gain/resource/WNS objective checks fail;
hold passes. UTLZ-1 Error remains, so candidate does not fit and no route launched.
Root immediately informed to reject candidate2; no production source edited.

Exact comparison is golden/out/qor/candidate-reciprocal-synth/comparison.json,
objective SHA256029ec1b25a33a1370691ce867f341cb9e2681ee6483c001837c70cfb75315e45.
Constraints/settings/toolrunner equal baseline; only GlobalRender_top differs.
Parser with --root reciprocal-candidate-source --parse-only --check-working-tree
returns complete/errors[], confirming retained input hashes match scratch source.
Vivado group2581162 has no active processes; Python runner finished. No owned jobs,
no descendants, no commits/pushes. Main docs include this rejected candidate too.

Fresh quota2026-10-10 14:24:45UTC22%five-hour35%weekly, resets unchanged above.
Normal completion checkpoint, not quota shutdown. Root60-second timer continues
while its other assignments run.

Next recreation: retain all failed candidate evidence and original failed route,
use original immutable baseline as resource/timing reference. Do not copy either
rejected helper candidate into production based on arithmetic equivalence alone.
An eventual separately scoped optimization needs a new frozen objective and
verified actual source semantics; current pipeline remains over Basys3 capacity
with undeclared pixel clock/I/O/CDC findings. No additional measurement is active.
