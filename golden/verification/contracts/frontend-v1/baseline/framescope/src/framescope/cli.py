"""framescope command line. Commands print JSON; session uses one response per
request line. Progress goes to stderr."""

from __future__ import annotations

import argparse
import json
import platform
import sys
from pathlib import Path

from . import FramescopeError, __version__, build, manifest, protocols, run, runtime
from . import batch, compare, coverage, host, scenario, session


def _log(msg: str) -> None:
    print(f"[framescope] {msg}", file=sys.stderr, flush=True)


def _trace_window(s: str) -> tuple[int, int]:
    start, _, count = s.partition(":")
    try:
        return int(start), int(count or 1)
    except ValueError:
        raise argparse.ArgumentTypeError("expected FRAME or FRAME:COUNT") from None


def _tolerance(s: str) -> tuple[int, int, int]:
    try:
        return compare.parse_tolerance(s)
    except FramescopeError as e:
        raise argparse.ArgumentTypeError(str(e)) from None


def _parser() -> argparse.ArgumentParser:
    ap = argparse.ArgumentParser(prog="framescope", description="Observe RTL video output (VGA, ...) via Verilator.")
    ap.add_argument("--version", action="version", version=f"framescope {__version__}")
    ap.add_argument("--runtime", choices=["auto", *runtime.RUNTIMES], help="default: $FRAMESCOPE_RUNTIME or auto")
    sub = ap.add_subparsers(dest="cmd", required=True)

    def with_config(p: argparse.ArgumentParser) -> argparse.ArgumentParser:
        p.add_argument("-c", "--config", default="framescope.toml", help="manifest file or its directory")
        return p

    sub.add_parser("doctor", help="show runtimes, toolchain image and versions")
    img = sub.add_parser("image", help="manage the toolchain container image")
    img.add_argument("action", choices=["build", "tag"])
    with_config(sub.add_parser("ports", help="list the top module's ports"))
    with_config(sub.add_parser("lint", help="Verilator -Wall lint of the design"))
    b = with_config(sub.add_parser("build", help="generate the wrapper and build the simulator"))
    b.add_argument("--trace", action="store_true", help="build with FST tracing support")

    cv = sub.add_parser("coverage-merge", help="merge compatible complete RTL coverage runs")
    cv.add_argument("inputs", nargs="+", type=Path, help="run directories or coverage.json files")
    cv.add_argument("-o", "--out", required=True, type=Path)
    cv.add_argument("--scope", choices=["boot", "scenario"], default="scenario")

    c = sub.add_parser("compare", help="compare frames with reference PNGs (masks, diff PNGs, boxes)")
    c.add_argument("actual", type=Path, help="PNG file, or a directory such as a run directory")
    c.add_argument("reference", type=Path, help="reference PNG file, or a directory of them (matched by path/name)")
    c.add_argument("-m", "--masks", type=Path, help="region mask file (default: <reference dir>/masks.toml if present)")
    c.add_argument("--tolerance", type=_tolerance, metavar="N|R,G,B",
                   help="max per-channel difference (default: the mask file's, else 0)")
    c.add_argument("-o", "--out", type=Path, help="diff PNGs and compare.json (default: <actual dir>/compare)")
    c.add_argument("--no-diff", action="store_true", help="do not write diff PNGs")
    c.add_argument("--max-boxes", type=int, default=8, help="difference components listed per frame (default 8)")

    bt = with_config(sub.add_parser("batch", help="run many stimulus files against one build, in parallel"))
    bt.add_argument("scenarios", nargs="+", type=Path, help="stimulus TOML files, or directories of them")
    bt.add_argument("-n", "--frames", type=int, default=1, help="frames for scenarios without a `frames` key (default 1)")
    bt.add_argument("-j", "--jobs", type=int, help=f"simulations at a time (default: CPUs / 2 = {batch.default_jobs()})")
    bt.add_argument("-o", "--out", type=Path, help="batch directory (default: <work_dir>/batches/<timestamp>)")
    bt.add_argument("--refs", type=Path, help="compare each scenario with <refs>/<scenario name>/")
    bt.add_argument("-m", "--masks", type=Path, help="default mask file for comparisons")
    bt.add_argument("--tolerance", type=_tolerance, metavar="N|R,G,B", help="max per-channel difference")
    bt.add_argument("--set", action="append", default=[], metavar="NAME=VALUE", help="initial value for every scenario")
    bt.add_argument("--save", default="all", help="frames to write as PNG: all | last | none | 0,3,5")
    bt.add_argument("--dump", default="none", help="frames after which to dump [[dump]] memories: all | last | none | 0,3,5")
    bt.add_argument("--max-time-ms", type=float, help="simulated-time limit per scenario")
    bt.add_argument("--seed", type=int, metavar="N", help="reproducible runtime seed (1..2147483647; default 1)")
    bt.add_argument("--checkpoint", type=int, metavar="N",
                    help="boot once: start every scenario from a saved state after N frames")
    bt.add_argument("--host", action="append", default=[], metavar="[LINK=]CMD",
                    help="host process for a UART link, one per scenario (see README)")

    r = with_config(sub.add_parser("run", help="simulate and capture frames"))
    r.add_argument("-n", "--frames", type=int, help="complete frames to capture (default: the stim file's `frames`, else 1)")
    r.add_argument("-o", "--out", type=Path, help="run directory (default: <work_dir>/runs/<timestamp>)")
    r.add_argument("-s", "--stim", type=Path, help="stimulus TOML ([[event]] tables)")
    r.add_argument("--set", action="append", default=[], metavar="NAME=VALUE", help="initial input or virtual-input value")
    r.add_argument("--save", default="all", help="frames to write as PNG: all | last | none | 0,3,5")
    r.add_argument("--dump", default="none", help="frames after which to dump [[dump]] memories: all | last | none | 0,3,5")
    r.add_argument("--raster", action="store_true", help="also save full rasters including blanking")
    r.add_argument("--trace", type=_trace_window, metavar="FRAME[:COUNT]", help="dump FST for these frames")
    r.add_argument("--max-time-ms", type=float, help="simulated-time limit (default 40 ms per frame + 80)")
    r.add_argument("--coverage-from", type=int, metavar="FRAME", help="split boot/scenario coverage at frame start (default 0)")
    r.add_argument("--profile", action="store_true", help="report where the wall time goes (sim.profile)")
    r.add_argument("--seed", type=int, metavar="N", help="reproducible runtime seed (1..2147483647; default 1)")
    r.add_argument("--checkpoint", type=int, metavar="N",
                   help="start from a saved state after N frames (created on first use; needs N < frames)")
    r.add_argument("--host", action="append", default=[], metavar="[LINK=]CMD",
                   help="attach a host process to a UART link: it answers each received line (see README)")
    ss = with_config(sub.add_parser("session", help="persistent JSON-lines frame stepping (see README)"))
    ss.add_argument("-o", "--out", type=Path, help="session artifact directory")
    ss.add_argument("--seed", type=int, help="cold initialization seed, 1..2147483647")
    ss.add_argument("--set", action="append", default=[], metavar="NAME=VALUE")
    ss.add_argument("--save", choices=["all", "none"], default="none")
    return ap


