`timescale 1ns / 1ps

module StampingVectorStore #(
    parameter integer DIM = 8
) (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        accumJ_start,
    input  wire [15:0] accumJ_i,
    input  wire [31:0] accumJ_delta,
    output reg         accumJ_done,

    input  wire        fetchJ_start,
    input  wire [15:0] fetchJ_i,
    output reg         fetchJ_done,
    output reg  [31:0] fetchJ_result
);

  import StampingCombPkg::*;

  reg [31:0] mem[0:DIM-1];

  reg fetch_pending;
  reg [15:0] fetch_pending_i;

  integer idx;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      accumJ_done <= 1'b0;
      fetchJ_done <= 1'b0;
      fetchJ_result <= '0;
      fetch_pending <= 1'b0;
      fetch_pending_i <= '0;
      for (idx = 0; idx < DIM; idx = idx + 1) begin
        mem[idx] <= '0;
      end
    end else begin
      accumJ_done <= accumJ_start;
      if (accumJ_start && (accumJ_i < DIM)) begin
        mem[accumJ_i] <= fp_add_comb(mem[accumJ_i], accumJ_delta);
      end

      fetchJ_done <= fetch_pending;
      if (fetch_pending) begin
        fetchJ_result <= (fetch_pending_i < DIM) ? mem[fetch_pending_i] : '0;
      end

      fetch_pending <= fetchJ_start;
      if (fetchJ_start) begin
        fetch_pending_i <= fetchJ_i;
      end
    end
  end

endmodule
