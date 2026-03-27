`timescale 1ns / 1ps

module LU_hls_test ();

  reg clk_t_100m = 0;
  always #5 clk_t_100m = ~clk_t_100m;  // 10ns => 100MHz

  localparam integer TestMatrixSize = 8;
  localparam integer TestMatrixElementCount = TestMatrixSize * TestMatrixSize;
  localparam integer TestMatrixDimentionAddrLength = $clog2(TestMatrixSize);
  localparam integer TestMatrixAddrLength = $clog2(TestMatrixElementCount);

  localparam integer FloatLength = 32;

  reg                                     fetch_A_start;
  wire                                    fetch_A_busy;
  wire                                    fetch_A_done;
  reg [TestMatrixDimentionAddrLength-1:0] fetch_A_i; 
  reg [TestMatrixDimentionAddrLength-1:0] fetch_A_j;
  wire [FloatLength-1:0]                  fetch_A_result;
  reg                                     store_A_start;
  wire                                    store_A_busy;
  wire                                    store_A_done;
  reg [TestMatrixDimentionAddrLength-1:0] store_A_i; 
  reg [TestMatrixDimentionAddrLength-1:0] store_A_j;
  reg [FloatLength-1:0]                   store_A_v;

  matrixStore #(
    .SIZE(TestMatrixSize),
    .ELE_WIDTH(FloatLength)
  ) matrixstore_a_inst (
    .clk(clk_t_100m),
    .fetch_start(fetch_A_start),
    .fetch_busy(fetch_A_busy),
    .fetch_done(fetch_A_done),
    .fetch_i(fetch_A_i), 
    .fetch_j(fetch_A_j),
    .fetch_result(fetch_A_result),
    .store_start(store_A_start),
    .store_busy(store_A_busy),
    .store_done(store_A_done),
    .store_i(store_A_i), 
    .store_j(store_A_j),
    .store_v(store_A_v)
  );

  wire                                     fetch_LU_start;
  wire                                     fetch_LU_busy;
  wire                                     fetch_LU_done;
  wire [TestMatrixDimentionAddrLength-1:0] fetch_LU_i; 
  wire [TestMatrixDimentionAddrLength-1:0] fetch_LU_j;
  wire [FloatLength-1:0]                   fetch_LU_result;
  wire                                     store_LU_start;
  wire                                     store_LU_busy;
  wire                                     store_LU_done;
  wire [TestMatrixDimentionAddrLength-1:0] store_LU_i; 
  wire [TestMatrixDimentionAddrLength-1:0] store_LU_j;
  wire [FloatLength-1:0]                   store_LU_v;

  matrixStore #(
    .SIZE(TestMatrixSize),
    .ELE_WIDTH(FloatLength)
  ) matrixstore_lu_inst (
    .clk(clk_t_100m),
    .fetch_start(fetch_LU_start),
    .fetch_busy(fetch_LU_busy),
    .fetch_done(fetch_LU_done),
    .fetch_i(fetch_LU_i), 
    .fetch_j(fetch_LU_j),
    .fetch_result(fetch_LU_result),
    .store_start(store_LU_start),
    .store_busy(store_LU_busy),
    .store_done(store_LU_done),
    .store_i(store_LU_i), 
    .store_j(store_LU_j),
    .store_v(store_LU_v)
  );

  wire        fma_start;
  wire [31:0] fma_a;
  wire [31:0] fma_b;
  wire [31:0] fma_c;
  wire        fma_busy;
  wire        fma_done;
  wire [31:0] fma_result;
  wire        fma_underflow;
  wire        fma_overflow;
  wire        fma_invalid;
  
  /* Floating Point FMA IP Wrapper Instance */
  fpo_fma LUdecomp_FMA_inst (
      .clk(clk_t_100m),
      .start(fma_start),
      .a(fma_a),
      .b(fma_b),
      .c(fma_c),
      .busy(fma_busy),
      .done(fma_done),
      .result(fma_result),
      .exc_underflow(fma_underflow),
      .exc_overflow(fma_overflow),
      .exc_invalid(fma_invalid)
  );

  wire        div_start;
  wire [31:0] div_a;
  wire [31:0] div_b;
  wire        div_busy;
  wire        div_done;
  wire [31:0] div_result;
  wire        div_underflow;
  wire        div_overflow;
  wire        div_invalid;
  wire        div_div0;

  /* Floating Point DIV IP Wrapper Instance */
  fpo_div LUdecomp_DIV_inst (
      .clk(clk_t_100m),
      .start(div_start),
      .a(div_a),
      .b(div_b),
      .busy(div_busy),
      .done(div_done),
      .result(div_result),
      .exc_underflow(div_underflow),
      .exc_overflow(div_overflow),
      .exc_invalid(div_invalid),
      .exc_div0(div_div0)
  );

  reg  dut_start = 1'b0;
  wire dut_busy;
  wire dut_done;

  reg dut_rst_n = 1'b1;
  reg [31:0] dut_par_n = TestMatrixSize;

  lu_core lu_core_inst (
    .clk(clk_t_100m),
    .rst_n(dut_rst_n),
    .start(dut_start),
    .busy(dut_busy),
    .done(dut_done),
    .par_n(dut_par_n),
    .fetch_A_start(fetch_A_start),
    .fetch_A_i(fetch_A_i),
    .fetch_A_j(fetch_A_j),
    .fetch_A_done(fetch_A_done),
    .fetch_A_result(fetch_A_result),
    .fetch_LU_start(fetch_LU_start),
    .fetch_LU_i(fetch_LU_i),
    .fetch_LU_j(fetch_LU_j),
    .fetch_LU_done(fetch_LU_done),
    .fetch_LU_result(fetch_LU_result),
    .fma_start(fma_start),
    .fma_a(fma_a),
    .fma_b(fma_b),
    .fma_c(fma_c),
    .fma_done(fma_done),
    .fma_result(fma_result),
    .store_LU_start(store_LU_start),
    .store_LU_i(store_LU_i),
    .store_LU_j(store_LU_j),
    .store_LU_v(store_LU_v),
    .store_LU_done(store_LU_done),
    .div_start(div_start),
    .div_a(div_a),
    .div_b(div_b),
    .div_done(div_done),
    .div_result(div_result)
  );

  logic [31:0] matrix_lu_ref_mem[0:TestMatrixElementCount-1];

  integer mismatch_count;

  // Tune these depending on our reference model / FMA behavior
  real ABS_TOL = 1e-4;
  real REL_TOL = 1e-3;

  function automatic real abs_real(input real x);
    begin
      abs_real = (x < 0.0) ? -x : x;
    end
  endfunction

  function automatic real max_real(input real a, input real b);
    begin
      max_real = (a > b) ? a : b;
    end
  endfunction

  task automatic compare_lu_ram_with_reference;
    integer idx;
    integer row, col;

    shortreal got_sr, exp_sr;
    real got_r, exp_r;
    real abs_err, tol;
    begin
      mismatch_count = 0;

      // Load reference result dumped from Python
      $readmemh("lu_test_expected_8x8.mem", matrix_lu_ref_mem);

      for (idx = 0; idx < TestMatrixElementCount; idx = idx + 1) begin
        row = idx / TestMatrixSize;
        col = idx % TestMatrixSize;

        got_sr = $bitstoshortreal(matrixstore_lu_inst.ram.mem[idx]);
        exp_sr = $bitstoshortreal(matrix_lu_ref_mem[idx]);

        got_r = got_sr;
        exp_r = exp_sr;

        abs_err = abs_real(got_r - exp_r);

        // mixed absolute + relative tolerance
        tol = max_real(ABS_TOL, REL_TOL * max_real(abs_real(exp_r), 1.0));

        if (abs_err > tol) begin
          mismatch_count = mismatch_count + 1;
          $display("Mismatch at [%0d,%0d] idx=%0d: got=%h (%e), exp=%h (%e), abs_err=%e, tol=%e",
                   row, col, idx, matrixstore_lu_inst.ram.mem[idx], got_r, matrix_lu_ref_mem[idx],
                   exp_r, abs_err, tol);
        end
      end

      if (mismatch_count == 0) begin
        $display("LU RAM matches reference within tolerance.");
      end else begin
        $display("LU RAM comparison failed: %0d mismatches.", mismatch_count);
      end
    end
  endtask

  initial begin
    $readmemh("lu_test_input_8x8.mem", matrixstore_a_inst.ram.mem);

    dut_start = 1;
    # 16;
    dut_start = 0;

    wait (dut_done == 1'b1);
    // #1;  // allow final RAM write to settle if needed

    compare_lu_ram_with_reference();

    if (mismatch_count == 0) $finish;
    else $fatal(1, "Test failed.");
  end

endmodule
