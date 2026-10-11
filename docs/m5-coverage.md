# M5 line, branch and toggle coverage policy

`tools/verify_coverage_m5.py` validates genuine FS-11 evidence and applies a
project-owned executable coverage policy. Full readiness requires both native
Verilator5.046 and pinned Docker5.020, no eligible uncovered counters and reviewed
module/input requirements. Current requirements are explicitly unreviewed; full
readiness fails. No percentage threshold is reduced to turn uncovered paths into
acceptance. Instrumentation counters are not every HDL source line, and no
uncovered path is presumed safe.

```sh
python3 tools/verify_coverage_m5.py --coverage-report golden/out/m4/coverage-final-native/case-0/rtl/coverage/coverage.json --coverage-report golden/out/m4/coverage-final-docker/case-0/rtl/coverage/coverage.json --source-root golden/verification/contracts/frontend-v1/payloads --audit-only --out golden/out/m5-coverage/NEW-historical-audit
python3 -m unittest discover -s tools/tests -p test_verify_coverage_m5.py -v
```

Remove `--audit-only` for mandatory readiness: evidence corruption, missing
runtimes, unreviewed requirements and coverage gaps return nonzero. Audit mode
checks evidence integrity while retaining `ready:false`; its exit0 is not a
readiness pass. Default source root is the current main checkout, so historical
source evidence cannot qualify a changed current candidate. An explicit historical
or candidate source root is recorded in every input entry.

The accepted framescope raw parser is reused with its source hash pinned in the
policy. Both boot and scenario files must match hashes and recomputed FS-11
summaries; missing unused splits also fail. The enclosing successful simulation
must match provenance and coverage metadata, randomized initialization, seed and
scenario boundary. Every declared source hash is checked against the selected
source root or actual harness/stub path; every instrumented source must map to a
declared source or an explicit harness exclusion. Compatible same-runtime inputs
merge only with identical provenance and instrumentation; native and Docker
remain separate because tool versions emit different counters.

The output reconstructs every module/hierarchy/source/type from raw counters,
with instrumented, eligible, reached, uncovered and excluded totals and complete
uncapped gap/exclusion lists. It records raw/report/run-report, policy and tool
hashes. Required module scopes bind canonical HDL names to production source suffixes,
including Verilator parameter specializations (for example FloodQueueStore__D480).
Raw module/hierarchy names remain in the report. Missing required instrumentation
types fail readiness. Scopes name controller, frame capture, guard, wire draw,
queue, flooding/extraction and UART traffic. Every remaining production module
inherits an unreviewed full-input requirement. Explicit reviewed exclusions cover
only generated framescope wrapper and direct mouse/cursor stubs, with reasons.
Physical PS/2/CDC is not qualified by those models. Disabled production features,
constant bits, rare branches, missing solver/IP instrumentation and capacity
limits are not silently excluded; they remain coverage/review obligations.

Retained original native/Docker evidence is integrity-valid against the frozen
contract payloads, with `ok:true, ready:false`. Native scenario line counts are
eligible10044/reached1413/uncovered8631; toggle45514/11452/34062. Docker line counts
are10044/1347/8697; toggle22756/5816/16940. Complete per-module/branch/exclusion data
is in `golden/out/m5-coverage/retained-original-final-audit/summary.json`; this historical
report does not qualify the readiness fix or storage candidate.

Corruption controls cover raw coverage, reported summary counts, source/tool/
runtime identity, failed/missing parent simulation, absent splits, duplicate
inputs, unexplained exclusions, lowered thresholds and missing seed/boundary.
A short fresh candidate boot/idle run may supply current artifact provenance;
it cannot replace the missing interaction/UART/capacity/stall corpus or formal
reachability review. Full M5 coverage and refactor readiness remain incomplete.

