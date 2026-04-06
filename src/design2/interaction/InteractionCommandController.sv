`timescale 1ns / 1ps

module InteractionCommandController #(
    parameter integer CanvasPosX = 64,
    parameter integer CanvasPosY = 64,
    parameter integer CanvasWidth = 420,
    parameter integer CanvasHeight = 288,
    parameter integer CellSize = 32,
    parameter integer GridWidth = 32,
    parameter integer GridHeight = 32
) (
    input  wire                     clk,
    input  wire                     reset,
    input  wire                     frame_start_pulse,
    input  wire [3:0]               mode_select,
    input  wire [11:0]              mouse_x,
    input  wire [11:0]              mouse_y,
    input  wire                     mouse_left,
    input  wire                     mouse_middle,
    input  wire                     mouse_right,
    input  wire signed [12:0]       grid_pos_x,
    input  wire signed [12:0]       grid_pos_y,
    output reg                      cmd_valid,
    output reg  [63:0]              cmd_payload,
    output reg                      frame_done,
    output reg                      frame_drop_flag
);

  import CellStorePkg::*;
  import ComponentStorePkg::*;
  import MetaCommandPkg::*;

  localparam [3:0] MODE_SELECT   = 4'd0;
  localparam [3:0] MODE_WIRE     = 4'd1;
  localparam [3:0] MODE_JUNCTION = 4'd2;
  localparam [3:0] MODE_ELBOW    = 4'd3;
  localparam [3:0] MODE_TEE      = 4'd4;
  localparam [3:0] MODE_RES      = 4'd5;
  localparam [3:0] MODE_VOLT     = 4'd6;
  localparam [3:0] MODE_CURR     = 4'd7;
  localparam [3:0] MODE_ROTATE   = 4'd8;
  localparam [3:0] MODE_DELETE   = 4'd9;
  localparam [3:0] MODE_GROUND   = 4'd10;

  wire snapshot_valid;
  wire [11:0] snapshot_mouse_x;
  wire [11:0] snapshot_mouse_y;
  wire snapshot_mouse_left;
  wire snapshot_mouse_middle;
  wire snapshot_mouse_right;
  wire signed [12:0] snapshot_grid_pos_x;
  wire signed [12:0] snapshot_grid_pos_y;

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

  function automatic logic in_canvas(
      input logic [11:0] x,
      input logic [11:0] y
  );
    in_canvas = (x >= CanvasPosX) && (x < CanvasPosX + CanvasWidth) &&
                (y >= CanvasPosY) && (y < CanvasPosY + CanvasHeight);
  endfunction

  function automatic logic [4:0] target_cell_x(
      input logic [11:0] x,
      input logic signed [12:0] view_x
  );
    logic signed [13:0] rel_x;
    begin
      rel_x = $signed({1'b0, x}) - CanvasPosX - view_x;
      if (rel_x < 0) begin
        target_cell_x = 5'd0;
      end else begin
        target_cell_x = rel_x[12:0] / CellSize;
      end
    end
  endfunction

  function automatic logic [4:0] target_cell_y(
      input logic [11:0] y,
      input logic signed [12:0] view_y
  );
    logic signed [13:0] rel_y;
    begin
      rel_y = $signed({1'b0, y}) - CanvasPosY - view_y;
      if (rel_y < 0) begin
        target_cell_y = 5'd0;
      end else begin
        target_cell_y = rel_y[12:0] / CellSize;
      end
    end
  endfunction

  function automatic logic cell_target_valid(
      input logic [11:0] x,
      input logic [11:0] y,
      input logic signed [12:0] view_x,
      input logic signed [12:0] view_y
  );
    logic [4:0] tx;
    logic [4:0] ty;
    begin
      tx = target_cell_x(x, view_x);
      ty = target_cell_y(y, view_y);
      cell_target_valid = in_canvas(x, y) && (tx < GridWidth) && (ty < GridHeight);
    end
  endfunction

  always @(posedge clk) begin
    if (reset) begin
      cmd_valid <= 1'b0;
      cmd_payload <= pack_command(CMD_NONE, '0, '0, '0, '0, '0, '0, '0, 1'b0, '0, '0);
      frame_done <= 1'b1;
      frame_drop_flag <= 1'b0;
    end else begin
      cmd_valid <= 1'b0;
      cmd_payload <= pack_command(CMD_NONE, '0, '0, '0, '0, '0, '0, '0, 1'b0, '0, '0);
      frame_done <= 1'b1;

      if (frame_start_pulse && !frame_done) begin
        frame_drop_flag <= 1'b1;
      end

      if (snapshot_valid) begin
        logic [4:0] tx;
        logic [4:0] ty;
        logic target_ok;
        tx = target_cell_x(snapshot_mouse_x, snapshot_grid_pos_x);
        ty = target_cell_y(snapshot_mouse_y, snapshot_grid_pos_y);
        target_ok = cell_target_valid(
            snapshot_mouse_x,
            snapshot_mouse_y,
            snapshot_grid_pos_x,
            snapshot_grid_pos_y
        );

        if (target_ok) begin
          case (mode_select)
            MODE_SELECT: begin
              if (snapshot_mouse_left && !snapshot_mouse_middle && !snapshot_mouse_right) begin
                cmd_valid <= 1'b1;
                cmd_payload <= pack_command(
                    CMD_SELECT_TARGET,
                    NON_COMPONENT_IDX,
                    tx,
                    ty,
                    SPRITE_WIRE,
                    2'b00,
                    COMP_RESISTOR,
                    '0,
                    1'b0,
                    '0,
                    '0
                );
              end
            end
            MODE_WIRE: begin
              if (snapshot_mouse_left ^ snapshot_mouse_right) begin
                cmd_valid <= 1'b1;
                cmd_payload <= pack_command(
                    CMD_CELL_WRITE,
                    NON_COMPONENT_IDX,
                    tx,
                    ty,
                    SPRITE_WIRE,
                    snapshot_mouse_right ? 2'b01 : 2'b00,
                    COMP_RESISTOR,
                    '0,
                    1'b0,
                    '0,
                    '0
                );
              end
            end
            MODE_JUNCTION: begin
              if (snapshot_mouse_left) begin
                cmd_valid <= 1'b1;
                cmd_payload <= pack_command(CMD_CELL_WRITE, NON_COMPONENT_IDX, tx, ty, SPRITE_JUNCTION, 2'b00, COMP_RESISTOR, '0, 1'b0, '0, '0);
              end
            end
            MODE_ELBOW: begin
              if (snapshot_mouse_left) begin
                cmd_valid <= 1'b1;
                cmd_payload <= pack_command(CMD_CELL_WRITE, NON_COMPONENT_IDX, tx, ty, SPRITE_ELBOW, 2'b00, COMP_RESISTOR, '0, 1'b0, '0, '0);
              end
            end
            MODE_TEE: begin
              if (snapshot_mouse_left) begin
                cmd_valid <= 1'b1;
                cmd_payload <= pack_command(CMD_CELL_WRITE, NON_COMPONENT_IDX, tx, ty, SPRITE_TEE, 2'b00, COMP_RESISTOR, '0, 1'b0, '0, '0);
              end
            end
            MODE_GROUND: begin
              if (snapshot_mouse_left) begin
                cmd_valid <= 1'b1;
                cmd_payload <= pack_command(CMD_CELL_WRITE, NON_COMPONENT_IDX, tx, ty, SPRITE_GROUND, 2'b00, COMP_RESISTOR, '0, 1'b0, '0, '0);
              end
            end
            MODE_RES: begin
              if (snapshot_mouse_left) begin
                cmd_valid <= 1'b1;
                cmd_payload <= pack_command(CMD_COMPONENT_CREATE, NON_COMPONENT_IDX, tx, ty, SPRITE_RES_LEFT, 2'b01, COMP_RESISTOR, 13'd100, 1'b0, '0, '0);
              end
            end
            MODE_VOLT: begin
              if (snapshot_mouse_left) begin
                cmd_valid <= 1'b1;
                cmd_payload <= pack_command(CMD_COMPONENT_CREATE, NON_COMPONENT_IDX, tx, ty, SPRITE_VOLT_LEFT, 2'b01, COMP_VOLTAGE, 13'd5, 1'b0, '0, '0);
              end
            end
            MODE_CURR: begin
              if (snapshot_mouse_left) begin
                cmd_valid <= 1'b1;
                cmd_payload <= pack_command(CMD_COMPONENT_CREATE, NON_COMPONENT_IDX, tx, ty, SPRITE_CURR_LEFT, 2'b01, COMP_CURRENT, 13'd1, 1'b0, '0, '0);
              end
            end
            MODE_ROTATE: begin
              if (snapshot_mouse_left) begin
                cmd_valid <= 1'b1;
                cmd_payload <= pack_command(CMD_ROTATE_TARGET, NON_COMPONENT_IDX, tx, ty, SPRITE_WIRE, 2'b00, COMP_RESISTOR, '0, 1'b0, '0, '0);
              end
            end
            MODE_DELETE: begin
              if (snapshot_mouse_left) begin
                cmd_valid <= 1'b1;
                cmd_payload <= pack_command(CMD_DELETE_TARGET, NON_COMPONENT_IDX, tx, ty, SPRITE_WIRE, 2'b00, COMP_RESISTOR, '0, 1'b0, '0, '0);
              end
            end
            default: begin
            end
          endcase
        end
      end
    end
  end

endmodule
