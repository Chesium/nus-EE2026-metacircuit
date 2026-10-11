import os
import shutil
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from helpers import EXAMPLES, write

from framescope import FramescopeError, manifest, runtime
from framescope.batch import _plan, batch, expand
from framescope.rundir import new_dir
from framescope.scenario import read_meta


def _runtime():
    if os.environ.get("FRAMESCOPE_INTEGRATION") == "0":
        return None
    try:
        return runtime.detect()
    except FramescopeError:
        return None


RT = _runtime()


def _quiet(_msg: str) -> None:
    pass


class ScenarioMetaTest(unittest.TestCase):
    def test_top_level_keys(self):
        with tempfile.TemporaryDirectory() as tmp:
            stim = write(Path(tmp) / "s" / "a.toml",
                         'frames = 3\nreference = "../refs/a"\nmasks = "m.toml"\n[[event]]\nframe = 1\nset = { btn = 1 }\n')
            meta = read_meta(stim)
            self.assertEqual(meta.frames, 3)
            self.assertEqual(meta.reference, (Path(tmp) / "refs" / "a").resolve())
            self.assertEqual(meta.masks, (Path(tmp) / "s" / "m.toml").resolve())
            self.assertEqual(read_meta(None).frames, None)
            write(stim, "frames = 0\n")
            with self.assertRaisesRegex(FramescopeError, "positive integer"):
                read_meta(stim)


class RunDirTest(unittest.TestCase):
    def test_parallel_creation_is_unique(self):
        with tempfile.TemporaryDirectory() as tmp:
            with ThreadPoolExecutor(8) as pool:
                dirs = list(pool.map(lambda _: new_dir(Path(tmp), "20261009-120000"), range(16)))
            self.assertEqual(len(set(dirs)), 16)
            self.assertIn(Path(tmp).resolve() / "20261009-120000-15", dirs)


class PlanTest(unittest.TestCase):
    def test_expand_names_references_and_masks(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write(root / "sc" / "a.toml", "frames = 4\n")
            write(root / "sc" / "b.toml", f'reference = "{(root / "other").as_posix()}"\nmasks = "b.masks.toml"\n')
            write(root / "sc" / "b.masks.toml", "")
            write(root / "sc" / "masks.toml", "")
            write(root / "sc2" / "a.toml", "")
            write(root / "refs" / "a" / "masks.toml", "")
            (root / "other").mkdir()
            stims = expand([root / "sc", root / "sc2" / "a.toml"])
            self.assertEqual([s.name for s in stims], ["a.toml", "b.toml", "a.toml"])
            plan = _plan(stims, root / "batch", 2, root / "refs", root / "default.toml")
            self.assertEqual([s.name for s in plan], ["a", "b", "a-2"])
            self.assertEqual([s.frames for s in plan], [4, 2, 2])
            a, b, a2 = plan
            self.assertEqual((a.reference, a.masks), (root / "refs" / "a", root / "refs" / "a" / "masks.toml"))
            self.assertEqual((b.reference, b.masks), ((root / "other").resolve(), (root / "sc" / "b.masks.toml").resolve()))
            self.assertIsNone(a2.reference)  # refs/a-2 does not exist
            self.assertIn("reference directory not found", a2.reference_error)
            self.assertEqual(a2.run_dir, root / "batch" / "a-2")


@unittest.skipIf(RT is None, "no framescope runtime available")
class PatternBatchTest(unittest.TestCase):
    def test_two_scenarios_with_references(self):
        m = manifest.load(EXAMPLES / "pmod_pattern")
        with tempfile.TemporaryDirectory(dir=m.work_dir.parent) as tmp:
            root = Path(tmp)
            write(root / "sc" / "bars.toml", "frames = 1\n")
            shutil.copy(EXAMPLES / "pmod_pattern" / "stim_button.toml", root / "sc" / "button.toml")

            first = batch(m, RT, _quiet, scenarios=[root / "sc"], frames=2, out=root / "b1", jobs=2)
            self.assertTrue(first["ok"], first)
            self.assertEqual(first["jobs"], 2)
            self.assertTrue((root / "b1" / "summary.json").is_file())
            res = {s["name"]: s for s in first["scenarios"]}
            self.assertEqual((res["bars"]["frames"], res["button"]["frames"]), (1, 2))  # stim key vs -n default
            self.assertIsNone(res["bars"]["compare"])
            self.assertTrue(Path(res["button"]["run_dir"], "vga", "frame_0001.png").is_file())

            # first batch as the reference: everything matches...
            again = batch(m, RT, _quiet, scenarios=[root / "sc"], frames=2, out=root / "b2", refs=root / "b1")
            self.assertTrue(again["ok"], again)
            for s in again["scenarios"]:
                self.assertTrue(s["compare"]["ok"])
                self.assertEqual(s["compare"]["identical"], s["frames"])

            # ...until a reference frame is swapped: bars frame 0 vs the checkerboard
            shutil.copy(root / "b1" / "button" / "vga" / "frame_0001.png", root / "b1" / "bars" / "vga" / "frame_0000.png")
            bad = batch(m, RT, _quiet, scenarios=[root / "sc"], frames=2, out=root / "b3", refs=root / "b1")
            self.assertFalse(bad["ok"])
            self.assertEqual(bad["summary"]["failed_scenarios"], ["bars"])
            cmp = next(s for s in bad["scenarios"] if s["name"] == "bars")["compare"]
            self.assertEqual(cmp["failed"], 1)
            self.assertGreater(cmp["failures"][0]["diff_pixels"], 0)
            self.assertTrue(Path(cmp["failures"][0]["diff_png"]).is_file())

            with self.assertRaisesRegex(FramescopeError, "already exist"):
                batch(m, RT, _quiet, scenarios=[root / "sc"], out=root / "b1")


if __name__ == "__main__":
    unittest.main()
