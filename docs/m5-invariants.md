# M5 scoped controller/guard invariant qualification

This is directed simulation evidence for part of M5-4. It does not complete
M5-4 or establish autonomous refactor readiness. The production interaction RTL
and the existing `CanvasCommandGuard_test.sv` are unchanged. The separate
`M5CanvasInvariants_test` top and bound monitors reside in
`src/testbench/M5CanvasInvariants.sv`.

Run a fresh output directory for each runtime:

```sh
python3 golden/tools/verify_invariants_m5.py --runtime native --out golden/out/m5-invariants/NEW-native
python3 golden/tools/verify_invariants_m5.py --runtime docker --out golden/out/m5-invariants/NEW-docker
python3 -m unittest discover -s golden/tools -p test_verify_invariants_m5.py -v
```

The runner builds with `--timing --assert`, records active RTL/bench hashes,
runner hash and Verilator version, runs reply delays 1, 3 and 9, and returns a
nonzero exit if a build, directed run, exercised channel requirement or specific
negative control fails. Docker uses the existing
`framescope-toolchain:6501155dc903` image and a read-only source mount. The JSON
`ok` field qualifies only the stated scope; `unsupported` entries remain gaps.
The 14 Python tests reject omitted/duplicated evidence, missing stall exercise,
lost/duplicated commit or reply counts, wrong latency, excessive watchdog time
and unrelated negative-control crashes. They also pin writable Docker output
mapping, including output directories nested beneath the read-only source root.

Every rising edge checks request persistence across stalls on controller and
guard-background channels, including address, write control and meaningful
write data. Logical requests must remain within 288 cells. Local guard count
and index must fit its three-entry storage; this monitor deliberately depends
on the audited guard state encoding, unlike the interface monitor.

An independently specified ordered write ledger checks every accepted memory
write against expected address/data. At 42 settled boundaries, the bench checks
all 288 words against the ledger's expected image and verifies both component
halves, sprite pairing, rotation and partner location. Missing commands fail the
ledger drain; duplicates or unexpected rejected-edit writes fail its next-event
comparison. Rejected occupied-anchor/partner placements, occupied-component
replacement, blocked rotation and same-sprite replacement have no expected
writes. Successful placement, wire painting, two-cell rotation, delete and
single-cell replacement have exact expected write events. These checks establish
absence of partial writes for these directed rejected edits. Accepted multiword
edits use sequential memory writes; atomic visibility to other observers is
unqualified.

The memory model samples a read at acceptance, allows only one outstanding read
and emits one registered reply after the chosen delay. The monitor checks its
outstanding-read assumption and final reply drain/conservation. This is an
explicit environment model, not proof of production reply atomicity or arbitrary
latencies. The component check observes logical cell RAM and geometry; it does
not compare a second independently stored production component map.

Memory readiness is false at `cycle % 7 == 0`. A directed 20-cycle hold makes an
actual rotate read stall on both real interfaces. A second directed 20-cycle
hold leaves the guard validating an edit; after `controller_done`, a release
frame and another same-mode edit create genuine controller write backpressure
while the guard is busy. No ready signal is forced or bypassed. Normally frames
wait for `done && idle`; this one bounded overlap is explicit stimulus and does
not qualify arbitrary overlapping frames or mode changes during a guard edit.
A separate thread holds the first background write for 12 cycles before its
first acceptance, so memory write persistence is exercised at every delay.

The completion watchdog is `64 + 4 * reply_delay` rising-edge intervals counted
from entering the settle task, after releasing the directed 20-cycle holds.
The schedule can drain up to four validation reads in the two-edit overlap.
The 64-clock fixed allowance covers controller decode/readback stages, buffered
command acceptance, guard transitions, bounded `%7` denials, the initial
12-cycle write hold and settle sampling. It is a conservative test watchdog
chosen from this finite schedule, not a specified architectural progress bound
or formal derivation. Initial overlap setup has separate 32/8-cycle checks.
A withheld memory reply must hit the watchdog; this demonstrates detection
rather than establishing progress under an unfair memory environment.

Verified native and Docker evidence is in
`golden/out/m5-invariants/resume-{native,docker}-v2/summary.json`.
Each runtime passed all three delays and all four negative controls. Every
normal run has 42 settled checks, 16 commits, 21 accepted reads and 21 replies.
Observed maximum settle counts are 26, 30 and 52 at delays 1, 3 and 9. The two
directed upstream stall witnesses each last 19 sampled falling edges; the
rising-edge request counters are authoritative for channel exercise. Negative
controls corrupt the observed request address, observed committed data or
settled cell observation, or suppress the test memory reply. They must fail
with their specific invariant label; production RTL is unchanged.

