`timescale 1ns / 1ps

module PortGridStore #(
    parameter integer GRID_WIDTH = 8,
    parameter integer GRID_HEIGHT = 8,
    parameter integer CELL_COUNT = GRID_WIDTH * GRID_HEIGHT
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       fetchP_start,
    input  wire [7:0] fetchP_i,
    input  wire [7:0] fetchP_j,
    output reg        fetchP_done,
    output reg  [3:0] fetchP_result
);

  reg [3:0] mem[0:CELL_COUNT-1];

  reg       pending_valid;
  reg [7:0] pending_i;
  reg [7:0] pending_j;

  integer idx;

  function automatic integer flatten_addr(
      input [7:0] i,
      input [7:0] j
  );
    begin
      flatten_addr = j * GRID_WIDTH + i;
    end
  endfunction

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pending_valid <= 1'b0;
      pending_i <=0;
      pending_j <=0;
      fetchP_done <= 1'b0;
      fetchP_result <=0;
    end else begin
      fetchP_done <= pending_valid;
      if (pending_valid) begin
        if ((pending_i < GRID_WIDTH) && (pending_j < GRID_HEIGHT)) begin
          idx = flatten_addr(pending_i, pending_j);
          fetchP_result <= mem[idx];
        end else begin
          fetchP_result <= 4'b0000;
        end
      end

      pending_valid <= fetchP_start;
      if (fetchP_start) begin
        pending_i <= fetchP_i;
        pending_j <= fetchP_j;
      end
    end
  end

endmodule
