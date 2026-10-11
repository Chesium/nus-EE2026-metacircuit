#!/usr/bin/env python3
"""Cold actual-IP probe for declared32nodes plus one ideal-source auxiliary row."""
import argparse
import json
import re
import shutil
from pathlib import Path
from verify_solver_m5 import ROOT, command, packet, sha256
from verify_solver_xsim_m5 import actual_sources
from verify_fp_m5 import VIVADO, configuration_audit


def capacity_packets():
    frame = 'FF40'
    tx = [packet(f'NB,{frame},20,20'), packet(f'NC,{frame},00,03,00,FF,010,00')]
    tx += [packet(f'NC,{frame},{j+1:02X},01,{j:02X},{j+1:02X},001,00') for j in range(31)]
    tx += [packet(f'NE,{frame},20,20')]
    return tx


def capacity_include(tx):
    """Listen before any NC can trigger a capacity error; finish the entire TX."""
    sends = '\n'.join(f'    send_uart_line("{line}");' for line in tx)
    return 'fork\n  begin\n' + sends + '\n  end\n  begin\n    expect_capacity();\n  end\njoin\nif(solvestart!=-1) $fatal(1,"capacity rejection must precede solve");\n'


def capacity_sources(bench, solver_top=None):
    sources = actual_sources()[:-1] + [Path(bench)]
    if solver_top is not None:
        sources = [Path(solver_top).resolve() if p.name == 'SolverBoard_top.sv' else p for p in sources]
    return sources


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out',type=Path,required=True)
    parser.add_argument('--timeout',type=int,default=180)
    parser.add_argument('--solver-top',type=Path,help='explicit isolated SolverBoard_top capacity candidate; production unchanged and both identities pinned')
    parser.add_argument('--fp-report',type=Path,default=ROOT/'golden/out/m5-fp/characterization-final-20261010/report.json')
    args=parser.parse_args(); out=args.out.resolve(); out.mkdir(parents=True,exist_ok=True)
    tx=capacity_packets(); (out/'fixtures.json').write_text(json.dumps({'tx':tx,'node_count':32,'elements':32,'voltage_sources':1,'augmented_dimension':33,'expected_capacity_status':3,'expected_capacity_argument':33},indent=2)+'\n')
    template=ROOT/'src/testbench/M5SolverUartXsim.sv'
    bench=out/'M5SolverCapacityXsim.sv'
    text=template.read_text().replace('M5SolverUartXsim','M5SolverCapacityXsim')
    task='''  task automatic expect_capacity;
    integer k,scanned; reg [7:0] checksum,received; reg [15:0] argument;
    begin
      recv_uart_line(rx_line);
      $display("CAPACITY_REPLY %s",rx_line);
      if(rx_line.len()!=19 || rx_line.substr(0,11)!="@ER,FF40,03,")
        $fatal(1,"augmented capacity mismatch expected STATUS_CAPACITY03 error got %s",rx_line);
      checksum=0;
      for(k=1;k<16;k++) checksum=checksum^rx_line[k];
      scanned=$sscanf(rx_line.substr(17,18),"%h",received);
      if(scanned!=1 || rx_line[16]!="*" || received!=checksum)
        $fatal(1,"augmented capacity checksum mismatch got %s",rx_line);
      scanned=$sscanf(rx_line.substr(12,15),"%h",argument);
      if(scanned!=1 || argument!=16'h0021)
        $fatal(1,"augmented capacity argument mismatch expected0021 got %s",rx_line);
      // Require a valid baseline observation before injecting the control.
      $display("CAPACITY_BASELINE_VALID");
      if($test$plusargs("CORRUPT_CAPACITY")) begin
        rx_line={rx_line,"X"};
        $display("CORRUPT_CAPACITY_CONTROL applied");
      end
      if(rx_line!="EXPECTED_CAPACITY_LINE")
        $fatal(1,"capacity observation mismatch expected EXPECTED_CAPACITY_LINE got %s",rx_line);
    end
  endtask
'''.replace('EXPECTED_CAPACITY_LINE',packet('ER,FF40,03,0021'))
    text=text.replace('  initial begin\n    if(!numeric_policy',task+'  initial begin\n    if(!numeric_policy')
    bench.write_text(text)
    (out/'M5SolverUartFixtures.svh').write_text(capacity_include(tx))
    sources=capacity_sources(bench,args.solver_top)
    original_top=ROOT/'src/design/solver_board/SolverBoard_top.sv'
    overrides={}
    if args.solver_top is not None:
        overrides[str(original_top)]={'original':str(original_top),'effective':str(args.solver_top.resolve()),
                                     'original_sha256':sha256(original_top),'effective_sha256':sha256(args.solver_top),
                                     'basis':'root-authorized isolated capacity guard candidate; not production or frozen oracle'}
    audit={n:configuration_audit(n) for n in ('fma','div')}
    fp=json.loads(args.fp_report.read_text())
    drift=[p for p,digest in fp['source_tool_library_sha256'].items() if not Path(p).is_file() or sha256(p)!=digest]
    valid=fp.get('characterization_passed') is True and all(fp.get('negative_controls',{}).values()) and not drift
    rom=ROOT/'src/design/solver_board/bcd_unit_to_fp32_rom.mem'; shutil.copyfile(rom,out/rom.name)
    pins={str(p):sha256(p) for p in sources+[original_top,template,rom,Path(__file__),out/'fixtures.json',out/'M5SolverUartFixtures.svh']}
    report={'schema':'metacircuit.m5-capacity-xsim.v1','configuration_audit':audit,'source_sha256':pins,
            'fp_characterization':{'path':str(args.fp_report.resolve()),'sha256':sha256(args.fp_report),'valid':valid,'source_drift':drift},
            'expected_policy':'STATUS_CAPACITY03 rejection with augmented dimension0033decimal/0021hex argument, root-authorized capacity decision inferred from declared status; not frozen frontend contract',
            'source_overrides':overrides,
            'effective_bench':str(bench),'original_template':str(template),'operations':{}}
    cmds=[('vhdl',[str(VIVADO/'bin/xvhdl'),'--work','xil_defaultlib',*[a['product'] for a in audit.values()]]),
          ('sv',[str(VIVADO/'bin/xvlog'),'--sv','--work','xil_defaultlib','-i',str(out),*map(str,sources)]),
          ('elaborate',[str(VIVADO/'bin/xelab'),'xil_defaultlib.M5SolverCapacityXsim','-s','m5capacity','-L','floating_point_v7_1_21','--timescale','1ns/1ps','-mt','4']),
          ('run',[str(VIVADO/'bin/xsim'),'m5capacity','-runall']),
          ('negative_data',[str(VIVADO/'bin/xsim'),'m5capacity','-runall','-testplusarg','CORRUPT_CAPACITY'])]
    if valid and all(a['configuration_matches'] for a in audit.values()):
        for name,cmd in cmds:
            item=command(cmd,out,out/(name+'.log'),args.timeout); report['operations'][name]=item
            print(name,item['returncode'],flush=True)
            if item['returncode']!=0 or re.search(r'^ERROR:',(out/(name+'.log')).read_text(),re.M): break
            if name=='run' and 'M5SolverCapacityXsim passed.' not in (out/'run.log').read_text(): break
    run=(out/'run.log').read_text() if (out/'run.log').exists() else ''
    report['observed_reply']=re.findall(r'^CAPACITY_REPLY (.+)$',run,re.M)
    report['observed_solves']=re.findall(r'^ACTUAL_SOLVE .+$',run,re.M)
    report['source_drift']=[p for p,digest in pins.items() if sha256(p)!=digest]
    negative=(out/'negative_data.log').read_text() if (out/'negative_data.log').exists() else ''
    report['negative_data_detected']=('Fatal:' in negative and 'CAPACITY_BASELINE_VALID' in negative and
                                     'CORRUPT_CAPACITY_CONTROL applied' in negative and 'capacity observation mismatch' in negative and
                                     'M5SolverCapacityXsim passed.' not in negative)
    report['receive_policy']='concurrent receive starts before snapshot transmission; exact length/prefix, XOR checksum and augmented-dimension argument0021 required; rejection precedes solve'
    report['capacity_rejection_passed']='M5SolverCapacityXsim passed.' in run and not report['source_drift'] and valid and report['negative_data_detected']
    report['capacity_mismatch_detected']='Fatal:' in run and 'augmented capacity mismatch' in run
    report['full_m5_ready']=False; report['original_xci_synthesis_qualified']=False
    report['artifact_sha256']={p.name:sha256(p) for p in out.glob('*.log')}
    (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({'capacity_rejection_passed':report['capacity_rejection_passed'],'mismatch':report['capacity_mismatch_detected'],'reply':report['observed_reply']}))
    return 0 if report['capacity_rejection_passed'] else 1


if __name__=='__main__':raise SystemExit(main())