def main(argv: list[str] | None = None) -> int:
    args = _parser().parse_args(argv)
    if args.cmd == "session":
        try:
            rt = runtime.detect(args.runtime)
            m = manifest.load(args.config)
            with session.Session(m, rt, _log, out=args.out, sets=args.set, save=args.save, seed=args.seed) as running:
                session.serve(running, sys.stdin, sys.stdout)
            return 0
        except FramescopeError as e:
            print(json.dumps({"id": None, "ok": False, "error": str(e)}), flush=True)
            return 1
    try:
        result = _dispatch(args)
    except FramescopeError as e:
        result = {"ok": False, "error": str(e)}
    print(json.dumps(result, indent=2))
    return 0 if result.get("ok", True) else 1


def _dispatch(args: argparse.Namespace) -> dict:
    if args.cmd == "doctor":
        info: dict = {"ok": True, "framescope": __version__, "python": platform.python_version(),
                      "available": runtime.available(), "image_tag": runtime.image_tag()}
        try:
            info["runtime"] = runtime.detect(args.runtime).describe()
        except FramescopeError as e:
            info.update(ok=False, error=str(e))
        return info
    if args.cmd == "compare":
        return compare.compare_paths(args.actual, args.reference, masks=args.masks, tolerance=args.tolerance,
                                     out=args.out, diff=not args.no_diff, max_boxes=args.max_boxes)

    if args.cmd == "coverage-merge":
        return coverage.merge(args.inputs, args.out, scope=args.scope)
    rt = runtime.detect(args.runtime)
    if args.cmd == "image":
        if args.action == "build":
            if not isinstance(rt, runtime.ContainerRuntime):
                raise FramescopeError("the native runtime has no image")
            rt.build_image(_log)
        return {"ok": True, "image": runtime.image_tag(), "runtime": rt.name}

    m = manifest.load(args.config)
    if args.cmd == "ports":
        rt.prepare(_log)
        ports = build.introspect(m, build.plan(m, rt), _log)
        return {"ok": True, "top": m.top, "ports": [p.to_json() for p in ports]}
    if args.cmd == "lint":
        return build.lint(m, rt, _log)
    if args.cmd == "build":
        return {"ok": True, **build.build(m, rt, _log, trace=args.trace).to_json()}
    hosts = {}
    if args.cmd in ("run", "batch") and args.host:
        hosts = host.parse_specs(args.host, [mon.name for mon in protocols.links(m, "host")])
    if args.cmd == "batch":
        return batch.batch(
            m, rt, _log, scenarios=args.scenarios, frames=args.frames, out=args.out, jobs=args.jobs,
            refs=args.refs, masks=args.masks, tolerance=args.tolerance, save=args.save, dump=args.dump, sets=args.set,
            max_time_ms=args.max_time_ms, checkpoint=args.checkpoint, hosts=hosts, seed=args.seed,
        )
    if args.cmd == "run" and args.frames is None:
        args.frames = scenario.read_meta(args.stim).frames or 1
    if args.cmd == "run":
        return run.run(
            m, rt, _log,
            frames=args.frames, out=args.out, stim=args.stim, sets=args.set, save=args.save, dump=args.dump,
            raster=args.raster, trace=args.trace, max_time_ms=args.max_time_ms, profile=args.profile,
            checkpoint=args.checkpoint, hosts=hosts, seed=args.seed, coverage_from=args.coverage_from,
        )
    raise FramescopeError(f"unknown command {args.cmd}")
