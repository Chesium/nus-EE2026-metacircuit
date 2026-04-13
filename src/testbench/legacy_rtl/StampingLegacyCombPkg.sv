`timescale 1ns / 1ps

package StampingLegacyCombPkg;
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

  function automatic logic [31:0] sin_comb(input logic [31:0] v_bits);
    shortreal v_val;
    shortreal out_val;
    begin
      v_val = $bitstoshortreal(v_bits);
      out_val = $sin(v_val);
      sin_comb = $shortrealtobits(out_val);
    end
  endfunction

  function automatic logic pwm_gate_comb(
      input logic [31:0] time_bits,
      input logic [31:0] period_bits,
      input logic [31:0] duty_bits
  );
    shortreal time_val;
    shortreal period_val;
    shortreal duty_val;
    shortreal phase_val;
    integer cycles;
    begin
      time_val = $bitstoshortreal(time_bits);
      period_val = $bitstoshortreal(period_bits);
      duty_val = $bitstoshortreal(duty_bits);

      if (period_val <= 0.0) begin
        pwm_gate_comb = 1'b0;
      end else if (duty_val <= 0.0) begin
        pwm_gate_comb = 1'b0;
      end else if (duty_val >= 1.0) begin
        pwm_gate_comb = 1'b1;
      end else begin
        cycles = $rtoi(time_val / period_val);
        phase_val = time_val - (period_val * cycles);
        pwm_gate_comb = (phase_val < (period_val * duty_val));
      end
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
