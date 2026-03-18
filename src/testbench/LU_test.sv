`timescale 1ns / 1ps

module LU_test ();

  reg clk_t_100m = 0;
  always #5 clk_t_100m = ~clk_t_100m;  // 10ns => 100MHz

  localparam integer TestMatrixSize = 4;
  localparam integer TestMatrixElementCount = TestMatrixSize * TestMatrixSize;
  localparam integer TestMatrixAddrLength = $clog2(TestMatrixElementCount);

  localparam integer FloatLength = 32;

  reg matrix_a_ram_w_en = 0;
  reg [TestMatrixAddrLength-1:0] matrix_a_ram_w_addr = 0;
  wire [TestMatrixAddrLength-1:0] matrix_a_ram_r_addr;
  reg [FloatLength-1:0] matrix_a_ram_w_data = 0;
  wire [FloatLength-1:0] matrix_a_ram_r_data;

  SimpleRam #(
      .WordWidth(FloatLength),
      .WordCount(TestMatrixElementCount)  // 4*4 => addr:4bit
  ) matrix_a_ram_inst (
      .clk(clk_t_100m),
      .w_en(matrix_a_ram_w_en),
      .w_addr(matrix_a_ram_w_addr),
      .r_addr(matrix_a_ram_r_addr),
      .d_in(matrix_a_ram_w_data),
      .d_out(matrix_a_ram_r_data)
  );

  reg matrix_lu_ram_w_en = 0;
  reg [TestMatrixAddrLength-1:0] matrix_lu_ram_w_addr = 0;
  wire [TestMatrixAddrLength-1:0] matrix_lu_ram_r_addr;
  reg [FloatLength-1:0] matrix_lu_ram_w_data = 0;
  wire [FloatLength-1:0] matrix_lu_ram_r_data;

  SimpleRam #(
      .WordWidth(FloatLength),
      .WordCount(TestMatrixElementCount)  // 4*4 => addr:4bit
  ) matrix_lu_ram_inst (
      .clk(clk_t_100m),
      .w_en(matrix_lu_ram_w_en),
      .w_addr(matrix_lu_ram_w_addr),
      .r_addr(matrix_lu_ram_r_addr),
      .d_in(matrix_lu_ram_w_data),
      .d_out(matrix_lu_ram_r_data)
  );

  reg  dut_start = 1'b0;
  wire dut_busy;
  wire dut_done;

  LUdecomp #(
      .SIZE(TestMatrixSize)
  ) dut (
      /* General Ports */
      /*input*/ .clk  (clk_t_100m),
      /*input*/ .start(dut_start),
      /*output*/.busy (dut_busy),
      /*output*/.done (dut_done),

      /* Input Matrix A RAM handles (Read-only) */
      /*output*/  /*[ADDR_WIDTH-1:0]*/.A_r_addr  (matrix_a_ram_r_addr),
      /*input*/  /*[ ELE_WIDTH-1:0]*/ .A_data_out(matrix_a_ram_r_data),

      /* Output Matrix LU RAM handles (Read & Write) */
      /*output*/.LU_w_en(matrix_lu_ram_w_en),
      /*output*/  /*[ADDR_WIDTH-1:0]*/.LU_w_addr(matrix_lu_ram_w_addr),
      /*output*/  /*[ADDR_WIDTH-1:0]*/.LU_r_addr(matrix_lu_ram_r_addr),
      /*output*/  /*[ELE_WIDTH-1:0]*/.LU_data_in(matrix_lu_ram_w_data),
      /*input*/  /*[ELE_WIDTH-1:0]*/.LU_data_out(matrix_lu_ram_r_data)
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
      $readmemh("lu_test_expected_4x4.mem", matrix_lu_ref_mem);

      for (idx = 0; idx < TestMatrixElementCount; idx = idx + 1) begin
        row = idx / TestMatrixSize;
        col = idx % TestMatrixSize;

        got_sr = $bitstoshortreal(matrix_lu_ram_inst.mem[idx]);
        exp_sr = $bitstoshortreal(matrix_lu_ref_mem[idx]);

        got_r = got_sr;
        exp_r = exp_sr;

        abs_err = abs_real(got_r - exp_r);

        // mixed absolute + relative tolerance
        tol = max_real(ABS_TOL, REL_TOL * max_real(abs_real(exp_r), 1.0));

        if (abs_err > tol) begin
          mismatch_count = mismatch_count + 1;
          $display("Mismatch at [%0d,%0d] idx=%0d: got=%h (%e), exp=%h (%e), abs_err=%e, tol=%e",
                   row, col, idx, matrix_lu_ram_inst.mem[idx], got_r, matrix_lu_ref_mem[idx],
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
    $readmemh("lu_test_input_4x4.mem", matrix_a_ram_inst.mem);

    dut_start = 1;
    # 10;
    dut_start = 0;

    wait (dut_done == 1'b1);
    // #1;  // allow final RAM write to settle if needed

    compare_lu_ram_with_reference();

    if (mismatch_count == 0) $finish;
    else $fatal(1, "Test failed.");
  end

endmodule
