from __future__ import annotations

import pathlib
import sys
import unittest


THIS_DIR = pathlib.Path(__file__).resolve().parent
PACKAGE_ROOT = THIS_DIR.parent.parent.parent
if str(PACKAGE_ROOT) not in sys.path:
    sys.path.insert(0, str(PACKAGE_ROOT))

from src.uart_link.protocol import (
    GROUND_NODE,
    ErrorPacket,
    NetlistBegin,
    NetlistComponent,
    NetlistEnd,
    NetlistSnapshot,
    PacketError,
    SnapshotAssembler,
    VoltageBegin,
    VoltageEnd,
    VoltageNode,
    VoltageSnapshot,
    decode_line,
    encode_packet,
    encode_snapshot,
    encode_voltage_snapshot,
    xor_checksum,
)


class ProtocolTest(unittest.TestCase):
    def test_checksum_matches_known_payload(self) -> None:
        payload = "NB,0012,03,01"
        self.assertEqual(xor_checksum(payload), 0x21)

    def test_component_round_trip(self) -> None:
        packet = NetlistComponent(
            frame=0x0012,
            idx=0x02,
            kind=0x03,
            n0=GROUND_NODE,
            n1=0x00,
            value_bcd=0x470,
            unit=0x04,
        )
        encoded = encode_packet(packet)
        decoded = decode_line(encoded)
        self.assertEqual(decoded, packet)

    def test_bad_checksum_is_rejected(self) -> None:
        with self.assertRaises(PacketError):
            decode_line(b"@NB,0012,03,01*00\r\n")

    def test_netlist_snapshot_assembles(self) -> None:
        snapshot = NetlistSnapshot(
            frame=0x0031,
            elem_count=2,
            node_count=1,
            components=(
                NetlistComponent(0x0031, 0x00, 0x03, 0xFF, 0x00, 0x500, 0x00),
                NetlistComponent(0x0031, 0x01, 0x01, 0xFF, 0x00, 0x3E8, 0x04),
            ),
        )
        assembler = SnapshotAssembler()
        result = None
        for line in encode_snapshot(snapshot):
            maybe = assembler.push(decode_line(line))
            if maybe is not None:
                result = maybe
        self.assertEqual(result, snapshot)

    def test_voltage_snapshot_assembles(self) -> None:
        snapshot = VoltageSnapshot(
            frame=0x0031,
            node_count=2,
            status=0,
            values=(
                VoltageNode(0x0031, 0x00, 0x3F800000),
                VoltageNode(0x0031, 0x01, 0x40000000),
            ),
        )
        assembler = SnapshotAssembler()
        result = None
        for line in encode_voltage_snapshot(snapshot):
            maybe = assembler.push(decode_line(line))
            if maybe is not None:
                result = maybe
        self.assertEqual(result, snapshot)

    def test_aborted_snapshot_closes_and_recovers(self) -> None:
        assembler = SnapshotAssembler()
        assembler.push(NetlistBegin(frame=7, elem_count=2, node_count=1))
        assembler.push(NetlistComponent(7, 0, 1, 0, 255, 0x100, 0))
        self.assertIsNone(assembler.push(ErrorPacket(7, 0x85, 1)))
        with self.assertRaises(PacketError):
            assembler.push(NetlistEnd(7, 2, 1))
        assembler.push(NetlistBegin(8, 0, 0))
        self.assertEqual(assembler.push(NetlistEnd(8, 0, 0)), NetlistSnapshot(8, 0, 0, ()))

    def test_abort_count_and_id_are_checked(self) -> None:
        for packet in [ErrorPacket(7, 0x85, 1), ErrorPacket(8, 0x85, 0)]:
            assembler = SnapshotAssembler()
            assembler.push(NetlistBegin(7, 2, 1))
            with self.assertRaises(PacketError):
                assembler.push(packet)

    def test_sequence_mismatch_is_rejected(self) -> None:
        assembler = SnapshotAssembler()
        assembler.push(NetlistBegin(frame=1, elem_count=1, node_count=1))
        with self.assertRaises(PacketError):
            assembler.push(NetlistEnd(frame=2, elem_count=1, node_count=1))


if __name__ == "__main__":
    unittest.main()
