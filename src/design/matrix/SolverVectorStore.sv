`timescale 1ns / 1ps

module SolverVectorStore #(
    parameter integer DIM = 8
) (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        store_start,
    input  wire [15:0] store_i,
    input  wire [31:0] store_v,
    output reg         store_done,

    input  wire        fetch_start,
    input  wire [15:0] fetch_i,
    output reg         fetch_done,
    output reg  [31:0] fetch_result,

    input  wire        accum_start,
    input  wire [15:0] accum_i,
    input  wire [31:0] accum_delta,
    output reg         accum_done
);

  import StampingCombPkg::*;

  reg [31:0] mem[0:DIM-1];
  reg fetch_pending;
  reg [15:0] fetch_pending_i;

  integer idx;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      store_done <= 1'b0;
      fetch_done <= 1'b0;
      fetch_result <= '0;
      accum_done <= 1'b0;
      fetch_pending <= 1'b0;
      fetch_pending_i <= '0;
      for (idx = 0; idx < DIM; idx = idx + 1) begin
        mem[idx] <= '0;
      end
    end else begin
      store_done <= store_start;
      if (store_start && (store_i < DIM)) begin
        mem[store_i] <= store_v;
      end

      accum_done <= accum_start;
      if (accum_start && (accum_i < DIM)) begin
        mem[accum_i] <= fp_add_comb(mem[accum_i], accum_delta);
      end

      fetch_done <= fetch_pending;
      if (fetch_pending) begin
        fetch_result <= (fetch_pending_i < DIM) ? mem[fetch_pending_i] : '0;
      end

      fetch_pending <= fetch_start;
      if (fetch_start) begin
        fetch_pending_i <= fetch_i;
      end
    end
  end

endmodule
