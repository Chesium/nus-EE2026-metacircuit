"""Port introspection, wrapper generation and the Verilator build, with caching."""

from __future__ import annotations

import hashlib
import fcntl
import json
import re
import time
from collections.abc import Iterable
from dataclasses import dataclass
from pathlib import Path

from . import FramescopeError, __version__, codegen
from .coverage import source_files
from .manifest import Manifest
from .ports import Port, parse_json, parse_xml
from .runtime import PACKAGE_DIR, Log, Mount, PathMap, Runtime

HARNESS_DIR = PACKAGE_DIR / "harness"
DPI_PKG = PACKAGE_DIR / "rtl" / "framescope_dpi_pkg.sv"
HARNESS_SOURCES = ("main.cpp", "harness.cpp", "vga_monitor.cpp", "uart_monitor.cpp", "png.cpp", "dpi.cpp",
                   "checkpoint.cpp")
# Vendor-tool projects are noisy; `framescope lint` shows everything.
DEFAULT_WARNINGS = ("-Wno-fatal", "-Wno-lint", "-Wno-style")
BINARY = "Vframescope_top"


@dataclass
class Plan:
    """Mounts and path mapping for one tool invocation."""

    runtime: Runtime
    mounts: list[Mount]
    pm: PathMap
    work: Path

    def rt(self, p: Path) -> str:
        return self.pm.to_rt(p)


@dataclass
class BuildResult:
    build_dir: Path
    binary: Path
    ports: list[Port]
    cached: bool
    seconds: float
    trace: bool
    options: dict
    savable: bool = False

    def to_json(self) -> dict:
        return {
            "build_dir": str(self.build_dir),
            "binary": str(self.binary),
            "cached": self.cached,
            "seconds": round(self.seconds, 2),
            "trace": self.trace,
            "savable": self.savable,
            "options": self.options,
        }


def plan(m: Manifest, runtime: Runtime, extra_writable: Iterable[Path] = ()) -> Plan:
    m.work_dir.mkdir(parents=True, exist_ok=True)
    readonly = _covering_dirs([m.root, m.dir, *(f.parent for f in m.sources + m.extra_sources), *m.include_dirs])
    mounts = [Mount(PACKAGE_DIR, "/fs/tool")]
    mounts += [Mount(d, f"/fs/src{i}") for i, d in enumerate(readonly)]
    mounts.append(Mount(m.work_dir, "/fs/work", writable=True))
    for i, d in enumerate(_covering_dirs(extra_writable)):
        if not d.is_relative_to(m.work_dir):
            mounts.append(Mount(d, f"/fs/out{i}", writable=True))
    return Plan(runtime, mounts, runtime.path_map(mounts), m.work_dir)


def common_args(m: Manifest, p: Plan) -> list[str]:
    args = [*DEFAULT_WARNINGS, "--timescale", "1ns/1ps", *m.verilator_args]
    args += [f"+incdir+{p.rt(d)}" for d in m.include_dirs]
    args += [f"+define+{k}={v}" if v != "" else f"+define+{k}" for k, v in m.defines.items()]
    return args


def build_args(m: Manifest) -> list[str]:
    """Verilator arguments from [build] that only affect compilation of the model."""
    args = ["--x-initial", m.build.x_initial, "--x-assign", m.build.x_assign, "-CFLAGS", m.build.cxx_opt]  # after verilated.mk's OPT_FAST/OPT_SLOW, so it wins
    for flag in m.build.cxx_flags:
        args += ["-CFLAGS", flag]
    if m.build.threads > 1:
        args += ["--threads", str(m.build.threads)]
    if m.build.coverage:
        args += ["--coverage-line", "--coverage-toggle", "--coverage-user", "-CFLAGS", "-DFS_COVERAGE=1"]
    return args


def source_args(m: Manifest, p: Plan) -> list[str]:
    return [p.rt(DPI_PKG), *(p.rt(f) for f in m.sources), *(p.rt(f) for f in m.extra_sources)]


