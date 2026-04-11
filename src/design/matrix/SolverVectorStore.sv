`timescale 1ns / 1ps

module SolverVectorStore #(
    parameter integer DIM = 8,
    parameter integer ADDR_WIDTH = (DIM <= 2) ? 1 : $clog2(DIM),
    parameter integer ENABLE_ACCUM = 1
) (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        clear_start,
    output reg         clear_done,

    input  wire        store_start,
    input  wire [15:0] store_i,
    input  wire [31:0] store_v,
    output reg         store_done,

    input  wire        fetch_start,
    input  wire [15:0] fetch_i,
    output reg         fetch_done,
    output reg  [31:0] fetch_result,

    input  wire        accum_start,
    input  wire [15:0] accum_i,
    input  wire [31:0] accum_delta,
    output reg         accum_done
);

  import StampingCombPkg::*;

  localparam [2:0] S_IDLE = 3'd0;
  localparam [2:0] S_CLEAR = 3'd1;
  localparam [2:0] S_FETCH = 3'd2;
  localparam [2:0] S_ACCUM_READ = 3'd3;
  localparam [2:0] S_ACCUM_ADD_ISSUE = 3'd4;
  localparam [2:0] S_ACCUM_ADD_WAIT = 3'd5;
  localparam [31:0] FP_ONE = 32'h3F80_0000;

  reg [2:0] state = S_IDLE;
  reg [ADDR_WIDTH-1:0] clear_idx = {ADDR_WIDTH{1'b0}};
  reg [ADDR_WIDTH-1:0] op_addr = {ADDR_WIDTH{1'b0}};
  reg                  op_valid = 1'b0;
  reg [31:0] accum_delta_reg = 32'd0;
  reg [31:0] accum_base_reg = 32'd0;

  reg                  mem_w_en = 1'b0;
  reg [ADDR_WIDTH-1:0] mem_w_addr = {ADDR_WIDTH{1'b0}};
  reg [31:0]           mem_d_in = 32'd0;
  wire [ADDR_WIDTH-1:0] mem_r_addr;
  wire [31:0]          mem_d_out;

  reg         accum_add_start = 1'b0;
  reg  [31:0] accum_add_a = 32'd0;
  reg  [31:0] accum_add_c = 32'd0;
  wire        accum_add_done;
  wire [31:0] accum_add_result;

  generate
    if (ENABLE_ACCUM != 0) begin : gen_accum_fma
      wire accum_add_busy_unused;
      wire accum_add_underflow_unused;
      wire accum_add_overflow_unused;
      wire accum_add_invalid_unused;

      fpo_fma accum_add_inst (
          .clk(clk),
          .start(accum_add_start),
          .a(accum_add_a),
          .b(FP_ONE),
          .c(accum_add_c),
          .busy(accum_add_busy_unused),
          .done(accum_add_done),
          .result(accum_add_result),
          .exc_underflow(accum_add_underflow_unused),
          .exc_overflow(accum_add_overflow_unused),
          .exc_invalid(accum_add_invalid_unused)
      );
    end else begin : gen_no_accum_fma
      assign accum_add_done = 1'b0;
      assign accum_add_result = 32'd0;
    end
  endgenerate

  SimpleRam #(
      .WordWidth(32),
      .WordCount(DIM),
      .AddrWidth(ADDR_WIDTH)
  ) mem_inst (
      .clk(clk),
      .w_en(mem_w_en),
      .w_addr(mem_w_addr),
      .r_addr(mem_r_addr),
      .d_in(mem_d_in),
      .d_out(mem_d_out)
  );

  wire store_addr_valid = (store_i < DIM);
  wire fetch_addr_valid = (fetch_i < DIM);
  wire accum_addr_valid = (accum_i < DIM);
  wire [ADDR_WIDTH-1:0] store_addr = store_i[ADDR_WIDTH-1:0];
  wire [ADDR_WIDTH-1:0] fetch_addr = fetch_i[ADDR_WIDTH-1:0];
  wire [ADDR_WIDTH-1:0] accum_addr = accum_i[ADDR_WIDTH-1:0];
  assign mem_r_addr =
      ((state == S_IDLE) && fetch_start && fetch_addr_valid) ? fetch_addr :
      ((state == S_IDLE) && accum_start && accum_addr_valid) ? accum_addr :
      op_addr;

  always @(posedge clk) begin
    if (!rst_n) begin
      state <= S_IDLE;
      clear_idx <= {ADDR_WIDTH{1'b0}};
      op_addr <= {ADDR_WIDTH{1'b0}};
      op_valid <= 1'b0;
      accum_delta_reg <= 32'd0;
      accum_base_reg <= 32'd0;
      clear_done <= 1'b0;
      store_done <= 1'b0;
      fetch_done <= 1'b0;
      fetch_result <= 32'd0;
      accum_done <= 1'b0;
      mem_w_en <= 1'b0;
      mem_w_addr <= {ADDR_WIDTH{1'b0}};
      mem_d_in <= 32'd0;
      accum_add_start <= 1'b0;
      accum_add_a <= 32'd0;
      accum_add_c <= 32'd0;
    end else begin
      clear_done <= 1'b0;
      store_done <= 1'b0;
      fetch_done <= 1'b0;
      accum_done <= 1'b0;
      mem_w_en <= 1'b0;
      accum_add_start <= 1'b0;

      case (state)
        S_IDLE: begin
          if (clear_start) begin
            state <= S_CLEAR;
            clear_idx <= {ADDR_WIDTH{1'b0}};
          end else if (store_start) begin
            if (store_addr_valid) begin
              mem_w_en <= 1'b1;
              mem_w_addr <= store_addr;
              mem_d_in <= store_v;
            end
            store_done <= 1'b1;
          end else if (fetch_start) begin
            op_valid <= fetch_addr_valid;
            op_addr <= fetch_addr_valid ? fetch_addr : {ADDR_WIDTH{1'b0}};
            fetch_result <= 32'd0;
            state <= S_FETCH;
          end else if (accum_start) begin
            if (accum_addr_valid) begin
              op_addr <= accum_addr;
              accum_delta_reg <= accum_delta;
              state <= S_ACCUM_READ;
            end else begin
              accum_done <= 1'b1;
            end
          end
        end

        S_CLEAR: begin
          mem_w_en <= 1'b1;
          mem_w_addr <= clear_idx;
          mem_d_in <= 32'd0;
          if (clear_idx == DIM - 1) begin
            state <= S_IDLE;
            clear_done <= 1'b1;
          end else begin
            clear_idx <= clear_idx + 1'b1;
          end
        end

        S_FETCH: begin
          fetch_result <= op_valid ? mem_d_out : 32'd0;
          fetch_done <= 1'b1;
          state <= S_IDLE;
        end

        S_ACCUM_READ: begin
          accum_base_reg <= mem_d_out;
`ifdef SYNTHESIS
          if (ENABLE_ACCUM != 0) begin
            state <= S_ACCUM_ADD_ISSUE;
          end else begin
            accum_done <= 1'b1;
            state <= S_IDLE;
          end
`else
          if (ENABLE_ACCUM != 0) begin
            mem_w_en <= 1'b1;
            mem_w_addr <= op_addr;
            mem_d_in <= fp_add_comb(mem_d_out, accum_delta_reg);
          end
          accum_done <= 1'b1;
          state <= S_IDLE;
`endif
        end

        S_ACCUM_ADD_ISSUE: begin
          accum_add_a <= accum_base_reg;
          accum_add_c <= accum_delta_reg;
          accum_add_start <= 1'b1;
          state <= S_ACCUM_ADD_WAIT;
        end

        S_ACCUM_ADD_WAIT: begin
          if (accum_add_done) begin
            mem_w_en <= 1'b1;
            mem_w_addr <= op_addr;
            mem_d_in <= accum_add_result;
            accum_done <= 1'b1;
            state <= S_IDLE;
          end
        end

        default: begin
          state <= S_IDLE;
        end
      endcase
    end
  end

endmodule
