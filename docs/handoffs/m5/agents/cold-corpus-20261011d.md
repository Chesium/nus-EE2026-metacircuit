# Subagent handoff: cold native v2 corpus

Updated: 2026-10-11T06:30:53.665240+00:00
State: completed; active work ended normally
Author: /root/m5_cold_corpus
Parent/main handoff: [M5](../../m5-verification.md)
Former agent ID and parent role: /root/m5_cold_corpus, parent /root; historical IDs on resume.

## Self-contained assignment for a replacement agent

The assignment is COMPLETE. No recreation/rerun needed. Remaining native cold v2 seeds7/2026/11/12 x64 operations now all pass against the unchanged reviewed `golden/out/m5-shadow-functional-source`; seed1 passed historically and was never rerun. Parent should integrate `golden/out/m5-shadow-cold-corpus-20261011d-driver/audit.json` with historical seed1 evidence, preserving individual case provenance. This evidence qualifies settled M1 canvas state only; continuous properties, other clocks/backend/full M5 readiness remain separate.

Main workspace `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branch verification, HEAD f894fa8dcb487ff02c8f671e4126cc84cf169363. Sibling harness `/home/chesium/ee2026_ws/framescope`, existing dirty work preserved; pycircuit untouched. Owned outputs only `golden/out/m5-shadow-cold-corpus-20261011d-driver`, `golden/out/m5-shadow-cold-seed{7,2026,11,12}-20261011d` and this document. No implementation/production/shared evidence/docs changed, no commit/push.

## Saved work and verification

Command `python3 golden/out/m5-shadow-cold-corpus-20261011d-driver/run.py` launched four independent groups simultaneously06:11:12Z. Each command is `python3 tools/verify_m4.py --runtime native --framescope /home/chesium/ee2026_ws/framescope --seeds SEED --generator 2 --operations 64 --out /home/chesium/ee2026_ws/nus-EE2026-metacircuit/golden/out/m5-shadow-cold-seedSEED-20261011d`, cwd `/home/chesium/ee2026_ws/nus-EE2026-metacircuit/golden/out/m5-shadow-functional-source/golden`. Budget2400s each; all completed naturally, zero exits, no timeout/signals.

| Seed | Frames | Completed checks | Driver seconds | Artifact |
|---|---:|---:|---:|---|
|7|794|65/65|1128.135|golden/out/m5-shadow-cold-seed7-20261011d|
|2026|756|65/65|1128.136|golden/out/m5-shadow-cold-seed2026-20261011d|
|11|727|65/65|1116.134|golden/out/m5-shadow-cold-seed11-20261011d|
|12|794|65/65|1086.115|golden/out/m5-shadow-cold-seed12-20261011d|

Total new3071frames/260actual comparisons. `python3 golden/out/m5-shadow-cold-corpus-20261011d-driver/audit.py` exit0 at06:30:05Z:passedtrue, no errors. Every summary/result/state-compare/report exists and passes; frame counts,65passing checkpoints, complete VGA frames and `stop_reason=frames` match. All generated v2 seed inputs exactly byte-identical historical inputs (`historical-input-matches.json`).

Actual simulator invocation/PID lineage captured during execution (`cold-processes.json`): corresponding explicit `--seed N --rand-reset 2`, no restore argument. Report initialization is `seed=N,seed_explicit=true,rand_reset=2,x_initial=unique,x_assign=unique`; manifests/build options also unique. Compiled binary reused from cache; initialized state never reused. Binary SHA97168eb2e450bd2e4e3614782007a8070f890861d96efde83de1ebb9e82f5620, cache867193ff06aa38bd.

Source172files/harness48files exactly match pins before/after. Reviewed shadow top SHA93bc76d3019d3d1e5a8949a00e32d217d934b4ece5289ec26e1421b7a2a001fb; oracle-snapshot hashes checked; Verilator5.046. Initial pin helper omitted scenario files listed in oracle-snapshot (KeyError), then corrected scope and saved complete pins seconds after launch before meaningful simulation. No source mutation occurred; final drift audit passes. Initial recursive harness snapshot also included3435cache files; generated cache/build outputs removed from source pins. These setup corrections changed output metadata only. Driver `pins-before.json`, `pins-after.json` and `audit.json` preserve exact hashes and final report digests.

## In progress, uncertainties and owned jobs

Nothing remains in this assignment. `jobs.json` records exact commands/cwd/log/output/PID/PGID/start ticks/end states. Exec session6567 ended0; driver PID815021 ended. Seed groups815023/815024/815025/815026 ended normally. `cleanup.json` verifies no members in all four owned groups and driver `/proc` absent. No signals sent, no owned containers or jobs remain. Other agents/user jobs untouched. Historical interrupted20261010c outputs are preserved and not counted as passes.

## Descendant handoffs and stopped states

No descendants spawned.

## Quota trigger and completion acknowledgement

Fresh startup06:10:16.955091Z:98%five-hour/100%weekly. Latest fresh completion06:30:06.489266Z:52%five-hour/93%weekly,ok. Resets2026-10-11T11:09:37Z /2026-10-18T06:09:37Z. Defaults document5h<10% or weekly<6%; stop5h<3% or weekly<2%; parent owned team timer. No shutdown trigger. Document path/results sent to parent; agent ends its active turn after final cleanup/handoff aggregation. No permanent termination claim.
