`timescale 1ns / 1ps

module GlobalRender_top (
    input  wire        CLK100MHZ,
    input  wire [15:0] SW,
    output wire [15:0] LED,
    output wire [7:0]  SEG,
    output wire [3:0]  AN,
    input  wire        BTNC,
    input  wire        BTNU,
    input  wire        BTNL,
    input  wire        BTNR,
    input  wire        BTND,
    output wire [7:0]  JC,
    output wire [3:0]  VGARED,
    output wire [3:0]  VGABLUE,
    output wire [3:0]  VGAGREEN,
    output wire        HSYNC,
    output wire        VSYNC,
    inout              PS2CLK,
    inout              PS2DATA
);

    localparam [11:0] BLACK            = 12'h000;
    localparam [11:0] BACKGROUND       = 12'hECC;
    localparam integer SCREEN_H        = 480;
    localparam integer SCREEN_W        = 640;
    localparam integer TOP_BAR_H       = 64;
    localparam integer LEFT_BAR_W      = 64;
    localparam integer RIGHT_BAR_W     = 156;
    localparam integer BOTTOM_BAR_H    = 128;
    localparam integer CANVAS_X0       = LEFT_BAR_W;
    localparam integer CANVAS_Y0       = TOP_BAR_H;
    localparam integer CANVAS_W        = SCREEN_W - LEFT_BAR_W - RIGHT_BAR_W;
    localparam integer CANVAS_H        = SCREEN_H - TOP_BAR_H - BOTTOM_BAR_H;
    // =========================================================
    // 【決定生死的遮罩精算】
    // 在 Top 模組裡精準宣告 155 x 128 的物理空間，防止被切斷！
    // 5列 * 31寬 = 155, 4行 * 32高 = 128
    // =========================================================
    localparam integer KEYBOARD_SCALE  = 2;
    localparam integer KEY_W           = 31;
    localparam integer KEY_H           = 32;
    localparam integer KEYBOARD_W      = 5 * KEY_W;
    localparam integer KEYBOARD_H      = 4 * KEY_H; 
    localparam integer KEYBOARD_MARGIN = 0;
    localparam integer KEYBOARD_PANEL_PAD = 0;

    localparam integer KEYBOARD_X      = SCREEN_W - RIGHT_BAR_W + 1;
    // 485，讓它緊貼右側邊緣
    localparam integer KEYBOARD_Y      = SCREEN_H - BOTTOM_BAR_H;
    // 352
    
    localparam integer KEYBOARD_REGION_X0 = KEYBOARD_X;
    localparam integer KEYBOARD_REGION_Y0 = KEYBOARD_Y;
    localparam integer KEYBOARD_REGION_X1 = KEYBOARD_X + KEYBOARD_W;
    localparam integer KEYBOARD_REGION_Y1 = KEYBOARD_Y + KEYBOARD_H;
    // =========================================================

    wire clk_pixel, clk_nav, video_on;
    wire [11:0] x_pos, y_pos;
    reg  [11:0] rgb;

    wire [11:0] keyboard_rgb;
    wire [4:0]  keyboard_key_id;
    wire        keyboard_key_valid;
    wire [7:0]  keyboard_key_ascii;
    reg  [7:0]  last_ascii = 8'h00;

    wire        keyboard_region_active;

    wire [11:0] circuit_canvas_rgb;
    wire        circuit_canvas_rendered;
    reg  [11:0] ui_rgb;
    wire [11:0] toolbar_rgb;
    wire        toolbar_rendered;
    wire [2:0]  selected_toolbar_idx;
    reg         mouse_left_d_sys = 1'b0;

    reg top_bar_active, left_bar_active, right_bar_active, canvas_label_active, title_active, frame_active, icon_active, grid_line_active;
    integer dx, dy;

    wire [11:0] mouse_xpos, mouse_ypos;
    wire [3:0]  mouse_zpos;
    wire        mouse_left, mouse_middle, mouse_right, mouse_new_event;
    reg  [11:0] mouse_set_value;
    reg         mouse_set_max_x, mouse_set_max_y;

    wire        mouse_display_enable;
    wire [3:0]  mouse_r, mouse_g, mouse_b;
    wire [11:0] mouse_rgb;
    reg         circuit_canvas_ram_w_en = 1'b0;
    reg  [7:0]  circuit_canvas_ram_w_addr = 8'd0;
    wire [7:0]  circuit_canvas_ram_r_addr;
    reg  [15:0] circuit_canvas_ram_w_data = 16'd0;
    wire [15:0] circuit_canvas_ram_r_data;

    reg  [31:0] init_cycles = 32'd0;

    reg         clear_canvas_active = 1'b0;
    reg  [7:0]  clear_canvas_addr = 8'd0;
    reg         pending_second_tool_write = 1'b0;
    reg  [7:0]  pending_second_tool_addr = 8'd0;
    reg  [15:0] pending_second_tool_data = 16'd0;

    assign keyboard_region_active = (x_pos >= KEYBOARD_REGION_X0) && (x_pos < KEYBOARD_REGION_X1) && (y_pos >= KEYBOARD_REGION_Y0) && (y_pos < KEYBOARD_REGION_Y1);

    assign mouse_rgb = {mouse_r, mouse_g, mouse_b};

    function [11:0] rgb888_to_444;
        input [23:0] c;
        begin
            rgb888_to_444 = {c[23:20], c[15:12], c[7:4]};
        end
    endfunction

    function [15:0] make_cell_data;
        input [1:0] rotation;
        input [5:0] sprite_type;
        begin
            make_cell_data = {7'b0000000, rotation, sprite_type, 1'b1};
        end
    endfunction

    function [15:0] toolbar_first_cell_data;
        input [2:0] tool_idx;
        begin
            case (tool_idx)
                3'd1: toolbar_first_cell_data = make_cell_data(2'b00, 6'd0);   // wire
                3'd2: toolbar_first_cell_data = make_cell_data(2'b00, 6'd1);   // elbow
                3'd3: toolbar_first_cell_data = make_cell_data(2'b00, 6'd5);   // resistor left
                3'd4: toolbar_first_cell_data = make_cell_data(2'b00, 6'd13);  // capacitor left
                3'd5: toolbar_first_cell_data = make_cell_data(2'b00, 6'd7);   // voltage left
                3'd6: toolbar_first_cell_data = make_cell_data(2'b00, 6'd9);   // current left
                3'd7: toolbar_first_cell_data = make_cell_data(2'b00, 6'd11);  // diode left
                default: toolbar_first_cell_data = 16'd0;
            endcase
        end
    endfunction

    function [15:0] toolbar_second_cell_data;
        input [2:0] tool_idx;
        begin
            case (tool_idx)
                3'd3: toolbar_second_cell_data = make_cell_data(2'b00, 6'd6);   // resistor right
                3'd4: toolbar_second_cell_data = make_cell_data(2'b00, 6'd14);  // capacitor right
                3'd5: toolbar_second_cell_data = make_cell_data(2'b00, 6'd8);   // voltage right
                3'd6: toolbar_second_cell_data = make_cell_data(2'b00, 6'd10);  // current right
                3'd7: toolbar_second_cell_data = make_cell_data(2'b00, 6'd12);  // diode right
                default: toolbar_second_cell_data = 16'd0;
            endcase
        end
    endfunction

    function toolbar_tool_uses_two_cells;
        input [2:0] tool_idx;
        begin
            case (tool_idx)
                3'd3, 3'd4, 3'd5, 3'd6, 3'd7: toolbar_tool_uses_two_cells = 1'b1;
                default: toolbar_tool_uses_two_cells = 1'b0;
            endcase
        end
    endfunction

    function [4:0] glyph5x7_row;
        input [7:0] c;
        input [2:0] r;
        begin
            case (c)
                "0": case (r) 0: glyph5x7_row = 5'b01110; 1: glyph5x7_row = 5'b10001; 2: glyph5x7_row = 5'b10011; 3: glyph5x7_row = 5'b10101; 4: glyph5x7_row = 5'b11001; 5: glyph5x7_row = 5'b10001; default: glyph5x7_row = 5'b01110; endcase
                "1": case (r) 0: glyph5x7_row = 5'b00100; 1: glyph5x7_row = 5'b01100; 2: glyph5x7_row = 5'b00100; 3: glyph5x7_row = 5'b00100; 4: glyph5x7_row = 5'b00100; 5: glyph5x7_row = 5'b00100; default: glyph5x7_row = 5'b01110; endcase
                "2": case (r) 0: glyph5x7_row = 5'b01110; 1: glyph5x7_row = 5'b10001; 2: glyph5x7_row = 5'b00001; 3: glyph5x7_row = 5'b00010; 4: glyph5x7_row = 5'b00100; 5: glyph5x7_row = 5'b01000; default: glyph5x7_row = 5'b11111; endcase
                "3": case (r) 0: glyph5x7_row = 5'b11110; 1: glyph5x7_row = 5'b00001; 2: glyph5x7_row = 5'b00001; 3: glyph5x7_row = 5'b01110; 4: glyph5x7_row = 5'b00001; 5: glyph5x7_row = 5'b00001; default: glyph5x7_row = 5'b11110; endcase
                "4": case (r) 0: glyph5x7_row = 5'b00010; 1: glyph5x7_row = 5'b00110; 2: glyph5x7_row = 5'b01010; 3: glyph5x7_row = 5'b10010; 4: glyph5x7_row = 5'b11111; 5: glyph5x7_row = 5'b00010; default: glyph5x7_row = 5'b00010; endcase
                "5": case (r) 0: glyph5x7_row = 5'b11111; 1: glyph5x7_row = 5'b10000; 2: glyph5x7_row = 5'b11110; 3: glyph5x7_row = 5'b00001; 4: glyph5x7_row = 5'b00001; 5: glyph5x7_row = 5'b10001; default: glyph5x7_row = 5'b01110; endcase
                "6": case (r) 0: glyph5x7_row = 5'b00110; 1: glyph5x7_row = 5'b01000; 2: glyph5x7_row = 5'b10000; 3: glyph5x7_row = 5'b11110; 4: glyph5x7_row = 5'b10001; 5: glyph5x7_row = 5'b10001; default: glyph5x7_row = 5'b01110; endcase
                "7": case (r) 0: glyph5x7_row = 5'b11111; 1: glyph5x7_row = 5'b00001; 2: glyph5x7_row = 5'b00010; 3: glyph5x7_row = 5'b00100; 4: glyph5x7_row = 5'b01000; 5: glyph5x7_row = 5'b01000; default: glyph5x7_row = 5'b01000; endcase
                "8": case (r) 0: glyph5x7_row = 5'b01110; 1: glyph5x7_row = 5'b10001; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b01110; 4: glyph5x7_row = 5'b10001; 5: glyph5x7_row = 5'b10001; default: glyph5x7_row = 5'b01110; endcase
                "9": case (r) 0: glyph5x7_row = 5'b01110; 1: glyph5x7_row = 5'b10001; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b01111; 4: glyph5x7_row = 5'b00001; 5: glyph5x7_row = 5'b00010; default: glyph5x7_row = 5'b01100; endcase
                "@": case (r) 0: glyph5x7_row = 5'b01110; 1: glyph5x7_row = 5'b10001; 2: glyph5x7_row = 5'b10111; 3: glyph5x7_row = 5'b10101; 4: glyph5x7_row = 5'b10111; 5: glyph5x7_row = 5'b10000; default: glyph5x7_row = 5'b01111; endcase
                "A": case (r) 0: glyph5x7_row = 5'b01110; 1: glyph5x7_row = 5'b10001; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b11111; 4: glyph5x7_row = 5'b10001; 5: glyph5x7_row = 5'b10001; default: glyph5x7_row = 5'b10001; endcase
                "C": case (r) 0: glyph5x7_row = 5'b01111; 1: glyph5x7_row = 5'b10000; 2: glyph5x7_row = 5'b10000; 3: glyph5x7_row = 5'b10000; 4: glyph5x7_row = 5'b10000; 5: glyph5x7_row = 5'b10000; default: glyph5x7_row = 5'b01111; endcase
                "D": case (r) 0: glyph5x7_row = 5'b11110; 1: glyph5x7_row = 5'b10001; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b10001; 4: glyph5x7_row = 5'b10001; 5: glyph5x7_row = 5'b10001; default: glyph5x7_row = 5'b11110; endcase
                "E": case (r) 0: glyph5x7_row = 5'b11111; 1: glyph5x7_row = 5'b10000; 2: glyph5x7_row = 5'b11110; 3: glyph5x7_row = 5'b10000; 4: glyph5x7_row = 5'b10000; 5: glyph5x7_row = 5'b10000; default: glyph5x7_row = 5'b11111; endcase
                "G": case (r) 0: glyph5x7_row = 5'b01111; 1: glyph5x7_row = 5'b10000; 2: glyph5x7_row = 5'b10000; 3: glyph5x7_row = 5'b10111; 4: glyph5x7_row = 5'b10001; 5: glyph5x7_row = 5'b10001; default: glyph5x7_row = 5'b01111; endcase
                "H": case (r) 0: glyph5x7_row = 5'b10001; 1: glyph5x7_row = 5'b10001; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b11111; 4: glyph5x7_row = 5'b10001; 5: glyph5x7_row = 5'b10001; default: glyph5x7_row = 5'b10001; endcase
                "M": case (r) 0: glyph5x7_row = 5'b10001; 1: glyph5x7_row = 5'b11011; 2: glyph5x7_row = 5'b10101; 3: glyph5x7_row = 5'b10001; 4: glyph5x7_row = 5'b10001; 5: glyph5x7_row = 5'b10001; default: glyph5x7_row = 5'b10001; endcase
                "P": case (r) 0: glyph5x7_row = 5'b11110; 1: glyph5x7_row = 5'b10001; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b11110; 4: glyph5x7_row = 5'b10000; 5: glyph5x7_row = 5'b10000; default: glyph5x7_row = 5'b10000; endcase
                "R": case (r) 0: glyph5x7_row = 5'b11110; 1: glyph5x7_row = 5'b10001; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b11110; 4: glyph5x7_row = 5'b10100; 5: glyph5x7_row = 5'b10010; default: glyph5x7_row = 5'b10001; endcase
                "T": case (r) 0: glyph5x7_row = 5'b11111; 1: glyph5x7_row = 5'b00100; 2: glyph5x7_row = 5'b00100; 3: glyph5x7_row = 5'b00100; 4: glyph5x7_row = 5'b00100; 5: glyph5x7_row = 5'b00100; default: glyph5x7_row = 5'b00100; endcase
                "V": case (r) 0: glyph5x7_row = 5'b10001; 1: glyph5x7_row = 5'b10001; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b10001; 4: glyph5x7_row = 5'b10001; 5: glyph5x7_row = 5'b01010; default: glyph5x7_row = 5'b00100; endcase
                "W": case (r) 0: glyph5x7_row = 5'b10001; 1: glyph5x7_row = 5'b10001; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b10101; 4: glyph5x7_row = 5'b10101; 5: glyph5x7_row = 5'b10101; default: glyph5x7_row = 5'b01010; endcase
                "X": case (r) 0: glyph5x7_row = 5'b10001; 1: glyph5x7_row = 5'b10001; 2: glyph5x7_row = 5'b01010; 3: glyph5x7_row = 5'b00100; 4: glyph5x7_row = 5'b01010; 5: glyph5x7_row = 5'b10001; default: glyph5x7_row = 5'b10001; endcase
                "a": case (r) 0: glyph5x7_row = 5'b00000; 1: glyph5x7_row = 5'b01110; 2: glyph5x7_row = 5'b00001; 3: glyph5x7_row = 5'b01111; 4: glyph5x7_row = 5'b10001; 5: glyph5x7_row = 5'b10011; default: glyph5x7_row = 5'b01101; endcase
                "b": case (r) 0: glyph5x7_row = 5'b10000; 1: glyph5x7_row = 5'b10000; 2: glyph5x7_row = 5'b11110; 3: glyph5x7_row = 5'b10001; 4: glyph5x7_row = 5'b10001; 5: glyph5x7_row = 5'b10001; default: glyph5x7_row = 5'b11110; endcase
                "c": case (r) 0: glyph5x7_row = 5'b00000; 1: glyph5x7_row = 5'b01110; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b10000; 4: glyph5x7_row = 5'b10000; 5: glyph5x7_row = 5'b10001; default: glyph5x7_row = 5'b01110; endcase
                "d": case (r) 0: glyph5x7_row = 5'b00001; 1: glyph5x7_row = 5'b00001; 2: glyph5x7_row = 5'b01111; 3: glyph5x7_row = 5'b10001; 4: glyph5x7_row = 5'b10001; 5: glyph5x7_row = 5'b10001; default: glyph5x7_row = 5'b01111; endcase
                "e": case (r) 0: glyph5x7_row = 5'b00000; 1: glyph5x7_row = 5'b01110; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b11111; 4: glyph5x7_row = 5'b10000; 5: glyph5x7_row = 5'b10000; default: glyph5x7_row = 5'b01111; endcase
                "f": case (r) 0: glyph5x7_row = 5'b00110; 1: glyph5x7_row = 5'b01000; 2: glyph5x7_row = 5'b11100; 3: glyph5x7_row = 5'b01000; 4: glyph5x7_row = 5'b01000; 5: glyph5x7_row = 5'b01000; default: glyph5x7_row = 5'b01000; endcase
                "g": case (r) 0: glyph5x7_row = 5'b00000; 1: glyph5x7_row = 5'b01111; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b10001; 4: glyph5x7_row = 5'b01111; 5: glyph5x7_row = 5'b00001; default: glyph5x7_row = 5'b01110; endcase
                "i": case (r) 0: glyph5x7_row = 5'b00100; 1: glyph5x7_row = 5'b00000; 2: glyph5x7_row = 5'b01100; 3: glyph5x7_row = 5'b00100; 4: glyph5x7_row = 5'b00100; 5: glyph5x7_row = 5'b00100; default: glyph5x7_row = 5'b01110; endcase
                "l": case (r) 0: glyph5x7_row = 5'b01100; 1: glyph5x7_row = 5'b00100; 2: glyph5x7_row = 5'b00100; 3: glyph5x7_row = 5'b00100; 4: glyph5x7_row = 5'b00100; 5: glyph5x7_row = 5'b00100; default: glyph5x7_row = 5'b01110; endcase
                "m": case (r) 0: glyph5x7_row = 5'b00000; 1: glyph5x7_row = 5'b11010; 2: glyph5x7_row = 5'b10101; 3: glyph5x7_row = 5'b10101; 4: glyph5x7_row = 5'b10101; 5: glyph5x7_row = 5'b10101; default: glyph5x7_row = 5'b10101; endcase
                "n": case (r) 0: glyph5x7_row = 5'b00000; 1: glyph5x7_row = 5'b11110; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b10001; 4: glyph5x7_row = 5'b10001; 5: glyph5x7_row = 5'b10001; default: glyph5x7_row = 5'b10001; endcase
                "o": case (r) 0: glyph5x7_row = 5'b00000; 1: glyph5x7_row = 5'b01110; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b10001; 4: glyph5x7_row = 5'b10001; 5: glyph5x7_row = 5'b10001; default: glyph5x7_row = 5'b01110; endcase
                "p": case (r) 0: glyph5x7_row = 5'b00000; 1: glyph5x7_row = 5'b11110; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b11110; 4: glyph5x7_row = 5'b10000; 5: glyph5x7_row = 5'b10000; default: glyph5x7_row = 5'b10000; endcase
                "r": case (r) 0: glyph5x7_row = 5'b00000; 1: glyph5x7_row = 5'b10110; 2: glyph5x7_row = 5'b11001; 3: glyph5x7_row = 5'b10000; 4: glyph5x7_row = 5'b10000; 5: glyph5x7_row = 5'b10000; default: glyph5x7_row = 5'b10000; endcase
                "s": case (r) 0: glyph5x7_row = 5'b00000; 1: glyph5x7_row = 5'b01111; 2: glyph5x7_row = 5'b10000; 3: glyph5x7_row = 5'b01110; 4: glyph5x7_row = 5'b00001; 5: glyph5x7_row = 5'b00001; default: glyph5x7_row = 5'b11110; endcase
                "t": case (r) 0: glyph5x7_row = 5'b01000; 1: glyph5x7_row = 5'b01000; 2: glyph5x7_row = 5'b11100; 3: glyph5x7_row = 5'b01000; 4: glyph5x7_row = 5'b01000; 5: glyph5x7_row = 5'b01001; default: glyph5x7_row = 5'b00110; endcase
                "u": case (r) 0: glyph5x7_row = 5'b00000; 1: glyph5x7_row = 5'b10001; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b10001; 4: glyph5x7_row = 5'b10001; 5: glyph5x7_row = 5'b10011; default: glyph5x7_row = 5'b01101; endcase
                "v": case (r) 0: glyph5x7_row = 5'b00000; 1: glyph5x7_row = 5'b10001; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b10001; 4: glyph5x7_row = 5'b01010; 5: glyph5x7_row = 5'b01010; default: glyph5x7_row = 5'b00100; endcase
                "y": case (r) 0: glyph5x7_row = 5'b00000; 1: glyph5x7_row = 5'b10001; 2: glyph5x7_row = 5'b10001; 3: glyph5x7_row = 5'b01111; 4: glyph5x7_row = 5'b00001; 5: glyph5x7_row = 5'b00010; default: glyph5x7_row = 5'b11100; endcase
                "z": case (r) 0: glyph5x7_row = 5'b00000; 1: glyph5x7_row = 5'b11111; 2: glyph5x7_row = 5'b00010; 3: glyph5x7_row = 5'b00100; 4: glyph5x7_row = 5'b01000; 5: glyph5x7_row = 5'b10000; default: glyph5x7_row = 5'b11111; endcase
                "=": case (r) 0: glyph5x7_row = 5'b00000; 1: glyph5x7_row = 5'b11111; 2: glyph5x7_row = 5'b00000; 3: glyph5x7_row = 5'b11111; 4: glyph5x7_row = 5'b00000; 5: glyph5x7_row = 5'b00000; default: glyph5x7_row = 5'b00000; endcase
                default: glyph5x7_row = 5'b00000;
            endcase
        end
    endfunction

    function glyph_hit;
        input [7:0] c;
        input integer scale;
        input integer local_x;
        input integer local_y;
        reg [2:0] row_idx;
        reg [2:0] col_idx;
        reg [4:0] row_bits;
        begin
            glyph_hit = 1'b0;
            if ((local_x >= 0) && (local_y >= 0) &&
                (local_x < (5 * scale)) && (local_y < (7 * scale))) begin
                row_idx = local_y / scale;
                col_idx = local_x / scale;
                row_bits = glyph5x7_row(c, row_idx);
                glyph_hit = row_bits[4 - col_idx];
            end
        end
    endfunction

    assign JC = 8'h00;
    assign SEG = 8'hFF;
    assign AN = 4'hF;
    assign LED[4:0] = keyboard_key_id;
    assign LED[7:5] = 3'b000;
    assign LED[15:8] = last_ascii;
    ClockDivider #( .FREQ(25_000_000) ) clkdiv_pixel_inst ( .CLK100MHZ(CLK100MHZ), .clk_out(clk_pixel) );
    ClockDivider #( .FREQ(20) ) clkdiv_nav_inst ( .CLK100MHZ(CLK100MHZ), .clk_out(clk_nav) );
    VGAControl vga_ctrl_inst (
        .clk_pixel(clk_pixel), .reset(SW[15]), .rgb(rgb),
        .hsync(HSYNC), .vsync(VSYNC), .video_on(video_on),
        .h_count_reg(x_pos), .v_count_reg(y_pos),
        .vgaRed(VGARED), .vgaGreen(VGAGREEN), .vgaBlue(VGABLUE)
    );
    // 同步與重置訊號
    reg vsync_d;
    always @(posedge clk_pixel) vsync_d <= VSYNC;
    wire vsync_edge = (~VSYNC & vsync_d);
    wire wave_rst_n = ~BTNC;

    MouseCtl mouse_ctrl_inst (
        .clk(CLK100MHZ), .rst(BTNC), .xpos(mouse_xpos), .ypos(mouse_ypos), .zpos(mouse_zpos),
        .left(mouse_left), .middle(mouse_middle), .right(mouse_right),
        .new_event(mouse_new_event), .value(mouse_set_value), .setx(1'b0), .sety(1'b0),
        .setmax_x(mouse_set_max_x), .setmax_y(mouse_set_max_y), .ps2_clk(PS2CLK), .ps2_data(PS2DATA)
    );
    MouseDisplay mouse_disp_inst (
        .pixel_clk(clk_pixel), .xpos(mouse_xpos), .ypos(mouse_ypos),
        .mouse_left(mouse_left),
        .hcount(x_pos), .vcount(y_pos), .enable_mouse_display_out(mouse_display_enable),
        .red_out(mouse_r), .green_out(mouse_g), .blue_out(mouse_b)
    );
    SimpleRam #( .WordWidth(16), .WordCount(256) ) circuit_canvas_ram_inst (
        .clk(CLK100MHZ), .w_en(circuit_canvas_ram_w_en), .w_addr(circuit_canvas_ram_w_addr),
        .r_addr(circuit_canvas_ram_r_addr), .d_in(circuit_canvas_ram_w_data), .d_out(circuit_canvas_ram_r_data)
    );
    CircuitCanvas #( .CanvasPosX(CANVAS_X0), .CanvasPosY(CANVAS_Y0), .CanvasWidth(CANVAS_W), .CanvasHeight(CANVAS_H) ) circuit_canvas_inst (
        .clk_pixel(clk_pixel), .x_pos(x_pos), .y_pos(y_pos), .rgb(circuit_canvas_rgb),
        .rendered(circuit_canvas_rendered), .mouse_x_pos(mouse_xpos), .mouse_y_pos(mouse_ypos),
        .data_addr(circuit_canvas_ram_r_addr), .incoming_data(circuit_canvas_ram_r_data),
        .display_grid(1'b1), .mouse_left_click(mouse_left && (selected_toolbar_idx == 3'd0))
    );
    // Component Property Panel signals 以下为属性面板例化
    wire        prop_panel_rendered;
    wire [11:0] prop_panel_rgb;
    reg  [11:0] selected_cell_i = 12'd0;
    reg  [11:0] selected_cell_j = 12'd0;
    reg  [15:0] selected_cell_data = 16'd0;
    reg         has_selection = 1'b0;
    reg         mouse_left_d = 1'b0;
    wire        mouse_left_rising;
    
    // 鼠标悬停检测
    wire [11:0] mouse_cell_i;
    wire [11:0] mouse_cell_j;
    wire        mouse_hover_component;
    wire        canvas_mouse_in_bounds;
    wire        toolbar_place_two_cells;
    wire [15:0] toolbar_place_data0;
    wire [15:0] toolbar_place_data1;
    wire        mouse_left_rising_sys;
    
    // 示例元件数据 (从 init_cycles 中复制)
    // 地址 17-19: 电阻，地址 33: 电压源右，地址 49: 电压源左，地址 82-88: Tee
    reg  [15:0] component_data [0:255];
    reg  [7:0]  hovered_addr;

    // =========================================================
    // Component Property Panel - 元件属性显示 (简化版)
    // =========================================================
    // 鼠标悬停位置计算 (Canvas 区域：X0=64, Y0=64)
    assign mouse_cell_i = (mouse_xpos >= CANVAS_X0) ?
    ((mouse_xpos - CANVAS_X0) / 32) : 12'd0;
    assign mouse_cell_j = (mouse_ypos >= CANVAS_Y0) ?
    ((mouse_ypos - CANVAS_Y0) / 32) : 12'd0;
    
    // 鼠标点击边沿检测
    assign canvas_mouse_in_bounds = (mouse_xpos >= CANVAS_X0) && (mouse_xpos < (CANVAS_X0 + CANVAS_W)) &&
                                    (mouse_ypos >= CANVAS_Y0) && (mouse_ypos < (CANVAS_Y0 + CANVAS_H)) &&
                                    (mouse_cell_i < 16) && (mouse_cell_j < 16);
    assign toolbar_place_two_cells = toolbar_tool_uses_two_cells(selected_toolbar_idx);
    assign toolbar_place_data0 = toolbar_first_cell_data(selected_toolbar_idx);
    assign toolbar_place_data1 = toolbar_second_cell_data(selected_toolbar_idx);
    assign mouse_left_rising = mouse_left && !mouse_left_d;
    assign mouse_left_rising_sys = mouse_left && !mouse_left_d_sys;
    // 同步鼠标点击 - 记录选中的单元格
    always @(posedge clk_pixel) begin
        mouse_left_d <= mouse_left;
        if (mouse_left_rising && mouse_cell_i < 16 && mouse_cell_j < 16) begin
            selected_cell_i <= mouse_cell_i;
            selected_cell_j <= mouse_cell_j;
            has_selection <= 1'b1;
        end
    end

    // 示例元件数据初始化 (与 init_cycles 中的数据相同)
    integer init_idx;
    always @(posedge clk_pixel) begin
        // 初始化所有单元为 0
        for (init_idx = 0; init_idx < 256; init_idx = init_idx + 1) begin
            component_data[init_idx] <= 16'd0;
        end
        // 加载示例元件
        component_data[17] <= 16'b0000000_10_000001_1;
        // rotation=2, type=1
        component_data[18] <= 16'b0000000_00_000101_1;
        // rotation=0, type=5 (Resistor Left)
        component_data[19] <= 16'b0000000_00_000110_1;
        // rotation=0, type=6 (Resistor Right)
        component_data[33] <= 16'b0000000_11_001000_1;
        // rotation=3, type=8 (Voltage Right)
        component_data[49] <= 16'b0000000_11_000111_1;
        // rotation=3, type=7 (Voltage Left)
        component_data[82] <= 16'b0000000_00_000010_1;
        // rotation=0, type=2 (Tee)
        component_data[84] <= 16'b0000000_01_000010_1;
        // rotation=1, type=2 (Tee)
        component_data[86] <= 16'b0000000_10_000010_1;
        // rotation=2, type=2 (Tee)
        component_data[88] <= 16'b0000000_11_000010_1;
        // rotation=3, type=2 (Tee)
    end
    
    // 计算悬停的单元格地址
    always @(*) begin
        hovered_addr = mouse_cell_i + mouse_cell_j * 16;
    end
    
    // 从本地存储读取选中单元格的数据
    always @(posedge clk_pixel) begin
        if (mouse_left_rising && mouse_cell_i < 16 && mouse_cell_j < 16) begin
            selected_cell_data <= component_data[hovered_addr];
        end
    end

    // 例化属性面板
    ComponentPropertyPanel #(
        .PANEL_X(0),
        .PANEL_Y(0),
        .PANEL_W(640),
        .PANEL_H(64)
    ) u_prop_panel (
        .clk_pixel(clk_pixel),
        .hcount(x_pos),
        .vcount(y_pos),
        .video_on(video_on),
        .mouse_cell_i(mouse_cell_i),
        
        .mouse_cell_j(mouse_cell_j),
        .selected_cell_data(selected_cell_data),
        .has_selection(has_selection),
        .selected_cell_i(selected_cell_i),
        .selected_cell_j(selected_cell_j),
        .panel_rendered(prop_panel_rendered),
        .panel_rgb(prop_panel_rgb)
    );
    //属性面板例化结束

    // =========================================================
    // 【重點實例化：傳入更新的 KEY_W 和 KEY_H】
    // 確保這裡的尺寸與 Top 的遮罩區域完全相同
    // =========================================================
    KeyboardVGA #( 
        .KEY_COUNT(19),
        .FONT_SCALE(KEYBOARD_SCALE), 
        .KEYBOARD_X0(KEYBOARD_X), 
        .KEYBOARD_Y0(KEYBOARD_Y),
        .KEY_W(KEY_W),
        .KEY_H(KEY_H)
    ) keyboard_vga_inst (
        .clk_nav(clk_nav), .btnU(BTNU), .btnD(BTND), .btnL(BTNL), .btnR(BTNR), 
        .btnC(BTNC),
        .mouse_x(mouse_xpos), .mouse_y(mouse_ypos), .mouse_left(mouse_left),
        .x(x_pos), .y(y_pos), .pixel_rgb(keyboard_rgb), .key_id(keyboard_key_id),
        .key_valid(keyboard_key_valid), .key_ascii(keyboard_key_ascii)
    );

    ToolbarVGA toolbar_vga_inst (
        .clk_pixel(clk_pixel),
        .mouse_x(mouse_xpos),
        .mouse_y(mouse_ypos),
        .mouse_left(mouse_left),
        .x(x_pos),
        .y(y_pos),
        .pixel_rgb(toolbar_rgb),
        .rendered(toolbar_rendered),
        .selected_tool_idx(selected_toolbar_idx)
    );
    // =========================================================
    // 電壓波形 (X: 0 ~ 241, Y: 352 ~ 479)
    // =========================================================
    wire       v_wr_en;
    wire [7:0] v_wr_addr, v_wr_data;
    wire [7:0] v_rd_addr, v_rd_data;
    wire       is_v_wave, is_v_axis, is_v_text;
    wire [7:0] v_max_val; // 【新增】接收電壓峰值

    DummyDataGenerate v_gen (
        .clk(clk_pixel), .rst_n(wave_rst_n), .vsync_edge(vsync_edge),
        .wr_en(v_wr_en), .wr_addr(v_wr_addr), .wr_data(v_wr_data),
        .max_out(v_max_val)   // 【新增接線】
    );
    PingPongBuffer #( .ADDR_WIDTH(8), .DATA_WIDTH(8) ) v_buffer (
        .clk(clk_pixel), .rst_n(wave_rst_n), .vsync_edge(vsync_edge),
        .wr_en(v_wr_en), .wr_addr(v_wr_addr), .wr_data(v_wr_data),
        .rd_en(1'b1),    .rd_addr(v_rd_addr), .rd_data(v_rd_data)
    );
    wire [11:0] v_local_y_12bit = y_pos - 12'd352;
    
    WaveformPlot #( .IS_VOLTAGE(1) ) v_plot (
        .clk(clk_pixel), .rst_n(wave_rst_n),
        .local_x( (x_pos >= 0 && x_pos < 242) ? (x_pos[7:0] + 8'd1) : 8'd0 ),
        .local_y( (y_pos >= 352 && y_pos < 480) ? v_local_y_12bit[7:0] : 8'd0 ),
        .rd_addr(v_rd_addr), .rd_data(v_rd_data),
        .is_wave_pixel(is_v_wave), .is_axis_pixel(is_v_axis), .is_text_pixel(is_v_text)
    );
    // =========================================================
    // 電流波形 (X: 242 ~ 483, Y: 352 ~ 479)
    // =========================================================
    wire       i_wr_en;
    wire [7:0] i_wr_addr, i_wr_data;
    wire [7:0] i_rd_addr, i_rd_data;
    wire       is_i_wave, is_i_axis, is_i_text;
    wire [7:0] i_max_val; // 【新增】接收電流峰值

    DummyDataGenerate i_gen (
        .clk(clk_pixel), .rst_n(wave_rst_n), .vsync_edge(vsync_edge),
        .wr_en(i_wr_en), .wr_addr(i_wr_addr), .wr_data(i_wr_data),
        .max_out(i_max_val)   // 【新增接線】
    );
    PingPongBuffer #( .ADDR_WIDTH(8), .DATA_WIDTH(8) ) i_buffer (
        .clk(clk_pixel), .rst_n(wave_rst_n), .vsync_edge(vsync_edge),
        .wr_en(i_wr_en), .wr_addr(i_wr_addr), .wr_data(i_wr_data),
        .rd_en(1'b1),    .rd_addr(i_rd_addr), .rd_data(i_rd_data)
    );
    wire [11:0] i_local_x_12bit = x_pos - 12'd242;
    wire [11:0] i_local_y_12bit = y_pos - 12'd352;
    WaveformPlot #( .IS_VOLTAGE(0) ) i_plot (
        .clk(clk_pixel), .rst_n(wave_rst_n),
        .local_x( (x_pos >= 242 && x_pos < 484) ? (i_local_x_12bit[7:0] + 8'd1) : 8'd0 ),
        .local_y( (y_pos >= 352 && y_pos < 480) ? i_local_y_12bit[7:0] : 8'd0 ),
        .rd_addr(i_rd_addr), .rd_data(i_rd_data),
        .is_wave_pixel(is_i_wave), .is_axis_pixel(is_i_axis), .is_text_pixel(is_i_text)
    );

    // =========================================================
    // 【新增】8-bit Binary 轉 BCD 轉換器 (用於 OSD 顯示峰值)
    // =========================================================
    wire [3:0] v_max_h = v_max_val / 100;
    wire [3:0] v_max_t = (v_max_val % 100) / 10;
    wire [3:0] v_max_u = v_max_val % 10;

    wire [3:0] i_max_h = i_max_val / 100;
    wire [3:0] i_max_t = (i_max_val % 100) / 10;
    wire [3:0] i_max_u = i_max_val % 10;

    // 【新增】動態字元引擎
    wire v_dyn_text =
        glyph_hit("M", 2, x_pos - 146, y_pos - 360) ||
        glyph_hit("A", 2, x_pos - 158, y_pos - 360) ||
        glyph_hit("X", 2, x_pos - 170, y_pos - 360) ||
        glyph_hit("=", 2, x_pos - 182, y_pos - 360) ||
        glyph_hit("0" + v_max_h, 2, x_pos - 194, y_pos - 360) ||
        glyph_hit("0" + v_max_t, 2, x_pos - 206, y_pos - 360) ||
        glyph_hit("0" + v_max_u, 2, x_pos - 218, y_pos - 360);

    wire i_dyn_text =
        glyph_hit("M", 2, x_pos - 388, y_pos - 360) ||
        glyph_hit("A", 2, x_pos - 400, y_pos - 360) ||
        glyph_hit("X", 2, x_pos - 412, y_pos - 360) ||
        glyph_hit("=", 2, x_pos - 424, y_pos - 360) ||
        glyph_hit("0" + i_max_h, 2, x_pos - 436, y_pos - 360) ||
        glyph_hit("0" + i_max_t, 2, x_pos - 448, y_pos - 360) ||
        glyph_hit("0" + i_max_u, 2, x_pos - 460, y_pos - 360);

    // =========================================================
    // 波形影像混合邏輯 (修復波形溢出邊框的問題)
    // =========================================================
    wire in_v_region = (x_pos >= 0 && x_pos < 242) && (y_pos >= 352 && y_pos < 480);
    wire in_i_region = (x_pos >= 242 && x_pos < 484) && (y_pos >= 352 && y_pos < 480);
    wire dynamic_wave_active = in_v_region || in_i_region;

    // 加入 4 像素的安全遮罩，防止波形蓋過儀表板的外框
    wire v_wave_display = is_v_wave && (x_pos >= 4 && x_pos < 238) && (y_pos >= 356 && y_pos < 476);
    wire i_wave_display = is_i_wave && (x_pos >= 246 && x_pos < 480) && (y_pos >= 356 && y_pos < 476);
    
    // 終極混合：加入 v_dyn_text 與 i_dyn_text 的判斷，並顯示青色 (12'h0FF)
    wire [11:0] wave_out_rgb;
    assign wave_out_rgb =
        in_v_region ?
        (v_dyn_text ? 12'h0FF : is_v_text ? 12'hFFF : v_wave_display ? 12'h0F0 : is_v_axis ? 12'h444 : 12'h111) :
        in_i_region ?
        (i_dyn_text ? 12'h0FF : is_i_text ? 12'hFFF : i_wave_display ? 12'hFF0 : is_i_axis ? 12'h444 : 12'h111) :
        12'h000;
        
    always @(posedge clk_nav) begin
        if (keyboard_key_valid && (keyboard_key_id != 5'd18)) last_ascii <= keyboard_key_ascii;
    end

    // RAM 初始化與滑鼠重置
    always @(posedge CLK100MHZ) begin
        mouse_set_value <= 12'h000;
        mouse_set_max_x <= 1'b0; mouse_set_max_y <= 1'b0;
        circuit_canvas_ram_w_en <= 1'b0;
        mouse_left_d_sys <= mouse_left;
        if (init_cycles < 32'd1000) init_cycles <= init_cycles + 1'b1;

        if (keyboard_key_valid && (keyboard_key_id == 5'd18)) begin
            clear_canvas_active <= 1'b1;
            clear_canvas_addr <= 8'd0; init_cycles <= 32'd1000;
            pending_second_tool_write <= 1'b0;
        end

        if (clear_canvas_active) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= clear_canvas_addr; circuit_canvas_ram_w_data <= 16'd0;
            if (clear_canvas_addr == 8'd255) clear_canvas_active <= 1'b0;
            else clear_canvas_addr <= clear_canvas_addr + 1'b1;
        end else if (init_cycles == 32'd1) begin mouse_set_max_x <= 1'b1; mouse_set_value <= 12'd639;
        end else if (init_cycles == 32'd2) begin mouse_set_max_y <= 1'b1; mouse_set_value <= 12'd479;
        end else if (init_cycles < 32'd256) begin circuit_canvas_ram_w_en <= 1'b1; circuit_canvas_ram_w_addr <= init_cycles[7:0]; circuit_canvas_ram_w_data <= 16'd0;
        end else if (init_cycles == 32'd256) begin circuit_canvas_ram_w_en <= 1'b1; circuit_canvas_ram_w_addr <= 8'd17; circuit_canvas_ram_w_data <= 16'b0000000_10_000001_1;
        end else if (init_cycles == 32'd257) begin circuit_canvas_ram_w_en <= 1'b1; circuit_canvas_ram_w_addr <= 8'd18; circuit_canvas_ram_w_data <= 16'b0000000_00_000101_1;
        end else if (init_cycles == 32'd258) begin circuit_canvas_ram_w_en <= 1'b1; circuit_canvas_ram_w_addr <= 8'd19; circuit_canvas_ram_w_data <= 16'b0000000_00_000110_1;
        end else if (init_cycles == 32'd259) begin circuit_canvas_ram_w_en <= 1'b1; circuit_canvas_ram_w_addr <= 8'd33; circuit_canvas_ram_w_data <= 16'b0000000_11_001000_1;
        end else if (init_cycles == 32'd260) begin circuit_canvas_ram_w_en <= 1'b1; circuit_canvas_ram_w_addr <= 8'd49; circuit_canvas_ram_w_data <= 16'b0000000_11_000111_1;
        end else if (init_cycles == 32'd261) begin circuit_canvas_ram_w_en <= 1'b1; circuit_canvas_ram_w_addr <= 8'd82; circuit_canvas_ram_w_data <= 16'b0000000_00_000010_1;
        end else if (init_cycles == 32'd262) begin circuit_canvas_ram_w_en <= 1'b1; circuit_canvas_ram_w_addr <= 8'd84; circuit_canvas_ram_w_data <= 16'b0000000_01_000010_1;
        end else if (init_cycles == 32'd263) begin circuit_canvas_ram_w_en <= 1'b1; circuit_canvas_ram_w_addr <= 8'd86; circuit_canvas_ram_w_data <= 16'b0000000_10_000010_1;
        end else if (init_cycles == 32'd264) begin circuit_canvas_ram_w_en <= 1'b1; circuit_canvas_ram_w_addr <= 8'd88; circuit_canvas_ram_w_data <= 16'b0000000_11_000010_1;
        end else if (pending_second_tool_write) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= pending_second_tool_addr;
            circuit_canvas_ram_w_data <= pending_second_tool_data;
            pending_second_tool_write <= 1'b0;
        end else if (mouse_left_rising_sys && canvas_mouse_in_bounds && (selected_toolbar_idx != 3'd0) &&
                     (!toolbar_place_two_cells || (mouse_cell_i < 12'd15))) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= hovered_addr;
            circuit_canvas_ram_w_data <= toolbar_place_data0;
            if (toolbar_place_two_cells) begin
                pending_second_tool_write <= 1'b1;
                pending_second_tool_addr <= hovered_addr + 8'd1;
                pending_second_tool_data <= toolbar_place_data1;
            end
        end
    end

    always @(*) begin
        ui_rgb = BACKGROUND;
        top_bar_active = (y_pos < TOP_BAR_H);
        left_bar_active = (x_pos < LEFT_BAR_W) && (y_pos >= TOP_BAR_H) && (y_pos < (SCREEN_H - BOTTOM_BAR_H));
        right_bar_active = (x_pos >= (SCREEN_W - RIGHT_BAR_W)) && (y_pos >= TOP_BAR_H);
        
        canvas_label_active = 1'b0; title_active = 1'b0; frame_active = 1'b0;
        icon_active = 1'b0;
        grid_line_active = ((x_pos[4:0] == 5'd0) || (y_pos[4:0] == 5'd0));
        
        if (top_bar_active) begin
            ui_rgb = rgb888_to_444(24'hE2B2A8);
            if (grid_line_active) ui_rgb = rgb888_to_444(24'hEFD2CC);
            if ((x_pos >= 32 && x_pos < 164 && y_pos >= 22 && y_pos < 48) || (x_pos >= 196 && x_pos < 324 && y_pos >= 22 && y_pos < 48) ||
                (x_pos >= 356 && x_pos < 486 && y_pos >= 22 && y_pos < 48) || (x_pos >= 518 && x_pos < 608 && y_pos >= 22 && y_pos < 48)) begin
                
                ui_rgb = rgb888_to_444(24'hEED7D1);
            end
        end else if (left_bar_active) begin
            ui_rgb = rgb888_to_444(24'hF3D9B8);
            if (grid_line_active) ui_rgb = rgb888_to_444(24'hD9E8F2);
            if (toolbar_rendered) ui_rgb = toolbar_rgb;
        end else if (right_bar_active) begin
            ui_rgb = rgb888_to_444(24'hD0D0D0);
            if (grid_line_active) ui_rgb = rgb888_to_444(24'hDBDBDB);
            if (((x_pos >= 504 && x_pos < 618) && ((y_pos >= 84 && y_pos < 196) || (y_pos >= 218 && y_pos < 326) || (y_pos >= 356 && y_pos < 466)))) begin
                if ((x_pos < 506) || (x_pos >= 616) || (y_pos == 84) || (y_pos == 195) || (y_pos == 218) || (y_pos == 325) || (y_pos == 356) || (y_pos == 465)) begin
               
                    frame_active = 1'b1;
                end
            end
            if (frame_active) ui_rgb = 12'hFFF;
        end

        if (glyph_hit("P", 4, x_pos - 4, y_pos - 4) || glyph_hit("r", 4, x_pos - 28, y_pos - 4) || glyph_hit("o", 4, x_pos - 52, y_pos - 4) || glyph_hit("p", 4, x_pos - 76, y_pos - 4) || glyph_hit("e", 4, x_pos - 100, y_pos - 4) || glyph_hit("r", 4, x_pos - 124, y_pos - 4) || glyph_hit("t", 4, x_pos - 148, y_pos - 4) || glyph_hit("y", 4, x_pos - 172, y_pos - 4) || glyph_hit("E", 4, x_pos - 212, y_pos - 4) || glyph_hit("d", 4, x_pos - 236, y_pos - 4) || glyph_hit("i", 
        4, x_pos - 260, y_pos - 4) || glyph_hit("t", 4, x_pos - 276, y_pos - 4) || glyph_hit("o", 4, x_pos - 300, y_pos - 4) || glyph_hit("r", 4, x_pos - 324, y_pos - 4)) title_active = 1'b1;
        if (glyph_hit("R", 4, x_pos - 40, y_pos - 28) || glyph_hit("1", 4, x_pos - 64, y_pos - 28) || glyph_hit("2", 4, x_pos - 208, y_pos - 28) || glyph_hit("3", 4, x_pos - 232, y_pos - 28) || glyph_hit("0", 4, x_pos - 256, y_pos - 28) || glyph_hit("H", 4, x_pos - 360, y_pos - 28) || glyph_hit("o", 4, x_pos - 384, y_pos - 28) || glyph_hit("r", 4, x_pos - 408, y_pos - 28) || glyph_hit("i", 4, x_pos - 428, y_pos - 28) || glyph_hit("z", 4, x_pos - 444, y_pos - 28) || glyph_hit("o", 4, x_pos - 468, y_pos - 28) || 
        glyph_hit("n", 4, x_pos - 492, y_pos - 28) || glyph_hit("t", 4, x_pos - 516, y_pos - 28) || glyph_hit("a", 4, x_pos - 536, y_pos - 28) || glyph_hit("l", 4, x_pos - 560, y_pos - 28)) title_active = 1'b1;
        if (glyph_hit("D", 4, x_pos - 492, y_pos - 198) || glyph_hit("e", 4, x_pos - 516, y_pos - 198) || glyph_hit("b", 4, x_pos - 540, y_pos - 198) || glyph_hit("u", 4, x_pos - 564, y_pos - 198) || glyph_hit("g", 4, x_pos - 588, y_pos - 198) || glyph_hit("D", 4, x_pos - 492, y_pos - 328) || glyph_hit("i", 4, x_pos - 516, y_pos - 328) || glyph_hit("s", 4, x_pos - 532, y_pos - 328) || glyph_hit("p", 4, x_pos - 556, y_pos - 328) || glyph_hit("l", 4, x_pos - 580, y_pos - 328) || glyph_hit("a", 4, x_pos - 596, y_pos - 328) || 
        glyph_hit("y", 4, x_pos - 620, y_pos - 328)) title_active = 1'b1;
        if (1'b0) title_active = 1'b1;
        if (glyph_hit("V", 5, x_pos - 240, y_pos - 446) || glyph_hit("G", 5, x_pos - 270, y_pos - 446) || glyph_hit("A", 5, x_pos - 300, y_pos - 446) || glyph_hit("6", 5, x_pos - 352, y_pos - 446) || glyph_hit("4", 5, x_pos - 382, y_pos - 446) || glyph_hit("0", 5, x_pos - 412, y_pos - 446) || glyph_hit("@", 5, x_pos - 492, y_pos - 446) || glyph_hit("6", 5, x_pos - 544, y_pos - 446) || glyph_hit("0", 5, x_pos - 574, y_pos - 446)) title_active = 1'b1;
        if ((x_pos >= 448) && (x_pos < 482) && (y_pos >= 320) && (y_pos < 332)) title_active = 1'b1;
        
        if (title_active && !dynamic_wave_active) ui_rgb = 12'hFFF;
    end

    always @(posedge clk_pixel) begin
        if (!video_on) begin
            rgb <= BLACK;
        end else if (mouse_display_enable) begin
            rgb <= mouse_rgb;
        end else if (keyboard_region_active) begin
            rgb <= keyboard_rgb;
        end else if (circuit_canvas_rendered) begin
            rgb <= circuit_canvas_rgb;
        end else if (dynamic_wave_active) begin
            rgb <= wave_out_rgb;
        end else if (prop_panel_rendered && video_on) begin
            rgb <= prop_panel_rgb;
        end else begin
            rgb <= ui_rgb;
        end
    end

endmodule
