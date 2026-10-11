#!/usr/bin/env python3
"""Project-owned coverage audit; full readiness fails on gaps/unreviewed scope."""
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
    if policy.get('schema_version')!=1 or policy.get('required_runtimes')!=['native','docker']:
        raise ValueError('unsupported coverage policy/runtime requirements')
    if not SHA.fullmatch(policy.get('parser_sha256','')):
        raise ValueError('missing pinned coverage parser')
    for requirement in [policy['default_requirement'],*policy['requirements']]:
        if not requirement.get('input_scope') or type(requirement.get('reviewed')) is not bool:
            raise ValueError('coverage requirement missing input scope/review state')
        if requirement.get('max_uncovered')!=0 or requirement.get('types')!=['line','branch','toggle']:
            raise ValueError('coverage gaps may not be waived by a percentage/threshold')
    names=set()
    for requirement in policy['requirements']:
        name=requirement.get('module')
        if not name or name in names:
            raise ValueError('duplicate/missing required module')
        names.add(name)
        bins=requirement.get('required_input_bins')
        if (not requirement.get('source_suffix','').startswith('/src/design/') or
            not isinstance(bins,list) or not bins or any(not isinstance(b,str) or not b for b in bins) or
            len(bins)!=len(set(bins)) or type(requirement.get('input_scope_reviewed')) is not bool or
            not requirement.get('scope_review_note')):
            raise ValueError('missing explicit module/source/input-domain review')
    for exclusion in policy['exclusions']:
        if not exclusion.get('reason') or exclusion.get('reviewed') is not True or not exclusion.get('source_glob'):
            raise ValueError('unexplained/unreviewed coverage exclusion')
        if exclusion['source_glob'] not in ('*/framescope_top.sv','*/stubs/MouseCtl.sv','*/stubs/MouseDisplay.sv'):
            raise ValueError('unreviewed production coverage exclusion')


def source_file(original,source_root):
    marker='/src/design/'
    if marker in original:
        return source_root/'src/design'/original.split(marker,1)[1]
    return Path(original)


def excluded(source,policy):
    return next((x for x in policy['exclusions'] if fnmatch.fnmatch(source,x['source_glob'])),None)


def requirement_for(module,source,policy):
    # Verilator specializes parameterized modules as Name__piN/Name__Dhex.
    # Both the canonical name and the reviewed production source must agree;
    # unrelated similarly named modules cannot satisfy the requirement.
    return next((r for r in policy['requirements']
                 if (module==r['module'] or module.startswith(r['module']+'__'))
                 and source.endswith(r['source_suffix'])),policy['default_requirement'])


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
            if split==scope: points=parsed
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


def summarize_all(points,mappings,policy,parser):
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
    present=set()
    for (module,hierarchy,source),types in sorted(groups.items()):
        requirement=requirement_for(module,source,policy)
        logical_module=requirement.get('module',module)
        present.add(logical_module)
        metrics={}
        for kind,items in sorted(types.items()):
            eligible=[x for x in items if x['exclusion_reason'] is None]
            gaps=[x for x in eligible if x['hits']==0]
            omissions=[x for x in items if x['exclusion_reason'] is not None]
            counts={'instrumented':len(items),'eligible':len(eligible),'reached':len(eligible)-len(gaps),
                    'uncovered':len(gaps),'excluded':len(omissions)}
            metrics[kind]={**counts,'uncovered_points':gaps,'excluded_points':omissions}
            for key,value in counts.items(): totals[kind][key]+=value
            if eligible and (kind not in requirement['types'] or gaps):
                reasons.append(module+'/'+kind+': uncovered or unspecified instrumentation')
        if any(x['eligible'] for x in metrics.values()) and not requirement['reviewed']:
            reasons.append(module+': requirement/reachability review incomplete')
        rows.append({'module':module,'logical_module':logical_module,'hierarchy':hierarchy,'source':source,
                     'input_scope':requirement['input_scope'],'requirement_reviewed':requirement['reviewed'],'types':metrics})
        rows[-1].update(input_scope_reviewed=requirement.get('input_scope_reviewed',False),
                        required_input_bins=requirement.get('required_input_bins',[]),
                        scope_review_note=requirement.get('scope_review_note','Remaining production scope is unreviewed.'))
    for requirement in policy['requirements']:
        if requirement['module'] not in present:
            reasons.append(requirement['module']+': required module not instrumented')
    obligations=[]
    for requirement in policy['requirements']:
        matches=[r for r in rows if r['logical_module']==requirement['module'] and
                 r['source'].endswith(requirement['source_suffix'])]
        missing_types=[kind for kind in requirement['types'] if matches and
                       not any(r['types'].get(kind,{}).get('eligible',0) for r in matches)]
        for kind in missing_types:
            reasons.append(requirement['module']+'/'+kind+': required instrumentation missing')
        obligations.append({'module':requirement['module'],'source_suffix':requirement['source_suffix'],
                            'instrumented_modules':sorted(set(r['module'] for r in matches)),
                            'missing_required_types':missing_types,
                            'input_scope_reviewed':requirement['input_scope_reviewed'],
                            'reachability_reviewed':requirement['reviewed'],
                            'required_input_bins':requirement['required_input_bins'],
                            'input_bin_evidence':'not established by raw line/branch/toggle counters'})
    return {'totals':dict(totals),'modules':rows,'input_scope_obligations':obligations,
            'readiness_failures':sorted(set(reasons))}


def audit(paths,source_root,policy,parser,scope='scenario'):
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
    runtimes={runtime:summarize_all(b['points'],b['mappings'],policy,parser) for runtime,b in buckets.items()}
    missing=[r for r in policy['required_runtimes'] if r not in runtimes]
    ready=not errors and not missing and all(not r['readiness_failures'] for r in runtimes.values())
    return {'schema_version':1,'ok':not errors,'ready':ready,'scope':scope,'inputs':results,'runtimes':runtimes,
            'validation_errors':sorted(set(errors)),'missing_required_runtimes':missing,
            'interpretation':'Instrumentation counters, not all HDL lines or proof that uncovered paths are safe'}


def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--coverage-report',type=Path,action='append',required=True)
    ap.add_argument('--source-root',type=Path,default=REPO)
    ap.add_argument('--framescope',type=Path,default=REPO.parent/'framescope')
    ap.add_argument('--policy',type=Path,default=REPO/'tools/m5_coverage_policy.json')
    ap.add_argument('--scope',choices=('boot','scenario'),default='scenario')
    ap.add_argument('--audit-only',action='store_true',help='Validate evidence; still reports ready:false for coverage gaps')
    ap.add_argument('--out',type=Path,required=True)
    args=ap.parse_args(); out=args.out.resolve(); out.mkdir(parents=True,exist_ok=False)
    try:
        policy=json.loads(args.policy.read_text()); validate_policy(policy)
        parser=load_parser(args.framescope.resolve(),policy)
        result=audit(args.coverage_report,args.source_root.resolve(),policy,parser,args.scope)
    except Exception as exc:
        result={'schema_version':1,'ok':False,'ready':False,'validation_errors':[str(exc)]}
    result.update(policy_sha256=digest(args.policy),tool_sha256=digest(Path(__file__)),audit_only=args.audit_only)
    (out/'summary.json').write_text(json.dumps(result,indent=2)+'\n')
    accepted=result['ok'] if args.audit_only else result['ready']
    print(json.dumps({'ok':result['ok'],'ready':result['ready'],'summary':str(out/'summary.json')}))
    return 0 if accepted else 1


if __name__=='__main__':sys.exit(main())
