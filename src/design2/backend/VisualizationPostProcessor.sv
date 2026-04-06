`timescale 1ns / 1ps

module VisualizationPostProcessor (
    input  wire [15:0] cell_in,
    input  wire        solve_valid,
    output wire [15:0] cell_out
);

  import CellStorePkg::*;

  wire next_meta = solve_valid && cell_valid(cell_in);
  assign cell_out = pack_cell(
      cell_valid(cell_in),
      cell_sprite(cell_in),
      cell_rot(cell_in),
      cell_comp_idx(cell_in),
      next_meta
  );

endmodule
