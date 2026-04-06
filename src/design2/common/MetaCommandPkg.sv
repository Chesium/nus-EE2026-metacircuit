`timescale 1ns / 1ps

package MetaCommandPkg;

  parameter int COMMAND_WIDTH = 64;
  parameter int COMMAND_KIND_WIDTH = 4;

  typedef enum logic [COMMAND_KIND_WIDTH-1:0] {
    CMD_NONE              = 4'd0,
    CMD_CELL_WRITE        = 4'd1,
    CMD_CELL_CLEAR        = 4'd2,
    CMD_COMPONENT_CREATE  = 4'd3,
    CMD_COMPONENT_UPDATE  = 4'd4,
    CMD_COMPONENT_DELETE  = 4'd5,
    CMD_ROTATE_TARGET     = 4'd6,
    CMD_DELETE_TARGET     = 4'd7,
    CMD_SELECT_TARGET     = 4'd8,
    CMD_PAN               = 4'd9,
    CMD_COMPONENT_ROTATE  = 4'd10
  } command_kind_t;

  function automatic logic [COMMAND_WIDTH-1:0] pack_command(
      input logic [3:0] kind,
      input logic [5:0] comp_idx,
      input logic [4:0] cell_x,
      input logic [4:0] cell_y,
      input logic [5:0] sprite,
      input logic [1:0] rot,
      input logic [3:0] comp_type,
      input logic [12:0] value,
      input logic meta,
      input logic signed [7:0] pan_dx,
      input logic signed [7:0] pan_dy
  );
    pack_command = {
      kind,
      comp_idx,
      cell_x,
      cell_y,
      sprite,
      rot,
      comp_type,
      value,
      meta,
      pan_dx,
      pan_dy,
      2'b00
    };
  endfunction

  function automatic logic [3:0] command_kind(input logic [COMMAND_WIDTH-1:0] cmd);
    command_kind = cmd[63:60];
  endfunction

  function automatic logic [5:0] command_comp_idx(input logic [COMMAND_WIDTH-1:0] cmd);
    command_comp_idx = cmd[59:54];
  endfunction

  function automatic logic [4:0] command_cell_x(input logic [COMMAND_WIDTH-1:0] cmd);
    command_cell_x = cmd[53:49];
  endfunction

  function automatic logic [4:0] command_cell_y(input logic [COMMAND_WIDTH-1:0] cmd);
    command_cell_y = cmd[48:44];
  endfunction

  function automatic logic [5:0] command_sprite(input logic [COMMAND_WIDTH-1:0] cmd);
    command_sprite = cmd[43:38];
  endfunction

  function automatic logic [1:0] command_rot(input logic [COMMAND_WIDTH-1:0] cmd);
    command_rot = cmd[37:36];
  endfunction

  function automatic logic [3:0] command_comp_type(input logic [COMMAND_WIDTH-1:0] cmd);
    command_comp_type = cmd[35:32];
  endfunction

  function automatic logic [12:0] command_value(input logic [COMMAND_WIDTH-1:0] cmd);
    command_value = cmd[31:19];
  endfunction

  function automatic logic command_meta(input logic [COMMAND_WIDTH-1:0] cmd);
    command_meta = cmd[18];
  endfunction

  function automatic logic signed [7:0] command_pan_dx(input logic [COMMAND_WIDTH-1:0] cmd);
    command_pan_dx = cmd[17:10];
  endfunction

  function automatic logic signed [7:0] command_pan_dy(input logic [COMMAND_WIDTH-1:0] cmd);
    command_pan_dy = cmd[9:2];
  endfunction

endpackage
