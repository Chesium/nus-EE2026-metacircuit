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

module Oled_Display (
    input wire clk,
    input wire reset,
    input wire frame_begin,
    input wire sending_pixels,
    input wire sample_pixel,
    input wire [12:0] pixel_index,
    input wire [15:0] pixel_data,
    output wire [7:0] oled_pmod
);
  assign oled_pmod = 8'h00;
endmodule

module GlobalRenderFrontendUartProbe_test;
  localparam integer MAX_LINE_BYTES = 48;

  reg CLK100MHZ = 1'b0;
  always #5 CLK100MHZ = ~CLK100MHZ;

  reg [15:0] SW = 16'h0020;
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

  wire [7:0] rx_byte;
  wire rx_byte_valid;
  wire line_valid;
  wire line_overflow;
  wire [7:0] line_len;
  wire [MAX_LINE_BYTES*8-1:0] line_data;

  integer cycle_count;
  integer line_count;
  integer idx;
  reg [8*MAX_LINE_BYTES-1:0] line_text;
  reg [3:0] last_tx_state;
  reg last_component_entry_toggle;
  reg last_snapshot_ready;

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

  UartRx uart_rx_inst (
      .clk(CLK100MHZ),
      .rst_n(~BTNC),
      .rx(RsTx),
      .data(rx_byte),
      .data_valid(rx_byte_valid)
  );

  UartLineAssembler #(
      .MAX_LINE_BYTES(MAX_LINE_BYTES)
  ) line_assembler_inst (
      .clk(CLK100MHZ),
      .rst_n(~BTNC),
      .byte_valid(rx_byte_valid),
      .byte_data(rx_byte),
      .line_valid(line_valid),
      .line_overflow(line_overflow),
      .line_len(line_len),
      .line_data(line_data)
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
    if (dut.netlist_tx_state != last_tx_state) begin
      $display("[%0t] tx_state %0d -> %0d (snapshot_ready=%0d frame_pending=%0d read_pending=%0d read_busy=%0d err=%h arg=%h)",
          $time, last_tx_state, dut.netlist_tx_state, dut.netlist_snapshot_ready, dut.netlist_frame_pending,
          dut.netlist_component_read_pending, dut.component_store_read_busy, dut.netlist_error_code, dut.netlist_error_arg);
      last_tx_state <= dut.netlist_tx_state;
    end
    if (dut.netlist_component_entry_toggle != last_component_entry_toggle) begin
      $display("[%0t] component entry snap idx=%0d type=%h unit=%h n0=%h n1=%h",
          $time, dut.netlist_dump_idx, dut.netlist_component_entry_snap[26:23],
          dut.netlist_component_entry_snap[39:36], dut.netlist_component_node0_snap, dut.netlist_component_node1_snap);
      last_component_entry_toggle <= dut.netlist_component_entry_toggle;
    end
    if (dut.frontend_tx_start) begin
      $display("[%0t] frontend_tx_start mode=%0d frame=%h elem=%h node=%h idx=%h kind=%h n0=%h n1=%h val=%h unit=%h err=%h/%h",
          $time, dut.frontend_tx_mode, dut.frontend_tx_frame, dut.frontend_tx_elem_count,
          dut.frontend_tx_node_count, dut.frontend_tx_component_idx, dut.frontend_tx_component_kind,
          dut.frontend_tx_component_n0, dut.frontend_tx_component_n1, dut.frontend_tx_component_value_bcd,
          dut.frontend_tx_component_unit, dut.frontend_tx_error_code, dut.frontend_tx_error_arg);
    end
    if (dut.netlist_snapshot_ready != last_snapshot_ready) begin
      $display("[%0t] snapshot_ready -> %0d", $time, dut.netlist_snapshot_ready);
      last_snapshot_ready <= dut.netlist_snapshot_ready;
    end
    if (line_valid) begin
      line_text = {MAX_LINE_BYTES{8'h00}};
      for (idx = 0; idx < MAX_LINE_BYTES; idx = idx + 1) begin
        if (idx < line_len) begin
          line_text[((MAX_LINE_BYTES-1-idx)*8) +: 8] = line_data[(idx*8) +: 8];
        end
      end
      line_count = line_count + 1;
      $display("UART line %0d: %0s", line_count, line_text);
    end
  end

  initial begin
    cycle_count = 0;
    line_count = 0;
    last_tx_state = 4'hF;
    last_component_entry_toggle = 1'b0;
    last_snapshot_ready = 1'b0;

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
    while (dut.flood_colors_ready !== 1'b1 && cycle_count < 500000) begin
      @(posedge CLK100MHZ);
      cycle_count = cycle_count + 1;
    end

    if (dut.flood_colors_ready !== 1'b1) begin
      $display("Timeout waiting for flood color apply.");
      $display("  interaction_frame_tick=%0d vsync_edge=%0d flood_run_pending=%0d flood_start=%0d flood_done=%0d",
          dut.interaction_frame_tick, dut.vsync_edge, dut.flood_run_pending,
          dut.flood_wrapper_start, dut.flood_wrapper_done);
      $display("  flood_ready=%0d flood_colors_ready=%0d flood_busy=%0d color_apply=%0d/%0d",
          dut.flood_results_ready, dut.flood_colors_ready, dut.flood_wrapper_busy,
          dut.flood_color_apply_active, dut.flood_color_apply_fetch_busy);
      $fatal(1, "Flood color apply did not complete");
    end

    @(negedge CLK100MHZ);
    pulse_frame_tick();

    cycle_count = 0;
    while (line_count < 5 && cycle_count < 4000000) begin
      @(posedge CLK100MHZ);
      cycle_count = cycle_count + 1;
    end

    if (line_count == 0) begin
      $display("Timeout with no UART lines.");
      $display("  tx_state=%0d snapshot_ready=%0d frame_pending=%0d extract_busy=%0d extract_done=%0d",
          dut.netlist_tx_state, dut.netlist_snapshot_ready, dut.netlist_frame_pending,
          dut.netlist_extract_busy, dut.netlist_extract_done);
      $display("  interaction_frame_tick=%0d vsync_edge=%0d flood_run_pending=%0d flood_start=%0d flood_done=%0d",
          dut.interaction_frame_tick, dut.vsync_edge, dut.flood_run_pending,
          dut.flood_wrapper_start, dut.flood_wrapper_done);
      $display("  flood_ready=%0d flood_colors_ready=%0d flood_busy=%0d color_apply=%0d/%0d",
          dut.flood_results_ready, dut.flood_colors_ready, dut.flood_wrapper_busy,
          dut.flood_color_apply_active, dut.flood_color_apply_fetch_busy);
      $display("  component_store_count=%0d read_pending=%0d read_busy=%0d dump_idx=%0d dump_count=%0d",
          dut.component_store_count, dut.netlist_component_read_pending, dut.component_store_read_busy,
          dut.netlist_dump_idx, dut.netlist_dump_count);
      $display("  tx_busy=%0d tx_start=%0d tx_done=%0d error_code=%h error_arg=%h protocol_nodes=%0d",
          dut.frontend_tx_busy, dut.frontend_tx_start, dut.frontend_tx_done,
          dut.netlist_error_code, dut.netlist_error_arg, dut.netlist_protocol_node_count);
      $display("  node_mem: [0]=%h/%h [1]=%h/%h [2]=%h/%h",
          dut.netlist_node0_ram_inst.mem[0], dut.netlist_node1_ram_inst.mem[0],
          dut.netlist_node0_ram_inst.mem[1], dut.netlist_node1_ram_inst.mem[1],
          dut.netlist_node0_ram_inst.mem[2], dut.netlist_node1_ram_inst.mem[2]);
      $fatal(1, "No UART output observed");
    end

    $display("GlobalRenderFrontendUartProbe_test captured %0d UART lines.", line_count);
    $display("  final node_mem: [0]=%h/%h [1]=%h/%h [2]=%h/%h",
        dut.netlist_node0_ram_inst.mem[0], dut.netlist_node1_ram_inst.mem[0],
        dut.netlist_node0_ram_inst.mem[1], dut.netlist_node1_ram_inst.mem[1],
        dut.netlist_node0_ram_inst.mem[2], dut.netlist_node1_ram_inst.mem[2]);
    $finish;
  end
endmodule
