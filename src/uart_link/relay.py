from __future__ import annotations

import argparse
import sys
import threading
import time
from dataclasses import dataclass, field
from typing import Callable, List, Optional, Protocol

from .protocol import (
    Packet,
    PacketError,
    SnapshotAssembler,
    VoltageSnapshot,
    NetlistSnapshot,
    decode_line,
    encode_packet,
)


class LineEndpoint(Protocol):
    def readline(self) -> bytes:
        ...

    def write(self, data: bytes) -> int:
        ...

    def flush(self) -> None:
        ...


@dataclass
class RelayStats:
    frontend_lines: int = 0
    solver_lines: int = 0
    frontend_forwarded: int = 0
    solver_forwarded: int = 0
    frontend_errors: int = 0
    solver_errors: int = 0
    frontend_snapshots: int = 0
    solver_snapshots: int = 0


@dataclass
class RelayEvents:
    logs: list[str] = field(default_factory=list)

    def log(self, message: str) -> None:
        self.logs.append(message)


class UartRelay:
    def __init__(
        self,
        frontend_out: LineEndpoint,
        solver_out: LineEndpoint,
        logger: Optional[Callable[[str], None]] = None,
    ) -> None:
        self.frontend_out = frontend_out
        self.solver_out = solver_out
        self.logger = logger or (lambda _msg: None)
        self.stats = RelayStats()
        self.frontend_assembler = SnapshotAssembler()
        self.solver_assembler = SnapshotAssembler()

    def _handle_packet(
        self,
        source_name: str,
        packet: Packet,
        target: LineEndpoint,
        assembler: SnapshotAssembler,
    ) -> None:
        target.write(encode_packet(packet))
        target.flush()
        if source_name == "frontend":
            self.stats.frontend_forwarded += 1
        else:
            self.stats.solver_forwarded += 1
        snapshot = assembler.push(packet)
        if isinstance(snapshot, NetlistSnapshot):
            self.stats.frontend_snapshots += 1
            self.logger(
                f"frontend snapshot frame={snapshot.frame:04X} elems={snapshot.elem_count:02X} nodes={snapshot.node_count:02X}"
            )
        elif isinstance(snapshot, VoltageSnapshot):
            self.stats.solver_snapshots += 1
            self.logger(
                f"solver snapshot frame={snapshot.frame:04X} nodes={snapshot.node_count:02X} status={snapshot.status:02X}"
            )

    def handle_frontend_line(self, line: bytes) -> None:
        self.stats.frontend_lines += 1
        try:
            packet = decode_line(line)
        except PacketError as exc:
            self.stats.frontend_errors += 1
            self.logger(f"frontend parse error: {exc}")
            return
        self._handle_packet("frontend", packet, self.solver_out, self.frontend_assembler)

    def handle_solver_line(self, line: bytes) -> None:
        self.stats.solver_lines += 1
        try:
            packet = decode_line(line)
        except PacketError as exc:
            self.stats.solver_errors += 1
            self.logger(f"solver parse error: {exc}")
            return
        self._handle_packet("solver", packet, self.frontend_out, self.solver_assembler)


class InMemoryEndpoint:
    def __init__(self) -> None:
        self.writes: List[bytes] = []

    def readline(self) -> bytes:
        return b""

    def write(self, data: bytes) -> int:
        self.writes.append(data)
        return len(data)

    def flush(self) -> None:
        return None


def _serial_reader(relay_handler: Callable[[bytes], None], endpoint: LineEndpoint, stop_flag: threading.Event) -> None:
    while not stop_flag.is_set():
        line = endpoint.readline()
        if not line:
            time.sleep(0.005)
            continue
        relay_handler(line)


def run_cli(argv: Optional[list[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Relay UART packets between frontend and solver boards.")
    parser.add_argument("--frontend-port", required=True)
    parser.add_argument("--solver-port", required=True)
    parser.add_argument("--baud", type=int, default=115200)
    args = parser.parse_args(argv)

    try:
        import serial  # type: ignore
    except ImportError:
        print("pyserial is required for live relay mode", file=sys.stderr)
        return 2

    frontend = serial.Serial(args.frontend_port, args.baud, timeout=0.05)
    solver = serial.Serial(args.solver_port, args.baud, timeout=0.05)
    stop_flag = threading.Event()

    def log(msg: str) -> None:
        print(msg, flush=True)

    relay = UartRelay(frontend_out=frontend, solver_out=solver, logger=log)

    frontend_thread = threading.Thread(
        target=_serial_reader, args=(relay.handle_frontend_line, frontend, stop_flag), daemon=True
    )
    solver_thread = threading.Thread(
        target=_serial_reader, args=(relay.handle_solver_line, solver, stop_flag), daemon=True
    )

    frontend_thread.start()
    solver_thread.start()

    try:
        while frontend_thread.is_alive() and solver_thread.is_alive():
            time.sleep(0.25)
    except KeyboardInterrupt:
        pass
    finally:
        stop_flag.set()
        frontend.close()
        solver.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(run_cli())
