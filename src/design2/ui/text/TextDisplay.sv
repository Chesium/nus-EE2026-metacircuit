`timescale 1ns / 1ps

module TextDisplay #(
    parameter integer MAX_CHARS = 32
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
    input  wire [MAX_CHARS*8-1:0] text_data,
    input  wire [5:0]  text_len,
    input  wire [11:0] text_rgb,
    output wire        rendered,
    output wire [11:0] rgb,
    output wire [5:0]  char_index_out
);
    UiTextLineRenderer #(
        .MAX_CHARS(MAX_CHARS)
    ) u_text_line_renderer (
        .clk_pixel(clk_pixel),
        .video_on(video_on),
        .hcount(hcount),
        .vcount(vcount),
        .start_x(start_x),
        .start_y(start_y),
        .region_width(region_width),
        .scale(scale),
        .align(align),
        .text_len(text_len),
        .text_rgb(text_rgb),
        .text_data(text_data),
        .rendered(rendered),
        .rgb(rgb),
        .char_index_out(char_index_out)
    );
endmodule
