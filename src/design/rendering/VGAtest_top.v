`timescale 1ns / 1ps

module VGAtest_top (
    input  wire        CLK100MHZ,
    input  wire [15:0] SW,
    input  wire        BTNU,
    input  wire        BTND,
    input  wire        BTNR,
    input  wire        BTNL,
    output wire        HSYNC,
    output wire        VSYNC,
    inout              PS2CLK,
    inout              PS2DATA,
    output wire [ 3:0] VGARED,
    output wire [ 3:0] VGAGREEN,
    output wire [ 3:0] VGABLUE
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

  wire [11:0] mouse_xpos;
  wire [11:0] mouse_ypos;
  wire [ 3:0] mouse_zpos;
  wire        mouse_left;
  wire        mouse_middle;
  wire        mouse_right;
  wire        mouse_new_event;
  reg  [11:0] mouse_set_value;
  reg         mouse_set_max_x;
  reg         mouse_set_max_y;

  MouseCtl mouse_ctrl_inst (
      .clk      (CLK100MHZ),
      .rst      (0),
      .xpos     (mouse_xpos),       // OUT
      .ypos     (mouse_ypos),       // OUT
      .zpos     (mouse_zpos),       // OUT
      .left     (mouse_left),       // OUT
      .middle   (mouse_middle),     // OUT
      .right    (mouse_right),      // OUT
      .new_event(mouse_new_event),  // OUT
      .value    (mouse_set_value),
      .setx     (1'b0),
      .sety     (1'b0),
      .setmax_x (mouse_set_max_x),
      .setmax_y (mouse_set_max_y),
      .ps2_clk  (PS2CLK),
      .ps2_data (PS2DATA)
  );

  reg [7:0] init_cycles = 0;

  always @(posedge CLK100MHZ) begin
    mouse_set_value <= 12'h000;
    mouse_set_max_x <= 1'b0;
    mouse_set_max_y <= 1'b0;

    if (init_cycles < 10) begin
      init_cycles <= init_cycles + 1;
    end
    if (init_cycles == 1) begin
      mouse_set_max_x <= 1'b1;
      mouse_set_value <= 639;
    end
    if (init_cycles == 2) begin
      mouse_set_max_y <= 1'b1;
      mouse_set_value <= 479;
    end
  end

  wire mouse_display_enable;
  wire [3:0] mouse_r;
  wire [3:0] mouse_g;
  wire [3:0] mouse_b;
  wire [11:0] mouse_rgb;
  assign mouse_rgb = {mouse_r, mouse_g, mouse_b};

  MouseDisplay mouse_disp_inst (
      .pixel_clk               (clk_pixel),
      .xpos                    (mouse_xpos),
      .ypos                    (mouse_ypos),
      .hcount                  (x_pos),
      .vcount                  (y_pos),
      .enable_mouse_display_out(mouse_display_enable),
      .red_out                 (mouse_r),
      .green_out               (mouse_g),
      .blue_out                (mouse_b)
  );

  /* -BEGIN- VGA Color Signal Generation -BEGIN- */
  // Determines pixel color based on video_on status and selected pattern (switches)
  always @(posedge clk_pixel) begin
    if (!video_on) begin  // RESET, or Outside active display area, always black
      rgb <= Black;
    end else begin
      if (mouse_display_enable) begin
        rgb <= mouse_rgb;
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
  end
  /* -END- VGA Color Signal Generation -END- */

endmodule
