`timescale 1ns / 1ps

package StampingCombPkg;
  function automatic logic [31:0] neg_comb(input logic [31:0] v);
    begin
      neg_comb = {~v[31], v[30:0]};
    end
  endfunction

  function automatic logic [31:0] abs_comb(input logic [31:0] v);
    begin
      abs_comb = {1'b0, v[30:0]};
    end
  endfunction

  function automatic logic gt_comb(
      input logic [31:0] a_bits,
      input logic [31:0] b_bits
  );
    logic a_is_nan;
    logic b_is_nan;
    logic [30:0] a_mag;
    logic [30:0] b_mag;
    begin
      a_is_nan = (&a_bits[30:23]) && (a_bits[22:0] != 23'd0);
      b_is_nan = (&b_bits[30:23]) && (b_bits[22:0] != 23'd0);
      a_mag = a_bits[30:0];
      b_mag = b_bits[30:0];

      if (a_is_nan || b_is_nan) begin
        gt_comb = 1'b0;
      end else if (a_bits == b_bits) begin
        gt_comb = 1'b0;
      end else if (a_bits[31] != b_bits[31]) begin
        gt_comb = ~a_bits[31];
      end else if (a_bits[31] == 1'b0) begin
        gt_comb = (a_mag > b_mag);
      end else begin
        gt_comb = (a_mag < b_mag);
      end
    end
  endfunction
endpackage
