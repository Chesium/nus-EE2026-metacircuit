`timescale 1ns / 1ps

package ToolbarPkg;
    import UiThemePkg::*;

    localparam int TOOLBAR_TOOL_COUNT = 11;

    localparam logic [3:0] MODE_SELECT   = 4'd0;
    localparam logic [3:0] MODE_WIRE     = 4'd1;
    localparam logic [3:0] MODE_JUNCTION = 4'd2;
    localparam logic [3:0] MODE_ELBOW    = 4'd3;
    localparam logic [3:0] MODE_TEE      = 4'd4;
    localparam logic [3:0] MODE_RES      = 4'd5;
    localparam logic [3:0] MODE_VOLT     = 4'd6;
    localparam logic [3:0] MODE_CURR     = 4'd7;
    localparam logic [3:0] MODE_ROTATE   = 4'd8;
    localparam logic [3:0] MODE_DELETE   = 4'd9;
    localparam logic [3:0] MODE_GROUND   = 4'd10;

    localparam int TOOLBAR_SLOT_X = UI_TOOLBAR_X + 8;
    localparam int TOOLBAR_SLOT_Y0 = UI_TOOLBAR_Y + 8;
    localparam int TOOLBAR_SLOT_W = UI_TOOLBAR_W - 16;
    localparam int TOOLBAR_SLOT_H = 20;
    localparam int TOOLBAR_SLOT_GAP = 4;
    localparam int TOOLBAR_LABEL_Y_PAD = 6;

    function automatic logic [3:0] tool_mode_by_index(input int index);
        begin
            case (index)
                0: tool_mode_by_index = MODE_SELECT;
                1: tool_mode_by_index = MODE_WIRE;
                2: tool_mode_by_index = MODE_JUNCTION;
                3: tool_mode_by_index = MODE_ELBOW;
                4: tool_mode_by_index = MODE_TEE;
                5: tool_mode_by_index = MODE_GROUND;
                6: tool_mode_by_index = MODE_RES;
                7: tool_mode_by_index = MODE_VOLT;
                8: tool_mode_by_index = MODE_CURR;
                9: tool_mode_by_index = MODE_ROTATE;
                default: tool_mode_by_index = MODE_DELETE;
            endcase
        end
    endfunction

    function automatic logic tool_mode_valid(input logic [3:0] mode);
        begin
            case (mode)
                MODE_SELECT,
                MODE_WIRE,
                MODE_JUNCTION,
                MODE_ELBOW,
                MODE_TEE,
                MODE_GROUND,
                MODE_RES,
                MODE_VOLT,
                MODE_CURR,
                MODE_ROTATE,
                MODE_DELETE: tool_mode_valid = 1'b1;
                default:     tool_mode_valid = 1'b0;
            endcase
        end
    endfunction

    function automatic logic [3:0] sanitize_tool_mode(input logic [3:0] mode);
        begin
            sanitize_tool_mode = tool_mode_valid(mode) ? mode : MODE_SELECT;
        end
    endfunction

    function automatic logic [3:0] tool_index_from_mode(input logic [3:0] mode);
        int idx;
        begin
            tool_index_from_mode = 4'd0;
            for (idx = 0; idx < TOOLBAR_TOOL_COUNT; idx = idx + 1) begin
                if (tool_mode_by_index(idx) == mode) begin
                    tool_index_from_mode = idx[3:0];
                end
            end
        end
    endfunction

    function automatic logic tool_is_component_mode(input logic [3:0] mode);
        begin
            case (mode)
                MODE_RES,
                MODE_VOLT,
                MODE_CURR: tool_is_component_mode = 1'b1;
                default:   tool_is_component_mode = 1'b0;
            endcase
        end
    endfunction

    function automatic logic [11:0] tool_color_by_index(input int index);
        begin
            case (index)
                0: tool_color_by_index = 12'h89A;
                1: tool_color_by_index = 12'h4AF;
                2: tool_color_by_index = 12'h2CC;
                3: tool_color_by_index = 12'h3BD;
                4: tool_color_by_index = 12'h28A;
                5: tool_color_by_index = 12'h4B8;
                6: tool_color_by_index = 12'hDA6;
                7: tool_color_by_index = 12'hD66;
                8: tool_color_by_index = 12'h6CC;
                9: tool_color_by_index = 12'hF9A;
                default: tool_color_by_index = 12'hE54;
            endcase
        end
    endfunction

    function automatic logic [255:0] tool_label_data(input int index);
        begin
            case (index)
                0: tool_label_data = {"SEL", 232'd0};
                1: tool_label_data = {"WIR", 232'd0};
                2: tool_label_data = {"JUN", 232'd0};
                3: tool_label_data = {"ELB", 232'd0};
                4: tool_label_data = {"TEE", 232'd0};
                5: tool_label_data = {"GND", 232'd0};
                6: tool_label_data = {"RES", 232'd0};
                7: tool_label_data = {"VLT", 232'd0};
                8: tool_label_data = {"CUR", 232'd0};
                9: tool_label_data = {"ROT", 232'd0};
                default: tool_label_data = {"DEL", 232'd0};
            endcase
        end
    endfunction

    function automatic logic [5:0] tool_label_len(input int index);
        begin
            case (index)
                default: tool_label_len = 6'd3;
            endcase
        end
    endfunction

    function automatic logic [11:0] toolbar_slot_x(input int index);
        begin
            toolbar_slot_x = TOOLBAR_SLOT_X[11:0];
        end
    endfunction

    function automatic logic [11:0] toolbar_slot_y(input int index);
        begin
            toolbar_slot_y = TOOLBAR_SLOT_Y0 + (index * (TOOLBAR_SLOT_H + TOOLBAR_SLOT_GAP));
        end
    endfunction

    function automatic logic [11:0] toolbar_label_y(input int index);
        begin
            toolbar_label_y = TOOLBAR_SLOT_Y0 + (index * (TOOLBAR_SLOT_H + TOOLBAR_SLOT_GAP)) + TOOLBAR_LABEL_Y_PAD;
        end
    endfunction

    function automatic logic toolbar_inside(input logic [11:0] x, input logic [11:0] y);
        begin
            toolbar_inside = (x >= UI_TOOLBAR_X) && (x < UI_TOOLBAR_X + UI_TOOLBAR_W) &&
                             (y >= UI_TOOLBAR_Y) && (y < UI_TOOLBAR_Y + UI_TOOLBAR_H);
        end
    endfunction

    function automatic logic toolbar_slot_contains(
        input logic [11:0] x,
        input logic [11:0] y,
        input int index
    );
        logic [11:0] slot_y;
        begin
            slot_y = toolbar_slot_y(index);
            toolbar_slot_contains = (x >= TOOLBAR_SLOT_X) && (x < TOOLBAR_SLOT_X + TOOLBAR_SLOT_W) &&
                                    (y >= slot_y) && (y < slot_y + TOOLBAR_SLOT_H);
        end
    endfunction

    function automatic logic toolbar_hit_valid(input logic [11:0] x, input logic [11:0] y);
        int idx;
        begin
            toolbar_hit_valid = 1'b0;
            for (idx = 0; idx < TOOLBAR_TOOL_COUNT; idx = idx + 1) begin
                if (toolbar_slot_contains(x, y, idx)) begin
                    toolbar_hit_valid = 1'b1;
                end
            end
        end
    endfunction

    function automatic logic [3:0] toolbar_hit_index(input logic [11:0] x, input logic [11:0] y);
        int idx;
        begin
            toolbar_hit_index = 4'd0;
            for (idx = 0; idx < TOOLBAR_TOOL_COUNT; idx = idx + 1) begin
                if (toolbar_slot_contains(x, y, idx)) begin
                    toolbar_hit_index = idx[3:0];
                end
            end
        end
    endfunction
endpackage
