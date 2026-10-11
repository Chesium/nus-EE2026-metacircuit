"""Persistent frame-boundary simulator, with a synchronous JSON-lines CLI."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path
from typing import TextIO

from . import FramescopeError, protocols
from .build import build, plan
from .manifest import Manifest
from .rundir import new_dir
from .run import _to_signed, time_budget_ps, initialization_options
from .runtime import Log, Runtime
from .stimulus import compile_lines, raster_limits


class Session:
    """One cold simulator process. Requests are synchronous; no clocks run idle.

    Use as a context manager, or call close() to stop the owned process. Invalid
    requests return errors without changing simulation state.
    """

    def __init__(self, m: Manifest, runtime: Runtime, log: Log, *, out: Path | None = None,
                 sets: list[str] | None = None, save: str = "none", seed: int | None = None):
        if protocols.primary(m) is None:
            raise FramescopeError("session requires a frame monitor")
        if save not in ("all", "none"):
            raise FramescopeError("session --save expects all or none")
        if m.build.coverage:
            raise FramescopeError("session coverage artifacts are unsupported; use run --coverage-from")
        self.initialization = initialization_options(m, seed)
        self.m = m
        self.br = build(m, runtime, log)
        lines = compile_lines(m, self.br.ports, None, sets or [])
        self.out = out.resolve() if out else new_dir(m.work_dir / "sessions")
        self.out.mkdir(parents=True, exist_ok=True)
        self.p = plan(m, runtime, extra_writable=[self.out])
        stim = self.out / "stimulus.txt"
        stim.write_text("\n".join(lines) + "\n", encoding="utf-8")
        self.inputs = {p.name for p in self.br.ports if p.direction == "input"} - {c.name for c in m.clocks}
        self.inputs |= set(m.virtual_inputs)
        self.widths: dict = {}
        self.closed = False
        self.errf = (self.out / "sim.log").open("w", encoding="utf-8")
        try:
            self.proc = runtime.popen([self.p.rt(self.br.binary), "--session", "--out", self.p.rt(self.out),
                                       "--stim", self.p.rt(stim), "--save", save,
                                       "--seed", str(self.initialization["seed"]),
                                       "--rand-reset", str(self.initialization["rand_reset"])],
                                      self.p.mounts, self.p.work, self.errf, stdin=True)
            self.state = self._receive()
            if not self.state["ok"]:
                raise FramescopeError(self.state["error"])
        except BaseException:
            self.close()
            raise

    def _receive(self) -> dict:
        events = []
        errors = []
        assert self.proc.stdout is not None
        for line in self.proc.stdout:
            try:
                ev = json.loads(line)
            except json.JSONDecodeError:
                continue
            for key in ("png", "raster_png", "path"):
                if key in ev:
                    ev[key] = str(self.p.pm.to_host(ev[key]))
            kind = ev.get("event")
            if kind == "start":
                self.widths = ev.get("probe_widths", {})
            if kind == "probes":
                ev["values"] = self._signed(ev["values"])
            if kind == "session_result":
                ev.pop("event")
                ev["probes"] = self._signed(ev["probes"])
                ev["events"] = events
                ev["initialization"] = self.initialization
                if errors:
                    ev.update(ok=False, error="; ".join(errors))
                return ev
            events.append(ev)
            if kind == "error":
                errors.append(ev["message"])
            if kind == "end":
                errors.append(f"simulation stopped: {ev['stop_reason']}")
                break
        self.closed = True
        return {"ok": False, "error": "; ".join(errors) or "simulator closed before responding", "events": events}

    def _signed(self, values: dict) -> dict:
        signed = {p.name for p in self.m.probes if p.signed}
        return {k: _to_signed(v, self.widths.get(k, 64)) if k in signed else v for k, v in values.items()}

    def _exchange(self, line: str) -> dict:
        if self.closed:
            return {"ok": False, "error": "session is closed"}
        assert self.proc.stdin is not None
        try:
            self.proc.stdin.write(line + "\n")
            self.proc.stdin.flush()
            result = self._receive()
        except OSError as e:
            self.closed = True
            return {"ok": False, "error": f"session transport failed: {e}"}
        self.state = result
        return result

    def request(self, request: object) -> dict:
        """Handle one JSON request, echoing its optional id in one response."""
        ident = request.get("id") if isinstance(request, dict) else None
        try:
            if not isinstance(request, dict):
                raise FramescopeError("request must be an object")
            op = request.get("op")
            if op == "step":
                count = request.get("frames", 1)
                if type(count) is not int or not 1 <= count <= 10000:
                    raise FramescopeError("frames must be an integer in 1..10000")
                budget = time_budget_ps(count)
                if "max_time_ms" in request:
                    # Like run --max-time-ms: a cold design may need longer than the default
                    # per-frame allowance before its first frame boundary.
                    limit = request["max_time_ms"]
                    if type(limit) not in (int, float) or not 0 < limit <= 1e6 or limit != limit:
                        raise FramescopeError("max_time_ms must be a number in (0, 1e6]")
                    budget = max(1, int(limit * 1e9))
                result = self._exchange(f"step {count} {budget}")
            elif op == "poke":
                values = request.get("values")
                if not isinstance(values, dict) or not values:
                    raise FramescopeError("values must be a nonempty input mapping")
                position = ""
                if "pixel" in request and "line" not in request:
                    raise FramescopeError("pixel needs line")
                if "line" in request:
                    line, pixel = request["line"], request.get("pixel", 0)
                    lines, pixels, _ = raster_limits(self.m)
                    if type(line) is not int or type(pixel) is not int or not 0 <= line < lines or not 0 <= pixel < pixels:
                        raise FramescopeError(f"position needs line in 0..{lines-1}, pixel in 0..{pixels-1}")
                    position = f"_at {line} {pixel}"
                encoded = []
                for name, value in values.items():
                    if name not in self.inputs or any(c.isspace() for c in name):
                        raise FramescopeError(f"'{name}' is not a settable input")
                    if type(value) is not int or not -(1 << 63) <= value < (1 << 64):
                        raise FramescopeError(f"'{name}' needs an integer in -2^63..2^64-1")
                    if name in self.m.virtual_inputs and value >= (1 << 63):
                        raise FramescopeError(f"virtual input '{name}' needs a signed 64-bit integer")
                    if value >= (1 << 63):
                        value -= 1 << 64
                    encoded.append(f"{name} {value}")
                result = self._exchange(f"poke{position} {len(encoded)} " + " ".join(encoded))
            elif op == "probes":
                result = self._exchange("probes")
            elif op == "memory":
                name = request.get("name")
                if not isinstance(name, str) or name not in {d.name for d in self.m.dumps}:
                    raise FramescopeError("name must identify a declared [[dump]] memory")
                result = self._exchange(f"memory {name}")
                if result["ok"]:
                    event = next(e for e in result["events"] if e.get("event") == "dump")
                    result["memory"] = json.loads(Path(event["path"]).read_text(encoding="utf-8"))
            elif op == "stop":
                result = self._exchange("stop")
                self.close()
            else:
                raise FramescopeError("op must be step, poke, probes, memory or stop")
        except (FramescopeError, OSError, ValueError) as e:
            result = {"ok": False, "error": str(e)}
        return {"id": ident, **result}

    def close(self) -> None:
        """EOF lets the harness finalize. Kill only our process if it won't exit."""
        proc = getattr(self, "proc", None)
        if proc is not None:
            if proc.stdin is not None and not proc.stdin.closed:
                proc.stdin.close()
                proc.stdin = None
            try:
                proc.communicate(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.communicate()
            if proc.stdout is not None:
                proc.stdout.close()
        self.closed = True
        if hasattr(self, "errf"):
            self.errf.close()

    def __enter__(self) -> Session:
        return self

    def __exit__(self, *_args) -> None:
        self.close()


def serve(session: Session, source: TextIO, sink: TextIO) -> None:
    """Exactly one response for every input line, including malformed JSON."""
    for line in source:
        request = None
        try:
            request = json.loads(line, parse_constant=_invalid_constant)
            response = session.request(request)
        except (ValueError, RecursionError) as e:
            response = {"id": None, "ok": False, "error": f"invalid JSON: {e}"}
        sink.write(json.dumps(response, allow_nan=False) + "\n")
        sink.flush()
        if isinstance(request, dict) and request.get("op") == "stop":
            break


def _invalid_constant(value: str) -> None:
    raise ValueError(f"nonfinite number {value}")
