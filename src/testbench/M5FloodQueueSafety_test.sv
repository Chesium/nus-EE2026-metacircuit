`timescale 1ns/1ps
module QueueLedger #(parameter integer DEPTH=1152);
reg clk=0,rst_n=0,clear=0,add_start=0,pop_start=0,len_start=0;
always #5 clk=~clk;
reg [7:0] item_i=0,item_j=0;
reg [31:0] item_d=0;
wire add_done,pop_done,len_done;
wire [15:0] len_result;
wire [17:0] pop_result;
FloodQueueStore #(.DEPTH(DEPTH)) dut(.clk(clk),.rst_n(rst_n),.clear(clear),.addQueue_start(add_start),.addQueue_i(item_i),.addQueue_j(item_j),.addQueue_d(item_d),.addQueue_done(add_done),.popQueue_start(pop_start),.popQueue_done(pop_done),.popQueue_result(pop_result),.getQueueLen_start(len_start),.getQueueLen_done(len_done),.getQueueLen_result(len_result));
reg [17:0] ledger[$];
reg expect_add=0,expect_pop=0,expect_len=0;
reg [17:0] captured_pop=0,observed;
reg [15:0] captured_len=0;
integer cycles=0,full_cases=0,empty_cases=0,concurrent=0,resets=0;
reg inject;
task tick(input reg a,p,l,r,c);
 integer before_size;
 reg [17:0] payload,old_pop;
 reg accepted_add,accepted_pop;
 begin
  @(negedge clk);
  rst_n=r; clear=c; add_start=a; pop_start=p; len_start=l;
  payload=18'(cycles*37+19);
  {item_i,item_j,item_d[1:0]}=payload;
  before_size=ledger.size();
  accepted_add=a && before_size<DEPTH;
  accepted_pop=p && before_size!=0;
  @(posedge clk); #1;
  observed=pop_result;
  if(inject && cycles==3) observed=observed^18'd1;
  if(!r || c) begin
   if(add_done || pop_done || len_done || len_result!==0 || pop_result!==0)
    $fatal(1,"QUEUE_LEDGER_FAILURE reset cycle=%0d",cycles);
   ledger.delete();expect_add=0;expect_pop=0;expect_len=0;captured_pop=0;captured_len=0;resets=resets+1;
  end else begin
   if(add_done!==expect_add || pop_done!==expect_pop || len_done!==expect_len)
    $fatal(1,"QUEUE_LEDGER_FAILURE ack cycle=%0d",cycles);
   if(observed!==captured_pop || len_result!==captured_len)
    $fatal(1,"QUEUE_LEDGER_FAILURE payload cycle=%0d",cycles);
   if(a && before_size==DEPTH)full_cases=full_cases+1;
   if(p && before_size==0)empty_cases=empty_cases+1;
   if(a && p)concurrent=concurrent+1;
   if(l)captured_len=16'(before_size);
   if(p)begin
    if(accepted_pop)begin old_pop=ledger.pop_front();captured_pop=old_pop;end
    else captured_pop=0;
   end
   if(accepted_add)ledger.push_back(payload);
   expect_add=a;expect_pop=p;expect_len=l;
  end
  if(dut.count!==ledger.size() || dut.head_ptr>=DEPTH || dut.tail_ptr>=DEPTH)
   $fatal(1,"QUEUE_LEDGER_FAILURE range_count cycle=%0d",cycles);
  cycles=cycles+1;
 end
endtask
integer k;
reg [31:0] prng=32'hcafebabe;
initial begin
 inject=$test$plusargs("corrupt-ledger-observation");
 tick(0,0,0,0,0);tick(1,1,1,1,0);tick(0,1,1,1,0);tick(0,0,0,1,0);
 // Full then simultaneous add/pop explicitly retains the old full rejection policy.
 for(k=0;k<DEPTH;k=k+1)tick(1,0,1,1,0);
 tick(1,0,1,1,0);tick(1,1,1,1,0);
 for(k=0;k<DEPTH+2;k=k+1)tick(0,1,1,1,0);
 for(k=0;k<10000;k=k+1)begin
  prng=prng^(prng<<13);prng=prng^(prng>>17);prng=prng^(prng<<5);
  tick(prng[0],prng[1],prng[2],k%257!=0,k%331==0);
 end
 tick(0,0,0,1,0);tick(0,0,0,1,0);
 if(full_cases==0 || empty_cases==0 || concurrent==0 || resets<2)$fatal(1,"QUEUE_LEDGER_FAILURE fixture");
 $display("QUEUE_LEDGER_PASS depth=%0d cycles=%0d full=%0d empty=%0d concurrent=%0d resets=%0d",DEPTH,cycles,full_cases,empty_cases,concurrent,resets);
 $finish;
end
initial begin #1000000;$fatal(1,"QUEUE_LEDGER_FAILURE watchdog");end
endmodule
