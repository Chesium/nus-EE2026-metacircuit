`timescale 1ns / 1ps

module InteractionController_test ();

  localparam integer AddrWidth = 8;
  localparam integer DataWidth = 16;
  localparam [DataWidth-1:0] HorizontalWire = 16'b0000000_00_000000_1;
  localparam [DataWidth-1:0] VerticalWire = 16'b0000000_01_000000_1;

  reg clk = 1'b0;
  always #5 clk = ~clk;

  reg reset = 1'b1;
  reg frame_start_pulse = 1'b0;
  reg [1:0] mode_select = 2'd0;
  reg [11:0] mouse_x = 0;
  reg [11:0] mouse_y = 0;
  reg mouse_left = 1'b0;
  reg mouse_middle = 1'b0;
  reg mouse_right = 1'b0;
  reg signed [12:0] grid_pos_x = 0;
  reg signed [12:0] grid_pos_y = 0;
  reg bg_cmd_ready = 1'b0;

  wire bg_cmd_valid;
  wire bg_cmd_write;
  wire [AddrWidth-1:0] bg_cmd_addr;
  wire [DataWidth-1:0] bg_cmd_wdata;
  wire frame_done;
  wire frame_drop_flag;

  integer failure_count = 0;

  InteractionController dut (
      .clk(clk),
      .reset(reset),
      .frame_start_pulse(frame_start_pulse),
      .mode_select(mode_select),
      .mouse_x(mouse_x),
      .mouse_y(mouse_y),
      .mouse_left(mouse_left),
      .mouse_middle(mouse_middle),
      .mouse_right(mouse_right),
      .grid_pos_x(grid_pos_x),
      .grid_pos_y(grid_pos_y),
      .bg_cmd_ready(bg_cmd_ready),
      .bg_cmd_valid(bg_cmd_valid),
      .bg_cmd_write(bg_cmd_write),
      .bg_cmd_addr(bg_cmd_addr),
      .bg_cmd_wdata(bg_cmd_wdata),
      .frame_done(frame_done),
      .frame_drop_flag(frame_drop_flag)
  );

  task automatic expect_true;
    input condition;
    input [255:0] message;
    begin
      if (!condition) begin
        failure_count = failure_count + 1;
        $display("FAIL: %0s", message);
      end
    end
  endtask

  task automatic expect_word;
    input [15:0] got;
    input [15:0] expected;
    input [255:0] message;
    begin
      if (got !== expected) begin
        failure_count = failure_count + 1;
        $display("FAIL: %0s got=%h expected=%h", message, got, expected);
      end
    end
  endtask

  task automatic expect_addr;
    input [AddrWidth-1:0] got;
    input [AddrWidth-1:0] expected;
    input [255:0] message;
    begin
      if (got !== expected) begin
        failure_count = failure_count + 1;
        $display("FAIL: %0s got=%0d expected=%0d", message, got, expected);
      end
    end
  endtask

  task automatic pulse_frame;
    begin
      frame_start_pulse = 1'b1;
      @(posedge clk);
      #1;
      frame_start_pulse = 1'b0;
      @(posedge clk);
      #1;
    end
  endtask

  task automatic consume_command;
    begin
      bg_cmd_ready = 1'b1;
      @(posedge clk);
      #1;
      bg_cmd_ready = 1'b0;
      @(posedge clk);
      #1;
    end
  endtask

  initial begin
    repeat (3) @(posedge clk);
    reset = 1'b0;
    @(posedge clk);
    #1;

    mouse_x = 12'd10;
    mouse_y = 12'd10;
    mouse_left = 1'b0;
    mouse_middle = 1'b0;
    mouse_right = 1'b0;
    grid_pos_x = 13'sd0;
    grid_pos_y = 13'sd0;
    pulse_frame();
    expect_true(!bg_cmd_valid, "no click should not generate a background command");
    expect_true(frame_done, "no click frame should complete immediately");

    mouse_left = 1'b1;
    pulse_frame();
    expect_true(bg_cmd_valid, "left click inside canvas should generate a command");
    expect_true(bg_cmd_write, "draw-wire command should be a write");
    expect_addr(bg_cmd_addr, 8'd0, "left click near origin should target cell 0");
    expect_word(bg_cmd_wdata, HorizontalWire, "left click should draw a horizontal wire");
    expect_true(!frame_done, "frame should remain busy until its command is accepted");
    consume_command();
    expect_true(!bg_cmd_valid, "accepted command should clear the pending valid flag");
    expect_true(frame_done, "frame should complete after the command is accepted");

    mouse_left = 1'b0;
    mouse_right = 1'b1;
    mouse_x = 12'd50;
    mouse_y = 12'd40;
    pulse_frame();
    expect_true(bg_cmd_valid, "right click inside canvas should generate a command");
    expect_addr(bg_cmd_addr, 8'd17, "right click at (50,40) should target cell (1,1)");
    expect_word(bg_cmd_wdata, VerticalWire, "right click should draw a vertical wire");
    consume_command();

    mouse_right = 1'b0;
    mouse_x = 12'd500;
    mouse_y = 12'd40;
    mouse_left = 1'b1;
    pulse_frame();
    expect_true(!bg_cmd_valid, "click outside the canvas should be ignored");
    expect_true(frame_done, "outside-canvas frame should complete without a command");

    mouse_x = 12'd20;
    mouse_y = 12'd20;
    mouse_left = 1'b1;
    mouse_right = 1'b1;
    pulse_frame();
    expect_true(!bg_cmd_valid, "simultaneous left and right clicks should be ignored");

    mouse_left = 1'b1;
    mouse_right = 1'b0;
    mouse_middle = 1'b1;
    pulse_frame();
    expect_true(!bg_cmd_valid, "middle+left should not draw while panning is active");

    mouse_left = 1'b1;
    mouse_middle = 1'b0;
    mouse_right = 1'b0;
    mouse_x = 12'd10;
    mouse_y = 12'd10;
    grid_pos_x = -13'sd64;
    grid_pos_y = -13'sd32;
    pulse_frame();
    expect_true(bg_cmd_valid, "panned view click should still generate a command");
    expect_addr(bg_cmd_addr, 8'd18, "panned view click should map to the correct cell address");
    expect_word(bg_cmd_wdata, HorizontalWire, "panned view left click should still draw horizontal");

    mouse_left = 1'b0;
    mouse_right = 1'b1;
    mouse_x = 12'd80;
    mouse_y = 12'd80;
    pulse_frame();
    expect_true(frame_drop_flag, "new frame input should replace an older unconsumed command");
    expect_true(bg_cmd_valid, "replacement frame should still leave a pending command");
    expect_addr(bg_cmd_addr, 8'd52, "replacement frame should target the newest snapshot cell");
    expect_word(bg_cmd_wdata, VerticalWire, "replacement frame should use the newest snapshot direction");
    consume_command();

    if (failure_count == 0) begin
      $display("InteractionController_test passed.");
      $finish;
    end else begin
      $fatal(1, "InteractionController_test failed with %0d issue(s).", failure_count);
    end
  end

endmodule
