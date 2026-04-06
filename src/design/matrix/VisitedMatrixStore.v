`timescale 1ns / 1ps

module VisitedMatrixStore #(
    parameter integer GRID_WIDTH = 8,
    parameter integer GRID_HEIGHT = 8,
    parameter integer CELL_COUNT = GRID_WIDTH * GRID_HEIGHT
) (
    input  wire       clk,
    input  wire       rst_n,

    input  wire       getVisited_start,
    input  wire [7:0] getVisited_i,
    input  wire [7:0] getVisited_j,
    output reg        getVisited_done,
    output reg        getVisited_result,

    input  wire       setVisited_start,
    input  wire [7:0] setVisited_i,
    input  wire [7:0] setVisited_j,
    output reg        setVisited_done
);

  reg mem[0:CELL_COUNT-1];

  reg       pending_get_valid;
  reg [7:0] pending_get_i;
  reg [7:0] pending_get_j;

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
      pending_get_valid <= 1'b0;
      pending_get_i <=0;
      pending_get_j <=0;
      getVisited_done <= 1'b0;
      getVisited_result <= 1'b0;
      setVisited_done <= 1'b0;
      for (idx = 0; idx < CELL_COUNT; idx = idx + 1) begin
        mem[idx] <= 1'b0;
      end
    end else begin
      getVisited_done <= pending_get_valid;
      if (pending_get_valid) begin
        if ((pending_get_i < GRID_WIDTH) && (pending_get_j < GRID_HEIGHT)) begin
          idx = flatten_addr(pending_get_i, pending_get_j);
          getVisited_result <= mem[idx];
        end else begin
          getVisited_result <= 1'b0;
        end
      end

      setVisited_done <= setVisited_start;
      if (setVisited_start && (setVisited_i < GRID_WIDTH) && (setVisited_j < GRID_HEIGHT)) begin
        idx = flatten_addr(setVisited_i, setVisited_j);
        mem[idx] <= 1'b1;
      end

      pending_get_valid <= getVisited_start;
      if (getVisited_start) begin
        pending_get_i <= getVisited_i;
        pending_get_j <= getVisited_j;
      end
    end
  end

endmodule
