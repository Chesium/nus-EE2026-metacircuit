from __future__ import annotations

import argparse
import math
import struct
import sys
import time
from dataclasses import dataclass, field
from typing import Callable, Dict, List, Optional, Protocol, Sequence

from .protocol import (
    GROUND_NODE,
    KIND_CURRENT_DC,
    KIND_RESISTOR,
    KIND_VOLTAGE_DC,
    ErrorPacket,
    NetlistComponent,
    NetlistSnapshot,
    PacketError,
    SnapshotAssembler,
    STATUS_OK,
    VoltageSnapshot,
    decode_line,
    encode_snapshot,
)


class LineEndpoint(Protocol):
    def readline(self) -> bytes:
        ...

    def write(self, data: bytes) -> int:
        ...

    def flush(self) -> None:
        ...


@dataclass(frozen=True)
class VoltageExpectation:
    node: int
    value: float
    abs_tol: float = 1e-3
    rel_tol: float = 1e-3


@dataclass(frozen=True)
class SolverBoardCase:
    name: str
    snapshot: NetlistSnapshot
    expected_status: int = STATUS_OK
    expected_voltages: Sequence[VoltageExpectation] = field(default_factory=tuple)
    timeout_s: float = 3.0
    notes: str = ""


@dataclass(frozen=True)
class SolverBoardResult:
    case: SolverBoardCase
    snapshot: VoltageSnapshot
    elapsed_s: float


class SolverBoardError(RuntimeError):
    pass


def float_to_bits(value: float) -> int:
    return struct.unpack(">I", struct.pack(">f", value))[0]


def bits_to_float(value_bits: int) -> float:
    return struct.unpack(">f", struct.pack(">I", value_bits & 0xFFFFFFFF))[0]


def make_component(
    frame: int,
    idx: int,
    kind: int,
    n0: int,
    n1: int,
    value_bcd: int,
    unit: int,
) -> NetlistComponent:
    return NetlistComponent(
        frame=frame,
        idx=idx,
        kind=kind,
        n0=n0,
        n1=n1,
        value_bcd=value_bcd,
        unit=unit,
    )


def _make_voltage_divider_case() -> SolverBoardCase:
    frame = 0x0001
    snapshot = NetlistSnapshot(
        frame=frame,
        elem_count=3,
        node_count=2,
        components=(
            make_component(frame, 0x00, KIND_VOLTAGE_DC, 0x00, GROUND_NODE, 0x005, 0x00),
            make_component(frame, 0x01, KIND_RESISTOR, 0x00, 0x01, 0x003, 0x04),
            make_component(frame, 0x02, KIND_RESISTOR, 0x01, GROUND_NODE, 0x002, 0x04),
        ),
    )
    return SolverBoardCase(
        name="voltage_divider_5v_3k_2k",
        snapshot=snapshot,
        expected_voltages=(
            VoltageExpectation(node=0x00, value=5.0),
            VoltageExpectation(node=0x01, value=2.0),
        ),
        notes="5 V source into 3k/2k divider, expecting node voltages 5 V and 2 V.",
    )


def _make_current_source_case() -> SolverBoardCase:
    frame = 0x0002
    snapshot = NetlistSnapshot(
        frame=frame,
        elem_count=2,
        node_count=1,
        components=(
            make_component(frame, 0x00, KIND_CURRENT_DC, GROUND_NODE, 0x00, 0x002, 0x01),
            make_component(frame, 0x01, KIND_RESISTOR, 0x00, GROUND_NODE, 0x001, 0x04),
        ),
    )
    return SolverBoardCase(
        name="current_source_2ma_into_1k",
        snapshot=snapshot,
        expected_voltages=(VoltageExpectation(node=0x00, value=2.0),),
        notes="2 mA injected from ground into a 1k resistor-to-ground node, expecting 2 V.",
    )


def default_cases() -> Dict[str, SolverBoardCase]:
    cases = (
        _make_voltage_divider_case(),
        _make_current_source_case(),
    )
    return {case.name: case for case in cases}


