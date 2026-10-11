
/*

Parameters:
- clk

- input matrix size n

Ports:
- start / busy / done
- input matrix A's RAM handles [R]
- output matrix LU's RAM handle [RW]

- fp FMA module's ports
- fp DIV module's ports


*/

module LUdecomp #(
    parameter integer SIZE = 8,
    parameter integer ELE_COUNT = SIZE * SIZE,
    parameter integer ELE_WIDTH = 32,
    parameter integer ADDR_WIDTH = $clog2(ELE_COUNT)
) (
    /* General Ports */
    input  wire clk,
    input  wire start,
    output reg  busy = 0,
    output reg  done = 0,

    /* Input Matrix A RAM handles (Read-only) */
    output reg  [ADDR_WIDTH-1:0] A_r_addr,
    input  wire [ ELE_WIDTH-1:0] A_data_out,

    /* Output Matrix LU RAM handles (Read & Write) */
    output reg LU_w_en = 0,
    output reg [ADDR_WIDTH-1:0] LU_w_addr,
    output reg [ADDR_WIDTH-1:0] LU_r_addr,
    output reg [ELE_WIDTH-1:0] LU_data_in,
    input wire [ELE_WIDTH-1:0] LU_data_out
);

  /* PYTHON REFERENCE
    def lu_decomp(A: np.ndarray):
      n = A.shape[0]
      L = np.eye(n, dtype=float)
      U = np.zeros((n, n), dtype=float)
      for j in range(n):
        for i in range(n):
          if i <= j:
            L[i, j] = neg(A[i, j])
            for k in range(i):
              L[i, j] = fma(L[i, k], L[k, j], L[i, j]) # i > k
            L[i, j] = neg(L[i, j])
          else: # i > j
            L[i, j] = neg(A[i, j])
            for k in range(j):
              L[i, j] = fma(L[i, k] , L[k, j], L[i,j]) # k < j; i > j => i > k
            L[i, j] = div(L[i, j], L[j, j]) 
            L[i, j] = neg(L[i, j])
      return L, L
  */

  /*
    Overall Status:
    Waiting for fp to finish
    Start to calculate another LU element

    every cycle either

    - process the result from last command

    - initiate

    - [0] fetch A[i,j], set LU[i,j] = 0
    - [1] fetch LU[i,k]
          reset tmp_res to neg(A[i, j])
    - [2] latch LU[i,k]
          fetch LU[k,j]
    - [3] initiate FMA
  */

  /*
    every cycle there will be one set of the following operations:

    check whether one fp operation is just finished fp operation triggers the following:

    1. initiate another fp operation
    2. if needed, store the result to the current result matrix "pointer" (index)
  */

  /* Floating Point FMA IP Wrapper handles */
  reg FMA_start = 0;
  reg [ELE_WIDTH-1:0] FMA_A;
  reg [ELE_WIDTH-1:0] FMA_B;
  reg [ELE_WIDTH-1:0] FMA_C;
  wire [ELE_WIDTH-1:0] FMA_R;
  wire FMA_done;
  wire FMA_busy;
  wire FMA_underflow;
  wire FMA_overflow;
  wire FMA_invaild;

  /* Floating Point DIV IP Wrapper handles */
  reg DIV_start = 0;
  reg [ELE_WIDTH-1:0] DIV_A;
  reg [ELE_WIDTH-1:0] DIV_B;
  wire [ELE_WIDTH-1:0] DIV_R;
  wire DIV_done;
  wire DIV_busy;
  wire DIV_underflow;
  wire DIV_overflow;
  wire DIV_invaild;
  wire DIV_div0;

  /* Floating Point FMA IP Wrapper Instance */
  fpo_fma LUdecomp_FMA_inst (
      .clk(clk),
      .start(FMA_start),
      .a(FMA_A),
      .b(FMA_B),
      .c(FMA_C),
      .busy(FMA_busy),
      .done(FMA_done),
      .result(FMA_R),
      .exc_underflow(FMA_underflow),
      .exc_overflow(FMA_overflow),
      .exc_invalid(FMA_invaild)
  );

  /* Floating Point DIV IP Wrapper Instance */
  fpo_div LUdecomp_DIV_inst (
      .clk(clk),
      .start(DIV_start),
      .a(DIV_A),
      .b(DIV_B),
      .busy(DIV_busy),
      .done(DIV_done),
      .result(DIV_R),
      .exc_underflow(DIV_underflow),
      .exc_overflow(DIV_overflow),
      .exc_invalid(DIV_invaild),
      .exc_div0(DIV_div0)
  );

  reg [4:0] state = 0;

  localparam integer StateIdle = 0;
  localparam integer StateFetchA = 1;
  localparam integer StateWaitA = 2;
  localparam integer StateInitK = 3;
  localparam integer StateFetchL = 4;
  localparam integer StateWaitL = 5;
  localparam integer StateFetchU = 6;
  localparam integer StateWaitU = 7;
  localparam integer StateStartFMA = 8;
  localparam integer StateWaitFMA = 9;
  localparam integer StateCheckK = 10;
  localparam integer StateFetchDiag = 11;
  localparam integer StateWaitDiag = 12;
  localparam integer StateStartDIV = 13;
  localparam integer StateWaitDIV = 14;
  localparam integer StateStore = 15;
  localparam integer StateWaitStore = 16;
  localparam integer StateAdvance = 17;
  localparam integer StateDone = 18;

  /* Loop Status Registers */
  // actually $clog2(SIZE) is enough. use this for same-width address calculation
  reg [ADDR_WIDTH-1:0] i;
  reg [ADDR_WIDTH-1:0] j;
  reg [ADDR_WIDTH-1:0] k;
  reg [ADDR_WIDTH-1:0] k_limit;

  reg [11:0] wait_ctr;

  function [ADDR_WIDTH-1:0] calc_addr;
    input [ADDR_WIDTH-1:0] ii;
    input [ADDR_WIDTH-1:0] jj;
    begin
      calc_addr = jj + ii * SIZE;
    end
  endfunction

  function [ELE_WIDTH-1:0] neg;
    input [ELE_WIDTH-1:0] ff;
    begin
      neg = {~ff[ELE_WIDTH-1], ff[ELE_WIDTH-2:0]};
    end
  endfunction

  reg [ELE_WIDTH-1:0] op1;
  reg [ELE_WIDTH-1:0] op2;
  reg [ELE_WIDTH-1:0] acc;
  reg [ELE_WIDTH-1:0] diag;

  always @(posedge clk) begin
    done <= 1'b0;

    // default one-cycle start pulses
    FMA_start <= 1'b0;
    DIV_start <= 1'b0;
    LU_w_en    <= 1'b0;

    if (wait_ctr != 0) wait_ctr <= wait_ctr - 1;
    else
      case (state)
        StateIdle: begin
          if (start) begin
            busy <= 1'b1;
            i <= 0;
            j <= 0;
            state <= StateFetchA;
          end
        end

        StateFetchA: begin
          A_r_addr <= calc_addr(i, j);
          wait_ctr <= 1;
          state <= StateWaitA;
        end

        StateWaitA: begin
          acc <= neg(A_data_out);
          k_limit <= (i > j) ? j : i;
          k <= 0;
          state <= StateCheckK;
        end

        StateCheckK: begin
          if (k < k_limit) state <= StateFetchL;
          else if (i > j) state <= StateFetchDiag;
          else state <= StateStore;
        end

        StateFetchL: begin
          LU_r_addr <= calc_addr(i, k);
          wait_ctr <= 1;
          state <= StateWaitL;
        end

        StateWaitL: begin
          op1   <= LU_data_out;
          state <= StateFetchU;
        end

        StateFetchU: begin
          LU_r_addr <= calc_addr(k, j);
          wait_ctr <= 1;
          state <= StateWaitU;
        end

        StateWaitU: begin
          op2   <= LU_data_out;
          state <= StateStartFMA;
        end

        StateStartFMA: begin
          FMA_A <= op1;
          FMA_B <= op2;
          FMA_C <= acc;
          FMA_start <= 1'b1;
          state <= StateWaitFMA;
        end

        StateWaitFMA: begin
          if (FMA_done) begin
            acc <= FMA_R;
            k <= k + 1;
            state <= StateCheckK;
          end
        end

        StateFetchDiag: begin
          LU_r_addr <= calc_addr(j, j);
          wait_ctr <= 1;
          state <= StateWaitDiag;
        end

        StateWaitDiag: begin
          diag  <= LU_data_out;
          state <= StateStartDIV;
        end

        StateStartDIV: begin
          DIV_A <= acc;
          DIV_B <= diag;
          DIV_start <= 1'b1;
          state <= StateWaitDIV;
        end

        StateWaitDIV: begin
          if (DIV_done) begin
            acc   <= DIV_R;
            state <= StateStore;
          end
        end

        StateStore: begin
          LU_w_en    <= 1'b1;
          LU_w_addr  <= calc_addr(i,j);
          LU_data_in <= neg(acc);
          wait_ctr  <= 1;
          state <= StateWaitStore;
        end

        StateWaitStore: begin
          state <= StateAdvance;
        end

        StateAdvance: begin
          if (i + 1 < SIZE) begin
            i <= i + 1;
            state <= StateFetchA;
          end else if (j + 1 < SIZE) begin
            i <= 0;
            j <= j + 1;
            state <= StateFetchA;
          end else begin
            busy  <= 1'b0;
            done  <= 1'b1;
            state <= StateIdle;
          end
        end
        default: begin
        end
      endcase
  end

endmodule
