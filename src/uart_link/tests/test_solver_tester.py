from __future__ import annotations

import pathlib
import sys
import unittest
from collections import deque


THIS_DIR = pathlib.Path(__file__).resolve().parent
PACKAGE_ROOT = THIS_DIR.parent.parent.parent
if str(PACKAGE_ROOT) not in sys.path:
    sys.path.insert(0, str(PACKAGE_ROOT))

from src.uart_link.protocol import (
    NetlistSnapshot,
    VoltageNode,
    VoltageSnapshot,
    encode_snapshot,
    encode_voltage_snapshot,
)
from src.uart_link.solver_tester import (
    SolverBoardClient,
    SolverBoardError,
    bits_to_float,
    default_cases,
    float_to_bits,
    validate_case,
)


class FakeLineEndpoint:
    def __init__(self, reads: list[bytes] | None = None, release_after_writes: int = 0) -> None:
        self.reads = deque(reads or [])
        self.writes: list[bytes] = []
        self.release_after_writes = release_after_writes

    def readline(self) -> bytes:
        if len(self.writes) < self.release_after_writes:
            return b""
        if self.reads:
            return self.reads.popleft()
        return b""

    def write(self, data: bytes) -> int:
        self.writes.append(data)
        return len(data)

    def flush(self) -> None:
        return None


class SolverTesterTest(unittest.TestCase):
    def test_exchange_snapshot_writes_request_and_reads_voltage_snapshot(self) -> None:
        case = default_cases()["voltage_divider_5v_3k_2k"]
        response = VoltageSnapshot(
            frame=case.snapshot.frame,
            node_count=case.snapshot.node_count,
            status=0x00,
            values=(
                VoltageNode(case.snapshot.frame, 0x00, float_to_bits(5.0)),
                VoltageNode(case.snapshot.frame, 0x01, float_to_bits(2.0)),
            ),
        )
        endpoint = FakeLineEndpoint(
            reads=encode_voltage_snapshot(response),
            release_after_writes=len(encode_snapshot(case.snapshot)),
        )
        client = SolverBoardClient(endpoint)

        snapshot = client.exchange_snapshot(case.snapshot, timeout_s=0.01)

        self.assertEqual(snapshot, response)
        self.assertEqual(endpoint.writes, encode_snapshot(case.snapshot))

    def test_validate_case_rejects_voltage_mismatch(self) -> None:
        case = default_cases()["current_source_2ma_into_1k"]
        response = VoltageSnapshot(
            frame=case.snapshot.frame,
            node_count=case.snapshot.node_count,
            status=0x00,
            values=(
                VoltageNode(case.snapshot.frame, 0x00, float_to_bits(1.5)),
            ),
        )

        with self.assertRaises(SolverBoardError):
            validate_case(case, response)

    def test_default_cases_are_extensible_and_named(self) -> None:
        cases = default_cases()
        self.assertIn("voltage_divider_5v_3k_2k", cases)
        self.assertIn("current_source_2ma_into_1k", cases)
        self.assertIsInstance(cases["voltage_divider_5v_3k_2k"].snapshot, NetlistSnapshot)

    def test_bits_float_round_trip(self) -> None:
        value = 2.0
        bits = float_to_bits(value)
        self.assertAlmostEqual(bits_to_float(bits), value, places=6)


if __name__ == "__main__":
    unittest.main()
