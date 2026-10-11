"""Top-level port introspection from Verilator's --json-only (>= 5.026) or --xml-only (<= 5.03x) output."""

from __future__ import annotations

import json
import xml.etree.ElementTree as ET
from dataclasses import asdict, dataclass
from pathlib import Path

from . import FramescopeError


@dataclass(frozen=True)
class Port:
    name: str
    direction: str  # input | output | inout
    msb: int
    lsb: int
    ranged: bool  # declared with an explicit [msb:lsb]

    @property
    def width(self) -> int:
        return abs(self.msb - self.lsb) + 1

    @property
    def sv_range(self) -> str:
        return f"[{self.msb}:{self.lsb}]" if self.ranged else ""

    def to_json(self) -> dict:
        return {**asdict(self), "width": self.width}


def parse_xml(path: Path, top: str) -> list[Port]:
    root = ET.parse(path).getroot()
    dtypes = {el.get("id"): el for el in root.iter() if el.tag.endswith("dtype") and el.get("id")}
    module = next((m for m in root.iter("module") if m.get("topModule") == "1"), None)
    if module is None:
        raise FramescopeError(f"Verilator did not report a top module (expected {top})")

    pins = []
    for var in module.findall("var"):
        index = var.get("pinIndex")
        if index is None:
            continue
        name = var.get("origName") or var.get("name")
        msb, lsb, ranged = _dtype_range(dtypes, var.get("dtype_id"), name)
        pins.append((int(index), Port(name, var.get("dir", "input"), msb, lsb, ranged)))
    return [p for _, p in sorted(pins, key=lambda x: x[0])]


def parse_json(path: Path, top: str) -> list[Port]:
    root = json.loads(path.read_text(encoding="utf-8"))
    nodes: dict[str, dict] = {}
    stack = [root]
    while stack:
        n = stack.pop()
        if isinstance(n, dict):
            if "addr" in n:
                nodes[n["addr"]] = n
            stack.extend(v for v in n.values() if isinstance(v, (dict, list)))
        elif isinstance(n, list):
            stack.extend(n)
    modules = [m for m in root.get("modulesp", []) if m.get("type") == "MODULE"]
    module = next((m for m in modules if m.get("level") == 1), None)
    if module is None:
        raise FramescopeError(f"Verilator did not report a top module (expected {top})")

    # No pinIndex in the JSON dump; port variables appear in declaration order.
    ports = []
    for var in module.get("stmtsp", []):
        if var.get("type") != "VAR" or not var.get("isPrimaryIO"):
            continue
        name = var.get("origName") or var.get("name")
        msb, lsb, ranged = _json_dtype_range(nodes, var.get("dtypep"), name)
        ports.append(Port(name, var.get("direction", "INPUT").lower(), msb, lsb, ranged))
    return ports


def _json_dtype_range(nodes: dict, addr: str | None, port: str) -> tuple[int, int, bool]:
    seen = set()
    while addr and addr not in seen:
        seen.add(addr)
        el = nodes.get(addr)
        if el is None:
            break
        if el.get("type") == "BASICDTYPE":
            if el.get("range"):
                msb, lsb = el["range"].split(":")
                return int(msb), int(lsb), True
            return 0, 0, False
        if el.get("type") != "REFDTYPE":
            break
        addr = el.get("refDTypep")
    raise FramescopeError(
        f"port '{port}' has a type framescope cannot map yet (packed arrays, structs, enums); "
        "wrap the top module in a plain-vector shim"
    )


def _dtype_range(dtypes: dict, dtype_id: str | None, port: str) -> tuple[int, int, bool]:
    seen = set()
    while dtype_id and dtype_id not in seen:
        seen.add(dtype_id)
        el = dtypes.get(dtype_id)
        if el is None:
            break
        if el.tag == "basicdtype":
            if el.get("left") is not None:
                return int(el.get("left")), int(el.get("right")), True
            if el.get("name") in {"int", "integer"}:
                return 31, 0, True
            if el.get("name") == "byte":
                return 7, 0, True
            if el.get("name") == "shortint":
                return 15, 0, True
            if el.get("name") == "longint":
                return 63, 0, True
            return 0, 0, False
        dtype_id = el.get("sub_dtype_id")
    raise FramescopeError(
        f"port '{port}' has a type framescope cannot map yet (packed arrays, structs, enums); "
        "wrap the top module in a plain-vector shim"
    )
