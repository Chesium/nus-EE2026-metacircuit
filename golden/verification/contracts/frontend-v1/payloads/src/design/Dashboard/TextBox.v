`timescale 1ns / 1ps
/*例化展示：

    TextBox #(
        .TEXT_CONTENT("METACIRCUIT v0.0"), //文本框字符串，最长32个字符
        .TEXT_LEN (16) //手动输入当前字符串长度
    ) u_textbox (
        .clk_pixel (clk_pixel),
        .hcount (x_pos),
        .vcount (y_pos),
        .start_x (12'd0), // 自定义位置 X
        .start_y (12'd0), // 自定义位置 Y
        .scale (4'd1), // 自定义大小，含1，2，4，8四个放大倍率
        .text_enable (text_rendered),
        .text_color (text_rgb)
    );

*/
module TextBox #(
    parameter [255:0] TEXT_CONTENT = "Hello Basys3!",
    parameter TEXT_LEN = 13, 
    parameter CHAR_W_BASE = 8,
    parameter CHAR_H_BASE = 8, //文字基础大小：8x8
    parameter MAX_CHARS = 32 //字符串长度上限：32
)(
    input wire clk_pixel,
    input wire [11:0] hcount,
    input wire [11:0] vcount,
    input wire [11:0] start_x,
    input wire [11:0] start_y,
    input wire [3:0]  scale,
    output reg text_enable,
    output reg [11:0] text_color
);
    reg [7:0] char_mem [0:MAX_CHARS-1]; //31行每行8位
    integer i;

    // 2. 使用 initial 块将 parameter 字符串拆解填入数组
    initial begin
        for (i = 0; i < MAX_CHARS; i = i + 1) begin
            if (i < TEXT_LEN) begin
                // 有效范围内：提取字符
                char_mem[i] = TEXT_CONTENT[(TEXT_LEN - 1 - i) * 8 +: 8];
            end else begin
                // 超出有效长度：强制填 0 (作为结束标志)
                char_mem[i] = 8'd0;
            end
        end
    end

    // 1. 计算缩放参数
    wire [3:0] effective_scale = (scale == 0) ? 4'd1 : scale;
    wire [11:0] scaled_char_w = CHAR_W_BASE * effective_scale;
    wire [11:0] scaled_char_h = CHAR_H_BASE * effective_scale;
    
    // 使用 TEXT_LEN 计算总宽度
    wire [11:0] total_text_width = scaled_char_w * TEXT_LEN;

    // 2. 坐标差值 - 使用最大值作为无效值
    wire [11:0] relative_x = (hcount >= start_x) ? (hcount - start_x) : 12'd65535;
    wire [11:0] relative_y = (vcount >= start_y) ? (vcount - start_y) : 12'd65535;

    // 3. 边界与索引计算
    wire in_width  = (relative_x < (total_text_width));
    wire in_height = (relative_y < scaled_char_h);
    wire in_bounds = in_width && in_height;

    // 4. 字体内部行列计算
    
    // 仅支持 scale = 1, 2, 4, 8
    // 此时 scaled_char_w = 8, 16, 32, 64    
    wire [2:0] shift_amt = (scale == 8) ? 3'd3 : 
                           (scale == 4) ? 3'd2 : 
                           (scale == 2) ? 3'd1 : 3'd0; // scale=1 -> shift 0
    
    // 字符索引
    // 例如 scale=2 (shift_amt=1), 宽 16. relative_x / 16 = relative_x >> 4
    wire [4:0] char_idx = in_bounds ? (relative_x >> (3 + shift_amt)) : 5'd0; //计算当前渲染像素位于第几个字符

    // 字体内部列 = (relative_x % width) / scale
    // % width (如果是 2 的幂) = 取低位 (& mask)
    // 然后 >> shift_amt
    wire [11:0] char_mask = (scale == 8) ? 12'd63: //0000_0011_1111  
                            (scale == 4) ? 12'd31: //0000_0001_1111  
                            (scale == 2) ? 12'd15 : //0000_0000_1111 
                            12'd7; //0000_0000_0111
    
    wire [3:0] font_col = in_bounds ? ((relative_x & char_mask) >> shift_amt) : 4'd0;
    wire [3:0] font_row = in_bounds ? ((relative_y & char_mask) >> shift_amt) : 4'd0;

    // 5. 直接从 TEXT_CONTENT 参数提取字符 
    wire [7:0] current_char = char_mem[char_idx];

    wire is_valid_char = (current_char >= 32) && (current_char <= 126);
    wire [6:0] ascii_addr = is_valid_char ? (current_char - 32) : 7'd0;

    // 7. 字库查找 (组合逻辑实例化)
    wire [7:0] pixel_row;
    FontROM u_font (
        .char_addr(ascii_addr),
        .row(font_row),
        .pixel_data(pixel_row)
    );

    // 8. 判断点位 (组合逻辑)
    wire is_lit_point = is_valid_char && in_bounds && pixel_row[7 - font_col];

    // 9. 最终输出 (时序逻辑，仅用于同步输出，消除毛刺)
    always @(posedge clk_pixel) begin
        text_enable <= is_lit_point;
        text_color  <= 12'b1111_1111_1111;
    end

endmodule