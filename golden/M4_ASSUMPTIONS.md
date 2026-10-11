# M4 canvas stress scope

The first M4 runner checks the existing accepted M1 semantic state comparator
at settled checkpoints after cold startup and each generated operation. It
preserves the measured one-frame input latency and two-frame checkpoint wait;
it does not redefine the accepted oracle or claim transient equivalence.

Run from `golden/` with a sibling framescope checkout containing FS-8:

```sh
npm run verify:m4 -- --seeds 1,7,2026 --operations 16 --runtime native
npm run verify:m4 -- --seeds 1 --operations 4 --coverage
npm run verify:m4 -- --case test/fixtures/m4_boot_seed1.json --runtime docker
```

`--coverage` additionally requires FS-11 and validates boot/scenario coverage
artifacts and their hashes. Coverage starts at frame 3. Every simulation starts
with `x_initial = "unique"`, `x_assign = "unique"`, a recorded positive seed,
and random reset mode 2; checkpoints are never requested. The default corpus
is seeds 1, 7 and 2026, with 16 operations per seed. The operation count is an
explicit runtime budget; this corpus is exploratory, not M5 acceptance.

The version-1 generator uses pinned xorshift32 and emits ordinary replayable
scenario JSON plus operation blocks. It mixes canvas tools, visible edges,
boot-circuit collisions and held clicks. `--reduce-runs N` enables bounded
single-block deletion after failure, keeps the first difference class and
requires a separate cold replay. It may stop before reaching a minimal case;
the report states attempts, remaining blocks and reproduction status. Use
`--case path/to/reduced.json` to replay a saved case.

The output directory contains the exact inputs, golden references, stimulus,
RTL reports and RAM dumps, state comparison, first failing checkpoint with a
frame/probe window, initialization provenance and summary. The first version
finishes a batch run before reporting the first divergent checkpoint; the
persistent session client is a separate first-divergence stopping path.

Named functional bins count only states verified by passing RTL checkpoints:
tool selection, component kind/rotation, units and property-memory edits, all
four logical edges, empty/full/dense canvas, rejected placements and held inputs.
Every reached bin records its first passing checkpoint and frame. Edit bins
need consecutive verified endpoints; physical slot reuse additionally uses live
RTL component-store dumps. Input bins require visible canvas clicks. Partner
input and property-memory checks do not qualify panel selection or pixels.

The v1 and v2 seeded generators remain byte-stable. Directed cases supplement
random exploration with rotations, properties, boundaries and dense occupancy:

```sh
npm run stress -- --seed 2026 --directed rotations --out out/rotations.json
python3 tools/lockstep_m4.py --case out/rotations.json --runtime native --out out/rotations-rtl
python3 tools/functional_m4.py out/rotations-rtl --out out/functional-union.json
```

Other directed names are `properties`, `boundaries` and `dense`. Dense occupancy
means at least 144 of 288 logical cells; full occupancy is all 288 cells (144
two-cell components). The 288-slot physical component store cannot be exhausted
by legal two-cell placements on this canvas. Reports distinguish this exclusion
from a verified rejection at full canvas occupancy. Unreached bins remain visible.
`functional_m4.py` recalculates compatible bin reports from complete passing cold
sessions and rejects missing checkpoints, failed runs or incorrect initialization.

UART races, malformed packets, memory stalls, exact transient timing, continuous
invariants, real solver RTL and device-level PS/2 remain M5/FS-10 work. M4 does
not establish broad refactor readiness; M2 pixel checks remain separate regressions.

## First seeded failure

Cold seed 1 at frame 2 found mismatched mirrored cells and random shadow values
at addresses 1 and 2. `GlobalRender_top` configured mouse limits on those two
initialization cycles through exclusive branches, skipping their RAM clear.
The reducer removed all input operations and a separate three-frame cold run
reproduced the failure. The retained case is
`test/fixtures/m4_boot_seed1.json`. Mouse-limit setup now runs alongside the
clear loop, preserving its pulse timing while clearing every logical cell.

## Wire reselection failure

The 64-operation v2 seed 12 diverged at frame 617 when returning to the wire
tool. Accepted A-007 preserves its previous variant; `ToolbarVGA` reset it to
plain wire. The separate original cold replay reproduced the same differences
and word-identical dumps for all six memories. A four-tool-click, 23-frame
regression is retained in `test/fixtures/m4_wire_reselection_seed12.json`.
The RTL now retains the variant when returning from another tool; the accepted
golden and its existing A-007 test remain unchanged.
