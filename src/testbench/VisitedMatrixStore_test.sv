`timescale 1ns / 1ps

module VisitedMatrixStore_test;
  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk;

  reg getVisited_start = 1'b0;
  reg [7:0] getVisited_i = 8'd0;
  reg [7:0] getVisited_j = 8'd0;
  wire getVisited_done;
  wire getVisited_result;

  reg setVisited_start = 1'b0;
  reg [7:0] setVisited_i = 8'd0;
  reg [7:0] setVisited_j = 8'd0;
  wire setVisited_done;

  VisitedMatrixStore #(
      .GRID_WIDTH(8),
      .GRID_HEIGHT(8)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .getVisited_start(getVisited_start),
      .getVisited_i(getVisited_i),
      .getVisited_j(getVisited_j),
      .getVisited_done(getVisited_done),
      .getVisited_result(getVisited_result),
      .setVisited_start(setVisited_start),
      .setVisited_i(setVisited_i),
      .setVisited_j(setVisited_j),
      .setVisited_done(setVisited_done)
  );

  task automatic get_and_expect(
      input [7:0] i,
      input [7:0] j,
      input expected
  );
    begin
      @(negedge clk);
      getVisited_i <= i;
      getVisited_j <= j;
      getVisited_start <= 1'b1;
      @(negedge clk);
      getVisited_start <= 1'b0;
      wait (getVisited_done == 1'b1);
      #1;
      if (getVisited_result !== expected) begin
        $fatal(1, "VisitedMatrixStore mismatch at (%0d,%0d): got %b expected %b",
               i, j, getVisited_result, expected);
      end
    end
  endtask

  task automatic set_cell(input [7:0] i, input [7:0] j);
    begin
      @(negedge clk);
      setVisited_i <= i;
      setVisited_j <= j;
      setVisited_start <= 1'b1;
      @(negedge clk);
      setVisited_start <= 1'b0;
      wait (setVisited_done == 1'b1);
      #1;
    end
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst_n <= 1'b1;

    get_and_expect(8'd2, 8'd3, 1'b0);
    set_cell(8'd2, 8'd3);
    get_and_expect(8'd2, 8'd3, 1'b1);
    set_cell(8'd7, 8'd7);
    get_and_expect(8'd7, 8'd7, 1'b1);
    set_cell(8'd9, 8'd0);
    get_and_expect(8'd9, 8'd0, 1'b0);

    @(negedge clk);
    rst_n <= 1'b0;
    @(negedge clk);
    rst_n <= 1'b1;
    get_and_expect(8'd2, 8'd3, 1'b0);
    get_and_expect(8'd7, 8'd7, 1'b0);

    $display("VisitedMatrixStore_test passed.");
    $finish;
  end
endmodule
