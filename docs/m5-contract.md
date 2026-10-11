# Frozen frontend contract (M5-1 foundation)

`golden/verification/contracts/frontend-v1/contract.json` records the accepted
M1–M4 frontend oracle, input scope, exact observable timing, known exclusions,
and all frozen input hashes. Its neighboring `contract.sha256` identifies this
contract; an acceptance runner must also supply that identity from a trusted
baseline configuration with `--expected-contract-sha256`. Replacing both the
manifest and its local lock is detected by this external identity.

The original M5 plan starts at metacircuit `2ff7f3a`, simpyhls `0d6f22a`, and the
framescope commit in M3 evidence. The accepted baseline here uses the corrected
M4 working-tree contents at metacircuit HEAD `f894fa8`, rather than pretending
the historical commit passes the retained startup and A-007 regressions.
Startup now clears cells 1/2 alongside mouse-limit setup; returning to the wire
tool preserves its selected variant. The golden behavior remained accepted and
unchanged in those decisions. Exact source bytes, M3/M4 evidence, framescope
source and harness manifests are retained with their hashes for baseline replay.
The recorded dirty status is intentional; commit IDs alone cannot reproduce it.

Run from the repository root:

```sh
python3 golden/tools/freeze_contract.py verify
PYTHONPATH=golden/tools python3 -m unittest golden/tools/test_freeze_contract.py -v
```

`verify` fails for missing or changed frozen payloads, mandatory working oracle
inputs, masks, scenarios, dependency declarations, fixed constraints, or changed
input inventory. New oracle files cannot silently escape the manifest. The
visual behavior hash excludes only the top-level asset `source` provenance;
bitmap, font, palette, layout, schema and every other field stay pinned. Asset
provenance updates can therefore describe a candidate without changing expected
pixels. Frozen payload files themselves remain byte-exact. Candidate RTL is
allowed to change; its hashes must appear in fresh functional/QoR evidence.
Candidate-derived extraction never overwrites the contract's reference copies.

The copy under `payloads/golden/` preserves relative TypeScript imports, assets,
scenarios, dependency declarations and existing regression runners, so future
gate tooling can run the frozen oracle independently of candidate source.
Saved M4 generated scenarios are retained inside the contract; verification
does not depend on the ignored original `golden/out/` files remaining available.
The freezer refuses an existing directory. Creating another accepted contract
requires an explicit versioned baseline operation, rather than the candidate
gate regenerating expected behavior.

Input changes on line 10 in frame N have their specified frontend effect in
frame N+1. `m1_latency.json` checks each frame without settlement padding.
Rotation holdoff is eight frames, flow phase steps every two frames, and the
caret toggles every ten frames. M4's two additional checkpoint-wait frames are
settled test scheduling, and do not define a cycle-level progress bound. Existing
M3 codec/comparator behavior preserves ordered netlists, content snapshot ids,
reply rejection/commit, UART aborts and display behavior. Arbitrary memory stalls,
backend internal progress bounds and permitted internal retiming are not yet
specified or qualified; M5-4 must establish those independently.

This contract qualifies the existing frontend fixed regressions and settled
seeded exploration, with a 640×480 screen and 18×16 logical grid. It excludes
real PS/2, real solver/FP IP datapaths, physical-board validation, continuous
atomicity/progress under stalls and transient flooding pixels. Full-grid capacity
is exercised, but legal placements can occupy only 144 two-cell components,
so physical exhaustion of the 288-entry component store is excluded. Semantic
adapter validation, full M5 stress/progress scope, solver qualification, measured
FPGA characterization and the unified gate remain separate required evidence.
Adding this freeze alone does not establish M5 readiness.
