import importlib.util
import json
import tempfile
import shutil
import subprocess
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location('vivado_qor', Path(__file__).resolve().parents[1] / 'vivado_qor.py')
qor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(qor)

UTIL = '''| Slice LUTs* | 1,234 | 0 | 20800 |
| Slice Registers | 567 | 0 | 41600 |
| Block RAM Tile | 12.5 | 50 |
| DSPs | 2 | 90 |'''
TIMING = '''Design Timing Summary
WNS(ns) TNS(ns) TNS Failing Endpoints TNS Total Endpoints WHS(ns) THS(ns) THS Failing Endpoints THS Total Endpoints
------- ------- --------------------- ------------------- ------- ------- --------------------- -------------------
-1.125 -15.250 23 1000 0.050 0.000 0 1000
'''
HIER = '| GlobalRender_top | (top) | 1234 | 1234 | 0 | 0 | 567 | 12 | 1 | 2 |\n|   child | Child | 5 | 5 | 0 | 0 | 6 | 1 | 0 | 0 |'
DRC = 'REPORT SUMMARY\n| UTLZ-1 | Error | Resource utilization | 1 |'
CHECKS = '\n'.join('checking %s (0)' % s for s in ['no_clock', 'unconstrained_internal_endpoints', 'no_input_delay', 'no_output_delay'])


