`timescale 1ns / 1ps
// Independent FIFO ledger; no clear between successive enqueue/dequeue pairs.
module M5FloodQueueLifetime #(parameter integer DEPTH = 1152);
  reg clk = 0, rst_n = 0, clear = 0;
  always #5 clk = ~clk;
  reg add_start = 0, len_start = 0, pop_start = 0;
  reg [7:0] item_i = 0, item_j = 0;
  reg [31:0] item_d = 0;
  wire add_done, len_done, pop_done;
  wire [15:0] len_result;
  wire [17:0] pop_result;
  FloodQueueStore #(.DEPTH(DEPTH)) dut (
    .clk(clk), .rst_n(rst_n), .clear(clear),
    .addQueue_start(add_start), .addQueue_i(item_i),
    .addQueue_j(item_j), .addQueue_d(item_d), .addQueue_done(add_done),
    .getQueueLen_start(len_start), .getQueueLen_done(len_done),
    .getQueueLen_result(len_result), .popQueue_start(pop_start),
    .popQueue_done(pop_done), .popQueue_result(pop_result));
  integer sequence_id, checks = 0;
  reg inject;
  reg [17:0] expected, observed;
  initial begin
    inject = $test$plusargs("m5-corrupt-queue-observation");
    repeat (2) @(negedge clk);
    rst_n = 1;
    for (sequence_id = 0; sequence_id < 3*DEPTH+7; sequence_id = sequence_id+1) begin
      // Literal sequence encoding is independent of the DUT address/pointers.
      expected = 18'(sequence_id * 37 + 19);
      @(negedge clk);
      {item_i,item_j,item_d[1:0]} = expected;
      add_start = 1;
      @(negedge clk); add_start = 0;
      @(negedge clk);
      if (!add_done) $fatal(1,"M5_QUEUE_FAILURE add_ack sequence=%0d",sequence_id);
      @(negedge clk); pop_start = 1;
      @(negedge clk); pop_start = 0;
      @(negedge clk);
      observed = pop_result ^ ((inject && sequence_id==0) ? 18'd1 : 18'd0);
      if (!pop_done || observed !== expected)
        $fatal(1,"M5_QUEUE_FAILURE fifo depth=%0d sequence=%0d got=%h expected=%h head=%0d tail=%0d",
          DEPTH,sequence_id,observed,expected,dut.head_ptr,dut.tail_ptr);
      if (dut.count !== 0)
        $fatal(1,"M5_QUEUE_FAILURE count sequence=%0d",sequence_id);
      checks = checks+1;
    end
    $display("M5_QUEUE_LIFETIME_PASS depth=%0d checks=%0d",DEPTH,checks);
    $finish;
  end
  initial begin
    #1000000;
    $fatal(1,"M5_QUEUE_FAILURE watchdog");
  end
endmodule
