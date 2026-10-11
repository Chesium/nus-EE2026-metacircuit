`timescale 1ns / 1ps

module FloodQueueStore #(
    parameter integer DEPTH = 256,
    parameter integer LEN_WIDTH = 16,
    parameter integer PTR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH)
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        clear,

    input  wire        addQueue_start,
    input  wire [7:0]  addQueue_i,
    input  wire [7:0]  addQueue_j,
    input  wire [31:0] addQueue_d,
    output reg         addQueue_done,

    input  wire        getQueueLen_start,
    output reg         getQueueLen_done,
    output reg  [15:0] getQueueLen_result,

    input  wire        popQueue_start,
    output reg         popQueue_done,
    output reg  [17:0] popQueue_result
);

  (* ram_style = "block" *)
  reg [17:0] mem[0:DEPTH-1];

  reg [PTR_WIDTH-1:0] head_ptr;
  reg [PTR_WIDTH-1:0] tail_ptr;
  reg [LEN_WIDTH-1:0] count;

  reg add_pending;
  reg get_len_pending;
  reg pop_pending;

  reg [15:0] captured_len;
  reg [17:0] captured_pop;

  reg overflow_seen;
  reg underflow_seen;

  integer idx;

  wire do_add = addQueue_start && (count < DEPTH);
  wire do_pop = popQueue_start && (count != 0);

  initial begin
    captured_pop = 18'd0;
    for (idx = 0; idx < DEPTH; idx = idx + 1) begin
      mem[idx] = 18'd0;
    end
  end

  always @(posedge clk) begin
    if (!rst_n || clear) begin
      head_ptr <= 0;
      tail_ptr <= 0;
      count <= 0;
      add_pending <= 1'b0;
      get_len_pending <= 1'b0;
      pop_pending <= 1'b0;
      captured_len <= 0;
      captured_pop <= 18'd0;
      addQueue_done <= 1'b0;
      getQueueLen_done <= 1'b0;
      getQueueLen_result <= 0;
      popQueue_done <= 1'b0;
      popQueue_result <= 18'd0;
      overflow_seen <= 1'b0;
      underflow_seen <= 1'b0;
    end else begin
      addQueue_done <= add_pending;
      getQueueLen_done <= get_len_pending;
      popQueue_done <= pop_pending;
      getQueueLen_result <= captured_len;
      popQueue_result <= captured_pop;

      add_pending <= addQueue_start;
      get_len_pending <= getQueueLen_start;
      pop_pending <= popQueue_start;

      if (getQueueLen_start) begin
        captured_len <= count;
      end

      if (do_add) begin
        mem[tail_ptr] <= {addQueue_i, addQueue_j, addQueue_d[1:0]};
        tail_ptr <= tail_ptr + {{(PTR_WIDTH-1){1'b0}}, 1'b1};
      end else if (addQueue_start) begin
        overflow_seen <= 1'b1;
      end

      if (do_pop) begin
        captured_pop <= mem[head_ptr];
        head_ptr <= head_ptr + {{(PTR_WIDTH-1){1'b0}}, 1'b1};
      end else if (popQueue_start) begin
        captured_pop <= 18'd0;
        underflow_seen <= 1'b1;
      end

      case ({do_add, do_pop})
        2'b10: count <= count + {{(LEN_WIDTH-1){1'b0}}, 1'b1};
        2'b01: count <= count - {{(LEN_WIDTH-1){1'b0}}, 1'b1};
        default: count <= count;
      endcase
    end
  end

endmodule