class VivadoReports(unittest.TestCase):
    def test_utilization_counts_fractional_bram(self):
        self.assertEqual(qor.parse_utilization(UTIL), dict(lut=1234., ff=567., bram=12.5, dsp=2.))

    def test_utilization_missing_dsp_rejected(self):
        with self.assertRaises(ValueError):
            qor.parse_utilization(UTIL.replace('DSPs', 'unknown'))

    def test_hierarchical_and_drc_categories(self):
        rows = qor.parse_hierarchy(HIER)
        self.assertEqual(rows[0]['resources']['bram'], 12.5)
        self.assertEqual(rows[1]['path'], 'GlobalRender_top/child')
        self.assertEqual(qor.parse_drc(DRC)['findings'][0]['severity'], 'Error')
        for parse, bad in [(qor.parse_hierarchy, 'truncated'), (qor.parse_drc, 'REPORT SUMMARY')]:
            with self.assertRaises(ValueError):
                parse(bad)

    def test_timing_setup_and_hold(self):
        result = qor.parse_timing(TIMING)
        self.assertEqual(result['wns_ns'], -1.125)
        self.assertEqual(result['setup_failing_endpoints'], 23)
        self.assertEqual(result['whs_ns'], .05)

    def test_truncated_timing_rejected(self):
        with self.assertRaises(ValueError):
            qor.parse_timing(TIMING.split('-------')[0])

    def test_unconstrained_categories_mandatory(self):
        self.assertEqual(sum(qor.parse_checks(CHECKS).values()), 0)
        with self.assertRaises(ValueError):
            qor.parse_checks(CHECKS.replace('no_clock', 'unknown'))

    def test_missing_evidence_never_passes(self):
        with tempfile.TemporaryDirectory() as td:
            result = qor.summarize(Path(td))
            self.assertEqual(result['evidence_status'], 'incomplete')
            self.assertFalse(result['timing_clean'])

    def test_source_and_artifact_corruption_fail(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td) / 'repo'
            out = Path(td) / 'out'
            for p in qor.PROJECT_SOURCES + qor.PROJECT_IPS + qor.CONSTRAINTS + ['tools/vivado_qor.py', 'tools/vivado_qor.tcl', 'metacircuit.tcl']:
                path = root / p
                path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(qor.ROOT / p, path)
            qor.prepare(root, out, 'synth')
            reports = {'synth.complete': 'complete', 'synth.dcp': 'checkpoint', 'synth_utilization.rpt': UTIL, 'synth_hierarchical.rpt': HIER, 'synth_timing.rpt': TIMING, 'synth_paths.rpt': 'Slack (VIOLATED) : -1.125ns\n Logic Levels: 7\n Data Path Delay: 5.0ns (logic 3.0ns (60%) route 2.0ns (40%))', 'synth_clocks.rpt': 'clock report', 'synth_clock_periods.tsv': 'sys_clk_pin\t10.000\t0\n', 'synth_check_timing.rpt': CHECKS, 'synth_cdc.rpt': 'CDC\n' + ('review crossing\n' * 10), 'synth_drc.rpt': DRC, 'settings.txt': 'Vivado v2025.2 SW Build 6299465', 'run.json': json.dumps({'returncode': 0}), 'vivado.log': 'WARNING: test', 'vivado.jou': 'journal', 'console.log': 'console', 'ip_status.rpt': 'IP status', 'compile_order.rpt': 'compile order', 'black_boxes.rpt': 'black_box_count=0'}
            for name, value in reports.items():
                (out / name).write_text(value)
            hashes = {p.name: qor.sha(p) for p in out.iterdir() if p.is_file()}
            (out / 'artifacts.json').write_text(json.dumps(hashes))
            clean = qor.summarize(out, root)
            self.assertEqual(clean['evidence_status'], 'complete', clean['errors'])
            self.assertFalse(clean['timing_clean'])  # setup violation and CDC needs review
            (out / 'synth_utilization.rpt').write_text(UTIL.replace('1,234', '1,233'))
            corrupted = qor.summarize(out, root)
            self.assertIn('corrupt artifact: synth_utilization.rpt', corrupted['errors'])
            frozen = qor.summarize(out)
            self.assertNotIn('stale source hash: ' + qor.CONSTRAINTS[0], frozen['errors'])
            (root / qor.CONSTRAINTS[0]).write_text('weakened clock')
            stale = qor.summarize(out, root)
            self.assertIn('stale source hash: ' + qor.CONSTRAINTS[0], stale['errors'])
            (out / 'vivado.log').write_text('ERROR: tool silently returned zero\n')
            hashes['vivado.log'] = qor.sha(out / 'vivado.log')
            (out / 'artifacts.json').write_text(json.dumps(hashes))
            self.assertIn('Vivado logged ERROR: 1', qor.summarize(out, root)['errors'])
            (out / 'inputs' / qor.CONSTRAINTS[0]).write_text('snapshot corrupted')
            self.assertIn('stale source hash: ' + qor.CONSTRAINTS[0], qor.summarize(out)['errors'])
            (out / 'synth.dcp').unlink()
            self.assertEqual(qor.summarize(out, root)['evidence_status'], 'incomplete')

    @unittest.skipUnless(shutil.which('tclsh'), 'Tcl shell unavailable')
    def test_locked_ip_fails_before_generation(self):
        with tempfile.TemporaryDirectory() as td:
            out = Path(td)
            (out / 'manifest.tcl').write_text('set qor_sources {}\nset qor_ips {locked.xci}\nset qor_stage synth\n')
            stub = out / 'locked_test.tcl'
            stub.write_text("""
set argc 2
set argv [list [lindex $argv 0] [lindex $argv 1]]
proc unknown {args} { return {} }
proc get_ips {args} { return locked_core }
proc get_property {name object} { if {$name eq "IS_LOCKED"} { return 1 }; return {} }
proc generate_target {args} { error "UNSAFE generation reached" }
source [file join [lindex $argv 0] tools vivado_qor.tcl]
""")
            result = subprocess.run(['tclsh', str(stub), str(qor.ROOT), str(out)], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('Locked reachable IP', result.stderr)
            self.assertNotIn('UNSAFE generation reached', result.stderr)

    def test_frontend_reachability_omits_only_unused_ip(self):
        audit = qor.audit_reachability(qor.ROOT)
        self.assertEqual(qor.IPS, [])
        self.assertIn('src/design/driver/Mouse_Control.vhd', audit['edges'])
        self.assertIn('ps2interface', audit['edges']['src/design/driver/Mouse_Control.vhd'])
        self.assertEqual(set(audit['ip_reference_wrappers']), {
            'src/design/floating_point/fpo_fma.v', 'src/design/floating_point/fpo_div.v',
            'src/design/floating_point/fpo_tofixed.v'})

    def test_changed_reachability_fails_before_launch(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            for name in qor.PROJECT_SOURCES:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(qor.ROOT / name, path)
            top = root / 'src/design/rendering/GlobalRender_top.v'
            top.write_text(top.read_text() + '\nfpo_div newly_reachable();\n')
            with self.assertRaisesRegex(ValueError, 'reachability changed'):
                qor.audit_reachability(root)

    def test_existing_directory_not_reused(self):
        with tempfile.TemporaryDirectory() as td:
            (Path(td) / 'old.rpt').write_text('stale')
            with self.assertRaises(ValueError):
                qor.prepare(qor.ROOT, Path(td), 'synth')


if __name__ == '__main__':
    unittest.main()
