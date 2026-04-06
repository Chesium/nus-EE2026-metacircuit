`timescale 1ns / 1ps

package CellStorePkg;

  parameter int SCREEN_WIDTH = 640;
  parameter int SCREEN_HEIGHT = 480;
  parameter int CELL_SIZE = 32;
  parameter int GRID_WIDTH = 32;
  parameter int GRID_HEIGHT = 32;
  parameter int CELL_COUNT = GRID_WIDTH * GRID_HEIGHT;
  parameter int CELL_ADDR_WIDTH = $clog2(CELL_COUNT);
  parameter int CELL_WORD_WIDTH = 16;
  parameter int COMP_IDX_WIDTH = 6;

  localparam logic [COMP_IDX_WIDTH-1:0] NON_COMPONENT_IDX = {COMP_IDX_WIDTH{1'b1}};

  typedef enum logic [5:0] {
    SPRITE_WIRE       = 6'd0,
    SPRITE_ELBOW      = 6'd1,
    SPRITE_TEE        = 6'd2,
    SPRITE_JUNCTION   = 6'd3,
    SPRITE_CROSS      = 6'd4,
    SPRITE_RES_LEFT   = 6'd5,
    SPRITE_RES_RIGHT  = 6'd6,
    SPRITE_VOLT_LEFT  = 6'd7,
    SPRITE_VOLT_RIGHT = 6'd8,
    SPRITE_CURR_LEFT  = 6'd9,
    SPRITE_CURR_RIGHT = 6'd10,
    SPRITE_IND_LEFT   = 6'd11,
    SPRITE_IND_RIGHT  = 6'd12,
    SPRITE_CAP_LEFT   = 6'd13,
    SPRITE_CAP_RIGHT  = 6'd14,
    SPRITE_GROUND     = 6'd15
  } sprite_t;

  function automatic logic [CELL_WORD_WIDTH-1:0] pack_cell(
      input logic valid,
      input logic [5:0] sprite,
      input logic [1:0] rot,
      input logic [COMP_IDX_WIDTH-1:0] comp_idx,
      input logic meta
  );
    pack_cell = {meta, comp_idx, rot, sprite, valid};
  endfunction

  function automatic logic [CELL_WORD_WIDTH-1:0] empty_cell();
    empty_cell = pack_cell(1'b0, SPRITE_WIRE, 2'b00, NON_COMPONENT_IDX, 1'b0);
  endfunction

  function automatic logic cell_valid(input logic [CELL_WORD_WIDTH-1:0] cellx);
    cell_valid = cellx[0];
  endfunction

  function automatic logic [5:0] cell_sprite(input logic [CELL_WORD_WIDTH-1:0] cellx);
    cell_sprite = cellx[6:1];
  endfunction

  function automatic logic [1:0] cell_rot(input logic [CELL_WORD_WIDTH-1:0] cellx);
    cell_rot = cellx[8:7];
  endfunction

  function automatic logic [COMP_IDX_WIDTH-1:0] cell_comp_idx(input logic [CELL_WORD_WIDTH-1:0] cellx);
    cell_comp_idx = cellx[14:9];
  endfunction

  function automatic logic cell_meta(input logic [CELL_WORD_WIDTH-1:0] cellx);
    cell_meta = cellx[15];
  endfunction

  function automatic logic is_component_cell(input logic [CELL_WORD_WIDTH-1:0] cellx);
    is_component_cell = cell_valid(cellx) && (cell_comp_idx(cellx) != NON_COMPONENT_IDX);
  endfunction

  function automatic logic [CELL_ADDR_WIDTH-1:0] flatten_addr(
      input logic [4:0] x,
      input logic [4:0] y
  );
    flatten_addr = (y * GRID_WIDTH) + x;
  endfunction

  function automatic logic [3:0] cell_ports(
      input logic [5:0] sprite,
      input logic [1:0] rot
  );
    case (sprite)
      SPRITE_WIRE: begin
        case (rot[0])
          1'b0: cell_ports = 4'b1010; // down + up
          1'b1: cell_ports = 4'b0101; // right + left
        endcase
      end
      SPRITE_ELBOW: begin
        case (rot)
          2'd0: cell_ports = 4'b0011; // up + left
          2'd1: cell_ports = 4'b0110; // up + right
          2'd2: cell_ports = 4'b1100; // right + down
          default: cell_ports = 4'b1001; // down + left
        endcase
      end
      SPRITE_TEE: begin
        case (rot)
          2'd0: cell_ports = 4'b0111; // up + left + right
          2'd1: cell_ports = 4'b1110; // up + right + down
          2'd2: cell_ports = 4'b1101; // right + down + left
          default: cell_ports = 4'b1011; // up + down + left
        endcase
      end
      SPRITE_JUNCTION,
      SPRITE_CROSS: cell_ports = 4'b1111;
      SPRITE_GROUND: begin
        case (rot)
          2'd0: cell_ports = 4'b0010; // up
          2'd1: cell_ports = 4'b0100; // right
          2'd2: cell_ports = 4'b1000; // down
          default: cell_ports = 4'b0001; // left
        endcase
      end
      default: cell_ports = 4'b0000;
    endcase
  endfunction

endpackage