Formal or old/new equivalence, global queues, production component-map equality,
all-frame properties, arbitrary stalls, globally specified progress bounds,
accepted multiwrite/reply atomicity, solver/IP, PS/2 and CDC remain unsupported.
No source of those gaps is reclassified as a pass by this report.

### Isolated epoch invalidation qualification (2026-10-11)

The current-generation validity bitmap correction remains isolated under
`golden/out/m5-epoch-functional-source-20261011d`. This snapshot includes the
production SolverBoard capacity guard and original frontend top; only the two
matrix-store files change. It contains neither shadow write normalization nor
the separate panel latch correction. The exact composition and unchanged
oracle/stimulus hashes are in
`golden/out/m5-epoch-qualification-20261011d/provenance.json`.

Yosys 0.33 proves the following property for actual 18x16 stores with 16-bit
epochs: after a real synchronous reset or clear, an unwritten cell returns zero
when its read completes, even if other cells are written and the epoch wraps.
A symbolic watched address covers all 288 cells; its sole environmental
assumption is that the watched address is below CELL_COUNT. Read/write inputs,
invalid coordinates, reset and clear remain arbitrary defined values.
Observers strengthen the theorem with invalidity of the unwritten cell, correct
read-address tracking and invalidity at the RAM-response stage. Temporal
induction proves all four assertions together at depth two for both stores.

The watched-cell proof uses universal cutpoints for registered RAM tags and
epoch, plus registered data for the result store. These signals become arbitrary
each cycle; this overapproximates the actual memory behavior and establishes
that the validity guard suppresses stale values regardless of their contents.
The actual validity bitmap and read/handshake pipeline remain intact. Separate
unabstracted proofs establish the empty-generation property at induction depth
three. Formal source copies preserve the original module statement text and
append only observers. Removing bitmap reset/clear invalidation yields retained
bounded SAT counterexamples. Commands, source/tool/artifact hashes and exact
scope are recorded in `golden/out/m5-epoch-qualification-20261011d/proof/report.json`.

An independent logical-store checker tests every read/write completion and
value for 86,123 clocks on both pinned Verilator runtimes. It populates all
288 cells, applies 65,536 continuous real reset clocks, reads every cell and
then runs 20,000 deterministic random clocks with overlapping operations,
invalid coordinates and single-cycle reset/clear. Both runtimes pass the same
10,276 reads, 3,166 accepted writes, 65,628 reset clocks and 75 clear clocks.
Logical-value corruption fails with its specific assertion on both runtimes.
The unchanged baseline fails the same checker at clock 65,830, returning stale
region 1 where the independent model expects zero. Historical original-wrapper
alias witnesses remain preserved. Details are in
`golden/out/m5-epoch-qualification-20261011d/store-report.json` and
`store-baseline-native-report.json` under the same root.

This proves absence of stale values for unwritten cells after real reset/clear;
it does not prove arbitrary cold handshake state, updated-cell data correctness,
integrated flooding lifetime/progress or asynchronous reset/physical CDC.
Updated-cell values and overlap semantics have directed simulation evidence.
Historical standalone bitmap cost remains +813 LUT/+578 FF, unchanged BRAM;
production adoption and composed FPGA acceptance belong to separate decisions.

The same isolated epoch source also passes complete native/Docker M2 and M3:
780 frames/103 checkpoints each (M2 298/61, M3 482/42), with unchanged accepted
initialization, oracle, pixels/state/UI/UART comparators and final source/harness/
simpyhls hashes. Runs took 1413.904/1727.288 seconds under the originally
declared 2400-second runtime budgets. Aggregate evidence and cleanup are in
`golden/out/m5-epoch-qualification-20261011d/summary.json`. This qualification
uses the original frontend/queue/panel snapshot plus bitmap and capacity guard;
it does not inherit the parent's later FIFO/panel/shadow composition or remove
the independently failed composed FPGA objective.

### FIFO arbitrary-transaction order (2026-10-11 continuation)

`tools/verify_flood_queue_order_m5.py` proves circular pointer/count geometry
and FIFO order for an arbitrary selected accepted transaction at depths1,3,4
and1152. After actual reset/clear, its number of earlier queued transactions
stays below the queue count; its physical address equals head plus that rank
modulo DEPTH. Its truncated18-bit payload remains unchanged until pop capture,
and the delayed pop result/done preserves it. Requests, overlaps, rejection at
empty/full, reset/clear duration and lifetime are arbitrary binary inputs. No
fairness or eventual-pop assumption is made; reset/clear cancels the obligation.

