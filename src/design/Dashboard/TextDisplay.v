`timescale 1ns / 1ps

module TextDisplay (
    input wire clk_pixel,
    input wire [11:0] hcount,
    input wire [11:0] vcount,
    
    // 配置参数
    input wire [11:0] start_x,
    input wire [11:0] start_y,
    input wire [3:0]  scale,
    
    // 【修改点】将数组端口改为 32 个独立的 8 位输入
    input wire [7:0] char_0,  input wire [7:0] char_1,  input wire [7:0] char_2,  input wire [7:0] char_3,
    input wire [7:0] char_4,  input wire [7:0] char_5,  input wire [7:0] char_6,  input wire [7:0] char_7,
    input wire [7:0] char_8,  input wire [7:0] char_9,  input wire [7:0] char_10, input wire [7:0] char_11,
    input wire [7:0] char_12, input wire [7:0] char_13, input wire [7:0] char_14, input wire [7:0] char_15,
    input wire [7:0] char_16, input wire [7:0] char_17, input wire [7:0] char_18, input wire [7:0] char_19,
    input wire [7:0] char_20, input wire [7:0] char_21, input wire [7:0] char_22, input wire [7:0] char_23,
    input wire [7:0] char_24, input wire [7:0] char_25, input wire [7:0] char_26, input wire [7:0] char_27,
    input wire [7:0] char_28, input wire [7:0] char_29, input wire [7:0] char_30, input wire [7:0] char_31,
    
    // 输出
    output reg text_enable,
    output reg [4:0] char_index_out // 改为 5 位以容纳 0-31
);

    parameter CHAR_W = 8;
    parameter CHAR_H = 8;

    // 内部创建一个数组用于逻辑查找，将外部输入的 32 个信号打包进来
    reg [7:0] text_mem_local [0:31];
    integer i;

    // 将输入的独立信号打包到内部数组
    always @(*) begin
        text_mem_local[0]  = char_0;  text_mem_local[1]  = char_1;  text_mem_local[2]  = char_2;  text_mem_local[3]  = char_3;
        text_mem_local[4]  = char_4;  text_mem_local[5]  = char_5;  text_mem_local[6]  = char_6;  text_mem_local[7]  = char_7;
        text_mem_local[8]  = char_8;  text_mem_local[9]  = char_9;  text_mem_local[10] = char_10; text_mem_local[11] = char_11;
        text_mem_local[12] = char_12; text_mem_local[13] = char_13; text_mem_local[14] = char_14; text_mem_local[15] = char_15;
        text_mem_local[16] = char_16; text_mem_local[17] = char_17; text_mem_local[18] = char_18; text_mem_local[19] = char_19;
        text_mem_local[20] = char_20; text_mem_local[21] = char_21; text_mem_local[22] = char_22; text_mem_local[23] = char_23;
        text_mem_local[24] = char_24; text_mem_local[25] = char_25; text_mem_local[26] = char_26; text_mem_local[27] = char_27;
        text_mem_local[28] = char_28; text_mem_local[29] = char_29; text_mem_local[30] = char_30; text_mem_local[31] = char_31;
    end

    reg [3:0] effective_scale;
    reg [11:0] scaled_char_w;
    reg [11:0] scaled_char_h;

    always @(*) begin
        if (scale == 0) effective_scale = 4'd1;
        else effective_scale = scale;
        scaled_char_w = CHAR_W * effective_scale;
        scaled_char_h = CHAR_H * effective_scale;
    end

    reg [11:0] relative_x, relative_y;
    reg [4:0]  char_col_idx;
    reg [3:0]  font_row_idx;
    reg [3:0]  font_col_idx;
    reg [6:0]  ascii_code;
    wire [7:0]  font_pixel_row;
    reg        is_on;

    FontROM u_font (
        .char_addr(ascii_code - 32),
        .row(font_row_idx),
        .pixel_data(font_pixel_row)
    );

    always @(posedge clk_pixel) begin

        text_enable <= 1'b0;
        char_index_out <= 0;

        if (hcount >= start_x && vcount >= start_y) begin
            relative_x = hcount - start_x;
            relative_y = vcount - start_y;

            if (relative_x < (scaled_char_w * 32) && relative_y < scaled_char_h) begin
                char_col_idx = relative_x / scaled_char_w;
                
                // 优化：如果 scale 是 2 的幂，这里可以用移位，但先保持通用除法
                font_col_idx = (relative_x % scaled_char_w) / effective_scale;
                font_row_idx = (relative_y % scaled_char_h) / effective_scale;

                if (char_col_idx < 32) begin
                    ascii_code = text_mem_local[char_col_idx];
                    
                    if (ascii_code >= 32 && ascii_code <= 126) begin

                        is_on = font_pixel_row[7 - font_col_idx];
                        
                        if (is_on) begin
                            text_enable <= 1'b1;
                            char_index_out <= char_col_idx;
                        end
                    end
                end
            end
        end
    end
endmodule