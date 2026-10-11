"""Adapter controls run without Verilator; optional accepted-capture qualification."""
import copy
import json
from pathlib import Path
import tempfile
import unittest

from semantic_adapter import (COUNT, EvidenceError, adapt_run, compare_reference,
                              configuration, core_state, decode_dump, digest, uart_events)


def fixture():
    words = {name: [0] * COUNT for name in ("cells_render", "cells_shadow", "values_shadow",
                                           "value_units_shadow", "component_store", "component_index_map")}
    words["component_index_map"] = [511] * COUNT
    for address, sprite in ((39, 5), (40, 6)):
        words["cells_render"][address] = sprite * 2 + 1
        words["cells_shadow"][address] = sprite * 2 + 1
        words["component_index_map"][address] = 0
        words["values_shadow"][address] = 0x123
    words["component_store"][0] = (5 << 23) | (0x123 << 9) | (2 << 5) | 3
    probes = {"tool_idx": 0, "wire_variant": 0, "mode_select": 15, "grid_pos_x": 0,
              "grid_pos_y": -32, "init_done": 1, "interaction_idle": 1,
              "interaction_frame_drop": 0, "component_store_busy": 0, "component_count": 1}
    return probes, words


class AdapterControls(unittest.TestCase):
    def test_physical_slot_reallocation_is_semantically_equal(self):
        probes, words = fixture()
        expected = core_state(7, probes, words.__getitem__, configuration())
        word = words["component_store"][0]
        words["component_store"][0] = 0
        words["component_store"][11] = word | (11 << 27)
        words["component_index_map"][39:41] = [11, 11]
        actual = core_state(7, probes, words.__getitem__, configuration({"live_component_slots": [11]}))
        self.assertEqual(expected, actual)
        self.assertNotIn("slot", json.dumps(actual))
        with self.assertRaises(EvidenceError):
            core_state(7, probes, words.__getitem__, configuration())

    def test_probe_path_and_fsm_encoding_mapping(self):
        probes, words = fixture()
        expected = core_state(7, probes, words.__getitem__, configuration())
        del probes["interaction_idle"]
        probes["renamed.controller.state"] = 42
        config = configuration({"probes": {"interaction_idle": {"name": "renamed.controller.state", "values": {"42": 1}}}})
        self.assertEqual(expected, core_state(7, probes, words.__getitem__, config))
        probes["renamed.controller.state"] = 43
        with self.assertRaises(EvidenceError):
            core_state(7, probes, words.__getitem__, config)

    def test_explicit_shifted_component_packing(self):
        probes, words = fixture()
        expected = core_state(7, probes, words.__getitem__, configuration())
        config = configuration()
        for spec in config["fields"]["component"].values():
            spec[0] += 4
        words["component_store"] = [w << 4 for w in words["component_store"]]
        self.assertEqual(expected, core_state(7, probes, words.__getitem__, config))

    def test_dump_name_and_address_permutation(self):
        config = configuration({"memories": {"cells_render": {"name": "new.bank", "addresses": list(reversed(range(COUNT)))}}})
        dump = {"name": "new.bank", "frame": 7, "width": 16, "depth": COUNT,
                "words": [hex(w) for w in reversed(range(COUNT))]}
        self.assertEqual(decode_dump(dump, 7, config, "cells_render"), list(range(COUNT)))
        dump["frame"] = 8
        with self.assertRaises(EvidenceError):
            decode_dump(dump, 7, config, "cells_render")

    def test_corrupt_owner_value_mirror_and_missing_probe_fail(self):
        for name, address, value in (("component_index_map", 39, 511), ("values_shadow", 40, 1),
                                     ("cells_shadow", 39, 0)):
            probes, words = fixture()
            words[name][address] = value
            with self.assertRaises(EvidenceError):
                core_state(7, probes, words.__getitem__, configuration())
        probes, words = fixture()
        del probes["component_count"]
        with self.assertRaises(EvidenceError):
            core_state(7, probes, words.__getitem__, configuration())

    def test_config_unknown_schema_and_duplicate_address_fail(self):
        with self.assertRaises(EvidenceError):
            configuration({"schema": "other"})
        with self.assertRaises(EvidenceError):
            configuration({"skip_checks": True})
        config = configuration({"memories": {"cells_render": {"addresses": [0] * COUNT}}})
        with self.assertRaises(EvidenceError):
            decode_dump({"name": "cells_render", "frame": 7, "width": 16, "depth": COUNT,
                         "words": ["0x0"] * COUNT}, 7, config, "cells_render")

    def test_partial_final_uart_line_is_preserved(self):
        line = {"index": 0, "text": "@NB,00", "end": "", "errors": 0,
                "terminated": False, "t_ms": 1, "end_t_ms": 2}
        uart = {"errors": [], "lines": [line], "sent": [], "pending": {"bytes": 1}, "stats": {}}
        result = uart_events(uart)
        self.assertEqual(result["tx"][0]["text"], "@NB,00")
        self.assertEqual(result["capture_boundary"]["pending"], {"bytes": 1})
        uart["lines"].append({**line, "index": 1, "t_ms": 3, "end_t_ms": 4})
        with self.assertRaises(EvidenceError):
            uart_events(uart)

    def test_missing_duplicate_and_corrupted_capture_controls(self):
        probes, words = fixture()
        with tempfile.TemporaryDirectory() as temp:
            run = Path(temp)
            dumps = {}
            widths = {"cells_render": 16, "cells_shadow": 16, "values_shadow": 12,
                      "value_units_shadow": 4, "component_store": 40, "component_index_map": 9}
            for name, values in words.items():
                path = name + ".json"
                (run / path).write_text(json.dumps({"name": name, "frame": 7, "width": widths[name],
                       "depth": COUNT, "words": [hex(w) for w in values]}))
                dumps[name] = [{"frame": 7, "path": path}]
            report = {"ok": True, "stimulus": [], "dumps": dumps,
                      "monitors": {"vga": {"frames": [{"index": 7, "t_ms": 150, "probes": probes}]}}}
            (run / "report.json").write_text(json.dumps(report))
            self.assertEqual(len(adapt_run(run, [7])["snapshots"]), 1)
            captured = report["monitors"]["vga"]["frames"][0]
            del captured["t_ms"]
            captured["t_ps"] = 150_000_000_000
            (run / "report.json").write_text(json.dumps(report))
            self.assertEqual(adapt_run(run, [7])["snapshots"][0]["t_ms"], 150)
            for bad in (-1, True, 150.5):
                captured["t_ps"] = bad
                (run / "report.json").write_text(json.dumps(report))
                with self.assertRaises(EvidenceError):
                    adapt_run(run, [7])
            captured["t_ps"] = 150_000_000_000
            captured["t_ms"] = 151
            (run / "report.json").write_text(json.dumps(report))
            with self.assertRaises(EvidenceError):
                adapt_run(run, [7])
            del captured["t_ms"]
            report["dumps"]["cells_render"].append(copy.deepcopy(dumps["cells_render"][0]))
            (run / "report.json").write_text(json.dumps(report))
            with self.assertRaises(EvidenceError):
                adapt_run(run, [7])
            del report["dumps"]["cells_render"]
            (run / "report.json").write_text(json.dumps(report))
            with self.assertRaises(EvidenceError):
                adapt_run(run, [7])


