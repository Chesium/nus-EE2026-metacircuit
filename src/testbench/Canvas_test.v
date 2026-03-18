`timescale 1ns / 1ps

module Canvas_test ();

  reg clk_t_100m = 0;
  always #5 clk_t_100m = ~clk_t_100m;  // 10ns => 100MHz

  reg  [15:0] i_sw = 16'b0000_0000_0000_0000;
  wire [15:0] o_led;
  wire [ 7:0] o_seg;
  wire [ 3:0] o_an;
  reg i_btnc, i_btnu = 1'b0, i_btnl = 1'b0, i_btnr = 1'b0, i_btnd = 1'b0;
  wire [7:0] o_jc;
  wire [3:0] o_vga_r;
  wire [3:0] o_vga_b;
  wire [3:0] o_vga_g;
  wire o_vga_hsync;
  wire o_vga_vsync;
  wire io_ps2clk;
  wire io_ps2data;

  CircuitCanvas_top circuit_canvas_top_inst (
      .CLK100MHZ(clk_t_100m),
      .SW(i_sw),
      .LED(o_led),
      .SEG(o_seg),
      .AN(o_an),
      .BTNC(i_btnc),
      .BTNU(i_btnu),
      .BTNL(i_btnl),
      .BTNR(i_btnr),
      .BTND(i_btnd),
      .JC(o_jc),
      .VGARED(o_vga_r),
      .VGABLUE(o_vga_b),
      .VGAGREEN(o_vga_g),
      .HSYNC(o_vga_hsync),
      .VSYNC(o_vga_vsync),
      .PS2CLK(io_ps2clk),
      .PS2DATA(io_ps2data)
  );


  initial begin
    i_btnc = 1;
    #100
    i_btnc = 0;
    // $finish;
  end

endmodule
