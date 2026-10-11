#!/usr/bin/env python3
"""Qualify production frontend↔SolverBoard/default-baud UART with actual rev21 FP."""
import argparse
import json
import re
import shutil
from pathlib import Path
from verify_solver_m5 import ROOT, command, sha256
from verify_fp_m5 import VIVADO, configuration_audit


def actual_frontend_sources():
    design = ROOT / 'src/design'
    packages = sorted(design.rglob('*Pkg.sv'))
    other = sorted(p for p in design.rglob('*') if p.suffix in ('.v', '.sv') and not p.name.endswith('Pkg.sv')
                   and p.name not in ('Oled_Display.v', 'fpo_tofixed.v', 'bmatrixStore.v', 'matrixStore.v', 'LUdecomp.v', 'lu_core.sv'))
    return packages + other + [ROOT / 'src/testbench/M5SolverFrontendXsim.sv']


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', required=True, type=Path)
    parser.add_argument('--timeout', type=int, default=900)
    parser.add_argument('--fp-report', type=Path, default=ROOT / 'golden/out/m5-fp/characterization-final-20261010/report.json')
    args = parser.parse_args()
    out = args.out.resolve(); out.mkdir(parents=True, exist_ok=True)
    audit = {n: configuration_audit(n) for n in ('fma', 'div')}
    fp = json.loads(args.fp_report.read_text())
    fp_drift = [p for p, digest in fp.get('source_tool_library_sha256', {}).items()
                if not Path(p).is_file() or sha256(p) != digest]
    fp_valid = fp.get('characterization_passed') is True and all(fp.get('negative_controls', {}).values()) and not fp_drift
    sources = actual_frontend_sources()
    rom = ROOT / 'src/design/solver_board/bcd_unit_to_fp32_rom.mem'
    shutil.copyfile(rom, out / rom.name)
    tracked = sources + [rom, Path(__file__)]
    pins = {str(p): sha256(p) for p in tracked}
    report = {'schema':'metacircuit.m5-solver-frontend-xsim.v1', 'configuration_audit':audit,
              'source_sha256':pins, 'fp_characterization':{'path':str(args.fp_report.resolve()),
               'sha256':sha256(args.fp_report), 'valid':fp_valid, 'source_drift':fp_drift},
              'uart_baud':115200, 'mouse_output_injection':True, 'excluded_unelaborated_sources':{'Oled_Display.v':'GlobalRender_top ENABLE_OLED_CALC is constant0', 'fpo_tofixed.v':'not instantiated in frontend or SolverBoard', 'bmatrixStore.v/matrixStore.v/LUdecomp.v/lu_core.sv':'unused historical matrix modules; production pipeline instantiates solve_core_dc'}, 'operations':{}}
    commands = [('vhdl', [str(VIVADO/'bin/xvhdl'),'--work','xil_defaultlib',*[a['product'] for a in audit.values()]]),
        ('sv',[str(VIVADO/'bin/xvlog'),'--sv','--work','xil_defaultlib',*map(str,sources)]),
        ('elaborate',[str(VIVADO/'bin/xelab'),'xil_defaultlib.M5SolverFrontendXsim','-s','m5frontend',
                      '-L','floating_point_v7_1_21','--timescale','1ns/1ps','-mt','4']),
        ('run',[str(VIVADO/'bin/xsim'),'m5frontend','-runall']),
        ('negative_data',[str(VIVADO/'bin/xsim'),'m5frontend','-runall','-testplusarg','CORRUPT_FRONTEND'])]
    if fp_valid and all(a['configuration_matches'] for a in audit.values()):
        for name, cmd in commands:
            item=command(cmd,out,out/(name+'.log'),args.timeout); report['operations'][name]=item
            print(name,item['returncode'],flush=True)
            if item['returncode']!=0 or re.search(r'^ERROR:',(out/(name+'.log')).read_text(),re.M): break
    positive=(out/'run.log').read_text() if (out/'run.log').exists() else ''
    negative=(out/'negative_data.log').read_text() if (out/'negative_data.log').exists() else ''
    report['accepted_events']=re.findall(r'^FRONTEND .+$',positive,re.M)
    report['state_events']=re.findall(r'^FRONTEND_STATE .+$',positive,re.M)
    report['stimulus_events']=re.findall(r'^FRONTEND_STIMULUS .+$',positive,re.M)
    report['actual_fp_events']=re.findall(r'^ACTUAL_FP .+$',positive,re.M)
    report['negative_data_detected']='Fatal:' in negative and 'frontend boot voltage mismatch' in negative and 'M5SolverFrontendXsim passed.' not in negative
    report['source_drift']=[p for p,digest in pins.items() if sha256(p)!=digest]
    report['scoped_actual_frontend_passed']=('M5SolverFrontendXsim passed.' in positive and report['negative_data_detected']
                                           and fp_valid and not report['source_drift'])
    report['acceptance']={'full_m5_ready':False,'original_xci_synthesis_qualified':False,
       'scope':'actual production default115200 UART boot/duplicate/split-rail frontend loop with rev21 configured FP',
       'blockers':['revision21products vs originalXCIrevision6 mismatch remains',
                   'physical PS/2/board transport and full general frontend extraction/capacity remain unqualified']}
    report['artifact_sha256']={p.name:sha256(p) for p in out.glob('*.log')}
    (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({'passed':report['scoped_actual_frontend_passed'],'report':str(out/'report.json')}))
    return 0 if report['scoped_actual_frontend_passed'] else 1


if __name__=='__main__': raise SystemExit(main())
