`timescale 1ns / 1ps

module FloodingCombPkg_test;
  import FloodingCombPkg::*;

  initial begin
    if (!decode_iswire_comb(4'b1000)) $fatal(1, "decode_iswire_comb failed for wire cell");
    if (decode_iswire_comb(4'b0000)) $fatal(1, "decode_iswire_comb failed for empty cell");

    if (!getport_comb(4'b1000, 32'd0)) $fatal(1, "getport_comb failed at index 0");
    if (!getport_comb(4'b0100, 32'd1)) $fatal(1, "getport_comb failed at index 1");
    if (!getport_comb(4'b0010, 32'd2)) $fatal(1, "getport_comb failed at index 2");
    if (!getport_comb(4'b0001, 32'd3)) $fatal(1, "getport_comb failed at index 3");

    if (get_opp_dir_comb(2'd0) != 2'd2) $fatal(1, "get_opp_dir_comb failed for dir 0");
    if (get_opp_dir_comb(2'd3) != 2'd1) $fatal(1, "get_opp_dir_comb failed for dir 3");

    if (get_nxt_i_comb(8'd5, 2'd1) != 8'd6) $fatal(1, "get_nxt_i_comb failed for +x");
    if (get_nxt_i_comb(8'd5, 2'd3) != 8'd4) $fatal(1, "get_nxt_i_comb failed for -x");
    if (get_nxt_j_comb(8'd5, 2'd0) != 8'd6) $fatal(1, "get_nxt_j_comb failed for +y");
    if (get_nxt_j_comb(8'd5, 2'd2) != 8'd4) $fatal(1, "get_nxt_j_comb failed for -y");

    if (decode_i_comb(pack_queue_item_comb(8'd7, 8'd9, 2'd3)) != 8'd7) $fatal(1, "decode_i_comb failed");
    if (decode_j_comb(pack_queue_item_comb(8'd7, 8'd9, 2'd3)) != 8'd9) $fatal(1, "decode_j_comb failed");
    if (decode_d_comb(pack_queue_item_comb(8'd7, 8'd9, 2'd3)) != 2'd3) $fatal(1, "decode_d_comb failed");

    $display("FloodingCombPkg_test passed.");
    $finish;
  end
endmodule
