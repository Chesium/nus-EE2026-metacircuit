`timescale 1ns / 1ps

module CircuitCanvas_top (
    input  wire        CLK100MHZ,
    input  wire [15:0] SW,
    output wire [15:0] LED,
    output wire [ 7:0] SEG,
    output wire [ 3:0] AN,
    input  wire        BTNC,
    input  wire        BTNU,
    input  wire        BTNL,
    input  wire        BTNR,
    input  wire        BTND,
    output wire [ 7:0] JC,
    output wire [ 3:0] VGARED,
    output wire [ 3:0] VGABLUE,
    output wire [ 3:0] VGAGREEN,
    output wire        HSYNC,
    output wire        VSYNC,
    inout              PS2CLK,
    inout              PS2DATA
);

  assign LED = 16'b1111_1111_1111_1111;
  assign SEG = 8'b0000_0000;
  assign AN  = 4'b0000;
  assign JC  = 8'b0000_0000;

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
      .reset(BTNC),
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
      .rst      (BTNC),
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

  reg circuit_canvas_ram_w_en = 0;
  reg [7:0] circuit_canvas_ram_w_addr = 0;
  wire [7:0] circuit_canvas_ram_r_addr;
  reg [15:0] circuit_canvas_ram_w_data = 0;
  wire [15:0] circuit_canvas_ram_r_data;

  wire [11:0] circuit_canvas_rgb;
  wire circuit_canvas_rendered;

  SimpleRam #(
      .WordWidth(16),
      .WordCount(256)  // 16*16 => addr:8bit
  ) circuit_canvas_ram_inst (
      .clk(CLK100MHZ),
      .w_en(circuit_canvas_ram_w_en),
      .w_addr(circuit_canvas_ram_w_addr),
      .r_addr(circuit_canvas_ram_r_addr),
      .d_in(circuit_canvas_ram_w_data),
      .d_out(circuit_canvas_ram_r_data)
  );

  CircuitCanvas circuit_canvas_inst (
      .clk_pixel(clk_pixel),
      .x_pos(x_pos),
      .y_pos(y_pos),
      .rgb(circuit_canvas_rgb),
      .rendered(circuit_canvas_rendered),
      .data_addr(circuit_canvas_ram_r_addr),
      .incoming_data(circuit_canvas_ram_r_data),
      .display_grid(1'b1),
      .mouse_x_pos(mouse_xpos),
      .mouse_y_pos(mouse_ypos),
      .mouse_left_click(mouse_left)
  );

  reg [31:0] init_cycles = 0;

  always @(posedge CLK100MHZ) begin
    mouse_set_value <= 12'h000;
    mouse_set_max_x <= 1'b0;
    mouse_set_max_y <= 1'b0;

    circuit_canvas_ram_w_en <= 0;  // default 0

    if (init_cycles < 1000) begin
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

    // reset RAM
    if (init_cycles < 256) begin
      circuit_canvas_ram_w_en   <= 1;
      circuit_canvas_ram_w_addr <= init_cycles;
      circuit_canvas_ram_w_data <= 16'd0;
    end
    // load data
    if (init_cycles == 256 + 0) begin
      // at [1,1] (index = 17), place an elbow with rotation 1
      circuit_canvas_ram_w_en   <= 1;
      circuit_canvas_ram_w_addr <= 17;
      circuit_canvas_ram_w_data <= 16'b0000000_10_000001_1;
    end
    if (init_cycles == 256 + 1) begin
      circuit_canvas_ram_w_en   <= 1;
      circuit_canvas_ram_w_addr <= 18;
      circuit_canvas_ram_w_data <= 16'b0000000_00_000101_1;
    end
    if (init_cycles == 256 + 2) begin
      circuit_canvas_ram_w_en   <= 1;
      circuit_canvas_ram_w_addr <= 19;
      circuit_canvas_ram_w_data <= 16'b0000000_00_000110_1;
    end
    if (init_cycles == 256 + 3) begin
      circuit_canvas_ram_w_en   <= 1;
      circuit_canvas_ram_w_addr <= 33;
      circuit_canvas_ram_w_data <= 16'b0000000_11_001000_1;
    end
    if (init_cycles == 256 + 4) begin
      circuit_canvas_ram_w_en   <= 1;
      circuit_canvas_ram_w_addr <= 49;
      circuit_canvas_ram_w_data <= 16'b0000000_11_000111_1;
    end

    if (init_cycles == 256 + 5) begin
      circuit_canvas_ram_w_en   <= 1;
      circuit_canvas_ram_w_addr <= 82;
      circuit_canvas_ram_w_data <= 16'b0000000_00_000010_1;
    end
    if (init_cycles == 256 + 6) begin
      circuit_canvas_ram_w_en   <= 1;
      circuit_canvas_ram_w_addr <= 84;
      circuit_canvas_ram_w_data <= 16'b0000000_01_000010_1;
    end
    if (init_cycles == 256 + 7) begin
      circuit_canvas_ram_w_en   <= 1;
      circuit_canvas_ram_w_addr <= 86;
      circuit_canvas_ram_w_data <= 16'b0000000_10_000010_1;
    end
    if (init_cycles == 256 + 8) begin
      circuit_canvas_ram_w_en   <= 1;
      circuit_canvas_ram_w_addr <= 88;
      circuit_canvas_ram_w_data <= 16'b0000000_11_000010_1;
    end
  end
wire text_rendered;
wire [11:0] text_rgb = 12'b0110_1100_1111; // 文本输出的颜色

TextBox #(
    .TEXT_CONTENT("METACIRCUIT v0.0"), .TEXT_LEN (16)
) u_textbox (
    .clk_pixel (clk_pixel),
    .hcount (x_pos),
    .vcount (y_pos), 
    .start_x (12'd192),
    .start_y (12'd5),
    .scale (4'd2),
    .text_enable (text_rendered),
    .text_color (text_rgb)
);
// ==============================================================================
// 动态定点数 (Q8.8) 测试逻辑
// ==============================================================================

// 1. 信号定义
wire text_rendered_val;
wire signed [15:0] dynamic_value_q8_8; // Q8.8 格式：[15:8]整数，[7:0]小数

// 2. 生成缓慢变化的计数器 (用于模拟小数部分)
// 使用 32 位计数器，取最高 8 位 [31:24]
// 变化频率 ≈ 100MHz / 2^24 ≈ 5.96 Hz (每秒变化约 6 次，肉眼清晰可见)
reg [31:0] slow_counter;
always @(posedge CLK100MHZ) begin
    slow_counter <= slow_counter + 1'b1;
end

// 提取小数部分 (8 位)
wire [7:0] fractional_part = slow_counter[31:24]; 

// 3. 构造 Q8.8 定点数
// 逻辑：(鼠标 X 低 8 位 << 8) + 小数部分
// 效果：整数部分随鼠标移动，小数部分自动滚动。当小数从 .99 变回 .00 时，整数会自动 +1 (进位测试)
assign dynamic_value_q8_8 = ({mouse_xpos[7:0], 8'd0}) + {8'd0, fractional_part};

// 4. 例化动态文本显示模块
// 显示内容示例：鼠标在 123，小数在 0.45 -> 显示 "123.45"
DynamicTextDisplay #(
    .TOTAL_BITS   (16),       // 输入总位宽 16
    .FRAC_BITS    (8),        // 【关键】小数位数设为 8 (匹配 Q8.8)
    .MAX_DIGITS   (7),        // 最大长度 "255.99" = 6 或 7 (含负号)
    .CHAR_W_BASE  (8),
    .CHAR_H_BASE  (8)
) u_dynamic_text (
    .clk_pixel       (clk_pixel),
    .hcount          (x_pos),
    .vcount          (y_pos),
    
    .value_in        (dynamic_value_q8_8), // 输入构造好的 Q8.8 数据
    .start_x         (12'd192),             // X 起始位置 (已预留偏移补偿)
    .start_y         (12'd26),            // Y 起始位置
    .scale           (4'd1),               // 放大倍率
    
    .show_leading_zero (1'b1),             // 显示前导零 (如 005.20)
    
    .text_enable     (text_rendered_val),
    .text_color      (text_rgb_val)
);

  /* -BEGIN- VGA Color Signal Generation -BEGIN- */
  // Determines pixel color based on video_on status and selected pattern (switches)
  always @(posedge clk_pixel) begin
    if (!video_on) begin  // RESET, or Outside active display area, always black
      rgb <= Black;
    end else begin
      if (text_rendered) begin
        rgb <= text_rgb;
      end
      else if (text_rendered_val) begin
        rgb <= text_rgb;
      end
      else if (mouse_display_enable) begin
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
          if (circuit_canvas_rendered) rgb <= circuit_canvas_rgb;
          else rgb <= Pink;
        end
      end
    end
  end
  /* -END- VGA Color Signal Generation -END- */

endmodule
