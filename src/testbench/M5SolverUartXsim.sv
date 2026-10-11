`timescale 1ns / 1ps

module M5SolverUartXsim;
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
  localparam integer WATCHDOG_CYCLES = 300_000_000;

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
      repeat (30) @(posedge clk);
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
        $fatal(1, "M5SolverUartXsim timeout waiting for UART byte");
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
      if ($test$plusargs("CORRUPT_SOLVER") && expected.substr(0,2)=="@VN") rx_line={rx_line,"X"};
      $display("SOLVER_REPLY %s",rx_line);
      if (rx_line != expected) begin
        $fatal(1, "M5SolverUartXsim mismatch expected '%s' got '%s'", expected, rx_line);
      end
    end
  endtask

  integer cycle=0,fissue=-1,dissue=-1,fresults=0,dresults=0,solvestart=-1;
  always @(posedge clk) begin
    cycle++;
    if(dut.pipeline_inst.fma_inst.s_axis_a_tvalid) fissue=cycle;
    if(dut.pipeline_inst.div_inst.s_axis_a_tvalid) dissue=cycle;
    if(dut.solver_start) solvestart=cycle;
    #1;
    if(dut.pipeline_inst.fma_inst.m_axis_result_tvalid) begin
      if(cycle-fissue+1!=16) $fatal(1,"pipeline FMA latency mismatch");
      fresults++;
    end
    if(dut.pipeline_inst.div_inst.m_axis_result_tvalid) begin
      if(cycle-dissue+1!=28) $fatal(1,"pipeline divide latency mismatch");
      dresults++;
    end
    if(dut.solver_done)
      $display("ACTUAL_SOLVE frame=%04x cycles=%0d fp_exception=%0d fma_results=%0d div_results=%0d",dut.current_frame,cycle-solvestart,dut.solver_fp_exception,fresults,dresults);
  end
  task automatic expect_nonfinite(input string prefix);
    logic [31:0] value; integer scanned,k; logic [7:0] checksum,received;
    begin
      recv_uart_line(rx_line);
      if(rx_line.substr(0,11)!=prefix) $fatal(1,"nonfinite UART prefix mismatch got=%s expected=%s",rx_line,prefix);
      scanned=$sscanf(rx_line.substr(12,19),"%h",value);
      if(scanned!=1 || (value & 32'h7f800000)!=32'h7f800000)
        $fatal(1,"singular nonfinite mismatch got=%s",rx_line);
      checksum=0;
      for(k=1;k<20;k++) checksum=checksum^rx_line[k];
      scanned=$sscanf(rx_line.substr(21,22),"%h",received);
      if(scanned!=1 || rx_line[20]!="*" || received!=checksum) $fatal(1,"singular checksum mismatch");
      $display("SOLVER_REPLY %s",rx_line);
    end
  endtask
  task automatic expect_voltage(input string prefix, input real expected);
    reg [31:0] bits; integer scanned,k,exponent; reg [7:0] checksum,received;
    real got,error,scale;
    begin
      recv_uart_line(rx_line);
      if ($test$plusargs("CORRUPT_SOLVER")) rx_line={rx_line,"X"};
      if(rx_line.len()!=23 || rx_line.substr(0,11)!=prefix)
        $fatal(1,"general voltage prefix mismatch expected %s got %s",prefix,rx_line);
      scanned=$sscanf(rx_line.substr(12,19),"%h",bits);
      if(scanned!=1 || bits[30:23]==255) $fatal(1,"general nonfinite voltage mismatch %s",rx_line);
      checksum=0;
      for(k=1;k<20;k++) checksum=checksum^rx_line[k];
      scanned=$sscanf(rx_line.substr(21,22),"%h",received);
      if(scanned!=1 || rx_line[20]!="*" || received!=checksum) $fatal(1,"general checksum mismatch");
      exponent=bits[30:23];
      if(exponent==0) got=$itor(bits[22:0])*2.0**(-149);
      else got=(1.0+$itor(bits[22:0])/8388608.0)*2.0**(exponent-127);
      if(bits[31]) got=-got;
      if($test$plusargs("CORRUPT_GENERAL")) got=got*1.001;
      error=got-expected; if(error<0) error=-error;
      scale=expected; if(scale<0) scale=-scale;
      if(!numeric_policy_accepts(got,expected)) begin
        // ACCURACY_PROBE measures the error of declared ill-conditioned cases instead of stopping.
        if($test$plusargs("ACCURACY_PROBE"))
          $display("ACCURACY_MISS %s expected=%.17e got=%.17e",prefix,expected,got);
        else
          $fatal(1,"general voltage mismatch expected %e got %e bound %e",expected,got,scale*0.0002+1.0e-30);
      end
      $display("SOLVER_REPLY %s rational=%e observed=%e",rx_line,expected,got);
    end
  endtask
  function automatic bit numeric_policy_accepts(input real got, expected);
    real error,scale;
    error=got-expected; if(error<0) error=-error;
    scale=expected; if(scale<0) scale=-scale;
    return error <= scale*0.0002+1.0e-30;
  endfunction
  initial begin
    if(!numeric_policy_accepts(1.00019,1.0) || numeric_policy_accepts(1.00021,1.0) ||
       !numeric_policy_accepts(0.99981,1.0) || numeric_policy_accepts(0.99979,1.0) ||
       !numeric_policy_accepts(0.5e-30,0.0) || numeric_policy_accepts(2.0e-30,0.0))
      $fatal(1,"numeric policy boundary mismatch");
    $display("NUMERIC_POLICY controls inside/outside tolerance passed relative=0.0002 absolute=1e-30");
    repeat (20) @(posedge clk);
    BTNC = 1'b0;

    `include "M5SolverUartFixtures.svh"
    $display("M5SolverUartXsim passed.");
    $finish;
  end

  initial begin
    repeat (WATCHDOG_CYCLES) @(posedge clk);
    $display("M5SolverUartXsim watchdog fired");
    $display("top state=%0d status=%02h frame=%04h elem=%0d node=%0d tx_busy=%0b solver_busy=%0b solver_done=%0b",
             dut.state, dut.current_status, dut.current_frame, dut.current_elem_count, dut.current_node_count,
             dut.tx_busy, dut.solver_busy, dut.solver_done);
    $display("pipeline state=%0d clear_seen=%0b%0b%0b%0b%0b start=%0b done=%0b fp=%0b",
             dut.pipeline_inst.state,
             dut.pipeline_inst.a_clear_seen, dut.pipeline_inst.lu_clear_seen, dut.pipeline_inst.j_clear_seen,
             dut.pipeline_inst.y_clear_seen, dut.pipeline_inst.x_clear_seen,
             dut.pipeline_inst.solver_start, dut.pipeline_inst.done, dut.pipeline_inst.fp_exception);
    $fatal(1, "M5SolverUartXsim timed out");
  end
endmodule
