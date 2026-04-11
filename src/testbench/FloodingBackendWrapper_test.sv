`timescale 1ns / 1ps

module FloodingBackendWrapper_test;
  localparam integer GRID_WIDTH = 18;
  localparam integer GRID_HEIGHT = 16;
  localparam integer CELL_COUNT = GRID_WIDTH * GRID_HEIGHT;

  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk;

  reg start = 1'b0;
  wire busy;
  wire done;

  wire fetchP_ram_ren;
  wire [8:0] fetchP_ram_addr;
  reg  [15:0] fetchP_ram_rdata = 16'd0;

  reg         fetchR_start = 1'b0;
  reg  [7:0]  fetchR_i = 8'd0;
  reg  [7:0]  fetchR_j = 8'd0;
  wire        fetchR_done;
  wire [7:0]  fetchR_result;

  reg [15:0] canvas_mem[0:CELL_COUNT-1];
  integer idx;
  integer cycle_count;
  integer nonzero_count;
  integer x;
  integer y;
  reg [7:0] readback_value;

  FloodingBackendWrapper #(
      .GRID_WIDTH(GRID_WIDTH),
      .GRID_HEIGHT(GRID_HEIGHT)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .start(start),
      .busy(busy),
      .done(done),
      .fetchP_ram_ren(fetchP_ram_ren),
      .fetchP_ram_addr(fetchP_ram_addr),
      .fetchP_ram_rdata(fetchP_ram_rdata),
      .fetchR_start(fetchR_start),
      .fetchR_i(fetchR_i),
      .fetchR_j(fetchR_j),
      .fetchR_done(fetchR_done),
      .fetchR_result(fetchR_result)
  );

  task automatic read_result(
      input [7:0] i,
      input [7:0] j,
      output [7:0] result_value
  );
    begin
      @(negedge clk);
      fetchR_i <= i;
      fetchR_j <= j;
      fetchR_start <= 1'b1;
      @(negedge clk);
      fetchR_start <= 1'b0;
      wait (fetchR_done == 1'b1);
      #1;
      result_value = fetchR_result;
    end
  endtask

  always @(posedge clk) begin
    if (fetchP_ram_ren) begin
      fetchP_ram_rdata <= canvas_mem[fetchP_ram_addr];
    end
  end

  task automatic clear_canvas;
    begin
      for (idx = 0; idx < CELL_COUNT; idx = idx + 1) begin
        canvas_mem[idx] = 16'd0;
      end
    end
  endtask

  task automatic start_and_wait_done;
    begin
      @(negedge clk);
      start <= 1'b1;
      @(negedge clk);
      start <= 1'b0;

      cycle_count = 0;
      while (done !== 1'b1 && cycle_count < 20000) begin
        @(posedge clk);
        cycle_count = cycle_count + 1;
      end

      if (done !== 1'b1) begin
        $fatal(1, "FloodingBackendWrapper_test timed out after %0d cycles", cycle_count);
      end
    end
  endtask

  task automatic expect_result(
      input [7:0] i,
      input [7:0] j,
      input [7:0] expected
  );
    begin
      read_result(i, j, readback_value);
      if (readback_value !== expected) begin
        $fatal(1, "Unexpected flood result at (%0d,%0d): got %0d expected %0d", i, j, readback_value, expected);
      end
    end
  endtask

  task automatic run_case_single_horizontal_wire;
    begin
      clear_canvas();
      canvas_mem[9'd19] = 16'h0001; // (1,1) horizontal wire
      start_and_wait_done();

      expect_result(8'd1, 8'd1, 8'd1);
      expect_result(8'd2, 8'd1, 8'd0);
      expect_result(8'd3, 8'd1, 8'd0);
      expect_result(8'd0, 8'd1, 8'd0);
      expect_result(8'd1, 8'd0, 8'd0);
      expect_result(8'd1, 8'd2, 8'd0);

      $display("run_case_single_horizontal_wire passed.");
    end
  endtask

  task automatic run_case_single_vertical_wire;
    begin
      clear_canvas();
      canvas_mem[9'd76] = 16'h0081; // (4,4) vertical wire
      start_and_wait_done();

      expect_result(8'd4, 8'd4, 8'd1);
      expect_result(8'd5, 8'd4, 8'd0);
      expect_result(8'd3, 8'd4, 8'd0);
      expect_result(8'd4, 8'd3, 8'd0);
      expect_result(8'd4, 8'd5, 8'd0);

      $display("run_case_single_vertical_wire passed.");
    end
  endtask

  task automatic run_case_sample_circuit;
    begin
      clear_canvas();

      // Match the built-in sample circuit in GlobalRender_top.
      canvas_mem[9'd38]  = 16'h0083;
      canvas_mem[9'd39]  = 16'h000F;
      canvas_mem[9'd40]  = 16'h0011;
      canvas_mem[9'd41]  = 16'h0103;
      canvas_mem[9'd56]  = 16'h0281;
      canvas_mem[9'd59]  = 16'h0081;
      canvas_mem[9'd74]  = 16'h0285;
      canvas_mem[9'd75]  = 16'h020B;
      canvas_mem[9'd76]  = 16'h020D;
      canvas_mem[9'd77]  = 16'h0185;
      canvas_mem[9'd92]  = 16'h0281;
      canvas_mem[9'd95]  = 16'h0081;
      canvas_mem[9'd110] = 16'h0003;
      canvas_mem[9'd111] = 16'h021B;
      canvas_mem[9'd112] = 16'h021D;
      canvas_mem[9'd113] = 16'h0183;

      start_and_wait_done();

      nonzero_count = 0;
      for (y = 0; y < GRID_HEIGHT; y = y + 1) begin
        for (x = 0; x < GRID_WIDTH; x = x + 1) begin
          read_result(x[7:0], y[7:0], readback_value);
          if (readback_value != 8'd0) begin
            nonzero_count = nonzero_count + 1;
            $display("R(%0d,%0d) = %0d", x, y, readback_value);
          end
        end
      end

      if (nonzero_count == 0) begin
        $fatal(1, "FloodingBackendWrapper_test saw only zero flooded nodes");
      end

      $display("run_case_sample_circuit passed with %0d nonzero cells.", nonzero_count);
    end
  endtask

  initial begin
    clear_canvas();

    repeat (4) @(negedge clk);
    rst_n <= 1'b1;

    run_case_single_horizontal_wire();
    run_case_single_vertical_wire();
    run_case_sample_circuit();

    $display("FloodingBackendWrapper_test passed.");
    $finish;
  end
endmodule
