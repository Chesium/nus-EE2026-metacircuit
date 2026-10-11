#!/usr/bin/env python3
"""Actual-source scoped formal verification; assumptions and unsupported scope remain explicit."""
import sys,pathlib;sys.path.insert(0,str(pathlib.Path(__file__).resolve().parent));from m5_tools import yosys
from pathlib import Path
import argparse,datetime,hashlib,json,re,subprocess,sys
from formal_witness_m5 import cover, FIFO_OBSERVER, GUARD_OBSERVER
P=argparse.ArgumentParser(description=__doc__)
P.add_argument('--source',type=Path,default=Path(__file__).resolve().parents[1]/'src/design/interaction/CanvasCommandGuard.v')
P.add_argument('--out',type=Path,required=True)
P.add_argument('--yosys',default=yosys())
A=P.parse_args();O=A.out.resolve();O.mkdir(parents=True,exist_ok=False)
R=Path(__file__).resolve().parents[1];Y=A.yosys;S=A.source.resolve()
version=subprocess.check_output([Y,'-V'],text=True).strip()
if not version.startswith('Yosys 0.33 '):raise SystemExit('Expected qualified Yosys0.33')
(O/'runner.py').write_bytes(Path(__file__).read_bytes())
source=S.read_text();baseline=source;sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
if not re.search(r'parameter integer AddrWidth\s*=\s*9\b',source) or not re.search(r'parameter integer DataWidth\s*=\s*16\b',source):raise SystemExit('Unsupported guard parameter defaults; qualified AddrWidth9/DataWidth16 only')
observer='''
  localparam integer READY_BOUND = @A@;
  localparam integer REPLY_BOUND = @R@;
  localparam integer COMPLETION_BOUND = 5*READY_BOUND + 2*REPLY_BOUND + 4;
  reg established = 0;
  reg pending_read = 0;
  reg [7:0] ready_wait = 0, reply_wait = 0;
  reg [7:0] operation_age = 0;
  reg operation_active = 0;
  reg stalled = 0, previous_write = 0;
  reg [AddrWidth-1:0] previous_address = 0;
  reg [DataWidth-1:0] previous_data = 0;
  reg upstream_stalled = 0, previous_cmd_write = 0;
  reg [AddrWidth-1:0] previous_cmd_addr = 0;
  reg [DataWidth-1:0] previous_cmd_wdata = 0;
  reg [7:0] cycle = 0;
  wire [AddrWidth-1:0] observed_address = bg_cmd_addr ^ (@CORRUPT@ ? cycle[0] : 1'b0);
  wire [15:0] validation_reads = (dual_placement && index == 0) ? 2 : 1;
  wire [15:0] future_validation_reads = (dual_placement && index == 0) ? 1 : 0;
  wire [15:0] remaining_potential =
    state == CHECK ? validation_reads * (READY_BOUND + REPLY_BOUND) + count * READY_BOUND - ready_wait :
    state == WAIT_RESPONSE ? REPLY_BOUND - reply_wait + future_validation_reads * (READY_BOUND + REPLY_BOUND) + count * READY_BOUND :
    state == WRITE ? (count - index) * READY_BOUND - ready_wait : 0;
  always @(posedge clk) begin
    cycle <= cycle + 1'b1;
    if (reset) begin
      established <= 1;
      pending_read <= 0;
      ready_wait <= 0;
      reply_wait <= 0;
      operation_active <= 0;
      operation_age <= 0;
      stalled <= 0;
      upstream_stalled <= 0;
    end else if (established) begin
      assert(ready_wait < READY_BOUND);
      if (pending_read) assert(reply_wait < REPLY_BOUND);
      // Upstream obeys valid/ready and issues no next command/done until a
      // passthrough read completes. done closes a collected burst.
      if (upstream_stalled) begin
        assume(cmd_valid);
        assume(cmd_write == previous_cmd_write);
        assume(cmd_addr == previous_cmd_addr);
        if (previous_cmd_write) assume(cmd_wdata == previous_cmd_wdata);
      end
      if (controller_done) begin
        assume(!cmd_valid);
        assume(!pending_read);
      end
      if (pending_read && state == COLLECT) assume(!cmd_valid);
      // Memory accepts within A active request cycles and replies exactly
      // once, between 1 and R cycles after an accepted read.
      assume(!bg_rsp_valid || pending_read);
      if (bg_cmd_valid && ready_wait == READY_BOUND-1) assume(bg_cmd_ready);
      if (pending_read && reply_wait == REPLY_BOUND-1) assume(bg_rsp_valid);
      if (bg_cmd_valid && !bg_cmd_ready) ready_wait <= ready_wait + 1'b1;
      else ready_wait <= 0;
      if (pending_read && !bg_rsp_valid) reply_wait <= reply_wait + 1'b1;
      else reply_wait <= 0;
      if (bg_cmd_valid && bg_cmd_ready && !bg_cmd_write) begin
        assert(!pending_read);
        pending_read <= 1;
        reply_wait <= 0;
      end
      if (bg_rsp_valid) pending_read <= 0;
      if (stalled) begin
        assert(bg_cmd_valid);
        assert(bg_cmd_write == previous_write);
        assert(observed_address == previous_address);
        if (previous_write) assert(bg_cmd_wdata == previous_data);
      end
      if (operation_active && state == COLLECT) assert(count == 0);
      if (state == WAIT_RESPONSE) assert(pending_read);
      else if (state != COLLECT) assert(!pending_read);
      if (state != COLLECT) begin
        assert(count != 0);
        assert(index < count);
        assert(index < 3);
      end
      if (operation_active) begin
        assert(operation_age + remaining_potential < COMPLETION_BOUND);
        assert(operation_age < COMPLETION_BOUND || idle);
        if (idle) begin operation_active <= 0; operation_age <= 0; end
        else operation_age <= operation_age + 1'b1;
      end
      if (controller_done && count != 0 && state == COLLECT) begin
        operation_active <= 1;
        operation_age <= 0;
      end
      stalled <= bg_cmd_valid && !bg_cmd_ready;
      previous_write <= bg_cmd_write;
      previous_address <= observed_address;
      previous_data <= bg_cmd_wdata;
      upstream_stalled <= cmd_valid && !cmd_ready;
      previous_cmd_write <= cmd_write;
      previous_cmd_addr <= cmd_addr;
      previous_cmd_wdata <= cmd_wdata;
    end
  end
'''
rows=[]
for a,r,negative in [(1,1,False),(3,5,False),(7,11,False),(3,5,True)]:
 d=O/(f'ready{a}-reply{r}'+('-negative' if negative else ''));d.mkdir()
 obs=observer.replace('@A@',str(a)).replace('@R@',str(r)).replace('@CORRUPT@',"1'b1" if negative else "1'b0")
 assert source.count('endmodule')==1;text=source.replace('endmodule',obs+'\nendmodule');sv=d/'source.sv';sv.write_text(text)
 ys=d/'proof.ys';ys.write_text(f'read_verilog -formal -sv {sv}\nhierarchy -top CanvasCommandGuard\nproc\nflatten\nopt\nmemory_map\nopt\nsat -seq 4 -tempinduct -maxsteps 20 -set-assumes -prove-asserts -verify -dump_vcd {d/"counterexample.vcd"}\n')
 with (d/'proof.log').open('w') as log:
  try:rc=subprocess.run([Y,'-Q','-s',str(ys)],stdout=log,stderr=subprocess.STDOUT,timeout=180).returncode
  except subprocess.TimeoutExpired:rc=124
 log=(d/'proof.log').read_text();passed=rc==0 and 'SUCCESS!' in log;detected=rc!=0 and 'model found for base case: FAIL!' in log
 row={'ready_bound':a,'reply_bound':r,'completion_bound':5*a+2*r+4,'negative':negative,'returncode':rc,'proof_passed':passed,'corruption_detected':detected,'accepted':detected if negative else passed};rows.append(row);print(json.dumps(row),flush=True);(O/'checkpoint.json').write_text(json.dumps(rows,indent=2)+'\n')
