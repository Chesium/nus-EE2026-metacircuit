`timescale 1ns / 1ps

module CanonicalStampingNetlistStore #(
    parameter integer ELEM_COUNT = 64
) (
    input  wire [39:0] comp_word,
    output wire [7:0]  elem_kind,
    output wire [15:0] elem_n0,
    output wire [15:0] elem_n1,
    output wire [15:0] elem_n2,
    output wire [15:0] elem_n3,
    output wire [15:0] elem_aux,
    output wire [31:0] elem_val0,
    output wire [31:0] elem_val1,
    output wire [31:0] elem_val2
);

  import ComponentStorePkg::*;

  assign elem_kind = component_valid(comp_word) ? component_type(comp_word) : 8'd0;
  assign elem_n0 = {{13{1'b0}}, component_node0(comp_word)};
  assign elem_n1 = {{13{1'b0}}, component_node1(comp_word)};
  assign elem_n2 = 16'hFFFF;
  assign elem_n3 = 16'hFFFF;
  assign elem_aux = 16'hFFFF;
  assign elem_val0 = {19'd0, component_value(comp_word)};
  assign elem_val1 = 32'd0;
  assign elem_val2 = 32'd0;

endmodule
