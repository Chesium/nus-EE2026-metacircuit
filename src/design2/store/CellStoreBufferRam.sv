`timescale 1ns / 1ps

module CellStoreBufferRam #(
    parameter integer WordWidth = 16,
    parameter integer WordCount = 1024,
    parameter integer AddrWidth = $clog2(WordCount)
) (
    input  wire                 render_clk,
    input  wire [AddrWidth-1:0] render_r_addr,
    output reg  [WordWidth-1:0] render_d_out,

    input  wire                 sys_clk,
    input  wire                 sys_w_en,
    input  wire [AddrWidth-1:0] sys_w_addr,
    input  wire [AddrWidth-1:0] sys_r_addr,
    input  wire [WordWidth-1:0] sys_d_in,
    output reg  [WordWidth-1:0] sys_d_out
);

  (* ram_style = "block" *)
  reg [WordWidth-1:0] mem [0:WordCount-1];

  always @(posedge render_clk) begin
    render_d_out <= mem[render_r_addr];
  end

  always @(posedge sys_clk) begin
    if (sys_w_en) begin
      mem[sys_w_addr] <= sys_d_in;
    end
    sys_d_out <= mem[sys_r_addr];
  end

endmodule
