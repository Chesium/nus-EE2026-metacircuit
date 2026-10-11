"""Loads and validates framescope.toml."""

from __future__ import annotations

import fnmatch
import os
import re
import tomllib
from dataclasses import dataclass, field
from pathlib import Path

from . import FramescopeError

IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*$")
_VAR = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}")

_TOP_KEYS = {
    "vars", "design", "clocks", "inputs", "virtual_inputs", "inouts", "reset", "monitor", "probes", "dump", "build",
}
_DESIGN_KEYS = {
    "top", "root", "sources", "exclude", "extra_sources", "include_dirs",
    "defines", "parameters", "verilator_args",
}
_INOUT_MODES = {"none", "pullup", "pulldown"}
# A hierarchical path below the wrapper's `dut` instance, with optional
# constant indices for generate blocks or instance arrays: dut.gen[0].u_ram.mem
_SEGMENT = r"[A-Za-z_][A-Za-z0-9_$]*(?:\[\d+\])*"
HIER_PATH = re.compile(rf"dut(?:\.{_SEGMENT})+$")


@dataclass(frozen=True)
class Clock:
    name: str
    freq_hz: float
    phase_deg: float = 0.0

    @property
    def period_ps(self) -> int:
        return round(1e12 / self.freq_hz)

    @property
    def offset_ps(self) -> int:
        return round(self.period_ps * self.phase_deg / 360.0)


@dataclass(frozen=True)
class Reset:
    port: str
    active: int
    duration_ns: float


@dataclass
class MonitorSpec:
    name: str
    protocol: str
    signals: dict[str, str]
    options: dict[str, object]


@dataclass(frozen=True)
class Probe:
    """A named expression sampled once per frame of the first monitor."""

    name: str
    expr: str  # SystemVerilog over ports and dut.* paths, at most 64 bits
    signed: bool = False


@dataclass(frozen=True)
class Dump:
    """A memory (unpacked array) written out at the end of selected frames."""

    name: str
    path: str  # hierarchical path to the array, e.g. dut.u_ram.mem


@dataclass(frozen=True)
class BuildOptions:
    """[build] settings that only affect the simulator's compilation."""

    cxx_opt: str = "-O2"  # C++ optimisation of the model and harness (Verilator's own default is -Os)
    cxx_flags: tuple[str, ...] = ()  # extra C++ compiler flags, e.g. ("-march=native",)
    threads: int = 1  # Verilator --threads; 1 builds a single-threaded model
    x_initial: str = "fast"
    x_assign: str = "fast"

    coverage: bool = False

    @property
    def randomized(self) -> bool:
        return "unique" in (self.x_initial, self.x_assign)


_CXX_OPT = re.compile(r"-O[0-3sgz]?$|-Ofast$")


@dataclass
class Manifest:
    path: Path
    top: str
    root: Path
    sources: list[Path]
    extra_sources: list[Path]
    include_dirs: list[Path]
    defines: dict[str, str]
    parameters: dict[str, str]
    verilator_args: list[str]
    clocks: list[Clock]
    inputs: dict[str, int]
    virtual_inputs: dict[str, int]
    inouts: dict[str, str]
    reset: Reset | None
    monitors: list[MonitorSpec]
    work_dir: Path
    probes: list[Probe] = field(default_factory=list)
    dumps: list[Dump] = field(default_factory=list)
    build: BuildOptions = field(default_factory=BuildOptions)

    @property
    def dir(self) -> Path:
        return self.path.parent


