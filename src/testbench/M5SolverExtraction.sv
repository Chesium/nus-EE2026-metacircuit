`timescale 1ns/1ps
// Actual generated extraction with bounded deterministic response stalls.
module M5SolverResponder #(parameter WIDTH=8, ID=0)(
 input logic clk, rst_n, start, input logic [31:0] address,
 input logic [WIDTH-1:0] value, output logic done,
 output logic [WIDTH-1:0] result);
 integer pending=0, countdown=0, requests=0, stall_cycles=0;
 logic [31:0] captured_address, rng=32'h12345678+ID;
 logic [WIDTH-1:0] captured_value;
 always @(posedge clk) begin
  done<=0;
  if (!rst_n) begin pending<=0; requests<=0; stall_cycles<=0; end
  else if (pending) begin
   if (start) $fatal(1,"duplicate primitive request ID=%0d",ID);
   // start/done primitives latch arguments on start; inputs may change afterward.
   if (countdown==0) begin done<=1; result<=captured_value; pending<=0; end
   else begin countdown<=countdown-1; stall_cycles<=stall_cycles+1; end
  end else if (start) begin
   captured_address<=address; captured_value<=value; pending<=1;
   rng<=rng*32'd1664525+32'd1013904223; countdown<=rng[2:0]; requests<=requests+1;
  end
 end
endmodule

module M5SolverExtraction;
 logic clk=0, rst_n=0, start=0; always #5 clk=~clk;
 wire busy, done;
 logic [15:0] cells[36]; logic [7:0] regions[36];
 logic [7:0] comp_type, comp_x, comp_y; logic [1:0] comp_rot;
 wire ts,xs,ys,rs,cs,fs,n0s,n1s,td,xd,yd,rd,cd,fd,n0d,n1d;
 wire [15:0] ti,xi,yi,ri,n0i,n1i;
 wire [7:0] cx,cy,fx,fy,tr,xr,yr,fr,n0v,n1v;
 wire [1:0] rr; wire [15:0] cr;
 logic [7:0] got0,got1; integer writes0=0,writes1=0, fixture=0;
 extract_component_nodes dut(.clk(clk),.rst_n(rst_n),.start(start),.busy(busy),.done(done),
 .par_elem_n(32'd1),.grid_height(32'd6),.grid_width(32'd6),
 .fetchComponentType_start(ts),.fetchComponentType_idx(ti),.fetchComponentType_done(td),.fetchComponentType_result(tr),
 .fetchAnchorPositionX_start(xs),.fetchAnchorPositionX_idx(xi),.fetchAnchorPositionX_done(xd),.fetchAnchorPositionX_result(xr),
 .fetchAnchorPositionY_start(ys),.fetchAnchorPositionY_idx(yi),.fetchAnchorPositionY_done(yd),.fetchAnchorPositionY_result(yr),
 .fetchComponentRotation_start(rs),.fetchComponentRotation_idx(ri),.fetchComponentRotation_done(rd),.fetchComponentRotation_result(rr),
 .fetchCell_start(cs),.fetchCell_i(cx),.fetchCell_j(cy),.fetchCell_done(cd),.fetchCell_result(cr),
 .fetchR_start(fs),.fetchR_i(fx),.fetchR_j(fy),.fetchR_done(fd),.fetchR_result(fr),
 .storeNode0_start(n0s),.storeNode0_idx(n0i),.storeNode0_node_i(n0v),.storeNode0_done(n0d),
 .storeNode1_start(n1s),.storeNode1_idx(n1i),.storeNode1_node_i(n1v),.storeNode1_done(n1d));
 M5SolverResponder #(.ID(0)) rt(clk,rst_n,ts,{16'd0,ti},comp_type,td,tr);
 M5SolverResponder #(.ID(1)) rx(clk,rst_n,xs,{16'd0,xi},comp_x,xd,xr);
 M5SolverResponder #(.ID(2)) ry(clk,rst_n,ys,{16'd0,yi},comp_y,yd,yr);
 M5SolverResponder #(.ID(3),.WIDTH(2)) rrsp(clk,rst_n,rs,{16'd0,ri},comp_rot,rd,rr);
 M5SolverResponder #(.ID(4),.WIDTH(16)) rc(clk,rst_n,cs,{16'd0,cy,cx},cells[cy*6+cx],cd,cr);
 M5SolverResponder #(.ID(5)) rf(clk,rst_n,fs,{16'd0,fy,fx},regions[fy*6+fx],fd,fr);
 M5SolverResponder #(.ID(6)) rn0(clk,rst_n,n0s,{16'd0,n0i},n0v,n0d,);
 M5SolverResponder #(.ID(7)) rn1(clk,rst_n,n1s,{16'd0,n1i},n1v,n1d,);
 always @(posedge clk) if (rst_n) begin
  if ((cs && (cx>=6 || cy>=6)) || (fs && (fx>=6 || fy>=6))) $fatal(1,"out of grid read");
  if ((ts && ti!=0)||(xs && xi!=0)||(ys && yi!=0)||(rs && ri!=0)) $fatal(1,"out of range component read");
  if (n0s) begin if(n0i!=0) $fatal(1,"out of range write"); got0<=n0v; writes0<=writes0+1; end
  if (n1s) begin if(n1i!=0) $fatal(1,"out of range write"); got1<=n1v; writes1<=writes1+1; end
 end
 task automatic run_fixture(input integer case_id,input logic[7:0] want0,want1);
  integer cycles;
  begin
   fixture=case_id; rst_n=0; writes0=0; writes1=0;
   repeat(4) @(negedge clk); rst_n=1;
   repeat(2) @(negedge clk); start=1; @(negedge clk); start=0;
   cycles=0;
   while(!done && cycles<200000) begin @(negedge clk); cycles++; end
   if(!done) $fatal(1,"extraction timeout case=%0d",case_id);
   if($test$plusargs("CORRUPT_EXTRACTION") && case_id==0) got0=got0^8'h01;
   if(got0!==want0 || got1!==want1 || writes0!=1 || writes1!=1)
    $fatal(1,"extraction mismatch case=%0d got=%02x/%02x expected=%02x/%02x writes=%0d/%0d",case_id,got0,got1,want0,want1,writes0,writes1);
   $display("EXTRACTION case=%0d cycles=%0d nodes=%02x/%02x stalls=%0d",case_id,cycles,got0,got1,
   rt.stall_cycles+rx.stall_cycles+ry.stall_cycles+rrsp.stall_cycles+rc.stall_cycles+rf.stall_cycles+rn0.stall_cycles+rn1.stall_cycles);
  end
 endtask
 initial begin
  `include "M5SolverExtractionFixtures.svh"
  $display("M5SolverExtraction passed."); $finish;
 end
endmodule
