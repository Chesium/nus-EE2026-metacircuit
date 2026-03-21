`timescale 1ns / 1ps

module CircuitCanvas_top #(
    parameter integer EnableDemoProducer = 1,
    parameter integer BgStepWaitCycles   = 0
) (
    input  wire        CLK100MHZ,
    input  wire [15:0] SW,
    output wire [15:0] LED,
    output wire [ 7:0] SEG,
    output wire [ 3:0] AN,
    input  wire        BTNC,
    input  wire        BTNU,
    input  wire        BTNL,
    input  wire        BTNR,
    input  wire        BTND,
    output wire [ 7:0] JC,
    output wire [ 3:0] VGARED,
    output wire [ 3:0] VGABLUE,
    output wire [ 3:0] VGAGREEN,
    output wire        HSYNC,
    output wire        VSYNC,
    inout              PS2CLK,
    inout              PS2DATA
);

  localparam integer CanvasWordWidth = 16;
  localparam integer CanvasWordCount = 256;
  localparam integer CanvasAddrWidth = 8;

  localparam integer BgStateInitClearA = 0;
  localparam integer BgStateInitClearB = 1;
  localparam integer BgStateWaitFlip = 2;
  localparam integer BgStateCopySetRead = 3;
  localparam integer BgStateCopyWaitA = 4;
  localparam integer BgStateCopyWaitB = 5;
  localparam integer BgStateCopyWrite = 6;
  localparam integer BgStateUpdateIdle = 7;
  localparam integer BgStateUpdateReadSet = 8;
  localparam integer BgStateUpdateReadWaitA = 9;
  localparam integer BgStateUpdateReadWaitB = 10;
  localparam integer BgStateUpdateReadResp = 11;

  localparam integer DemoCommandCount = 9;

  function [CanvasAddrWidth-1:0] DemoAddr;
    input [3:0] cmd_idx;
    begin
      case (cmd_idx)
        4'd0: DemoAddr = 8'd0;
        4'd1: DemoAddr = 8'd1;
        4'd2: DemoAddr = 8'd2;
        4'd3: DemoAddr = 8'd16;
        4'd4: DemoAddr = 8'd32;
        4'd5: DemoAddr = 8'd82;
        4'd6: DemoAddr = 8'd84;
        4'd7: DemoAddr = 8'd86;
        4'd8: DemoAddr = 8'd88;
        default: DemoAddr = 8'd0;
      endcase
    end
  endfunction

  function [CanvasWordWidth-1:0] DemoData;
    input [3:0] cmd_idx;
    begin
      case (cmd_idx)
        4'd0: DemoData = 16'b0000000_00_000000_1;
        4'd1: DemoData = 16'b0000000_00_000101_1;
        4'd2: DemoData = 16'b0000000_00_000110_1;
        4'd3: DemoData = 16'b0000000_11_001000_1;
        4'd4: DemoData = 16'b0000000_11_000111_1;
        4'd5: DemoData = 16'b0000000_00_000010_1;
        4'd6: DemoData = 16'b0000000_01_000010_1;
        4'd7: DemoData = 16'b0000000_10_000010_1;
        4'd8: DemoData = 16'b0000000_11_000010_1;
        default: DemoData = 16'd0;
      endcase
    end
  endfunction

  assign LED = 16'b1111_1111_1111_1111;
  assign SEG = 8'b0000_0000;
  assign AN  = 4'b0000;
  assign JC  = 8'b0000_0000;

  wire clk_pixel;
  wire video_on;
  reg [11:0] rgb;
  wire [11:0] x_pos;
  wire [11:0] y_pos;

  parameter integer Black = 12'b0000_0000_0000;
  parameter integer Red = 12'b1111_0000_0000;
  parameter integer Blue = 12'b0000_0000_1111;
  parameter integer Green = 12'b0000_1111_0000;
  parameter integer YellowishOrange = 12'b1111_1100_0000;
  parameter integer Pink = 12'b1111_0011_1100;

  ClockDivider #(
      .FREQ(25_000_000)
  ) clkdiv_inst_25MHz (
      .CLK100MHZ(CLK100MHZ),
      .clk_out  (clk_pixel)
  );

  VGAControl vga_ctrl_inst (
      .clk_pixel(clk_pixel),
      .reset(BTNC),
      .rgb(rgb),
      .hsync(HSYNC),
      .vsync(VSYNC),
      .video_on(video_on),
      .h_count_reg(x_pos),
      .v_count_reg(y_pos),
      .vgaRed(VGARED),
      .vgaGreen(VGAGREEN),
      .vgaBlue(VGABLUE)
  );

  wire [11:0] mouse_xpos;
  wire [11:0] mouse_ypos;
  wire [ 3:0] mouse_zpos;
  wire        mouse_left;
  wire        mouse_middle;
  wire        mouse_right;
  wire        mouse_new_event;
  reg  [11:0] mouse_set_value;
  reg         mouse_set_max_x;
  reg         mouse_set_max_y;

  MouseCtl mouse_ctrl_inst (
      .clk      (CLK100MHZ),
      .rst      (BTNC),
      .xpos     (mouse_xpos),
      .ypos     (mouse_ypos),
      .zpos     (mouse_zpos),
      .left     (mouse_left),
      .middle   (mouse_middle),
      .right    (mouse_right),
      .new_event(mouse_new_event),
      .value    (mouse_set_value),
      .setx     (1'b0),
      .sety     (1'b0),
      .setmax_x (mouse_set_max_x),
      .setmax_y (mouse_set_max_y),
      .ps2_clk  (PS2CLK),
      .ps2_data (PS2DATA)
  );

  wire mouse_display_enable;
  wire [3:0] mouse_r;
  wire [3:0] mouse_g;
  wire [3:0] mouse_b;
  wire [11:0] mouse_rgb;
  assign mouse_rgb = {mouse_r, mouse_g, mouse_b};

  MouseDisplay mouse_disp_inst (
      .pixel_clk               (clk_pixel),
      .xpos                    (mouse_xpos),
      .ypos                    (mouse_ypos),
      .hcount                  (x_pos),
      .vcount                  (y_pos),
      .enable_mouse_display_out(mouse_display_enable),
      .red_out                 (mouse_r),
      .green_out               (mouse_g),
      .blue_out                (mouse_b)
  );

  wire [CanvasAddrWidth-1:0] circuit_canvas_ram_render_addr;
  wire [CanvasWordWidth-1:0] canvas_ram_a_render_data;
  wire [CanvasWordWidth-1:0] canvas_ram_b_render_data;
  wire [CanvasWordWidth-1:0] circuit_canvas_ram_render_data;

  reg active_buf_sel_pix = 1'b0;
  reg active_buf_sel_bg = 1'b0;
  reg buffers_init_done = 1'b0;
  reg frame_prep_done = 1'b0;
  reg bg_overrun_flag = 1'b0;

  reg canvas_ram_a_bg_w_en = 1'b0;
  reg [CanvasAddrWidth-1:0] canvas_ram_a_bg_w_addr = 0;
  reg [CanvasAddrWidth-1:0] canvas_ram_a_bg_r_addr = 0;
  reg [CanvasWordWidth-1:0] canvas_ram_a_bg_d_in = 0;
  wire [CanvasWordWidth-1:0] canvas_ram_a_bg_d_out;

  reg canvas_ram_b_bg_w_en = 1'b0;
  reg [CanvasAddrWidth-1:0] canvas_ram_b_bg_w_addr = 0;
  reg [CanvasAddrWidth-1:0] canvas_ram_b_bg_r_addr = 0;
  reg [CanvasWordWidth-1:0] canvas_ram_b_bg_d_in = 0;
  wire [CanvasWordWidth-1:0] canvas_ram_b_bg_d_out;

  CanvasBufferRam #(
      .WordWidth(CanvasWordWidth),
      .WordCount(CanvasWordCount)
  ) canvas_ram_a_inst (
      .render_clk   (clk_pixel),
      .render_r_addr(circuit_canvas_ram_render_addr),
      .render_d_out (canvas_ram_a_render_data),
      .bg_clk       (CLK100MHZ),
      .bg_w_en      (canvas_ram_a_bg_w_en),
      .bg_w_addr    (canvas_ram_a_bg_w_addr),
      .bg_r_addr    (canvas_ram_a_bg_r_addr),
      .bg_d_in      (canvas_ram_a_bg_d_in),
      .bg_d_out     (canvas_ram_a_bg_d_out)
  );

  CanvasBufferRam #(
      .WordWidth(CanvasWordWidth),
      .WordCount(CanvasWordCount)
  ) canvas_ram_b_inst (
      .render_clk   (clk_pixel),
      .render_r_addr(circuit_canvas_ram_render_addr),
      .render_d_out (canvas_ram_b_render_data),
      .bg_clk       (CLK100MHZ),
      .bg_w_en      (canvas_ram_b_bg_w_en),
      .bg_w_addr    (canvas_ram_b_bg_w_addr),
      .bg_r_addr    (canvas_ram_b_bg_r_addr),
      .bg_d_in      (canvas_ram_b_bg_d_in),
      .bg_d_out     (canvas_ram_b_bg_d_out)
  );

  assign circuit_canvas_ram_render_data = active_buf_sel_pix ? canvas_ram_b_render_data
                                                             : canvas_ram_a_render_data;

  wire [11:0] circuit_canvas_rgb;
  wire circuit_canvas_rendered;

  CircuitCanvas circuit_canvas_inst (
      .clk_pixel(clk_pixel),
      .x_pos(x_pos),
      .y_pos(y_pos),
      .rgb(circuit_canvas_rgb),
      .rendered(circuit_canvas_rendered),
      .data_addr(circuit_canvas_ram_render_addr),
      .incoming_data(circuit_canvas_ram_render_data),
      .display_grid(1'b1),
      .mouse_x_pos(mouse_xpos),
      .mouse_y_pos(mouse_ypos),
      .mouse_left_click(mouse_left)
  );

  reg [31:0] mouse_init_cycles = 0;
  always @(posedge CLK100MHZ) begin
    if (BTNC) begin
      mouse_init_cycles <= 0;
      mouse_set_value   <= 12'h000;
      mouse_set_max_x   <= 1'b0;
      mouse_set_max_y   <= 1'b0;
    end else begin
      mouse_set_value <= 12'h000;
      mouse_set_max_x <= 1'b0;
      mouse_set_max_y <= 1'b0;

      if (mouse_init_cycles < 1000) begin
        mouse_init_cycles <= mouse_init_cycles + 1;
      end
      if (mouse_init_cycles == 1) begin
        mouse_set_max_x <= 1'b1;
        mouse_set_value <= 12'd639;
      end
      if (mouse_init_cycles == 2) begin
        mouse_set_max_y <= 1'b1;
        mouse_set_value <= 12'd479;
      end
    end
  end

  reg  vsync_prev = 1'b0;
  reg  frame_flip_toggle_pix = 1'b0;
  wire frame_flip_pulse_pix;
  assign frame_flip_pulse_pix = buffers_init_done && !vsync_prev && VSYNC;

  always @(posedge clk_pixel) begin
    if (BTNC) begin
      vsync_prev <= 1'b0;
      frame_flip_toggle_pix <= 1'b0;
      active_buf_sel_pix <= 1'b0;
    end else begin
      vsync_prev <= VSYNC;
      if (frame_flip_pulse_pix) begin
        active_buf_sel_pix <= ~active_buf_sel_pix;
        frame_flip_toggle_pix <= ~frame_flip_toggle_pix;
      end
    end
  end

  reg [1:0] frame_flip_toggle_bg_sync = 2'b00;
  reg frame_flip_toggle_bg_prev = 1'b0;
  wire frame_flip_pulse_bg;
  assign frame_flip_pulse_bg = frame_flip_toggle_bg_sync[1] ^ frame_flip_toggle_bg_prev;

  always @(posedge CLK100MHZ) begin
    if (BTNC) begin
      frame_flip_toggle_bg_sync <= 2'b00;
      frame_flip_toggle_bg_prev <= 1'b0;
    end else begin
      frame_flip_toggle_bg_sync <= {frame_flip_toggle_bg_sync[0], frame_flip_toggle_pix};
      frame_flip_toggle_bg_prev <= frame_flip_toggle_bg_sync[1];
    end
  end

  reg [3:0] bg_state = BgStateInitClearA;
  reg [CanvasAddrWidth-1:0] bg_init_addr = 0;
  reg [CanvasAddrWidth-1:0] bg_copy_addr = 0;
  reg [CanvasWordWidth-1:0] bg_copy_latched_data = 0;
  reg [CanvasWordWidth-1:0] bg_rsp_rdata = 0;
  reg bg_rsp_valid = 1'b0;
  reg [31:0] bg_step_wait_ctr = 0;
  reg frame_flip_pending_bg = 1'b0;

  reg demo_loaded = 1'b0;
  reg [3:0] demo_cmd_index = 0;

  wire bg_cmd_valid;
  reg bg_cmd_ready = 1'b0;
  wire bg_cmd_write;
  wire [CanvasAddrWidth-1:0] bg_cmd_addr;
  wire [CanvasWordWidth-1:0] bg_cmd_wdata;
  wire bg_cmd_stream_done;

  assign bg_cmd_valid = EnableDemoProducer && !demo_loaded && (demo_cmd_index < DemoCommandCount);
  assign bg_cmd_write = 1'b1;
  assign bg_cmd_addr = DemoAddr(demo_cmd_index);
  assign bg_cmd_wdata = DemoData(demo_cmd_index);
  assign bg_cmd_stream_done = !EnableDemoProducer || demo_loaded;

  always @(posedge CLK100MHZ) begin
    if (BTNC) begin
      active_buf_sel_bg <= 1'b0;
      buffers_init_done <= 1'b0;
      frame_prep_done <= 1'b0;
      bg_overrun_flag <= 1'b0;
      bg_state <= BgStateInitClearA;
      bg_init_addr <= 0;
      bg_copy_addr <= 0;
      bg_copy_latched_data <= 0;
      bg_rsp_rdata <= 0;
      bg_rsp_valid <= 1'b0;
      bg_step_wait_ctr <= 0;
      frame_flip_pending_bg <= 1'b0;
      bg_cmd_ready <= 1'b0;
      demo_loaded <= 1'b0;
      demo_cmd_index <= 0;

      canvas_ram_a_bg_w_en <= 1'b0;
      canvas_ram_a_bg_w_addr <= 0;
      canvas_ram_a_bg_r_addr <= 0;
      canvas_ram_a_bg_d_in <= 0;
      canvas_ram_b_bg_w_en <= 1'b0;
      canvas_ram_b_bg_w_addr <= 0;
      canvas_ram_b_bg_r_addr <= 0;
      canvas_ram_b_bg_d_in <= 0;
    end else begin
      canvas_ram_a_bg_w_en <= 1'b0;
      canvas_ram_b_bg_w_en <= 1'b0;
      bg_rsp_valid <= 1'b0;
      bg_cmd_ready <= 1'b0;
      frame_flip_pending_bg <= frame_flip_pending_bg || frame_flip_pulse_bg;

      if (buffers_init_done && (frame_flip_pending_bg || frame_flip_pulse_bg)) begin
        frame_flip_pending_bg <= 1'b0;
        if (bg_state != BgStateWaitFlip) begin
          bg_overrun_flag <= 1'b1;
        end
        active_buf_sel_bg <= ~active_buf_sel_bg;
        frame_prep_done <= 1'b0;
        bg_copy_addr <= 0;
        bg_state <= BgStateCopySetRead;
        bg_step_wait_ctr <= BgStepWaitCycles;
      end else if (bg_step_wait_ctr != 0) begin
        bg_step_wait_ctr <= bg_step_wait_ctr - 1;
      end else begin
        case (bg_state)
          BgStateInitClearA: begin
            canvas_ram_a_bg_w_en   <= 1'b1;
            canvas_ram_a_bg_w_addr <= bg_init_addr;
            canvas_ram_a_bg_d_in   <= {CanvasWordWidth{1'b0}};
            if (bg_init_addr == CanvasWordCount - 1) begin
              bg_init_addr <= 0;
              bg_state <= BgStateInitClearB;
            end else begin
              bg_init_addr <= bg_init_addr + 1;
            end
            bg_step_wait_ctr <= BgStepWaitCycles;
          end

          BgStateInitClearB: begin
            canvas_ram_b_bg_w_en   <= 1'b1;
            canvas_ram_b_bg_w_addr <= bg_init_addr;
            canvas_ram_b_bg_d_in   <= {CanvasWordWidth{1'b0}};
            if (bg_init_addr == CanvasWordCount - 1) begin
              bg_init_addr <= 0;
              buffers_init_done <= 1'b1;
              frame_prep_done <= 1'b1;
              bg_state <= BgStateWaitFlip;
            end else begin
              bg_init_addr <= bg_init_addr + 1;
            end
            bg_step_wait_ctr <= BgStepWaitCycles;
          end

          BgStateWaitFlip: begin
            frame_prep_done <= 1'b1;
          end

          BgStateCopySetRead: begin
            if (active_buf_sel_bg) begin
              canvas_ram_b_bg_r_addr <= bg_copy_addr;
            end else begin
              canvas_ram_a_bg_r_addr <= bg_copy_addr;
            end
            bg_state <= BgStateCopyWaitA;
            bg_step_wait_ctr <= BgStepWaitCycles;
          end

          BgStateCopyWaitA: begin
            bg_state <= BgStateCopyWaitB;
            bg_step_wait_ctr <= BgStepWaitCycles;
          end

          BgStateCopyWaitB: begin
            bg_copy_latched_data <= active_buf_sel_bg ? canvas_ram_b_bg_d_out
                                                        : canvas_ram_a_bg_d_out;
            bg_state <= BgStateCopyWrite;
            bg_step_wait_ctr <= BgStepWaitCycles;
          end

          BgStateCopyWrite: begin
            if (active_buf_sel_bg) begin
              canvas_ram_a_bg_w_en   <= 1'b1;
              canvas_ram_a_bg_w_addr <= bg_copy_addr;
              canvas_ram_a_bg_d_in   <= bg_copy_latched_data;
            end else begin
              canvas_ram_b_bg_w_en   <= 1'b1;
              canvas_ram_b_bg_w_addr <= bg_copy_addr;
              canvas_ram_b_bg_d_in   <= bg_copy_latched_data;
            end

            if (bg_copy_addr == CanvasWordCount - 1) begin
              bg_state <= BgStateUpdateIdle;
            end else begin
              bg_copy_addr <= bg_copy_addr + 1;
              bg_state <= BgStateCopySetRead;
            end
            bg_step_wait_ctr <= BgStepWaitCycles;
          end

          BgStateUpdateIdle: begin
            bg_cmd_ready <= 1'b1;
            if (bg_cmd_valid) begin
              if (bg_cmd_write) begin
                if (active_buf_sel_bg) begin
                  canvas_ram_a_bg_w_en   <= 1'b1;
                  canvas_ram_a_bg_w_addr <= bg_cmd_addr;
                  canvas_ram_a_bg_d_in   <= bg_cmd_wdata;
                end else begin
                  canvas_ram_b_bg_w_en   <= 1'b1;
                  canvas_ram_b_bg_w_addr <= bg_cmd_addr;
                  canvas_ram_b_bg_d_in   <= bg_cmd_wdata;
                end

                if (demo_cmd_index == DemoCommandCount - 1) begin
                  demo_loaded <= 1'b1;
                end else begin
                  demo_cmd_index <= demo_cmd_index + 1;
                end
                bg_step_wait_ctr <= BgStepWaitCycles;
              end else begin
                if (active_buf_sel_bg) begin
                  canvas_ram_a_bg_r_addr <= bg_cmd_addr;
                end else begin
                  canvas_ram_b_bg_r_addr <= bg_cmd_addr;
                end
                bg_state <= BgStateUpdateReadSet;
                bg_step_wait_ctr <= BgStepWaitCycles;
              end
            end else if (bg_cmd_stream_done) begin
              frame_prep_done <= 1'b1;
              bg_state <= BgStateWaitFlip;
            end
          end

          BgStateUpdateReadSet: begin
            bg_state <= BgStateUpdateReadWaitA;
            bg_step_wait_ctr <= BgStepWaitCycles;
          end

          BgStateUpdateReadWaitA: begin
            bg_state <= BgStateUpdateReadWaitB;
            bg_step_wait_ctr <= BgStepWaitCycles;
          end

          BgStateUpdateReadWaitB: begin
            bg_rsp_rdata <= active_buf_sel_bg ? canvas_ram_a_bg_d_out : canvas_ram_b_bg_d_out;
            bg_state <= BgStateUpdateReadResp;
            bg_step_wait_ctr <= BgStepWaitCycles;
          end

          BgStateUpdateReadResp: begin
            bg_rsp_valid <= 1'b1;
            bg_state <= BgStateUpdateIdle;
            bg_step_wait_ctr <= BgStepWaitCycles;
          end

          default: begin
            bg_state <= BgStateInitClearA;
          end
        endcase
      end
    end
  end

  always @(posedge clk_pixel) begin
    if (!video_on) begin
      rgb <= Black;
    end else begin
      if (mouse_display_enable) begin
        rgb <= mouse_rgb;
      end else begin
        if (SW[0]) begin
          if (x_pos < 640 / 3) begin
            rgb <= Blue;
          end else if (x_pos < (640 * 2) / 3) begin
            rgb <= YellowishOrange;
          end else begin
            rgb <= Red;
          end
        end else if (SW[1]) begin
          if (y_pos < 480 / 3) begin
            rgb <= Black;
          end else if (y_pos < (480 * 2) / 3) begin
            rgb <= Red;
          end else begin
            rgb <= YellowishOrange;
          end
        end else begin
          if (buffers_init_done && circuit_canvas_rendered) rgb <= circuit_canvas_rgb;
          else rgb <= Pink;
        end
      end
    end
  end

endmodule
