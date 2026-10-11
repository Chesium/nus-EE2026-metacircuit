`timescale 1ns / 1ps

module VisitedMatrixStore #(
    parameter integer GRID_WIDTH = 8,
    parameter integer GRID_HEIGHT = 8,
    parameter integer CELL_COUNT = GRID_WIDTH * GRID_HEIGHT,
    parameter integer ADDR_WIDTH = (CELL_COUNT <= 1) ? 1 : $clog2(CELL_COUNT),
    parameter integer EPOCH_WIDTH = 16
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       clear,

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

  (* ram_style = "block" *)
  reg [EPOCH_WIDTH-1:0] tag_mem[0:CELL_COUNT-1];
  reg       get_req_valid;
  reg       get_req_in_range;
  reg       get_resp_valid;
  reg       get_resp_in_range;
  reg [ADDR_WIDTH-1:0] rd_addr;
  reg [EPOCH_WIDTH-1:0] rd_tag;
  reg [EPOCH_WIDTH-1:0] epoch;

  integer idx;
  wire get_in_range = (getVisited_i < GRID_WIDTH) && (getVisited_j < GRID_HEIGHT);
  wire set_in_range = (setVisited_i < GRID_WIDTH) && (setVisited_j < GRID_HEIGHT);

  function automatic [ADDR_WIDTH-1:0] flatten_addr(
      input [7:0] i,
      input [7:0] j
  );
    begin
      flatten_addr = j * GRID_WIDTH + i;
    end
  endfunction

  initial begin
    rd_tag = {EPOCH_WIDTH{1'b0}};
    epoch = {{(EPOCH_WIDTH-1){1'b0}}, 1'b1};
    for (idx = 0; idx < CELL_COUNT; idx = idx + 1) begin
      tag_mem[idx] = {EPOCH_WIDTH{1'b0}};
    end
  end

`ifndef SYNTHESIS
  wire mem[0:CELL_COUNT-1];
  genvar g;
  generate
    for (g = 0; g < CELL_COUNT; g = g + 1) begin : gen_mem_view
      assign mem[g] = (tag_mem[g] == epoch);
    end
  endgenerate
`endif

  always @(posedge clk) begin
    if (setVisited_start && set_in_range) begin
      tag_mem[flatten_addr(setVisited_i, setVisited_j)] <= epoch;
    end
  end

  always @(posedge clk) begin
    rd_tag <= tag_mem[rd_addr];
  end

  always @(posedge clk) begin
    if (!rst_n || clear) begin
      get_req_valid <= 1'b0;
      get_req_in_range <= 1'b0;
      get_resp_valid <= 1'b0;
      get_resp_in_range <= 1'b0;
      rd_addr <= {ADDR_WIDTH{1'b0}};
      epoch <= epoch + {{(EPOCH_WIDTH-1){1'b0}}, 1'b1};
      getVisited_done <= 1'b0;
      getVisited_result <= 1'b0;
      setVisited_done <= 1'b0;
    end else begin
      getVisited_done <= get_resp_valid;
      if (get_resp_valid && get_resp_in_range) begin
        getVisited_result <= (rd_tag == epoch);
      end else begin
        getVisited_result <= 1'b0;
      end

      setVisited_done <= setVisited_start;

      get_resp_valid <= get_req_valid;
      get_resp_in_range <= get_req_in_range;
      get_req_valid <= getVisited_start;
      get_req_in_range <= get_in_range;
      if (getVisited_start && get_in_range) begin
        rd_addr <= flatten_addr(getVisited_i, getVisited_j);
      end
    end
  end

endmodule
