`timescale 1ns / 1ps

module SolveCore_test;
  localparam integer ELEM_COUNT_MAX = 8;
  localparam integer DIM_MAX = 6;
  localparam integer MAX_CYCLES = 250000;

  localparam [7:0] KIND_R = 8'd1;
  localparam [7:0] KIND_I = 8'd2;
  localparam [7:0] KIND_V = 8'd3;
  localparam [7:0] KIND_C = 8'd4;
  localparam [7:0] KIND_L = 8'd5;
  localparam [7:0] KIND_VSIN = 8'd6;
  localparam [7:0] KIND_ISIN = 8'd7;
  localparam [7:0] KIND_SWPWM = 8'd8;
  localparam [7:0] KIND_VPWM = 8'd9;

  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk;

  reg start = 1'b0;
  reg [31:0] par_elem_n = '0;
  reg [31:0] par_node_n = '0;
  reg [31:0] par_dt = '0;
  reg [31:0] par_time = '0;
  wire busy;
  wire done;

  wire        fetchElemKind_start;
  wire [15:0] fetchElemKind_idx;
  wire        fetchElemKind_done;
  wire [7:0]  fetchElemKind_result;

  wire        fetchElemN0_start;
  wire [15:0] fetchElemN0_idx;
  wire        fetchElemN0_done;
  wire [15:0] fetchElemN0_result;

  wire        fetchElemN1_start;
  wire [15:0] fetchElemN1_idx;
  wire        fetchElemN1_done;
  wire [15:0] fetchElemN1_result;

  wire        fetchElemVal0_start;
  wire [15:0] fetchElemVal0_idx;
  wire        fetchElemVal0_done;
  wire [31:0] fetchElemVal0_result;

  wire        fetchElemVal1_start;
  wire [15:0] fetchElemVal1_idx;
  wire        fetchElemVal1_done;
  wire [31:0] fetchElemVal1_result;

  wire        fetchElemVal2_start;
  wire [15:0] fetchElemVal2_idx;
  wire        fetchElemVal2_done;
  wire [31:0] fetchElemVal2_result;

  wire        fetchElemVal3_start;
  wire [15:0] fetchElemVal3_idx;
  wire        fetchElemVal3_done;
  wire [31:0] fetchElemVal3_result;

  wire        store_J_start;
  wire [15:0] store_J_i;
  wire [31:0] store_J_v;
  wire        store_J_done;

  wire        store_Y_start;
  wire [15:0] store_Y_i;
  wire [31:0] store_Y_v;
  wire        store_Y_done;

  wire        store_X_start;
  wire [15:0] store_X_i;
  wire [31:0] store_X_v;
  wire        store_X_done;

  wire        store_A_start;
  wire [15:0] store_A_i;
  wire [15:0] store_A_j;
  wire [31:0] store_A_v;
  wire        store_A_done;

  wire        store_LU_start;
  wire [15:0] store_LU_i;
  wire [15:0] store_LU_j;
  wire [31:0] store_LU_v;
  wire        store_LU_done;

  wire        accumA_start;
  wire [15:0] accumA_i;
  wire [15:0] accumA_j;
  wire [31:0] accumA_delta;
  wire        accumA_done;

  wire        accumJ_start;
  wire [15:0] accumJ_i;
  wire [31:0] accumJ_delta;
  wire        accumJ_done;

  wire        fetch_A_start;
  wire [15:0] fetch_A_i;
  wire [15:0] fetch_A_j;
  wire        fetch_A_done;
  wire [31:0] fetch_A_result;

  wire        fetch_LU_start;
  wire [15:0] fetch_LU_i;
  wire [15:0] fetch_LU_j;
  wire        fetch_LU_done;
  wire [31:0] fetch_LU_result;

  wire        fetch_J_start;
  wire [15:0] fetch_J_i;
  wire        fetch_J_done;
  wire [31:0] fetch_J_result;

  wire        fetch_Y_start;
  wire [15:0] fetch_Y_i;
  wire        fetch_Y_done;
  wire [31:0] fetch_Y_result;

  wire        fetch_X_start;
  wire [15:0] fetch_X_i;
  wire        fetch_X_done;
  wire [31:0] fetch_X_result;

  wire        fetch_prevX_start;
  wire [15:0] fetch_prevX_i;
  wire        fetch_prevX_done;
  wire [31:0] fetch_prevX_result;

  wire        store_prevX_start;
  wire [15:0] store_prevX_i;
  wire [31:0] store_prevX_v;
  wire        store_prevX_done;

  wire        fma_start;
  wire [31:0] fma_a;
  wire [31:0] fma_b;
  wire [31:0] fma_c;
  wire        fma_done;
  wire [31:0] fma_result;

  wire        div_start;
  wire [31:0] div_a;
  wire [31:0] div_b;
  wire        div_done;
  wire [31:0] div_result;

  reg  a_clear_start = 1'b0;
  wire a_clear_done;
  reg  lu_clear_start = 1'b0;
  wire lu_clear_done;
  reg  j_clear_start = 1'b0;
  wire j_clear_done;
  reg  y_clear_start = 1'b0;
  wire y_clear_done;
  reg  x_clear_start = 1'b0;
  wire x_clear_done;
  reg  prevx_clear_start = 1'b0;
  wire prevx_clear_done;

  wire unused_fetchElemN2_done;
  wire [15:0] unused_fetchElemN2_result;
  wire unused_fetchElemN3_done;
  wire [15:0] unused_fetchElemN3_result;
  wire unused_fetchElemAux_done;
  wire [15:0] unused_fetchElemAux_result;

  wire fma_busy_unused;
  wire fma_underflow_unused;
  wire fma_overflow_unused;
  wire fma_invalid_unused;
  wire div_busy_unused;
  wire div_underflow_unused;
  wire div_overflow_unused;
  wire div_invalid_unused;
  wire div_div0_unused;

  integer cycle_count;
  integer idx;

  shortreal got_sr;
  shortreal exp_sr;
  real got_r;
  real exp_r;
  real abs_err;
  real tol;

  function automatic [31:0] real_to_bits(input real value);
    shortreal value_sr;
    begin
      value_sr = value;
      real_to_bits = $shortrealtobits(value_sr);
    end
  endfunction

  function automatic real bits_to_real(input [31:0] bits);
    shortreal value_sr;
    begin
      value_sr = $bitstoshortreal(bits);
      bits_to_real = value_sr;
    end
  endfunction

  function automatic real abs_real(input real value);
    begin
      abs_real = (value < 0.0) ? -value : value;
    end
  endfunction

  function automatic real max_real(input real a, input real b);
    begin
      max_real = (a > b) ? a : b;
    end
  endfunction

  solve_core dut (
      .clk(clk),
      .rst_n(rst_n),
      .start(start),
      .busy(busy),
      .done(done),
      .par_elem_n(par_elem_n),
      .par_node_n(par_node_n),
      .par_dt(par_dt),
      .par_time(par_time),
      .fetchElemKind_start(fetchElemKind_start),
      .fetchElemKind_idx(fetchElemKind_idx),
      .fetchElemKind_done(fetchElemKind_done),
      .fetchElemKind_result(fetchElemKind_result),
      .store_J_start(store_J_start),
      .store_J_i(store_J_i),
      .store_J_v(store_J_v),
      .store_J_done(store_J_done),
      .store_Y_start(store_Y_start),
      .store_Y_i(store_Y_i),
      .store_Y_v(store_Y_v),
      .store_Y_done(store_Y_done),
      .store_X_start(store_X_start),
      .store_X_i(store_X_i),
      .store_X_v(store_X_v),
      .store_X_done(store_X_done),
      .store_A_start(store_A_start),
      .store_A_i(store_A_i),
      .store_A_j(store_A_j),
      .store_A_v(store_A_v),
      .store_A_done(store_A_done),
      .store_LU_start(store_LU_start),
      .store_LU_i(store_LU_i),
      .store_LU_j(store_LU_j),
      .store_LU_v(store_LU_v),
      .store_LU_done(store_LU_done),
      .fetchElemN0_start(fetchElemN0_start),
      .fetchElemN0_idx(fetchElemN0_idx),
      .fetchElemN0_done(fetchElemN0_done),
      .fetchElemN0_result(fetchElemN0_result),
      .fetchElemN1_start(fetchElemN1_start),
      .fetchElemN1_idx(fetchElemN1_idx),
      .fetchElemN1_done(fetchElemN1_done),
      .fetchElemN1_result(fetchElemN1_result),
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
      .fetchElemVal3_start(fetchElemVal3_start),
      .fetchElemVal3_idx(fetchElemVal3_idx),
      .fetchElemVal3_done(fetchElemVal3_done),
      .fetchElemVal3_result(fetchElemVal3_result),
      .div_start(div_start),
      .div_a(div_a),
      .div_b(div_b),
      .div_done(div_done),
      .div_result(div_result),
      .accumA_start(accumA_start),
      .accumA_i(accumA_i),
      .accumA_j(accumA_j),
      .accumA_delta(accumA_delta),
      .accumA_done(accumA_done),
      .accumJ_start(accumJ_start),
      .accumJ_i(accumJ_i),
      .accumJ_delta(accumJ_delta),
      .accumJ_done(accumJ_done),
      .fetch_prevX_start(fetch_prevX_start),
      .fetch_prevX_i(fetch_prevX_i),
      .fetch_prevX_done(fetch_prevX_done),
      .fetch_prevX_result(fetch_prevX_result),
      .fma_start(fma_start),
      .fma_a(fma_a),
      .fma_b(fma_b),
      .fma_c(fma_c),
      .fma_done(fma_done),
      .fma_result(fma_result),
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
      .fetch_J_start(fetch_J_start),
      .fetch_J_i(fetch_J_i),
      .fetch_J_done(fetch_J_done),
      .fetch_J_result(fetch_J_result),
      .fetch_Y_start(fetch_Y_start),
      .fetch_Y_i(fetch_Y_i),
      .fetch_Y_done(fetch_Y_done),
      .fetch_Y_result(fetch_Y_result),
      .fetch_X_start(fetch_X_start),
      .fetch_X_i(fetch_X_i),
      .fetch_X_done(fetch_X_done),
      .fetch_X_result(fetch_X_result),
      .store_prevX_start(store_prevX_start),
      .store_prevX_i(store_prevX_i),
      .store_prevX_v(store_prevX_v),
      .store_prevX_done(store_prevX_done)
  );

  StampingNetlistStore #(
      .ELEM_COUNT(ELEM_COUNT_MAX)
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
      .fetchElemN2_start(1'b0),
      .fetchElemN2_idx(16'd0),
      .fetchElemN2_done(unused_fetchElemN2_done),
      .fetchElemN2_result(unused_fetchElemN2_result),
      .fetchElemN3_start(1'b0),
      .fetchElemN3_idx(16'd0),
      .fetchElemN3_done(unused_fetchElemN3_done),
      .fetchElemN3_result(unused_fetchElemN3_result),
      .fetchElemAux_start(1'b0),
      .fetchElemAux_idx(16'd0),
      .fetchElemAux_done(unused_fetchElemAux_done),
      .fetchElemAux_result(unused_fetchElemAux_result),
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
      .fetchElemVal3_start(fetchElemVal3_start),
      .fetchElemVal3_idx(fetchElemVal3_idx),
      .fetchElemVal3_done(fetchElemVal3_done),
      .fetchElemVal3_result(fetchElemVal3_result)
  );

  SolverMatrixStore #(
      .DIM(DIM_MAX)
  ) a_store (
      .clk(clk),
      .rst_n(rst_n),
      .clear_start(a_clear_start),
      .clear_done(a_clear_done),
      .store_start(store_A_start),
      .store_i(store_A_i),
      .store_j(store_A_j),
      .store_v(store_A_v),
      .store_done(store_A_done),
      .fetch_start(fetch_A_start),
      .fetch_i(fetch_A_i),
      .fetch_j(fetch_A_j),
      .fetch_done(fetch_A_done),
      .fetch_result(fetch_A_result),
      .accum_start(accumA_start),
      .accum_i(accumA_i),
      .accum_j(accumA_j),
      .accum_delta(accumA_delta),
      .accum_done(accumA_done)
  );

  SolverMatrixStore #(
      .DIM(DIM_MAX),
      .ENABLE_ACCUM(0)
  ) lu_store (
      .clk(clk),
      .rst_n(rst_n),
      .clear_start(lu_clear_start),
      .clear_done(lu_clear_done),
      .store_start(store_LU_start),
      .store_i(store_LU_i),
      .store_j(store_LU_j),
      .store_v(store_LU_v),
      .store_done(store_LU_done),
      .fetch_start(fetch_LU_start),
      .fetch_i(fetch_LU_i),
      .fetch_j(fetch_LU_j),
      .fetch_done(fetch_LU_done),
      .fetch_result(fetch_LU_result),
      .accum_start(1'b0),
      .accum_i(16'd0),
      .accum_j(16'd0),
      .accum_delta(32'd0),
      .accum_done()
  );

  SolverVectorStore #(
      .DIM(DIM_MAX)
  ) j_store (
      .clk(clk),
      .rst_n(rst_n),
      .clear_start(j_clear_start),
      .clear_done(j_clear_done),
      .store_start(store_J_start),
      .store_i(store_J_i),
      .store_v(store_J_v),
      .store_done(store_J_done),
      .fetch_start(fetch_J_start),
      .fetch_i(fetch_J_i),
      .fetch_done(fetch_J_done),
      .fetch_result(fetch_J_result),
      .accum_start(accumJ_start),
      .accum_i(accumJ_i),
      .accum_delta(accumJ_delta),
      .accum_done(accumJ_done)
  );

  SolverVectorStore #(
      .DIM(DIM_MAX),
      .ENABLE_ACCUM(0)
  ) y_store (
      .clk(clk),
      .rst_n(rst_n),
      .clear_start(y_clear_start),
      .clear_done(y_clear_done),
      .store_start(store_Y_start),
      .store_i(store_Y_i),
      .store_v(store_Y_v),
      .store_done(store_Y_done),
      .fetch_start(fetch_Y_start),
      .fetch_i(fetch_Y_i),
      .fetch_done(fetch_Y_done),
      .fetch_result(fetch_Y_result),
      .accum_start(1'b0),
      .accum_i(16'd0),
      .accum_delta(32'd0),
      .accum_done()
  );

  SolverVectorStore #(
      .DIM(DIM_MAX),
      .ENABLE_ACCUM(0)
  ) x_store (
      .clk(clk),
      .rst_n(rst_n),
      .clear_start(x_clear_start),
      .clear_done(x_clear_done),
      .store_start(store_X_start),
      .store_i(store_X_i),
      .store_v(store_X_v),
      .store_done(store_X_done),
      .fetch_start(fetch_X_start),
      .fetch_i(fetch_X_i),
      .fetch_done(fetch_X_done),
      .fetch_result(fetch_X_result),
      .accum_start(1'b0),
      .accum_i(16'd0),
      .accum_delta(32'd0),
      .accum_done()
  );

  SolverVectorStore #(
      .DIM(DIM_MAX),
      .ENABLE_ACCUM(0)
  ) prevx_store (
      .clk(clk),
      .rst_n(rst_n),
      .clear_start(prevx_clear_start),
      .clear_done(prevx_clear_done),
      .store_start(store_prevX_start),
      .store_i(store_prevX_i),
      .store_v(store_prevX_v),
      .store_done(store_prevX_done),
      .fetch_start(fetch_prevX_start),
      .fetch_i(fetch_prevX_i),
      .fetch_done(fetch_prevX_done),
      .fetch_result(fetch_prevX_result),
      .accum_start(1'b0),
      .accum_i(16'd0),
      .accum_delta(32'd0),
      .accum_done()
  );

  fpo_fma fma_inst (
      .clk(clk),
      .start(fma_start),
      .a(fma_a),
      .b(fma_b),
      .c(fma_c),
      .busy(fma_busy_unused),
      .done(fma_done),
      .result(fma_result),
      .exc_underflow(fma_underflow_unused),
      .exc_overflow(fma_overflow_unused),
      .exc_invalid(fma_invalid_unused)
  );

  fpo_div div_inst (
      .clk(clk),
      .start(div_start),
      .a(div_a),
      .b(div_b),
      .busy(div_busy_unused),
      .done(div_done),
      .result(div_result),
      .exc_underflow(div_underflow_unused),
      .exc_overflow(div_overflow_unused),
      .exc_invalid(div_invalid_unused),
      .exc_div0(div_div0_unused)
  );

  task automatic clear_netlist_memories;
    begin
      for (idx = 0; idx < ELEM_COUNT_MAX; idx = idx + 1) begin
        netlist_store.kind_mem[idx] = '0;
        netlist_store.n0_mem[idx] = '0;
        netlist_store.n1_mem[idx] = '0;
        netlist_store.n2_mem[idx] = '0;
        netlist_store.n3_mem[idx] = '0;
        netlist_store.aux_mem[idx] = '0;
        netlist_store.v0_mem[idx] = '0;
        netlist_store.v1_mem[idx] = '0;
        netlist_store.v2_mem[idx] = '0;
        netlist_store.v3_mem[idx] = '0;
      end
    end
  endtask

  task automatic clear_solver_stores;
    reg seen_a_clear_done;
    reg seen_lu_clear_done;
    reg seen_j_clear_done;
    reg seen_y_clear_done;
    reg seen_x_clear_done;
    reg seen_prevx_clear_done;
    begin
      @(negedge clk);
      a_clear_start <= 1'b1;
      lu_clear_start <= 1'b1;
      j_clear_start <= 1'b1;
      y_clear_start <= 1'b1;
      x_clear_start <= 1'b1;
      prevx_clear_start <= 1'b1;
      @(negedge clk);
      a_clear_start <= 1'b0;
      lu_clear_start <= 1'b0;
      j_clear_start <= 1'b0;
      y_clear_start <= 1'b0;
      x_clear_start <= 1'b0;
      prevx_clear_start <= 1'b0;
      seen_a_clear_done = 1'b0;
      seen_lu_clear_done = 1'b0;
      seen_j_clear_done = 1'b0;
      seen_y_clear_done = 1'b0;
      seen_x_clear_done = 1'b0;
      seen_prevx_clear_done = 1'b0;
      while (!(seen_a_clear_done && seen_lu_clear_done &&
               seen_j_clear_done && seen_y_clear_done &&
               seen_x_clear_done && seen_prevx_clear_done)) begin
        @(negedge clk);
        if (a_clear_done === 1'b1) seen_a_clear_done = 1'b1;
        if (lu_clear_done === 1'b1) seen_lu_clear_done = 1'b1;
        if (j_clear_done === 1'b1) seen_j_clear_done = 1'b1;
        if (y_clear_done === 1'b1) seen_y_clear_done = 1'b1;
        if (x_clear_done === 1'b1) seen_x_clear_done = 1'b1;
        if (prevx_clear_done === 1'b1) seen_prevx_clear_done = 1'b1;
      end
    end
  endtask

  task automatic reset_design;
    begin
      rst_n <= 1'b0;
      start <= 1'b0;
      par_elem_n <= '0;
      par_node_n <= '0;
      par_dt <= '0;
      par_time <= '0;
      repeat (4) @(negedge clk);
      rst_n <= 1'b1;
      repeat (2) @(negedge clk);
      clear_netlist_memories();
      clear_solver_stores();
    end
  endtask

  task automatic program_element(
      input integer elem_idx,
      input [7:0] kind,
      input integer n0,
      input integer n1,
      input real v0,
      input real v1,
      input real v2,
      input real v3
  );
    begin
      netlist_store.kind_mem[elem_idx] = kind;
      netlist_store.n0_mem[elem_idx] = n0[15:0];
      netlist_store.n1_mem[elem_idx] = n1[15:0];
      netlist_store.v0_mem[elem_idx] = real_to_bits(v0);
      netlist_store.v1_mem[elem_idx] = real_to_bits(v1);
      netlist_store.v2_mem[elem_idx] = real_to_bits(v2);
      netlist_store.v3_mem[elem_idx] = real_to_bits(v3);
    end
  endtask

  task automatic run_step(
      input integer elem_n,
      input integer node_n,
      input real dt_value,
      input real time_value
  );
    begin
      par_elem_n <= elem_n;
      par_node_n <= node_n;
      par_dt <= real_to_bits(dt_value);
      par_time <= real_to_bits(time_value);
      @(negedge clk);
      start <= 1'b1;
      @(negedge clk);
      start <= 1'b0;

      cycle_count = 0;
      while (done !== 1'b1) begin
        @(posedge clk);
        cycle_count = cycle_count + 1;
        if (cycle_count > MAX_CYCLES) begin
          $fatal(1, "Timeout waiting for done at time=%e dt=%e", time_value, dt_value);
        end
      end
      @(posedge clk);
    end
  endtask

  task automatic expect_vector_entry(
      input string mem_name,
      input [31:0] bits_value,
      input real expected_value
  );
    begin
      got_sr = $bitstoshortreal(bits_value);
      exp_sr = expected_value;
      got_r = got_sr;
      exp_r = exp_sr;
      abs_err = abs_real(got_r - exp_r);
      tol = max_real(1e-4, abs_real(exp_r) * 1e-3);
      if (abs_err > tol) begin
        $fatal(1, "%s mismatch: got=%e expected=%e abs_err=%e tol=%e",
               mem_name, got_r, exp_r, abs_err, tol);
      end
    end
  endtask

  task automatic expect_x(
      input integer vec_idx,
      input real expected_value
  );
    begin
      expect_vector_entry($sformatf("X[%0d]", vec_idx), x_store.mem_inst.mem[vec_idx], expected_value);
    end
  endtask

  task automatic expect_prevx(
      input integer vec_idx,
      input real expected_value
  );
    begin
      expect_vector_entry($sformatf("prevX[%0d]", vec_idx), prevx_store.mem_inst.mem[vec_idx], expected_value);
    end
  endtask

  task automatic run_case_rc_multistep;
    begin
      reset_design();
      program_element(0, KIND_V, 1, 0, 1.0, 0.0, 0.0, 0.0);
      program_element(1, KIND_R, 1, 2, 1.0, 0.0, 0.0, 0.0);
      program_element(2, KIND_C, 2, 0, 1.0, 0.0, 0.0, 0.0);

      run_step(3, 2, 0.1, 0.0);
      expect_x(0, 1.0);
      expect_x(1, 0.09090909090909091);
      expect_x(2, 0.9090909090909091);
      expect_prevx(1, 0.09090909090909091);

      run_step(3, 2, 0.1, 0.1);
      expect_x(0, 1.0);
      expect_x(1, 0.17355371900826447);
      expect_x(2, 0.8264462809917354);
      expect_prevx(1, 0.17355371900826447);

      run_step(3, 2, 0.1, 0.2);
      expect_x(0, 1.0);
      expect_x(1, 0.24868519909842224);
      expect_x(2, 0.7513148009015778);
      expect_prevx(1, 0.24868519909842224);

      $display("run_case_rc_multistep passed.");
    end
  endtask

  task automatic run_case_vpwm_levels;
    begin
      reset_design();
      program_element(0, KIND_VPWM, 1, 0, 0.0, 2.5, 1.0, 0.25);
      program_element(1, KIND_R, 1, 0, 5.0, 0.0, 0.0, 0.0);

      run_step(2, 1, 0.01, 0.10);
      expect_x(0, 2.5);
      expect_x(1, 0.5);

      run_step(2, 1, 0.01, 0.60);
      expect_x(0, 0.0);
      expect_x(1, 0.0);

      $display("run_case_vpwm_levels passed.");
    end
  endtask

  task automatic run_case_swpwm_divider;
    begin
      reset_design();
      program_element(0, KIND_V, 1, 0, 1.0, 0.0, 0.0, 0.0);
      program_element(1, KIND_R, 1, 2, 1.0, 0.0, 0.0, 0.0);
      program_element(2, KIND_R, 2, 0, 10.0, 0.0, 0.0, 0.0);
      program_element(3, KIND_SWPWM, 2, 0, 0.1, 1000.0, 1.0, 0.5);

      run_step(4, 2, 0.01, 0.10);
      expect_x(0, 1.0);
      expect_x(1, 0.09009009009009009);
      expect_x(2, 0.9099099099099098);

      run_step(4, 2, 0.01, 0.75);
      expect_x(0, 1.0);
      expect_x(1, 0.9082652134423251);
      expect_x(2, 0.09173478655767482);

      $display("run_case_swpwm_divider passed.");
    end
  endtask

  task automatic run_case_boost_lite_stage;
    begin
      reset_design();
      program_element(0, KIND_V, 1, 0, 1.0, 0.0, 0.0, 0.0);
      program_element(1, KIND_L, 1, 2, 0.25, 0.0, 0.0, 0.0);
      program_element(2, KIND_R, 2, 0, 4.0, 0.0, 0.0, 0.0);
      program_element(3, KIND_SWPWM, 2, 0, 0.1, 1000.0, 0.4, 0.5);

      run_step(4, 2, 0.02, 0.00);
      expect_x(0, 1.0);
      expect_x(1, -0.007866273352999017);
      expect_x(2, -0.08062930186823992);
      expect_x(3, 0.08062930186823992);

      run_step(4, 2, 0.02, 0.02);
      expect_x(0, 1.0);
      expect_x(1, -0.015794424962462136);
      expect_x(2, -0.16189285586523688);
      expect_x(3, 0.16189285586523688);

      run_step(4, 2, 0.02, 0.04);
      expect_x(0, 1.0);
      expect_x(1, -0.02378494157966931);
      expect_x(2, -0.24379565119161042);
      expect_x(3, 0.24379565119161042);

      run_step(4, 2, 0.02, 0.06);
      expect_x(0, 1.0);
      expect_x(1, -0.03183831378481912);
      expect_x(2, -0.326342716294396);
      expect_x(3, 0.326342716294396);

      $display("run_case_boost_lite_stage passed.");
    end
  endtask

  initial begin
    run_case_rc_multistep();
    run_case_vpwm_levels();
    run_case_swpwm_divider();
    run_case_boost_lite_stage();
    $display("SolveCore_test passed.");
    $finish;
  end
endmodule
