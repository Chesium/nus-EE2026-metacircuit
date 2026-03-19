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
    localparam integer SCREEN_W        = 640;
    localparam integer SCREEN_H        = 480;
    localparam integer KEYBOARD_SCALE  = 3;
    localparam integer KEYBOARD_W      = 5 * (12 * KEYBOARD_SCALE);
    localparam integer KEYBOARD_H      = 4 * (12 * KEYBOARD_SCALE);
    localparam integer KEYBOARD_X      = 0;
    localparam integer KEYBOARD_Y      = SCREEN_H - KEYBOARD_H;

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

    wire keyboard_region_active;
    assign keyboard_region_active =
        (x_pos >= KEYBOARD_X) &&
        (x_pos <  (KEYBOARD_X + KEYBOARD_W)) &&
        (y_pos >= KEYBOARD_Y) &&
        (y_pos <  (KEYBOARD_Y + KEYBOARD_H));

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
        .x(x_pos),
        .y(y_pos),
        .pixel_rgb(keyboard_rgb),
        .key_id(keyboard_key_id),
        .key_valid(keyboard_key_valid),
        .key_ascii(keyboard_key_ascii)
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

        if (init_cycles < 32'd1000) begin
            init_cycles <= init_cycles + 1'b1;
        end

        if (init_cycles == 32'd1) begin
            mouse_set_max_x <= 1'b1;
            mouse_set_value <= 12'd639;
        end
        if (init_cycles == 32'd2) begin
            mouse_set_max_y <= 1'b1;
            mouse_set_value <= 12'd479;
        end

        if (init_cycles < 32'd256) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= init_cycles[7:0];
            circuit_canvas_ram_w_data <= 16'd0;
        end

        if (init_cycles == 32'd256) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 8'd17;
            circuit_canvas_ram_w_data <= 16'b0000000_10_000001_1;
        end
        if (init_cycles == 32'd257) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 8'd18;
            circuit_canvas_ram_w_data <= 16'b0000000_00_000101_1;
        end
        if (init_cycles == 32'd258) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 8'd19;
            circuit_canvas_ram_w_data <= 16'b0000000_00_000110_1;
        end
        if (init_cycles == 32'd259) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 8'd33;
            circuit_canvas_ram_w_data <= 16'b0000000_11_001000_1;
        end
        if (init_cycles == 32'd260) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 8'd49;
            circuit_canvas_ram_w_data <= 16'b0000000_11_000111_1;
        end
        if (init_cycles == 32'd261) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 8'd82;
            circuit_canvas_ram_w_data <= 16'b0000000_00_000010_1;
        end
        if (init_cycles == 32'd262) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 8'd84;
            circuit_canvas_ram_w_data <= 16'b0000000_01_000010_1;
        end
        if (init_cycles == 32'd263) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 8'd86;
            circuit_canvas_ram_w_data <= 16'b0000000_10_000010_1;
        end
        if (init_cycles == 32'd264) begin
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
        end else if (keyboard_region_active) begin
            rgb <= keyboard_rgb;
        end else if (circuit_canvas_rendered) begin
            rgb <= circuit_canvas_rgb;
        end else begin
            rgb <= BACKGROUND;
        end
    end

endmodule
