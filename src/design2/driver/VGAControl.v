`timescale 1ns / 1ps

module VGAControl (
    input wire clk_pixel,  // 25.175Hz for 640x480@60
    input wire reset,
    input wire [11:0] rgb,
    output wire hsync,
    output wire vsync,
    output wire video_on,
    output reg [11:0] h_count_reg,  // Horizontal pixel counter (current pixel X-coordinate)
    output reg [11:0] v_count_reg,  // Vertical line counter (current pixel Y-coordinate)
    output reg [3:0] vgaRed,
    output reg [3:0] vgaGreen,
    output reg [3:0] vgaBlue
);

  parameter integer HD = 640;  // Horizontal Display (Active Pixels)
  parameter integer HF = 16;  // Horizontal Front Porch
  parameter integer HR = 96;  // Horizontal Sync Pulse
  parameter integer HB = 48;  // Horizontal Back Porch
  parameter integer HMAX = HD + HF + HB + HR;  // Total Horizontal Pixels (Horizontal Line Length)

  parameter integer VD = 480;  // Vertical Display (Active Lines)
  parameter integer VF = 11;  // Vertical Front Porch
  parameter integer VR = 2;  // Vertical Sync Pulse
  parameter integer VB = 31;  // Vertical Back Porch
  parameter integer VMAX = VD + VF + VB + VR;  // Total Vertical Lines (Frame Height)

  /* -BEGIN- Combinational Assignments for VGA Sync and Video_on -BEGIN- */

  // Generates hsync pulse when h_count_reg is within HR range
  assign hsync     = ~((h_count_reg >= (HD + HF)) && (h_count_reg < (HD + HF + HR)));
  // Generates vsync pulse when v_count_reg is within VR range
  assign vsync     = ~((v_count_reg >= (VD + VF)) && (v_count_reg < (VD + VF + VR)));
  // video_on is high when h_count_reg and v_count_reg are within active display area
  assign video_on  = (h_count_reg < HD) && (v_count_reg < VD);

  /* -END- Combinational Assignments for VGA Sync and Video_on -END- */

  /* -BEGIN- Pixel Counter Logic -BEGIN- */
  // Horizontal Counter (self-increment by one for every pixel cycle, resets at HMAX)
  always @(posedge clk_pixel or posedge reset) begin
    if (reset) h_count_reg <= 0;
    else if (h_count_reg == HMAX) h_count_reg <= 0;
    else h_count_reg <= h_count_reg + 1;
  end

  // --- Vertical Counter Logic ---
  // Increments vertical line counter when horizontal counter resets, resets at VMAX
  always @(posedge clk_pixel or posedge reset) begin
    if (reset) v_count_reg <= 0;
    else if (h_count_reg == HMAX) begin
      // Increment vertical counter at the end of each horizontal line
      if (v_count_reg == VMAX) v_count_reg <= 0;
      else v_count_reg <= v_count_reg + 1;
    end
  end
  /* -END- Pixel Counter Logic -END- */

  /* -BEGIN- VGA Color Signal Generation -BEGIN- */
  // Determines pixel color based on video_on status and selected pattern (switches)
  always @(posedge clk_pixel or posedge reset) begin
    if (reset || !video_on) begin  // RESET, or Outside active display area, always black
      /* BLACK */
      vgaRed   <= 4'b0000;
      vgaGreen <= 4'b0000;
      vgaBlue  <= 4'b0000;
    end else begin
      vgaRed   <= rgb[11:8];
      vgaGreen <= rgb[7:4];
      vgaBlue  <= rgb[3:0];
    end
  end
  /* -END- VGA Color Signal Generation -END- */
endmodule
