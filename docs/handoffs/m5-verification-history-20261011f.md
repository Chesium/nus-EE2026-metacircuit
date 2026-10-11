# M5 verification handoff

Updated: 2026-10-11T13:49:47.930045+00:00
State: paused for quota; M5 incomplete; all owned jobs stopped

## Objective and constraints
Complete M5 in docs/verification-plan.md under codex-usage-guard defaults. Preserve frozen frontend-v1 behavior and pre-existing dirty work. No commit/push or subagents requested/used this continuation. Prior coordinating handoff and historical team documents: [startup](m5-verification-history-20261011e-start.md). This run's detailed commands, failed attempts and checkpoints: [progress](m5-verification-history-20261011e-progress.md). Completed old teams remain historical, not active.

## Workspace and saved work
Main /home/chesium/ee2026_ws/nus-EE2026-metacircuit, verification HEAD f894fa8dcb487ff02c8f671e4126cc84cf169363; all work uncommitted. Sibling framescope/pycircuit and simpyhls untouched. Existing shadow normalization, FIFO wrap, panel default, FMA exception port and SolverBoard capacity guard preserved. This continuation integrates A009/A010: distinct/declared-range reply nodes and full-width32node display count comparisons. CurrentTopSHA9b7e4d062a06142994d828d49c45feba8893fe32af7e489745f84458b82667e9. Prior top93bc76...saved in golden/out/m5-reply-integrity-20261011e/production-top-before-integration.v. Epoch matrix stores and productionXDC unchanged; known epoch alias persists.

New persistent bench src/testbench/M5ReplyIntegrity_test.sv; tools formal_witness_m5.py and verify_{flood_queue_order,guard_progress,component_progress,reply_parser,reply_banks,reply_integrity}_m5.py. Acceptance runner/policy adds six source-pinned mandatory proof/serial reports to fast/full modes; historical baseline mode preserved. Tests17PASS. Asset source provenance regenerated only, all254frozenbehavior entriesverify. Do not edit source/tools/policy/bench/assets while current pinned cold jobs run.

## Completed and verified
- Before reply correction: fresh fullM3 both482frames/42checks, allframe CRC/probes/timestamps/UART/hostlogs/504RAMdumpbytes crossruntime exact; fivecoldv2x64 both3784/325 and fourdirected both973/79, independentlyrecomputed64/64functional bins. Older source only; never transfer these verdicts to newTop.
- New reply correction: cold real115200RsRx exposes duplicate VN and declared-range VN falselycommitting baseline BOTH; missing-node end alreadyrejects. PhysicalBTNR exposes32count truncation BOTH. Unchanged golden decoder rejects actual bad byte streams. Corrections pass elevenfixtures/101lines, all32words/31next selections/nonwrap/selectionretention, reversed order/recovery/empty plus observationcorruption onbothruntimes.
- Exact isolated full-src newTop passes fullM2/M3 both780frames/103checks plus fivev2x4 coldsmoke245/25 each. Final-audit.json checks initialization/source/oracle/masks/harness and exactonlyTopdesign diff; source thenintegratedbyteexact. First pixel-mask-copy omission and explicitchecker capacity-packetcount mistake preserved and repaired as harnessmetadata defects, never relabeledfailedsimulation.
- Fresh currentmain fastgates PASS14checks eachruntime, readyfalse; inventories/source/helper/bench/assets stable, framescope135tests/7skips. Reports golden/out/m5-acceptance/reply-integrity-{native,docker}-20261011e/summary.json. Six new mandatory scoped reports actually execute on main.
- Actual current default115200/vendorFP frontend PASS bootframe3/duplicatestable5/editedsplitrail12, coldCORRUPT_FRONTEND caught, source/libraryfinaldrift empty. Report m5-solver-frontend-xsim/reply-integrity-production-qualified-20261011e/report.json. Initial attempt used olderFPhelperpin and failedpreflight withoutsimulation; retained. No solver arithmetic edit or physical-board claim.
- Maintained FIFO watched-transaction order/rank/payload depths1/3/4/1152 with exact-source single-cell memory projection, negative and reachablecovers; guardconditional11/29/61clocks under recordedfairness, phase/ranking lemmas/negative/stallcovers; actualcomponentrebuild quiescent1744clock bound/maxpotential1733 with arbitraryscan predicates and restartcover. Parser dispatch/range/reset/output proof overapproximates independentlyarbitrary purehelperreturns; unabstracted parser timeout notPASS. Receiver mask/count/inactivebank/complete-currentcommit control proof under separatelyprovedparser constraints.
- Additional artifact payload proof PASS arbitrarywatchednode0..31 usingactualSimpleRam cellprojections, pendingregisteredwrite/staged32bitword/primarycachedvalue; bitcorruptioncounterexample. Report m5-reply-payload-20261011e/report.json. Notmaintained/gate-required yet; physicalRAM/read-refresh/arbitraryUI-replyoverlap outside scope.
- New main raw11frame/2check captures BOTH and explicitcurrent-root scenario/boot auditPASSintegrity/readyfalse, nominal8/64functional bins each; noold-source merges. Reports m5-post-reply-coverage-control-20261011e/audits.json. Old7reports properlyfailstalesource audit afterintegration. Gaps/reviews/exclusions unchanged.

