"""Verilator coverage points, provenance and compatible artifact merging.

Counts are instrumentation points, not a percentage of all HDL source lines.
Older Verilator emits branch counters under v_line; retain the tool's types.
"""
from __future__ import annotations

import hashlib
import json
import re
from collections import defaultdict
from pathlib import Path
from urllib.parse import unquote

from . import FramescopeError

_POINT = re.compile(r"C '(.*)' ([0-9]+)$")


def read_points(path: Path) -> dict[str, int]:
    try:
        lines = path.read_text().splitlines()
    except (OSError, UnicodeError) as e:
        raise FramescopeError(f"coverage artifact unreadable: {path}: {e}") from None
    if not lines or lines[0] != "# SystemC::Coverage-3":
        raise FramescopeError(f"invalid coverage header: {path}")
    points = {}
    for i, line in enumerate(lines[1:], 2):
        if not line or line.startswith("#"):
            continue
        match = _POINT.fullmatch(line)
        if not match:
            raise FramescopeError(f"malformed coverage record: {path}:{i}")
        key, count = match.groups()
        fields(key)  # validate metadata, never silently omit broken points
        points[key] = points.get(key, 0) + int(count)
    if not points:
        raise FramescopeError(f"coverage artifact has no points: {path}")
    return points


def fields(key: str) -> dict[str, str]:
    try:
        data = dict(part.split("\x02", 1) for part in key.split("\x01")[1:])
    except ValueError:
        raise FramescopeError("malformed coverage point metadata") from None
    if not data.get("f") or not data.get("l") or not data.get("page"):
        raise FramescopeError("coverage point missing filename, line or page")
    if not data["l"].isdigit():
        raise FramescopeError("coverage point line must be a nonnegative integer")
    return {k: unquote(v) for k, v in data.items()}


def summarize(points: dict[str, int], pm=None, source_paths=None) -> dict:
    modules = defaultdict(lambda: defaultdict(list))
    for key, count in points.items():
        d = fields(key)
        page = d["page"]
        category, _, module = page.partition("/")
        kind = d.get("t") or category.removeprefix("v_").removeprefix("sp_")
        source = str(pm.to_host(d["f"])) if pm else (source_paths or {}).get(d["f"], d["f"])
        group = (module or "unknown", d.get("h", ""), source)
        point = {"line": int(d["l"]), "column": d.get("n"), "comment": d.get("o", ""),
                 "hits": count}
        modules[group][kind].append(point)
    out = []
    for (module, hierarchy, source), types in sorted(modules.items()):
        metrics = {}
        for kind, items in sorted(types.items()):
            gaps = [p for p in items if p["hits"] == 0]
            metrics[kind] = {"eligible": len(items), "reached": len(items) - len(gaps),
                             "uncovered": len(gaps), "gaps": gaps[:64], "gaps_omitted": max(0, len(gaps) - 64),
                             "excluded": [], "exclusion_note": "Tool-pruned and pragma-disabled points are absent, not inferred"}
        out.append({"module": module, "hierarchy": hierarchy, "source": source, "types": metrics})
    return {"measurement": "Verilator instrumentation points; v_line includes branch flow counters on older tools",
            "acceptance": "Informational gaps only; named functional bins and project policy determine acceptance",
            "modules": out}


def source_files(m) -> list[Path]:
    """Declared sources and HDL include dependencies for cache and provenance."""
    files = set(m.sources + m.extra_sources)
    for directory in m.include_dirs:
        files.update(f for f in directory.rglob("*") if f.is_file()
                     and f.suffix.lower() in {".sv", ".v", ".svh", ".vh", ".inc"}
                     and not f.is_relative_to(m.work_dir))
    return list(dict.fromkeys([*m.sources, *m.extra_sources, *sorted(files)]))


