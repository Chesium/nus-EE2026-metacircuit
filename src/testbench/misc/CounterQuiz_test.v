`timescale 1ns / 1ps

module divider1 (
    input  clk_in,
    output clk_out
);

  reg [31:0] count = 0;

  always @(posedge clk_in) begin
    count = count + 1;
  end

  assign clk_out = count[1];

endmodule

module divider2 (
    input  clk_in,
    output clk_out
);

  reg [3:0] count = 0;

  always @(posedge clk_in) begin
    count = count + 1;
  end

  assign clk_out = count[3];

endmodule

module divider3 (
    input clk_in,
    output reg clk_out = 0
);

  reg count = 0;

  always @(posedge clk_in) begin
    count   <= count + 1;
    clk_out <= (count == 0) ? ~clk_out : clk_out;
  end

endmodule



module divider4 (
    input clk_in,
    output reg clk_out = 0
);

  reg [1:0] count = 0;

  always @(posedge clk_in) begin
    if (count == 2'd3) begin
      count   <= 0;
      clk_out <= ~clk_out;
    end else begin
      count <= count + 1;
    end
  end

endmodule

module CounterQuiz_test ();

  reg clk = 0;
  wire clk1, clk2, clk3, clk4;
  always #5 clk = ~clk;  // 10ns => 100MHz

  divider1 d1 (
      clk,
      clk1
  );
  divider2 d2 (
      clk,
      clk2
  );
  divider3 d3 (
      clk,
      clk3
  );
  divider4 d4 (
      clk,
      clk4
  );

endmodule
