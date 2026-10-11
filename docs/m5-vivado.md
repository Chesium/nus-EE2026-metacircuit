# M5 Vivado characterization

The repository runner targets `GlobalRender_top` on Basys 3
`xc7a35tcpg236-1`. It audits the complete original `metacircuit.tcl` source list and measures its
41-source conservative `GlobalRender_top` closure, including real VHDL `MouseCtl`,
`Ps2Interface` and `MouseDisplay`. All generate branches are conservatively
included. The three floating-point XCI and their fpo wrappers are unreachable
from this frontend top and omitted, with their original hashes and the dependency
graph retained in `manifest.json`. Any source closure change fails before launch.
Vivado synthesis must also report zero unresolved black boxes. Simulation mouse and floating-point stand-ins
are absent. Only the enabled frontend constraint file `src/constraint/basys3.xdc`
is read. No constraints, source RTL, tracked IP configuration or existing project
manifest are modified, and no IP upgrade is automatic.

```sh
python3 tools/vivado_qor.py --out golden/out/qor/frontend-baseline-resume --stage routed
python3 tools/vivado_qor.py --out golden/out/qor/frontend-baseline-resume --parse-only
python3 -m unittest discover -s tools/tests -v
```

Use `--stage synth` for development feedback. Every measurement invocation requires an empty
output directory; existing results cannot silently qualify a new run. `--root`
and `--vivado` permit another checkout/tool installation. The default executable
is `/opt/amd/2025.2/Vivado/bin/vivado`. The Python entry point prepares
`manifest.tcl`; the Tcl file is run with repository root and run directory as
its two arguments.

`manifest.json` records each original source, XCI, memory initialization and constraint
SHA-256, the manifest/runner hashes, top, part, strategy and time. `settings.txt`
records the complete Vivado version/build and actual commands: synthesis defaults
with rebuilt hierarchy, then default optimization, placement, physical
optimization and routing; four threads, no exposed/set implementation seed.
Every measured input is copied into `inputs/`, and Vivado executes that preserved
source/tool/constraint snapshot. This permits comparing a historical baseline
with a changed candidate. Default `--parse-only` verifies the saved snapshot;
`--check-working-tree` additionally requires the current checkout hashes to
match. Python `summarize(out, root=current_root)` provides the strict checkout
check; `summarize(out)` verifies retained inputs. `run.json` records the exact
command, exit code and times. `job.json` for new runs
records the isolated owned process group for safe cancellation. Sending SIGTERM
to the Python runner forwards termination to that process group and preserves
partial evidence afterward; other user processes are outside that group.

Synthesis and route snapshots preserve DCPs, total and hierarchical utilization,
setup/hold timing, unconstrained path/timing checks, detailed critical paths,
clock reports/periods, CDC and DRC reports. Route status, IP status, Vivado log,
journal and console output are retained. `artifacts.json` hashes preserved files
and `summary.json` is machine readable. The parser measures LUT/FF/BRAM/DSP,
WNS/TNS, setup and hold endpoint counts, critical-path logic levels and
logic/routing delay, required no-clock/unconstrained/missing-I/O-delay categories
and clock periods. Hierarchical resources are parsed by instance/module, with explicit inclusive
and direct scopes to avoid double counting. DRC rule/severity/count categories
are parsed; CDC and DRC findings still require review; no automated waiver is
inferred from them.

The parser rejects any logged `ERROR`, even when Vivado exits zero, and exits
nonzero for incomplete, stale, corrupted or unsuccessful
requested measurements. A complete characterization may report setup failure or
unconstrained paths; it is not optimization acceptance. `timing_clean` remains
false because this initial tool does not implement justified CDC/DRC waiver
policy. A future acceptance gate must compare the frozen baseline and candidate
against an explicit improvement objective and allowed tradeoffs. Missing report
categories cannot be converted into zero counts.

Twelve runner unit tests cover frontend source reachability and drift, logged errors, negative setup slack and hold timing, fractional BRAM,
truncated timing/utilization, missing timing-check categories, absent evidence,
changed constraint hashes, removed DCPs, changed numeric report content and
refusal to reuse an old output directory. They pass.

