`timescale 1ns / 1ps

// 1-bit Full Adder
// Used as building block for ripple-carry adder chain
module one_bit_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule
