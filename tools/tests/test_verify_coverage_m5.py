"""Coverage integrity and readiness controls; no model-generated pass fixture."""
from copy import deepcopy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[2]
spec=importlib.util.spec_from_file_location('coverage_gate',ROOT/'tools/verify_coverage_m5.py')
G=importlib.util.module_from_spec(spec);spec.loader.exec_module(G)
POLICY=json.loads((ROOT/'tools/m5_coverage_policy.json').read_text())
PARSER=G.load_parser(ROOT.parent/'framescope',POLICY)


class CoverageControls(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name);self.directory=self.root/'rtl/coverage';self.directory.mkdir(parents=True)
        self.source=self.root/'src/design/rendering/GlobalRender_top.v';self.source.parent.mkdir(parents=True)
        self.source.write_text('module GlobalRender_top; endmodule\n')
        self.path=self.directory/'coverage.json'
        key=lambda i:'\x01f\x02'+str(self.source)+'\x01l\x021\x01n\x02'+str(i)+'\x01page\x02v_toggle/GlobalRender_top\x01o\x02signal'+str(i)+'\x01h\x02TOP.framescope_top.dut'
        points={key(i):0 for i in range(100)}
        info={'build_id':'fixture-build','top':'GlobalRender_top','runtime':'native',
              'tool_version':'Verilator 5.046 fixture','runtime_identity':'native:Verilator 5.046 fixture',
              'sources':[{'path':str(self.source),'sha256':G.digest(self.source)}],
              'build_options':{'coverage':True,'x_initial':'unique','x_assign':'unique'}}
        self.report={'schema_version':1,'complete':True,'boundary':{'event':'coverage_boundary','frame':3,'t_ps':123},
                     'provenance':info,'source_paths':{str(self.source):str(self.source)},'artifacts':{}}
        for split in ('boot','scenario'):
            raw=self.directory/(split+'.dat');raw.write_text("# SystemC::Coverage-3\n"+''.join(f"C '{k}' {v}\n"for k,v in points.items()))
            self.report['artifacts'][split]={'path':str(raw),'sha256':G.digest(raw),
                                           'summary':PARSER.summarize(points,source_paths=self.report['source_paths'])}
        self.run={'ok':True,'runtime':'native','sim':{'initialization':{'seed':1,'x_initial':'unique','x_assign':'unique'},'frames_requested':4}}
        self.save()

    def save(self):
        self.path.write_text(json.dumps(self.report))
        self.run['coverage']=deepcopy(self.report)
        (self.directory.parent/'report.json').write_text(json.dumps(self.run))

    def audit(self,paths=None,policy=None):
        return G.audit(paths or [self.path],self.root,policy or POLICY,PARSER)

    def test_full_uncapped_gap_counts_and_unreviewed_readiness(self):
        result=self.audit();self.assertTrue(result['ok']);self.assertFalse(result['ready'])
        metric=result['runtimes']['native']['modules'][0]['types']['toggle']
        self.assertEqual(metric['eligible'],100);self.assertEqual(metric['uncovered'],100)
        self.assertEqual(len(metric['uncovered_points']),100)
        self.assertEqual(result['missing_required_runtimes'],['docker'])

    def test_raw_coverage_corruption(self):
        (self.directory/'scenario.dat').write_text('broken')
        self.assertFalse(self.audit()['ok'])

    def test_capped_report_output_corruption(self):
        self.report['artifacts']['scenario']['summary']['modules'][0]['types']['toggle']['eligible']=1
        self.save();self.assertFalse(self.audit()['ok'])

    def test_missing_unused_boot_split_also_fails(self):
        (self.directory/'boot.dat').unlink();self.assertFalse(self.audit()['ok'])

    def test_source_corruption(self):
        self.source.write_text('changed');self.assertFalse(self.audit()['ok'])

    def test_runtime_and_tool_provenance_corruption(self):
        for field,value in [('runtime','other'),('runtime_identity','forged'),('tool_version','Verilator 1.000')]:
            original=self.report['provenance'][field];self.report['provenance'][field]=value
            self.save();self.assertFalse(self.audit()['ok']);self.report['provenance'][field]=original

    def test_parent_failed_or_missing_simulation(self):
        self.run['ok']=False;self.save();self.assertFalse(self.audit()['ok'])
        (self.directory.parent/'report.json').unlink();self.assertFalse(self.audit()['ok'])

    def test_duplicate_inputs_rejected(self):
        with self.assertRaises(ValueError):self.audit([self.path,self.path])

    def test_unexplained_or_production_exclusion_rejected(self):
        for mutate in [lambda p:p['exclusions'][0].pop('reason'),
                       lambda p:p['exclusions'][0].update(source_glob='*/GlobalRender_top.v')]:
            policy=deepcopy(POLICY);mutate(policy)
            with self.assertRaises(ValueError):self.audit(policy=policy)

    def test_threshold_lowering_rejected(self):
        policy=deepcopy(POLICY);policy['default_requirement']['max_uncovered']=1
        with self.assertRaises(ValueError):self.audit(policy=policy)

    def test_split_and_seed_provenance_required(self):
        self.report['boundary']['frame']=2;self.save();self.assertFalse(self.audit()['ok'])
        self.report['boundary']['frame']=3;self.run['sim']['initialization']['seed']=0
        self.save();self.assertFalse(self.audit()['ok'])

    def test_parent_and_external_report_must_match(self):
        self.path.write_text(json.dumps({**self.report,'complete':False}))
        self.assertFalse(self.audit()['ok'])

    def test_parameterized_module_requires_canonical_name_and_source(self):
        source='/candidate/src/design/common/FloodQueueStore.v'
        key='\x01f\x02'+source+'\x01l\x021\x01page\x02v_toggle/FloodQueueStore__D480\x01h\x02TOP.queue'
        result=G.summarize_all({key:1},{source:source},POLICY,PARSER)
        row=result['modules'][0]
        self.assertEqual(row['module'],'FloodQueueStore__D480')
        self.assertEqual(row['logical_module'],'FloodQueueStore')
        self.assertNotIn('FloodQueueStore: required module not instrumented',result['readiness_failures'])
        self.assertIn('FloodQueueStore/branch: required instrumentation missing',result['readiness_failures'])
        self.assertIn('FloodQueueStore/line: required instrumentation missing',result['readiness_failures'])
        self.assertTrue(row['input_scope_reviewed'])
        self.assertFalse(row['requirement_reviewed'])
        self.assertIn('non-power-of-two-pointer-wrap',row['required_input_bins'])
        wrong='/candidate/src/design/other/FloodQueueStore.v'
        result=G.summarize_all({key:1},{source:wrong},POLICY,PARSER)
        self.assertIn('FloodQueueStore: required module not instrumented',result['readiness_failures'])

    def test_input_domain_review_does_not_prove_reachability(self):
        result=self.audit();obligations=result['runtimes']['native']['input_scope_obligations']
        queue=next(x for x in obligations if x['module']=='FloodQueueStore')
        self.assertTrue(queue['input_scope_reviewed']);self.assertFalse(queue['reachability_reviewed'])
        self.assertEqual(queue['instrumented_modules'],[])
        self.assertIn('not established',queue['input_bin_evidence'])
        self.assertFalse(result['ready'])

    def test_missing_module_input_obligations_rejected(self):
        for field in ('source_suffix','required_input_bins','input_scope_reviewed','scope_review_note'):
            policy=deepcopy(POLICY);policy['requirements'][0].pop(field)
            with self.assertRaises(ValueError):self.audit(policy=policy)


if __name__=='__main__':unittest.main()
