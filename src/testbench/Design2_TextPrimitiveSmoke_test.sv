`timescale 1ns / 1ps

module Design2_TextPrimitiveSmoke_test;
    import UiTextPkg::*;

    reg         clk_pixel = 1'b0;
    reg         video_on = 1'b1;
    reg [11:0]  hcount = 12'd0;
    reg [11:0]  vcount = 12'd0;
    reg [255:0] dyn_text_data = {"OK", 240'd0};
    reg [5:0]   dyn_text_len = 6'd2;
    reg signed [15:0] value_in = 16'sd256;

    wire [7:0] font_pixel_data;
    wire text_display_rendered;
    wire [11:0] text_display_rgb;
    wire [5:0] text_display_char_idx;
    wire text_box_rendered;
    wire [11:0] text_box_rgb;
    wire dyn_box_rendered;
    wire [11:0] dyn_box_rgb;
    wire [5:0] dyn_box_char_idx;
    wire dyn_num_rendered;
    wire [11:0] dyn_num_rgb;
    wire [5:0] actual_len_dbg;
    wire [7:0] char0_dbg;
    wire [7:0] char1_dbg;
    wire [7:0] char2_dbg;
    wire [7:0] char3_dbg;
    wire [7:0] char4_dbg;
    wire [7:0] char5_dbg;

    always #20 clk_pixel = ~clk_pixel;

    FontROM u_font_rom (
        .char_addr(7'd16),
        .row(3'd0),
        .pixel_data(font_pixel_data)
    );

    TextDisplay #(
        .MAX_CHARS(32)
    ) u_text_display (
        .clk_pixel(clk_pixel),
        .video_on(video_on),
        .hcount(hcount),
        .vcount(vcount),
        .start_x(12'd10),
        .start_y(12'd10),
        .region_width(12'd0),
        .scale(4'd1),
        .align(UI_ALIGN_LEFT),
        .text_data({"SMOKE", 216'd0}),
        .text_len(6'd5),
        .text_rgb(12'hFFF),
        .rendered(text_display_rendered),
        .rgb(text_display_rgb),
        .char_index_out(text_display_char_idx)
    );

    TextBox #(
        .MAX_CHARS(32),
        .TEXT_CONTENT({"TB", 240'd0}),
        .TEXT_LEN(2)
    ) u_text_box (
        .clk_pixel(clk_pixel),
        .video_on(video_on),
        .hcount(hcount),
        .vcount(vcount),
        .start_x(12'd20),
        .start_y(12'd20),
        .region_width(12'd0),
        .scale(4'd1),
        .align(UI_ALIGN_LEFT),
        .text_rgb(12'h0F0),
        .rendered(text_box_rendered),
        .rgb(text_box_rgb)
    );

    DynamicTextBox #(
        .MAX_CHARS(32)
    ) u_dynamic_text_box (
        .clk_pixel(clk_pixel),
        .video_on(video_on),
        .hcount(hcount),
        .vcount(vcount),
        .text_data(dyn_text_data),
        .text_len(dyn_text_len),
        .start_x(12'd30),
        .start_y(12'd30),
        .region_width(12'd0),
        .scale(4'd1),
        .align(UI_ALIGN_LEFT),
        .text_rgb(12'hF80),
        .rendered(dyn_box_rendered),
        .rgb(dyn_box_rgb),
        .char_index_out(dyn_box_char_idx)
    );

    DynamicTextDisplay #(
        .TOTAL_BITS(16),
        .FRAC_BITS(8),
        .MAX_DIGITS(8),
        .MAX_CHARS(32)
    ) u_dynamic_text_display (
        .clk_pixel(clk_pixel),
        .video_on(video_on),
        .hcount(hcount),
        .vcount(vcount),
        .value_in(value_in),
        .start_x(12'd40),
        .start_y(12'd40),
        .region_width(12'd32),
        .scale(4'd1),
        .align(UI_ALIGN_LEFT),
        .show_sign(1'b1),
        .show_leading_zero(1'b1),
        .text_rgb(12'hFFF),
        .rendered(dyn_num_rendered),
        .rgb(dyn_num_rgb),
        .actual_len_dbg(actual_len_dbg),
        .char0_dbg(char0_dbg),
        .char1_dbg(char1_dbg),
        .char2_dbg(char2_dbg),
        .char3_dbg(char3_dbg),
        .char4_dbg(char4_dbg),
        .char5_dbg(char5_dbg)
    );

    initial begin
        repeat (4) @(posedge clk_pixel);
        $display("Design2_TextPrimitiveSmoke_test elaborated and ran");
        $finish;
    end
endmodule
