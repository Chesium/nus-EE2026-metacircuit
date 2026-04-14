`timescale 1ns / 1ps

// 简化版 GlobalRender - 仅包含 OLED 和 VGA 基础功能
module GlobalRender_Simple (
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

    localparam [11:0] BLACK = 12'h000;
    localparam integer SCREEN_H = 480;
    localparam integer SCREEN_W = 640;

    wire clk_pixel, clk_nav, video_on;
    wire [11:0] x_pos, y_pos;
    reg  [11:0] rgb;

    reg [3:0] oled_clk_div_counter = 0;
    reg [22:0] oled_clk_div_20hz = 0;
    reg oled_clk6p25m = 0;
    reg oled_clk20hz = 0;

    always @(posedge CLK100MHZ or posedge BTNC) begin
        if (BTNC) begin
            oled_clk_div_counter <= 0;
            oled_clk6p25m <= 0;
            oled_clk_div_20hz <= 0;
            oled_clk20hz <= 0;
        end else begin
            if (oled_clk_div_counter == 7) begin
                oled_clk_div_counter <= 0;
                oled_clk6p25m <= ~oled_clk6p25m;
            end else
                oled_clk_div_counter <= oled_clk_div_counter + 1;

            if (oled_clk_div_20hz == 2500000) begin
                oled_clk_div_20hz <= 0;
                oled_clk20hz <= ~oled_clk20hz;
            end else
                oled_clk_div_20hz <= oled_clk_div_20hz + 1;
        end
    end

    reg [15:0] oled_data = 16'h07E0;
    wire frame_begin, sending_pixels, sample_pixel;
    wire [12:0] pixel_index;
    wire [6:0] oled_x_pos;
    wire [5:0] oled_y_pos;

    assign oled_x_pos = pixel_index % 96;
    assign oled_y_pos = pixel_index / 96;

    always @(posedge oled_clk6p25m) begin
        if (oled_y_pos < 32)
            oled_data <= 16'hF800;  // 红色
        else
            oled_data <= 16'h07E0;  // 绿色
    end

    ClockDivider #( .FREQ(25_000_000) ) clkdiv_pixel_inst ( .CLK100MHZ(CLK100MHZ), .clk_out(clk_pixel) );
    ClockDivider #( .FREQ(20) ) clkdiv_nav_inst ( .CLK100MHZ(CLK100MHZ), .clk_out(clk_nav) );
    
    VGAControl vga_ctrl_inst (
        .clk_pixel(clk_pixel), .reset(1'b0), .rgb(rgb),
        .hsync(HSYNC), .vsync(VSYNC), .video_on(video_on),
        .h_count_reg(x_pos), .v_count_reg(y_pos),
        .vgaRed(VGARED), .vgaGreen(VGAGREEN), .vgaBlue(VGABLUE)
    );

    Oled_Display oled_inst (
        .clk(oled_clk6p25m),
        .reset(BTNC),
        .frame_begin(frame_begin),
        .sending_pixels(sending_pixels),
        .sample_pixel(sample_pixel),
        .pixel_index(pixel_index),
        .pixel_data(oled_data),
        .cs(JC[0]),
        .sdin(JC[1]),
        .sclk(JC[3]),
        .d_cn(JC[4]),
        .resn(JC[5]),
        .vccen(JC[6]),
        .pmoden(JC[7])
    );

    assign SEG = 8'hFF;
    assign AN = 4'hF;
    assign LED = 16'd0;
    assign JC[2] = 1'b0;  // JC[2] 未使用
    assign PS2CLK = 1'b1;
    assign PS2DATA = 1'b1;

    always @(posedge clk_pixel) begin
        if (!video_on) begin
            rgb <= BLACK;
        end else begin
            rgb <= 12'hECC;  // 浅色背景
        end
    end

endmodule
