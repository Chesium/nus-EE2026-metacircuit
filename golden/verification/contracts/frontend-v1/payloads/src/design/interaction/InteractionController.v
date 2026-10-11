`timescale 1ns / 1ps

module InteractionController #(
    parameter integer CanvasPosX = 0,
    parameter integer CanvasPosY = 0,
    parameter integer CanvasWidth = 400,
    parameter integer CanvasHeight = 300,
    parameter integer CellSize = 32,
    parameter integer GridWidth = 16,
    parameter integer GridHeight = 16,
    parameter integer RotateFramesPerStep = 20,
    parameter integer AddrWidth = $clog2(GridWidth * GridHeight),
    parameter integer DataWidth = 16
) (
    input  wire                      clk,
    input  wire                      reset,
    input  wire                      frame_start_pulse,
    input  wire [3:0]                mode_select,
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

  localparam integer RotateCtrWidth = (RotateFramesPerStep <= 1) ? 1 : $clog2(RotateFramesPerStep);

  localparam [3:0] ModeDrawWires    = 4'd0;
  localparam [3:0] ModeDrawJunction = 4'd1;
  localparam [3:0] ModeDrawElbow    = 4'd2;
  localparam [3:0] ModeDrawTee      = 4'd3;
  localparam [3:0] ModeDrawResistor = 4'd4;
  localparam [3:0] ModeDrawVoltage  = 4'd5;
  localparam [3:0] ModeDrawCurrent  = 4'd6;
  localparam [3:0] ModeRotateCell   = 4'd7;
  localparam [3:0] ModeClearCell    = 4'd8;
  localparam [3:0] ModeDrawInductor = 4'd9;
  localparam [3:0] ModeDrawCapacitor = 4'd10;
  localparam [3:0] ModeDrawGround   = 4'd11;

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
  localparam [5:0] SpriteIndLeft  = 6'd11;
  localparam [5:0] SpriteIndRight = 6'd12;
  localparam [5:0] SpriteCapLeft  = 6'd13;
  localparam [5:0] SpriteCapRight = 6'd14;
  localparam [5:0] SpriteGround   = 6'd15;

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
  reg cmd2_valid = 1'b0;
  reg cmd2_write = 1'b1;
  reg [AddrWidth-1:0] cmd2_addr = 0;
  reg [DataWidth-1:0] cmd2_wdata = 0;
  reg readback_is_clear = 1'b0;
  reg clear_rsp_pending = 1'b0;
  reg rotate_rsp_pending = 1'b0;
  reg clear_decode_pending = 1'b0;
  reg rotate_decode_pending = 1'b0;
  reg clear_apply_pending = 1'b0;
  reg rotate_apply_pending = 1'b0;
  reg decode_issue_pending = 1'b0;
  reg decode_cmd0_valid = 1'b0;
  reg decode_cmd0_write = 1'b1;
  reg [AddrWidth-1:0] decode_cmd0_addr = 0;
  reg [DataWidth-1:0] decode_cmd0_wdata = 0;
  reg decode_cmd1_valid = 1'b0;
  reg decode_cmd1_write = 1'b1;
  reg [AddrWidth-1:0] decode_cmd1_addr = 0;
  reg [DataWidth-1:0] decode_cmd1_wdata = 0;
  reg decode_cmd2_valid = 1'b0;
  reg decode_cmd2_write = 1'b1;
  reg [AddrWidth-1:0] decode_cmd2_addr = 0;
  reg [DataWidth-1:0] decode_cmd2_wdata = 0;
  reg decode_readback_is_clear = 1'b0;
  reg [AddrWidth-1:0] decode_rotate_addr = 0;
  reg [11:0] decode_rotate_cell_i = 0;
  reg [11:0] decode_rotate_cell_j = 0;
  reg cmd_issue_pending = 1'b0;
  reg issue_cmd0_valid = 1'b0;
  reg issue_cmd0_write = 1'b1;
  reg [AddrWidth-1:0] issue_cmd0_addr = 0;
  reg [DataWidth-1:0] issue_cmd0_wdata = 0;
  reg issue_cmd1_valid = 1'b0;
  reg issue_cmd1_write = 1'b1;
  reg [AddrWidth-1:0] issue_cmd1_addr = 0;
  reg [DataWidth-1:0] issue_cmd1_wdata = 0;
  reg issue_cmd2_valid = 1'b0;
  reg issue_cmd2_write = 1'b1;
  reg [AddrWidth-1:0] issue_cmd2_addr = 0;
  reg [DataWidth-1:0] issue_cmd2_wdata = 0;
  reg [DataWidth-1:0] rsp_data_hold = 0;
  reg [AddrWidth-1:0] rotate_addr = 0;
  reg [11:0] rotate_cell_i = 0;
  reg [11:0] rotate_cell_j = 0;
  reg [RotateCtrWidth-1:0] rotate_frame_holdoff = 0;

  wire draw_cmd_valid;
  wire [AddrWidth-1:0] draw_cmd_addr;
  wire [DataWidth-1:0] draw_cmd_wdata;
  wire draw_mouse_in_canvas;
  wire draw_target_cell_valid;
  wire [11:0] draw_target_cell_i;
  wire [11:0] draw_target_cell_j;

  wire single_action;
  reg previous_left = 1'b0;
  reg canvas_gesture = 1'b0;
  wire press_action = single_action && !previous_left;
  wire dual_cell_fits;
  wire [AddrWidth-1:0] second_cell_addr;
  reg [5:0] clicked_sprite_type;
  reg [1:0] clicked_rotation;
  reg clicked_is_two_cell;
  reg clicked_is_left_half;
  reg signed [12:0] pair_step_x;
  reg signed [12:0] pair_step_y;
  reg signed [12:0] origin_cell_i_signed;
  reg signed [12:0] origin_cell_j_signed;
  reg signed [12:0] partner_cell_i_signed;
  reg signed [12:0] partner_cell_j_signed;
  reg signed [12:0] next_pair_step_x;
  reg signed [12:0] next_pair_step_y;
  reg signed [12:0] next_partner_cell_i_signed;
  reg signed [12:0] next_partner_cell_j_signed;
  reg origin_cell_valid;
  reg partner_cell_valid;
  reg next_partner_cell_valid;
  reg [AddrWidth-1:0] origin_cell_addr;
  reg [AddrWidth-1:0] partner_cell_addr;
  reg [AddrWidth-1:0] next_partner_cell_addr;
  reg [5:0] primary_sprite_type;
  reg [5:0] secondary_sprite_type;
  reg [5:0] partner_sprite_type;
  reg [1:0] next_rotation_value;
  reg decoded_is_two_cell = 1'b0;
  reg decoded_origin_cell_valid = 1'b0;
  reg decoded_partner_cell_valid = 1'b0;
  reg decoded_next_partner_cell_valid = 1'b0;
  reg [AddrWidth-1:0] decoded_origin_cell_addr = 0;
  reg [AddrWidth-1:0] decoded_partner_cell_addr = 0;
  reg [AddrWidth-1:0] decoded_next_partner_cell_addr = 0;
  reg [5:0] decoded_primary_sprite_type = 0;
  reg [5:0] decoded_secondary_sprite_type = 0;
  reg [1:0] decoded_next_rotation_value = 0;
  reg [DataWidth-1:0] decoded_rotated_cell_data = 0;

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

  function IsTwoCellSprite;
    input [5:0] sprite_type;
    begin
      case (sprite_type)
        SpriteResLeft, SpriteResRight,
        SpriteVoltLeft, SpriteVoltRight,
        SpriteCurrLeft, SpriteCurrRight,
        SpriteIndLeft, SpriteIndRight,
        SpriteCapLeft, SpriteCapRight: IsTwoCellSprite = 1'b1;
        default: IsTwoCellSprite = 1'b0;
      endcase
    end
  endfunction

  function IsLeftSprite;
    input [5:0] sprite_type;
    begin
      case (sprite_type)
        SpriteResLeft, SpriteVoltLeft, SpriteCurrLeft,
        SpriteIndLeft, SpriteCapLeft: IsLeftSprite = 1'b1;
        default: IsLeftSprite = 1'b0;
      endcase
    end
  endfunction

  function [5:0] PairSpriteType;
    input [5:0] sprite_type;
    begin
      case (sprite_type)
        SpriteResLeft: PairSpriteType = SpriteResRight;
        SpriteResRight: PairSpriteType = SpriteResLeft;
        SpriteVoltLeft: PairSpriteType = SpriteVoltRight;
        SpriteVoltRight: PairSpriteType = SpriteVoltLeft;
        SpriteCurrLeft: PairSpriteType = SpriteCurrRight;
        SpriteCurrRight: PairSpriteType = SpriteCurrLeft;
        SpriteIndLeft: PairSpriteType = SpriteIndRight;
        SpriteIndRight: PairSpriteType = SpriteIndLeft;
        SpriteCapLeft: PairSpriteType = SpriteCapRight;
        SpriteCapRight: PairSpriteType = SpriteCapLeft;
        default: PairSpriteType = sprite_type;
      endcase
    end
  endfunction

  function signed [12:0] PairStepX;
    input [1:0] rotation;
    begin
      case (rotation)
        2'd0: PairStepX = 13'sd1;
        2'd1: PairStepX = 13'sd0;
        2'd2: PairStepX = -13'sd1;
        default: PairStepX = 13'sd0;
      endcase
    end
  endfunction

  function signed [12:0] PairStepY;
    input [1:0] rotation;
    begin
      case (rotation)
        2'd0: PairStepY = 13'sd0;
        2'd1: PairStepY = 13'sd1;
        2'd2: PairStepY = 13'sd0;
        default: PairStepY = -13'sd1;
      endcase
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

  // Only the left button edits. A gesture must begin inside the canvas;
  // two-cell components are stamped on its press edge, while wires paint.
  assign single_action = snapshot_mouse_left &&
                         (canvas_gesture || (!previous_left && draw_target_cell_valid));
  assign dual_cell_fits = draw_target_cell_valid && (draw_target_cell_i < GridWidth - 1);
  assign second_cell_addr = draw_cmd_addr + 1'b1;

  assign bg_cmd_valid = cmd0_valid;
  assign bg_cmd_write = cmd0_write;
  assign bg_cmd_addr = cmd0_addr;
  assign bg_cmd_wdata = cmd0_wdata;
  assign frame_done = !decode_pending && !cmd0_valid && !cmd1_valid && !cmd2_valid &&
                      !clear_rsp_pending && !rotate_rsp_pending &&
                      !clear_decode_pending && !rotate_decode_pending &&
                      !clear_apply_pending && !rotate_apply_pending &&
                      !decode_issue_pending &&
                      !cmd_issue_pending;

  always @(*) begin
    clicked_sprite_type = rsp_data_hold[6:1];
    clicked_rotation = rsp_data_hold[8:7];
    clicked_is_two_cell = rsp_data_hold[0] && IsTwoCellSprite(rsp_data_hold[6:1]);
    clicked_is_left_half = IsLeftSprite(rsp_data_hold[6:1]);
    pair_step_x = PairStepX(rsp_data_hold[8:7]);
    pair_step_y = PairStepY(rsp_data_hold[8:7]);
    partner_sprite_type = PairSpriteType(rsp_data_hold[6:1]);
    primary_sprite_type = clicked_is_left_half ? clicked_sprite_type : partner_sprite_type;
    secondary_sprite_type = clicked_is_left_half ? partner_sprite_type : clicked_sprite_type;
    next_rotation_value = rsp_data_hold[8:7] + 2'b01;
    next_pair_step_x = PairStepX(next_rotation_value);
    next_pair_step_y = PairStepY(next_rotation_value);

    if (clicked_is_left_half) begin
      origin_cell_i_signed = $signed({1'b0, rotate_cell_i});
      origin_cell_j_signed = $signed({1'b0, rotate_cell_j});
    end else begin
      origin_cell_i_signed = $signed({1'b0, rotate_cell_i}) - pair_step_x;
      origin_cell_j_signed = $signed({1'b0, rotate_cell_j}) - pair_step_y;
    end

    partner_cell_i_signed = origin_cell_i_signed + pair_step_x;
    partner_cell_j_signed = origin_cell_j_signed + pair_step_y;
    next_partner_cell_i_signed = origin_cell_i_signed + next_pair_step_x;
    next_partner_cell_j_signed = origin_cell_j_signed + next_pair_step_y;

    origin_cell_valid = clicked_is_two_cell &&
                        (origin_cell_i_signed >= 0) &&
                        (origin_cell_i_signed < GridWidth) &&
                        (origin_cell_j_signed >= 0) &&
                        (origin_cell_j_signed < GridHeight);

    partner_cell_valid = clicked_is_two_cell &&
                         origin_cell_valid &&
                         (partner_cell_i_signed >= 0) &&
                         (partner_cell_i_signed < GridWidth) &&
                         (partner_cell_j_signed >= 0) &&
                         (partner_cell_j_signed < GridHeight);
    next_partner_cell_valid = clicked_is_two_cell &&
                              origin_cell_valid &&
                              (next_partner_cell_i_signed >= 0) &&
                              (next_partner_cell_i_signed < GridWidth) &&
                              (next_partner_cell_j_signed >= 0) &&
                              (next_partner_cell_j_signed < GridHeight);
    origin_cell_addr = origin_cell_i_signed[AddrWidth-1:0] +
                       (origin_cell_j_signed[AddrWidth-1:0] * GridWidth);
    partner_cell_addr = partner_cell_i_signed[AddrWidth-1:0] +
                        (partner_cell_j_signed[AddrWidth-1:0] * GridWidth);
    next_partner_cell_addr = next_partner_cell_i_signed[AddrWidth-1:0] +
                             (next_partner_cell_j_signed[AddrWidth-1:0] * GridWidth);
  end

  always @(posedge clk) begin
    if (reset) begin
      previous_left <= 1'b0;
      canvas_gesture <= 1'b0;
      decode_pending <= 1'b0;
      cmd0_valid <= 1'b0;
      cmd0_write <= 1'b1;
      cmd0_addr <= 0;
      cmd0_wdata <= 0;
      cmd1_valid <= 1'b0;
      cmd1_write <= 1'b1;
      cmd1_addr <= 0;
      cmd1_wdata <= 0;
      cmd2_valid <= 1'b0;
      cmd2_write <= 1'b1;
      cmd2_addr <= 0;
      cmd2_wdata <= 0;
      readback_is_clear <= 1'b0;
      clear_rsp_pending <= 1'b0;
      rotate_rsp_pending <= 1'b0;
      clear_decode_pending <= 1'b0;
      rotate_decode_pending <= 1'b0;
      clear_apply_pending <= 1'b0;
      rotate_apply_pending <= 1'b0;
      decode_issue_pending <= 1'b0;
      decode_cmd0_valid <= 1'b0;
      decode_cmd0_write <= 1'b1;
      decode_cmd0_addr <= 0;
      decode_cmd0_wdata <= 0;
      decode_cmd1_valid <= 1'b0;
      decode_cmd1_write <= 1'b1;
      decode_cmd1_addr <= 0;
      decode_cmd1_wdata <= 0;
      decode_cmd2_valid <= 1'b0;
      decode_cmd2_write <= 1'b1;
      decode_cmd2_addr <= 0;
      decode_cmd2_wdata <= 0;
      decode_readback_is_clear <= 1'b0;
      decode_rotate_addr <= 0;
      decode_rotate_cell_i <= 0;
      decode_rotate_cell_j <= 0;
      cmd_issue_pending <= 1'b0;
      issue_cmd0_valid <= 1'b0;
      issue_cmd0_write <= 1'b1;
      issue_cmd0_addr <= 0;
      issue_cmd0_wdata <= 0;
      issue_cmd1_valid <= 1'b0;
      issue_cmd1_write <= 1'b1;
      issue_cmd1_addr <= 0;
      issue_cmd1_wdata <= 0;
      issue_cmd2_valid <= 1'b0;
      issue_cmd2_write <= 1'b1;
      issue_cmd2_addr <= 0;
      issue_cmd2_wdata <= 0;
      rsp_data_hold <= 0;
      decoded_is_two_cell <= 1'b0;
      decoded_origin_cell_valid <= 1'b0;
      decoded_partner_cell_valid <= 1'b0;
      decoded_next_partner_cell_valid <= 1'b0;
      decoded_origin_cell_addr <= 0;
      decoded_partner_cell_addr <= 0;
      decoded_next_partner_cell_addr <= 0;
      decoded_primary_sprite_type <= 0;
      decoded_secondary_sprite_type <= 0;
      decoded_next_rotation_value <= 0;
      decoded_rotated_cell_data <= 0;
      rotate_addr <= 0;
      rotate_cell_i <= 0;
      rotate_cell_j <= 0;
      rotate_frame_holdoff <= 0;
      frame_drop_flag <= 1'b0;
    end else begin
      if (frame_start_pulse) begin
        if (decode_pending || cmd0_valid || cmd1_valid || cmd2_valid ||
            clear_rsp_pending || rotate_rsp_pending ||
            clear_decode_pending || rotate_decode_pending ||
            clear_apply_pending || rotate_apply_pending ||
            decode_issue_pending ||
            cmd_issue_pending) begin
          frame_drop_flag <= 1'b1;
        end
        decode_pending <= 1'b1;
        cmd0_valid <= 1'b0;
        cmd1_valid <= 1'b0;
        cmd2_valid <= 1'b0;
        readback_is_clear <= 1'b0;
        clear_rsp_pending <= 1'b0;
        rotate_rsp_pending <= 1'b0;
        clear_decode_pending <= 1'b0;
        rotate_decode_pending <= 1'b0;
        clear_apply_pending <= 1'b0;
        rotate_apply_pending <= 1'b0;
        decode_issue_pending <= 1'b0;
        cmd_issue_pending <= 1'b0;
      end else begin
        if (decode_pending) begin
          previous_left <= snapshot_mouse_left;
          if (!snapshot_mouse_left) canvas_gesture <= 1'b0;
          else if (!previous_left) canvas_gesture <= draw_target_cell_valid;
          decode_pending <= 1'b0;
          decode_issue_pending <= 1'b0;
          decode_cmd0_valid <= 1'b0;
          decode_cmd0_write <= 1'b1;
          decode_cmd0_addr <= 0;
          decode_cmd0_wdata <= 0;
          decode_cmd1_valid <= 1'b0;
          decode_cmd1_write <= 1'b1;
          decode_cmd1_addr <= 0;
          decode_cmd1_wdata <= 0;
          decode_cmd2_valid <= 1'b0;
          decode_cmd2_write <= 1'b1;
          decode_cmd2_addr <= 0;
          decode_cmd2_wdata <= 0;
          decode_readback_is_clear <= 1'b0;
          decode_rotate_addr <= 0;
          decode_rotate_cell_i <= 0;
          decode_rotate_cell_j <= 0;
          if ((mode_select == ModeRotateCell) && single_action) begin
            if (rotate_frame_holdoff != 0) begin
              rotate_frame_holdoff <= rotate_frame_holdoff - 1'b1;
            end else begin
              rotate_frame_holdoff <= (RotateFramesPerStep <= 1) ? 0 : RotateFramesPerStep - 1;
            end
          end else begin
            rotate_frame_holdoff <= 0;
          end

          case (mode_select)
            ModeDrawWires: begin
              if (draw_target_cell_valid && single_action) begin
                decode_issue_pending <= 1'b1;
                decode_cmd0_valid <= 1'b1;
                decode_cmd0_write <= 1'b1;
                decode_cmd0_addr <= draw_cmd_addr;
                decode_cmd0_wdata <= MakeCellData(2'b00, SpriteWire);
              end
            end

            ModeDrawJunction: begin
              if (draw_target_cell_valid && single_action) begin
                decode_issue_pending <= 1'b1;
                decode_cmd0_valid <= 1'b1;
                decode_cmd0_write <= 1'b1;
                decode_cmd0_addr <= draw_cmd_addr;
                decode_cmd0_wdata <= MakeCellData(2'b00, SpriteJunction);
              end
            end

            ModeDrawElbow: begin
              if (draw_target_cell_valid && single_action) begin
                decode_issue_pending <= 1'b1;
                decode_cmd0_valid <= 1'b1;
                decode_cmd0_write <= 1'b1;
                decode_cmd0_addr <= draw_cmd_addr;
                decode_cmd0_wdata <= MakeCellData(2'b00, SpriteElbow);
              end
            end

            ModeDrawTee: begin
              if (draw_target_cell_valid && single_action) begin
                decode_issue_pending <= 1'b1;
                decode_cmd0_valid <= 1'b1;
                decode_cmd0_write <= 1'b1;
                decode_cmd0_addr <= draw_cmd_addr;
                decode_cmd0_wdata <= MakeCellData(2'b00, SpriteTee);
              end
            end

            ModeDrawResistor: begin
              if (dual_cell_fits && press_action) begin
                decode_issue_pending <= 1'b1;
                decode_cmd0_valid <= 1'b1;
                decode_cmd0_write <= 1'b1;
                decode_cmd0_addr <= draw_cmd_addr;
                decode_cmd0_wdata <= MakeCellData(2'b00, SpriteResLeft);
                decode_cmd1_valid <= 1'b1;
                decode_cmd1_write <= 1'b1;
                decode_cmd1_addr <= second_cell_addr;
                decode_cmd1_wdata <= MakeCellData(2'b00, SpriteResRight);
              end
            end

            ModeDrawVoltage: begin
              if (dual_cell_fits && press_action) begin
                decode_issue_pending <= 1'b1;
                decode_cmd0_valid <= 1'b1;
                decode_cmd0_write <= 1'b1;
                decode_cmd0_addr <= draw_cmd_addr;
                decode_cmd0_wdata <= MakeCellData(2'b00, SpriteVoltLeft);
                decode_cmd1_valid <= 1'b1;
                decode_cmd1_write <= 1'b1;
                decode_cmd1_addr <= second_cell_addr;
                decode_cmd1_wdata <= MakeCellData(2'b00, SpriteVoltRight);
              end
            end

            ModeDrawCurrent: begin
              if (dual_cell_fits && press_action) begin
                decode_issue_pending <= 1'b1;
                decode_cmd0_valid <= 1'b1;
                decode_cmd0_write <= 1'b1;
                decode_cmd0_addr <= draw_cmd_addr;
                decode_cmd0_wdata <= MakeCellData(2'b00, SpriteCurrLeft);
                decode_cmd1_valid <= 1'b1;
                decode_cmd1_write <= 1'b1;
                decode_cmd1_addr <= second_cell_addr;
                decode_cmd1_wdata <= MakeCellData(2'b00, SpriteCurrRight);
              end
            end

            ModeDrawInductor: begin
              if (dual_cell_fits && press_action) begin
                decode_issue_pending <= 1'b1;
                decode_cmd0_valid <= 1'b1;
                decode_cmd0_write <= 1'b1;
                decode_cmd0_addr <= draw_cmd_addr;
                decode_cmd0_wdata <= MakeCellData(2'b00, SpriteIndLeft);
                decode_cmd1_valid <= 1'b1;
                decode_cmd1_write <= 1'b1;
                decode_cmd1_addr <= second_cell_addr;
                decode_cmd1_wdata <= MakeCellData(2'b00, SpriteIndRight);
              end
            end

            ModeDrawCapacitor: begin
              if (dual_cell_fits && press_action) begin
                decode_issue_pending <= 1'b1;
                decode_cmd0_valid <= 1'b1;
                decode_cmd0_write <= 1'b1;
                decode_cmd0_addr <= draw_cmd_addr;
                decode_cmd0_wdata <= MakeCellData(2'b00, SpriteCapLeft);
                decode_cmd1_valid <= 1'b1;
                decode_cmd1_write <= 1'b1;
                decode_cmd1_addr <= second_cell_addr;
                decode_cmd1_wdata <= MakeCellData(2'b00, SpriteCapRight);
              end
            end

            ModeDrawGround: begin
              if (draw_target_cell_valid && single_action) begin
                decode_issue_pending <= 1'b1;
                decode_cmd0_valid <= 1'b1;
                decode_cmd0_write <= 1'b1;
                decode_cmd0_addr <= draw_cmd_addr;
                decode_cmd0_wdata <= MakeCellData(2'b00, SpriteGround);
              end
            end

            ModeClearCell: begin
              if (draw_target_cell_valid && single_action) begin
                decode_issue_pending <= 1'b1;
                decode_cmd0_valid <= 1'b1;
                decode_cmd0_write <= 1'b0;
                decode_cmd0_addr <= draw_cmd_addr;
                decode_cmd0_wdata <= {DataWidth{1'b0}};
                decode_rotate_addr <= draw_cmd_addr;
                decode_rotate_cell_i <= draw_target_cell_i;
                decode_rotate_cell_j <= draw_target_cell_j;
                decode_readback_is_clear <= 1'b1;
              end
            end

            ModeRotateCell: begin
              if ((rotate_frame_holdoff == 0) && draw_target_cell_valid && single_action) begin
                decode_issue_pending <= 1'b1;
                decode_cmd0_valid <= 1'b1;
                decode_cmd0_write <= 1'b0;
                decode_cmd0_addr <= draw_cmd_addr;
                decode_cmd0_wdata <= {DataWidth{1'b0}};
                decode_rotate_addr <= draw_cmd_addr;
                decode_rotate_cell_i <= draw_target_cell_i;
                decode_rotate_cell_j <= draw_target_cell_j;
              end
            end

            default: begin
            end
          endcase
        end

        if (cmd0_valid && bg_cmd_ready) begin
          if (!cmd0_write) begin
            if (readback_is_clear) begin
              clear_rsp_pending <= 1'b1;
            end else begin
              rotate_rsp_pending <= 1'b1;
            end
            readback_is_clear <= 1'b0;
          end

          if (cmd1_valid) begin
            cmd0_valid <= 1'b1;
            cmd0_write <= cmd1_write;
            cmd0_addr <= cmd1_addr;
            cmd0_wdata <= cmd1_wdata;
            if (cmd2_valid) begin
              cmd1_valid <= 1'b1;
              cmd1_write <= cmd2_write;
              cmd1_addr <= cmd2_addr;
              cmd1_wdata <= cmd2_wdata;
              cmd2_valid <= 1'b0;
            end else begin
              cmd1_valid <= 1'b0;
            end
          end else begin
            cmd0_valid <= 1'b0;
          end
        end

        if (decode_issue_pending) begin
          decode_issue_pending <= 1'b0;
          cmd0_valid <= decode_cmd0_valid;
          cmd0_write <= decode_cmd0_write;
          cmd0_addr <= decode_cmd0_addr;
          cmd0_wdata <= decode_cmd0_wdata;
          cmd1_valid <= decode_cmd1_valid;
          cmd1_write <= decode_cmd1_write;
          cmd1_addr <= decode_cmd1_addr;
          cmd1_wdata <= decode_cmd1_wdata;
          cmd2_valid <= decode_cmd2_valid;
          cmd2_write <= decode_cmd2_write;
          cmd2_addr <= decode_cmd2_addr;
          cmd2_wdata <= decode_cmd2_wdata;
          readback_is_clear <= decode_readback_is_clear;
          rotate_addr <= decode_rotate_addr;
          rotate_cell_i <= decode_rotate_cell_i;
          rotate_cell_j <= decode_rotate_cell_j;
        end else if (cmd_issue_pending) begin
          cmd_issue_pending <= 1'b0;
          cmd0_valid <= issue_cmd0_valid;
          cmd0_write <= issue_cmd0_write;
          cmd0_addr <= issue_cmd0_addr;
          cmd0_wdata <= issue_cmd0_wdata;
          cmd1_valid <= issue_cmd1_valid;
          cmd1_write <= issue_cmd1_write;
          cmd1_addr <= issue_cmd1_addr;
          cmd1_wdata <= issue_cmd1_wdata;
          cmd2_valid <= issue_cmd2_valid;
          cmd2_write <= issue_cmd2_write;
          cmd2_addr <= issue_cmd2_addr;
          cmd2_wdata <= issue_cmd2_wdata;
        end else if (clear_apply_pending) begin
          clear_apply_pending <= 1'b0;
          cmd_issue_pending <= 1'b1;
          issue_cmd0_valid <= 1'b1;
          issue_cmd0_write <= 1'b1;
          issue_cmd1_valid <= 1'b0;
          issue_cmd1_write <= 1'b1;
          issue_cmd1_addr <= 0;
          issue_cmd1_wdata <= 0;
          issue_cmd2_valid <= 1'b0;
          issue_cmd2_write <= 1'b1;
          issue_cmd2_addr <= 0;
          issue_cmd2_wdata <= 0;
          if (decoded_is_two_cell && decoded_origin_cell_valid && decoded_partner_cell_valid) begin
            issue_cmd0_addr <= decoded_origin_cell_addr;
            issue_cmd0_wdata <= {DataWidth{1'b0}};
            issue_cmd1_valid <= 1'b1;
            issue_cmd1_addr <= decoded_partner_cell_addr;
            issue_cmd1_wdata <= {DataWidth{1'b0}};
          end else begin
            issue_cmd0_addr <= rotate_addr;
            issue_cmd0_wdata <= {DataWidth{1'b0}};
          end
        end else if (rotate_apply_pending) begin
          rotate_apply_pending <= 1'b0;
          cmd_issue_pending <= 1'b1;
          issue_cmd0_valid <= 1'b0;
          issue_cmd0_write <= 1'b1;
          issue_cmd0_addr <= 0;
          issue_cmd0_wdata <= 0;
          issue_cmd1_valid <= 1'b0;
          issue_cmd1_write <= 1'b1;
          issue_cmd1_addr <= 0;
          issue_cmd1_wdata <= 0;
          issue_cmd2_valid <= 1'b0;
          issue_cmd2_write <= 1'b1;
          issue_cmd2_addr <= 0;
          issue_cmd2_wdata <= 0;
          if (decoded_is_two_cell && decoded_origin_cell_valid &&
              decoded_partner_cell_valid && decoded_next_partner_cell_valid) begin
            issue_cmd0_valid <= 1'b1;
            issue_cmd0_addr <= decoded_origin_cell_addr;
            issue_cmd0_wdata <= MakeCellData(decoded_next_rotation_value, decoded_primary_sprite_type);
            issue_cmd1_valid <= 1'b1;
            issue_cmd1_addr <= decoded_next_partner_cell_addr;
            issue_cmd1_wdata <= MakeCellData(decoded_next_rotation_value, decoded_secondary_sprite_type);
            if (decoded_partner_cell_addr != decoded_next_partner_cell_addr) begin
              issue_cmd2_valid <= 1'b1;
              issue_cmd2_addr <= decoded_partner_cell_addr;
              issue_cmd2_wdata <= {DataWidth{1'b0}};
            end
          end else if (!decoded_is_two_cell) begin
            issue_cmd0_valid <= 1'b1;
            issue_cmd0_addr <= rotate_addr;
            issue_cmd0_wdata <= decoded_rotated_cell_data;
          end
        end else if (clear_decode_pending) begin
          clear_decode_pending <= 1'b0;
          clear_apply_pending <= 1'b1;
          decoded_is_two_cell <= clicked_is_two_cell;
          decoded_origin_cell_valid <= origin_cell_valid;
          decoded_partner_cell_valid <= partner_cell_valid;
          decoded_next_partner_cell_valid <= next_partner_cell_valid;
          decoded_origin_cell_addr <= origin_cell_addr;
          decoded_partner_cell_addr <= partner_cell_addr;
          decoded_next_partner_cell_addr <= next_partner_cell_addr;
          decoded_primary_sprite_type <= primary_sprite_type;
          decoded_secondary_sprite_type <= secondary_sprite_type;
          decoded_next_rotation_value <= next_rotation_value;
          decoded_rotated_cell_data <= RotateCellData(rsp_data_hold);
        end else if (rotate_decode_pending) begin
          rotate_decode_pending <= 1'b0;
          rotate_apply_pending <= 1'b1;
          decoded_is_two_cell <= clicked_is_two_cell;
          decoded_origin_cell_valid <= origin_cell_valid;
          decoded_partner_cell_valid <= partner_cell_valid;
          decoded_next_partner_cell_valid <= next_partner_cell_valid;
          decoded_origin_cell_addr <= origin_cell_addr;
          decoded_partner_cell_addr <= partner_cell_addr;
          decoded_next_partner_cell_addr <= next_partner_cell_addr;
          decoded_primary_sprite_type <= primary_sprite_type;
          decoded_secondary_sprite_type <= secondary_sprite_type;
          decoded_next_rotation_value <= next_rotation_value;
          decoded_rotated_cell_data <= RotateCellData(rsp_data_hold);
        end else if (clear_rsp_pending && bg_rsp_valid) begin
          clear_rsp_pending <= 1'b0;
          clear_decode_pending <= 1'b1;
          rsp_data_hold <= bg_rsp_rdata;
        end else if (rotate_rsp_pending && bg_rsp_valid) begin
          rotate_rsp_pending <= 1'b0;
          rotate_decode_pending <= 1'b1;
          rsp_data_hold <= bg_rsp_rdata;
        end
      end
    end
  end

endmodule
