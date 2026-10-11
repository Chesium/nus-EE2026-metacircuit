#!/usr/bin/env python3
"""Scoped production frontend/store/queue invariants on the frozen UART-loop bench."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

REPO = Path(__file__).resolve().parents[2]
IMAGE = 'framescope-toolchain:6501155dc903'
NEGATIVES = {'component-map': 'component index map', 'voltage-bank': 'voltage metadata atomicity',
             'queue-count': 'flood queue bounds', 'voltage-data':'committed voltage data',
             'stage-state':'staged reply cancellation', 'component-entry':'component store entry',
             'selected-read':'selected index synchronous read', 'rebuild-progress':'quiescent component rebuild progress', 'restart-progress':'dirty restart progress'}
RESTART_NEGATIVES=('component-map','component-entry','selected-read','restart-progress')


def evaluate(log, code, bench="frozen"):
    rows = re.findall(r'M5_FRONTEND_OBSERVER ready_checks=(\d+) bank_checks=(\d+) commits=(\d+) stage_writes=(\d+) stale_events=(\d+) aborts=(\d+) sys_clocks=(\d+)', log)
    queues = re.findall(r'M5_FRONTEND_QUEUE depth=(\d+) clocks=(\d+) adds=(\d+) pops=(\d+)', log)
    fields = ('ready_checks','bank_checks','commits','stage_writes','stale_events','aborts','sys_clocks')
    obs = dict(zip(fields, map(int, rows[0]))) if len(rows)==1 else {}
    q = dict(zip(('depth','clocks','adds','pops'),map(int,queues[0]))) if len(queues)==1 else {}
    if bench=='restart':
        return evaluate_restart(log,code,obs,q)
    ok = bool(code==0 and ('GlobalRenderUartLoop_test passed' if bench=='frozen' else 'M5FrontendSupplemental_test passed') in log and 'M5_FRONTEND_FAILURE' not in log
              and obs.get('ready_checks',0)>=(2 if bench=='frozen' else 7) and obs.get('bank_checks',0)>0 and obs.get('commits')==(3 if bench=='frozen' else 2)
              and obs.get('stage_writes')==(5 if bench=='frozen' else 8) and obs.get('stale_events')==2 and obs.get('sys_clocks',0)>0
              and q.get('depth')==1152 and q.get('adds',0)>0 and q.get('pops',0)>0)
    progress_rows=re.findall(r'M5_FRONTEND_PROGRESS completed=(\d+) max_cycles=(\d+) bound=(\d+) selected_read_checks=(\d+)',log)
    progress=dict(zip(('completed','max_cycles','bound','selected_read_checks'),map(int,progress_rows[0]))) if len(progress_rows)==1 else {}
    ok=ok and progress.get('completed',0)>=1 and 0<progress.get('max_cycles',0)<=870 and progress.get('bound')==870
    supplemental={}
    if bench=='supplemental':
        rows=re.findall(r'M5_FRONTEND_SUPPLEMENTAL layouts=(\d+) abort_cases=(\d+)',log)
        supplemental=dict(zip(('layouts','abort_cases'),map(int,rows[0]))) if len(rows)==1 else {}
        layouts=re.findall(r'M5_SUPPLEMENTAL_LAYOUT ([a-z0-9-]+) count=(\d+)',log)
        wanted=[('empty','0'),('all-types-four-directions-corners','5'),('last-cell-horizontal-partner','1'),
                ('last-cell-vertical-partner','1'),('deleted-last-cell-component','0'),('last-cell-origin','1')]
        abort_cases=re.findall(r'M5_SUPPLEMENTAL_ABORT_CASE (\d+) status=([0-9a-fA-F]{2}) valid=([01])',log)
        ok=ok and supplemental=={'layouts':6,'abort_cases':5} and obs.get('aborts')==6 and layouts==wanted
        ok=ok and abort_cases==[('1','83','1'),('2','83','1'),('3','83','1'),('4','83','1'),('5','05','0')]
        ok=ok and progress.get('selected_read_checks',0)>=7 and progress.get('completed',0)>=6
    return {'ok':bool(ok),'exit':code,'observer':obs,'queue':q,'supplemental':supplemental,'progress':progress}


def evaluate_restart(log,code,obs,q):
    rows=re.findall(r'M5_FRONTEND_RESTART completed=(\d+) max_cycles=(\d+) bound=(\d+) edit_clocks=(\d+)',log)
    restart=dict(zip(('completed','max_cycles','bound','edit_clocks'),map(int,rows[0]))) if len(rows)==1 else {}
    rows=re.findall(r'M5_FRONTEND_RESTART_FIXTURE cases=(\d+) layouts=(\d+)',log)
    fixture=dict(zip(('cases','layouts'),map(int,rows[0]))) if len(rows)==1 else {}
    cases=re.findall(r'M5_SUPPLEMENTAL_RESTART_CASE ([a-z-]+) phase=(\d+) count=(\d+) cycles=(\d+)',log)
    wanted=[('during-clear','0','2'),('during-scan','1','2'),('pending-pair','2','2'),
            ('final-scan','3','2'),('registered-drain','4','2')]
    layouts=re.findall(r'M5_SUPPLEMENTAL_LAYOUT ([a-z-]+) count=(\d+)',log)
    ok=(code==0 and 'M5FrontendRestart_test passed' in log and 'M5_FRONTEND_FAILURE' not in log
        and fixture=={'cases':5,'layouts':7} and [r[:3] for r in cases]==wanted
        and all(0<int(r[3])<=1744 for r in cases)
        and layouts==[('restart-empty','0'),('restart-baseline','2')]+[(r[0],'2') for r in wanted]
        and restart.get('completed')==7 and restart.get('bound')==1744
        and 0<restart.get('max_cycles',0)<=1744 and restart.get('edit_clocks',0)>0
        and obs.get('ready_checks')==8 and obs.get('commits')==0 and obs.get('stage_writes')==0
        and obs.get('aborts')==0 and obs.get('sys_clocks',0)>0 and q.get('depth')==1152)
    return {'ok':bool(ok),'exit':code,'observer':obs,'queue':q,'restart':restart,'restart_fixture':fixture,
            'restart_cases':[{'label':r[0],'phase':int(r[1]),'count':int(r[2]),'cycles':int(r[3])} for r in cases]}


def evaluate_negative(log,code,kind):
    return bool(code!=0 and 'M5_FRONTEND_FAILURE '+NEGATIVES[kind] in log
                and 'GlobalRenderUartLoop_test passed' not in log and 'M5FrontendSupplemental_test passed' not in log and 'M5FrontendRestart_test passed' not in log)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime',choices=('native','docker'),required=True)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--bench',choices=('frozen','supplemental','restart'),default='frozen')
    parser.add_argument('--design-root',type=Path,default=REPO/'src/design',help='Explicit production or isolated candidate design directory')
    args=parser.parse_args(); out=args.out.resolve(); out.mkdir(parents=True,exist_ok=False)
    design=args.design_root.resolve()
    if not design.is_dir(): parser.error('--design-root must be an existing directory')
    sources=sorted(design.rglob('*Pkg.sv'))
    sources+=sorted(p for p in design.rglob('*') if p.suffix in ('.v','.sv') and not p.name.endswith('Pkg.sv') and 'floating_point' not in p.parts)
    sources += [REPO/'src/testbench/GlobalRenderUartLoop_test.sv',REPO/'src/testbench/M5FrontendInvariants.sv']
    top='GlobalRenderUartLoop_test' if args.bench=='frozen' else 'M5FrontendSupplemental_test'
    definitions=[]
    if args.bench!='frozen':
        sources.append(REPO/'src/testbench/M5FrontendSupplemental_test.sv')
        definitions=['-DM5D=M5FrontendSupplemental_test.dut']
    hashes={(str(p.relative_to(REPO)) if p.is_relative_to(REPO) else str(p)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}
    def path(p):
        if args.runtime=='native': return str(p)
        if p.is_relative_to(out): return '/out/'+str(p.relative_to(out))
        if p.is_relative_to(design): return '/design/'+str(p.relative_to(design))
        return '/source/'+str(p.relative_to(REPO))
    def run(cmd,label):
        if args.runtime=='docker':
            cmd=['docker','run','--rm','-v',f'{REPO}:/source:ro','-v',f'{out}:/out','-v',f'{design}:/design:ro','-w','/source',IMAGE]+cmd
        with (out/(label+'.log')).open('w') as log:
            try: return subprocess.run(cmd,cwd=REPO,stdout=log,stderr=subprocess.STDOUT,timeout=240).returncode
            except (OSError,subprocess.TimeoutExpired) as exc:
                log.write('\nM5_FRONTEND_RUNNER_FAILURE '+type(exc).__name__+'\n'); return 124
    version=run(['verilator','--version'],'tool')
    build=run(['verilator','--binary','--timing','--assert','-O2','--top-module',top,*definitions,
               '-Wno-fatal','-Wno-lint','-Wno-style','-Wno-MULTIDRIVEN','-j','4','--Mdir',path(out/'build'),*[path(p) for p in sources]],'build')
    result={'schema_version':1,'ok':False,'runtime':args.runtime,'bench':args.bench,'design_root':str(design),'tool_version':(out/'tool.log').read_text().strip(),
            'tool_exit':version,'build_exit':build,'source_hashes':hashes,
            'runner_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            'scope':'production full-top sysclock safety and exact component/index maps at advertised post-init !busy boundaries; atomic accepted voltage-bank metadata/data; local flood queue bounds/count',
            'assumptions':['frozen UART bench or explicitly selected supplemental real-UART/accepted-command fixtures; no real PS2 or CDC qualification',
                           'UART parser emits one semantic event per accepted line; reference acceptance model tracks distinct node indices',
                           'component entries reconstructed independently from enabled primary sprites, BCD/unit shadows and geometry',
                           'check genuine !component_store_busy boundary pre-NBA without hidden extra settle',
                           'restart deadline resets on every possible edit; completion required within1744clocks after edits quiesce'],
            'unsupported':['formal proof','global arbitrary progress/stalls','all-frame renderer safety','actual PS2/CDC',
                           'arbitrary overlapping events and duplicate node semantics unqualified']}
    if version==0 and build==0:
        binary=path(out/('build/V'+top))
        bench_args=['+m5-restart-only'] if args.bench=='restart' else []
        code=run([binary,*bench_args],'normal'); normal=evaluate((out/'normal.log').read_text(),code,args.bench)
        controls={}
        for kind in (RESTART_NEGATIVES if args.bench=='restart' else [k for k in NEGATIVES if k!='restart-progress']):
            code=run([binary,*bench_args,'+m5-inject-'+kind,*(['+m5-abort-only'] if args.bench=='supplemental' and kind=='stage-state' else [])],'negative-'+kind)
            log=(out/('negative-'+kind+'.log')).read_text()
            controls[kind]={'exit':code,'detected':evaluate_negative(log,code,kind)}
        result.update(normal=normal,negative_controls=controls)
        result['ok']=normal['ok'] and all(c['detected'] for c in controls.values())
    result['sources_unchanged_during_run']=all(hashlib.sha256((REPO/p).read_bytes()).hexdigest()==h for p,h in hashes.items())
    result['ok']=result['ok'] and result['sources_unchanged_during_run']
    (out/'summary.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({'ok':result['ok'],'summary':str(out/'summary.json')}));return 0 if result['ok'] else 1


if __name__=='__main__': raise SystemExit(main())
