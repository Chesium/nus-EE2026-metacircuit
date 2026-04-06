`timescale 1ns / 1ps

module WireDrawMode #(
    parameter integer CanvasPosX = 0,
    parameter integer CanvasPosY = 0,
    parameter integer CanvasWidth = 400,
    parameter integer CanvasHeight = 300,
    parameter integer CellSize = 32,
    parameter integer GridWidth = 16,
    parameter integer GridHeight = 16,
    parameter integer AddrWidth = $clog2(GridWidth * GridHeight),
    parameter integer DataWidth = 16
) (
    input  wire [11:0]                    mouse_x,
    input  wire [11:0]                    mouse_y,
    input  wire                           mouse_left,
    input  wire                           mouse_middle,
    input  wire                           mouse_right,
    input  wire signed [12:0]             grid_pos_x,
    input  wire signed [12:0]             grid_pos_y,
    output wire                           cmd_valid,
    output wire [AddrWidth-1:0]           cmd_addr,
    output wire [DataWidth-1:0]           cmd_wdata,
    output wire                           mouse_in_canvas,
    output wire                           target_cell_valid,
    output wire [11:0]                    target_cell_i,
    output wire [11:0]                    target_cell_j
);

  localparam signed [13:0] CanvasPosXSigned = CanvasPosX;
  localparam signed [13:0] CanvasPosYSigned = CanvasPosY;

  function [DataWidth-1:0] MakeCellData;
    input [1:0] rotation;
    input [5:0] sprite_type;
    begin
      MakeCellData = {7'b0000000, rotation, sprite_type, 1'b1};
    end
  endfunction

  wire draw_horizontal;
  wire draw_vertical;
  assign draw_horizontal = mouse_left && !mouse_middle && !mouse_right;
  assign draw_vertical   = mouse_right && !mouse_middle && !mouse_left;

  assign mouse_in_canvas = (mouse_x >= CanvasPosX) &&
                           (mouse_x < CanvasPosX + CanvasWidth) &&
                           (mouse_y >= CanvasPosY) &&
                           (mouse_y < CanvasPosY + CanvasHeight);

  wire signed [13:0] mouse_x_rel_canvas = $signed({1'b0, mouse_x}) - CanvasPosXSigned;
  wire signed [13:0] mouse_y_rel_canvas = $signed({1'b0, mouse_y}) - CanvasPosYSigned;
  wire signed [13:0] absolute_mouse_grid_x = mouse_x_rel_canvas - $signed(grid_pos_x);
  wire signed [13:0] absolute_mouse_grid_y = mouse_y_rel_canvas - $signed(grid_pos_y);

  wire absolute_mouse_grid_x_valid;
  wire absolute_mouse_grid_y_valid;
  assign absolute_mouse_grid_x_valid = absolute_mouse_grid_x >= 0;
  assign absolute_mouse_grid_y_valid = absolute_mouse_grid_y >= 0;

  assign target_cell_i = absolute_mouse_grid_x[11:0] / CellSize;
  assign target_cell_j = absolute_mouse_grid_y[11:0] / CellSize;

  assign target_cell_valid = mouse_in_canvas &&
                             absolute_mouse_grid_x_valid &&
                             absolute_mouse_grid_y_valid &&
                             (target_cell_i < GridWidth) &&
                             (target_cell_j < GridHeight);

  assign cmd_valid = target_cell_valid && (draw_horizontal || draw_vertical);
  assign cmd_addr = target_cell_i + (target_cell_j * GridWidth);
  assign cmd_wdata = draw_horizontal ? MakeCellData(2'b00, 6'd0) :
                     draw_vertical ? MakeCellData(2'b01, 6'd0) :
                     {DataWidth{1'b0}};

endmodule
