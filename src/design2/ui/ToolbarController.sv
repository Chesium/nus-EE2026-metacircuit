`timescale 1ns / 1ps

module ToolbarController (
    input  wire       clk,
    input  wire       rst,
    input  wire [15:0] sw,
    output reg  [3:0] mode_select
);

  always @(posedge clk) begin
    if (rst) begin
      mode_select <= 4'd0;
    end else begin
      mode_select <= sw[3:0];
    end
  end

endmodule
