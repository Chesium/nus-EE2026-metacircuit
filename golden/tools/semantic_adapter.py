#!/usr/bin/env python3
"""Strict artifact adapter for settled MetaCircuit frontend checkpoints.

Physical names, word fields and address order are adapter configuration. Public
state contains logical coordinates and ids, never component slots/FSMs/banks.
This supplements (does not replace) the accepted pixel and backend oracles.
"""
from __future__ import annotations

import argparse
import copy
import dataclasses
import hashlib
import json
from pathlib import Path
import re
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from src.uart_link import protocol

SCHEMA = "metacircuit-semantic/v1"
COUNT = 288
KINDS = {5: "resistor", 7: "voltage", 9: "current", 11: "inductor", 13: "capacitor"}
TOOLS = ["pan", "wire", "resistor", "inductor", "capacitor", "voltage", "current", "ground", "rotate", "delete"]
VARIANTS = ["wire", "junction", "elbow", "tee"]
CORE_PROBES = ["tool_idx", "wire_variant", "mode_select", "grid_pos_x", "grid_pos_y", "init_done",
               "interaction_idle", "interaction_frame_drop", "component_store_busy", "component_count"]
UI_PROBES = ["has_selection", "value_edit_active", "selected_cell_i", "selected_cell_j",
             "selected_component_valid", "selected_value_bcd", "selected_value_unit", "selected_component_type",
             "selected_value_text_len", "selected_value_text_hi", "selected_value_text_lo"]
BACKEND_PROBES = ["uart_client", "snapshot_id", "snapshot_id_valid", "reply_valid", "reply_frame",
                  "reply_status", "reply_node_count", "reply_bank", "reply_stale_count", "reply_view_node",
                  "reply_view_upper", "seg_value", "leds", "voltage_node0", "netlist_error_code"]
MEMORIES = {"cells_render": (16, COUNT), "cells_shadow": (16, COUNT), "values_shadow": (12, COUNT),
            "value_units_shadow": (4, COUNT), "component_store": (40, COUNT), "component_index_map": (9, COUNT),
            "cell_bg_color": (4, COUNT), "cell_fg_color": (4, COUNT), "voltages_bank0": (32, 32),
            "voltages_bank1": (32, 32), "netlist_n0": (8, COUNT), "netlist_n1": (8, COUNT)}
FIELDS = {"cell": {"enabled": [0, 1], "sprite": [1, 6], "rotation": [7, 2]},
          "component": {"unit": [36, 4], "index": [27, 9], "type": [23, 4], "rotation": [21, 2],
                        "value": [9, 12], "y": [5, 4], "x": [0, 5]}}


