`timescale 1ns / 1ps

module ComponentPropertyPanel #(
    parameter integer PANEL_X = 0,
    parameter integer PANEL_Y = 0,
    parameter integer PANEL_W = 640,
    parameter integer PANEL_H = 64,
    parameter integer MAX_CHARS = 16
)(
    input wire clk_pixel,
    input wire [11:0] hcount,
    input wire [11:0] vcount,
    input wire video_on,

    input wire [11:0] mouse_cell_i,
    input wire [11:0] mouse_cell_j,

    input wire [15:0] selected_cell_data,
    input wire [63:0] selected_value_text,
    input wire [3:0] selected_value_text_len,
    input wire value_edit_active,
    input wire value_editable,
    input wire has_selection,
    input wire [11:0] selected_cell_i,
    input wire [11:0] selected_cell_j,
    input wire selected_component_index_valid,
    input wire [8:0] selected_component_index,

    output reg panel_rendered,
    output reg [11:0] panel_rgb
);

    localparam [11:0] COLOR_BG = 12'hECC;
    localparam [11:0] COLOR_TEXT = 12'h210;
    localparam [11:0] COLOR_CAPTION = 12'h754;
    localparam [11:0] COLOR_BORDER = 12'hB86;
    localparam [11:0] COLOR_BOX_BG = 12'hFED;
    localparam [11:0] COLOR_BOX_BORDER = 12'hC96;
    localparam [11:0] COLOR_BOX_ACTIVE = 12'hFD0;

    localparam [5:0] SPRITE_WIRE       = 6'd0;
    localparam [5:0] SPRITE_ELBOW      = 6'd1;
    localparam [5:0] SPRITE_TEE        = 6'd2;
    localparam [5:0] SPRITE_JUNCTION   = 6'd3;
    localparam [5:0] SPRITE_RES_LEFT   = 6'd5;
    localparam [5:0] SPRITE_RES_RIGHT  = 6'd6;
    localparam [5:0] SPRITE_VOLT_LEFT  = 6'd7;
    localparam [5:0] SPRITE_VOLT_RIGHT = 6'd8;
    localparam [5:0] SPRITE_CURR_LEFT  = 6'd9;
    localparam [5:0] SPRITE_CURR_RIGHT = 6'd10;
    localparam [5:0] SPRITE_IND_LEFT   = 6'd11;
    localparam [5:0] SPRITE_IND_RIGHT  = 6'd12;
    localparam [5:0] SPRITE_CAP_LEFT   = 6'd13;
    localparam [5:0] SPRITE_CAP_RIGHT  = 6'd14;
    localparam [5:0] SPRITE_GROUND     = 6'd15;

    localparam integer TYPE_X = PANEL_X + 16;
    localparam integer VALUE_X = PANEL_X + 224;
    localparam integer POS_X = PANEL_X + 392;
    localparam integer TITLE_Y = PANEL_Y + 10;
    localparam integer CONTENT_Y = PANEL_Y + 30;
    localparam integer INPUT_X = PANEL_X + 232;
    localparam integer INPUT_Y = PANEL_Y + 30;
    localparam [11:0] TYPE_X_POS = TYPE_X;
    localparam [11:0] VALUE_X_POS = VALUE_X;
    localparam [11:0] POS_X_POS = POS_X;
    localparam [11:0] TITLE_Y_POS = TITLE_Y;
    localparam [11:0] CONTENT_Y_POS = CONTENT_Y;
    localparam [11:0] INPUT_X_POS = INPUT_X;
    localparam [11:0] INPUT_Y_POS = INPUT_Y;
    localparam [11:0] VALUE_BOX_X0 = PANEL_X + 224;
    localparam [11:0] VALUE_BOX_Y0 = PANEL_Y + 24;
    localparam [11:0] VALUE_BOX_X1 = PANEL_X + 336;
    localparam [11:0] VALUE_BOX_Y1 = PANEL_Y + 44;
    localparam [11:0] SEP0_X = PANEL_X + 192;
    localparam [11:0] SEP1_X = PANEL_X + 376;
    localparam [11:0] SEP_Y0 = PANEL_Y + 10;
    localparam [11:0] SEP_Y1 = PANEL_Y + 54;
    localparam [11:0] SUMMARY_Y = PANEL_Y + 26;
    localparam [11:0] HINT_Y = PANEL_Y + 26;

    wire [5:0] cell_sprite_type = selected_cell_data[6:1];
    wire cell_enable = selected_cell_data[0];

    wire is_wire = has_selection && cell_enable && (cell_sprite_type == SPRITE_WIRE);
    wire is_elbow = has_selection && cell_enable && (cell_sprite_type == SPRITE_ELBOW);
    wire is_tee = has_selection && cell_enable && (cell_sprite_type == SPRITE_TEE);
    wire is_junction = has_selection && cell_enable && (cell_sprite_type == SPRITE_JUNCTION);
    wire is_resistor = has_selection && cell_enable &&
        ((cell_sprite_type == SPRITE_RES_LEFT) || (cell_sprite_type == SPRITE_RES_RIGHT));
    wire is_voltage = has_selection && cell_enable &&
        ((cell_sprite_type == SPRITE_VOLT_LEFT) || (cell_sprite_type == SPRITE_VOLT_RIGHT));
    wire is_current = has_selection && cell_enable &&
        ((cell_sprite_type == SPRITE_CURR_LEFT) || (cell_sprite_type == SPRITE_CURR_RIGHT));
    wire is_inductor = has_selection && cell_enable &&
        ((cell_sprite_type == SPRITE_IND_LEFT) || (cell_sprite_type == SPRITE_IND_RIGHT));
    wire is_capacitor = has_selection && cell_enable &&
        ((cell_sprite_type == SPRITE_CAP_LEFT) || (cell_sprite_type == SPRITE_CAP_RIGHT));
    wire is_ground = has_selection && cell_enable && (cell_sprite_type == SPRITE_GROUND);
    wire show_detail_layout = has_selection && value_editable;
    wire show_summary_layout = has_selection && cell_enable && !value_editable;
    wire show_hint_layout = has_selection && !cell_enable;

    wire [3:0] sel_i_tens = selected_cell_i / 10;
    wire [3:0] sel_i_ones = selected_cell_i % 10;
    wire [3:0] sel_j_tens = selected_cell_j / 10;
    wire [3:0] sel_j_ones = selected_cell_j % 10;

    wire [7:0] ascii_sel_i_tens = sel_i_tens + 8'd48;
    wire [7:0] ascii_sel_i_ones = sel_i_ones + 8'd48;
    wire [7:0] ascii_sel_j_tens = sel_j_tens + 8'd48;
    wire [7:0] ascii_sel_j_ones = sel_j_ones + 8'd48;
    wire [3:0] sel_idx_hundreds = selected_component_index / 100;
    wire [3:0] sel_idx_tens = (selected_component_index % 100) / 10;
    wire [3:0] sel_idx_ones = selected_component_index % 10;
    wire [7:0] ascii_sel_idx_hundreds = sel_idx_hundreds + 8'd48;
    wire [7:0] ascii_sel_idx_tens = sel_idx_tens + 8'd48;
    wire [7:0] ascii_sel_idx_ones = sel_idx_ones + 8'd48;

    reg [MAX_CHARS * 8 - 1:0] type_title_data;
    reg [4:0] type_title_len;
    reg [MAX_CHARS * 8 - 1:0] label_data;
    reg [4:0] label_len;
    reg [MAX_CHARS * 8 - 1:0] value_label_data;
    reg [4:0] value_label_len;
    reg [MAX_CHARS * 8 - 1:0] pos_title_data;
    reg [4:0] pos_title_len;
    reg [MAX_CHARS * 8 - 1:0] coord_data;
    reg [4:0] coord_len;
    reg [MAX_CHARS * 8 - 1:0] input_data;
    reg [4:0] input_len;
    reg [MAX_CHARS * 8 - 1:0] type_title_data_q = {MAX_CHARS * 8{1'b0}};
    reg [4:0] type_title_len_q = 5'd0;
    reg [MAX_CHARS * 8 - 1:0] label_data_q = {MAX_CHARS * 8{1'b0}};
    reg [4:0] label_len_q = 5'd0;
    reg [MAX_CHARS * 8 - 1:0] value_label_data_q = {MAX_CHARS * 8{1'b0}};
    reg [4:0] value_label_len_q = 5'd0;
    reg [MAX_CHARS * 8 - 1:0] pos_title_data_q = {MAX_CHARS * 8{1'b0}};
    reg [4:0] pos_title_len_q = 5'd0;
    reg [MAX_CHARS * 8 - 1:0] coord_data_q = {MAX_CHARS * 8{1'b0}};
    reg [4:0] coord_len_q = 5'd0;
    reg [MAX_CHARS * 8 - 1:0] input_data_q = {MAX_CHARS * 8{1'b0}};
    reg [4:0] input_len_q = 5'd0;
    reg [22:0] blink_counter = 23'd0;
    integer i;

    wire [11:0] label_text_width = ({7'd0, label_len_q} << 3);
    wire [11:0] centered_label_x = PANEL_X + ((PANEL_W - label_text_width) >> 1);
    wire [11:0] label_x_pos = show_hint_layout ? centered_label_x : TYPE_X_POS;
    wire [11:0] coord_x_pos = POS_X_POS;
    wire [11:0] label_y_pos = show_hint_layout ? HINT_Y : CONTENT_Y_POS;
    wire [11:0] coord_y_pos = CONTENT_Y_POS;
    wire [3:0] cursor_char_offset = (input_len_q[3:0] < 4'd8) ? input_len_q[3:0] : 4'd7;
    wire [11:0] cursor_x0 = INPUT_X_POS + ({8'd0, cursor_char_offset} << 3);
    wire [11:0] cursor_x1 = cursor_x0 + 12'd2;

    always @(*) begin
        for (i = 0; i < MAX_CHARS * 8; i = i + 8) begin
            type_title_data[i +: 8] = 8'd0;
            label_data[i +: 8] = 8'd0;
            value_label_data[i +: 8] = 8'd0;
            pos_title_data[i +: 8] = 8'd0;
            coord_data[i +: 8] = 8'd0;
            input_data[i +: 8] = 8'd0;
        end

        type_title_data[MAX_CHARS * 8 - 1 -: 8] = "T";
        type_title_data[MAX_CHARS * 8 - 9 -: 8] = "y";
        type_title_data[MAX_CHARS * 8 - 17 -: 8] = "p";
        type_title_data[MAX_CHARS * 8 - 25 -: 8] = "e";
        type_title_len = (show_detail_layout || show_summary_layout) ? 5'd4 : 5'd0;

        pos_title_data[MAX_CHARS * 8 - 1 -: 8] = "P";
        pos_title_data[MAX_CHARS * 8 - 9 -: 8] = "o";
        pos_title_data[MAX_CHARS * 8 - 17 -: 8] = "s";
        pos_title_data[MAX_CHARS * 8 - 25 -: 8] = "/";
        pos_title_data[MAX_CHARS * 8 - 33 -: 8] = "I";
        pos_title_data[MAX_CHARS * 8 - 41 -: 8] = "d";
        pos_title_data[MAX_CHARS * 8 - 49 -: 8] = "x";
        pos_title_len = (show_detail_layout || show_summary_layout) ? 5'd7 : 5'd0;

        if (!show_hint_layout) begin
            coord_data[MAX_CHARS * 8 - 1 -: 8] = "#";
            coord_data[MAX_CHARS * 8 - 9 -: 8] = selected_component_index_valid ? ascii_sel_idx_hundreds : "-";
            coord_data[MAX_CHARS * 8 - 17 -: 8] = selected_component_index_valid ? ascii_sel_idx_tens : "-";
            coord_data[MAX_CHARS * 8 - 25 -: 8] = selected_component_index_valid ? ascii_sel_idx_ones : "-";
            coord_data[MAX_CHARS * 8 - 33 -: 8] = " ";
            coord_data[MAX_CHARS * 8 - 41 -: 8] = "(";
            coord_data[MAX_CHARS * 8 - 49 -: 8] = ascii_sel_i_tens;
            coord_data[MAX_CHARS * 8 - 57 -: 8] = ascii_sel_i_ones;
            coord_data[MAX_CHARS * 8 - 65 -: 8] = ",";
            coord_data[MAX_CHARS * 8 - 73 -: 8] = " ";
            coord_data[MAX_CHARS * 8 - 81 -: 8] = ascii_sel_j_tens;
            coord_data[MAX_CHARS * 8 - 89 -: 8] = ascii_sel_j_ones;
            coord_data[MAX_CHARS * 8 - 97 -: 8] = ")";
            coord_len = (show_detail_layout || show_summary_layout) ? 5'd13 : 5'd0;
        end

        value_label_data[MAX_CHARS * 8 - 1 -: 8] = "V";
        value_label_data[MAX_CHARS * 8 - 9 -: 8] = "a";
        value_label_data[MAX_CHARS * 8 - 17 -: 8] = "l";
        value_label_data[MAX_CHARS * 8 - 25 -: 8] = "u";
        value_label_data[MAX_CHARS * 8 - 33 -: 8] = "e";
        value_label_len = show_detail_layout ? 5'd5 : 5'd0;

        label_len = 5'd0;
        input_len = show_detail_layout ? {1'b0, selected_value_text_len} : 5'd0;

        if (!has_selection) begin
            label_len = 5'd0;
        end else if (is_wire) begin
            label_data[MAX_CHARS * 8 - 1 -: 8] = "W";
            label_data[MAX_CHARS * 8 - 9 -: 8] = "i";
            label_data[MAX_CHARS * 8 - 17 -: 8] = "r";
            label_data[MAX_CHARS * 8 - 25 -: 8] = "e";
            label_len = 5'd4;
        end else if (is_elbow) begin
            label_data[MAX_CHARS * 8 - 1 -: 8] = "E";
            label_data[MAX_CHARS * 8 - 9 -: 8] = "l";
            label_data[MAX_CHARS * 8 - 17 -: 8] = "b";
            label_data[MAX_CHARS * 8 - 25 -: 8] = "o";
            label_data[MAX_CHARS * 8 - 33 -: 8] = "w";
            label_len = 5'd5;
        end else if (is_tee) begin
            label_data[MAX_CHARS * 8 - 1 -: 8] = "T";
            label_data[MAX_CHARS * 8 - 9 -: 8] = "e";
            label_data[MAX_CHARS * 8 - 17 -: 8] = "e";
            label_len = 5'd3;
        end else if (is_junction) begin
            label_data[MAX_CHARS * 8 - 1 -: 8] = "J";
            label_data[MAX_CHARS * 8 - 9 -: 8] = "u";
            label_data[MAX_CHARS * 8 - 17 -: 8] = "n";
            label_data[MAX_CHARS * 8 - 25 -: 8] = "c";
            label_data[MAX_CHARS * 8 - 33 -: 8] = "t";
            label_data[MAX_CHARS * 8 - 41 -: 8] = "i";
            label_data[MAX_CHARS * 8 - 49 -: 8] = "o";
            label_data[MAX_CHARS * 8 - 57 -: 8] = "n";
            label_len = 5'd8;
        end else if (is_resistor) begin
            label_data[MAX_CHARS * 8 - 1 -: 8] = "R";
            label_data[MAX_CHARS * 8 - 9 -: 8] = "e";
            label_data[MAX_CHARS * 8 - 17 -: 8] = "s";
            label_data[MAX_CHARS * 8 - 25 -: 8] = "i";
            label_data[MAX_CHARS * 8 - 33 -: 8] = "s";
            label_data[MAX_CHARS * 8 - 41 -: 8] = "t";
            label_data[MAX_CHARS * 8 - 49 -: 8] = "o";
            label_data[MAX_CHARS * 8 - 57 -: 8] = "r";
            label_len = 5'd8;
        end else if (is_voltage) begin
            label_data[MAX_CHARS * 8 - 1 -: 8] = "V";
            label_data[MAX_CHARS * 8 - 9 -: 8] = "o";
            label_data[MAX_CHARS * 8 - 17 -: 8] = "l";
            label_data[MAX_CHARS * 8 - 25 -: 8] = "t";
            label_data[MAX_CHARS * 8 - 33 -: 8] = "a";
            label_data[MAX_CHARS * 8 - 41 -: 8] = "g";
            label_data[MAX_CHARS * 8 - 49 -: 8] = "e";
            label_data[MAX_CHARS * 8 - 57 -: 8] = " ";
            label_data[MAX_CHARS * 8 - 65 -: 8] = "S";
            label_data[MAX_CHARS * 8 - 73 -: 8] = "o";
            label_data[MAX_CHARS * 8 - 81 -: 8] = "u";
            label_data[MAX_CHARS * 8 - 89 -: 8] = "r";
            label_data[MAX_CHARS * 8 - 97 -: 8] = "c";
            label_data[MAX_CHARS * 8 - 105 -: 8] = "e";
            label_len = 5'd14;
        end else if (is_current) begin
            label_data[MAX_CHARS * 8 - 1 -: 8] = "C";
            label_data[MAX_CHARS * 8 - 9 -: 8] = "u";
            label_data[MAX_CHARS * 8 - 17 -: 8] = "r";
            label_data[MAX_CHARS * 8 - 25 -: 8] = "r";
            label_data[MAX_CHARS * 8 - 33 -: 8] = "e";
            label_data[MAX_CHARS * 8 - 41 -: 8] = "n";
            label_data[MAX_CHARS * 8 - 49 -: 8] = "t";
            label_data[MAX_CHARS * 8 - 57 -: 8] = " ";
            label_data[MAX_CHARS * 8 - 65 -: 8] = "S";
            label_data[MAX_CHARS * 8 - 73 -: 8] = "o";
            label_data[MAX_CHARS * 8 - 81 -: 8] = "u";
            label_data[MAX_CHARS * 8 - 89 -: 8] = "r";
            label_data[MAX_CHARS * 8 - 97 -: 8] = "c";
            label_data[MAX_CHARS * 8 - 105 -: 8] = "e";
            label_len = 5'd14;
        end else if (is_inductor) begin
            label_data[MAX_CHARS * 8 - 1 -: 8] = "I";
            label_data[MAX_CHARS * 8 - 9 -: 8] = "n";
            label_data[MAX_CHARS * 8 - 17 -: 8] = "d";
            label_data[MAX_CHARS * 8 - 25 -: 8] = "u";
            label_data[MAX_CHARS * 8 - 33 -: 8] = "c";
            label_data[MAX_CHARS * 8 - 41 -: 8] = "t";
            label_data[MAX_CHARS * 8 - 49 -: 8] = "o";
            label_data[MAX_CHARS * 8 - 57 -: 8] = "r";
            label_len = 5'd8;
        end else if (is_capacitor) begin
            label_data[MAX_CHARS * 8 - 1 -: 8] = "C";
            label_data[MAX_CHARS * 8 - 9 -: 8] = "a";
            label_data[MAX_CHARS * 8 - 17 -: 8] = "p";
            label_data[MAX_CHARS * 8 - 25 -: 8] = "a";
            label_data[MAX_CHARS * 8 - 33 -: 8] = "c";
            label_data[MAX_CHARS * 8 - 41 -: 8] = "i";
            label_data[MAX_CHARS * 8 - 49 -: 8] = "t";
            label_data[MAX_CHARS * 8 - 57 -: 8] = "o";
            label_data[MAX_CHARS * 8 - 65 -: 8] = "r";
            label_len = 5'd9;
        end else if (is_ground) begin
            label_data[MAX_CHARS * 8 - 1 -: 8] = "G";
            label_data[MAX_CHARS * 8 - 9 -: 8] = "r";
            label_data[MAX_CHARS * 8 - 17 -: 8] = "o";
            label_data[MAX_CHARS * 8 - 25 -: 8] = "u";
            label_data[MAX_CHARS * 8 - 33 -: 8] = "n";
            label_data[MAX_CHARS * 8 - 41 -: 8] = "d";
            label_len = 5'd6;
        end else begin
            label_data[MAX_CHARS * 8 - 1 -: 8] = "C";
            label_data[MAX_CHARS * 8 - 9 -: 8] = "l";
            label_data[MAX_CHARS * 8 - 17 -: 8] = "i";
            label_data[MAX_CHARS * 8 - 25 -: 8] = "c";
            label_data[MAX_CHARS * 8 - 33 -: 8] = "k";
            label_data[MAX_CHARS * 8 - 41 -: 8] = " ";
            label_data[MAX_CHARS * 8 - 49 -: 8] = "c";
            label_data[MAX_CHARS * 8 - 57 -: 8] = "o";
            label_data[MAX_CHARS * 8 - 65 -: 8] = "m";
            label_data[MAX_CHARS * 8 - 73 -: 8] = "p";
            label_data[MAX_CHARS * 8 - 81 -: 8] = "o";
            label_data[MAX_CHARS * 8 - 89 -: 8] = "n";
            label_data[MAX_CHARS * 8 - 97 -: 8] = "e";
            label_data[MAX_CHARS * 8 - 105 -: 8] = "n";
            label_data[MAX_CHARS * 8 - 113 -: 8] = "t";
            label_len = 5'd15;
        end

        if (show_detail_layout) begin
            input_data[MAX_CHARS * 8 - 1 -: 8] = selected_value_text[63:56];
            input_data[MAX_CHARS * 8 - 9 -: 8] = selected_value_text[55:48];
            input_data[MAX_CHARS * 8 - 17 -: 8] = selected_value_text[47:40];
            input_data[MAX_CHARS * 8 - 25 -: 8] = selected_value_text[39:32];
            input_data[MAX_CHARS * 8 - 33 -: 8] = selected_value_text[31:24];
            input_data[MAX_CHARS * 8 - 41 -: 8] = selected_value_text[23:16];
            input_data[MAX_CHARS * 8 - 49 -: 8] = selected_value_text[15:8];
            input_data[MAX_CHARS * 8 - 57 -: 8] = selected_value_text[7:0];
        end
    end

    always @(posedge clk_pixel) begin
        type_title_data_q <= type_title_data;
        type_title_len_q <= type_title_len;
        label_data_q <= label_data;
        label_len_q <= label_len;
        value_label_data_q <= value_label_data;
        value_label_len_q <= value_label_len;
        pos_title_data_q <= pos_title_data;
        pos_title_len_q <= pos_title_len;
        coord_data_q <= coord_data;
        coord_len_q <= coord_len;
        input_data_q <= input_data;
        input_len_q <= input_len;
    end

    wire type_title_text_enable;
    wire [11:0] type_title_text_color;
    wire label_text_enable;
    wire [11:0] label_text_color;
    wire value_label_text_enable;
    wire [11:0] value_label_text_color;
    wire pos_title_text_enable;
    wire [11:0] pos_title_text_color;
    wire coord_text_enable;
    wire [11:0] coord_text_color;
    wire input_text_enable;
    wire [11:0] input_text_color;

    DynamicTextBox #(
        .MAX_CHARS(MAX_CHARS),
        .CHAR_W_BASE(8),
        .CHAR_H_BASE(8)
    ) u_type_title_textbox (
        .clk_pixel(clk_pixel),
        .hcount(hcount),
        .vcount(vcount),
        .text_data(type_title_data_q),
        .text_len(type_title_len_q),
        .start_x(TYPE_X_POS),
        .start_y(TITLE_Y_POS),
        .scale(4'd1),
        .text_enable(type_title_text_enable),
        .text_color(type_title_text_color)
    );

    DynamicTextBox #(
        .MAX_CHARS(MAX_CHARS),
        .CHAR_W_BASE(8),
        .CHAR_H_BASE(8)
    ) u_label_textbox (
        .clk_pixel(clk_pixel),
        .hcount(hcount),
        .vcount(vcount),
        .text_data(label_data_q),
        .text_len(label_len_q),
        .start_x(label_x_pos),
        .start_y(label_y_pos),
        .scale(4'd1),
        .text_enable(label_text_enable),
        .text_color(label_text_color)
    );

    DynamicTextBox #(
        .MAX_CHARS(MAX_CHARS),
        .CHAR_W_BASE(8),
        .CHAR_H_BASE(8)
    ) u_value_label_textbox (
        .clk_pixel(clk_pixel),
        .hcount(hcount),
        .vcount(vcount),
        .text_data(value_label_data_q),
        .text_len(value_label_len_q),
        .start_x(VALUE_X_POS),
        .start_y(TITLE_Y_POS),
        .scale(4'd1),
        .text_enable(value_label_text_enable),
        .text_color(value_label_text_color)
    );

    DynamicTextBox #(
        .MAX_CHARS(MAX_CHARS),
        .CHAR_W_BASE(8),
        .CHAR_H_BASE(8)
    ) u_pos_title_textbox (
        .clk_pixel(clk_pixel),
        .hcount(hcount),
        .vcount(vcount),
        .text_data(pos_title_data_q),
        .text_len(pos_title_len_q),
        .start_x(POS_X_POS),
        .start_y(TITLE_Y_POS),
        .scale(4'd1),
        .text_enable(pos_title_text_enable),
        .text_color(pos_title_text_color)
    );

    DynamicTextBox #(
        .MAX_CHARS(MAX_CHARS),
        .CHAR_W_BASE(8),
        .CHAR_H_BASE(8)
    ) u_coord_textbox (
        .clk_pixel(clk_pixel),
        .hcount(hcount),
        .vcount(vcount),
        .text_data(coord_data_q),
        .text_len(coord_len_q),
        .start_x(coord_x_pos),
        .start_y(coord_y_pos),
        .scale(4'd1),
        .text_enable(coord_text_enable),
        .text_color(coord_text_color)
    );

    DynamicTextBox #(
        .MAX_CHARS(MAX_CHARS),
        .CHAR_W_BASE(8),
        .CHAR_H_BASE(8)
    ) u_input_textbox (
        .clk_pixel(clk_pixel),
        .hcount(hcount),
        .vcount(vcount),
        .text_data(input_data_q),
        .text_len(input_len_q),
        .start_x(INPUT_X_POS),
        .start_y(INPUT_Y_POS),
        .scale(4'd1),
        .text_enable(input_text_enable),
        .text_color(input_text_color)
    );

    wire in_panel =
                    (hcount >= PANEL_X) && (hcount < PANEL_X + PANEL_W) &&
                    (vcount >= PANEL_Y) && (vcount < PANEL_Y + PANEL_H);
    wire in_value_box = in_panel && show_detail_layout &&
                        (hcount >= VALUE_BOX_X0) && (hcount < VALUE_BOX_X1) &&
                        (vcount >= VALUE_BOX_Y0) && (vcount < VALUE_BOX_Y1);
    wire value_box_border = in_value_box &&
                            ((hcount == VALUE_BOX_X0) || (hcount == VALUE_BOX_X1 - 1) ||
                             (vcount == VALUE_BOX_Y0) || (vcount == VALUE_BOX_Y1 - 1));
    wire cursor_visible = value_edit_active && value_editable && blink_counter[22];
    wire cursor_active = cursor_visible && in_value_box &&
                         (hcount >= cursor_x0) && (hcount < cursor_x1) &&
                         (vcount >= (VALUE_BOX_Y0 + 12'd3)) && (vcount < (VALUE_BOX_Y1 - 12'd3));
    wire separator_active = in_panel && show_detail_layout &&
                            (((hcount == SEP0_X) || (hcount == SEP1_X)) &&
                             (vcount >= SEP_Y0) && (vcount < SEP_Y1));

    wire is_border = has_selection && in_panel && (
        (hcount == PANEL_X) || (hcount == PANEL_X + PANEL_W - 1) ||
        (vcount == PANEL_Y) || (vcount == PANEL_Y + PANEL_H - 1)
    );

    always @(posedge clk_pixel) begin
        blink_counter <= blink_counter + 1'b1;
    end

    always @(posedge clk_pixel) begin
        panel_rendered <= 1'b0;
        panel_rgb <= COLOR_BG;

        if (video_on && in_panel) begin
            panel_rendered <= 1'b1;
            if (is_border)
                panel_rgb <= COLOR_BORDER;
            else if (value_box_border)
                panel_rgb <= value_edit_active ? COLOR_BOX_ACTIVE : COLOR_BOX_BORDER;
            else if (separator_active)
                panel_rgb <= COLOR_BORDER;
            else if (type_title_text_enable)
                panel_rgb <= COLOR_CAPTION;
            else if (value_label_text_enable)
                panel_rgb <= COLOR_CAPTION;
            else if (pos_title_text_enable)
                panel_rgb <= COLOR_CAPTION;
            else if (label_text_enable)
                panel_rgb <= COLOR_TEXT;
            else if (input_text_enable)
                panel_rgb <= COLOR_TEXT;
            else if (coord_text_enable)
                panel_rgb <= COLOR_TEXT;
            else if (cursor_active)
                panel_rgb <= COLOR_BOX_ACTIVE;
            else if (in_value_box)
                panel_rgb <= COLOR_BOX_BG;
            else
                panel_rgb <= COLOR_BG;
        end
    end

endmodule
