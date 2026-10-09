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
  parameter integer VF = 10;  // Vertical Front Porch
  parameter integer VR = 2;  // Vertical Sync Pulse
  parameter integer VB = 33;  // Vertical Back Porch
  parameter integer VMAX = VD + VF + VB + VR;  // Total Vertical Lines (Frame Height)

  // Pixel clocks between h/v_count_reg and the matching `rgb` input
  // (GlobalRender_top registers rgb once). hsync/vsync are delayed to line up
  // with the colour outputs, which add one more register stage.
  parameter integer RGB_LATENCY = 1;
  localparam integer SYNC_DELAY = RGB_LATENCY + 1;

  /* -BEGIN- Combinational Assignments for VGA Sync and Video_on -BEGIN- */

  // Generates hsync pulse when h_count_reg is within HR range
  wire hsync_now = ~((h_count_reg >= (HD + HF)) && (h_count_reg < (HD + HF + HR)));
  // Generates vsync pulse when v_count_reg is within VR range
  wire vsync_now = ~((v_count_reg >= (VD + VF)) && (v_count_reg < (VD + VF + VR)));
  // video_on is high when h_count_reg and v_count_reg are within active display area
  assign video_on = (h_count_reg < HD) && (v_count_reg < VD);

  /* -END- Combinational Assignments for VGA Sync and Video_on -END- */

  /* -BEGIN- Sync / Blanking Alignment -BEGIN- */
  reg [SYNC_DELAY-1:0] hsync_pipe = {SYNC_DELAY{1'b1}};
  reg [SYNC_DELAY-1:0] vsync_pipe = {SYNC_DELAY{1'b1}};
  integer i;
  always @(posedge clk_pixel) begin
    hsync_pipe[0] <= hsync_now;
    vsync_pipe[0] <= vsync_now;
    for (i = 1; i < SYNC_DELAY; i = i + 1) begin
      hsync_pipe[i] <= hsync_pipe[i-1];
      vsync_pipe[i] <= vsync_pipe[i-1];
    end
  end
  assign hsync = hsync_pipe[SYNC_DELAY-1];
  assign vsync = vsync_pipe[SYNC_DELAY-1];

  // video_on delayed to match the `rgb` input, for blanking the colour outputs
  wire video_on_rgb;
  generate
    if (RGB_LATENCY == 0) begin : g_blank_now
      assign video_on_rgb = video_on;
    end else begin : g_blank_delayed
      reg [RGB_LATENCY-1:0] video_on_pipe = {RGB_LATENCY{1'b0}};
      integer j;
      always @(posedge clk_pixel) begin
        video_on_pipe[0] <= video_on;
        for (j = 1; j < RGB_LATENCY; j = j + 1) video_on_pipe[j] <= video_on_pipe[j-1];
      end
      assign video_on_rgb = video_on_pipe[RGB_LATENCY-1];
    end
  endgenerate
  /* -END- Sync / Blanking Alignment -END- */

  /* -BEGIN- Pixel Counter Logic -BEGIN- */
  // Horizontal Counter (self-increment by one for every pixel cycle, counts 0..HMAX-1)
  always @(posedge clk_pixel) begin
    if (reset) h_count_reg <= 0;
    else if (h_count_reg == HMAX - 1) h_count_reg <= 0;
    else h_count_reg <= h_count_reg + 1;
  end

  // --- Vertical Counter Logic ---
  // Increments vertical line counter when horizontal counter resets, counts 0..VMAX-1
  always @(posedge clk_pixel) begin
    if (reset) v_count_reg <= 0;
    else if (h_count_reg == HMAX - 1) begin
      // Increment vertical counter at the end of each horizontal line
      if (v_count_reg == VMAX - 1) v_count_reg <= 0;
      else v_count_reg <= v_count_reg + 1;
    end
  end
  /* -END- Pixel Counter Logic -END- */

  /* -BEGIN- VGA Color Signal Generation -BEGIN- */
  // Determines pixel color based on video_on status and selected pattern (switches)
  always @(posedge clk_pixel) begin
    if (reset || !video_on_rgb) begin  // RESET, or Outside active display area, always black
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
