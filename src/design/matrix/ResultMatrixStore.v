`timescale 1ns / 1ps

module ResultMatrixStore #(
    parameter integer GRID_WIDTH = 8,
    parameter integer GRID_HEIGHT = 8,
    parameter integer CELL_COUNT = GRID_WIDTH * GRID_HEIGHT,
    parameter integer ADDR_WIDTH = (CELL_COUNT <= 1) ? 1 : $clog2(CELL_COUNT),
    parameter integer EPOCH_WIDTH = 16
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       clear,
    input  wire       storeR_start,
    input  wire [7:0] storeR_i,
    input  wire [7:0] storeR_j,
    input  wire [7:0] storeR_v,
    output reg        storeR_done,
    input  wire       fetchR_start,
    input  wire [7:0] fetchR_i,
    input  wire [7:0] fetchR_j,
    output reg        fetchR_done,
    output reg  [7:0] fetchR_result
);

  (* ram_style = "block" *)
  reg [7:0] data_mem[0:CELL_COUNT-1];
  (* ram_style = "block" *)
  reg [EPOCH_WIDTH-1:0] tag_mem[0:CELL_COUNT-1];
  reg       fetch_req_valid;
  reg       fetch_req_in_range;
  reg       fetch_resp_valid;
  reg       fetch_resp_in_range;
  reg [ADDR_WIDTH-1:0] rd_addr;
  reg [7:0] rd_data;
  reg [EPOCH_WIDTH-1:0] rd_tag;
  reg [EPOCH_WIDTH-1:0] epoch;

  integer idx;
  wire store_in_range = (storeR_i < GRID_WIDTH) && (storeR_j < GRID_HEIGHT);
  wire fetch_in_range = (fetchR_i < GRID_WIDTH) && (fetchR_j < GRID_HEIGHT);

  function automatic [ADDR_WIDTH-1:0] flatten_addr(
      input [7:0] i,
      input [7:0] j
  );
    begin
      flatten_addr = j * GRID_WIDTH + i;
    end
  endfunction

  initial begin
    rd_data = 8'd0;
    rd_tag = {EPOCH_WIDTH{1'b0}};
    epoch = {{(EPOCH_WIDTH-1){1'b0}}, 1'b1};
    for (idx = 0; idx < CELL_COUNT; idx = idx + 1) begin
      data_mem[idx] = 8'd0;
      tag_mem[idx] = {EPOCH_WIDTH{1'b0}};
    end
  end

`ifndef SYNTHESIS
  wire [7:0] mem[0:CELL_COUNT-1];
  genvar g;
  generate
    for (g = 0; g < CELL_COUNT; g = g + 1) begin : gen_mem_view
      assign mem[g] = (tag_mem[g] == epoch) ? data_mem[g] : 8'd0;
    end
  endgenerate
`endif

  always @(posedge clk) begin
    if (storeR_start && store_in_range) begin
      data_mem[flatten_addr(storeR_i, storeR_j)] <= storeR_v;
      tag_mem[flatten_addr(storeR_i, storeR_j)] <= epoch;
    end
  end

  always @(posedge clk) begin
    rd_data <= data_mem[rd_addr];
    rd_tag <= tag_mem[rd_addr];
  end

  always @(posedge clk) begin
    if (!rst_n || clear) begin
      storeR_done <= 1'b0;
      fetchR_done <= 1'b0;
      fetchR_result <= 8'd0;
      fetch_req_valid <= 1'b0;
      fetch_req_in_range <= 1'b0;
      fetch_resp_valid <= 1'b0;
      fetch_resp_in_range <= 1'b0;
      rd_addr <= {ADDR_WIDTH{1'b0}};
      epoch <= epoch + {{(EPOCH_WIDTH-1){1'b0}}, 1'b1};
    end else begin
      storeR_done <= storeR_start;
      fetchR_done <= fetch_resp_valid;
      if (fetch_resp_valid && fetch_resp_in_range && (rd_tag == epoch)) begin
        fetchR_result <= rd_data;
      end else begin
        fetchR_result <= 8'd0;
      end

      fetch_resp_valid <= fetch_req_valid;
      fetch_resp_in_range <= fetch_req_in_range;
      fetch_req_valid <= fetchR_start;
      fetch_req_in_range <= fetch_in_range;
      if (fetchR_start && fetch_in_range) begin
        rd_addr <= flatten_addr(fetchR_i, fetchR_j);
      end
    end
  end

endmodule