Final controls also establish that the full policy returns exit1 for those valid
original reports, and current-source audit returns exit1 for their stale source
identity. At the earlier quota shutdown, a genuine four-frame candidate native boot/idle
run had finished in `golden/out/m5-coverage/raw-candidate-native-v2`, but had not
yet been audited. Docker failed before simulation with Verilator's locked Thread
Pool internal build error. That shutdown remains preserved in the earlier handoff.
The authorized 2026-10-11 resume audits the saved native artifact against explicit
`golden/out/m5-shadow-functional-source`; integrity passes and readiness fails.
The final reviewed-scope audit is
`golden/out/m5-coverage/candidate-native-reviewed-scope-audit/summary.json`.
Native scenario eligible/reached/uncovered counters are line10046/1376/8670,
branch2108/735/1373 and toggle45640/10662/34978. This evidence is for the frozen
storage candidate, not any subsequently modified current production source.

Every required module now lists named input-domain obligations, source identity,
input-scope review state and separate reachability review state. These are
obligations, not inferred functional hits: raw line/branch/toggle counters do not
prove the named input combinations occurred or passed their functional checks.
All reachability reviews remain incomplete, thresholds stay zero and production
exclusions remain forbidden. Fifteen acceptance/provenance/alias/input-domain
controls pass. Parameterized names require both canonical-name agreement and
the reviewed source suffix; a similarly named module from another source cannot
satisfy the requirement.

Complete source review of InteractionFrameCapture, WireDrawMode and FloodQueueStore
corrected the input-domain descriptions. Frame capture is synchronous and has no
handshake/drop policy: reset dominates, snapshot_valid follows the frame pulse,
and inputs remain latched between pulses. Wire drawing is combinational; occupied
cells and drag sequencing belong to integration. Queue lifetime coverage must
include delayed completions, simultaneous add/pop at full/empty, data truncation,
FIFO order and the integrated non-power-of-two DEPTH1152. Its pointer increment
uses PTR_WIDTH rather than modulo DEPTH, so lifetime beyond1152 operations is an
explicit unqualified risk; boot/idle coverage cannot exclude it. No production
change is made by this coverage audit. Physical PS2/CDC and actual solver/IP
coverage remain separate mandatory M5 scope.

The fresh Docker retry completed unchanged-tool/source compilation and four
seed1 frames with both settled checkpoints passing, in
`golden/out/m5-coverage/raw-candidate-docker-resume-v3/summary.json`. Combined
native5.046 and Docker5.020 evidence audits cleanly against the frozen source in
`golden/out/m5-coverage/candidate-both-reviewed-scope-audit/summary.json`: 
`ok:true, ready:false`. Docker scenario eligible/reached/uncovered counters are
line10046/1310/8736, branch1732/587/1145 and toggle22819/5316/17503. Both reports
retain all101 module/hierarchy rows and complete point lists. Counter totals
remain separate because runtimes instrument different sets.

The full invocation returns exit1 despite integrity passing
(`candidate-both-full-negative/summary.json`), and auditing the saved candidate
report against the changed current checkout returns exit1/okfalse for stale
source (`candidate-stale-current-negative-resume/summary.json`). Neither fresh
report qualifies any later queue/readiness/production fix. Next required work
is source-correct coverage for the broad interaction/UART/stall/capacity corpus,
module reachability decisions and actual solver/IP scopes; the boot/idle retry
only restores provenance and artifact availability.

A subsequent bounded stimulus phase adds a genuine native editing case in
`raw-candidate-editing-native-20261011b`: version2/seed1/one generated operation,
11frames (inspected before simulation, within16frame/1200second limits), capacitor
placement at[4,0]. Both boot and operation_0 frame10 pass the accepted settled
RTL comparator. Functional evidence reaches8/64bins, adding tool:capacitor,
component:capacitor:rotation:0, edge:top and edit:placed:capacitor to the four
boot bins. These witnesses come from passing RTL endpoints, not raw counters.

`candidate-editing-native-merged-audit-20261011b/summary.json` merges the new native
editing artifact with earlier native/Docker idle artifacts against the explicit
frozen candidate source; integrity passes and readiness fails. Native eligible
counts remain branch2108/line10046/toggle45640, with reached823/1759/13510 and
uncovered1285/8287/32130. This adds88branches,383lines and2848toggle counters.
Docker remains idle-only in this partial audit while its bounded editing job runs.
All production gap/reachability/input-domain, UART/stall/capacity/solver/IP and
physical PS2/CDC obligations remain; a single capacitor edit cannot qualify M5.

