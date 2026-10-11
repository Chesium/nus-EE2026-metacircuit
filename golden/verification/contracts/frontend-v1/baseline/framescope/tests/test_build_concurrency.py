"""Concurrent callers must compile a shared cache entry exactly once."""
from concurrent.futures import ThreadPoolExecutor
import tempfile
import unittest
from pathlib import Path
from threading import Barrier

from framescope.build import build
from framescope import manifest
from test_seed import RTL, CONFIG
from test_integration import RT, _quiet
from helpers import write


class BuildConcurrencyTest(unittest.TestCase):
    @unittest.skipIf(RT is None, "no runtime available")
    def test_two_cold_builds_share_one_complete_binary(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write(root / "seed_top.sv", RTL)
            write(root / "framescope.toml", CONFIG)
            m = manifest.load(root / "framescope.toml")
            barrier = Barrier(2)
            def compile_one():
                barrier.wait(timeout=10)
                return build(m, RT, _quiet)
            with ThreadPoolExecutor(max_workers=2) as executor:
                results = list(executor.map(lambda _: compile_one(), range(2)))
            self.assertEqual(sorted(r.cached for r in results), [False, True])
            self.assertEqual(results[0].binary, results[1].binary)
            self.assertTrue(results[0].binary.is_file())
