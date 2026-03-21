`timescale 1ns / 1ps

module InteractionCanvas_test ();

  localparam integer CanvasWordCount = 256;
  localparam [15:0] HorizontalWire = 16'b0000000_00_000000_1;
  localparam [15:0] VerticalWire = 16'b0000000_01_000000_1;

  reg clk_t_100m = 1'b0;
  always #5 clk_t_100m = ~clk_t_100m;

  reg [15:0] i_sw = 16'd0;
  reg btnc = 1'b1;

  wire [15:0] led;
  wire [7:0] seg;
  wire [3:0] an;
  wire [7:0] jc;
  wire [3:0] vga_r;
  wire [3:0] vga_b;
  wire [3:0] vga_g;
  wire hsync;
  wire vsync;
  wire ps2clk;
  wire ps2data;

  integer failure_count = 0;
  integer idx;
  reg sel_before;
  reg sel_after;
  reg [11:0] forced_mouse_x = 12'd0;
  reg [11:0] forced_mouse_y = 12'd0;
  reg forced_mouse_left = 1'b0;
  reg forced_mouse_middle = 1'b0;
  reg forced_mouse_right = 1'b0;

  CircuitCanvas_top #(
      .EnableDemoProducer(0),
      .EnableInteraction(1),
      .BgStepWaitCycles(0)
  ) dut (
      .CLK100MHZ(clk_t_100m),
      .SW(i_sw),
      .LED(led),
      .SEG(seg),
      .AN(an),
      .BTNC(btnc),
      .BTNU(1'b0),
      .BTNL(1'b0),
      .BTNR(1'b0),
      .BTND(1'b0),
      .JC(jc),
      .VGARED(vga_r),
      .VGABLUE(vga_b),
      .VGAGREEN(vga_g),
      .HSYNC(hsync),
      .VSYNC(vsync),
      .PS2CLK(ps2clk),
      .PS2DATA(ps2data)
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

  task automatic wait_for_bg_frame_prep_done;
    begin
      wait (dut.frame_prep_done == 1'b1);
      @(posedge clk_t_100m);
    end
  endtask

  task automatic wait_for_bg_frame_flip;
    reg prev_sel;
    begin
      prev_sel = dut.active_buf_sel_bg;
      wait (dut.active_buf_sel_bg != prev_sel);
      @(posedge clk_t_100m);
    end
  endtask

  task automatic wait_for_next_bg_frame_prep_done;
    begin
      wait (dut.frame_prep_done == 1'b0);
      wait (dut.frame_prep_done == 1'b1);
      @(posedge clk_t_100m);
    end
  endtask

  task automatic drive_mouse;
    input [11:0] new_x;
    input [11:0] new_y;
    input new_left;
    input new_middle;
    input new_right;
    begin
      forced_mouse_x = new_x;
      forced_mouse_y = new_y;
      forced_mouse_left = new_left;
      forced_mouse_middle = new_middle;
      forced_mouse_right = new_right;
    end
  endtask

  initial begin
    #100;
    btnc = 1'b0;
  end

  initial begin
    #250_000_000;
    $fatal(1, "InteractionCanvas_test timed out.");
  end

  initial begin
    force dut.mouse_xpos = forced_mouse_x;
    force dut.mouse_ypos = forced_mouse_y;
    force dut.mouse_left = forced_mouse_left;
    force dut.mouse_middle = forced_mouse_middle;
    force dut.mouse_right = forced_mouse_right;

    drive_mouse(12'd0, 12'd0, 1'b0, 1'b0, 1'b0);

    wait (dut.buffers_init_done == 1'b1);
    wait_for_bg_frame_prep_done();

    expect_word(dut.canvas_ram_a_inst.mem[0], 16'd0,
                "interaction DUT buffer A cell 0 should start cleared");
    expect_word(dut.canvas_ram_b_inst.mem[0], 16'd0,
                "interaction DUT buffer B cell 0 should start cleared");
    expect_word(dut.canvas_ram_a_inst.mem[17], 16'd0,
                "interaction DUT buffer A cell 17 should start cleared");
    expect_word(dut.canvas_ram_b_inst.mem[17], 16'd0,
                "interaction DUT buffer B cell 17 should start cleared");

    sel_before = dut.active_buf_sel_bg;
    drive_mouse(12'd10, 12'd10, 1'b1, 1'b0, 1'b0);
    wait_for_bg_frame_flip();
    wait_for_next_bg_frame_prep_done();
    drive_mouse(12'd10, 12'd10, 1'b0, 1'b0, 1'b0);
    sel_after = dut.active_buf_sel_bg;
    expect_true(sel_before != sel_after, "interaction DUT should flip buffers each frame");
    if (sel_after == 1'b0) begin
      expect_word(dut.canvas_ram_a_inst.mem[0], 16'd0,
                  "active buffer should stay unchanged during the draw frame");
      expect_word(dut.canvas_ram_b_inst.mem[0], HorizontalWire,
                  "inactive buffer should receive the horizontal wire update");
    end else begin
      expect_word(dut.canvas_ram_b_inst.mem[0], 16'd0,
                  "active buffer should stay unchanged during the draw frame");
      expect_word(dut.canvas_ram_a_inst.mem[0], HorizontalWire,
                  "inactive buffer should receive the horizontal wire update");
    end

    wait_for_bg_frame_flip();
    wait_for_next_bg_frame_prep_done();
    if (dut.active_buf_sel_bg == 1'b0) begin
      expect_word(dut.canvas_ram_a_inst.mem[0], HorizontalWire,
                  "horizontal wire should become visible after the next flip");
    end else begin
      expect_word(dut.canvas_ram_b_inst.mem[0], HorizontalWire,
                  "horizontal wire should become visible after the next flip");
    end

    drive_mouse(12'd50, 12'd40, 1'b0, 1'b0, 1'b1);
    wait_for_bg_frame_flip();
    wait_for_next_bg_frame_prep_done();
    drive_mouse(12'd50, 12'd40, 1'b0, 1'b0, 1'b0);
    if (dut.active_buf_sel_bg == 1'b0) begin
      expect_word(dut.canvas_ram_b_inst.mem[17], VerticalWire,
                  "right click should update the next inactive buffer with a vertical wire");
    end else begin
      expect_word(dut.canvas_ram_a_inst.mem[17], VerticalWire,
                  "right click should update the next inactive buffer with a vertical wire");
    end

    wait_for_bg_frame_flip();
    wait_for_next_bg_frame_prep_done();
    if (dut.active_buf_sel_bg == 1'b0) begin
      expect_word(dut.canvas_ram_a_inst.mem[17], VerticalWire,
                  "vertical wire should become visible after the next flip");
    end else begin
      expect_word(dut.canvas_ram_b_inst.mem[17], VerticalWire,
                  "vertical wire should become visible after the next flip");
    end

    drive_mouse(12'd500, 12'd20, 1'b1, 1'b0, 1'b0);
    wait_for_bg_frame_flip();
    wait_for_next_bg_frame_prep_done();
    drive_mouse(12'd500, 12'd20, 1'b0, 1'b0, 1'b0);
    expect_word(dut.canvas_ram_a_inst.mem[5], 16'd0,
                "outside-canvas click should not modify unrelated cells in buffer A");
    expect_word(dut.canvas_ram_b_inst.mem[5], 16'd0,
                "outside-canvas click should not modify unrelated cells in buffer B");

    if (failure_count == 0) begin
      $display("InteractionCanvas_test passed.");
      $finish;
    end else begin
      $fatal(1, "InteractionCanvas_test failed with %0d issue(s).", failure_count);
    end
  end

endmodule
