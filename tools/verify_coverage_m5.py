#!/usr/bin/env python3
"""Project-owned coverage audit: validated measurement plus no-regression for changed modules.

Structural gaps are reported as corpus limits. Readiness fails on invalid or
missing evidence, missing required instrumentation, or a changed module instance
that reaches a smaller fraction of its eligible points than the recorded baseline.
"""
import argparse
from collections import defaultdict
import fnmatch
import hashlib
import importlib
import json
from pathlib import Path
import re
import sys

REPO=Path(__file__).resolve().parents[1]
SHA=re.compile(r'[0-9a-f]{64}')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_parser(framescope,policy):
    source=framescope/'src/framescope/coverage.py'
    if digest(source)!=policy['parser_sha256']:
        raise ValueError('coverage parser source hash mismatch')
    sys.path.insert(0,str(framescope/'src'))
    parser=importlib.import_module('framescope.coverage')
    if Path(parser.__file__).resolve()!=source.resolve():
        raise ValueError('coverage parser imported from unexpected checkout')
    return parser


def validate_policy(policy):
    if policy.get('schema_version')!=2 or policy.get('required_runtimes')!=['native']:
        raise ValueError('unsupported coverage policy/runtime requirements')
    if not SHA.fullmatch(policy.get('parser_sha256','')):
        raise ValueError('missing pinned coverage parser')
    if policy.get('types')!=['line','branch','toggle']:
        raise ValueError('coverage policy must measure line, branch and toggle')
    names=set()
    for requirement in policy['requirements']:
        name=requirement.get('module')
        if not name or name in names or not requirement.get('source_suffix','').startswith('/src/design/'):
            raise ValueError('duplicate/missing required module or source')
        names.add(name)
    for exclusion in policy['exclusions']:
        if not exclusion.get('reason') or not exclusion.get('source_glob'):
            raise ValueError('unexplained coverage exclusion')
        if exclusion['source_glob'] not in ('*/framescope_top.sv','*/stubs/MouseCtl.sv','*/stubs/MouseDisplay.sv'):
            raise ValueError('production coverage exclusion is not allowed')
    baseline=policy.get('baseline',{})
    if not baseline.get('path') or not SHA.fullmatch(baseline.get('sha256','')):
        raise ValueError('missing pinned coverage baseline')


def load_baseline(policy,repo=REPO):
    path=repo/policy['baseline']['path']
    if digest(path)!=policy['baseline']['sha256']:
        raise ValueError('coverage baseline identity changed')
    return json.loads(path.read_text())


def relative_source(source):
    marker='/src/design/'
    return 'src/design/'+source.split(marker,1)[1] if marker in source else source


def source_file(original,source_root):
    marker='/src/design/'
    if marker in original:
        return source_root/'src/design'/original.split(marker,1)[1]
    return Path(original)


def excluded(source,policy):
    return next((x for x in policy['exclusions'] if fnmatch.fnmatch(source,x['source_glob'])),None)


