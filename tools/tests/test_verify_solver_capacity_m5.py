"""Check independent boundary physics and capacity packet coverage."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from verify_solver_capacity_m5 import capacity_fixtures, packets
from verify_solver_xsim_m5 import rational_mna
from verify_solver_m5 import packet


class CapacityFixtures(unittest.TestCase):
    def test_reject_recover_without_reset_covers_auxiliary_count(self):
        fixtures = capacity_fixtures()
        self.assertEqual([f["rejection"] for f in fixtures], [True, False, True, False])
        self.assertEqual(
            [sum(e[0] == 3 for e in f["elements"]) for f in fixtures], [1, 1, 2, 0]
        )
        self.assertEqual(
            [f["nodes"] + sum(e[0] == 3 for e in f["elements"]) for f in fixtures],
            [33, 32, 33, 32],
        )
        self.assertTrue(all(len(f["elements"]) == 32 for f in fixtures))

    def test_exact_boundary_recovery_matches_independent_mna(self):
        for fixture in capacity_fixtures():
            if fixture["rejection"]:
                continue
            elements = [(*e, 0) for e in fixture["elements"]]
            self.assertEqual(
                rational_mna(elements, fixture["nodes"]), fixture["values"]
            )

    def test_packets_are_complete_sequential_and_checksummed(self):
        for fixture in capacity_fixtures():
            tx = packets(fixture["frame"], fixture["nodes"], fixture["elements"])
            self.assertEqual(len(tx), 34)
            fields = [line[1:-3].split(",") for line in tx]
            self.assertEqual(fields[0][2:], fields[-1][2:])
            self.assertEqual([int(row[2], 16) for row in fields[1:-1]], list(range(32)))
            self.assertTrue(all(row[1] == fixture["frame"] for row in fields))
            for line in tx:
                self.assertEqual(packet(line[1:-3]), line)


if __name__ == "__main__":
    unittest.main()