The matching Docker editing run completed successfully in
`raw-candidate-editing-docker-20261011b` with the same11frames, two passing RTL
checkpoints and capacitor-placement witness. Native/Docker elapsed times were
50.11/279.25seconds, both below1200. Owned runner process groups ended and the
Docker container was removed; no editing jobs remain.

The final four-report merge is
`golden/out/m5-coverage/candidate-editing-merged-audit-20261011b/summary.json`: 
integrity `ok:true`, `ready:false`, no missing runtimes or validation errors.
It merges each runtime's earlier idle and new editing evidence separately.
Instrumented/eligible/excluded sets stay unchanged; all101module/hierarchy rows
and complete gap lists remain. Exact scenario totals and marginal gains over
idle-only coverage are:

| Runtime | Type | Eligible | Reached | Uncovered | Newly reached |
|---|---|---:|---:|---:|---:|
| Native5.046 | Branch | 2108 | 823 | 1285 | 88 |
| Native5.046 | Line | 10046 | 1759 | 8287 | 383 |
| Native5.046 | Toggle | 45640 | 13510 | 32130 | 2848 |
| Docker5.020 | Branch | 1732 | 645 | 1087 | 58 |
| Docker5.020 | Line | 10046 | 1695 | 8351 | 385 |
| Docker5.020 | Toggle | 22819 | 6936 | 15883 | 1620 |

Structured deltas and exact process budgets are retained in
`editing-control-20261011b/final-marginal-gain.json` and job metadata. Full policy
invocation deliberately returns exit1 with integrity passing, in
`candidate-editing-full-negative-20261011b/summary.json`. Both runtime functional
reports reach8of64settled-canvas bins, leaving56uncovered. All module reachability
reviews remain incomplete; arbitrary input combinations, near-capacity/queue
lifetime, stalled traffic, edits during backend/UART phases, malformed/stale/
incomplete reply combinations, actual solver/IP and PS2/CDC remain required.
Counters are instrumentation points, not all HDL source lines. This evidence
qualifies the frozen candidate source93bc76... and the stated single settled edit;
it cannot qualify later production changes or full autonomous refactor readiness.

The next bounded artifact phase adds v2seed12/16operations on the same frozen
candidate. Its golden reference was inspected before launch:182frames,
17checkpoints, below the declared200frame/1200second bounds. The genuine native
run completedexit0 in596.07seconds with17/17RTL checkpoints passing and no
divergence, in `raw-candidate-corpus-native-20261010c`. It reaches28/64settled
functional bins, retaining all previous8 and adding20: current/inductor/voltage
placements, bottom/left edges, blocked placement, component rotation, held input,
partner-half input and additional tool selections. Exact bins and accepted RTL
endpoint witnesses are in `corpus-control-20261010c/native-marginal-gain.json`.
These are finite cold canvas cases, not UART/stall/capacity/solver qualification.

The intermediate five-report source-correct merge,
`candidate-corpus-native-merged-audit-20261010c/summary.json`, adds the new native
report to the four prior idle/editing reports. Integrity passes (`ok:true`) and
readiness remainsfalse, with no validation errors or missing runtimes. It retains
all101module/hierarchy rows and complete gap lists per runtime. Native scenario
eligible/reached/uncovered counts are branch2108/900/1208,
line10046/2240/7806 and toggle45640/17133/28507, adding77branches,481lines and
3623toggle counters over the earlier editing merge. Eligible/excluded sets and
policy thresholds remain unchanged. Docker in this intermediate merge retains
its earlier editing evidence and8/64functional bins; it is not a fresh broad
Docker qualification.

The initial matching182frame Docker attempt was deliberately stopped after
238.6seconds when actual frame times made the1200second budget implausible.
Only its owned process group and independently mount-matched container were
stopped; partial logs/dumps are retained and excluded from coverage acceptance.
A separate seed12directed voltage placement at[0,4], with hold reduced9to1,
has a prelaunch-verified11frame reference and its own fresh output/budget. Its
fresh Docker result is still pending at this checkpoint. Control job, cleanup,
container ownership and pending audit commands are retained in
`golden/out/m5-coverage/corpus-control-20261010c`. All implementation/coverage
policy/frontend benches remained frozen during this artifact phase.

