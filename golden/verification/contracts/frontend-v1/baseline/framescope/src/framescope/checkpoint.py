"""Boot checkpoints: simulate the first N frames once, save the simulator state
(Verilator --savable plus the harness's own state), and start later runs from
it instead of time 0.

A checkpoint is taken at the VSYNC leading edge that ends frame N-1 (frame N
starts), after that edge's probes and dumps and before frame N's stimulus, so a
restored run continues exactly where a cold run would be. It is reusable by any
run of the same binary whose stimulus up to that point is identical: the same
time-triggered lines up to the checkpoint time (reset, --set, early ns/us/ms
events) and the same frame/line-timed lines for frames below N.

The boot run saves every frame's PNGs (and raster PNGs) and every memory dump
before the checkpoint, plus its event stream, so a restored run reports
frames 0..N-1 exactly like a cold run; the files are copied into its run
directory according to its --save/--dump selection.

Layout: <work_dir>/checkpoints/<key>/{meta.json, state/model.bin,
state/harness.bin, vga/..., dumps/...}. Safe to delete at any time.
"""

from __future__ import annotations

import hashlib
import json
import shutil
import time
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path

from . import FramescopeError
from .build import BuildResult, Plan, plan
from .manifest import Manifest
from .rundir import new_dir
from .runtime import Log, Runtime

CHECKPOINT_DIR = "checkpoints"
_FORMAT = 1
# Events of the boot run that describe frames before the checkpoint.
_PRE_EVENTS = ("frame", "probes", "dump", "stim", "send", "uart_line", "uart_byte", "uart_error", "uart_sent")
_PATH_KEYS = ("png", "raster_png", "path")


class CheckpointUnavailable(FramescopeError):
    """The run cannot start from a checkpoint; it runs from time 0 instead."""


@dataclass
class Checkpoint:
    path: Path
    frames: int
    t_ps: int
    events: list[dict]  # pre-checkpoint events; file paths relative to `path`
    created: bool
    boot_wall_s: float

    @property
    def state(self) -> Path:
        return self.path / "state"

    def to_json(self) -> dict:
        return {"restored": True, "frames": self.frames, "t_ms": round(self.t_ps / 1e9, 6), "path": str(self.path),
                "created": self.created, "boot_wall_s": self.boot_wall_s}


def simulate(runtime: Runtime, p: Plan, argv: list[str], run_dir: Path, log: Log | None = None, *,
             answer: Callable[[dict], str] | None = None, errors: list[str] | None = None) -> tuple[list[dict], int]:
    """Runs the simulator, returns its JSON events (paths mapped to the host) and exit code.

    With `answer`, the simulator's stdin is a pipe and every event marked
    "await" gets `answer(event)` written back (host processes on UART links). If
    `answer` raises, the message goes to `errors` and the simulator is killed.
    """
    events: list[dict] = []
    t0 = time.monotonic()
    with (
        open(run_dir / "sim.log", "w", encoding="utf-8", errors="replace") as errf,
        runtime.popen(argv, p.mounts, p.work, errf, stdin=answer is not None) as proc,
    ):
        assert proc.stdout is not None
        for line in proc.stdout:
            line = line.strip()
            if not line.startswith("{"):
                continue
            try:
                ev = json.loads(line)
            except json.JSONDecodeError:
                continue
            for key in _PATH_KEYS:
                if key in ev:
                    ev[key] = str(p.pm.to_host(ev[key]))
            events.append(ev)
            if log and ev.get("event") == "frame":
                log(f"{ev['monitor']}: frame {ev['index']} crc={ev['crc32']} ({time.monotonic() - t0:.1f}s)")
            if answer is not None and ev.get("await"):
                try:
                    reply = answer(ev)
                    assert proc.stdin is not None
                    proc.stdin.write(reply + "\n")
                    proc.stdin.flush()
                except (FramescopeError, OSError) as e:
                    (errors if errors is not None else []).append(str(e))
                    proc.kill()
                    break
        rc = proc.wait()
    return events, rc


def _kind(line: str) -> tuple[str, str]:
    """(trigger kind t/f/p, when) of a stimulus line; UART byte lines (ut/uf/up) count like t/f/p."""
    kind, at = line.split()[:2]
    return (kind[1:] if len(kind) == 2 and kind[0] == "u" else kind), at


def check_hosts(ck: Checkpoint, hosts: dict) -> None:
    """Refuses a checkpoint for a run with host processes when a hosted link
    received a line before the checkpoint: a cold run's host would have seen
    (and maybe answered) it, which the boot run (no hosts) cannot reproduce.
    Hosts are started fresh for a restored run and see only later lines."""
    for link in hosts:
        n = sum(1 for e in ck.events if e.get("event") == "uart_line" and e.get("monitor") == link)
        if n:
            raise CheckpointUnavailable(
                f"UART link '{link}' received {n} line(s) before the frame-{ck.frames} checkpoint, which its "
                "--host would have answered; running from time 0")


def consumed(lines: list[str], frames: int, t_ps: int) -> list[str]:
    """The stimulus lines that fire before a checkpoint at frame `frames` and
    time `t_ps`, in the order the harness applies them."""
    timed, framed, placed = [], [], []
    for ln in lines:
        kind, at = _kind(ln)
        if kind == "t" and int(at) <= t_ps:
            timed.append((int(at), ln))
        elif kind == "f" and int(at) < frames:
            framed.append((int(at), ln))
        elif kind == "p":
            pos = tuple(int(x) for x in at.split(":"))
            if pos[0] < frames:
                placed.append((pos, ln))
    key = lambda item: item[0]  # noqa: E731  (sorted() is stable, like the harness's stable_sort)
    return [ln for group in (timed, framed, placed) for _, ln in sorted(group, key=key)]


