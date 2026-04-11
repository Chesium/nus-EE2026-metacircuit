`timescale 1ns / 1ps

module MouseCtl (
    input  wire        clk,
    input  wire        rst,
    output reg  [11:0] xpos = 12'd0,
    output reg  [11:0] ypos = 12'd0,
    output reg  [3:0]  zpos = 4'd0,
    output reg         left = 1'b0,
    output reg         middle = 1'b0,
    output reg         right = 1'b0,
    output reg         new_event = 1'b0,
    input  wire [11:0] value,
    input  wire        setx,
    input  wire        sety,
    input  wire        setmax_x,
    input  wire        setmax_y,
    inout              ps2_clk,
    inout              ps2_data
);
  assign ps2_clk = 1'bz;
  assign ps2_data = 1'bz;
  always @(posedge clk) begin
    new_event <= 1'b0;
    if (rst) begin
      xpos <= 12'd0;
      ypos <= 12'd0;
      zpos <= 4'd0;
      left <= 1'b0;
      middle <= 1'b0;
      right <= 1'b0;
    end else begin
      if (setx || setmax_x) xpos <= value;
      if (sety || setmax_y) ypos <= value;
    end
  end
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

module GlobalRenderNetlistProbe_test;
  reg CLK100MHZ = 1'b0;
  always #5 CLK100MHZ = ~CLK100MHZ;

  reg [15:0] SW = 16'h0020; // SW[5] enables UART netlist debug / extractor path
  wire [15:0] LED;
  wire [7:0] SEG;
  wire [3:0] AN;
  reg BTNC = 1'b0;
  reg BTNU = 1'b0;
  reg BTNL = 1'b0;
  reg BTNR = 1'b0;
  reg BTND = 1'b0;
  wire [7:0] JC;
  wire [3:0] VGARED;
  wire [3:0] VGABLUE;
  wire [3:0] VGAGREEN;
  wire HSYNC;
  wire VSYNC;
  reg RsRx = 1'b1;
  tri PS2CLK;
  tri PS2DATA;
  wire RsTx;

  integer cycle_count;
  integer node0_write_count;
  integer node1_write_count;

  GlobalRender_top dut (
      .CLK100MHZ(CLK100MHZ),
      .SW(SW),
      .LED(LED),
      .SEG(SEG),
      .AN(AN),
      .BTNC(BTNC),
      .BTNU(BTNU),
      .BTNL(BTNL),
      .BTNR(BTNR),
      .BTND(BTND),
      .JC(JC),
      .VGARED(VGARED),
      .VGABLUE(VGABLUE),
      .VGAGREEN(VGAGREEN),
      .HSYNC(HSYNC),
      .VSYNC(VSYNC),
      .RsRx(RsRx),
      .RsTx(RsTx),
      .PS2CLK(PS2CLK),
      .PS2DATA(PS2DATA)
  );

  task automatic pulse_frame_tick;
    begin
      force dut.interaction_frame_sync2 = 1'b0;
      force dut.interaction_frame_sync1 = 1'b1;
      #1;
      release dut.interaction_frame_sync1;
      release dut.interaction_frame_sync2;
    end
  endtask

  always @(posedge CLK100MHZ) begin
    if (dut.netlist_extract_fetch_type_done) begin
      $display("fetchType idx=%0d -> %0d t=%0t",
               dut.netlist_extract_fetch_type_idx,
               dut.netlist_extract_fetch_type_result,
               $time);
    end
    if (dut.netlist_extract_fetch_x_done) begin
      $display("fetchX idx=%0d -> %0d t=%0t",
               dut.netlist_extract_fetch_x_idx,
               dut.netlist_extract_fetch_x_result,
               $time);
    end
    if (dut.netlist_extract_fetch_y_done) begin
      $display("fetchY idx=%0d -> %0d t=%0t",
               dut.netlist_extract_fetch_y_idx,
               dut.netlist_extract_fetch_y_result,
               $time);
    end
    if (dut.netlist_extract_fetch_rot_done) begin
      $display("fetchRot idx=%0d -> %0d t=%0t",
               dut.netlist_extract_fetch_rot_idx,
               dut.netlist_extract_fetch_rot_result,
               $time);
    end
    if (dut.netlist_extract_fetchR_done) begin
      $display("fetchR (%0d,%0d) -> %0d t=%0t",
               dut.netlist_extract_fetchR_i,
               dut.netlist_extract_fetchR_j,
               dut.netlist_extract_fetchR_result,
               $time);
    end
    if (dut.netlist_extract_storeNode0_start) begin
      node0_write_count <= node0_write_count + 1;
      $display("storeNode0 idx=%0d node=%0d t=%0t",
               dut.netlist_extract_storeNode0_idx,
               dut.netlist_extract_storeNode0_node_i,
               $time);
    end
    if (dut.netlist_extract_storeNode1_start) begin
      node1_write_count <= node1_write_count + 1;
      $display("storeNode1 idx=%0d node=%0d t=%0t",
               dut.netlist_extract_storeNode1_idx,
               dut.netlist_extract_storeNode1_node_i,
               $time);
    end
  end

  initial begin
    cycle_count = 0;
    node0_write_count = 0;
    node1_write_count = 0;

    while (dut.init_cycles < dut.INIT_DELAY_CYCLES && cycle_count < 5000) begin
      @(posedge CLK100MHZ);
      cycle_count = cycle_count + 1;
    end

    if (dut.init_cycles < dut.INIT_DELAY_CYCLES) begin
      $fatal(1, "Initialization did not complete");
    end

    @(negedge CLK100MHZ);
    pulse_frame_tick();

    cycle_count = 0;
    while (dut.flood_colors_ready !== 1'b1 && cycle_count < 50000) begin
      @(posedge CLK100MHZ);
      cycle_count = cycle_count + 1;
    end

    if (dut.flood_colors_ready !== 1'b1) begin
      $fatal(1, "Flood color apply did not complete");
    end

    cycle_count = 0;
    while (dut.netlist_extract_done !== 1'b1 && cycle_count < 250000) begin
      @(posedge CLK100MHZ);
      cycle_count = cycle_count + 1;
    end

    if (dut.netlist_extract_done !== 1'b1) begin
      $fatal(1, "Netlist extraction did not complete");
    end

    repeat (4) @(posedge CLK100MHZ);

    $display("component_store_count=%0d", dut.component_store_count);
    $display("component store entries:");
    $display("cmp0 raw=%h", dut.component_store_ram_inst.mem[0]);
    $display("cmp1 raw=%h", dut.component_store_ram_inst.mem[1]);
    $display("cmp2 raw=%h", dut.component_store_ram_inst.mem[2]);
    $display("node writes: node0=%0d node1=%0d", node0_write_count, node1_write_count);
    $display("node RAM contents:");
    $display("cmp0: n0=%0d n1=%0d", dut.netlist_node0_ram_inst.mem[0], dut.netlist_node1_ram_inst.mem[0]);
    $display("cmp1: n0=%0d n1=%0d", dut.netlist_node0_ram_inst.mem[1], dut.netlist_node1_ram_inst.mem[1]);
    $display("cmp2: n0=%0d n1=%0d", dut.netlist_node0_ram_inst.mem[2], dut.netlist_node1_ram_inst.mem[2]);

    $finish;
  end
endmodule
