from __future__ import annotations

import pathlib
import sys
import unittest


THIS_DIR = pathlib.Path(__file__).resolve().parent
PACKAGE_ROOT = THIS_DIR.parent.parent.parent
if str(PACKAGE_ROOT) not in sys.path:
    sys.path.insert(0, str(PACKAGE_ROOT))

from src.uart_link.protocol import (
    NetlistComponent,
    NetlistSnapshot,
    VoltageNode,
    VoltageSnapshot,
    decode_line,
    encode_snapshot,
    encode_voltage_snapshot,
)
from src.uart_link.relay import InMemoryEndpoint, UartRelay


class RelayTest(unittest.TestCase):
    def test_frontend_netlist_is_forwarded_and_counted(self) -> None:
        frontend_out = InMemoryEndpoint()
        solver_out = InMemoryEndpoint()
        logs: list[str] = []
        relay = UartRelay(frontend_out=frontend_out, solver_out=solver_out, logger=logs.append)

        snapshot = NetlistSnapshot(
            frame=0x0007,
            elem_count=2,
            node_count=1,
            components=(
                NetlistComponent(0x0007, 0x00, 0x03, 0xFF, 0x00, 0x500, 0x00),
                NetlistComponent(0x0007, 0x01, 0x01, 0xFF, 0x00, 0x3E8, 0x04),
            ),
        )

        for line in encode_snapshot(snapshot):
            relay.handle_frontend_line(line)

        self.assertEqual(relay.stats.frontend_lines, 4)
        self.assertEqual(relay.stats.frontend_forwarded, 4)
        self.assertEqual(relay.stats.frontend_snapshots, 1)
        self.assertEqual(len(solver_out.writes), 4)
        self.assertIn("frontend snapshot frame=0007 elems=02 nodes=01", logs)
        self.assertEqual(decode_line(solver_out.writes[1]), snapshot.components[0])

    def test_solver_voltage_is_forwarded_and_counted(self) -> None:
        frontend_out = InMemoryEndpoint()
        solver_out = InMemoryEndpoint()
        relay = UartRelay(frontend_out=frontend_out, solver_out=solver_out)

        snapshot = VoltageSnapshot(
            frame=0x0007,
            node_count=2,
            status=0,
            values=(
                VoltageNode(0x0007, 0x00, 0x3F800000),
                VoltageNode(0x0007, 0x01, 0x40000000),
            ),
        )

        for line in encode_voltage_snapshot(snapshot):
            relay.handle_solver_line(line)

        self.assertEqual(relay.stats.solver_lines, 4)
        self.assertEqual(relay.stats.solver_forwarded, 4)
        self.assertEqual(relay.stats.solver_snapshots, 1)
        self.assertEqual(len(frontend_out.writes), 4)
        self.assertEqual(decode_line(frontend_out.writes[2]), snapshot.values[1])

    def test_bad_line_is_dropped(self) -> None:
        frontend_out = InMemoryEndpoint()
        solver_out = InMemoryEndpoint()
        logs: list[str] = []
        relay = UartRelay(frontend_out=frontend_out, solver_out=solver_out, logger=logs.append)

        relay.handle_frontend_line(b"@NB,0001,01,01*00\r\n")

        self.assertEqual(relay.stats.frontend_errors, 1)
        self.assertEqual(len(solver_out.writes), 0)
        self.assertTrue(any("parse error" in log for log in logs))


if __name__ == "__main__":
    unittest.main()
