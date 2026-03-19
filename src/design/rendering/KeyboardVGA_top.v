`timescale 1ns / 1ps

module KeyboardVGA_top (
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
    output wire        VSYNC
);

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

    reg [7:0] last_ascii = 8'h00;

    localparam [11:0] BLACK = 12'h000;
    localparam [11:0] DARK_BLUE = 12'h124;
    localparam integer KEYBOARD_SCALE = 4;
    localparam integer SCREEN_H = 480;
    localparam integer KEYBOARD_KEY_H = 12 * KEYBOARD_SCALE;
    localparam integer KEYBOARD_H = 4 * KEYBOARD_KEY_H;
    localparam integer KEYBOARD_X = 0;
    localparam integer KEYBOARD_Y = SCREEN_H - KEYBOARD_H;

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

    always @(posedge clk_pixel) begin
        if (!video_on) begin
            rgb <= BLACK;
        end else if (SW[0]) begin
            rgb <= DARK_BLUE;
        end else begin
            rgb <= keyboard_rgb;
        end
    end

endmodule
