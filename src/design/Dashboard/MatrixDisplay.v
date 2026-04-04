`timescale 1ns / 1ps
/*
 * MatrixDisplay - 全屏矩阵数据显示模块 (上下布局)
 * 显示两个 8x8 矩阵：A 矩阵和 LU 矩阵 (上下居中)
 * 使用 CompactDigitROM 紧凑字库 (5x7)
 * 支持 Q8.8 定点数格式，显示：-999.99 ~ 999.99
 */

module MatrixDisplay #(
    parameter integer PANEL_X = 0,
    parameter integer PANEL_Y = 0,
    parameter integer PANEL_W = 640,
    parameter integer PANEL_H = 480
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

    // 尺寸参数
    localparam integer MATRIX_SIZE = 8;
    localparam integer BORDER_WIDTH = 2;
    localparam integer TITLE_HEIGHT = 8;  // 标题高度
    localparam integer CHARS_PER_CELL = 7; // 符号+百位+十位+个位+小数点+十分位+百分位

    // 单元格尺寸：每个字符 6 像素 (5+1)，7 个字符 = 42 像素
    localparam integer CELL_WIDTH = 42;  // 7 字符 × 6 像素
    localparam integer CELL_HEIGHT = 24; // 7 行字模 × 3 倍缩放
    localparam integer BRACKET_WIDTH = 10;

    // 矩阵内容尺寸
    localparam integer MATRIX_CONTENT_W = MATRIX_SIZE * CELL_WIDTH;   // 336 像素
    localparam integer MATRIX_CONTENT_H = MATRIX_SIZE * CELL_HEIGHT;  // 192 像素

    // 矩阵总尺寸 (含方括号)
    localparam integer MATRIX_TOTAL_W = MATRIX_CONTENT_W + BRACKET_WIDTH * 2;  // 356 像素
    localparam integer MATRIX_TOTAL_H = MATRIX_CONTENT_H;  // 192 像素

    // 单个矩阵区域高度 (含标题和边框)
    localparam integer MATRIX_REGION_H = TITLE_HEIGHT + BORDER_WIDTH * 2 + MATRIX_TOTAL_H;  // 24+4+192=220

    // 计算布局：两个矩阵上下居中显示
    localparam integer MATRIX_GAP = 12;  // 两个矩阵之间的间距
    localparam integer TOTAL_H = MATRIX_REGION_H * 2 + MATRIX_GAP;  // 452 像素
    localparam integer START_X = (PANEL_W - MATRIX_TOTAL_W) / 2;  // (640-356)/2 = 142
    localparam integer START_Y = (PANEL_H - TOTAL_H) / 2;  // (480-452)/2 = 14

    // A 和 LU 矩阵的起始位置
    localparam integer A_LEFT = START_X;
    localparam integer A_TOP = START_Y;
    localparam integer LU_LEFT = START_X;
    localparam integer LU_TOP = START_Y + MATRIX_REGION_H + MATRIX_GAP;

    // 从扁平化总线提取矩阵元素
    // 数据排列：[0][0] 在 [1023:1008], [0][1] 在 [1007:992], ..., [7][7] 在 [15:0]
    function [15:0] get_matrix_elem;
        input [1023:0] data_bus;
        input [5:0] index;
        begin
            get_matrix_elem = data_bus[(63 - index) * 16 +: 16];
        end
    endfunction

    // A 矩阵内容顶部（标题 + 边框）
    wire [11:0] a_content_top = A_TOP + TITLE_HEIGHT + BORDER_WIDTH;
    wire [11:0] lu_content_top = LU_TOP + TITLE_HEIGHT + BORDER_WIDTH;

    // 判断是否在 A 或 LU 矩阵区域
    wire in_a = (vcount >= a_content_top &&
                 vcount < a_content_top + MATRIX_CONTENT_H &&
                 hcount >= A_LEFT && hcount < A_LEFT + MATRIX_TOTAL_W);

    wire in_lu = (vcount >= lu_content_top &&
                  vcount < lu_content_top + MATRIX_CONTENT_H &&
                  hcount >= LU_LEFT && hcount < LU_LEFT + MATRIX_TOTAL_W);

    wire in_matrix = in_a || in_lu;

    // 相对坐标
    wire [11:0] matrix_top = in_a ? a_content_top : lu_content_top;
    wire [11:0] matrix_left = in_a ? A_LEFT : LU_LEFT;
    wire [11:0] rel_y = vcount - matrix_top;  // 0~191
    wire [11:0] rel_x = hcount - matrix_left;  // 0~67

    // 方括号区域
    wire in_left_bracket = (rel_x < BRACKET_WIDTH);
    wire in_right_bracket = (rel_x >= BRACKET_WIDTH + MATRIX_CONTENT_W);
    wire in_cell_area = (rel_x >= BRACKET_WIDTH && rel_x < BRACKET_WIDTH + MATRIX_CONTENT_W);

    // 单元格行列索引
    wire [5:0] cell_row = rel_y / CELL_HEIGHT;
    wire [5:0] cell_col = (rel_x - BRACKET_WIDTH) / CELL_WIDTH;

    wire cell_row_ok = (cell_row < MATRIX_SIZE);
    wire cell_col_ok = (cell_col < MATRIX_SIZE);
    wire cell_ok = cell_row_ok && cell_col_ok;

    wire [5:0] cell_idx = cell_row * MATRIX_SIZE + cell_col;

    // 单元格内坐标
    wire [11:0] in_cell_x = (rel_x - BRACKET_WIDTH) % CELL_WIDTH;
    wire [11:0] in_cell_y = rel_y % CELL_HEIGHT;

    // 获取元素值
    wire [15:0] elem_a = get_matrix_elem(matrix_a_data, cell_idx);
    wire [15:0] elem_lu = get_matrix_elem(matrix_lu_data, cell_idx);
    wire [15:0] elem = in_a ? elem_a : elem_lu;

    // 字符位置 (0-6): 符号/百位，十位，个位，小数点，十分位，百分位，结束符
    wire [2:0] char_pos = in_cell_x / 6;  // 每字符 6 像素 (5+1)
    wire char_idx_ok = (char_pos < CHARS_PER_CELL);

    // 字模内坐标 (5x7 字模，3 倍垂直缩放)
    wire [2:0] font_col = in_cell_x % 6;  // 列索引 0-5
    wire [3:0] font_row = in_cell_y / (CELL_HEIGHT / 7);  // 3 倍垂直缩放
    wire font_row_ok = (font_row < 7);
    wire font_col_ok = (font_col < 5);  // 字模只有 5 列宽

    // Q8.8 转数字 (7 字符：符号+百位+十位+个位+小数点+十分位+百分位)
    wire is_minus = elem[15];
    wire [7:0] int_part = is_minus ? -elem[15:8] : elem[15:8];
    wire [3:0] hundreds = int_part / 100;
    wire [3:0] tens = (int_part % 100) / 10;
    wire [3:0] ones = int_part % 10;

    // 小数部分 (Q8.8 的低 8 位)
    wire [7:0] frac_part = elem[7:0];
    wire [7:0] frac_x100 = (frac_part * 100) >> 8;  // 乘以 100/256
    wire [3:0] tenths = frac_x100 / 10;
    wire [3:0] hundredths = frac_x100 % 10;

    // 根据字符位置选择数字 (支持 7 字符：符号+百+十+个+小数点+十分+百分)
    // 不显示前导 0：负数也隐藏百位/十位的 0
    reg [3:0] digit_addr;
    always @(*) begin
        case (char_pos)
            3'd0: digit_addr = is_minus ? 4'd10 : 4'd12;  // 负号或空格
            3'd1: digit_addr = hundreds;                  // 百位 (如果是 0 会显示为 0)
            3'd2: digit_addr = tens;                      // 十位
            3'd3: digit_addr = ones;                      // 个位
            3'd4: digit_addr = 4'd11;                     // 小数点
            3'd5: digit_addr = tenths;                    // 十分位
            3'd6: digit_addr = hundredths;                // 百分位
            default: digit_addr = 4'd12;
        endcase
    end

    // 前导 0 掩码：将前导 0 转换为空格 (ASCII 32 → digit_addr=12)
    wire hundreds_is_zero = (hundreds == 4'd0);
    wire tens_is_zero = (tens == 4'd0);
    wire is_small_num = hundreds_is_zero && tens_is_zero;  // 0-9 的数

    // 最终 digit_addr (应用前导 0 掩码)
    // 百位为 0 → 空格；十位为 0 且百位为 0 → 空格；负数也适用
    wire [3:0] final_digit_addr =
        (char_pos == 3'd1 && hundreds_is_zero) ? 4'd12 :  // 百位是 0 → 空格
        (char_pos == 3'd2 && tens_is_zero && hundreds_is_zero) ? 4'd12 :  // 十位是 0 且百位是 0 → 空格
        digit_addr;

    wire cell_valid = in_matrix && cell_ok && char_idx_ok && font_row_ok && font_col_ok && in_cell_area;

    // 字库实例化
    wire [4:0] digit_pixels;
    CompactDigitROM u_digit (
        .digit_addr(cell_valid ? final_digit_addr : 4'd12),
        .row(font_row[2:0]),  // 取低 3 位 (0-6)
        .pixel_data(digit_pixels)
    );

    // digit_lit: 只有 font_col 在 0-4 范围内才点亮
    wire digit_lit = cell_valid && font_col_ok && digit_pixels[4 - font_col];

    // 方括号渲染 (简单的垂直线)
    wire bracket_left = in_left_bracket && ((rel_x == 4) || (rel_x == 5));
    wire [11:0] right_rel_x = rel_x - (BRACKET_WIDTH + MATRIX_CONTENT_W);
    wire bracket_right = in_right_bracket && ((right_rel_x == 4) || (right_rel_x == 5));

    wire pixel_lit = digit_lit || bracket_left || bracket_right;

    // 标题 (使用 8x8 字模，无缩放 = 8x8 像素/字符)
    // [A] = 3 字符 × 8 = 24 像素宽
    // [LU] = 4 字符 × 8 = 32 像素宽
    wire [11:0] title_a_w = 12'd24;
    wire [11:0] title_lu_w = 12'd32;
    
    // 标题居中位置 (在 A_TOP 和 LU_TOP 处显示)
    wire [11:0] title_a_left = A_LEFT + (MATRIX_TOTAL_W - title_a_w) / 2;
    wire [11:0] title_lu_left = LU_LEFT + (MATRIX_TOTAL_W - title_lu_w) / 2;
    
    // 标题区域判断 (在矩阵顶部显示)
    wire in_title_a = (vcount >= A_TOP) && (vcount < A_TOP + TITLE_HEIGHT) &&
                      (hcount >= title_a_left) && (hcount < title_a_left + title_a_w);
    wire in_title_lu = (vcount >= LU_TOP) && (vcount < LU_TOP + TITLE_HEIGHT) &&
                       (hcount >= title_lu_left) && (hcount < title_lu_left + title_lu_w);
    
    // 标题本地 X 坐标（相对于标题起始位置）
    wire [11:0] title_local_x_a = hcount - title_a_left;
    wire [11:0] title_local_x_lu = hcount - title_lu_left;
    wire [11:0] title_local_x = in_title_a ? title_local_x_a : title_local_x_lu;
    
    // 标题有效性检查
    wire [11:0] title_width = in_title_a ? title_a_w : title_lu_w;
    wire title_valid = (in_title_a || in_title_lu) && (title_local_x < title_width);
    
    // 标题字符选择（每 8 像素一个字符）
    wire [1:0] char_idx = title_local_x / 8;  // 0,1,2 对应 [A]；0,1,2,3 对应 [LU]
    
    reg [7:0] title_char;
    always @(*) begin
        case (char_idx)
            2'd0: title_char = 8'h5B;  // '['
            2'd1: title_char = in_title_a ? 8'h41 : 8'h4C;  // 'A' 或 'L'
            2'd2: title_char = in_title_a ? 8'h5D : 8'h55;  // ']' 或 'U'
            2'd3: title_char = 8'h5D;  // ']' (仅 LU)
            default: title_char = 8'd0;
        endcase
    end

    wire [3:0] title_font_row = (vcount - (in_title_a ? A_TOP : LU_TOP)) % 8;
    wire [3:0] title_font_col = title_local_x % 8;

    wire [7:0] title_pixels;
    FontROM u_title (
        .char_addr(title_valid ? (title_char - 32) : 7'd0),
        .row(title_font_row),
        .pixel_data(title_pixels)
    );

    wire title_pixel_lit = title_valid && title_pixels[7 - title_font_col];

    // 面板和边框
    wire in_panel = (hcount >= START_X - BORDER_WIDTH) && (hcount < START_X + MATRIX_TOTAL_W + BORDER_WIDTH) &&
                    (vcount >= START_Y - BORDER_WIDTH) && (vcount < LU_TOP + MATRIX_TOTAL_H + BORDER_WIDTH + TITLE_HEIGHT);

    wire is_outer_border = in_panel && (
        (hcount == START_X - BORDER_WIDTH) || (hcount == START_X + MATRIX_TOTAL_W + BORDER_WIDTH - 1) ||
        (vcount == START_Y - BORDER_WIDTH) || (vcount == LU_TOP + MATRIX_TOTAL_H + BORDER_WIDTH + TITLE_HEIGHT - 1)
    );

    wire is_divider = (hcount >= START_X - BORDER_WIDTH) && (hcount < START_X + MATRIX_TOTAL_W + BORDER_WIDTH) &&
                      (vcount >= A_TOP + MATRIX_REGION_H) && (vcount < LU_TOP);

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
