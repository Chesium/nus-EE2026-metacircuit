`timescale 1ns / 1ps

module FP_wrapper_test ();

  reg aclk_100m = 0;
  always #5 aclk_100m = ~aclk_100m;  // 10ns => 100MHz

  reg         start_fma;
  reg         start_div;
  reg         start_tofixed;
  reg  [31:0] a;
  reg  [31:0] b;
  reg  [31:0] c;

  wire        busy_fma;
  wire        done_fma;
  wire [31:0] result_fma;
  wire        exc_underflow_fma;
  wire        exc_overflow_fma;
  wire        exc_invalid_fma;

  wire        busy_div;
  wire        done_div;
  wire [31:0] result_div;
  wire        exc_underflow_div;
  wire        exc_overflow_div;
  wire        exc_invalid_div;
  wire        exc_div0_div;

  wire        busy_tofixed;
  wire        done_tofixed;
  wire [31:0] result_tofixed;
  wire        exc_overflow_tofixed;
  wire        exc_invalid_tofixed;

  reg  [31:0] res;
  reg  [31:0] res_fixed;

  initial begin
    start_fma = 1'b0;  // no valid data placed yet
    start_div = 1'b0;  // no valid data placed yet
    start_tofixed = 1'b0;  // no valid data placed yet

    #10

    //A        hex : 42F4147B
    //B        hex : 3D7BFC65
    //C        hex : 3E72B021
    //Expected hex : 40F7D63B

    a = 32'h42F4147B;
    b = 32'h3D7BFC65;
    c = 32'h3E72B021;
    
    start_fma = 1;
    #10 start_fma = 0;
    while (!done_fma) #10;
    res = result_fma;

    start_div = 1;
    #10 start_div = 0;
    while (!done_div) #10;
    res = result_div;

    start_tofixed = 1;
    #10 start_tofixed = 0;
    while (!done_tofixed) #10;
    res_fixed = result_tofixed;

    #10 $finish;
  end

  fpo_fma fpo_fma_inst (
      .clk(aclk_100m),
      .start(start_fma),
      .a(a),
      .b(b),
      .c(c),
      .busy(busy_fma),
      .done(done_fma),
      .result(result_fma),
      .exc_underflow(exc_underflow_fma),
      .exc_overflow(exc_overflow_fma),
      .exc_invalid(exc_invalid_fma)
  );

  fpo_div fpo_div_inst (
      .clk(aclk_100m),
      .start(start_div),
      .a(a),
      .b(b),
      .busy(busy_div),
      .done(done_div),
      .result(result_div),
      .exc_underflow(exc_underflow_div),
      .exc_overflow(exc_overflow_div),
      .exc_invalid(exc_invalid_div),
      .exc_div0(exc_div0_div)
  );

  fpo_tofixed fpo_tofixed_inst (
      .clk(aclk_100m),
      .start(start_tofixed),
      .a(a),
      .busy(busy_tofixed),
      .done(done_tofixed),
      .result(result_tofixed),
      .exc_overflow(exc_overflow_tofixed),
      .exc_invalid(exc_invalid_tofixed)
  );

endmodule
