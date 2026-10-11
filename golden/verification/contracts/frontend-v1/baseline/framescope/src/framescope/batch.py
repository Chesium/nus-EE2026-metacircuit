"""Runs many stimulus scenarios against one build, in parallel, with optional
reference comparison, and summarises them in one report.

The simulator is built once; each scenario then runs as its own simulator
process (at most `jobs` at a time) in <batch_dir>/<scenario>/, followed by
`compare` against its reference directory when it has one.
"""

from __future__ import annotations

import json
import os
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path

from . import FramescopeError, build, compare, protocols, rundir
from . import checkpoint as ckpt
from .manifest import Manifest
from .run import initialization_options, run
from .runtime import Log, Runtime
from .scenario import read_meta
from .stimulus import compile_lines

_NOT_SCENARIOS = {"framescope.toml", compare.MASK_FILE}


@dataclass
class Scenario:
    name: str
    stim: Path
    frames: int
    run_dir: Path
    reference: Path | None
    masks: Path | None
    reference_error: str | None = None


def default_jobs() -> int:
    return max(1, (os.cpu_count() or 2) // 2)


def expand(paths: list[Path]) -> list[Path]:
    """Stimulus files from files and directories (a directory contributes its
    *.toml files, except framescope.toml, masks.toml and *.masks.toml)."""
    out: list[Path] = []
    for p in paths:
        p = Path(p).resolve()
        if p.is_dir():
            found = sorted(f for f in p.glob("*.toml")
                           if f.name not in _NOT_SCENARIOS and not f.name.endswith(".masks.toml"))
            if not found:
                raise FramescopeError(f"no scenario TOML files in {p}")
            out += found
        elif p.is_file():
            out.append(p)
        else:
            raise FramescopeError(f"scenario not found: {p}")
    if not out:
        raise FramescopeError("give at least one stimulus file or directory")
    return out


def batch(
    m: Manifest,
    runtime: Runtime,
    log: Log,
    *,
    scenarios: list[Path],
    frames: int = 1,
    out: Path | None = None,
    jobs: int | None = None,
    refs: Path | None = None,
    masks: Path | None = None,
    tolerance: tuple[int, int, int] | None = None,
    save: str = "all",
    dump: str = "none",
    sets: list[str] | None = None,
    max_time_ms: float | None = None,
    checkpoint: int | None = None,
    hosts: dict[str, list[str]] | None = None,
    seed: int | None = None,
) -> dict:
    initialization = initialization_options(m, seed)
    if not m.monitors:
        raise FramescopeError("add a [[monitor]] to the manifest before running")
    stims = expand(scenarios)
    t0 = time.monotonic()
    checkpointable = not m.build.randomized and seed is None
    br = build.build(m, runtime, log, savable=checkpoint is not None and checkpointable)

    if out is not None:
        batch_dir = Path(out).resolve()
        batch_dir.mkdir(parents=True, exist_ok=True)
    else:
        batch_dir = rundir.new_dir(m.work_dir / "batches")
    plan = _plan(stims, batch_dir, frames, refs, masks)
    taken = [s.run_dir for s in plan if s.run_dir.exists()]
    if taken:
        raise FramescopeError(f"run directories already exist (remove them or choose another -o): "
                              f"{[str(p) for p in taken]}")
    for s in plan:
        s.run_dir.mkdir(parents=True)

    if checkpoint is not None and checkpointable:
        # Create the boot checkpoints up front, one per distinct early stimulus
        # (usually one), so parallel scenarios only restore them.
        for s in plan:
            if s.frames > checkpoint >= 1:
                try:
                    ckpt.ensure(m, runtime, log, br, checkpoint, compile_lines(m, br.ports, s.stim, sets or []))
                except FramescopeError as e:
                    log(f"batch: {s.name}: no checkpoint ({e})")

    jobs = max(1, min(jobs or default_jobs(), len(plan)))
    log(f"batch: {len(plan)} scenario(s), {jobs} at a time -> {batch_dir}")

    def one(s: Scenario) -> dict:
        res = _run_scenario(s, m, runtime, lambda msg: log(f"{s.name}: {msg}"), tolerance=tolerance, save=save,
                            dump=dump, sets=sets or [], max_time_ms=max_time_ms, checkpoint=checkpoint,
                            hosts=hosts or {}, seed=seed)
        log(f"batch: {s.name}: {'ok' if res['ok'] else 'FAILED'} ({res['wall_s']}s)")
        return res

    with ThreadPoolExecutor(max_workers=jobs) as pool:
        results = list(pool.map(one, plan))

    failed = [r["name"] for r in results if not r["ok"]]
    summary = {
        "ok": not failed,
        "batch_dir": str(batch_dir),
        "runtime": runtime.name,
        "build": br.to_json(),
        "initialization": initialization,
        "jobs": jobs,
        "wall_s": round(time.monotonic() - t0, 2),
        "summary": {"scenarios": len(results), "passed": len(results) - len(failed), "failed": len(failed),
                    "failed_scenarios": failed},
        "scenarios": results,
    }
    (batch_dir / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    return summary


def _plan(stims: list[Path], batch_dir: Path, frames: int, refs: Path | None, masks: Path | None) -> list[Scenario]:
    if frames < 1:
        raise FramescopeError("--frames must be at least 1")
    names: set[str] = set()
    plan = []
    for stim in stims:
        name = stim.stem
        i = 2
        while name in names:
            name, i = f"{stim.stem}-{i}", i + 1
        names.add(name)
        meta = read_meta(stim)
        ref, err = meta.reference, None
        if ref is None and refs is not None:
            ref = Path(refs).resolve() / name
        if ref is not None and not ref.is_dir():
            err, ref = f"reference directory not found: {ref}", None
        mask = meta.masks
        if mask is None and ref is not None and (ref / compare.MASK_FILE).is_file():
            mask = ref / compare.MASK_FILE
        if mask is None and masks is not None:
            mask = Path(masks).resolve()
        plan.append(Scenario(name, stim, meta.frames or frames, batch_dir / name, ref, mask, err))
    return plan


def _run_scenario(s: Scenario, m: Manifest, runtime: Runtime, log: Log, *, tolerance, save: str, dump: str,
                  sets: list[str], max_time_ms: float | None, checkpoint: int | None = None,
                  hosts: dict[str, list[str]] | None = None, seed: int | None = None) -> dict:
    t0 = time.monotonic()
    res: dict = {"name": s.name, "stim": str(s.stim), "ok": False, "frames_requested": s.frames,
                 "frames": 0, "run_dir": str(s.run_dir)}
    try:
        report = run(m, runtime, log, frames=s.frames, out=s.run_dir, stim=s.stim, sets=sets, save=save, dump=dump,
                     max_time_ms=max_time_ms, checkpoint=checkpoint, hosts=hosts, seed=seed)
        ref = protocols.primary(m)
        first = report["monitors"].get(ref.name, {}) if ref else {}
        res.update(
            ok=report["ok"],
            frames=len(first.get("frames", [])),
            report=str(s.run_dir / "report.json"),
            stop_reason=report["sim"]["stop_reason"],
            sim_wall_s=report["sim"]["wall_s"],
            checkpoint=report.get("checkpoint"),
            errors=report["errors"],
            diagnosis={k: v.get("diagnosis", []) for k, v in report["monitors"].items() if v.get("diagnosis")},
        )
    except FramescopeError as e:
        res["errors"] = [str(e)]

    if s.reference_error:
        res["compare"] = {"ok": False, "error": s.reference_error}
    elif s.reference is not None:
        try:
            res["compare"] = _compare_summary(compare.compare_paths(
                s.run_dir, s.reference, masks=s.masks, tolerance=tolerance, out=s.run_dir / "compare"))
        except FramescopeError as e:
            res["compare"] = {"ok": False, "reference": str(s.reference), "error": str(e)}
    else:
        res["compare"] = None
    if res["compare"] is not None:
        res["ok"] = res["ok"] and res["compare"]["ok"]
    res["wall_s"] = round(time.monotonic() - t0, 2)
    return res


def _compare_summary(c: dict, limit: int = 10) -> dict:
    failures = [
        {k: f[k] for k in ("name", "diff_pixels", "bbox", "diff_png", "error") if k in f}
        for f in c["frames"] if not f["ok"]
    ]
    return {
        "ok": c["ok"],
        "reference": c["reference"],
        "masks": c["masks"],
        **{k: v for k, v in c["summary"].items() if k != "failed_frames"},
        "failures": failures[:limit],
        "json": str(Path(c["out_dir"]) / "compare.json"),
    }
