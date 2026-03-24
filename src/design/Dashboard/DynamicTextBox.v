`timescale 1ns / 1ps
/*
 * ============================================================================
 * DynamicTextBox - 动态文本显示模块
 * ============================================================================
 * 
 * 【功能概述】
 *   与静态 TextBox 不同，此模块支持运行时动态改变文本内容。
 *   通过扁平化总线传递文本数据 (将 32 个 8 位字符拼接成 256 位总线)。
 * 
 * 【与 TextBox 的区别】
 *   TextBox:
 *     - 文本内容通过 parameter 传递 (编译时确定)
 *     - 适用于固定文本 (如标题、固定标签)
 *     - 例化：TextBox #(.TEXT_CONTENT("Hello"), .TEXT_LEN(5)) u_txt (...);
 * 
 *   DynamicTextBox:
 *     - 文本内容通过 input 端口传递 (运行时可变)
 *     - 适用于动态文本 (如数值、状态信息)
 *     - 例化：DynamicTextBox u_txt (.text_data(data_bus), .text_len(len), ...);
 * 
 * 【数据格式】
 *   text_data[MAX_CHARS * 8 - 1:0] - 扁平化文本总线
 *   - 字符 0 存储在最高位 [255:248]
 *   - 字符 1 存储在 [247:240]
 *   - ...
 *   - 字符 31 存储在最低位 [7:0]
 * 
 *   示例：显示 "Hello"
 *   text_data[255:248] = 8'H48  // 'H'
 *   text_data[247:240] = 8'He7  // 'e'
 *   text_data[239:232] = 8'H6C  // 'l'
 *   text_data[231:224] = 8'H6C  // 'l'
 *   text_data[223:216] = 8'H6F  // 'o'
 *   text_len = 5'd5
 * 
 * 【缩放倍率】
 *   scale = 4'd1 : 原始大小 8x8 像素
 *   scale = 4'd2 : 放大 2 倍 16x16 像素
 *   scale = 4'd4 : 放大 4 倍 32x32 像素
 *   scale = 4'd8 : 放大 8 倍 64x64 像素
 * 
 * 【依赖模块】
 *   FontROM : 8x8 ASCII 字库 (字符 32-126)
 * 
 * ============================================================================
 * 【例化演示 1 - 基本用法】
 * ============================================================================
 * 
 * // 1. 声明文本数据
 * reg [255:0] my_text_data;
 * reg [4:0] my_text_len;
 * 
 * // 2. 准备文本数据 (显示 "Test")
 * always @(*) begin
 *     my_text_data = 256'd0;  // 清零
 *     my_text_data[255:248] = 8'H54;  // 'T'
 *     my_text_data[247:240] = 8'He5;  // 'e'
 *     my_text_data[239:232] = 8'H73;  // 's'
 *     my_text_data[231:224] = 8'H74;  // 't'
 *     my_text_len = 5'd4;
 * end
 * 
 * // 3. 例化模块
 * DynamicTextBox #(
 *     .MAX_CHARS(32),         // 最大字符数
 *     .CHAR_W_BASE(8),        // 字符基础宽度
 *     .CHAR_H_BASE(8)         // 字符基础高度
 * ) u_dyn_text (
 *     .clk_pixel(clk_pixel),      // 像素时钟
 *     .hcount(x_pos),             // 当前像素 X 坐标
 *     .vcount(y_pos),             // 当前像素 Y 坐标
 *     .text_data(my_text_data),   // 256 位文本数据总线
 *     .text_len(my_text_len),     // 实际文本长度
 *     .start_x(12'd100),          // 起始 X 坐标
 *     .start_y(12'd50),           // 起始 Y 坐标
 *     .scale(4'd2),               // 放大 2 倍 (16x16 像素)
 *     .text_enable(text_en),      // 文本使能输出
 *     .text_color(text_rgb)       // 文本颜色输出 (12 位 444 格式)
 * );
 * 
 * ============================================================================
 * 【例化演示 2 - 动态数值显示】
 * ============================================================================
 * 
 * // 显示动态数值 (如计数器)
 * reg [255:0] counter_text;
 * reg [4:0] counter_len;
 * reg [9:0] counter_value;
 * 
 * // 数值转 ASCII
 * wire [7:0] hundreds = (counter_value / 100) + 8'd48;
 * wire [7:0] tens = ((counter_value % 100) / 10) + 8'd48;
 * wire [7:0] ones = (counter_value % 10) + 8'd48;
 * 
 * // 生成文本 "Count: XXX"
 * always @(*) begin
 *     counter_text = 256'd0;
 *     counter_text[255:248] = 8'H43;  // 'C'
 *     counter_text[247:240] = 8'HeF;  // 'o'
 *     counter_text[239:232] = 8'H75;  // 'u'
 *     counter_text[231:224] = 8'H6E;  // 'n'
 *     counter_text[223:216] = 8'H74;  // 't'
 *     counter_text[215:208] = 8'H3A;  // ':'
 *     counter_text[207:200] = 8'H20;  // ' '
 *     counter_text[199:192] = hundreds;
 *     counter_text[191:184] = tens;
 *     counter_text[183:176] = ones;
 *     counter_len = 5'd10;
 * end
 * 
 * DynamicTextBox u_counter (
 *     .clk_pixel(clk_pixel),
 *     .hcount(x_pos),
 *     .vcount(y_pos),
 *     .text_data(counter_text),
 *     .text_len(counter_len),
 *     .start_x(12'd0),
 *     .start_y(12'd100),
 *     .scale(4'd1),
 *     .text_enable(counter_en),
 *     .text_color(counter_rgb)
 * );
 * 
 * ============================================================================
 * 【例化演示 3 - 多行文本】
 * ============================================================================
 * 
 * // 三行文本显示
 * wire [255:0] line1_data, line2_data, line3_data;
 * wire [4:0] line1_len, line2_len, line3_len;
 * 
 * // 第一行 (放大 2 倍)
 * DynamicTextBox u_line1 (
 *     .clk_pixel(clk_pixel), .hcount(x_pos), .vcount(y_pos),
 *     .text_data(line1_data), .text_len(line1_len),
 *     .start_x(12'd0), .start_y(12'd0),
 *     .scale(4'd2), .text_enable(en1), .text_color(rgb1)
 * );
 * 
 * // 第二行 (原始大小)
 * DynamicTextBox u_line2 (
 *     .clk_pixel(clk_pixel), .hcount(x_pos), .vcount(y_pos),
 *     .text_data(line2_data), .text_len(line2_len),
 *     .start_x(12'd0), .start_y(12'd20),  // Y 偏移
 *     .scale(4'd1), .text_enable(en2), .text_color(rgb2)
 * );
 * 
 * // 第三行 (原始大小)
 * DynamicTextBox u_line3 (
 *     .clk_pixel(clk_pixel), .hcount(x_pos), .vcount(y_pos),
 *     .text_data(line3_data), .text_len(line3_len),
 *     .start_x(12'd0), .start_y(12'd30),  // Y 偏移
 *     .scale(4'd1), .text_enable(en3), .text_color(rgb3)
 * );
 * 
 * ============================================================================
 * 【文本数据生成技巧】
 * ============================================================================
 * 
 * // 方法 1: 直接赋值 (适合短文本)
 * text_data[255:248] = 8'H41;  // 'A'
 * text_data[247:240] = 8'H42;  // 'B'
 * 
 * // 方法 2: 使用字符串 (综合工具支持时)
 * text_data = {"AB", {240'd0}};
 * 
 * // 方法 3: 循环赋值 (适合长文本)
 * integer i;
 * reg [7:0] text_array [0:31];
 * // ... 填充 text_array ...
 * for (i = 0; i < 32; i = i + 1) begin
 *     text_data[(31-i)*8 +: 8] = text_array[i];
 * end
 * 
 * // 方法 4: ASCII 码转换
 * wire [7:0] digit_ascii = digit_value + 8'd48;  // 数值转 ASCII
 * 
 * ============================================================================
 * 【注意事项】
 * ============================================================================
 * 
 * 1. 时钟域：必须使用像素时钟 clk_pixel，与 VGA 时序同步
 * 2. 文本长度：text_len 必须准确，否则显示会截断或显示多余字符
 * 3. 字符范围：仅支持 ASCII 32-126 (空格到~)
 * 4. 缩放限制：仅支持 scale = 1, 2, 4, 8 (2 的幂次)
 * 5. 位置计算：start_x/start_y 必须是正数，且在屏幕范围内
 * 6. 资源消耗：MAX_CHARS 越大，消耗的寄存器越多
 * 
 * ============================================================================
 * 【字符编码参考表】
 * ============================================================================
 * 
 * ASCII | Char | Hex  || ASCII | Char | Hex
 * ------|------|------||-------|------|-----
 *   32  |  ' ' | 20   ||   80  |  'P' | 50
 *   48  |  '0' | 30   ||   97  |  'a' | 61
 *   65  |  'A' | 41   ||  126  |  '~' | 7E
 * 
 * 完整 ASCII 表请参考标准 ASCII 码表
 * 
 * ============================================================================
 */

module DynamicTextBox #(
    parameter integer MAX_CHARS = 32,     // 最大字符数 (默认 32)
    parameter integer CHAR_W_BASE = 8,    // 字符基础宽度 (8 像素)
    parameter integer CHAR_H_BASE = 8     // 字符基础高度 (8 像素)
)(
    input wire clk_pixel,                 // 像素时钟
    input wire [11:0] hcount,             // 当前像素 X 坐标 (来自 VGA 控制器)
    input wire [11:0] vcount,             // 当前像素 Y 坐标 (来自 VGA 控制器)

    // 动态文本输入 - 扁平化总线
    // 字符 0 在 [MAX_CHARS*8-1 : MAX_CHARS*8-8]
    // 字符 1 在 [MAX_CHARS*8-9 : MAX_CHARS*8-16]
    // ...
    // 字符 N 在 [(MAX_CHARS-1-N)*8+7 : (MAX_CHARS-1-N)*8]
    input wire [MAX_CHARS * 8 - 1:0] text_data,
    input wire [4:0] text_len,            // 实际文本长度 (0-31)

    input wire [11:0] start_x,            // 文本起始 X 坐标
    input wire [11:0] start_y,            // 文本起始 Y 坐标
    input wire [3:0]  scale,              // 缩放倍率 (1/2/4/8)
    
    output reg text_enable,               // 文本使能输出 (高电平有效)
    output reg [11:0] text_color          // 文本颜色输出 (12 位 444 格式 RGB)
);

    // ========================================================================
    // 缩放参数计算
    // ========================================================================
    // effective_scale: 处理 scale=0 的边界情况
    wire [3:0] effective_scale = (scale == 0) ? 4'd1 : scale;
    
    // scaled_char_w/h: 缩放后的字符宽高
    wire [11:0] scaled_char_w = CHAR_W_BASE * effective_scale;
    wire [11:0] scaled_char_h = CHAR_H_BASE * effective_scale;

    // total_text_width: 文本总宽度
    wire [11:0] total_text_width = scaled_char_w * text_len;

    // ========================================================================
    // 坐标变换
    // ========================================================================
    // relative_x/y: 相对于文本起始点的坐标
    // 如果坐标在起始点之前，设为最大值 65535 作为无效值
    wire [11:0] relative_x = (hcount >= start_x) ? (hcount - start_x) : 12'd65535;
    wire [11:0] relative_y = (vcount >= start_y) ? (vcount - start_y) : 12'd65535;

    // ========================================================================
    // 边界检测
    // ========================================================================
    wire in_width  = (relative_x < total_text_width);   // 在文本宽度内
    wire in_height = (relative_y < scaled_char_h);      // 在字符高度内
    wire in_bounds = in_width && in_height;             // 在文本边界内

    // ========================================================================
    // 字模行列计算
    // ========================================================================
    // shift_amt: 根据 scale 计算位移量
    // scale=1 -> shift=0, scale=2 -> shift=1, scale=4 -> shift=2, scale=8 -> shift=3
    wire [2:0] shift_amt = (scale == 8) ? 3'd3 :
                           (scale == 4) ? 3'd2 :
                           (scale == 2) ? 3'd1 : 3'd0;

    // char_idx: 当前像素属于第几个字符
    wire [4:0] char_idx = in_bounds ? (relative_x >> (3 + shift_amt)) : 5'd0;

    // char_mask: 用于计算字符内列位置的掩码
    // scale=1 -> mask=7,  scale=2 -> mask=15, scale=4 -> mask=31, scale=8 -> mask=63
    wire [11:0] char_mask = (scale == 8) ? 12'd63 :
                            (scale == 4) ? 12'd31 :
                            (scale == 2) ? 12'd15 :
                            12'd7;

    // font_col/row: 字模内的行列索引 (0-7)
    wire [3:0] font_col = in_bounds ? ((relative_x & char_mask) >> shift_amt) : 4'd0;
    wire [3:0] font_row = in_bounds ? ((relative_y & char_mask) >> shift_amt) : 4'd0;

    // ========================================================================
    // 字符提取
    // ========================================================================
    // 从扁平化总线中提取当前字符
    // 字符 0 在最高位，所以要反向索引
    wire [7:0] current_char = (char_idx < MAX_CHARS) ? 
        text_data[(MAX_CHARS - 1 - char_idx) * 8 +: 8] : 8'd0;

    // 字符合法性检查 (ASCII 32-126)
    wire is_valid_char = (current_char >= 32) && (current_char <= 126);
    
    // 字库地址计算
    wire [6:0] ascii_addr = is_valid_char ? (current_char - 32) : 7'd0;

    // ========================================================================
    // 字库查找
    // ========================================================================
    wire [7:0] pixel_row;
    FontROM u_font (
        .char_addr(ascii_addr),     // 字符 ASCII 码 - 32
        .row(font_row),             // 字模行 (0-7)
        .pixel_data(pixel_row)      // 字模行数据 (8 位)
    );

    // ========================================================================
    // 像素点亮判断
    // ========================================================================
    // pixel_row[7-font_col]: 取字模数据中的对应位
    wire is_lit_point = is_valid_char && in_bounds && pixel_row[7 - font_col];

    // ========================================================================
    // 同步输出
    // ========================================================================
    // 使用时序逻辑消除毛刺，确保输出与像素时钟同步
    always @(posedge clk_pixel) begin
        text_enable <= is_lit_point;
        text_color  <= 12'b1111_1111_1111;  // 白色 (R=1111, G=1111, B=1111)
    end

endmodule
