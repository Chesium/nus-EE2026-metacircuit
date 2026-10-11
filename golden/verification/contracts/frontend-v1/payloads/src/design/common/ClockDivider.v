`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.03.2026 20:04:24
// Design Name: 
// Module Name: ClockDivider
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ClockDivider #(
    parameter integer FREQ = 1
) (
    input CLK100MHZ,
    output reg clk_out = 0
);

  localparam integer CounterMax = 100_000_000 / 2 / FREQ - 1;

  reg [$clog2(CounterMax)-1:0] count = 0;

  always @(posedge CLK100MHZ) begin
    if (count == CounterMax) begin
      count   <= 0;
      clk_out <= ~clk_out;
    end else begin
      count <= count + 1;
    end
  end
endmodule
