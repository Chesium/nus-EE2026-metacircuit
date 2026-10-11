# M5 contract agent handoff

Assignment: freeze accepted frontend oracle, visual payloads, scenario corpus,
masks, constraints, limitations and corrected M4 baseline source provenance.
Own golden/verification/contracts/frontend-v1/, golden/tools/freeze_contract.py,
golden/tools/test_freeze_contract.py and docs/m5-contract.md only. Parent owns
main M5 handoff, verification plan and evidence. No descendants or jobs.

Workspace /home/chesium/ee2026_ws/nus-EE2026-metacircuit, branch verification,
HEAD f894fa8dcb487ff02c8f671e4126cc84cf169363, dirty M4 changes preserved.
Sibling framescope m1-harness HEAD de04a24; simpyhls 0d6f22a.

Startup quota 2026-10-10T06:53:48Z: five-hour 27%, weekly 51%, status ok.
Default guard thresholds apply; root owns team timer and watcher.

Current checkpoint: inspected M5-1 requirements, accepted M1-M4 assumptions,
M4 evidence source hashes, source tree and latency/mask definitions. Contract
layout shared with adapter agent. No implementation files written yet.

Next step: implement freezer and strict verifier, capture immutable inputs with
content hashes plus accepted corrected source snapshot/provenance, add corruption
tests, run bounded unittest suite, and send parent reviewable results. Internal
progress bounds remain unspecified and must not be invented from settled waits.

## Completed checkpoint

Implemented golden/tools/freeze_contract.py and ten mutation tests in
`golden/tools/test_freeze_contract.py`; documented behavior in docs/m5-contract.md.
Frozen frontend-v1 stores 254 entries (~4MB) including accepted TypeScript oracle,
visual JSON, masks, assumptions, fixed M1/M2/M3 scenarios, M4 reduced fixtures,
12 saved seeded/directed M4 cases, dependencies, existing verification runners,
XDC/Tcl, actual corrected RTL and accepted harness source/manifest/evidence.

Contract identity:
`475a48362f0f353104abfde654c25f7bdc60acc266c7a774ca6b256d315b540e`.
Location golden/verification/contracts/frontend-v1/contract.json and neighboring
contract.sha256. Parent gate should pass this trusted identity with
`--expected-contract-sha256`; local lock alone cannot resist rewriting both files.
Candidate RTL changes allowed; current oracle/constraints inventory and all frozen
bytes remain mandatory. Asset provenance-only updates ignored semantically;
bitmap/font/palette/layout updates fail. Freezer refuses existing target.

Validation 2026-10-10T06:58Z:
- `python3 golden/tools/freeze_contract.py verify` passes.
- `PYTHONPATH=golden/tools python3 -m unittest golden/tools/test_freeze_contract.py -v`
  all ten pass, 0.660s. Negative controls cover oracle/masks/scenarios/pixels,
  frozen baseline/corpus, weakened constraints, missing/added mandatory files,
  external identity against rewritten manifest+lock and path traversal.
- Candidate RTL mutation test verifies reference remains fixed.

Last live quota 2026-10-10T06:58:03Z status ok: five-hour14%, weekly49%.
No background jobs or descendants. All owned edits uncommitted; no commits/pushes.

## Remaining / exact next step

Root integrates contract identity/check command into M5 evidence and acceptance
entry point. M5-2 adapter schema metacircuit-semantic/v1 agreed with adapter
agent; actual adapter implementation/config acceptance hashes are separate evidence.
Internal cycle progress bounds explicitly null/unqualified (M5-4 remains), exact
N+1 frontend latency and phase/rotation constants pinned. Frozen M4 wait scheduling
is not an invented progress bound. Solver pipeline/PS2/CDC/stalls/Vivado readiness
is not claimed. Baseline source snapshots are corrected dirty M4, with historical
plan2ff7f3a and simpyhls0d6f22a recorded; no old-baseline pass claimed.

If root adds package scripts, package.json is frozen mandatory and verifier will
correctly report drift. Decide a reviewed metadata-only allowance rather than
silently regenerate this reference. Root should inspect docs/m5-contract.md and
contract manifest, run the two validation commands above, and record scoped
foundation status. Recreate this agent only for unfinished contract integration
or separately authorized contract version changes; baseline freeze implementation
is complete. Parent main handoff docs/handoffs/m5-verification.md.

Final bounded reporting refinement: verify emits contract_sha256, checked_entries
and provenance_changes (raw frozen/current asset hashes) so permissible extractor
metadata drift remains visible in acceptance evidence. Repeated ten-test suite
passes0.612s; trusted-identity verification passes254 entries with zero drift.