def introspect(m: Manifest, p: Plan, log: Log) -> list[Port]:
    key = _digest([m.top, *_file_digests(source_files(m)), *common_args(m, p), p.runtime.identity()])
    cache = p.work / "introspect" / f"{key[:16]}.json"
    if cache.is_file():
        return [Port(d["name"], d["direction"], d["msb"], d["lsb"], d["ranged"]) for d in json.loads(cache.read_text())]
    cache.parent.mkdir(parents=True, exist_ok=True)
    logfile = cache.with_suffix(".log")
    log(f"reading ports of {m.top}")
    # Verilator 5.026 added --json-only; later releases removed --xml-only.
    for only, output, suffix, parse in (("--json-only", "--json-only-output", ".json", parse_json),
                                        ("--xml-only", "--xml-output", ".xml", parse_xml)):
        dump = cache.with_suffix(suffix)
        argv = ["verilator", only, output, p.rt(dump), "--Mdir", p.rt(cache.parent / "obj"),
                "--top-module", m.top, *common_args(m, p), *source_args(m, p)]
        rc = p.runtime.run(argv, p.mounts, p.work, logfile)
        if rc == 0 or f"Invalid option: {only}" not in logfile.read_text(errors="replace"):
            break
    if rc != 0 or not dump.is_file():
        raise FramescopeError(f"Verilator could not elaborate {m.top}:\n{_errors(logfile, p.pm)}")
    ports = parse(dump, m.top)
    dump.unlink()
    cache.write_text(json.dumps([port.to_json() for port in ports], indent=1))
    return ports


