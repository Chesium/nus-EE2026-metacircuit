# M5 Vivado assignment handoff

- Owner: `/root/m5_vivado`; no descendants.
- Parent: `docs/handoffs/m5-verification.md`.
- Workspace: `/home/chesium/ee2026_ws/nus-EE2026-metacircuit`, branch `verification`, starting HEAD `f894fa` with pre-existing M4 changes.
- Owned files: new `tools/vivado_qor.py`, `tools/vivado_qor.tcl`, `tools/tests/test_vivado_qor.py`, `docs/m5-vivado.md`, this handoff only.
- Task: reproducible Basys 3 GlobalRender_top synthesis/routed measurements, explicit source/IP/constraint/tool provenance, strict missing-evidence/report corruption checks; actual isolated baseline attempt. SolverBoard_top excluded until separately qualified.
- Quota: fresh 2026-10-10 06:54:16 UTC check: five-hour 24%, resets 11:24:08 UTC; weekly 51%, resets 2026-10-14 15:27:22 UTC. Default strict thresholds document <10%/<6%, stop <3%/<2%; root owns team timer.
- Inspection: metacircuit.tcl has correct GlobalRender_top, real Mouse_Control/Ps2Interface/MouseDisplay VHDL and src/ip XCI; metacircuit-2025.2.tcl instead uses CircuitCanvas_top. Basys3.xdc is enabled; solver constraints disabled in that original project.
- Current operation: writing runner; no background jobs yet.
- Next: test parser/missing evidence mutations, launch isolated Vivado baseline, collect evidence without changing constraints or source RTL.

## Checkpoint 2026-10-10 06:59 UTC

Implemented `tools/vivado_qor.py`, `tools/vivado_qor.tcl`, `tools/tests/test_vivado_qor.py` and `docs/m5-vivado.md`. Eight unit tests pass (`python3 -m unittest discover -s tools/tests -v`), including missing/truncated evidence, numeric utilization corruption, removed DCP, stale source/constraint hashes, and stale output reuse. Python compile checks pass. Tcl real tool execution reads proper VHDL/XCI, enters synthesis; final report API/format integration remains unverified.

Real development invocation: `python3 tools/vivado_qor.py --out golden/out/qor/m5-baseline --stage routed`. Session `19714`, owned process group `1509690`, Python PID `1509690`, Vivado main `1509794`; synthesis children share this group. Tool version `Vivado v2025.2`, SW Build `6299465`, IP Build `6300035`. The original XCI is accepted without automatic upgrade. Synthesis reached timing optimization, not yet a finalized synthesis/route checkpoint. Existing source/IP/constraints were not changed by this agent. The first invocation's Tcl ran with repository cwd; subsequent frozen invocations use output cwd. First invocation was launched before final parser/artifact capture/job-cancellation edits, so runner/Tcl provenance is stale and it cannot qualify readiness, even if later synthesis finishes. Preserve all partial logs; do not invent missing metrics.

Latest fresh quota 06:58:48 UTC: five-hour 12%, reset 11:24:08 UTC; weekly 49%, reset 2026-10-14 15:27:22 UTC. Root notified. No descendants.

Replacement assignment: inspect actual stopped/job state and retained output; run tests, then launch final runner in a NEW empty `golden/out/qor/baseline-final` directory. Verify actual report formats and adjust parsers with real fixtures only as needed; rerun frozen provenance after code changes. Complete frontend synth/route characterization, parse hierarchical resources/CDC categories if needed, review missing I/O/generated clocks and DRC findings without weakening constraints. Leave SolverBoard excluded until independent correct manifest/primitive qualification. Current artifact summary marks unresolved CDC/DRC as requires review and `timing_clean=false`; no FPGA acceptance claimed. Do not change accepted RTL or constraints while obtaining baseline.

## Final quota shutdown checkpoint 2026-10-10 07:00 UTC

**State: documented and active work ended.** Quota check 06:59:39 UTC returned exit10/document: five-hour **9%**, weekly **48%**, resets as above. Root immediately notified; latched team shutdown observed. No new implementation/test batch was launched after this trigger.

Owned job group `1509690` received SIGTERM after verifying `/proc/1509690/cmdline` was our Python runner and its PGID matched. Session `19714` ended exit143. Process check shows only Vivado zombie PID `1509794` (PPID1), no active workers; no user jobs signaled. `synth.dcp` was being written at shutdown, therefore its integrity is unverified. No `synth.complete`, synthesis reports or routed evidence exist. Saved manual `run.json` interruption record, `artifacts.json` hashes and parsed `summary.json`: **incomplete**, stale runner/Tcl hashes plus missing mandatory artifacts. Logs/IP status/manifest/tool settings are preserved in `golden/out/qor/m5-baseline`. No readiness/timing pass claimed.

Critical actual-run discovery supersedes the earlier statement that original IP was usable: all 3 original 2018.2 Floating-point7.1 rev6 XCI are locked against 2025.2 rev21. `report_ip_status` explicitly recommends upgrade; none performed. IP generation produced ERROR no HDL sources/open design and CRITICAL WARNING uncustomized BOM. `synth_ip` is unsupported in project mode, though tool continued top synthesis. Licensing did succeed. **Runner is reviewable partial infrastructure, not yet usable acceptance evidence.** Next implementation must enforce fail-fast locked-IP errors, use correct project-mode IP synthesis, and reject logged ERROR even if Tcl returns0. Prefer audit of frontend-reachable sources/IP over treating unrelated solver IP as mandatory; any IP upgrade requires explicit separate provenance/behavior qualification, not automatic weakening. Root notified.

Eight unit tests last passed before quota trigger; report API and parser integration with real complete reports remains unverified. Current parser keeps CDC/DRC review unresolved, and hierarchical utilization is linked rather than parsed per module. No descendants. Replacement should read this handoff and `docs/m5-vivado.md`, run fresh live quota, inspect working tree, address the listed runner deficiencies, then perform frozen empty-directory synthesis+routed baseline. No commits/pushes made; preserve other agents' and pre-existing changes.
