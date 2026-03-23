`timescale 1ns / 1ps

module WaveformPlot #(
    parameter IS_VOLTAGE = 1
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] local_x,
    input  wire [7:0] local_y,
    output wire [7:0] rd_addr,
    input  wire [7:0] rd_data,
    output wire       is_wave_pixel,
    output wire       is_axis_pixel,
    output wire       is_text_pixel
);

    assign rd_addr = local_x;
    
    // 畫布高度為 128，所以 Y 座標最大為 127
    wire [7:0] target_y = 8'd127 - rd_data;
    reg [7:0] prev_y;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) prev_y <= 8'd0;
        else if (local_x == 8'd0) prev_y <= target_y;
        else prev_y <= target_y;
    end

    wire [7:0] y_max = (target_y > prev_y) ? target_y : prev_y;
    wire [7:0] y_min = (target_y < prev_y) ? target_y : prev_y;
    localparam THICKNESS = 8'd1;

    wire [7:0] y_min_safe = (y_min > THICKNESS) ? (y_min - THICKNESS) : 8'd0;
    wire [7:0] y_max_safe = (y_max < (8'd127 - THICKNESS)) ? (y_max + THICKNESS) : 8'd127;

    assign is_wave_pixel = (local_y >= y_min_safe) && (local_y <= y_max_safe);

    // =========================================================
    // 【重點修改：加粗的儀表板外框】
    // Y 中心為 63，寬度為 242 所以 X 中心為 121。十字線維持 2 像素厚實感。
    // 外圍邊框 (Top, Bottom, Left, Right) 全面加粗到 4 像素！
    // =========================================================
    assign is_axis_pixel = (local_y >= 8'd63 && local_y <= 8'd64) ||  // 水平十字線 (2px)
                           (local_x >= 8'd120 && local_x <= 8'd121)|| // 垂直十字線 (2px)
                           (local_x <= 8'd3)  || (local_x >= 8'd238)|| // 左、右厚邊框 (4px)
                           (local_y <= 8'd3)  || (local_y >= 8'd124);  // 上、下厚邊框 (4px)

    // =========================================================
    // 硬體 OSD 字元點陣 (8x8 Bitmap)
    // =========================================================
    reg [7:0] char_rom [0:7];
    initial begin
        if (IS_VOLTAGE == 1) begin
            // "V"
            char_rom[0] = 8'b11000011; char_rom[1] = 8'b11000011; char_rom[2] = 8'b01100110; char_rom[3] = 8'b01100110;
            char_rom[4] = 8'b00111100; char_rom[5] = 8'b00011000; char_rom[6] = 8'b00011000; char_rom[7] = 8'b00000000;
        end else begin
            // "I"
            char_rom[0] = 8'b00111100; char_rom[1] = 8'b00011000; char_rom[2] = 8'b00011000; char_rom[3] = 8'b00011000;
            char_rom[4] = 8'b00011000; char_rom[5] = 8'b00011000; char_rom[6] = 8'b00111100; char_rom[7] = 8'b00000000;
        end
    end

    wire in_char_box = (local_x >= 8'd8 && local_x <= 8'd23) && (local_y >= 8'd8 && local_y <= 8'd23);
    wire [2:0] char_x = (local_x - 8'd8) >> 1;
    wire [2:0] char_y = (local_y - 8'd8) >> 1;
    assign is_text_pixel = in_char_box ? char_rom[char_y][3'd7 - char_x] : 1'b0;

endmodule