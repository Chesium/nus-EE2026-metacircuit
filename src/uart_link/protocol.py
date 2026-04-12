from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable, List, Sequence, Union


GROUND_NODE = 0xFF

KIND_RESISTOR = 0x01
KIND_CURRENT_DC = 0x02
KIND_VOLTAGE_DC = 0x03
KIND_CAPACITOR = 0x04
KIND_INDUCTOR = 0x05

STATUS_OK = 0x00

ERROR_BAD_CHECKSUM = 0x01
ERROR_BAD_SEQUENCE = 0x02
ERROR_BAD_FIELD = 0x03


class PacketError(ValueError):
    """Raised when a UART packet cannot be decoded or assembled."""


@dataclass(frozen=True)
class NetlistBegin:
    frame: int
    elem_count: int
    node_count: int


@dataclass(frozen=True)
class NetlistComponent:
    frame: int
    idx: int
    kind: int
    n0: int
    n1: int
    value_bcd: int
    unit: int


@dataclass(frozen=True)
class NetlistEnd:
    frame: int
    elem_count: int
    node_count: int


@dataclass(frozen=True)
class VoltageBegin:
    frame: int
    node_count: int
    status: int = STATUS_OK


@dataclass(frozen=True)
class VoltageNode:
    frame: int
    node: int
    value_bits: int


@dataclass(frozen=True)
class VoltageEnd:
    frame: int
    node_count: int
    status: int = STATUS_OK


@dataclass(frozen=True)
class ErrorPacket:
    frame: int
    code: int
    arg: int


Packet = Union[
    NetlistBegin,
    NetlistComponent,
    NetlistEnd,
    VoltageBegin,
    VoltageNode,
    VoltageEnd,
    ErrorPacket,
]


@dataclass(frozen=True)
class NetlistSnapshot:
    frame: int
    elem_count: int
    node_count: int
    components: Sequence[NetlistComponent]


@dataclass(frozen=True)
class VoltageSnapshot:
    frame: int
    node_count: int
    status: int
    values: Sequence[VoltageNode]


def xor_checksum(payload: str) -> int:
    checksum = 0
    for byte in payload.encode("ascii"):
        checksum ^= byte
    return checksum


def _fmt_u8(value: int) -> str:
    return f"{value & 0xFF:02X}"


def _fmt_u12(value: int) -> str:
    return f"{value & 0xFFF:03X}"


def _fmt_u16(value: int) -> str:
    return f"{value & 0xFFFF:04X}"


def _fmt_u32(value: int) -> str:
    return f"{value & 0xFFFFFFFF:08X}"


def _encode_payload(packet: Packet) -> str:
    if isinstance(packet, NetlistBegin):
        return f"NB,{_fmt_u16(packet.frame)},{_fmt_u8(packet.elem_count)},{_fmt_u8(packet.node_count)}"
    if isinstance(packet, NetlistComponent):
        return (
            f"NC,{_fmt_u16(packet.frame)},{_fmt_u8(packet.idx)},{_fmt_u8(packet.kind)},"
            f"{_fmt_u8(packet.n0)},{_fmt_u8(packet.n1)},{_fmt_u12(packet.value_bcd)},{_fmt_u8(packet.unit)}"
        )
    if isinstance(packet, NetlistEnd):
        return f"NE,{_fmt_u16(packet.frame)},{_fmt_u8(packet.elem_count)},{_fmt_u8(packet.node_count)}"
    if isinstance(packet, VoltageBegin):
        return f"VB,{_fmt_u16(packet.frame)},{_fmt_u8(packet.node_count)},{_fmt_u8(packet.status)}"
    if isinstance(packet, VoltageNode):
        return f"VN,{_fmt_u16(packet.frame)},{_fmt_u8(packet.node)},{_fmt_u32(packet.value_bits)}"
    if isinstance(packet, VoltageEnd):
        return f"VE,{_fmt_u16(packet.frame)},{_fmt_u8(packet.node_count)},{_fmt_u8(packet.status)}"
    if isinstance(packet, ErrorPacket):
        return f"ER,{_fmt_u16(packet.frame)},{_fmt_u8(packet.code)},{_fmt_u16(packet.arg)}"
    raise TypeError(f"unsupported packet type: {type(packet)!r}")


def encode_packet(packet: Packet) -> bytes:
    payload = _encode_payload(packet)
    checksum = xor_checksum(payload)
    return f"@{payload}*{checksum:02X}\r\n".encode("ascii")


def _parse_hex(field: str, width: int) -> int:
    if len(field) != width:
        raise PacketError(f"expected {width} hex chars, got {field!r}")
    try:
        return int(field, 16)
    except ValueError as exc:
        raise PacketError(f"invalid hex field {field!r}") from exc


