`timescale 1ns / 1ps

package StampingCombPkg;
  function automatic logic [31:0] neg_comb(input logic [31:0] v);
    begin
      neg_comb = {~v[31], v[30:0]};
    end
  endfunction

  function automatic logic [31:0] fp_add_comb(
      input logic [31:0] a_bits,
      input logic [31:0] b_bits
  );
    shortreal a_val;
    shortreal b_val;
    shortreal sum_val;
    begin
      a_val = $bitstoshortreal(a_bits);
      b_val = $bitstoshortreal(b_bits);
      sum_val = a_val + b_val;
      fp_add_comb = $shortrealtobits(sum_val);
    end
  endfunction

  function automatic real fp_to_real(input logic [31:0] bits);
    shortreal value_sr;
    begin
      value_sr = $bitstoshortreal(bits);
      fp_to_real = value_sr;
    end
  endfunction
endpackage