## FPGA decisions and remaining risks
All measurements strict75inputs/related10/40ns clocks in isolatedXDC. ProductionXDC unchanged; every result remains unqualified for global100MHz/externalIO/CDC/fullreadiness.
- Reply correction scoped objectivePASS10149LUT/4197FF/10BRAM/0DSP, setup-1.953/hold+0.027, internalunknown0/0. Correctness tradeoff +57LUT/+40FF/+0.5BRAM/-0.620setup vs current-before; notareaoptimization.
- Selectedaddress capture exactcone proofPASS, route-2.547 rejects frozen-1.0target.
- Valid-only epoch correction full86123clock ledger+watched-value proofsPASS, route-2.040 fails strict-2.0floor despite1BRAMsaving; rejected.
- Row-valid decoder restructuring ledger/proofsPASS, route-2.726 fails samefloor; rejected.
- Balancedunit last-match decoder all2^64text/16length comb equivalencePASS+XORcounterexample, route10284LUT/4194FF/9.5BRAM, setup-2.580/hold+0.011 fails frozen-1.5target. Rejected/unintegrated. Firstnegativeclassifier under-verify didnotprintmodel; explicitnonverify replay retainedactualSAT model and oldclassifiererror.
All candidate roots/reports under golden/out/qor; comparisons preserve objectives/rejections. No failedfloor relaxed and no rejected proposal integrated.

Full M5 remains incomplete: global setup/reset/externalIO/CDC, complete current-source functional/counter reachability coverage and review, broad atomic/progress assumptions, actual original-XCI synthesis and ill-conditioned numericalaccuracy. Epoch alias stillpresent. No physicalboard or generalfourstate/arbitraryparameter theorem. No new approval required.

## Current operation / resume here
Only active jobs are fresh post-correction fivecoldv2x64 NONinstrumented main RTL corpora. Each runtime9000s budget. Source/tool/harness/oracle/masks/bench/policy pins at golden/out/m5-post-reply-cold-corpora-20261011e/pins.json. Inspect actual process identity before signals; all other gates/XSim/Vivado/proofs/raw jobs completed. No ownedagents or descendants. Verify cleanup by output roots, not reused numericalPIDs.

