`timescale 1ns / 1ps
/*
 * CompactDigitROM - 紧凑版数字字符库
 * 5x7 点阵数字和符号，用于矩阵显示
 * 支持：0-9, 负号，小数点，空格
 */

module CompactDigitROM (
    input wire [3:0] digit_addr,  // 0-9=数字，10=负号，11=小数点，12=空格
    input wire [2:0] row,         // 0-6 (7 行)
    output reg [4:0] pixel_data   // 5 位行模式
);

    always @(*) begin
        case (digit_addr)
            // 0: 数字 0
            4'd0: case (row)
                    3'd0: pixel_data = 5'b01110;
                    3'd1: pixel_data = 5'b10001;
                    3'd2: pixel_data = 5'b10001;
                    3'd3: pixel_data = 5'b10001;
                    3'd4: pixel_data = 5'b10001;
                    3'd5: pixel_data = 5'b10001;
                    3'd6: pixel_data = 5'b01110;
                    default: pixel_data = 5'b00000;
                  endcase

            // 1: 数字 1
            4'd1: case (row)
                    3'd0: pixel_data = 5'b00100;
                    3'd1: pixel_data = 5'b01100;
                    3'd2: pixel_data = 5'b00100;
                    3'd3: pixel_data = 5'b00100;
                    3'd4: pixel_data = 5'b00100;
                    3'd5: pixel_data = 5'b00100;
                    3'd6: pixel_data = 5'b01110;
                    default: pixel_data = 5'b00000;
                  endcase

            // 2: 数字 2
            4'd2: case (row)
                    3'd0: pixel_data = 5'b01110;
                    3'd1: pixel_data = 5'b10001;
                    3'd2: pixel_data = 5'b00001;
                    3'd3: pixel_data = 5'b00010;
                    3'd4: pixel_data = 5'b00100;
                    3'd5: pixel_data = 5'b01000;
                    3'd6: pixel_data = 5'b11111;
                    default: pixel_data = 5'b00000;
                  endcase

            // 3: 数字 3
            4'd3: case (row)
                    3'd0: pixel_data = 5'b01110;
                    3'd1: pixel_data = 5'b10001;
                    3'd2: pixel_data = 5'b00001;
                    3'd3: pixel_data = 5'b00110;
                    3'd4: pixel_data = 5'b00001;
                    3'd5: pixel_data = 5'b10001;
                    3'd6: pixel_data = 5'b01110;
                    default: pixel_data = 5'b00000;
                  endcase

            // 4: 数字 4
            4'd4: case (row)
                    3'd0: pixel_data = 5'b00010;
                    3'd1: pixel_data = 5'b00110;
                    3'd2: pixel_data = 5'b01010;
                    3'd3: pixel_data = 5'b10010;
                    3'd4: pixel_data = 5'b11111;
                    3'd5: pixel_data = 5'b00010;
                    3'd6: pixel_data = 5'b00010;
                    default: pixel_data = 5'b00000;
                  endcase

            // 5: 数字 5
            4'd5: case (row)
                    3'd0: pixel_data = 5'b11111;
                    3'd1: pixel_data = 5'b10000;
                    3'd2: pixel_data = 5'b11110;
                    3'd3: pixel_data = 5'b00001;
                    3'd4: pixel_data = 5'b00001;
                    3'd5: pixel_data = 5'b10001;
                    3'd6: pixel_data = 5'b01110;
                    default: pixel_data = 5'b00000;
                  endcase

            // 6: 数字 6
            4'd6: case (row)
                    3'd0: pixel_data = 5'b00110;
                    3'd1: pixel_data = 5'b01000;
                    3'd2: pixel_data = 5'b10000;
                    3'd3: pixel_data = 5'b11110;
                    3'd4: pixel_data = 5'b10001;
                    3'd5: pixel_data = 5'b10001;
                    3'd6: pixel_data = 5'b01110;
                    default: pixel_data = 5'b00000;
                  endcase

            // 7: 数字 7
            4'd7: case (row)
                    3'd0: pixel_data = 5'b11111;
                    3'd1: pixel_data = 5'b00001;
                    3'd2: pixel_data = 5'b00010;
                    3'd3: pixel_data = 5'b00100;
                    3'd4: pixel_data = 5'b01000;
                    3'd5: pixel_data = 5'b01000;
                    3'd6: pixel_data = 5'b01000;
                    default: pixel_data = 5'b00000;
                  endcase

            // 8: 数字 8
            4'd8: case (row)
                    3'd0: pixel_data = 5'b01110;
                    3'd1: pixel_data = 5'b10001;
                    3'd2: pixel_data = 5'b10001;
                    3'd3: pixel_data = 5'b01110;
                    3'd4: pixel_data = 5'b10001;
                    3'd5: pixel_data = 5'b10001;
                    3'd6: pixel_data = 5'b01110;
                    default: pixel_data = 5'b00000;
                  endcase

            // 9: 数字 9
            4'd9: case (row)
                    3'd0: pixel_data = 5'b01110;
                    3'd1: pixel_data = 5'b10001;
                    3'd2: pixel_data = 5'b10001;
                    3'd3: pixel_data = 5'b01111;
                    3'd4: pixel_data = 5'b00001;
                    3'd5: pixel_data = 5'b10001;
                    3'd6: pixel_data = 5'b01110;
                    default: pixel_data = 5'b00000;
                  endcase

            // 10: 负号 -
            4'd10: case (row)
                    3'd0: pixel_data = 5'b00000;
                    3'd1: pixel_data = 5'b00000;
                    3'd2: pixel_data = 5'b00000;
                    3'd3: pixel_data = 5'b11111;
                    3'd4: pixel_data = 5'b00000;
                    3'd5: pixel_data = 5'b00000;
                    3'd6: pixel_data = 5'b00000;
                    default: pixel_data = 5'b00000;
                  endcase

            // 11: 小数点 .
            4'd11: case (row)
                    3'd0: pixel_data = 5'b00000;
                    3'd1: pixel_data = 5'b00000;
                    3'd2: pixel_data = 5'b00000;
                    3'd3: pixel_data = 5'b00000;
                    3'd4: pixel_data = 5'b00000;
                    3'd5: pixel_data = 5'b00000;
                    3'd6: pixel_data = 5'b00100;
                    default: pixel_data = 5'b00000;
                  endcase

            // 12: 空格
            4'd12: case (row)
                    3'd0: pixel_data = 5'b00000;
                    3'd1: pixel_data = 5'b00000;
                    3'd2: pixel_data = 5'b00000;
                    3'd3: pixel_data = 5'b00000;
                    3'd4: pixel_data = 5'b00000;
                    3'd5: pixel_data = 5'b00000;
                    3'd6: pixel_data = 5'b00000;
                    default: pixel_data = 5'b00000;
                  endcase

            default: pixel_data = 5'b00000;
        endcase
    end

endmodule