def decode_line(line: Union[bytes, str]) -> Packet:
    if isinstance(line, bytes):
        text = line.decode("ascii")
    else:
        text = line
    text = text.strip()
    if not text.startswith("@") or "*" not in text:
        raise PacketError("invalid framing")
    payload, checksum_text = text[1:].rsplit("*", 1)
    checksum = _parse_hex(checksum_text, 2)
    actual = xor_checksum(payload)
    if checksum != actual:
        raise PacketError(f"checksum mismatch: got {checksum:02X}, expected {actual:02X}")
    fields = payload.split(",")
    if not fields:
        raise PacketError("empty payload")
    tag = fields[0]
    if tag == "NB" and len(fields) == 4:
        return NetlistBegin(_parse_hex(fields[1], 4), _parse_hex(fields[2], 2), _parse_hex(fields[3], 2))
    if tag == "NC" and len(fields) == 8:
        return NetlistComponent(
            frame=_parse_hex(fields[1], 4),
            idx=_parse_hex(fields[2], 2),
            kind=_parse_hex(fields[3], 2),
            n0=_parse_hex(fields[4], 2),
            n1=_parse_hex(fields[5], 2),
            value_bcd=_parse_hex(fields[6], 3),
            unit=_parse_hex(fields[7], 2),
        )
    if tag == "NE" and len(fields) == 4:
        return NetlistEnd(_parse_hex(fields[1], 4), _parse_hex(fields[2], 2), _parse_hex(fields[3], 2))
    if tag == "VB" and len(fields) == 4:
        return VoltageBegin(_parse_hex(fields[1], 4), _parse_hex(fields[2], 2), _parse_hex(fields[3], 2))
    if tag == "VN" and len(fields) == 4:
        return VoltageNode(_parse_hex(fields[1], 4), _parse_hex(fields[2], 2), _parse_hex(fields[3], 8))
    if tag == "VE" and len(fields) == 4:
        return VoltageEnd(_parse_hex(fields[1], 4), _parse_hex(fields[2], 2), _parse_hex(fields[3], 2))
    if tag == "ER" and len(fields) == 4:
        return ErrorPacket(_parse_hex(fields[1], 4), _parse_hex(fields[2], 2), _parse_hex(fields[3], 4))
    raise PacketError(f"unsupported payload {payload!r}")


def encode_snapshot(snapshot: NetlistSnapshot) -> List[bytes]:
    packets: List[bytes] = [
        encode_packet(NetlistBegin(snapshot.frame, snapshot.elem_count, snapshot.node_count))
    ]
    for component in snapshot.components:
        packets.append(encode_packet(component))
    packets.append(encode_packet(NetlistEnd(snapshot.frame, snapshot.elem_count, snapshot.node_count)))
    return packets


def encode_voltage_snapshot(snapshot: VoltageSnapshot) -> List[bytes]:
    packets: List[bytes] = [
        encode_packet(VoltageBegin(snapshot.frame, snapshot.node_count, snapshot.status))
    ]
    for value in snapshot.values:
        packets.append(encode_packet(value))
    packets.append(encode_packet(VoltageEnd(snapshot.frame, snapshot.node_count, snapshot.status)))
    return packets


class SnapshotAssembler:
    def __init__(self) -> None:
        self._netlist_begin: NetlistBegin | None = None
        self._netlist_components: list[NetlistComponent] = []
        self._voltage_begin: VoltageBegin | None = None
        self._voltage_values: list[VoltageNode] = []

    def push(self, packet: Packet) -> NetlistSnapshot | VoltageSnapshot | None:
        if isinstance(packet, NetlistBegin):
            self._netlist_begin = packet
            self._netlist_components = []
            return None
        if isinstance(packet, NetlistComponent):
            if self._netlist_begin is None or packet.frame != self._netlist_begin.frame:
                raise PacketError("netlist component without matching begin")
            self._netlist_components.append(packet)
            return None
        if isinstance(packet, NetlistEnd):
            if self._netlist_begin is None:
                raise PacketError("netlist end without begin")
            begin = self._netlist_begin
            if packet.frame != begin.frame:
                raise PacketError("netlist end frame mismatch")
            if packet.elem_count != begin.elem_count or packet.node_count != begin.node_count:
                raise PacketError("netlist end count mismatch")
            if len(self._netlist_components) != begin.elem_count:
                raise PacketError("netlist component count mismatch")
            snapshot = NetlistSnapshot(begin.frame, begin.elem_count, begin.node_count, tuple(self._netlist_components))
            self._netlist_begin = None
            self._netlist_components = []
            return snapshot
        if isinstance(packet, VoltageBegin):
            self._voltage_begin = packet
            self._voltage_values = []
            return None
        if isinstance(packet, VoltageNode):
            if self._voltage_begin is None or packet.frame != self._voltage_begin.frame:
                raise PacketError("voltage node without matching begin")
            self._voltage_values.append(packet)
            return None
        if isinstance(packet, VoltageEnd):
            if self._voltage_begin is None:
                raise PacketError("voltage end without begin")
            begin = self._voltage_begin
            if packet.frame != begin.frame:
                raise PacketError("voltage end frame mismatch")
            if packet.node_count != begin.node_count or packet.status != begin.status:
                raise PacketError("voltage end mismatch")
            if len(self._voltage_values) != begin.node_count:
                raise PacketError("voltage node count mismatch")
            snapshot = VoltageSnapshot(begin.frame, begin.node_count, begin.status, tuple(self._voltage_values))
            self._voltage_begin = None
            self._voltage_values = []
            return snapshot
        return None


def decode_stream(lines: Iterable[Union[bytes, str]]) -> List[Packet]:
    return [decode_line(line) for line in lines]
