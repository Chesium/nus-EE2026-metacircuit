`timescale 1ns / 1ps

module BcdUnitToFp32Rom_test;
  reg clk = 1'b0;
  reg rst_n = 1'b0;
  reg start = 1'b0;
  reg [11:0] value_bcd = 12'd0;
  reg [7:0] unit_code = 8'd0;
  wire done;
  wire invalid;
  wire [31:0] value_fp32;

  shortreal sr;

  always #5 clk = ~clk;

  BcdUnitToFp32Rom dut (
      .clk(clk),
      .rst_n(rst_n),
      .start(start),
      .value_bcd(value_bcd),
      .unit_code(unit_code),
      .done(done),
      .invalid(invalid),
      .value_fp32(value_fp32)
  );

  task automatic request_value(input [11:0] bcd, input [7:0] unit);
    begin
      @(posedge clk);
      value_bcd <= bcd;
      unit_code <= unit;
      start <= 1'b1;
      @(posedge clk);
      start <= 1'b0;
      wait (done);
    end
  endtask

  initial begin
    repeat (4) @(posedge clk);
    rst_n = 1'b1;

    request_value(12'h001, 8'h00);
    if (invalid || value_fp32 !== 32'h3F800000) begin
      $fatal(1, "BcdUnitToFp32Rom_test expected 1.0");
    end

    request_value(12'h010, 8'h01);
    sr = 0.01;
    if (invalid || value_fp32 !== $shortrealtobits(sr)) begin
      $fatal(1, "BcdUnitToFp32Rom_test expected 0.01");
    end

    request_value(12'h470, 8'h04);
    sr = 470000.0;
    if (invalid || value_fp32 !== $shortrealtobits(sr)) begin
      $fatal(1, "BcdUnitToFp32Rom_test expected 470000.0");
    end

    request_value(12'hABC, 8'h00);
    if (!invalid) begin
      $fatal(1, "BcdUnitToFp32Rom_test expected invalid BCD rejection");
    end

    $display("BcdUnitToFp32Rom_test passed.");
    $finish;
  end
endmodule
