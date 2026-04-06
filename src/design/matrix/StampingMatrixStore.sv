`timescale 1ns / 1ps

module StampingMatrixStore #(
    parameter integer DIM = 8,
    parameter integer CELL_COUNT = DIM * DIM
) (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        accumA_start,
    input  wire [15:0] accumA_i,
    input  wire [15:0] accumA_j,
    input  wire [31:0] accumA_delta,
    output reg         accumA_done,

    input  wire        fetchA_start,
    input  wire [15:0] fetchA_i,
    input  wire [15:0] fetchA_j,
    output reg         fetchA_done,
    output reg  [31:0] fetchA_result
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
      accumA_done <= 1'b0;
      fetchA_done <= 1'b0;
      fetchA_result <= '0;
      fetch_pending <= 1'b0;
      fetch_pending_i <= '0;
      fetch_pending_j <= '0;
      for (idx = 0; idx < CELL_COUNT; idx = idx + 1) begin
        mem[idx] <= '0;
      end
    end else begin
      accumA_done <= accumA_start;
      if (accumA_start && (accumA_i < DIM) && (accumA_j < DIM)) begin
        idx = flatten_addr(accumA_i, accumA_j);
        mem[idx] <= fp_add_comb(mem[idx], accumA_delta);
      end

      fetchA_done <= fetch_pending;
      if (fetch_pending) begin
        if ((fetch_pending_i < DIM) && (fetch_pending_j < DIM)) begin
          idx = flatten_addr(fetch_pending_i, fetch_pending_j);
          fetchA_result <= mem[idx];
        end else begin
          fetchA_result <= '0;
        end
      end

      fetch_pending <= fetchA_start;
      if (fetchA_start) begin
        fetch_pending_i <= fetchA_i;
        fetch_pending_j <= fetchA_j;
      end
    end
  end

endmodule
