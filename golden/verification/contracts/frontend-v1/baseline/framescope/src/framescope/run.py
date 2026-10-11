"""Runs a built simulation and turns its event stream into a report."""

from __future__ import annotations

import json
import time
from pathlib import Path

from . import FramescopeError, protocols
from . import checkpoint as ckpt
from . import coverage as cov
from .build import build, plan
from .host import Host
from .manifest import Manifest
from .rundir import new_dir
from .runtime import Log, Runtime
from .stimulus import compile_lines

# Generous enough for >= 25 Hz modes plus the frame spent learning sync polarity.
_MS_PER_FRAME_BUDGET = 40.0


def time_budget_ps(frames: int) -> int:
    """Default simulated-time limit for `frames` frames."""
    return int(_MS_PER_FRAME_BUDGET * (frames + 2) * 1e9)


def run(
    m: Manifest,
    runtime: Runtime,
    log: Log,
    *,
    frames: int,
    out: Path | None = None,
    stim: Path | None = None,
    sets: list[str] | None = None,
    save: str = "all",
    dump: str = "none",
    raster: bool = False,
    trace: tuple[int, int] | None = None,
    max_time_ms: float | None = None,
    profile: bool = False,
    checkpoint: int | None = None,
    hosts: dict[str, list[str]] | None = None,
    host_timeout_s: float = 60.0,
    seed: int | None = None,
    coverage_from: int | None = None,
) -> dict:
    """Simulates `frames` frames. With `checkpoint` = N, starts from a boot
    checkpoint after N frames (created on first use, see checkpoint.py) when the
    stimulus allows it, else runs from time 0 and says why in the report.

    `hosts` maps link monitors to host-process commands (see host.py); the
    simulation waits for each host answer, so runs stay deterministic.
    """
    initialization = initialization_options(m, seed)
    if not m.monitors:
        raise FramescopeError("add a [[monitor]] to the manifest before running")
    if frames < 1:
        raise FramescopeError("--frames must be at least 1")
    ref = protocols.primary(m)
    if ref is None and max_time_ms is None:
        raise FramescopeError("no monitor produces frames (e.g. vga): give --max-time-ms to bound the run")
    if coverage_from is not None and not m.build.coverage:
        raise FramescopeError("--coverage-from requires [build] coverage = true")
    if m.build.coverage:
        coverage_from = 0 if coverage_from is None else coverage_from
        if isinstance(coverage_from, bool) or not isinstance(coverage_from, int) or not 0 <= coverage_from < frames:
            raise FramescopeError("--coverage-from needs 0 <= FRAME < frames")
        if ref is None:
            raise FramescopeError("coverage requires a monitor that produces frames")
        if checkpoint is not None:
            raise FramescopeError("coverage requires a cold run without --checkpoint")
    hosts = dict(hosts or {})
    hostable = [mon.name for mon in protocols.links(m, "host")]
    for link in hosts:
        if link not in hostable:
            raise FramescopeError(f"--host: '{link}' is not a monitor that takes a host; known: {hostable}")
    dump = check_frame_selection(dump, frames, "--dump")
    if dump != "none" and not m.dumps:
        raise FramescopeError("--dump needs [[dump]] memories in the manifest")
    save = check_frame_selection(save, frames, "--save")
    ck, ck_skip = None, None
    if checkpoint is not None:
        if m.build.randomized or seed is not None:
            ck_skip = "seeded/randomized runs start from time 0 (RNG checkpoint state is not verified)"
        elif trace is not None:
            ck_skip = "--trace runs from time 0"
        elif not 1 <= checkpoint < frames:
            ck_skip = f"--checkpoint {checkpoint} needs 1 <= N < frames ({frames})"
    savable = checkpoint is not None and ck_skip is None
    br = build(m, runtime, log, trace=trace is not None, savable=savable)
    lines = compile_lines(m, br.ports, stim, sets or [])
    if savable:
        try:
            ck = ckpt.ensure(m, runtime, log, br, checkpoint, lines)
            ckpt.check_hosts(ck, hosts)
        except ckpt.CheckpointUnavailable as e:
            ck, ck_skip = None, str(e)

    run_dir = out.resolve() if out else new_dir(m.work_dir / "runs")  # unique even for parallel runs
    run_dir.mkdir(parents=True, exist_ok=True)
    p = plan(m, runtime, extra_writable=[run_dir])
    stim_file = run_dir / "stimulus.txt"
    stim_file.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")

    budget_ps = int(max_time_ms * 1e9) if max_time_ms is not None else time_budget_ps(frames)
    argv = [
        p.rt(br.binary), "--out", p.rt(run_dir), "--frames", str(frames),
        "--max-time-ps", str(budget_ps), "--stim", p.rt(stim_file), "--save", save,
        "--dump", dump, "--seed", str(initialization["seed"]),
        "--rand-reset", str(initialization["rand_reset"]),
    ]
    coverage_info = None
    if m.build.coverage:
        coverage_dir = run_dir / "coverage"
        coverage_dir.mkdir(parents=True, exist_ok=True)
        for stale in ("boot.dat", "scenario.dat", "coverage.json"):
            (coverage_dir / stale).unlink(missing_ok=True)
        coverage_info = cov.provenance(m, runtime, br, p)
        argv += ["--coverage", p.rt(coverage_dir), "--coverage-from", str(coverage_from)]
    if ck is not None:
        argv += ["--checkpoint-load", p.rt(ck.state)]
    if raster:
        argv.append("--raster")
    if profile:
        argv.append("--profile")
    if trace is not None:
        argv += ["--trace", p.rt(run_dir / "trace.fst"), "--trace-from", str(trace[0]), "--trace-frames", str(trace[1])]
    for link in hosts:
        argv += ["--host", link]

    by_name = {mon.name: mon for mon in m.monitors}
    host_errors: list[str] = []
    started: dict[str, Host] = {}

    def answer(ev: dict) -> str:
        mon = by_name[ev["monitor"]]
        proto = protocols.get(mon.protocol)
        return proto.host_reply(mon, started[mon.name].request(proto.host_message(mon, ev)))

    t0 = time.monotonic()
    log(f"simulating {frames} frame(s) -> {run_dir}" + (f" from the frame-{ck.frames} checkpoint" if ck else ""))
    try:
        for link, cmd in hosts.items():
            started[link] = Host(link, cmd, run_dir / f"host_{link}.log", run_dir, host_timeout_s)
            started[link].send(protocols.get(by_name[link].protocol).host_start(by_name[link]))
        events, rc = ckpt.simulate(runtime, p, argv, run_dir, log, answer=answer if hosts else None,
                                   errors=host_errors)
    finally:
        host_info = {}
        for link, h in started.items():
            code = h.kill() if host_errors else h.close()
            host_info[link] = {"argv": h.argv, "requests": h.requests, "exit_code": code,
                               "log": str(run_dir / f"host_{link}.log")}
    if ck is not None:
        events = ckpt.replay(ck, run_dir, frames=frames, save=save, dump=dump, raster=raster) + events

    end = next((e for e in events if e.get("event") == "end"), None)
    errors = host_errors + [e["message"] for e in events if e.get("event") == "error"]
    if end is None and not errors:
        tail = (run_dir / "sim.log").read_text(encoding="utf-8", errors="replace")[-2000:]
        errors.append(f"simulation exited with code {rc} before finishing; sim.log tail:\n{tail}")

    sim = {
        "initialization": initialization,
        "frames_requested": frames,
        "stop_reason": end["stop_reason"] if end else "crashed",
        "sim_time_ms": round(end["t_ps"] / 1e9, 3) if end else None,
        "wall_s": round(end["wall_s"], 2) if end else round(time.monotonic() - t0, 2),
    }
    if end and "profile" in end:
        sim["profile"] = _round_profile(end["profile"])
    monitors = {}
    for mon in m.monitors:
        mon_ev = [e for e in events if e.get("monitor") == mon.name]
        frames_ev = [e for e in mon_ev if e.get("event") == "frame"]
        summary = next((e["summary"] for e in mon_ev if e.get("event") == "monitor_summary"), {})
        monitors[mon.name] = protocols.get(mon.protocol).analyze(mon, frames_ev, summary, sim, mon_ev)
        if mon.name in host_info:
            monitors[mon.name]["host"] = host_info[mon.name]
    probes = _attach_probes(m, monitors[ref.name], events) if m.probes and ref else {}

    warnings = []
    stimulus = [_stim_entry(e) for e in events if e.get("event") == "stim"]
    for st in stimulus:
        if st["late"]:
            warnings.append(
                f"stimulus {st['name']}={st['value']} for frame {st['frame']} line {st['line']} pixel {st['pixel']} "
                f"fired late at frame {st['at_frame']} line {st['at_line']} pixel {st['at_pixel']} "
                "(that position does not occur)"
            )
    dumps: dict[str, list[dict]] = {d.name: [] for d in m.dumps} if dump != "none" else {}
    for e in events:
        if e.get("event") == "dump":
            dumps.setdefault(e["name"], []).append(
                {"frame": e["frame"], "path": e["path"], "width": e["width"], "depth": e["depth"]})
    if ck_skip is not None:
        warnings.append(f"not using a checkpoint: {ck_skip}")
    if end and end.get("undeclared_virtual_inputs"):
        warnings.append(f"stubs read virtual inputs not declared in the manifest: {end['undeclared_virtual_inputs']}")
    report = {
        "ok": not errors and sim["stop_reason"] == ("frames" if ref else "max_time"),
        "run_dir": str(run_dir),
        "runtime": runtime.name,
        "build": br.to_json(),
        "sim": sim,
        "monitors": monitors,
        "checkpoint": ck.to_json() if ck else ({"restored": False, "reason": ck_skip} if ck_skip else None),
        "trace": str(run_dir / "trace.fst") if trace is not None and (run_dir / "trace.fst").is_file() else None,
        "probes": probes,
        "dumps": dumps,
        "stimulus": stimulus,
        "warnings": warnings,
        "errors": errors,
    }
    if coverage_info is not None:
        boundary = next((e for e in events if e.get("event") == "coverage_boundary"), None)
        try:
            report["coverage"] = cov.write_run(coverage_dir, coverage_info, boundary, report["ok"], p.pm)
        except FramescopeError as e:
            report["ok"] = False
            report["errors"].append(str(e))
    (run_dir / "report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    return report


def check_frame_selection(spec: str, frames: int, what: str) -> str:
    """Validates all | last | none | 0,3,5 against the number of frames."""
    if spec in ("all", "last", "none"):
        return spec
    try:
        picked = [int(x) for x in spec.split(",")]
    except ValueError:
        raise FramescopeError(f"{what} expects all, last, none or frame indices like 0,3; got '{spec}'") from None
    bad = [x for x in picked if not 0 <= x < frames]
    if bad:
        raise FramescopeError(f"{what}: frame(s) {bad} outside 0..{frames - 1}")
    return ",".join(map(str, picked))


def _attach_probes(m: Manifest, monitor: dict, events: list[dict]) -> dict:
    """Adds frames[i].probes from the harness's per-frame probe events; returns
    the probe declarations with their widths."""
    start = next((e for e in events if e.get("event") == "start"), {})
    widths = start.get("probe_widths", {})
    signed = {p.name: widths.get(p.name, 64) for p in m.probes if p.signed}
    by_frame = {e["frame"]: e["values"] for e in events if e.get("event") == "probes"}
    for f in monitor["frames"]:
        values = by_frame.get(f["index"])
        if values is not None:
            f["probes"] = {k: _to_signed(v, signed[k]) if k in signed else v for k, v in values.items()}
    return {p.name: {"expr": p.expr, "width": widths.get(p.name), "signed": p.signed} for p in m.probes}


def _round_profile(prof: dict) -> dict:
    return {k: ({kk: round(vv, 4) if isinstance(vv, float) else vv for kk, vv in v.items()} if isinstance(v, dict)
                else round(v, 4)) for k, v in prof.items()}


def _to_signed(value: int, width: int) -> int:
    return value - (1 << width) if (value >> (width - 1)) & 1 else value


def _stim_entry(e: dict) -> dict:
    keys = ("name", "value", "frame", "line", "pixel", "at_frame", "at_line", "at_pixel")
    out = {k: e[k] for k in keys}
    out["t_ms"] = round(e["t_ps"] / 1e9, 6)
    out["late"] = (e["at_frame"], e["at_line"], e["at_pixel"]) != (e["frame"], e["line"], e["pixel"])
    return out


def initialization_options(m: Manifest, seed: int | None) -> dict:
    """Runtime initialization provenance; nonzero seeds are portable to pinned Verilator."""
    if seed is not None and (isinstance(seed, bool) or not isinstance(seed, int) or not 1 <= seed <= 2147483647):
        raise FramescopeError("--seed must be an integer in 1..2147483647 (0 chooses a nondeterministic seed)")
    return {"seed": seed if seed is not None else 1, "seed_explicit": seed is not None,
            "rand_reset": 2 if m.build.randomized else 0,
            "x_initial": m.build.x_initial, "x_assign": m.build.x_assign}
