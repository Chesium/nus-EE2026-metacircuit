`timescale 1ns / 1ps

module MetaCircuit_top (
    input  wire        CLK100MHZ,
    input  wire [15:0] SW,
    output wire [15:0] LED,
    output wire [7:0]  SEG,
    output wire [3:0]  AN,
    input  wire        BTNC,
    input  wire        BTNU,
    input  wire        BTNL,
    input  wire        BTNR,
    input  wire        BTND,
    output wire [7:0]  JC,
    output wire [3:0]  VGARED,
    output wire [3:0]  VGABLUE,
    output wire [3:0]  VGAGREEN,
    output wire        HSYNC,
    output wire        VSYNC,
    inout              PS2CLK,
    inout              PS2DATA
);

  import CellStorePkg::*;
  import ComponentStorePkg::*;
  import MetaCommandPkg::*;

  localparam integer CANVAS_X0 = 64;
  localparam integer CANVAS_Y0 = 64;
  localparam integer CANVAS_W = 420;
  localparam integer CANVAS_H = 288;

  typedef enum logic [4:0] {
    SYS_INIT_CLEAR_A,
    SYS_INIT_CLEAR_B,
    SYS_INIT_CLEAR_COMP,
    SYS_WAIT_FLIP,
    SYS_COPY_SET_READ,
    SYS_COPY_WAIT_A,
    SYS_COPY_WAIT_B,
    SYS_COPY_WRITE,
    SYS_SELECT_SET_READ,
    SYS_SELECT_WAIT_A,
    SYS_SELECT_WAIT_B,
    SYS_SELECT_EVAL,
    SYS_EXEC_START,
    SYS_EXEC_RUN,
    SYS_PROJECT_START,
    SYS_PROJECT_RUN
  } sys_state_t;

  wire clk_pixel;
  wire video_on;
  wire [11:0] x_pos;
  wire [11:0] y_pos;
  reg  [11:0] rgb;

  reg [11:0] mouse_set_value;
  reg        mouse_set_max_x;
  reg        mouse_set_max_y;
  reg [31:0] mouse_init_cycles;

  wire [11:0] mouse_xpos;
  wire [11:0] mouse_ypos;
  wire [3:0]  mouse_zpos;
  wire        mouse_left;
  wire        mouse_middle;
  wire        mouse_right;
  wire        mouse_new_event;

  wire        mouse_display_enable;
  wire [3:0]  mouse_r;
  wire [3:0]  mouse_g;
  wire [3:0]  mouse_b;
  wire [11:0] mouse_rgb;
  assign mouse_rgb = {mouse_r, mouse_g, mouse_b};

  (* ASYNC_REG = "TRUE" *) reg [11:0] mouse_xpos_pix_sync0;
  (* ASYNC_REG = "TRUE" *) reg [11:0] mouse_xpos_pix_sync1;
  (* ASYNC_REG = "TRUE" *) reg [11:0] mouse_ypos_pix_sync0;
  (* ASYNC_REG = "TRUE" *) reg [11:0] mouse_ypos_pix_sync1;
  (* ASYNC_REG = "TRUE" *) reg        mouse_left_pix_sync0;
  (* ASYNC_REG = "TRUE" *) reg        mouse_left_pix_sync1;
  (* ASYNC_REG = "TRUE" *) reg        mouse_middle_pix_sync0;
  (* ASYNC_REG = "TRUE" *) reg        mouse_middle_pix_sync1;
  (* ASYNC_REG = "TRUE" *) reg [39:0] selected_comp_data_pix_sync0;
  (* ASYNC_REG = "TRUE" *) reg [39:0] selected_comp_data_pix_sync1;
  (* ASYNC_REG = "TRUE" *) reg        has_selection_pix_sync0;
  (* ASYNC_REG = "TRUE" *) reg        has_selection_pix_sync1;

  wire [11:0] canvas_rgb;
  wire        canvas_rendered;
  wire signed [12:0] canvas_grid_pos_x;
  wire signed [12:0] canvas_grid_pos_y;

  wire [11:0] prop_panel_rgb;
  wire        prop_panel_rendered;

  reg render_bank_sel_pix;
  reg render_bank_sel_bg_sync0;
  reg render_bank_sel_bg_sync1;
  reg render_bank_sel_bg_prev;
  wire frame_flip_pulse_bg;

  reg vsync_prev;
  wire frame_flip_pulse_pix;

  reg signed [12:0] frame_grid_pos_x_pix;
  reg signed [12:0] frame_grid_pos_y_pix;
  reg signed [12:0] frame_grid_pos_x_bg_sync0;
  reg signed [12:0] frame_grid_pos_x_bg_sync1;
  reg signed [12:0] frame_grid_pos_y_bg_sync0;
  reg signed [12:0] frame_grid_pos_y_bg_sync1;

  wire bg_bank_is_a = render_bank_sel_bg_sync1;

  reg        cell_ram_a_sys_w_en;
  reg [9:0]  cell_ram_a_sys_w_addr;
  reg [9:0]  cell_ram_a_sys_r_addr;
  reg [15:0] cell_ram_a_sys_d_in;
  wire [15:0] cell_ram_a_sys_d_out;
  wire [15:0] cell_ram_a_render_d_out;

  reg        cell_ram_b_sys_w_en;
  reg [9:0]  cell_ram_b_sys_w_addr;
  reg [9:0]  cell_ram_b_sys_r_addr;
  reg [15:0] cell_ram_b_sys_d_in;
  wire [15:0] cell_ram_b_sys_d_out;
  wire [15:0] cell_ram_b_render_d_out;

  wire [9:0] render_cell_addr;
  wire [15:0] render_cell_word;
  wire [15:0] render_legacy_word;

  reg        comp_store_w_en;
  reg [5:0]  comp_store_w_addr;
  reg [5:0]  comp_store_r_addr;
  reg [39:0] comp_store_d_in;
  wire [39:0] comp_store_d_out;

  wire [3:0] mode_select;

  wire interaction_cmd_valid;
  wire [63:0] interaction_cmd_payload;
  wire interaction_frame_done;
  wire interaction_frame_drop_flag;

  reg interaction_cmd_pending;
  reg [63:0] interaction_cmd_pending_payload;

  wire property_cmd_valid;
  wire [63:0] property_cmd_payload;
  reg property_cmd_pending;
  reg [63:0] property_cmd_pending_payload;

  wire arb_cmd_valid;
  wire [63:0] arb_cmd_payload;

  reg has_selection;
  reg [5:0] selected_comp_idx;
  reg [39:0] selected_comp_data;

  reg executor_start;
  wire executor_busy;
  wire executor_done;
  wire exec_cell_req_valid;
  wire exec_cell_req_write;
  wire [9:0] exec_cell_req_addr;
  wire [15:0] exec_cell_req_wdata;
  reg exec_cell_rsp_valid;
  reg [15:0] exec_cell_rsp_rdata;
  wire exec_comp_req_valid;
  wire exec_comp_req_write;
  wire [5:0] exec_comp_req_addr;
  wire [39:0] exec_comp_req_wdata;
  reg exec_comp_rsp_valid;
  reg [39:0] exec_comp_rsp_rdata;

  reg projector_start;
  wire projector_busy;
  wire projector_done;
  wire proj_cell_req_valid;
  wire proj_cell_req_write;
  wire [9:0] proj_cell_req_addr;
  wire [15:0] proj_cell_req_wdata;
  reg proj_cell_rsp_valid;
  reg [15:0] proj_cell_rsp_rdata;
  wire proj_comp_req_valid;
  wire proj_comp_req_write;
  wire [5:0] proj_comp_req_addr;
  wire [39:0] proj_comp_req_wdata;
  reg proj_comp_rsp_valid;
  reg [39:0] proj_comp_rsp_rdata;

  reg [15:0] sys_copy_latched;
  reg [9:0]  sys_cell_index;
  reg [5:0]  sys_comp_index;
  reg [15:0] select_cell_latched;

  reg [1:0]  cell_read_actor_d0;
  reg [1:0]  cell_read_actor_d1;
  reg [1:0]  comp_read_actor_d0;
  reg [1:0]  comp_read_actor_d1;
  localparam [1:0] ACT_NONE = 2'd0;
  localparam [1:0] ACT_EXEC = 2'd1;
  localparam [1:0] ACT_PROJ = 2'd2;

  reg bg_overrun_flag;
  reg system_busy_on_flip;

  sys_state_t sys_state;

  assign SEG = 8'hFF;
  assign AN = 4'hF;
  assign JC = 8'h00;
  assign LED = {
    2'b00,
    mode_select,
    bg_overrun_flag,
    interaction_frame_drop_flag,
    property_cmd_pending,
    interaction_cmd_pending,
    has_selection,
    selected_comp_idx
  };

  ClockDivider #(
      .FREQ(25_000_000)
  ) clkdiv_pixel_inst (
      .CLK100MHZ(CLK100MHZ),
      .clk_out(clk_pixel)
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

  MouseCtl mouse_ctrl_inst (
      .clk(CLK100MHZ),
      .rst(BTNC),
      .xpos(mouse_xpos),
      .ypos(mouse_ypos),
      .zpos(mouse_zpos),
      .left(mouse_left),
      .middle(mouse_middle),
      .right(mouse_right),
      .new_event(mouse_new_event),
      .value(mouse_set_value),
      .setx(1'b0),
      .sety(1'b0),
      .setmax_x(mouse_set_max_x),
      .setmax_y(mouse_set_max_y),
      .ps2_clk(PS2CLK),
      .ps2_data(PS2DATA)
  );

  MouseDisplay mouse_disp_inst (
      .pixel_clk(clk_pixel),
      .xpos(mouse_xpos_pix_sync1),
      .ypos(mouse_ypos_pix_sync1),
      .mouse_left(mouse_left_pix_sync1),
      .hcount(x_pos),
      .vcount(y_pos),
      .enable_mouse_display_out(mouse_display_enable),
      .red_out(mouse_r),
      .green_out(mouse_g),
      .blue_out(mouse_b)
  );

  CellStoreBufferRam #(
      .WordWidth(CELL_WORD_WIDTH),
      .WordCount(CELL_COUNT)
  ) cell_ram_a_inst (
      .render_clk(clk_pixel),
      .render_r_addr(render_cell_addr),
      .render_d_out(cell_ram_a_render_d_out),
      .sys_clk(CLK100MHZ),
      .sys_w_en(cell_ram_a_sys_w_en),
      .sys_w_addr(cell_ram_a_sys_w_addr),
      .sys_r_addr(cell_ram_a_sys_r_addr),
      .sys_d_in(cell_ram_a_sys_d_in),
      .sys_d_out(cell_ram_a_sys_d_out)
  );

  CellStoreBufferRam #(
      .WordWidth(CELL_WORD_WIDTH),
      .WordCount(CELL_COUNT)
  ) cell_ram_b_inst (
      .render_clk(clk_pixel),
      .render_r_addr(render_cell_addr),
      .render_d_out(cell_ram_b_render_d_out),
      .sys_clk(CLK100MHZ),
      .sys_w_en(cell_ram_b_sys_w_en),
      .sys_w_addr(cell_ram_b_sys_w_addr),
      .sys_r_addr(cell_ram_b_sys_r_addr),
      .sys_d_in(cell_ram_b_sys_d_in),
      .sys_d_out(cell_ram_b_sys_d_out)
  );

  assign render_cell_word = render_bank_sel_pix ? cell_ram_b_render_d_out : cell_ram_a_render_d_out;
  assign render_legacy_word = {6'd0, cell_meta(render_cell_word), cell_rot(render_cell_word), cell_sprite(render_cell_word), cell_valid(render_cell_word)};

  ComponentStoreRam #(
      .WordWidth(COMPONENT_WORD_WIDTH),
      .WordCount(COMPONENT_COUNT)
  ) comp_store_inst (
      .clk(CLK100MHZ),
      .w_en(comp_store_w_en),
      .w_addr(comp_store_w_addr),
      .r_addr(comp_store_r_addr),
      .d_in(comp_store_d_in),
      .d_out(comp_store_d_out)
  );

  ToolbarController toolbar_ctrl_inst (
      .clk(CLK100MHZ),
      .rst(BTNC),
      .sw(SW),
      .mode_select(mode_select)
  );

  InteractionCommandController #(
      .CanvasPosX(CANVAS_X0),
      .CanvasPosY(CANVAS_Y0),
      .CanvasWidth(CANVAS_W),
      .CanvasHeight(CANVAS_H),
      .CellSize(CELL_SIZE),
      .GridWidth(GRID_WIDTH),
      .GridHeight(GRID_HEIGHT)
  ) interaction_ctrl_inst (
      .clk(CLK100MHZ),
      .reset(BTNC),
      .frame_start_pulse(frame_flip_pulse_bg),
      .mode_select(mode_select),
      .mouse_x(mouse_xpos),
      .mouse_y(mouse_ypos),
      .mouse_left(mouse_left),
      .mouse_middle(mouse_middle),
      .mouse_right(mouse_right),
      .grid_pos_x(frame_grid_pos_x_bg_sync1),
      .grid_pos_y(frame_grid_pos_y_bg_sync1),
      .cmd_valid(interaction_cmd_valid),
      .cmd_payload(interaction_cmd_payload),
      .frame_done(interaction_frame_done),
      .frame_drop_flag(interaction_frame_drop_flag)
  );

  ComponentPropertyPanel #(
      .PANEL_X(0),
      .PANEL_Y(0),
      .PANEL_W(640),
      .PANEL_H(64)
  ) prop_panel_inst (
      .clk_sys(CLK100MHZ),
      .rst(BTNC),
      .clk_pixel(clk_pixel),
      .hcount(x_pos),
      .vcount(y_pos),
      .video_on(video_on),
      .has_selection_sys(has_selection),
      .selected_comp_idx_sys(selected_comp_idx),
      .selected_comp_data_sys(selected_comp_data),
      .has_selection_pix(has_selection_pix_sync1),
      .selected_comp_data_pix(selected_comp_data_pix_sync1),
      .btnU(BTNU),
      .btnD(BTND),
      .btnL(BTNL),
      .btnR(BTNR),
      .btnC(BTNC),
      .cmd_valid(property_cmd_valid),
      .cmd_payload(property_cmd_payload),
      .panel_rendered(prop_panel_rendered),
      .panel_rgb(prop_panel_rgb)
  );

  CommandArbiter arbiter_inst (
      .interaction_cmd_valid(interaction_cmd_pending),
      .interaction_cmd_payload(interaction_cmd_pending_payload),
      .property_cmd_valid(property_cmd_pending),
      .property_cmd_payload(property_cmd_pending_payload),
      .arb_cmd_valid(arb_cmd_valid),
      .arb_cmd_payload(arb_cmd_payload)
  );

  CommandExecutor executor_inst (
      .clk(CLK100MHZ),
      .rst(BTNC),
      .start(executor_start),
      .cmd_valid(arb_cmd_valid),
      .cmd_payload(arb_cmd_payload),
      .busy(executor_busy),
      .done(executor_done),
      .cell_req_valid(exec_cell_req_valid),
      .cell_req_write(exec_cell_req_write),
      .cell_req_addr(exec_cell_req_addr),
      .cell_req_wdata(exec_cell_req_wdata),
      .cell_rsp_valid(exec_cell_rsp_valid),
      .cell_rsp_rdata(exec_cell_rsp_rdata),
      .comp_req_valid(exec_comp_req_valid),
      .comp_req_write(exec_comp_req_write),
      .comp_req_addr(exec_comp_req_addr),
      .comp_req_wdata(exec_comp_req_wdata),
      .comp_rsp_valid(exec_comp_rsp_valid),
      .comp_rsp_rdata(exec_comp_rsp_rdata)
  );

  ComponentProjector projector_inst (
      .clk(CLK100MHZ),
      .rst(BTNC),
      .start(projector_start),
      .busy(projector_busy),
      .done(projector_done),
      .cell_req_valid(proj_cell_req_valid),
      .cell_req_write(proj_cell_req_write),
      .cell_req_addr(proj_cell_req_addr),
      .cell_req_wdata(proj_cell_req_wdata),
      .cell_rsp_valid(proj_cell_rsp_valid),
      .cell_rsp_rdata(proj_cell_rsp_rdata),
      .comp_req_valid(proj_comp_req_valid),
      .comp_req_write(proj_comp_req_write),
      .comp_req_addr(proj_comp_req_addr),
      .comp_req_wdata(proj_comp_req_wdata),
      .comp_rsp_valid(proj_comp_rsp_valid),
      .comp_rsp_rdata(proj_comp_rsp_rdata)
  );

  CircuitCanvas #(
      .CanvasPosX(CANVAS_X0),
      .CanvasPosY(CANVAS_Y0),
      .CanvasWidth(CANVAS_W),
      .CanvasHeight(CANVAS_H),
      .CellSize(CELL_SIZE),
      .GridWidth(GRID_WIDTH),
      .GridHeight(GRID_HEIGHT)
  ) canvas_inst (
      .clk_pixel(clk_pixel),
      .x_pos(x_pos),
      .y_pos(y_pos),
      .anim_phase(5'd0),
      .rgb(canvas_rgb),
      .rendered(canvas_rendered),
      .mouse_x_pos(mouse_xpos_pix_sync1),
      .mouse_y_pos(mouse_ypos_pix_sync1),
      .data_addr(render_cell_addr),
      .incoming_data(render_legacy_word),
      .display_grid(1'b1),
      .mouse_left_click(mouse_middle_pix_sync1),
      .grid_pos_x_out(canvas_grid_pos_x),
      .grid_pos_y_out(canvas_grid_pos_y)
  );

  assign frame_flip_pulse_pix = !vsync_prev && VSYNC;
  assign frame_flip_pulse_bg = render_bank_sel_bg_sync1 ^ render_bank_sel_bg_prev;

  always @(posedge CLK100MHZ) begin
    if (BTNC) begin
      mouse_set_value <= 12'd0;
      mouse_set_max_x <= 1'b0;
      mouse_set_max_y <= 1'b0;
      mouse_init_cycles <= 32'd0;
    end else begin
      mouse_set_value <= 12'd0;
      mouse_set_max_x <= 1'b0;
      mouse_set_max_y <= 1'b0;
      if (mouse_init_cycles < 32'd1000) begin
        mouse_init_cycles <= mouse_init_cycles + 1'b1;
      end
      if (mouse_init_cycles == 32'd1) begin
        mouse_set_max_x <= 1'b1;
        mouse_set_value <= 12'd639;
      end
      if (mouse_init_cycles == 32'd2) begin
        mouse_set_max_y <= 1'b1;
        mouse_set_value <= 12'd479;
      end
    end
  end

  always @(posedge clk_pixel) begin
    if (BTNC) begin
      vsync_prev <= 1'b0;
      render_bank_sel_pix <= 1'b0;
      frame_grid_pos_x_pix <= 13'sd0;
      frame_grid_pos_y_pix <= 13'sd0;
      mouse_xpos_pix_sync0 <= 12'd0;
      mouse_xpos_pix_sync1 <= 12'd0;
      mouse_ypos_pix_sync0 <= 12'd0;
      mouse_ypos_pix_sync1 <= 12'd0;
      mouse_left_pix_sync0 <= 1'b0;
      mouse_left_pix_sync1 <= 1'b0;
      mouse_middle_pix_sync0 <= 1'b0;
      mouse_middle_pix_sync1 <= 1'b0;
      selected_comp_data_pix_sync0 <= 40'd0;
      selected_comp_data_pix_sync1 <= 40'd0;
      has_selection_pix_sync0 <= 1'b0;
      has_selection_pix_sync1 <= 1'b0;
    end else begin
      vsync_prev <= VSYNC;
      mouse_xpos_pix_sync0 <= mouse_xpos;
      mouse_xpos_pix_sync1 <= mouse_xpos_pix_sync0;
      mouse_ypos_pix_sync0 <= mouse_ypos;
      mouse_ypos_pix_sync1 <= mouse_ypos_pix_sync0;
      mouse_left_pix_sync0 <= mouse_left;
      mouse_left_pix_sync1 <= mouse_left_pix_sync0;
      mouse_middle_pix_sync0 <= mouse_middle;
      mouse_middle_pix_sync1 <= mouse_middle_pix_sync0;
      selected_comp_data_pix_sync0 <= selected_comp_data;
      selected_comp_data_pix_sync1 <= selected_comp_data_pix_sync0;
      has_selection_pix_sync0 <= has_selection;
      has_selection_pix_sync1 <= has_selection_pix_sync0;
      if (frame_flip_pulse_pix) begin
        render_bank_sel_pix <= ~render_bank_sel_pix;
        frame_grid_pos_x_pix <= canvas_grid_pos_x;
        frame_grid_pos_y_pix <= canvas_grid_pos_y;
      end
    end
  end

  always @(posedge CLK100MHZ) begin
    if (BTNC) begin
      render_bank_sel_bg_sync0 <= 1'b0;
      render_bank_sel_bg_sync1 <= 1'b0;
      render_bank_sel_bg_prev <= 1'b0;
      frame_grid_pos_x_bg_sync0 <= 13'sd0;
      frame_grid_pos_x_bg_sync1 <= 13'sd0;
      frame_grid_pos_y_bg_sync0 <= 13'sd0;
      frame_grid_pos_y_bg_sync1 <= 13'sd0;
    end else begin
      render_bank_sel_bg_sync0 <= render_bank_sel_pix;
      render_bank_sel_bg_sync1 <= render_bank_sel_bg_sync0;
      render_bank_sel_bg_prev <= render_bank_sel_bg_sync1;
      frame_grid_pos_x_bg_sync0 <= frame_grid_pos_x_pix;
      frame_grid_pos_x_bg_sync1 <= frame_grid_pos_x_bg_sync0;
      frame_grid_pos_y_bg_sync0 <= frame_grid_pos_y_pix;
      frame_grid_pos_y_bg_sync1 <= frame_grid_pos_y_bg_sync0;
    end
  end

  always @(posedge CLK100MHZ) begin
    if (BTNC) begin
      interaction_cmd_pending <= 1'b0;
      interaction_cmd_pending_payload <= '0;
      property_cmd_pending <= 1'b0;
      property_cmd_pending_payload <= '0;
    end else begin
      if (interaction_cmd_valid) begin
        interaction_cmd_pending <= 1'b1;
        interaction_cmd_pending_payload <= interaction_cmd_payload;
      end
      if (property_cmd_valid) begin
        property_cmd_pending <= 1'b1;
        property_cmd_pending_payload <= property_cmd_payload;
      end
      if (sys_state == SYS_EXEC_START && arb_cmd_valid) begin
        if (property_cmd_pending) begin
          property_cmd_pending <= 1'b0;
        end else if (interaction_cmd_pending) begin
          interaction_cmd_pending <= 1'b0;
        end
      end
      if (sys_state == SYS_SELECT_EVAL && interaction_cmd_pending &&
          (command_kind(interaction_cmd_pending_payload) == CMD_SELECT_TARGET)) begin
        interaction_cmd_pending <= 1'b0;
      end
    end
  end

  always @(posedge CLK100MHZ) begin
    if (BTNC) begin
      cell_read_actor_d0 <= ACT_NONE;
      cell_read_actor_d1 <= ACT_NONE;
      comp_read_actor_d0 <= ACT_NONE;
      comp_read_actor_d1 <= ACT_NONE;
      exec_cell_rsp_valid <= 1'b0;
      exec_cell_rsp_rdata <= 16'd0;
      proj_cell_rsp_valid <= 1'b0;
      proj_cell_rsp_rdata <= 16'd0;
      exec_comp_rsp_valid <= 1'b0;
      exec_comp_rsp_rdata <= 40'd0;
      proj_comp_rsp_valid <= 1'b0;
      proj_comp_rsp_rdata <= 40'd0;
    end else begin
      exec_cell_rsp_valid <= 1'b0;
      proj_cell_rsp_valid <= 1'b0;
      exec_comp_rsp_valid <= 1'b0;
      proj_comp_rsp_valid <= 1'b0;

      cell_read_actor_d1 <= cell_read_actor_d0;
      cell_read_actor_d0 <= ACT_NONE;
      comp_read_actor_d1 <= comp_read_actor_d0;
      comp_read_actor_d0 <= ACT_NONE;

      if (sys_state == SYS_EXEC_RUN && exec_cell_req_valid && !exec_cell_req_write) begin
        cell_read_actor_d0 <= ACT_EXEC;
      end else if (sys_state == SYS_PROJECT_RUN && proj_cell_req_valid && !proj_cell_req_write) begin
        cell_read_actor_d0 <= ACT_PROJ;
      end

      if (sys_state == SYS_EXEC_RUN && exec_comp_req_valid && !exec_comp_req_write) begin
        comp_read_actor_d0 <= ACT_EXEC;
      end else if (sys_state == SYS_PROJECT_RUN && proj_comp_req_valid && !proj_comp_req_write) begin
        comp_read_actor_d0 <= ACT_PROJ;
      end

      if (cell_read_actor_d1 == ACT_EXEC) begin
        exec_cell_rsp_valid <= 1'b1;
        exec_cell_rsp_rdata <= bg_bank_is_a ? cell_ram_a_sys_d_out : cell_ram_b_sys_d_out;
      end else if (cell_read_actor_d1 == ACT_PROJ) begin
        proj_cell_rsp_valid <= 1'b1;
        proj_cell_rsp_rdata <= bg_bank_is_a ? cell_ram_a_sys_d_out : cell_ram_b_sys_d_out;
      end

      if (comp_read_actor_d1 == ACT_EXEC) begin
        exec_comp_rsp_valid <= 1'b1;
        exec_comp_rsp_rdata <= comp_store_d_out;
      end else if (comp_read_actor_d1 == ACT_PROJ) begin
        proj_comp_rsp_valid <= 1'b1;
        proj_comp_rsp_rdata <= comp_store_d_out;
      end
    end
  end

  always @(posedge CLK100MHZ) begin
    if (BTNC) begin
      sys_state <= SYS_INIT_CLEAR_A;
      sys_cell_index <= 10'd0;
      sys_comp_index <= 6'd0;
      sys_copy_latched <= 16'd0;
      select_cell_latched <= 16'd0;
      has_selection <= 1'b0;
      selected_comp_idx <= 6'd0;
      selected_comp_data <= 40'd0;
      executor_start <= 1'b0;
      projector_start <= 1'b0;
      bg_overrun_flag <= 1'b0;
      system_busy_on_flip <= 1'b0;
      cell_ram_a_sys_w_en <= 1'b0;
      cell_ram_a_sys_w_addr <= 10'd0;
      cell_ram_a_sys_r_addr <= 10'd0;
      cell_ram_a_sys_d_in <= 16'd0;
      cell_ram_b_sys_w_en <= 1'b0;
      cell_ram_b_sys_w_addr <= 10'd0;
      cell_ram_b_sys_r_addr <= 10'd0;
      cell_ram_b_sys_d_in <= 16'd0;
      comp_store_w_en <= 1'b0;
      comp_store_w_addr <= 6'd0;
      comp_store_r_addr <= 6'd0;
      comp_store_d_in <= 40'd0;
    end else begin
      cell_ram_a_sys_w_en <= 1'b0;
      cell_ram_b_sys_w_en <= 1'b0;
      comp_store_w_en <= 1'b0;
      executor_start <= 1'b0;
      projector_start <= 1'b0;

      if (frame_flip_pulse_bg && (sys_state != SYS_WAIT_FLIP)) begin
        bg_overrun_flag <= 1'b1;
      end

      case (sys_state)
        SYS_INIT_CLEAR_A: begin
          cell_ram_a_sys_w_en <= 1'b1;
          cell_ram_a_sys_w_addr <= sys_cell_index;
          cell_ram_a_sys_d_in <= empty_cell();
          if (sys_cell_index == CELL_COUNT - 1) begin
            sys_cell_index <= 10'd0;
            sys_state <= SYS_INIT_CLEAR_B;
          end else begin
            sys_cell_index <= sys_cell_index + 1'b1;
          end
        end

        SYS_INIT_CLEAR_B: begin
          cell_ram_b_sys_w_en <= 1'b1;
          cell_ram_b_sys_w_addr <= sys_cell_index;
          cell_ram_b_sys_d_in <= empty_cell();
          if (sys_cell_index == CELL_COUNT - 1) begin
            sys_comp_index <= 6'd0;
            sys_state <= SYS_INIT_CLEAR_COMP;
          end else begin
            sys_cell_index <= sys_cell_index + 1'b1;
          end
        end

        SYS_INIT_CLEAR_COMP: begin
          comp_store_w_en <= 1'b1;
          comp_store_w_addr <= sys_comp_index;
          comp_store_d_in <= empty_component();
          if (sys_comp_index == COMPONENT_COUNT - 1) begin
            sys_state <= SYS_WAIT_FLIP;
          end else begin
            sys_comp_index <= sys_comp_index + 1'b1;
          end
        end

        SYS_WAIT_FLIP: begin
          if (frame_flip_pulse_bg) begin
            sys_cell_index <= 10'd0;
            sys_state <= SYS_COPY_SET_READ;
          end
        end

        SYS_COPY_SET_READ: begin
          if (bg_bank_is_a) begin
            cell_ram_b_sys_r_addr <= sys_cell_index;
          end else begin
            cell_ram_a_sys_r_addr <= sys_cell_index;
          end
          sys_state <= SYS_COPY_WAIT_A;
        end

        SYS_COPY_WAIT_A: begin
          sys_state <= SYS_COPY_WAIT_B;
        end

        SYS_COPY_WAIT_B: begin
          sys_copy_latched <= bg_bank_is_a ? cell_ram_b_sys_d_out : cell_ram_a_sys_d_out;
          sys_state <= SYS_COPY_WRITE;
        end

        SYS_COPY_WRITE: begin
          if (bg_bank_is_a) begin
            cell_ram_a_sys_w_en <= 1'b1;
            cell_ram_a_sys_w_addr <= sys_cell_index;
            cell_ram_a_sys_d_in <= sys_copy_latched;
          end else begin
            cell_ram_b_sys_w_en <= 1'b1;
            cell_ram_b_sys_w_addr <= sys_cell_index;
            cell_ram_b_sys_d_in <= sys_copy_latched;
          end

          if (sys_cell_index == CELL_COUNT - 1) begin
            if (interaction_cmd_pending &&
                (command_kind(interaction_cmd_pending_payload) == CMD_SELECT_TARGET)) begin
              sys_state <= SYS_SELECT_SET_READ;
            end else begin
              sys_state <= SYS_EXEC_START;
            end
          end else begin
            sys_cell_index <= sys_cell_index + 1'b1;
            sys_state <= SYS_COPY_SET_READ;
          end
        end

        SYS_SELECT_SET_READ: begin
          if (bg_bank_is_a) begin
            cell_ram_a_sys_r_addr <= flatten_addr(command_cell_x(interaction_cmd_pending_payload), command_cell_y(interaction_cmd_pending_payload));
          end else begin
            cell_ram_b_sys_r_addr <= flatten_addr(command_cell_x(interaction_cmd_pending_payload), command_cell_y(interaction_cmd_pending_payload));
          end
          sys_state <= SYS_SELECT_WAIT_A;
        end

        SYS_SELECT_WAIT_A: begin
          sys_state <= SYS_SELECT_WAIT_B;
        end

        SYS_SELECT_WAIT_B: begin
          select_cell_latched <= bg_bank_is_a ? cell_ram_a_sys_d_out : cell_ram_b_sys_d_out;
          sys_state <= SYS_SELECT_EVAL;
        end

        SYS_SELECT_EVAL: begin
          if (is_component_cell(select_cell_latched)) begin
            selected_comp_idx <= cell_comp_idx(select_cell_latched);
            selected_comp_data <= 40'd0;
            has_selection <= 1'b1;
            comp_store_r_addr <= cell_comp_idx(select_cell_latched);
          end else begin
            has_selection <= 1'b0;
            selected_comp_idx <= 6'd0;
            selected_comp_data <= 40'd0;
          end
          sys_state <= SYS_EXEC_START;
        end

        SYS_EXEC_START: begin
          if (has_selection) begin
            selected_comp_data <= comp_store_d_out;
          end
          if (arb_cmd_valid &&
              (command_kind(arb_cmd_payload) != CMD_SELECT_TARGET)) begin
            executor_start <= 1'b1;
            sys_state <= SYS_EXEC_RUN;
          end else begin
            projector_start <= 1'b1;
            sys_state <= SYS_PROJECT_RUN;
          end
        end

        SYS_EXEC_RUN: begin
          if (bg_bank_is_a) begin
            if (exec_cell_req_valid && exec_cell_req_write) begin
              cell_ram_a_sys_w_en <= 1'b1;
              cell_ram_a_sys_w_addr <= exec_cell_req_addr;
              cell_ram_a_sys_d_in <= exec_cell_req_wdata;
            end else if (exec_cell_req_valid) begin
              cell_ram_a_sys_r_addr <= exec_cell_req_addr;
            end
          end else begin
            if (exec_cell_req_valid && exec_cell_req_write) begin
              cell_ram_b_sys_w_en <= 1'b1;
              cell_ram_b_sys_w_addr <= exec_cell_req_addr;
              cell_ram_b_sys_d_in <= exec_cell_req_wdata;
            end else if (exec_cell_req_valid) begin
              cell_ram_b_sys_r_addr <= exec_cell_req_addr;
            end
          end

          if (exec_comp_req_valid && exec_comp_req_write) begin
            comp_store_w_en <= 1'b1;
            comp_store_w_addr <= exec_comp_req_addr;
            comp_store_d_in <= exec_comp_req_wdata;
            if (has_selection && (selected_comp_idx == exec_comp_req_addr)) begin
              selected_comp_data <= exec_comp_req_wdata;
              if (!component_valid(exec_comp_req_wdata)) begin
                has_selection <= 1'b0;
                selected_comp_idx <= 6'd0;
                selected_comp_data <= 40'd0;
              end
            end
          end else if (exec_comp_req_valid) begin
            comp_store_r_addr <= exec_comp_req_addr;
          end

          if (executor_done) begin
            projector_start <= 1'b1;
            sys_state <= SYS_PROJECT_RUN;
          end
        end

        SYS_PROJECT_RUN: begin
          if (bg_bank_is_a) begin
            if (proj_cell_req_valid && proj_cell_req_write) begin
              cell_ram_a_sys_w_en <= 1'b1;
              cell_ram_a_sys_w_addr <= proj_cell_req_addr;
              cell_ram_a_sys_d_in <= proj_cell_req_wdata;
            end else if (proj_cell_req_valid) begin
              cell_ram_a_sys_r_addr <= proj_cell_req_addr;
            end
          end else begin
            if (proj_cell_req_valid && proj_cell_req_write) begin
              cell_ram_b_sys_w_en <= 1'b1;
              cell_ram_b_sys_w_addr <= proj_cell_req_addr;
              cell_ram_b_sys_d_in <= proj_cell_req_wdata;
            end else if (proj_cell_req_valid) begin
              cell_ram_b_sys_r_addr <= proj_cell_req_addr;
            end
          end

          if (proj_comp_req_valid && proj_comp_req_write) begin
            comp_store_w_en <= 1'b1;
            comp_store_w_addr <= proj_comp_req_addr;
            comp_store_d_in <= proj_comp_req_wdata;
          end else if (proj_comp_req_valid) begin
            comp_store_r_addr <= proj_comp_req_addr;
          end

          if (projector_done) begin
            if (has_selection) begin
              comp_store_r_addr <= selected_comp_idx;
              selected_comp_data <= comp_store_d_out;
            end
            sys_state <= SYS_WAIT_FLIP;
          end
        end

        default: sys_state <= SYS_WAIT_FLIP;
      endcase
    end
  end

  always @(posedge clk_pixel) begin
    if (!video_on) begin
      rgb <= 12'h000;
    end else if (mouse_display_enable) begin
      rgb <= mouse_rgb;
    end else if (prop_panel_rendered) begin
      rgb <= prop_panel_rgb;
    end else if (canvas_rendered) begin
      rgb <= canvas_rgb;
    end else begin
      rgb <= 12'h111;
    end
  end

endmodule