def build(m: Manifest, runtime: Runtime, log: Log, *, trace: bool = False, savable: bool = False) -> BuildResult:
    """Builds (or finds in the cache) the simulator. `savable` adds Verilator
    --savable for boot checkpoints (a separate binary; not with --trace)."""
    # Parallel scenarios share a writable cache. Serialize generation/compilation
    # so neither callers nor container compilers overwrite each other's files.
    m.work_dir.mkdir(parents=True, exist_ok=True)
    with (m.work_dir / '.build.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        return _build_locked(m, runtime, log, trace=trace, savable=savable)


def _build_locked(m: Manifest, runtime: Runtime, log: Log, *, trace: bool = False,
                  savable: bool = False) -> BuildResult:
    t0 = time.monotonic()
    runtime.prepare(log)
    p = plan(m, runtime)
    ports = introspect(m, p, log)
    codegen.validate(m, ports)
    files = {
        "framescope_top.sv": codegen.wrapper_sv(m, ports),
        "framescope_bindings.cpp": codegen.bindings_cpp(m, ports),
    }
    harness = sorted(f for f in HARNESS_DIR.iterdir() if f.is_file())
    key = _digest([
        __version__, str(trace), *(["savable"] if savable else []), runtime.identity(),
        *common_args(m, p), *build_args(m), *files.values(),
        *_file_digests(source_files(m) + harness + [DPI_PKG]),
    ])
    bdir = p.work / "build" / key[:16]
    binary = bdir / "obj" / BINARY
    if (bdir / "ok").is_file() and binary.is_file():
        return BuildResult(bdir, binary, ports, True, time.monotonic() - t0, trace, _options(m), savable)

    bdir.mkdir(parents=True, exist_ok=True)
    for name, text in files.items():
        (bdir / name).write_text(text, encoding="utf-8", newline="\n")
    argv = [
        "verilator", "--cc", "--exe", "--build", "-j", "0", "-O3",
        "--top-module", codegen.WRAPPER_TOP, "--Mdir", p.rt(bdir / "obj"),
        "-CFLAGS", f"-I{p.rt(HARNESS_DIR)}", "-CFLAGS", "-std=c++17", "-LDFLAGS", "-lz",
    ]
    if trace:
        argv += ["--trace-fst", "-CFLAGS", "-DFS_TRACE=1"]
    if savable:
        # Build only: --json-only introspection implies --timing, which --savable rejects.
        argv += ["--savable", "-CFLAGS", "-DFS_SAVABLE=1"]
    argv += build_args(m) + common_args(m, p) + source_args(m, p) + [p.rt(bdir / "framescope_top.sv")]
    argv += [p.rt(HARNESS_DIR / f) for f in HARNESS_SOURCES] + [p.rt(bdir / "framescope_bindings.cpp")]
    log(f"verilating {m.top} ({len(m.sources)} design files) with {runtime.name}")
    rc = runtime.run(argv, p.mounts, p.work, bdir / "build.log")
    if rc != 0 or not binary.is_file():
        raise FramescopeError(f"build failed (log: {bdir / 'build.log'}):\n{_errors(bdir / 'build.log', p.pm)}")
    (bdir / "ok").write_text("")
    return BuildResult(bdir, binary, ports, False, time.monotonic() - t0, trace, _options(m), savable)


def _options(m: Manifest) -> dict:
    return {"cxx_opt": m.build.cxx_opt, "cxx_flags": list(m.build.cxx_flags), "threads": m.build.threads,
            "x_initial": m.build.x_initial, "x_assign": m.build.x_assign, "coverage": m.build.coverage}


_MSG = re.compile(r"^%(Warning|Error)(?:-([A-Z0-9_]+))?: (?:(.+?):(\d+):(\d+): )?(.*)$")


def lint(m: Manifest, runtime: Runtime, log: Log, limit: int = 200) -> dict:
    runtime.prepare(log)
    p = plan(m, runtime)
    logfile = p.work / "lint.log"
    argv = ["verilator", "--lint-only", "-Wall", "-Wno-fatal", "--timescale", "1ns/1ps", *m.verilator_args,
            *[f"+incdir+{p.rt(d)}" for d in m.include_dirs],
            *[f"+define+{k}={v}" for k, v in m.defines.items()],
            "--top-module", m.top, *source_args(m, p)]
    log(f"linting {m.top}")
    rc = runtime.run(argv, p.mounts, p.work, logfile)
    messages, counts = [], {}
    for line in logfile.read_text(encoding="utf-8", errors="replace").splitlines():
        mt = _MSG.match(line)
        if not mt:
            continue
        severity, code, file, ln, col, text = mt.groups()
        code = code or severity.upper()
        counts[code] = counts.get(code, 0) + 1
        if len(messages) < limit:
            messages.append({
                "severity": severity.lower(),
                "code": code,
                "file": str(p.pm.to_host(file)) if file else None,
                "line": int(ln) if ln else None,
                "col": int(col) if col else None,
                "message": p.pm.rewrite(text),
            })
    errors = sum(1 for msg in messages if msg["severity"] == "error")
    return {
        "ok": rc == 0 and errors == 0,
        "counts": dict(sorted(counts.items(), key=lambda kv: -kv[1])),
        "messages": messages,
        "truncated": sum(counts.values()) > len(messages),
        "log": str(logfile),
    }


def _covering_dirs(dirs: Iterable[Path]) -> list[Path]:
    """Smallest set of directories containing all of `dirs`, in a stable order."""
    chosen: list[Path] = []
    for d in sorted({Path(d).resolve() for d in dirs}, key=lambda d: (len(d.parts), str(d))):
        if not any(d.is_relative_to(c) for c in chosen):
            chosen.append(d)
    return chosen


def _file_digests(files: Iterable[Path]) -> list[str]:
    return [f"{f}:{hashlib.sha256(f.read_bytes()).hexdigest()}" for f in files]


def _digest(parts: Iterable[str]) -> str:
    h = hashlib.sha256()
    for part in parts:
        h.update(part.encode("utf-8", "surrogateescape"))
        h.update(b"\0")
    return h.hexdigest()


def _errors(logfile: Path, pm: PathMap, limit: int = 40) -> str:
    try:
        lines = logfile.read_text(encoding="utf-8", errors="replace").splitlines()
    except FileNotFoundError:
        return "(no log)"
    picked = [ln for ln in lines if ln.startswith("%Error") or ": error:" in ln]
    return pm.rewrite("\n".join((picked or lines[-limit:])[:limit]))