```json
{
  "native": {
    "driver_pid": 1978493,
    "active_pgid": 1978495,
    "command": [
      "python3",
      "/home/chesium/ee2026_ws/nus-EE2026-metacircuit/golden/tools/verify_m4.py",
      "--runtime",
      "native",
      "--framescope",
      "/home/chesium/ee2026_ws/framescope",
      "--seeds",
      "1,7,2026,11,12",
      "--operations",
      "64",
      "--generator",
      "2",
      "--out",
      "/home/chesium/ee2026_ws/nus-EE2026-metacircuit/golden/out/m5-post-reply-cold-corpora-20261011e/m4-native/corpus"
    ],
    "started_at_utc": "2026-10-11T13:17:36.316461+00:00",
    "budget_seconds": 9000,
    "completed_cases": [
      {
        "seed": 1,
        "frames": 713,
        "checks": {
          "checkpoints": 65,
          "passed": 65,
          "failed": 0
        }
      },
      {
        "seed": 7,
        "frames": 794,
        "checks": {
          "checkpoints": 65,
          "passed": 65,
          "failed": 0
        }
      },
      {
        "seed": 2026,
        "frames": 756,
        "checks": {
          "checkpoints": 65,
          "passed": 65,
          "failed": 0
        }
      }
    ]
  },
  "docker": {
    "driver_pid": 1978492,
    "active_pgid": 1978494,
    "command": [
      "python3",
      "/home/chesium/ee2026_ws/nus-EE2026-metacircuit/golden/tools/verify_m4.py",
      "--runtime",
      "docker",
      "--framescope",
      "/home/chesium/ee2026_ws/framescope",
      "--seeds",
      "1,7,2026,11,12",
      "--operations",
      "64",
      "--generator",
      "2",
      "--out",
      "/home/chesium/ee2026_ws/nus-EE2026-metacircuit/golden/out/m5-post-reply-cold-corpora-20261011e/m4-docker/corpus"
    ],
    "started_at_utc": "2026-10-11T13:17:36.309134+00:00",
    "budget_seconds": 9000,
    "completed_cases": [
      {
        "seed": 1,
        "frames": 713,
        "checks": {
          "checkpoints": 65,
          "passed": 65,
          "failed": 0
        }
      },
      {
        "seed": 7,
        "frames": 794,
        "checks": {
          "checkpoints": 65,
          "passed": 65,
          "failed": 0
        }
      }
    ]
  }
}
```

Native session75010/Docker13582; driver logs/results/job/containers metadata under m4-{runtime}. Completed cases are eligible individually, but no full fivecase verdict until all5/initialization/pinsfinal. Do not relabel partial/failed/interrupted cases. At quota stop, signal only verifiedowneddriver (its handler stops ownactive group and mount-matched containers), inspect noownedsimulators/CIDs remain and preserve incompletecaptures. Main ends active work last.

Next concrete steps: freshlivequota check; inspect new5cold jobs/results; audit completecurrentcases and allpins, then update docs/m5-verification.json and coverage/handoff. Current post-correction64functional/native+Docker broaderraw scopes stillneedownsource evidence. Maintain/integrate payload theorem after pinned jobs end, with newhelper/gate negatives/currentpins andfreshgates if changed. Further timing/epoch correction proposals must predeclare objective and keep rejected thresholds/source scopes intact.

## Quota policy
Default strict document five-hour<10% OR weekly<6%; stop five-hour<3% OR weekly<2%. Solo<=300s, documentation<=60s; no subagents. Latest successful livecheck13:45:44.383426Z16%five-hour/72%weeklyOK; resets2026-10-11T16:11:45Z /2026-10-18T06:09:37Z. At stop/unavailable no new substantive work; write checkpoint and end active turn. Fresh checkmandatory on resume; cached checks/reset alone do not authorize automatic restart.

## Documentation-mode checkpoint
Latestlive2026-10-11T13:56:50.871359Z9%five-hour/71%weeklyDOCUMENT/exit10. Defaultsolo requiresboundedcheckpointwork and<=60s livechecks now; no newbroadphase. Bothcurrentpostreply coldcorpora havecompletepassing1/7/2026cases (2263frames/195checks EACH);11and12notfinal. All currentSRC/bench/policy/asset helpers remainfrozen. Only twoowned drivers/mainCLI/simulator groups remain. Completed-case checkpoint document-checkpoint.json preserves scopes. Finalaggregate/results/source checks pending; quotaStop<3orweekly<2 stops ownverifieddrivers/CIDs, documents and ends activework.

