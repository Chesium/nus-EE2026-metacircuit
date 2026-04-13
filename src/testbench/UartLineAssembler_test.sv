`timescale 1ns / 1ps

module UartLineAssembler_test;
  localparam integer MAX_LINE_BYTES = 16;

  reg clk = 1'b0;
  reg rst_n = 1'b0;
  reg byte_valid = 1'b0;
  reg [7:0] byte_data = 8'h00;
  wire line_valid;
  wire line_overflow;
  wire [7:0] line_len;
  wire [MAX_LINE_BYTES*8-1:0] line_data;

  always #5 clk = ~clk;

  UartLineAssembler #(
      .MAX_LINE_BYTES(MAX_LINE_BYTES)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .byte_valid(byte_valid),
      .byte_data(byte_data),
      .line_valid(line_valid),
      .line_overflow(line_overflow),
      .line_len(line_len),
      .line_data(line_data)
  );

  task automatic push_byte(input [7:0] b);
    begin
      @(posedge clk);
      byte_valid <= 1'b1;
      byte_data <= b;
      @(posedge clk);
      byte_valid <= 1'b0;
    end
  endtask

  initial begin
    repeat (4) @(posedge clk);
    rst_n = 1'b1;

    push_byte("@");
    push_byte("N");
    push_byte("B");
    push_byte(8'h0D);
    push_byte(8'h0A);
    wait (line_valid);
    if (line_len !== 8'd3 || line_overflow) begin
      $fatal(1, "UartLineAssembler_test unexpected first line result len=%0d overflow=%0d", line_len, line_overflow);
    end

    repeat (MAX_LINE_BYTES + 2) push_byte("A");
    push_byte(8'h0A);
    wait (line_valid);
    if (!line_overflow) begin
      $fatal(1, "UartLineAssembler_test expected overflow pulse");
    end

    $display("UartLineAssembler_test passed.");
    $finish;
  end
endmodule
