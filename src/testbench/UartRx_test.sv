`timescale 1ns / 1ps

module UartRx_test;
  localparam integer CLKS_PER_BIT = 100_000_000 / 115200;

  reg clk = 1'b0;
  reg rst_n = 1'b0;
  reg rx = 1'b1;
  wire [7:0] data;
  wire data_valid;

  always #5 clk = ~clk;

  UartRx dut (
      .clk(clk),
      .rst_n(rst_n),
      .rx(rx),
      .data(data),
      .data_valid(data_valid)
  );

  task automatic send_uart_byte(input [7:0] tx_byte);
    integer bit_idx;
    begin
      rx = 1'b0;
      repeat (CLKS_PER_BIT) @(posedge clk);
      for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
        rx = tx_byte[bit_idx];
        repeat (CLKS_PER_BIT) @(posedge clk);
      end
      rx = 1'b1;
      repeat (CLKS_PER_BIT) @(posedge clk);
    end
  endtask

  task automatic wait_for_capture_and_check(input [7:0] expected);
    begin
      repeat (CLKS_PER_BIT * 2) @(posedge clk);
      if (data !== expected) begin
        $fatal(1, "UartRx_test expected 0x%02h, got 0x%02h", expected, data);
      end
    end
  endtask

  initial begin
    repeat (10) @(posedge clk);
    rst_n = 1'b1;

    send_uart_byte(8'hA5);
    wait_for_capture_and_check(8'hA5);

    send_uart_byte(8'h3C);
    wait_for_capture_and_check(8'h3C);

    $display("UartRx_test passed.");
    $finish;
  end
endmodule
