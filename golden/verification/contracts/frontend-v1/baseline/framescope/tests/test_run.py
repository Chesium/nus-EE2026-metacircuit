import unittest

from helpers import EXAMPLES

from framescope import FramescopeError, manifest
from framescope.run import _attach_probes, _stim_entry, check_frame_selection


class RunHelpersTest(unittest.TestCase):
    def test_frame_selection(self):
        self.assertEqual(check_frame_selection("last", 3, "--dump"), "last")
        self.assertEqual(check_frame_selection("0, 2", 3, "--dump"), "0,2")
        with self.assertRaisesRegex(FramescopeError, r"frame\(s\) \[3\] outside 0..2"):
            check_frame_selection("1,3", 3, "--dump")
        with self.assertRaisesRegex(FramescopeError, "expects all, last, none"):
            check_frame_selection("first", 3, "--dump")

    def test_attach_probes_sign_extends(self):
        m = manifest.load(EXAMPLES / "pmod_pattern")
        events = [
            {"event": "start", "probe_widths": {"frame": 8, "mode": 1, "vc": 10, "hc": 10, "vc_minus_500": 11}},
            {"event": "probes", "frame": 0, "values": {"frame": 2, "mode": 0, "vc": 490, "hc": 1, "vc_minus_500": 2038}},
        ]
        monitor = {"frames": [{"index": 0}, {"index": 1}]}
        decl = _attach_probes(m, monitor, events)
        self.assertEqual(monitor["frames"][0]["probes"]["vc_minus_500"], -10)
        self.assertEqual(monitor["frames"][0]["probes"]["vc"], 490)
        self.assertNotIn("probes", monitor["frames"][1])
        self.assertEqual(decl["vc_minus_500"], {"expr": "$signed({1'b0, dut.vc}) - 11'sd500", "width": 11, "signed": True})

    def test_stim_entry_late(self):
        e = {"event": "stim", "name": "btn", "value": 1, "frame": 0, "line": 3, "pixel": 900,
             "at_frame": 0, "at_line": 4, "at_pixel": 0, "t_ps": 1_000_000}
        self.assertTrue(_stim_entry(e)["late"])
        self.assertFalse(_stim_entry({**e, "at_line": 3, "at_pixel": 900})["late"])


if __name__ == "__main__":
    unittest.main()