def load(path: str | os.PathLike[str]) -> Manifest:
    p = Path(path).resolve()
    if p.is_dir():
        p = p / "framescope.toml"
    try:
        data = tomllib.loads(p.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise FramescopeError(f"manifest not found: {p}") from None
    except tomllib.TOMLDecodeError as e:
        raise FramescopeError(f"{p}: {e}") from None
    _check_keys(data, _TOP_KEYS, "top level")

    variables = {str(k): str(v) for k, v in _table(data, "vars").items()}

    def expand(s: object, where: str) -> str:
        if not isinstance(s, str):
            raise FramescopeError(f"{where}: expected a string, got {s!r}")
        return _expand(s, variables, where)

    design = _table(data, "design")
    _check_keys(design, _DESIGN_KEYS, "[design]")
    top = design.get("top")
    if not isinstance(top, str) or not IDENT.match(top):
        raise FramescopeError("[design].top must name the top-level module")
    root = _resolve(p.parent, expand(design.get("root", "."), "design.root"))
    if not root.is_dir():
        raise FramescopeError(f"design.root is not a directory: {root}")

    excludes = [expand(e, "design.exclude") for e in _list(design, "exclude")]
    sources = _glob_all(root, [expand(s, "design.sources") for s in _list(design, "sources")], excludes, "design.sources")
    if not sources:
        raise FramescopeError("[design].sources matched no files")
    extra = _glob_all(p.parent, [expand(s, "design.extra_sources") for s in _list(design, "extra_sources")], [], "design.extra_sources")
    include_dirs = [_resolve(root, expand(d, "design.include_dirs")) for d in _list(design, "include_dirs")]

    clocks = []
    for name, spec in _table(data, "clocks").items():
        _ident(name, "clocks")
        if isinstance(spec, (int, float)):
            spec = {"freq_hz": spec}
        _check_keys(spec, {"freq_hz", "phase_deg"}, f"clocks.{name}")
        freq = spec.get("freq_hz")
        if not isinstance(freq, (int, float)) or freq <= 0:
            raise FramescopeError(f"clocks.{name}.freq_hz must be a positive number")
        clocks.append(Clock(name, float(freq), float(spec.get("phase_deg", 0.0))))
    if not clocks:
        raise FramescopeError("define at least one clock under [clocks]")

    inouts = {}
    for name, mode in _table(data, "inouts").items():
        if mode not in _INOUT_MODES:
            raise FramescopeError(f"inouts.{name} must be one of {sorted(_INOUT_MODES)}")
        inouts[name] = mode

    reset = None
    if "reset" in data:
        r = _table(data, "reset")
        _check_keys(r, {"port", "active", "duration_ns"}, "[reset]")
        if not isinstance(r.get("port"), str):
            raise FramescopeError("[reset].port is required")
        reset = Reset(r["port"], _int(r.get("active", 1), "reset.active") & 1, float(r.get("duration_ns", 100)))

    monitors = []
    for i, mon in enumerate(data.get("monitor", [])):
        where = f"[[monitor]] #{i + 1}"
        if not isinstance(mon, dict):
            raise FramescopeError(f"{where} must be a table")
        name = mon.get("name")
        if not isinstance(name, str) or not IDENT.match(name):
            raise FramescopeError(f"{where}: name must be an identifier")
        if any(m.name == name for m in monitors):
            raise FramescopeError(f"{where}: duplicate monitor name '{name}'")
        if name == "probe":
            raise FramescopeError(f"{where}: the monitor name 'probe' is reserved")
        protocol = mon.get("protocol")
        if not isinstance(protocol, str):
            raise FramescopeError(f"monitor '{name}': protocol is required")
        signals = mon.get("signals", {})
        if not isinstance(signals, dict) or not all(isinstance(v, str) for v in signals.values()):
            raise FramescopeError(f"monitor '{name}': signals must map names to SystemVerilog expressions")
        options = {k: v for k, v in mon.items() if k not in {"name", "protocol", "signals"}}
        monitors.append(MonitorSpec(name, protocol, dict(signals), options))

    probes = _probes(_table(data, "probes"))
    dumps = _dumps(data.get("dump", []))

    build = _table(data, "build")
    _check_keys(build, {"work_dir", "cxx_opt", "cxx_flags", "threads", "x_initial", "x_assign", "coverage"}, "[build]")
    work_dir = _resolve(p.parent, expand(build.get("work_dir", ".framescope"), "build.work_dir"))
    build_options = _build_options(build)

    verilator_args = [str(a) for a in _list(design, "verilator_args")]
    for arg in verilator_args:
        if arg.split("=", 1)[0] in ("--x-initial", "--x-assign", "-x-initial", "-x-assign"):
            raise FramescopeError("set x_initial/x_assign under [build], not design.verilator_args")

    return Manifest(
        path=p,
        top=top,
        root=root,
        sources=sources,
        extra_sources=extra,
        include_dirs=include_dirs,
        defines={str(k): str(v) for k, v in _table(design, "defines").items()},
        parameters={str(k): str(v) for k, v in _table(design, "parameters").items()},
        verilator_args=verilator_args,
        clocks=clocks,
        inputs={k: _int(v, f"inputs.{k}") for k, v in _table(data, "inputs").items()},
        virtual_inputs={k: _int(v, f"virtual_inputs.{k}") for k, v in _table(data, "virtual_inputs").items()},
        inouts=inouts,
        reset=reset,
        monitors=monitors,
        work_dir=work_dir,
        probes=probes,
        dumps=dumps,
        build=build_options,
    )


def _build_options(build: dict) -> BuildOptions:
    opt = build.get("cxx_opt", BuildOptions.cxx_opt)
    if not isinstance(opt, str) or not _CXX_OPT.match(opt):
        raise FramescopeError(f"build.cxx_opt must be a compiler optimisation flag such as -O2 or -Os, got {opt!r}")
    flags = _list(build, "cxx_flags")
    if not all(isinstance(f, str) and f.startswith("-") for f in flags):
        raise FramescopeError("build.cxx_flags must be a list of compiler flags (strings starting with '-')")
    threads = build.get("threads", 1)
    if isinstance(threads, bool) or not isinstance(threads, int) or threads < 1:
        raise FramescopeError(f"build.threads must be a positive integer, got {threads!r}")
    modes = {}
    for name, allowed in (("x_initial", {"0", "fast", "unique"}),
                          ("x_assign", {"0", "1", "fast", "unique"})):
        value = build.get(name, "fast")
        if not isinstance(value, str) or value not in allowed:
            raise FramescopeError(f"build.{name} must be one of {sorted(allowed)}, got {value!r}")
        modes[name] = value
    coverage = build.get("coverage", False)
    if not isinstance(coverage, bool):
        raise FramescopeError("build.coverage must be true or false")
    return BuildOptions(opt, tuple(flags), threads, coverage=coverage, **modes)


def _probes(table: dict) -> list[Probe]:
    """[probes]: name = "expr" or name = { expr = "...", signed = true }."""
    out = []
    for name, spec in table.items():
        where = f"probes.{name}"
        _ident(name, "probes")
        if isinstance(spec, str):
            spec = {"expr": spec}
        _check_keys(spec, {"expr", "signed"}, where)
        expr = spec.get("expr")
        if not isinstance(expr, str) or not expr.strip():
            raise FramescopeError(f"{where}: expr must be a SystemVerilog expression")
        signed = spec.get("signed", False)
        if not isinstance(signed, bool):
            raise FramescopeError(f"{where}: signed must be true or false")
        out.append(Probe(name, expr.strip(), signed))
    return out


def _dumps(items: object) -> list[Dump]:
    """[[dump]] tables: name (identifier) and path (dut.<hierarchy>.<array>)."""
    if not isinstance(items, list):
        raise FramescopeError("[[dump]] must be an array of tables")
    out: list[Dump] = []
    for i, d in enumerate(items):
        where = f"[[dump]] #{i + 1}"
        _check_keys(d, {"name", "path"}, where)
        name, path = d.get("name"), d.get("path")
        if not isinstance(name, str) or not IDENT.match(name):
            raise FramescopeError(f"{where}: name must be an identifier")
        if any(x.name == name for x in out):
            raise FramescopeError(f"{where}: duplicate dump name '{name}'")
        if not isinstance(path, str) or not HIER_PATH.match(path):
            raise FramescopeError(
                f"{where}: path must be a hierarchical path to an unpacked array below the design "
                f"instance, e.g. 'dut.u_ram.mem'; got {path!r}"
            )
        out.append(Dump(name, path))
    return out


def _expand(s: str, variables: dict[str, str], where: str) -> str:
    def sub(m: re.Match[str]) -> str:
        name = m.group(1)
        if name in os.environ:
            return os.environ[name]
        if name in variables:
            return variables[name]
        raise FramescopeError(f"{where}: ${{{name}}} is not set (define it under [vars] or in the environment)")

    return _VAR.sub(sub, s)


def _resolve(base: Path, s: str) -> Path:
    p = Path(s)
    return (p if p.is_absolute() else base / p).resolve()


def _glob_all(base: Path, patterns: list[str], excludes: list[str], where: str) -> list[Path]:
    out: list[Path] = []
    seen: set[Path] = set()
    for pat in patterns:
        magic = any(c in pat for c in "*?[")
        if magic:
            matches = sorted(base.glob(pat))
        else:
            candidate = _resolve(base, pat)
            if not candidate.is_file():
                raise FramescopeError(f"{where}: file not found: {candidate}")
            matches = [candidate]
        if not matches:
            raise FramescopeError(f"{where}: '{pat}' matched no files under {base}")
        for m in matches:
            if not m.is_file():
                continue
            m = m.resolve()
            try:
                rel = m.relative_to(base).as_posix()
            except ValueError:
                rel = m.as_posix()
            if any(fnmatch.fnmatchcase(rel, e) for e in excludes):
                continue
            if m not in seen:
                seen.add(m)
                out.append(m)
    return out


def _check_keys(table: object, allowed: set[str], where: str) -> None:
    if not isinstance(table, dict):
        raise FramescopeError(f"{where} must be a table")
    unknown = sorted(set(table) - allowed)
    if unknown:
        raise FramescopeError(f"{where}: unknown key(s) {unknown}; allowed: {sorted(allowed)}")


def _table(data: dict, key: str) -> dict:
    value = data.get(key, {})
    if not isinstance(value, dict):
        raise FramescopeError(f"[{key}] must be a table")
    return value


def _list(data: dict, key: str) -> list:
    value = data.get(key, [])
    if isinstance(value, str):
        return [value]
    if not isinstance(value, list):
        raise FramescopeError(f"{key} must be a list")
    return value


def _int(value: object, where: str) -> int:
    if isinstance(value, bool):
        return int(value)
    if isinstance(value, int):
        return value
    raise FramescopeError(f"{where} must be an integer, got {value!r}")


def _ident(name: str, where: str) -> None:
    if not IDENT.match(name):
        raise FramescopeError(f"{where}: '{name}' is not a valid identifier")