def validate_input(path,source_root,policy,parser,scope):
    report=json.loads(path.read_text()); errors=[]; points={}
    if report.get('schema_version')!=1 or report.get('complete') is not True:
        errors.append('incomplete/unsupported coverage report')
    boundary=report.get('boundary',{})
    if boundary.get('event')!='coverage_boundary' or boundary.get('frame')!=3 or not isinstance(boundary.get('t_ps'),int):
        errors.append('missing expected boot/scenario boundary')
    info=report.get('provenance',{}); runtime=info.get('runtime')
    expected=policy['runtime_tools'].get(runtime,{})
    if not expected or not str(info.get('tool_version','')).startswith(expected.get('version_prefix','missing')):
        errors.append('unexpected coverage runtime/tool version')
    identity=info.get('runtime_identity','')
    if runtime=='docker' and identity!=expected.get('identity'):
        errors.append('unexpected Docker coverage identity')
    if runtime=='native' and identity!='native:'+info.get('tool_version',''):
        errors.append('unexpected native coverage identity')
    options=info.get('build_options',{})
    if options.get('coverage') is not True or options.get('x_initial')!='unique' or options.get('x_assign')!='unique':
        errors.append('coverage/randomized initialization options missing')
    if info.get('top')!='GlobalRender_top' or not info.get('build_id'):
        errors.append('missing coverage top/build identity')
    declared={}; stale=[]
    for item in info.get('sources',[]):
        name=item.get('path',''); wanted=item.get('sha256','')
        if name in declared or not name or not SHA.fullmatch(wanted):
            errors.append('duplicate/malformed source provenance'); continue
        declared[name]=wanted
        actual=source_file(name,source_root)
        if not actual.is_file() or digest(actual)!=wanted:
            stale.append({'source':name,'checked_path':str(actual),'expected_sha256':wanted})
    if not declared or not any(x.endswith('/src/design/rendering/GlobalRender_top.v') for x in declared):
        errors.append('missing production top source provenance')
    if stale: errors.append('stale/missing source identity')
    mappings=report.get('source_paths',{})
    hashes={}
    # Validate both splits, including the unused split; do not silently accept a
    # fabricated boot report alongside an apparently intact scenario artifact.
    for split in ('boot','scenario'):
        artifact=report.get('artifacts',{}).get(split,{})
        raw=path.parent/(split+'.dat')
        if Path(artifact.get('path','')).name!=raw.name or not raw.is_file():
            errors.append('missing '+split+' coverage artifact'); continue
        hashes[split]=digest(raw)
        if hashes[split]!=artifact.get('sha256'):
            errors.append(split+' coverage artifact hash mismatch')
        try:
            parsed=parser.read_points(raw)
            if parser.summarize(parsed,source_paths=mappings)!=artifact.get('summary'):
                errors.append(split+' coverage summary differs from raw evidence')
            for key in parsed:
                data=parser.fields(key); host=mappings.get(data['f'])
                if not host or (host not in declared and not excluded(host,policy)):
                    errors.append('instrumented source absent from declared provenance'); break
            # 'run' counts a point reached if either split hit it: declaration initializers
            # and reset-only logic run during boot, so a scenario-only view can never reach them.
            if split==scope or scope=='run':
                for key,hits in parsed.items(): points[key]=points.get(key,0)+hits
        except Exception as exc:
            errors.append(split+' coverage parse failed: '+str(exc))
    # The enclosing successful simulation is a second independent record of
    # provenance/split metadata; coverage.json alone cannot fabricate an exit0.
    run_path=path.parent.parent/'report.json'
    try:
        run=json.loads(run_path.read_text())
        if run.get('ok') is not True or run.get('runtime')!=runtime:
            errors.append('enclosing simulation failed/runtime mismatch')
        saved=run.get('coverage',{})
        for key in ('schema_version','provenance','boundary','complete','artifacts','source_paths'):
            if saved.get(key)!=report.get(key):
                errors.append('enclosing coverage record mismatch: '+key)
        init=run.get('sim',{}).get('initialization',{})
        if not isinstance(init.get('seed'),int) or init['seed']<1 or init.get('x_initial')!='unique' or init.get('x_assign')!='unique':
            errors.append('missing cold randomized seed provenance')
        if run.get('sim',{}).get('frames_requested',0)<=boundary.get('frame',3):
            errors.append('no scenario frame after coverage boundary')
    except (OSError,ValueError,TypeError) as exc:
        errors.append('enclosing simulation report missing/invalid: '+str(exc))
    return {'report':str(path),'report_sha256':digest(path),'runtime':runtime,'provenance':info,
            'artifact_sha256':hashes,'run_report_sha256':digest(run_path) if run_path.is_file() else None,
            'source_root':str(source_root),'stale_sources':stale,'errors':errors},points,mappings