class EvidenceError(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise EvidenceError(message)


def integer(value, name):
    require(type(value) is int, f"missing/invalid integer {name}")
    return value


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def configuration(overrides=None):
    """Only explicitly supported configuration keys are accepted, fail closed."""
    config = {"schema": SCHEMA, "monitor": "vga", "uart_monitor": "uart", "probes": {}, "memories": {},
              "fields": copy.deepcopy(FIELDS), "live_component_slots": None, "index_invalid": 511}
    if overrides:
        require(not (set(overrides) - set(config)), "unknown adapter configuration keys")
        config.update(copy.deepcopy(overrides))
    require(config["schema"] == SCHEMA, "unsupported semantic schema")
    require(isinstance(config["probes"], dict) and not (set(config["probes"]) -
            set(CORE_PROBES + UI_PROBES + BACKEND_PROBES)), "unknown/invalid probe mapping")
    require(isinstance(config["memories"], dict) and not (set(config["memories"]) - set(MEMORIES)),
            "unknown/invalid memory mapping")
    require(set(config["fields"]) == set(FIELDS), "missing/unknown word field groups")
    for group, fields in FIELDS.items():
        require(set(config["fields"][group]) == set(fields), f"missing/unknown {group} fields")
        for name, spec in config["fields"][group].items():
            require(isinstance(spec, list) and len(spec) == 2 and all(type(x) is int for x in spec)
                    and spec[0] >= 0 and 1 <= spec[1] <= 64, f"invalid field {group}.{name}")
    return config


def field(word, config, group, name):
    shift, width = config["fields"][group][name]
    return (word >> shift) & ((1 << width) - 1)


def probe(probes, config, name):
    spec = config["probes"].get(name, name)
    require(isinstance(spec, (str, dict)), f"invalid mapping for probe {name}")
    if isinstance(spec, str):
        return integer(probes.get(spec), name)
    require(set(spec) <= {"name", "values"} and "name" in spec, f"invalid mapping for probe {name}")
    value = integer(probes.get(spec["name"]), name)
    if "values" in spec:
        require(str(value) in spec["values"], f"unmapped probe value {name}={value}")
        return integer(spec["values"][str(value)], name)
    return value


def memory_spec(config, name):
    spec = config["memories"].get(name, {})
    require(isinstance(spec, dict) and not (set(spec) - {"name", "width", "depth", "addresses"}),
            f"invalid memory mapping {name}")
    width, depth = MEMORIES[name]
    return {"name": name, "width": width, "depth": depth, **spec}


def decode_dump(dump, frame, config, name):
    spec = memory_spec(config, name)
    require(dump.get("name") == spec["name"] and dump.get("frame") == frame,
            f"wrong memory name/frame {name}")
    require(dump.get("width") == spec["width"] and dump.get("depth") == spec["depth"]
            and isinstance(dump.get("words"), list) and len(dump["words"]) == spec["depth"],
            f"invalid width/depth/words {name}")
    words = []
    for index, word in enumerate(dump["words"]):
        require(isinstance(word, str) and re.fullmatch(r"0x[0-9a-fA-F]+", word) is not None,
                f"invalid hex word {name}[{index}]")
        value = int(word, 16)
        require(value < (1 << spec["width"]), f"overflow word {name}[{index}]")
        words.append(value)
    logical_depth = MEMORIES[name][1]
    addresses = spec.get("addresses", list(range(logical_depth)))
    require(isinstance(addresses, list) and len(addresses) == logical_depth
            and len(set(addresses)) == logical_depth
            and all(type(a) is int and 0 <= a < len(words) for a in addresses),
            f"invalid logical address permutation {name}")
    return [words[a] for a in addresses]


def core_state(frame, probes, dumps, config):
    p = {name: probe(probes, config, name) for name in CORE_PROBES}
    require(p["init_done"] == 1 and p["interaction_idle"] == 1 and p["component_store_busy"] == 0,
            "checkpoint is not settled")
    require(p["interaction_frame_drop"] == 0, "interaction frame dropped")
    tool, variant = p["tool_idx"], p["wire_variant"]
    require(0 <= tool < len(TOOLS) and 0 <= variant < 4, "invalid toolbar state")
    mode = [15, variant, 4, 9, 10, 5, 6, 11, 7, 8][tool]
    require(p["mode_select"] == mode, "toolbar and interaction mode disagree")
    words = {name: dumps(name) for name in list(MEMORIES)[:6]}
    require(words["cells_render"] == words["cells_shadow"], "cell render/shadow differ")
    count = p["component_count"]
    require(0 <= count <= COUNT, "invalid component count")
    slots = config["live_component_slots"]
    if slots is None:
        slots = list(range(count))
    else:
        require(isinstance(slots, list) and len(slots) == count and len(set(slots)) == count
                and all(type(s) is int and 0 <= s < COUNT for s in slots), "invalid live component slots")
    components, owners, ids = [], {}, set()
    for slot in slots:
        c = {name: field(words["component_store"][slot], config, "component", name) for name in FIELDS["component"]}
        require(c["index"] == slot, f"component slot {slot} index disagrees")
        col, row, rotation = c["x"], c["y"], c["rotation"]
        require(c["type"] in KINDS and rotation < 4, "invalid component kind/rotation")
        identity = f"{col},{row}"
        require(identity not in ids, "duplicate component anchor")
        ids.add(identity)
        dx, dy = [(1, 0), (0, 1), (-1, 0), (0, -1)][rotation]
        for half, (x, y) in enumerate([(col, row), (col + dx, row + dy)]):
            require(0 <= x < 18 and 0 <= y < 16, "component half outside grid")
            address = y * 18 + x
            require(address not in owners, "component overlap")
            owners[address] = (slot, identity)
            w = words["cells_render"][address]
            require(field(w, config, "cell", "enabled") == 1
                    and field(w, config, "cell", "sprite") == c["type"] + half
                    and field(w, config, "cell", "rotation") == rotation, "component/cell disagreement")
            require(words["values_shadow"][address] == c["value"]
                    and words["value_units_shadow"][address] == c["unit"], "component/per-cell value disagreement")
        components.append({"id": identity, "col": col, "row": row, "kind": KINDS[c["type"]],
                           "rotation": rotation, "value_bcd": c["value"], "unit": c["unit"]})
    cells = []
    for address, word in enumerate(words["cells_render"]):
        owner = owners.get(address)
        require(words["component_index_map"][address] == (owner[0] if owner else config["index_invalid"]),
                f"component index map disagrees at {address}")
        if not owner:
            require(words["values_shadow"][address] == 0 and words["value_units_shadow"][address] == 0,
                    f"orphan per-cell value at {address}")
        enabled = field(word, config, "cell", "enabled")
        cells.append({"col": address % 18, "row": address // 18, "enabled": enabled,
                      "sprite": field(word, config, "cell", "sprite") if enabled else None,
                      "rotation": field(word, config, "cell", "rotation") if enabled else None,
                      "component": owner[1] if owner else None, "value_bcd": words["values_shadow"][address],
                      "unit": words["value_units_shadow"][address]})
    return {"frame": frame, "tool": TOOLS[tool], "wire_variant": VARIANTS[variant],
            "pan": {"x": p["grid_pos_x"], "y": p["grid_pos_y"]}, "ready": True,
            "cells": cells, "components": sorted(components, key=lambda c: (c["row"], c["col"]))}


def snapshot(frame, probes, dumps, config, profile):
    result = core_state(frame, probes, dumps, config)
    if profile in ("ui", "backend"):
        p = {name: probe(probes, config, name) for name in UI_PROBES}
        require(p["has_selection"] in (0, 1) and p["value_edit_active"] in (0, 1), "invalid UI status")
        selection = None
        if p["has_selection"]:
            length = p["selected_value_text_len"]
            require(0 <= length <= 8, "invalid selected text length")
            try:
                text = (p["selected_value_text_hi"].to_bytes(4, "big") +
                        p["selected_value_text_lo"].to_bytes(4, "big"))[:length].decode("ascii")
            except (ValueError, OverflowError, UnicodeDecodeError) as error:
                raise EvidenceError("invalid selected text") from error
            selection = {"col": p["selected_cell_i"], "row": p["selected_cell_j"],
                         "component_valid": p["selected_component_valid"], "kind": p["selected_component_type"],
                         "value_bcd": p["selected_value_bcd"], "unit": p["selected_value_unit"], "text": text}
        bg, fg = dumps("cell_bg_color"), dumps("cell_fg_color")
        result["ui"] = {"selection": selection, "editing": bool(p["value_edit_active"]),
                        "background": bg, "foreground": [fg[a] if c["enabled"] else None for a, c in enumerate(result["cells"])]}
    if profile == "backend":
        p = {name: probe(probes, config, name) for name in BACKEND_PROBES}
        require(p["uart_client"] == 1 and p["snapshot_id_valid"] == 1, "backend mode/snapshot unavailable")
        require(p["reply_bank"] in (0, 1) and 0 <= p["reply_node_count"] <= 32, "invalid reply bank/count")
        bits = dumps(f"voltages_bank{p['reply_bank']}")
        require(p["voltage_node0"] == bits[0], "voltage node0 probe/memory disagree")
        node = p["reply_view_node"]
        require(0 <= node < 32 and p["reply_view_upper"] in (0, 1), "invalid display view")
        require(p["seg_value"] == ((bits[node] >> 16) if p["reply_view_upper"] else bits[node] & 65535),
                "display/voltage disagreement")
        n0, n1 = dumps("netlist_n0"), dumps("netlist_n1")
        result["backend"] = {"snapshot_id": p["snapshot_id"], "error": p["netlist_error_code"],
                             "reply": {"valid": p["reply_valid"], "id": p["reply_frame"], "status": p["reply_status"],
                                       "count": p["reply_node_count"], "stale_count": p["reply_stale_count"], "voltage_bits": bits},
                             "display": {"node": node, "upper": p["reply_view_upper"], "value": p["seg_value"],
                                         "semantic_leds": p["leds"] & ~0x1c},
                             "terminals": [{"ordinal": i, "n0": n0[i], "n1": n1[i]} for i in range(len(result["components"]))]}
    return result


def uart_events(uart):
    require(isinstance(uart, dict) and not uart.get("errors"), "missing UART/error evidence")
    require(all(name in uart for name in ("lines", "sent", "pending", "stats")), "incomplete UART evidence")
    events, open_snapshot, next_ordinal = [], None, 0
    previous_time = -1
    for i, line in enumerate(uart["lines"]):
        require(line.get("index") == i, "UART line order/index mismatch")
        for name in ("t_ms", "end_t_ms", "text", "end", "errors", "terminated"):
            require(name in line, f"missing UART {name}")
        require(line["t_ms"] >= previous_time and line["end_t_ms"] >= line["t_ms"], "nonmonotonic UART timing")
        previous_time = line["end_t_ms"]
        event = {name: line[name] for name in ("index", "text", "end", "t_ms", "end_t_ms", "terminated")}
        if line["terminated"]:
            require(not line["errors"] and line["end"] == "\r\n", "bad UART TX framing")
            try:
                packet = protocol.decode_line(line["text"] + line["end"])
            except protocol.PacketError as error:
                raise EvidenceError(f"invalid TX record: {error}") from error
            event["record"] = {"type": type(packet).__name__, **dataclasses.asdict(packet)}
            if isinstance(packet, protocol.NetlistBegin):
                require(open_snapshot is None, "NB inside unfinished snapshot")
                open_snapshot, next_ordinal = packet, 0
            elif isinstance(packet, protocol.NetlistComponent):
                require(open_snapshot is not None and packet.frame == open_snapshot.frame
                        and packet.idx == next_ordinal, "NC snapshot/order mismatch")
                next_ordinal += 1
            elif isinstance(packet, protocol.NetlistEnd):
                require(open_snapshot is not None and packet.frame == open_snapshot.frame
                        and next_ordinal == open_snapshot.elem_count
                        and packet.elem_count == open_snapshot.elem_count
                        and packet.node_count == open_snapshot.node_count, "NE snapshot/count mismatch")
                open_snapshot = None
            elif isinstance(packet, protocol.ErrorPacket):
                if packet.code == 0x85:
                    require(open_snapshot is not None and packet.frame == open_snapshot.frame
                            and packet.arg == next_ordinal, "abort snapshot/prefix mismatch")
                    open_snapshot = None
                else:
                    require(open_snapshot is None, "rejection inside unfinished snapshot")
            else:
                raise EvidenceError("unexpected TX record type")
        else:
            require(i == len(uart["lines"]) - 1, "partial TX line before capture end")
        events.append(event)
    replies = []
    for sent in uart["sent"]:
        require(all(name in sent for name in ("source", "text", "reply_to", "t_ms", "end_t_ms")), "missing RX evidence")
        require(sent["source"] == "host" and sent["end_t_ms"] >= sent["t_ms"], "invalid RX source/timing")
        # Malformed RX bytes are deliberate accepted scenarios. Preserve every
        # byte instead of rejecting/correcting them or losing their boundaries.
        replies.append({name: sent[name] for name in ("source", "text", "reply_to", "t_ms", "end_t_ms")})
    return {"tx": events, "rx": replies,
            "capture_boundary": {"open_snapshot": dataclasses.asdict(open_snapshot) if open_snapshot else None,
                                 "next_ordinal": next_ordinal if open_snapshot else None,
                                 "pending": uart["pending"], "unsent": uart["stats"].get("unsent", [])}}


def adapt_run(run, frames, config=None, profile="core"):
    config = configuration(config)
    run = Path(run)
    report = json.loads((run / "report.json").read_text())
    require(report.get("ok") is True and isinstance(report.get("stimulus"), list)
            and not any(event.get("late") for event in report["stimulus"]), "failed/missing/late simulation stimulus")
    require(profile in ("core", "ui", "backend"), "unknown profile")
    require(frames and len(set(frames)) == len(frames), "missing/duplicate checkpoint frames")
    all_frames = report.get("monitors", {}).get(config["monitor"], {}).get("frames")
    require(isinstance(all_frames, list), "missing frame monitor")
    snapshots = []
    for frame in frames:
        matches = [f for f in all_frames if f.get("index") == frame]
        require(len(matches) == 1 and isinstance(matches[0].get("probes"), dict), f"missing/duplicate frame {frame}")
        def dumps(name):
            spec = memory_spec(config, name)
            entries = [d for d in report.get("dumps", {}).get(spec["name"], []) if d.get("frame") == frame]
            require(len(entries) == 1 and "path" in entries[0], f"missing/duplicate memory {name} at {frame}")
            return decode_dump(json.loads((run / entries[0]["path"]).read_text()), frame, config, name)
        value = snapshot(frame, matches[0]["probes"], dumps, config, profile)
        # Persistent sessions retain the harness's integer picoseconds; batch
        # captures expose milliseconds. Preserve observed time in either format.
        observed = matches[0]
        if "t_ps" in observed:
            require(type(observed["t_ps"]) is int and observed["t_ps"] >= 0,
                    "invalid frame picosecond timestamp")
            timestamp = observed["t_ps"] / 1_000_000_000
            if "t_ms" in observed:
                require(type(observed["t_ms"]) in (int, float)
                        and observed["t_ms"] == timestamp, "inconsistent frame timestamps")
        else:
            timestamp = observed.get("t_ms")
        require(type(timestamp) in (int, float) and 0 <= timestamp < float("inf"),
                "missing/invalid frame timestamp")
        value["t_ms"] = timestamp
        snapshots.append(value)
    result = {"schema": SCHEMA, "profile": profile, "adapter_config_sha256": digest(config), "snapshots": snapshots}
    if profile == "backend":
        result["uart"] = uart_events(report.get("monitors", {}).get(config["uart_monitor"]))
    return result


def compare_reference(normalized, reference):
    """Core oracle check: accepted saved semantic/ram artifacts, never candidate-derived."""
    reference = Path(reference)
    index = json.loads((reference / "checkpoints.json").read_text())
    actual = {s["frame"]: s for s in normalized["snapshots"]}
    require(set(actual) == {c["frame"] for c in index["checkpoints"]}, "reference/checkpoint frame set mismatch")
    differences = []
    for checkpoint in index["checkpoints"]:
        frame = checkpoint["frame"]
        expected = json.loads((reference / checkpoint["state"]).read_text())
        rams = json.loads((reference / checkpoint["ram"]).read_text())
        config = configuration()
        # Golden slots can be sparse; candidate physical allocation remains a
        # separate explicit mapping and is never inferred from the oracle.
        config["live_component_slots"] = [c["slot"] for c in expected["components"]]
        probes = {"tool_idx": expected["toolIndex"], "wire_variant": VARIANTS.index(expected["wireVariant"]),
                  "mode_select": expected["modeSelect"], "grid_pos_x": expected["pan"]["x"],
                  "grid_pos_y": expected["pan"]["y"], "init_done": 1, "interaction_idle": 1,
                  "interaction_frame_drop": 0, "component_store_busy": 0, "component_count": len(expected["components"])}
        def dump(name):
            physical = index["names"].get({"cells_render": "cellsRender", "cells_shadow": "cellsShadow",
                    "values_shadow": "values", "value_units_shadow": "valueUnits", "component_store": "componentStore",
                    "component_index_map": "componentIndexMap"}[name], name)
            matches = [d for d in rams if d["name"] == physical]
            require(len(matches) == 1, "missing golden memory")
            return decode_dump({**matches[0], "name": name}, frame, config, name)
        oracle = core_state(frame, probes, dump, config)
        observed = {key: actual[frame][key] for key in oracle}
        if observed != oracle:
            differences.append({"frame": frame, "fields": [key for key in oracle if observed[key] != oracle[key]]})
    return {"ok": not differences, "profile": "core", "checkpoints": len(actual), "differences": differences}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--actual", type=Path, required=True)
    parser.add_argument("--reference", type=Path)
    parser.add_argument("--frames", help="comma-separated settled checkpoint frames (default: reference index)")
    parser.add_argument("--config", type=Path)
    parser.add_argument("--profile", choices=("core", "ui", "backend"), default="core")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        frames = [int(f) for f in args.frames.split(",")] if args.frames else [c["frame"] for c in
                     json.loads((args.reference / "checkpoints.json").read_text())["checkpoints"]]
        result = adapt_run(args.actual, frames, json.loads(args.config.read_text()) if args.config else None, args.profile)
        if args.reference:
            result["comparison"] = compare_reference(result, args.reference)
        result["ok"] = result.get("comparison", {}).get("ok", True)
    except (EvidenceError, OSError, ValueError, KeyError, TypeError) as error:
        result = {"ok": False, "schema": SCHEMA, "error": str(error)}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({key: value for key, value in result.items() if key not in ("snapshots", "uart")}))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
