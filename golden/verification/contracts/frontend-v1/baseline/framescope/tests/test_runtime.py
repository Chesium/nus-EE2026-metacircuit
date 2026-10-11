import tempfile
import unittest
from pathlib import Path

from helpers import REPO  # noqa: F401  (puts src/ on sys.path)

from framescope import FramescopeError
from framescope.build import _covering_dirs
from framescope.runtime import Mount, PathMap


class PathMapTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name).resolve()
        self.proj = root / "proj"
        self.work = self.proj / ".framescope"
        self.pm = PathMap([Mount(self.proj, "/fs/src0"), Mount(self.work, "/fs/work", writable=True)])

    def tearDown(self):
        self.tmp.cleanup()

    def test_longest_prefix_wins(self):
        self.assertEqual(self.pm.to_rt(self.proj / "rtl" / "a.sv"), "/fs/src0/rtl/a.sv")
        self.assertEqual(self.pm.to_rt(self.work / "build" / "x"), "/fs/work/build/x")
        self.assertEqual(self.pm.to_rt(self.work), "/fs/work")

    def test_round_trip_and_rewrite(self):
        self.assertEqual(self.pm.to_host("/fs/work/runs/1/vga/frame_0000.png"),
                         self.work / "runs" / "1" / "vga" / "frame_0000.png")
        text = "%Error: /fs/src0/rtl/a.sv:12:3: syntax error"
        self.assertEqual(self.pm.rewrite(text), f"%Error: {self.proj / 'rtl' / 'a.sv'}:12:3: syntax error")

    def test_outside_mounts(self):
        with self.assertRaises(FramescopeError):
            self.pm.to_rt(Path(self.tmp.name).resolve() / "elsewhere")

    def test_covering_dirs(self):
        a = self.proj / "a"
        self.assertEqual(_covering_dirs([a / "b", self.proj, a]), [self.proj])
        self.assertEqual(_covering_dirs([a / "x", a / "y"]), [a / "x", a / "y"])


if __name__ == "__main__":
    unittest.main()
