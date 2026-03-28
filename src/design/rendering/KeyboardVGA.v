// VGA version of the on-screen keyboard.
// - Keeps the same 5x4 key layout and navigation behavior as Keyboard.v.
// - Renders by composing reusable ButtonVGA modules.
module KeyboardVGA #(
    parameter integer KEY_COUNT = 20,
    parameter integer COLS = 5,
    parameter integer ROWS = 4,
    parameter integer FONT_SCALE = 2,
    parameter integer KEYBOARD_X0 = 484,
    parameter integer KEYBOARD_Y0 = 352,
    // 【修改點】：將按鍵長寬獨立為參數，以完美填滿不規則空間
    parameter integer KEY_W = 31,
    parameter integer KEY_H = 32
) (
    input  wire        clk_nav,
    input  wire        btnU,
    input  wire        btnD,
    input  wire        btnL,
    input  wire        btnR,
    input  wire        btnC,
    input  wire [11:0] mouse_x,
    input  wire [11:0] mouse_y,
    input  wire        mouse_left,
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

    // =========================================================
    // Grid and panel geometry.
    // 移除了內部寫死的尺寸，改用傳入的 KEY_W 與 KEY_H
    // =========================================================
    localparam integer TOTAL_KEYS = COLS * ROWS;
    localparam integer KEYBOARD_W = COLS * KEY_W;
    localparam integer KEYBOARD_H = ROWS * KEY_H;
    
    // 移除不必要的 Padding，讓邊界完美貼合螢幕
    localparam integer PANEL_PAD = 0;
    localparam integer PANEL_BORDER = 0;
    localparam integer PANEL_X0 = KEYBOARD_X0;
    localparam integer PANEL_Y0 = KEYBOARD_Y0;
    localparam integer PANEL_X1 = KEYBOARD_X0 + KEYBOARD_W;
    localparam integer PANEL_Y1 = KEYBOARD_Y0 + KEYBOARD_H;

    // Shared button styling.
    localparam integer BORDER = 3;
    localparam integer EDGE_THICK = 2;
    localparam integer MARKER_OFFSET = 7;
    localparam integer MARKER_W = 3;
    localparam integer MARKER_H = 3;
    localparam integer FONT5_SCALE = FONT_SCALE;
    localparam integer FONT3_SCALE = FONT_SCALE;
    localparam integer ACTION_GAP = 0;
    localparam integer DEL_W = ((3 * KEY_W) / 2) - (ACTION_GAP / 2);
    localparam integer RST_W = (3 * KEY_W) - DEL_W - ACTION_GAP;

    // Color palette.
    localparam [23:0]
        RGB_BG              = 24'hF8F4EC,
        RGB_PANEL           = 24'hF3EADF,
        RGB_PANEL_BORDER    = 24'h5A4F44,
        RGB_BORDER          = 24'hCBBFB0,
        RGB_SELECTED_BORDER = 24'hFFD84D,
        RGB_SELECTED_MARKER = 24'hFFF7D2,
        RGB_PRESSED_BORDER  = 24'hD9A900,
        RGB_DIGIT           = 24'hAFCBFF,
        RGB_UNIT            = 24'hBEE8B7,
        RGB_DOT             = 24'hF9E79F,
        RGB_DEL             = 24'hFFB7B2,
        RGB_RST             = 24'hA9D8D0,
        RGB_NONE            = 24'hE7DDD2,
        RGB_TEXT            = 24'h5B534D;

    // Navigation state.
    reg [2:0] sel_row = 3'd0;
    reg [2:0] sel_col = 3'd0;
    reg btnU_d = 1'b0;
    reg btnD_d = 1'b0;
    reg btnL_d = 1'b0;
    reg btnR_d = 1'b0;
    reg btnC_d = 1'b0;
    reg mouse_left_d = 1'b0;
    reg [11:0] mouse_x_d = 12'd0;
    reg [11:0] mouse_y_d = 12'd0;
    reg use_mouse_selection = 1'b0;

    reg inside_keyboard;
    reg panel_area_active;
    reg mouse_inside_keyboard;
    reg mouse_moved;
    reg hover_valid;
    reg [11:0] mouse_rel_x;
    reg [11:0] mouse_rel_y;
    reg [2:0] mouse_col;
    reg [2:0] mouse_row;
    reg [4:0] hovered_key_id;
    reg [4:0] active_key_id;
    reg active_key_valid;
    reg active_pressed;
    integer k;

    wire [TOTAL_KEYS-1:0] button_inside;
    wire [(TOTAL_KEYS*12)-1:0] button_rgb_bus;

    function [11:0] rgb888_to_444;
        input [23:0] c;
        begin
            rgb888_to_444 = {c[23:20], c[15:12], c[7:4]};
        end
    endfunction

    function [7:0] key_ascii_for_id;
        input integer idx;
        begin
            case (idx)
                0: key_ascii_for_id = "1";
                1: key_ascii_for_id = "2";
                2: key_ascii_for_id = "3";
                3: key_ascii_for_id = "M";
                4: key_ascii_for_id = "k";
                5: key_ascii_for_id = "4";
                6: key_ascii_for_id = "5";
                7: key_ascii_for_id = "6";
                8: key_ascii_for_id = "m";
                9: key_ascii_for_id = "u";
                10: key_ascii_for_id = "7";
                11: key_ascii_for_id = "8";
                12: key_ascii_for_id = "9";
                13: key_ascii_for_id = "n";
                14: key_ascii_for_id = "p";
                15: key_ascii_for_id = ".";
                16: key_ascii_for_id = "0";
                17: key_ascii_for_id = 8'h08;
                18: key_ascii_for_id = 8'h7F;
                default: key_ascii_for_id = 8'h00;
            endcase
        end
    endfunction

    function [23:0] key_color_for_id;
        input integer idx;
        begin
            case (idx)
                0, 1, 2, 5, 6, 7, 10, 11, 12, 16: key_color_for_id = RGB_DIGIT;
                3, 4, 8, 9, 13, 14: key_color_for_id = RGB_UNIT;
                15: key_color_for_id = RGB_DOT;
                17: key_color_for_id = RGB_DEL;
                18: key_color_for_id = RGB_RST;
                default: key_color_for_id = RGB_NONE;
            endcase
        end
    endfunction

    function key_is_digit_for_id;
        input integer idx;
        begin
            case (idx)
                0, 1, 2, 5, 6, 7, 10, 11, 12, 16: key_is_digit_for_id = 1'b1;
                default: key_is_digit_for_id = 1'b0;
            endcase
        end
    endfunction

    function key_is_unit_for_id;
        input integer idx;
        begin
            case (idx)
                3, 4, 8, 9, 13, 14: key_is_unit_for_id = 1'b1;
                default: key_is_unit_for_id = 1'b0;
            endcase
        end
    endfunction

    function key_is_action_for_id;
        input integer idx;
        begin
            case (idx)
                15, 17, 18: key_is_action_for_id = 1'b1;
                default: key_is_action_for_id = 1'b0;
            endcase
        end
    endfunction

    function [7:0] label0_for_id;
        input integer idx;
        begin
            case (idx)
                0: label0_for_id = "1";
                1: label0_for_id = "2";
                2: label0_for_id = "3";
                3: label0_for_id = "M";
                4: label0_for_id = "k";
                5: label0_for_id = "4";
                6: label0_for_id = "5";
                7: label0_for_id = "6";
                8: label0_for_id = "m";
                9: label0_for_id = "u";
                10: label0_for_id = "7";
                11: label0_for_id = "8";
                12: label0_for_id = "9";
                13: label0_for_id = "n";
                14: label0_for_id = "p";
                15: label0_for_id = ".";
                16: label0_for_id = "0";
                17: label0_for_id = "D";
                18: label0_for_id = "R";
                default: label0_for_id = 8'h00;
            endcase
        end
    endfunction

    function [7:0] label1_for_id;
        input integer idx;
        begin
            case (idx)
                17: label1_for_id = "E";
                18: label1_for_id = "S";
                default: label1_for_id = 8'h00;
            endcase
        end
    endfunction

    function [7:0] label2_for_id;
        input integer idx;
        begin
            case (idx)
                17: label2_for_id = "L";
                18: label2_for_id = "T";
                default: label2_for_id = 8'h00;
            endcase
        end
    endfunction

    function integer text_cols_for_id;
        input integer idx;
        begin
            case (idx)
                17, 18: text_cols_for_id = 3;
                default: text_cols_for_id = 1;
            endcase
        end
    endfunction

    function small_text_for_id;
        input integer idx;
        begin
            case (idx)
                17, 18: small_text_for_id = 1'b0;
                default: small_text_for_id = 1'b0;
            endcase
        end
    endfunction

    function [4:0] key_id_for_grid;
        input integer row_idx;
        input integer col_idx;
        begin
            if (row_idx == 3) begin
                case (col_idx)
                    0: key_id_for_grid = 15;
                    1: key_id_for_grid = 16;
                    2: key_id_for_grid = 17;
                    3, 4: key_id_for_grid = 18;
                    default: key_id_for_grid = 5'd0;
                endcase
            end else begin
                key_id_for_grid = (row_idx * COLS) + col_idx;
            end
        end
    endfunction

    function integer button_x0_for_id;
        input integer idx;
        begin
            case (idx)
                17: button_x0_for_id = KEYBOARD_X0 + (2 * KEY_W);
                18: button_x0_for_id = KEYBOARD_X0 + (2 * KEY_W) + DEL_W + ACTION_GAP;
                default: button_x0_for_id = KEYBOARD_X0 + ((idx % COLS) * KEY_W);
            endcase
        end
    endfunction

    function integer button_w_for_id;
        input integer idx;
        begin
            case (idx)
                17: button_w_for_id = DEL_W;
                18: button_w_for_id = RST_W;
                default: button_w_for_id = KEY_W;
            endcase
        end
    endfunction

    genvar i;
    generate
        for (i = 0; i < TOTAL_KEYS; i = i + 1) begin : button_gen
            ButtonVGA #(
                .X0(button_x0_for_id(i)),
                .Y0(KEYBOARD_Y0 + ((i / COLS) * KEY_H)),
                .W(button_w_for_id(i)),
                .H(KEY_H),
                .BORDER(BORDER),
                .EDGE_THICK(EDGE_THICK),
                .MARKER_OFFSET(MARKER_OFFSET),
                .MARKER_W(MARKER_W),
                .MARKER_H(MARKER_H),
                .FONT5_SCALE(FONT5_SCALE),
                .FONT3_SCALE(FONT3_SCALE),
                .LABEL0(label0_for_id(i)),
                .LABEL1(label1_for_id(i)),
                .LABEL2(label2_for_id(i)),
                .TEXT_COLS(text_cols_for_id(i)),
                .SMALL_TEXT(small_text_for_id(i)),
                .FACE_RGB(key_color_for_id(i)),
                .BORDER_RGB(RGB_BORDER),
                .SELECTED_BORDER_RGB(RGB_SELECTED_BORDER),
                .SELECTED_MARKER_RGB(RGB_SELECTED_MARKER),
                .PRESSED_BORDER_RGB(RGB_PRESSED_BORDER),
                .TEXT_RGB(RGB_TEXT)
            ) button_inst (
                .enabled(i < KEY_COUNT),
                .selected(active_key_valid && (active_key_id == i[4:0])),
                .pressed(active_key_valid && (active_key_id == i[4:0]) && active_pressed),
                .x(x),
                .y(y),
                .pixel_rgb(button_rgb_bus[(i * 12) +: 12]),
                .inside_button(button_inside[i])
            );
        end
    endgenerate

    always @(posedge clk_nav) begin
        btnU_d <= btnU; btnD_d <= btnD; btnL_d <= btnL; btnR_d <= btnR; btnC_d <= btnC;
        mouse_left_d <= mouse_left; mouse_x_d <= mouse_x; mouse_y_d <= mouse_y;
        key_valid <= 1'b0;

        if (mouse_moved) use_mouse_selection <= 1'b1;

        if (btnU & ~btnU_d) begin
            use_mouse_selection <= 1'b0;
            if (sel_row == 0) sel_row <= ROWS - 1; else sel_row <= sel_row - 1'b1;
            if (((sel_row == 0) ? (ROWS - 1) : (sel_row - 1'b1)) == 3 && sel_col == 4) sel_col <= 3;
        end else if (btnD & ~btnD_d) begin
            use_mouse_selection <= 1'b0;
            if (sel_row == ROWS - 1) sel_row <= 0; else sel_row <= sel_row + 1'b1;
            if (((sel_row == ROWS - 1) ? 0 : (sel_row + 1'b1)) == 3 && sel_col == 4) sel_col <= 3;
        end else if (btnL & ~btnL_d) begin
            use_mouse_selection <= 1'b0;
            if (sel_row == 3) begin
                if (sel_col == 0) sel_col <= 3;
                else sel_col <= sel_col - 1'b1;
            end else begin
                if (sel_col == 0) sel_col <= COLS - 1; else sel_col <= sel_col - 1'b1;
            end
        end else if (btnR & ~btnR_d) begin
            use_mouse_selection <= 1'b0;
            if (sel_row == 3) begin
                if (sel_col >= 3) sel_col <= 0;
                else sel_col <= sel_col + 1'b1;
            end else begin
                if (sel_col == COLS - 1) sel_col <= 0; else sel_col <= sel_col + 1'b1;
            end
        end else if (mouse_left & ~mouse_left_d & hover_valid) begin
            use_mouse_selection <= 1'b1;
            if (hovered_key_id == 18) begin
                sel_row <= 3;
                sel_col <= 3;
            end else begin
                sel_row <= hovered_key_id / COLS;
                sel_col <= hovered_key_id % COLS;
            end
            key_valid <= 1'b1;
        end else if (btnC & ~btnC_d) begin
            use_mouse_selection <= 1'b0;
            key_valid <= 1'b1;
        end
    end

    always @(*) begin
        mouse_inside_keyboard = (mouse_x >= KEYBOARD_X0) && (mouse_x < (KEYBOARD_X0 + KEYBOARD_W)) && (mouse_y >= KEYBOARD_Y0) && (mouse_y < (KEYBOARD_Y0 + KEYBOARD_H));
        mouse_rel_x = mouse_x - KEYBOARD_X0;
        mouse_rel_y = mouse_y - KEYBOARD_Y0;
        mouse_col = mouse_rel_x / KEY_W;
        mouse_row = mouse_rel_y / KEY_H;
        hovered_key_id = (mouse_row * COLS) + mouse_col;

        if ((mouse_row == 3) &&
            (mouse_rel_x >= (2 * KEY_W)) &&
            (mouse_rel_x < ((2 * KEY_W) + DEL_W))) begin
            hovered_key_id = 17;
        end else if ((mouse_row == 3) &&
                     (mouse_rel_x >= ((2 * KEY_W) + DEL_W + ACTION_GAP)) &&
                     (mouse_rel_x < (5 * KEY_W))) begin
            hovered_key_id = 18;
        end

        mouse_moved = (mouse_x != mouse_x_d) || (mouse_y != mouse_y_d);
        hover_valid = mouse_inside_keyboard && (hovered_key_id < KEY_COUNT);
        active_key_valid = use_mouse_selection ? hover_valid : 1'b1;
        active_key_id = use_mouse_selection ? hovered_key_id : key_id_for_grid(sel_row, sel_col);
        active_pressed = (btnC && !use_mouse_selection) || (mouse_left && use_mouse_selection && hover_valid);

        if (active_key_valid) begin
            key_id = active_key_id;
            key_ascii = key_ascii_for_id(active_key_id);
            key_rgb = key_color_for_id(active_key_id);
            key_is_digit = key_is_digit_for_id(active_key_id);
            key_is_unit = key_is_unit_for_id(active_key_id);
            key_is_action = key_is_action_for_id(active_key_id);
        end else begin
            key_id = 5'd0;
            key_ascii = 8'h00;
            key_rgb = 24'h000000;
            key_is_digit = 1'b0;
            key_is_unit = 1'b0;
            key_is_action = 1'b0;
        end
    end

    always @(*) begin
        pixel_rgb = rgb888_to_444(RGB_BG);
        inside_keyboard = (x >= KEYBOARD_X0) && (x < (KEYBOARD_X0 + KEYBOARD_W)) && (y >= KEYBOARD_Y0) && (y < (KEYBOARD_Y0 + KEYBOARD_H));
        panel_area_active = (x >= PANEL_X0) && (x < PANEL_X1) && (y >= PANEL_Y0) && (y < PANEL_Y1);

        if (!inside_keyboard) begin
            if (panel_area_active) begin
                if ((x < (PANEL_X0 + PANEL_BORDER)) || (x >= (PANEL_X1 - PANEL_BORDER)) || (y < (PANEL_Y0 + PANEL_BORDER)) || (y >= (PANEL_Y1 - PANEL_BORDER))) begin
                    pixel_rgb = rgb888_to_444(RGB_PANEL_BORDER);
                end else begin
                    pixel_rgb = rgb888_to_444(RGB_PANEL);
                end
            end
        end else begin
            for (k = 0; k < TOTAL_KEYS; k = k + 1) begin
                if (button_inside[k]) begin
                    pixel_rgb = button_rgb_bus[(k * 12) +: 12];
                end
            end
        end
    end

endmodule
