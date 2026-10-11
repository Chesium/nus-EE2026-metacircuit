#!/usr/bin/env python3
"""Prove quiescent component-rebuild completion from the actual control cone."""
import sys,pathlib;sys.path.insert(0,str(pathlib.Path(__file__).resolve().parent));from m5_tools import yosys
from pathlib import Path
import argparse, datetime, hashlib, json, re, subprocess
from verify_address_m5 import extract_functions
from formal_witness_m5 import cover

P=argparse.ArgumentParser(description=__doc__)
P.add_argument('--source',type=Path,default=Path(__file__).resolve().parents[1]/'src/design/rendering/GlobalRender_top.v')
P.add_argument('--out',type=Path,required=True)
P.add_argument('--yosys',default=yosys())
A=P.parse_args();O=A.out.resolve();O.mkdir(parents=True,exist_ok=False);S=A.source.resolve();Y=A.yosys
source=S.read_text();sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
version=subprocess.check_output([Y,'-V'],text=True).strip()
if not version.startswith('Yosys 0.33 '):raise SystemExit('Expected qualified Yosys0.33')
functions=extract_functions(source)
start='        if (component_index_map_pending_pair_write) begin'
end="        if (component_store_change_this_cycle) begin\n            component_store_dirty <= 1'b1;\n        end"
assert source.count(start)==1 and source.count(end)==1
fragment=source[source.index(start):source.index(end)+len(end)]
names=['component_store_w_en','component_store_w_addr','component_store_w_data','component_store_count','component_store_dirty','component_index_map_w_en','component_index_map_w_addr','component_index_map_w_data','component_index_map_clear_active','component_index_map_clear_addr','component_index_map_pending_pair_write','component_index_map_pending_pair_addr','component_index_map_pending_pair_data','component_store_rebuild_active','component_store_write_drain','component_store_scan_addr','component_store_next_index']
declarations=[]
for name in names:
 matches=re.findall(r'^\s*reg\s+[^;\n]*\b'+name+r'\s*=\s*[^;]+;',source,re.M)
 assert len(matches)==1,name;declarations.append(matches[0])
 additional=1 if name in ['component_store_w_en','component_index_map_w_en','component_store_write_drain'] else 0
 assert len(re.findall(r'\b'+name+r'\s*<=',source))==len(re.findall(r'\b'+name+r'\s*<=',fragment))+additional,'unobserved producer '+name
busy=re.findall(r'wire\s+component_store_busy\s*=.*?;',source,re.S);assert len(busy)==1
payload=re.findall(r'function\s+\[COMPONENT_STORE_ENTRY_W-1:0\]\s+make_component_store_entry;.*?endfunction',source,re.S);assert len(payload)==1
control='''module Progress(input CLK100MHZ,freeze_request,component_store_change_this_cycle,abstract_origin,
input [15:0] component_store_scan_cell,input [5:0] component_store_scan_sprite,
input component_store_scan_needs_index,component_store_scan_is_two_cell,
input [8:0] component_store_scan_pair_addr,input [3:0] component_store_scan_unit,component_store_scan_store_type,
input [1:0] component_store_scan_rotation,input [11:0] component_store_scan_value);
localparam integer CANVAS_GRID_W=18,CANVAS_GRID_H=16,CANVAS_CELL_COUNT=288,CANVAS_ADDR_W=9,COMPONENT_STORE_ENTRY_W=40;
localparam [8:0] COMPONENT_INDEX_INVALID=9'h1ff;
function component_store_is_origin;
 input [15:0] cell_word; input [5:0] sprite;
 begin component_store_is_origin=abstract_origin; end
endfunction
'''+functions+'\n'+payload[0]+'\n'+'\n'.join(declarations)+'\n'+busy[0]+'''
always @(posedge CLK100MHZ) begin
 component_store_write_drain <= component_index_map_w_en || component_store_w_en;
 component_index_map_w_en <= 0;
 component_store_w_en <= 0;
'''+fragment+'\nend\n'
observer='''
reg frozen = 0, previous_frozen = 0, previous_busy = 0;
reg [10:0] age = 0;
reg [15:0] previous_potential = 0;
wire [15:0] phase_rank = component_index_map_clear_active ?
  (CANVAS_CELL_COUNT - component_index_map_clear_addr) + 2*CANVAS_CELL_COUNT :
  component_store_rebuild_active ? 2*(CANVAS_CELL_COUNT - component_store_scan_addr) + component_index_map_pending_pair_write :
  component_index_map_pending_pair_write ? 1 : 0;
wire [15:0] scheduler_rank = phase_rank + (component_store_dirty ? 3*CANVAS_CELL_COUNT+1 : 0);
wire [15:0] potential = scheduler_rank != 0 ? scheduler_rank+3 :
  (component_store_w_en || component_index_map_w_en) ? 2 : component_store_write_drain ? 1 : 0;
always @(posedge CLK100MHZ) begin
 if (!frozen) assert(age == 0);
 assert(!previous_frozen || frozen);
 assert(!(component_index_map_clear_active && component_store_rebuild_active));
 assert(!(component_index_map_clear_active && component_index_map_pending_pair_write));
 if (component_index_map_clear_active) assert(component_index_map_clear_addr < CANVAS_CELL_COUNT);
 if (component_store_rebuild_active) begin
  assert(component_store_scan_addr < CANVAS_CELL_COUNT);
  assert(component_store_next_index <= component_store_scan_addr);
 end
 assert(component_store_count <= CANVAS_CELL_COUNT);
 assert(potential <= 6*CANVAS_CELL_COUNT+5);
 assert((potential != 0) == component_store_busy);
 if (frozen) begin
  assume(!component_store_change_this_cycle);
  assert(age + potential <= 6*CANVAS_CELL_COUNT+5);
  assert(age < 1744 || !component_store_busy);
  if (previous_frozen && previous_busy) assert(potential < previous_potential);
  if (component_store_busy) age <= age + 1'b1;
  else age <= 0;
 end
 if (freeze_request) frozen <= 1;
 previous_frozen <= frozen;
 previous_busy <= component_store_busy;
 previous_potential <= potential;
end
'''
rows=[]
for negative in [False,True]:
 d=O/('negative-stuck-clear' if negative else 'normal');d.mkdir();text=control+observer+'\nendmodule\n'
 if negative:
  old="component_index_map_clear_addr <= component_index_map_clear_addr + 1'b1;";assert text.count(old)==1;text=text.replace(old,'component_index_map_clear_addr <= component_index_map_clear_addr;')
 sv=d/'source.sv';sv.write_text(text);ys=d/'proof.ys';ys.write_text(f'read_verilog -formal -sv {sv}\nhierarchy -top Progress\nproc\nflatten\nopt\nsat -seq 4 -tempinduct -maxsteps 16 -set-assumes -prove-asserts -verify -dump_vcd {d/"counterexample.vcd"}\n')
 with (d/'proof.log').open('w') as log:
  try:rc=subprocess.run([Y,'-Q','-s',str(ys)],stdout=log,stderr=subprocess.STDOUT,timeout=120).returncode
  except subprocess.TimeoutExpired:rc=124
 log=(d/'proof.log').read_text();passed=rc==0 and 'SUCCESS!' in log;detected=rc!=0 and 'model found for base case: FAIL!' in log
 row={'negative':negative,'returncode':rc,'proof_passed':passed,'stuck_clear_detected':detected,'accepted':detected if negative else passed};rows.append(row);print(json.dumps(row),flush=True)
