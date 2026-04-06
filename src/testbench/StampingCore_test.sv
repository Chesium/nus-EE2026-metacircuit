`timescale 1ns / 1ps

module StampingCore_test;
  localparam integer ELEM_COUNT = 7;
  localparam integer DIM = 7;
  localparam integer A_CELL_COUNT = DIM * DIM;

  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk;

  reg start = 1'b0;
  wire busy;
  wire done;

  wire fetchElemKind_start;
  wire [15:0] fetchElemKind_idx;
  wire fetchElemKind_done;
  wire [7:0] fetchElemKind_result;

  wire fetchElemN0_start;
  wire [15:0] fetchElemN0_idx;
  wire fetchElemN0_done;
  wire [15:0] fetchElemN0_result;

  wire fetchElemN1_start;
  wire [15:0] fetchElemN1_idx;
  wire fetchElemN1_done;
  wire [15:0] fetchElemN1_result;

  wire fetchElemN2_start;
  wire [15:0] fetchElemN2_idx;
  wire fetchElemN2_done;
  wire [15:0] fetchElemN2_result;

  wire fetchElemN3_start;
  wire [15:0] fetchElemN3_idx;
  wire fetchElemN3_done;
  wire [15:0] fetchElemN3_result;

  wire fetchElemAux_start;
  wire [15:0] fetchElemAux_idx;
  wire fetchElemAux_done;
  wire [15:0] fetchElemAux_result;

  wire fetchElemVal0_start;
  wire [15:0] fetchElemVal0_idx;
  wire fetchElemVal0_done;
  wire [31:0] fetchElemVal0_result;

  wire fetchElemVal1_start;
  wire [15:0] fetchElemVal1_idx;
  wire fetchElemVal1_done;
  wire [31:0] fetchElemVal1_result;

  wire fetchElemVal2_start;
  wire [15:0] fetchElemVal2_idx;
  wire fetchElemVal2_done;
  wire [31:0] fetchElemVal2_result;

  wire accumA_start;
  wire [15:0] accumA_i;
  wire [15:0] accumA_j;
  wire [31:0] accumA_delta;
  wire accumA_done;

  wire accumJ_start;
  wire [15:0] accumJ_i;
  wire [31:0] accumJ_delta;
  wire accumJ_done;

  reg fetchA_start = 1'b0;
  reg [15:0] fetchA_i = '0;
  reg [15:0] fetchA_j = '0;
  wire fetchA_done;
  wire [31:0] fetchA_result;

  reg fetchJ_start = 1'b0;
  reg [15:0] fetchJ_i = '0;
  wire fetchJ_done;
  wire [31:0] fetchJ_result;

  stamping_core dut (
      .clk(clk),
      .rst_n(rst_n),
      .start(start),
      .busy(busy),
      .done(done),
      .par_elem_n(ELEM_COUNT),
      .fetchElemKind_start(fetchElemKind_start),
      .fetchElemKind_idx(fetchElemKind_idx),
      .fetchElemKind_done(fetchElemKind_done),
      .fetchElemKind_result(fetchElemKind_result),
      .fetchElemN0_start(fetchElemN0_start),
      .fetchElemN0_idx(fetchElemN0_idx),
      .fetchElemN0_done(fetchElemN0_done),
      .fetchElemN0_result(fetchElemN0_result),
      .fetchElemN1_start(fetchElemN1_start),
      .fetchElemN1_idx(fetchElemN1_idx),
      .fetchElemN1_done(fetchElemN1_done),
      .fetchElemN1_result(fetchElemN1_result),
      .fetchElemN2_start(fetchElemN2_start),
      .fetchElemN2_idx(fetchElemN2_idx),
      .fetchElemN2_done(fetchElemN2_done),
      .fetchElemN2_result(fetchElemN2_result),
      .fetchElemN3_start(fetchElemN3_start),
      .fetchElemN3_idx(fetchElemN3_idx),
      .fetchElemN3_done(fetchElemN3_done),
      .fetchElemN3_result(fetchElemN3_result),
      .fetchElemAux_start(fetchElemAux_start),
      .fetchElemAux_idx(fetchElemAux_idx),
      .fetchElemAux_done(fetchElemAux_done),
      .fetchElemAux_result(fetchElemAux_result),
      .fetchElemVal0_start(fetchElemVal0_start),
      .fetchElemVal0_idx(fetchElemVal0_idx),
      .fetchElemVal0_done(fetchElemVal0_done),
      .fetchElemVal0_result(fetchElemVal0_result),
      .fetchElemVal1_start(fetchElemVal1_start),
      .fetchElemVal1_idx(fetchElemVal1_idx),
      .fetchElemVal1_done(fetchElemVal1_done),
      .fetchElemVal1_result(fetchElemVal1_result),
      .fetchElemVal2_start(fetchElemVal2_start),
      .fetchElemVal2_idx(fetchElemVal2_idx),
      .fetchElemVal2_done(fetchElemVal2_done),
      .fetchElemVal2_result(fetchElemVal2_result),
      .accumA_start(accumA_start),
      .accumA_i(accumA_i),
      .accumA_j(accumA_j),
      .accumA_delta(accumA_delta),
      .accumA_done(accumA_done),
      .accumJ_start(accumJ_start),
      .accumJ_i(accumJ_i),
      .accumJ_delta(accumJ_delta),
      .accumJ_done(accumJ_done)
  );

  StampingNetlistStore #(
      .ELEM_COUNT(ELEM_COUNT)
  ) netlist_store (
      .clk(clk),
      .rst_n(rst_n),
      .fetchElemKind_start(fetchElemKind_start),
      .fetchElemKind_idx(fetchElemKind_idx),
      .fetchElemKind_done(fetchElemKind_done),
      .fetchElemKind_result(fetchElemKind_result),
      .fetchElemN0_start(fetchElemN0_start),
      .fetchElemN0_idx(fetchElemN0_idx),
      .fetchElemN0_done(fetchElemN0_done),
      .fetchElemN0_result(fetchElemN0_result),
      .fetchElemN1_start(fetchElemN1_start),
      .fetchElemN1_idx(fetchElemN1_idx),
      .fetchElemN1_done(fetchElemN1_done),
      .fetchElemN1_result(fetchElemN1_result),
      .fetchElemN2_start(fetchElemN2_start),
      .fetchElemN2_idx(fetchElemN2_idx),
      .fetchElemN2_done(fetchElemN2_done),
      .fetchElemN2_result(fetchElemN2_result),
      .fetchElemN3_start(fetchElemN3_start),
      .fetchElemN3_idx(fetchElemN3_idx),
      .fetchElemN3_done(fetchElemN3_done),
      .fetchElemN3_result(fetchElemN3_result),
      .fetchElemAux_start(fetchElemAux_start),
      .fetchElemAux_idx(fetchElemAux_idx),
      .fetchElemAux_done(fetchElemAux_done),
      .fetchElemAux_result(fetchElemAux_result),
      .fetchElemVal0_start(fetchElemVal0_start),
      .fetchElemVal0_idx(fetchElemVal0_idx),
      .fetchElemVal0_done(fetchElemVal0_done),
      .fetchElemVal0_result(fetchElemVal0_result),
      .fetchElemVal1_start(fetchElemVal1_start),
      .fetchElemVal1_idx(fetchElemVal1_idx),
      .fetchElemVal1_done(fetchElemVal1_done),
      .fetchElemVal1_result(fetchElemVal1_result),
      .fetchElemVal2_start(fetchElemVal2_start),
      .fetchElemVal2_idx(fetchElemVal2_idx),
      .fetchElemVal2_done(fetchElemVal2_done),
      .fetchElemVal2_result(fetchElemVal2_result)
  );

  StampingMatrixStore #(
      .DIM(DIM)
  ) matrix_store (
      .clk(clk),
      .rst_n(rst_n),
      .accumA_start(accumA_start),
      .accumA_i(accumA_i),
      .accumA_j(accumA_j),
      .accumA_delta(accumA_delta),
      .accumA_done(accumA_done),
      .fetchA_start(fetchA_start),
      .fetchA_i(fetchA_i),
      .fetchA_j(fetchA_j),
      .fetchA_done(fetchA_done),
      .fetchA_result(fetchA_result)
  );

  StampingVectorStore #(
      .DIM(DIM)
  ) vector_store (
      .clk(clk),
      .rst_n(rst_n),
      .accumJ_start(accumJ_start),
      .accumJ_i(accumJ_i),
      .accumJ_delta(accumJ_delta),
      .accumJ_done(accumJ_done),
      .fetchJ_start(fetchJ_start),
      .fetchJ_i(fetchJ_i),
      .fetchJ_done(fetchJ_done),
      .fetchJ_result(fetchJ_result)
  );

  reg [31:0] expected_A[0:A_CELL_COUNT-1];
  reg [31:0] expected_J[0:DIM-1];

  integer idx;
  integer mismatch_count;
  integer cycle_count;

  task automatic compare_results;
    begin
      mismatch_count = 0;
      for (idx = 0; idx < A_CELL_COUNT; idx = idx + 1) begin
        if (matrix_store.mem[idx] !== expected_A[idx]) begin
          mismatch_count = mismatch_count + 1;
          $display("A mismatch at idx=%0d: got=%h expected=%h",
                   idx, matrix_store.mem[idx], expected_A[idx]);
        end
      end
      for (idx = 0; idx < DIM; idx = idx + 1) begin
        if (vector_store.mem[idx] !== expected_J[idx]) begin
          mismatch_count = mismatch_count + 1;
          $display("J mismatch at idx=%0d: got=%h expected=%h",
                   idx, vector_store.mem[idx], expected_J[idx]);
        end
      end
    end
  endtask

  initial begin
    repeat (4) @(negedge clk);
    rst_n <= 1'b1;

    $readmemh("stamping_mixed_kind.mem", netlist_store.kind_mem);
    $readmemh("stamping_mixed_n0.mem", netlist_store.n0_mem);
    $readmemh("stamping_mixed_n1.mem", netlist_store.n1_mem);
    $readmemh("stamping_mixed_n2.mem", netlist_store.n2_mem);
    $readmemh("stamping_mixed_n3.mem", netlist_store.n3_mem);
    $readmemh("stamping_mixed_aux.mem", netlist_store.aux_mem);
    $readmemh("stamping_mixed_v0.mem", netlist_store.v0_mem);
    $readmemh("stamping_mixed_v1.mem", netlist_store.v1_mem);
    $readmemh("stamping_mixed_v2.mem", netlist_store.v2_mem);
    $readmemh("stamping_mixed_expected_A.mem", expected_A);
    $readmemh("stamping_mixed_expected_J.mem", expected_J);

    @(negedge clk);
    start <= 1'b1;
    @(negedge clk);
    start <= 1'b0;

    cycle_count = 0;
    while (done !== 1'b1 && cycle_count < 4000) begin
      @(posedge clk);
      cycle_count = cycle_count + 1;
    end

    if (done !== 1'b1) begin
      $fatal(1, "StampingCore_test timed out after %0d cycles", cycle_count);
    end

    #1;
    compare_results();

    if (mismatch_count != 0) begin
      $fatal(1, "StampingCore_test failed with %0d mismatches", mismatch_count);
    end

    $display("StampingCore_test passed in %0d cycles.", cycle_count);
    $finish;
  end
endmodule
