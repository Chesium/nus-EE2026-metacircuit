# M5 QoR shadow write-port resume handoff

Updated: 2026-10-10 19:22 UTC. State: documented and work ended under latched team quota shutdown; M5 readiness unresolved.
Owner `/root/m5_qor`, parent `/root`; no descendants.
Main handoff: [m5-verification.md](../../m5-verification.md).

## Assignment and ownership

Workspace `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branch `verification`,
HEAD `f894fa8dcb487ff02c8f671e4126cc84cf169363`. Preserve all shared dirty M4/M5
files; no commits or pushes. This agent has not changed production RTL.

Own the Vivado runner/Tcl/tests, `docs/m5-vivado.md`, isolated QoR sources and
measurements, `tools/verify_shadow_ports_m5.py`, `tools/verify_shadow_temporal_m5.py`,
`tools/tests/test_verify_shadow_ports_m5.py`, and this handoff. Root owns the
independent A-008 production correction, whole frontend regression and acceptance
policy. Do not conflate the correction with the optimization.

## Proposal and exact proof scope

The original baseline attributes 8,547 LUT to CanvasCommandGuard, but critical
path names reveal top BCD/text/dirty logic migrated there by rebuilt synthesis.
The selected proposal consolidates the three shadow arrays' 20/23/23 mutually
exclusive write sites into one synchronous write port per array. Each write
site sets blocking enable/address/data selectors; enables default to zero each
edge. A final indexed memory update remains nonblocking on that same edge.
All reads, full canvas16 bits, original division helpers, boot writes and data
expressions remain unchanged. Vivado now infers distributed RAM for these arrays.

`verify_shadow_ports_m5.py` requires an exact canonical source rewrite and parses
the entire write-arbitration tree to establish at most one write per array per
edge, accounting for every original write. The source-level induction starts
from arbitrary equal array contents: the same branch evaluates the same address
and data, schedules the same NBA update, and all old-data reads remain unchanged.
The two-state argument retains all 512 address values; no four-state X/Z or
active-region hierarchical observation equivalence is claimed. This is a narrow
structural argument, not a general HDL parser or solver-backed full-design proof.

Only two full-source reference identities are admitted:

- Original: `254c8842d72c6c4801ef015c8c3274687a970c8794f9d09e6d966ced42657a66`.
- Reviewed A-008 correction: `4e62e63dd68ba9e946006a86129d48c39dd7570710a73451f0fd1fba68c2bb16`.

The tool reconstructs exactly the three reviewed A-008 hunks from the original:
one initialized drain register, expanded busy expression, and one always block
holding busy through RAM read refresh. Arbitrary live hashes are rejected.
Eight failure-oriented unit tests pass from the durable frozen contract payload.

`verify_shadow_temporal_m5.py` additionally compiles actual-source projected
control/write chains and compares all 288 array cells after each of 16,384 edges,
including synchronous old-data reads/collisions, all 512 addresses and all 1,024
initialization-counter values. Normal and exact labeled cell287-corruption
negative control both pass their expected verdict. Source readback remains stable;
native Verilator is 5.046. These traces supplement the structural argument and
do not replace root's whole-frontend lockstep/observer regression.

Current A-008 proof evidence:

- `golden/out/qor/a008-shadow-singleport-proof.json`.
- `golden/out/qor/a008-shadow-singleport-temporal-final-v2/report.json`.
- `golden/out/qor/a008-shadow-singleport-temporal-negative-v2/report.json`.

## Completed characterization

All measurements below use the original XDC, runner and Vivado settings. Prior
address and reciprocal candidates remain rejected. No timing exceptions, DRC
waivers, IP upgrades or source-closure changes were used.

| Measurement | LUT | FF | BRAM | DSP | WNS ns | State |
|---|---:|---:|---:|---:|---:|---|
| Original baseline-final-synth | 24117 | 13677 | 10 | 0 | -5.176 | Complete |
| Corrected original shadow candidate | 10505 | 4302 | 10 | 0 | -4.388 | Complete |
| A-008 historical75 baseline | 24500 | 13668 | 10 | 0 | -4.459 | Complete |
| A-008 historical75 shadow candidate | 10492 | 4303 | 10 | 0 | -4.361 | Complete |

The original candidate saves 13,612 LUT (56.44%) and 9,375 FF. The matching A-008
pair saves 14,008 LUT (57.18%) and 9,365 FF, improving WNS by 0.098ns. Both pass
their predeclared provisional objectives: positive LUT gain, resource ceilings
24117/13677/10/0, WNS>=-5.176ns, holdWNS>=0. Both have holdWNS0.045ns. Setup
remains negative and readiness remains false. Comparisons are saved beside their
summaries. Strict parse-only current-scratch hash checks pass. Each pair differs
only in GlobalRender_top, with identical tool/XDC/settings.

The historical A-008 pair is `a008-baseline-synth` / `a008-shadow-singleport-synth`,
with sources `a008-baseline-source` / `a008-shadow-singleport-source`. These contain
the original omitted FMA wrapper and must not masquerade as current production
input snapshots. Source patch is `a008-baseline-source-change.patch`.

Development failures remain preserved:

- `candidate-shadow-singleport-synth`: first generator missed value/unit enable
  defaults. Canonical audit caught this; `rejection.json` explicitly rejects it.
  Its numbers are invalid for acceptance despite complete reports.
- `shadow-singleport-temporal`: first projected test missed the declaration for
  an interaction response read; compile failed. Corrected tests succeeded later.
- `candidate-shadow-singleport-routed`: original-source route request cancelled
  via verified owned runner3291414 to prioritize current A-008 pair under memory
  pressure. PGID3292063 is empty; `superseded.json` and incomplete summary retained.
  No synthesis-complete or route success from that cancelled run is claimed.

## Current final route phase

New roots `a008-current-baseline-source` and `a008-current-shadow-source` preserve
current75-input provenance. BOTH include the root-approved current omitted FMA
wrapper SHA `9c1daa50bb18196ff22615da92bcf8a3b0697647e821db45376d735948f05ec7`.
The FMA wrapper remains outside the audited 41-source frontend closure. The only
live-versus-original input changes were independently confirmed as top and FMA.

Baseline top is the A-008 pin above; candidate top is
`93bc76d3019d3d1e5a8949a00e32d217d934b4ece5289ec26e1421b7a2a001fb`.
Both final measurement roots share all75 input hashes except that candidate top.
Historical roots and snapshots were not changed or relabeled.

Separate acceptance objective was frozen BEFORE final routes:
`golden/out/qor/a008-shadow-acceptance-objective.json`, SHA
`4e6268d4acd5a9a3fa1074dd3c3a5021999bcad2972bb6aeefe14df3adf97ad0`.
It adds explicit `comparison_stage:synth`; previous provisional objectives remain
unchanged. Proposal metadata is `a008-shadow-acceptance-proposal.json`.
Root's gate allows a characterized failing baseline only when this explicit
resource objective and an independently validated exact capacity failure apply.
The same final failed-route baseline directory may be passed as `--baseline-qor`
and `--baseline-route-attempt`, retaining its actual errors/incomplete state.
Candidate must still have complete routed reports and qualified timing/clock/
I/O/CDC/DRC; no automatic waiver follows from area gain.

Owned ACTIVE jobs (inspect commands/ownership before cancellation):

| Output | Session | Python runner PID | Owned Vivado PGID |
|---|---:|---:|---:|
| a008-current-shadow-routed | 81507 | 3326946 | 3327871 |
| a008-current-baseline-routed | 14852 | 3328039 | 3328125 |

All earlier owned synth/temporal jobs finished. Root's candidate capture/observer
jobs are outside this agent's ownership; do not stop them. No descendants exist.

Next concrete step: await these reports, preserve actual baseline placement
capacity failure and actual candidate fitting/routing results, parse retained
snapshots and compare the frozen objective. After root approves/applies the
candidate, verify all current production input hashes match the final measurement.
Root handles whole-frontend regression/integration. Audit routed timing, clock,
I/O, CDC and DRC honestly before claiming M5 readiness.

## Constraint findings and quota

The synthesized shadow candidate still has 793 no-clock pins, 1,222 unconstrained
internal endpoints, ten missing input delays and 44 missing output delays. Only
the10ns primary clock is declared. The pixel divider output is undeclared, so
report_cdc's single-known-clock safe-path statement does not qualify pixel-domain
crossings. No constraints were weakened; board/interface timing requirements
remain open even if physical routing completes.

Initial quota2026-10-10 19:06:27UTC:97%five-hour/32%weekly. Latest fresh quota
19:20:46UTC:40%five-hour/23%weekly. Resets2026-10-11 00:05:41UTC and
2026-10-14 15:27:22UTC. Default thresholds unchanged; root owns60-second team
cadence. No quota shutdown triggered at this checkpoint. Parent has this path and
job/source details; this handoff will be updated at the next safe checkpoint.


## Checkpoint 2026-10-10 19:27 UTC

Final current75 baseline session14852 ended naturally rc1. Synthesis matches
24500LUT/13668FF/10BRAM/0DSP, WNS-4.459ns/TNS-5334.680ns, hold0.045ns.
Actual place_design DRC requires22523LUT-as-logic sites but Basys3 has20800.
Exact three ERROR labels are DRC UTLZ-1, Vivado_Tcl4-23 and Common17-39.
No placer or route ran; requested_stage=routed and evidence_status=incomplete
are retained. Root's validate_capacity_failure using this same directory as
baseline/witness returns an empty error list. This is the explicitly required
characterized failing baseline, not an invented complete route.

Final candidate passed placement and phys_opt_design, and is now in route_design.
Pre-route physopt estimate WNS approximately-1.032ns, which is not final timing.
Only owned active job is candidate session81507, Python3326946/PGID3327871.
Baseline3328039/PGID3328125 ended. Next: preserve final actual routed reports,
review timings/clock/I/O/CDC/DRC and compare frozen acceptance objective.
Quota fresh19:26:37UTC21%five-hour/20%weekly; no shutdown trigger yet.


## Final checkpoint 2026-10-10 19:29 UTC

Final current75 candidate session81507 ended naturally rc0 with complete evidence,
no logged errors, all14,339routable nets fully routed and zero routing errors.
Routed resources:10,089LUT,4,166FF,10BRAM,0DSP. WNS-1.657ns/TNS-354.929ns,
443failing setup endpoints; holdWNS0.044ns with zero hold failures. Its synthesis
metrics match10492LUT/4303FF/WNS-4.361. Baseline synthesis24500LUT/13668FF matches
historical pair; baseline real placement fails22523LUTlogic>20800 as described.
All owned groups3327871/3328125 are verified empty. No jobs or descendants remain.

Finalcomparison `golden/out/qor/a008-current-shadow-routed/comparison.json` records
same-stage synth LUT gain14,008, positive gain/resource limits/routed setup+hold
floors allpass, and no capacity/provenance errors. Root full objective validator
returns false ONLY for unqualified timing/CDC/DRC readiness; numeric objective
passing must never be described as full acceptance. Actual baseline errors and
incomplete requested-route status stay in baseline_characterization. Strict
--parse-only --check-working-tree against the final candidate scratchroot passes.
The pair differs only top across75inputs, including identical approved currentFMA.
Root handles whether to integrate a functionally qualified area improvement;
this agent has made no production RTL edits.

Worst routed path: keyboard_ascii_sys_ff1[1] to netlist_content_dirty,13logic
levels,11.620ns data delay (2.476logic/9.144routing),-1.657ns slack. Routed710
no-clock pins include708at pixeldivider clk_out/Q;1139unconstrained internal
endpoints,10missing input delays and44missing output delays. Only primary10ns
clock is declared. Gated-clock PDRC-153, CFGBVS/config-voltage and RAM async-control
DRC warnings need review. CDC single-known-clock safe-path message is insufficient.
No constraints or waivers changed. Next assignment: preserve these exact failed
baseline and fully routed candidate snapshots; optimize the BCD/text/dirty cone
under a new predeclared objective/proof, define legitimate pixel and external I/O
clock/timing requirements, then run matched measurements and full frontend gate.
Do not silently change XDC or infer board timing margins from missing constraints.

Verification completed:12Vivado runner tests,8shadow proof tests, A-008 structural
canonical proof and native projected temporal normal/labeled corruption controls,
strict final scratch-source snapshot parse, capacity witness and pair validation,
and git diff --check. Root owns actual native/Docker frontend captures/observers;
this role does not certify their results. Latest direct quota19:28:49UTC12%five-hour/
19%weekly; resets unchanged. Parent receives this handoff and all final findings.


## Latched team shutdown acknowledgement

Parent ordered shutdown at2026-10-10 19:29:28UTC after fresh live quota entered
DOCUMENT mode:9%five-hour/18%weekly. Default prepare threshold is strictly below
10%five-hour or6%weekly. This transition is latched; no new implementation or
verification was started afterward. This agent has no descendants and all its
owned runners/groups ended naturally before shutdown; the last explicit ps check
confirmed final groups3327871/3328125 empty. No active owned jobs remain.

Final artifacts, source/objective pins, comparison, real baseline capacity failure,
complete candidate route, proof limits and exact next steps are above. Parent's
instruction prohibits acceptance or reinstatement of the candidate during this
shutdown. Production integration/full acceptance remains root-owned and unresolved;
this agent changed no production RTL. Preserved routed fit evidence does not imply
100MHz timing closure or full M5 readiness. Parent receives this separate document
and the stopped acknowledgement; main coordinator ends last. A future authorized
resume must read this handoff and perform a fresh live quota check before work.
