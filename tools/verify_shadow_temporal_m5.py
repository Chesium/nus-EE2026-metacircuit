#!/usr/bin/env python3
"""Compile projected actual-source shadow write chains and exercise NBA reads."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
from verify_shadow_ports_m5 import ARRAYS, Statements, audit

INPUTS = {'clear_canvas_active':1,'init_cycles':10,'pending_pair_value_write':1,
          'keyboard_edit_event':1,'edit_value_valid':1,'interaction_bg_cmd_valid':1,
          'interaction_bg_cmd_ready':1,'interaction_bg_cmd_write':1,'interaction_copy_value':1,
          'clear_canvas_addr':9,'pending_pair_value_addr':9,'selected_cell_addr_sys':9,
          'interaction_bg_cmd_addr':9,'interaction_value_read_addr':9,
          'interaction_bg_cmd_wdata':16,'pending_pair_value_data':12,'edit_value_next_bcd':12,
          'pending_pair_value_text':64,'edit_value_next_text':64,
          'pending_pair_value_text_len':4,'edit_value_next_text_len':4,'observe_addr':9}


def relevant(leaf):
    return any(re.search(r'\b'+name+r'(?:\[|_w[ead]\s*=)',leaf) for name,_ in ARRAYS)


def project(tree):
    if tree[0]=='leaf': return tree[1] if relevant(tree[1]) else ''
    if tree[0]=='block': return '\n'.join(filter(None,(project(c) for c in tree[1])))
    yes,no=project(tree[2]),project(tree[3])
    if not yes and not no: return ''
    return 'if '+tree[1]+' begin\n'+yes+'\nend else begin\n'+no+'\nend'


def module(source,name,candidate):
    start=source.rindex('        if (clear_canvas_active) begin')
    end=source.index('        if (component_index_map_pending_pair_write) begin',start)
    parser=Statements(source[start:end])
    body=project(parser.statement())
    ports=['input wire clk']+[f'input wire [{w-1}:0] {n}' for n,w in INPUTS.items()]
    ports += ['output reg [31:0] synchronous_old_read', 'output reg [15:0] interaction_bg_rsp_rdata=0']
    decls=['localparam CANVAS_CELL_COUNT=288, CANVAS_ADDR_W=9;']
    decls += re.findall(r'localparam \[3:0\] COMPONENT_UNIT_\w+\s*=\s*[^;]+;',source)
    for fn in ['text_char_at8','component_unit_code_from_ascii','component_unit_code_from_text']:
        decls += [re.search(r'    function[^\n]*\b'+fn+r';.*?    endfunction',source,re.S)[0]]
    decls += [f'reg [{w-1}:0] {n} [0:287];' for n,w in ARRAYS]
    # Equal arbitrary nonzero initial state: regression premise, not hardware initialization.
    decls += ['integer k; initial begin for(k=0;k<288;k=k+1) begin',
              'canvas_shadow_data[k]=k*157+3; value_shadow_data[k]=k*19+5;',
              'value_unit_shadow_data[k]=k%16; end end']
    defaults=''
    writes=''
    if candidate:
        for n,w in ARRAYS:
            decls += [f'reg {n}_we; reg [8:0] {n}_wa; reg [{w-1}:0] {n}_wd;']
            # Copy canonical actual-source default and final indexed NBA.
            for suffix in ['we','wa','wd']:
                defaults += re.search(r'        '+n+'_'+suffix+r' = [^;]+;',source)[0]+'\n'
            writes += re.search(r'        if \('+n+'_we'+r'\)\s*'+n+r'\['+n+r'_wa\] <= '+n+r'_wd;',source)[0]+'\n'
    old='synchronous_old_read <= {canvas_shadow_data[observe_addr], value_shadow_data[observe_addr], value_unit_shadow_data[observe_addr]};'
    return f'module {name}('+',\n'.join(ports)+');\n'+'\n'.join(decls)+'\nalways @(posedge clk) begin\n'+defaults+body+'\n'+writes+old+'\nend\nendmodule\n'


def bench(negative_control=False):
    declarations='\n'.join(f'reg [{w-1}:0] {n}=0;' for n,w in INPUTS.items())
    hookups=', '.join('.'+n+'('+n+')' for n in INPUTS)
    randoms='\n'.join(n+' = $urandom;' if w<=32 else n+' = {$urandom,$urandom};' for n,w in INPUTS.items())
    corruption = "if(step==1024) dut_inst.value_shadow_data[287] = dut_inst.value_shadow_data[287] ^ 12'd1;" if negative_control else ''
    return '''module ShadowTemporal;
reg clk=0; reg [31:0] expected; wire [31:0] ref_read,dut_read; wire [15:0] ref_rsp,dut_rsp;
'''+declarations+f'''
ShadowReference ref_inst(.clk(clk), {hookups}, .synchronous_old_read(ref_read), .interaction_bg_rsp_rdata(ref_rsp));
ShadowCandidate dut_inst(.clk(clk), {hookups}, .synchronous_old_read(dut_read), .interaction_bg_rsp_rdata(dut_rsp));
integer step,cell_idx;
initial begin
for(step=0;step<16384;step=step+1) begin
'''+randoms+'''
// Visit every init value and every 9-bit address, including invalid 288..511.
init_cycles=step%1024;
observe_addr=step%512;
clear_canvas_addr=step%512;
interaction_bg_cmd_addr=step%512;
if(step<1024) begin
clear_canvas_active=0; pending_pair_value_write=0; keyboard_edit_event=0;
interaction_bg_cmd_valid=0;
end
// Force read-during-write collisions across control paths.
if(step>=1024 && step%3==0) observe_addr=interaction_bg_cmd_addr;
#1;
expected={ref_inst.canvas_shadow_data[observe_addr],ref_inst.value_shadow_data[observe_addr],ref_inst.value_unit_shadow_data[observe_addr]};
clk=1; #1;
'''+corruption+'''
if(ref_read!==dut_read || ref_read!==expected || ref_rsp!==dut_rsp) $fatal(1,"SHADOW_TEMPORAL_FAILURE old_read step=%0d",step);
for(cell_idx=0;cell_idx<288;cell_idx=cell_idx+1) begin
if(ref_inst.canvas_shadow_data[cell_idx]!==dut_inst.canvas_shadow_data[cell_idx] ||
   ref_inst.value_shadow_data[cell_idx]!==dut_inst.value_shadow_data[cell_idx] ||
   ref_inst.value_unit_shadow_data[cell_idx]!==dut_inst.value_unit_shadow_data[cell_idx])
$fatal(1,"SHADOW_TEMPORAL_FAILURE array step=%0d cell=%0d",step,cell_idx);
end
clk=0; #1;
end
$display("SHADOW_TEMPORAL_PASS edges=16384 cells_per_edge=288 address_domain=512"); $finish;
end
endmodule
'''


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--reference',type=Path,required=True);p.add_argument('--candidate',type=Path,required=True)
    p.add_argument('--out',type=Path,required=True);p.add_argument('--verilator',default='verilator')
    p.add_argument('--negative-control',action='store_true')
    args=p.parse_args();args.out=args.out.resolve();args.out.mkdir(parents=True,exist_ok=True)
    reference,candidate=args.reference.read_text(),args.candidate.read_text()
    proof=audit(reference,candidate)
    source=module(reference,'ShadowReference',False)+module(candidate,'ShadowCandidate',True)+bench(args.negative_control)
    sv=args.out/'ShadowTemporal.sv';sv.write_text(source)
    command=[args.verilator,'--binary','--timing','-Wno-fatal','--top-module','ShadowTemporal','--Mdir',str(args.out/'obj'),'-j','4',str(sv)]
    build=subprocess.run(command,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (args.out/'build.log').write_text(build.stdout)
    run=None
    if build.returncode==0:
        run=subprocess.run([str(args.out/'obj/VShadowTemporal')],text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        (args.out/'run.log').write_text(run.stdout)
    passing=bool(run and run.returncode==0 and 'SHADOW_TEMPORAL_PASS' in run.stdout)
    if args.negative_control:
        passing=bool(run and run.returncode!=0 and 'SHADOW_TEMPORAL_FAILURE array step=1024 cell=287' in run.stdout)
    source_stable=(args.reference.read_text()==reference and args.candidate.read_text()==candidate)
    version=subprocess.run([args.verilator,'--version'],text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    report={'ok':passing and source_stable,'negative_control':args.negative_control,
            'source_stable':source_stable,'verilator_version':version.stdout.strip(),
            'build_exit':build.returncode,'run_exit':run.returncode if run else None,
            'command':command,'reference_sha256':proof['reference_sha256'],'candidate_sha256':proof['candidate_sha256'],
            'bench_sha256':hashlib.sha256(sv.read_bytes()).hexdigest(),
            'runner_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            'scope':'Projected actual-source write/control chains, all array cells per edge, NBA old read; supplements structural proof, not full design regression.'}
    (args.out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
    return 0 if report['ok'] else 1
if __name__=='__main__': raise SystemExit(main())
