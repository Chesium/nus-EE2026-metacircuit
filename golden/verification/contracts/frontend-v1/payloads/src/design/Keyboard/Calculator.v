// Calculator UI + 8-bit ripple-carry adder/subtractor
// - Render a 5x3 on-screen keyboard (13 keys + 1 wide DEL) for a 96x64 OLED.
// - Top 16 lines (y=0..15) show expression and result.
// - Decode key presses to build expression, compute, and display result.
//
// Keyboard layout (5x3 grid, y=16..63):
//   Row0:  7  8  9  +  -
//   Row1:  4  5  6  0  =
//   Row2:  1  2  3  DEL(wide, spans col3-col4)

`timescale 1ns / 1ps

module Calculator #(
    parameter integer OLED_W = 96,
    parameter integer OLED_H = 64,
    parameter integer DATA_W = 10         // 10-bit operands (0-1023)
) (
    input  wire        clk,              // system clock
    input  wire        clk_nav,          // navigation clock (~20Hz)
    input  wire        btnU,
    input  wire        btnD,
    input  wire        btnL,
    input  wire        btnR,
    input  wire        btnC,
    input  wire [6:0]  x,               // 0..95 pixel x
    input  wire [5:0]  y,               // 0..63 pixel y
    output reg  [15:0] pixel_rgb        // RGB565 for OLED
);

    // ========================================================================
    //  Geometry
    // ========================================================================
    localparam integer COLS       = 5;
    localparam integer ROWS_KB    = 3;   // keyboard rows only
    localparam integer KEY_H      = 16;  // height per key row
    localparam integer KEY_W      = 19;  // 96/5 = 19 (approx)
    localparam integer KB_Y_START = 16;  // keyboard starts at y=16
    localparam integer BORDER     = 1;

    // ========================================================================
    //  Color palette (RGB888)
    // ========================================================================
    localparam [23:0]
        RGB_DIGIT  = 24'h1E90FF, // DodgerBlue
        RGB_PLUS   = 24'h2ECC71, // Green
        RGB_MINUS  = 24'hE67E22, // Orange
        RGB_DEL    = 24'hE74C3C, // Red
        RGB_EQUAL  = 24'h9B59B6, // Purple
        RGB_NONE   = 24'h666666, // Gray
        RGB_EXPR   = 24'h000000, // Black background for expression area
        RGB_TEXT   = 24'hFFFFFF; // White text

    // ========================================================================
    //  Key IDs (logical, not row-major anymore due to wide DEL)
    // ========================================================================
    localparam [4:0]
        KEY_7     = 5'd0,  KEY_8 = 5'd1,  KEY_9  = 5'd2,
        KEY_PLUS  = 5'd3,  KEY_MINUS = 5'd4,
        KEY_4     = 5'd5,  KEY_5 = 5'd6,  KEY_6  = 5'd7,
        KEY_0     = 5'd8,  KEY_EQUAL   = 5'd9,
        KEY_1     = 5'd10, KEY_2 = 5'd11, KEY_3  = 5'd12,
        KEY_DEL   = 5'd13; // wide button

    // ========================================================================
    //  Calculator State Machine
    // ========================================================================
    localparam [2:0]
        ST_IDLE     = 3'd0,
        ST_OP1      = 3'd1,   // entering first operand
        ST_OP_SEL   = 3'd2,   // operator selected (+ or -)
        ST_OP2      = 3'd3,   // entering second operand
        ST_RESULT   = 3'd4,   // showing result
        ST_ERROR    = 3'd5;   // overflow / error

    reg [2:0] state       = ST_IDLE;
    reg [9:0] operand1    = 10'd0;
    reg [9:0] operand2    = 10'd0;
    reg       op_is_add   = 1'b0;   // 1 = add, 0 = subtract
    reg [9:0] result      = 10'd0;
    reg       has_error   = 1'b0;   // 1 if result out of range

    // Expression string buffer (no longer used as state, computed combinationally)
    
    // ========================================================================
    //  1-bit Adder chain (10-bit ripple-carry)
    // ========================================================================
    wire [9:0] adder_a;
    wire [9:0] adder_b;
    wire       adder_cin;
    wire [9:0] adder_sum;
    wire       adder_cout;

    wire [9:0] carry_chain;

    one_bit_adder add0 (
        .a(adder_a[0]), .b(adder_b[0]), .cin(adder_cin),
        .sum(adder_sum[0]), .cout(carry_chain[0])
    );
    one_bit_adder add1 (
        .a(adder_a[1]), .b(adder_b[1]), .cin(carry_chain[0]),
        .sum(adder_sum[1]), .cout(carry_chain[1])
    );
    one_bit_adder add2 (
        .a(adder_a[2]), .b(adder_b[2]), .cin(carry_chain[1]),
        .sum(adder_sum[2]), .cout(carry_chain[2])
    );
    one_bit_adder add3 (
        .a(adder_a[3]), .b(adder_b[3]), .cin(carry_chain[2]),
        .sum(adder_sum[3]), .cout(carry_chain[3])
    );
    one_bit_adder add4 (
        .a(adder_a[4]), .b(adder_b[4]), .cin(carry_chain[3]),
        .sum(adder_sum[4]), .cout(carry_chain[4])
    );
    one_bit_adder add5 (
        .a(adder_a[5]), .b(adder_b[5]), .cin(carry_chain[4]),
        .sum(adder_sum[5]), .cout(carry_chain[5])
    );
    one_bit_adder add6 (
        .a(adder_a[6]), .b(adder_b[6]), .cin(carry_chain[5]),
        .sum(adder_sum[6]), .cout(carry_chain[6])
    );
    one_bit_adder add7 (
        .a(adder_a[7]), .b(adder_b[7]), .cin(carry_chain[6]),
        .sum(adder_sum[7]), .cout(carry_chain[7])
    );
    one_bit_adder add8 (
        .a(adder_a[8]), .b(adder_b[8]), .cin(carry_chain[7]),
        .sum(adder_sum[8]), .cout(carry_chain[8])
    );
    one_bit_adder add9 (
        .a(adder_a[9]), .b(adder_b[9]), .cin(carry_chain[8]),
        .sum(adder_sum[9]), .cout(adder_cout)
    );

    // ========================================================================
    //  Compute logic (combinational)
    // ========================================================================
    wire [9:0] comp_a     = operand1;
    wire [9:0] comp_b_raw = operand2;
    wire [9:0] comp_b     = op_is_add ? comp_b_raw : ~comp_b_raw;
    wire       comp_cin   = op_is_add ? 1'b0 : 1'b1;
    wire [9:0] comp_sum;
    wire       comp_cout;

    assign adder_a   = comp_a;
    assign adder_b   = comp_b;
    assign adder_cin = comp_cin;
    assign comp_sum  = adder_sum;
    assign comp_cout = adder_cout;

    // Error detection:
    //   Addition overflow:  carry out = 1  (result > 1023)
    //   Subtraction underflow: carry out = 0 when a < b  → result wrapped
    wire error_add =  op_is_add  & comp_cout;
    wire error_sub = ~op_is_add  & ~comp_cout;  // A < B in subtraction
    wire calc_error = error_add | error_sub;

    // ========================================================================
    //  Button edge detection & navigation
    // ========================================================================
    reg [2:0] sel_row = 3'd0;
    reg [2:0] sel_col = 3'd0;
    reg       btnU_d = 1'b0;
    reg       btnD_d = 1'b0;
    reg       btnL_d = 1'b0;
    reg       btnR_d = 1'b0;
    reg       btnC_d = 1'b0;
    reg       key_pulse = 1'b0;   // 1-cycle pulse on confirm

    // Current logical key under selection
    wire [4:0] sel_key_id;
    assign sel_key_id = (sel_row == 3'd2 && sel_col >= 3'd3) ? KEY_DEL
                        : (sel_row * COLS) + sel_col;

    always @(posedge clk_nav) begin
        btnU_d <= btnU;
        btnD_d <= btnD;
        btnL_d <= btnL;
        btnR_d <= btnR;
        btnC_d <= btnC;
        key_pulse <= 1'b0;

        if (btnU & ~btnU_d) begin
            if (sel_row == 0) sel_row <= 3'd2;
            else sel_row <= sel_row - 1'b1;
        end else if (btnD & ~btnD_d) begin
            if (sel_row == 2) sel_row <= 3'd0;
            else sel_row <= sel_row + 1'b1;
        end else if (btnL & ~btnL_d) begin
            if (sel_col == 0) sel_col <= 3'd4;
            else sel_col <= sel_col - 1'b1;
        end else if (btnR & ~btnR_d) begin
            // DEL spans col3-4, so right from col2 goes to col3
            if (sel_col == 4) sel_col <= 3'd0;
            else sel_col <= sel_col + 1'b1;
        end else if (btnC & ~btnC_d) begin
            key_pulse <= 1'b1;
        end
    end

    // ========================================================================
    //  Expression builder & state transitions
    // ========================================================================
    reg [3:0] digit_val;
    reg       is_digit;
    reg       is_plus;
    reg       is_minus;
    reg       is_equal;
    reg       is_del;

    always @(*) begin
        is_digit = 1'b0;
        is_plus  = 1'b0;
        is_minus = 1'b0;
        is_equal = 1'b0;
        is_del   = 1'b0;
        digit_val = 4'd0;

        case (sel_key_id)
            KEY_0: begin is_digit = 1'b1; digit_val = 4'd0; end
            KEY_1: begin is_digit = 1'b1; digit_val = 4'd1; end
            KEY_2: begin is_digit = 1'b1; digit_val = 4'd2; end
            KEY_3: begin is_digit = 1'b1; digit_val = 4'd3; end
            KEY_4: begin is_digit = 1'b1; digit_val = 4'd4; end
            KEY_5: begin is_digit = 1'b1; digit_val = 4'd5; end
            KEY_6: begin is_digit = 1'b1; digit_val = 4'd6; end
            KEY_7: begin is_digit = 1'b1; digit_val = 4'd7; end
            KEY_8: begin is_digit = 1'b1; digit_val = 4'd8; end
            KEY_9: begin is_digit = 1'b1; digit_val = 4'd9; end
            KEY_PLUS:  is_plus  = 1'b1;
            KEY_MINUS: is_minus = 1'b1;
            KEY_EQUAL: is_equal = 1'b1;
            KEY_DEL:   is_del   = 1'b1;
            default: ;
        endcase
    end

    // Append a digit to the current operand being entered
    function [9:0] append_digit;
        input [9:0] current;
        input [3:0] d;
        reg [15:0] tmp;
        begin
            tmp = current * 10 + d;
            // saturate at 1023
            if (tmp > 1023) append_digit = 10'd1023;
            else append_digit = tmp[9:0];
        end
    endfunction

    // Helper: get character at index (0=leftmost) for a number 0-1023
    // Returns 0 if no character at this index
    function [7:0] get_digit_char;
        input [9:0] num;
        input integer idx;
        reg [7:0] digits [0:3];
        integer d, i;
        reg [9:0] tmp;
        begin
            tmp = num;
            d = 0;
            // Extract digits (reversed, max 4 for 0-1023)
            for (i = 0; i < 4; i = i + 1) begin
                if (tmp > 0) begin
                    digits[i] = (tmp % 10) + 8'd48;
                    tmp = tmp / 10;
                    d = d + 1;
                end else begin
                    digits[i] = 8'h00;
                end
            end
            if (num == 0) begin
                if (idx == 0) get_digit_char = "0";
                else get_digit_char = 8'h00;
            end else begin
                // Return character at idx from left
                if (idx < d) get_digit_char = digits[d - 1 - idx];
                else get_digit_char = 8'h00;
            end
        end
    endfunction

    // State transitions (pure logic, no display buffers)
    always @(posedge clk_nav) begin
        if (key_pulse) begin
            case (state)
                ST_IDLE: begin
                    if (is_digit) begin
                        operand1 <= digit_val;
                        state <= ST_OP1;
                    end
                end
                ST_OP1: begin
                    if (is_digit) begin
                        operand1 <= append_digit(operand1, digit_val);
                    end else if (is_plus) begin
                        op_is_add <= 1'b1;
                        state <= ST_OP_SEL;
                    end else if (is_minus) begin
                        op_is_add <= 1'b0;
                        state <= ST_OP_SEL;
                    end else if (is_del) begin
                        if (operand1 >= 10)
                            operand1 <= operand1 / 10;
                        else begin
                            operand1 <= 10'd0;
                            state <= ST_IDLE;
                        end
                    end
                end
                ST_OP_SEL: begin
                    if (is_digit) begin
                        operand2 <= digit_val;
                        state <= ST_OP2;
                    end else if (is_del) begin
                        state <= ST_OP1;
                    end
                end
                ST_OP2: begin
                    if (is_digit) begin
                        operand2 <= append_digit(operand2, digit_val);
                    end else if (is_equal) begin
                        result <= comp_sum;
                        has_error <= calc_error;
                        state <= calc_error ? ST_ERROR : ST_RESULT;
                    end else if (is_del) begin
                        if (operand2 >= 10)
                            operand2 <= operand2 / 10;
                        else begin
                            operand2 <= 10'd0;
                            state <= ST_OP_SEL;
                        end
                    end
                end
                ST_RESULT, ST_ERROR: begin
                    if (is_del) begin
                        state <= ST_IDLE;
                        operand1 <= 10'd0;
                        operand2 <= 10'd0;
                    end
                end
                default: state <= ST_IDLE;
            endcase
        end
    end

    // ========================================================================
    //  Build expression string for display (purely combinational)
    // ========================================================================
    reg [7:0] display_buf [0:15];
    integer   display_len;
    integer len1, len2, len3;
    integer i;
    always @(*) begin
        for (i = 0; i < 16; i = i + 1) display_buf[i] = 8'h00;
        display_len = 0;

        case (state)
            ST_IDLE: begin
                display_buf[0] = "R"; display_buf[1] = "e";
                display_buf[2] = "a"; display_buf[3] = "d";
                display_buf[4] = "y";
                display_len = 5;
            end
            ST_OP1: begin
                for (i = 0; i < 4; i = i + 1) display_buf[i] = get_digit_char(operand1, i);
                display_len = get_num_digits(operand1);
            end
            ST_OP_SEL: begin
                len1 = get_num_digits(operand1);
                for (i = 0; i < 4; i = i + 1) display_buf[i] = get_digit_char(operand1, i);
                display_buf[len1] = op_is_add ? "+" : "-";
                display_len = len1 + 1;
            end
            ST_OP2: begin
                len1 = get_num_digits(operand1);
                for (i = 0; i < 4; i = i + 1) display_buf[i] = get_digit_char(operand1, i);
                display_buf[len1] = op_is_add ? "+" : "-";
                for (i = 0; i < 4; i = i + 1) display_buf[len1 + 1 + i] = get_digit_char(operand2, i);
                display_len = len1 + 1 + get_num_digits(operand2);
            end
            ST_RESULT: begin 
                len1 = get_num_digits(operand1);
                len2 = get_num_digits(operand2);
                for (i = 0; i < 4; i = i + 1) display_buf[i] = get_digit_char(operand1, i);
                display_buf[len1] = op_is_add ? "+" : "-";
                for (i = 0; i < 4; i = i + 1) display_buf[len1 + 1 + i] = get_digit_char(operand2, i);
                display_buf[len1 + 1 + len2] = "=";
                len3 = get_num_digits(result);
                for (i = 0; i < 4; i = i + 1) display_buf[len1 + 1 + len2 + 1 + i] = get_digit_char(result, i);
                display_len = len1 + 1 + len2 + 1 + len3;
            end
            ST_ERROR: begin
                display_buf[0] = "E"; display_buf[1] = "r";
                display_buf[2] = "r"; display_buf[3] = "o";
                display_buf[4] = "r";
                display_len = 5;
            end
            default: ;
        endcase
    end

    // Helper: get number of digits for a number 0-1023
    function integer get_num_digits;
        input [9:0] num;
        begin
            if (num == 0) get_num_digits = 1;
            else if (num < 10) get_num_digits = 1;
            else if (num < 100) get_num_digits = 2;
            else if (num < 1000) get_num_digits = 3;
            else get_num_digits = 4;
        end
    endfunction

    // ========================================================================
    //  Font: 5x7 glyphs (same as Keyboard.v)
    // ========================================================================
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
                "+": glyph5x7 = 35'b00000_00100_00100_11111_00100_00100_00000;
                "-": glyph5x7 = 35'b00000_00000_00000_11111_00000_00000_00000;
                "=": glyph5x7 = 35'b00000_00000_11111_00000_11111_00000_00000;
                "E": glyph5x7 = 35'b11111_10000_10000_11110_10000_10000_11111;
                "r": glyph5x7 = 35'b00000_00000_10110_11001_10000_10000_10000;
                "o": glyph5x7 = 35'b00000_00000_01110_10001_10001_10001_01110;
                "R": glyph5x7 = 35'b11110_10001_10001_11110_10100_10010_10001;
                "e": glyph5x7 = 35'b00000_00000_01110_10001_11111_10000_01110;
                "a": glyph5x7 = 35'b00000_00000_01110_00001_01111_10001_01111;
                "d": glyph5x7 = 35'b00000_00001_01101_10011_10001_10001_01111;
                "y": glyph5x7 = 35'b00000_00000_10001_10001_01010_00100_01000;
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

    // 3x5 font for compact labels
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

    // ========================================================================
    //  Pixel coordinate helpers
    // ========================================================================
    reg [2:0] col;
    reg [2:0] row;
    reg [4:0] cell_id;
    reg [6:0] cell_x;
    reg [5:0] cell_y;
    reg       valid_kb_pixel;

    always @(*) begin
        // map x to column
        if (x < KEY_W) col = 3'd0;
        else if (x < (KEY_W * 2)) col = 3'd1;
        else if (x < (KEY_W * 3)) col = 3'd2;
        else if (x < (KEY_W * 4)) col = 3'd3;
        else col = 3'd4;

        // Check if pixel is in keyboard area
        if (y >= KB_Y_START) begin
            valid_kb_pixel = 1'b1;
            // map y to keyboard row
            if ((y - KB_Y_START) < KEY_H) row = 3'd0;
            else if ((y - KB_Y_START) < (KEY_H * 2)) row = 3'd1;
            else row = 3'd2;

            // handle wide DEL: if row2 and col>=3, treat as DEL
            if (row == 3'd2 && col >= 3'd3)
                cell_id = KEY_DEL;
            else
                cell_id = (row * COLS) + col;

            cell_x = x - (col * KEY_W);
            cell_y = y - KB_Y_START - (row * KEY_H);
        end else begin
            valid_kb_pixel = 1'b0;
            row = 3'd0;
            cell_id = 5'd0;
            cell_x = 7'd0;
            cell_y = 6'd0;
        end
    end

    // ========================================================================
    //  Per-cell color & label determination
    // ========================================================================
    reg [23:0] cell_color;
    reg        is_border;
    reg        is_selected;
    reg        is_text;
    reg [2:0]  text_cols;
    reg [7:0]  t0, t1, t2;
    reg [2:0]  text_h;
    reg        small_text;
    reg [6:0]  text_w;
    reg [6:0]  text_x0;
    reg [5:0]  text_y0;
    reg        is_expr_area;
    reg [6:0]  local_x;  // Unified X coordinate for rendering

    always @(*) begin
        pixel_rgb = 16'h0000;
        cell_color = RGB_NONE;
        is_border = 1'b0;
        is_selected = 1'b0;
        is_text = 1'b0;
        text_cols = 3'd0;
        t0 = 8'h00; t1 = 8'h00; t2 = 8'h00;
        text_h = 3'd7;
        small_text = 1'b0;
        is_expr_area = (y < KB_Y_START);

        if (is_expr_area) begin
            // --- Expression / Result area ---
            pixel_rgb = rgb888_to_565(RGB_EXPR);
            // render expression string here
            render_expr_text(x, y);
            pixel_rgb = is_text ? rgb888_to_565(RGB_TEXT) : rgb888_to_565(RGB_EXPR);
        end else if (valid_kb_pixel) begin
            // --- Keyboard area ---
            // determine cell color based on key
            case (cell_id)
                KEY_0, KEY_1, KEY_2, KEY_3, KEY_4,
                KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
                    cell_color = RGB_DIGIT;
                KEY_PLUS:  cell_color = RGB_PLUS;
                KEY_MINUS: cell_color = RGB_MINUS;
                KEY_DEL:   cell_color = RGB_DEL;
                KEY_EQUAL: cell_color = RGB_EQUAL;
                default:   cell_color = RGB_NONE;
            endcase

            // border pixels
            is_border = (cell_x < BORDER) || (cell_y < BORDER) ||
                        (cell_x >= (KEY_W - BORDER)) || (cell_y >= (KEY_H - BORDER));

            // Remove internal vertical border for DEL wide button to merge the two cells visually
            if (cell_id == KEY_DEL) begin
                if (col == 3'd3) 
                    is_border = (cell_x < BORDER) || (cell_y < BORDER) || (cell_y >= (KEY_H - BORDER)); // Skip right border
                else if (col == 3'd4) 
                    is_border = (cell_y < BORDER) || (cell_x >= (KEY_W - BORDER)) || (cell_y >= (KEY_H - BORDER)); // Skip left border
            end

            // selected highlight
            is_selected = (cell_id == sel_key_id);

            // label text for each key
            case (cell_id)
                KEY_0: begin t0 = "0"; text_cols = 3'd1; end
                KEY_1: begin t0 = "1"; text_cols = 3'd1; end
                KEY_2: begin t0 = "2"; text_cols = 3'd1; end
                KEY_3: begin t0 = "3"; text_cols = 3'd1; end
                KEY_4: begin t0 = "4"; text_cols = 3'd1; end
                KEY_5: begin t0 = "5"; text_cols = 3'd1; end
                KEY_6: begin t0 = "6"; text_cols = 3'd1; end
                KEY_7: begin t0 = "7"; text_cols = 3'd1; end
                KEY_8: begin t0 = "8"; text_cols = 3'd1; end
                KEY_9: begin t0 = "9"; text_cols = 3'd1; end
                KEY_PLUS:  begin t0 = "+"; text_cols = 3'd1; end
                KEY_MINUS: begin t0 = "-"; text_cols = 3'd1; end
                KEY_EQUAL: begin t0 = "="; text_cols = 3'd1; end
                KEY_DEL: begin
                    t0 = "D"; t1 = "E"; t2 = "L";
                    text_cols = 3'd3; text_h = 3'd5; small_text = 1'b1;
                end
                default: begin t0 = 8'h00; text_cols = 3'd0; end
            endcase

            // text placement (centered)
            if (text_cols == 0)
                text_w = 0;
            else if (small_text)
                text_w = (text_cols * 3) + ((text_cols - 1) * 1);
            else
                text_w = (text_cols * 5) + ((text_cols - 1) * 1);
            
            // Calculate X offset for centering
            if (cell_id == KEY_DEL) begin
                // DEL spans 2 cells (38 pixels wide)
                text_x0 = ((KEY_W * 2) - text_w) >> 1;
            end else begin
                text_x0 = (KEY_W - text_w) >> 1;
            end
            text_y0 = (KEY_H - text_h) >> 1;

            // Unified local X for rendering
            if (cell_id == KEY_DEL)
                local_x = x - (KEY_W * 3); // Global x minus DEL start position
            else
                local_x = cell_x;

            // check if pixel is inside a glyph
            if (text_cols != 0) begin
                if ((cell_y >= text_y0) && (cell_y < (text_y0 + text_h))) begin
                    // check against each glyph column
                    if (small_text) begin
                        render_3x5_text(local_x, cell_y - text_y0, t0, t1, t2, text_cols, text_x0);
                    end else begin
                        render_5x7_text(local_x, cell_y - text_y0, t0, t1, t2, text_cols, text_x0);
                    end
                    // is_text is set by render functions
                end
            end

            // final pixel color
            if (is_border)
                pixel_rgb = 16'hFFFF;
            else if (is_text)
                pixel_rgb = 16'hFFFF;
            else if (is_selected)
                pixel_rgb = rgb888_to_565(cell_color) ^ 16'h7BEF; // highlight
            else
                pixel_rgb = rgb888_to_565(cell_color);
        end else begin
            // Outside keyboard area (should not happen with proper region check)
            pixel_rgb = 16'h0000;
        end
    end

    // ========================================================================
    //  Expression text renderer (5x7 font, single line at y=0..7)
    // ========================================================================
    task render_expr_text;
        input [6:0] px;
        input [5:0] py;
        integer offset;
        reg [2:0] row_g;
        reg [4:0] col_g;
        reg [4:0] row_bits;
        reg [6:0] text_width;
        reg [6:0] start_x;
        begin
            is_text = 1'b0;
            if (py < 8) begin  // only top 8 pixels for expression
                row_g = py[2:0];
                // Calculate text width and center it
                text_width = display_len * 6 - 1;  // 5 pixels + 1 spacing per char, minus last spacing
                start_x = (96 - text_width) >> 1;  // center horizontally
                offset = start_x;

            // Unrolled loop for synthesis (max 16 chars)
            if (0 < display_len && px >= offset && px < offset + 5) begin
                col_g = px - offset;
                row_bits = glyph5x7_row(display_buf[0], row_g);
                if (row_bits[4 - col_g]) is_text = 1'b1;
            end
            offset = offset + 6;

            if (1 < display_len && px >= offset && px < offset + 5) begin
                col_g = px - offset;
                row_bits = glyph5x7_row(display_buf[1], row_g);
                if (row_bits[4 - col_g]) is_text = 1'b1;
            end
            offset = offset + 6;

            if (2 < display_len && px >= offset && px < offset + 5) begin
                col_g = px - offset;
                row_bits = glyph5x7_row(display_buf[2], row_g);
                if (row_bits[4 - col_g]) is_text = 1'b1;
            end
            offset = offset + 6;

            if (3 < display_len && px >= offset && px < offset + 5) begin
                col_g = px - offset;
                row_bits = glyph5x7_row(display_buf[3], row_g);
                if (row_bits[4 - col_g]) is_text = 1'b1;
            end
            offset = offset + 6;

            if (4 < display_len && px >= offset && px < offset + 5) begin
                col_g = px - offset;
                row_bits = glyph5x7_row(display_buf[4], row_g);
                if (row_bits[4 - col_g]) is_text = 1'b1;
            end
            offset = offset + 6;

            if (5 < display_len && px >= offset && px < offset + 5) begin
                col_g = px - offset;
                row_bits = glyph5x7_row(display_buf[5], row_g);
                if (row_bits[4 - col_g]) is_text = 1'b1;
            end
            offset = offset + 6;

            if (6 < display_len && px >= offset && px < offset + 5) begin
                col_g = px - offset;
                row_bits = glyph5x7_row(display_buf[6], row_g);
                if (row_bits[4 - col_g]) is_text = 1'b1;
            end
            offset = offset + 6;

            if (7 < display_len && px >= offset && px < offset + 5) begin
                col_g = px - offset;
                row_bits = glyph5x7_row(display_buf[7], row_g);
                if (row_bits[4 - col_g]) is_text = 1'b1;
            end
            offset = offset + 6;

            if (8 < display_len && px >= offset && px < offset + 5) begin
                col_g = px - offset;
                row_bits = glyph5x7_row(display_buf[8], row_g);
                if (row_bits[4 - col_g]) is_text = 1'b1;
            end
            offset = offset + 6;

            if (9 < display_len && px >= offset && px < offset + 5) begin
                col_g = px - offset;
                row_bits = glyph5x7_row(display_buf[9], row_g);
                if (row_bits[4 - col_g]) is_text = 1'b1;
            end
            offset = offset + 6;

            if (10 < display_len && px >= offset && px < offset + 5) begin
                col_g = px - offset;
                row_bits = glyph5x7_row(display_buf[10], row_g);
                if (row_bits[4 - col_g]) is_text = 1'b1;
            end
            offset = offset + 6;

            if (11 < display_len && px >= offset && px < offset + 5) begin
                col_g = px - offset;
                row_bits = glyph5x7_row(display_buf[11], row_g);
                if (row_bits[4 - col_g]) is_text = 1'b1;
            end
            offset = offset + 6;

            if (12 < display_len && px >= offset && px < offset + 5) begin
                col_g = px - offset;
                row_bits = glyph5x7_row(display_buf[12], row_g);
                if (row_bits[4 - col_g]) is_text = 1'b1;
            end
            offset = offset + 6;

            if (13 < display_len && px >= offset && px < offset + 5) begin
                col_g = px - offset;
                row_bits = glyph5x7_row(display_buf[13], row_g);
                if (row_bits[4 - col_g]) is_text = 1'b1;
            end
            offset = offset + 6;

            if (14 < display_len && px >= offset && px < offset + 5) begin
                col_g = px - offset;
                row_bits = glyph5x7_row(display_buf[14], row_g);
                if (row_bits[4 - col_g]) is_text = 1'b1;
            end
            offset = offset + 6;

            if (15 < display_len && px >= offset && px < offset + 5) begin
                col_g = px - offset;
                row_bits = glyph5x7_row(display_buf[15], row_g);
                if (row_bits[4 - col_g]) is_text = 1'b1;
            end
            end  // if (py < 8)
        end
    endtask

    // ========================================================================
    //  5x7 text renderer for keyboard labels
    // ========================================================================
    task render_5x7_text;
        input [6:0] check_x;
        input [5:0] check_y;
        input [7:0] c0, c1, c2;
        input [2:0] cols;
        input [6:0] tx0;
        reg [6:0] gx;
        reg [4:0] row_bits;
        reg [2:0] col_g;
        begin
            is_text = 1'b0;
            // glyph 0
            gx = tx0;
            if (check_x >= gx && check_x < gx + 5) begin
                col_g = check_x - gx;
                row_bits = glyph5x7_row(c0, check_y);
                if (row_bits[4 - col_g]) is_text = 1'b1;
            end
            // glyph 1
            if (!is_text && cols >= 2) begin
                gx = tx0 + 6;
                if (check_x >= gx && check_x < gx + 5) begin
                    col_g = check_x - gx;
                    row_bits = glyph5x7_row(c1, check_y);
                    if (row_bits[4 - col_g]) is_text = 1'b1;
                end
            end
            // glyph 2
            if (!is_text && cols >= 3) begin
                gx = tx0 + 12;
                if (check_x >= gx && check_x < gx + 5) begin
                    col_g = check_x - gx;
                    row_bits = glyph5x7_row(c2, check_y);
                    if (row_bits[4 - col_g]) is_text = 1'b1;
                end
            end
        end
    endtask

    // ========================================================================
    //  3x5 text renderer for compact labels (DEL)
    // ========================================================================
    task render_3x5_text;
        input [6:0] check_x;
        input [5:0] check_y;
        input [7:0] c0, c1, c2;
        input [2:0] cols;
        input [6:0] tx0;
        reg [6:0] gx;
        reg [2:0] row_bits;
        reg [2:0] col_g;
        begin
            is_text = 1'b0;
            // glyph 0
            gx = tx0;
            if (check_x >= gx && check_x < gx + 3) begin
                col_g = check_x - gx;
                row_bits = glyph3x5_row(c0, check_y);
                if (row_bits[2 - col_g]) is_text = 1'b1;
            end
            // glyph 1
            if (!is_text && cols >= 2) begin
                gx = tx0 + 4;
                if (check_x >= gx && check_x < gx + 3) begin
                    col_g = check_x - gx;
                    row_bits = glyph3x5_row(c1, check_y);
                    if (row_bits[2 - col_g]) is_text = 1'b1;
                end
            end
            // glyph 2
            if (!is_text && cols >= 3) begin
                gx = tx0 + 8;
                if (check_x >= gx && check_x < gx + 3) begin
                    col_g = check_x - gx;
                    row_bits = glyph3x5_row(c2, check_y);
                    if (row_bits[2 - col_g]) is_text = 1'b1;
                end
            end
        end
    endtask

    // ========================================================================
    //  Helper: RGB888 to RGB565
    // ========================================================================
    function [15:0] rgb888_to_565;
        input [23:0] c;
        begin
            rgb888_to_565 = {c[23:19], c[15:10], c[7:3]};
        end
    endfunction

endmodule
