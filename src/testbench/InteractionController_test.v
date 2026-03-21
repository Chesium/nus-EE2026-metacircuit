`timescale 1ns / 1ps

module InteractionController_test ();

  localparam integer AddrWidth = 8;
  localparam integer DataWidth = 16;
  localparam integer RotateFramesPerStep = 3;
  localparam [DataWidth-1:0] HorizontalWire = 16'b0000000_00_000000_1;
  localparam [DataWidth-1:0] VerticalWire   = 16'b0000000_01_000000_1;
  localparam [DataWidth-1:0] JunctionCell   = 16'b0000000_00_000011_1;
  localparam [DataWidth-1:0] ElbowCell      = 16'b0000000_00_000001_1;
  localparam [DataWidth-1:0] TeeCell        = 16'b0000000_00_000010_1;
  localparam [DataWidth-1:0] ResLeftCell    = 16'b0000000_00_000101_1;
  localparam [DataWidth-1:0] ResRightCell   = 16'b0000000_00_000110_1;
  localparam [DataWidth-1:0] VoltLeftCell   = 16'b0000000_00_000111_1;
  localparam [DataWidth-1:0] VoltRightCell  = 16'b0000000_00_001000_1;
  localparam [DataWidth-1:0] CurrLeftCell   = 16'b0000000_00_001001_1;
  localparam [DataWidth-1:0] CurrRightCell  = 16'b0000000_00_001010_1;

  reg clk = 1'b0;
  always #5 clk = ~clk;

  reg reset = 1'b1;
  reg frame_start_pulse = 1'b0;
  reg [3:0] mode_select = 4'd0;
  reg [11:0] mouse_x = 0;
  reg [11:0] mouse_y = 0;
  reg mouse_left = 1'b0;
  reg mouse_middle = 1'b0;
  reg mouse_right = 1'b0;
  reg signed [12:0] grid_pos_x = 0;
  reg signed [12:0] grid_pos_y = 0;
  reg bg_cmd_ready = 1'b0;
  reg bg_rsp_valid = 1'b0;
  reg [DataWidth-1:0] bg_rsp_rdata = 0;

  wire bg_cmd_valid;
  wire bg_cmd_write;
  wire [AddrWidth-1:0] bg_cmd_addr;
  wire [DataWidth-1:0] bg_cmd_wdata;
  wire frame_done;
  wire frame_drop_flag;

  integer failure_count = 0;

  InteractionController #(
      .RotateFramesPerStep(RotateFramesPerStep)
  ) dut (
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
      .bg_rsp_valid(bg_rsp_valid),
      .bg_rsp_rdata(bg_rsp_rdata),
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

  task automatic accept_head_command;
    begin
      bg_cmd_ready = 1'b1;
      @(posedge clk);
      #1;
      bg_cmd_ready = 1'b0;
      @(posedge clk);
      #1;
    end
  endtask

  task automatic return_read_data;
    input [DataWidth-1:0] read_data;
    begin
      bg_rsp_rdata = read_data;
      bg_rsp_valid = 1'b1;
      @(posedge clk);
      #1;
      bg_rsp_valid = 1'b0;
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
    pulse_frame();
    expect_true(!bg_cmd_valid, "no click should not generate a command");
    expect_true(frame_done, "empty frame should complete immediately");

    mode_select = 4'd0;
    mouse_left = 1'b1;
    pulse_frame();
    expect_true(bg_cmd_valid, "wire mode left click should generate a command");
    expect_true(bg_cmd_write, "wire mode should issue a write command");
    expect_addr(bg_cmd_addr, 8'd0, "wire mode left click should target cell 0");
    expect_word(bg_cmd_wdata, HorizontalWire, "wire mode left click should place horizontal wire");
    accept_head_command();

    mouse_left = 1'b0;
    mouse_right = 1'b1;
    mouse_x = 12'd50;
    mouse_y = 12'd40;
    pulse_frame();
    expect_true(bg_cmd_valid, "wire mode right click should generate a command");
    expect_addr(bg_cmd_addr, 8'd17, "wire mode right click should target cell (1,1)");
    expect_word(bg_cmd_wdata, VerticalWire, "wire mode right click should place vertical wire");
    accept_head_command();

    mouse_right = 1'b0;
    mouse_left = 1'b1;
    mode_select = 4'd1;
    pulse_frame();
    expect_word(bg_cmd_wdata, JunctionCell, "junction mode should place a junction sprite");
    accept_head_command();

    mode_select = 4'd2;
    pulse_frame();
    expect_word(bg_cmd_wdata, ElbowCell, "elbow mode should place an elbow sprite");
    accept_head_command();

    mode_select = 4'd3;
    pulse_frame();
    expect_word(bg_cmd_wdata, TeeCell, "tee mode should place a tee sprite");
    accept_head_command();

    mode_select = 4'd4;
    mouse_x = 12'd20;
    mouse_y = 12'd20;
    pulse_frame();
    expect_true(bg_cmd_valid, "resistor mode should issue the left-half write first");
    expect_addr(bg_cmd_addr, 8'd0, "resistor left half should target the selected cell");
    expect_word(bg_cmd_wdata, ResLeftCell, "resistor mode should place RL first");
    accept_head_command();
    expect_true(bg_cmd_valid, "resistor mode should issue the right-half write next");
    expect_addr(bg_cmd_addr, 8'd1, "resistor right half should target the adjacent cell");
    expect_word(bg_cmd_wdata, ResRightCell, "resistor mode should place RR second");
    accept_head_command();

    mode_select = 4'd5;
    pulse_frame();
    expect_word(bg_cmd_wdata, VoltLeftCell, "voltage mode should place VL first");
    accept_head_command();
    expect_addr(bg_cmd_addr, 8'd1, "voltage mode right half should target the adjacent cell");
    expect_word(bg_cmd_wdata, VoltRightCell, "voltage mode should place VR second");
    accept_head_command();

    mode_select = 4'd6;
    pulse_frame();
    expect_word(bg_cmd_wdata, CurrLeftCell, "current mode should place IL first");
    accept_head_command();
    expect_addr(bg_cmd_addr, 8'd1, "current mode right half should target the adjacent cell");
    expect_word(bg_cmd_wdata, CurrRightCell, "current mode should place IR second");
    accept_head_command();

    mode_select = 4'd8;
    mouse_x = 12'd50;
    mouse_y = 12'd40;
    pulse_frame();
    expect_true(bg_cmd_valid, "clear mode should generate a command");
    expect_true(bg_cmd_write, "clear mode should issue a write command");
    expect_addr(bg_cmd_addr, 8'd17, "clear mode should target the selected cell");
    expect_word(bg_cmd_wdata, 16'd0, "clear mode should write zero to clear the cell");
    accept_head_command();

    mode_select = 4'd7;
    mouse_x = 12'd50;
    mouse_y = 12'd40;
    pulse_frame();
    expect_true(bg_cmd_valid, "rotate mode should start with a read command");
    expect_true(!bg_cmd_write, "rotate mode first command should be a read");
    expect_addr(bg_cmd_addr, 8'd17, "rotate mode should read the selected cell");
    accept_head_command();
    return_read_data(16'b0000000_10_000101_1);
    expect_true(bg_cmd_valid, "rotate mode should issue a write after the read response");
    expect_true(bg_cmd_write, "rotate mode second command should be a write");
    expect_addr(bg_cmd_addr, 8'd17, "rotate mode write should target the same cell");
    expect_word(bg_cmd_wdata, 16'b0000000_11_000101_1,
                "rotate mode should increment the cell rotation");
    accept_head_command();

    pulse_frame();
    expect_true(!bg_cmd_valid, "rotate mode should wait before issuing another step");
    pulse_frame();
    expect_true(!bg_cmd_valid, "rotate mode should keep waiting until the holdoff expires");
    pulse_frame();
    expect_true(bg_cmd_valid, "rotate mode should issue the next step after the programmed frame interval");
    expect_true(!bg_cmd_write, "throttled rotate step should still begin with a read");
    expect_addr(bg_cmd_addr, 8'd17, "throttled rotate step should keep targeting the selected cell");
    accept_head_command();
    return_read_data(16'd0);
    expect_word(bg_cmd_wdata, 16'd0, "rotate mode should leave empty cells unchanged");
    accept_head_command();

    mode_select = 4'd7;
    mouse_left = 1'b0;
    pulse_frame();
    expect_true(!bg_cmd_valid, "releasing rotate input should stop issuing commands immediately");
    mouse_left = 1'b1;
    pulse_frame();
    expect_true(bg_cmd_valid, "rotate holdoff should reset once the input is released");
    accept_head_command();
    return_read_data(16'b0000000_00_000111_1);
    expect_word(bg_cmd_wdata, 16'b0000000_01_000111_1,
                "rotate mode should restart from the current cell data after a release");
    accept_head_command();

    mode_select = 4'd4;
    mouse_x = 12'd500;
    mouse_y = 12'd40;
    mouse_left = 1'b1;
    mouse_right = 1'b0;
    pulse_frame();
    expect_true(!bg_cmd_valid, "outside-canvas click should be ignored in all draw modes");

    mouse_x = 12'd10;
    mouse_y = 12'd10;
    mouse_left = 1'b1;
    mouse_right = 1'b1;
    pulse_frame();
    expect_true(!bg_cmd_valid, "simultaneous left and right clicks should be ignored");

    mouse_left = 1'b1;
    mouse_right = 1'b0;
    mouse_middle = 1'b1;
    pulse_frame();
    expect_true(!bg_cmd_valid, "middle-button press should suppress placement");

    mouse_middle = 1'b0;
    mode_select = 4'd4;
    mouse_x = 12'd395;
    mouse_y = 12'd10;
    grid_pos_x = -13'sd112;
    grid_pos_y = 13'sd0;
    pulse_frame();
    expect_true(!bg_cmd_valid, "dual-cell modes should ignore placements that would spill past the row edge");

    mode_select = 4'd1;
    mouse_x = 12'd10;
    mouse_y = 12'd10;
    grid_pos_x = -13'sd64;
    grid_pos_y = -13'sd32;
    pulse_frame();
    expect_true(bg_cmd_valid, "panned placement should still generate a command");
    expect_addr(bg_cmd_addr, 8'd18, "panned placement should target the correct translated cell");
    accept_head_command();

    mode_select = 4'd1;
    mouse_x = 12'd10;
    mouse_y = 12'd10;
    mouse_left = 1'b1;
    grid_pos_x = 13'sd0;
    grid_pos_y = 13'sd0;
    pulse_frame();
    expect_word(bg_cmd_wdata, JunctionCell, "setup frame should leave a pending command to be replaced");

    mode_select = 4'd5;
    pulse_frame();
    expect_word(bg_cmd_wdata, VoltLeftCell, "new frame should replace older pending work with the newest snapshot");
    expect_true(frame_drop_flag, "overwriting a previous unfinished frame should raise the drop flag");
    accept_head_command();
    expect_word(bg_cmd_wdata, VoltRightCell, "newest dual-cell work should keep its second half");
    accept_head_command();

    if (failure_count == 0) begin
      $display("InteractionController_test passed.");
      $finish;
    end else begin
      $fatal(1, "InteractionController_test failed with %0d issue(s).", failure_count);
    end
  end

endmodule
