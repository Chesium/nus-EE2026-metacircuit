`timescale 1ns / 1ps

module CanonicalCellPortAdapter (
    input  wire [15:0] cell_word,
    output wire        cell_valid_o,
    output wire        is_component_o,
    output wire [3:0]  port_mask_o
);

  import CellStorePkg::*;

  assign cell_valid_o = cell_valid(cell_word);
  assign is_component_o = is_component_cell(cell_word);
  assign port_mask_o = cell_ports(cell_sprite(cell_word), cell_rot(cell_word));

endmodule
