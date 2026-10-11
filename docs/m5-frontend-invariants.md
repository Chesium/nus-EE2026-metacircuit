# M5 production frontend invariant observations

These observers qualify finite production frontend safety cases in M5-4. They
run the real `GlobalRender_top`; the frozen `GlobalRenderUartLoop_test.sv` remains
unchanged. The supplemental `M5FrontendSupplemental_test.sv` adds serial reply
cancellation and canvas command fixtures. This evidence does not complete M5-4
or establish full refactor readiness.

```sh
python3 golden/tools/verify_frontend_invariants_m5.py --runtime native --out golden/out/m5-frontend-invariants/NEW-frozen-native
python3 golden/tools/verify_frontend_invariants_m5.py --runtime docker --out golden/out/m5-frontend-invariants/NEW-frozen-docker
python3 golden/tools/verify_frontend_invariants_m5.py --runtime native --bench supplemental --out golden/out/m5-frontend-invariants/NEW-supplemental-native
python3 golden/tools/verify_frontend_invariants_m5.py --runtime docker --bench supplemental --out golden/out/m5-frontend-invariants/NEW-supplemental-docker
python3 -m unittest discover -s golden/tools -p test_verify_frontend_invariants_m5.py -v
```

The runner compiles the complete design, packages first, excluding vendor floating
point files, with `--timing --assert`. Reports include source and runner hashes,
actual tool version and source stability through the run. Docker uses the existing
read-only source mount and toolchain image. Missing/duplicate/malformed evidence,
failed builds, failed simulations or unrelated negative crashes return nonzero.
Nineteen Python controls pin this acceptance, including every required supplemental
layout and cancellation case. Wall-clock and bench watchdog limits are test limits.

At the first initialized `!component_store_busy` edge and each subsequent
busy-to-ready boundary, the observer reconstructs row-major indices, packed
unit/type/rotation/value/position entries and all 288 map words independently
from primary sprite shadows. It checks paired geometry and orphan halves without
calling DUT address or component helpers. Stale unused component entries are
unconstrained. Continuous assertions bound actual store/map write addresses.
All checks sample before nonblocking assignments, exactly when consumers see
readiness; no hidden RAM-drain wait is added. The selected synchronous index
read is also compared at those edges if its address has remained stable for
two sampled clocks and a selection is active. Arbitrary selection changes and
physical canvas RAM equality remain outside this observer's scope.

The frozen UART loop covers boot and wire deletion, two layouts of three indexed
components. The supplemental bench drives exact accepted write commands at the
real frontend's background command port; it never initializes RAM or shadow
arrays directly. It checks the command actually presented on each accepted edge
on both Verilator versions. It bypasses mouse/controller/guard stimulus, including
selection crossing for a fixed read at address286. This allows RAM boundary
fixtures beyond the initially visible UI canvas; it does not establish UI
reachability of every fixture. The fixture expectations are separately built from
literal stimulus words, not from DUT shadows. Six layouts cover empty storage,
all five indexed types and four rotations with corner cells, horizontal and
vertical last-cell partners, deletion, and a last-cell origin287/partner286.
All fixture values/units are zero; boot retains nonzero values. Arbitrary values,
units, overlapping/malformed layouts and maximum-capacity layouts remain gaps.

A clock-by-clock independent semantic packet model checks active voltage-bank
selector, valid, frame, node count, status and staging-active lifecycle. It forbids
both banks being written together, active-bank writes and staging into the active
bank. At packet boundaries it compares published RAM words with independently
collected serial values. Assumptions are one semantic event per accepted UART
line and distinct valid node indices; arbitrary overlapping parser events and
duplicate-node semantics remain unqualified. The UART parser handles framing and
checksums; both benches drive real serial pins at115200baud.

The supplemental bench establishes a committed10V value, writes a different
partial reply into the inactive bank, then separately cancels it with a bad
checksum, stale error, stale begin, incomplete end and current error. It also
replaces a partial stage with a current begin and commits the replacement. Each
case independently checks bank/data preservation and specified valid/status,
plus the observer's full metadata/lifecycle model. Five explicit cancellation
cases and six observer aborts (including replacement) must be present for
acceptance. The frozen bench still reports zero aborts; its old gap is not hidden.

