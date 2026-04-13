from __future__ import annotations

import argparse
import sys
import time
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import Callable, Optional, Protocol, Sequence

from .protocol import (
    ERROR_BAD_FIELD,
    ERROR_BAD_SEQUENCE,
    GROUND_NODE,
    KIND_CURRENT_DC,
    KIND_RESISTOR,
    KIND_VOLTAGE_DC,
    ErrorPacket,
    NetlistComponent,
    NetlistSnapshot,
    PacketError,
    SnapshotAssembler,
    VoltageNode,
    VoltageSnapshot,
    decode_line,
    encode_packet,
    encode_voltage_snapshot,
)
from .solver_tester import float_to_bits


ROOT = Path(__file__).resolve().parents[2]
SIMPYHLS_ROOT = ROOT / "simpyhls"
if str(SIMPYHLS_ROOT) not in sys.path:
    sys.path.insert(0, str(SIMPYHLS_ROOT))

from compiler.ast_to_hir import lower_source  # type: ignore
from compiler.hir_to_lir import lower_func  # type: ignore
from compiler.sim_runtime import PrimitiveModel, SimulationHarness, run_lir  # type: ignore


STATUS_OK = 0x00
STATUS_SOLVE_ERROR = 0x04

UNIT_SCALE = {
    0x00: 1.0,
    0x01: 1.0e-3,
    0x02: 1.0e-6,
    0x03: 1.0e-9,
    0x04: 1.0e3,
    0x05: 1.0e6,
    0x06: 1.0e9,
}


class LineEndpoint(Protocol):
    def readline(self) -> bytes:
        ...

    def write(self, data: bytes) -> int:
        ...

    def flush(self) -> None:
        ...


class FrontendTesterError(RuntimeError):
    pass


@dataclass
class FrontendTesterStats:
    lines_rx: int = 0
    snapshots_rx: int = 0
    replies_tx: int = 0
    errors_tx: int = 0
    solve_errors: int = 0


def _kind_name(kind: int) -> str:
    if kind == KIND_RESISTOR:
        return "R"
    if kind == KIND_CURRENT_DC:
        return "I"
    if kind == KIND_VOLTAGE_DC:
        return "V"
    raise FrontendTesterError(f"unsupported kind code {kind:02X}")


def _bcd_to_int(value_bcd: int) -> int:
    digit_h = (value_bcd >> 8) & 0xF
    digit_t = (value_bcd >> 4) & 0xF
    digit_o = value_bcd & 0xF
    if digit_h > 9 or digit_t > 9 or digit_o > 9:
        raise FrontendTesterError(f"invalid packed BCD value {value_bcd:03X}")
    return (digit_h * 100) + (digit_t * 10) + digit_o


def _value_to_float(value_bcd: int, unit: int) -> float:
    try:
        scale = UNIT_SCALE[unit]
    except KeyError as exc:
        raise FrontendTesterError(f"unsupported unit code {unit:02X}") from exc
    return float(_bcd_to_int(value_bcd)) * scale


def _normalize_snapshot(snapshot: NetlistSnapshot) -> list[tuple[int, str, int, int, float]]:
    if snapshot.elem_count != len(snapshot.components):
        raise FrontendTesterError(
            f"element count mismatch: header={snapshot.elem_count} actual={len(snapshot.components)}"
        )
    if snapshot.node_count > 0x20:
        raise FrontendTesterError(f"node_count {snapshot.node_count:02X} exceeds frontend tester capacity")

    normalized: list[tuple[int, str, int, int, float]] = []
    expected_idx = 0
    for component in sorted(snapshot.components, key=lambda item: item.idx):
        if component.frame != snapshot.frame:
            raise FrontendTesterError("component frame mismatch inside snapshot")
        if component.idx != expected_idx:
            raise FrontendTesterError(
                f"component index mismatch: expected {expected_idx:02X}, got {component.idx:02X}"
            )
        expected_idx += 1
        for node in (component.n0, component.n1):
            if node != GROUND_NODE and node >= snapshot.node_count:
                raise FrontendTesterError(
                    f"node index {node:02X} out of range for node_count {snapshot.node_count:02X}"
                )
        normalized.append(
            (
                component.idx,
                _kind_name(component.kind),
                component.n0,
                component.n1,
                _value_to_float(component.value_bcd, component.unit),
            )
        )
    return normalized


def fetchElemKind(tb, idx):
    return tb.state["elements"][idx][1]


def fetchElemN0(tb, idx):
    return tb.state["elements"][idx][2]


def fetchElemN1(tb, idx):
    return tb.state["elements"][idx][3]


def fetchElemVal0(tb, idx):
    return tb.state["elements"][idx][4]


def store_A(tb, i, j, v):
    tb.state["A"][i][j] = v


