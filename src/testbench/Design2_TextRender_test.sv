`timescale 1ns / 1ps

module Design2_TextRender_test;
    import UiTextPkg::*;

    localparam [255:0] TEXT_AB  = {"AB", 240'd0};
    localparam [255:0] TEXT_HI  = {"HI", 240'd0};
    localparam [255:0] TEXT_ON  = {"ON", 240'd0};
    localparam [255:0] TEXT_ONE = {"ONE", 232'd0};

    reg         clk_pixel = 1'b0;
    reg         video_on = 1'b1;
    reg [11:0]  hcount = 12'd0;
    reg [11:0]  vcount = 12'd0;

    reg [11:0]  start_x = 12'd100;
    reg [11:0]  start_y = 12'd50;
    reg [11:0]  region_width = 12'd0;
    reg [3:0]   scale = 4'd1;
    reg [1:0]   align = UI_ALIGN_LEFT;
    reg [255:0] dyn_text_data = TEXT_ON;
    reg [5:0]   dyn_text_len = 6'd2;
    reg signed [15:0] value_in = 16'sd0;
    reg         show_sign = 1'b1;
    reg         show_leading_zero = 1'b1;
    reg [6:0]   font_char_addr = 7'd0;
    reg [2:0]   font_row = 3'd0;

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
        .char_addr(font_char_addr),
        .row(font_row),
        .pixel_data(font_pixel_data)
    );

    TextDisplay #(
        .MAX_CHARS(32)
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
        .text_data(TEXT_AB),
        .text_len(6'd2),
        .text_rgb(12'hACE),
        .rendered(text_display_rendered),
        .rgb(text_display_rgb),
        .char_index_out(text_display_char_idx)
    );

    TextBox #(
        .MAX_CHARS(32),
        .TEXT_CONTENT(TEXT_HI),
        .TEXT_LEN(2)
    ) u_text_box (
        .clk_pixel(clk_pixel),
        .video_on(video_on),
        .hcount(hcount),
        .vcount(vcount),
        .start_x(12'd200),
        .start_y(12'd70),
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
        .start_x(12'd120),
        .start_y(12'd80),
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
        .start_x(12'd300),
        .start_y(12'd100),
        .region_width(12'd40),
        .scale(4'd1),
        .align(UI_ALIGN_CENTER),
        .show_sign(show_sign),
        .show_leading_zero(show_leading_zero),
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

    task automatic sample_pixel;
        input  [11:0] sample_x;
        input  [11:0] sample_y;
        output reg    lit_text_display;
        output reg    lit_text_box;
        output reg    lit_dyn_box;
        output reg    lit_dyn_num;
        begin
            hcount = sample_x;
            vcount = sample_y;
            @(posedge clk_pixel);
            #1;
            lit_text_display = text_display_rendered;
            lit_text_box = text_box_rendered;
            lit_dyn_box = dyn_box_rendered;
            lit_dyn_num = dyn_num_rendered;
        end
    endtask

    reg lit_text_display;
    reg lit_text_box;
    reg lit_dyn_box;
    reg lit_dyn_num;

    initial begin
        @(posedge clk_pixel);

        font_char_addr = 7'd33;
        font_row = 3'd0;
        #1;
        if (font_pixel_data !== 8'b00111100) begin
            $fatal(1, "FontROM row 0 for 'A' mismatch: %b", font_pixel_data);
        end

        font_row = 3'd3;
        #1;
        if (font_pixel_data !== 8'b01111110) begin
            $fatal(1, "FontROM row 3 for 'A' mismatch: %b", font_pixel_data);
        end

        start_x = 12'd100;
        start_y = 12'd50;
        region_width = 12'd0;
        align = UI_ALIGN_LEFT;
        scale = 4'd1;
        sample_pixel(12'd102, 12'd50, lit_text_display, lit_text_box, lit_dyn_box, lit_dyn_num);
        if (!lit_text_display || (text_display_rgb !== 12'hACE)) begin
            $fatal(1, "TextDisplay failed to render a known lit pixel");
        end

        sample_pixel(12'd116, 12'd50, lit_text_display, lit_text_box, lit_dyn_box, lit_dyn_num);
        if (lit_text_display) begin
            $fatal(1, "TextDisplay did not clip after the end of the text run");
        end

        sample_pixel(12'd201, 12'd70, lit_text_display, lit_text_box, lit_dyn_box, lit_dyn_num);
        if (!lit_text_box || (text_box_rgb !== 12'h0F0)) begin
            $fatal(1, "TextBox failed to render a known lit pixel");
        end

        sample_pixel(12'd137, 12'd80, lit_text_display, lit_text_box, lit_dyn_box, lit_dyn_num);
        if (lit_dyn_box) begin
            $fatal(1, "DynamicTextBox rendered a third character before the text update");
        end

        dyn_text_data = TEXT_ONE;
        dyn_text_len = 6'd3;
        sample_pixel(12'd137, 12'd80, lit_text_display, lit_text_box, lit_dyn_box, lit_dyn_num);
        if (!lit_dyn_box || (dyn_box_rgb !== 12'hF80) || (dyn_box_char_idx != 6'd2)) begin
            $fatal(1, "DynamicTextBox failed to pick up the updated text bus");
        end

        value_in = 16'sd448;
        repeat (2) @(posedge clk_pixel);
        #1;
        if ((actual_len_dbg != 6'd4) ||
            (char0_dbg != "1") ||
            (char1_dbg != ".") ||
            (char2_dbg != "7") ||
            (char3_dbg != "5")) begin
            $fatal(1, "DynamicTextDisplay formatted 1.75 incorrectly: %c%c%c%c",
                   char0_dbg, char1_dbg, char2_dbg, char3_dbg);
        end

        sample_pixel(12'd306, 12'd100, lit_text_display, lit_text_box, lit_dyn_box, lit_dyn_num);
        if (!lit_dyn_num || (dyn_num_rgb !== 12'hFFF)) begin
            $fatal(1, "DynamicTextDisplay failed to render centered text");
        end

        $display("Design2_TextRender_test passed");
        $finish;
    end
endmodule
