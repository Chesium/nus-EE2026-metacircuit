#!/usr/bin/env python3
"""Actual-source scoped formal verification; assumptions and unsupported scope remain explicit."""
from pathlib import Path
import argparse,datetime,hashlib,json,subprocess,sys
from formal_witness_m5 import cover, FIFO_OBSERVER, GUARD_OBSERVER
P=argparse.ArgumentParser(description=__doc__)
P.add_argument('--source',type=Path,default=Path(__file__).resolve().parents[1]/'src/design/common/FloodQueueStore.v')
P.add_argument('--out',type=Path,required=True)
P.add_argument('--yosys',default='/tmp/m5-qor-yosys-tools/extracted/usr/bin/yosys')
A=P.parse_args();O=A.out.resolve();O.mkdir(parents=True,exist_ok=False)
R=Path(__file__).resolve().parents[1];Y=A.yosys;S=A.source.resolve()
version=subprocess.check_output([Y,'-V'],text=True).strip()
if not version.startswith('Yosys 0.33 '):raise SystemExit('Expected qualified Yosys0.33')
(O/'runner.py').write_bytes(Path(__file__).read_bytes())
source=S.read_text();baseline=source;sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
if hashlib.sha256(S.read_bytes()).hexdigest() != '6e80cfbf5b6b456462822014b15808814b2c6b0208ad7ef0bbd4da4c664adfb8':raise SystemExit('Unreviewed FIFO memory semantics: exact-source projection only qualifies the reviewed reset/write/read structure')
observer='''
  // One fixed symbolic memory address projects the actual memory's read-old
  // semantics. All other read values are unconstrained, an overapproximation.
  (* anyconst *) reg [PTR_WIDTH-1:0] watched_address;
  (* anyseq *) reg [17:0] untracked_read_value;
  reg [17:0] watched_memory = 18'd0;
  wire [17:0] projected_read_value = (head_ptr == watched_address) ? watched_memory : untracked_read_value;
  always @(posedge clk) begin
    assume(watched_address < DEPTH);
    if (rst_n && !clear && do_add && tail_ptr == watched_address)
      watched_memory <= {addQueue_i, addQueue_j, addQueue_d[1:0]};
  end
  (* anyseq *) reg select_transaction;
  reg established = 1'b0;
  reg watched_valid = 1'b0;
  reg [LEN_WIDTH-1:0] earlier_transactions = 0;
  reg [17:0] watched_payload = 0;
  reg retire_capture = 1'b0;
  reg [17:0] retire_payload = 0;
  reg retire_output = 1'b0;
  reg [17:0] retire_output_payload = 0;
  wire [LEN_WIDTH:0] tail_sum = {1'b0,count} + head_ptr;
  wire [LEN_WIDTH:0] expected_tail = (tail_sum >= DEPTH) ? tail_sum - DEPTH : tail_sum;
  wire [LEN_WIDTH:0] watched_sum = {1'b0,earlier_transactions} + head_ptr;
  wire [LEN_WIDTH:0] expected_watched_address = (watched_sum >= DEPTH) ? watched_sum - DEPTH : watched_sum;
  always @(posedge clk) begin
    if (established) begin
      assert(count <= DEPTH);
      assert(head_ptr < DEPTH);
      assert(tail_ptr < DEPTH);
      assert(tail_ptr == expected_tail);
      if (watched_valid) begin
        assert(earlier_transactions < count);
        assert(watched_address == expected_watched_address);
        assert(watched_memory == watched_payload);
      end
      if (rst_n && !clear) begin
        if (retire_capture) assert(captured_pop == retire_payload);
        if (retire_output) begin
          assert(popQueue_done);
          assert(popQueue_result == retire_output_payload);
        end
      end
    end
    if (!rst_n || clear) begin
      established <= 1'b1;
      watched_valid <= 1'b0;
      earlier_transactions <= 0;
      watched_payload <= 0;
      retire_capture <= 1'b0;
      retire_output <= 1'b0;
      retire_payload <= 0;
      retire_output_payload <= 0;
    end else begin
      retire_capture <= watched_valid && do_pop && earlier_transactions == 0;
      retire_payload <= watched_payload;
      retire_output <= retire_capture;
      retire_output_payload <= retire_payload;
      if (watched_valid && do_pop) begin
        if (earlier_transactions == 0) watched_valid <= 1'b0;
        else earlier_transactions <= earlier_transactions - 1'b1;
      end
      if (!watched_valid && select_transaction && do_add && tail_ptr == watched_address) begin
        watched_valid <= 1'b1;
        earlier_transactions <= count - (do_pop ? 1'b1 : 1'b0);
        watched_payload <= {addQueue_i, addQueue_j, addQueue_d[1:0]};
      end
    end
  end
'''
assert baseline.count('captured_pop <= mem[head_ptr];')==1
projected=baseline.replace('captured_pop <= mem[head_ptr];','captured_pop <= projected_read_value;')
assert projected.count('endmodule')==1;projected=projected.replace('endmodule',observer+'\nendmodule')
rows=[]
for depth,negative in [(1,False),(3,False),(4,False),(1152,False),(1152,True)]:
 d=O/(('negative-' if negative else 'depth-')+str(depth));d.mkdir()
 text=projected
 if negative:text=text.replace('captured_pop <= projected_read_value;','captured_pop <= projected_read_value ^ 18\'d1;')
 sv=d/'source.sv';sv.write_text(text)
 ys=d/'proof.ys';ys.write_text(f'read_verilog -formal -sv {sv}\nchparam -set DEPTH {depth} FloodQueueStore\nhierarchy -top FloodQueueStore\nproc\nflatten\nopt\nmemory_map\nopt\nsat -seq 4 -tempinduct -maxsteps 12 -set-assumes -prove-asserts -verify -dump_vcd {d/"counterexample.vcd"}\n')
 with (d/'proof.log').open('w') as log:
  try:rc=subprocess.run([Y,'-Q','-s',str(ys)],stdout=log,stderr=subprocess.STDOUT,timeout=180).returncode
  except subprocess.TimeoutExpired:rc=124
 log=(d/'proof.log').read_text(); passed=rc==0 and 'SUCCESS!' in log;detected=rc!=0 and 'model found for base case: FAIL!' in log
 row={'depth':depth,'negative':negative,'returncode':rc,'proof_passed':passed,'corruption_detected':detected,'accepted':detected if negative else passed,'instrumented_source_file':str(sv),'source_sha256':sha(sv)};rows.append(row);print(json.dumps(row),flush=True);(O/'checkpoint.json').write_text(json.dumps(rows,indent=2)+'\n')
