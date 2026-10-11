#!/usr/bin/env python3
"""Actual reply parser output exclusivity and configured node bounds."""
import sys,pathlib;sys.path.insert(0,str(pathlib.Path(__file__).resolve().parent));from m5_tools import yosys
from pathlib import Path
import argparse,datetime,hashlib,json,re,subprocess
from formal_witness_m5 import cover
P=argparse.ArgumentParser(description=__doc__)
P.add_argument('--source',type=Path,default=Path(__file__).resolve().parents[1]/'src/design/uart/FrontendVoltagePacketParser.sv')
P.add_argument('--out',type=Path,required=True)
P.add_argument('--yosys',default=yosys())
A=P.parse_args();O=A.out.resolve();O.mkdir(parents=True,exist_ok=False);S=A.source.resolve();source=S.read_text();Y=A.yosys;sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert re.search(r'MAX_LINE_BYTES\s*=\s*48\b',source) and re.search(r'MAX_NODES\s*=\s*32\b',source)
version=subprocess.check_output([Y,'-V'],text=True).strip();assert version.startswith('Yosys 0.33 ')
# Only helper return values are cut; their independently arbitrary values
# overapproximate the real pure functions. Actual procedural dispatch/range
# checks, nonblocking outputs and reset remain unchanged.
start=source.index('    reg [7:0] checksum_actual;')
body=source[start:source.rindex('endmodule')]
header=source[:source.index('    function automatic [7:0] byte_at;')]
task=re.findall(r'    task automatic raise_error;.*?    endtask',source,re.S);assert len(task)==1
cuts=[]
widths={'byte_at':8,'valid_field_hex':1,'compute_checksum':8,'parse_hex2':8,'parse_hex4':16,'parse_hex8':32}
pattern=r'\b('+'|'.join(widths)+r')\(([^()]*)\)'
def cut(m):
 name='helper_cut_'+str(len(cuts));width=widths[m.group(1)];cuts.append({'wire':name,'width':width,'original_call':m.group(0)})
 return name
body=re.sub(pattern,cut,body)
cut_declarations='\n'.join('  (* anyseq *) reg ['+str(c['width']-1)+':0] '+c['wire']+';' for c in cuts)
abstract_source=header+task[0]+'\n'+cut_declarations+'\n'+body+'\nendmodule\n'
(O/'helper-cuts.json').write_text(json.dumps(cuts,indent=2)+'\n')
observer='''
wire [2:0] event_count = {2'd0,voltage_begin_valid}+{2'd0,voltage_node_valid}+{2'd0,voltage_end_valid}+{2'd0,error_packet_valid}+{2'd0,parse_error};
always @(posedge clk) begin
 assert(event_count <= 1);
 if (voltage_begin_valid) assert(voltage_begin_node_count <= MAX_NODES);
 if (voltage_end_valid) assert(voltage_end_node_count <= MAX_NODES);
 if (voltage_node_valid) assert(voltage_node_idx < MAX_NODES);
end
'''
assert source.count('endmodule')==1;rows=[]
for negative in [False,True]:
 D=O/('negative-multiple-events' if negative else 'normal');D.mkdir();s=abstract_source
 if negative:
  anchor="            voltage_node_valid <= 1'b0;";assert s.count(anchor)==2
  # Change the normal-cycle default, retaining the actual reset default.
  idx=s.rindex(anchor);s=s[:idx]+s[idx:].replace(anchor,"            voltage_node_valid <= 1'b1;",1)
 generated=D/'source.sv';generated.write_text(s.replace('endmodule',observer+'\nendmodule'))
 script=D/'proof.ys';script.write_text(f'read_verilog -formal -sv {generated}\nhierarchy -top FrontendVoltagePacketParser\nproc\nflatten\nopt\nsat -seq 3 -tempinduct -maxsteps 8 -prove-asserts -verify -dump_vcd {D/"counterexample.vcd"}\n')
 with (D/'proof.log').open('w') as log:
  try:rc=subprocess.run([Y,'-Q','-s',str(script)],stdout=log,stderr=subprocess.STDOUT,timeout=120).returncode
  except subprocess.TimeoutExpired:rc=124
 text=(D/'proof.log').read_text();passed=rc==0 and 'SUCCESS!' in text;detected=rc!=0 and 'model found for base case: FAIL!' in text
 row={'negative':negative,'returncode':rc,'proof_passed':passed,'multiple_event_corruption_detected':detected,'accepted':detected if negative else passed};rows.append(row);print(json.dumps(row),flush=True)
cover_observer='''
reg [4:0] seen_events = 0;
always @(posedge clk) begin
 if(!rst_n)seen_events<=0;
 else seen_events <= seen_events | {parse_error,error_packet_valid,voltage_end_valid,voltage_node_valid,voltage_begin_valid};
end
(* keep *) wire proof_exercised = &seen_events;
'''
witness=cover(Y,O/'normal/source.sv',O/'normal','FrontendVoltagePacketParser',cover_observer,'rst_n 0',cycles=9,remove_assertions=True)
report={'ok':all(x['accepted'] for x in rows) and witness['reachable'] and S.read_text()==source,'rows':rows,'cover':witness,'source_sha256':sha(S),'source_unchanged':S.read_text()==source,'tool_version':version,'runner_sha256':sha(Path(__file__)),'helper_sha256':sha(Path(__file__).parent/'formal_witness_m5.py'),'scope':'Actual configured48-byte/32-node parser dispatch/range/reset/output cone; every pure helper call return independently arbitrary (overapproximation). All binary line length/overflow/valid/reset sequences. At most one begin/node/end/error/parse-error output per clock; declared begin/end counts<=32 and accepted node index<32.','helper_cuts':cuts,'assumptions':['Two-state synchronous model with actual initialized validity outputs. Pure helper returns independently arbitrary per cycle; no input grammar/checksum assumption.'],'unsupported':['Full grammar/data-byte equivalence to independent golden','UART/line-assembler timing','Packet uniqueness/completeness/atomic banks; separately required'],'artifacts':{str(p.relative_to(O)):sha(p) for p in O.rglob('*') if p.is_file()},'completed_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()};(O/'report.json').write_text(json.dumps(report,indent=2)+'\n');raise SystemExit(0 if report['ok'] else 1)