def summarize_all(points,mappings,policy,parser,source_hashes=None):
    groups=defaultdict(lambda:defaultdict(list))
    for key,hits in points.items():
        data=parser.fields(key); category,_,module=data['page'].partition('/')
        kind=data.get('t') or category.removeprefix('v_').removeprefix('sp_')
        source=mappings.get(data['f'],data['f']); exclusion=excluded(source,policy)
        groups[(module,data.get('h',''),source)][kind].append({
            'id':hashlib.sha256(key.encode()).hexdigest(),'line':int(data['l']),
            'column':data.get('n'),'comment':data.get('o',''),'hits':hits,
            'exclusion_reason':exclusion['reason'] if exclusion else None})
    rows=[]; reasons=[]; totals=defaultdict(lambda:dict(instrumented=0,eligible=0,reached=0,uncovered=0,excluded=0))
    for (module,hierarchy,source),types in sorted(groups.items()):
        metrics={}
        for kind,items in sorted(types.items()):
            eligible=[x for x in items if x['exclusion_reason'] is None]
            gaps=[x for x in eligible if x['hits']==0]
            omissions=[x for x in items if x['exclusion_reason'] is not None]
            counts={'instrumented':len(items),'eligible':len(eligible),'reached':len(eligible)-len(gaps),
                    'uncovered':len(gaps),'excluded':len(omissions)}
            metrics[kind]={**counts,'uncovered_points':gaps,'excluded_points':omissions}
            for key,value in counts.items(): totals[kind][key]+=value
        rows.append({'module':module,'hierarchy':hierarchy,'source':source,
                     'source_sha256':(source_hashes or {}).get(source),'types':metrics})
    for requirement in policy['requirements']:
        matches=[r for r in rows if (r['module']==requirement['module'] or r['module'].startswith(requirement['module']+'__'))
                 and r['source'].endswith(requirement['source_suffix'])]
        if not matches:
            reasons.append(requirement['module']+': required module not instrumented')
        for kind in policy['types']:
            if matches and not any(r['types'].get(kind,{}).get('eligible',0) for r in matches):
                reasons.append(requirement['module']+'/'+kind+': required instrumentation missing')
    return {'totals':dict(totals),'modules':rows,'readiness_failures':sorted(set(reasons))}


def instance_key(row):
    return row['hierarchy']+'|'+relative_source(row['source'])


def baseline_record(runtimes,scope):
    """Per-instance reached/eligible counts with source identity, written once per accepted baseline."""
    record={}
    for runtime,summary in runtimes.items():
        record[runtime]={instance_key(r):{'source':relative_source(r['source']),'source_sha256':r['source_sha256'],
                                          'types':{k:{'eligible':v['eligible'],'reached':v['reached']} for k,v in r['types'].items()}}
                         for r in summary['modules'] if r['source_sha256']}
    return {'schema_version':1,'scope':scope,'instances':record}


def compare_baseline(runtime,summary,baseline,scope):
    """Changed instances may not lose coverage; unchanged and new instances are reported only."""
    if baseline.get('scope')!=scope:
        return {'failures':['coverage baseline scope %r differs from audit scope %r'%(baseline.get('scope'),scope)],
                'changed':[],'new':[],'removed':[]}
    recorded=baseline['instances'].get(runtime)
    if recorded is None:
        return {'failures':[runtime+': no recorded coverage baseline'],'changed':[],'new':[],'removed':[]}
    failures,changed,new=[],[],[]; seen=set()
    for row in summary['modules']:
        if not row['source_sha256']:
            continue
        key=instance_key(row); seen.add(key); base=recorded.get(key)
        if base is None:
            new.append(key); continue
        if base['source_sha256']==row['source_sha256']:
            continue
        changed.append(key)
        for kind,before in base['types'].items():
            after=row['types'].get(kind,{'eligible':0,'reached':0})
            if not before['eligible'] or not after['eligible']:
                continue
            if after['reached']*before['eligible']<before['reached']*after['eligible']:
                failures.append('%s/%s: coverage fell from %d/%d to %d/%d'%(key,kind,before['reached'],before['eligible'],
                                                                          after['reached'],after['eligible']))
    return {'failures':failures,'changed':changed,'new':sorted(new),'removed':sorted(set(recorded)-seen)}