covers=[]
for depth in [1,3,4,1152]:
 d=O/('depth-'+str(depth))
 observer=FIFO_OBSERVER.replace('@EXTRA@','&& saw_rank && saw_overlap' if depth>1 else '')
 c=cover(Y,d/'source.sv',d,'FloodQueueStore',observer,'rst_n 0',f'chparam -set DEPTH {depth} FloodQueueStore\n')
 covers.append({'depth':depth,'earlier_transactions_and_overlap_required':depth>1,**c})
report={'ok':all(x['accepted'] for x in rows) and all(x['reachable'] for x in covers) and S.read_text()==baseline,'rows':rows,'covers':covers,'witness_helper_sha256':hashlib.sha256((Path(__file__).parent/'formal_witness_m5.py').read_bytes()).hexdigest(),'source_file':str(S),'source_sha256':sha(S),'source_unchanged':S.read_text()==baseline,'scope':'For depths1/3/4/1152 after an actual reset/clear: circular pointer/count geometry and arbitrary selected transaction FIFO rank, unchanged truncated payload at pop capture and delayed done/result. Arbitrary add/pop/reset/clear inputs; no fairness/progress assumption.','assumptions':['One fixed symbolic address is in range; arbitrary transaction selection and all interface inputs defined.','Exact-source memory projection: watched cell keeps initial zero and updates on actual accepted writes; other reads unconstrained. No RAM timing abstraction beyond actual read-old single-clock semantics.'],'unsupported':['Before first real reset/clear','Arbitrary parameter widths','Liveness/when consumer requests pop','Physical RAM primitive/four-state/metastability equivalence'],'tool_version':version,'runner_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'completed_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'artifacts':{str(p.relative_to(O)):sha(p) for p in O.rglob('*') if p.is_file() and p.name!='report.json'}};(O/'report.json').write_text(json.dumps(report,indent=2)+'\n');raise SystemExit(0 if report['ok'] else 1)
