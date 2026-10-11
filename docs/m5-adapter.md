# M5 semantic observation adapter

`golden/tools/semantic_adapter.py` reads the existing framescope `report.json`
and its indexed memory dumps. Schema `metacircuit-semantic/v1` expresses logical
grid coordinates, component identities by anchor, sprite/rotation, per-cell
values and units, toolbar and pan state. The UI profile adds selection, edited
text and settled colours. The backend profile adds snapshot/reply ids and
status, node-addressed active voltage bits, display values, terminal order and
complete UART TX/RX bytes with exact timestamps and capture boundaries.

All requested profiles require their mandatory evidence. Missing or duplicate
frames/dumps, wrong widths/depths, overflow words, unmapped probe encodings,
unsettled/drop checkpoints, broken owners, component overlap, mirrored-memory
disagreement, malformed TX records and invalid transaction order fail. Deliberate
malformed RX fault bytes remain preserved for the independent receiver oracle.
Final partial TX lines, open snapshots and queued responses remain explicit;
they never excuse a completed record mismatch. Frame indices and times are
preserved without latency shifting or extra settling time.

Configuration is explicit JSON: `probes` maps logical names to captured names,
or `{ "name": "new.state", "values": { "42": 1 } }` for a declared encoding;
`memories` maps names, widths/depths and logical-to-physical address permutations;
`fields.cell` and `fields.component` define each field as `[shift,width]`.
`live_component_slots` explicitly declares sparse live allocation; its length
must equal the captured component count. Index fields and ownership maps must
agree with that physical allocation. Default allocation is the baseline's
contiguous live prefix, with stale entries above count ignored. These mappings
permit renamed capture paths, slot reorder, address reorder and supported
bitfield packing. They do not implement arbitrary split-field or compressed
RAM decoders. Framescope manifest capture expressions must be updated separately
when RTL hierarchy changes. Public output excludes instance paths, FSM encodings,
component slots and voltage-bank selection; config identity is a SHA-256 digest.

Run from the repository root:

```sh
python3 -m unittest discover -s golden/tools -p test_semantic_adapter.py -v
python3 golden/tools/test_semantic_adapter.py --qualify \
  golden/out/m4/regression-agent-evidence.json golden/out/m5/adapter/qualification.json
python3 golden/tools/semantic_adapter.py \
  --actual golden/out/m4/regression-agent-qualification-20261010/native-m3/m3_display/rtl \
  --reference golden/out/m4/regression-agent-qualification-20261010/native-m3/m3_display/reference \
  --profile backend --output golden/out/m5/adapter/m3_display.json
```

Qualification performed on 2026-10-10: eight controls pass, including physical
slot relocation, captured-path/FSM remapping, shifted component packing, address
permutation and missing/corrupted evidence. All 18 accepted native/Docker M2/M3
captures pass strict adaptation and core comparison against saved golden RAM/
semantic checkpoint files: 206 checkpoints. All nine paired native/Docker
normalized outputs agree, including UART timing and boundaries. Evidence lives
in ignored `golden/out/m5/adapter/qualification.json`; accepted capture paths
are inherited from `golden/out/m4/regression-agent-evidence.json`.

`--reference` compares the core profile only. UI and backend normalization is
qualified through capture validation/runtime equality; their independent
expected colours, replies, netlists and displays remain checked by the accepted
M2/M3 comparators. This adapter supplements those comparators, pixel checks,
continuous invariants and eventual unified acceptance; it cannot establish
continuous atomicity or progress between frame samples. Backend terminal entries
keep protocol ordinals, since accepted UART component order is part of the
contract. All 32 active-bank voltage words are retained to preserve the existing
M3 memory check; candidate bank/storage changes may need a separately reviewed
mapping to supply that logical view. Deliberate RX corruption is validated by
the existing M3 oracle, not rejected by this adapter.

The M5-1 freeze records this schema separately from the immutable golden payloads.
An acceptance gate must pin adapter source, schema/config hashes and requested
profiles and run the independent oracles. No adapter change can silently lower
required evidence. M5-2 remains bounded to this settled frontend capture scope;
it grants no qualification for PS/2, solver RTL, CDC or arbitrary packing changes.

Resume qualification: all eight saved M4 directed captures pass independent core
RAM/state comparison (158 checkpoints); four native/Docker core-state pairs are
equal. Evidence: `golden/out/m5/adapter/m4-qualification-resume.json`. Sessions
provide integer picoseconds; the adapter converts these to milliseconds and
rejects negative, Boolean, fractional or inconsistent dual timestamps. Exact
observed times remain in each output. Cold startup times differ by runtime, so
M4 runtime parity compares core states without claiming absolute time equality.
The acceptance policy pins adapter source, schema and default configuration.
