`timescale 1ns / 1ps

module SolverMatrixStore #(
    parameter integer DIM = 8,
    parameter integer CELL_COUNT = DIM * DIM
) (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        store_start,
    input  wire [15:0] store_i,
    input  wire [15:0] store_j,
    input  wire [31:0] store_v,
    output reg         store_done,

    input  wire        fetch_start,
    input  wire [15:0] fetch_i,
    input  wire [15:0] fetch_j,
    output reg         fetch_done,
    output reg  [31:0] fetch_result,

    input  wire        accum_start,
    input  wire [15:0] accum_i,
    input  wire [15:0] accum_j,
    input  wire [31:0] accum_delta,
    output reg         accum_done
);

  import StampingCombPkg::*;

  reg [31:0] mem[0:CELL_COUNT-1];
  reg fetch_pending;
  reg [15:0] fetch_pending_i;
  reg [15:0] fetch_pending_j;

  integer idx;

  function automatic integer flatten_addr(
      input [15:0] i,
      input [15:0] j
  );
    begin
      flatten_addr = i * DIM + j;
    end
  endfunction

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      store_done <= 1'b0;
      fetch_done <= 1'b0;
      fetch_result <= '0;
      accum_done <= 1'b0;
      fetch_pending <= 1'b0;
      fetch_pending_i <= '0;
      fetch_pending_j <= '0;
      for (idx = 0; idx < CELL_COUNT; idx = idx + 1) begin
        mem[idx] <= '0;
      end
    end else begin
      store_done <= store_start;
      if (store_start && (store_i < DIM) && (store_j < DIM)) begin
        idx = flatten_addr(store_i, store_j);
        mem[idx] <= store_v;
      end

      accum_done <= accum_start;
      if (accum_start && (accum_i < DIM) && (accum_j < DIM)) begin
        idx = flatten_addr(accum_i, accum_j);
        mem[idx] <= fp_add_comb(mem[idx], accum_delta);
      end

      fetch_done <= fetch_pending;
      if (fetch_pending) begin
        if ((fetch_pending_i < DIM) && (fetch_pending_j < DIM)) begin
          idx = flatten_addr(fetch_pending_i, fetch_pending_j);
          fetch_result <= mem[idx];
        end else begin
          fetch_result <= '0;
        end
      end

      fetch_pending <= fetch_start;
      if (fetch_start) begin
        fetch_pending_i <= fetch_i;
        fetch_pending_j <= fetch_j;
      end
    end
  end

endmodule
