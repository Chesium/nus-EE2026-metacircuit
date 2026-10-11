"""Boot checkpoints (run/batch --checkpoint N) and --profile."""

import hashlib
import json
import os
import shutil
import tempfile
import unittest
from pathlib import Path

from helpers import EXAMPLES, write

from framescope import FramescopeError, manifest, runtime
from framescope import checkpoint as ckpt
from framescope.batch import batch
from framescope.run import run


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


def comparable(report: dict) -> dict:
    """A report without wall times, build/checkpoint info and its run directory;
    files under the run directory are replaced by their relative path and hash."""
    run_dir = report["run_dir"]

    def walk(o):
        if isinstance(o, dict):
            return {k: walk(v) for k, v in o.items()
                    if k not in ("wall_s", "build", "checkpoint", "run_dir", "warnings", "profile")}
        if isinstance(o, list):
            return [walk(v) for v in o]
        if isinstance(o, str) and o.startswith(run_dir):
            p = Path(o)
            return [Path(o).relative_to(run_dir).as_posix(), hashlib.sha256(p.read_bytes()).hexdigest()]
        return o

    return walk(report)


class ConsumedTest(unittest.TestCase):
    LINES = [
        "t 0 rst_n 0", "t 200000 rst_n 1", "t 90000000000 btn 1",
        "f 2 btn 1", "f 0 mode 1", "f 1 btn 0",
        "p 1:10:0 btn 1", "p 0:135:0 btn 0", "p 2:0:0 btn 0",
    ]

    def test_partition_in_harness_order(self):
        self.assertEqual(ckpt.consumed(self.LINES, 2, 50_000_000_000), [
            "t 0 rst_n 0", "t 200000 rst_n 1",
            "f 0 mode 1", "f 1 btn 0",
            "p 0:135:0 btn 0", "p 1:10:0 btn 1",
        ])
        self.assertIn("t 90000000000 btn 1", ckpt.consumed(self.LINES, 2, 90_000_000_000))

    def test_same_time_events_keep_their_order(self):
        a = ckpt.consumed(["f 1 btn 1", "f 1 btn 0"], 2, 0)
        b = ckpt.consumed(["f 1 btn 0", "f 1 btn 1"], 2, 0)
        self.assertNotEqual(a, b)

    def test_boot_lines(self):
        self.assertEqual(ckpt._boot_lines(self.LINES, 2), [
            "t 0 rst_n 0", "t 200000 rst_n 1", "t 90000000000 btn 1", "f 0 mode 1", "f 1 btn 0",
            "p 1:10:0 btn 1", "p 0:135:0 btn 0",
        ])

    def test_selected(self):
        self.assertTrue(ckpt.selected("all", 0, 5))
        self.assertFalse(ckpt.selected("none", 0, 5))
        self.assertTrue(ckpt.selected("last", 4, 5))
        self.assertFalse(ckpt.selected("last", 3, 5))
        self.assertEqual([i for i in range(5) if ckpt.selected("1,3", i, 5)], [1, 3])

    def test_replay_copies_selected_files(self):
        with tempfile.TemporaryDirectory() as tmp:
            src, dst = Path(tmp) / "ck", Path(tmp) / "run"
            for rel in ("vga/frame_0000.png", "vga/raster_0000.png", "vga/frame_0001.png", "vga/raster_0001.png",
                        "dumps/m/frame_0000.json", "dumps/m/frame_0001.json"):
                write(src / rel, rel)
            events = [
                {"event": "frame", "index": 0, "active_source": "de", "png": "vga/frame_0000.png",
                 "raster_png": "vga/raster_0000.png"},
                {"event": "probes", "frame": 0, "values": {}},
                {"event": "dump", "name": "m", "frame": 0, "path": "dumps/m/frame_0000.json"},
                {"event": "frame", "index": 1, "active_source": "de", "png": "vga/frame_0001.png",
                 "raster_png": "vga/raster_0001.png"},
                {"event": "dump", "name": "m", "frame": 1, "path": "dumps/m/frame_0001.json"},
            ]
            ck = ckpt.Checkpoint(src, 2, 0, events, False, 0.0)
            out = ckpt.replay(ck, dst, frames=5, save="1", dump="0", raster=False)
            self.assertEqual([e["event"] for e in out], ["frame", "probes", "dump", "frame"])
            self.assertNotIn("png", out[0])
            self.assertEqual(out[3]["png"], str(dst / "vga/frame_0001.png"))
            self.assertNotIn("raster_png", out[3])  # only with --raster or without an active-area crop
            self.assertEqual(out[2]["path"], str(dst / "dumps/m/frame_0000.json"))
            self.assertEqual(sorted(p.relative_to(dst).as_posix() for p in dst.rglob("*") if p.is_file()),
                             ["dumps/m/frame_0000.json", "vga/frame_0001.png"])
            self.assertEqual(events[0]["png"], "vga/frame_0000.png")  # the checkpoint's events are not modified


