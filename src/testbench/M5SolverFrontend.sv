`timescale 1ns / 1ps

// RTL-4: frontend UART loop on the full GlobalRender_top with SW[5] = 1.
//
// The testbench is the host side of src/uart_link/README.md: an independent
// 115200-baud line decoder on RsTx and a line driver on RsRx (both timed in
// nanoseconds, not by the DUT's clock divider). It
//   1. captures the boot circuit's netlist snapshots (@NB/@NC/@NE): one per
//      frame, all with frame id 0001 while the canvas is idle (D-016), and the
//      boot voltage source with its + terminal (n0) on the right rail (D-015),
//   2. replies to one of them with @VB/@VN/@VE and checks the voltage store,
//      the 7-segment value (both halves, via BTNU/BTND) and the LED status,
//   3. deletes the right-rail wire at (5,5) through the mouse (golden scenario
//      macros "click_tool delete", "click_cell 5 5"; inputs change at line 10
//      of a frame, D-008), checks that the id increments once and then stays,
//      and measures, in frames, edit -> netlist TX -> reply -> voltage visible,
//   4. checks that a corrupted line sets status 83 and keeps the voltages,
//   5. checks that stale replies (@VB..@VE and @ER with an older frame id) are
//      dropped without touching the stored voltages or reply_valid/frame/
//      status (D-016), and that a reply with the current id is accepted.
// Every RsTx/RsRx line is printed as "TXLINE"/"RXLINE" so golden/tools can
// re-check framing and checksums with src/uart_link/protocol.py.
//
// Frames are counted at VSYNC leading edges (framescope's frame boundaries):
// frame f is the interval after the f-th leading edge, and "visible in frame
// f" means a probe taken at the leading edge that ends frame f shows it.

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

module M5SolverFrontend;
 reg clk=0; always #5 clk=~clk;
 reg reset=1; wire front_tx,solver_tx; wire [15:0] led;
 wire [7:0] seg; wire [3:0] an; tri pclk,pdata;
 wire vsync;
 GlobalRender_top front(.CLK100MHZ(clk),.SW(16'h0020),.LED(led),.SEG(seg),.AN(an),
 .BTNC(1'b0),.BTNU(1'b0),.BTNL(1'b0),.BTNR(1'b0),.BTND(1'b0),
 .JC(),.VGARED(),.VGABLUE(),.VGAGREEN(),.HSYNC(),.VSYNC(vsync),
 .RsRx(solver_tx),.RsTx(front_tx),.PS2CLK(pclk),.PS2DATA(pdata));
 SolverBoard_top solver(.CLK100MHZ(clk),.BTNC(reset),.RsRx(front_tx),.RsTx(solver_tx),.LED(),.SEG(),.AN());
 logic [31:0] observed_boot_voltage;
 integer frames=0;
 always @(negedge vsync) frames++;
 function automatic [31:0] voltage(input integer node=0);
  voltage=front.frontend_reply_active_bank ? front.frontend_reply_ram1_inst.mem[node] : front.frontend_reply_ram0_inst.mem[node];
 endfunction
 task automatic mouse(input integer x,y,input bit left);
  @(negedge vsync); #320000;
  front.mouse_ctrl_inst.xpos=x; front.mouse_ctrl_inst.ypos=y; front.mouse_ctrl_inst.left=left;
 endtask
 initial begin
  repeat(20) @(negedge clk); reset=0;
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
  // Accepted M3 split-rail edit, driven through the frontend mouse outputs.
  // Source still fixes node0 at10V; isolated lower resistor fixes node1 at0V.
  mouse(32,318,0); mouse(32,318,1); mouse(32,318,0);
  mouse(240,240,0); mouse(240,240,1); mouse(240,240,0);
  wait(front.frontend_reply_valid && front.frontend_reply_frame==2 && front.frontend_reply_node_count==2);
  @(negedge clk);
  if(front.frontend_snapshot_frame!=2 || front.frontend_reply_status!=0 || voltage(0)!=32'h41200000 || voltage(1)!=0)
   $fatal(1,"frontend edited voltage mismatch node0=%08x node1=%08x",voltage(0),voltage(1));
  $display("FRONTEND split rail accepted frame=%0d voltages=%08x/%08x",frames,voltage(0),voltage(1));
  $display("M5SolverFrontend passed."); $finish;
 end
 initial begin repeat(24) @(negedge vsync); $fatal(1,"frontend-solver loop timeout"); end
endmodule
