`timescale 1ns / 1ps

module StampingCombPkg_test;
  import StampingCombPkg::*;

  logic [31:0] a_bits;
  logic [31:0] b_bits;
  logic gt_value;

  initial begin
    a_bits = $shortrealtobits(1.5);
    if (neg_comb(a_bits) !== $shortrealtobits(-1.5)) begin
      $fatal(1, "neg_comb mismatch");
    end

    a_bits = $shortrealtobits(-2.25);
    if (abs_comb(a_bits) !== $shortrealtobits(2.25)) begin
      $fatal(1, "abs_comb mismatch");
    end

    a_bits = $shortrealtobits(3.0);
    b_bits = $shortrealtobits(2.0);
    gt_value = gt_comb(a_bits, b_bits);
    if (gt_value !== 1'b1) begin
      $fatal(1, "gt_comb positive compare mismatch");
    end

    a_bits = $shortrealtobits(-4.0);
    b_bits = $shortrealtobits(-2.0);
    gt_value = gt_comb(a_bits, b_bits);
    if (gt_value !== 1'b0) begin
      $fatal(1, "gt_comb negative compare mismatch");
    end

    a_bits = 32'h7FC0_0000;
    b_bits = $shortrealtobits(1.0);
    gt_value = gt_comb(a_bits, b_bits);
    if (gt_value !== 1'b0) begin
      $fatal(1, "gt_comb NaN compare mismatch");
    end

    $display("StampingCombPkg_test passed.");
    $finish;
  end
endmodule
