`timescale 1ns / 1ps

module OLED_Test_top (
    input  wire        CLK100MHZ,
    input  wire        BTNC,
    output wire [7:0]  JC,
    output wire [7:0]  SEG,
    output wire [3:0]  AN
);

    reg [3:0] clk_div_counter = 0;
    reg [22:0] clk_div_20hz = 0;
    reg clk6p25m = 0;
    reg clk20hz = 0;

    always @(posedge CLK100MHZ or posedge BTNC) begin
        if (BTNC) begin
            clk_div_counter <= 0;
            clk6p25m <= 0;
            clk_div_20hz <= 0;
            clk20hz <= 0;
        end else begin
            if (clk_div_counter == 7) begin
                clk_div_counter <= 0;
                clk6p25m <= ~clk6p25m;
            end else
                clk_div_counter <= clk_div_counter + 1;

            if (clk_div_20hz == 2500000) begin
                clk_div_20hz <= 0;
                clk20hz <= ~clk20hz;
            end else
                clk_div_20hz <= clk_div_20hz + 1;
        end
    end

    reg [15:0] oled_data = 16'h07E0;
    wire frame_begin, sending_pixels, sample_pixel;
    wire [12:0] pixel_index;
    wire [6:0] x_pos;
    wire [5:0] y_pos;

    assign x_pos = pixel_index % 96;
    assign y_pos = pixel_index / 96;

    always @(posedge clk6p25m) begin
        if (y_pos < 32)
            oled_data <= 16'hF800;  // 红色
        else
            oled_data <= 16'h07E0;  // 绿色
    end

    assign SEG = 8'hFF;
    assign AN = 4'hF;

    Oled_Display oled_inst (
        .clk(clk6p25m),
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

endmodule
