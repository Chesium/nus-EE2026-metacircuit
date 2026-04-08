`timescale 1ns / 1ps

module ResultMatrixStore #(
    parameter integer GRID_WIDTH = 8,
    parameter integer GRID_HEIGHT = 8,
    parameter integer CELL_COUNT = GRID_WIDTH * GRID_HEIGHT
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       storeR_start,
    input  wire [7:0] storeR_i,
    input  wire [7:0] storeR_j,
    input  wire [7:0] storeR_v,
    output reg        storeR_done
);

  reg [7:0] mem[0:CELL_COUNT-1];

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
      storeR_done <= 1'b0;
      for (idx = 0; idx < CELL_COUNT; idx = idx + 1) begin
        mem[idx] <= 8'd0;
      end
    end else begin
      storeR_done <= storeR_start;
      if (storeR_start && (storeR_i < GRID_WIDTH) && (storeR_j < GRID_HEIGHT)) begin
        idx = flatten_addr(storeR_i, storeR_j);
        mem[idx] <= storeR_v;
      end
    end
  end

endmodule
