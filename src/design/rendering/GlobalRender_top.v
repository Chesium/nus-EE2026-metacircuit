`timescale 1ns / 1ps

module GlobalRender_top (
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

    localparam [11:0] BLACK            = 12'h000;
    localparam [11:0] BACKGROUND       = 12'hFCE;
    localparam integer SCREEN_H        = 480;
    localparam integer SCREEN_W        = 640;
    localparam integer KEYBOARD_SCALE  = 3;
    localparam integer KEYBOARD_W      = 5 * (12 * KEYBOARD_SCALE);
    localparam integer KEYBOARD_H      = 4 * (12 * KEYBOARD_SCALE);
    localparam integer KEYBOARD_MARGIN = 8;
    localparam integer KEYBOARD_PANEL_PAD = 8;
    localparam integer KEYBOARD_X      = KEYBOARD_MARGIN;
    localparam integer KEYBOARD_Y      = SCREEN_H - KEYBOARD_H - KEYBOARD_MARGIN;
    localparam integer KEYBOARD_REGION_X0 = KEYBOARD_X - KEYBOARD_PANEL_PAD;
    localparam integer KEYBOARD_REGION_Y0 = KEYBOARD_Y - KEYBOARD_PANEL_PAD;
    localparam integer KEYBOARD_REGION_X1 = KEYBOARD_X + KEYBOARD_W + KEYBOARD_PANEL_PAD;
    localparam integer KEYBOARD_REGION_Y1 = KEYBOARD_Y + KEYBOARD_H + KEYBOARD_PANEL_PAD;
    localparam integer RESET_BUTTON_W = 72;
    localparam integer RESET_BUTTON_H = 36;
    localparam integer RESET_BUTTON_MARGIN = 12;
    localparam integer RESET_BUTTON_X = SCREEN_W - RESET_BUTTON_W - RESET_BUTTON_MARGIN;
    localparam integer RESET_BUTTON_Y = RESET_BUTTON_MARGIN;

    wire clk_pixel;
    wire clk_nav;
    wire video_on;
    wire [11:0] x_pos;
    wire [11:0] y_pos;
    reg  [11:0] rgb;

    wire [11:0] keyboard_rgb;
    wire [4:0]  keyboard_key_id;
    wire        keyboard_key_valid;
    wire [7:0]  keyboard_key_ascii;
    reg  [7:0]  last_ascii = 8'h00;
    wire [11:0] reset_button_rgb;
    wire        reset_button_inside;
    wire        reset_button_hover;
    wire        reset_button_pressed;
    wire        reset_region_active;

    wire [11:0] circuit_canvas_rgb;
    wire        circuit_canvas_rendered;

    wire [11:0] mouse_xpos;
    wire [11:0] mouse_ypos;
    wire [3:0]  mouse_zpos;
    wire        mouse_left;
    wire        mouse_middle;
    wire        mouse_right;
    wire        mouse_new_event;
    reg  [11:0] mouse_set_value;
    reg         mouse_set_max_x;
    reg         mouse_set_max_y;

    wire        mouse_display_enable;
    wire [3:0]  mouse_r;
    wire [3:0]  mouse_g;
    wire [3:0]  mouse_b;
    wire [11:0] mouse_rgb;

    reg         circuit_canvas_ram_w_en = 1'b0;
    reg  [7:0]  circuit_canvas_ram_w_addr = 8'd0;
    wire [7:0]  circuit_canvas_ram_r_addr;
    reg  [15:0] circuit_canvas_ram_w_data = 16'd0;
    wire [15:0] circuit_canvas_ram_r_data;
    reg  [31:0] init_cycles = 32'd0;
    reg         reset_button_click_d = 1'b0;
    reg         clear_canvas_active = 1'b0;
    reg  [7:0]  clear_canvas_addr = 8'd0;

    wire keyboard_region_active;
    assign keyboard_region_active =
        (x_pos >= KEYBOARD_REGION_X0) &&
        (x_pos <  KEYBOARD_REGION_X1) &&
        (y_pos >= KEYBOARD_REGION_Y0) &&
        (y_pos <  KEYBOARD_REGION_Y1);
    assign reset_button_hover =
        (mouse_xpos >= RESET_BUTTON_X) &&
        (mouse_xpos <  (RESET_BUTTON_X + RESET_BUTTON_W)) &&
        (mouse_ypos >= RESET_BUTTON_Y) &&
        (mouse_ypos <  (RESET_BUTTON_Y + RESET_BUTTON_H));
    assign reset_button_pressed = reset_button_hover && mouse_left;
    assign reset_region_active =
        (x_pos >= RESET_BUTTON_X) &&
        (x_pos <  (RESET_BUTTON_X + RESET_BUTTON_W)) &&
        (y_pos >= RESET_BUTTON_Y) &&
        (y_pos <  (RESET_BUTTON_Y + RESET_BUTTON_H));

    assign mouse_rgb = {mouse_r, mouse_g, mouse_b};

    assign JC = 8'h00;
    assign SEG = 8'hFF;
    assign AN = 4'hF;
    assign LED[4:0] = keyboard_key_id;
    assign LED[7:5] = 3'b000;
    assign LED[15:8] = last_ascii;

    ClockDivider #(
        .FREQ(25_000_000)
    ) clkdiv_pixel_inst (
        .CLK100MHZ(CLK100MHZ),
        .clk_out(clk_pixel)
    );

    ClockDivider #(
        .FREQ(20)
    ) clkdiv_nav_inst (
        .CLK100MHZ(CLK100MHZ),
        .clk_out(clk_nav)
    );

    VGAControl vga_ctrl_inst (
        .clk_pixel(clk_pixel),
        .reset(SW[15]),
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
        .xpos(mouse_xpos),
        .ypos(mouse_ypos),
        .hcount(x_pos),
        .vcount(y_pos),
        .enable_mouse_display_out(mouse_display_enable),
        .red_out(mouse_r),
        .green_out(mouse_g),
        .blue_out(mouse_b)
    );

    SimpleRam #(
        .WordWidth(16),
        .WordCount(256)
    ) circuit_canvas_ram_inst (
        .clk(CLK100MHZ),
        .w_en(circuit_canvas_ram_w_en),
        .w_addr(circuit_canvas_ram_w_addr),
        .r_addr(circuit_canvas_ram_r_addr),
        .d_in(circuit_canvas_ram_w_data),
        .d_out(circuit_canvas_ram_r_data)
    );

    CircuitCanvas circuit_canvas_inst (
        .clk_pixel(clk_pixel),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .rgb(circuit_canvas_rgb),
        .rendered(circuit_canvas_rendered),
        .mouse_x_pos(mouse_xpos),
        .mouse_y_pos(mouse_ypos),
        .data_addr(circuit_canvas_ram_r_addr),
        .incoming_data(circuit_canvas_ram_r_data),
        .display_grid(1'b1),
        .mouse_left_click(mouse_left)
    );

    KeyboardVGA #(
        .FONT_SCALE(KEYBOARD_SCALE),
        .KEYBOARD_X0(KEYBOARD_X),
        .KEYBOARD_Y0(KEYBOARD_Y)
    ) keyboard_vga_inst (
        .clk_nav(clk_nav),
        .btnU(BTNU),
        .btnD(BTND),
        .btnL(BTNL),
        .btnR(BTNR),
        .btnC(BTNC),
        .mouse_x(mouse_xpos),
        .mouse_y(mouse_ypos),
        .mouse_left(mouse_left),
        .x(x_pos),
        .y(y_pos),
        .pixel_rgb(keyboard_rgb),
        .key_id(keyboard_key_id),
        .key_valid(keyboard_key_valid),
        .key_ascii(keyboard_key_ascii)
    );

    ButtonVGA #(
        .X0(RESET_BUTTON_X),
        .Y0(RESET_BUTTON_Y),
        .W(RESET_BUTTON_W),
        .H(RESET_BUTTON_H),
        .BORDER(3),
        .EDGE_THICK(2),
        .MARKER_OFFSET(6),
        .MARKER_W(3),
        .MARKER_H(3),
        .FONT5_SCALE(3),
        .FONT3_SCALE(2),
        .LABEL0("R"),
        .LABEL1("S"),
        .LABEL2("T"),
        .TEXT_COLS(3),
        .SMALL_TEXT(1'b0),
        .FACE_RGB(24'hF2C8C5),
        .BORDER_RGB(24'hA35C57),
        .SELECTED_BORDER_RGB(24'h7A2F2A),
        .SELECTED_MARKER_RGB(24'hFFF1E8),
        .PRESSED_BORDER_RGB(24'h5B1B18),
        .TEXT_RGB(24'h4A1F1C)
    ) reset_button_inst (
        .enabled(1'b1),
        .selected(reset_button_hover),
        .pressed(reset_button_pressed),
        .x(x_pos),
        .y(y_pos),
        .pixel_rgb(reset_button_rgb),
        .inside_button(reset_button_inside)
    );

    always @(posedge clk_nav) begin
        if (keyboard_key_valid) begin
            last_ascii <= keyboard_key_ascii;
        end
    end

    always @(posedge CLK100MHZ) begin
        mouse_set_value <= 12'h000;
        mouse_set_max_x <= 1'b0;
        mouse_set_max_y <= 1'b0;
        circuit_canvas_ram_w_en <= 1'b0;
        reset_button_click_d <= reset_button_pressed;

        if (init_cycles < 32'd1000) begin
            init_cycles <= init_cycles + 1'b1;
        end

        if (reset_button_pressed && !reset_button_click_d) begin
            clear_canvas_active <= 1'b1;
            clear_canvas_addr <= 8'd0;
            init_cycles <= 32'd1000;
        end

        if (clear_canvas_active) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= clear_canvas_addr;
            circuit_canvas_ram_w_data <= 16'd0;

            if (clear_canvas_addr == 8'd255) begin
                clear_canvas_active <= 1'b0;
            end else begin
                clear_canvas_addr <= clear_canvas_addr + 1'b1;
            end
        end else if (init_cycles == 32'd1) begin
            mouse_set_max_x <= 1'b1;
            mouse_set_value <= 12'd639;
        end else if (init_cycles == 32'd2) begin
            mouse_set_max_y <= 1'b1;
            mouse_set_value <= 12'd479;
        end else if (init_cycles < 32'd256) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= init_cycles[7:0];
            circuit_canvas_ram_w_data <= 16'd0;
        end else if (init_cycles == 32'd256) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 8'd17;
            circuit_canvas_ram_w_data <= 16'b0000000_10_000001_1;
        end else if (init_cycles == 32'd257) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 8'd18;
            circuit_canvas_ram_w_data <= 16'b0000000_00_000101_1;
        end else if (init_cycles == 32'd258) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 8'd19;
            circuit_canvas_ram_w_data <= 16'b0000000_00_000110_1;
        end else if (init_cycles == 32'd259) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 8'd33;
            circuit_canvas_ram_w_data <= 16'b0000000_11_001000_1;
        end else if (init_cycles == 32'd260) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 8'd49;
            circuit_canvas_ram_w_data <= 16'b0000000_11_000111_1;
        end else if (init_cycles == 32'd261) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 8'd82;
            circuit_canvas_ram_w_data <= 16'b0000000_00_000010_1;
        end else if (init_cycles == 32'd262) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 8'd84;
            circuit_canvas_ram_w_data <= 16'b0000000_01_000010_1;
        end else if (init_cycles == 32'd263) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 8'd86;
            circuit_canvas_ram_w_data <= 16'b0000000_10_000010_1;
        end else if (init_cycles == 32'd264) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 8'd88;
            circuit_canvas_ram_w_data <= 16'b0000000_11_000010_1;
        end
    end

    always @(posedge clk_pixel) begin
        if (!video_on) begin
            rgb <= BLACK;
        end else if (mouse_display_enable) begin
            rgb <= mouse_rgb;
        end else if (reset_region_active) begin
            rgb <= reset_button_rgb;
        end else if (keyboard_region_active) begin
            rgb <= keyboard_rgb;
        end else if (circuit_canvas_rendered) begin
            rgb <= circuit_canvas_rgb;
        end else begin
            rgb <= BACKGROUND;
        end
    end

endmodule