@unittest.skipIf(RT is None, "no framescope runtime available")
class PatternCheckpointTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.work = tempfile.TemporaryDirectory(dir=EXAMPLES / "pmod_pattern")

    @classmethod
    def tearDownClass(cls):
        cls.work.cleanup()

    def setUp(self):
        self.m = manifest.load(EXAMPLES / "pmod_pattern")
        # A private work dir (builds shared by this class), without checkpoints from earlier tests.
        self.m.work_dir = Path(self.work.name)
        shutil.rmtree(self.m.work_dir / ckpt.CHECKPOINT_DIR, ignore_errors=True)
        tmp = tempfile.TemporaryDirectory(dir=self.m.work_dir)
        self.addCleanup(tmp.cleanup)
        self.tmp = Path(tmp.name)
        # Events before (frame 0, frame 1) and after (frame 2) the checkpoint at frame 2.
        self.stim = write(self.tmp / "stim.toml", """
[[event]]
frame = 0
line = 135
set = { btn = 1 }
[[event]]
frame = 1
set = { btn = 0 }
[[event]]
frame = 2
line = 300
pixel = 200
set = { btn = 1 }
""")

    def _run(self, name, **kw):
        kw.setdefault("stim", self.stim)
        kw.setdefault("dump", "all")
        return run(self.m, RT, _quiet, frames=4, out=self.tmp / name, **kw)

    def test_restored_run_matches_cold_run(self):
        cold = self._run("cold")
        first = self._run("first", checkpoint=2)
        again = self._run("again", checkpoint=2, save="1,3", dump="0,3")
        selective = self._run("selective", save="1,3", dump="0,3")
        for r in (cold, first, again, selective):
            self.assertTrue(r["ok"], r)
        self.assertIsNone(cold["checkpoint"])
        self.assertTrue(first["checkpoint"]["restored"] and first["checkpoint"]["created"])
        self.assertTrue(again["checkpoint"]["restored"] and not again["checkpoint"]["created"])
        self.assertEqual(again["checkpoint"]["path"], first["checkpoint"]["path"])
        self.assertEqual(first["warnings"], [])
        self.assertEqual(comparable(first), comparable(cold))
        self.assertEqual(comparable(again), comparable(selective))
        self.assertEqual(len(first["monitors"]["vga"]["frames"]), 4)
        self.assertEqual(len(first["stimulus"]), 2)  # line-timed events, before and after the checkpoint
        # The restored part really started at frame 2: it simulated less.
        self.assertLess(first["sim"]["wall_s"], cold["sim"]["wall_s"])

    def test_different_early_stimulus_gets_its_own_checkpoint(self):
        a = self._run("a", checkpoint=2)
        b = self._run("b", checkpoint=2, sets=["btn=1"])
        c = self._run("c", checkpoint=2, stim=None)
        paths = {r["checkpoint"]["path"] for r in (a, b, c)}
        self.assertEqual(len(paths), 3)
        self.assertEqual(comparable(b), comparable(self._run("b_cold", sets=["btn=1"])))

    def test_unusable_checkpoint_falls_back_to_a_cold_run(self):
        for kw, reason in [({"checkpoint": 4}, "1 <= N < frames"), ({"checkpoint": 1, "trace": (0, 1)}, "--trace")]:
            with self.subTest(kw=kw):
                r = self._run(f"fallback{len(reason)}", **kw)
                self.assertTrue(r["ok"], r)
                self.assertFalse(r["checkpoint"]["restored"])
                self.assertIn(reason, r["checkpoint"]["reason"])
                self.assertTrue(any("not using a checkpoint" in w for w in r["warnings"]))

    def test_pending_line_timed_event_prevents_the_checkpoint(self):
        # Without a timing preset, line offsets up to 4095 are accepted; frames have 525
        # lines, so this event is still pending at the frame-2 checkpoint and fires late.
        text = (EXAMPLES / "pmod_pattern" / "framescope.toml").read_text()
        text = text.replace('timing = "640x480@60"', "").replace('"rtl/pattern_top.sv"',
                                                               json.dumps((EXAMPLES / "pmod_pattern" / "rtl" / "pattern_top.sv").as_posix()))
        self.m = manifest.load(write(self.tmp / "no_preset" / "framescope.toml", text))
        self.m.work_dir = Path(self.work.name)
        stim = write(self.tmp / "late.toml", "[[event]]\nframe = 1\nline = 600\nset = { btn = 1 }\n")
        r = self._run("late", stim=stim, checkpoint=2)
        cold = self._run("late_cold", stim=stim)
        self.assertTrue(r["ok"], r)
        self.assertFalse(r["checkpoint"]["restored"])
        self.assertIn("has not fired yet", r["checkpoint"]["reason"])
        self.assertEqual((r["stimulus"][0]["at_frame"], r["stimulus"][0]["late"]), (2, True))
        self.assertEqual(comparable(r), comparable(cold))
        self.assertEqual(list((self.m.work_dir / ckpt.CHECKPOINT_DIR).glob("*")), [])  # no leftovers

    def test_checkpoints_are_safe_to_delete(self):
        first = self._run("first", checkpoint=2)
        shutil.rmtree(self.m.work_dir / ckpt.CHECKPOINT_DIR)
        second = self._run("second", checkpoint=2)
        self.assertTrue(second["checkpoint"]["created"])
        self.assertEqual(comparable(first), comparable(second))

    def test_batch_boots_once(self):
        other = write(self.tmp / "other.toml", "[[event]]\nframe = 3\nset = { btn = 1 }\n")
        plain = write(self.tmp / "plain.toml", "frames = 3\n")
        cold = batch(self.m, RT, _quiet, scenarios=[other, plain], frames=4, out=self.tmp / "b_cold", jobs=2)
        warm = batch(self.m, RT, _quiet, scenarios=[other, plain], frames=4, out=self.tmp / "b_warm", jobs=2,
                     checkpoint=2)
        self.assertTrue(cold["ok"] and warm["ok"], warm)
        self.assertEqual(len(list((self.m.work_dir / ckpt.CHECKPOINT_DIR).glob("*/meta.json"))), 1)
        for c, w in zip(cold["scenarios"], warm["scenarios"]):
            self.assertTrue(w["checkpoint"]["restored"])
            self.assertEqual(comparable(json.loads(Path(c["report"]).read_text())),
                             comparable(json.loads(Path(w["report"]).read_text())))

    def test_profile(self):
        r = self._run("profile", profile=True)
        prof = r["sim"]["profile"]
        self.assertGreater(prof["eval"]["calls"], 100_000)
        self.assertEqual(prof["png"]["calls"], 4)
        self.assertEqual(prof["dump"]["calls"], 4)
        self.assertLessEqual(prof["eval"]["s"], prof["wall_s"])


@unittest.skipIf(RT is None or os.environ.get("FRAMESCOPE_METACIRCUIT_TEST") != "1",
                 "set FRAMESCOPE_METACIRCUIT_TEST=1 (needs the metacircuit checkout)")
class MetacircuitCheckpointTest(unittest.TestCase):
    def test_restored_run_matches_cold_run(self):
        m = manifest.load(EXAMPLES / "metacircuit")
        stim = EXAMPLES / "metacircuit" / "stim_click.toml"  # events from frame 1, line 10
        with tempfile.TemporaryDirectory(dir=m.work_dir.parent) as tmp:
            m.work_dir = Path(tmp) / "work"
            cold = run(m, RT, _quiet, frames=5, out=Path(tmp) / "cold", stim=stim, dump="all")
            warm = run(m, RT, _quiet, frames=5, out=Path(tmp) / "warm", stim=stim, dump="all", checkpoint=3)
            self.assertTrue(cold["ok"] and warm["ok"], warm)
            self.assertTrue(warm["checkpoint"]["restored"])
            self.assertEqual(comparable(warm), comparable(cold))


if __name__ == "__main__":
    unittest.main()
