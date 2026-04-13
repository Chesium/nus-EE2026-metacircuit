`timescale 1ns / 1ps

module SolverBoard_top_test;
  localparam integer TEST_BAUD = 10_000_000;
  localparam integer CLKS_PER_BIT = 100_000_000 / TEST_BAUD;
  localparam integer MAX_WAIT_CYCLES = 8_000_000;

  reg clk = 1'b0;
  reg BTNC = 1'b1;
  reg RsRx = 1'b1;
  wire RsTx;
  wire [15:0] LED;
  wire [7:0] SEG;
  wire [3:0] AN;
  wire [7:0] tx_mon_byte;
  wire       tx_mon_valid;
  localparam integer WATCHDOG_CYCLES = 2_000_000;

  integer wait_cycles;
  reg [7:0] rx_byte;
  string rx_line;

  always #5 clk = ~clk;

  SolverBoard_top #(
      .UART_BAUD(TEST_BAUD)
  ) dut (
      .CLK100MHZ(clk),
      .BTNC(BTNC),
      .RsRx(RsRx),
      .RsTx(RsTx),
      .LED(LED),
      .SEG(SEG),
      .AN(AN)
  );

  UartRx #(
      .BAUD(TEST_BAUD)
  ) tx_monitor (
      .clk(clk),
      .rst_n(~BTNC),
      .rx(RsTx),
      .data(tx_mon_byte),
      .data_valid(tx_mon_valid)
  );

  task automatic send_uart_byte(input [7:0] tx_byte);
    integer bit_idx;
    begin
      RsRx = 1'b0;
      repeat (CLKS_PER_BIT) @(posedge clk);
      for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
        RsRx = tx_byte[bit_idx];
        repeat (CLKS_PER_BIT) @(posedge clk);
      end
      RsRx = 1'b1;
      repeat (CLKS_PER_BIT) @(posedge clk);
    end
  endtask

  task automatic send_uart_line(input string s);
    integer idx;
    begin
      for (idx = 0; idx < s.len(); idx = idx + 1) begin
        send_uart_byte(s[idx]);
      end
      send_uart_byte(8'h0D);
      send_uart_byte(8'h0A);
    end
  endtask

  task automatic recv_uart_byte(output [7:0] data_byte);
    begin
      wait_cycles = 0;
      while (!tx_mon_valid && wait_cycles < MAX_WAIT_CYCLES) begin
        @(posedge clk);
        wait_cycles = wait_cycles + 1;
      end
      if (!tx_mon_valid) begin
        $fatal(1, "SolverBoard_top_test timeout waiting for UART byte");
      end
      data_byte = tx_mon_byte;
      @(posedge clk);
    end
  endtask

  task automatic recv_uart_line(output string line);
    begin
      line = "";
      begin : recv_loop
        while (1) begin
          recv_uart_byte(rx_byte);
          if (rx_byte == 8'h0A) begin
            disable recv_loop;
          end
          if (rx_byte != 8'h0D) begin
            line = {line, rx_byte};
          end
        end
      end
    end
  endtask

  task automatic expect_line(input string expected);
    begin
      recv_uart_line(rx_line);
      if (rx_line != expected) begin
        $fatal(1, "SolverBoard_top_test expected '%s' got '%s'", expected, rx_line);
      end
    end
  endtask

  initial begin
    repeat (20) @(posedge clk);
    BTNC = 1'b0;

    send_uart_line("@NB,0001,03,02*20");
    send_uart_line("@NC,0001,00,03,00,FF,500,00*16");
    send_uart_line("@NC,0001,01,01,00,01,003,00*12");
    send_uart_line("@NC,0001,02,01,01,FF,002,00*10");
    send_uart_line("@NE,0001,03,02*27");

    expect_line("@VB,0001,02,00*3B");
    expect_line("@VN,0001,00,43FA0000*35");
    expect_line("@VN,0001,01,43480000*3F");
    expect_line("@VE,0001,02,00*3C");

    $display("SolverBoard_top_test passed.");
    $finish;
  end

  initial begin
    repeat (WATCHDOG_CYCLES) @(posedge clk);
    $display("SolverBoard_top_test watchdog fired");
    $display("top state=%0d status=%02h frame=%04h elem=%0d node=%0d tx_busy=%0b solver_busy=%0b solver_done=%0b",
             dut.state, dut.current_status, dut.current_frame, dut.current_elem_count, dut.current_node_count,
             dut.tx_busy, dut.solver_busy, dut.solver_done);
    $display("pipeline state=%0d clear_seen=%0b%0b%0b%0b%0b start=%0b done=%0b fp=%0b",
             dut.pipeline_inst.state,
             dut.pipeline_inst.a_clear_seen, dut.pipeline_inst.lu_clear_seen, dut.pipeline_inst.j_clear_seen,
             dut.pipeline_inst.y_clear_seen, dut.pipeline_inst.x_clear_seen,
             dut.pipeline_inst.solver_start, dut.pipeline_inst.done, dut.pipeline_inst.fp_exception);
    $fatal(1, "SolverBoard_top_test timed out");
  end
endmodule
