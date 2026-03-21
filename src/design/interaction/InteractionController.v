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
    input  wire [2:0]                mode_select,
    input  wire [11:0]               mouse_x,
    input  wire [11:0]               mouse_y,
    input  wire                      mouse_left,
    input  wire                      mouse_middle,
    input  wire                      mouse_right,
    input  wire signed [12:0]        grid_pos_x,
    input  wire signed [12:0]        grid_pos_y,
    input  wire                      bg_cmd_ready,
    input  wire                      bg_rsp_valid,
    input  wire [DataWidth-1:0]      bg_rsp_rdata,
    output wire                      bg_cmd_valid,
    output wire                      bg_cmd_write,
    output wire [AddrWidth-1:0]      bg_cmd_addr,
    output wire [DataWidth-1:0]      bg_cmd_wdata,
    output wire                      frame_done,
    output reg                       frame_drop_flag = 1'b0
);

  localparam [2:0] ModeDrawWires    = 3'd0;
  localparam [2:0] ModeDrawJunction = 3'd1;
  localparam [2:0] ModeDrawElbow    = 3'd2;
  localparam [2:0] ModeDrawTee      = 3'd3;
  localparam [2:0] ModeDrawResistor = 3'd4;
  localparam [2:0] ModeDrawVoltage  = 3'd5;
  localparam [2:0] ModeDrawCurrent  = 3'd6;
  localparam [2:0] ModeRotateCell   = 3'd7;

  localparam [5:0] SpriteWire     = 6'd0;
  localparam [5:0] SpriteElbow    = 6'd1;
  localparam [5:0] SpriteTee      = 6'd2;
  localparam [5:0] SpriteJunction = 6'd3;
  localparam [5:0] SpriteResLeft  = 6'd5;
  localparam [5:0] SpriteResRight = 6'd6;
  localparam [5:0] SpriteVoltLeft = 6'd7;
  localparam [5:0] SpriteVoltRight = 6'd8;
  localparam [5:0] SpriteCurrLeft = 6'd9;
  localparam [5:0] SpriteCurrRight = 6'd10;

  wire snapshot_valid;
  wire [11:0] snapshot_mouse_x;
  wire [11:0] snapshot_mouse_y;
  wire snapshot_mouse_left;
  wire snapshot_mouse_middle;
  wire snapshot_mouse_right;
  wire signed [12:0] snapshot_grid_pos_x;
  wire signed [12:0] snapshot_grid_pos_y;

  reg decode_pending = 1'b0;
  reg cmd0_valid = 1'b0;
  reg cmd0_write = 1'b1;
  reg [AddrWidth-1:0] cmd0_addr = 0;
  reg [DataWidth-1:0] cmd0_wdata = 0;
  reg cmd1_valid = 1'b0;
  reg cmd1_write = 1'b1;
  reg [AddrWidth-1:0] cmd1_addr = 0;
  reg [DataWidth-1:0] cmd1_wdata = 0;
  reg rotate_rsp_pending = 1'b0;
  reg [AddrWidth-1:0] rotate_addr = 0;

  wire draw_cmd_valid;
  wire [AddrWidth-1:0] draw_cmd_addr;
  wire [DataWidth-1:0] draw_cmd_wdata;
  wire draw_mouse_in_canvas;
  wire draw_target_cell_valid;
  wire [11:0] draw_target_cell_i;
  wire [11:0] draw_target_cell_j;

  wire single_action;
  wire dual_cell_fits;
  wire [AddrWidth-1:0] second_cell_addr;

  function [DataWidth-1:0] MakeCellData;
    input [1:0] rotation;
    input [5:0] sprite_type;
    begin
      MakeCellData = {7'b0000000, rotation, sprite_type, 1'b1};
    end
  endfunction

  function [DataWidth-1:0] RotateCellData;
    input [DataWidth-1:0] original_data;
    reg [1:0] next_rotation;
    begin
      if (original_data[0]) begin
        next_rotation = original_data[8:7] + 2'b01;
        RotateCellData = {original_data[15:9], next_rotation, original_data[6:0]};
      end else begin
        RotateCellData = original_data;
      end
    end
  endfunction

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

  assign single_action = (snapshot_mouse_left ^ snapshot_mouse_right) && !snapshot_mouse_middle;
  assign dual_cell_fits = draw_target_cell_valid && (draw_target_cell_i < GridWidth - 1);
  assign second_cell_addr = draw_cmd_addr + 1'b1;

  assign bg_cmd_valid = cmd0_valid;
  assign bg_cmd_write = cmd0_write;
  assign bg_cmd_addr = cmd0_addr;
  assign bg_cmd_wdata = cmd0_wdata;
  assign frame_done = !decode_pending && !cmd0_valid && !cmd1_valid && !rotate_rsp_pending;

  always @(posedge clk) begin
    if (reset) begin
      decode_pending <= 1'b0;
      cmd0_valid <= 1'b0;
      cmd0_write <= 1'b1;
      cmd0_addr <= 0;
      cmd0_wdata <= 0;
      cmd1_valid <= 1'b0;
      cmd1_write <= 1'b1;
      cmd1_addr <= 0;
      cmd1_wdata <= 0;
      rotate_rsp_pending <= 1'b0;
      rotate_addr <= 0;
      frame_drop_flag <= 1'b0;
    end else begin
      if (frame_start_pulse) begin
        if (decode_pending || cmd0_valid || cmd1_valid || rotate_rsp_pending) begin
          frame_drop_flag <= 1'b1;
        end
        decode_pending <= 1'b1;
        cmd0_valid <= 1'b0;
        cmd1_valid <= 1'b0;
        rotate_rsp_pending <= 1'b0;
      end else begin
        if (decode_pending) begin
          decode_pending <= 1'b0;
          case (mode_select)
            ModeDrawWires: begin
              if (draw_cmd_valid) begin
                cmd0_valid <= 1'b1;
                cmd0_write <= 1'b1;
                cmd0_addr <= draw_cmd_addr;
                cmd0_wdata <= draw_cmd_wdata;
              end
            end

            ModeDrawJunction: begin
              if (draw_target_cell_valid && single_action) begin
                cmd0_valid <= 1'b1;
                cmd0_write <= 1'b1;
                cmd0_addr <= draw_cmd_addr;
                cmd0_wdata <= MakeCellData(2'b00, SpriteJunction);
              end
            end

            ModeDrawElbow: begin
              if (draw_target_cell_valid && single_action) begin
                cmd0_valid <= 1'b1;
                cmd0_write <= 1'b1;
                cmd0_addr <= draw_cmd_addr;
                cmd0_wdata <= MakeCellData(2'b00, SpriteElbow);
              end
            end

            ModeDrawTee: begin
              if (draw_target_cell_valid && single_action) begin
                cmd0_valid <= 1'b1;
                cmd0_write <= 1'b1;
                cmd0_addr <= draw_cmd_addr;
                cmd0_wdata <= MakeCellData(2'b00, SpriteTee);
              end
            end

            ModeDrawResistor: begin
              if (dual_cell_fits && single_action) begin
                cmd0_valid <= 1'b1;
                cmd0_write <= 1'b1;
                cmd0_addr <= draw_cmd_addr;
                cmd0_wdata <= MakeCellData(2'b00, SpriteResLeft);
                cmd1_valid <= 1'b1;
                cmd1_write <= 1'b1;
                cmd1_addr <= second_cell_addr;
                cmd1_wdata <= MakeCellData(2'b00, SpriteResRight);
              end
            end

            ModeDrawVoltage: begin
              if (dual_cell_fits && single_action) begin
                cmd0_valid <= 1'b1;
                cmd0_write <= 1'b1;
                cmd0_addr <= draw_cmd_addr;
                cmd0_wdata <= MakeCellData(2'b00, SpriteVoltLeft);
                cmd1_valid <= 1'b1;
                cmd1_write <= 1'b1;
                cmd1_addr <= second_cell_addr;
                cmd1_wdata <= MakeCellData(2'b00, SpriteVoltRight);
              end
            end

            ModeDrawCurrent: begin
              if (dual_cell_fits && single_action) begin
                cmd0_valid <= 1'b1;
                cmd0_write <= 1'b1;
                cmd0_addr <= draw_cmd_addr;
                cmd0_wdata <= MakeCellData(2'b00, SpriteCurrLeft);
                cmd1_valid <= 1'b1;
                cmd1_write <= 1'b1;
                cmd1_addr <= second_cell_addr;
                cmd1_wdata <= MakeCellData(2'b00, SpriteCurrRight);
              end
            end

            ModeRotateCell: begin
              if (draw_target_cell_valid && single_action) begin
                cmd0_valid <= 1'b1;
                cmd0_write <= 1'b0;
                cmd0_addr <= draw_cmd_addr;
                cmd0_wdata <= {DataWidth{1'b0}};
                rotate_addr <= draw_cmd_addr;
              end
            end

            default: begin
            end
          endcase
        end

        if (cmd0_valid && bg_cmd_ready) begin
          if (!cmd0_write) begin
            rotate_rsp_pending <= 1'b1;
          end

          if (cmd1_valid) begin
            cmd0_valid <= 1'b1;
            cmd0_write <= cmd1_write;
            cmd0_addr <= cmd1_addr;
            cmd0_wdata <= cmd1_wdata;
            cmd1_valid <= 1'b0;
          end else begin
            cmd0_valid <= 1'b0;
          end
        end

        if (rotate_rsp_pending && bg_rsp_valid) begin
          rotate_rsp_pending <= 1'b0;
          cmd0_valid <= 1'b1;
          cmd0_write <= 1'b1;
          cmd0_addr <= rotate_addr;
          cmd0_wdata <= RotateCellData(bg_rsp_rdata);
        end
      end
    end
  end

endmodule