def provenance(m, runtime, br, p) -> dict:
    version_path = br.build_dir / "coverage-verilator-version.txt"
    if not version_path.is_file():
        rc = runtime.run(["verilator", "--version"], p.mounts, p.work, version_path)
        if rc:
            raise FramescopeError("could not record coverage Verilator version")
    files = source_files(m)
    return {"build_id": br.build_dir.name, "tool_version": version_path.read_text().strip(),
            "runtime": runtime.name, "runtime_identity": runtime.identity(),
            "sources": [{"path": str(f), "sha256": hashlib.sha256(f.read_bytes()).hexdigest()}
                        for f in sorted(files)], "top": m.top, "build_options": br.options}


def write_run(directory: Path, info: dict, boundary: dict | None, complete: bool, pm) -> dict:
    artifacts = {}
    source_paths = {}
    for scope in ("boot", "scenario"):
        artifact = directory / f"{scope}.dat"
        if artifact.is_file():
            points = read_points(artifact)
            source_paths.update({fields(k)["f"]: str(pm.to_host(fields(k)["f"])) for k in points})
            artifacts[scope] = {"path": str(artifact), "sha256": hashlib.sha256(artifact.read_bytes()).hexdigest(),
                                "summary": summarize(points, pm)}
    report = {"schema_version": 1, "provenance": info, "boundary": boundary,
              "complete": complete and boundary is not None and {"boot", "scenario"} <= artifacts.keys(),
              "artifacts": artifacts, "source_paths": source_paths}
    target = directory / "coverage.json"
    target.write_text(json.dumps(report, indent=2))
    return {"report": str(target), **report}


def merge(inputs: list[Path], out: Path, *, scope: str = "scenario") -> dict:
    if scope not in ("boot", "scenario"):
        raise FramescopeError("coverage merge scope must be boot or scenario")
    if not inputs:
        raise FramescopeError("coverage merge needs at least one coverage.json")
    totals: dict[str, int] = {}
    expected = None
    source_paths = {}
    included = []
    seen = set()
    for source in inputs:
        source = source.resolve()
        if source.is_dir():
            source = source / "coverage" / "coverage.json"
        if source in seen:
            raise FramescopeError(f"duplicate coverage input: {source}")
        seen.add(source)
        try:
            report = json.loads(source.read_text())
            if report["schema_version"] != 1 or report["complete"] is not True or not report.get("boundary"):
                raise FramescopeError(f"incomplete or unsupported coverage report: {source}")
            if not {"boot", "scenario"} <= report["artifacts"].keys():
                raise FramescopeError(f"incomplete or unsupported coverage report: {source}")
            info = report["provenance"]
            if not {"build_id", "tool_version", "runtime", "runtime_identity", "sources", "top", "build_options"} <= info.keys():
                raise FramescopeError(f"coverage provenance missing fields: {source}")
            artifact_info = report["artifacts"][scope]
            artifact = source.parent / Path(artifact_info["path"]).name
            data = artifact.read_bytes()
            if hashlib.sha256(data).hexdigest() != artifact_info["sha256"]:
                raise FramescopeError(f"coverage artifact hash mismatch: {artifact}")
        except (OSError, ValueError, KeyError, TypeError, AttributeError) as e:
            raise FramescopeError(f"invalid coverage input {source}: {e}") from None
        if expected is None:
            expected = info
        elif expected != info:
            raise FramescopeError(f"coverage provenance mismatch: {source}")
        source_paths.update(report.get("source_paths", {}))
        points = read_points(artifact)
        if totals and set(points) != set(totals):
            raise FramescopeError(f"coverage instrumentation point mismatch: {source}")
        for key, count in points.items():
            totals[key] = totals.get(key, 0) + count
        included.append({"report": str(source), "sha256": hashlib.sha256(source.read_bytes()).hexdigest()})
    out = out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    artifact = out / f"merged-{scope}.dat"
    artifact.write_text("# SystemC::Coverage-3\n" + "".join(f"C '{key}' {count}\n" for key, count in sorted(totals.items())))
    result = {"ok": True, "schema_version": 1, "scope": scope, "provenance": expected,
              "inputs": included, "artifact": str(artifact), "source_paths": source_paths, "summary": summarize(totals, source_paths=source_paths)}
    (out / "coverage-merge.json").write_text(json.dumps(result, indent=2))
    return result
