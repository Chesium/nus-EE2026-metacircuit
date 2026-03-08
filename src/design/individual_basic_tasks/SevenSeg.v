`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.03.2026 18:54:18
// Design Name: 
// Module Name: SevenSeg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

/*

Individual cathodes (active low)
 00000
5     1
5     1
 66666
4     2
4     2
 33333  77

Common anodes (active low)
3 2 1 0
            N   6543210
0 | 012345  1 | 1000000
1 | 12      5 | 1111001
2 | 01346   2 | 0100100
3 | 01236   2 | 0110000
4 | 1256    3 | 0011001
5 | 02356   2 | 0010010
6 | 023456  1 | 0000010
7 | 012     4 | 1111000
8 | 0123456 0 | 0000000
9 | 012356  1 | 0010000

*/


module SevenSeg(
    input CLK100MHZ,
    input [5:0] char1,
    input [5:0] char2,
    input [5:0] char3,
    input [5:0] char4,
    input [3:0] decimalpoints,
    output reg [7:0] seg,
    output reg [4:0] an
);

    // 000000 - 001001 : 0 ~ 9

    parameter seg_clk_freq = 500; // Hz 
    parameter seg_clk_cnt_mx = 100000000 / seg_clk_freq / 2;

    reg [$clog2(seg_clk_cnt_mx)-1:0] seg_clk_cnt = 0;
    reg seg_clk = 0;

    // clock divider for the 500Hz seg_clk
    always @(posedge CLK100MHZ) begin
        if (seg_clk_cnt == seg_clk_cnt_mx) begin
            seg_clk <= ~seg_clk;
            seg_clk_cnt <= 0;
        end else begin
            seg_clk_cnt <= seg_clk_cnt + 1;
        end
    end

    reg [1:0] seg_num = 0;

    // traversing the four common anodes using 500Hz seg_clk
    always @(posedge seg_clk) begin
        if (seg_num == 3) begin
            seg_num <= 0;
        end else begin
            seg_num <= seg_num + 1;
        end
    end

    reg [5:0] char_cur;
    reg dp_cur;

    always @(*) begin
        case (seg_num)
            0: begin an = 4'b1110; char_cur = char1; dp_cur = decimalpoints[0]; end
            1: begin an = 4'b1101; char_cur = char2; dp_cur = decimalpoints[1]; end
            2: begin an = 4'b1011; char_cur = char3; dp_cur = decimalpoints[2]; end
            3: begin an = 4'b0111; char_cur = char4; dp_cur = decimalpoints[3]; end
            default: begin an = 4'b0000; char_cur = 6'b000000; dp_cur = 1; end
        endcase
    end

    always @(*) begin
        case (char_cur)
            0: seg = { ~dp_cur, 7'b1000000 };
            1: seg = { ~dp_cur, 7'b1111001 };
            2: seg = { ~dp_cur, 7'b0100100 };
            3: seg = { ~dp_cur, 7'b0110000 };
            4: seg = { ~dp_cur, 7'b0011001 };
            5: seg = { ~dp_cur, 7'b0010010 };
            6: seg = { ~dp_cur, 7'b0000010 };
            7: seg = { ~dp_cur, 7'b1111000 };
            8: seg = { ~dp_cur, 7'b0000000 };
            9: seg = { ~dp_cur, 7'b0010000 };
            default: seg = 8'b11111111;
        endcase
    end

endmodule
