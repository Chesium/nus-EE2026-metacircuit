`timescale 1ns / 1ps

module SolverMatrixStore_test;
  localparam integer DIM = 4;

  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk;

  reg store_start = 1'b0;
  reg [15:0] store_i = '0;
  reg [15:0] store_j = '0;
  reg [31:0] store_v = '0;
  wire store_done;

  reg fetch_start = 1'b0;
  reg [15:0] fetch_i = '0;
  reg [15:0] fetch_j = '0;
  wire fetch_done;
  wire [31:0] fetch_result;

  reg accum_start = 1'b0;
  reg [15:0] accum_i = '0;
  reg [15:0] accum_j = '0;
  reg [31:0] accum_delta = '0;
  wire accum_done;

  shortreal got_sr;
  shortreal exp_sr;
  real got_r;
  real exp_r;

  function automatic [31:0] real_to_bits(input real value);
    shortreal value_sr;
    begin
      value_sr = value;
      real_to_bits = $shortrealtobits(value_sr);
    end
  endfunction

  function automatic real abs_real(input real value);
    begin
      abs_real = (value < 0.0) ? -value : value;
    end
  endfunction

  SolverMatrixStore #(
      .DIM(DIM)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .store_start(store_start),
      .store_i(store_i),
      .store_j(store_j),
      .store_v(store_v),
      .store_done(store_done),
      .fetch_start(fetch_start),
      .fetch_i(fetch_i),
      .fetch_j(fetch_j),
      .fetch_done(fetch_done),
      .fetch_result(fetch_result),
      .accum_start(accum_start),
      .accum_i(accum_i),
      .accum_j(accum_j),
      .accum_delta(accum_delta),
      .accum_done(accum_done)
  );

  task automatic do_store(input [15:0] i, input [15:0] j, input [31:0] v);
    begin
      @(negedge clk);
      store_i <= i;
      store_j <= j;
      store_v <= v;
      store_start <= 1'b1;
      @(negedge clk);
      store_start <= 1'b0;
      if (store_done !== 1'b1) begin
        $fatal(1, "store_done did not pulse");
      end
    end
  endtask

  task automatic do_accum(input [15:0] i, input [15:0] j, input [31:0] delta);
    begin
      @(negedge clk);
      accum_i <= i;
      accum_j <= j;
      accum_delta <= delta;
      accum_start <= 1'b1;
      @(negedge clk);
      accum_start <= 1'b0;
      if (accum_done !== 1'b1) begin
        $fatal(1, "accum_done did not pulse");
      end
    end
  endtask

  task automatic expect_fetch(input [15:0] i, input [15:0] j, input real expected_value);
    begin
      @(negedge clk);
      fetch_i <= i;
      fetch_j <= j;
      fetch_start <= 1'b1;
      @(negedge clk);
      fetch_start <= 1'b0;
      while (fetch_done !== 1'b1) begin
        @(posedge clk);
      end
      if (fetch_done !== 1'b1) begin
        $fatal(1, "fetch_done did not pulse");
      end
      got_sr = $bitstoshortreal(fetch_result);
      exp_sr = expected_value;
      got_r = got_sr;
      exp_r = exp_sr;
      if (abs_real(got_r - exp_r) > 1e-5) begin
        $fatal(1, "fetch mismatch at (%0d,%0d): got=%e expected=%e", i, j, got_r, exp_r);
      end
    end
  endtask

  initial begin
    repeat (4) @(negedge clk);
    rst_n <= 1'b1;

    do_store(16'd1, 16'd2, real_to_bits(2.5));
    expect_fetch(16'd1, 16'd2, 2.5);

    do_accum(16'd1, 16'd2, real_to_bits(1.25));
    expect_fetch(16'd1, 16'd2, 3.75);

    do_store(16'd3, 16'd0, real_to_bits(-4.0));
    expect_fetch(16'd3, 16'd0, -4.0);

    $display("SolverMatrixStore_test passed.");
    $finish;
  end
endmodule
