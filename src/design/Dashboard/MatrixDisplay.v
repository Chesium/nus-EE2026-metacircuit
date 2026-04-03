`timescale 1ns / 1ps
/*
 * MatrixDisplay - 全屏矩阵数据显示模块
 * 显示两个 8x8 矩阵：A 矩阵和 LU 矩阵 (并排)
 * 使用 CompactDigitROM 紧凑字库 (5x7)
 * 支持 Q8.8 定点数格式，显示范围 -128~127，保留两位小数
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
    localparam integer TITLE_HEIGHT = 16;
    localparam integer CHARS_PER_CELL = 7;  // 符号+十位+个位+小数点+十分位+百分位

    // 单元格尺寸：全屏模式下每个单元格较大
    localparam integer CELL_WIDTH = 44;   // 7 字符 × 6 像素 + 2 间距
    localparam integer CELL_HEIGHT = 42;  // 7 行字模 × 6 倍缩放
    localparam integer BRACKET_WIDTH = 10;

    // 矩阵内容尺寸
    localparam integer MATRIX_CONTENT_W = MATRIX_SIZE * CELL_WIDTH;   // 352 像素
    localparam integer MATRIX_CONTENT_H = MATRIX_SIZE * CELL_HEIGHT;  // 336 像素

    // 矩阵总尺寸 (含方括号)
    localparam integer MATRIX_TOTAL_W = MATRIX_CONTENT_W + BRACKET_WIDTH * 2;  // 372 像素
    localparam integer MATRIX_TOTAL_H = MATRIX_CONTENT_H;  // 336 像素

    // 计算布局：两个矩阵并排，居中显示
    localparam integer MATRIX_GAP = 16;  // 两个矩阵之间的间距
    localparam integer TOTAL_W = MATRIX_TOTAL_W * 2 + MATRIX_GAP;
    localparam integer START_X = (PANEL_W - TOTAL_W) / 2;
    localparam integer START_Y = (PANEL_H - MATRIX_TOTAL_H) / 2 + TITLE_HEIGHT/2;

    // A 和 LU 矩阵的起始位置
    localparam integer A_LEFT = START_X;
    localparam integer A_TOP = START_Y;
    localparam integer LU_LEFT = START_X + MATRIX_TOTAL_W + MATRIX_GAP;
    localparam integer LU_TOP = START_Y;

    // A 矩阵内容顶部
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
    wire [11:0] rel_y = vcount - matrix_top;  // 0~335
    wire [11:0] rel_x = hcount - matrix_left;  // 0~371

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

    // 字符位置 (0-6): 符号/十位，个位，小数点，十分位，百分位
    wire [2:0] char_idx = in_cell_x / 6;  // 每字符 6 像素 (5+1)
    wire char_idx_ok = (char_idx < CHARS_PER_CELL);

    // 字模内坐标 (5x7 字模，6 倍垂直缩放)
    wire [2:0] font_col = in_cell_x % 6;
    wire [3:0] font_row = in_cell_y / (CELL_HEIGHT / 7);
    wire font_row_ok = (font_row < 7);

    // Q8.8 转数字
    wire is_minus = elem[15];
    wire [7:0] int_part = is_minus ? -elem[15:8] : elem[15:8];
    wire [7:0] tens = int_part / 10;
    wire [3:0] ones = int_part % 10;
    
    // 小数部分 (Q8.8 的低 8 位)
    wire [7:0] frac_part = elem[7:0];
    wire [7:0] frac_x100 = (frac_part * 100) >> 8;  // 乘以 100/256
    wire [3:0] tenths = frac_x100 / 10;
    wire [3:0] hundredths = frac_x100 % 10;

    // 根据字符位置选择数字
    reg [3:0] digit_addr;
    always @(*) begin
        case (char_idx)
            3'd0: digit_addr = is_minus ? 4'd10 : ((int_part >= 10) ? tens : 4'd12);
            3'd1: digit_addr = ones;
            3'd2: digit_addr = 4'd11;  // 小数点
            3'd3: digit_addr = tenths;
            3'd4: digit_addr = hundredths;
            default: digit_addr = 4'd12;  // 空格
        endcase
    end

    wire cell_valid = in_matrix && cell_ok && char_idx_ok && font_row_ok && in_cell_area;

    // 字库实例化
    wire [4:0] digit_pixels;
    CompactDigitROM u_digit (
        .digit_addr(cell_valid ? digit_addr : 4'd12),
        .row(font_row),
        .pixel_data(digit_pixels)
    );

    wire digit_lit = cell_valid && digit_pixels[4 - font_col];

    // 方括号渲染 (简单的垂直线)
    wire bracket_left = in_left_bracket && ((rel_x == 4) || (rel_x == 5));
    wire [11:0] right_rel_x = rel_x - (BRACKET_WIDTH + MATRIX_CONTENT_W);
    wire bracket_right = in_right_bracket && ((right_rel_x == 4) || (right_rel_x == 5));

    wire pixel_lit = digit_lit || bracket_left || bracket_right;

    // 标题
    wire title_y_a = A_TOP;
    wire title_y_lu = LU_TOP;
    wire in_title_a = (vcount >= title_y_a && vcount < title_y_a + TITLE_HEIGHT &&
                       hcount >= A_LEFT && hcount < A_LEFT + MATRIX_TOTAL_W);
    wire in_title_lu = (vcount >= title_y_lu && vcount < title_y_lu + TITLE_HEIGHT &&
                        hcount >= LU_LEFT && hcount < LU_LEFT + MATRIX_TOTAL_W);

    wire [11:0] title_x = in_a ? (hcount - A_LEFT) : (hcount - LU_LEFT);
    wire title_valid = (in_title_a || in_title_lu) && (title_x / 16 < 4);

    reg [7:0] title_char;
    always @(*) begin
        case (title_x / 16)
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

    wire title_pixel_lit = title_valid && title_pixels[7 - title_font_col];

    // 面板和边框
    wire in_panel = (hcount >= START_X - BORDER_WIDTH) && (hcount < START_X + TOTAL_W + BORDER_WIDTH) &&
                    (vcount >= START_Y - BORDER_WIDTH - TITLE_HEIGHT) && (vcount < START_Y + MATRIX_TOTAL_H + BORDER_WIDTH);

    wire is_outer_border = in_panel && (
        (hcount == START_X - BORDER_WIDTH) || (hcount == START_X + TOTAL_W + BORDER_WIDTH - 1) ||
        (vcount == START_Y - BORDER_WIDTH - TITLE_HEIGHT) || (vcount == START_Y + MATRIX_TOTAL_H + BORDER_WIDTH - 1)
    );

    wire is_divider = (hcount >= A_LEFT + MATRIX_TOTAL_W) && (hcount < LU_LEFT) &&
                      (vcount >= START_Y - BORDER_WIDTH - TITLE_HEIGHT) && (vcount < START_Y + MATRIX_TOTAL_H + BORDER_WIDTH);

    // 从扁平化总线提取矩阵元素
    function [15:0] get_matrix_elem;
        input [1023:0] data_bus;
        input [5:0] index;
        begin
            get_matrix_elem = data_bus[(63 - index) * 16 +: 16];
        end
    endfunction

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
