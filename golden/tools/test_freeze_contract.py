"""Mutation tests for the frozen contract boundary (no RTL simulations)."""
import copy
import json
from pathlib import Path
import shutil
import tempfile
import unittest

import freeze_contract as fc


class FrozenContractTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name) / "candidate"
        self.contract = Path(self.temp.name) / "contract"
        shutil.copytree(fc.DEFAULT_CONTRACT, self.contract)
        self.metadata = json.loads((self.contract / "contract.json").read_text())
        self.pin = (self.contract / "contract.sha256").read_text().strip()
        for entry in self.metadata["entries"]:
            if entry["current_required"]:
                dest = self.repo / entry["path"]
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(self.contract / entry["stored"], dest)

    def check(self):
        return fc.verify(self.repo, self.contract, self.pin)

    def test_unchanged_accepted_inputs_pass(self):
        self.assertTrue(self.check()["ok"])

    def test_oracle_mask_and_scenario_changes_fail(self):
        for name in ["golden/src/core/step.ts", "golden/masks/m2_ui.toml",
                     "golden/scenarios/m1_latency.json"]:
            with self.subTest(name=name):
                path = self.repo / name
                original = path.read_bytes()
                path.write_bytes(original + b"\nchanged\n")
                result = self.check()
                self.assertFalse(result["ok"])
                self.assertTrue(any(name in error for error in result["errors"]))
                path.write_bytes(original)

    def test_candidate_asset_provenance_changes_pass_but_pixels_fail(self):
        path = self.repo / "golden/assets/canvas.json"
        asset = json.loads(path.read_text())
        asset["source"] = {"candidate": "renderer rewritten"}
        path.write_text(json.dumps(asset))
        self.assertTrue(self.check()["ok"])
        self.assertEqual(self.check()["provenance_changes"][0]["path"], "golden/assets/canvas.json")
        asset["palette"][0] = "deliberate pixel corruption"
        path.write_text(json.dumps(asset))
        self.assertFalse(self.check()["ok"])

    def test_missing_and_new_mandatory_inputs_fail(self):
        path = self.repo / "golden/src/core/new_behavior.ts"
        path.write_text("// new candidate behavior\n")
        self.assertFalse(self.check()["ok"])
        path.unlink()
        (self.repo / "golden/src/core/step.ts").unlink()
        self.assertFalse(self.check()["ok"])

    def test_fixed_constraints_cannot_be_weakened(self):
        path = self.repo / "src/constraint/basys3.xdc"
        path.write_text(path.read_text().replace("-period 10.00", "-period 20.00"))
        self.assertFalse(self.check()["ok"])

    def test_candidate_rtl_may_change_without_changing_reference(self):
        path = self.repo / "src/design/rendering/GlobalRender_top.v"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("module candidate; endmodule\n")
        self.assertTrue(self.check()["ok"])
        baseline = self.contract / "payloads/src/design/rendering/GlobalRender_top.v"
        self.assertNotEqual(path.read_bytes(), baseline.read_bytes())
        baseline.write_text("module corrupted_baseline; endmodule\n")
        self.assertFalse(self.check()["ok"])

    def test_frozen_visual_and_saved_corpus_corruptions_fail(self):
        for group in ["visual", "saved_corpus"]:
            with self.subTest(group=group):
                entry = next(e for e in self.metadata["entries"] if e["group"] == group)
                path = self.contract / entry["stored"]
                original = path.read_bytes()
                path.write_bytes(original + b" ")
                self.assertFalse(self.check()["ok"])
                path.write_bytes(original)

    def test_external_pin_rejects_rewritten_contract_and_local_lock(self):
        altered = copy.deepcopy(self.metadata)
        altered["comparison"]["pixel_tolerance"] = 1
        raw = json.dumps(altered).encode()
        (self.contract / "contract.json").write_bytes(raw)
        (self.contract / "contract.sha256").write_text(fc.sha(raw))
        self.assertFalse(self.check()["ok"])
        self.assertIn("contract identity changed", self.check()["errors"])

    def test_refreeze_existing_contract_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "already exists"):
            fc.freeze(self.repo, self.contract, self.repo / "framescope")

    def test_path_traversal_cannot_read_outside_contract(self):
        altered = copy.deepcopy(self.metadata)
        altered["entries"][0]["stored"] = "../secret"
        raw = json.dumps(altered).encode()
        (self.contract / "contract.json").write_bytes(raw)
        (self.contract / "contract.sha256").write_text(fc.sha(raw))
        result = fc.verify(self.repo, self.contract)
        self.assertFalse(result["ok"])
        self.assertTrue(any("unsafe contract path" in error for error in result["errors"]))


if __name__ == "__main__":
    unittest.main()
