`timescale 1ns / 1ps

module ToolbarRenderer (
    input  wire        clk_pixel,
    input  wire        video_on,
    input  wire [11:0] hcount,
    input  wire [11:0] vcount,
    input  wire [11:0] mouse_x,
    input  wire [11:0] mouse_y,
    input  wire        mouse_left,
    input  wire [3:0]  selected_mode,
    output reg         rendered,
    output reg  [11:0] rgb
);
    import UiThemePkg::*;
    import UiTextPkg::*;
    import ToolbarPkg::*;

    function automatic logic [11:0] brighten_color(input logic [11:0] color);
        logic [4:0] r;
        logic [4:0] g;
        logic [4:0] b;
        begin
            r = color[11:8] + 1'b1;
            g = color[7:4] + 1'b1;
            b = color[3:0] + 1'b1;
            brighten_color = {
                (r > 5'd15) ? 4'hF : r[3:0],
                (g > 5'd15) ? 4'hF : g[3:0],
                (b > 5'd15) ? 4'hF : b[3:0]
            };
        end
    endfunction

    function automatic logic [11:0] darken_color(input logic [11:0] color);
        logic [4:0] r;
        logic [4:0] g;
        logic [4:0] b;
        begin
            r = (color[11:8] > 0) ? (color[11:8] - 1'b1) : 5'd0;
            g = (color[7:4] > 0) ? (color[7:4] - 1'b1) : 5'd0;
            b = (color[3:0] > 0) ? (color[3:0] - 1'b1) : 5'd0;
            darken_color = {r[3:0], g[3:0], b[3:0]};
        end
    endfunction

    function automatic logic slot_border_pixel(
        input logic [11:0] x,
        input logic [11:0] y,
        input int index
    );
        logic [11:0] sx;
        logic [11:0] sy;
        begin
            sx = toolbar_slot_x(index);
            sy = toolbar_slot_y(index);
            slot_border_pixel =
                (x == sx) ||
                (x == (sx + TOOLBAR_SLOT_W - 1)) ||
                (y == sy) ||
                (y == (sy + TOOLBAR_SLOT_H - 1));
        end
    endfunction

    wire [TOOLBAR_TOOL_COUNT-1:0] slot_inside;
    wire [TOOLBAR_TOOL_COUNT-1:0] slot_hovered;
    wire [TOOLBAR_TOOL_COUNT-1:0] slot_selected;
    wire [TOOLBAR_TOOL_COUNT-1:0] label_rendered;
    wire [11:0] label_rgb [0:TOOLBAR_TOOL_COUNT-1];
    wire [5:0] label_char_idx [0:TOOLBAR_TOOL_COUNT-1];

    genvar gi;
    generate
        for (gi = 0; gi < TOOLBAR_TOOL_COUNT; gi = gi + 1) begin : gen_toolbar_labels
            localparam [255:0] TOOL_LABEL = tool_label_data(gi);
            localparam [5:0] TOOL_LABEL_LEN = tool_label_len(gi);
            localparam [11:0] TOOL_SLOT_X = toolbar_slot_x(gi);
            localparam [11:0] TOOL_LABEL_Y = toolbar_label_y(gi);

            assign slot_inside[gi] = toolbar_slot_contains(hcount, vcount, gi);
            assign slot_hovered[gi] = toolbar_slot_contains(mouse_x, mouse_y, gi);
            assign slot_selected[gi] = (selected_mode == tool_mode_by_index(gi));

            TextDisplay #(
                .MAX_CHARS(32)
            ) u_tool_label (
                .clk_pixel(clk_pixel),
                .video_on(video_on),
                .hcount(hcount),
                .vcount(vcount),
                .start_x(TOOL_SLOT_X),
                .start_y(TOOL_LABEL_Y),
                .region_width(TOOLBAR_SLOT_W[11:0]),
                .scale(4'd1),
                .align(UI_ALIGN_CENTER),
                .text_data(TOOL_LABEL),
                .text_len(TOOL_LABEL_LEN),
                .text_rgb(slot_selected[gi] ? 12'h111 : 12'hFFF),
                .rendered(label_rendered[gi]),
                .rgb(label_rgb[gi]),
                .char_index_out(label_char_idx[gi])
            );
        end
    endgenerate

    integer i;
    reg [11:0] slot_face_rgb;
    reg [11:0] slot_border_rgb;
    reg [11:0] slot_base_rgb;

    always @(*) begin
        rendered = 1'b0;
        rgb = 12'h000;

        if (video_on && toolbar_inside(hcount, vcount)) begin
            rendered = 1'b1;
            rgb = UI_COLOR_TOOLBAR_BG;

            if ((hcount == UI_TOOLBAR_X) ||
                (hcount == UI_TOOLBAR_X + UI_TOOLBAR_W - 1) ||
                (vcount == UI_TOOLBAR_Y) ||
                (vcount == UI_TOOLBAR_Y + UI_TOOLBAR_H - 1)) begin
                rgb = UI_COLOR_PANEL_BORDER;
            end
        end

        for (i = 0; i < TOOLBAR_TOOL_COUNT; i = i + 1) begin
            if (slot_inside[i]) begin
                slot_base_rgb = tool_color_by_index(i);
                slot_face_rgb = darken_color(slot_base_rgb);
                if (slot_hovered[i]) begin
                    slot_face_rgb = brighten_color(slot_face_rgb);
                end
                if (slot_hovered[i] && mouse_left) begin
                    slot_face_rgb = darken_color(slot_face_rgb);
                end

                slot_border_rgb = darken_color(slot_base_rgb);
                if (slot_selected[i]) begin
                    slot_face_rgb = brighten_color(slot_base_rgb);
                    slot_border_rgb = UI_COLOR_TOOLBAR_ACCENT;
                end else if (slot_hovered[i]) begin
                    slot_border_rgb = brighten_color(slot_base_rgb);
                end

                rendered = 1'b1;
                rgb = slot_border_pixel(hcount, vcount, i) ? slot_border_rgb : slot_face_rgb;
            end
        end

        for (i = 0; i < TOOLBAR_TOOL_COUNT; i = i + 1) begin
            if (label_rendered[i]) begin
                rendered = 1'b1;
                rgb = label_rgb[i];
            end
        end
    end
endmodule
