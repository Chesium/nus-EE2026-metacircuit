`timescale 1ns / 1ps
/*
 * MatrixDisplay - 矩阵数据显示模块 (8x8 固定尺寸，紧凑字库版)
 * 显示两个 8x8 矩阵：A 矩阵和 LU 矩阵
 * 使用 5x7 紧凑数字字符库，每单元格显示 3 个字符 (符号/十位 + 个位 + 小数)
 */

module MatrixDisplay #(
    parameter integer PANEL_X = 484,
    parameter integer PANEL_Y = 64,
    parameter integer PANEL_W = 156,
    parameter integer PANEL_H = 300
)(
    input wire clk_pixel,
    input wire [11:0] hcount,
    input wire [11:0] vcount,
    input wire video_on,

    input wire [1023:0] matrix_a_data,
    input wire [1023:0] matrix_lu_data,

    output reg matrix_rendered,
    output reg [11:0] matrix_rgb
);

    localparam [11:0] COLOR_BG = 12'hDDD;
    localparam [11:0] COLOR_BORDER = 12'h666;
    localparam [11:0] COLOR_TEXT = 12'h000;

    // 尺寸参数 - 使用紧凑字库 (5x7)
    localparam integer MATRIX_SIZE = 8;
    localparam integer BORDER_WIDTH = 2;
    localparam integer TITLE_HEIGHT = 16;
    localparam integer CELL_HEIGHT = 14;   // 7 像素字模×2 倍缩放
    localparam integer CELL_WIDTH = 17;    // 3 字符×5 像素 +2 间距
    localparam integer BRACKET_WIDTH = 8;

    // 矩阵内容尺寸
    localparam integer MATRIX_CONTENT_W = MATRIX_SIZE * CELL_WIDTH;   // 136 像素
    localparam integer MATRIX_CONTENT_H = MATRIX_SIZE * CELL_HEIGHT;  // 112 像素

    // 矩阵总尺寸 (含方括号)
    localparam integer MATRIX_TOTAL_W = MATRIX_CONTENT_W + BRACKET_WIDTH * 2;  // 152 像素
    localparam integer MATRIX_TOTAL_H = MATRIX_CONTENT_H;  // 112 像素

    // 单个矩阵区域高度
    localparam integer MATRIX_REGION_H = TITLE_HEIGHT + BORDER_WIDTH * 2 + MATRIX_TOTAL_H;  // 16+4+112=132

    // 矩阵起始位置 (居中：156-152=4, 左右各 2 像素)
    localparam integer MATRIX_START_X = PANEL_X + BORDER_WIDTH + 2;  // 488
    localparam integer MATRIX_START_Y = PANEL_Y + BORDER_WIDTH + 4;  // 70
    localparam integer MATRIX_END_X = MATRIX_START_X + MATRIX_TOTAL_W;  // 640
    localparam integer MATRIX_END_Y = MATRIX_START_Y + MATRIX_TOTAL_H;  // 182

    // A/LU 矩阵边界
    localparam integer A_REGION_END_Y = MATRIX_START_Y + MATRIX_REGION_H;  // 70+132=202
    localparam integer LU_MATRIX_START_Y = A_REGION_END_Y;  // 202

    // 从扁平化总线提取矩阵元素
    function [15:0] get_matrix_elem;
        input [1023:0] data_bus;
        input [5:0] index;
        begin
            get_matrix_elem = data_bus[(63 - index) * 16 +: 16];
        end
    endfunction

    // 渲染信号
    wire in_panel, is_outer_border, is_divider;
    wire pixel_lit, title_pixel_lit;

    // A 矩阵内容区域 (严格限制在 8 行内)
    wire in_a_matrix = (vcount >= MATRIX_START_Y + TITLE_HEIGHT + BORDER_WIDTH &&
                        vcount < MATRIX_START_Y + TITLE_HEIGHT + BORDER_WIDTH + MATRIX_CONTENT_H &&
                        hcount >= MATRIX_START_X && hcount < MATRIX_END_X);

    // LU 矩阵内容区域
    wire in_lu_matrix = (vcount >= LU_MATRIX_START_Y + TITLE_HEIGHT + BORDER_WIDTH &&
                         vcount < LU_MATRIX_START_Y + TITLE_HEIGHT + BORDER_WIDTH + MATRIX_CONTENT_H &&
                         hcount >= MATRIX_START_X && hcount < MATRIX_END_X);

    wire in_matrix = in_a_matrix || in_lu_matrix;

    // 相对坐标
    wire [11:0] a_top = MATRIX_START_Y + TITLE_HEIGHT + BORDER_WIDTH;
    wire [11:0] lu_top = LU_MATRIX_START_Y + TITLE_HEIGHT + BORDER_WIDTH;
    wire [11:0] matrix_top = in_a_matrix ? a_top : lu_top;
    wire [11:0] rel_y = vcount - matrix_top;  // 0~111 (MATRIX_CONTENT_H-1)
    wire [11:0] rel_x = hcount - MATRIX_START_X;  // 0~151 (MATRIX_TOTAL_W-1)

    // 方括号区域
    wire in_left_bracket = (rel_x < BRACKET_WIDTH);
    wire in_right_bracket = (rel_x >= BRACKET_WIDTH + MATRIX_CONTENT_W);
    wire in_cell_area = (rel_x >= BRACKET_WIDTH && rel_x < BRACKET_WIDTH + MATRIX_CONTENT_W);

    // 单元格行列索引 (0-7)
    wire [5:0] cell_row = rel_y / CELL_HEIGHT;
    wire [5:0] cell_col = (rel_x - BRACKET_WIDTH) / CELL_WIDTH;

    // 行列有效性 (严格限制 8x8)
    wire cell_row_ok = (cell_row < MATRIX_SIZE);
    wire cell_col_ok = (cell_col < MATRIX_SIZE);
    wire cell_ok = cell_row_ok && cell_col_ok;

    // 单元格索引
    wire [5:0] cell_idx = cell_row * MATRIX_SIZE + cell_col;

    // 单元格内坐标
    wire [11:0] in_cell_x = (rel_x - BRACKET_WIDTH) % CELL_WIDTH;
    wire [11:0] in_cell_y = rel_y % CELL_HEIGHT;

    // 字符位置 (0-2): 符号/十位，个位，小数位
    wire [1:0] char_idx = in_cell_x / 6;  // 每字符 6 像素 (5+1)
    wire char_idx_ok = (char_idx < 3);

    // 字模内坐标 (5x7 字模，2 倍垂直缩放)
    wire [2:0] font_col = in_cell_x % 6;
    wire [3:0] font_row = in_cell_y / 2;  // 2 倍垂直缩放
    wire font_row_ok = (font_row < 7);

    // 获取元素值
    wire [15:0] elem_a = get_matrix_elem(matrix_a_data, cell_idx);
    wire [15:0] elem_lu = get_matrix_elem(matrix_lu_data, cell_idx);
    wire [15:0] elem = in_a_matrix ? elem_a : elem_lu;

    // Q8.8 转数字索引
    wire [7:0] int_part = elem[15] ? -elem[15:8] : elem[15:8];
    wire [3:0] tens_digit = int_part / 10;
    wire [3:0] ones_digit = int_part % 10;

    // 根据 char_idx 选择显示的数字
    // char_idx=0: 符号位或十位，char_idx=1: 个位，char_idx=2: 小数位
    wire is_minus = elem[15];
    wire has_tens = (int_part >= 10);
    
    // char_idx=0 时：负数显示负号，有十位显示十位，否则显示空格
    wire show_minus_at_0 = (char_idx == 2'd0) && is_minus;
    wire show_tens_at_0 = (char_idx == 2'd0) && !is_minus && has_tens;
    wire show_blank_at_0 = (char_idx == 2'd0) && !is_minus && !has_tens;
    
    // char_idx=1 时：显示个位
    wire show_ones_at_1 = (char_idx == 2'd1);
    
    // char_idx=2 时：显示小数点
    wire show_decimal_at_2 = (char_idx == 2'd2);

    // 根据位置选择要显示的数字值
    reg [3:0] digit_value;
    always @(*) begin
        case (char_idx)
            2'd0: digit_value = is_minus ? 4'd10 :  // 负号
                  has_tens ? tens_digit : 4'd12;    // 十位或空格
            2'd1: digit_value = ones_digit;          // 个位
            2'd2: digit_value = 4'd11;               // 小数点
            default: digit_value = 4'd12;
        endcase
    end

    wire [3:0] digit_addr = digit_value;

    wire cell_valid = in_matrix && cell_ok && char_idx_ok && font_row_ok && in_cell_area;

    // 字库实例化
    wire [4:0] digit_pixels;
    CompactDigitROM u_digit (
        .digit_addr(cell_valid ? digit_addr : 4'd12),
        .row(font_row),
        .pixel_data(digit_pixels)
    );

    wire digit_lit = cell_valid && digit_pixels[4 - font_col];

    // 方括号渲染 (左括号和右括号)
    // 左方括号：在 rel_x = 3,4 处绘制垂直线
    wire bracket_left = in_left_bracket && ((rel_x == 3) || (rel_x == 4));

    // 右方括号：在右侧区域 rel_x 对应位置绘制
    wire [11:0] right_rel_x = rel_x - (BRACKET_WIDTH + MATRIX_CONTENT_W);
    wire bracket_right = in_right_bracket && ((right_rel_x == 3) || (right_rel_x == 4));

    assign pixel_lit = digit_lit || bracket_left || bracket_right;

    // 标题渲染
    wire title_y_a = MATRIX_START_Y;
    wire title_y_lu = LU_MATRIX_START_Y;

    wire in_title_a = (vcount >= title_y_a && vcount < title_y_a + TITLE_HEIGHT &&
                       hcount >= MATRIX_START_X && hcount < MATRIX_END_X);
    wire in_title_lu = (vcount >= title_y_lu && vcount < title_y_lu + TITLE_HEIGHT &&
                        hcount >= MATRIX_START_X && hcount < MATRIX_END_X);

    wire [11:0] title_x = hcount - MATRIX_START_X;
    wire [4:0] title_char_idx = title_x / 16;
    wire title_valid = (in_title_a || in_title_lu) && (title_char_idx < 4);

    reg [7:0] title_char;
    always @(*) begin
        case (title_char_idx)
            5'd0: title_char = 8'h5B;  // '['
            5'd1: title_char = in_title_a ? 8'h41 : 8'h4C;  // 'A' 或 'L'
            5'd2: title_char = in_title_a ? 8'h5D : 8'h55;  // ']' 或 'U'
            5'd3: title_char = 8'h5D;  // ']'
            default: title_char = 8'd0;
        endcase
    end

    wire [3:0] title_font_row = (vcount - (in_title_a ? title_y_a : title_y_lu)) % 8;
    wire [3:0] title_font_col = title_x % 8;

    wire [7:0] title_pixels;
    FontROM u_title (
        .char_addr(title_valid ? (title_char - 32) : 7'd0),
        .row(title_font_row),
        .pixel_data(title_pixels)
    );

    assign title_pixel_lit = title_valid && title_pixels[7 - title_font_col];

    // 面板边界
    assign in_panel = (hcount >= PANEL_X) && (hcount < PANEL_X + PANEL_W) &&
                      (vcount >= PANEL_Y) && (vcount < PANEL_Y + PANEL_H);

    assign is_outer_border = in_panel && (
        (hcount == PANEL_X) || (hcount == PANEL_X + PANEL_W - 1) ||
        (vcount == PANEL_Y) || (vcount == PANEL_Y + PANEL_H - 1)
    );

    assign is_divider = (vcount >= A_REGION_END_Y) && (vcount < LU_MATRIX_START_Y);

    // 渲染输出
    always @(posedge clk_pixel) begin
        matrix_rendered <= 1'b0;
        matrix_rgb <= COLOR_BG;

        if (video_on && in_panel) begin
            matrix_rendered <= 1'b1;

            if (is_outer_border || is_divider)
                matrix_rgb <= COLOR_BORDER;
            else if (title_pixel_lit)
                matrix_rgb <= COLOR_TEXT;
            else if (pixel_lit)
                matrix_rgb <= COLOR_TEXT;
            else
                matrix_rgb <= COLOR_BG;
        end
    end

endmodule
