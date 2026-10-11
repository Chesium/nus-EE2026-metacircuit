#!/usr/bin/env python3
"""Create a new accepted frontend contract, or verify its immutable inputs.

Freezing is an explicit baseline operation. It refuses to replace an existing
contract; candidate acceptance uses verify and never regenerates references.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
from pathlib import Path
import subprocess
import sys

REPO = Path(__file__).resolve().parents[2]
DEFAULT_CONTRACT = REPO / "golden/verification/contracts/frontend-v1"
GROUP_GLOBS = {
    "oracle": ["golden/src/core/*.ts", "golden/src/backend/*.ts", "golden/src/render/*.ts",
               "golden/src/scenario/*.ts", "golden/src/cli/*.ts"],
    "visual": ["golden/assets/*.json"],
    "scenarios": ["golden/scenarios/*.json", "golden/test/fixtures/m4*.json"],
    "masks": ["golden/masks/*.toml"],
    "constraints": ["src/constraint/*.xdc"],
    "assumptions": ["golden/*ASSUMPTIONS.md", "golden/INTERFACE_FACTS.md"],
}
FIXED_INPUTS = {
    "dependencies": ["golden/package.json", "golden/package-lock.json", "golden/tsconfig.json"],
    "comparators": ["golden/tools/verify_m1.py", "golden/tools/verify_m2.py",
                    "golden/tools/verify_m3.py", "golden/tools/verify_m4.py",
                    "golden/tools/lockstep_m4.py", "golden/tools/functional_m4.py"],
    "implementation_settings": ["metacircuit-2025.2.tcl", "metacircuit.tcl", "solver_board_synth.tcl"],
}
SAVED_CASES = [
    *[f"golden/out/m4-lockstep/cases16/seed-{seed}.json" for seed in (1, 7, 2026)],
    *[f"golden/out/m4-lockstep/cases16-v2/seed-{seed}.json" for seed in (1, 7, 2026)],
    *[f"golden/out/m4-lockstep/cases64-v2/seed-{seed}.json" for seed in (11, 12)],
    *[f"golden/out/m4-lockstep/corpus-agent-cases/{name}-2026.json"
      for name in ("rotations", "properties", "boundaries")],
    "golden/out/m4-lockstep/corpus-agent-cases/dense-2026-compact.json",
]


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def canonical(data: object) -> bytes:
    return (json.dumps(data, sort_keys=True, separators=(",", ":")) + "\n").encode()


def behavior_bytes(data: bytes, group: str) -> bytes:
    if group != "visual":
        return data
    asset = json.loads(data)
    # Only extractor provenance is dispensable. Bitmap/layout/palette/schema
    # changes, including added keys, remain behavior changes.
    asset.pop("source", None)
    return canonical(asset)


def git(repo: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(repo), *args], text=True).strip()


def inputs(repo: Path) -> dict[str, list[str]]:
    groups = {}
    for group, patterns in GROUP_GLOBS.items():
        groups[group] = sorted({str(path.relative_to(repo)) for pattern in patterns
                                for path in repo.glob(pattern) if path.is_file()})
        if not groups[group]:
            raise ValueError(f"mandatory input group empty: {group}")
    groups.update(FIXED_INPUTS)
    for group, paths in groups.items():
        for path in paths:
            if not (repo / path).is_file():
                raise ValueError(f"missing mandatory {group} input: {path}")
    return groups


def safe_path(root: Path, name: str) -> Path:
    path = root / name
    if Path(name).is_absolute() or ".." in Path(name).parts or not path.resolve().is_relative_to(root.resolve()):
        raise ValueError(f"unsafe contract path: {name}")
    return path


def freeze(repo: Path, target: Path, framescope: Path) -> dict:
    if target.exists():
        raise ValueError(f"contract already exists; choose a new version: {target}")
    groups = inputs(repo)
    m4 = json.loads((repo / "docs/m4-verification.json").read_text())
    if m4.get("remaining") != [] or m4.get("status") != "complete":
        raise ValueError("M4 evidence does not record completed qualification")
    for name, expected in m4["source_hashes"].items():
        if sha((repo / name).read_bytes()) != expected:
            raise ValueError(f"accepted M4 source is stale: {name}")
    m3 = json.loads((repo / "docs/m3-verification.json").read_text())
    contract = {
        "schema": "metacircuit-frozen-contract/v1",
        "name": "frontend-v1",
        "created_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "readiness": "baseline freeze only; M5 acceptance not established",
        "provenance": {
            "plan_start": {"metacircuit": "2ff7f3a", "simpyhls": "0d6f22a",
                           "framescope": m3["provenance"]["../framescope"]},
            "accepted": {"metacircuit_head": git(repo, "rev-parse", "HEAD"),
                         "metacircuit_branch": git(repo, "branch", "--show-current"),
                         "metacircuit_dirty": bool(git(repo, "status", "--porcelain")),
                         "framescope_head": git(framescope, "rev-parse", "HEAD"),
                         "framescope_dirty": bool(git(framescope, "status", "--porcelain")),
                         "simpyhls_head": git(repo / "simpyhls", "rev-parse", "HEAD")},
            "decisions": ["M4 startup clears cells 1/2 alongside mouse setup",
                          "A-007 preserves selected wire variant when returning to wire tool"],
            "old_baseline_status": "Historical plan baseline is not the corrected accepted source; reduced startup/A-007 cases exposed defects. No old-baseline M5 pass is claimed.",
        },
        "scope": {
            "top": "GlobalRender_top",
            "modules": ["frontend interaction and command guard", "cell/component/property stores",
                        "toolbar, canvas, cursor, keypad and property-panel rendering",
                        "settled flooding colours and extraction", "frontend UART TX/RX snapshot protocol",
                        "accepted voltage RAM, seven-segment display and LEDs"],
            "inputs": {"mouse": "absolute MouseCtl output coordinates and buttons, not PS/2 packets",
                       "screen": [640, 480], "logical_grid": [18, 16],
                       "pan_x": [0, 0], "pan_y": [-224, 0], "rotations": [0, 1, 2, 3],
                       "tools": "all ten tools and four wire variants",
                       "backend": "fixed M3 UART/host fixtures; accepted M3 assumptions define numeric scope"},
            "qualification": "M1/M2/M3 fixed regressions and M4 cold seeded settled endpoint exploration, not exhaustive combinations",
            "exclusions": ["device-level PS/2", "physical board", "real SolverBoard_top datapath and configured floating-point IP",
                           "arbitrary memory stalls and continuous progress/atomicity",
                           "transient flooding pixels and every intermediate canvas transaction",
                           "physical component-store exhaustion (legal grid fits at most 144 two-cell components)",
                           "clock/reset/CDC refactors without additional evidence"],
        },
        "timing": {
            "input_line": 10, "input_latency_frames": 1,
            "frame_rule": "Back-porch input change in frame N first appears in frame N+1; m1_latency checks RAM/probes every frame without extra wait.",
            "rotate_frames_per_step": 8, "flow_phase_frames": 2, "caret_toggle_frames": 10,
            "settled_m4_extra_wait_frames": 2,
            "settled_wait_is_progress_bound": False,
            "uart": "M3 frozen codec/comparator defines ordered records, content snapshot ids, stale rejection, ER85 abort and reply/display rules; recorded UART timing is preserved by the legacy regression.",
            "internal_progress_bounds": None,
            "internal_progress_status": "Not yet specified/qualified under configurable stalls; M5-4 must establish bounds before stall/retiming acceptance.",
            "permitted_retiming": "none for already specified observable frame effects; any change requires a new accepted contract",
        },
        "comparison": {"order": ["semantic state", "decoded cells", "pixels"],
                       "pixel_tolerance": 0, "default_pixel_exclusions": [],
                       "adapter_schema": "metacircuit-semantic/v1",
                       "adapter_status": "M5-2 separately validated; adapter implementation/config hashes must be pinned by acceptance evidence",
                       "legacy_m2_pixels_and_m3_oracles_required": True},
        "seed_policy": {"initialization": {"x_initial": "unique", "x_assign": "unique", "rand_reset": 2},
                        "checkpoint_reuse": False, "v1_v2_seeds": [1, 7, 2026],
                        "v2_long_seeds": [11, 12], "v2_long_operations": 64,
                        "directed_seed": 2026, "budget_status": "frozen M4 exploratory corpus; M5 gate runtime budget not yet accepted"},
        "mandatory_inventory": groups,
        "entries": [],
    }
    # Prepare every byte before writing anything. Baseline RTL is retained for
    # old/new validation, while candidate RTL may evolve without oracle drift.
    pending = []
    def capture(name: str, group: str, current_required: bool, origin: Path = repo):
        data = (origin / name).read_bytes()
        stored = ("baseline/framescope/" if origin == framescope else "payloads/") + name
        entry = {"path": name, "stored": stored, "group": group,
                 "sha256": sha(data), "behavior_sha256": sha(behavior_bytes(data, group)),
                 "current_required": current_required}
        contract["entries"].append(entry)
        pending.append((stored, data))
    for group, names in groups.items():
        for name in names:
            capture(name, group, True)
    for name in SAVED_CASES:
        capture(name, "saved_corpus", False)
    for name in ["docs/m3-verification.json", "docs/m4-verification.json"]:
        capture(name, "accepted_evidence", False)
    for path in sorted((repo / "src/design").rglob("*")):
        if path.is_file() and path.suffix.lower() in {".v", ".sv", ".vhd", ".vh"}:
            capture(str(path.relative_to(repo)), "baseline_rtl", False)
    for name in sorted(m4["framescope_source_hashes"]):
        data = (framescope / name).read_bytes()
        if sha(data) != m4["framescope_source_hashes"][name]:
            raise ValueError(f"accepted framescope source stale: {name}")
        capture(name, "baseline_harness", False, framescope)
    for path in sorted((framescope / "examples/metacircuit").rglob("*")):
        if path.is_file() and path.suffix in {".toml", ".sv", ".v"}:
            capture(str(path.relative_to(framescope)), "baseline_harness_manifest", False, framescope)
    target.mkdir(parents=True)
    for stored, data in pending:
        path = safe_path(target, stored)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    raw = json.dumps(contract, indent=2, sort_keys=True).encode() + b"\n"
    (target / "contract.json").write_bytes(raw)
    (target / "contract.sha256").write_text(sha(raw) + "\n")
    return {"ok": True, "contract_sha256": sha(raw), "entries": len(pending), "contract": str(target)}


def verify(repo: Path, target: Path, expected_sha256: str | None = None) -> dict:
    problems = []
    provenance_changes = []
    digest = None
    entry_count = 0
    try:
        raw = (target / "contract.json").read_bytes()
        pin = (target / "contract.sha256").read_text().strip()
        digest = sha(raw)
        if digest != pin or (expected_sha256 is not None and digest != expected_sha256):
            problems.append("contract identity changed")
        contract = json.loads(raw)
        if contract.get("schema") != "metacircuit-frozen-contract/v1":
            raise ValueError("unsupported contract schema")
        inventory = inputs(repo)
        if inventory != contract["mandatory_inventory"]:
            problems.append("mandatory input inventory changed")
        seen = set()
        for entry in contract["entries"]:
            entry_count += 1
            stored = entry["stored"]
            if stored in seen:
                raise ValueError(f"duplicate frozen entry: {stored}")
            seen.add(stored)
            data = safe_path(target, stored).read_bytes()
            if sha(data) != entry["sha256"] or sha(behavior_bytes(data, entry["group"])) != entry["behavior_sha256"]:
                problems.append(f"frozen input changed: {stored}")
            if entry["current_required"]:
                current = safe_path(repo, entry["path"]).read_bytes()
                if sha(behavior_bytes(current, entry["group"])) != entry["behavior_sha256"]:
                    problems.append(f"mandatory input stale: {entry['path']}")
                elif sha(current) != entry["sha256"]:
                    provenance_changes.append({"path": entry["path"],
                                               "frozen_sha256": entry["sha256"],
                                               "current_sha256": sha(current)})
        required = {name for names in inventory.values() for name in names}
        declared = {entry["path"] for entry in contract["entries"] if entry["current_required"]}
        if required != declared:
            problems.append("mandatory entry set incomplete")
    except (OSError, ValueError, KeyError, TypeError) as exc:
        problems.append(str(exc))
    return {"ok": not problems, "contract": str(target), "contract_sha256": digest,
            "checked_entries": entry_count, "provenance_changes": provenance_changes,
            "errors": problems}


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["freeze", "verify"])
    parser.add_argument("--repo", type=Path, default=REPO)
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--framescope", type=Path, default=REPO.parent / "framescope")
    parser.add_argument("--expected-contract-sha256", help="external trusted contract identity for the acceptance gate")
    args = parser.parse_args(argv)
    try:
        result = freeze(args.repo.resolve(), args.contract.resolve(), args.framescope.resolve()) if args.action == "freeze" else verify(args.repo.resolve(), args.contract.resolve(), args.expected_contract_sha256)
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError) as exc:
        result = {"ok": False, "errors": [str(exc)]}
    print(json.dumps(result, indent=2))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
