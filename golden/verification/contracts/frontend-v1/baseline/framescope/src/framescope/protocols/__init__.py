"""Protocol registry. Add a module here (and a harness monitor) for HDMI/TMDS, SPI panels, ..."""

from __future__ import annotations

from .. import FramescopeError
from ..manifest import Manifest, MonitorSpec
from .base import Protocol, Tap
from .uart import UartProtocol
from .vga import VgaProtocol

REGISTRY: dict[str, Protocol] = {p.name: p for p in (VgaProtocol(), UartProtocol())}


def get(name: str) -> Protocol:
    try:
        return REGISTRY[name]
    except KeyError:
        raise FramescopeError(f"unknown protocol '{name}'; known: {sorted(REGISTRY)}") from None


def primary(m: Manifest) -> MonitorSpec | None:
    """The frame reference: the first monitor whose protocol produces frames."""
    return next((mon for mon in m.monitors if get(mon.protocol).frames), None)


def links(m: Manifest, capability: str) -> list[MonitorSpec]:
    """Monitors that can `send` (byte stimulus) or `host` (a host process)."""
    return [mon for mon in m.monitors if getattr(get(mon.protocol), f"can_{capability}")(mon)]


__all__ = ["Protocol", "REGISTRY", "Tap", "get", "links", "primary"]
