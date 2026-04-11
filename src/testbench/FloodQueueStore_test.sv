`timescale 1ns / 1ps

module FloodQueueStore_test;
  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk;

  reg addQueue_start = 1'b0;
  reg [7:0] addQueue_i = 8'd0;
  reg [7:0] addQueue_j = 8'd0;
  reg [31:0] addQueue_d = 32'd0;
  wire addQueue_done;

  reg getQueueLen_start = 1'b0;
  wire getQueueLen_done;
  wire [15:0] getQueueLen_result;

  reg popQueue_start = 1'b0;
  wire popQueue_done;
  wire [17:0] popQueue_result;

  FloodQueueStore #(
      .DEPTH(4)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .clear(1'b0),
      .addQueue_start(addQueue_start),
      .addQueue_i(addQueue_i),
      .addQueue_j(addQueue_j),
      .addQueue_d(addQueue_d),
      .addQueue_done(addQueue_done),
      .getQueueLen_start(getQueueLen_start),
      .getQueueLen_done(getQueueLen_done),
      .getQueueLen_result(getQueueLen_result),
      .popQueue_start(popQueue_start),
      .popQueue_done(popQueue_done),
      .popQueue_result(popQueue_result)
  );

  task automatic add_item(
      input [7:0] i,
      input [7:0] j,
      input [1:0] d
  );
    begin
      @(negedge clk);
      addQueue_i <= i;
      addQueue_j <= j;
      addQueue_d <= d;
      addQueue_start <= 1'b1;
      @(negedge clk);
      addQueue_start <= 1'b0;
      wait (addQueue_done == 1'b1);
      #1;
    end
  endtask

  task automatic expect_len(input [15:0] expected);
    begin
      @(negedge clk);
      getQueueLen_start <= 1'b1;
      @(negedge clk);
      getQueueLen_start <= 1'b0;
      wait (getQueueLen_done == 1'b1);
      #1;
      if (getQueueLen_result !== expected) begin
        $fatal(1, "FloodQueueStore length mismatch: got %0d expected %0d",
               getQueueLen_result, expected);
      end
    end
  endtask

  task automatic pop_and_expect(
      input [7:0] expected_i,
      input [7:0] expected_j,
      input [1:0] expected_d
  );
    begin
      @(negedge clk);
      popQueue_start <= 1'b1;
      @(negedge clk);
      popQueue_start <= 1'b0;
      wait (popQueue_done == 1'b1);
      #1;
      if (popQueue_result !== {expected_i, expected_j, expected_d}) begin
        $fatal(1, "FloodQueueStore pop mismatch: got %h expected %h",
               popQueue_result, {expected_i, expected_j, expected_d});
      end
    end
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst_n <= 1'b1;

    expect_len(16'd0);
    pop_and_expect(8'd0, 8'd0, 2'd0);

    add_item(8'd1, 8'd2, 2'd0);
    add_item(8'd3, 8'd4, 2'd1);
    add_item(8'd5, 8'd6, 2'd2);
    expect_len(16'd3);

    pop_and_expect(8'd1, 8'd2, 2'd0);
    pop_and_expect(8'd3, 8'd4, 2'd1);
    expect_len(16'd1);

    add_item(8'd7, 8'd8, 2'd3);
    add_item(8'd9, 8'd10, 2'd0);
    expect_len(16'd3);

    pop_and_expect(8'd5, 8'd6, 2'd2);
    pop_and_expect(8'd7, 8'd8, 2'd3);
    pop_and_expect(8'd9, 8'd10, 2'd0);
    expect_len(16'd0);

    if (!dut.underflow_seen) $fatal(1, "Expected underflow_seen to latch after empty pop");

    $display("FloodQueueStore_test passed.");
    $finish;
  end
endmodule