def qualify(evidence, output):
    """Existing ignored baseline captures are optional inputs, never generated fixtures."""
    source = json.loads(Path(evidence).read_text())
    results, paired = [], {}
    for section, profile in (("m2", "ui"), ("m3", "backend")):
        for item in source[section]:
            base = Path(item["summary"]).parent
            reference = base / "reference"
            index = json.loads((reference / "checkpoints.json").read_text())
            normalized = adapt_run(base / "rtl", [c["frame"] for c in index["checkpoints"]], profile=profile)
            comparison = compare_reference(normalized, reference)
            require_ok = comparison["ok"]
            if not require_ok:
                raise AssertionError(comparison)
            paired.setdefault(item["scenario"], {})[item["runtime"]] = normalized
            results.append({"scenario": item["scenario"], "runtime": item["runtime"], "profile": profile,
                            "checkpoints": len(index["checkpoints"]), "core_golden": comparison,
                            "normalized_sha256": digest(normalized), "actual": str(base / "rtl")})
    equality = []
    for scenario, runs in paired.items():
        same = runs["native"] == runs["docker"]
        equality.append({"scenario": scenario, "equal": same})
        if not same:
            raise AssertionError(f"native/docker semantic difference: {scenario}")
    output = Path(output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps({"ok": True, "accepted_evidence": str(evidence),
                                 "runs": results, "runtime_equality": equality}, indent=2) + "\n")
    return results


if __name__ == "__main__":
    import sys
    if len(sys.argv) == 4 and sys.argv[1] == "--qualify":
        results = qualify(sys.argv[2], sys.argv[3])
        print(f"qualified {len(results)} accepted captures / {sum(r['checkpoints'] for r in results)} checkpoints")
    else:
        unittest.main()
