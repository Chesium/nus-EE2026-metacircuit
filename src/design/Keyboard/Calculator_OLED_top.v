`timescale 1ns / 1ps

module Calculator_OLED_top (
    input  wire        CLK100MHZ,      // 100MHz 系统时钟
    input  wire        BTNC,           // 中间按钮（确认/等号）
    input  wire        BTNU,           // 上按钮
    input  wire        BTND,           // 下按钮
    input  wire        BTNL,           // 左按钮
    input  wire        BTNR,           // 右按钮
    input  wire [15:0] SW,             // 开关（可选功能选择）
    output wire [7:0]  JC,             // PMOD OLED 接口
    output wire [7:0]  SEG,            // 7段数码管
    output wire [3:0]  AN              // 7段数码管位选
);

    reg [3:0] clk_div_counter = 0;
    reg clk6p25m = 0;

    reg [22:0] clk_div_20hz = 0;
    reg clk20hz = 0;

    always @(posedge CLK100MHZ) begin
        // 6.25MHz 时钟：100MHz / 16 = 6.25MHz
        if (clk_div_counter == 7) begin
            clk_div_counter <= 0;
            clk6p25m <= ~clk6p25m;
        end else begin
            clk_div_counter <= clk_div_counter + 1;
        end

        // 20Hz 时钟：100MHz / 20Hz / 2 = 2,500,000
        if (clk_div_20hz == 23'd2500000) begin
            clk_div_20hz <= 0;
            clk20hz <= ~clk20hz;
        end else begin
            clk_div_20hz <= clk_div_20hz + 1;
        end
    end

    wire frame_begin;
    wire sending_pixels;
    wire sample_pixel;
    wire [12:0] pixel_index;  // 96*64 = 6144 像素，需要 13 位

    wire [6:0] x_pos;  // 0..95
    wire [5:0] y_pos;  // 0..63

    assign x_pos = pixel_index % 96;
    assign y_pos = pixel_index / 96;

    wire [15:0] calc_pixel_rgb;  // RGB565 格式

    reg [15:0] oled_data = 16'h0000;

    always @(posedge clk6p25m) begin
        if (sending_pixels) begin
            oled_data <= calc_pixel_rgb;
        end
    end

    Calculator #(
        .OLED_W(96),
        .OLED_H(64),
        .DATA_W(8)
    ) calculator_inst (
        .clk(CLK100MHZ),           // 系统时钟（状态机）
        .clk_nav(clk20hz),         // 导航时钟（~20Hz）
        .btnU(BTNU),
        .btnD(BTND),
        .btnL(BTNL),
        .btnR(BTNR),
        .btnC(BTNC),               // BTNC 用作确认键
        .x(x_pos),                 // 0..95
        .y(y_pos),                 // 0..63
        .pixel_rgb(calc_pixel_rgb) // RGB565 输出
    );

    Oled_Display oled_inst (
        .clk(clk6p25m),
        .reset(1'b0),              // 不复位，BTNC 用于计算器确认
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

    assign SEG = 8'hFF;  // 关闭7段显示
    assign AN = 4'hF;    // 禁用所有位选

endmodule
