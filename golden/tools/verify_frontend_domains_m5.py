#!/usr/bin/env python3
"""Finite capacity, keypad values/units, selection and clear backpressure fixtures."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

REPO=Path(__file__).resolve().parents[2]
IMAGE='framescope-toolchain:6501155dc903'
NEGATIVES={'component-map':'M5_FRONTEND_FAILURE component index map',
           'component-entry':'M5_FRONTEND_FAILURE component store entry',
           'selected-read':'M5_FRONTEND_FAILURE selected index synchronous read',
           'restart-progress':'M5_FRONTEND_FAILURE dirty restart progress',
           'keyboard-value':'M5_DOMAINS_FAILURE keyboard literal value',
           'keyboard-unit':'M5_DOMAINS_FAILURE keyboard literal unit',
           'domain-selection':'M5_DOMAINS_FAILURE selection literal map read'}
LAYOUTS=[('empty','0'),('capacity-144','144'),('resistor-three-digits-M','144'),
         ('two-digits-k','144'),('two-digits-m','144'),('two-digits-u','144'),
         ('two-digits-n','144'),('resistor-two-digits-p','144'),('no-unit','144'),
         ('text-only-extra-digit','144'),('clear-keyboard','144'),('scan-keyboard','144'),
         ('pair-keyboard','144'),('drain-keyboard','144'),('clear-backpressure','0')]
VALUES=[('resistor-three-digits-M','0','1','123','1'),('two-digits-k','2','20','045','2'),
        ('two-digits-m','3','21','067','3'),('two-digits-u','5','4','089','4'),
        ('two-digits-n','8','9','012','5'),('resistor-two-digits-p','10','28','340','6'),
        ('no-unit','11','29','990','0'),('text-only-extra-digit','0','1','123','6')]
SELECTIONS=[('origin','0','1'),('partner','1','1'),('last-origin','287','1'),
            ('last-partner','269','1'),('disabled','0','0'),('reenabled','2','1'),
            ('empty-selected','287','1'),('empty-disabled','287','0')]
PHASES=[('clear-keyboard','0'),('scan-keyboard','1'),('pair-keyboard','2'),('drain-keyboard','3')]

def one(log,pattern,fields):
    rows=re.findall(pattern,log)
    return dict(zip(fields,map(int,rows[0]))) if len(rows)==1 else {}

def evaluate(log,code):
    domain=one(log,r'M5_FRONTEND_DOMAINS layouts=(\d+) keyboard_events=(\d+) selections=(\d+) phases=(\d+) blocked_clocks=(\d+) capacity=(\d+)',
               ('layouts','keyboard_events','selections','phases','blocked_clocks','capacity'))
    obs=one(log,r'M5_FRONTEND_OBSERVER ready_checks=(\d+) bank_checks=(\d+) commits=(\d+) stage_writes=(\d+) stale_events=(\d+) aborts=(\d+) sys_clocks=(\d+)',
            ('ready_checks','bank_checks','commits','stage_writes','stale_events','aborts','sys_clocks'))
    progress=one(log,r'M5_FRONTEND_PROGRESS completed=(\d+) max_cycles=(\d+) bound=(\d+) selected_read_checks=(\d+)',
                 ('completed','max_cycles','bound','selected_read_checks'))
    restart=one(log,r'M5_FRONTEND_RESTART completed=(\d+) max_cycles=(\d+) bound=(\d+) edit_clocks=(\d+)',
                ('completed','max_cycles','bound','edit_clocks'))
    queue=one(log,r'M5_FRONTEND_QUEUE depth=(\d+) clocks=(\d+) adds=(\d+) pops=(\d+)',('depth','clocks','adds','pops'))
    layouts=re.findall(r'M5_DOMAINS_LAYOUT ([a-zA-Z0-9-]+) count=(\d+)',log)
    values=re.findall(r'M5_DOMAINS_VALUE ([a-zA-Z0-9-]+) origin=(\d+) partner=(\d+) bcd=([0-9a-f]{3}) unit=(\d+)',log)
    selections=re.findall(r'M5_DOMAINS_SELECTION ([a-zA-Z0-9-]+) addr=(\d+) enabled=([01])',log)
    phases=re.findall(r'M5_DOMAINS_PHASE ([a-z-]+) phase=(\d+)',log)
    ok=(code==0 and 'M5FrontendDomains_test passed' in log and 'M5_DOMAINS_FAILURE' not in log and 'M5_FRONTEND_FAILURE' not in log
        and domain==dict(layouts=15,keyboard_events=41,selections=8,phases=4,blocked_clocks=20,capacity=144)
        and layouts==LAYOUTS and values==VALUES and selections==SELECTIONS and phases==PHASES
        and obs.get('ready_checks',0)>=16 and obs.get('sys_clocks',0)>0
        and all(obs.get(k)==0 for k in ('bank_checks','commits','stage_writes','stale_events','aborts'))
        and progress.get('completed',0)>=1 and progress.get('bound')==870 and 0<progress.get('max_cycles',0)<=870
        and progress.get('selected_read_checks',0)>0
        and restart.get('completed',0)>=15 and restart.get('bound')==1744 and 0<restart.get('max_cycles',0)<=1744 and restart.get('edit_clocks',0)>0
        and queue.get('depth')==1152 and queue.get('clocks',0)>0 and queue.get('adds')==0 and queue.get('pops')==0)
    return {'ok':bool(ok),'exit':code,'domain':domain,'observer':obs,'progress':progress,'restart':restart,'queue':queue,
            'layouts':layouts,'values':values,'selections':selections,'phases':phases}

def evaluate_negative(log,code,kind):
    return code!=0 and NEGATIVES[kind] in log and 'M5FrontendDomains_test passed' not in log

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime',choices=('native','docker'),required=True)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--design-root',type=Path,default=REPO/'src/design')
    args=parser.parse_args();design=args.design_root.resolve()
    if not design.is_dir():parser.error('--design-root must exist')
    out=args.out.resolve();out.mkdir(parents=True,exist_ok=False)
    sources=sorted(design.rglob('*Pkg.sv'))
    sources+=sorted(p for p in design.rglob('*') if p.suffix in ('.v','.sv') and not p.name.endswith('Pkg.sv') and 'floating_point' not in p.parts)
    sources += [REPO/'src/testbench/GlobalRenderUartLoop_test.sv',REPO/'src/testbench/M5FrontendInvariants.sv',REPO/'src/testbench/M5FrontendDomains_test.sv']
    hashes={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}
    def path(p):
        if args.runtime=='native':return str(p)
        if p.is_relative_to(out):return '/out/'+str(p.relative_to(out))
        if p.is_relative_to(design):return '/design/'+str(p.relative_to(design))
        return '/source/'+str(p.relative_to(REPO))
    def run(cmd,label):
        if args.runtime=='docker':cmd=['docker','run','--rm','-v',f'{REPO}:/source:ro','-v',f'{out}:/out','-v',f'{design}:/design:ro','-w','/source',IMAGE]+cmd
        with (out/(label+'.log')).open('w') as log:
            try:return subprocess.run(cmd,cwd=REPO,stdout=log,stderr=subprocess.STDOUT,timeout=240).returncode
            except (OSError,subprocess.TimeoutExpired) as exc:log.write('\nM5_DOMAINS_RUNNER_FAILURE '+type(exc).__name__+'\n');return 124
    version=run(['verilator','--version'],'tool')
    top='M5FrontendDomains_test'
    build=run(['verilator','--binary','--timing','--assert','-O2','--top-module',top,'-DM5D=M5FrontendDomains_test.dut',
               '-Wno-fatal','-Wno-lint','-Wno-style','-Wno-MULTIDRIVEN','-j','4','--Mdir',path(out/'build'),*[path(p) for p in sources]],'build')
    result={'schema_version':1,'ok':False,'runtime':args.runtime,'bench':'domains','design_root':str(design),
            'tool_version':(out/'tool.log').read_text().strip(),'tool_exit':version,'build_exit':build,'source_hashes':hashes,
            'runner_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            'scope':'finite full-top capacity144; literal keyboard value/unit and paired writes; selected property transitions; keyboard stimulus during named rebuild phases;20clear backpressure clocks',
            'assumptions':['background commands bypass mouse/controller/guard; exact accepted commands required and higher-priority writers excluded',
                           'selection coordinates/enable and value-edit enable enter pixel-side UI registers with real system synchronizers; keypad pulse enters real pixel-side key input with real toggle synchronizer',
                           'all maps, packed entries, values and units checked from literal fixture words at first advertised ready',
                           'capacity144 means disjoint two-cell components on288cells; no malformed/overlapping geometry'],
            'unsupported':['formal/global arbitrary progress','arbitrary external stalls','physical PS2/CDC or all-frame renderer safety',
                           'no UART replies or flood queue traffic in this separate fixture']}
    if version==0 and build==0:
        binary=path(out/('build/V'+top));code=run([binary],'normal');normal=evaluate((out/'normal.log').read_text(),code)
        controls={}
        for kind in NEGATIVES:
            code=run([binary,'+m5-inject-'+kind],'negative-'+kind)
            controls[kind]={'exit':code,'detected':evaluate_negative((out/('negative-'+kind+'.log')).read_text(),code,kind)}
        result.update(normal=normal,negative_controls=controls)
        result['ok']=normal['ok'] and all(c['detected'] for c in controls.values())
    result['sources_unchanged_during_run']=all(hashlib.sha256(Path(p).read_bytes()).hexdigest()==h for p,h in hashes.items())
    result['ok']=result['ok'] and result['sources_unchanged_during_run']
    (out/'summary.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({'ok':result['ok'],'summary':str(out/'summary.json')}));return 0 if result['ok'] else 1

if __name__=='__main__':raise SystemExit(main())
