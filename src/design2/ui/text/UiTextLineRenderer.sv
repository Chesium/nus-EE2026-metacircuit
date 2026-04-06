`timescale 1ns / 1ps

module UiTextLineRenderer #(
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
    input  wire [5:0]  text_len,
    input  wire [11:0] text_rgb,
    input  wire [MAX_CHARS*8-1:0] text_data,
    output reg         rendered,
    output reg  [11:0] rgb,
    output reg  [5:0]  char_index_out
);
    import UiTextPkg::*;

    localparam [11:0] INVALID_COORD = 12'hFFF;

    wire [3:0] effective_scale = sanitize_scale(scale);
    wire [2:0] shift_amt = scale_shift(effective_scale);
    wire [11:0] char_mask = scale_mask(effective_scale);
    wire [11:0] scaled_char_w = char_span(effective_scale);
    wire [11:0] scaled_char_h = UI_TEXT_CHAR_H * effective_scale;
    wire [11:0] aligned_x = aligned_start_x(start_x, region_width, text_len, effective_scale, align);
    wire [11:0] total_text_width = text_width(text_len, effective_scale);

    wire [11:0] relative_x = (hcount >= aligned_x) ? (hcount - aligned_x) : INVALID_COORD;
    wire [11:0] relative_y = (vcount >= start_y) ? (vcount - start_y) : INVALID_COORD;
    wire in_bounds = video_on &&
                     (relative_x < total_text_width) &&
                     (relative_y < scaled_char_h);

    wire [5:0] char_idx = in_bounds ? (relative_x >> (3 + shift_amt)) : 6'd0;
    wire [2:0] font_col = in_bounds ? ((relative_x & char_mask) >> shift_amt) : 3'd0;
    wire [2:0] font_row = in_bounds ? ((relative_y & char_mask) >> shift_amt) : 3'd0;

    wire [7:0] current_char =
        ((char_idx < text_len) && (char_idx < MAX_CHARS)) ?
        text_data[(MAX_CHARS - 1 - char_idx) * 8 +: 8] :
        8'd0;
    wire valid_ascii = (current_char >= 8'd32) && (current_char <= 8'd126);
    wire [6:0] ascii_addr = valid_ascii ? (current_char - 8'd32) : 7'd0;

    wire [7:0] pixel_row;
    FontROM u_font_rom (
        .char_addr(ascii_addr),
        .row(font_row),
        .pixel_data(pixel_row)
    );

    wire pixel_lit = in_bounds && valid_ascii && pixel_row[7 - font_col];

    always @(posedge clk_pixel) begin
        rendered <= pixel_lit;
        rgb <= pixel_lit ? text_rgb : 12'h000;
        char_index_out <= char_idx;
    end
endmodule
