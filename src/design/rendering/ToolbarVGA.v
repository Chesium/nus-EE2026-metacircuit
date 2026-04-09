`timescale 1ns / 1ps

module ToolbarVGA #(
    parameter integer BAR_X0 = 0,
    parameter integer BAR_Y0 = 64,
    parameter integer BAR_W = 64,
    parameter integer BAR_H = 288,
    parameter integer TOOLBAR_COUNT = 10,
    parameter integer BTN_X0 = 14,
    parameter integer BTN_W = 36,
    parameter integer BTN_H = 24,
    parameter integer BTN_GAP = 2,
    parameter integer BTN_Y0 = 72,
    parameter integer ICON_X0 = 20,
    parameter integer ICON_W = 24,
    parameter integer ICON_H = 24
) (
    input  wire        clk_pixel,
    input  wire [11:0] mouse_x,
    input  wire [11:0] mouse_y,
    input  wire        mouse_left,
    input  wire [11:0] x,
    input  wire [11:0] y,
    output reg  [11:0] pixel_rgb,
    output wire        rendered,
    output reg  [3:0]  selected_tool_idx = 4'd0,
    output reg  [1:0]  selected_wire_variant = 2'd0
);

    wire [TOOLBAR_COUNT-1:0] button_inside;
    wire [(TOOLBAR_COUNT*12)-1:0] button_rgb_bus;
    reg  [3:0] hovered_tool_idx;
    reg        hover_valid;
    reg        mouse_left_d = 1'b0;
    wire       mouse_left_rising;
    reg  [23:0] toolbar_row_bits;
    reg         toolbar_bitmap_active;
    reg  [3:0]  display_icon_idx;
    integer     k;

    function integer button_y0;
        input integer idx;
        begin
            button_y0 = BTN_Y0 + (idx * (BTN_H + BTN_GAP));
        end
    endfunction

    function integer icon_y0;
        input integer idx;
        begin
            icon_y0 = button_y0(idx) + ((BTN_H - ICON_H) / 2);
        end
    endfunction

    function [23:0] toolbar_bitmap_row;
        input integer icon_idx;
        input integer row_idx;
        begin
            toolbar_bitmap_row = 24'b0;
            case (icon_idx)
                0: begin
                    case (row_idx)
                        0: toolbar_bitmap_row = 24'b001100000000000000000000;
                        1: toolbar_bitmap_row = 24'b111110000000000000000000;
                        2: toolbar_bitmap_row = 24'b110011000000000010000000;
                        3: toolbar_bitmap_row = 24'b110011001101111111100000;
                        4: toolbar_bitmap_row = 24'b010001111111111101100000;
                        5: toolbar_bitmap_row = 24'b011001110011001100110000;
                        6: toolbar_bitmap_row = 24'b001100110011001100010000;
                        7: toolbar_bitmap_row = 24'b001100110001100110011000;
                        8: toolbar_bitmap_row = 24'b000110011001100110001100;
                        9: toolbar_bitmap_row = 24'b000110001000110010001100;
                        10: toolbar_bitmap_row = 24'b000011001100000000000110;
                        11: toolbar_bitmap_row = 24'b000001000100000000000110;
                        12: toolbar_bitmap_row = 24'b000001100000000000000011;
                        13: toolbar_bitmap_row = 24'b001111100000000000000011;
                        14: toolbar_bitmap_row = 24'b011111110000000000000011;
                        15: toolbar_bitmap_row = 24'b110000111000000000000011;
                        16: toolbar_bitmap_row = 24'b011000010000000000000011;
                        17: toolbar_bitmap_row = 24'b001110000000000000000110;
                        18: toolbar_bitmap_row = 24'b000111000000000000001110;
                        19: toolbar_bitmap_row = 24'b000001100000000000011100;
                        20: toolbar_bitmap_row = 24'b000000111000000001110000;
                        21: toolbar_bitmap_row = 24'b000000011100000111100000;
                        22: toolbar_bitmap_row = 24'b000000000111111110000000;
                        default: toolbar_bitmap_row = 24'b000000000001111000000000;
                    endcase
                end
                1: begin
                    case (row_idx)
                        11: toolbar_bitmap_row = 24'b000111111111111111111000;
                        12: toolbar_bitmap_row = 24'b000111111111111111111000;
                        13: toolbar_bitmap_row = 24'b000111111111111111111000;
                        default: toolbar_bitmap_row = 24'b000000000000000000000000;
                    endcase
                end
                2: begin
                    case (row_idx)
                        6:  toolbar_bitmap_row = 24'b000001110001110011100000;
                        7:  toolbar_bitmap_row = 24'b000001110001110011100000;
                        8:  toolbar_bitmap_row = 24'b000011010001010011110000;
                        9:  toolbar_bitmap_row = 24'b000011011011011010110000;
                        10: toolbar_bitmap_row = 24'b000011011011011110110000;
                        11: toolbar_bitmap_row = 24'b000110011011011110011000;
                        12: toolbar_bitmap_row = 24'b011110001010001110011110;
                        13: toolbar_bitmap_row = 24'b011110001110001110011110;
                        14: toolbar_bitmap_row = 24'b000000001110001110000000;
                        15: toolbar_bitmap_row = 24'b000000001110001100000000;
                        16: toolbar_bitmap_row = 24'b000000000100001100000000;
                        17: toolbar_bitmap_row = 24'b000000001110001110000000;
                        default: toolbar_bitmap_row = 24'b000000000000000000000000;
                    endcase
                end
                3: begin
                    case (row_idx)
                        0: toolbar_bitmap_row = 24'b000000000000000000000000;
                        1: toolbar_bitmap_row = 24'b000000000000110000000000;
                        2: toolbar_bitmap_row = 24'b000000000011110000000000;
                        3: toolbar_bitmap_row = 24'b000000000111100000000000;
                        4: toolbar_bitmap_row = 24'b000000001110000000000000;
                        5: toolbar_bitmap_row = 24'b000000001100000000000000;
                        6: toolbar_bitmap_row = 24'b000000001111110000000000;
                        7: toolbar_bitmap_row = 24'b000000000111111000000000;
                        8: toolbar_bitmap_row = 24'b000000001111100000000000;
                        9: toolbar_bitmap_row = 24'b000000001100000000000000;
                        10: toolbar_bitmap_row = 24'b000000001111110000000000;
                        11: toolbar_bitmap_row = 24'b000000000111111000000000;
                        12: toolbar_bitmap_row = 24'b000000001111100000000000;
                        13: toolbar_bitmap_row = 24'b000000001100000000000000;
                        14: toolbar_bitmap_row = 24'b000000001111110000000000;
                        15: toolbar_bitmap_row = 24'b000000000111111000000000;
                        16: toolbar_bitmap_row = 24'b000000001111100000000000;
                        17: toolbar_bitmap_row = 24'b000000001100000000000000;
                        18: toolbar_bitmap_row = 24'b000000001110000000000000;
                        19: toolbar_bitmap_row = 24'b000000000111110000000000;
                        20: toolbar_bitmap_row = 24'b000000000011110000000000;
                        21: toolbar_bitmap_row = 24'b000000000000110000000000;
                        22: toolbar_bitmap_row = 24'b000000000000000000000000;
                        default: toolbar_bitmap_row = 24'b000000000000110000000000;
                    endcase
                end
                4: begin
                    case (row_idx)
                        7:  toolbar_bitmap_row = 24'b000000000110011000000000;
                        8:  toolbar_bitmap_row = 24'b000000000110011000000000;
                        9:  toolbar_bitmap_row = 24'b000000000110011000000000;
                        10: toolbar_bitmap_row = 24'b000000000110011000000000;
                        11: toolbar_bitmap_row = 24'b001111111110011111111100;
                        12: toolbar_bitmap_row = 24'b001111111110011111111100;
                        13: toolbar_bitmap_row = 24'b000000000110011000000000;
                        14: toolbar_bitmap_row = 24'b000000000110011000000000;
                        15: toolbar_bitmap_row = 24'b000000000110011000000000;
                        16: toolbar_bitmap_row = 24'b000000000110011000000000;
                        default: toolbar_bitmap_row = 24'b000000000000000000000000;
                    endcase
                end
                5: begin
                    case (row_idx)
                        2:  toolbar_bitmap_row = 24'b000000000111111000000000;
                        3:  toolbar_bitmap_row = 24'b000000011111111110000000;
                        4:  toolbar_bitmap_row = 24'b000000111000000111000000;
                        5:  toolbar_bitmap_row = 24'b000001100000000001100000;
                        6:  toolbar_bitmap_row = 24'b000011000001100000110000;
                        7:  toolbar_bitmap_row = 24'b000110000001100000011000;
                        8:  toolbar_bitmap_row = 24'b000110000001100000011000;
                        9:  toolbar_bitmap_row = 24'b001100001111111100001100;
                        10: toolbar_bitmap_row = 24'b001100001111111100001100;
                        11: toolbar_bitmap_row = 24'b001100000001100000001100;
                        12: toolbar_bitmap_row = 24'b001100000001100000001100;
                        13: toolbar_bitmap_row = 24'b001100000000000000001100;
                        14: toolbar_bitmap_row = 24'b001100000000000000001100;
                        15: toolbar_bitmap_row = 24'b000110000000000000011000;
                        16: toolbar_bitmap_row = 24'b00011000111111100011000;
                        17: toolbar_bitmap_row = 24'b00001100111111100110000;
                        18: toolbar_bitmap_row = 24'b000001100000000001100000;
                        19: toolbar_bitmap_row = 24'b000000111000000111000000;
                        20: toolbar_bitmap_row = 24'b000000011111111110000000;
                        21: toolbar_bitmap_row = 24'b000000000111111000000000;
                        default: toolbar_bitmap_row = 24'b000000000000000000000000;
                    endcase
                end
                6: begin
                    case (row_idx)
                        2:  toolbar_bitmap_row = 24'b000000000111111000000000;
                        3:  toolbar_bitmap_row = 24'b000000011111111110000000;
                        4:  toolbar_bitmap_row = 24'b000000111000000111000000;
                        5:  toolbar_bitmap_row = 24'b000001100000000001100000;
                        6:  toolbar_bitmap_row = 24'b000011000011100000110000;
                        7:  toolbar_bitmap_row = 24'b000110000011100000011000;
                        8:  toolbar_bitmap_row = 24'b000110000011100000011000;
                        9:  toolbar_bitmap_row = 24'b001100000011100000001100;
                        10: toolbar_bitmap_row = 24'b001100000011100000001100;
                        11: toolbar_bitmap_row = 24'b001100000011100000001100;
                        12: toolbar_bitmap_row = 24'b001100000011100000001100;
                        13: toolbar_bitmap_row = 24'b001100000011100000001100;
                        14: toolbar_bitmap_row = 24'b001100011111111100001100;
                        15: toolbar_bitmap_row = 24'b000110001111111000011000;
                        16: toolbar_bitmap_row = 24'b000110000111110000011000;
                        17: toolbar_bitmap_row = 24'b00001100000100000110000;
                        18: toolbar_bitmap_row = 24'b000001100000000001100000;
                        19: toolbar_bitmap_row = 24'b000000111000000111000000;
                        20: toolbar_bitmap_row = 24'b000000011111111110000000;
                        21: toolbar_bitmap_row = 24'b000000000111111000000000;
                        default: toolbar_bitmap_row = 24'b000000000000000000000000;
                    endcase
                end
                7: begin
                    case (row_idx)
                        2:  toolbar_bitmap_row = 24'b000000000001110000000000;
                        3:  toolbar_bitmap_row = 24'b000000000001110000000000;
                        4:  toolbar_bitmap_row = 24'b000000000001110000000000;
                        5:  toolbar_bitmap_row = 24'b000000000001110000000000;
                        6:  toolbar_bitmap_row = 24'b000000000001110000000000;
                        7:  toolbar_bitmap_row = 24'b000000000001110000000000;
                        8:  toolbar_bitmap_row = 24'b000000000001110000000000;
                        9:  toolbar_bitmap_row = 24'b000000000001110000000000;
                        10: toolbar_bitmap_row = 24'b000001111111111111110000;
                        11: toolbar_bitmap_row = 24'b000001111111111111110000;
                        12: toolbar_bitmap_row = 24'b000000111000000011100000;
                        13: toolbar_bitmap_row = 24'b000000011100000110000000;
                        14: toolbar_bitmap_row = 24'b000000001100000110000000;
                        15: toolbar_bitmap_row = 24'b000000000110001100000000;
                        16: toolbar_bitmap_row = 24'b000000000111011000000000;
                        17: toolbar_bitmap_row = 24'b000000000011111000000000;
                        18: toolbar_bitmap_row = 24'b000000000001110000000000;
                        19: toolbar_bitmap_row = 24'b000000000001110000000000;
                        20: toolbar_bitmap_row = 24'b000000000000100000000000;
                        default: toolbar_bitmap_row = 24'b000000000000000000000000;
                    endcase
                end
                8: begin
                    case (row_idx)
                        3:  toolbar_bitmap_row = 24'b000000000000000000000000;
                        4:  toolbar_bitmap_row = 24'b000000000000000000000000;
                        5:  toolbar_bitmap_row = 24'b000011111111111111110000;
                        6:  toolbar_bitmap_row = 24'b000011111111111111110000;
                        7:  toolbar_bitmap_row = 24'b000011111111111111110000;
                        8:  toolbar_bitmap_row = 24'b000000000000000001110000;
                        9:  toolbar_bitmap_row = 24'b000000000000000001110000;
                        10: toolbar_bitmap_row = 24'b000001000000000001110000;
                        11: toolbar_bitmap_row = 24'b000011100000000001110000;
                        12: toolbar_bitmap_row = 24'b000111110000000001110000;
                        13: toolbar_bitmap_row = 24'b000011100000000001110000;
                        14: toolbar_bitmap_row = 24'b000011100000000001110000;
                        15: toolbar_bitmap_row = 24'b000011100000000001110000;
                        16: toolbar_bitmap_row = 24'b000011111111111111110000;
                        17: toolbar_bitmap_row = 24'b000011111111111111110000;
                        18: toolbar_bitmap_row = 24'b000011111111111111110000;
                        19: toolbar_bitmap_row = 24'b000000000000000000000000;
                        20: toolbar_bitmap_row = 24'b000000000000000000000000;
                        default: toolbar_bitmap_row = 24'b000000000000000000000000;
                    endcase
                end
                10: begin
                    case (row_idx)
                        11: toolbar_bitmap_row = 24'b000111111111111111111000;
                        12: toolbar_bitmap_row = 24'b000111111111111111111000;
                        13: toolbar_bitmap_row = 24'b000111111111111111111000;
                        default: toolbar_bitmap_row = 24'b000000000000000000000000;
                    endcase
                end
                11: begin
                    case (row_idx)
                        4:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        5:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        6:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        7:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        8:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        9:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        10: toolbar_bitmap_row = 24'b000000000011110000000000;
                        11: toolbar_bitmap_row = 24'b000111111111111111111000;
                        12: toolbar_bitmap_row = 24'b000111111111111111111000;
                        13: toolbar_bitmap_row = 24'b000111111111111111111000;
                        14: toolbar_bitmap_row = 24'b000000000011110000000000;
                        15: toolbar_bitmap_row = 24'b000000000011110000000000;
                        16: toolbar_bitmap_row = 24'b000000000011110000000000;
                        17: toolbar_bitmap_row = 24'b000000000011110000000000;
                        18: toolbar_bitmap_row = 24'b000000000011110000000000;
                        19: toolbar_bitmap_row = 24'b000000000011110000000000;
                        20: toolbar_bitmap_row = 24'b000000000011110000000000;
                        default: toolbar_bitmap_row = 24'b000000000000000000000000;
                    endcase
                end
                12: begin
                    case (row_idx)
                        4:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        5:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        6:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        7:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        8:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        9:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        10: toolbar_bitmap_row = 24'b000000000011110000000000;
                        11: toolbar_bitmap_row = 24'b000000000011111111111000;
                        12: toolbar_bitmap_row = 24'b000000000011111111111000;
                        13: toolbar_bitmap_row = 24'b000000000011111111111000;
                        14: toolbar_bitmap_row = 24'b000000000000000000000000;
                        15: toolbar_bitmap_row = 24'b000000000000000000000000;
                        16: toolbar_bitmap_row = 24'b000000000000000000000000;
                        17: toolbar_bitmap_row = 24'b000000000000000000000000;
                        default: toolbar_bitmap_row = 24'b000000000000000000000000;
                    endcase
                end
                13: begin
                    case (row_idx)
                        4:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        5:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        6:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        7:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        8:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        9:  toolbar_bitmap_row = 24'b000000000011110000000000;
                        10: toolbar_bitmap_row = 24'b000000000011110000000000;
                        11: toolbar_bitmap_row = 24'b000111111111111111111000;
                        12: toolbar_bitmap_row = 24'b000111111111111111111000;
                        13: toolbar_bitmap_row = 24'b000111111111111111111000;
                        14: toolbar_bitmap_row = 24'b000000000000000000000000;
                        15: toolbar_bitmap_row = 24'b000000000000000000000000;
                        16: toolbar_bitmap_row = 24'b000000000000000000000000;
                        17: toolbar_bitmap_row = 24'b000000000000000000000000;
                        18: toolbar_bitmap_row = 24'b000000000000000000000000;
                        19: toolbar_bitmap_row = 24'b000000000000000000000000;
                        20: toolbar_bitmap_row = 24'b000000000000000000000000;
                        default: toolbar_bitmap_row = 24'b000000000000000000000000;
                    endcase
                end
                default: begin
                    case (row_idx)
                        3:  toolbar_bitmap_row = 24'b000000000000000000000000;
                        4:  toolbar_bitmap_row = 24'b000111000000000000111000;
                        5:  toolbar_bitmap_row = 24'b000011100000000001110000;
                        6:  toolbar_bitmap_row = 24'b000001110000000011100000;
                        7:  toolbar_bitmap_row = 24'b000000111000000111000000;
                        8:  toolbar_bitmap_row = 24'b000000011100001110000000;
                        9:  toolbar_bitmap_row = 24'b000000001110011100000000;
                        10: toolbar_bitmap_row = 24'b000000000111111000000000;
                        11: toolbar_bitmap_row = 24'b000000000111111000000000;
                        12: toolbar_bitmap_row = 24'b000000001110011100000000;
                        13: toolbar_bitmap_row = 24'b000000011100001110000000;
                        14: toolbar_bitmap_row = 24'b000000111000000111000000;
                        15: toolbar_bitmap_row = 24'b00000111000000001110000;
                        16: toolbar_bitmap_row = 24'b000011100000000001110000;
                        17: toolbar_bitmap_row = 24'b000111000000000000111000;
                        18: toolbar_bitmap_row = 24'b000000000000000000000000;
                        default: toolbar_bitmap_row = 24'b000000000000000000000000;
                    endcase
                end
            endcase
        end
    endfunction

    function [11:0] rgb888_to_444;
        input [23:0] c;
        begin
            rgb888_to_444 = {c[23:20], c[15:12], c[7:4]};
        end
    endfunction

    assign rendered = (x >= BAR_X0) && (x < (BAR_X0 + BAR_W)) &&
                      (y >= BAR_Y0) && (y < (BAR_Y0 + BAR_H));
    assign mouse_left_rising = mouse_left && !mouse_left_d;

    always @(*) begin
        hover_valid = 1'b0;
        hovered_tool_idx = 4'd0;
        if ((mouse_x >= BTN_X0) && (mouse_x < (BTN_X0 + BTN_W))) begin
            for (k = 0; k < TOOLBAR_COUNT; k = k + 1) begin
                if ((mouse_y >= button_y0(k)) && (mouse_y < (button_y0(k) + BTN_H))) begin
                    hover_valid = 1'b1;
                    hovered_tool_idx = k[3:0];
                end
            end
        end
    end

    always @(posedge clk_pixel) begin
        mouse_left_d <= mouse_left;
        if (mouse_left_rising && hover_valid) begin
            if (hovered_tool_idx == 4'd1) begin
                if (selected_tool_idx == 4'd1) begin
                    selected_wire_variant <= selected_wire_variant + 1'b1;
                end else begin
                    selected_wire_variant <= 2'd0;
                end
            end
            selected_tool_idx <= hovered_tool_idx;
        end
    end

    genvar btn_idx;
    generate
        for (btn_idx = 0; btn_idx < TOOLBAR_COUNT; btn_idx = btn_idx + 1) begin : toolbar_button_gen
            ButtonVGA #(
                .X0(BTN_X0),
                .Y0(button_y0(btn_idx)),
                .W(BTN_W),
                .H(BTN_H),
                .BORDER(2),
                .EDGE_THICK(2),
                .MARKER_OFFSET(5),
                .MARKER_W(2),
                .MARKER_H(2),
                .FONT5_SCALE(1),
                .FONT3_SCALE(1),
                .LABEL0(8'h00),
                .TEXT_COLS(1),
                .FACE_RGB(24'hF4E7D5),
                .BORDER_RGB(24'hC9AE8E),
                .SELECTED_BORDER_RGB(24'hD96B3B),
                .SELECTED_MARKER_RGB(24'hFFF7D2),
                .PRESSED_BORDER_RGB(24'hA54924),
                .TEXT_RGB(24'hF4E7D5)
            ) toolbar_button_inst (
                .enabled(1'b1),
                .selected(selected_tool_idx == btn_idx[3:0]),
                .pressed(mouse_left && hover_valid && (hovered_tool_idx == btn_idx[3:0])),
                .x(x),
                .y(y),
                .pixel_rgb(button_rgb_bus[(btn_idx * 12) +: 12]),
                .inside_button(button_inside[btn_idx])
            );
        end
    endgenerate

    always @(*) begin
        pixel_rgb = rgb888_to_444(24'hF3D9B8);
        toolbar_bitmap_active = 1'b0;
        toolbar_row_bits = 24'b0;

        for (k = 0; k < TOOLBAR_COUNT; k = k + 1) begin
            if (button_inside[k]) begin
                pixel_rgb = button_rgb_bus[(k * 12) +: 12];
            end
        end

        for (k = 0; k < TOOLBAR_COUNT; k = k + 1) begin
            if ((x >= ICON_X0) && (x < (ICON_X0 + ICON_W)) &&
                (y >= icon_y0(k)) && (y < (icon_y0(k) + ICON_H))) begin
                display_icon_idx = k[3:0];
                if (k == 1) begin
                    case (selected_wire_variant)
                        2'd0: display_icon_idx = 4'd10;
                        2'd1: display_icon_idx = 4'd11;
                        2'd2: display_icon_idx = 4'd12;
                        default: display_icon_idx = 4'd13;
                    endcase
                end
                toolbar_row_bits = toolbar_bitmap_row(display_icon_idx, y - icon_y0(k));
                if (toolbar_row_bits[23 - (x - ICON_X0)]) toolbar_bitmap_active = 1'b1;
            end
        end

        if (toolbar_bitmap_active) pixel_rgb = 12'h000;
    end

endmodule
