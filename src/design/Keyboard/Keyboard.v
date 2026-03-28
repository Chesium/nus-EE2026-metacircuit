
// Keyboard UI + decoder.
// - Render a 5x4 on-screen keyboard (20 keys) for a 96x64 OLED.
// - Decode key_id to ASCII and per-key RGB category color.
module Keyboard #(
    parameter integer KEY_COUNT = 20,
    parameter integer OLED_W = 96,
    parameter integer OLED_H = 64
) (
    input  wire        clk_nav,     // navigation clock (e.g. 20Hz)
    input  wire        btnU,
    input  wire        btnD,
    input  wire        btnL,
    input  wire        btnR,
    input  wire        btnC,
    input  wire [6:0]  x,           // 0..95 pixel x
    input  wire [5:0]  y,           // 0..63 pixel y
    output reg  [15:0] pixel_rgb,   // RGB565 for OLED
    output reg  [4:0]  key_id,      // selected key id (0..19)
    output reg         key_valid,   // 1-cycle pulse on confirm
    output reg  [7:0]  key_ascii,   // ASCII code for key
    output reg  [23:0] key_rgb,     // RGB888 color for key category
    output reg         key_is_digit,
    output reg         key_is_unit,
    output reg         key_is_action
);

    // Key id assignments (row-major positions in a 5x4 grid)
    localparam [4:0]
        POS_R0C0 = 5'd0,  // 1
        POS_R0C1 = 5'd1,  // 2
        POS_R0C2 = 5'd2,  // 3
        POS_R0C3 = 5'd3,  // M
        POS_R0C4 = 5'd4,  // k
        POS_R1C0 = 5'd5,  // 4
        POS_R1C1 = 5'd6,  // 5
        POS_R1C2 = 5'd7,  // 6
        POS_R1C3 = 5'd8,  // m
        POS_R1C4 = 5'd9,  // u
        POS_R2C0 = 5'd10, // 7
        POS_R2C1 = 5'd11, // 8
        POS_R2C2 = 5'd12, // 9
        POS_R2C3 = 5'd13, // n
        POS_R2C4 = 5'd14, // p
        POS_R3C0 = 5'd15, // .
        POS_R3C1 = 5'd16, // 0
        POS_R3C2 = 5'd17, // DEL
        POS_R3C3 = 5'd18, // RST
        POS_R3C4 = 5'd19; // empty

    // Color palette (RGB888)
    localparam [23:0]
        RGB_DIGIT = 24'h1E90FF, // DodgerBlue
        RGB_UNIT  = 24'h2ECC71, // Green
        RGB_DOT   = 24'hF1C40F, // Yellow
        RGB_DEL   = 24'hE74C3C, // Red
        RGB_RST   = 24'h4DB6AC, // Teal
        RGB_NONE  = 24'h666666; // Gray

    // 5x4 grid geometry for 96x64
    localparam integer COLS = 5;
    localparam integer ROWS = 4;
    localparam integer KEY_W = (OLED_W / COLS); // 19 for 96
    localparam integer KEY_H = (OLED_H / ROWS); // 16 for 64
    localparam integer BORDER = 1;

    // Helper: map x,y to (row, col) without division edge issues.
    reg [2:0] col;
    reg [2:0] row;
    reg [4:0] cell_id;
    reg [6:0] cell_x;
    reg [5:0] cell_y;

    always @(*) begin
        // column
        if (x < KEY_W) col = 3'd0;
        else if (x < (KEY_W * 2)) col = 3'd1;
        else if (x < (KEY_W * 3)) col = 3'd2;
        else if (x < (KEY_W * 4)) col = 3'd3;
        else col = 3'd4;

        // row
        if (y < KEY_H) row = 3'd0;
        else if (y < (KEY_H * 2)) row = 3'd1;
        else if (y < (KEY_H * 3)) row = 3'd2;
        else row = 3'd3;

        cell_id = row * COLS + col; // 0..19
        cell_x = x - (col * KEY_W);
        cell_y = y - (row * KEY_H);
    end

    // Selection control (button navigation)
    reg [2:0] sel_row = 3'd0;
    reg [2:0] sel_col = 3'd0;
    reg       btnU_d = 1'b0;
    reg       btnD_d = 1'b0;
    reg       btnL_d = 1'b0;
    reg       btnR_d = 1'b0;
    reg       btnC_d = 1'b0;

    always @(posedge clk_nav) begin
        // edge detect
        btnU_d <= btnU;
        btnD_d <= btnD;
        btnL_d <= btnL;
        btnR_d <= btnR;
        btnC_d <= btnC;

        key_valid <= 1'b0;

        if (btnU & ~btnU_d) begin
            if (sel_row == 0) sel_row <= 3'd3;
            else sel_row <= sel_row - 1'b1;
        end else if (btnD & ~btnD_d) begin
            if (sel_row == 3) sel_row <= 3'd0;
            else sel_row <= sel_row + 1'b1;
        end else if (btnL & ~btnL_d) begin
            if (sel_col == 0) sel_col <= 3'd4;
            else sel_col <= sel_col - 1'b1;
        end else if (btnR & ~btnR_d) begin
            if (sel_col == 4) sel_col <= 3'd0;
            else sel_col <= sel_col + 1'b1;
        end else if (btnC & ~btnC_d) begin
            key_valid <= 1'b1; // confirm/press
        end

        key_id <= (sel_row * 5) + sel_col;
    end

    // Decode key_id to ASCII + category flags
    always @(*) begin
        // defaults
        key_ascii    = 8'h00;
        key_rgb      = RGB_NONE;
        key_is_digit = 1'b0;
        key_is_unit  = 1'b0;
        key_is_action= 1'b0;

        if (key_valid) begin
            case (key_id)
                POS_R0C0: begin key_ascii = "1"; key_rgb = RGB_DIGIT; key_is_digit = 1'b1; end
                POS_R0C1: begin key_ascii = "2"; key_rgb = RGB_DIGIT; key_is_digit = 1'b1; end
                POS_R0C2: begin key_ascii = "3"; key_rgb = RGB_DIGIT; key_is_digit = 1'b1; end
                POS_R0C3: begin key_ascii = "M"; key_rgb = RGB_UNIT;  key_is_unit  = 1'b1; end
                POS_R0C4: begin key_ascii = "k"; key_rgb = RGB_UNIT;  key_is_unit  = 1'b1; end
                POS_R1C0: begin key_ascii = "4"; key_rgb = RGB_DIGIT; key_is_digit = 1'b1; end
                POS_R1C1: begin key_ascii = "5"; key_rgb = RGB_DIGIT; key_is_digit = 1'b1; end
                POS_R1C2: begin key_ascii = "6"; key_rgb = RGB_DIGIT; key_is_digit = 1'b1; end
                POS_R1C3: begin key_ascii = "m"; key_rgb = RGB_UNIT;  key_is_unit  = 1'b1; end
                POS_R1C4: begin key_ascii = "u"; key_rgb = RGB_UNIT;  key_is_unit  = 1'b1; end
                POS_R2C0: begin key_ascii = "7"; key_rgb = RGB_DIGIT; key_is_digit = 1'b1; end
                POS_R2C1: begin key_ascii = "8"; key_rgb = RGB_DIGIT; key_is_digit = 1'b1; end
                POS_R2C2: begin key_ascii = "9"; key_rgb = RGB_DIGIT; key_is_digit = 1'b1; end
                POS_R2C3: begin key_ascii = "n"; key_rgb = RGB_UNIT;  key_is_unit  = 1'b1; end
                POS_R2C4: begin key_ascii = "p"; key_rgb = RGB_UNIT;  key_is_unit  = 1'b1; end
                POS_R3C0: begin key_ascii = "."; key_rgb = RGB_DOT;   key_is_action= 1'b1; end
                POS_R3C1: begin key_ascii = "0"; key_rgb = RGB_DIGIT; key_is_digit = 1'b1; end
                POS_R3C2: begin key_ascii = 8'h08; key_rgb = RGB_DEL; key_is_action= 1'b1; end // backspace
                POS_R3C3: begin key_ascii = 8'h7F; key_rgb = RGB_RST; key_is_action= 1'b1; end // reset
                default:begin key_ascii = 8'h00; key_rgb = RGB_NONE; end
            endcase
        end
    end

    // Convert RGB888 to RGB565 for pixel rendering.
    function [15:0] rgb888_to_565;
        input [23:0] c;
        begin
            rgb888_to_565 = {c[23:19], c[15:10], c[7:3]};
        end
    endfunction

    // 5x7 font glyphs (bit 34 = row0 col0, bit 0 = row6 col4)
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
                "m": glyph5x7 = 35'b00000_00000_11010_10101_10101_10101_10101;
                "u": glyph5x7 = 35'b00000_00000_10001_10001_10001_10011_01101;
                "n": glyph5x7 = 35'b00000_00000_11110_10001_10001_10001_10001;
                "p": glyph5x7 = 35'b00000_00000_11110_10001_11110_10000_10000;
                "D": glyph5x7 = 35'b11110_10001_10001_10001_10001_10001_11110;
                "E": glyph5x7 = 35'b11111_10000_10000_11110_10000_10000_11111;
                "L": glyph5x7 = 35'b10000_10000_10000_10000_10000_10000_11111;
                "R": glyph5x7 = 35'b11110_10001_10001_11110_10100_10010_10001;
                "S": glyph5x7 = 35'b01111_10000_10000_01110_00001_00001_11110;
                "T": glyph5x7 = 35'b11111_00100_00100_00100_00100_00100_00100;
                "O": glyph5x7 = 35'b01110_10001_10001_10001_10001_10001_01110;
                "K": glyph5x7 = 35'b10001_10010_10100_11000_10100_10010_10001;
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

    // 3x5 font glyphs for compact labels (bit 14 = row0 col0, bit 0 = row4 col2)
    function [14:0] glyph3x5;
        input [7:0] c;
        begin
            case (c)
                "D": glyph3x5 = 15'b110_101_101_101_110;
                "E": glyph3x5 = 15'b111_100_111_100_111;
                "L": glyph3x5 = 15'b100_100_100_100_111;
                "R": glyph3x5 = 15'b110_101_110_101_101;
                "S": glyph3x5 = 15'b111_100_111_001_111;
                "T": glyph3x5 = 15'b111_010_010_010_010;
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

    // Render keyboard grid
    // Layout (row-major):
    // Row0: 1 2 3 M k
    // Row1: 4 5 6 m u
    // Row2: 7 8 9 n p
    // Row3: . 0 DEL RST empty
    reg [23:0] cell_color;
    reg        is_border;
    reg        is_selected;
    reg        is_text;
    reg [2:0]  text_cols;
    reg [7:0]  t0;
    reg [7:0]  t1;
    reg [7:0]  t2;
    reg [6:0]  text_x0;
    reg [5:0]  text_y0;
    reg [6:0]  text_w;
    reg [2:0]  text_h;
    reg        small_text;
    reg [2:0]  row_g;
    reg [2:0]  col_g;
    reg [4:0]  row_bits;
    reg [2:0]  row_bits_3x5;
    reg [6:0]  gx0;
    reg [7:0]  gc;

    always @(*) begin
        // Default background
        pixel_rgb = 16'h0000; // black
        cell_color = RGB_NONE;
        is_text = 1'b0;
        text_cols = 3'd1;
        t0 = 8'h00; t1 = 8'h00; t2 = 8'h00;
        text_h = 3'd7;
        small_text = 1'b0;

        // Choose per-cell color based on the cell_id mapping
        case (cell_id)
            POS_R0C0, POS_R0C1, POS_R0C2, POS_R1C0, POS_R1C1, POS_R1C2,
            POS_R2C0, POS_R2C1, POS_R2C2, POS_R3C1: cell_color = RGB_DIGIT;
            POS_R0C3, POS_R0C4, POS_R1C3, POS_R1C4, POS_R2C3, POS_R2C4: cell_color = RGB_UNIT;
            POS_R3C0: cell_color = RGB_DOT;
            POS_R3C2: cell_color = RGB_DEL;
            POS_R3C3: cell_color = RGB_RST;
            default: cell_color = RGB_NONE;
        endcase

        // Border and selection
        is_border = (cell_x < BORDER) || (cell_y < BORDER) ||
                    (cell_x >= (KEY_W - BORDER)) || (cell_y >= (KEY_H - BORDER));
        // highlight current selection even when not pressing
        is_selected = (cell_id == key_id);

        // Decide label per key
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
            // Use compact 3x5 action labels
            POS_R3C2: begin t0 = "D"; t1 = "E"; t2 = "L"; text_cols = 3'd3; text_h = 3'd5; small_text = 1'b1; end
            POS_R3C3: begin t0 = "R"; t1 = "S"; t2 = "T"; text_cols = 3'd3; text_h = 3'd5; small_text = 1'b1; end
            default: begin t0 = 8'h00; text_cols = 3'd0; end
        endcase

        // Text placement (centered)
        if (text_cols == 0) begin
            text_w = 0;
        end else begin
            if (small_text)
                text_w = (text_cols * 3) + ((text_cols - 1) * 1);
            else
                text_w = (text_cols * 5) + ((text_cols - 1) * 1);
        end
        text_x0 = (KEY_W - text_w) >> 1;
        text_y0 = (KEY_H - text_h) >> 1;

        // Check if this pixel is inside any glyph
        if (text_cols != 0) begin
            if ((cell_y >= text_y0) && (cell_y < (text_y0 + text_h))) begin
                row_g = cell_y - text_y0;

                if (small_text) begin
                    // 3x5 glyphs
                    gx0 = text_x0;
                    if ((cell_x >= gx0) && (cell_x < (gx0 + 3))) begin
                        col_g = cell_x - gx0;
                        row_bits_3x5 = glyph3x5_row(t0, row_g);
                        if (row_bits_3x5[2 - col_g]) is_text = 1'b1;
                    end

                    if (!is_text && (text_cols >= 2)) begin
                        gx0 = text_x0 + 4;
                        if ((cell_x >= gx0) && (cell_x < (gx0 + 3))) begin
                            col_g = cell_x - gx0;
                            row_bits_3x5 = glyph3x5_row(t1, row_g);
                            if (row_bits_3x5[2 - col_g]) is_text = 1'b1;
                        end
                    end

                    if (!is_text && (text_cols >= 3)) begin
                        gx0 = text_x0 + 8;
                        if ((cell_x >= gx0) && (cell_x < (gx0 + 3))) begin
                            col_g = cell_x - gx0;
                            row_bits_3x5 = glyph3x5_row(t2, row_g);
                            if (row_bits_3x5[2 - col_g]) is_text = 1'b1;
                        end
                    end
                end else begin
                    // 5x7 glyphs
                    gx0 = text_x0;
                    if ((cell_x >= gx0) && (cell_x < (gx0 + 5))) begin
                        col_g = cell_x - gx0;
                        row_bits = glyph5x7_row(t0, row_g);
                        if (row_bits[4 - col_g]) is_text = 1'b1;
                    end

                    if (!is_text && (text_cols >= 2)) begin
                        gx0 = text_x0 + 6;
                        if ((cell_x >= gx0) && (cell_x < (gx0 + 5))) begin
                            col_g = cell_x - gx0;
                            row_bits = glyph5x7_row(t1, row_g);
                            if (row_bits[4 - col_g]) is_text = 1'b1;
                        end
                    end

                    if (!is_text && (text_cols >= 3)) begin
                        gx0 = text_x0 + 12;
                        if ((cell_x >= gx0) && (cell_x < (gx0 + 5))) begin
                            col_g = cell_x - gx0;
                            row_bits = glyph5x7_row(t2, row_g);
                            if (row_bits[4 - col_g]) is_text = 1'b1;
                        end
                    end
                end
            end
        end

        if (cell_id < KEY_COUNT) begin
            if (is_border)
                pixel_rgb = 16'hFFFF; // white border
            else if (is_text)
                pixel_rgb = 16'hFFFF; // white text
            else if (is_selected)
                pixel_rgb = rgb888_to_565(cell_color) ^ 16'h7BEF; // simple highlight
            else
                pixel_rgb = rgb888_to_565(cell_color);
        end
    end

endmodule
