`timescale 1ns / 1ps

package ComponentStorePkg;

  parameter int COMPONENT_COUNT = 64;
  parameter int COMPONENT_ADDR_WIDTH = $clog2(COMPONENT_COUNT);
  parameter int COMPONENT_WORD_WIDTH = 40;
  parameter int COMPONENT_VALUE_WIDTH = 13;
  parameter int COMPONENT_NODE_WIDTH = 3;
  parameter int COMPONENT_CELL_INDEX_WIDTH = 5;
  parameter int COMPONENT_FLAGS_WIDTH = 5;

  localparam logic [COMPONENT_NODE_WIDTH-1:0] NODE_NONE = {COMPONENT_NODE_WIDTH{1'b1}};

  typedef enum logic [3:0] {
    COMP_WIRE      = 4'd0,
    COMP_GROUND    = 4'd1,
    COMP_RESISTOR  = 4'd2,
    COMP_CAPACITOR = 4'd3,
    COMP_INDUCTOR  = 4'd4,
    COMP_VOLTAGE   = 4'd5,
    COMP_CURRENT   = 4'd6
  } component_type_t;

  function automatic logic [COMPONENT_WORD_WIDTH-1:0] pack_component(
      input logic [3:0] comp_type,
      input logic [COMPONENT_VALUE_WIDTH-1:0] value,
      input logic [COMPONENT_NODE_WIDTH-1:0] node0,
      input logic [COMPONENT_NODE_WIDTH-1:0] node1,
      input logic [COMPONENT_CELL_INDEX_WIDTH-1:0] anchor_x,
      input logic [COMPONENT_CELL_INDEX_WIDTH-1:0] anchor_y,
      input logic [1:0] rot,
      input logic [COMPONENT_FLAGS_WIDTH-1:0] flags
  );
    pack_component = {
      comp_type,
      value,
      node0,
      node1,
      anchor_x,
      anchor_y,
      rot,
      flags
    };
  endfunction

  function automatic logic [COMPONENT_WORD_WIDTH-1:0] empty_component();
    empty_component = pack_component(
        COMP_RESISTOR,
        '0,
        NODE_NONE,
        NODE_NONE,
        '0,
        '0,
        2'b00,
        '0
    );
  endfunction

  function automatic logic component_valid(input logic [COMPONENT_WORD_WIDTH-1:0] comp);
    component_valid = comp[0];
  endfunction

  function automatic logic [3:0] component_type(input logic [COMPONENT_WORD_WIDTH-1:0] comp);
    component_type = comp[39:36];
  endfunction

  function automatic logic [COMPONENT_VALUE_WIDTH-1:0] component_value(input logic [COMPONENT_WORD_WIDTH-1:0] comp);
    component_value = comp[35:23];
  endfunction

  function automatic logic [COMPONENT_NODE_WIDTH-1:0] component_node0(input logic [COMPONENT_WORD_WIDTH-1:0] comp);
    component_node0 = comp[22:20];
  endfunction

  function automatic logic [COMPONENT_NODE_WIDTH-1:0] component_node1(input logic [COMPONENT_WORD_WIDTH-1:0] comp);
    component_node1 = comp[19:17];
  endfunction

  function automatic logic [COMPONENT_CELL_INDEX_WIDTH-1:0] component_anchor_x(input logic [COMPONENT_WORD_WIDTH-1:0] comp);
    component_anchor_x = comp[16:12];
  endfunction

  function automatic logic [COMPONENT_CELL_INDEX_WIDTH-1:0] component_anchor_y(input logic [COMPONENT_WORD_WIDTH-1:0] comp);
    component_anchor_y = comp[11:7];
  endfunction

  function automatic logic [1:0] component_rot(input logic [COMPONENT_WORD_WIDTH-1:0] comp);
    component_rot = comp[6:5];
  endfunction

  function automatic logic [COMPONENT_FLAGS_WIDTH-1:0] component_flags(input logic [COMPONENT_WORD_WIDTH-1:0] comp);
    component_flags = comp[4:0];
  endfunction

  function automatic logic [COMPONENT_WORD_WIDTH-1:0] component_with_value(
      input logic [COMPONENT_WORD_WIDTH-1:0] comp,
      input logic [COMPONENT_VALUE_WIDTH-1:0] new_value
  );
    component_with_value = {
      component_type(comp),
      new_value,
      component_node0(comp),
      component_node1(comp),
      component_anchor_x(comp),
      component_anchor_y(comp),
      component_rot(comp),
      component_flags(comp)
    };
  endfunction

  function automatic logic [COMPONENT_WORD_WIDTH-1:0] component_with_rot(
      input logic [COMPONENT_WORD_WIDTH-1:0] comp,
      input logic [1:0] new_rot
  );
    component_with_rot = {
      component_type(comp),
      component_value(comp),
      component_node0(comp),
      component_node1(comp),
      component_anchor_x(comp),
      component_anchor_y(comp),
      new_rot,
      component_flags(comp)
    };
  endfunction

  function automatic logic [COMPONENT_WORD_WIDTH-1:0] component_with_nodes(
      input logic [COMPONENT_WORD_WIDTH-1:0] comp,
      input logic [COMPONENT_NODE_WIDTH-1:0] new_node0,
      input logic [COMPONENT_NODE_WIDTH-1:0] new_node1
  );
    component_with_nodes = {
      component_type(comp),
      component_value(comp),
      new_node0,
      new_node1,
      component_anchor_x(comp),
      component_anchor_y(comp),
      component_rot(comp),
      component_flags(comp)
    };
  endfunction

  function automatic logic [COMPONENT_WORD_WIDTH-1:0] component_invalidate(
      input logic [COMPONENT_WORD_WIDTH-1:0] comp
  );
    component_invalidate = {
      component_type(comp),
      component_value(comp),
      component_node0(comp),
      component_node1(comp),
      component_anchor_x(comp),
      component_anchor_y(comp),
      component_rot(comp),
      5'b00000
    };
  endfunction

endpackage