class SolverBoardClient:
    def __init__(
        self,
        endpoint: LineEndpoint,
        logger: Optional[Callable[[str], None]] = None,
    ) -> None:
        self.endpoint = endpoint
        self.logger = logger or (lambda _msg: None)

    def _drain_input(self, drain_window_s: float = 0.05) -> None:
        deadline = time.monotonic() + drain_window_s
        while time.monotonic() < deadline:
            line = self.endpoint.readline()
            if not line:
                break
            self.logger(f"drained stale line: {line.rstrip().decode('ascii', errors='replace')}")

    def exchange_snapshot(self, snapshot: NetlistSnapshot, timeout_s: float = 3.0) -> VoltageSnapshot:
        assembler = SnapshotAssembler()
        self._drain_input()
        start = time.monotonic()
        for line in encode_snapshot(snapshot):
            self.endpoint.write(line)
            self.endpoint.flush()
            self.logger(f"tx {line.rstrip().decode('ascii')}")

        deadline = start + timeout_s
        while time.monotonic() < deadline:
            line = self.endpoint.readline()
            if not line:
                continue
            text = line.rstrip().decode("ascii", errors="replace")
            self.logger(f"rx {text}")
            packet = decode_line(line)
            if isinstance(packet, ErrorPacket):
                raise SolverBoardError(
                    f"board returned error frame={packet.frame:04X} code={packet.code:02X} arg={packet.arg:04X}"
                )
            snapshot_or_none = assembler.push(packet)
            if isinstance(snapshot_or_none, VoltageSnapshot):
                return snapshot_or_none

        raise TimeoutError(f"timed out waiting for solver response for frame {snapshot.frame:04X}")

    def run_case(self, case: SolverBoardCase) -> SolverBoardResult:
        start = time.monotonic()
        response = self.exchange_snapshot(case.snapshot, timeout_s=case.timeout_s)
        elapsed_s = time.monotonic() - start
        validate_case(case, response)
        return SolverBoardResult(case=case, snapshot=response, elapsed_s=elapsed_s)


def validate_case(case: SolverBoardCase, response: VoltageSnapshot) -> None:
    if response.frame != case.snapshot.frame:
        raise SolverBoardError(
            f"{case.name}: response frame mismatch got {response.frame:04X} expected {case.snapshot.frame:04X}"
        )
    if response.status != case.expected_status:
        raise SolverBoardError(
            f"{case.name}: response status mismatch got {response.status:02X} expected {case.expected_status:02X}"
        )
    if response.node_count != case.snapshot.node_count:
        raise SolverBoardError(
            f"{case.name}: response node_count mismatch got {response.node_count:02X} expected {case.snapshot.node_count:02X}"
        )

    actual_by_node = {entry.node: bits_to_float(entry.value_bits) for entry in response.values}
    for expected in case.expected_voltages:
        if expected.node not in actual_by_node:
            raise SolverBoardError(f"{case.name}: missing voltage for node {expected.node:02X}")
        actual_value = actual_by_node[expected.node]
        if not math.isclose(
            actual_value,
            expected.value,
            rel_tol=expected.rel_tol,
            abs_tol=expected.abs_tol,
        ):
            raise SolverBoardError(
                f"{case.name}: node {expected.node:02X} mismatch got {actual_value:.6f} expected {expected.value:.6f}"
            )


def _open_serial_endpoint(port: str, baud: int, timeout_s: float) -> LineEndpoint:
    try:
        import serial  # type: ignore
    except ImportError as exc:
        raise SolverBoardError("pyserial is required for live solver-board testing") from exc
    return serial.Serial(port, baudrate=baud, timeout=timeout_s)


def run_cli(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Automatic hardware tester for the standalone solver board.")
    parser.add_argument("--port", help="Windows COM port, for example COM7")
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--timeout", type=float, default=3.0, help="Per-case timeout in seconds")
    parser.add_argument("--list", action="store_true", help="List available built-in test cases and exit")
    parser.add_argument(
        "--case",
        action="append",
        dest="cases",
        help="Case name to run. Repeat to run multiple cases. Defaults to all built-in cases.",
    )
    args = parser.parse_args(list(argv) if argv is not None else None)

    cases_by_name = default_cases()

    if args.list:
        for case in cases_by_name.values():
            print(f"{case.name}: {case.notes}")
        return 0

    if not args.port:
        parser.error("--port is required unless --list is used")

    selected_names = args.cases or list(cases_by_name.keys())
    unknown = [name for name in selected_names if name not in cases_by_name]
    if unknown:
        parser.error(f"unknown case(s): {', '.join(unknown)}")

    endpoint = _open_serial_endpoint(args.port, args.baud, timeout_s=0.05)
    client = SolverBoardClient(endpoint=endpoint, logger=lambda msg: print(msg, flush=True))

    failures = 0
    try:
        for name in selected_names:
            case = cases_by_name[name]
            case = SolverBoardCase(
                name=case.name,
                snapshot=case.snapshot,
                expected_status=case.expected_status,
                expected_voltages=case.expected_voltages,
                timeout_s=args.timeout,
                notes=case.notes,
            )
            print(f"running {case.name} on {args.port} ...", flush=True)
            try:
                result = client.run_case(case)
            except Exception as exc:  # noqa: BLE001 - CLI should keep running remaining cases
                failures += 1
                print(f"FAIL {case.name}: {exc}", flush=True)
                continue

            print(
                f"PASS {case.name}: frame={result.snapshot.frame:04X} "
                f"status={result.snapshot.status:02X} elapsed={result.elapsed_s:.3f}s",
                flush=True,
            )
            for entry in result.snapshot.values:
                print(
                    f"  node {entry.node:02X} = {bits_to_float(entry.value_bits):.6f} "
                    f"(0x{entry.value_bits:08X})",
                    flush=True,
                )
    finally:
        close = getattr(endpoint, "close", None)
        if callable(close):
            close()

    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(run_cli())