The directed Docker fallback subsequently completedexit0 in420.30seconds,
11coldseed12frames with both actual RTL checkpoints passing and no divergence,
in `raw-candidate-voltage-docker-20261010c`. Its voltage placement at[0,4] supplies
four new passing functional witnesses: `component:voltage:rotation:0`, `edge:left`,
`edit:placed:voltage` and `tool:voltage`. The compatible per-runtime functional
unions now reach28/64native and12/64Docker bins, versus8/64each before this phase.
The inputs deliberately differ: native has the182frame16operation corpus, Docker
has the11frame directed case. No broad182frame Docker pass is claimed.

The completed six-report integrity audit supersedes the intermediate merge:
`golden/out/m5-coverage/candidate-corpus-merged-audit-20261010c/summary.json`.
It returns `ok:true, ready:false`, with no validation errors or missing runtimes.
All101module/hierarchy rows and complete point/gap lists remain per runtime.
Scenario totals and marginal gains over the earlier editing merge are:

| Runtime | Type | Eligible | Reached | Uncovered | Newly reached |
|---|---|---:|---:|---:|---:|
| Native5.046 | Branch | 2108 | 900 | 1208 | 77 |
| Native5.046 | Line | 10046 | 2240 | 7806 | 481 |
| Native5.046 | Toggle | 45640 | 17133 | 28507 | 3623 |
| Docker5.020 | Branch | 1732 | 650 | 1082 | 5 |
| Docker5.020 | Line | 10046 | 1765 | 8281 | 70 |
| Docker5.020 | Toggle | 22819 | 7157 | 15662 | 221 |

`corpus-control-20261010c/final-raw-marginal-gain.json` records these counters;
`final-functional-marginal-gain.json` retains each runtime's compatible functional
union and exact witnesses using the unchanged copied M4 helper. The stopped
Docker182frame partial is excluded from both unions/audits. All owned runner
groups were independently verified absent, and both owned Docker containers
were verified removed. Tool, policy and completed domain-suite pins remain
unchanged. Reachability/input-domain reviews, solver/IP, physical PS2/CDC,
arbitrary input/stall/overlap combinations and full M5 readiness remain incomplete.

The 20261011d directed orientation phase uses the unchanged reviewed shadow
source `golden/out/m5-shadow-functional-source` (top93bc76...), copied M4 helper,
and frozen coverage policy/tool. Its reference was inspected before RTL launch:
174frames/22checkpoints, within180frames/1800seconds. The genuine native run
completedexit0 in716.12seconds with22/22accepted settled RTL checkpoints passing,
no divergence, in `raw-candidate-directed-native-20261011d`.

The case reaches39/64functional bins. Combined with the earlier compatible
native corpus it reaches48/64, adding20 actual witnesses: every remaining
component-kind orientation, emptycanvas/store, deletedcells/components,
resistorplacement, actualRTLslotreuse and resistor tool selection. All20
kind/orientation combinations now have accepted native endpoints. Exact newly
reached bins and witness frames are retained in
`expand-control-20261011d/native-orientations-marginal.json`. This qualifies
finite cold settled canvas behavior on the recorded isolated source. A separate
24frame directed Docker deletion/reuse/right-edge/boundary case and130frame
native property/unit case remain pending at this checkpoint; neither has a
completed comparison or accepted final coverage union yet. Final source-correct
raw coverage merge is pending; M5 readiness, continuous/arbitrary-input scope,
solver/IP, physicalPS2/CDC and reachability reviews remain incomplete.

The directed Docker case subsequently completedexit0 in747.21seconds with all
24coldframes/four accepted RTL checkpoints passing and no divergence, in
`raw-candidate-directed-docker-20261011d`. Its13casebins merge with the earlier
compatible12bins to reach20/64 (+8): rightedge, blocked/boundaryplacement,
deletedcomponent, resistorplacement, partner-half input and delete/resistor
selections. Exact accepted witnesses are in
`expand-control-20261011d/docker-directed-marginal.json`. Planned slot reuse did
not produce an accepted Docker witness and is not counted. The independently
mount-matched owned container was removed after completion. Native property/unit
coverage and the complete raw merge remain pending at this checkpoint.