A local source-derived progress assertion starts only at a fresh index-map clear
address0 with dirty clear after initialization. It cancels tracking on any
possible canvas/value edit or dirty restart. Under that explicit quiescence,
288clear visits +288scan visits +at most288pending-pair service cycles +launch
and registered write/read drain finish within a conservative870system clocks.
The counter includes the launch/acceptance edge allowance and compares against
this fixed source-derived bound, rather than inferring a bound from observed
runtime. This says nothing about arbitrary stalls, mid-rebuild dirty restarts,
continuous edit traffic or global architectural progress. Reports expose
completion count and maximum observed cycles; a specific negative exceeds the
bound only in the observer. A queue observer continuously checks count
conservation and head/tail/count capacity at the actual flood queue depth1152.
It does not prove FIFO order, all queues or arbitrary lifetime wrapping.

Eight negatives corrupt observer observations only: index map, component entry,
active voltage metadata/data, stage lifecycle, selected synchronous index read,
queue count and local rebuild counter. Each must terminate with its exact
`M5_FRONTEND_FAILURE` label. The supplemental stage negative specifically fires
after cancellation, while the frozen stage negative tests lifecycle consistency.
Production control/memories are untouched by negative injection.

On the restored source SHA254c8842d72c6c4801ef015c8c3274687a970c8794f9d09e6d966ced42657a66,
original observers passed both runtimes (`{native,docker}-restored-20261011`).
New supplemental evidence then found a real last-origin readiness defect on
both runtimes: at58,792,165ns, `busy=0`, map286=511 while expected0 and the
registered write strobe still targets286. Captured pre-fix reports
`{native,docker}-prefixed-boundary-20261011/summary.json` deliberately fail.
Five preceding layouts and five cancellation cases passed; no failing boundary
was waived. Production fixes belong to the coordinator: retain map/store
registered write strobes and their synchronous read drain in busy. The fixed
source SHA4e62e63dd68ba9e946006a86129d48c39dd7570710a73451f0fd1fba68c2bb16
is qualified separately in `{native,docker}-fixed-{frozen,supplemental}-20261011`.
Historical candidate-source reports remain historical, not current acceptance.

The compiled supplemental binary accepts `+m5-boundary-only` for a separate
minimal witness: quiescent boot then one last-cell-origin layout through the
accepted command interface, with first-ready storage/read checks. This fast
witness does not satisfy complete supplemental acceptance by itself.

Formal/global equivalence, all-frame renderer safety, arbitrary overlap/stalls,
full value/unit/capacity coverage and actual PS/2/CDC remain unsupported. Mouse
model stubs come from the frozen bench, not actual hardware PS/2 behavior.

Final frozen native/Docker reports both `ok:true`, with 2 map-ready checks,
12 bank-data checks, 3 commits, 5 staged nodes, 2 stale events, 0 aborts,
26,318,579 clocks and 370 queue adds/pops. Both supplemental reports are
`ok:true`, with 7 map-ready checks, 20 bank-data checks, 2 commits, 8 staged
nodes, 2 stale events, 6 aborts and 5,879,221 clocks. Their six quiescent
rebuilds reach at most 582 clocks, with seven selected-read checks and 72
queue adds/pops. All eight negatives were detected in each of the four
runs. Both minimal witnesses pass. Every final report records unchanged
sources through the run; later source edits require fresh qualification.

An isolated candidate can use `--design-root /path/to/candidate/src/design`.
The bench and observer still come from the main workspace. Reports record the
selected design root and exact source paths/hashes; Docker mounts that directory
separately at `/design` read-only. This option never falls back to production when
the directory is absent. Candidate observations are separate from restored and
readiness-fixed baseline evidence.

