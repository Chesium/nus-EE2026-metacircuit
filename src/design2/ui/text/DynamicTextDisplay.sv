`timescale 1ns / 1ps

module DynamicTextDisplay #(
    parameter integer TOTAL_BITS = 16,
    parameter integer FRAC_BITS = 8,
    parameter integer MAX_DIGITS = 8,
    parameter integer MAX_CHARS = 32
)(
    input  wire                          clk_pixel,
    input  wire                          video_on,
    input  wire [11:0]                   hcount,
    input  wire [11:0]                   vcount,
    input  wire signed [TOTAL_BITS-1:0]  value_in,
    input  wire [11:0]                   start_x,
    input  wire [11:0]                   start_y,
    input  wire [11:0]                   region_width,
    input  wire [3:0]                    scale,
    input  wire [1:0]                    align,
    input  wire                          show_sign,
    input  wire                          show_leading_zero,
    input  wire [11:0]                   text_rgb,
    output wire                          rendered,
    output wire [11:0]                   rgb,
    output wire [5:0]                    actual_len_dbg,
    output wire [7:0]                    char0_dbg,
    output wire [7:0]                    char1_dbg,
    output wire [7:0]                    char2_dbg,
    output wire [7:0]                    char3_dbg,
    output wire [7:0]                    char4_dbg,
    output wire [7:0]                    char5_dbg
);
    localparam integer DECIMAL_DIGITS = 2;
    localparam integer LEN_LIMIT = (MAX_DIGITS < MAX_CHARS) ? MAX_DIGITS : MAX_CHARS;

    reg [MAX_CHARS*8-1:0] text_data_reg = {MAX_CHARS*8{1'b0}};
    reg [5:0]             text_len_reg = 6'd0;

    integer k;
    integer len_i;
    integer int_part_i;
    integer frac_scaled_i;
    integer divisor_i;
    integer digit_i;
    integer abs_value_i;
    integer frac_mask_i;
    integer int_digits_i;
    integer power_i;
    reg signed [TOTAL_BITS-1:0] sample_value;
    reg [7:0] chars [0:MAX_CHARS-1];

    always @(posedge clk_pixel) begin
        sample_value = value_in;
        len_i = 0;

        for (k = 0; k < MAX_CHARS; k = k + 1) begin
            chars[k] = 8'd0;
        end

        if (show_sign && sample_value < 0) begin
            chars[len_i] = "-";
            len_i = len_i + 1;
            abs_value_i = -sample_value;
        end else begin
            abs_value_i = sample_value;
        end

        int_part_i = abs_value_i >>> FRAC_BITS;
        frac_mask_i = (1 << FRAC_BITS) - 1;
        frac_scaled_i = ((abs_value_i & frac_mask_i) * 100 + (1 << (FRAC_BITS - 1))) >>> FRAC_BITS;
        if (frac_scaled_i > 99) begin
            frac_scaled_i = 99;
        end

        int_digits_i = 1;
        power_i = 10;
        while ((power_i <= int_part_i) && (int_digits_i < 6)) begin
            int_digits_i = int_digits_i + 1;
            power_i = power_i * 10;
        end

        if ((int_part_i != 0) || show_leading_zero) begin
            divisor_i = 1;
            for (k = 1; k < int_digits_i; k = k + 1) begin
                divisor_i = divisor_i * 10;
            end

            for (k = 0; k < int_digits_i; k = k + 1) begin
                digit_i = int_part_i / divisor_i;
                chars[len_i] = 8'd48 + digit_i[7:0];
                len_i = len_i + 1;
                int_part_i = int_part_i % divisor_i;
                if (divisor_i > 1) begin
                    divisor_i = divisor_i / 10;
                end
            end
        end else begin
            chars[len_i] = "0";
            len_i = len_i + 1;
        end

        chars[len_i] = ".";
        len_i = len_i + 1;
        chars[len_i] = 8'd48 + ((frac_scaled_i / 10) % 10);
        len_i = len_i + 1;
        chars[len_i] = 8'd48 + (frac_scaled_i % 10);
        len_i = len_i + 1;

        if (len_i > LEN_LIMIT) begin
            len_i = LEN_LIMIT;
        end

        text_len_reg <= len_i[5:0];
        for (k = 0; k < MAX_CHARS; k = k + 1) begin
            text_data_reg[(MAX_CHARS - 1 - k) * 8 +: 8] <= chars[k];
        end
    end

    assign actual_len_dbg = text_len_reg;
    assign char0_dbg = text_data_reg[(MAX_CHARS - 1) * 8 +: 8];
    assign char1_dbg = text_data_reg[(MAX_CHARS - 2) * 8 +: 8];
    assign char2_dbg = text_data_reg[(MAX_CHARS - 3) * 8 +: 8];
    assign char3_dbg = text_data_reg[(MAX_CHARS - 4) * 8 +: 8];
    assign char4_dbg = text_data_reg[(MAX_CHARS - 5) * 8 +: 8];
    assign char5_dbg = text_data_reg[(MAX_CHARS - 6) * 8 +: 8];

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
        .text_data(text_data_reg),
        .text_len(text_len_reg),
        .text_rgb(text_rgb),
        .rendered(rendered),
        .rgb(rgb),
        .char_index_out(char_index_unused)
    );
endmodule
