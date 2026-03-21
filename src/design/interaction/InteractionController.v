`timescale 1ns / 1ps

module InteractionController #(
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
    input  wire                      clk,
    input  wire                      reset,
    input  wire                      frame_start_pulse,
    input  wire [1:0]                mode_select,
    input  wire [11:0]               mouse_x,
    input  wire [11:0]               mouse_y,
    input  wire                      mouse_left,
    input  wire                      mouse_middle,
    input  wire                      mouse_right,
    input  wire signed [12:0]        grid_pos_x,
    input  wire signed [12:0]        grid_pos_y,
    input  wire                      bg_cmd_ready,
    output wire                      bg_cmd_valid,
    output wire                      bg_cmd_write,
    output wire [AddrWidth-1:0]      bg_cmd_addr,
    output wire [DataWidth-1:0]      bg_cmd_wdata,
    output wire                      frame_done,
    output reg                       frame_drop_flag = 1'b0
);

  localparam [1:0] ModeDrawWires = 2'd0;

  wire snapshot_valid;
  wire [11:0] snapshot_mouse_x;
  wire [11:0] snapshot_mouse_y;
  wire snapshot_mouse_left;
  wire snapshot_mouse_middle;
  wire snapshot_mouse_right;
  wire signed [12:0] snapshot_grid_pos_x;
  wire signed [12:0] snapshot_grid_pos_y;

  reg decode_pending = 1'b0;
  reg pending_cmd_valid = 1'b0;
  reg [AddrWidth-1:0] pending_cmd_addr = 0;
  reg [DataWidth-1:0] pending_cmd_wdata = 0;

  wire draw_cmd_valid;
  wire [AddrWidth-1:0] draw_cmd_addr;
  wire [DataWidth-1:0] draw_cmd_wdata;
  wire draw_mouse_in_canvas;
  wire draw_target_cell_valid;
  wire [11:0] draw_target_cell_i;
  wire [11:0] draw_target_cell_j;

  InteractionFrameCapture frame_capture_inst (
      .clk(clk),
      .reset(reset),
      .frame_start_pulse(frame_start_pulse),
      .mouse_x(mouse_x),
      .mouse_y(mouse_y),
      .mouse_left(mouse_left),
      .mouse_middle(mouse_middle),
      .mouse_right(mouse_right),
      .grid_pos_x(grid_pos_x),
      .grid_pos_y(grid_pos_y),
      .snapshot_valid(snapshot_valid),
      .snapshot_mouse_x(snapshot_mouse_x),
      .snapshot_mouse_y(snapshot_mouse_y),
      .snapshot_mouse_left(snapshot_mouse_left),
      .snapshot_mouse_middle(snapshot_mouse_middle),
      .snapshot_mouse_right(snapshot_mouse_right),
      .snapshot_grid_pos_x(snapshot_grid_pos_x),
      .snapshot_grid_pos_y(snapshot_grid_pos_y)
  );

  WireDrawMode #(
      .CanvasPosX(CanvasPosX),
      .CanvasPosY(CanvasPosY),
      .CanvasWidth(CanvasWidth),
      .CanvasHeight(CanvasHeight),
      .CellSize(CellSize),
      .GridWidth(GridWidth),
      .GridHeight(GridHeight),
      .AddrWidth(AddrWidth),
      .DataWidth(DataWidth)
  ) wire_draw_mode_inst (
      .mouse_x(snapshot_mouse_x),
      .mouse_y(snapshot_mouse_y),
      .mouse_left(snapshot_mouse_left),
      .mouse_middle(snapshot_mouse_middle),
      .mouse_right(snapshot_mouse_right),
      .grid_pos_x(snapshot_grid_pos_x),
      .grid_pos_y(snapshot_grid_pos_y),
      .cmd_valid(draw_cmd_valid),
      .cmd_addr(draw_cmd_addr),
      .cmd_wdata(draw_cmd_wdata),
      .mouse_in_canvas(draw_mouse_in_canvas),
      .target_cell_valid(draw_target_cell_valid),
      .target_cell_i(draw_target_cell_i),
      .target_cell_j(draw_target_cell_j)
  );

  assign bg_cmd_valid = pending_cmd_valid;
  assign bg_cmd_write = 1'b1;
  assign bg_cmd_addr = pending_cmd_addr;
  assign bg_cmd_wdata = pending_cmd_wdata;
  assign frame_done = !decode_pending && !pending_cmd_valid;

  always @(posedge clk) begin
    if (reset) begin
      decode_pending <= 1'b0;
      pending_cmd_valid <= 1'b0;
      pending_cmd_addr <= 0;
      pending_cmd_wdata <= 0;
      frame_drop_flag <= 1'b0;
    end else begin
      if (frame_start_pulse) begin
        if (decode_pending || pending_cmd_valid) begin
          frame_drop_flag <= 1'b1;
        end
        decode_pending <= 1'b1;
        pending_cmd_valid <= 1'b0;
      end else if (decode_pending) begin
        decode_pending <= 1'b0;
        if ((mode_select == ModeDrawWires) && draw_cmd_valid) begin
          pending_cmd_valid <= 1'b1;
          pending_cmd_addr <= draw_cmd_addr;
          pending_cmd_wdata <= draw_cmd_wdata;
        end
      end else if (pending_cmd_valid && bg_cmd_ready) begin
        pending_cmd_valid <= 1'b0;
      end
    end
  end

endmodule
