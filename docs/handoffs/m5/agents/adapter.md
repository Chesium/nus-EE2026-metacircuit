# M5 semantic adapter agent

Assignment: implement M5-2 bounded stable semantic adapter in new
`golden/tools/semantic_adapter.py`, separate tests and `docs/m5-adapter.md`.
Parent: `docs/handoffs/m5-verification.md`. No descendants.
Own only those new files plus this handoff. Shared main checkout
`/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branch verification,
starting HEAD f894fa with preserved M4 uncommitted changes. Do not change RTL,
oracle, existing acceptance tools, contract-agent files or main evidence.

Initial live quota 2026-10-10T06:53:59Z: five-hour 26%, weekly 51%, status ok.
Root owns periodic team checks. No spawned jobs.

Current work: inspect existing M1 semantic export, M2 UI comparator and M3
backend comparator, then implement strict profile-driven normalized output.
Core golden references are saved `.state.json`/`.ram.json`. UI/backend independent
accepted comparators remain necessary because those reference values are derived
by existing TypeScript tools rather than fully persisted in those checkpoint files.

Next: implement core logical snapshots plus UI/backend normalized profile;
validate actual M4/M2/M3 captures against golden core, runtime equality and negative
controls. Document limits (settled frame checkpoints, no continuous atomicity proof).

## Completed safe checkpoint

New owned files:
- `golden/tools/semantic_adapter.py`: strict `metacircuit-semantic/v1` adapter and
  CLI. Core/UI/backend profiles; explicit probe name/encoding, memory name,
  field packing, logical address permutation and live-slot configuration.
- `golden/tools/test_semantic_adapter.py`: eight controls plus optional real
  capture qualification helper.
- `docs/m5-adapter.md`: commands, exact evidence, configuration and qualified limits.

Validation completed:
```
python3 -m unittest discover -s golden/tools -p test_semantic_adapter.py -v
python3 golden/tools/test_semantic_adapter.py --qualify \
  golden/out/m4/regression-agent-evidence.json golden/out/m5/adapter/qualification.json
```
Eight controls pass. 18 accepted final-source native/Docker M2/M3 captures /206
checkpoints pass strict adaptation and core golden reference comparison. All
nine paired normalized outputs are equal, including transaction UART times.
`golden/out/m5/adapter/m3_display.json` is an example full backend output.
No new Verilator jobs or background processes were started. No descendants.
No commits/pushes. All three source/doc files remain new untracked files.

Last personal quota read at 2026-10-10T06:58:49Z: five-hour12%, weekly49%, statusok.
Parent reports11% shortly afterward and asks for bounded docs/checkpoint only.

## Remaining work / recreation assignment

The bounded M5-2 implementation is ready for coordinator review. Preserve this
scope: settled checkpoint semantics only. `--reference` checks independent saved
core RAM/semantic golden data; UI/backend independent expected values remain the
accepted M2/M3 oracles, with normalization tested via strict validation/runtime
parity. No continuous atomicity, arbitrary split/compressed packing, PS/2, actual
solver RTL or CDC qualification is claimed. All32active voltage words are kept
because the accepted M3 checker checks those words; future bank changes need an
explicit reviewed logical view mapping.

Next concrete optional qualification: read
`golden/out/m4-lockstep/corpus-agent-summary.json`, then adapt core at each saved
reference checkpoint in per-run
`corpus-agent-{rotations,properties,boundaries}-{native,docker}-fixed` and
`corpus-agent-dense-{native,docker}-compact` under the same directory. Compare
against saved `.ram.json`/`.state.json`, record hashes/counts in adapter evidence.
This M4-specific qualification has not been run; do not claim it from M2/M3
capture results. Add schema/config/source pinning and requested profiles to the
future unified acceptance runner, retaining full independent pixel/backend
checks. No agent recreation is needed unless those follow-ups are assigned.