def audit(paths,source_root,policy,parser,scope='run',baseline=None):
    validate_policy(policy); results=[]; buckets={}; errors=[]; seen=set()
    for path in paths:
        path=path.resolve()
        if path in seen: raise ValueError('duplicate coverage report input')
        seen.add(path)
        result,points,mappings=validate_input(path,source_root,policy,parser,scope); results.append(result)
        errors.extend(result['errors']); runtime=result['runtime']
        if runtime not in buckets: buckets[runtime]={'provenance':result['provenance'],'points':{},'mappings':mappings}
        bucket=buckets[runtime]
        if bucket['provenance']!=result['provenance'] or (bucket['points'] and set(bucket['points'])!=set(points)):
            errors.append('incompatible coverage merge provenance/instrumentation'); continue
        for key,count in points.items(): bucket['points'][key]=bucket['points'].get(key,0)+count
    runtimes={}
    for runtime,b in buckets.items():
        hashes={item['path']:item['sha256'] for item in b['provenance'].get('sources',[])}
        runtimes[runtime]=summarize_all(b['points'],b['mappings'],policy,parser,hashes)
        if baseline is not None:
            comparison=compare_baseline(runtime,runtimes[runtime],baseline,scope)
            runtimes[runtime]['baseline_comparison']=comparison
            runtimes[runtime]['readiness_failures']=sorted(set(runtimes[runtime]['readiness_failures']+comparison['failures']))
    missing=[r for r in policy['required_runtimes'] if r not in runtimes]
    ready=(baseline is not None and not errors and not missing
           and all(not r['readiness_failures'] for r in runtimes.values()))
    return {'schema_version':2,'ok':not errors,'ready':ready,'scope':scope,'inputs':results,'runtimes':runtimes,
            'validation_errors':sorted(set(errors)),'missing_required_runtimes':missing,
            'baseline_applied':baseline is not None,
            'interpretation':'Instrumentation counters; uncovered points are reported corpus limits, not proof of safety'}


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--coverage-report',type=Path,action='append',required=True)
    ap.add_argument('--source-root',type=Path,default=REPO)
    ap.add_argument('--framescope',type=Path,default=REPO.parent/'framescope')
    ap.add_argument('--policy',type=Path,default=REPO/'tools/m5_coverage_policy.json')
    ap.add_argument('--scope',choices=('run','boot','scenario'),default='run',
                    help='run: boot and scenario hits together (default, used by the baseline)')
    ap.add_argument('--audit-only',action='store_true',help='Validate evidence only; readiness still requires the baseline comparison')
    ap.add_argument('--write-baseline',type=Path,help='Write a new baseline record from valid evidence (rebaseline only)')
    ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args(); out=args.out.resolve(); out.mkdir(parents=True,exist_ok=False)
    try:
        policy=json.loads(args.policy.read_text()); validate_policy(policy)
        parser=load_parser(args.framescope.resolve(),policy)
        baseline=None if args.write_baseline else load_baseline(policy)
        result=audit(args.coverage_report,args.source_root.resolve(),policy,parser,args.scope,baseline)
        if args.write_baseline:
            if not result['ok'] or result['missing_required_runtimes']:
                raise ValueError('baseline requires valid evidence from every required runtime')
            args.write_baseline.write_text(json.dumps(baseline_record(result['runtimes'],args.scope),indent=1,sort_keys=True)+'\n')
    except Exception as exc:
        result={'schema_version':2,'ok':False,'ready':False,'validation_errors':[str(exc)]}
    result.update(policy_sha256=digest(args.policy),tool_sha256=digest(Path(__file__)),audit_only=args.audit_only)
    (out/'summary.json').write_text(json.dumps(result,indent=2)+'\n')
    accepted=result['ok'] if (args.audit_only or args.write_baseline) else result['ready']
    print(json.dumps({'ok':result['ok'],'ready':result['ready'],'summary':str(out/'summary.json')}))
    return 0 if accepted else 1


if __name__=='__main__':sys.exit(main())
