`timescale 1ns / 1ps

module SolverDcPipeline #(
    parameter integer ELEM_COUNT = 32,
    parameter integer DIM = 32
) (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        clear_netlist_start,
    output wire        clear_netlist_done,

    input  wire        load_start,
    input  wire [15:0] load_idx,
    input  wire [7:0]  load_kind,
    input  wire [7:0]  load_n0,
    input  wire [7:0]  load_n1,
    input  wire [31:0] load_v0,
    output wire        load_done,

    input  wire        start,
    input  wire [31:0] par_elem_n,
    input  wire [31:0] par_node_n,
    output reg         busy = 1'b0,
    output reg         done = 1'b0,
    output reg         fp_exception = 1'b0,

    input  wire        result_fetch_start,
    input  wire [15:0] result_fetch_idx,
    output reg         result_fetch_done = 1'b0,
    output reg [31:0]  result_fetch_value = 32'd0
);

    localparam [1:0] S_IDLE = 2'd0;
    localparam [1:0] S_CLEAR_WAIT = 2'd1;
    localparam [1:0] S_RUN = 2'd2;

    reg [1:0] state = S_IDLE;

    reg a_clear_start = 1'b0;
    wire a_clear_done;
    reg lu_clear_start = 1'b0;
    wire lu_clear_done;
    reg j_clear_start = 1'b0;
    wire j_clear_done;
    reg y_clear_start = 1'b0;
    wire y_clear_done;
    reg x_clear_start = 1'b0;
    wire x_clear_done;

    reg solver_start = 1'b0;
    wire solver_done;

    reg a_clear_seen = 1'b0;
    reg lu_clear_seen = 1'b0;
    reg j_clear_seen = 1'b0;
    reg y_clear_seen = 1'b0;
    reg x_clear_seen = 1'b0;

    wire        fetchElemKind_start;
    wire [15:0] fetchElemKind_idx;
    wire        fetchElemKind_done;
    wire [7:0]  fetchElemKind_result;
    wire        fetchElemN0_start;
    wire [15:0] fetchElemN0_idx;
    wire        fetchElemN0_done;
    wire [7:0]  fetchElemN0_result;
    wire        fetchElemN1_start;
    wire [15:0] fetchElemN1_idx;
    wire        fetchElemN1_done;
    wire [7:0]  fetchElemN1_result;
    wire        fetchElemVal0_start;
    wire [15:0] fetchElemVal0_idx;
    wire        fetchElemVal0_done;
    wire [31:0] fetchElemVal0_result;

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
    wire [7:0]  accumA_i;
    wire [7:0]  accumA_j;
    wire [31:0] accumA_delta;
    wire        accumA_done;
    wire        accumJ_start;
    wire [7:0]  accumJ_i;
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

    wire        div_start;
    wire [31:0] div_a;
    wire [31:0] div_b;
    wire        div_done;
    wire [31:0] div_result;
    wire        div_busy_unused;
    wire        div_underflow;
    wire        div_overflow;
    wire        div_invalid;
    wire        div_div0;

    wire        fma_start;
    wire [31:0] fma_a;
    wire [31:0] fma_b;
    wire [31:0] fma_c;
    wire        fma_done;
    wire [31:0] fma_result;
    wire        fma_busy_unused;
    wire        fma_underflow;
    wire        fma_overflow;
    wire        fma_invalid;

    wire unused_fetchElemN2_done;
    wire [7:0] unused_fetchElemN2_result;
    wire unused_fetchElemN3_done;
    wire [7:0] unused_fetchElemN3_result;
    wire unused_fetchElemAux_done;
    wire [7:0] unused_fetchElemAux_result;
    wire unused_fetchElemVal1_done;
    wire [31:0] unused_fetchElemVal1_result;
    wire unused_fetchElemVal2_done;
    wire [31:0] unused_fetchElemVal2_result;
    wire unused_fetchElemVal3_done;
    wire [31:0] unused_fetchElemVal3_result;

    reg x_fetch_external_pending = 1'b0;
    wire x_fetch_mux_start = busy ? fetch_X_start : result_fetch_start;
    wire [15:0] x_fetch_mux_i = busy ? fetch_X_i : result_fetch_idx;

    StampingNetlistStore #(
        .ELEM_COUNT(ELEM_COUNT)
    ) netlist_store (
        .clk(clk),
        .rst_n(rst_n),
        .clear_start(clear_netlist_start),
        .clear_done(clear_netlist_done),
        .load_start(load_start),
        .load_idx(load_idx),
        .load_kind(load_kind),
        .load_n0(load_n0),
        .load_n1(load_n1),
        .load_n2(8'd0),
        .load_n3(8'd0),
        .load_aux(8'd0),
        .load_v0(load_v0),
        .load_v1(32'd0),
        .load_v2(32'd0),
        .load_v3(32'd0),
        .load_done(load_done),
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
        .fetchElemVal1_start(1'b0),
        .fetchElemVal1_idx(16'd0),
        .fetchElemVal1_done(unused_fetchElemVal1_done),
        .fetchElemVal1_result(unused_fetchElemVal1_result),
        .fetchElemVal2_start(1'b0),
        .fetchElemVal2_idx(16'd0),
        .fetchElemVal2_done(unused_fetchElemVal2_done),
        .fetchElemVal2_result(unused_fetchElemVal2_result),
        .fetchElemVal3_start(1'b0),
        .fetchElemVal3_idx(16'd0),
        .fetchElemVal3_done(unused_fetchElemVal3_done),
        .fetchElemVal3_result(unused_fetchElemVal3_result)
    );

    SolverMatrixStore #(.DIM(DIM), .ENABLE_ACCUM(1)) a_store (
        .clk(clk), .rst_n(rst_n),
        .clear_start(a_clear_start), .clear_done(a_clear_done),
        .store_start(store_A_start), .store_i(store_A_i), .store_j(store_A_j), .store_v(store_A_v), .store_done(store_A_done),
        .fetch_start(fetch_A_start), .fetch_i(fetch_A_i), .fetch_j(fetch_A_j), .fetch_done(fetch_A_done), .fetch_result(fetch_A_result),
        .accum_start(accumA_start), .accum_i({8'd0, accumA_i}), .accum_j({8'd0, accumA_j}), .accum_delta(accumA_delta), .accum_done(accumA_done)
    );

    SolverMatrixStore #(.DIM(DIM), .ENABLE_ACCUM(0)) lu_store (
        .clk(clk), .rst_n(rst_n),
        .clear_start(lu_clear_start), .clear_done(lu_clear_done),
        .store_start(store_LU_start), .store_i(store_LU_i), .store_j(store_LU_j), .store_v(store_LU_v), .store_done(store_LU_done),
        .fetch_start(fetch_LU_start), .fetch_i(fetch_LU_i), .fetch_j(fetch_LU_j), .fetch_done(fetch_LU_done), .fetch_result(fetch_LU_result),
        .accum_start(1'b0), .accum_i(16'd0), .accum_j(16'd0), .accum_delta(32'd0), .accum_done()
    );

    SolverVectorStore #(.DIM(DIM), .ENABLE_ACCUM(1)) j_store (
        .clk(clk), .rst_n(rst_n),
        .clear_start(j_clear_start), .clear_done(j_clear_done),
        .store_start(store_J_start), .store_i(store_J_i), .store_v(store_J_v), .store_done(store_J_done),
        .fetch_start(fetch_J_start), .fetch_i(fetch_J_i), .fetch_done(fetch_J_done), .fetch_result(fetch_J_result),
        .accum_start(accumJ_start), .accum_i({8'd0, accumJ_i}), .accum_delta(accumJ_delta), .accum_done(accumJ_done)
    );

    SolverVectorStore #(.DIM(DIM), .ENABLE_ACCUM(0)) y_store (
        .clk(clk), .rst_n(rst_n),
        .clear_start(y_clear_start), .clear_done(y_clear_done),
        .store_start(store_Y_start), .store_i(store_Y_i), .store_v(store_Y_v), .store_done(store_Y_done),
        .fetch_start(fetch_Y_start), .fetch_i(fetch_Y_i), .fetch_done(fetch_Y_done), .fetch_result(fetch_Y_result),
        .accum_start(1'b0), .accum_i(16'd0), .accum_delta(32'd0), .accum_done()
    );

    SolverVectorStore #(.DIM(DIM), .ENABLE_ACCUM(0)) x_store (
        .clk(clk), .rst_n(rst_n),
        .clear_start(x_clear_start), .clear_done(x_clear_done),
        .store_start(store_X_start), .store_i(store_X_i), .store_v(store_X_v), .store_done(store_X_done),
        .fetch_start(x_fetch_mux_start), .fetch_i(x_fetch_mux_i), .fetch_done(fetch_X_done), .fetch_result(fetch_X_result),
        .accum_start(1'b0), .accum_i(16'd0), .accum_delta(32'd0), .accum_done()
    );

    fpo_div div_inst (
        .clk(clk), .start(div_start), .a(div_a), .b(div_b),
        .busy(div_busy_unused), .done(div_done), .result(div_result),
        .exc_underflow(div_underflow), .exc_overflow(div_overflow),
        .exc_invalid(div_invalid), .exc_div0(div_div0)
    );

    fpo_fma fma_inst (
        .clk(clk), .start(fma_start), .a(fma_a), .b(fma_b), .c(fma_c),
        .busy(fma_busy_unused), .done(fma_done), .result(fma_result),
        .exc_underflow(fma_underflow), .exc_overflow(fma_overflow), .exc_invalid(fma_invalid)
    );

    solve_core_dc solver_inst (
        .clk(clk), .rst_n(rst_n), .start(solver_start), .busy(), .done(solver_done),
        .par_elem_n(par_elem_n), .par_node_n(par_node_n),
        .fetchElemKind_start(fetchElemKind_start), .fetchElemKind_idx(fetchElemKind_idx),
        .fetchElemKind_done(fetchElemKind_done), .fetchElemKind_result(fetchElemKind_result),
        .store_J_start(store_J_start), .store_J_i(store_J_i), .store_J_v(store_J_v), .store_J_done(store_J_done),
        .store_Y_start(store_Y_start), .store_Y_i(store_Y_i), .store_Y_v(store_Y_v), .store_Y_done(store_Y_done),
        .store_X_start(store_X_start), .store_X_i(store_X_i), .store_X_v(store_X_v), .store_X_done(store_X_done),
        .store_A_start(store_A_start), .store_A_i(store_A_i), .store_A_j(store_A_j), .store_A_v(store_A_v), .store_A_done(store_A_done),
        .store_LU_start(store_LU_start), .store_LU_i(store_LU_i), .store_LU_j(store_LU_j), .store_LU_v(store_LU_v), .store_LU_done(store_LU_done),
        .fetchElemN0_start(fetchElemN0_start), .fetchElemN0_idx(fetchElemN0_idx),
        .fetchElemN0_done(fetchElemN0_done), .fetchElemN0_result(fetchElemN0_result),
        .fetchElemN1_start(fetchElemN1_start), .fetchElemN1_idx(fetchElemN1_idx),
        .fetchElemN1_done(fetchElemN1_done), .fetchElemN1_result(fetchElemN1_result),
        .fetchElemVal0_start(fetchElemVal0_start), .fetchElemVal0_idx(fetchElemVal0_idx),
        .fetchElemVal0_done(fetchElemVal0_done), .fetchElemVal0_result(fetchElemVal0_result),
        .div_start(div_start), .div_a(div_a), .div_b(div_b), .div_done(div_done), .div_result(div_result),
        .accumA_start(accumA_start), .accumA_i(accumA_i), .accumA_j(accumA_j), .accumA_delta(accumA_delta), .accumA_done(accumA_done),
        .accumJ_start(accumJ_start), .accumJ_i(accumJ_i), .accumJ_delta(accumJ_delta), .accumJ_done(accumJ_done),
        .fetch_A_start(fetch_A_start), .fetch_A_i(fetch_A_i), .fetch_A_j(fetch_A_j), .fetch_A_done(fetch_A_done), .fetch_A_result(fetch_A_result),
        .fetch_LU_start(fetch_LU_start), .fetch_LU_i(fetch_LU_i), .fetch_LU_j(fetch_LU_j), .fetch_LU_done(fetch_LU_done), .fetch_LU_result(fetch_LU_result),
        .fma_start(fma_start), .fma_a(fma_a), .fma_b(fma_b), .fma_c(fma_c), .fma_done(fma_done), .fma_result(fma_result),
        .fetch_J_start(fetch_J_start), .fetch_J_i(fetch_J_i), .fetch_J_done(fetch_J_done), .fetch_J_result(fetch_J_result),
        .fetch_Y_start(fetch_Y_start), .fetch_Y_i(fetch_Y_i), .fetch_Y_done(fetch_Y_done), .fetch_Y_result(fetch_Y_result),
        .fetch_X_start(fetch_X_start), .fetch_X_i(fetch_X_i), .fetch_X_done(fetch_X_done), .fetch_X_result(fetch_X_result)
    );

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= S_IDLE;
            a_clear_start <= 1'b0;
            lu_clear_start <= 1'b0;
            j_clear_start <= 1'b0;
            y_clear_start <= 1'b0;
            x_clear_start <= 1'b0;
            solver_start <= 1'b0;
            busy <= 1'b0;
            done <= 1'b0;
            fp_exception <= 1'b0;
            a_clear_seen <= 1'b0;
            lu_clear_seen <= 1'b0;
            j_clear_seen <= 1'b0;
            y_clear_seen <= 1'b0;
            x_clear_seen <= 1'b0;
            x_fetch_external_pending <= 1'b0;
            result_fetch_done <= 1'b0;
            result_fetch_value <= 32'd0;
        end else begin
            a_clear_start <= 1'b0;
            lu_clear_start <= 1'b0;
            j_clear_start <= 1'b0;
            y_clear_start <= 1'b0;
            x_clear_start <= 1'b0;
            solver_start <= 1'b0;
            done <= 1'b0;
            result_fetch_done <= 1'b0;

            if (a_clear_done) a_clear_seen <= 1'b1;
            if (lu_clear_done) lu_clear_seen <= 1'b1;
            if (j_clear_done) j_clear_seen <= 1'b1;
            if (y_clear_done) y_clear_seen <= 1'b1;
            if (x_clear_done) x_clear_seen <= 1'b1;

            if (!busy && result_fetch_start) begin
                x_fetch_external_pending <= 1'b1;
            end
            if (!busy && x_fetch_external_pending && fetch_X_done) begin
                x_fetch_external_pending <= 1'b0;
                result_fetch_done <= 1'b1;
                result_fetch_value <= fetch_X_result;
            end

            if (busy && (div_underflow || div_overflow || div_invalid || div_div0 ||
                         fma_underflow || fma_overflow || fma_invalid)) begin
                fp_exception <= 1'b1;
            end

            case (state)
                S_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        busy <= 1'b1;
                        fp_exception <= 1'b0;
                        a_clear_seen <= 1'b0;
                        lu_clear_seen <= 1'b0;
                        j_clear_seen <= 1'b0;
                        y_clear_seen <= 1'b0;
                        x_clear_seen <= 1'b0;
                        a_clear_start <= 1'b1;
                        lu_clear_start <= 1'b1;
                        j_clear_start <= 1'b1;
                        y_clear_start <= 1'b1;
                        x_clear_start <= 1'b1;
                        state <= S_CLEAR_WAIT;
                    end
                end

                S_CLEAR_WAIT: begin
                    if (a_clear_seen && lu_clear_seen && j_clear_seen && y_clear_seen && x_clear_seen) begin
                        solver_start <= 1'b1;
                        state <= S_RUN;
                    end
                end

                S_RUN: begin
                    if (solver_done) begin
                        busy <= 1'b0;
                        done <= 1'b1;
                        state <= S_IDLE;
                    end
                end

                default: begin
                    state <= S_IDLE;
                    busy <= 1'b0;
                end
            endcase
        end
    end
endmodule
