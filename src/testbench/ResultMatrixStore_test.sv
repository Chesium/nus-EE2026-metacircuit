`timescale 1ns / 1ps

module ResultMatrixStore_test;
  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk;

  reg storeR_start = 1'b0;
  reg [7:0] storeR_i = 8'd0;
  reg [7:0] storeR_j = 8'd0;
  reg [7:0] storeR_v = 8'd0;
  wire storeR_done;

  ResultMatrixStore #(
      .GRID_WIDTH(8),
      .GRID_HEIGHT(8)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .storeR_start(storeR_start),
      .storeR_i(storeR_i),
      .storeR_j(storeR_j),
      .storeR_v(storeR_v),
      .storeR_done(storeR_done)
  );

  function automatic integer flatten_addr(
      input integer i,
      input integer j
  );
    begin
      flatten_addr = j * 8 + i;
    end
  endfunction

  task automatic store_cell(
      input [7:0] i,
      input [7:0] j,
      input [7:0] v
  );
    begin
      @(negedge clk);
      storeR_i <= i;
      storeR_j <= j;
      storeR_v <= v;
      storeR_start <= 1'b1;
      @(negedge clk);
      storeR_start <= 1'b0;
      wait (storeR_done == 1'b1);
      #1;
    end
  endtask

  initial begin
    repeat (2) @(negedge clk);
    rst_n <= 1'b1;

    store_cell(8'd1, 8'd2, 8'd5);
    if (dut.mem[flatten_addr(1, 2)] !== 8'd5) $fatal(1, "ResultMatrixStore write failed at (1,2)");

    store_cell(8'd7, 8'd7, 8'd99);
    if (dut.mem[flatten_addr(7, 7)] !== 8'd99) $fatal(1, "ResultMatrixStore write failed at (7,7)");

    store_cell(8'd1, 8'd2, 8'd42);
    if (dut.mem[flatten_addr(1, 2)] !== 8'd42) $fatal(1, "ResultMatrixStore overwrite failed");

    store_cell(8'd8, 8'd0, 8'd77);
    if (dut.mem[flatten_addr(1, 2)] !== 8'd42) $fatal(1, "Out-of-range write corrupted valid cell");

    @(negedge clk);
    rst_n <= 1'b0;
    @(negedge clk);
    rst_n <= 1'b1;
    if (dut.mem[flatten_addr(1, 2)] !== 8'd0) $fatal(1, "ResultMatrixStore reset clear failed");

    $display("ResultMatrixStore_test passed.");
    $finish;
  end
endmodule
