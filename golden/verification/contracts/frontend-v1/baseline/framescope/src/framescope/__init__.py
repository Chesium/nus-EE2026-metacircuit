"""Agent-facing observability for RTL video outputs, built on Verilator."""

__version__ = "0.1.0"


class FramescopeError(Exception):
    """A user-facing error: bad manifest, missing runtime, failed build, ..."""