def fetch_A(tb, i, j):
    return tb.state["A"][i][j]


def accumA(tb, i, j, delta):
    tb.state["A"][i][j] += delta


def store_J(tb, i, v):
    tb.state["J"][i] = v


def fetch_J(tb, i):
    return tb.state["J"][i]


def accumJ(tb, i, delta):
    tb.state["J"][i] += delta


def fetch_LU(tb, i, j):
    return tb.state["LU"][i][j]


def store_LU(tb, i, j, v):
    tb.state["LU"][i][j] = v


def fetch_Y(tb, i):
    return tb.state["Y"][i]


def store_Y(tb, i, v):
    tb.state["Y"][i] = v


def fetch_X(tb, i):
    return tb.state["X"][i]


def store_X(tb, i, v):
    tb.state["X"][i] = v


def neg_comb(tb, v):
    return -v


def abs_comb(tb, v):
    return abs(v)


def gt_comb(tb, a, b):
    return a > b


def fma(tb, a, b, c):
    return (a * b) + c


def div(tb, a, b):
    return a / b


def _solve_primitives() -> dict[str, PrimitiveModel]:
    return {
        "fetchElemKind": PrimitiveModel("fetchElemKind", fetchElemKind, latency=1),
        "fetchElemN0": PrimitiveModel("fetchElemN0", fetchElemN0, latency=1),
        "fetchElemN1": PrimitiveModel("fetchElemN1", fetchElemN1, latency=1),
        "fetchElemVal0": PrimitiveModel("fetchElemVal0", fetchElemVal0, latency=1),
        "store_A": PrimitiveModel("store_A", store_A, latency=1),
        "fetch_A": PrimitiveModel("fetch_A", fetch_A, latency=1),
        "accumA": PrimitiveModel("accumA", accumA, latency=1),
        "store_J": PrimitiveModel("store_J", store_J, latency=1),
        "fetch_J": PrimitiveModel("fetch_J", fetch_J, latency=1),
        "accumJ": PrimitiveModel("accumJ", accumJ, latency=1),
        "fetch_LU": PrimitiveModel("fetch_LU", fetch_LU, latency=1),
        "store_LU": PrimitiveModel("store_LU", store_LU, latency=1),
        "fetch_Y": PrimitiveModel("fetch_Y", fetch_Y, latency=1),
        "store_Y": PrimitiveModel("store_Y", store_Y, latency=1),
        "fetch_X": PrimitiveModel("fetch_X", fetch_X, latency=1),
        "store_X": PrimitiveModel("store_X", store_X, latency=1),
        "neg_comb": PrimitiveModel("neg_comb", neg_comb),
        "abs_comb": PrimitiveModel("abs_comb", abs_comb),
        "gt_comb": PrimitiveModel("gt_comb", gt_comb),
        "fma": PrimitiveModel("fma", fma, latency=3),
        "div": PrimitiveModel("div", div, latency=4),
    }


def _solver_dim(base_node_n: int, elements: Sequence[tuple[int, str, int, int, float]]) -> int:
    return base_node_n + sum(1 for _, kind_name, _, _, _ in elements if kind_name == "V")


def _make_state(dim: int, elements: Sequence[tuple[int, str, int, int, float]]) -> dict[str, object]:
    return {
        "elements": [(idx, {"R": 1, "I": 2, "V": 3}[kind], n0, n1, float(value)) for idx, kind, n0, n1, value in elements],
        "A": [[-123.0 for _ in range(dim)] for _ in range(dim)],
        "J": [-123.0 for _ in range(dim)],
        "LU": [[-123.0 for _ in range(dim)] for _ in range(dim)],
        "Y": [-123.0 for _ in range(dim)],
        "X": [-123.0 for _ in range(dim)],
    }


@lru_cache(maxsize=1)
def _lowered_solve_core_dc():
    source = (SIMPYHLS_ROOT / "examples" / "solve_core_dc.dsl.py").read_text()
    return lower_func(lower_source(source))


class SimpyhlsDcSolver:
    def __init__(self) -> None:
        self._primitives = _solve_primitives()

    def solve_snapshot(self, snapshot: NetlistSnapshot) -> VoltageSnapshot:
        elements = _normalize_snapshot(snapshot)
        dim = _solver_dim(snapshot.node_count, elements)
        harness = SimulationHarness(
            params={"par_elem_n": len(elements), "par_node_n": snapshot.node_count},
            primitives=self._primitives,
            initial_state=_make_state(dim, elements),
        )
        result = run_lir(_lowered_solve_core_dc(), harness)
        values = tuple(
            VoltageNode(snapshot.frame, node_idx, float_to_bits(float(result.final_state["X"][node_idx])))
            for node_idx in range(snapshot.node_count)
        )
        return VoltageSnapshot(
            frame=snapshot.frame,
            node_count=snapshot.node_count,
            status=STATUS_OK,
            values=values,
        )


