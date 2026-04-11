`timescale 1ns / 1ps

module GlobalRenderFloodColor_test;
  reg CLK100MHZ = 1'b0;
  always #5 CLK100MHZ = ~CLK100MHZ;

  reg [15:0] SW = 16'h0000;
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

  initial begin
    cycle_count = 0;

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

    $display("BG[39]=%0d BG[40]=%0d BG[56]=%0d BG[59]=%0d BG[75]=%0d BG[76]=%0d",
             dut.circuit_canvas_bg_color_ram_inst.mem[9'd39],
             dut.circuit_canvas_bg_color_ram_inst.mem[9'd40],
             dut.circuit_canvas_bg_color_ram_inst.mem[9'd56],
             dut.circuit_canvas_bg_color_ram_inst.mem[9'd59],
             dut.circuit_canvas_bg_color_ram_inst.mem[9'd75],
             dut.circuit_canvas_bg_color_ram_inst.mem[9'd76]);

    if (dut.circuit_canvas_bg_color_ram_inst.mem[9'd39] == 4'd0 &&
        dut.circuit_canvas_bg_color_ram_inst.mem[9'd40] == 4'd0 &&
        dut.circuit_canvas_bg_color_ram_inst.mem[9'd56] == 4'd0 &&
        dut.circuit_canvas_bg_color_ram_inst.mem[9'd59] == 4'd0 &&
        dut.circuit_canvas_bg_color_ram_inst.mem[9'd75] == 4'd0 &&
        dut.circuit_canvas_bg_color_ram_inst.mem[9'd76] == 4'd0) begin
      $fatal(1, "Flood color RAM remained all-default on known wired cells");
    end

    $display("GlobalRenderFloodColor_test passed.");
    $finish;
  end
endmodule
