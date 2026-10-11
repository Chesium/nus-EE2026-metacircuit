`timescale 1ns/1ps
// Actual existing AMD-generated VHDL products, never the Verilator stand-ins.
module M5FpCharacterization;
 logic clk=0; always #5 clk=~clk;
 logic fvalid=0,dvalid=0;
 logic [31:0] fa,fb,fc,da,db;
 wire fv,dv; wire [31:0] fresult,dresult;
 logic [31:0] observed_fresult; logic [3:0] observed_dflags;
 wire [2:0] fuser; wire [3:0] duser;
 floating_point_fma fma(.aclk(clk),.s_axis_a_tvalid(fvalid),.s_axis_a_tdata(fa),
 .s_axis_b_tvalid(fvalid),.s_axis_b_tdata(fb),.s_axis_c_tvalid(fvalid),.s_axis_c_tdata(fc),
 .m_axis_result_tvalid(fv),.m_axis_result_tdata(fresult),.m_axis_result_tuser(fuser));
 floating_point_div div(.aclk(clk),.s_axis_a_tvalid(dvalid),.s_axis_a_tdata(da),
 .s_axis_b_tvalid(dvalid),.s_axis_b_tdata(db),.m_axis_result_tvalid(dv),
 .m_axis_result_tdata(dresult),.m_axis_result_tuser(duser));
 integer cycle=0,fissued=0,dissued=0,fseen=0,dseen=0;
 integer fcycles[8192],dcycles[8192];
 logic [31:0] fexpected[8192],dexpected[8192];
 logic [3:0] fflags[8192],dflags[8192];
 integer fexpected_latency=16,dexpected_latency=28;
 always @(posedge clk) begin
  cycle++;
  if(fvalid) fcycles[fissued-1]=cycle;
  if(dvalid) dcycles[dissued-1]=cycle;
  #1;
  if(fv) begin
   observed_fresult=fresult;
   if($test$plusargs("CORRUPT_FP_DATA") && fseen==0) observed_fresult=observed_fresult^1;
   if(fseen>=fissued) $fatal(1,"FMA unsolicited output mismatch");
   if((cycle-fcycles[fseen]+1)!=fexpected_latency ||
      observed_fresult!==fexpected[fseen] || {1'b0,fuser}!==fflags[fseen])
    $fatal(1,"FMA mismatch case=%0d result=%08x expected=%08x flags=%x expectedflags=%x latency=%0d expectedlatency=%0d",fseen,observed_fresult,fexpected[fseen],fuser,fflags[fseen],cycle-fcycles[fseen]+1,fexpected_latency);
   $display("FP_FMA case=%0d result=%08x flags=%x latency=%0d",fseen,fresult,fuser,cycle-fcycles[fseen]+1);
   fseen++;
  end
  if(dv) begin
   observed_dflags=duser;
   if($test$plusargs("CORRUPT_FP_FLAGS") && dseen==0) observed_dflags=observed_dflags^1;
   if(dseen>=dissued) $fatal(1,"DIV unsolicited output mismatch");
   if((cycle-dcycles[dseen]+1)!=dexpected_latency || dresult!==dexpected[dseen] || observed_dflags!==dflags[dseen])
    $fatal(1,"DIV mismatch case=%0d result=%08x expected=%08x flags=%x expectedflags=%x latency=%0d expectedlatency=%0d",dseen,dresult,dexpected[dseen],observed_dflags,dflags[dseen],cycle-dcycles[dseen]+1,dexpected_latency);
   $display("FP_DIV case=%0d result=%08x flags=%x latency=%0d",dseen,dresult,duser,cycle-dcycles[dseen]+1);
   dseen++;
  end
 end
 task automatic issue_fma(input logic[31:0] a,b,c,want,input logic[3:0] flags,input integer gap);
  @(negedge clk); fvalid=0;
  repeat(gap) @(negedge clk);
  fa=a;fb=b;fc=c;fvalid=1;fexpected[fissued]=want;fflags[fissued]=flags;fissued++;
 endtask
 task automatic issue_div(input logic[31:0] a,b,want,input logic[3:0] flags,input integer gap);
  @(negedge clk); dvalid=0;
  repeat(gap) @(negedge clk);
  da=a;db=b;dvalid=1;dexpected[dissued]=want;dflags[dissued]=flags;dissued++;
 endtask
 initial begin
  repeat(4) @(negedge clk);
  if($test$plusargs("CORRUPT_LATENCY")) fexpected_latency++;
  if($test$plusargs("CORRUPT_DIV_LATENCY")) dexpected_latency++;
  `include "M5FpFixtures.svh"
  @(negedge clk);fvalid=0;dvalid=0;
  wait(fseen==fissued && dseen==dissued);
  repeat(32) @(negedge clk);
  $display("M5FpCharacterization passed fma=%0d div=%0d",fseen,dseen);$finish;
 end
 initial begin repeat(100000) @(negedge clk);$fatal(1,"FP characterization watchdog");end
endmodule