The isolated shadow-storage candidate top SHA
`93bc76d3019d3d1e5a8949a00e32d217d934b4ece5289ec26e1421b7a2a001fb`
also passes all four frozen/supplemental native/Docker runs in
`{native,docker}-shadow-{frozen,supplemental}-20261011`. Observations match the
readiness-fixed baseline exactly, all eight specific negatives are caught, and
selected source hashes remain unchanged through each run. These finite safety
observations do not establish FPGA gain or full candidate readiness.

The 2026-10-11 expansion adds `--bench restart`, a separate fast fixture using
`M5FrontendSupplemental_test.sv` and `+m5-restart-only`. It supplies no UART
packets and exercises no flood-queue traffic. Its acceptance scope is component
store/index publication and eventual-quiescence rebuild progress; its reports
cannot replace the original UART/cancellation/queue suites.

```sh
python3 golden/tools/verify_frontend_invariants_m5.py --runtime native --bench restart --out golden/out/m5-frontend-invariants/NEW-restart-native
python3 golden/tools/verify_frontend_invariants_m5.py --runtime docker --bench restart --out golden/out/m5-frontend-invariants/NEW-restart-docker
```

The continuous observer now retains a separate deadline across dirty restarts.
Every possible edit after initialization starts or resets that deadline. After
edits quiesce, at most one old rebuild plus one complete fresh rebuild and four
launch/drain clocks must finish within1744system clocks (2*870+4). This bound is
derived from the finite source operations, not tuned to observed fixture times.
Clear-canvas, pending value copies, keyboard edits and accepted background writes
reset the deadline; perpetual edit traffic carries no completion promise. The
original870clock fresh-clear bound remains independently checked. Neither bound
proves arbitrary external stalls, formal fairness or global architectural progress.

Five finite cases update a previously scanned indexed origin and its partner
during map clear, interior scan, pending partner write, final scan and registered
write drain. Each starts through an accepted standalone wire edit and then
changes literal accepted cell words at origin0/partner1, retaining a second
origin287/partner286. Expected maps and packed entries come from these fixture
constants; no RAM/shadow array is directly written. The independent observer
checks the first advertised pre-NBA readiness edge, and the fixture additionally
checks every map word and both component entries. Fixed selection286 checks the
synchronous read. Exact phase labels/counts, all seven layouts, eight ready
checks, seven completed edit deadlines and the fixed1744bound are required.

Native/Docker `{native,docker}-restart-20261011b/summary.json` both pass with source stability,
8,552clocks,595edit clocks, seven completed deadlines and maximum1058clocks.
Five per-case readiness counts are1057,728,868,581,581. Four specific negatives
(index map, component entry, selected read and restart deadline) are detected;
an unrelated crash does not qualify. This is directed phase evidence, not an
arbitrary-state proof. It leaves maximum capacity, nonzero values/units, arbitrary
selection/overlapping packets, queue lifetime/order and actual PS2/CDC open.
Earlier frozen/supplemental reports retain their earlier observer/runner hashes;
current-source acceptance requires fresh evidence after source/test changes.

Fresh current-observer qualification is also complete for both original suites
in `{native,docker}-{frozen,supplemental}-expansion-20261011b`. All four reports
pass, preserve the earlier normal observation totals, catch all eight original
specific negatives and record unchanged source hashes. Together with the two
restart reports, all six source and runner hashes match the current files at
this checkpoint. The frozen UART bench remains unchanged. The restart suite
uses four controls; the original suites keep their eight controls. Full M5-4
remains incomplete despite these additional finite progress/safety cases.

A separate finite domain suite now preserves the original observer, supplemental
bench and runner hashes. It builds `M5FrontendDomains_test.sv` with the same
unchanged production-bound observer, using its own runner and parser controls:

```sh
python3 golden/tools/verify_frontend_domains_m5.py --runtime native --out golden/out/m5-frontend-domains/NEW-native
python3 golden/tools/verify_frontend_domains_m5.py --runtime docker --out golden/out/m5-frontend-domains/NEW-docker
python3 -m unittest discover -s golden/tools -p test_verify_frontend_domains_m5.py -v
```

