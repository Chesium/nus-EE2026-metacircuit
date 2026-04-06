`timescale 1ns / 1ps

module DynamicTextDisplay #(
    parameter TOTAL_BITS = 16,
    parameter FRAC_BITS = 8,
    parameter MAX_DIGITS = 6,
    parameter CHAR_W_BASE = 8,
    parameter CHAR_H_BASE = 8
)(
    input wire clk_pixel,
    input wire [11:0] hcount,
    input wire [11:0] vcount,
    input wire signed [TOTAL_BITS-1:0] value_in,
    input wire [11:0] start_x,
    input wire [11:0] start_y,
    input wire [3:0]  scale,
    input wire        show_sign,
    input wire        show_leading_zero,
    output reg text_enable,
    output reg [11:0] text_color,
    output wire [4:0] actual_len_dbg,
    output wire [7:0] char0_dbg,
    output wire [7:0] char1_dbg,
    output wire [7:0] char2_dbg,
    output wire [7:0] char3_dbg,
    output wire [7:0] char4_dbg,
    output wire [7:0] char5_dbg
);

    reg [7:0] char_mem [0:MAX_DIGITS];
    reg [4:0] actual_len = 5'd0;
    reg is_negative = 1'b0;
    reg [TOTAL_BITS-1:0] last_value = {TOTAL_BITS{1'b0}};
    reg value_changed = 1'b0;
    reg text_cache_valid = 1'b0;

    assign actual_len_dbg = actual_len;
    assign char0_dbg = char_mem[0];
    assign char1_dbg = char_mem[1];
    assign char2_dbg = char_mem[2];
    assign char3_dbg = char_mem[3];
    assign char4_dbg = char_mem[4];
    assign char5_dbg = char_mem[5];

    always @(posedge clk_pixel) begin
        value_changed <= (value_in != last_value);
        last_value <= value_in;
    end

    integer k;
    reg [7:0] buffer [0:MAX_DIGITS];
    reg [4:0] len;
    reg signed [TOTAL_BITS-1:0] work_val;
    reg [TOTAL_BITS-FRAC_BITS-1:0] i_part;
    reg [FRAC_BITS-1:0] f_part;
    reg [15:0] f_scaled;
    reg [3:0] hundreds_digit;
    reg [3:0] tens_digit;
    reg [3:0] ones_digit;

    always @(posedge clk_pixel) begin
        if (!text_cache_valid || value_changed) begin
            for (k = 0; k < MAX_DIGITS; k = k + 1) begin
                buffer[k] = 8'd0;
            end
            len = 5'd0;
            work_val = value_in;

            is_negative = 1'b0;
            if (show_sign && work_val < 0) begin
                is_negative = 1'b1;
                buffer[len] = 8'd45;
                len = len + 5'd1;
                work_val = -work_val;
            end

            i_part = work_val >> FRAC_BITS;
            f_part = work_val & ((1 << FRAC_BITS) - 1);

            hundreds_digit = 4'd0;
            tens_digit = 4'd0;
            ones_digit = 4'd0;

            if (i_part >= 100) begin
                if (i_part >= 300) begin
                    hundreds_digit = 4'd3;
                    i_part = i_part - 300;
                end else if (i_part >= 200) begin
                    hundreds_digit = 4'd2;
                    i_part = i_part - 200;
                end else begin
                    hundreds_digit = 4'd1;
                    i_part = i_part - 100;
                end
            end

            if (i_part >= 10) begin
                if (i_part >= 90) begin tens_digit = 4'd9; i_part = i_part - 90;
                end else if (i_part >= 80) begin tens_digit = 4'd8; i_part = i_part - 80;
                end else if (i_part >= 70) begin tens_digit = 4'd7; i_part = i_part - 70;
                end else if (i_part >= 60) begin tens_digit = 4'd6; i_part = i_part - 60;
                end else if (i_part >= 50) begin tens_digit = 4'd5; i_part = i_part - 50;
                end else if (i_part >= 40) begin tens_digit = 4'd4; i_part = i_part - 40;
                end else if (i_part >= 30) begin tens_digit = 4'd3; i_part = i_part - 30;
                end else if (i_part >= 20) begin tens_digit = 4'd2; i_part = i_part - 20;
                end else begin tens_digit = 4'd1; i_part = i_part - 10;
                end
            end
            ones_digit = i_part[3:0];

            if (hundreds_digit != 0) begin
                buffer[len] = hundreds_digit + 8'd48;
                len = len + 5'd1;
            end
            if ((hundreds_digit != 0) || (tens_digit != 0)) begin
                buffer[len] = tens_digit + 8'd48;
                len = len + 5'd1;
            end
            if (!((hundreds_digit == 0) && (tens_digit == 0) && (ones_digit == 0) && !show_leading_zero)) begin
                buffer[len] = ones_digit + 8'd48;
                len = len + 5'd1;
            end

            if (len == 0 || (len == 1 && is_negative)) begin
                buffer[len] = 8'd48;
                len = len + 5'd1;
            end

            buffer[len] = 8'd46;
            len = len + 5'd1;

            f_scaled = (f_part * 100 + (1 << (FRAC_BITS - 1))) >> FRAC_BITS;
            if (f_scaled >= 100) f_scaled = 16'd99;

            tens_digit = 4'd0;
            if (f_scaled >= 90) begin tens_digit = 4'd9; f_scaled = f_scaled - 90;
            end else if (f_scaled >= 80) begin tens_digit = 4'd8; f_scaled = f_scaled - 80;
            end else if (f_scaled >= 70) begin tens_digit = 4'd7; f_scaled = f_scaled - 70;
            end else if (f_scaled >= 60) begin tens_digit = 4'd6; f_scaled = f_scaled - 60;
            end else if (f_scaled >= 50) begin tens_digit = 4'd5; f_scaled = f_scaled - 50;
            end else if (f_scaled >= 40) begin tens_digit = 4'd4; f_scaled = f_scaled - 40;
            end else if (f_scaled >= 30) begin tens_digit = 4'd3; f_scaled = f_scaled - 30;
            end else if (f_scaled >= 20) begin tens_digit = 4'd2; f_scaled = f_scaled - 20;
            end else if (f_scaled >= 10) begin tens_digit = 4'd1; f_scaled = f_scaled - 10;
            end

            buffer[len] = tens_digit + 8'd48;
            len = len + 5'd1;
            buffer[len] = f_scaled[3:0] + 8'd48;
            len = len + 5'd1;

            actual_len <= len;
            for (k = 0; k < MAX_DIGITS; k = k + 1) begin
                char_mem[k] <= buffer[k];
            end
            text_cache_valid <= 1'b1;
        end
    end

    wire [3:0] effective_scale = (scale == 0) ? 4'd1 : scale;
    wire [11:0] scaled_char_w = CHAR_W_BASE * effective_scale;
    wire [11:0] scaled_char_h = CHAR_H_BASE * effective_scale;
    wire [11:0] relative_x = (hcount >= start_x) ? (hcount - start_x) : 12'd4095;
    wire [11:0] relative_y = (vcount >= start_y) ? (vcount - start_y) : 12'd4095;
    wire in_bounds = (relative_x < (scaled_char_w * actual_len)) && (relative_y < scaled_char_h);
    wire [2:0] shift_amt = (scale == 8) ? 3'd3 : (scale == 4) ? 3'd2 : (scale == 2) ? 3'd1 : 3'd0;
    wire [4:0] char_idx = in_bounds ? (relative_x >> (3 + shift_amt)) : 5'd0;
    wire [11:0] char_mask = (scale == 8) ? 12'd63 : (scale == 4) ? 12'd31 : (scale == 2) ? 12'd15 : 12'd7;
    wire [2:0] font_col = in_bounds ? ((relative_x & char_mask) >> shift_amt) : 3'd0;
    wire [2:0] font_row = in_bounds ? ((relative_y & char_mask) >> shift_amt) : 3'd0;
    wire [7:0] current_char = char_mem[char_idx];
    wire is_valid_char = (current_char >= 32) && (current_char <= 126);
    wire [6:0] ascii_addr = is_valid_char ? (current_char - 32) : 7'd0;
    wire [7:0] pixel_row;
    wire is_lit;

    FontROM u_font (
        .char_addr(ascii_addr),
        .row(font_row),
        .pixel_data(pixel_row)
    );

    assign is_lit = is_valid_char && in_bounds && pixel_row[6 - font_col];

    always @(posedge clk_pixel) begin
        text_enable <= is_lit;
        text_color <= 12'b1111_1111_1111;
    end

endmodule