The proof projects one fixed symbolic RAM cell. Its sole address assumption is
`watched_address < DEPTH`; that cell starts at zero and updates under the exact
reviewed reset-gated write condition. Other read values are unconstrained. This
overapproximates the logical single-clock read-old array semantics. The runner
fails closed for an unreviewed FIFO source identity, so changing RAM semantics
requires a new reviewed projection. It does not qualify a physical primitive,
four-state behavior, cold pre-reset pointer state or arbitrary parameter widths.
A low-bit read corruption must produce a bounded counterexample. Positive
bounded witnesses require actual reset, selected enqueue and delayed retirement;
depths>1 additionally require earlier transactions and simultaneous accepted
enqueue/dequeue while the selected transaction remains outstanding.

Original exploratory proof and maintained reports are in
`golden/out/m5-flood-queue/order-proof-20261011e` and
`maintained-order-covers-20261011e`; the latter remains pending until its report
and all cover traces have been checked. Existing lifetime/overlap/range evidence
is retained separately. Production FIFO RTL is unchanged in this continuation.

### Guard conditional completion proof (2026-10-11 continuation)

`tools/verify_guard_progress_m5.py` uses the actual guard state, buffered arrays
and outputs, with appended observers. It proves stalled downstream request
stability, buffer index safety and completion after controller_done within
`5*A + 2*R + 4` clock samples for (A,R)=(1,1),(3,5),(7,11), giving11,29,61
clocks. A bounds request acceptance; R bounds the exactly-once response latency
from1 toR clocks. Upstream holds valid/address/write/meaningful write data until
ready; it does not issue another command during a passthrough read, and done
closes a collected burst with no concurrent command or pending passthrough read.
Synchronous reset cancels the progress obligation. AddrWidth9/DataWidth16 and a
two-state model are the scope; whole-controller/frontend/physical progress is
not established.

The ranking function accounts for remaining validation reads and writes, and
subtracts the elapsed ready/reply waits. Range and phase invariants prove that
a closed active operation cannot return to COLLECT with buffered work. These
lemmas remove unreachable induction states; they are assertions proved from
real reset, not extra environmental assumptions. A stalled-address observation
corruption is detected. Reachable input witnesses also establish reset, accepted
collected work and completion; A3/R5 andA7/R11 additionally exercise read/write
backpressure and delayed replies under the same assumptions.

Earlier undef-model induction was interrupted and the initial two-state
A7/R11 attempt timed out; neither is relabeled PASS. The completed strengthened
artifact report is `golden/out/m5-guard-formal-ranking-phase-20261011e/report.json`.
Maintained proof/cover reports in `m5-guard-maintained-covers-20261011e` are checked
separately before gate integration. Global map/reply publication, controller
progress and arbitrary unfair stalls remain outside this proof.

### Quiescent rebuild and reply integrity proofs (2026-10-11)

`verify_component_progress_m5.py` extracts the actual initialized rebuild
scheduler, write strobes, drain and busy expression, and checks that no producer
is omitted. Scan classifications and payloads become arbitrary cutpoints.
This proves range, a maximum ranking potential1733, strict decrease after edits
cease, and the existing1744clock completion deadline at any reachable phase.
A stuck-clear update has a bounded counterexample. A separately retained input
witness edits an old rebuild, freezes it, then completes a second clear/rebuild
and drain. This is a control-cone theorem, not component-map/data equivalence
or flooding/extraction/solver progress.

`verify_reply_parser_m5.py` proves actual dispatch/reset/output control with
every pure helper-call return independently arbitrary, an overapproximation of
the unchanged pure byte/hex/checksum functions. At most one begin/node/end/error/
parse-error event appears per clock; accepted begin/end counts are<=32 and node
indices<32. A multiple-event corruption has a bounded counterexample, and all
five event types have a reachable cover. The unabstracted full parser timed out
and is not called proved; grammar/data-byte equivalence remains unsupported.

`verify_reply_banks_m5.py` copies the actual receiver body and initialized
registers, checking complete producer inventory. Under those independently
proved parser constraints, the corrected seen mask equals the received count,
contains no undeclared node, and permits commit only after every declared node
is seen and the staged frame matches the current snapshot ID. Staged writes
select the inactive primary bank, and primary bank selection changes only for
a complete current reply or disabled mode. Commit metadata is preserved.
Removing the duplicate guard produces a bounded counterexample. Current ID,
enable, decoded payload/status and button predicates otherwise remain arbitrary;
no fairness or packet timing assumption is made. This proof qualifies control
and metadata, not logical RAM payload, view refresh or arbitrary simultaneous
UI/reply range semantics. The real UART/BTN fixture verifies finite payload/view
cases separately, including all32words and selection retention.
