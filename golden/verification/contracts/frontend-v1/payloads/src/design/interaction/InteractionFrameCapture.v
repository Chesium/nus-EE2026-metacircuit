`timescale 1ns / 1ps

module InteractionFrameCapture #(
    parameter integer MouseCoordWidth = 12,
    parameter integer GridPosWidth = 13
) (
    input  wire                            clk,
    input  wire                            reset,
    input  wire                            frame_start_pulse,
    input  wire [MouseCoordWidth-1:0]      mouse_x,
    input  wire [MouseCoordWidth-1:0]      mouse_y,
    input  wire                            mouse_left,
    input  wire                            mouse_middle,
    input  wire                            mouse_right,
    input  wire signed [GridPosWidth-1:0]  grid_pos_x,
    input  wire signed [GridPosWidth-1:0]  grid_pos_y,
    output reg                             snapshot_valid = 1'b0,
    output reg [MouseCoordWidth-1:0]       snapshot_mouse_x = 0,
    output reg [MouseCoordWidth-1:0]       snapshot_mouse_y = 0,
    output reg                             snapshot_mouse_left = 1'b0,
    output reg                             snapshot_mouse_middle = 1'b0,
    output reg                             snapshot_mouse_right = 1'b0,
    output reg signed [GridPosWidth-1:0]   snapshot_grid_pos_x = 0,
    output reg signed [GridPosWidth-1:0]   snapshot_grid_pos_y = 0
);

  always @(posedge clk) begin
    if (reset) begin
      snapshot_valid        <= 1'b0;
      snapshot_mouse_x      <= 0;
      snapshot_mouse_y      <= 0;
      snapshot_mouse_left   <= 1'b0;
      snapshot_mouse_middle <= 1'b0;
      snapshot_mouse_right  <= 1'b0;
      snapshot_grid_pos_x   <= 0;
      snapshot_grid_pos_y   <= 0;
    end else begin
      snapshot_valid <= frame_start_pulse;
      if (frame_start_pulse) begin
        snapshot_mouse_x      <= mouse_x;
        snapshot_mouse_y      <= mouse_y;
        snapshot_mouse_left   <= mouse_left;
        snapshot_mouse_middle <= mouse_middle;
        snapshot_mouse_right  <= mouse_right;
        snapshot_grid_pos_x   <= grid_pos_x;
        snapshot_grid_pos_y   <= grid_pos_y;
      end
    end
  end

endmodule
