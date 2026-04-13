`timescale 1ns / 1ps

module StampingVectorStore_test;
  import StampingLegacyCombPkg::*;

  localparam integer DIM = 4;

  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk;

  reg accumJ_start = 1'b0;
  reg [15:0] accumJ_i = '0;
  reg [31:0] accumJ_delta = '0;
  wire accumJ_done;

  reg fetchJ_start = 1'b0;
  reg [15:0] fetchJ_i = '0;
  wire fetchJ_done;
  wire [31:0] fetchJ_result;

  StampingVectorStore #(
      .DIM(DIM)
  ) dut (
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

  task automatic accum_entry(
      input [15:0] i,
      input [31:0] delta
  );
    begin
      @(negedge clk);
      accumJ_i <= i;
      accumJ_delta <= delta;
      accumJ_start <= 1'b1;
      @(posedge clk);
      #1;
      if (accumJ_done !== 1'b1) begin
        $fatal(1, "accumJ_done missing for idx=%0d", i);
      end
      @(negedge clk);
      accumJ_start <= 1'b0;
    end
  endtask

  task automatic fetch_entry_expect_real(
      input [15:0] i,
      input real expected
  );
    real got_value;
    real abs_err;
    begin
      @(negedge clk);
      fetchJ_i <= i;
      fetchJ_start <= 1'b1;
      @(negedge clk);
      fetchJ_start <= 1'b0;
      @(posedge clk);
      #1;
      if (fetchJ_done !== 1'b1) begin
        $fatal(1, "fetchJ_done missing for idx=%0d", i);
      end
      got_value = fp_to_real(fetchJ_result);
      abs_err = (got_value > expected) ? (got_value - expected) : (expected - got_value);
      if (abs_err > 1e-6) begin
        $fatal(1, "fetchJ mismatch for idx=%0d: got=%e expected=%e", i, got_value, expected);
      end
    end
  endtask

  initial begin
    repeat (4) @(negedge clk);
    rst_n <= 1'b1;

    accum_entry(16'd2, $shortrealtobits(0.25));
    accum_entry(16'd2, neg_comb($shortrealtobits(0.5)));
    fetch_entry_expect_real(16'd2, -0.25);

    accum_entry(16'd7, $shortrealtobits(3.0));
    fetch_entry_expect_real(16'd2, -0.25);

    $display("StampingVectorStore_test passed.");
    $finish;
  end
endmodule
