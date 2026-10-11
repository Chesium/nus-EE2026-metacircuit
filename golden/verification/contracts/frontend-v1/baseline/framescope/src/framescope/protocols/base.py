"""Interface every display protocol implements.

A protocol turns a [[monitor]] entry into three things:
  * taps: wrapper outputs that expose the monitored signals to the harness,
  * C++ that constructs the matching harness monitor (see harness/*_monitor.*),
  * a report: timing checks and diagnosis built from the monitor's events.

Protocols with `frames = True` (video) can be the frame reference: the first
such monitor numbers frames and positions for stimulus, probes and other
monitors' events. Link protocols (UART) may also drive a design input
(`can_send`) and talk to a host process during the run (`can_host`).
"""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass

from .. import FramescopeError
from ..manifest import MonitorSpec


@dataclass(frozen=True)
class Tap:
    signal: str  # protocol signal name, e.g. "hsync"
    width: int
    expr: str  # SystemVerilog over the design's ports and dut.* hierarchical paths


class Protocol:
    name: str = ""
    required: tuple[str, ...] = ()
    optional: tuple[str, ...] = ()
    option_keys: frozenset[str] = frozenset()
    cpp_header: str = ""
    frames: bool = True

    def validate(self, mon: MonitorSpec) -> None:
        missing = [s for s in self.required if s not in mon.signals]
        if missing:
            raise FramescopeError(f"monitor '{mon.name}': missing signals {missing}")
        unknown = sorted(set(mon.signals) - set(self.required) - set(self.optional))
        if unknown:
            raise FramescopeError(
                f"monitor '{mon.name}': unknown signals {unknown}; "
                f"{self.name} takes {list(self.required)} and optionally {list(self.optional)}"
            )
        bad = sorted(set(mon.options) - self.option_keys)
        if bad:
            raise FramescopeError(f"monitor '{mon.name}': unknown option(s) {bad}; allowed: {sorted(self.option_keys)}")

    def check_ports(self, mon: MonitorSpec, ports: dict, clocks: set[str]) -> None:
        """Cross-checks options that name top-level ports (`ports`: name -> Port)."""

    def can_send(self, mon: MonitorSpec) -> bool:
        """True if [[uart]]-style byte stimulus can be addressed to this monitor."""
        return False

    def can_host(self, mon: MonitorSpec) -> bool:
        """True if a host process can be attached to this monitor (`run --host`)."""
        return False

    def host_start(self, mon: MonitorSpec) -> dict:
        raise NotImplementedError

    def host_message(self, mon: MonitorSpec, ev: dict) -> dict:
        """What the host process receives for an awaited harness event."""
        raise NotImplementedError

    def host_reply(self, mon: MonitorSpec, reply: dict) -> str:
        """The harness stdin line for the host's JSON reply."""
        raise NotImplementedError

    def taps(self, mon: MonitorSpec) -> list[Tap]:
        raise NotImplementedError

    def cpp_bind(self, mon: MonitorSpec, member: Callable[[str], str]) -> str:
        """C++ statements for fs_bind(); `member(signal)` names a tap's port on `top`."""
        raise NotImplementedError

    def analyze(self, mon: MonitorSpec, frames: list[dict], summary: dict, sim: dict, events=()) -> dict:
        """`frames`: this monitor's frame events; `events`: all of its events."""
        raise NotImplementedError


def cpp_str(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'