The native property case completedexit0 in682.12seconds with130coldframes and
21/21accepted RTL checkpoints passing, in
`raw-candidate-properties-native-20261011d`. The reference was inspected before
launch (130frames/21checks, within160frames/1800seconds). It supplies genuine
witnesses for all six nonzero unit codes and propertyvalue/unit changes from a
partner-half input. This proves settled property RAM changes; panel selection,
text/caret/pixels and transient behavior remain separate scope.

The nine-report source-correct audit is
`golden/out/m5-coverage/candidate-directed-merged-audit-20261011d/summary.json`:
`ok:true, ready:false`, no validation errors or missing runtimes, with all101
module/hierarchy rows and complete uncapped point/gap lists per runtime.
Recomputed functional unions reach57/64native (+29over28) and20/64Docker
(+8over12), preserving the unchanged64bin definitions and eligible partitions.
Exact witnesses and marginal raw counts are in
`expand-control-20261011d/final-functional-marginal-gain.json` and
`final-raw-marginal-gain.json`. Runtime counters remain separate:

| Runtime | Type | Eligible | Reached | Uncovered | Newly reached |
|---|---|---:|---:|---:|---:|
| Native5.046 | Branch | 2108 | 973 | 1135 | 73 |
| Native5.046 | Line | 10046 | 2471 | 7575 | 231 |
| Native5.046 | Toggle | 45640 | 19349 | 26291 | 2216 |
| Docker5.020 | Branch | 1732 | 671 | 1061 | 21 |
| Docker5.020 | Line | 10046 | 1844 | 8202 | 79 |
| Docker5.020 | Toggle | 22819 | 7862 | 14957 | 705 |

Instrumented/eligible/excluded sets, policy thresholds, tool/helper/source pins
and incomplete reachability reviews remain unchanged. Fullpolicy evaluation of
these nine valid reports returns exit1 with integrity passing, in
`candidate-directed-full-negative-20261011d`. Auditing the same nine reports
against current production returns exit1/okfalse for source mismatch, in
`candidate-directed-stale-current-negative-20261011d`. This prevents the
isolated-source coverage from qualifying later production changes.

All three completed simulation groups and the owned Docker container were
independently verified absent. A final short native case covering ground/right
edge, ground rotation and boundary rejection has a prelaunch-verified27frame/
four-check reference and900second budget; its verdict and separate ten-report
merge remain pending at this checkpoint. Finite settled coverage still leaves
continuous behavior, arbitrary combinations, solver/IP/UART/stalls, physical
PS2/CDC and reviewed source/input reachability required for M5.

The final native edge case completedexit0 in100.01seconds with27coldframes and
four/four accepted RTL checkpoints passing, in
`raw-candidate-edges-native-20261011d`. Its prelaunch reference was inspected
within the27frame/900second bounds. Passing endpoints add `edge:right`,
`edit:boundary_blocked`, `edit:rotated_cell` and `tool:ground` to the native
union. Recomputed unchanged-helper functional coverage now reaches61/64native
(+33over the earlier28) and20/64Docker (+8over12). Native remaining bins are
`canvas:dense`, `canvas:full` and `edit:capacity_blocked`; Docker retains44
uncovered functional bins. All eligible partitions/definitions remain intact.

The final ten-report audit supersedes the nine-report merge for this phase:
`golden/out/m5-coverage/candidate-directed-final-merged-audit-20261011d/summary.json`.
It reports `ok:true, ready:false`, no validation errors or missing runtimes,
all101module/hierarchy rows and complete uncapped point/gap lists per runtime.
Exact witnesses and source-correct marginal gains remain in
`expand-control-20261011d/final-functional-with-edges-marginal-gain.json` and
`final-raw-with-edges-marginal-gain.json`:

| Runtime | Type | Eligible | Reached | Uncovered | Newly reached |
|---|---|---:|---:|---:|---:|
| Native5.046 | Branch | 2108 | 978 | 1130 | 78 |
| Native5.046 | Line | 10046 | 2489 | 7557 | 249 |
| Native5.046 | Toggle | 45640 | 19501 | 26139 | 2368 |
| Docker5.020 | Branch | 1732 | 671 | 1061 | 21 |
| Docker5.020 | Line | 10046 | 1844 | 8202 | 79 |
| Docker5.020 | Toggle | 22819 | 7862 | 14957 | 705 |