The suite fills all288cells with144disjoint two-cell components, the maximum
legal tiling for this geometry. Its72literal2x2tiles combine all five indexed
types and four rotations. All288map words and all144packed entries are compared
against independent fixture constants at the first advertised readiness edge.
The remaining14layouts include empty storage, eight value/text cases, four
keyboard/rebuild phase combinations and a real clear-canvas backpressure case.
No RAM or shadow entry is directly assigned by the bench.

The keypad input supplies exactly41one-pixel-clock semantic pulses. Actual DUT
logic toggles and synchronizes each event, reads existing property text from its
RAM, edits the selected component, and performs its pending second-half write.
Literal expectations cover resistor123, multiple nonresistor two-digit words,
all six recognized suffixes (`M`, `k`, `m`, `u`, `n`, `p`) and no suffix. Origin
and partner selection alternate during editing. Backspace removes a suffix,
replacement changes its unit, and a dot plus a fourth digit preserves the
resistor123BCD while retaining the literal text edit's final unit. Values and
units for every cell, including both halves, are checked independently alongside
the packed component entries.

UI hit testing and mouse/guard input remain bypassed. Selection coordinates,
selection enable and property-edit enable enter the pixel-side UI registers;
the DUT's system synchronizers and read logic remain active. The keypad pulse
enters the real pixel-side key-valid/ASCII input. Eight directed stable selection
transitions check origin, partner, last origin, last partner, disabled, reenabled,
empty selected and empty disabled states. After12system clocks for the declared
stable selection, literal map index, valid state, value, unit, rotation and packed
position must agree. These checks do not establish arbitrary rapidly changing
selections, physical mouse/keypad input or asynchronous CDC correctness.

Four cases start keypad stimulus while the old rebuild occupies clear, interior
scan, pending partner write or registered drain. The accepted edit crosses the
real pixel-to-system event path and need not coincide with the initial one-clock
phase; these are finite phase combinations, not a promise of exact acceptance
in every named phase. The unchanged continuous observer retains its1744clock
completion deadline after input quiescence and its independent870clock fresh
rebuild bound. In the backpressure case, global DEL with selection disabled
launches the real288cell clear. A background command is held for20clocks while
its actual ready signal remains low, then withdrawn before acceptance. The final
empty fixture proves that this stalled command did not publish its component.
Arbitrary stalls and contention with higher-priority writers remain gaps.

Verilator5.020 initially exposed a stimulus error: forcing the system selection
alias did not propagate to an inlined editable-property predicate, although the
alias readback appeared forced. The saved Docker draft reports deliberately fail
at the first keyboard edit; generated C++ references the underlying unforced
synchronizer register in that predicate. Moving selection/edit enable stimulus
to their upstream pixel-side registers repaired the fixture without changing
production RTL. Native drafts also retain an independently corrected packed
position expectation and the parser's initial uppercase-label rejection.

The final reports are
`golden/out/m5-frontend-domains/{native,docker}-pixel-selection-20261010c/summary.json`.
Both return `ok:true` with source stability,22438system clocks,17ready checks,
16fresh rebuild completions (max722<=870),16dirty-restart deadlines
(max1425<=1744) and16observer selected-read checks. Every declared layout,
value/unit case, selection and phase label is required in order by the runner.
Seven specific negatives corrupt observed map, packed entry, synchronous read,
restart deadline, keyboard value, keyboard unit or selected map comparison; every
control terminates with its own required assertion label. Nine parser controls
reject missing/duplicate/reordered cases, wrong literal values/geometry/units,
wrong bounds, failed exits, unrelated crashes and unsupported UART/queue counts.

The domain fixture has zero UART commits/staged nodes and zero flood queue
adds/pops; the original suites retain those separate finite obligations. All
final source and runner hashes were independently read back against both reports.
No existing observer/supplemental/runner or coverage policy was changed. Capacity,
values and selection now have these directed witnesses, while malformed/overlap
layouts, exhaustive values/text, arbitrary stall/selection timing, formal/global
progress, actual PS/2/CDC and all-frame renderer safety remain unsupported.
