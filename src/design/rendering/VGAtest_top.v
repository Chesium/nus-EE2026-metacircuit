`timescale 1ns / 1ps

module VGAtest_top (
    input wire CLK100MHZ,
    input wire [15:0] SW,
    input wire BTNU,
    input wire BTND,
    input wire BTNR,
    input wire BTNL,
    output wire HSYNC,
    output wire VSYNC,
    output wire [3:0] VGARED,
    output wire [3:0] VGAGREEN,
    output wire [3:0] VGABLUE
);

  wire clk_pixel;
  wire video_on;
  reg [11:0] rgb;
  wire [11:0] x_pos;
  wire [11:0] y_pos;

  parameter integer Black = 12'b0000_0000_0000;
  parameter integer Red = 12'b1111_0000_0000;
  parameter integer Blue = 12'b0000_0000_1111;
  parameter integer Green = 12'b0000_1111_0000;
  parameter integer YellowishOrange = 12'b1111_1100_0000;
  parameter integer Pink = 12'b1111_0011_1100;

  ClockDivider #(
      .FREQ(25_000_000)
  ) clkdiv_inst_25MHz (
      .CLK100MHZ(CLK100MHZ),
      .clk_out  (clk_pixel)
  );

  VGAControl vga_ctrl_inst (
      .clk_pixel(clk_pixel),
      .reset(0),
      .rgb(rgb),
      .hsync(HSYNC),
      .vsync(VSYNC),
      .video_on(video_on),
      .h_count_reg(x_pos),
      .v_count_reg(y_pos),
      .vgaRed(VGARED),
      .vgaGreen(VGAGREEN),
      .vgaBlue(VGABLUE)
  );

  /* -BEGIN- VGA Color Signal Generation -BEGIN- */
  // Determines pixel color based on video_on status and selected pattern (switches)
  always @(posedge clk_pixel) begin
    if (!video_on) begin  // RESET, or Outside active display area, always black
      rgb <= Black;
    end else begin
      if (SW[0]) begin  // Pattern 1: Horizontal color bands
        if (x_pos < 640 / 3) begin
          rgb <= Blue;
        end else if (x_pos < (640 * 2) / 3) begin
          rgb <= YellowishOrange;
        end else begin
          rgb <= Red;
        end
      end else if (SW[1]) begin  // Pattern 2: Vertical color bands
        if (y_pos < 480 / 3) begin
          rgb <= Black;
        end else if (y_pos < (480 * 2) / 3) begin
          rgb <= Red;
        end else begin
          rgb <= YellowishOrange;
        end
      end else begin  // Default pattern: Solid color when no switch is active
        rgb <= Pink;
      end
    end
  end
  /* -END- VGA Color Signal Generation -END- */

endmodule
