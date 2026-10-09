#!/usr/bin/env python3
"""Encode/decode uart_link records with the reference src/uart_link/protocol.py.

Used by golden/test/uart.test.ts to check the TypeScript codec byte for byte.
Reads JSON from stdin:

    {"netlists": [{"frame", "elem_count", "node_count",
                   "components": [{"idx", "kind", "n0", "n1", "value_bcd", "unit"}]}],
     "voltages": [{"frame", "node_count", "status", "values": [{"node", "value_bits"}]}],
     "errors":   [{"frame", "code", "arg"}],
     "decode":   ["@...*CC\\r\\n", ...]}

and writes {"netlists": [text], "voltages": [text], "errors": [text],
"decode": [{"type": ..., fields...} | {"error": message}]}, where each text is
the concatenation of protocol.py's encoded lines (ASCII, CRLF terminated).
"""

from __future__ import annotations

import dataclasses
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from src.uart_link import protocol as p  # noqa: E402

TAGS = {
    p.NetlistBegin: "NB", p.NetlistComponent: "NC", p.NetlistEnd: "NE",
    p.VoltageBegin: "VB", p.VoltageNode: "VN", p.VoltageEnd: "VE", p.ErrorPacket: "ER",
}


def text(lines: list[bytes]) -> str:
    return b"".join(lines).decode("ascii")


def main() -> int:
    req = json.load(sys.stdin)
    out = {"netlists": [], "voltages": [], "errors": [], "decode": []}
    for n in req.get("netlists", []):
        comps = [p.NetlistComponent(n["frame"], c["idx"], c["kind"], c["n0"], c["n1"], c["value_bcd"], c["unit"])
                 for c in n["components"]]
        out["netlists"].append(text(p.encode_snapshot(p.NetlistSnapshot(n["frame"], n["elem_count"], n["node_count"], comps))))
    for v in req.get("voltages", []):
        values = [p.VoltageNode(v["frame"], x["node"], x["value_bits"]) for x in v["values"]]
        out["voltages"].append(text(p.encode_voltage_snapshot(p.VoltageSnapshot(v["frame"], v["node_count"], v["status"], values))))
    for e in req.get("errors", []):
        out["errors"].append(text([p.encode_packet(p.ErrorPacket(e["frame"], e["code"], e["arg"]))]))
    for line in req.get("decode", []):
        try:
            pkt = p.decode_line(line)
            out["decode"].append({"type": TAGS[type(pkt)], **dataclasses.asdict(pkt)})
        except p.PacketError as exc:
            out["decode"].append({"error": str(exc)})
    json.dump(out, sys.stdout)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
