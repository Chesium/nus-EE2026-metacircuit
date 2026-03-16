`timescale 1ns / 1ps


module ClockDividerMs #(
    parameter integer MS = 1000
) (
    input CLK100MHZ,
    input enable,
    output reg clk_out = 0
);

  localparam integer CounterMax = 100_000 / 2 * MS;

  reg [$clog2(CounterMax)-1:0] count = 0;

  always @(posedge CLK100MHZ) begin
    if (enable) begin
      if (count == CounterMax) begin
        count   <= 0;
        clk_out <= ~clk_out;
      end else begin
        count <= count + 1;
      end
    end
  end
endmodule
