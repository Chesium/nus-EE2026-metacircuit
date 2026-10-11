#!/usr/bin/env python3
"""Actual receiver cone: distinct declared nodes and conditional bank commit safety."""
from pathlib import Path
import argparse,datetime,hashlib,json,re,subprocess
P=argparse.ArgumentParser(description=__doc__)
P.add_argument('--source',type=Path,required=True)
P.add_argument('--out',type=Path,required=True)
P.add_argument('--yosys',default='/tmp/m5-qor-yosys-tools/extracted/usr/bin/yosys')
A=P.parse_args();O=A.out.resolve();O.mkdir(parents=True,exist_ok=False);S=A.source.resolve();source=S.read_text();Y=A.yosys;sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
version=subprocess.check_output([Y,'-V'],text=True).strip();assert version.startswith('Yosys 0.33 ')
assert 'frontend_reply_stage_seen' in source,'requires explicit distinct-node correction'
anchor="        frontend_reply_ram0_w_en <= 1'b0;";assert source.count(anchor)==1
start=source.rfind('    always @(posedge CLK100MHZ) begin',0,source.index(anchor));end=source.index('\n    always @(posedge CLK100MHZ) begin',source.index(anchor));body=source[start:end]
vars=sorted(set(re.findall(r'\b(\w+)\s*<=',body)));decl=[]
for name in vars:
 found=re.findall(r'^\s*reg\s+[^;\n]*\b'+name+r'\s*=\s*[^;]+;',source,re.M);assert len(found)==1,name;decl.append(found[0])
 assert len(re.findall(r'\b'+name+r'\s*<=',source))==len(re.findall(r'\b'+name+r'\s*<=',body)),'unobserved producer '+name
