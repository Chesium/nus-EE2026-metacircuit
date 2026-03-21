module CellVisStore (
  input clk,

  output wire vis_cell_enable,
  output wire vis_cell_sprite_id,
  output wire vis_cell_rotation,
  // output wire vis_cell_component_id,
  output wire vis_cell_selected,

  input wire buf_i_cell_enable,
  input wire buf_i_cell_sprite_id,
  input wire buf_i_cell_rotation,
  input wire buf_i_cell_component_id,
  input wire buf_i_cell_selected,

  output wire buf_o_cell_enable,
  output wire buf_o_cell_sprite_id,
  output wire buf_o_cell_rotation,
  output wire buf_o_cell_component_id,
  output wire buf_o_cell_selected
);
  
endmodule
