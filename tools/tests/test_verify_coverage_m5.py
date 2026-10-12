"""Coverage integrity, required instrumentation and baseline no-regression controls."""
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

    def test_gaps_are_reported_not_readiness_failures(self):
        result=self.audit();self.assertTrue(result['ok']);self.assertFalse(result['ready'])
        metric=result['runtimes']['native']['modules'][0]['types']['toggle']
        self.assertEqual(metric['eligible'],100);self.assertEqual(metric['uncovered'],100)
        self.assertEqual(len(metric['uncovered_points']),100)
        self.assertFalse(any('uncovered' in r for r in result['runtimes']['native']['readiness_failures']))
        self.assertEqual(result['missing_required_runtimes'],[])
        self.assertFalse(result['baseline_applied'])

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

    def test_policy_requires_all_types_and_pinned_baseline(self):
        for mutate in [lambda p:p.update(types=['line']),lambda p:p.update(required_runtimes=['native','docker']),lambda p:p['baseline'].update(sha256='unpinned'),
                       lambda p:p.pop('baseline')]:
            policy=deepcopy(POLICY);mutate(policy)
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
        self.assertEqual(result['modules'][0]['module'],'FloodQueueStore__D480')
        self.assertNotIn('FloodQueueStore: required module not instrumented',result['readiness_failures'])
        self.assertIn('FloodQueueStore/branch: required instrumentation missing',result['readiness_failures'])
        self.assertIn('FloodQueueStore/line: required instrumentation missing',result['readiness_failures'])
        wrong='/candidate/src/design/other/FloodQueueStore.v'
        result=G.summarize_all({key:1},{source:wrong},POLICY,PARSER)
        self.assertIn('FloodQueueStore: required module not instrumented',result['readiness_failures'])

    def test_missing_required_module_source_rejected(self):
        policy=deepcopy(POLICY);policy['requirements'][0].pop('source_suffix')
        with self.assertRaises(ValueError):self.audit(policy=policy)

    def baseline(self,reached,source_sha):
        record=G.baseline_record(self.audit()['runtimes'],'run')
        entry=next(iter(record['instances']['native'].values()))
        entry['types']['toggle']['reached']=reached;entry['source_sha256']=source_sha
        return record

    def comparison(self,baseline):
        return G.audit([self.path],self.root,POLICY,PARSER,baseline=baseline)['runtimes']['native']['baseline_comparison']

    def failures(self,baseline):
        return self.comparison(baseline)['failures']

    def test_changed_module_may_not_lose_coverage(self):
        self.assertTrue(any('coverage fell from 10/100 to 0/100' in f for f in self.failures(self.baseline(10,'old'))))
        self.assertEqual(self.failures(self.baseline(0,'old')),[])

    def test_unchanged_module_gaps_are_not_compared(self):
        self.assertEqual(self.failures(self.baseline(10,G.digest(self.source))),[])

    def test_new_instances_are_reported_and_missing_runtime_baseline_fails(self):
        comparison=self.comparison({'schema_version':1,'scope':'run','instances':{'native':{}}})
        self.assertEqual(comparison['failures'],[]);self.assertEqual(len(comparison['new']),1)
        self.assertTrue(self.failures({'schema_version':1,'scope':'run','instances':{}}))

    def test_baseline_from_another_scope_is_rejected(self):
        baseline=self.baseline(0,'old');baseline['scope']='scenario'
        self.assertTrue(any('scope' in f for f in self.failures(baseline)))

    def test_run_scope_counts_boot_only_hits(self):
        boot=self.directory/'boot.dat';text=boot.read_text().replace(' 0\n',' 1\n',1);boot.write_text(text)
        self.report['artifacts']['boot']['sha256']=G.digest(boot)
        self.report['artifacts']['boot']['summary']=PARSER.summarize(PARSER.read_points(boot),source_paths=self.report['source_paths'])
        self.save()
        reached=lambda scope:G.audit([self.path],self.root,POLICY,PARSER,scope)['runtimes']['native']['modules'][0]['types']['toggle']['reached']
        self.assertEqual(reached('scenario'),0);self.assertEqual(reached('run'),1)

if __name__=='__main__':unittest.main()