currents=re.findall(r'wire\s+frontend_reply_(?:error|begin|stage)_current\s*=.*?;',source,re.S);assert len(currents)==3
header='''module Banks(input CLK100MHZ,frontend_uart_client_enable,frontend_snapshot_id_valid,
input [15:0] frontend_snapshot_frame,
input frontend_error_packet_valid,frontend_voltage_begin_valid,frontend_voltage_node_valid,frontend_voltage_end_valid,frontend_reply_parse_error,
input [15:0] frontend_error_packet_frame,frontend_voltage_begin_frame,frontend_voltage_node_frame,frontend_voltage_end_frame,
input [7:0] frontend_error_packet_code,frontend_voltage_begin_node_count,frontend_voltage_begin_status,frontend_voltage_node_idx,frontend_voltage_end_node_count,frontend_voltage_end_status,
input [31:0] frontend_voltage_node_value_bits,
input BTNL,BTNR,BTNU,BTND,frontend_btnl_rise,frontend_btnr_rise,frontend_btnu_rise,frontend_btnd_rise,
input frontend_rx_byte_valid,frontend_tx_busy,frontend_tx_start);
localparam [7:0] FRONTEND_STATUS_REPLY_PARSE=8'h83;
'''
base=header+'\n'.join(decl)+'\n'+'\n'.join(currents)+'\n'+body
# Balanced sum avoids a long arithmetic chain in the proof observer only.
terms=["{6'd0,frontend_reply_stage_seen["+str(i)+"]}" for i in range(32)]
while len(terms)>1:terms=['('+terms[i]+' + '+terms[i+1]+')' for i in range(0,len(terms),2)]
observer='''
wire [6:0] seen_count = @SUM@;
wire [31:0] declared_mask = 32'hffffffff >> (32 - frontend_reply_stage_node_count);
wire complete_current_end = frontend_reply_stage_active && frontend_voltage_end_valid &&
  frontend_voltage_end_frame == frontend_reply_stage_frame &&
  frontend_voltage_end_node_count == frontend_reply_stage_node_count &&
  frontend_voltage_end_status == frontend_reply_stage_status &&
  frontend_reply_stage_received_count == frontend_reply_stage_node_count && frontend_reply_stage_current;
wire [2:0] events = {2'd0,frontend_error_packet_valid}+{2'd0,frontend_voltage_begin_valid}+{2'd0,frontend_voltage_node_valid}+{2'd0,frontend_voltage_end_valid}+{2'd0,frontend_reply_parse_error};
(* anyconst *) reg [4:0] watched_node;
reg previous_bank = 0, previous_enable = 0, previous_commit = 0;
reg [15:0] expected_commit_frame = 0;
reg [7:0] expected_commit_nodes = 0, expected_commit_status = 0;
always @(posedge CLK100MHZ) begin
 assume(events <= 1);
 if(frontend_voltage_begin_valid) assume(frontend_voltage_begin_node_count <= 32);
 if(frontend_voltage_end_valid) assume(frontend_voltage_end_node_count <= 32);
 if(frontend_voltage_node_valid) assume(frontend_voltage_node_idx < 32);
 assert(frontend_reply_stage_node_count <= 32);
 assert(frontend_reply_stage_received_count == seen_count);
 assert((frontend_reply_stage_seen & ~declared_mask) == 0);
 assert(frontend_reply_stage_received_count <= frontend_reply_stage_node_count);
 if(frontend_reply_stage_active) assert(frontend_reply_stage_bank != frontend_reply_active_bank);
 assert(!(frontend_reply_ram0_w_en && frontend_reply_ram1_w_en));
 if(frontend_uart_client_enable && frontend_reply_valid) begin
  if(frontend_reply_ram0_w_en) assert(frontend_reply_active_bank != 0);
  if(frontend_reply_ram1_w_en) assert(frontend_reply_active_bank != 1);
 end
 if(complete_current_end && watched_node < frontend_reply_stage_node_count)
  assert(frontend_reply_stage_seen[watched_node]);
 if(previous_enable && !previous_commit) assert(frontend_reply_active_bank == previous_bank);
 if(previous_commit) begin
  assert(frontend_reply_valid);
  assert(frontend_reply_frame == expected_commit_frame);
  assert(frontend_reply_node_count == expected_commit_nodes);
  assert(frontend_reply_status == expected_commit_status);
 end
 previous_bank <= frontend_reply_active_bank;
 previous_enable <= frontend_uart_client_enable;
 previous_commit <= frontend_uart_client_enable && complete_current_end;
 expected_commit_frame <= frontend_reply_stage_frame;
 expected_commit_nodes <= frontend_reply_stage_node_count;
 expected_commit_status <= frontend_reply_stage_status;
end
'''.replace('@SUM@',terms[0])
rows=[]
for negative in [False,True]:
 D=O/('negative-duplicate-admitted' if negative else 'normal');D.mkdir();text=base+observer+'\nendmodule\n'
 if negative:
  old='!frontend_reply_stage_seen[frontend_voltage_node_idx[4:0]]';assert text.count(old)==1;text=text.replace(old,"1'b1")
 sv=D/'source.sv';sv.write_text(text);ys=D/'proof.ys';ys.write_text(f'read_verilog -formal -sv {sv}\nhierarchy -top Banks\nproc\nflatten\nopt\nsat -seq 4 -tempinduct -maxsteps 12 -set-assumes -prove-asserts -verify -dump_vcd {D/"counterexample.vcd"}\n')
 with (D/'proof.log').open('w') as log:
  try:rc=subprocess.run([Y,'-Q','-s',str(ys)],stdout=log,stderr=subprocess.STDOUT,timeout=180).returncode
  except subprocess.TimeoutExpired:rc=124
 text=(D/'proof.log').read_text();passed=rc==0 and 'SUCCESS!' in text;detected=rc!=0 and 'model found for base case: FAIL!' in text
 row={'negative':negative,'returncode':rc,'proof_passed':passed,'duplicate_counterexample':detected,'accepted':detected if negative else passed};rows.append(row);print(json.dumps(row),flush=True)
report={'ok':all(x['accepted'] for x in rows) and S.read_text()==source,'rows':rows,'source_sha256':sha(S),'source_unchanged':S.read_text()==source,'producer_inventory_verified':True,'receiver_body_sha256':hashlib.sha256(body.encode()).hexdigest(),'tool_version':version,'runner_sha256':sha(Path(__file__)),'scope':'Initialized actual receiver control cone; declared32node mask/count equality/range, inactive-bank writes, complete-current-ID conditional commits and unchanged primary-bank selection when no commit. Arbitrary parsed event sequences/current IDs/enable/button predicates/payload fields under parser constraints.','assumptions':['Synchronous two-state model, actual initialized receiver registers.','At most one parsed begin/node/end/error/parse-error event eachclock; begin/endnode counts<=32 and nodeindex<32. These follow separately proved actual configured parser properties.','Current snapshot ID/valid and decoded packet fields/payload/button-edge predicates otherwise arbitrary; no fair timing assumption.'],'unsupported':['Logical/physical RAM payload theorem','Registered view-read timing','Arbitrary button/reply overlap view-range semantics','UART/assembler/PS2/CDC; realserial regression separately required'],'artifacts':{str(p.relative_to(O)):sha(p) for p in O.rglob('*') if p.is_file()},'completed_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()};(O/'report.json').write_text(json.dumps(report,indent=2)+'\n');raise SystemExit(0 if report['ok'] else 1)
