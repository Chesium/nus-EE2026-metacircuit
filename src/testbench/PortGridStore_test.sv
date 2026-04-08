`timescale 1ns / 1ps

module PortGridStore_test;
  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk;

  reg fetchP_start = 1'b0;
  reg [7:0] fetchP_i = 8'd0;
  reg [7:0] fetchP_j = 8'd0;
  wire fetchP_done;
  wire [3:0] fetchP_result;

  PortGridStore #(
      .GRID_WIDTH(8),
      .GRID_HEIGHT(8)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .fetchP_start(fetchP_start),
      .fetchP_i(fetchP_i),
      .fetchP_j(fetchP_j),
      .fetchP_done(fetchP_done),
      .fetchP_result(fetchP_result)
  );

  task automatic fetch_and_expect(
      input [7:0] i,
      input [7:0] j,
      input [3:0] expected
  );
    begin
      @(negedge clk);
      fetchP_i <= i;
      fetchP_j <= j;
      fetchP_start <= 1'b1;
      @(negedge clk);
      fetchP_start <= 1'b0;
      wait (fetchP_done == 1'b1);
      #1;
      if (fetchP_result !== expected) begin
        $fatal(1, "PortGridStore mismatch at (%0d,%0d): got %b expected %b",
               i, j, fetchP_result, expected);
      end
    end
  endtask

  initial begin
    $readmemb("src/testbench/data/flooding_ports_8x8.mem", dut.mem);

    repeat (2) @(negedge clk);
    rst_n <= 1'b1;

    fetch_and_expect(8'd0, 8'd0, 4'b0100);
    fetch_and_expect(8'd1, 8'd0, 4'b1101);
    fetch_and_expect(8'd7, 8'd7, 4'b0011);
    fetch_and_expect(8'd3, 8'd4, 4'b1011);
    fetch_and_expect(8'd8, 8'd0, 4'b0000);
    fetch_and_expect(8'd0, 8'd9, 4'b0000);

    $display("PortGridStore_test passed.");
    $finish;
  end
endmodule
