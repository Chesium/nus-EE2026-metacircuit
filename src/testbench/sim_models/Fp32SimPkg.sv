`timescale 1ns / 1ps

// binary32 <-> real conversion for benches and simulation models.
// shortreal is not converted by Verilator (it is promoted to real, and
// $bitstoshortreal / $shortrealtobits keep double bits), so the conversion is
// done explicitly, with round-to-nearest-even. Plain SystemVerilog, so the
// same benches still work under other simulators.
package Fp32SimPkg;
  function automatic real fp32_to_real(input logic [31:0] b);
    real r;
    begin
      if (b[30:23] == 8'hFF) begin
        fp32_to_real = $bitstoreal({b[31], 11'h7FF, b[22:0], 29'd0});
      end else if (b[30:23] == 8'd0) begin
        // zero or subnormal: m * 2^-149
        r = b[22:0];
        r = r * $bitstoreal({1'b0, 11'd874, 52'd0});
        fp32_to_real = b[31] ? -r : r;
      end else begin
        fp32_to_real = $bitstoreal({b[31], 11'({3'd0, b[30:23]} + 11'd896), b[22:0], 29'd0});
      end
    end
  endfunction

  function automatic logic [31:0] real_to_fp32(input real value);
    logic [63:0] d;
    logic [52:0] mant;
    logic [52:0] q;
    logic [52:0] rem;
    logic [52:0] half;
    integer e;
    integer shift;
    longint val;
    begin
      d = $realtobits(value);
      if (d[62:52] == 11'h7FF) begin
        real_to_fp32 = {d[63], 8'hFF, (d[51:0] != 52'd0) ? 23'h400000 : 23'd0};
      end else if (d[62:52] == 11'd0) begin
        real_to_fp32 = {d[63], 31'd0};
      end else begin
        e = int'(d[62:52]) - 1023 + 127;
        mant = {1'b1, d[51:0]};
        shift = (e >= 1) ? 29 : 29 + 1 - e;
        if (shift > 54) begin
          real_to_fp32 = {d[63], 31'd0};
        end else begin
          q = mant >> shift;
          rem = mant & ((53'd1 << shift) - 53'd1);
          half = 53'd1 << (shift - 1);
          if (rem > half || (rem == half && q[0])) q = q + 53'd1;
          val = (e >= 1) ? (longint'(e - 1) << 23) + longint'(q) : longint'(q);
          if (val >= (longint'(255) << 23)) real_to_fp32 = {d[63], 8'hFF, 23'd0};
          else real_to_fp32 = {d[63], val[30:0]};
        end
      end
    end
  endfunction
endpackage