def _boot_lines(lines: list[str], frames: int) -> list[str]:
    """Stimulus for the boot run: everything that may fire before frame `frames`."""
    out = []
    for ln in lines:
        kind, at = _kind(ln)
        if kind == "t" or int(at.split(":")[0]) < frames:
            out.append(ln)
    return out


def find(m: Manifest, br: BuildResult, frames: int, lines: list[str]) -> Checkpoint | None:
    root = m.work_dir / CHECKPOINT_DIR
    for meta_file in sorted(root.glob("*/meta.json")):
        try:
            meta = json.loads(meta_file.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if (meta.get("format") == _FORMAT and meta.get("build") == br.build_dir.name and meta.get("frames") == frames
                and meta.get("consumed") == consumed(lines, frames, meta["t_ps"])
                and (meta_file.parent / "state" / "model.bin").is_file()):
            return Checkpoint(meta_file.parent, frames, meta["t_ps"], meta["events"], False, meta["boot_wall_s"])
    return None


def ensure(m: Manifest, runtime: Runtime, log: Log, br: BuildResult, frames: int, lines: list[str]) -> Checkpoint:
    """A checkpoint after `frames` frames that a run with stimulus `lines` can
    start from: cached, else created by a boot run. Raises CheckpointUnavailable."""
    if m.build.randomized:
        raise CheckpointUnavailable("randomized runs start from time 0 (RNG checkpoint state is not verified)")
    if not br.savable:
        raise CheckpointUnavailable("the simulator was not built with --savable")
    found = find(m, br, frames, lines)
    if found:
        return found
    root = m.work_dir / CHECKPOINT_DIR
    tmp = new_dir(root, f"tmp-{frames}")
    try:
        boot = _boot_lines(lines, frames)
        (tmp / "stimulus.txt").write_text("\n".join(boot) + "\n", encoding="utf-8", newline="\n")
        p = plan(m, runtime)
        from .run import time_budget_ps  # noqa: PLC0415  (run imports this module)

        argv = [p.rt(br.binary), "--out", p.rt(tmp), "--frames", str(frames), "--max-time-ps",
                str(time_budget_ps(frames)), "--stim", p.rt(tmp / "stimulus.txt"), "--save", "all", "--raster",
                "--dump", "all" if m.dumps else "none", "--checkpoint-save", p.rt(tmp / "state")]
        log(f"checkpoint: booting {frames} frame(s) -> {tmp}")
        events, rc = simulate(runtime, p, argv, tmp)
        errors = [e["message"] for e in events if e.get("event") == "error"]
        saved = next((e for e in events if e.get("event") == "checkpoint" and e.get("state") == "saved"), None)
        if errors or saved is None or rc != 0:
            reason = "; ".join(errors) or f"boot run exited with code {rc} without saving a checkpoint"
            raise CheckpointUnavailable(f"boot run failed: {reason}")
        end = next((e for e in events if e.get("event") == "end"), {})
        pre = []
        for e in events:
            if e.get("event") in _PRE_EVENTS:
                e = dict(e)
                for key in _PATH_KEYS:
                    if key in e:
                        e[key] = Path(e[key]).relative_to(tmp).as_posix()
                pre.append(e)
        t_ps = int(saved["t_ps"])
        used = consumed(boot, frames, t_ps)
        meta = {"format": _FORMAT, "build": br.build_dir.name, "frames": frames, "t_ps": t_ps, "consumed": used,
                "boot_wall_s": round(end.get("wall_s", 0.0), 2), "events": pre}
        (tmp / "meta.json").write_text(json.dumps(meta, indent=1), encoding="utf-8")
    except BaseException:
        shutil.rmtree(tmp, ignore_errors=True)
        raise
    key = hashlib.sha256(json.dumps([br.build_dir.name, frames, used]).encode()).hexdigest()[:16]
    final = root / key
    try:
        tmp.rename(final)
    except OSError:  # a concurrent run created the same checkpoint first
        shutil.rmtree(tmp, ignore_errors=True)
        found = find(m, br, frames, lines)
        if found is None:
            raise CheckpointUnavailable(f"could not store the checkpoint in {final}") from None
        return found
    return Checkpoint(final, frames, t_ps, meta["events"], True, meta["boot_wall_s"])


def selected(spec: str, index: int, frames: int) -> bool:
    """Whether frame `index` is in a validated all | last | none | 0,3 selection."""
    if spec in ("all", "none"):
        return spec == "all"
    if spec == "last":
        return index == frames - 1
    return index in {int(x) for x in spec.split(",")}


def replay(ck: Checkpoint, run_dir: Path, *, frames: int, save: str, dump: str, raster: bool) -> list[dict]:
    """The checkpoint's events for frames before it, with the PNGs and dumps
    this run's --save/--dump select copied into `run_dir` (as a cold run would
    have written them)."""
    out = []
    for e in ck.events:
        e = dict(e)
        kind = e["event"]
        if kind == "frame":
            keep = selected(save, e["index"], frames)
            if not keep:
                e.pop("png", None)
            # The harness writes a raster PNG for saved frames without an active-area crop, or with --raster.
            if not (keep and (raster or e.get("active_source") == "none")):
                e.pop("raster_png", None)
        elif kind == "dump" and not selected(dump, e["frame"], frames):
            continue
        for key in _PATH_KEYS:
            if key in e:
                dst = run_dir / e[key]
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ck.path / e[key], dst)
                e[key] = str(dst)
        out.append(e)
    return out