The first actual development attempt is in `golden/out/qor/m5-baseline`. Vivado
2025.2 SW Build 6299465 read the real sources and entered top synthesis. Synthesis licensing succeeded,
but all original 2018.2 XCI are locked against the 2025.2 IP catalog; IP generation
logged no-HDL-source errors, uncustomized-BOM warnings and an unsupported
project-mode `synth_ip` warning. The resumed runner implements fail-fast locked-IP handling and uses project-mode
`create_ip_run`, `launch_runs` and `wait_on_run` for any reachable IP; the present
frontend has none. See the official
[create_ip_run command](https://docs.amd.com/r/en-US/Vivado-Design-Suite-Tcl-Command-Reference-Guide-UG835/create_ip_run).
The parser now rejects logged errors independent of process exit status. The Python runner was
extended while that first attempt was running, so its saved runner hash is stale
and the attempt cannot qualify acceptance. The current job state and eventual
reports/failures are tracked in
[`handoffs/m5/agents/vivado.md`](handoffs/m5/agents/vivado.md).
The attempt was interrupted at the quota shutdown threshold after writing began
on `synth.dcp`, with no finalized report/complete marker and no route. Its summary
is `incomplete`. A frozen invocation in a fresh directory is still necessary after
resolving the explicit top-reachable IP manifest and runner errors.

`SolverBoard_top` is explicitly excluded. Its standalone manifest, top-specific
constraints and configured floating-point primitive behavior/latency must be
qualified separately under M5-5. Frontend implementation does not certify the
solver datapath or complete M5-6/M5-8 readiness.

The resumed real run is `golden/out/qor/frontend-baseline-resume`; its latest
state is recorded in [vivado-resume.md](handoffs/m5/agents/vivado-resume.md).
No synthesis/routing success is claimed until complete reports have been parsed.

Actual resumed routed attempt: synthesis finished with zero errors and zero
critical warnings. Final synthesis use is 24,117 LUT (115.95% of 20,800),
13,677 FF, 10 BRAM tiles and zero DSP. After optimization, placement DRC still
requires 22,138 LUT; `place_design` stopped on UTLZ-1. No route exists. This
attempt remains `requested_stage=routed` and `evidence_status=incomplete`; no
constraint or DRC severity was changed. It predates the immutable-input/parser
extension and is preserved as failed development evidence.

Synthesis WNS is -5.176 ns and TNS -9,647.644 ns with 4,568 failing setup
endpoints; hold WNS is 0.045 ns with zero failing hold endpoints. Checks report
792 no-clock pins, 1,215 unconstrained internal endpoints, ten missing input
delays and 44 missing output delays. The pixel divider is not declared as a
generated clock. `report_cdc` says all paths are safely timed with only the
primary clock known; that does not qualify the undeclared pixel domain.
The primary-clock critical path has sixteen logic levels, 15.025 ns data delay
(3.046 ns logic, 11.979 ns estimated routing), from the keyboard synchronizer
through command-guard BCD logic to `netlist_content_dirty_reg`.

The largest synthesized hierarchy scopes are CanvasCommandGuard (8,547 LUT),
VGAControl (4,295), direct top logic (4,272) and extract_component_nodes
(2,710). Rebuilt hierarchy can migrate logic across module boundaries; these
numbers identify inspection scopes, not a source-level attribution proof.
The fresh immutable-input synthesis baseline in
`golden/out/qor/baseline-final-synth` completed with exit0,
`evidence_status=complete`, `timing_clean=false` and the same resource/timing
results. Completeness certifies preserved synthesis measurement, not device fit
or timing acceptance. It remains separate from the failed routed run.

Root has frozen a provisional area objective before measuring its bounded
address-arithmetic candidate: LUT gain at least1, no increase in FF/BRAM/DSP,
WNS at least-5.176ns and hold WNS at least0. Candidate synthesis completed in
`golden/out/qor/candidate-address-synth`, with the same runner/XDC/settings and
only `GlobalRender_top.v` changed in its preserved input hashes. This objective
can establish synthesis gain while overall readiness remains false.

The measured candidate fails the frozen provisional objective: 24,471 LUT
(+354), 13,668 FF (-9), ten BRAM tiles and zero DSP. Setup WNS worsens to
-6.262 ns (-1.086 ns) and TNS to -10,316.741 ns; hold WNS remains0.045ns.
Both synth measurements have complete preserved evidence. Their comparison is
`golden/out/qor/candidate-address-synth/comparison.json`; it records the original
objective/hash, source differences and exact failed checks. The candidate still
exceeds device capacity, so the conditional candidate route was not launched.
The original actual placement failure remains required evidence. The measured
candidate must be rejected despite any independent functional equivalence.
No successful optimization or routed readiness is claimed.

A second bounded candidate was measured from an isolated baseline source copy in
`golden/out/qor/reciprocal-candidate-source`; production RTL was untouched by the
measurement agent. Its narrow reciprocal multiply decoder also fails the same
predeclared objective: 25,055 LUT (+938), 13,650 FF (-27), 9.5 BRAM tiles (-0.5)
and zero DSP. WNS is -5.696ns (-0.520ns); TNS improves to -8,136.568ns, but the
objective uses WNS. Hold WNS remains0.045ns. Complete synth snapshots/reports and
comparison are in `golden/out/qor/candidate-reciprocal-synth`; current scratchroot
hash validation passes. It remains over device capacity and is rejected. These
two experiments do not establish an accepted optimization.

A third isolated proposal consolidates the shadow arrays' mutually exclusive
write sites into one synchronous write port per array. It retains canvas data
width16, every memory read and the original address helpers. Blocking selectors
are reset each edge; the selected indexed memory write remains nonblocking on
that same edge. `tools/verify_shadow_ports_m5.py` pins the original source,
requires the exact canonical transformation, inventories20/23/23 write sites
and verifies the arbitration tree permits at most one write per array per edge.
Its structural induction assumes arbitrary equal prior array contents and
unchanged pure address/data expressions. It is a narrowly scoped source argument,
not a general parser or solver-backed whole-design proof. Eight mutation/control
tests pass. `tools/verify_shadow_temporal_m5.py` additionally compiles actual-source
projected control/write chains:16,384edges, all288cells checked each edge,
all512address values, all1024initialization-counter values and synchronous
old-data read collisions. Normal run passes; corruption at cell287 fails with
the required `SHADOW_TEMPORAL_FAILURE array step=1024 cell=287` label.
Reports are under `golden/out/qor/shadow-singleport-temporal-{final,negative}`.

The objective in `golden/out/qor/shadow-singleport-objective.json` was frozen
before measurement: LUT gain>=1, no resource increases, WNS>=-5.176ns,
holdWNS>=0. Corrected measurement
`golden/out/qor/candidate-shadow-singleport-corrected-synth` is complete and
passes that provisional objective:10,505LUT(-13,612;56.44% reduction),
4,302FF(-9,375),10BRAM and0DSP; WNS-4.388ns(+0.788),TNS-816.635ns,
606failing setup endpoints,holdWNS0.045ns. All snapshot hashes match the isolated
source; only `GlobalRender_top.v` differs from `baseline-final-synth`, with equal
tool runner, XDC and settings. Vivado reports distributed RAM inference for all
three shadow arrays. The complete comparison is saved beside the summary.
The first `candidate-shadow-singleport-synth` snapshot had missing value/unit
selector defaults, detected by the canonical checker, and remains explicitly
rejected in its `rejection.json`. Its numbers cannot qualify improvement.

The original-source route attempt at `golden/out/qor/candidate-shadow-singleport-routed`
was cancelled via its owned runner to prioritize the approved A-008 matched pair
under memory pressure. Its retained manifest/log/summary record incomplete evidence;
no routing success is claimed.
This is characterization against the original immutable baseline; the independent
A-008 frontend ready-boundary correction needs a new matched baseline/candidate
comparison and complete frontend regression before production acceptance.
Production RTL has not been modified by this measurement/proof role.
Synthesis still reports793no-clock pins,1,222unconstrained internal endpoints,
tenmissing input delays and44missing output delays. The only declared clock
is the10ns primary clock; the divider output is undeclared. With just one known
clock, the CDC report's safe-path statement does not qualify crossings into the
pixel domain. No false paths, generated-clock changes, I/O delays, DRC waivers
or other constraint changes were used to achieve this gain. Constraint and
board-level timing requirements remain open even if routing completes.


The reviewed A-008 baseline is separately pinned to full source SHA256
`4e62e63dd68ba9e946006a86129d48c39dd7570710a73451f0fd1fba68c2bb16`.
The proof tool reconstructs exactly its three write-drain correction hunks from
the frozen original and admits that one identity in addition to the original.
The write-port candidate based on it has SHA256
`93bc76d3019d3d1e5a8949a00e32d217d934b4ece5289ec26e1421b7a2a001fb`.
Its structural proof passes; current actual-source temporal normal/negative
reports are in `golden/out/qor/a008-shadow-singleport-temporal-{final,negative}-v2`,
with runtime version and source-stability checks. Matched historical75-input synthesis measurements
completed at `a008-baseline-synth` and `a008-shadow-singleport-synth`, using
fresh isolated original-input copies plus the approved top source only. Objective
`a008-shadow-singleport-objective.json` was frozen before both launches, retaining
the original conservative resource and timing limits.


The A-008 baseline measures24,500LUT,13,668FF,10BRAM,0DSP and WNS-4.459ns;
its matched shadow-write candidate measures10,492LUT,4,303FF,10BRAM,0DSP
and WNS-4.361ns. The14,008LUT reduction(57.18%) and9,365FF reduction pass
the provisional objective; WNS improves0.098ns against this corrected baseline.
Both are complete, snapshot-verified synthesis reports. The independent A-008
correction therefore changes synthesis results and must not be conflated with
comparison against the original baseline. Their comparison.json records that
these historical75-input roots still contain the original omitted FMA wrapper.

Final measurements use exact current75-input provenance, with the approved
`fpo_fma.v` SHA256`9c1daa50bb18196ff22615da92bcf8a3b0697647e821db45376d735948f05ec7`
copied into BOTH `a008-current-baseline-source` and `a008-current-shadow-source`.
The FMA wrapper remains outside the audited41-source frontend closure. Fresh
routed requests are running at `a008-current-baseline-routed` and
`a008-current-shadow-routed`; no previous snapshot was relabeled. Before their
launch, a separate acceptance objective was frozen at
`golden/out/qor/a008-shadow-acceptance-objective.json`, SHA256
`4e6268d4acd5a9a3fa1074dd3c3a5021999bcad2972bb6aeefe14df3adf97ad0`.
It explicitly selects synth-to-synth LUT gain (`comparison_stage:synth`),
conditional on a provenance-matched actual baseline capacity failure and
complete routed candidate evidence. Physical resource ceilings, setup/hold
floors and independently qualified clock/I/O/CDC/DRC readiness still apply.
The historical provisional objectives are preserved unchanged.


The final current75 baseline route attempt ended naturally with the expected
UTLZ-1 capacity failure: after opt_design it requires22,523LUT-as-logic sites
against20,800 available. Vivado retained exactly the three place_design failure
errors, completed synth reports and an incomplete requested-route summary.
Its synth metrics match the historical A-008 baseline24,500LUT/13,668FF and
WNS-4.459ns. The capacity-witness validator returns no errors against this retained
snapshot; no baseline route success is claimed. The final candidate has passed
placement and physical optimization and entered route_design. Its pre-route
slack estimate remains negative; final timing and qualification are pending.


Final current75 candidate routed measurement completed naturally with exit0,
complete preserved reports and no logged errors. All14,339routable nets are fully
routed with zero routing errors. Routed resources are10,089LUT,4,166FF,10BRAM
and0DSP. Final setup WNS is-1.657ns,TNS-354.929ns with443failing setup endpoints;
holdWNS0.044ns with zero hold failures. The same-stage synthesis gain remains
14,008LUT against the validated capacity-failing A-008 baseline. All explicit
numeric objective checks and provenance/capacity checks pass, while full
acceptance remains false because timing/CDC/DRC readiness is unqualified.
`golden/out/qor/a008-current-shadow-routed/comparison.json` retains the baseline's
actual incomplete requested-route status/errors, full routed candidate metrics,
objective identity and exact failed acceptance reason. Strict current-scratch
input validation passes; only the top differs across the final75-input pair.

The routed worst path remains keyboard ASCII through BCD/text/dirty logic to
`netlist_content_dirty_reg`:13logic levels and11.620ns data delay, comprising
2.476ns logic and9.144ns routing. Routed constraint checks report710no-clock
pins,1,139unconstrained endpoints, tenmissing input delays and44missing output
delays;708no-clock pins are rooted at `clkdiv_pixel_inst/clk_out_reg/Q`.
Only the10ns primary clock is known. DRC retains the gated-clock PDRC-153 warning,
CFGBVS/configuration-voltage warning and RAM async-control warnings requiring
review. No exceptions or waivers were added. Follow-up work must address the
BCD/text timing cone and explicit pixel/interface clock/timing requirements,
then rerun a properly matched characterization. Physical fit is established;
100MHz timing closure and full M5 readiness are not.

## Resumed pixel-clock and external-interface audit (2026-10-11)

A separate retained-checkpoint diagnostic is preserved at
`golden/out/qor/pixel-clock-diagnostic-20261011/report.json`. Its Tcl opens the
original candidate routed DCP and adds exactly one generated clock, without
rewriting the DCP, production XDC, original reports or exceptions. The divider
RTL sets `FREQ=25_000_000`, giving `CounterMax=1`; initialized `count=0` and
`clk_out=0` make the first output rising transition occur at the second system
rising edge. Thus `-edges {3 7 11}` on `clkdiv_pixel_inst/clk_out_reg/Q`, referenced
to `CLK100MHZ`, gives a40ns period and `{10 30}` waveform. This derivation requires
the pinned initialized divider and the current implementation; it is not a
blanket constraint for another divider or reset behavior.

| Check | Original candidate route | Derived-clock diagnostic |
|---|---:|---:|
| no_clock entries |710|2|
| unconstrained internal endpoints |1139|1|
| missing input delays |10|10|
| missing output delays |44|44|
| hold WNS ns |0.044|-2.486|
| failing hold endpoints |0|115|

The newly timed pixel domain has five hold failures, worst-0.031ns. The110
system-to-pixel paths have worst hold slack-2.486ns and total hold violation
-207.922ns. Pixel-to-system paths have positive setup/hold slack in this
checkpoint. These are diagnostic results against the existing route, not a
fresh implementation constrained by both clocks. A correctly constrained rerun
must repair hold rather than add clock-group or false-path exceptions between
these related clocks. `report_cdc` still prints “All paths are Safely Timed”;
that related-clock classification does not override negative hold slack or
certify transfer protocols. AMD describes CDC analysis as structural and
separate from timing slack in [UG906](https://docs.amd.com/r/2021.1-English/ug906-vivado-design-analysis/Report-Clock-Domain-Crossings).

The remaining unclocked entry is the inferred latch
`gen_prop_panel.u_prop_panel/coord_len_reg[3]/G`, driven from selection signals.
`ComponentPropertyPanel.v` assigns `coord_len` only inside `!show_hint_layout`
and provides no default in that combinational block. The latch D is the single
remaining unconstrained endpoint. This needs an independently verified RTL
correction; inventing a clock for its gate would hide the missing assignment.

The [Digilent Basys3 rev.C manual](https://digilent.com/reference/_media/basys3:basys3_rm.pdf)
identifies a100MHz oscillator atW5 (§4), the FT2232HQ two-wire UART (§5), a PIC24
emulating a PS/2 peripheral (§6), analog VGA RGB via resistor networks and two
sync signals (§7), and mechanical buttons/switches (§8). Its PS/2 example gives
5µs minimum setup/hold relative to the PS/2 clock. It provides VGA raster examples
but does not define an attached monitor's FPGA-pad setup/hold or cable/skew
budget. The repository XDC describes rev.B; hardware revision compatibility
must be confirmed before adopting rev.C details as a deployment contract.

The10 reported asynchronous inputs are `BTNC/BTND/BTNL/BTNR/BTNU`, `PS2CLK`,
`PS2DATA`, `RsRx`, `SW[15]` and `SW[5]`. A fixed input delay relative to the100MHz
clock cannot establish a phase relationship for these sources. AMD's
[UG903 asynchronous-signal guidance](https://docs.amd.com/r/en-US/ug903-vivado-using-constraints/Constraining-Asynchronous-Signals)
requires a synchronizer and a defined timing treatment for the actual interface;
[UG903 input delay](https://docs.amd.com/r/en-US/ug903-vivado-using-constraints/Input-Delay)
models external clock/data phase, which must come from interface evidence.
The audit currently finds:

- `UartRx.v` directly consumes `rx` in start detection, start validation, data
  sampling and stop validation. The top directly connects `RsRx`; no ingress
  two-register synchronizer is present. The nominal115200baud functional loop
  tests digital framing; it cannot test metastability or qualify pad sampling.
- Buttons directly feed edge detection and reset logic; `SW[5]` directly enables
  client mode and `SW[15]` directly resets pixel logic. Destination-domain
  synchronization/reset-release and button debouncing require explicit design
  and verification. Synchronous reset syntax alone does not synchronize a pad.
- `Ps2Interface.vhd` debounces both pads before adding a final registered sample,
  but the raw pad also participates in first-stage counter-control comparisons.
  The debounce comments do not establish a clean synchronizer topology. Audit
  first-stage fanout, recognized `ASYNC_REG` placement and filtered-clock/data
  coherency before qualifying this interface. PS/2 setup/hold applies relative
  to its own serial clock and does not imply phase alignment with `CLK100MHZ`.

VGA outputs require a declared raster mode, RGB/sync alignment and a monitor/
cable/board timing budget. UART output requires framing/baud error tolerance
and a receiving-device contract. LED/seven-segment/constant-disabledJC outputs
need explicit human-visible/static interface classifications rather than a
blanket synchronous output-delay claim. The [UG903 output-delay definition](https://docs.amd.com/r/en-US/ug903-vivado-using-constraints/Output-Delay)
requires the external receiver context. No delays, false paths or readiness
waivers have been assigned from the board descriptions. Timing/CDC/I/O readiness
remains false.

## Isolated BCD rank proposal and proof

The new `tools/verify_bcd_rank_m5.py` generates one exact canonical rewrite of
reviewed shadow top SHA256`93bc76d3019d3d1e5a8949a00e32d217d934b4ece5289ec26e1421b7a2a001fb`.
The serial8-character digit-insertion chain becomes independent digit masks,
balanced4-bit prefix counts and rank-selected digit nibbles. All edit validity,
text append/delete/reset operations, lengths, existing BCD state handling and
sequential logic remain identical. No selected-value consistency assumption is
required: arbitrary text, all16lengths and independently arbitrary decoded
ASCII/type inputs are admitted by the proof.

Candidate full top SHA256 is
`3da5807ad5ceb75db1332eed61b6699b97616712183cfabe2625c24bc09b1bbf`.
Actual-source projected reference/candidate combinational cones were flattened
and checked with Yosys0.33 SAT: all83observable edit outputs are identical for
every two-state input assignment. Exact source matching rejects all unreviewed
changes. The labeled negative toggles the third resistor digit and SAT produces
a counterexample as required. Final proof reports are
`golden/out/qor/bcd-rank-proof-final-20261011/report.json` and
`bcd-rank-proof-negative-final-20261011/report.json`. This is solver-backed cone
equality plus an exact unchanged-remainder source argument, not a full-design
four-state/electrical CDC proof. Six failure-oriented proof-tool tests pass;
the12Vivado runner and8shadow-proof tests also pass.

Before launching measurements, objective
`golden/out/qor/bcd-rank-objective-20261011.json` was frozen at SHA256
`aeeecba0aa7db764f9f0aaf1b407259a33269a1581323bce3c04e2ccba7e93df`.
It requires positive synth LUT gain, routed ceilings10089LUT/4166FF/10BRAM/0DSP,
setup WNS>=-1.607ns and hold WNS>=0. These are deliberately separate proposal
criteria and may fail; they cannot be revised after results to claim success.
`bcd-rank-proposal-20261011.json` freezes all75pair input hashes and settings:
only the reviewed top differs. Matched new baseline/candidate routed requests
are in `bcd-rank-{baseline,candidate}-routed-20261011`, retaining original XDC
and tool defaults; the generated-clock diagnostic is not mixed into this pair.
Measurement outcomes and whole-frontend regression remain pending. Production
RTL has not been changed by this QoR work.

Both new matched BCD routes completed with exit0 and complete reports. Strict
`--parse-only --check-working-tree` verification passes for both isolated roots.
The repeated shadow baseline measures10086LUT/4166FF/10BRAM/0DSP, WNS-1.701ns,
hold0.042ns; the BCD candidate measures10240LUT/4164FF/10BRAM/0DSP,
WNS-2.689ns, hold0.012ns. Synthesis baseline10492LUT versus candidate10633LUT
means gain-141LUT. The frozen proposal fails positive synth LUT gain, routed
resource ceilings and setup floor; only hold floor passes. Its preserved
`comparison.json` and `rejection.json` reject integration. Equivalent logic
alone is not a QoR success. The original retained candidate's slightly different
route10089LUT/WNS-1.657ns remains preserved; its measurements were not substituted
for this matched rerun.

An independently scoped shadow-only dual-clock characterization was approved
and frozen before launch at
`golden/out/qor/dualclock-shadow-proposal-20261011.json`, objective SHA256
`07fa63fea714b941558364bd81941d022c19cf079d5093bd34b499e0dadd67cf`.
All75input files match the repeated shadow baseline except the XDC, which adds
exactly the derived pixel clock without timing exceptions. Sources are
`dualclock-shadow-source-20261011`; output is
`dualclock-shadow-routed-20261011`. This run asks the implementation flow to
repair related-clock hold while retaining both clocks' setup/hold analysis.
Its characterization target is nonnegative setup/hold, resources within
12000LUT/4500FF/10BRAM/0DSP, clock periods10/40ns and no-clock/unconstrained
counts no greater than the2/1known latch findings. External I/O, the inferred
latch and functional pad synchronization remain explicitly unqualified even
if these numeric targets pass. The strengthened XDC is isolated and has not
been applied to production. Final outcome remains pending.

The dual-clock route completed naturally with exit0 and complete reports, and
strict scratch-source verification passes. It uses10081LUT/4167FF/10BRAM/0DSP.
All115hold failures exposed by the retained-DCP diagnostic are repaired by fresh
implementation: pixel hold+0.106ns, system-to-pixel hold+0.256ns and
pixel-to-system hold+0.011ns; overall hold failures are zero. Pixel setup is
+10.846ns; cross-domain setup is+7.123ns and+4.196ns. System setup remains
-1.816ns with484failing endpoints, so the predeclared nonnegative-setup target
fails and readiness stays false. The clocks remain related and timed without
exceptions. `dualclock-shadow-routed-20261011/characterization.json` records the
actual results and unresolved latch/I/O/CDC/DRC scope. Its current worst system
path is selected-cell Y-coordinate through address/pair logic into pending-pair
write enables,17logic levels (nineCARRY4) and11.536ns data delay.

Root authorized a separate old-text-prefix BCD candidate after the failed rank
proposal. Its isolated generator is
`golden/out/qor/bcd-prefix-tool-20261011.py`; repository tool inventory remains
frozen during root's independent gates. This rewrite recomputes the original
text prefix, then inserts the current ASCII digit once for an append, preserving
backspace and clear semantics. The83-bit actual-source edit cone again passes
arbitrary-input Yosys SAT; a labeled prefix-BCD XOR1negative yields the required
counterexample. Candidate full top SHA256 is
`ab175da0372ab5a4e0c362d48a154c24e2f508ea4f7e332011f02886a13c913d`.
No state, latency or extra-frame allowance was added.

Its new predeclared objective SHA256 is
`8acf1d522528deeb4a417425d71c133a8fcd048435ba5083abdc4137313a03cc`,
requiring positive synth LUT gain, nonnegative routed setup/hold and ceilings
12000LUT/4500FF/10BRAM/0DSP. Both baseline and candidate use the identical
strengthened dual-clock XDC. The completed dual-clock shadow measurement is
reused as the baseline only after verifying all75input hashes exactly match the
new baseline root, including runner/Tcl/XDC and matching tool/settings/part/
requested routed stage. `bcd-prefix-proposal-20261011.json` freezes those identities
before candidate measurement. New route output is
`bcd-prefix-candidate-routed-20261011`; its outcome is pending. Production remains
unchanged; full acceptance still needs independent functional and physical gates.

The prefix route completed naturally with exit0 and strict scratch-source
verification. It measures10207LUT/4160FF/9.5BRAM/0DSP, WNS-1.399ns,
TNS-363.328ns with472setup-failing endpoints, and hold+0.011ns with zero hold
failures. It improves setup by0.417ns against the exact dual-clock shadow
baseline, but synthesis LUT gain is-131 (10493baseline versus10624candidate).
The frozen nonnegative-setup and positive-LUT-gain requirements both fail;
resource ceilings and hold floor pass. Preserved comparison/rejection reports
reject integration. The gain in timing and half-BRAM saving are characterization
results for future proposals, with no retrospective objective change. All owned
QoR runs are complete; no production RTL or constraints were modified.

## Selected-pair and coordinate-latch proposals (2026-10-10 resume)

Two new isolated proposals start from the exact reviewed dual-clock shadow source,
without adopting either rejected BCD rewrite. The pair proposal changes only
`pair_addr_for_cell`'s 32-bit integer temporaries into signed 11-bit values with
explicit zero-extension of the 9-bit base and signed 288 bounds. The complete
intermediate range is -18 through 529, so 11 bits retain every case. It preserves
all 512 addresses, including 224 out-of-grid values; selected coordinates, state,
latency, array widths and other helpers remain unchanged. The actual-source
Yosys 0.33 SAT miter proves equality for arbitrary base/type/rotation, and an XOR 1
counterexample control passes. Generator and reports are
`golden/out/qor/pair-narrow-tool-20261010c.py` and
`pair-narrow-proof-20261010c/report.json`. Candidate top SHA256 is
`f86f59a278fd7168aa505636437c0bcc036fb010569b68c6a9fe13e0134f40a8`.

Its predeclared objective SHA256 is
`44a0d7f516d2ff5dfd6efcaa77f18e32b37b02427c7a85f48d358a05cc1887bc`:
positive synth LUT gain, routed ceilings 10081 LUT/4167 FF/10 BRAM/0 DSP,
setup WNS >= -1.716ns (0.1ns improvement), hold >= 0, no_clock <= 2 and
unconstrained <= 1. This bounded improvement would leave100 MHz readiness false.
The original dual-clock baseline is reused only after checking exact equality of
all 75 input hashes, runner/Tcl, top/part/stage, settings and tool version. Only
the candidate top differs. Proposal records and frozen input hashes precede
the route at `pair-narrow-candidate-routed-20261010c`; results remain pending.

The separate panel proposal inserts only `coord_len = 5'd0` at the start of its
combinational block. On the hint branch, `coord_data` is already all zero; the
actual `DynamicTextBox` marks character 0 invalid regardless of a retained length.
Its next-state output cone (the sole output register removed for combinational
analysis) passes SAT for arbitrary 128-bit text, all 32 lengths/stale lengths and
all 4096 x 4096 pixel coordinates. Nonhint data/length remain identical; hint data
is zero with arbitrary reference stale length versus candidate length 0. The
visible-A negative control yields a counterexample. Data and length are captured
at the same edge, so length differences remain paired with blank registered data;
equal next-state textbox output transfers through the unchanged panel pipeline.
This compositional argument qualifies observable two-state rendering behavior,
not arbitrary whole-design sequential/four-state equivalence. Independent full
panel/dependency Yosys `proc` inventory asserts exactly one baseline inferred
latch and zero candidate latches; `latch-inventory.json` retains scripts/logs.

Generator/reports are `coord-default-tool-20261010c.py` and
`coord-default-proof-20261010c/report.json`; candidate panel SHA256 is
`45ca2444a42286dce2cb0c71b1364762a8ec60b825277f94f086cc2337c73786`.
The independent latch-removal objective SHA256
`f448071ada8bcc6bdb00c74352747d8a86a04daeb345797445e859afbda21856`
requires zero internal no_clock/unconstrained findings, nonnegative routed hold,
ceilings 12000 LUT/4500 FF/10 BRAM/0 DSP and setup>=-2.0ns. Its explicit allowance
is 0.184 ns setup degradation; it does not claim100 MHz timing. Only panel source
differs across75matched inputs, and the same checked baseline is reused. Route
`coord-default-candidate-routed-20261010c` is pending. Both proposals preserve
the identical strengthened related 10/40 ns clocks, without exceptions or pad
delays. Production RTL/XDC remains unchanged and external-pad readiness false.

The signed-narrowing route completed naturally with exit0 and strict 75-input
scratch verification. It measures 10088 LUT/4165 FF/9.5 BRAM/0 DSP, setup WNS -2.248ns,
TNS -589.124ns with 628 failing endpoints, hold+0.053ns with zero failures.
Synthesis uses 10502 LUT versus 10493 baseline (gain -9), despite synth WNS improving
from -4.361 to -3.789 ns. Positive synth gain, routed LUT ceiling and setup criteria
FAIL; retained comparison/rejection rejects integration. Narrow signed arithmetic
alone is not a measured improvement. The actual route worsens setup 0.432 ns.

A distinct direct-range proposal replaces the general delta/add/compare chain
with four constant directions and exact pre-add/sub bounds: +1 requires base < 287,
+18 requires base < 270, -1 requires 1 <= base < 289, and -18 requires 18 <= base < 306.
Right-half sprites reverse direction; noncomponent types retain the base.
The bounds intentionally preserve invalid-address mappings 288->287 for subtract 1
and 305->287 for subtract 18. Arbitrary 512-address/64-type/4-rotation SAT equality
and XOR 1counterexample control both pass. Candidate top SHA256 is
`306711c4e679f971f7d1fa78fab5047e86cffe372cbd1653711bc3b8db19ce40`;
generator/reports are `pair-range-tool-20261010c.py` and
`pair-range-proof-20261010c/report.json`. New frozen proposal/objective uses the
identical original signed-narrowing criteria/hash 44a0d7f...; no failed threshold
was relaxed. Measurement has not yet launched, pending completion of the
independent latch route to avoid concurrent Vivado memory pressure.

The latch-only route completed naturally with exit0 and strict 75-input scratch
verification. It measures 10250 LUT/4159 FF/9.5 BRAM/0 DSP, setup WNS -1.585ns,
TNS -312.321ns with 452 failing endpoints, hold+0.022ns with zero failures.
All internal no_clock/unconstrained findings are zero, while the 10 input/44 output
delay findings remain. Every predeclared latch objective passes; setup improves
0.231 ns rather than spending its allowed degradation. The increased LUT count
is retained honestly: synth 10637 versus 10493 baseline (+144), routed 10250 versus
10081 (+169). This objective prioritizes correcting the inferred latch within
declared fit limits; it is separate from the failed positive-area pair objective.
`comparison.json` and `qualification.json` establish provisional latch correction,
with full readiness false. Production adoption still belongs to the root's
frontend contract review and whole-design regression.

After both earlier Vivado jobs completed, the independently frozen direct-range
proposal launched at `pair-range-candidate-routed-20261010c`. It remains pending;
the qualified latch correction has not been folded into this pair measurement.

The direct-range route completed naturally with exit0 and strict75-input scratch
verification. It measures10208LUT/4167FF/10BRAM/0DSP, setupWNS-2.303ns,
TNS-525.826ns with499failing endpoints, hold+0.037ns with zero failures.
Synthesis uses10628LUT (gain-135) and WNS-4.373ns. Positive synthgain, routed
LUTceiling and setup criteria FAIL, so comparison/rejection retain another
rejected proposal. No arithmetic candidate is qualified for adoption. All three
new Vivado jobs completed naturally; their owned process groups are empty.
The isolated latch correction is the only accepted provisional objective from
this role, with production integration and full readiness left to the root gate.

Root's isolated bitmap+shadow+panel composition (2026-10-11 client date)
completes routing with strict75input source/snapshot/tool/XDC verification.
Only the two bitmap store files differ from the qualified panel baseline.
`golden/out/qor/composed-epoch-objective-20261011d.json` was frozen before launch:
14000LUT/5200FF/10BRAM/0DSP ceilings, setup>=-2.0ns, hold>=0, no internal
no-clock/unconstrained findings. Routed10671LUT/4740FF/9.5BRAM/0DSP passes area,
hold+0.007ns/zero failures and internal constraints0/0, but setup-2.699ns fails
its fixed floor (-1.114ns versus panel baseline-1.585). TNS-746.149,757setup
failures. External10input/44output delays remain unknown. `comparison.json`
retains rejection; bitmap remains isolated. This composition predates root's
FIFO wrap correction and cannot qualify evolved production. No threshold or
clock exception changed to accept the result.

Current queue/panel/shadow composition (2026-10-11 client date) completes strict
75input qualification at `queue-panel-shadow-routed-20261011d`. Only queue and
unreachable currentSolverBoard differ from the prior panel baseline; all measured
RTL matches adopted production, while XDC remains isolated with related10/40ns
clocks and no exceptions. Frozen scoped objective passes:10092LUT/4157FF/9.5BRAM/
0DSP,setup-1.333ns/hold+0.047ns,internalno-clock/unconstrained0/0. Versus panel
baseline10250LUT/4159FF/9.5BRAM, setup improves0.252ns and LUT falls158; these
are observed deltas, not a replacement for predeclared full acceptance. TNS-361.343
and455setup endpoints stillfail; external10input/44output delays remain unknown.
`comparison.json` records scopedpass/readinessfalse. Production XDC notchanged.

Current-production selected-address capture proposal (2026-10-11 continuation)
passes actual extracted two-stage cone equivalence and a shortened-pipeline
control, but routes10097LUT/4141FF/9.5BRAM, WNS-2.547ns/hold+0.050ns. Its frozen
setup floor is-1.0ns (>=0.333ns improvement from current-1.333ns). It fails and
remains isolated: +5LUT/-16FF/-1.214ns. The new worst path is keyboard ASCII to
netlist dirty,14levels/12.576ns with9.914ns routing. Internal unknowns0/0 do not
remove the external10input/44output timing gaps.

The new validity-only alias correction removes redundant epoch tags while
retaining the qualified bitmap and logical store latency. It passes independent
store ledgers and watched-cell proofs, routes10776LUT/4705FF/8.5BRAM/0DSP,
setup-2.040ns/hold+0.032ns, internalunknown0/0. It saves1BRAM but narrowly fails
the unchanged-2.0ns correction floor; no rounding or threshold relaxation.
`valid-only-candidate-routed-20261011e/comparison.json` preserves rejection.
A separate row-organized bitmap proposal changes real address-decoder structure
while retaining flat logical cells and latency. It passes the same store ledger/
proof controls. Its predeclared objective keeps the same caps/floor and BRAM
gain requirement; routing is pending in `row-valid-candidate-routed-20261011e`.
Neither proposal is integrated, and production constraints remain unchanged.

The integrated A009/A010 reply correction passes its predeclared scoped floor:
10149LUT/4197FF/10BRAM/0DSP, setup-1.953ns/hold+0.027ns. Strict75source/snapshot
pins match mainRTL; XDC is still the isolated related10/40ns variant, not
production. The correction spends+57LUT/+40FF/+0.5BRAM and0.620ns setup compared
with the preceding composition. This is correctness qualification, not a
positive-resource optimization or fulltiming pass.

A new last-recognized unit-suffix priority tree is exact two-state equivalent
for every64bit text value and16lengths, including invalid bytes/lengths. Routed
10284LUT/4194FF/9.5BRAM/0DSP,setup-2.580ns/hold+0.011ns fails the fixed-1.5ns
setup target (required0.453ns improvement from-1.953). It is rejected, unchanged
constraints/objective preserved inunit-tree-candidate-routed-20261011e/comparison.json.
