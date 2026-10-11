"""Host processes attached to link monitors (`run --host LINK=CMD`).

A host is any program that speaks JSON lines on stdin/stdout. framescope
writes one object per line to its stdin:

    {"event": "start", "link": "uart", "baud": 115200, ...}      once, before the simulation
    {"event": "line", "link": "uart", "index": 0, "text": "...", ...}  per received line
    {"event": "end"}                                              then stdin closes

and the host answers every "line" with exactly one JSON object on stdout:

    {}                                     nothing to send
    {"text": "...\\r\\n"}                   or {"hex": "4041"} or {"bytes": [64, 65]}
    {"text": "...", "delay_bits": 20}      start that many bit times after the line's end

The simulator waits for the answer before it advances, and the reply starts at
a simulated time derived from the line's end, so a deterministic host gives a
deterministic run. Anything the host prints on stderr goes to
<run>/host_<link>.log.
"""

from __future__ import annotations

import json
import os
import queue
import shlex
import subprocess
import threading
from pathlib import Path

from . import FramescopeError


def parse_specs(specs: list[str], hostable: list[str]) -> dict[str, list[str]]:
    """--host [LINK=]CMD ... -> {link: argv}; LINK may be omitted with one hostable link."""
    out: dict[str, list[str]] = {}
    for spec in specs:
        link, sep, cmd = spec.partition("=")
        if not sep or not link.isidentifier() or " " in link:
            if len(hostable) != 1:
                raise FramescopeError(f"--host '{spec}': write LINK=CMD (links that take a host: {hostable})")
            link, cmd = hostable[0], spec
        if link not in hostable:
            raise FramescopeError(f"--host: '{link}' is not a monitor that takes a host; known: {hostable}")
        if link in out:
            raise FramescopeError(f"--host: '{link}' given twice")
        argv = shlex.split(cmd, posix=os.name != "nt")
        if not argv:
            raise FramescopeError(f"--host {link}: empty command")
        out[link] = argv
    return out


class Host:
    def __init__(self, link: str, argv: list[str], log_path: Path, run_dir: Path, timeout_s: float):
        self.link = link
        self.argv = argv
        self.timeout_s = timeout_s
        self.requests = 0
        self._log = open(log_path, "w", encoding="utf-8", errors="replace")
        env = {**os.environ, "FRAMESCOPE_LINK": link, "FRAMESCOPE_RUN_DIR": str(run_dir)}
        try:
            self.proc = subprocess.Popen(
                argv, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=self._log, text=True,
                encoding="utf-8", errors="replace", bufsize=1, env=env,
            )
        except OSError as e:
            self._log.close()
            raise FramescopeError(f"--host {link}: cannot start {argv[0]!r}: {e}") from None
        self._lines: queue.Queue[str | None] = queue.Queue()
        self._reader = threading.Thread(target=self._read, daemon=True)
        self._reader.start()

    def _read(self) -> None:
        assert self.proc.stdout is not None
        for line in self.proc.stdout:
            self._lines.put(line)
        self._lines.put(None)

    def send(self, msg: dict) -> None:
        try:
            assert self.proc.stdin is not None
            self.proc.stdin.write(json.dumps(msg) + "\n")
            self.proc.stdin.flush()
        except (BrokenPipeError, OSError, ValueError):
            raise FramescopeError(f"host for '{self.link}' exited (code {self.proc.poll()})") from None

    def request(self, msg: dict) -> dict:
        self.requests += 1
        self.send(msg)
        while True:
            try:
                line = self._lines.get(timeout=self.timeout_s)
            except queue.Empty:
                raise FramescopeError(f"host for '{self.link}' did not answer line {msg.get('index')} "
                                      f"within {self.timeout_s:g} s") from None
            if line is None:
                raise FramescopeError(f"host for '{self.link}' exited (code {self.proc.wait()}) "
                                      f"without answering line {msg.get('index')}")
            line = line.strip()
            if not line:
                continue
            try:
                return json.loads(line)
            except json.JSONDecodeError:
                raise FramescopeError(f"host for '{self.link}' printed a non-JSON line {line[:200]!r} "
                                      "(log to stderr instead)") from None

    def close(self) -> int | None:
        try:
            self.send({"event": "end"})
        except FramescopeError:
            pass
        try:
            if self.proc.stdin:
                self.proc.stdin.close()
        except OSError:
            pass
        try:
            rc = self.proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            self.proc.kill()
            rc = self.proc.wait()
        self._reader.join(timeout=5)
        if self.proc.stdout and not self._reader.is_alive():
            self.proc.stdout.close()
        self._log.close()
        return rc

    def kill(self) -> int | None:
        if self.proc.poll() is None:
            self.proc.kill()
        return self.close()