cover_observer="""
reg saw_old_edit = 0, saw_dirty_freeze = 0, saw_new_clear = 0, saw_new_rebuild = 0, saw_finish = 0;
always @(posedge CLK100MHZ) begin
 if (!frozen && component_store_rebuild_active && component_store_change_this_cycle) saw_old_edit <= 1;
 if (freeze_request && saw_old_edit && component_store_dirty && component_store_rebuild_active) saw_dirty_freeze <= 1;
 if (frozen && saw_dirty_freeze && component_index_map_clear_active) saw_new_clear <= 1;
 if (frozen && saw_new_clear && component_store_rebuild_active) saw_new_rebuild <= 1;
 if (frozen && saw_new_rebuild && !component_store_busy) saw_finish <= 1;
end
(* keep *) wire proof_exercised = saw_finish;
"""
witness=cover(Y,O/'normal/source.sv',O/'normal','Progress',cover_observer,cycles=1180,remove_assertions=True,input_constraints='-set abstract_origin 0 -set component_store_scan_needs_index 0 -set component_store_scan_is_two_cell 0 -set freeze_request 0 -set-at 301 freeze_request 1 -set component_store_change_this_cycle 0 -set-at 300 component_store_change_this_cycle 1')
report={'ok':all(x['accepted'] for x in rows) and witness['reachable'] and S.read_text()==source,'rows':rows,'cover':witness,'cover_scope':'Reachable extracted-cone history: edit during old rebuild, freeze with dirty old rebuild, second map clear/rebuild and final drain. Same predicate cuts and quiescence assumptions.','witness_helper_sha256':sha(Path(__file__).parent/'formal_witness_m5.py'),'source_sha256':sha(S),'source_unchanged':S.read_text()==source,'control_fragment_sha256':hashlib.sha256(fragment.encode()).hexdigest(),'producer_inventory_verified':True,'deadline_clocks':1744,'maximum_initial_potential':1733,'scope':'Actual extracted18x16 rebuild controller with unchanged initial register values, write strobes/drain and busy expression. Once edits cease at any reachable phase, busy deasserts within1744 system-clock samples; every active frozen step decreases proved ranking potential.','assumptions':['Two-state synchronous model, control registers retain explicit RTL initial values. No new component_store_change_this_cycle after nondeterministically chosen freeze boundary.','Scan origin/index/two-cell/pair and payload values are arbitrary per-cycle cutpoints, overapproximating actual arrays/classifiers. No map/content/data equivalence theorem.','Fixed actual SimpleRam write visibility and one-edge read-refresh drain; no memory backpressure interface exists in this extracted scheduler.'],'unsupported':['Full flooding/extraction/UART/solver completion','Arbitrary uninitialized control state/physical CDC','Global map/payload equality or multiwrite publication atomicity'],'tool_version':version,'runner_sha256':sha(Path(__file__)),'address_helper_sha256':sha(Path(__file__).parent/'verify_address_m5.py'),'artifacts':{str(p.relative_to(O)):sha(p) for p in O.rglob('*') if p.is_file()},'completed_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()};(O/'report.json').write_text(json.dumps(report,indent=2)+'\n');raise SystemExit(0 if report['ok'] else 1)
