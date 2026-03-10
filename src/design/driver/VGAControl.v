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
  assign hsync     = (h_count_reg >= (HD + HF) && h_count_reg <= (HD + HF + HR));
  // Generates vsync pulse when v_count_reg is within VR range
  assign vsync     = (v_count_reg >= (VD + VF) && v_count_reg <= (VD + VF + VR));
  // video_on is high when h_count_reg and v_count_reg are within active display area
  assign video_on  = (h_count_reg < HD) && (v_count_reg < VD);

  /* -END- Combinational Assignments for VGA Sync and Video_on -END- */

  wire [11:0] renderer_rgb;

  wire mouse_enable;
  wire [3:0] mouse_red, mouse_green, mouse_blue;
  wire [11:0] text_rgb;
  wire mouse_left, mouse_middle, mouse_right;

  // procedural_renderer renderer (
  //     .pix_clk(clk_pixel),
  //     .rst    (reset),        // synchronous reset
  //     .active (video_on),     // 1 when within visible region
  //     .x      (h_count_reg),
  //     .y      (v_count_reg),
  //     .rgb    (renderer_rgb)  // VGA RGB444 output
  // );

  // text_display u_text_display (
  //     .pix_clk     (clk_pixel),
  //     .rst         (reset),
  //     .video_on    (video_on),
  //     .mouse_x     (mouse_xpos),        // �������� MouseCtl �� X
  //     .mouse_y     (mouse_ypos),        // �������� MouseCtl �� Y
  //     .mouse_left  (mouse_left_btn),    // �������� MouseCtl �� ����״̬
  //     .mouse_middle(mouse_middle_btn),
  //     .mouse_right (mouse_right_btn),
  //     .h_count     (h_count_reg),
  //     .v_count     (v_count_reg),
  //     .rgb_out     (text_rgb)
  // );

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
      // // ���ȼ� 1: ������ʾ (��� text_rgb ���Ǻ�ɫ��˵��������)
      // if (text_rgb != 12'h000) begin
      //   vgaRed   <= text_rgb[11:8];
      //   vgaGreen <= text_rgb[7:4];
      //   vgaBlue  <= text_rgb[3:0];
      // end  // ���ȼ� 2: �����
      // else if (mouse_enable) begin
      //   vgaRed   <= mouse_red;
      //   vgaGreen <= mouse_green;
      //   vgaBlue  <= mouse_blue;
      // end  // ���ȼ� 3: ������Ⱦ���� (procedural_renderer)
      // else begin
      //   if (sw[0]) begin  // Pattern 1: Horizontal color bands
      //     if (h_count_reg < HD / 3) begin
      //       vgaRed   <= 4'b0000;
      //       vgaGreen <= 4'b0000;
      //       vgaBlue  <= 4'b1111;  // Blue band
      //     end else if (h_count_reg < (HD * 2) / 3) begin
      //       vgaRed   <= 4'b1111;
      //       vgaGreen <= 4'b1100;
      //       vgaBlue  <= 4'b0000;  // Yellowish-orange band
      //     end else begin
      //       vgaRed   <= 4'b1111;
      //       vgaGreen <= 4'b0000;
      //       vgaBlue  <= 4'b0000;  // Red band
      //     end
      //   end else if (sw[1]) begin  // Pattern 2: Vertical color bands
      //     if (v_count_reg < VD / 3) begin
      //       vgaRed   <= 4'b0000;
      //       vgaGreen <= 4'b0000;
      //       vgaBlue  <= 4'b0000;  // Black band
      //     end else if (v_count_reg < (VD * 2) / 3) begin
      //       vgaRed   <= 4'b1111;
      //       vgaGreen <= 4'b0000;
      //       vgaBlue  <= 4'b0000;  // Red band
      //     end else begin
      //       vgaRed   <= 4'b1111;
      //       vgaGreen <= 4'b1100;
      //       vgaBlue  <= 4'b0000;  // Yellowish-orange band
      //     end
      //   end else if(sw[2]) begin // Pattern 3: Circle with three segments or square + white background
      //     // if(dist_sq_circ <= R_SQ) begin // If pixel is inside the circle
      //     //     if(relative_h < ONE_THIRD_CIRC_WIDTH) begin
      //     //         vgaRed   <= 4'b0000;
      //     //         vgaGreen <= 4'b0000;
      //     //         vgaBlue  <= 4'b1111; // Blue segment
      //     //     end else if (relative_h < TWO_THIRDS_CIRC_WIDTH) begin
      //     //         vgaRed   <= 4'b1111;
      //     //         vgaGreen <= 4'b1100;
      //     //         vgaBlue  <= 4'b0000; // Yellowish-orange segment
      //     //     end else begin
      //     //         vgaRed   <= 4'b1111;
      //     //         vgaGreen <= 4'b0000;
      //     //         vgaBlue  <= 4'b0000; // Red segment
      //     //     end
      //     // end else if(h_count_reg >= SQUARE_X_START && h_count_reg <= SQUARE_X_END &&
      //     //              ( (v_count_reg >= SQUARE_Y_START && v_count_reg <= 600) ||
      //     //                (v_count_reg >= 850 && v_count_reg <= SQUARE_Y_END) )
      //     //             ) begin // If pixel is inside the square bars
      //     //     vgaRed   <= 4'b0110;
      //     //     vgaGreen <= 4'b1000;
      //     //     vgaBlue  <= 4'b1101; // Specific color for the square bars
      //     // end else begin
      //     // vgaRed   <= 4'b1111;
      //     // vgaGreen <= 4'b1111;
      //     // vgaBlue  <= 4'b1111; // White background
      //     if (mouse_enable) begin
      //       vgaRed   <= mouse_red;
      //       vgaGreen <= mouse_green;
      //       vgaBlue  <= mouse_blue;
      //     end else begin
      //       vgaRed   <= renderer_rgb[11:8];
      //       vgaGreen <= renderer_rgb[7:4];
      //       vgaBlue  <= renderer_rgb[3:0];
      //     end
      //     // end
      //   end else begin  // Default pattern: Solid color when no switch is active
      //     vgaRed   <= 4'b1111;
      //     vgaGreen <= 4'b0011;
      //     vgaBlue  <= 4'b1100;  // Purple/Rosy-Magenta color (as per your last request)
      //   end
      // end
    end
  end
  /* -END- VGA Color Signal Generation -END- */
endmodule
