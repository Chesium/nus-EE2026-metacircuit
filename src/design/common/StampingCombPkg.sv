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
    shortreal a_val;
    shortreal b_val;
    begin
      a_val = $bitstoshortreal(a_bits);
      b_val = $bitstoshortreal(b_bits);
      gt_comb = (a_val > b_val);
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
