`timescale 1ns / 1ps

module Canvas_test ();

  localparam integer CanvasWordCount = 256;
  localparam integer OverrunBgStepWaitCycles = 5000;

  reg clk_t_100m = 0;
  always #5 clk_t_100m = ~clk_t_100m;  // 10ns => 100MHz

  reg [15:0] i_sw = 16'b0000_0000_0000_0000;

  reg stable_btnc = 1'b1;
  reg demo_btnc = 1'b1;
  reg overrun_btnc = 1'b1;

  wire [15:0] stable_led;
  wire [ 7:0] stable_seg;
  wire [ 3:0] stable_an;
  wire [ 7:0] stable_jc;
  wire [ 3:0] stable_vga_r;
  wire [ 3:0] stable_vga_b;
  wire [ 3:0] stable_vga_g;
  wire stable_vga_hsync;
  wire stable_vga_vsync;
  wire stable_ps2clk;
  wire stable_ps2data;

  wire [15:0] demo_led;
  wire [ 7:0] demo_seg;
  wire [ 3:0] demo_an;
  wire [ 7:0] demo_jc;
  wire [ 3:0] demo_vga_r;
  wire [ 3:0] demo_vga_b;
  wire [ 3:0] demo_vga_g;
  wire demo_vga_hsync;
  wire demo_vga_vsync;
  wire demo_ps2clk;
  wire demo_ps2data;

  wire [15:0] overrun_led;
  wire [ 7:0] overrun_seg;
  wire [ 3:0] overrun_an;
  wire [ 7:0] overrun_jc;
  wire [ 3:0] overrun_vga_r;
  wire [ 3:0] overrun_vga_b;
  wire [ 3:0] overrun_vga_g;
  wire overrun_vga_hsync;
  wire overrun_vga_vsync;
  wire overrun_ps2clk;
  wire overrun_ps2data;

  CircuitCanvas_top #(
      .EnableDemoProducer(0),
      .BgStepWaitCycles(0)
  ) dut_stable (
      .CLK100MHZ(clk_t_100m),
      .SW(i_sw),
      .LED(stable_led),
      .SEG(stable_seg),
      .AN(stable_an),
      .BTNC(stable_btnc),
      .BTNU(1'b0),
      .BTNL(1'b0),
      .BTNR(1'b0),
      .BTND(1'b0),
      .JC(stable_jc),
      .VGARED(stable_vga_r),
      .VGABLUE(stable_vga_b),
      .VGAGREEN(stable_vga_g),
      .HSYNC(stable_vga_hsync),
      .VSYNC(stable_vga_vsync),
      .PS2CLK(stable_ps2clk),
      .PS2DATA(stable_ps2data)
  );

  CircuitCanvas_top #(
      .EnableDemoProducer(1),
      .BgStepWaitCycles(0)
  ) dut_demo (
      .CLK100MHZ(clk_t_100m),
      .SW(i_sw),
      .LED(demo_led),
      .SEG(demo_seg),
      .AN(demo_an),
      .BTNC(demo_btnc),
      .BTNU(1'b0),
      .BTNL(1'b0),
      .BTNR(1'b0),
      .BTND(1'b0),
      .JC(demo_jc),
      .VGARED(demo_vga_r),
      .VGABLUE(demo_vga_b),
      .VGAGREEN(demo_vga_g),
      .HSYNC(demo_vga_hsync),
      .VSYNC(demo_vga_vsync),
      .PS2CLK(demo_ps2clk),
      .PS2DATA(demo_ps2data)
  );

  CircuitCanvas_top #(
      .EnableDemoProducer(0),
      .BgStepWaitCycles(OverrunBgStepWaitCycles)
  ) dut_overrun (
      .CLK100MHZ(clk_t_100m),
      .SW(i_sw),
      .LED(overrun_led),
      .SEG(overrun_seg),
      .AN(overrun_an),
      .BTNC(overrun_btnc),
      .BTNU(1'b0),
      .BTNL(1'b0),
      .BTNR(1'b0),
      .BTND(1'b0),
      .JC(overrun_jc),
      .VGARED(overrun_vga_r),
      .VGABLUE(overrun_vga_b),
      .VGAGREEN(overrun_vga_g),
      .HSYNC(overrun_vga_hsync),
      .VSYNC(overrun_vga_vsync),
      .PS2CLK(overrun_ps2clk),
      .PS2DATA(overrun_ps2data)
  );

  integer failure_count = 0;
  integer idx;
  integer current_active;
  integer next_active;
  reg overrun_sel_before;
  reg stable_sel_before;
  reg stable_sel_after;
  reg demo_sel_before;
  reg demo_sel_after;

  function [15:0] demo_expected_word;
    input integer addr;
    begin
      case (addr)
        0: demo_expected_word = 16'b0000000_00_000000_1;
        1: demo_expected_word = 16'b0000000_00_000101_1;
        2: demo_expected_word = 16'b0000000_00_000110_1;
        16: demo_expected_word = 16'b0000000_11_001000_1;
        32: demo_expected_word = 16'b0000000_11_000111_1;
        82: demo_expected_word = 16'b0000000_00_000010_1;
        84: demo_expected_word = 16'b0000000_01_000010_1;
        86: demo_expected_word = 16'b0000000_10_000010_1;
        88: demo_expected_word = 16'b0000000_11_000010_1;
        default: demo_expected_word = 16'd0;
      endcase
    end
  endfunction

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

  task automatic wait_for_bg_frame_prep_done_stable;
    begin
      wait (dut_stable.frame_prep_done == 1'b1);
      @(posedge clk_t_100m);
    end
  endtask

  task automatic wait_for_next_bg_frame_prep_done_stable;
    begin
      wait (dut_stable.frame_prep_done == 1'b0);
      wait (dut_stable.frame_prep_done == 1'b1);
      @(posedge clk_t_100m);
    end
  endtask

  task automatic wait_for_bg_frame_flip_stable;
    reg prev_sel;
    begin
      prev_sel = dut_stable.active_buf_sel_bg;
      wait (dut_stable.active_buf_sel_bg != prev_sel);
      @(posedge clk_t_100m);
    end
  endtask

  task automatic wait_for_bg_frame_flip_demo;
    reg prev_sel;
    begin
      prev_sel = dut_demo.active_buf_sel_bg;
      wait (dut_demo.active_buf_sel_bg != prev_sel);
      @(posedge clk_t_100m);
    end
  endtask

  task automatic wait_for_next_bg_frame_prep_done_demo;
    begin
      wait (dut_demo.frame_prep_done == 1'b0);
      wait (dut_demo.frame_prep_done == 1'b1);
      @(posedge clk_t_100m);
    end
  endtask

  initial begin
    #100;
    stable_btnc = 1'b0;
  end

  initial begin
    #200_000_000;
    $fatal(1, "Canvas_test timed out.");
  end

  initial begin
    wait (dut_stable.buffers_init_done == 1'b1);

    wait_for_bg_frame_prep_done_stable();

    $display("Checking no-update stability...");
    stable_sel_before = dut_stable.active_buf_sel_pix;
    wait_for_bg_frame_flip_stable();
    wait_for_next_bg_frame_prep_done_stable();
    stable_sel_after = dut_stable.active_buf_sel_pix;
    expect_true(stable_sel_before != stable_sel_after,
                "stable DUT active buffer should toggle on frame flip");
    expect_true(dut_stable.bg_overrun_flag == 1'b0,
                "stable DUT should not flag overrun");
    for (idx = 0; idx < CanvasWordCount; idx = idx + 1) begin
      expect_word(dut_stable.canvas_ram_a_inst.mem[idx], 16'd0,
                  "stable DUT buffer A should stay zero with no updates");
      expect_word(dut_stable.canvas_ram_b_inst.mem[idx], 16'd0,
                  "stable DUT buffer B should stay zero with no updates");
    end

    $display("Checking copy correctness...");
    current_active = dut_stable.active_buf_sel_bg;
    next_active = current_active ? 0 : 1;
    for (idx = 0; idx < CanvasWordCount; idx = idx + 1) begin
      if (next_active == 0) begin
        dut_stable.canvas_ram_a_inst.mem[idx] = 16'h1000 + idx;
        dut_stable.canvas_ram_b_inst.mem[idx] = 16'hDEAD;
      end else begin
        dut_stable.canvas_ram_b_inst.mem[idx] = 16'h1000 + idx;
        dut_stable.canvas_ram_a_inst.mem[idx] = 16'hDEAD;
      end
    end
    wait_for_bg_frame_flip_stable();
    wait_for_next_bg_frame_prep_done_stable();
    expect_true(dut_stable.active_buf_sel_bg == next_active,
                "stable DUT should flip to the prepared source buffer");
    for (idx = 0; idx < CanvasWordCount; idx = idx + 1) begin
      expect_word(dut_stable.canvas_ram_a_inst.mem[idx], 16'h1000 + idx,
                  "copy phase should preserve source pattern in buffer A");
      expect_word(dut_stable.canvas_ram_b_inst.mem[idx], 16'h1000 + idx,
                  "copy phase should clone the active pattern into buffer B");
    end

    demo_btnc = 1'b0;
    wait (dut_demo.buffers_init_done == 1'b1);

    $display("Checking deferred visibility and copy-through...");
    wait (dut_demo.demo_loaded == 1'b1 && dut_demo.frame_prep_done == 1'b1);
    demo_sel_before = dut_demo.active_buf_sel_bg;
    if (demo_sel_before == 1'b0) begin
      for (idx = 0; idx < CanvasWordCount; idx = idx + 1) begin
        expect_word(dut_demo.canvas_ram_a_inst.mem[idx], 16'd0,
                    "active demo buffer should stay unchanged until next flip");
        expect_word(dut_demo.canvas_ram_b_inst.mem[idx], demo_expected_word(idx),
                    "inactive demo buffer should contain copied+updated data");
      end
    end else begin
      for (idx = 0; idx < CanvasWordCount; idx = idx + 1) begin
        expect_word(dut_demo.canvas_ram_b_inst.mem[idx], 16'd0,
                    "active demo buffer should stay unchanged until next flip");
        expect_word(dut_demo.canvas_ram_a_inst.mem[idx], demo_expected_word(idx),
                    "inactive demo buffer should contain copied+updated data");
      end
    end
    expect_word(demo_expected_word(0), 16'b0000000_00_000000_1,
                "demo pattern helper should reflect the current addr 0 write");

    wait_for_bg_frame_flip_demo();
    wait_for_next_bg_frame_prep_done_demo();
    demo_sel_after = dut_demo.active_buf_sel_bg;
    expect_true(demo_sel_before != demo_sel_after,
                "demo DUT should flip buffers after preparing updates");
    if (demo_sel_after == 1'b0) begin
      for (idx = 0; idx < CanvasWordCount; idx = idx + 1) begin
        expect_word(dut_demo.canvas_ram_a_inst.mem[idx], demo_expected_word(idx),
                    "demo pattern should become visible only after the next flip");
      end
    end else begin
      for (idx = 0; idx < CanvasWordCount; idx = idx + 1) begin
        expect_word(dut_demo.canvas_ram_b_inst.mem[idx], demo_expected_word(idx),
                    "demo pattern should become visible only after the next flip");
      end
    end
    expect_word(dut_demo.canvas_ram_a_inst.mem[0], 16'b0000000_00_000000_1,
                "addr 0 should contain the demo write in buffer A");
    expect_word(dut_demo.canvas_ram_b_inst.mem[0], 16'b0000000_00_000000_1,
                "addr 0 should contain the demo write in buffer B after copy-through");

    overrun_btnc = 1'b0;
    wait (dut_overrun.buffers_init_done == 1'b1);

    $display("Checking overrun signalling...");
    overrun_sel_before = dut_overrun.active_buf_sel_bg;
    wait (dut_overrun.active_buf_sel_bg != overrun_sel_before);
    wait (dut_overrun.bg_overrun_flag == 1'b1);
    expect_true(dut_overrun.active_buf_sel_bg != 1'bx,
                "overrun DUT should still maintain a valid buffer select when it overruns");

    if (failure_count == 0) begin
      $display("Canvas ping-pong tests passed.");
      $finish;
    end else begin
      $fatal(1, "Canvas ping-pong tests failed with %0d issue(s).", failure_count);
    end
  end

endmodule
