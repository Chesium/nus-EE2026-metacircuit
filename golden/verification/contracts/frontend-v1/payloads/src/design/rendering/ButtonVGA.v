module ButtonVGA #(
    parameter integer X0 = 0,
    parameter integer Y0 = 0,
    parameter integer W = 48,
    parameter integer H = 48,
    parameter integer BORDER = 3,
    parameter integer EDGE_THICK = 2,
    parameter integer MARKER_OFFSET = 7,
    parameter integer MARKER_W = 3,
    parameter integer MARKER_H = 3,
    parameter integer FONT5_SCALE = 4,
    parameter integer FONT3_SCALE = 3,
    parameter [7:0] LABEL0 = "0",
    parameter [7:0] LABEL1 = 8'h00,
    parameter [7:0] LABEL2 = 8'h00,
    parameter integer TEXT_COLS = 1,
    parameter SMALL_TEXT = 1'b0,
    parameter [23:0] FACE_RGB = 24'hE7DDD2,
    parameter [23:0] BORDER_RGB = 24'hCBBFB0,
    parameter [23:0] SELECTED_BORDER_RGB = 24'hFFD84D,
    parameter [23:0] SELECTED_MARKER_RGB = 24'hFFF7D2,
    parameter [23:0] PRESSED_BORDER_RGB = 24'hD9A900,
    parameter [23:0] TEXT_RGB = 24'h5B534D
) (
    input  wire        enabled,
    input  wire        selected,
    input  wire        pressed,
    input  wire [11:0] x,
    input  wire [11:0] y,
    output reg  [11:0] pixel_rgb,
    output wire        inside_button
);

    reg [11:0] local_x;
    reg [11:0] local_y;
    reg [23:0] face_color;
    reg [23:0] top_left_edge_color;
    reg [23:0] bottom_right_edge_color;
    reg is_border;
    reg is_selected_marker;
    reg is_top_edge;
    reg is_left_edge;
    reg is_right_edge;
    reg is_bottom_edge;
    reg is_text;
    reg [11:0] text_x0;
    reg [11:0] text_y0;
    reg [11:0] text_w;
    reg [11:0] text_h;
    reg [11:0] glyph_local_x;
    reg [11:0] glyph_local_y;
    reg [2:0] glyph_col;
    reg [2:0] glyph_row;
    reg [4:0] row_bits_5x7;
    reg [2:0] row_bits_3x5;

    assign inside_button =
        enabled &&
        (x >= X0) && (x < (X0 + W)) &&
        (y >= Y0) && (y < (Y0 + H));

    function [11:0] rgb888_to_444;
        input [23:0] c;
        begin
            rgb888_to_444 = {c[23:20], c[15:12], c[7:4]};
        end
    endfunction

    function [23:0] lighten_rgb_quarter;
        input [23:0] c;
        reg [7:0] r;
        reg [7:0] g;
        reg [7:0] b;
        begin
            r = c[23:16] + ((8'hFF - c[23:16]) >> 2);
            g = c[15:8]  + ((8'hFF - c[15:8])  >> 2);
            b = c[7:0]   + ((8'hFF - c[7:0])   >> 2);
            lighten_rgb_quarter = {r, g, b};
        end
    endfunction

    function [23:0] darken_rgb_quarter;
        input [23:0] c;
        begin
            darken_rgb_quarter = {c[23:16] - (c[23:16] >> 2),
                                  c[15:8]  - (c[15:8]  >> 2),
                                  c[7:0]   - (c[7:0]   >> 2)};
        end
    endfunction

    function [23:0] darken_rgb_eighth;
        input [23:0] c;
        begin
            darken_rgb_eighth = {c[23:16] - (c[23:16] >> 3),
                                 c[15:8]  - (c[15:8]  >> 3),
                                 c[7:0]   - (c[7:0]   >> 3)};
        end
    endfunction

    function [34:0] glyph5x7;
        input [7:0] c;
        begin
            case (c)
                "0": glyph5x7 = 35'b01110_10001_10011_10101_11001_10001_01110;
                "1": glyph5x7 = 35'b00100_01100_00100_00100_00100_00100_01110;
                "2": glyph5x7 = 35'b01110_10001_00001_00010_00100_01000_11111;
                "3": glyph5x7 = 35'b11110_00001_00001_01110_00001_00001_11110;
                "4": glyph5x7 = 35'b00010_00110_01010_10010_11111_00010_00010;
                "5": glyph5x7 = 35'b11111_10000_11110_00001_00001_10001_01110;
                "6": glyph5x7 = 35'b00110_01000_10000_11110_10001_10001_01110;
                "7": glyph5x7 = 35'b11111_00001_00010_00100_01000_01000_01000;
                "8": glyph5x7 = 35'b01110_10001_10001_01110_10001_10001_01110;
                "9": glyph5x7 = 35'b01110_10001_10001_01111_00001_00010_01100;
                "D": glyph5x7 = 35'b11110_10001_10001_10001_10001_10001_11110;
                "E": glyph5x7 = 35'b11111_10000_10000_11110_10000_10000_11111;
                "L": glyph5x7 = 35'b10000_10000_10000_10000_10000_10000_11111;
                "M": glyph5x7 = 35'b10001_11011_10101_10101_10001_10001_10001;
                "R": glyph5x7 = 35'b11110_10001_10001_11110_10100_10010_10001;
                "S": glyph5x7 = 35'b01111_10000_10000_01110_00001_00001_11110;
                "T": glyph5x7 = 35'b11111_00100_00100_00100_00100_00100_00100;
                "k": glyph5x7 = 35'b10000_10000_10010_10100_11000_10100_10010;
                "m": glyph5x7 = 35'b00000_11010_10101_10101_10101_10101_00000;
                "u": glyph5x7 = 35'b00000_10001_10001_10011_11101_10000_10000;
                "n": glyph5x7 = 35'b00000_11110_10001_10001_10001_10001_00000;
                "p": glyph5x7 = 35'b00000_11110_10001_11110_10000_10000_00000;
                ".": glyph5x7 = 35'b00000_00000_00000_00000_00000_01100_01100;
                default: glyph5x7 = 35'b00000_00000_00000_00000_00000_00000_00000;
            endcase
        end
    endfunction

    function [4:0] glyph5x7_row;
        input [7:0] c;
        input [2:0] r;
        reg [34:0] g;
        begin
            g = glyph5x7(c);
            case (r)
                3'd0: glyph5x7_row = g[34:30];
                3'd1: glyph5x7_row = g[29:25];
                3'd2: glyph5x7_row = g[24:20];
                3'd3: glyph5x7_row = g[19:15];
                3'd4: glyph5x7_row = g[14:10];
                3'd5: glyph5x7_row = g[9:5];
                default: glyph5x7_row = g[4:0];
            endcase
        end
    endfunction

    function [14:0] glyph3x5;
        input [7:0] c;
        begin
            case (c)
                "D": glyph3x5 = 15'b110_101_101_101_110;
                "E": glyph3x5 = 15'b111_100_111_100_111;
                "L": glyph3x5 = 15'b100_100_100_100_111;
                default: glyph3x5 = 15'b000_000_000_000_000;
            endcase
        end
    endfunction

    function [2:0] glyph3x5_row;
        input [7:0] c;
        input [2:0] r;
        reg [14:0] g;
        begin
            g = glyph3x5(c);
            case (r)
                3'd0: glyph3x5_row = g[14:12];
                3'd1: glyph3x5_row = g[11:9];
                3'd2: glyph3x5_row = g[8:6];
                3'd3: glyph3x5_row = g[5:3];
                default: glyph3x5_row = g[2:0];
            endcase
        end
    endfunction

    always @(*) begin
        pixel_rgb = 12'h000;
        local_x = x - X0;
        local_y = y - Y0;
        face_color = FACE_RGB;
        top_left_edge_color = FACE_RGB;
        bottom_right_edge_color = FACE_RGB;
        is_border = 1'b0;
        is_selected_marker = 1'b0;
        is_top_edge = 1'b0;
        is_left_edge = 1'b0;
        is_right_edge = 1'b0;
        is_bottom_edge = 1'b0;
        is_text = 1'b0;
        text_x0 = 12'd0;
        text_y0 = 12'd0;
        text_w = 12'd0;
        text_h = 12'd0;
        glyph_local_x = 12'd0;
        glyph_local_y = 12'd0;
        glyph_col = 3'd0;
        glyph_row = 3'd0;
        row_bits_5x7 = 5'd0;
        row_bits_3x5 = 3'd0;

        if (inside_button) begin
            if (selected) face_color = lighten_rgb_quarter(FACE_RGB);
            if (pressed) face_color = darken_rgb_eighth(face_color);

            if (pressed) begin
                top_left_edge_color = darken_rgb_eighth(face_color);
                bottom_right_edge_color = darken_rgb_quarter(face_color);
            end else begin
                top_left_edge_color = lighten_rgb_quarter(face_color);
                bottom_right_edge_color = darken_rgb_quarter(face_color);
            end

            is_border = (local_x < BORDER) || (local_y < BORDER) ||
                        (local_x >= (W - BORDER)) || (local_y >= (H - BORDER));
            is_selected_marker = selected &&
                                 (local_x >= MARKER_OFFSET) &&
                                 (local_x < (MARKER_OFFSET + MARKER_W)) &&
                                 (local_y >= MARKER_OFFSET) &&
                                 (local_y < (MARKER_OFFSET + MARKER_H));
            is_top_edge = (local_y >= BORDER) && (local_y < (BORDER + EDGE_THICK)) &&
                          (local_x >= BORDER) && (local_x < (W - BORDER));
            is_left_edge = (local_x >= BORDER) && (local_x < (BORDER + EDGE_THICK)) &&
                           (local_y >= BORDER) && (local_y < (H - BORDER));
            is_right_edge = (local_x >= (W - BORDER - EDGE_THICK)) &&
                            (local_x < (W - BORDER)) &&
                            (local_y >= BORDER) && (local_y < (H - BORDER));
            is_bottom_edge = (local_y >= (H - BORDER - EDGE_THICK)) &&
                             (local_y < (H - BORDER)) &&
                             (local_x >= BORDER) && (local_x < (W - BORDER));

            if (SMALL_TEXT) begin
                text_w = (TEXT_COLS * (3 * FONT3_SCALE)) + ((TEXT_COLS - 1) * FONT3_SCALE);
                text_h = 5 * FONT3_SCALE;
            end else begin
                text_w = (TEXT_COLS * (5 * FONT5_SCALE)) + ((TEXT_COLS - 1) * FONT5_SCALE);
                text_h = 7 * FONT5_SCALE;
            end

            text_x0 = (W - text_w) >> 1;
            text_y0 = (H - text_h) >> 1;

            if ((TEXT_COLS != 0) &&
                (local_x >= text_x0) && (local_x < (text_x0 + text_w)) &&
                (local_y >= text_y0) && (local_y < (text_y0 + text_h))) begin
                glyph_local_x = local_x - text_x0;
                glyph_local_y = local_y - text_y0;

                if (SMALL_TEXT) begin
                    glyph_row = glyph_local_y / FONT3_SCALE;
                    if (glyph_local_x < (3 * FONT3_SCALE)) begin
                        glyph_col = glyph_local_x / FONT3_SCALE;
                        row_bits_3x5 = glyph3x5_row(LABEL0, glyph_row);
                        if (row_bits_3x5[2 - glyph_col]) is_text = 1'b1;
                    end else if ((TEXT_COLS >= 2) &&
                                 (glyph_local_x >= (4 * FONT3_SCALE)) &&
                                 (glyph_local_x < (7 * FONT3_SCALE))) begin
                        glyph_col = (glyph_local_x - (4 * FONT3_SCALE)) / FONT3_SCALE;
                        row_bits_3x5 = glyph3x5_row(LABEL1, glyph_row);
                        if (row_bits_3x5[2 - glyph_col]) is_text = 1'b1;
                    end else if ((TEXT_COLS >= 3) &&
                                 (glyph_local_x >= (8 * FONT3_SCALE)) &&
                                 (glyph_local_x < (11 * FONT3_SCALE))) begin
                        glyph_col = (glyph_local_x - (8 * FONT3_SCALE)) / FONT3_SCALE;
                        row_bits_3x5 = glyph3x5_row(LABEL2, glyph_row);
                        if (row_bits_3x5[2 - glyph_col]) is_text = 1'b1;
                    end
                end else begin
                    glyph_row = glyph_local_y / FONT5_SCALE;
                    if (glyph_local_x < (5 * FONT5_SCALE)) begin
                        glyph_col = glyph_local_x / FONT5_SCALE;
                        row_bits_5x7 = glyph5x7_row(LABEL0, glyph_row);
                        if (row_bits_5x7[4 - glyph_col]) is_text = 1'b1;
                    end else if ((TEXT_COLS >= 2) &&
                                 (glyph_local_x >= (6 * FONT5_SCALE)) &&
                                 (glyph_local_x < (11 * FONT5_SCALE))) begin
                        glyph_col = (glyph_local_x - (6 * FONT5_SCALE)) / FONT5_SCALE;
                        row_bits_5x7 = glyph5x7_row(LABEL1, glyph_row);
                        if (row_bits_5x7[4 - glyph_col]) is_text = 1'b1;
                    end else if ((TEXT_COLS >= 3) &&
                                 (glyph_local_x >= (12 * FONT5_SCALE)) &&
                                 (glyph_local_x < (17 * FONT5_SCALE))) begin
                        glyph_col = (glyph_local_x - (12 * FONT5_SCALE)) / FONT5_SCALE;
                        row_bits_5x7 = glyph5x7_row(LABEL2, glyph_row);
                        if (row_bits_5x7[4 - glyph_col]) is_text = 1'b1;
                    end
                end
            end

            if (is_border && pressed) pixel_rgb = rgb888_to_444(PRESSED_BORDER_RGB);
            else if (is_border && selected) pixel_rgb = rgb888_to_444(SELECTED_BORDER_RGB);
            else if (is_border) pixel_rgb = rgb888_to_444(BORDER_RGB);
            else if (is_text) pixel_rgb = rgb888_to_444(TEXT_RGB);
            else if (is_top_edge || is_left_edge) pixel_rgb = rgb888_to_444(top_left_edge_color);
            else if (is_right_edge || is_bottom_edge) pixel_rgb = rgb888_to_444(bottom_right_edge_color);
            else if (is_selected_marker) pixel_rgb = rgb888_to_444(SELECTED_MARKER_RGB);
            else pixel_rgb = rgb888_to_444(face_color);
        end
    end

endmodule
