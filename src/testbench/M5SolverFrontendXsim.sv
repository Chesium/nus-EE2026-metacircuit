`timescale 1ns / 1ps
// Actual production frontend and SolverBoard UART at default115200.
// Mouse outputs are injected; PS/2 physical transport is outside this test.
module MouseCtl (
    input  wire        clk,
    input  wire        rst,
    output reg  [11:0] xpos = 12'd320,
    output reg  [11:0] ypos = 12'd240,
    output wire [3:0]  zpos,
    output reg         left = 1'b0,
    output reg         middle = 1'b0,
    output reg         right = 1'b0,
    output reg         new_event = 1'b0,
    input  wire [11:0] value,
    input  wire        setx,
    input  wire        sety,
    input  wire        setmax_x,
    input  wire        setmax_y,
    inout  wire        ps2_clk,
    inout  wire        ps2_data
);
  // Absolute position and buttons at the MouseCtl outputs (D-010), written by
  // the testbench through hierarchical references, like framescope's stub.
  assign zpos = 4'd0;
endmodule

module MouseDisplay (
    input  wire        pixel_clk,
    input  wire [11:0] xpos,
    input  wire [11:0] ypos,
    input  wire        mouse_left,
    input  wire [11:0] hcount,
    input  wire [11:0] vcount,
    output wire        enable_mouse_display_out,
    output wire [3:0]  red_out,
    output wire [3:0]  green_out,
    output wire [3:0]  blue_out
);
  assign enable_mouse_display_out = 1'b0;
  assign red_out = 4'd0;
  assign green_out = 4'd0;
  assign blue_out = 4'd0;
endmodule

module M5SolverFrontendXsim;
 reg clk=0; always #5 clk=~clk;
 reg [15:0] switches=16'h8020;
 reg reset=1; wire front_tx,solver_tx; wire [15:0] led;
 wire [7:0] seg; wire [3:0] an; tri pclk,pdata;
 wire vsync;
 GlobalRender_top front(.CLK100MHZ(clk),.SW(switches),.LED(led),.SEG(seg),.AN(an),
 .BTNC(1'b0),.BTNU(1'b0),.BTNL(1'b0),.BTNR(1'b0),.BTND(1'b0),
 .JC(),.VGARED(),.VGABLUE(),.VGAGREEN(),.HSYNC(),.VSYNC(vsync),
 .RsRx(solver_tx),.RsTx(front_tx),.PS2CLK(pclk),.PS2DATA(pdata));
 SolverBoard_top solver(.CLK100MHZ(clk),.BTNC(reset),.RsRx(front_tx),.RsTx(solver_tx),.LED(),.SEG(),.AN());
 integer cycle=0,fissue=-1,dissue=-1,fresults=0,dresults=0;
 always @(posedge clk) begin
   cycle++;
   if(solver.pipeline_inst.fma_inst.s_axis_a_tvalid) fissue=cycle;
   if(solver.pipeline_inst.div_inst.s_axis_a_tvalid) dissue=cycle;
   #1;
   if(solver.pipeline_inst.fma_inst.m_axis_result_tvalid) begin
     if(cycle-fissue+1!=16) $fatal(1,"frontend actual FMA latency mismatch");
     fresults++;
   end
   if(solver.pipeline_inst.div_inst.m_axis_result_tvalid) begin
     if(cycle-dissue+1!=28) $fatal(1,"frontend actual DIV latency mismatch");
     dresults++;
   end
 end
 logic [31:0] observed_boot_voltage;
 integer frames=0;
 always @(negedge vsync) begin
  frames++;
  #1;
  $display("FRONTEND_STATE frame=%0d time=%0t snapshot=%04x reply=%04x valid=%0b nodes=%0d status=%02x stage=%0b stage_frame=%04x stage_nodes=%0d stale=%0d solver_state=%0d pipeline_state=%0d solver_busy=%0b solver_done=%0b fp_exception=%0b mouse=%0d/%0d/%0b toolbar=%0d",
    frames,$time,front.frontend_snapshot_frame,front.frontend_reply_frame,
    front.frontend_reply_valid,front.frontend_reply_node_count,front.frontend_reply_status,
    front.frontend_reply_stage_active,front.frontend_reply_stage_frame,
    front.frontend_reply_stage_received_count,front.frontend_reply_stale_count,
    solver.state,solver.pipeline_inst.state,solver.solver_busy,solver.solver_done,
    solver.pipeline_inst.fp_exception,front.mouse_xpos_pix,front.mouse_ypos_pix,
    front.mouse_left_pix,front.selected_toolbar_idx);
 end
 function automatic [31:0] voltage(input integer node=0);
  voltage=front.frontend_reply_active_bank ? front.frontend_reply_ram1_inst.mem[node] : front.frontend_reply_ram0_inst.mem[node];
 endfunction
 task automatic mouse(input integer x,y,input bit left);
  @(negedge vsync); #320000;
  front.mouse_ctrl_inst.xpos=x; front.mouse_ctrl_inst.ypos=y; front.mouse_ctrl_inst.left=left;
  $display("FRONTEND_STIMULUS frame=%0d time=%0t mouse=%0d/%0d/%0b",frames,$time,x,y,left);
 endtask
 initial begin
  repeat(40) @(negedge clk); reset=0; switches=16'h0020;
  wait(front.frontend_reply_valid);
  @(negedge clk);
  if(front.frontend_snapshot_frame!=1 || front.frontend_reply_frame!=1 || front.frontend_reply_node_count!=1 || front.frontend_reply_status!=0)
   $fatal(1,"frontend boot reply metadata mismatch");
  observed_boot_voltage=voltage();
  if($test$plusargs("CORRUPT_FRONTEND")) observed_boot_voltage=observed_boot_voltage^32'h1;
  if(observed_boot_voltage!=32'h41200000)
   $fatal(1,"frontend boot voltage mismatch got=%08x",observed_boot_voltage);
  $display("FRONTEND boot accepted frame=%0d voltage=%08x",frames,voltage());
  // An accepted duplicate response must still produce the same immutable voltage.
  wait(!front.frontend_reply_valid || solver.state==0);
  repeat(2) @(negedge vsync);
  if(voltage()!=32'h41200000 || front.frontend_reply_frame!=1 || front.frontend_reply_status!=0)
   $fatal(1,"frontend repeat reply mismatch");
  $display("FRONTEND duplicate stable frame=%0d voltage=%08x",frames,voltage());
  // Accepted M3 split-rail edit, driven through the frontend mouse outputs.
  // Source still fixes node0 at10V; isolated lower resistor fixes node1 at0V.
  mouse(32,318,0); mouse(32,318,1); mouse(32,318,0);
  mouse(240,240,0); mouse(240,240,1); mouse(240,240,0);
  wait(front.frontend_reply_valid && front.frontend_reply_frame==2 && front.frontend_reply_node_count==2);
  @(negedge clk);
  if(front.frontend_snapshot_frame!=2 || front.frontend_reply_status!=0 || voltage(0)!=32'h41200000 || voltage(1)!=0)
   $fatal(1,"frontend edited voltage mismatch node0=%08x node1=%08x",voltage(0),voltage(1));
  $display("FRONTEND split rail accepted frame=%0d voltages=%08x/%08x",frames,voltage(0),voltage(1));
  $display("ACTUAL_FP frontend fma_results=%0d div_results=%0d baud=115200",fresults,dresults);
  if(fresults==0 || dresults==0) $fatal(1,"actual frontend FP operations absent");
  $display("M5SolverFrontendXsim passed."); $finish;
 end
 initial begin
   #2000;
   if($isunknown(front.vga_ctrl_inst.h_count_reg) || $isunknown(front.vga_ctrl_inst.v_count_reg))
     $fatal(1,"frontend explicit SW15 reset failed to initialize VGA counters");
 end
 initial begin #500000000; $fatal(1,"frontend-solver wall-clock simulation watchdog"); end
 initial begin repeat(24) @(negedge vsync); $fatal(1,"frontend-solver loop timeout"); end
endmodule