## Boundeddocumentation checkpoint14:01UTC
Live7%five-hour/71%weeklyDOCUMENT. Completedcurrentcold source-specific cases: [{"runtime": "native", "seed": 1, "frames": 713, "checks": 65, "report": "/home/chesium/ee2026_ws/nus-EE2026-metacircuit/golden/out/m5-post-reply-cold-corpora-20261011e/m4-native/corpus/case-0/result.json"}, {"runtime": "native", "seed": 7, "frames": 794, "checks": 65, "report": "/home/chesium/ee2026_ws/nus-EE2026-metacircuit/golden/out/m5-post-reply-cold-corpora-20261011e/m4-native/corpus/case-1/result.json"}, {"runtime": "native", "seed": 2026, "frames": 756, "checks": 65, "report": "/home/chesium/ee2026_ws/nus-EE2026-metacircuit/golden/out/m5-post-reply-cold-corpora-20261011e/m4-native/corpus/case-2/result.json"}, {"runtime": "native", "seed": 11, "frames": 727, "checks": 65, "report": "/home/chesium/ee2026_ws/nus-EE2026-metacircuit/golden/out/m5-post-reply-cold-corpora-20261011e/m4-native/corpus/case-3/result.json"}, {"runtime": "docker", "seed": 1, "frames": 713, "checks": 65, "report": "/home/chesium/ee2026_ws/nus-EE2026-metacircuit/golden/out/m5-post-reply-cold-corpora-20261011e/m4-docker/corpus/case-0/result.json"}, {"runtime": "docker", "seed": 7, "frames": 794, "checks": 65, "report": "/home/chesium/ee2026_ws/nus-EE2026-metacircuit/golden/out/m5-post-reply-cold-corpora-20261011e/m4-docker/corpus/case-1/result.json"}, {"runtime": "docker", "seed": 2026, "frames": 756, "checks": 65, "report": "/home/chesium/ee2026_ws/nus-EE2026-metacircuit/golden/out/m5-post-reply-cold-corpora-20261011e/m4-docker/corpus/case-2/result.json"}]. Nativecurrentcase12/Dockercurrentcase11active; no fivecaseaggregate verdict. Source/helper/policy/asset/bench remainfrozen. Onlyverifiedowneddrivernative1978493/group1978495 andDocker1978492/group1978494 plus mount-matchedDockerCID inrecorded containers.json remain; inspectfreshidentitybeforesignals. Allotherjobsended. Documentationchecks<=60s.

## Authoritative final quota stop and resume checkpoint
Latest live check2026-10-11T14:05:56.036063Z STOP/exit20:2%five-hour/70%weekly. Default strictfive-hour<3% triggersstop. Main ownedjobs/containers stopped and independentlyverified absent; noagents/descendants. Cleanup golden/out/m5-post-reply-cold-corpora-20261011e/quota-cleanup.json recordscommands/PIDidentity, initialSIGTERM, mount-matchedDockerCID andremovedstatus. Do notsignalhistoricalPIDs. Gitchangesalluncommitted; no commit/push/daemon/unrelatedprocess action.

Current post-correction FOURcompletecoldv2x64seeds1/7/2026/11 PASS2990frames/260checks EACHruntime on currentTop9b7e4...; everycapturedsource/helper/oracle/asset/policy/bench/harness pinreadbackstable. Native/Dockerseed12case-4 captures incomplete andexcluded. Bothwhole-driver summariesfalse/interrupted (expected), never fullfivecasePASS. Before-correction fivecase3784/325 and64bin verdicts remainoldsourceonly. Actual currentfullM2/M3,245/25coldsmoke,14checkgates,realserial32node/primitives,actualvendorFPfrontend/scopedQor/proofs PASS recordedabove; fullM5remainsfalse.

Next concrete step afterfreshlivequota/state check: rerun ONLYseed12x64 coldcase onnativeandDocker against unchangedcurrentmain, using fresh outputdirectories. Existing seeds1/7/2026/11 mustnotbererun/importedwithouttheir actualsource/hash/init/result audit. Example:

```sh
python3 golden/tools/verify_m4.py --runtime native --framescope /home/chesium/ee2026_ws/framescope --seeds 12 --generator 2 --operations 64 --out golden/out/m5-post-reply-seed12-native-resume
python3 golden/tools/verify_m4.py --runtime docker --framescope /home/chesium/ee2026_ws/framescope --seeds 12 --generator 2 --operations 64 --out golden/out/m5-post-reply-seed12-docker-resume
```

Pin currentSrc/tools/helpers/masks/harness/init andpreservecompletecase audit beforecombining. Then maintain/gate-integrate payloadtheorem, current64bin/broaderrawsource scope andremainingglobaltiming/IO/CDC/epoch/originalIP/numericalwork. Allisolatedtiming/epochproposals rejected/unintegrated exceptacceptedA009/A010correctnesscorrection; balancedunitlastmatch SourceRoot remainsisolated afterfloor-1.5FAIL(-2.580). No unfinished testpromoted, no fullreadinessclaim.

Quota reset alone isnotpermissionforautomaticrestart. Fresh checkmandatory whenuserresumes. Applicable skillinstruction: "Stop new substantive work, finish only the safe checkpoint/handoff, report and end the turn."
