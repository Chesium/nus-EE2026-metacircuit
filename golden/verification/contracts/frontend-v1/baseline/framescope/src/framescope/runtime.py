"""Where Verilator and the simulation binary run: a container runtime or the host.

Container runtimes (wslc, podman, docker) get the framescope package, the
design and the work directory as bind mounts; PathMap translates between the
host paths the user and agent see and the paths inside the runtime.
"""

from __future__ import annotations

import hashlib
import os
import re
import shutil
import subprocess
import sys
from collections.abc import Callable, Sequence
from dataclasses import dataclass
from pathlib import Path

from . import FramescopeError

PACKAGE_DIR = Path(__file__).resolve().parent
CONTAINERFILE = PACKAGE_DIR / "container" / "Containerfile"
RUNTIMES = ("wslc", "podman", "docker", "native")

Log = Callable[[str], None]


@dataclass(frozen=True)
class Mount:
    host: Path
    target: str  # absolute POSIX path inside the runtime
    writable: bool = False


class PathMap:
    def __init__(self, mounts: Sequence[Mount] | None):
        self._mounts = sorted(mounts or (), key=lambda m: len(m.host.parts), reverse=True)
        self.identity = mounts is None

    def to_rt(self, p: Path) -> str:
        if self.identity:
            return str(p)
        for m in self._mounts:
            if p == m.host or p.is_relative_to(m.host):
                rel = p.relative_to(m.host).as_posix()
                return m.target if rel == "." else f"{m.target}/{rel}"
        raise FramescopeError(f"{p} is outside every mounted directory")

    def to_host(self, s: str) -> Path:
        if self.identity:
            return Path(s)
        for m in sorted(self._mounts, key=lambda m: len(m.target), reverse=True):
            if s == m.target:
                return m.host
            if s.startswith(m.target + "/"):
                return m.host.joinpath(*s[len(m.target) + 1 :].split("/"))
        return Path(s)

    def rewrite(self, text: str) -> str:
        """Replaces runtime paths in tool output (compiler messages) with host paths."""
        if self.identity or not self._mounts:
            return text
        targets = sorted((m.target for m in self._mounts), key=len, reverse=True)
        pattern = re.compile("(" + "|".join(re.escape(t) for t in targets) + r")(/[^\s:'\"),]*)?")
        return pattern.sub(lambda mt: str(self.to_host(mt.group(0))), text)


class Runtime:
    name = ""

    def prepare(self, log: Log) -> None:
        """Makes the runtime usable (e.g. builds the toolchain image)."""

    def identity(self) -> str:
        """Changes whenever the toolchain does; part of build cache keys."""
        raise NotImplementedError

    def path_map(self, mounts: Sequence[Mount]) -> PathMap:
        raise NotImplementedError

    def command(self, argv: Sequence[str], mounts: Sequence[Mount], workdir: Path,
                interactive: bool = False) -> tuple[list[str], Path | None]:
        """`interactive`: the process reads stdin (containers need -i)."""
        raise NotImplementedError

    def describe(self) -> dict:
        raise NotImplementedError

    def run(self, argv: Sequence[str], mounts: Sequence[Mount], workdir: Path, log_path: Path) -> int:
        cmd, cwd = self.command(argv, mounts, workdir)
        with open(log_path, "w", encoding="utf-8", errors="replace") as f:
            return subprocess.run(cmd, cwd=cwd, stdout=f, stderr=subprocess.STDOUT).returncode

    def popen(self, argv: Sequence[str], mounts: Sequence[Mount], workdir: Path, stderr,
              stdin: bool = False) -> subprocess.Popen:
        """Starts `argv` with stdout piped (and stdin too if `stdin`)."""
        cmd, cwd = self.command(argv, mounts, workdir, interactive=stdin)
        return subprocess.Popen(
            cmd, cwd=cwd, stdout=subprocess.PIPE, stderr=stderr, text=True, encoding="utf-8", errors="replace",
            stdin=subprocess.PIPE if stdin else None,
        )


class NativeRuntime(Runtime):
    name = "native"

    def __init__(self, exe: str):
        self.exe = exe

    def identity(self) -> str:
        out = subprocess.run([self.exe, "--version"], capture_output=True, text=True)
        return "native:" + out.stdout.strip()

    def path_map(self, mounts: Sequence[Mount]) -> PathMap:
        return PathMap(None)

    def command(self, argv, mounts, workdir, interactive=False):
        return list(argv), workdir

    def describe(self) -> dict:
        return {"name": self.name, "verilator": self.exe, "identity": self.identity()}


class ContainerRuntime(Runtime):
    def __init__(self, exe: str, name: str):
        self.exe = exe
        self.name = name
        self.image = image_tag()

    def identity(self) -> str:
        return self.image

    def image_present(self) -> bool:
        return subprocess.run([self.exe, "image", "inspect", self.image], capture_output=True).returncode == 0

    def prepare(self, log: Log) -> None:
        if self.image_present():
            return
        self.build_image(log)

    def build_image(self, log: Log) -> None:
        log(f"building toolchain image {self.image} with {self.name} (one-time, ~1 min)")
        rc = subprocess.run(
            [self.exe, "build", "-t", self.image, "-f", str(CONTAINERFILE), str(CONTAINERFILE.parent)],
            stdout=sys.stderr,
            stderr=sys.stderr,
        ).returncode
        if rc != 0:
            raise FramescopeError(f"{self.name} build of {self.image} failed (exit {rc})")

    def path_map(self, mounts: Sequence[Mount]) -> PathMap:
        return PathMap(mounts)

    def command(self, argv, mounts, workdir, interactive=False):
        pm = self.path_map(mounts)
        cmd = [self.exe, "run", "--rm", *(["-i"] if interactive else [])]
        for m in mounts:
            cmd += ["-v", f"{m.host}:{m.target}" + ("" if m.writable else ":ro")]
        cmd += ["-w", pm.to_rt(workdir), "-e", "HOME=/tmp", *self._user_args(), self.image, *argv]
        return cmd, None

    def _user_args(self) -> list[str]:
        if os.name != "posix":
            return []
        if self.name == "podman":
            return ["--userns=keep-id"]
        return ["--user", f"{os.getuid()}:{os.getgid()}"]

    def describe(self) -> dict:
        return {"name": self.name, "exe": self.exe, "image": self.image, "image_present": self.image_present()}


def image_tag() -> str:
    data = CONTAINERFILE.read_bytes().replace(b"\r\n", b"\n")
    return "framescope-toolchain:" + hashlib.sha256(data).hexdigest()[:12]


def detect(preference: str | None = None) -> Runtime:
    choice = preference or os.environ.get("FRAMESCOPE_RUNTIME") or "auto"
    if choice != "auto" and choice not in RUNTIMES:
        raise FramescopeError(f"unknown runtime '{choice}'; choose from {RUNTIMES}")
    names = RUNTIMES if choice == "auto" else (choice,)
    for name in names:
        exe = shutil.which("verilator" if name == "native" else name)
        if not exe:
            continue
        return NativeRuntime(exe) if name == "native" else ContainerRuntime(exe, name)
    raise FramescopeError(
        f"no usable runtime (tried {', '.join(names)}). Install wslc (WSL >= 2.9.3), podman or docker, "
        "or put Verilator on PATH and use --runtime native."
    )


def available() -> dict[str, str | None]:
    return {name: shutil.which("verilator" if name == "native" else name) for name in RUNTIMES}