covers=[]
for a,r in [(1,1),(3,5),(7,11)]:
 d=O/f'ready{a}-reply{r}'
 observer=GUARD_OBSERVER.replace('@EXTRA@','&& seen_read_stall && seen_write_stall && seen_reply_delay' if a>1 else '')
 c=cover(Y,d/'source.sv',d,'CanvasCommandGuard',observer,'reset 1')
 covers.append({'ready_bound':a,'reply_bound':r,'stalls_and_delay_required':a>1,**c})
report={'ok':all(x['accepted'] for x in rows) and all(x['reachable'] for x in covers) and S.read_text()==source,'rows':rows,'covers':covers,'witness_helper_sha256':hashlib.sha256((Path(__file__).parent/'formal_witness_m5.py').read_bytes()).hexdigest(),'source_unchanged':S.read_text()==source,'source_file':str(S),'source_sha256':hashlib.sha256(S.read_bytes()).hexdigest(),'scope':'Actual guard with proved phase/ranking invariants state/arrays unchanged; continuous stable downstream requests, internal buffer index safety and post-controller-done guard completion within 5*A+2*R+4 clock samples after real synchronous reset.','assumptions':['Two-state synchronous formal model; initially unspecified buffer contents arbitrary binary values; defined interface inputs; upstream valid/ready stability. controller_done implies no concurrent command or outstanding passthrough read; collected burst already present.','One outstanding read, exactly one response 1..R cycles after acceptance. No new upstream command while COLLECT read pending.','Every asserted background request accepted within A active request cycles. Resets cancel operations and are outside progress obligation.'],'unsupported':['Upstream InteractionController progress','Global maps/publication/reply atomicity','Physical clocks/CDC or arbitrary unfair stalls','Full frontend completion bound'],'tool_version':version,'runner_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'artifacts':{str(p.relative_to(O)):sha(p) for p in O.rglob('*') if p.is_file() and p.name!='report.json'},'completed_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()};(O/'report.json').write_text(json.dumps(report,indent=2)+'\n');raise SystemExit(0 if report['ok'] else 1)
