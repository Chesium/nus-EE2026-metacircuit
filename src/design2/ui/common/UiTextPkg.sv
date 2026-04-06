`timescale 1ns / 1ps

package UiTextPkg;
    localparam int UI_TEXT_CHAR_W       = 8;
    localparam int UI_TEXT_CHAR_H       = 8;
    localparam int UI_TEXT_MAX_CHARS    = 32;
    localparam int UI_TEXT_LEN_W        = 6;
    localparam logic [1:0] UI_ALIGN_LEFT   = 2'd0;
    localparam logic [1:0] UI_ALIGN_CENTER = 2'd1;
    localparam logic [1:0] UI_ALIGN_RIGHT  = 2'd2;

    function automatic logic [3:0] sanitize_scale(input logic [3:0] scale);
        begin
            case (scale)
                4'd1, 4'd2, 4'd4, 4'd8: sanitize_scale = scale;
                default:                sanitize_scale = 4'd1;
            endcase
        end
    endfunction

    function automatic logic [2:0] scale_shift(input logic [3:0] scale);
        begin
            case (sanitize_scale(scale))
                4'd8: scale_shift = 3'd3;
                4'd4: scale_shift = 3'd2;
                4'd2: scale_shift = 3'd1;
                default: scale_shift = 3'd0;
            endcase
        end
    endfunction

    function automatic logic [11:0] scale_mask(input logic [3:0] scale);
        begin
            case (sanitize_scale(scale))
                4'd8: scale_mask = 12'd63;
                4'd4: scale_mask = 12'd31;
                4'd2: scale_mask = 12'd15;
                default: scale_mask = 12'd7;
            endcase
        end
    endfunction

    function automatic logic [11:0] char_span(input logic [3:0] scale);
        begin
            char_span = UI_TEXT_CHAR_W * sanitize_scale(scale);
        end
    endfunction

    function automatic logic [11:0] text_width(
        input logic [UI_TEXT_LEN_W-1:0] text_len,
        input logic [3:0] scale
    );
        begin
            text_width = char_span(scale) * text_len;
        end
    endfunction

    function automatic logic [11:0] aligned_start_x(
        input logic [11:0] base_x,
        input logic [11:0] region_width,
        input logic [UI_TEXT_LEN_W-1:0] text_len,
        input logic [3:0] scale,
        input logic [1:0] align
    );
        logic [11:0] rendered_width;
        logic [11:0] spare_width;
        begin
            rendered_width = text_width(text_len, scale);
            if ((region_width == 12'd0) || (region_width <= rendered_width)) begin
                aligned_start_x = base_x;
            end else begin
                spare_width = region_width - rendered_width;
                case (align)
                    UI_ALIGN_CENTER: aligned_start_x = base_x + (spare_width >> 1);
                    UI_ALIGN_RIGHT:  aligned_start_x = base_x + spare_width;
                    default:         aligned_start_x = base_x;
                endcase
            end
        end
    endfunction
endpackage
