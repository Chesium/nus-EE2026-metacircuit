`timescale 1ns / 1ps

module Hex7SegMux (
    input  wire        clk,
    input  wire [15:0] hex_value,
    output reg  [7:0]  SEG = 8'hFF,
    output reg  [3:0]  AN  = 4'hF
);

    reg [17:0] refresh_ctr = 18'd0;
    wire [1:0] digit_sel = refresh_ctr[17:16];

    reg [3:0] digit_nibble;

    always @(posedge clk) begin
        refresh_ctr <= refresh_ctr + 1'b1;
    end

    always @(*) begin
        case (digit_sel)
            2'd0: begin
                AN = 4'b1110;
                digit_nibble = hex_value[3:0];
            end
            2'd1: begin
                AN = 4'b1101;
                digit_nibble = hex_value[7:4];
            end
            2'd2: begin
                AN = 4'b1011;
                digit_nibble = hex_value[11:8];
            end
            default: begin
                AN = 4'b0111;
                digit_nibble = hex_value[15:12];
            end
        endcase

        case (digit_nibble)
            4'h0: SEG = 8'b1100_0000;
            4'h1: SEG = 8'b1111_1001;
            4'h2: SEG = 8'b1010_0100;
            4'h3: SEG = 8'b1011_0000;
            4'h4: SEG = 8'b1001_1001;
            4'h5: SEG = 8'b1001_0010;
            4'h6: SEG = 8'b1000_0010;
            4'h7: SEG = 8'b1111_1000;
            4'h8: SEG = 8'b1000_0000;
            4'h9: SEG = 8'b1001_0000;
            4'hA: SEG = 8'b1000_1000;
            4'hB: SEG = 8'b1000_0011;
            4'hC: SEG = 8'b1100_0110;
            4'hD: SEG = 8'b1010_0001;
            4'hE: SEG = 8'b1000_0110;
            default: SEG = 8'b1000_1110;
        endcase
    end
endmodule
