`timescale 1ns / 1ps

module SimpleRam #(
    parameter integer WordWidth = 32,
    parameter integer WordCount = 16,
    parameter integer AddrWidth = $clog2(WordCount)
) (
    input  wire                 clk,
    input  wire                 w_en,    // write enable
    input  wire [AddrWidth-1:0] w_addr,
    input  wire [AddrWidth-1:0] r_addr,
    input  wire [WordWidth-1:0] d_in,
    output reg  [WordWidth-1:0] d_out
);

  // Ask Vivado to prefer Block RAM
  (* ram_style = "block" *)
  reg [WordWidth-1:0] mem[WordCount-1:0];

  always @(posedge clk) begin
    if (w_en) begin
      mem[w_addr] <= d_in;
    end
    d_out <= mem[r_addr];  // synchronous read
  end

endmodule
