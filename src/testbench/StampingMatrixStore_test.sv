`timescale 1ns / 1ps

module StampingMatrixStore_test;
  import StampingCombPkg::*;

  localparam integer DIM = 4;

  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk;

  reg accumA_start = 1'b0;
  reg [15:0] accumA_i = '0;
  reg [15:0] accumA_j = '0;
  reg [31:0] accumA_delta = '0;
  wire accumA_done;

  reg fetchA_start = 1'b0;
  reg [15:0] fetchA_i = '0;
  reg [15:0] fetchA_j = '0;
  wire fetchA_done;
  wire [31:0] fetchA_result;

  StampingMatrixStore #(
      .DIM(DIM)
  ) dut (
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

  task automatic accum_cell(
      input [15:0] i,
      input [15:0] j,
      input [31:0] delta
  );
    begin
      @(negedge clk);
      accumA_i <= i;
      accumA_j <= j;
      accumA_delta <= delta;
      accumA_start <= 1'b1;
      @(posedge clk);
      #1;
      if (accumA_done !== 1'b1) begin
        $fatal(1, "accumA_done missing for (%0d,%0d)", i, j);
      end
      @(negedge clk);
      accumA_start <= 1'b0;
    end
  endtask

  task automatic fetch_cell_expect_real(
      input [15:0] i,
      input [15:0] j,
      input real expected
  );
    real got_value;
    real abs_err;
    begin
      @(negedge clk);
      fetchA_i <= i;
      fetchA_j <= j;
      fetchA_start <= 1'b1;
      @(negedge clk);
      fetchA_start <= 1'b0;
      @(posedge clk);
      #1;
      if (fetchA_done !== 1'b1) begin
        $fatal(1, "fetchA_done missing for (%0d,%0d)", i, j);
      end
      got_value = fp_to_real(fetchA_result);
      abs_err = (got_value > expected) ? (got_value - expected) : (expected - got_value);
      if (abs_err > 1e-6) begin
        $fatal(1, "fetchA mismatch for (%0d,%0d): got=%e expected=%e", i, j, got_value, expected);
      end
    end
  endtask

  initial begin
    repeat (4) @(negedge clk);
    rst_n <= 1'b1;

    accum_cell(16'd1, 16'd2, $shortrealtobits(1.25));
    accum_cell(16'd1, 16'd2, $shortrealtobits(2.5));
    fetch_cell_expect_real(16'd1, 16'd2, 3.75);

    accum_cell(16'd1, 16'd2, neg_comb($shortrealtobits(0.5)));
    fetch_cell_expect_real(16'd1, 16'd2, 3.25);

    accum_cell(16'd9, 16'd9, $shortrealtobits(7.0));
    fetch_cell_expect_real(16'd1, 16'd2, 3.25);

    $display("StampingMatrixStore_test passed.");
    $finish;
  end
endmodule
