`timescale 1ns / 1ps

module StampingCombPkg_test;
  import StampingCombPkg::*;

  task automatic expect_real_close(
      input string name,
      input logic [31:0] got_bits,
      input real expected
  );
    real got_value;
    real abs_err;
    begin
      got_value = fp_to_real(got_bits);
      abs_err = (got_value > expected) ? (got_value - expected) : (expected - got_value);
      if (abs_err > 1e-6) begin
        $fatal(1, "%s mismatch: got=%e expected=%e", name, got_value, expected);
      end
    end
  endtask

  logic [31:0] a_bits;
  logic [31:0] b_bits;
  logic [31:0] c_bits;
  logic [31:0] got_bits;
  logic gate_value;

  initial begin
    a_bits = $shortrealtobits(1.5);
    got_bits = neg_comb(a_bits);
    expect_real_close("neg_comb", got_bits, -1.5);

    a_bits = $shortrealtobits(1.25);
    b_bits = $shortrealtobits(2.5);
    got_bits = fp_add_comb(a_bits, b_bits);
    expect_real_close("fp_add_comb positive", got_bits, 3.75);

    a_bits = $shortrealtobits(-0.5);
    b_bits = $shortrealtobits(2.0);
    got_bits = fp_add_comb(a_bits, b_bits);
    expect_real_close("fp_add_comb mixed sign", got_bits, 1.5);

    a_bits = $shortrealtobits(0.25);
    got_bits = sin_comb(a_bits);
    expect_real_close("sin_comb", got_bits, $sin(0.25));

    a_bits = $shortrealtobits(0.10);
    b_bits = $shortrealtobits(1.00);
    c_bits = $shortrealtobits(0.50);
    gate_value = pwm_gate_comb(a_bits, b_bits, c_bits);
    if (gate_value !== 1'b1) begin
      $fatal(1, "pwm_gate_comb expected ON for time=0.10");
    end

    a_bits = $shortrealtobits(0.75);
    gate_value = pwm_gate_comb(a_bits, b_bits, c_bits);
    if (gate_value !== 1'b0) begin
      $fatal(1, "pwm_gate_comb expected OFF for time=0.75");
    end

    $display("StampingCombPkg_test passed.");
    $finish;
  end
endmodule