The full ten-report policy returns exit1 with integrity passing in
`candidate-directed-final-full-negative-20261011d`; current-production source
audit returns exit1/okfalse in
`candidate-directed-final-stale-current-negative-20261011d`. Thresholds,
exclusions, source/tool/helper pins and incomplete reachability reviews remain
unchanged. All four owned simulation groups and the Docker container were
independently verified absent in `final-with-edges-closure.json`. No partial or
failed runs enter either union. This completed finite canvas/property artifact
phase qualifies the recorded isolated source; current production and full M5
readiness still require their own source-correct evidence and outstanding scope.

A separate current-production provenance phase uses the adopted composition
(top93bc76..., queue6e80cf..., panel45ca244..., SolverBoard guard77a637...).
It directly executes the unchanged main-checkout M4 helper with fresh seed12
current-component placement at[0,4]. Reference frames/checkpoints were inspected
before both launches:11frames/two checks, within14frames/900seconds per runtime.
New current-source reports do not import old-shadow raw reports or their
61/64native and20/64Docker functional unions.

The current native run completesexit0 in97.01seconds with both accepted settled
RTL checkpoints passing, no divergence, in
`raw-current-composition-native-20261011d`. It reaches8/64functional bins on
this current composition: the four boot bins plus current tool/orientation0,
left edge and current placement. Native-only integrity audit against the explicit
current main source passes with `ok:true, ready:false`, no validation errors and
Docker explicitly missing, in `current-composition-native-partial-audit-20261011d`.
Native scenario eligible/reached/uncovered counts are branch2112/825/1287,
line10046/1777/8269 and toggle45640/13237/32403. Current Docker comparison and the
fresh two-runtime scenario/boot audits remain pending at this checkpoint.

Current-production Docker coverage subsequently completesexit0 in352.76seconds
with11coldframes/two accepted RTL checkpoints passing and no divergence, in
`raw-current-composition-docker-20261011d`. Both fresh current-source runs fit the
900second budgets and each independently reaches8/64functional bins. Their
recomputed witnesses are retained in
`current-control-20261011d/functional-coverage.json`;56bins/runtime remain
uncovered. No old-source raw report or functional union enters these results.

The fresh two-report audit uses the explicit main checkout as source root.
`golden/out/m5-coverage/current-composition-scenario-audit-20261011d/summary.json`
and `current-composition-boot-audit-20261011d/summary.json` each return
`ok:true, ready:false`, no validation errors or missing runtimes, with101
module/hierarchy rows and complete uncapped point/gap lists per runtime. The
boot baseline and scenario split remain separate; native and Docker retain their
own instrumentation sets. Current scenario totals are:

| Runtime | Type | Eligible | Reached | Uncovered |
|---|---|---:|---:|---:|
| Native5.046 | Branch | 2112 | 825 | 1287 |
| Native5.046 | Line | 10046 | 1777 | 8269 |
| Native5.046 | Toggle | 45640 | 13237 | 32403 |
| Docker5.020 | Branch | 1732 | 645 | 1087 |
| Docker5.020 | Line | 10046 | 1713 | 8333 |
| Docker5.020 | Toggle | 22819 | 6808 | 16011 |

The full current-source policy correctly returns exit1 with integrity passing
and readiness false, in `current-composition-full-negative-20261011d`. Auditing
these current reports against the oldshadow source correctly returns
exit1/okfalse, in `current-composition-stale-old-shadow-negative-20261011d`.
Exact commands, original compile/run provenance, raw boot/scenario identities,
source pins and negative verdicts remain in `current-control-20261011d`.
All current src/tool/helper/policy hashes read back unchanged. Both owned groups
and the independently mount-matched Docker container are verified absent in
`final-closure.json`. This restores honest current-composition provenance for
one cold edit per runtime; M5 still requires broader current-source functional
coverage, complete eligible counters, source/input reachability review and the
outstanding continuous/solver/IP/UART/stall/physicalPS2/CDC scope.
