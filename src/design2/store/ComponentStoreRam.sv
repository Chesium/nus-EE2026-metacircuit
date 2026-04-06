`timescale 1ns / 1ps

module ComponentStoreRam #(
    parameter integer WordWidth = 40,
    parameter integer WordCount = 64,
    parameter integer AddrWidth = $clog2(WordCount)
) (
    input  wire                 clk,
    input  wire                 w_en,
    input  wire [AddrWidth-1:0] w_addr,
    input  wire [AddrWidth-1:0] r_addr,
    input  wire [WordWidth-1:0] d_in,
    output reg  [WordWidth-1:0] d_out
);

  (* ram_style = "block" *)
  reg [WordWidth-1:0] mem [0:WordCount-1];

  always @(posedge clk) begin
    if (w_en) begin
      mem[w_addr] <= d_in;
    end
    d_out <= mem[r_addr];
  end

endmodule
