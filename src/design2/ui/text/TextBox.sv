`timescale 1ns / 1ps

module TextBox #(
    parameter integer MAX_CHARS = 32,
    parameter [MAX_CHARS*8-1:0] TEXT_CONTENT = "Hello Basys3!",
    parameter integer TEXT_LEN = 13
)(
    input  wire        clk_pixel,
    input  wire        video_on,
    input  wire [11:0] hcount,
    input  wire [11:0] vcount,
    input  wire [11:0] start_x,
    input  wire [11:0] start_y,
    input  wire [11:0] region_width,
    input  wire [3:0]  scale,
    input  wire [1:0]  align,
    input  wire [11:0] text_rgb,
    output wire        rendered,
    output wire [11:0] rgb
);
    wire [5:0] char_index_unused;

    TextDisplay #(
        .MAX_CHARS(MAX_CHARS)
    ) u_text_display (
        .clk_pixel(clk_pixel),
        .video_on(video_on),
        .hcount(hcount),
        .vcount(vcount),
        .start_x(start_x),
        .start_y(start_y),
        .region_width(region_width),
        .scale(scale),
        .align(align),
        .text_data(TEXT_CONTENT),
        .text_len(TEXT_LEN[5:0]),
        .text_rgb(text_rgb),
        .rendered(rendered),
        .rgb(rgb),
        .char_index_out(char_index_unused)
    );
endmodule
