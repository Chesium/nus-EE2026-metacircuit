from __future__ import annotations

import pathlib
import sys
import unittest
from collections import deque


THIS_DIR = pathlib.Path(__file__).resolve().parent
PACKAGE_ROOT = THIS_DIR.parent.parent.parent
if str(PACKAGE_ROOT) not in sys.path:
    sys.path.insert(0, str(PACKAGE_ROOT))

from src.uart_link.frontend_tester import (
    FrontendTester,
    SimpyhlsDcSolver,
    _bcd_to_int,
    _value_to_float,
)
from src.uart_link.protocol import (
    ERROR_BAD_FIELD,
    GROUND_NODE,
    KIND_CURRENT_DC,
    KIND_RESISTOR,
    KIND_VOLTAGE_DC,
    ErrorPacket,
    NetlistComponent,
    NetlistSnapshot,
    SnapshotAssembler,
    VoltageSnapshot,
    decode_line,
    encode_snapshot,
)
from src.uart_link.solver_tester import bits_to_float


class FakeLineEndpoint:
    def __init__(self, reads: list[bytes] | None = None) -> None:
        self.reads = deque(reads or [])
        self.writes: list[bytes] = []

    def readline(self) -> bytes:
        if self.reads:
            return self.reads.popleft()
        return b""

    def write(self, data: bytes) -> int:
        self.writes.append(data)
        return len(data)

    def flush(self) -> None:
        return None


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


class FrontendTesterTest(unittest.TestCase):
    def test_bcd_helpers_follow_solver_board_units(self) -> None:
        self.assertEqual(_bcd_to_int(0x470), 470)
        self.assertAlmostEqual(_value_to_float(0x010, 0x01), 0.01, places=8)
        self.assertAlmostEqual(_value_to_float(0x470, 0x04), 470000.0, places=3)

    def test_simpyhls_solver_solves_known_divider_snapshot(self) -> None:
        snapshot = NetlistSnapshot(
            frame=0x0001,
            elem_count=3,
            node_count=2,
            components=(
                make_component(0x0001, 0x00, KIND_VOLTAGE_DC, 0x00, GROUND_NODE, 0x005, 0x00),
                make_component(0x0001, 0x01, KIND_RESISTOR, 0x00, 0x01, 0x003, 0x04),
                make_component(0x0001, 0x02, KIND_RESISTOR, 0x01, GROUND_NODE, 0x002, 0x04),
            ),
        )

        response = SimpyhlsDcSolver().solve_snapshot(snapshot)

        self.assertEqual(response.frame, 0x0001)
        self.assertEqual(response.node_count, 2)
        self.assertEqual(response.status, 0x00)
        actual = {item.node: bits_to_float(item.value_bits) for item in response.values}
        self.assertAlmostEqual(actual[0x00], 5.0, places=3)
        self.assertAlmostEqual(actual[0x01], 2.0, places=3)

    def test_frontend_tester_round_trips_snapshot_to_voltage_response(self) -> None:
        snapshot = NetlistSnapshot(
            frame=0x0001,
            elem_count=3,
            node_count=2,
            components=(
                make_component(0x0001, 0x00, KIND_VOLTAGE_DC, 0x00, GROUND_NODE, 0x005, 0x00),
                make_component(0x0001, 0x01, KIND_RESISTOR, 0x00, 0x01, 0x003, 0x04),
                make_component(0x0001, 0x02, KIND_RESISTOR, 0x01, GROUND_NODE, 0x002, 0x04),
            ),
        )
        endpoint = FakeLineEndpoint(reads=encode_snapshot(snapshot))
        tester = FrontendTester(endpoint)

        response = tester.serve_once(timeout_s=0.5)

        self.assertIsInstance(response, VoltageSnapshot)
        assembler = SnapshotAssembler()
        decoded = [decode_line(line) for line in endpoint.writes]
        final = None
        for packet in decoded:
            final = assembler.push(packet) or final
        self.assertIsInstance(final, VoltageSnapshot)
        actual = {item.node: bits_to_float(item.value_bits) for item in final.values}
        self.assertAlmostEqual(actual[0x00], 5.0, places=3)
        self.assertAlmostEqual(actual[0x01], 2.0, places=3)

    def test_frontend_tester_sends_error_for_unsupported_kind(self) -> None:
        snapshot = NetlistSnapshot(
            frame=0x0020,
            elem_count=1,
            node_count=1,
            components=(
                make_component(0x0020, 0x00, KIND_CURRENT_DC + 0x10, 0x00, GROUND_NODE, 0x001, 0x00),
            ),
        )
        endpoint = FakeLineEndpoint(reads=encode_snapshot(snapshot))
        tester = FrontendTester(endpoint)

        response = tester.serve_once(timeout_s=0.2)

        self.assertIsNone(response)
        self.assertEqual(len(endpoint.writes), 1)
        packet = decode_line(endpoint.writes[0])
        self.assertIsInstance(packet, ErrorPacket)
        self.assertEqual(packet.frame, 0x0020)
        self.assertEqual(packet.code, ERROR_BAD_FIELD)


if __name__ == "__main__":
    unittest.main()