class FrontendTester:
    def __init__(
        self,
        endpoint: LineEndpoint,
        solver: Optional[SimpyhlsDcSolver] = None,
        logger: Optional[Callable[[str], None]] = None,
    ) -> None:
        self.endpoint = endpoint
        self.solver = solver or SimpyhlsDcSolver()
        self.logger = logger or (lambda _msg: None)
        self.assembler = SnapshotAssembler()
        self.stats = FrontendTesterStats()
        self._frame_hint = 0

    def _send_packet(self, packet) -> None:
        line = encode_packet(packet)
        self.endpoint.write(line)
        self.endpoint.flush()
        self.logger(f"tx {line.rstrip().decode('ascii')}")

    def _send_error(self, frame: int, code: int, arg: int) -> None:
        self._send_packet(ErrorPacket(frame & 0xFFFF, code & 0xFF, arg & 0xFFFF))
        self.stats.errors_tx += 1

    def _send_voltage_snapshot(self, snapshot: VoltageSnapshot) -> None:
        for line in encode_voltage_snapshot(snapshot):
            self.endpoint.write(line)
            self.endpoint.flush()
            self.logger(f"tx {line.rstrip().decode('ascii')}")
        self.stats.replies_tx += 1

    def handle_line(self, line: bytes) -> VoltageSnapshot | None:
        self.stats.lines_rx += 1
        try:
            packet = decode_line(line)
        except PacketError as exc:
            self.logger(f"rx parse error: {exc}")
            self._send_error(self._frame_hint, ERROR_BAD_FIELD, 0x0000)
            return None

        frame = getattr(packet, "frame", self._frame_hint)
        self._frame_hint = int(frame) & 0xFFFF
        self.logger(f"rx {line.rstrip().decode('ascii', errors='replace')}")

        try:
            snapshot = self.assembler.push(packet)
        except PacketError as exc:
            self.logger(f"rx sequence error: {exc}")
            self._send_error(self._frame_hint, ERROR_BAD_SEQUENCE, 0x0000)
            return None

        if not isinstance(snapshot, NetlistSnapshot):
            return None

        self.stats.snapshots_rx += 1
        try:
            response = self.solver.solve_snapshot(snapshot)
        except FrontendTesterError as exc:
            self.logger(f"solve input error: {exc}")
            self._send_error(snapshot.frame, ERROR_BAD_FIELD, 0x0001)
            return None
        except Exception as exc:  # pragma: no cover - defensive host-side guard
            self.stats.solve_errors += 1
            self.logger(f"solve failure: {exc}")
            self._send_packet(ErrorPacket(snapshot.frame, STATUS_SOLVE_ERROR, 0x0000))
            return None

        self._send_voltage_snapshot(response)
        return response

    def serve_once(self, timeout_s: float = 3.0) -> VoltageSnapshot | None:
        deadline = time.monotonic() + timeout_s
        while time.monotonic() < deadline:
            line = self.endpoint.readline()
            if not line:
                continue
            response = self.handle_line(line)
            if response is not None:
                return response
        return None

    def serve_forever(self) -> None:
        while True:
            line = self.endpoint.readline()
            if not line:
                time.sleep(0.005)
                continue
            self.handle_line(line)


def _open_serial_endpoint(port: str, baud: int, timeout_s: float) -> LineEndpoint:
    try:
        import serial  # type: ignore
    except ImportError as exc:
        raise FrontendTesterError("pyserial is required for live frontend testing") from exc
    return serial.Serial(port, baudrate=baud, timeout=timeout_s)


def run_cli(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description="Simulate board S on a laptop: receive frontend UART snapshots, solve in simpyhls, send replies."
    )
    parser.add_argument("--port", required=True, help="Windows COM port, for example COM7")
    parser.add_argument("--baud", type=int, default=115200)
    parser.add_argument("--timeout", type=float, default=0.05, help="Serial read timeout in seconds")
    parser.add_argument("--once", action="store_true", help="Process one complete snapshot and exit")
    args = parser.parse_args(list(argv) if argv is not None else None)

    endpoint = _open_serial_endpoint(args.port, args.baud, args.timeout)
    tester = FrontendTester(endpoint, logger=lambda msg: print(msg, flush=True))
    try:
        if args.once:
            response = tester.serve_once(timeout_s=5.0)
            if response is None:
                print("timed out waiting for a complete frontend snapshot", file=sys.stderr)
                return 1
            return 0
        tester.serve_forever()
    except KeyboardInterrupt:
        return 0
    finally:
        close = getattr(endpoint, "close", None)
        if callable(close):
            close()
    return 0


if __name__ == "__main__":
    raise SystemExit(run_cli())
