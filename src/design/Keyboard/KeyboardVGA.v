// VGA version of the on-screen keyboard.
// - Keeps the same 5x4 key layout and navigation behavior as Keyboard.v.
// - Renders directly for a 640x480-style pixel stream using RGB444.
module KeyboardVGA #(
    parameter integer KEY_COUNT = 20,
    parameter integer SCREEN_W = 640,
    parameter integer SCREEN_H = 480,
    parameter integer COLS = 5,
    parameter integer ROWS = 4,
    parameter integer FONT_SCALE = 4,
    parameter integer KEYBOARD_X0 = 0,
    parameter integer KEYBOARD_Y0 = 0
) (
    input  wire        clk_nav,
    input  wire        btnU,
    input  wire        btnD,
    input  wire        btnL,
    input  wire        btnR,
    input  wire        btnC,
    input  wire [11:0] x,
    input  wire [11:0] y,
    output reg  [11:0] pixel_rgb,
    output reg  [4:0]  key_id,
    output reg         key_valid,
    output reg  [7:0]  key_ascii,
    output reg  [23:0] key_rgb,
    output reg         key_is_digit,
    output reg         key_is_unit,
    output reg         key_is_action
);

    localparam [4:0]
        POS_R0C0 = 5'd0,
        POS_R0C1 = 5'd1,
        POS_R0C2 = 5'd2,
        POS_R0C3 = 5'd3,
        POS_R0C4 = 5'd4,
        POS_R1C0 = 5'd5,
        POS_R1C1 = 5'd6,
        POS_R1C2 = 5'd7,
        POS_R1C3 = 5'd8,
        POS_R1C4 = 5'd9,
        POS_R2C0 = 5'd10,
        POS_R2C1 = 5'd11,
        POS_R2C2 = 5'd12,
        POS_R2C3 = 5'd13,
        POS_R2C4 = 5'd14,
        POS_R3C0 = 5'd15,
        POS_R3C1 = 5'd16,
        POS_R3C2 = 5'd17,
        POS_R3C3 = 5'd18,
        POS_R3C4 = 5'd19;

    localparam [23:0]
        RGB_BG              = 24'hF8F4EC,
        RGB_PANEL           = 24'hF3EADF,
        RGB_BORDER          = 24'hCBBFB0,
        RGB_SELECTED_BORDER = 24'hFFD84D,
        RGB_DIGIT           = 24'hAFCBFF,
        RGB_UNIT            = 24'hBEE8B7,
        RGB_DOT             = 24'hF9E79F,
        RGB_DEL             = 24'hFFB7B2,
        RGB_NONE            = 24'hE7DDD2,
        RGB_TEXT            = 24'h5B534D;

    // Use scale to define each key directly so DEL can fit fully.
    localparam integer KEY_W = 12 * FONT_SCALE;
    localparam integer KEY_H = 12 * FONT_SCALE;
    localparam integer KEYBOARD_W = COLS * KEY_W;
    localparam integer KEYBOARD_H = ROWS * KEY_H;
    localparam integer BORDER = 3;
    localparam integer FONT5_SCALE = FONT_SCALE;
    localparam integer FONT3_SCALE = FONT_SCALE - 1;

    reg [2:0] sel_row = 3'd0;
    reg [2:0] sel_col = 3'd0;
    reg btnU_d = 1'b0;
    reg btnD_d = 1'b0;
    reg btnL_d = 1'b0;
    reg btnR_d = 1'b0;
    reg btnC_d = 1'b0;

    reg [7:0] decoded_ascii;
    reg [23:0] decoded_rgb;
    reg decoded_is_digit;
    reg decoded_is_unit;
    reg decoded_is_action;

    reg inside_keyboard;
    reg [11:0] rel_x;
    reg [11:0] rel_y;
    reg [2:0] col;
    reg [2:0] row;
    reg [4:0] cell_id;
    reg [11:0] cell_x;
    reg [11:0] cell_y;

    reg [23:0] cell_color;
    reg is_border;
    reg is_selected;
    reg is_text;
    reg [2:0] text_cols;
    reg [7:0] t0;
    reg [7:0] t1;
    reg [7:0] t2;
    reg [11:0] text_x0;
    reg [11:0] text_y0;
    reg [11:0] text_w;
    reg [11:0] text_h;
    reg small_text;
    reg [11:0] glyph_local_x;
    reg [11:0] glyph_local_y;
    reg [2:0] glyph_col;
    reg [2:0] glyph_row;
    reg [4:0] row_bits_5x7;
    reg [2:0] row_bits_3x5;

    always @(posedge clk_nav) begin
        btnU_d <= btnU;
        btnD_d <= btnD;
        btnL_d <= btnL;
        btnR_d <= btnR;
        btnC_d <= btnC;

        key_valid <= 1'b0;

        if (btnU & ~btnU_d) begin
            if (sel_row == 0) sel_row <= ROWS - 1;
            else sel_row <= sel_row - 1'b1;
        end else if (btnD & ~btnD_d) begin
            if (sel_row == ROWS - 1) sel_row <= 0;
            else sel_row <= sel_row + 1'b1;
        end else if (btnL & ~btnL_d) begin
            if (sel_col == 0) sel_col <= COLS - 1;
            else sel_col <= sel_col - 1'b1;
        end else if (btnR & ~btnR_d) begin
            if (sel_col == COLS - 1) sel_col <= 0;
            else sel_col <= sel_col + 1'b1;
        end else if (btnC & ~btnC_d) begin
            key_valid <= 1'b1;
        end

        key_id <= (sel_row * COLS) + sel_col;
    end

    always @(*) begin
        decoded_ascii = 8'h00;
        decoded_rgb = RGB_NONE;
        decoded_is_digit = 1'b0;
        decoded_is_unit = 1'b0;
        decoded_is_action = 1'b0;

        case (key_id)
            POS_R0C0: begin decoded_ascii = "1"; decoded_rgb = RGB_DIGIT; decoded_is_digit = 1'b1; end
            POS_R0C1: begin decoded_ascii = "2"; decoded_rgb = RGB_DIGIT; decoded_is_digit = 1'b1; end
            POS_R0C2: begin decoded_ascii = "3"; decoded_rgb = RGB_DIGIT; decoded_is_digit = 1'b1; end
            POS_R0C3: begin decoded_ascii = "M"; decoded_rgb = RGB_UNIT;  decoded_is_unit  = 1'b1; end
            POS_R0C4: begin decoded_ascii = "k"; decoded_rgb = RGB_UNIT;  decoded_is_unit  = 1'b1; end
            POS_R1C0: begin decoded_ascii = "4"; decoded_rgb = RGB_DIGIT; decoded_is_digit = 1'b1; end
            POS_R1C1: begin decoded_ascii = "5"; decoded_rgb = RGB_DIGIT; decoded_is_digit = 1'b1; end
            POS_R1C2: begin decoded_ascii = "6"; decoded_rgb = RGB_DIGIT; decoded_is_digit = 1'b1; end
            POS_R1C3: begin decoded_ascii = "m"; decoded_rgb = RGB_UNIT;  decoded_is_unit  = 1'b1; end
            POS_R1C4: begin decoded_ascii = "u"; decoded_rgb = RGB_UNIT;  decoded_is_unit  = 1'b1; end
            POS_R2C0: begin decoded_ascii = "7"; decoded_rgb = RGB_DIGIT; decoded_is_digit = 1'b1; end
            POS_R2C1: begin decoded_ascii = "8"; decoded_rgb = RGB_DIGIT; decoded_is_digit = 1'b1; end
            POS_R2C2: begin decoded_ascii = "9"; decoded_rgb = RGB_DIGIT; decoded_is_digit = 1'b1; end
            POS_R2C3: begin decoded_ascii = "n"; decoded_rgb = RGB_UNIT;  decoded_is_unit  = 1'b1; end
            POS_R2C4: begin decoded_ascii = "p"; decoded_rgb = RGB_UNIT;  decoded_is_unit  = 1'b1; end
            POS_R3C0: begin decoded_ascii = ".";  decoded_rgb = RGB_DOT; decoded_is_action = 1'b1; end
            POS_R3C1: begin decoded_ascii = "0";  decoded_rgb = RGB_DIGIT; decoded_is_digit = 1'b1; end
            POS_R3C2: begin decoded_ascii = 8'h08; decoded_rgb = RGB_DEL; decoded_is_action = 1'b1; end
            default: begin end
        endcase
    end

    always @(*) begin
        key_ascii = decoded_ascii;
        key_rgb = decoded_rgb;
        key_is_digit = decoded_is_digit;
        key_is_unit = decoded_is_unit;
        key_is_action = decoded_is_action;
    end

    always @(*) begin
        inside_keyboard = (x >= KEYBOARD_X0) && (x < (KEYBOARD_X0 + KEYBOARD_W)) &&
                          (y >= KEYBOARD_Y0) && (y < (KEYBOARD_Y0 + KEYBOARD_H));

        rel_x = x - KEYBOARD_X0;
        rel_y = y - KEYBOARD_Y0;

        if (rel_x < KEY_W) col = 3'd0;
        else if (rel_x < (KEY_W * 2)) col = 3'd1;
        else if (rel_x < (KEY_W * 3)) col = 3'd2;
        else if (rel_x < (KEY_W * 4)) col = 3'd3;
        else col = 3'd4;

        if (rel_y < KEY_H) row = 3'd0;
        else if (rel_y < (KEY_H * 2)) row = 3'd1;
        else if (rel_y < (KEY_H * 3)) row = 3'd2;
        else row = 3'd3;

        cell_id = row * COLS + col;
        cell_x = rel_x - (col * KEY_W);
        cell_y = rel_y - (row * KEY_H);
    end

    function [11:0] rgb888_to_444;
        input [23:0] c;
        begin
            rgb888_to_444 = {c[23:20], c[15:12], c[7:4]};
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
                "M": glyph5x7 = 35'b10001_11011_10101_10101_10001_10001_10001;
                "k": glyph5x7 = 35'b10000_10000_10010_10100_11000_10100_10010;
                "m": glyph5x7 = 35'b00000_11010_10101_10101_10101_10101_00000;
                "u": glyph5x7 = 35'b00000_10001_10001_10011_01101_00001_00001;
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
        pixel_rgb = rgb888_to_444(RGB_BG);
        cell_color = RGB_NONE;
        is_border = 1'b0;
        is_selected = 1'b0;
        is_text = 1'b0;
        text_cols = 3'd0;
        t0 = 8'h00;
        t1 = 8'h00;
        t2 = 8'h00;
        text_x0 = 12'd0;
        text_y0 = 12'd0;
        text_w = 12'd0;
        text_h = 12'd0;
        small_text = 1'b0;
        glyph_local_x = 12'd0;
        glyph_local_y = 12'd0;
        glyph_col = 3'd0;
        glyph_row = 3'd0;
        row_bits_5x7 = 5'd0;
        row_bits_3x5 = 3'd0;

        if (!inside_keyboard) begin
            if ((x >= (KEYBOARD_X0 - 8)) && (x < (KEYBOARD_X0 + KEYBOARD_W + 8)) &&
                (y >= (KEYBOARD_Y0 - 8)) && (y < (KEYBOARD_Y0 + KEYBOARD_H + 8))) begin
                pixel_rgb = rgb888_to_444(RGB_PANEL);
            end
        end else begin
            case (cell_id)
                POS_R0C0, POS_R0C1, POS_R0C2, POS_R1C0, POS_R1C1, POS_R1C2,
                POS_R2C0, POS_R2C1, POS_R2C2, POS_R3C1: cell_color = RGB_DIGIT;
                POS_R0C3, POS_R0C4, POS_R1C3, POS_R1C4, POS_R2C3, POS_R2C4: cell_color = RGB_UNIT;
                POS_R3C0: cell_color = RGB_DOT;
                POS_R3C2: cell_color = RGB_DEL;
                default: cell_color = RGB_NONE;
            endcase

            is_border = (cell_x < BORDER) || (cell_y < BORDER) ||
                        (cell_x >= (KEY_W - BORDER)) || (cell_y >= (KEY_H - BORDER));
            is_selected = (cell_id == key_id);

            case (cell_id)
                POS_R0C0: begin t0 = "1"; text_cols = 3'd1; end
                POS_R0C1: begin t0 = "2"; text_cols = 3'd1; end
                POS_R0C2: begin t0 = "3"; text_cols = 3'd1; end
                POS_R0C3: begin t0 = "M"; text_cols = 3'd1; end
                POS_R0C4: begin t0 = "k"; text_cols = 3'd1; end
                POS_R1C0: begin t0 = "4"; text_cols = 3'd1; end
                POS_R1C1: begin t0 = "5"; text_cols = 3'd1; end
                POS_R1C2: begin t0 = "6"; text_cols = 3'd1; end
                POS_R1C3: begin t0 = "m"; text_cols = 3'd1; end
                POS_R1C4: begin t0 = "u"; text_cols = 3'd1; end
                POS_R2C0: begin t0 = "7"; text_cols = 3'd1; end
                POS_R2C1: begin t0 = "8"; text_cols = 3'd1; end
                POS_R2C2: begin t0 = "9"; text_cols = 3'd1; end
                POS_R2C3: begin t0 = "n"; text_cols = 3'd1; end
                POS_R2C4: begin t0 = "p"; text_cols = 3'd1; end
                POS_R3C0: begin t0 = "."; text_cols = 3'd1; end
                POS_R3C1: begin t0 = "0"; text_cols = 3'd1; end
                POS_R3C2: begin
                    t0 = "D";
                    t1 = "E";
                    t2 = "L";
                    text_cols = 3'd3;
                    small_text = 1'b1;
                end
                default: begin end
            endcase

            if (small_text) begin
                text_w = (text_cols * (3 * FONT3_SCALE)) + ((text_cols - 1) * FONT3_SCALE);
                text_h = 5 * FONT3_SCALE;
            end else begin
                text_w = (text_cols * (5 * FONT5_SCALE)) + ((text_cols - 1) * FONT5_SCALE);
                text_h = 7 * FONT5_SCALE;
            end

            text_x0 = (KEY_W - text_w) >> 1;
            text_y0 = (KEY_H - text_h) >> 1;

            if (text_cols != 0 &&
                cell_x >= text_x0 && cell_x < (text_x0 + text_w) &&
                cell_y >= text_y0 && cell_y < (text_y0 + text_h)) begin

                glyph_local_x = cell_x - text_x0;
                glyph_local_y = cell_y - text_y0;

                if (small_text) begin
                    glyph_row = glyph_local_y / FONT3_SCALE;
                    if (glyph_local_x < (3 * FONT3_SCALE)) begin
                        glyph_col = (glyph_local_x / FONT3_SCALE);
                        row_bits_3x5 = glyph3x5_row(t0, glyph_row);
                        if (row_bits_3x5[2 - glyph_col]) is_text = 1'b1;
                    end else if ((text_cols >= 2) &&
                                 (glyph_local_x >= (4 * FONT3_SCALE)) &&
                                 (glyph_local_x < (7 * FONT3_SCALE))) begin
                        glyph_col = (glyph_local_x - (4 * FONT3_SCALE)) / FONT3_SCALE;
                        row_bits_3x5 = glyph3x5_row(t1, glyph_row);
                        if (row_bits_3x5[2 - glyph_col]) is_text = 1'b1;
                    end else if ((text_cols >= 3) &&
                                 (glyph_local_x >= (8 * FONT3_SCALE)) &&
                                 (glyph_local_x < (11 * FONT3_SCALE))) begin
                        glyph_col = (glyph_local_x - (8 * FONT3_SCALE)) / FONT3_SCALE;
                        row_bits_3x5 = glyph3x5_row(t2, glyph_row);
                        if (row_bits_3x5[2 - glyph_col]) is_text = 1'b1;
                    end
                end else begin
                    glyph_row = glyph_local_y / FONT5_SCALE;
                    if (glyph_local_x < (5 * FONT5_SCALE)) begin
                        glyph_col = (glyph_local_x / FONT5_SCALE);
                        row_bits_5x7 = glyph5x7_row(t0, glyph_row);
                        if (row_bits_5x7[4 - glyph_col]) is_text = 1'b1;
                    end else if ((text_cols >= 2) &&
                                 (glyph_local_x >= (6 * FONT5_SCALE)) &&
                                 (glyph_local_x < (11 * FONT5_SCALE))) begin
                        glyph_col = (glyph_local_x - (6 * FONT5_SCALE)) / FONT5_SCALE;
                        row_bits_5x7 = glyph5x7_row(t1, glyph_row);
                        if (row_bits_5x7[4 - glyph_col]) is_text = 1'b1;
                    end else if ((text_cols >= 3) &&
                                 (glyph_local_x >= (12 * FONT5_SCALE)) &&
                                 (glyph_local_x < (17 * FONT5_SCALE))) begin
                        glyph_col = (glyph_local_x - (12 * FONT5_SCALE)) / FONT5_SCALE;
                        row_bits_5x7 = glyph5x7_row(t2, glyph_row);
                        if (row_bits_5x7[4 - glyph_col]) is_text = 1'b1;
                    end
                end
            end

            if (cell_id < KEY_COUNT) begin
                if (is_border && is_selected) pixel_rgb = rgb888_to_444(RGB_SELECTED_BORDER);
                else if (is_border) pixel_rgb = rgb888_to_444(RGB_BORDER);
                else if (is_text) pixel_rgb = rgb888_to_444(RGB_TEXT);
                else pixel_rgb = rgb888_to_444(cell_color);
            end
        end
    end

endmodule
