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
    localparam integer CANVAS_CELL_SIZE = 32;
    localparam integer CANVAS_GRID_W   = 18;
    localparam integer CANVAS_GRID_H   = 16;
    localparam integer CANVAS_CELL_COUNT = CANVAS_GRID_W * CANVAS_GRID_H;
    localparam integer CANVAS_ADDR_W   = $clog2(CANVAS_CELL_COUNT);
    localparam [CANVAS_ADDR_W-1:0] COMPONENT_INDEX_INVALID = {CANVAS_ADDR_W{1'b1}};
    localparam integer CANVAS_X0       = LEFT_BAR_W;
    localparam integer CANVAS_Y0       = TOP_BAR_H;
    localparam integer CANVAS_W        = CANVAS_GRID_W * CANVAS_CELL_SIZE;
    localparam integer CANVAS_H        = SCREEN_H - TOP_BAR_H - BOTTOM_BAR_H;
    localparam integer PROP_PANEL_X    = 0;
    localparam integer PROP_PANEL_Y    = 0;
    localparam integer PROP_PANEL_W    = 640;
    localparam integer PROP_PANEL_H    = 64;
    localparam integer PROP_VALUE_BOX_X0 = 224;
    localparam integer PROP_VALUE_BOX_Y0 = 24;
    localparam integer PROP_VALUE_BOX_X1 = 336;
    localparam integer PROP_VALUE_BOX_Y1 = 44;
    localparam integer STORE_VIEW_TEXT_MAX_CHARS = 32;
    localparam integer STORE_VIEW_CARD_X0 = 56;
    localparam integer STORE_VIEW_CARD_Y0 = 40;
    localparam integer STORE_VIEW_CARD_X1 = 584;
    localparam integer STORE_VIEW_CARD_Y1 = 424;
    localparam integer STORE_VIEW_TEXT_X = 88;
    localparam integer STORE_VIEW_TITLE_Y = 72;
    localparam integer STORE_VIEW_HINT_Y = 104;
    localparam integer STORE_VIEW_STATUS_Y = 152;
    localparam integer STORE_VIEW_COUNT_Y = 184;
    localparam integer STORE_VIEW_PACKED_Y = 224;
    localparam integer STORE_VIEW_INDEX_Y = 248;
    localparam integer STORE_VIEW_TYPE_Y = 272;
    localparam integer STORE_VIEW_ROT_Y = 296;
    localparam integer STORE_VIEW_VALUE_Y = 320;
    localparam integer STORE_VIEW_RAW_Y = 344;
    localparam integer STORE_VIEW_POS_Y = 368;

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
    wire [23:0] keyboard_key_rgb;
    wire        keyboard_key_is_digit;
    wire        keyboard_key_is_unit;
    wire        keyboard_key_is_action;
    (* ASYNC_REG = "TRUE" *) reg  [7:0]  keyboard_ascii_sys_ff0 = 8'h00;
    (* ASYNC_REG = "TRUE" *) reg  [7:0]  keyboard_ascii_sys_ff1 = 8'h00;

    wire        keyboard_region_active;
    wire        show_matrix = SW[0];
    wire        show_component_store_view = SW[1];

    // =========================================================
    // Calculator on OLED signals
    // =========================================================
    wire        oled_frame_begin;
    wire        oled_sending_pixels;
    wire        oled_sample_pixel;
    wire [12:0] oled_pixel_index;
    wire [6:0]  oled_x_pos;
    wire [5:0]  oled_y_pos;
    wire [15:0] oled_pixel_rgb;
    reg  [15:0] oled_data;

    wire [11:0] circuit_canvas_rgb;
    wire        circuit_canvas_rendered;
    reg  [11:0] ui_rgb;
    wire [7:0]  seg_data;
    wire [11:0] toolbar_rgb;
    wire        toolbar_rendered;
    wire [3:0]  selected_toolbar_idx;
    wire [1:0]  selected_wire_variant;
    (* ASYNC_REG = "TRUE" *) reg  [3:0]  selected_toolbar_idx_sys_ff0 = 4'd0;
    (* ASYNC_REG = "TRUE" *) reg  [3:0]  selected_toolbar_idx_sys_ff1 = 4'd0;
    (* ASYNC_REG = "TRUE" *) reg  [1:0]  selected_wire_variant_sys_ff0 = 2'd0;
    (* ASYNC_REG = "TRUE" *) reg  [1:0]  selected_wire_variant_sys_ff1 = 2'd0;
    wire signed [12:0] circuit_canvas_grid_pos_x;
    wire signed [12:0] circuit_canvas_grid_pos_y;
    (* ASYNC_REG = "TRUE" *) reg signed [12:0] circuit_canvas_grid_pos_x_sys_ff0 = 13'sd0;
    (* ASYNC_REG = "TRUE" *) reg signed [12:0] circuit_canvas_grid_pos_x_sys_ff1 = 13'sd0;
    (* ASYNC_REG = "TRUE" *) reg signed [12:0] circuit_canvas_grid_pos_y_sys_ff0 = 13'sd0;
    (* ASYNC_REG = "TRUE" *) reg signed [12:0] circuit_canvas_grid_pos_y_sys_ff1 = 13'sd0;
    wire signed [12:0] circuit_canvas_grid_pos_x_sys = circuit_canvas_grid_pos_x_sys_ff1;
    wire signed [12:0] circuit_canvas_grid_pos_y_sys = circuit_canvas_grid_pos_y_sys_ff1;
    reg         mouse_left_d_sys = 1'b0;
    reg top_bar_active, left_bar_active, right_bar_active, canvas_label_active, title_active, frame_active, icon_active, grid_line_active;
    integer dx, dy;

    wire [11:0] mouse_xpos, mouse_ypos;
    wire [3:0]  mouse_zpos;
    wire        mouse_left, mouse_middle, mouse_right, mouse_new_event;
    (* ASYNC_REG = "TRUE" *) reg  [11:0] mouse_xpos_pix_ff0 = 12'd0;
    (* ASYNC_REG = "TRUE" *) reg  [11:0] mouse_xpos_pix_ff1 = 12'd0;
    (* ASYNC_REG = "TRUE" *) reg  [11:0] mouse_ypos_pix_ff0 = 12'd0;
    (* ASYNC_REG = "TRUE" *) reg  [11:0] mouse_ypos_pix_ff1 = 12'd0;
    (* ASYNC_REG = "TRUE" *) reg         mouse_left_pix_ff0 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg         mouse_left_pix_ff1 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg         mouse_middle_pix_ff0 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg         mouse_middle_pix_ff1 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg         mouse_right_pix_ff0 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg         mouse_right_pix_ff1 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg  [11:0] mouse_xpos_nav_ff0 = 12'd0;
    (* ASYNC_REG = "TRUE" *) reg  [11:0] mouse_xpos_nav_ff1 = 12'd0;
    (* ASYNC_REG = "TRUE" *) reg  [11:0] mouse_ypos_nav_ff0 = 12'd0;
    (* ASYNC_REG = "TRUE" *) reg  [11:0] mouse_ypos_nav_ff1 = 12'd0;
    (* ASYNC_REG = "TRUE" *) reg         mouse_left_nav_ff0 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg         mouse_left_nav_ff1 = 1'b0;
    reg  [11:0] mouse_set_value;
    reg         mouse_set_max_x, mouse_set_max_y;

    wire        mouse_display_enable;
    wire [3:0]  mouse_r, mouse_g, mouse_b;
    wire [11:0] mouse_rgb;
    reg         circuit_canvas_ram_w_en = 1'b0;
    reg  [CANVAS_ADDR_W-1:0]  circuit_canvas_ram_w_addr = {CANVAS_ADDR_W{1'b0}};
    wire [CANVAS_ADDR_W-1:0]  circuit_canvas_ram_r_addr;
    reg  [15:0] circuit_canvas_ram_w_data = 16'd0;
    wire [15:0] circuit_canvas_ram_r_data;
    localparam [9:0] INIT_DELAY_CYCLES = 10'd1000;
    reg  [9:0]  init_cycles = 10'd0;

    reg         clear_canvas_active = 1'b0;
    reg  [CANVAS_ADDR_W-1:0]  clear_canvas_addr = {CANVAS_ADDR_W{1'b0}};
    wire [11:0] mouse_xpos_pix = mouse_xpos_pix_ff1;
    wire [11:0] mouse_ypos_pix = mouse_ypos_pix_ff1;
    wire        mouse_left_pix = mouse_left_pix_ff1;
    wire        mouse_middle_pix = mouse_middle_pix_ff1;
    wire        mouse_right_pix = mouse_right_pix_ff1;
    wire [11:0] mouse_xpos_nav = mouse_xpos_nav_ff1;
    wire [11:0] mouse_ypos_nav = mouse_ypos_nav_ff1;
    wire        mouse_left_nav = mouse_left_nav_ff1;
    wire [3:0]  selected_toolbar_idx_sys = selected_toolbar_idx_sys_ff1;
    wire [1:0]  selected_wire_variant_sys = selected_wire_variant_sys_ff1;
    assign keyboard_region_active = (x_pos >= KEYBOARD_REGION_X0) && (x_pos < KEYBOARD_REGION_X1) && (y_pos >= KEYBOARD_REGION_Y0) && (y_pos < KEYBOARD_REGION_Y1);
    assign mouse_rgb = {mouse_r, mouse_g, mouse_b};

    function [11:0] rgb888_to_444;
        input [23:0] c;
        begin
            rgb888_to_444 = {c[23:20], c[15:12], c[7:4]};
        end
    endfunction

    function [7:0] ascii_hex_nibble;
        input [3:0] nibble;
        begin
            case (nibble)
                4'h0: ascii_hex_nibble = "0";
                4'h1: ascii_hex_nibble = "1";
                4'h2: ascii_hex_nibble = "2";
                4'h3: ascii_hex_nibble = "3";
                4'h4: ascii_hex_nibble = "4";
                4'h5: ascii_hex_nibble = "5";
                4'h6: ascii_hex_nibble = "6";
                4'h7: ascii_hex_nibble = "7";
                4'h8: ascii_hex_nibble = "8";
                4'h9: ascii_hex_nibble = "9";
                4'hA: ascii_hex_nibble = "A";
                4'hB: ascii_hex_nibble = "B";
                4'hC: ascii_hex_nibble = "C";
                4'hD: ascii_hex_nibble = "D";
                4'hE: ascii_hex_nibble = "E";
                default: ascii_hex_nibble = "F";
            endcase
        end
    endfunction

    function [7:0] ascii_decimal_nibble;
        input [3:0] nibble;
        begin
            if (nibble <= 4'd9) begin
                ascii_decimal_nibble = nibble + 8'd48;
            end else begin
                ascii_decimal_nibble = "?";
            end
        end
    endfunction

    task set_store_char;
        inout [STORE_VIEW_TEXT_MAX_CHARS * 8 - 1:0] text_bus;
        input integer char_index;
        input [7:0] ch;
        begin
            text_bus[STORE_VIEW_TEXT_MAX_CHARS * 8 - 1 - (char_index * 8) -: 8] = ch;
        end
    endtask

    function [15:0] make_cell_data;
        input [1:0] rotation;
        input [5:0] sprite_type;
        begin
            make_cell_data = {7'b0000000, rotation, sprite_type, 1'b1};
        end
    endfunction

    function [15:0] toolbar_first_cell_data;
        input [3:0] tool_idx;
        begin
            case (tool_idx)
                4'd1: toolbar_first_cell_data = make_cell_data(2'b00, 6'd0); // wire
                4'd2: toolbar_first_cell_data = make_cell_data(2'b00, 6'd5); // resistor left
                4'd3: toolbar_first_cell_data = make_cell_data(2'b00, 6'd11); // inductor left
                4'd4: toolbar_first_cell_data = make_cell_data(2'b00, 6'd13); // capacitor left
                4'd5: toolbar_first_cell_data = make_cell_data(2'b00, 6'd7); // voltage left
                4'd6: toolbar_first_cell_data = make_cell_data(2'b00, 6'd9); // current left
                4'd7: toolbar_first_cell_data = make_cell_data(2'b00, 6'd15); // ground
                default: toolbar_first_cell_data = 16'd0;
            endcase
        end
    endfunction

    function [15:0] toolbar_second_cell_data;
        input [3:0] tool_idx;
        begin
            case (tool_idx)
                4'd2: toolbar_second_cell_data = make_cell_data(2'b00, 6'd6); // resistor right
                4'd3: toolbar_second_cell_data = make_cell_data(2'b00, 6'd12); // inductor right
                4'd4: toolbar_second_cell_data = make_cell_data(2'b00, 6'd14); // capacitor right
                4'd5: toolbar_second_cell_data = make_cell_data(2'b00, 6'd8); // voltage right
                4'd6: toolbar_second_cell_data = make_cell_data(2'b00, 6'd10); // current right
                default: toolbar_second_cell_data = 16'd0;
            endcase
        end
    endfunction

    function toolbar_tool_uses_two_cells;
        input [3:0] tool_idx;
        begin
            case (tool_idx)
                4'd2, 4'd3, 4'd4, 4'd5, 4'd6: toolbar_tool_uses_two_cells = 1'b1;
                default: toolbar_tool_uses_two_cells = 1'b0;
            endcase
        end
    endfunction

    function [15:0] rotate_cell_data;
        input [15:0] cell_data;
        begin
            if (cell_data[0]) begin
                rotate_cell_data = {cell_data[15:9], cell_data[8:7] + 2'b01, cell_data[6:0]};
            end else begin
                rotate_cell_data = cell_data;
            end
        end
    endfunction

    function [3:0] toolbar_mode_select;
        input [3:0] tool_idx;
        input [1:0] wire_variant;
        begin
            case (tool_idx)
                4'd1: begin
                    case (wire_variant)
                        2'd0: toolbar_mode_select = 4'd0;   // wire
                        2'd1: toolbar_mode_select = 4'd1;   // junction
                        2'd2: toolbar_mode_select = 4'd2;   // elbow
                        default: toolbar_mode_select = 4'd3; // tee
                    endcase
                end
                4'd2: toolbar_mode_select = 4'd4;   // resistor
                4'd3: toolbar_mode_select = 4'd9;   // inductor
                4'd4: toolbar_mode_select = 4'd10;  // capacitor
                4'd5: toolbar_mode_select = 4'd5;   // voltage source
                4'd6: toolbar_mode_select = 4'd6;   // current source
                4'd7: toolbar_mode_select = 4'd11;  // ground
                4'd8: toolbar_mode_select = 4'd7;   // rotate
                4'd9: toolbar_mode_select = 4'd8;   // delete
                default: toolbar_mode_select = 4'hF;
            endcase
        end
    endfunction

    localparam [5:0] SPRITE_WIRE       = 6'd0;
    localparam [5:0] SPRITE_ELBOW      = 6'd1;
    localparam [5:0] SPRITE_TEE        = 6'd2;
    localparam [5:0] SPRITE_JUNCTION   = 6'd3;
    localparam [5:0] SPRITE_RES_LEFT   = 6'd5;
    localparam [5:0] SPRITE_RES_RIGHT  = 6'd6;
    localparam [5:0] SPRITE_VOLT_LEFT  = 6'd7;
    localparam [5:0] SPRITE_VOLT_RIGHT = 6'd8;
    localparam [5:0] SPRITE_CURR_LEFT  = 6'd9;
    localparam [5:0] SPRITE_CURR_RIGHT = 6'd10;
    localparam [5:0] SPRITE_IND_LEFT   = 6'd11;
    localparam [5:0] SPRITE_IND_RIGHT  = 6'd12;
    localparam [5:0] SPRITE_CAP_LEFT   = 6'd13;
    localparam [5:0] SPRITE_CAP_RIGHT  = 6'd14;
    localparam [5:0] SPRITE_GROUND     = 6'd15;

    localparam [3:0] COMPONENT_TYPE_WIRE      = 4'd0;
    localparam [3:0] COMPONENT_TYPE_GROUND    = 4'd1;
    localparam [3:0] COMPONENT_TYPE_RESISTOR  = 4'd2;
    localparam [3:0] COMPONENT_TYPE_CAPACITOR = 4'd3;
    localparam [3:0] COMPONENT_TYPE_INDUCTOR  = 4'd4;
    localparam [3:0] COMPONENT_TYPE_VOLTAGE   = 4'd5;
    localparam [3:0] COMPONENT_TYPE_CURRENT   = 4'd6;
    localparam [3:0] COMPONENT_UNIT_NONE      = 4'd0;
    localparam [3:0] COMPONENT_UNIT_M         = 4'd1;
    localparam [3:0] COMPONENT_UNIT_K         = 4'd2;
    localparam [3:0] COMPONENT_UNIT_m         = 4'd3;
    localparam [3:0] COMPONENT_UNIT_U         = 4'd4;
    localparam [3:0] COMPONENT_UNIT_N         = 4'd5;
    localparam [3:0] COMPONENT_UNIT_P         = 4'd6;
    localparam integer COMPONENT_STORE_ENTRY_W = 40;

    function is_left_half_type;
        input [5:0] sprite_type;
        begin
            case (sprite_type)
                SPRITE_RES_LEFT, SPRITE_VOLT_LEFT, SPRITE_CURR_LEFT,
                SPRITE_IND_LEFT, SPRITE_CAP_LEFT: is_left_half_type = 1'b1;
                default: is_left_half_type = 1'b0;
            endcase
        end
    endfunction

    function is_right_half_type;
        input [5:0] sprite_type;
        begin
            case (sprite_type)
                SPRITE_RES_RIGHT, SPRITE_VOLT_RIGHT, SPRITE_CURR_RIGHT,
                SPRITE_IND_RIGHT, SPRITE_CAP_RIGHT: is_right_half_type = 1'b1;
                default: is_right_half_type = 1'b0;
            endcase
        end
    endfunction

    function component_store_is_origin;
        input [15:0] cell_data;
        input [5:0] sprite_type;
        begin
            component_store_is_origin = cell_data[0] && !is_right_half_type(sprite_type);
        end
    endfunction

    function [3:0] component_type_from_sprite;
        input [5:0] sprite_type;
        begin
            case (sprite_type)
                SPRITE_GROUND: component_type_from_sprite = COMPONENT_TYPE_GROUND;
                SPRITE_RES_LEFT, SPRITE_RES_RIGHT: component_type_from_sprite = COMPONENT_TYPE_RESISTOR;
                SPRITE_CAP_LEFT, SPRITE_CAP_RIGHT: component_type_from_sprite = COMPONENT_TYPE_CAPACITOR;
                SPRITE_IND_LEFT, SPRITE_IND_RIGHT: component_type_from_sprite = COMPONENT_TYPE_INDUCTOR;
                SPRITE_VOLT_LEFT, SPRITE_VOLT_RIGHT: component_type_from_sprite = COMPONENT_TYPE_VOLTAGE;
                SPRITE_CURR_LEFT, SPRITE_CURR_RIGHT: component_type_from_sprite = COMPONENT_TYPE_CURRENT;
                SPRITE_WIRE, SPRITE_ELBOW, SPRITE_TEE, SPRITE_JUNCTION: component_type_from_sprite = COMPONENT_TYPE_WIRE;
                default: component_type_from_sprite = COMPONENT_TYPE_WIRE;
            endcase
        end
    endfunction

    function [8:0] component_position_from_addr;
        input [CANVAS_ADDR_W-1:0] cell_addr;
        integer pos_x;
        integer pos_y;
        begin
            pos_x = cell_addr % CANVAS_GRID_W;
            pos_y = cell_addr / CANVAS_GRID_W;
            component_position_from_addr = {pos_y[3:0], pos_x[4:0]};
        end
    endfunction

    function [7:0] text_char_at8;
        input [63:0] text_value;
        input [2:0] char_index;
        begin
            case (char_index)
                3'd0: text_char_at8 = text_value[63:56];
                3'd1: text_char_at8 = text_value[55:48];
                3'd2: text_char_at8 = text_value[47:40];
                3'd3: text_char_at8 = text_value[39:32];
                3'd4: text_char_at8 = text_value[31:24];
                3'd5: text_char_at8 = text_value[23:16];
                3'd6: text_char_at8 = text_value[15:8];
                default: text_char_at8 = text_value[7:0];
            endcase
        end
    endfunction

    function [3:0] component_unit_code_from_ascii;
        input [7:0] ascii;
        begin
            case (ascii)
                "M": component_unit_code_from_ascii = COMPONENT_UNIT_M;
                "k": component_unit_code_from_ascii = COMPONENT_UNIT_K;
                "m": component_unit_code_from_ascii = COMPONENT_UNIT_m;
                "u": component_unit_code_from_ascii = COMPONENT_UNIT_U;
                "n": component_unit_code_from_ascii = COMPONENT_UNIT_N;
                "p": component_unit_code_from_ascii = COMPONENT_UNIT_P;
                default: component_unit_code_from_ascii = COMPONENT_UNIT_NONE;
            endcase
        end
    endfunction

    function [7:0] ascii_from_component_unit;
        input [3:0] unit_code;
        begin
            case (unit_code)
                COMPONENT_UNIT_M: ascii_from_component_unit = "M";
                COMPONENT_UNIT_K: ascii_from_component_unit = "k";
                COMPONENT_UNIT_m: ascii_from_component_unit = "m";
                COMPONENT_UNIT_U: ascii_from_component_unit = "u";
                COMPONENT_UNIT_N: ascii_from_component_unit = "n";
                COMPONENT_UNIT_P: ascii_from_component_unit = "p";
                default: ascii_from_component_unit = "-";
            endcase
        end
    endfunction

    function [3:0] component_unit_code_from_text;
        input [63:0] text_value;
        input [3:0] text_len;
        integer idx;
        reg [3:0] unit_code;
        begin
            unit_code = COMPONENT_UNIT_NONE;
            for (idx = 0; idx < 8; idx = idx + 1) begin
                if (idx < text_len) begin
                    case (component_unit_code_from_ascii(text_char_at8(text_value, idx[2:0])))
                        COMPONENT_UNIT_NONE: begin end
                        default: unit_code = component_unit_code_from_ascii(text_char_at8(text_value, idx[2:0]));
                    endcase
                end
            end
            component_unit_code_from_text = unit_code;
        end
    endfunction

    function [COMPONENT_STORE_ENTRY_W-1:0] make_component_store_entry;
        input [3:0] component_unit;
        input [CANVAS_ADDR_W-1:0] store_index;
        input [3:0] component_type;
        input [1:0] component_rotation;
        input [11:0] component_value;
        input [CANVAS_ADDR_W-1:0] cell_addr;
        begin
            make_component_store_entry = {
                component_unit,
                store_index,
                component_type,
                component_rotation,
                component_value,
                component_position_from_addr(cell_addr)
            };
        end
    endfunction

    function component_type_uses_two_cells;
        input [3:0] component_type;
        begin
            case (component_type)
                COMPONENT_TYPE_RESISTOR,
                COMPONENT_TYPE_CAPACITOR,
                COMPONENT_TYPE_INDUCTOR,
                COMPONENT_TYPE_VOLTAGE,
                COMPONENT_TYPE_CURRENT: component_type_uses_two_cells = 1'b1;
                default: component_type_uses_two_cells = 1'b0;
            endcase
        end
    endfunction

    function component_type_needs_index;
        input [3:0] component_type;
        begin
            case (component_type)
                COMPONENT_TYPE_WIRE: component_type_needs_index = 1'b0;
                default: component_type_needs_index = 1'b1;
            endcase
        end
    endfunction

    function [CANVAS_ADDR_W-1:0] component_addr_from_position;
        input [8:0] component_position;
        integer pos_x;
        integer pos_y;
        begin
            pos_x = component_position[4:0];
            pos_y = component_position[8:5];
            component_addr_from_position = pos_x + (pos_y * CANVAS_GRID_W);
        end
    endfunction

    function [CANVAS_ADDR_W-1:0] component_pair_addr_from_origin;
        input [CANVAS_ADDR_W-1:0] origin_addr;
        input [1:0] rotation;
        integer delta;
        integer tmp;
        begin
            case (rotation)
                2'd0: delta = 1;
                2'd1: delta = CANVAS_GRID_W;
                2'd2: delta = -1;
                default: delta = -CANVAS_GRID_W;
            endcase

            tmp = origin_addr + delta;
            if ((tmp < 0) || (tmp >= CANVAS_CELL_COUNT)) component_pair_addr_from_origin = origin_addr;
            else component_pair_addr_from_origin = tmp[CANVAS_ADDR_W-1:0];
        end
    endfunction

    function [11:0] bcd_insert_ltr3;
        input [11:0] cur;
        input [3:0] digit;
        input [1:0] digit_count;
        begin
            case (digit_count)
                2'd0: bcd_insert_ltr3 = {digit, 8'd0};
                2'd1: bcd_insert_ltr3 = {cur[11:8], digit, 4'd0};
                2'd2: bcd_insert_ltr3 = {cur[11:8], cur[7:4], digit};
                default: bcd_insert_ltr3 = cur;
            endcase
        end
    endfunction

    function [11:0] bcd_insert_ltr2;
        input [11:0] cur;
        input [3:0] digit;
        input [1:0] digit_count;
        begin
            case (digit_count)
                2'd0: bcd_insert_ltr2 = {4'd0, digit, 4'd0};
                2'd1: bcd_insert_ltr2 = {4'd0, cur[7:4], digit};
                default: bcd_insert_ltr2 = cur;
            endcase
        end
    endfunction

    function [11:0] bcd_delete_ltr3;
        input [11:0] cur;
        input [1:0] digit_count;
        begin
            case (digit_count)
                2'd1: bcd_delete_ltr3 = 12'd0;
                2'd2: bcd_delete_ltr3 = {cur[11:8], 8'd0};
                2'd3: bcd_delete_ltr3 = {cur[11:8], cur[7:4], 4'd0};
                default: bcd_delete_ltr3 = cur;
            endcase
        end
    endfunction

    function [11:0] bcd_delete_ltr2;
        input [11:0] cur;
        input [1:0] digit_count;
        begin
            case (digit_count)
                2'd1: bcd_delete_ltr2 = 12'd0;
                2'd2: bcd_delete_ltr2 = {4'd0, cur[7:4], 4'd0};
                default: bcd_delete_ltr2 = cur;
            endcase
        end
    endfunction

    function [CANVAS_ADDR_W-1:0] pair_addr_for_cell;
        input [CANVAS_ADDR_W-1:0] base_addr;
        input [5:0] sprite_type;
        input [1:0] rotation;
        integer delta;
        integer tmp;
        begin
            case (rotation)
                2'd0: delta = 1;
                2'd1: delta = CANVAS_GRID_W;
                2'd2: delta = -1;
                default: delta = -CANVAS_GRID_W;
            endcase

            if (is_left_half_type(sprite_type)) tmp = base_addr + delta;
            else if (is_right_half_type(sprite_type)) tmp = base_addr - delta;
            else tmp = base_addr;

            if ((tmp < 0) || (tmp >= CANVAS_CELL_COUNT)) pair_addr_for_cell = base_addr;
            else pair_addr_for_cell = tmp[CANVAS_ADDR_W-1:0];
        end
    endfunction

    function keyboard_ascii_is_unit_char;
        input [7:0] ascii;
        begin
            case (ascii)
                "M", "k", "m", "u", "n", "p": keyboard_ascii_is_unit_char = 1'b1;
                default: keyboard_ascii_is_unit_char = 1'b0;
            endcase
        end
    endfunction

    function [63:0] text_append8;
        input [63:0] cur;
        input [7:0] ascii;
        input [3:0] len;
        begin
            case (len)
                4'd0: text_append8 = {ascii, 56'd0};
                4'd1: text_append8 = {cur[63:56], ascii, 48'd0};
                4'd2: text_append8 = {cur[63:48], ascii, 40'd0};
                4'd3: text_append8 = {cur[63:40], ascii, 32'd0};
                4'd4: text_append8 = {cur[63:32], ascii, 24'd0};
                4'd5: text_append8 = {cur[63:24], ascii, 16'd0};
                4'd6: text_append8 = {cur[63:16], ascii, 8'd0};
                4'd7: text_append8 = {cur[63:8], ascii};
                default: text_append8 = cur;
            endcase
        end
    endfunction

    function [63:0] text_delete8;
        input [63:0] cur;
        input [3:0] len;
        begin
            case (len)
                4'd1: text_delete8 = 64'd0;
                4'd2: text_delete8 = {cur[63:56], 56'd0};
                4'd3: text_delete8 = {cur[63:48], 48'd0};
                4'd4: text_delete8 = {cur[63:40], 40'd0};
                4'd5: text_delete8 = {cur[63:32], 32'd0};
                4'd6: text_delete8 = {cur[63:24], 24'd0};
                4'd7: text_delete8 = {cur[63:16], 16'd0};
                4'd8: text_delete8 = {cur[63:8], 8'd0};
                default: text_delete8 = cur;
            endcase
        end
    endfunction

    // JC 端口由 Oled_Display 模块驱动，必须移除强制拉低，否则 OLED 黑屏
    // assign JC = 8'h00;
    assign SEG = seg_data;
    assign AN = 4'hF;
    assign LED = SW;
    ClockDivider #( .FREQ(25_000_000) ) clkdiv_pixel_inst ( .CLK100MHZ(CLK100MHZ), .clk_out(clk_pixel) );
    ClockDivider #( .FREQ(20) ) clkdiv_nav_inst ( .CLK100MHZ(CLK100MHZ), .clk_out(clk_nav) );

    // =========================================================
    // OLED Clock Divider: 100MHz -> 6.25MHz & 20Hz
    // 生成 OLED 像素时钟和计算器导航时钟 (独立于系统时钟)
    // =========================================================
    reg [3:0] oled_clk_div_counter = 0;
    reg [22:0] oled_clk_div_20hz = 0;
    reg oled_clk6p25m = 0;
    reg oled_clk20hz = 0;

    always @(posedge CLK100MHZ) begin
        if (oled_clk_div_counter == 7) begin
            oled_clk_div_counter <= 0;
            oled_clk6p25m <= ~oled_clk6p25m;
        end else begin
            oled_clk_div_counter <= oled_clk_div_counter + 1;
        end
        
        if (oled_clk_div_20hz == 2500000) begin
            oled_clk_div_20hz <= 0;
            oled_clk20hz <= ~oled_clk20hz;
        end else begin
            oled_clk_div_20hz <= oled_clk_div_20hz + 1;
        end
    end

    assign oled_x_pos = oled_pixel_index % 96;
    assign oled_y_pos = oled_pixel_index / 96;

    always @(posedge oled_clk6p25m) begin
        oled_data <= oled_pixel_rgb;
    end

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
    wire wave_rst_n = ~SW[15];

    MouseCtl mouse_ctrl_inst (
        .clk(CLK100MHZ), .rst(BTNC), .xpos(mouse_xpos), .ypos(mouse_ypos), .zpos(mouse_zpos),
        .left(mouse_left), .middle(mouse_middle), .right(mouse_right),
        .new_event(mouse_new_event), .value(mouse_set_value), .setx(1'b0), .sety(1'b0),
        .setmax_x(mouse_set_max_x), .setmax_y(mouse_set_max_y), .ps2_clk(PS2CLK), .ps2_data(PS2DATA)
    );
    always @(posedge clk_pixel) begin
        mouse_xpos_pix_ff0 <= mouse_xpos;
        mouse_xpos_pix_ff1 <= mouse_xpos_pix_ff0;
        mouse_ypos_pix_ff0 <= mouse_ypos;
        mouse_ypos_pix_ff1 <= mouse_ypos_pix_ff0;
        mouse_left_pix_ff0 <= mouse_left;
        mouse_left_pix_ff1 <= mouse_left_pix_ff0;
        mouse_middle_pix_ff0 <= mouse_middle;
        mouse_middle_pix_ff1 <= mouse_middle_pix_ff0;
        mouse_right_pix_ff0 <= mouse_right;
        mouse_right_pix_ff1 <= mouse_right_pix_ff0;
    end
    always @(posedge clk_nav) begin
        mouse_xpos_nav_ff0 <= mouse_xpos;
        mouse_xpos_nav_ff1 <= mouse_xpos_nav_ff0;
        mouse_ypos_nav_ff0 <= mouse_ypos;
        mouse_ypos_nav_ff1 <= mouse_ypos_nav_ff0;
        mouse_left_nav_ff0 <= mouse_left;
        mouse_left_nav_ff1 <= mouse_left_nav_ff0;
    end
    always @(posedge CLK100MHZ) begin
        selected_toolbar_idx_sys_ff0 <= selected_toolbar_idx;
        selected_toolbar_idx_sys_ff1 <= selected_toolbar_idx_sys_ff0;
        selected_wire_variant_sys_ff0 <= selected_wire_variant;
        selected_wire_variant_sys_ff1 <= selected_wire_variant_sys_ff0;
        circuit_canvas_grid_pos_x_sys_ff0 <= circuit_canvas_grid_pos_x;
        circuit_canvas_grid_pos_x_sys_ff1 <= circuit_canvas_grid_pos_x_sys_ff0;
        circuit_canvas_grid_pos_y_sys_ff0 <= circuit_canvas_grid_pos_y;
        circuit_canvas_grid_pos_y_sys_ff1 <= circuit_canvas_grid_pos_y_sys_ff0;
    end
    MouseDisplay mouse_disp_inst (
        .pixel_clk(clk_pixel), .xpos(mouse_xpos_pix), .ypos(mouse_ypos_pix),
        .mouse_left(mouse_left_pix),
        .hcount(x_pos), .vcount(y_pos), .enable_mouse_display_out(mouse_display_enable),
        .red_out(mouse_r), .green_out(mouse_g), .blue_out(mouse_b)
    );

    SimpleDualClockRam #( .WordWidth(16), .WordCount(CANVAS_CELL_COUNT) ) circuit_canvas_ram_inst (
        .wr_clk(CLK100MHZ), .rd_clk(clk_pixel),
        .w_en(circuit_canvas_ram_w_en), .w_addr(circuit_canvas_ram_w_addr),
        .r_addr(circuit_canvas_ram_r_addr), .d_in(circuit_canvas_ram_w_data), .d_out(circuit_canvas_ram_r_data)
    );

    // =========================================================
    // 動態電流動畫產生器 (內建 1D 相位)
    // =========================================================
    reg [21:0] anim_tick = 0;
    reg [4:0]  global_anim_phase = 0;
    always @(posedge clk_pixel) begin
        if (anim_tick >= 22'd1000000) begin
            anim_tick <= 0;
            global_anim_phase <= global_anim_phase + 1;
        end else begin
            anim_tick <= anim_tick + 1;
        end
    end

    reg         interaction_frame_toggle_pix = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg         interaction_frame_sync0 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg         interaction_frame_sync1 = 1'b0;
    reg         interaction_frame_sync2 = 1'b0;
    wire        interaction_frame_tick;
    wire [3:0]  interaction_mode_select;
    wire        interaction_bg_cmd_valid;
    wire        interaction_bg_cmd_write;
    wire [CANVAS_ADDR_W-1:0]  interaction_bg_cmd_addr;
    wire [15:0] interaction_bg_cmd_wdata;
    wire        interaction_bg_cmd_ready;
    reg         interaction_bg_rsp_valid = 1'b0;
    reg  [15:0] interaction_bg_rsp_rdata = 16'd0;
    wire        interaction_frame_done;
    wire        interaction_frame_drop_flag;

    assign interaction_mode_select = toolbar_mode_select(selected_toolbar_idx_sys, selected_wire_variant_sys);
    assign interaction_frame_tick = interaction_frame_sync1 ^ interaction_frame_sync2;

    CircuitCanvas #(
        .CanvasPosX(CANVAS_X0), .CanvasPosY(CANVAS_Y0),
        .CanvasWidth(CANVAS_W), .CanvasHeight(CANVAS_H),
        .CellSize(CANVAS_CELL_SIZE), .GridWidth(CANVAS_GRID_W), .GridHeight(CANVAS_GRID_H)
    ) circuit_canvas_inst (
        .clk_pixel(clk_pixel), .x_pos(x_pos), .y_pos(y_pos), .rgb(circuit_canvas_rgb),
        .rendered(circuit_canvas_rendered), .mouse_x_pos(mouse_xpos_pix), .mouse_y_pos(mouse_ypos_pix),
        .data_addr(circuit_canvas_ram_r_addr), .incoming_data(circuit_canvas_ram_r_data),
        .display_grid(1'b1), .mouse_left_click(mouse_left_pix && (selected_toolbar_idx == 4'd0)),
        .anim_phase(global_anim_phase),
        .grid_pos_x_out(circuit_canvas_grid_pos_x),
        .grid_pos_y_out(circuit_canvas_grid_pos_y)
    );
    // Component Property Panel signals 以下为属性面板例化
    wire        prop_panel_rendered;
    wire [11:0] prop_panel_rgb;
    reg  [11:0] selected_cell_i = 12'd0;
    reg  [11:0] selected_cell_j = 12'd0;
    reg  [15:0] selected_cell_data = 16'd0;
    reg  [15:0] selected_cell_data_sys = 16'd0;
    reg  [11:0] selected_value_bcd = 12'd0;
    reg  [1:0]  selected_value_digits = 2'd0;
    reg  [63:0] selected_value_text = 64'd0;
    reg  [3:0]  selected_value_text_len = 4'd0;
    reg  [CANVAS_ADDR_W-1:0] selected_component_index_sys = COMPONENT_INDEX_INVALID;
    reg         selected_component_index_valid_sys = 1'b0;
    reg  [3:0]  selected_component_unit_sys = COMPONENT_UNIT_NONE;
    reg  [3:0]  selected_component_type_sys = COMPONENT_TYPE_WIRE;
    reg  [1:0]  selected_component_rotation_sys = 2'd0;
    reg  [11:0] selected_component_value_sys = 12'd0;
    reg  [8:0]  selected_component_position_sys = 9'd0;
    reg         has_selection = 1'b0;
    reg         value_edit_active = 1'b0;
    reg         mouse_left_d = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg [11:0] selected_cell_i_sys_ff0 = 12'd0;
    (* ASYNC_REG = "TRUE" *) reg [11:0] selected_cell_i_sys_ff1 = 12'd0;
    (* ASYNC_REG = "TRUE" *) reg [11:0] selected_cell_j_sys_ff0 = 12'd0;
    (* ASYNC_REG = "TRUE" *) reg [11:0] selected_cell_j_sys_ff1 = 12'd0;
    (* ASYNC_REG = "TRUE" *) reg        has_selection_sys_ff0 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg        has_selection_sys_ff1 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg        value_edit_active_sys_ff0 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg        value_edit_active_sys_ff1 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg [15:0] selected_cell_data_ff0 = 16'd0;
    (* ASYNC_REG = "TRUE" *) reg [15:0] selected_cell_data_ff1 = 16'd0;
    (* ASYNC_REG = "TRUE" *) reg [63:0] selected_value_text_ui_ff0 = 64'd0;
    (* ASYNC_REG = "TRUE" *) reg [63:0] selected_value_text_ui_ff1 = 64'd0;
    (* ASYNC_REG = "TRUE" *) reg [3:0]  selected_value_text_len_ui_ff0 = 4'd0;
    (* ASYNC_REG = "TRUE" *) reg [3:0]  selected_value_text_len_ui_ff1 = 4'd0;
    (* ASYNC_REG = "TRUE" *) reg [CANVAS_ADDR_W-1:0] selected_component_index_ui_ff0 = COMPONENT_INDEX_INVALID;
    (* ASYNC_REG = "TRUE" *) reg [CANVAS_ADDR_W-1:0] selected_component_index_ui_ff1 = COMPONENT_INDEX_INVALID;
    (* ASYNC_REG = "TRUE" *) reg        selected_component_index_valid_ui_ff0 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg        selected_component_index_valid_ui_ff1 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg [3:0]  selected_component_unit_ui_ff0 = COMPONENT_UNIT_NONE;
    (* ASYNC_REG = "TRUE" *) reg [3:0]  selected_component_unit_ui_ff1 = COMPONENT_UNIT_NONE;
    (* ASYNC_REG = "TRUE" *) reg [3:0]  selected_component_type_ui_ff0 = COMPONENT_TYPE_WIRE;
    (* ASYNC_REG = "TRUE" *) reg [3:0]  selected_component_type_ui_ff1 = COMPONENT_TYPE_WIRE;
    (* ASYNC_REG = "TRUE" *) reg [1:0]  selected_component_rotation_ui_ff0 = 2'd0;
    (* ASYNC_REG = "TRUE" *) reg [1:0]  selected_component_rotation_ui_ff1 = 2'd0;
    (* ASYNC_REG = "TRUE" *) reg [11:0] selected_component_value_ui_ff0 = 12'd0;
    (* ASYNC_REG = "TRUE" *) reg [11:0] selected_component_value_ui_ff1 = 12'd0;
    (* ASYNC_REG = "TRUE" *) reg [8:0]  selected_component_position_ui_ff0 = 9'd0;
    (* ASYNC_REG = "TRUE" *) reg [8:0]  selected_component_position_ui_ff1 = 9'd0;
    (* ASYNC_REG = "TRUE" *) reg        component_store_busy_ui_ff0 = 1'b1;
    (* ASYNC_REG = "TRUE" *) reg        component_store_busy_ui_ff1 = 1'b1;
    (* ASYNC_REG = "TRUE" *) reg [CANVAS_ADDR_W-1:0] component_store_count_ui_ff0 = {CANVAS_ADDR_W{1'b0}};
    (* ASYNC_REG = "TRUE" *) reg [CANVAS_ADDR_W-1:0] component_store_count_ui_ff1 = {CANVAS_ADDR_W{1'b0}};
    reg  [CANVAS_ADDR_W-1:0] component_store_view_index_ui = {CANVAS_ADDR_W{1'b0}};
    reg         component_store_view_manual_ui = 1'b0;
    reg         component_store_view_show_d = 1'b0;
    reg         component_store_prev_toggle_nav = 1'b0;
    reg         component_store_prev_btn_nav_d = 1'b0;
    reg         component_store_next_toggle_nav = 1'b0;
    reg         component_store_next_btn_nav_d = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg        component_store_prev_toggle_pix_ff0 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg        component_store_prev_toggle_pix_ff1 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg        component_store_next_toggle_pix_ff0 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg        component_store_next_toggle_pix_ff1 = 1'b0;
    reg         component_store_prev_toggle_seen_pix = 1'b0;
    reg         component_store_next_toggle_seen_pix = 1'b0;
    reg         component_store_display_valid_ui = 1'b0;
    reg  [CANVAS_ADDR_W-1:0] component_store_display_index_ui = {CANVAS_ADDR_W{1'b0}};
    reg  [COMPONENT_STORE_ENTRY_W-1:0] component_store_display_entry_ui = {COMPONENT_STORE_ENTRY_W{1'b0}};
    reg  [CANVAS_ADDR_W-1:0] component_store_view_req_index_ui = {CANVAS_ADDR_W{1'b0}};
    reg         component_store_view_req_toggle_ui = 1'b0;
    reg         component_store_view_req_pending_ui = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg [CANVAS_ADDR_W-1:0] component_store_view_rsp_index_ui_ff0 = {CANVAS_ADDR_W{1'b0}};
    (* ASYNC_REG = "TRUE" *) reg [CANVAS_ADDR_W-1:0] component_store_view_rsp_index_ui_ff1 = {CANVAS_ADDR_W{1'b0}};
    (* ASYNC_REG = "TRUE" *) reg [COMPONENT_STORE_ENTRY_W-1:0] component_store_view_rsp_entry_ui_ff0 = {COMPONENT_STORE_ENTRY_W{1'b0}};
    (* ASYNC_REG = "TRUE" *) reg [COMPONENT_STORE_ENTRY_W-1:0] component_store_view_rsp_entry_ui_ff1 = {COMPONENT_STORE_ENTRY_W{1'b0}};
    (* ASYNC_REG = "TRUE" *) reg        component_store_view_rsp_toggle_ui_ff0 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg        component_store_view_rsp_toggle_ui_ff1 = 1'b0;
    reg         component_store_view_rsp_toggle_seen_ui = 1'b0;
    wire [11:0] selected_cell_i_sys = selected_cell_i_sys_ff1;
    wire [11:0] selected_cell_j_sys = selected_cell_j_sys_ff1;
    wire        has_selection_sys = has_selection_sys_ff1;
    wire        value_edit_active_sys = value_edit_active_sys_ff1;
    wire [63:0] selected_value_text_ui = selected_value_text_ui_ff1;
    wire [3:0]  selected_value_text_len_ui = selected_value_text_len_ui_ff1;
    wire [CANVAS_ADDR_W-1:0] selected_component_index_ui = selected_component_index_ui_ff1;
    wire        selected_component_index_valid_ui = selected_component_index_valid_ui_ff1;
    wire [3:0]  selected_component_unit_ui = selected_component_unit_ui_ff1;
    wire [3:0]  selected_component_type_ui = selected_component_type_ui_ff1;
    wire [1:0]  selected_component_rotation_ui = selected_component_rotation_ui_ff1;
    wire [11:0] selected_component_value_ui = selected_component_value_ui_ff1;
    wire [8:0]  selected_component_position_ui = selected_component_position_ui_ff1;
    wire        component_store_busy_ui = component_store_busy_ui_ff1;
    wire [CANVAS_ADDR_W-1:0] component_store_count_ui = component_store_count_ui_ff1;
    wire        selected_component_store_ready_ui =
        !component_store_busy_ui && selected_component_index_valid_ui &&
        (selected_component_index_ui < component_store_count_ui);
    wire        component_store_prev_event_pix =
        (component_store_prev_toggle_pix_ff1 != component_store_prev_toggle_seen_pix);
    wire        component_store_next_event_pix =
        (component_store_next_toggle_pix_ff1 != component_store_next_toggle_seen_pix);
    wire        component_store_view_has_entry_ui =
        !component_store_busy_ui && (component_store_count_ui != {CANVAS_ADDR_W{1'b0}});
    wire [CANVAS_ADDR_W-1:0] component_store_selected_index_ui =
        selected_component_store_ready_ui ? selected_component_index_ui : {CANVAS_ADDR_W{1'b0}};
    wire [CANVAS_ADDR_W-1:0] component_store_view_index_clamped_ui =
        (component_store_count_ui == {CANVAS_ADDR_W{1'b0}}) ? {CANVAS_ADDR_W{1'b0}} :
        ((component_store_view_index_ui < component_store_count_ui) ?
            component_store_view_index_ui : (component_store_count_ui - 1'b1));
    wire        component_store_view_rsp_event_ui =
        (component_store_view_rsp_toggle_ui_ff1 != component_store_view_rsp_toggle_seen_ui);
    wire        component_store_view_entry_ready_ui =
        component_store_view_has_entry_ui && component_store_display_valid_ui &&
        (component_store_display_index_ui < component_store_count_ui);
    wire [3:0]  component_store_view_unit_ui = component_store_display_entry_ui[39:36];
    wire [CANVAS_ADDR_W-1:0] component_store_view_entry_index_ui =
        component_store_display_entry_ui[35:27];
    wire [3:0]  component_store_view_type_ui = component_store_display_entry_ui[26:23];
    wire [1:0]  component_store_view_rotation_ui = component_store_display_entry_ui[22:21];
    wire [11:0] component_store_view_value_ui = component_store_display_entry_ui[20:9];
    wire [8:0]  component_store_view_position_ui = component_store_display_entry_ui[8:0];
    wire        mouse_left_rising;
    reg  [STORE_VIEW_TEXT_MAX_CHARS * 8 - 1:0] store_status_data;
    reg  [4:0] store_status_len;
    reg  [STORE_VIEW_TEXT_MAX_CHARS * 8 - 1:0] store_count_data;
    reg  [4:0] store_count_len;
    reg  [STORE_VIEW_TEXT_MAX_CHARS * 8 - 1:0] store_packed_data;
    reg  [4:0] store_packed_len;
    reg  [STORE_VIEW_TEXT_MAX_CHARS * 8 - 1:0] store_index_data;
    reg  [4:0] store_index_len;
    reg  [STORE_VIEW_TEXT_MAX_CHARS * 8 - 1:0] store_type_data;
    reg  [4:0] store_type_len;
    reg  [STORE_VIEW_TEXT_MAX_CHARS * 8 - 1:0] store_rot_data;
    reg  [4:0] store_rot_len;
    reg  [STORE_VIEW_TEXT_MAX_CHARS * 8 - 1:0] store_value_data;
    reg  [4:0] store_value_len;
    reg  [STORE_VIEW_TEXT_MAX_CHARS * 8 - 1:0] store_raw_data;
    reg  [4:0] store_raw_len;
    reg  [STORE_VIEW_TEXT_MAX_CHARS * 8 - 1:0] store_pos_data;
    reg  [4:0] store_pos_len;
    wire       store_title_rendered;
    wire [11:0] store_title_rgb;
    wire       store_hint_rendered;
    wire [11:0] store_hint_rgb;
    wire       store_status_rendered;
    wire [11:0] store_status_rgb;
    wire       store_count_rendered;
    wire [11:0] store_count_rgb;
    wire       store_packed_rendered;
    wire [11:0] store_packed_rgb;
    wire       store_index_rendered;
    wire [11:0] store_index_rgb;
    wire       store_type_rendered;
    wire [11:0] store_type_rgb;
    wire       store_rot_rendered;
    wire [11:0] store_rot_rgb;
    wire       store_value_rendered;
    wire [11:0] store_value_rgb;
    wire       store_raw_rendered;
    wire [11:0] store_raw_rgb;
    wire       store_pos_rendered;
    wire [11:0] store_pos_rgb;
    reg        component_store_view_rendered;
    reg  [11:0] component_store_view_rgb;
    integer    store_char_idx;
    
    // 鼠标悬停检测
    wire signed [13:0] mouse_x_rel_canvas_signed;
    wire signed [13:0] mouse_y_rel_canvas_signed;
    wire signed [13:0] mouse_grid_x_signed;
    wire signed [13:0] mouse_grid_y_signed;
    wire        mouse_grid_x_valid;
    wire        mouse_grid_y_valid;
    wire [11:0] mouse_cell_i;
    wire [11:0] mouse_cell_j;
    wire        mouse_cell_valid;
    wire        canvas_mouse_in_bounds;
    wire        mouse_in_prop_value_box;
    wire        mouse_in_prop_panel;
    wire        mouse_in_keyboard_panel;
    wire        selected_is_editable_ui;
    reg         value_ram_w_en = 1'b0;
    reg  [CANVAS_ADDR_W-1:0] value_ram_w_addr = {CANVAS_ADDR_W{1'b0}};
    reg  [11:0] value_ram_w_data = 12'd0;
    wire [11:0] value_ram_r_data;
    reg  [1:0]  value_digit_ram_w_data = 2'd0;
    wire [1:0]  value_digit_ram_r_data;
    reg  [63:0] value_text_ram_w_data = 64'd0;
    wire [63:0] value_text_ram_r_data;
    reg  [3:0]  value_text_len_ram_w_data = 4'd0;
    wire [3:0]  value_text_len_ram_r_data;
    reg         pending_pair_value_write = 1'b0;
    reg  [CANVAS_ADDR_W-1:0] pending_pair_value_addr = {CANVAS_ADDR_W{1'b0}};
    reg  [11:0] pending_pair_value_data = 12'd0;
    reg  [1:0]  pending_pair_value_digits = 2'd0;
    reg  [63:0] pending_pair_value_text = 64'd0;
    reg  [3:0]  pending_pair_value_text_len = 4'd0;
    reg         keyboard_event_toggle_nav = 1'b0;
    reg  [7:0]  keyboard_event_ascii_nav = 8'h00;
    (* ASYNC_REG = "TRUE" *) reg         keyboard_event_sync0 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg         keyboard_event_sync1 = 1'b0;
    reg         keyboard_event_seen = 1'b0;
    reg  [11:0] edit_value_next_bcd = 12'd0;
    reg  [1:0]  edit_value_next_digits = 2'd0;
    reg  [63:0] edit_value_next_text = 64'd0;
    reg  [3:0]  edit_value_next_text_len = 4'd0;
    reg         edit_value_valid = 1'b0;
    
    // 示例元件数据 (从 init_cycles 中复制)
    reg  [15:0] canvas_shadow_data [0:CANVAS_CELL_COUNT-1];
    reg  [11:0] value_shadow_data [0:CANVAS_CELL_COUNT-1];
    reg  [3:0]  value_unit_shadow_data [0:CANVAS_CELL_COUNT-1];
    // component_store entry = {unit[3:0], index[8:0], type[3:0], rotation[1:0], value[11:0], position[8:0]}
    // position[8:5] = y, position[4:0] = x
    localparam integer BACKEND_FRAME_CYCLE_BUDGET = 10000;
    localparam [3:0] BACKEND_TEST_IDLE        = 4'd0;
    localparam [3:0] BACKEND_TEST_START_TYPE  = 4'd1;
    localparam [3:0] BACKEND_TEST_WAIT_TYPE   = 4'd2;
    localparam [3:0] BACKEND_TEST_START_VALUE = 4'd3;
    localparam [3:0] BACKEND_TEST_WAIT_VALUE  = 4'd4;
    localparam [3:0] BACKEND_TEST_START_X     = 4'd5;
    localparam [3:0] BACKEND_TEST_WAIT_X      = 4'd6;
    localparam [3:0] BACKEND_TEST_START_Y     = 4'd7;
    localparam [3:0] BACKEND_TEST_WAIT_Y      = 4'd8;
    reg         component_store_w_en = 1'b0;
    reg  [CANVAS_ADDR_W-1:0] component_store_w_addr = {CANVAS_ADDR_W{1'b0}};
    reg  [COMPONENT_STORE_ENTRY_W-1:0] component_store_w_data = {COMPONENT_STORE_ENTRY_W{1'b0}};
    reg  [CANVAS_ADDR_W-1:0] component_store_ram_r_addr = {CANVAS_ADDR_W{1'b0}};
    wire [COMPONENT_STORE_ENTRY_W-1:0] component_store_ram_r_data;
    reg  [CANVAS_ADDR_W-1:0] component_store_count = {CANVAS_ADDR_W{1'b0}};
    reg         component_store_dirty = 1'b1;
    reg         component_store_read_busy = 1'b0;
    reg         component_store_read_owner_backend = 1'b0;
    reg  [CANVAS_ADDR_W-1:0] component_store_read_addr_latched = {CANVAS_ADDR_W{1'b0}};
    (* ASYNC_REG = "TRUE" *) reg [CANVAS_ADDR_W-1:0] component_store_view_req_index_sys_ff0 = {CANVAS_ADDR_W{1'b0}};
    (* ASYNC_REG = "TRUE" *) reg [CANVAS_ADDR_W-1:0] component_store_view_req_index_sys_ff1 = {CANVAS_ADDR_W{1'b0}};
    (* ASYNC_REG = "TRUE" *) reg        component_store_view_req_toggle_sys_ff0 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg        component_store_view_req_toggle_sys_ff1 = 1'b0;
    reg         component_store_view_req_toggle_seen_sys = 1'b0;
    reg  [CANVAS_ADDR_W-1:0] component_store_view_rsp_index_sys = {CANVAS_ADDR_W{1'b0}};
    reg  [COMPONENT_STORE_ENTRY_W-1:0] component_store_view_rsp_entry_sys = {COMPONENT_STORE_ENTRY_W{1'b0}};
    reg         component_store_view_rsp_toggle_sys = 1'b0;
    reg         component_index_map_w_en = 1'b0;
    reg  [CANVAS_ADDR_W-1:0] component_index_map_w_addr = {CANVAS_ADDR_W{1'b0}};
    reg  [CANVAS_ADDR_W-1:0] component_index_map_w_data = COMPONENT_INDEX_INVALID;
    reg         component_index_map_clear_active = 1'b0;
    reg  [CANVAS_ADDR_W-1:0] component_index_map_clear_addr = {CANVAS_ADDR_W{1'b0}};
    reg         component_index_map_pending_pair_write = 1'b0;
    reg  [CANVAS_ADDR_W-1:0] component_index_map_pending_pair_addr = {CANVAS_ADDR_W{1'b0}};
    reg  [CANVAS_ADDR_W-1:0] component_index_map_pending_pair_data = COMPONENT_INDEX_INVALID;
    reg         component_store_rebuild_active = 1'b0;
    reg  [CANVAS_ADDR_W-1:0] component_store_scan_addr = {CANVAS_ADDR_W{1'b0}};
    reg  [CANVAS_ADDR_W-1:0] component_store_next_index = {CANVAS_ADDR_W{1'b0}};
    reg         component_store_change_this_cycle;
    wire [15:0] component_store_scan_cell = canvas_shadow_data[component_store_scan_addr];
    wire [5:0]  component_store_scan_sprite = component_store_scan_cell[6:1];
    wire [1:0]  component_store_scan_rotation = component_store_scan_cell[8:7];
    wire [11:0] component_store_scan_value = value_shadow_data[component_store_scan_addr];
    wire [3:0]  component_store_scan_unit = value_unit_shadow_data[component_store_scan_addr];
    wire [3:0]  component_store_scan_type = component_type_from_sprite(component_store_scan_sprite);
    wire        component_store_scan_needs_index = component_type_needs_index(component_store_scan_type);
    wire        component_store_scan_is_two_cell = component_type_uses_two_cells(component_store_scan_type);
    wire [CANVAS_ADDR_W-1:0] component_store_scan_pair_addr =
        component_pair_addr_from_origin(component_store_scan_addr, component_store_scan_rotation);
    wire [CANVAS_ADDR_W-1:0] selected_cell_addr_sys;
    wire [CANVAS_ADDR_W-1:0] selected_value_store_addr_sys;
    wire [CANVAS_ADDR_W-1:0] selected_component_index_map_data;
    wire        component_store_busy =
        component_index_map_pending_pair_write || component_index_map_clear_active ||
        component_store_rebuild_active || component_store_dirty;
    wire        backend_fetch_test_enable;
    reg         backend_frame_pending = 1'b0;
    reg         backend_test_active = 1'b0;
    reg  [13:0] backend_cycle_budget = 14'd0;
    reg  [CANVAS_ADDR_W-1:0] backend_test_idx = {CANVAS_ADDR_W{1'b0}};
    reg  [CANVAS_ADDR_W-1:0] backend_test_count = {CANVAS_ADDR_W{1'b0}};
    reg  [3:0]  backend_test_state = BACKEND_TEST_IDLE;
    reg         backend_fetch_type_start = 1'b0;
    reg         backend_fetch_value_start = 1'b0;
    reg         backend_fetch_x_start = 1'b0;
    reg         backend_fetch_y_start = 1'b0;
    wire        backend_fetch_type_busy;
    wire        backend_fetch_type_done;
    wire [3:0]  backend_fetch_type_result;
    wire        backend_fetch_type_comp_ren;
    wire [CANVAS_ADDR_W-1:0] backend_fetch_type_comp_addr;
    wire        backend_fetch_value_busy;
    wire        backend_fetch_value_done;
    wire [11:0] backend_fetch_value_result;
    wire        backend_fetch_value_comp_ren;
    wire [CANVAS_ADDR_W-1:0] backend_fetch_value_comp_addr;
    wire        backend_fetch_x_busy;
    wire        backend_fetch_x_done;
    wire [4:0]  backend_fetch_x_result;
    wire        backend_fetch_x_comp_ren;
    wire [CANVAS_ADDR_W-1:0] backend_fetch_x_comp_addr;
    wire        backend_fetch_y_busy;
    wire        backend_fetch_y_done;
    wire [3:0]  backend_fetch_y_result;
    wire        backend_fetch_y_comp_ren;
    wire [CANVAS_ADDR_W-1:0] backend_fetch_y_comp_addr;
    wire        backend_comp_ren =
        backend_fetch_type_comp_ren || backend_fetch_value_comp_ren ||
        backend_fetch_x_comp_ren || backend_fetch_y_comp_ren;
    wire [CANVAS_ADDR_W-1:0] backend_comp_addr =
        backend_fetch_type_comp_ren ? backend_fetch_type_comp_addr :
        backend_fetch_value_comp_ren ? backend_fetch_value_comp_addr :
        backend_fetch_x_comp_ren ? backend_fetch_x_comp_addr :
        backend_fetch_y_comp_addr;
    wire        backend_component_port_ready = !component_store_busy && !component_store_read_busy;
    reg  [3:0]  backend_last_type = 4'd0;
    reg  [11:0] backend_last_value = 12'd0;
    reg  [4:0]  backend_last_x = 5'd0;
    reg  [3:0]  backend_last_y = 4'd0;
    assign seg_data = backend_fetch_test_enable ?
        {4'hF, ~backend_test_active, ~backend_frame_pending, ~component_store_busy, ~component_store_read_busy} :
        8'hFF;
    SimpleRam #( .WordWidth(CANVAS_ADDR_W), .WordCount(CANVAS_CELL_COUNT) ) component_index_map_ram_inst (
        .clk(CLK100MHZ), .w_en(component_index_map_w_en), .w_addr(component_index_map_w_addr),
        .r_addr(selected_cell_addr_sys), .d_in(component_index_map_w_data), .d_out(selected_component_index_map_data)
    );
    SimpleDualClockRam #( .WordWidth(COMPONENT_STORE_ENTRY_W), .WordCount(CANVAS_CELL_COUNT) ) component_store_ram_inst (
        .wr_clk(CLK100MHZ), .rd_clk(CLK100MHZ),
        .w_en(component_store_w_en), .w_addr(component_store_w_addr),
        .r_addr(component_store_ram_r_addr), .d_in(component_store_w_data), .d_out(component_store_ram_r_data)
    );
    fetchComponentType backend_fetch_type_inst (
        .clk(CLK100MHZ),
        .start(backend_fetch_type_start),
        .busy(backend_fetch_type_busy),
        .done(backend_fetch_type_done),
        .idx(backend_test_idx),
        .result(backend_fetch_type_result),
        .comp_ren(backend_fetch_type_comp_ren),
        .comp_addr(backend_fetch_type_comp_addr),
        .comp_rdata(component_store_ram_r_data)
    );
    fetchComponentValue backend_fetch_value_inst (
        .clk(CLK100MHZ),
        .start(backend_fetch_value_start),
        .busy(backend_fetch_value_busy),
        .done(backend_fetch_value_done),
        .idx(backend_test_idx),
        .result(backend_fetch_value_result),
        .comp_ren(backend_fetch_value_comp_ren),
        .comp_addr(backend_fetch_value_comp_addr),
        .comp_rdata(component_store_ram_r_data)
    );
    fetchAnchorPositionX backend_fetch_x_inst (
        .clk(CLK100MHZ),
        .start(backend_fetch_x_start),
        .busy(backend_fetch_x_busy),
        .done(backend_fetch_x_done),
        .idx(backend_test_idx),
        .result(backend_fetch_x_result),
        .comp_ren(backend_fetch_x_comp_ren),
        .comp_addr(backend_fetch_x_comp_addr),
        .comp_rdata(component_store_ram_r_data)
    );
    fetchAnchorPositionY backend_fetch_y_inst (
        .clk(CLK100MHZ),
        .start(backend_fetch_y_start),
        .busy(backend_fetch_y_busy),
        .done(backend_fetch_y_done),
        .idx(backend_test_idx),
        .result(backend_fetch_y_result),
        .comp_ren(backend_fetch_y_comp_ren),
        .comp_addr(backend_fetch_y_comp_addr),
        .comp_rdata(component_store_ram_r_data)
    );
    SimpleRam #( .WordWidth(12), .WordCount(CANVAS_CELL_COUNT) ) component_value_ram_inst (
        .clk(CLK100MHZ), .w_en(value_ram_w_en), .w_addr(value_ram_w_addr),
        .r_addr(selected_value_store_addr_sys), .d_in(value_ram_w_data), .d_out(value_ram_r_data)
    );
    SimpleRam #( .WordWidth(2), .WordCount(CANVAS_CELL_COUNT) ) component_value_digit_ram_inst (
        .clk(CLK100MHZ), .w_en(value_ram_w_en), .w_addr(value_ram_w_addr),
        .r_addr(selected_value_store_addr_sys), .d_in(value_digit_ram_w_data), .d_out(value_digit_ram_r_data)
    );
    SimpleRam #( .WordWidth(64), .WordCount(CANVAS_CELL_COUNT) ) component_value_text_ram_inst (
        .clk(CLK100MHZ), .w_en(value_ram_w_en), .w_addr(value_ram_w_addr),
        .r_addr(selected_value_store_addr_sys), .d_in(value_text_ram_w_data), .d_out(value_text_ram_r_data)
    );
    SimpleRam #( .WordWidth(4), .WordCount(CANVAS_CELL_COUNT) ) component_value_text_len_ram_inst (
        .clk(CLK100MHZ), .w_en(value_ram_w_en), .w_addr(value_ram_w_addr),
        .r_addr(selected_value_store_addr_sys), .d_in(value_text_len_ram_w_data), .d_out(value_text_len_ram_r_data)
    );

    always @(posedge CLK100MHZ) begin
        component_store_view_req_index_sys_ff0 <= component_store_view_req_index_ui;
        component_store_view_req_index_sys_ff1 <= component_store_view_req_index_sys_ff0;
        component_store_view_req_toggle_sys_ff0 <= component_store_view_req_toggle_ui;
        component_store_view_req_toggle_sys_ff1 <= component_store_view_req_toggle_sys_ff0;

        if (component_store_read_busy) begin
            component_store_read_busy <= 1'b0;
            if (!component_store_read_owner_backend) begin
                component_store_view_rsp_index_sys <= component_store_read_addr_latched;
                component_store_view_rsp_entry_sys <= component_store_ram_r_data;
                component_store_view_rsp_toggle_sys <= ~component_store_view_rsp_toggle_sys;
            end
        end else if (!component_store_busy) begin
            if (backend_comp_ren) begin
                component_store_ram_r_addr <= backend_comp_addr;
                component_store_read_addr_latched <= backend_comp_addr;
                component_store_read_owner_backend <= 1'b1;
                component_store_read_busy <= 1'b1;
            end else if (component_store_view_req_toggle_sys_ff1 != component_store_view_req_toggle_seen_sys) begin
                component_store_view_req_toggle_seen_sys <= component_store_view_req_toggle_sys_ff1;
                component_store_ram_r_addr <= component_store_view_req_index_sys_ff1;
                component_store_read_addr_latched <= component_store_view_req_index_sys_ff1;
                component_store_read_owner_backend <= 1'b0;
                component_store_read_busy <= 1'b1;
            end
        end
    end

    always @(posedge CLK100MHZ) begin
        backend_fetch_type_start <= 1'b0;
        backend_fetch_value_start <= 1'b0;
        backend_fetch_x_start <= 1'b0;
        backend_fetch_y_start <= 1'b0;

        if (interaction_frame_tick && backend_fetch_test_enable) begin
            backend_frame_pending <= 1'b1;
        end

        if (!backend_fetch_test_enable) begin
            backend_frame_pending <= 1'b0;
            backend_test_active <= 1'b0;
            backend_cycle_budget <= 14'd0;
            backend_test_idx <= {CANVAS_ADDR_W{1'b0}};
            backend_test_count <= {CANVAS_ADDR_W{1'b0}};
            backend_test_state <= BACKEND_TEST_IDLE;
        end else if (component_store_busy) begin
            backend_test_active <= 1'b0;
            backend_test_state <= BACKEND_TEST_IDLE;
            backend_cycle_budget <= 14'd0;
        end else begin
            if (backend_test_active && (backend_cycle_budget != 14'd0)) begin
                backend_cycle_budget <= backend_cycle_budget - 1'b1;
            end

            if (backend_test_active && (backend_cycle_budget == 14'd0)) begin
                backend_test_active <= 1'b0;
                backend_test_state <= BACKEND_TEST_IDLE;
            end else begin
                case (backend_test_state)
                    BACKEND_TEST_IDLE: begin
                        if (backend_frame_pending) begin
                            backend_frame_pending <= 1'b0;
                            if (component_store_count != {CANVAS_ADDR_W{1'b0}}) begin
                                backend_test_active <= 1'b1;
                                backend_cycle_budget <= BACKEND_FRAME_CYCLE_BUDGET;
                                backend_test_idx <= {CANVAS_ADDR_W{1'b0}};
                                backend_test_count <= component_store_count;
                                backend_test_state <= BACKEND_TEST_START_TYPE;
                            end
                        end
                    end
                    BACKEND_TEST_START_TYPE: begin
                        if (backend_component_port_ready) begin
                            backend_fetch_type_start <= 1'b1;
                            backend_test_state <= BACKEND_TEST_WAIT_TYPE;
                        end
                    end
                    BACKEND_TEST_WAIT_TYPE: begin
                        if (backend_fetch_type_done) begin
                            backend_last_type <= backend_fetch_type_result;
                            backend_test_state <= BACKEND_TEST_START_VALUE;
                        end
                    end
                    BACKEND_TEST_START_VALUE: begin
                        if (backend_component_port_ready) begin
                            backend_fetch_value_start <= 1'b1;
                            backend_test_state <= BACKEND_TEST_WAIT_VALUE;
                        end
                    end
                    BACKEND_TEST_WAIT_VALUE: begin
                        if (backend_fetch_value_done) begin
                            backend_last_value <= backend_fetch_value_result;
                            backend_test_state <= BACKEND_TEST_START_X;
                        end
                    end
                    BACKEND_TEST_START_X: begin
                        if (backend_component_port_ready) begin
                            backend_fetch_x_start <= 1'b1;
                            backend_test_state <= BACKEND_TEST_WAIT_X;
                        end
                    end
                    BACKEND_TEST_WAIT_X: begin
                        if (backend_fetch_x_done) begin
                            backend_last_x <= backend_fetch_x_result;
                            backend_test_state <= BACKEND_TEST_START_Y;
                        end
                    end
                    BACKEND_TEST_START_Y: begin
                        if (backend_component_port_ready) begin
                            backend_fetch_y_start <= 1'b1;
                            backend_test_state <= BACKEND_TEST_WAIT_Y;
                        end
                    end
                    BACKEND_TEST_WAIT_Y: begin
                        if (backend_fetch_y_done) begin
                            backend_last_y <= backend_fetch_y_result;
                            if ((backend_test_idx + 1'b1) < backend_test_count && (backend_cycle_budget > 14'd8)) begin
                                backend_test_idx <= backend_test_idx + 1'b1;
                                backend_test_state <= BACKEND_TEST_START_TYPE;
                            end else begin
                                backend_test_active <= 1'b0;
                                backend_test_state <= BACKEND_TEST_IDLE;
                            end
                        end
                    end
                    default: backend_test_state <= BACKEND_TEST_IDLE;
                endcase
            end
        end
    end

    // =========================================================
    // Component Property Panel - 元件属性显示 (简化版)
    // =========================================================
    assign selected_cell_addr_sys = selected_cell_i_sys + selected_cell_j_sys * CANVAS_GRID_W;
    assign selected_value_store_addr_sys =
        is_right_half_type(selected_cell_data_sys[6:1]) ?
        pair_addr_for_cell(selected_cell_addr_sys, selected_cell_data_sys[6:1], selected_cell_data_sys[8:7]) :
        selected_cell_addr_sys;

    // 鼠标悬停位置计算 (Canvas 区域：X0=64, Y0=64)
    assign mouse_x_rel_canvas_signed = $signed({1'b0, mouse_xpos_pix}) - CANVAS_X0;
    assign mouse_y_rel_canvas_signed = $signed({1'b0, mouse_ypos_pix}) - CANVAS_Y0;
    assign mouse_grid_x_signed = mouse_x_rel_canvas_signed - $signed(circuit_canvas_grid_pos_x);
    assign mouse_grid_y_signed = mouse_y_rel_canvas_signed - $signed(circuit_canvas_grid_pos_y);
    assign mouse_grid_x_valid = mouse_grid_x_signed >= 0;
    assign mouse_grid_y_valid = mouse_grid_y_signed >= 0;
    assign mouse_cell_i = mouse_grid_x_signed[11:0] / CANVAS_CELL_SIZE;
    assign mouse_cell_j = mouse_grid_y_signed[11:0] / CANVAS_CELL_SIZE;
    assign mouse_cell_valid = mouse_grid_x_valid && mouse_grid_y_valid &&
                              (mouse_cell_i < CANVAS_GRID_W) && (mouse_cell_j < CANVAS_GRID_H);
    
    // 鼠标点击边沿检测
    assign canvas_mouse_in_bounds = (mouse_xpos_pix >= CANVAS_X0) && (mouse_xpos_pix < (CANVAS_X0 + CANVAS_W)) &&
                                    (mouse_ypos_pix >= CANVAS_Y0) && (mouse_ypos_pix < (CANVAS_Y0 + CANVAS_H)) &&
                               
     mouse_cell_valid;
    assign mouse_in_prop_panel = has_selection &&
                                 (mouse_xpos_pix >= PROP_PANEL_X) && (mouse_xpos_pix < (PROP_PANEL_X + PROP_PANEL_W)) &&
                                 (mouse_ypos_pix >= PROP_PANEL_Y) && (mouse_ypos_pix < (PROP_PANEL_Y + PROP_PANEL_H));
    assign mouse_in_keyboard_panel = (mouse_xpos_pix >= KEYBOARD_X) && (mouse_xpos_pix < (KEYBOARD_X + KEYBOARD_W)) &&
                                     (mouse_ypos_pix >= KEYBOARD_Y) && (mouse_ypos_pix < (KEYBOARD_Y + KEYBOARD_H));
    assign mouse_in_prop_value_box = has_selection &&
                                     (mouse_xpos_pix >= PROP_VALUE_BOX_X0) && (mouse_xpos_pix < PROP_VALUE_BOX_X1) &&
                                     (mouse_ypos_pix >= PROP_VALUE_BOX_Y0) && (mouse_ypos_pix < PROP_VALUE_BOX_Y1);
    assign selected_is_editable_ui = has_selection && selected_cell_data[0] &&
                                     ((selected_cell_data[6:1] == SPRITE_RES_LEFT) || (selected_cell_data[6:1] == SPRITE_RES_RIGHT) ||
                                      (selected_cell_data[6:1] == SPRITE_VOLT_LEFT) || (selected_cell_data[6:1] == SPRITE_VOLT_RIGHT) ||
                                      (selected_cell_data[6:1] == SPRITE_CURR_LEFT) || (selected_cell_data[6:1] == SPRITE_CURR_RIGHT) ||
                                      (selected_cell_data[6:1] == SPRITE_IND_LEFT) || (selected_cell_data[6:1] == SPRITE_IND_RIGHT) ||
                                      (selected_cell_data[6:1] == SPRITE_CAP_LEFT) || (selected_cell_data[6:1] == SPRITE_CAP_RIGHT));
    assign mouse_left_rising = mouse_left_pix && !mouse_left_d;
    always @(posedge CLK100MHZ) begin
        selected_cell_i_sys_ff0 <= selected_cell_i;
        selected_cell_i_sys_ff1 <= selected_cell_i_sys_ff0;
        selected_cell_j_sys_ff0 <= selected_cell_j;
        selected_cell_j_sys_ff1 <= selected_cell_j_sys_ff0;
        has_selection_sys_ff0 <= has_selection;
        has_selection_sys_ff1 <= has_selection_sys_ff0;
        value_edit_active_sys_ff0 <= value_edit_active;
        value_edit_active_sys_ff1 <= value_edit_active_sys_ff0;
        if (has_selection_sys) begin
            selected_cell_data_sys <= canvas_shadow_data[selected_cell_addr_sys];
        end else begin
            selected_cell_data_sys <= 16'd0;
        end
        if (has_selection_sys) begin
            selected_component_unit_sys <= value_unit_shadow_data[selected_value_store_addr_sys];
            selected_component_type_sys <= component_type_from_sprite(selected_cell_data_sys[6:1]);
            selected_component_rotation_sys <= selected_cell_data_sys[8:7];
            selected_component_value_sys <= value_shadow_data[selected_value_store_addr_sys];
            selected_component_position_sys <= component_position_from_addr(selected_value_store_addr_sys);
        end else begin
            selected_component_unit_sys <= COMPONENT_UNIT_NONE;
            selected_component_type_sys <= COMPONENT_TYPE_WIRE;
            selected_component_rotation_sys <= 2'd0;
            selected_component_value_sys <= 12'd0;
            selected_component_position_sys <= 9'd0;
        end
        if (has_selection_sys && !component_store_busy &&
            (selected_component_index_map_data != COMPONENT_INDEX_INVALID)) begin
            selected_component_index_sys <= selected_component_index_map_data;
            selected_component_index_valid_sys <= 1'b1;
        end else begin
            selected_component_index_sys <= COMPONENT_INDEX_INVALID;
            selected_component_index_valid_sys <= 1'b0;
        end
    end

    always @(posedge clk_pixel) begin
        selected_cell_data_ff0 <= selected_cell_data_sys;
        selected_cell_data_ff1 <= selected_cell_data_ff0;
        selected_cell_data <= selected_cell_data_ff1;
        selected_value_text_ui_ff0 <= selected_value_text;
        selected_value_text_ui_ff1 <= selected_value_text_ui_ff0;
        selected_value_text_len_ui_ff0 <= selected_value_text_len;
        selected_value_text_len_ui_ff1 <= selected_value_text_len_ui_ff0;
        selected_component_index_ui_ff0 <= selected_component_index_sys;
        selected_component_index_ui_ff1 <= selected_component_index_ui_ff0;
        selected_component_index_valid_ui_ff0 <= selected_component_index_valid_sys;
        selected_component_index_valid_ui_ff1 <= selected_component_index_valid_ui_ff0;
        selected_component_unit_ui_ff0 <= selected_component_unit_sys;
        selected_component_unit_ui_ff1 <= selected_component_unit_ui_ff0;
        selected_component_type_ui_ff0 <= selected_component_type_sys;
        selected_component_type_ui_ff1 <= selected_component_type_ui_ff0;
        selected_component_rotation_ui_ff0 <= selected_component_rotation_sys;
        selected_component_rotation_ui_ff1 <= selected_component_rotation_ui_ff0;
        selected_component_value_ui_ff0 <= selected_component_value_sys;
        selected_component_value_ui_ff1 <= selected_component_value_ui_ff0;
        selected_component_position_ui_ff0 <= selected_component_position_sys;
        selected_component_position_ui_ff1 <= selected_component_position_ui_ff0;
        component_store_busy_ui_ff0 <= component_store_busy;
        component_store_busy_ui_ff1 <= component_store_busy_ui_ff0;
        component_store_count_ui_ff0 <= component_store_count;
        component_store_count_ui_ff1 <= component_store_count_ui_ff0;
        component_store_prev_toggle_pix_ff0 <= component_store_prev_toggle_nav;
        component_store_prev_toggle_pix_ff1 <= component_store_prev_toggle_pix_ff0;
        component_store_next_toggle_pix_ff0 <= component_store_next_toggle_nav;
        component_store_next_toggle_pix_ff1 <= component_store_next_toggle_pix_ff0;
        component_store_view_rsp_index_ui_ff0 <= component_store_view_rsp_index_sys;
        component_store_view_rsp_index_ui_ff1 <= component_store_view_rsp_index_ui_ff0;
        component_store_view_rsp_entry_ui_ff0 <= component_store_view_rsp_entry_sys;
        component_store_view_rsp_entry_ui_ff1 <= component_store_view_rsp_entry_ui_ff0;
        component_store_view_rsp_toggle_ui_ff0 <= component_store_view_rsp_toggle_sys;
        component_store_view_rsp_toggle_ui_ff1 <= component_store_view_rsp_toggle_ui_ff0;
        component_store_view_show_d <= show_component_store_view;

        if (component_store_prev_event_pix) begin
            component_store_prev_toggle_seen_pix <= component_store_prev_toggle_pix_ff1;
        end
        if (component_store_next_event_pix) begin
            component_store_next_toggle_seen_pix <= component_store_next_toggle_pix_ff1;
        end

        if (!component_store_view_manual_ui && selected_component_store_ready_ui) begin
            component_store_view_index_ui <= component_store_selected_index_ui;
        end else if (component_store_view_has_entry_ui &&
                     (component_store_view_index_ui >= component_store_count_ui)) begin
            component_store_view_index_ui <= component_store_count_ui - 1'b1;
        end

        if (component_store_view_rsp_event_ui) begin
            component_store_view_rsp_toggle_seen_ui <= component_store_view_rsp_toggle_ui_ff1;
            component_store_display_index_ui <= component_store_view_rsp_index_ui_ff1;
            component_store_display_entry_ui <= component_store_view_rsp_entry_ui_ff1;
            component_store_display_valid_ui <= 1'b1;
            component_store_view_req_pending_ui <= 1'b0;
        end

        if (!show_component_store_view) begin
            component_store_view_manual_ui <= 1'b0;
            component_store_display_valid_ui <= 1'b0;
            component_store_view_req_pending_ui <= 1'b0;
        end else if (!component_store_view_show_d) begin
            component_store_view_manual_ui <= 1'b0;
            component_store_display_valid_ui <= 1'b0;
            component_store_view_req_pending_ui <= 1'b0;
        end else if (component_store_busy_ui || !component_store_view_has_entry_ui) begin
            component_store_display_valid_ui <= 1'b0;
            component_store_view_req_pending_ui <= 1'b0;
        end

        if (show_component_store_view && component_store_view_has_entry_ui) begin
            if (component_store_prev_event_pix) begin
                component_store_view_manual_ui <= 1'b1;
                if (component_store_view_index_clamped_ui == {CANVAS_ADDR_W{1'b0}}) begin
                    component_store_view_index_ui <= component_store_count_ui - 1'b1;
                end else begin
                    component_store_view_index_ui <= component_store_view_index_clamped_ui - 1'b1;
                end
            end else if (component_store_next_event_pix) begin
                component_store_view_manual_ui <= 1'b1;
                if ((component_store_view_index_clamped_ui + 1'b1) >= component_store_count_ui) begin
                    component_store_view_index_ui <= {CANVAS_ADDR_W{1'b0}};
                end else begin
                    component_store_view_index_ui <= component_store_view_index_clamped_ui + 1'b1;
                end
            end
        end

        if (show_component_store_view && component_store_view_has_entry_ui &&
            !component_store_view_req_pending_ui &&
            (!component_store_view_entry_ready_ui ||
             (component_store_display_index_ui != component_store_view_index_clamped_ui))) begin
            component_store_view_req_index_ui <= component_store_view_index_clamped_ui;
            component_store_view_req_toggle_ui <= ~component_store_view_req_toggle_ui;
            component_store_view_req_pending_ui <= 1'b1;
        end
    end
    // 同步鼠标点击 - 记录选中的单元格
    always @(posedge clk_pixel) begin
        mouse_left_d <= mouse_left_pix;
        if (show_component_store_view) begin
            value_edit_active <= 1'b0;
        end else if (mouse_left_rising && canvas_mouse_in_bounds) begin
            selected_cell_i <= mouse_cell_i;
            selected_cell_j <= mouse_cell_j;
            has_selection <= 1'b1;
            value_edit_active <= 1'b0;
        end else if (mouse_left_rising && mouse_in_prop_value_box && selected_is_editable_ui) begin
            value_edit_active <= 1'b1;
        end else if (mouse_left_rising && mouse_in_keyboard_panel) begin
            // Keep the current property-panel state while the on-screen keyboard is used for input.
        end else if (mouse_left_rising) begin
            value_edit_active <= 1'b0;
            if (!mouse_in_prop_panel) begin
                has_selection <= 1'b0;
            end
        end
    end

/*

    // 示例元件数据初始化 (与 init_cycles 中的数据相同)
    always @(posedge clk_pixel) begin
        // 初始化所有单元为 0
        // 加载示例元件 (更新為新電路：所有轉角+90度，Tee L/R翻轉)
    
    // 计算悬停的单元格地址
    
    // 从本地存储读取选中单元格的数据

    // 例化属性面板
    end

*/
    wire [5:0] selected_sprite_type = selected_cell_data_sys[6:1];
    wire [1:0] selected_rotation = selected_cell_data_sys[8:7];
    wire selected_is_resistor = (selected_sprite_type == SPRITE_RES_LEFT) || (selected_sprite_type == SPRITE_RES_RIGHT);
    wire selected_is_voltage = (selected_sprite_type == SPRITE_VOLT_LEFT) || (selected_sprite_type == SPRITE_VOLT_RIGHT);
    wire selected_is_current = (selected_sprite_type == SPRITE_CURR_LEFT) || (selected_sprite_type == SPRITE_CURR_RIGHT);
    wire selected_is_inductor = (selected_sprite_type == SPRITE_IND_LEFT) || (selected_sprite_type == SPRITE_IND_RIGHT);
    wire selected_is_capacitor = (selected_sprite_type == SPRITE_CAP_LEFT) || (selected_sprite_type == SPRITE_CAP_RIGHT);
    wire selected_is_editable = has_selection_sys && selected_cell_data_sys[0] &&
        (selected_is_resistor || selected_is_voltage || selected_is_current ||
         selected_is_inductor || selected_is_capacitor);
    wire [CANVAS_ADDR_W-1:0] selected_pair_addr = pair_addr_for_cell(selected_cell_addr_sys, selected_sprite_type, selected_rotation);
    wire keyboard_edit_event = (keyboard_event_sync1 != keyboard_event_seen);
    wire keyboard_ascii_is_digit = (keyboard_ascii_sys_ff1 >= "0") && (keyboard_ascii_sys_ff1 <= "9");
    wire keyboard_ascii_is_dot = (keyboard_ascii_sys_ff1 == ".");
    wire keyboard_ascii_is_unit = keyboard_ascii_is_unit_char(keyboard_ascii_sys_ff1);
    wire keyboard_ascii_is_value_char = keyboard_ascii_is_digit || keyboard_ascii_is_dot || keyboard_ascii_is_unit;
    wire [3:0] keyboard_ascii_digit = keyboard_ascii_sys_ff1 - "0";

    always @(*) begin
        edit_value_next_bcd = selected_value_bcd;
        edit_value_next_digits = selected_value_digits;
        edit_value_next_text = selected_value_text;
        edit_value_next_text_len = selected_value_text_len;
        edit_value_valid = 1'b0;

        if (selected_is_editable && value_edit_active_sys) begin
            if (keyboard_ascii_is_value_char && (selected_value_text_len < 4'd8)) begin
                edit_value_next_text = text_append8(selected_value_text, keyboard_ascii_sys_ff1, selected_value_text_len);
                edit_value_next_text_len = selected_value_text_len + 1'b1;
                if (selected_is_resistor) begin
                    if (keyboard_ascii_is_digit && (selected_value_digits < 2'd3)) begin
                        edit_value_next_bcd = bcd_insert_ltr3(selected_value_bcd, keyboard_ascii_digit, selected_value_digits);
                        edit_value_next_digits = selected_value_digits + 1'b1;
                    end
                end else begin
                    if (keyboard_ascii_is_digit && (selected_value_digits < 2'd2)) begin
                        edit_value_next_bcd = bcd_insert_ltr2(selected_value_bcd, keyboard_ascii_digit, selected_value_digits);
                        edit_value_next_digits = selected_value_digits + 1'b1;
                    end
                end
                edit_value_valid = 1'b1;
            end else if (keyboard_ascii_sys_ff1 == 8'h08) begin
                if (selected_value_text_len != 4'd0) begin
                    edit_value_next_text = text_delete8(selected_value_text, selected_value_text_len);
                    edit_value_next_text_len = selected_value_text_len - 1'b1;
                    if (selected_is_resistor && (selected_value_digits != 2'd0)) begin
                        edit_value_next_bcd = bcd_delete_ltr3(selected_value_bcd, selected_value_digits);
                        edit_value_next_digits = selected_value_digits - 1'b1;
                    end else if ((selected_is_voltage || selected_is_current ||
                                  selected_is_inductor || selected_is_capacitor) &&
                                 (selected_value_digits != 2'd0)) begin
                        edit_value_next_bcd = bcd_delete_ltr2(selected_value_bcd, selected_value_digits);
                        edit_value_next_digits = selected_value_digits - 1'b1;
                    end
                    edit_value_valid = 1'b1;
                end
            end else if (keyboard_ascii_sys_ff1 == 8'h7F) begin
                edit_value_next_bcd = 12'd0;
                edit_value_next_digits = 2'd0;
                edit_value_next_text = 64'd0;
                edit_value_next_text_len = 4'd0;
                edit_value_valid = 1'b1;
            end
        end
    end

    always @(posedge clk_nav) begin
        component_store_prev_btn_nav_d <= BTNL;
        component_store_next_btn_nav_d <= BTNR;
        if (show_component_store_view && BTNL && !component_store_prev_btn_nav_d) begin
            component_store_prev_toggle_nav <= ~component_store_prev_toggle_nav;
        end
        if (show_component_store_view && BTNR && !component_store_next_btn_nav_d) begin
            component_store_next_toggle_nav <= ~component_store_next_toggle_nav;
        end
        if (keyboard_key_valid) begin
            keyboard_event_ascii_nav <= keyboard_key_ascii;
            keyboard_event_toggle_nav <= ~keyboard_event_toggle_nav;
        end
    end
    always @(posedge CLK100MHZ) begin
        keyboard_ascii_sys_ff0 <= keyboard_event_ascii_nav;
        keyboard_ascii_sys_ff1 <= keyboard_ascii_sys_ff0;
    end

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
        .selected_value_text(selected_value_text_ui),
        .selected_value_text_len(selected_value_text_len_ui),
        .value_edit_active(value_edit_active),
        .value_editable(selected_is_editable_ui),
        .has_selection(has_selection),
        .selected_cell_i(selected_cell_i),
        .selected_cell_j(selected_cell_j),
        .selected_component_index_valid(selected_component_index_valid_ui),
        .selected_component_index(selected_component_index_ui),
        .panel_rendered(prop_panel_rendered),
        .panel_rgb(prop_panel_rgb)
    );
    //属性面板例化结束

    // =========================================================
    // 矩阵显示模块 (上下布局，居中显示)
    // =========================================================
    always @(posedge clk_pixel) begin
        if (vsync_edge) begin
            interaction_frame_toggle_pix <= ~interaction_frame_toggle_pix;
        end
    end

    always @(posedge CLK100MHZ) begin
        interaction_frame_sync0 <= interaction_frame_toggle_pix;
        interaction_frame_sync1 <= interaction_frame_sync0;
        interaction_frame_sync2 <= interaction_frame_sync1;
    end

    always @(*) begin
        for (store_char_idx = 0; store_char_idx < STORE_VIEW_TEXT_MAX_CHARS; store_char_idx = store_char_idx + 1) begin
            store_status_data[STORE_VIEW_TEXT_MAX_CHARS * 8 - 1 - (store_char_idx * 8) -: 8] = 8'd0;
            store_count_data[STORE_VIEW_TEXT_MAX_CHARS * 8 - 1 - (store_char_idx * 8) -: 8] = 8'd0;
            store_packed_data[STORE_VIEW_TEXT_MAX_CHARS * 8 - 1 - (store_char_idx * 8) -: 8] = 8'd0;
            store_index_data[STORE_VIEW_TEXT_MAX_CHARS * 8 - 1 - (store_char_idx * 8) -: 8] = 8'd0;
            store_type_data[STORE_VIEW_TEXT_MAX_CHARS * 8 - 1 - (store_char_idx * 8) -: 8] = 8'd0;
            store_rot_data[STORE_VIEW_TEXT_MAX_CHARS * 8 - 1 - (store_char_idx * 8) -: 8] = 8'd0;
            store_value_data[STORE_VIEW_TEXT_MAX_CHARS * 8 - 1 - (store_char_idx * 8) -: 8] = 8'd0;
            store_raw_data[STORE_VIEW_TEXT_MAX_CHARS * 8 - 1 - (store_char_idx * 8) -: 8] = 8'd0;
            store_pos_data[STORE_VIEW_TEXT_MAX_CHARS * 8 - 1 - (store_char_idx * 8) -: 8] = 8'd0;
        end

        store_status_len = 5'd0;
        store_count_len = 5'd0;
        store_packed_len = 5'd0;
        store_index_len = 5'd0;
        store_type_len = 5'd0;
        store_rot_len = 5'd0;
        store_value_len = 5'd0;
        store_raw_len = 5'd0;
        store_pos_len = 5'd0;

        set_store_char(store_status_data, 0, "S");
        set_store_char(store_status_data, 1, "t");
        set_store_char(store_status_data, 2, "a");
        set_store_char(store_status_data, 3, "t");
        set_store_char(store_status_data, 4, "u");
        set_store_char(store_status_data, 5, "s");
        set_store_char(store_status_data, 6, ":");
        set_store_char(store_status_data, 7, " ");
        if (component_store_busy_ui) begin
            set_store_char(store_status_data, 8, "s");
            set_store_char(store_status_data, 9, "t");
            set_store_char(store_status_data, 10, "o");
            set_store_char(store_status_data, 11, "r");
            set_store_char(store_status_data, 12, "e");
            set_store_char(store_status_data, 13, " ");
            set_store_char(store_status_data, 14, "r");
            set_store_char(store_status_data, 15, "e");
            set_store_char(store_status_data, 16, "b");
            set_store_char(store_status_data, 17, "u");
            set_store_char(store_status_data, 18, "i");
            set_store_char(store_status_data, 19, "l");
            set_store_char(store_status_data, 20, "d");
            set_store_char(store_status_data, 21, "i");
            set_store_char(store_status_data, 22, "n");
            set_store_char(store_status_data, 23, "g");
            set_store_char(store_status_data, 24, ".");
            set_store_char(store_status_data, 25, ".");
            set_store_char(store_status_data, 26, ".");
            store_status_len = 5'd27;
        end else if (!component_store_view_has_entry_ui) begin
            set_store_char(store_status_data, 8, "s");
            set_store_char(store_status_data, 9, "t");
            set_store_char(store_status_data, 10, "o");
            set_store_char(store_status_data, 11, "r");
            set_store_char(store_status_data, 12, "e");
            set_store_char(store_status_data, 13, " ");
            set_store_char(store_status_data, 14, "e");
            set_store_char(store_status_data, 15, "m");
            set_store_char(store_status_data, 16, "p");
            set_store_char(store_status_data, 17, "t");
            set_store_char(store_status_data, 18, "y");
            store_status_len = 5'd19;
        end else if (component_store_view_manual_ui) begin
            set_store_char(store_status_data, 8, "m");
            set_store_char(store_status_data, 9, "a");
            set_store_char(store_status_data, 10, "n");
            set_store_char(store_status_data, 11, "u");
            set_store_char(store_status_data, 12, "a");
            set_store_char(store_status_data, 13, "l");
            set_store_char(store_status_data, 14, " ");
            set_store_char(store_status_data, 15, "b");
            set_store_char(store_status_data, 16, "r");
            set_store_char(store_status_data, 17, "o");
            set_store_char(store_status_data, 18, "w");
            set_store_char(store_status_data, 19, "s");
            set_store_char(store_status_data, 20, "e");
            store_status_len = 5'd21;
        end else if (selected_component_store_ready_ui) begin
            set_store_char(store_status_data, 8, "f");
            set_store_char(store_status_data, 9, "o");
            set_store_char(store_status_data, 10, "l");
            set_store_char(store_status_data, 11, "l");
            set_store_char(store_status_data, 12, "o");
            set_store_char(store_status_data, 13, "w");
            set_store_char(store_status_data, 14, " ");
            set_store_char(store_status_data, 15, "s");
            set_store_char(store_status_data, 16, "e");
            set_store_char(store_status_data, 17, "l");
            set_store_char(store_status_data, 18, "e");
            set_store_char(store_status_data, 19, "c");
            set_store_char(store_status_data, 20, "t");
            set_store_char(store_status_data, 21, "i");
            set_store_char(store_status_data, 22, "o");
            set_store_char(store_status_data, 23, "n");
            store_status_len = 5'd24;
        end else begin
            set_store_char(store_status_data, 8, "e");
            set_store_char(store_status_data, 9, "n");
            set_store_char(store_status_data, 10, "t");
            set_store_char(store_status_data, 11, "r");
            set_store_char(store_status_data, 12, "y");
            set_store_char(store_status_data, 13, " ");
            set_store_char(store_status_data, 14, "r");
            set_store_char(store_status_data, 15, "e");
            set_store_char(store_status_data, 16, "a");
            set_store_char(store_status_data, 17, "d");
            set_store_char(store_status_data, 18, "y");
            store_status_len = 5'd19;
        end

        set_store_char(store_count_data, 0, "C");
        set_store_char(store_count_data, 1, "o");
        set_store_char(store_count_data, 2, "u");
        set_store_char(store_count_data, 3, "n");
        set_store_char(store_count_data, 4, "t");
        set_store_char(store_count_data, 5, " ");
        set_store_char(store_count_data, 6, ":");
        set_store_char(store_count_data, 7, " ");
        if (component_store_busy_ui) begin
            set_store_char(store_count_data, 8, "-");
            set_store_char(store_count_data, 9, "-");
            set_store_char(store_count_data, 10, "-");
        end else begin
            set_store_char(store_count_data, 8, (component_store_count_ui / 100) + 8'd48);
            set_store_char(store_count_data, 9, ((component_store_count_ui % 100) / 10) + 8'd48);
            set_store_char(store_count_data, 10, (component_store_count_ui % 10) + 8'd48);
        end
        store_count_len = 5'd11;

        set_store_char(store_packed_data, 0, "P");
        set_store_char(store_packed_data, 1, "a");
        set_store_char(store_packed_data, 2, "c");
        set_store_char(store_packed_data, 3, "k");
        set_store_char(store_packed_data, 4, "e");
        set_store_char(store_packed_data, 5, "d");
        set_store_char(store_packed_data, 6, ":");
        set_store_char(store_packed_data, 7, " ");
        if (component_store_view_entry_ready_ui) begin
            set_store_char(store_packed_data, 8, "0");
            set_store_char(store_packed_data, 9, "x");
            set_store_char(store_packed_data, 10, ascii_hex_nibble(component_store_display_entry_ui[39:36]));
            set_store_char(store_packed_data, 11, ascii_hex_nibble(component_store_display_entry_ui[35:32]));
            set_store_char(store_packed_data, 12, ascii_hex_nibble(component_store_display_entry_ui[31:28]));
            set_store_char(store_packed_data, 13, ascii_hex_nibble(component_store_display_entry_ui[27:24]));
            set_store_char(store_packed_data, 14, ascii_hex_nibble(component_store_display_entry_ui[23:20]));
            set_store_char(store_packed_data, 15, ascii_hex_nibble(component_store_display_entry_ui[19:16]));
            set_store_char(store_packed_data, 16, ascii_hex_nibble(component_store_display_entry_ui[15:12]));
            set_store_char(store_packed_data, 17, ascii_hex_nibble(component_store_display_entry_ui[11:8]));
            set_store_char(store_packed_data, 18, ascii_hex_nibble(component_store_display_entry_ui[7:4]));
            set_store_char(store_packed_data, 19, ascii_hex_nibble(component_store_display_entry_ui[3:0]));
            store_packed_len = 5'd20;
        end else begin
            set_store_char(store_packed_data, 8, "-");
            set_store_char(store_packed_data, 9, "-");
            set_store_char(store_packed_data, 10, "-");
            set_store_char(store_packed_data, 11, "-");
            set_store_char(store_packed_data, 12, "-");
            set_store_char(store_packed_data, 13, "-");
            set_store_char(store_packed_data, 14, "-");
            set_store_char(store_packed_data, 15, "-");
            set_store_char(store_packed_data, 16, "-");
            set_store_char(store_packed_data, 17, "-");
            store_packed_len = 5'd18;
        end

        set_store_char(store_index_data, 0, "I");
        set_store_char(store_index_data, 1, "n");
        set_store_char(store_index_data, 2, "d");
        set_store_char(store_index_data, 3, "e");
        set_store_char(store_index_data, 4, "x");
        set_store_char(store_index_data, 5, " ");
        set_store_char(store_index_data, 6, ":");
        set_store_char(store_index_data, 7, " ");
        if (component_store_view_entry_ready_ui) begin
            set_store_char(store_index_data, 8, (component_store_view_entry_index_ui / 100) + 8'd48);
            set_store_char(store_index_data, 9, ((component_store_view_entry_index_ui % 100) / 10) + 8'd48);
            set_store_char(store_index_data, 10, (component_store_view_entry_index_ui % 10) + 8'd48);
        end else begin
            set_store_char(store_index_data, 8, "-");
            set_store_char(store_index_data, 9, "-");
            set_store_char(store_index_data, 10, "-");
        end
        store_index_len = 5'd11;

        set_store_char(store_type_data, 0, "T");
        set_store_char(store_type_data, 1, "y");
        set_store_char(store_type_data, 2, "p");
        set_store_char(store_type_data, 3, "e");
        set_store_char(store_type_data, 4, " ");
        set_store_char(store_type_data, 5, " ");
        set_store_char(store_type_data, 6, ":");
        set_store_char(store_type_data, 7, " ");
        if (component_store_view_entry_ready_ui) begin
            case (component_store_view_type_ui)
                COMPONENT_TYPE_GROUND: begin
                    set_store_char(store_type_data, 8, "G");
                    set_store_char(store_type_data, 9, "R");
                    set_store_char(store_type_data, 10, "O");
                    set_store_char(store_type_data, 11, "U");
                    set_store_char(store_type_data, 12, "N");
                    set_store_char(store_type_data, 13, "D");
                    store_type_len = 5'd14;
                end
                COMPONENT_TYPE_RESISTOR: begin
                    set_store_char(store_type_data, 8, "R");
                    set_store_char(store_type_data, 9, "E");
                    set_store_char(store_type_data, 10, "S");
                    set_store_char(store_type_data, 11, "I");
                    set_store_char(store_type_data, 12, "S");
                    set_store_char(store_type_data, 13, "T");
                    set_store_char(store_type_data, 14, "O");
                    set_store_char(store_type_data, 15, "R");
                    store_type_len = 5'd16;
                end
                COMPONENT_TYPE_CAPACITOR: begin
                    set_store_char(store_type_data, 8, "C");
                    set_store_char(store_type_data, 9, "A");
                    set_store_char(store_type_data, 10, "P");
                    set_store_char(store_type_data, 11, "A");
                    set_store_char(store_type_data, 12, "C");
                    set_store_char(store_type_data, 13, "I");
                    set_store_char(store_type_data, 14, "T");
                    set_store_char(store_type_data, 15, "O");
                    set_store_char(store_type_data, 16, "R");
                    store_type_len = 5'd17;
                end
                COMPONENT_TYPE_INDUCTOR: begin
                    set_store_char(store_type_data, 8, "I");
                    set_store_char(store_type_data, 9, "N");
                    set_store_char(store_type_data, 10, "D");
                    set_store_char(store_type_data, 11, "U");
                    set_store_char(store_type_data, 12, "C");
                    set_store_char(store_type_data, 13, "T");
                    set_store_char(store_type_data, 14, "O");
                    set_store_char(store_type_data, 15, "R");
                    store_type_len = 5'd16;
                end
                COMPONENT_TYPE_VOLTAGE: begin
                    set_store_char(store_type_data, 8, "V");
                    set_store_char(store_type_data, 9, "O");
                    set_store_char(store_type_data, 10, "L");
                    set_store_char(store_type_data, 11, "T");
                    set_store_char(store_type_data, 12, "A");
                    set_store_char(store_type_data, 13, "G");
                    set_store_char(store_type_data, 14, "E");
                    store_type_len = 5'd15;
                end
                COMPONENT_TYPE_CURRENT: begin
                    set_store_char(store_type_data, 8, "C");
                    set_store_char(store_type_data, 9, "U");
                    set_store_char(store_type_data, 10, "R");
                    set_store_char(store_type_data, 11, "R");
                    set_store_char(store_type_data, 12, "E");
                    set_store_char(store_type_data, 13, "N");
                    set_store_char(store_type_data, 14, "T");
                    store_type_len = 5'd15;
                end
                default: begin
                    set_store_char(store_type_data, 8, "W");
                    set_store_char(store_type_data, 9, "I");
                    set_store_char(store_type_data, 10, "R");
                    set_store_char(store_type_data, 11, "E");
                    store_type_len = 5'd12;
                end
            endcase
        end else begin
            set_store_char(store_type_data, 8, "-");
            store_type_len = 5'd9;
        end

        set_store_char(store_rot_data, 0, "R");
        set_store_char(store_rot_data, 1, "o");
        set_store_char(store_rot_data, 2, "t");
        set_store_char(store_rot_data, 3, " ");
        set_store_char(store_rot_data, 4, " ");
        set_store_char(store_rot_data, 5, " ");
        set_store_char(store_rot_data, 6, ":");
        set_store_char(store_rot_data, 7, " ");
        if (component_store_view_entry_ready_ui) begin
            set_store_char(store_rot_data, 8, component_store_view_rotation_ui + 8'd48);
        end else begin
            set_store_char(store_rot_data, 8, "-");
        end
        store_rot_len = 5'd9;

        set_store_char(store_value_data, 0, "V");
        set_store_char(store_value_data, 1, "a");
        set_store_char(store_value_data, 2, "l");
        set_store_char(store_value_data, 3, "u");
        set_store_char(store_value_data, 4, "e");
        set_store_char(store_value_data, 5, " ");
        set_store_char(store_value_data, 6, ":");
        set_store_char(store_value_data, 7, " ");
        if (component_store_view_entry_ready_ui) begin
            if (component_store_view_value_ui[11:8] != 4'd0) begin
                set_store_char(store_value_data, 8, ascii_decimal_nibble(component_store_view_value_ui[11:8]));
                set_store_char(store_value_data, 9, ascii_decimal_nibble(component_store_view_value_ui[7:4]));
                set_store_char(store_value_data, 10, ascii_decimal_nibble(component_store_view_value_ui[3:0]));
                store_value_len = 5'd11;
            end else if (component_store_view_value_ui[7:4] != 4'd0) begin
                set_store_char(store_value_data, 8, ascii_decimal_nibble(component_store_view_value_ui[7:4]));
                set_store_char(store_value_data, 9, ascii_decimal_nibble(component_store_view_value_ui[3:0]));
                store_value_len = 5'd10;
            end else begin
                set_store_char(store_value_data, 8, ascii_decimal_nibble(component_store_view_value_ui[3:0]));
                store_value_len = 5'd9;
            end
            if (component_store_view_unit_ui != COMPONENT_UNIT_NONE) begin
                set_store_char(store_value_data, store_value_len, ascii_from_component_unit(component_store_view_unit_ui));
                store_value_len = store_value_len + 1'b1;
            end
        end else begin
            set_store_char(store_value_data, 8, "-");
            store_value_len = 5'd9;
        end

        set_store_char(store_raw_data, 0, "R");
        set_store_char(store_raw_data, 1, "a");
        set_store_char(store_raw_data, 2, "w");
        set_store_char(store_raw_data, 3, " ");
        set_store_char(store_raw_data, 4, " ");
        set_store_char(store_raw_data, 5, " ");
        set_store_char(store_raw_data, 6, ":");
        set_store_char(store_raw_data, 7, " ");
        set_store_char(store_raw_data, 8, "0");
        set_store_char(store_raw_data, 9, "x");
        if (component_store_view_entry_ready_ui) begin
            set_store_char(store_raw_data, 10, ascii_hex_nibble(component_store_view_value_ui[11:8]));
            set_store_char(store_raw_data, 11, ascii_hex_nibble(component_store_view_value_ui[7:4]));
            set_store_char(store_raw_data, 12, ascii_hex_nibble(component_store_view_value_ui[3:0]));
        end else begin
            set_store_char(store_raw_data, 10, "-");
            set_store_char(store_raw_data, 11, "-");
            set_store_char(store_raw_data, 12, "-");
        end
        store_raw_len = 5'd13;

        set_store_char(store_pos_data, 0, "P");
        set_store_char(store_pos_data, 1, "o");
        set_store_char(store_pos_data, 2, "s");
        set_store_char(store_pos_data, 3, " ");
        set_store_char(store_pos_data, 4, " ");
        set_store_char(store_pos_data, 5, " ");
        set_store_char(store_pos_data, 6, ":");
        set_store_char(store_pos_data, 7, " ");
        if (component_store_view_entry_ready_ui) begin
            set_store_char(store_pos_data, 8, "(");
            set_store_char(store_pos_data, 9, (component_store_view_position_ui[4:0] / 10) + 8'd48);
            set_store_char(store_pos_data, 10, (component_store_view_position_ui[4:0] % 10) + 8'd48);
            set_store_char(store_pos_data, 11, ",");
            set_store_char(store_pos_data, 12, " ");
            set_store_char(store_pos_data, 13, (component_store_view_position_ui[8:5] / 10) + 8'd48);
            set_store_char(store_pos_data, 14, (component_store_view_position_ui[8:5] % 10) + 8'd48);
            set_store_char(store_pos_data, 15, ")");
        end else begin
            set_store_char(store_pos_data, 8, "(");
            set_store_char(store_pos_data, 9, "-");
            set_store_char(store_pos_data, 10, "-");
            set_store_char(store_pos_data, 11, ",");
            set_store_char(store_pos_data, 12, " ");
            set_store_char(store_pos_data, 13, "-");
            set_store_char(store_pos_data, 14, "-");
            set_store_char(store_pos_data, 15, ")");
        end
        store_pos_len = 5'd16;
    end

    TextBox #(
        .TEXT_CONTENT("COMPONENT STORE"),
        .TEXT_LEN(15),
        .MAX_CHARS(STORE_VIEW_TEXT_MAX_CHARS)
    ) u_store_title (
        .clk_pixel(clk_pixel),
        .hcount(x_pos),
        .vcount(y_pos),
        .start_x(STORE_VIEW_TEXT_X),
        .start_y(STORE_VIEW_TITLE_Y),
        .scale(4'd2),
        .text_enable(store_title_rendered),
        .text_color(store_title_rgb)
    );

    TextBox #(
        .TEXT_CONTENT("SW1 VIEW  L/R BROWSE"),
        .TEXT_LEN(20),
        .MAX_CHARS(STORE_VIEW_TEXT_MAX_CHARS)
    ) u_store_hint (
        .clk_pixel(clk_pixel),
        .hcount(x_pos),
        .vcount(y_pos),
        .start_x(STORE_VIEW_TEXT_X),
        .start_y(STORE_VIEW_HINT_Y),
        .scale(4'd1),
        .text_enable(store_hint_rendered),
        .text_color(store_hint_rgb)
    );

    DynamicTextBox #(.MAX_CHARS(STORE_VIEW_TEXT_MAX_CHARS)) u_store_status (
        .clk_pixel(clk_pixel),
        .hcount(x_pos),
        .vcount(y_pos),
        .text_data(store_status_data),
        .text_len(store_status_len),
        .start_x(STORE_VIEW_TEXT_X),
        .start_y(STORE_VIEW_STATUS_Y),
        .scale(4'd1),
        .text_enable(store_status_rendered),
        .text_color(store_status_rgb)
    );

    DynamicTextBox #(.MAX_CHARS(STORE_VIEW_TEXT_MAX_CHARS)) u_store_count (
        .clk_pixel(clk_pixel),
        .hcount(x_pos),
        .vcount(y_pos),
        .text_data(store_count_data),
        .text_len(store_count_len),
        .start_x(STORE_VIEW_TEXT_X),
        .start_y(STORE_VIEW_COUNT_Y),
        .scale(4'd1),
        .text_enable(store_count_rendered),
        .text_color(store_count_rgb)
    );

    DynamicTextBox #(.MAX_CHARS(STORE_VIEW_TEXT_MAX_CHARS)) u_store_packed (
        .clk_pixel(clk_pixel),
        .hcount(x_pos),
        .vcount(y_pos),
        .text_data(store_packed_data),
        .text_len(store_packed_len),
        .start_x(STORE_VIEW_TEXT_X),
        .start_y(STORE_VIEW_PACKED_Y),
        .scale(4'd1),
        .text_enable(store_packed_rendered),
        .text_color(store_packed_rgb)
    );

    DynamicTextBox #(.MAX_CHARS(STORE_VIEW_TEXT_MAX_CHARS)) u_store_index (
        .clk_pixel(clk_pixel),
        .hcount(x_pos),
        .vcount(y_pos),
        .text_data(store_index_data),
        .text_len(store_index_len),
        .start_x(STORE_VIEW_TEXT_X),
        .start_y(STORE_VIEW_INDEX_Y),
        .scale(4'd1),
        .text_enable(store_index_rendered),
        .text_color(store_index_rgb)
    );

    DynamicTextBox #(.MAX_CHARS(STORE_VIEW_TEXT_MAX_CHARS)) u_store_type (
        .clk_pixel(clk_pixel),
        .hcount(x_pos),
        .vcount(y_pos),
        .text_data(store_type_data),
        .text_len(store_type_len),
        .start_x(STORE_VIEW_TEXT_X),
        .start_y(STORE_VIEW_TYPE_Y),
        .scale(4'd1),
        .text_enable(store_type_rendered),
        .text_color(store_type_rgb)
    );

    DynamicTextBox #(.MAX_CHARS(STORE_VIEW_TEXT_MAX_CHARS)) u_store_rot (
        .clk_pixel(clk_pixel),
        .hcount(x_pos),
        .vcount(y_pos),
        .text_data(store_rot_data),
        .text_len(store_rot_len),
        .start_x(STORE_VIEW_TEXT_X),
        .start_y(STORE_VIEW_ROT_Y),
        .scale(4'd1),
        .text_enable(store_rot_rendered),
        .text_color(store_rot_rgb)
    );

    DynamicTextBox #(.MAX_CHARS(STORE_VIEW_TEXT_MAX_CHARS)) u_store_value (
        .clk_pixel(clk_pixel),
        .hcount(x_pos),
        .vcount(y_pos),
        .text_data(store_value_data),
        .text_len(store_value_len),
        .start_x(STORE_VIEW_TEXT_X),
        .start_y(STORE_VIEW_VALUE_Y),
        .scale(4'd1),
        .text_enable(store_value_rendered),
        .text_color(store_value_rgb)
    );

    DynamicTextBox #(.MAX_CHARS(STORE_VIEW_TEXT_MAX_CHARS)) u_store_raw (
        .clk_pixel(clk_pixel),
        .hcount(x_pos),
        .vcount(y_pos),
        .text_data(store_raw_data),
        .text_len(store_raw_len),
        .start_x(STORE_VIEW_TEXT_X),
        .start_y(STORE_VIEW_RAW_Y),
        .scale(4'd1),
        .text_enable(store_raw_rendered),
        .text_color(store_raw_rgb)
    );

    DynamicTextBox #(.MAX_CHARS(STORE_VIEW_TEXT_MAX_CHARS)) u_store_pos (
        .clk_pixel(clk_pixel),
        .hcount(x_pos),
        .vcount(y_pos),
        .text_data(store_pos_data),
        .text_len(store_pos_len),
        .start_x(STORE_VIEW_TEXT_X),
        .start_y(STORE_VIEW_POS_Y),
        .scale(4'd1),
        .text_enable(store_pos_rendered),
        .text_color(store_pos_rgb)
    );

    always @(*) begin
        component_store_view_rendered = video_on;
        component_store_view_rgb = 12'h132;

        if ((x_pos >= STORE_VIEW_CARD_X0) && (x_pos < STORE_VIEW_CARD_X1) &&
            (y_pos >= STORE_VIEW_CARD_Y0) && (y_pos < STORE_VIEW_CARD_Y1)) begin
            component_store_view_rgb = 12'h254;
            if ((x_pos < STORE_VIEW_CARD_X0 + 3) || (x_pos >= STORE_VIEW_CARD_X1 - 3) ||
                (y_pos < STORE_VIEW_CARD_Y0 + 3) || (y_pos >= STORE_VIEW_CARD_Y1 - 3)) begin
                component_store_view_rgb = 12'hFC9;
            end else if (y_pos < STORE_VIEW_CARD_Y0 + 48) begin
                component_store_view_rgb = 12'h365;
            end else if ((y_pos == STORE_VIEW_COUNT_Y - 12) || (y_pos == STORE_VIEW_PACKED_Y - 12)) begin
                component_store_view_rgb = 12'h486;
            end
        end

        if (store_title_rendered) component_store_view_rgb = store_title_rgb;
        if (store_hint_rendered) component_store_view_rgb = store_hint_rgb;
        if (store_status_rendered) component_store_view_rgb = store_status_rgb;
        if (store_count_rendered) component_store_view_rgb = store_count_rgb;
        if (store_packed_rendered) component_store_view_rgb = store_packed_rgb;
        if (store_index_rendered) component_store_view_rgb = store_index_rgb;
        if (store_type_rendered) component_store_view_rgb = store_type_rgb;
        if (store_rot_rendered) component_store_view_rgb = store_rot_rgb;
        if (store_value_rendered) component_store_view_rgb = store_value_rgb;
        if (store_raw_rendered) component_store_view_rgb = store_raw_rgb;
        if (store_pos_rendered) component_store_view_rgb = store_pos_rgb;
    end

    assign interaction_bg_cmd_ready = (init_cycles >= INIT_DELAY_CYCLES) && !clear_canvas_active;

    InteractionController #(
        .CanvasPosX(CANVAS_X0),
        .CanvasPosY(CANVAS_Y0),
        .CanvasWidth(CANVAS_W),
        .CanvasHeight(CANVAS_H),
        .CellSize(CANVAS_CELL_SIZE),
        .GridWidth(CANVAS_GRID_W),
        .GridHeight(CANVAS_GRID_H),
        .RotateFramesPerStep(8),
        .AddrWidth(CANVAS_ADDR_W),
        .DataWidth(16)
    ) interaction_controller_inst (
        .clk(CLK100MHZ),
        .reset(BTNC),
        .frame_start_pulse(interaction_frame_tick && (selected_toolbar_idx_sys != 4'd0)),
        .mode_select(interaction_mode_select),
        .mouse_x(mouse_xpos),
        .mouse_y(mouse_ypos),
        .mouse_left(mouse_left),
        .mouse_middle(mouse_middle),
        .mouse_right(mouse_right),
        .grid_pos_x(circuit_canvas_grid_pos_x_sys),
        .grid_pos_y(circuit_canvas_grid_pos_y_sys),
        .bg_cmd_ready(interaction_bg_cmd_ready),
        .bg_rsp_valid(interaction_bg_rsp_valid),
        .bg_rsp_rdata(interaction_bg_rsp_rdata),
        .bg_cmd_valid(interaction_bg_cmd_valid),
        .bg_cmd_write(interaction_bg_cmd_write),
        .bg_cmd_addr(interaction_bg_cmd_addr),
        .bg_cmd_wdata(interaction_bg_cmd_wdata),
        .frame_done(interaction_frame_done),
        .frame_drop_flag(interaction_frame_drop_flag)
    );

    wire        matrix_rendered;
    wire [11:0] matrix_rgb;
    localparam [1023:0] MATRIX_A_CONST = {
        16'h8000, 16'h0240, 16'h0000, 16'h0000, 16'h0000, 16'h0000, 16'h0000, 16'h0000,
        16'h0240, 16'hEC40, 16'h0380, 16'h0000, 16'h0000, 16'h0000, 16'h0000, 16'h0000,
        16'h0000, 16'h0380, 16'h1E1A, 16'h04CC, 16'h0000, 16'h0000, 16'h0000, 16'h0000,
        16'h0000, 16'h0000, 16'h04CC, 16'h2840, 16'h05E6, 16'h0000, 16'h0000, 16'h0000,
        16'h0000, 16'h0000, 16'h0000, 16'h05E6, 16'hCD67, 16'h06B3, 16'h0000, 16'h0000,
        16'h0000, 16'h0000, 16'h0000, 16'h0000, 16'h06B3, 16'h3CCD, 16'h0766, 16'h0000,
        16'h0000, 16'h0000, 16'h0000, 16'h0000, 16'h0000, 16'h0766, 16'hB91A, 16'h081A,
        16'h0000, 16'h0000, 16'h0000, 16'h0000, 16'h0000, 16'h0000, 16'h081A, 16'h63FD
    };
    localparam [1023:0] MATRIX_LU_CONST = {
        16'h0100, 16'h0080, 16'h0040, 16'h001A, 16'h000C, 16'h0005, 16'h0002, 16'h0000,
        16'h0200, 16'h0180, 16'h00C0, 16'h004C, 16'h0026, 16'h0014, 16'h000A, 16'h0005,
        16'h0300, 16'h0280, 16'h0200, 16'h0100, 16'h0080, 16'h0040, 16'h001F, 16'h000F,
        16'h0400, 16'h0380, 16'h0300, 16'h0280, 16'h0140, 16'h0099, 16'h004C, 16'h0026,
        16'h0500, 16'h0480, 16'h0400, 16'h0380, 16'h0300, 16'h0180, 16'h00C0, 16'h0059,
        16'h0600, 16'h0580, 16'h0500, 16'h0480, 16'h0400, 16'h0380, 16'h01C0, 16'h00D9,
        16'h0700, 16'h0680, 16'h0600, 16'h0580, 16'h0500, 16'h0480, 16'h0400, 16'h0200,
        16'h0800, 16'h0780, 16'h0700, 16'h0680, 16'h0600, 16'h0580, 16'h0500, 16'h0480
    };
    reg  [1023:0] matrix_a_data;    // 8x8 Q8.8 定点数矩阵
    reg  [1023:0] matrix_lu_data;   // 8x8 Q8.8 定点数矩阵

    // 开关控制：SW[0]=0 显示电路，SW[0]=1 显示矩阵
    assign backend_fetch_test_enable = SW[2];

    // 初始化示例矩阵数据 (8x8 矩阵，Q8.8 定点数)
    // 数据排列：[0][0] 在 [1023:1008], [0][1] 在 [1007:992], ..., [7][7] 在 [15:0]
    // index = row * 8 + col, 位范围 = (63 - index) * 16 +: 16
    always @(posedge clk_pixel) begin
        // A 矩阵 - 三对角测试矩阵 (带小数和负数)
        // [-128.00,   2.25,   0,     0,     0,     0,     0,     0   ]
        // [  2.25,  -20.75,  3.50,  0,     0,     0,     0,     0   ]
        // [  0,      3.50,  30.10,  4.80,  0,     0,     0,     0   ]
        // [  0,      0,      4.80, 40.25,  5.90,  0,     0,     0   ]
        // [  0,      0,      0,     5.90,-50.60,  6.70,  0,     0   ]
        // [  0,      0,      0,     0,     6.70, 60.80,  7.40,  0   ]
        // [  0,      0,      0,     0,     0,     7.40,-70.90,  8.10]
        // [  0,      0,      0,     0,     0,     0,     8.10, 99.99]
        matrix_a_data <= 1024'd0;
        // Q8.8 格式：负数使用符号位 (bit 15)
        // -128.00 = 0x8000 (1000 0000 0000 0000)
        // -20.75  = 0xEC40 (1110 1100 0100 0000)
        // -50.60  = 0xCD67 (1100 1101 0110 0111)
        // -70.90  = 0xB91A (1011 1001 0001 1010)
        // 99.99   = 0x63FD (0110 0011 1111 1101)
        
        // 第 0 行 (index 0-7)
        matrix_a_data[1023:1008] <= 16'h8000;  // A[0][0] = -128.00
        matrix_a_data[1007:992]  <= 16'h0240;  // A[0][1] = 2.25
        matrix_a_data[991:976]   <= 16'h0000;  // A[0][2] = 0.00
        matrix_a_data[975:960]   <= 16'h0000;  // A[0][3] = 0.00
        matrix_a_data[959:944]   <= 16'h0000;  // A[0][4] = 0.00
        matrix_a_data[943:928]   <= 16'h0000;  // A[0][5] = 0.00
        matrix_a_data[927:912]   <= 16'h0000;  // A[0][6] = 0.00
        matrix_a_data[911:896]   <= 16'h0000;  // A[0][7] = 0.00
        // 第 1 行 (index 8-15)
        matrix_a_data[895:880]   <= 16'h0240;  // A[1][0] = 2.25
        matrix_a_data[879:864]   <= 16'hEC40;  // A[1][1] = -20.75
        matrix_a_data[863:848]   <= 16'h0380;  // A[1][2] = 3.50
        matrix_a_data[847:832]   <= 16'h0000;  // A[1][3] = 0.00
        matrix_a_data[831:816]   <= 16'h0000;  // A[1][4] = 0.00
        matrix_a_data[815:800]   <= 16'h0000;  // A[1][5] = 0.00
        matrix_a_data[799:784]   <= 16'h0000;  // A[1][6] = 0.00
        matrix_a_data[783:768]   <= 16'h0000;  // A[1][7] = 0.00
        // 第 2 行 (index 16-23)
        matrix_a_data[767:752]   <= 16'h0000;  // A[2][0] = 0.00
        matrix_a_data[751:736]   <= 16'h0380;  // A[2][1] = 3.50
        matrix_a_data[735:720]   <= 16'h1E1A;  // A[2][2] = 30.10
        matrix_a_data[719:704]   <= 16'h04CC;  // A[2][3] = 4.80
        matrix_a_data[703:688]   <= 16'h0000;  // A[2][4] = 0.00
        matrix_a_data[687:672]   <= 16'h0000;  // A[2][5] = 0.00
        matrix_a_data[671:656]   <= 16'h0000;  // A[2][6] = 0.00
        matrix_a_data[655:640]   <= 16'h0000;  // A[2][7] = 0.00
        // 第 3 行 (index 24-31)
        matrix_a_data[639:624]   <= 16'h0000;  // A[3][0] = 0.00
        matrix_a_data[623:608]   <= 16'h0000;  // A[3][1] = 0.00
        matrix_a_data[607:592]   <= 16'h04CC;  // A[3][2] = 4.80
        matrix_a_data[591:576]   <= 16'h2840;  // A[3][3] = 40.25
        matrix_a_data[575:560]   <= 16'h05E6;  // A[3][4] = 5.90
        matrix_a_data[559:544]   <= 16'h0000;  // A[3][5] = 0.00
        matrix_a_data[543:528]   <= 16'h0000;  // A[3][6] = 0.00
        matrix_a_data[527:512]   <= 16'h0000;  // A[3][7] = 0.00
        // 第 4 行 (index 32-39)
        matrix_a_data[511:496]   <= 16'h0000;  // A[4][0] = 0.00
        matrix_a_data[495:480]   <= 16'h0000;  // A[4][1] = 0.00
        matrix_a_data[479:464]   <= 16'h0000;  // A[4][2] = 0.00
        matrix_a_data[463:448]   <= 16'h05E6;  // A[4][3] = 5.90
        matrix_a_data[447:432]   <= 16'hCD67;  // A[4][4] = -50.60
        matrix_a_data[431:416]   <= 16'h06B3;  // A[4][5] = 6.70
        matrix_a_data[415:400]   <= 16'h0000;  // A[4][6] = 0.00
        matrix_a_data[399:384]   <= 16'h0000;  // A[4][7] = 0.00
        // 第 5 行 (index 40-47)
        matrix_a_data[383:368]   <= 16'h0000;  // A[5][0] = 0.00
        matrix_a_data[367:352]   <= 16'h0000;  // A[5][1] = 0.00
        matrix_a_data[351:336]   <= 16'h0000;  // A[5][2] = 0.00
        matrix_a_data[335:320]   <= 16'h0000;  // A[5][3] = 0.00
        matrix_a_data[319:304]   <= 16'h06B3;  // A[5][4] = 6.70
        matrix_a_data[303:288]   <= 16'h3CCD;  // A[5][5] = 60.80
        matrix_a_data[287:272]   <= 16'h0766;  // A[5][6] = 7.40
        matrix_a_data[271:256]   <= 16'h0000;  // A[5][7] = 0.00
        // 第 6 行 (index 48-55)
        matrix_a_data[255:240]   <= 16'h0000;  // A[6][0] = 0.00
        matrix_a_data[239:224]   <= 16'h0000;  // A[6][1] = 0.00
        matrix_a_data[223:208]   <= 16'h0000;  // A[6][2] = 0.00
        matrix_a_data[207:192]   <= 16'h0000;  // A[6][3] = 0.00
        matrix_a_data[191:176]   <= 16'h0000;  // A[6][4] = 0.00
        matrix_a_data[175:160]   <= 16'h0766;  // A[6][5] = 7.40
        matrix_a_data[159:144]   <= 16'hB91A;  // A[6][6] = -70.90
        matrix_a_data[143:128]   <= 16'h081A;  // A[6][7] = 8.10
        // 第 7 行 (index 56-63)
        matrix_a_data[127:112]   <= 16'h0000;  // A[7][0] = 0.00
        matrix_a_data[111:96]    <= 16'h0000;  // A[7][1] = 0.00
        matrix_a_data[95:80]     <= 16'h0000;  // A[7][2] = 0.00
        matrix_a_data[79:64]     <= 16'h0000;  // A[7][3] = 0.00
        matrix_a_data[63:48]     <= 16'h0000;  // A[7][4] = 0.00
        matrix_a_data[47:32]     <= 16'h0000;  // A[7][5] = 0.00
        matrix_a_data[31:16]     <= 16'h081A;  // A[7][6] = 8.10
        matrix_a_data[15:0]      <= 16'h63FD;  // A[7][7] = 99.99

        // LU 矩阵 - LU 分解示例 (带小数，含负数测试)
        // [  1.00,  0.50,  0.25,  0.10,  0.05,  0.02,  0.01,  0.00]
        // [  2.00,  1.50,  0.75,  0.30,  0.15,  0.08,  0.04,  0.02]
        // [  3.00,  2.50,  2.00,  1.00,  0.50,  0.25,  0.12,  0.06]
        // [  4.00,  3.50,  3.00,  2.50,  1.25,  0.60,  0.30,  0.15]
        // [  5.00,  4.50,  4.00,  3.50,  3.00,  1.50,  0.75,  0.35]
        // [  6.00,  5.50,  5.00,  4.50,  4.00,  3.50,  1.75,  0.85]
        // [  7.00,  6.50,  6.00,  5.50,  5.00,  4.50,  4.00,  2.00]
        // [  8.00,  7.50,  7.00,  6.50,  6.00,  5.50,  5.00,  4.50]
        matrix_lu_data <= 1024'd0;
        // 第 0 行
        matrix_lu_data[1023:1008] <= 16'h0100;  // 1.00
        matrix_lu_data[1007:992]  <= 16'h0080;  // 0.50
        matrix_lu_data[991:976]   <= 16'h0040;  // 0.25
        matrix_lu_data[975:960]   <= 16'h001A;  // 0.10
        matrix_lu_data[959:944]   <= 16'h000C;  // 0.05
        matrix_lu_data[943:928]   <= 16'h0005;  // 0.02
        matrix_lu_data[927:912]   <= 16'h0002;  // 0.01
        matrix_lu_data[911:896]   <= 16'h0000;  // 0.00
        // 第 1 行
        matrix_lu_data[895:880]   <= 16'h0200;  // 2.00
        matrix_lu_data[879:864]   <= 16'h0180;  // 1.50
        matrix_lu_data[863:848]   <= 16'h00C0;  // 0.75
        matrix_lu_data[847:832]   <= 16'h004C;  // 0.30
        matrix_lu_data[831:816]   <= 16'h0026;  // 0.15
        matrix_lu_data[815:800]   <= 16'h0014;  // 0.08
        matrix_lu_data[799:784]   <= 16'h000A;  // 0.04
        matrix_lu_data[783:768]   <= 16'h0005;  // 0.02
        // 第 2 行
        matrix_lu_data[767:752]   <= 16'h0300;  // 3.00
        matrix_lu_data[751:736]   <= 16'h0280;  // 2.50
        matrix_lu_data[735:720]   <= 16'h0200;  // 2.00
        matrix_lu_data[719:704]   <= 16'h0100;  // 1.00
        matrix_lu_data[703:688]   <= 16'h0080;  // 0.50
        matrix_lu_data[687:672]   <= 16'h0040;  // 0.25
        matrix_lu_data[671:656]   <= 16'h001F;  // 0.12
        matrix_lu_data[655:640]   <= 16'h000F;  // 0.06
        // 第 3 行
        matrix_lu_data[639:624]   <= 16'h0400;  // 4.00
        matrix_lu_data[623:608]   <= 16'h0380;  // 3.50
        matrix_lu_data[607:592]   <= 16'h0300;  // 3.00
        matrix_lu_data[591:576]   <= 16'h0280;  // 2.50
        matrix_lu_data[575:560]   <= 16'h0140;  // 1.25
        matrix_lu_data[559:544]   <= 16'h0099;  // 0.60
        matrix_lu_data[543:528]   <= 16'h004C;  // 0.30
        matrix_lu_data[527:512]   <= 16'h0026;  // 0.15
        // 第 4 行
        matrix_lu_data[511:496]   <= 16'h0500;  // 5.00
        matrix_lu_data[495:480]   <= 16'h0480;  // 4.50
        matrix_lu_data[479:464]   <= 16'h0400;  // 4.00
        matrix_lu_data[463:448]   <= 16'h0380;  // 3.50
        matrix_lu_data[447:432]   <= 16'h0300;  // 3.00
        matrix_lu_data[431:416]   <= 16'h0180;  // 1.50
        matrix_lu_data[415:400]   <= 16'h00C0;  // 0.75
        matrix_lu_data[399:384]   <= 16'h0059;  // 0.35
        // 第 5 行
        matrix_lu_data[383:368]   <= 16'h0600;  // 6.00
        matrix_lu_data[367:352]   <= 16'h0580;  // 5.50
        matrix_lu_data[351:336]   <= 16'h0500;  // 5.00
        matrix_lu_data[335:320]   <= 16'h0480;  // 4.50
        matrix_lu_data[319:304]   <= 16'h0400;  // 4.00
        matrix_lu_data[303:288]   <= 16'h0380;  // 3.50
        matrix_lu_data[287:272]   <= 16'h01C0;  // 1.75
        matrix_lu_data[271:256]   <= 16'h00D9;  // 0.85
        // 第 6 行
        matrix_lu_data[255:240]   <= 16'h0700;  // 7.00
        matrix_lu_data[239:224]   <= 16'h0680;  // 6.50
        matrix_lu_data[223:208]   <= 16'h0600;  // 6.00
        matrix_lu_data[207:192]   <= 16'h0580;  // 5.50
        matrix_lu_data[191:176]   <= 16'h0500;  // 5.00
        matrix_lu_data[175:160]   <= 16'h0480;  // 4.50
        matrix_lu_data[159:144]   <= 16'h0400;  // 4.00
        matrix_lu_data[143:128]   <= 16'h0200;  // 2.00
        // 第 7 行
        matrix_lu_data[127:112]   <= 16'h0800;  // 8.00
        matrix_lu_data[111:96]    <= 16'h0780;  // 7.50
        matrix_lu_data[95:80]     <= 16'h0700;  // 7.00
        matrix_lu_data[79:64]     <= 16'h0680;  // 6.50
        matrix_lu_data[63:48]     <= 16'h0600;  // 6.00
        matrix_lu_data[47:32]     <= 16'h0580;  // 5.50
        matrix_lu_data[31:16]     <= 16'h0500;  // 5.00
        matrix_lu_data[15:0]      <= 16'h0480;  // 4.50
    end

    // 全屏矩阵显示 (上下布局)
    MatrixDisplay #(
        .PANEL_X(0),
        .PANEL_Y(0),
        .PANEL_W(SCREEN_W),
        .PANEL_H(SCREEN_H)
    ) u_matrix_display (
        .clk_pixel(clk_pixel),
        .hcount(x_pos),
        .vcount(y_pos),
        .video_on(video_on),
        .matrix_a_data(MATRIX_A_CONST),
        .matrix_lu_data(MATRIX_LU_CONST),
        .matrix_rendered(matrix_rendered),
        .matrix_rgb(matrix_rgb)
    );

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
        .clk_nav(clk_nav),
        .mouse_x(mouse_xpos_nav), .mouse_y(mouse_ypos_nav), .mouse_left(mouse_left_nav),
        .x(x_pos), .y(y_pos), .pixel_rgb(keyboard_rgb), .key_id(keyboard_key_id),
        .key_valid(keyboard_key_valid), .key_ascii(keyboard_key_ascii),
        .key_rgb(keyboard_key_rgb), .key_is_digit(keyboard_key_is_digit),
        .key_is_unit(keyboard_key_is_unit), .key_is_action(keyboard_key_is_action)
    );
    ToolbarVGA toolbar_vga_inst (
        .clk_pixel(clk_pixel),
        .mouse_x(mouse_xpos_pix),
        .mouse_y(mouse_ypos_pix),
        .mouse_left(mouse_left_pix),
        .x(x_pos),
        .y(y_pos),
        .pixel_rgb(toolbar_rgb),
        .rendered(toolbar_rendered),
        .selected_tool_idx(selected_toolbar_idx),
        .selected_wire_variant(selected_wire_variant)
    );

    // =========================================================
    // Calculator on OLED 实例化 (96x64 OLED)
    // =========================================================
    Calculator #(
        .OLED_W(96),
        .OLED_H(64),
        .DATA_W(10)
    ) calculator_inst (
        .clk(CLK100MHZ),
        .clk_nav(oled_clk20hz),      // 使用独立的 20Hz 导航时钟
        .btnU(BTNU),
        .btnD(BTND),
        .btnL(BTNL),
        .btnR(BTNR),
        .btnC(BTNC),                 // BTNC 用作确认键
        .x(oled_x_pos),
        .y(oled_y_pos),
        .pixel_rgb(oled_pixel_rgb)
    );

    Oled_Display oled_inst (
        .clk(oled_clk6p25m),         // 使用独立的 6.25MHz 像素时钟
        .reset(1'b0),                // OLED 始终工作，不复位
        .frame_begin(oled_frame_begin),
        .sending_pixels(oled_sending_pixels),
        .sample_pixel(oled_sample_pixel),
        .pixel_index(oled_pixel_index),
        .pixel_data(oled_data),
        .cs(JC[0]),
        .sdin(JC[1]),
        .sclk(JC[3]),
        .d_cn(JC[4]),
        .resn(JC[5]),
        .vccen(JC[6]),
        .pmoden(JC[7])
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
    wire v_dyn_text = 1'b0;
    wire i_dyn_text = 1'b0;
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

    // RAM 初始化與滑鼠重置
    always @(posedge CLK100MHZ) begin
        mouse_set_value <= 12'h000;
        mouse_set_max_x <= 1'b0;
        mouse_set_max_y <= 1'b0;
        circuit_canvas_ram_w_en <= 1'b0;
        value_ram_w_en <= 1'b0;
        component_index_map_w_en <= 1'b0;
        component_store_w_en <= 1'b0;
        value_digit_ram_w_data <= selected_value_digits;
        value_text_ram_w_data <= selected_value_text;
        value_text_len_ram_w_data <= selected_value_text_len;
        mouse_left_d_sys <= mouse_left;
        interaction_bg_rsp_valid <= 1'b0;
        selected_value_bcd <= value_ram_r_data;
        selected_value_digits <= value_digit_ram_r_data;
        selected_value_text <= value_text_ram_r_data;
        selected_value_text_len <= value_text_len_ram_r_data;
        keyboard_event_sync0 <= keyboard_event_toggle_nav;
        keyboard_event_sync1 <= keyboard_event_sync0;
        component_store_change_this_cycle = 1'b0;

        if (init_cycles < INIT_DELAY_CYCLES) begin
            init_cycles <= init_cycles + 1'b1;
        end

        if (keyboard_edit_event) begin
            keyboard_event_seen <= keyboard_event_sync1;
        end

        if (keyboard_edit_event && (keyboard_ascii_sys_ff1 == 8'h7F) && !selected_is_editable) begin
            clear_canvas_active <= 1'b1;
            clear_canvas_addr <= {CANVAS_ADDR_W{1'b0}};
            init_cycles <= INIT_DELAY_CYCLES;
            pending_pair_value_write <= 1'b0;
        end

        if (clear_canvas_active) begin
            pending_pair_value_write <= 1'b0;
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= clear_canvas_addr;
            circuit_canvas_ram_w_data <= 16'd0;
            value_ram_w_en <= 1'b1;
            value_ram_w_addr <= clear_canvas_addr;
            value_ram_w_data <= 12'd0;
            value_digit_ram_w_data <= 2'd0;
            value_text_ram_w_data <= 64'd0;
            value_text_len_ram_w_data <= 4'd0;
            canvas_shadow_data[clear_canvas_addr] <= 16'd0;
            value_shadow_data[clear_canvas_addr] <= 12'd0;
            value_unit_shadow_data[clear_canvas_addr] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;

            if (clear_canvas_addr == CANVAS_CELL_COUNT - 1) begin
                clear_canvas_active <= 1'b0;
            end else begin
                clear_canvas_addr <= clear_canvas_addr + 1'b1;
            end
        end else if (init_cycles == 10'd1) begin
            mouse_set_max_x <= 1'b1;
            mouse_set_value <= 12'd639;
        end else if (init_cycles == 10'd2) begin
            mouse_set_max_y <= 1'b1;
            mouse_set_value <= 12'd479;
        end else if (init_cycles < CANVAS_CELL_COUNT) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= init_cycles[CANVAS_ADDR_W-1:0];
            circuit_canvas_ram_w_data <= 16'd0;
            value_ram_w_en <= 1'b1;
            value_ram_w_addr <= init_cycles[CANVAS_ADDR_W-1:0];
            value_ram_w_data <= 12'd0;
            value_digit_ram_w_data <= 2'd0;
            value_text_ram_w_data <= 64'd0;
            value_text_len_ram_w_data <= 4'd0;
            canvas_shadow_data[init_cycles[CANVAS_ADDR_W-1:0]] <= 16'd0;
            value_shadow_data[init_cycles[CANVAS_ADDR_W-1:0]] <= 12'd0;
            value_unit_shadow_data[init_cycles[CANVAS_ADDR_W-1:0]] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 0) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd38;
            circuit_canvas_ram_w_data <= 16'h0083;
            canvas_shadow_data[9'd38] <= 16'h0083;
            value_shadow_data[9'd38] <= 12'd0;
            value_unit_shadow_data[9'd38] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 1) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd39;
            circuit_canvas_ram_w_data <= 16'h000F;
            value_ram_w_en <= 1'b1;
            value_ram_w_addr <= 9'd39;
            value_ram_w_data <= 12'h010;
            value_digit_ram_w_data <= 2'd2;
            value_text_ram_w_data <= {"1", "0", 48'd0};
            value_text_len_ram_w_data <= 4'd2;
            canvas_shadow_data[9'd39] <= 16'h000F;
            value_shadow_data[9'd39] <= 12'h010;
            value_unit_shadow_data[9'd39] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 2) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd40;
            circuit_canvas_ram_w_data <= 16'h0011;
            value_ram_w_en <= 1'b1;
            value_ram_w_addr <= 9'd40;
            value_ram_w_data <= 12'h010;
            value_digit_ram_w_data <= 2'd2;
            value_text_ram_w_data <= {"1", "0", 48'd0};
            value_text_len_ram_w_data <= 4'd2;
            canvas_shadow_data[9'd40] <= 16'h0011;
            value_shadow_data[9'd40] <= 12'h010;
            value_unit_shadow_data[9'd40] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 3) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd41;
            circuit_canvas_ram_w_data <= 16'h0103;
            canvas_shadow_data[9'd41] <= 16'h0103;
            value_shadow_data[9'd41] <= 12'd0;
            value_unit_shadow_data[9'd41] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 4) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd56;
            circuit_canvas_ram_w_data <= 16'h0281;
            canvas_shadow_data[9'd56] <= 16'h0281;
            value_shadow_data[9'd56] <= 12'd0;
            value_unit_shadow_data[9'd56] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 5) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd59;
            circuit_canvas_ram_w_data <= 16'h0081;
            canvas_shadow_data[9'd59] <= 16'h0081;
            value_shadow_data[9'd59] <= 12'd0;
            value_unit_shadow_data[9'd59] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 6) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd74;
            circuit_canvas_ram_w_data <= 16'h0285;
            canvas_shadow_data[9'd74] <= 16'h0285;
            value_shadow_data[9'd74] <= 12'd0;
            value_unit_shadow_data[9'd74] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 7) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd75;
            circuit_canvas_ram_w_data <= 16'h020B;
            value_ram_w_en <= 1'b1;
            value_ram_w_addr <= 9'd75;
            value_ram_w_data <= 12'h100;
            value_digit_ram_w_data <= 2'd3;
            value_text_ram_w_data <= {"1", "0", "0", 40'd0};
            value_text_len_ram_w_data <= 4'd3;
            canvas_shadow_data[9'd75] <= 16'h020B;
            value_shadow_data[9'd75] <= 12'h100;
            value_unit_shadow_data[9'd75] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 8) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd76;
            circuit_canvas_ram_w_data <= 16'h020D;
            value_ram_w_en <= 1'b1;
            value_ram_w_addr <= 9'd76;
            value_ram_w_data <= 12'h100;
            value_digit_ram_w_data <= 2'd3;
            value_text_ram_w_data <= {"1", "0", "0", 40'd0};
            value_text_len_ram_w_data <= 4'd3;
            canvas_shadow_data[9'd76] <= 16'h020D;
            value_shadow_data[9'd76] <= 12'h100;
            value_unit_shadow_data[9'd76] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 9) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd77;
            circuit_canvas_ram_w_data <= 16'h0185;
            canvas_shadow_data[9'd77] <= 16'h0185;
            value_shadow_data[9'd77] <= 12'd0;
            value_unit_shadow_data[9'd77] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 10) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd92;
            circuit_canvas_ram_w_data <= 16'h0281;
            canvas_shadow_data[9'd92] <= 16'h0281;
            value_shadow_data[9'd92] <= 12'd0;
            value_unit_shadow_data[9'd92] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 11) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd95;
            circuit_canvas_ram_w_data <= 16'h0081;
            canvas_shadow_data[9'd95] <= 16'h0081;
            value_shadow_data[9'd95] <= 12'd0;
            value_unit_shadow_data[9'd95] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 12) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd110;
            circuit_canvas_ram_w_data <= 16'h0003;
            canvas_shadow_data[9'd110] <= 16'h0003;
            value_shadow_data[9'd110] <= 12'd0;
            value_unit_shadow_data[9'd110] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 13) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd111;
            circuit_canvas_ram_w_data <= 16'h021B;
            value_ram_w_en <= 1'b1;
            value_ram_w_addr <= 9'd111;
            value_ram_w_data <= 12'h100;
            value_digit_ram_w_data <= 2'd3;
            value_text_ram_w_data <= {"1", "0", "0", "p", 32'd0};
            value_text_len_ram_w_data <= 4'd4;
            canvas_shadow_data[9'd111] <= 16'h021B;
            value_shadow_data[9'd111] <= 12'h100;
            value_unit_shadow_data[9'd111] <= COMPONENT_UNIT_P;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 14) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd112;
            circuit_canvas_ram_w_data <= 16'h021D;
            value_ram_w_en <= 1'b1;
            value_ram_w_addr <= 9'd112;
            value_ram_w_data <= 12'h100;
            value_digit_ram_w_data <= 2'd3;
            value_text_ram_w_data <= {"1", "0", "0", "p", 32'd0};
            value_text_len_ram_w_data <= 4'd4;
            canvas_shadow_data[9'd112] <= 16'h021D;
            value_shadow_data[9'd112] <= 12'h100;
            value_unit_shadow_data[9'd112] <= COMPONENT_UNIT_P;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 15) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd113;
            circuit_canvas_ram_w_data <= 16'h0183;
            canvas_shadow_data[9'd113] <= 16'h0183;
            value_shadow_data[9'd113] <= 12'd0;
            value_unit_shadow_data[9'd113] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (pending_pair_value_write) begin
            value_ram_w_en <= 1'b1;
            value_ram_w_addr <= pending_pair_value_addr;
            value_ram_w_data <= pending_pair_value_data;
            value_digit_ram_w_data <= pending_pair_value_digits;
            value_text_ram_w_data <= pending_pair_value_text;
            value_text_len_ram_w_data <= pending_pair_value_text_len;
            value_shadow_data[pending_pair_value_addr] <= pending_pair_value_data;
            value_unit_shadow_data[pending_pair_value_addr] <= component_unit_code_from_text(
                pending_pair_value_text,
                pending_pair_value_text_len
            );
            pending_pair_value_write <= 1'b0;
            component_store_change_this_cycle = 1'b1;
        end else if (keyboard_edit_event && edit_value_valid) begin
            value_ram_w_en <= 1'b1;
            value_ram_w_addr <= selected_cell_addr_sys;
            value_ram_w_data <= edit_value_next_bcd;
            value_digit_ram_w_data <= edit_value_next_digits;
            value_text_ram_w_data <= edit_value_next_text;
            value_text_len_ram_w_data <= edit_value_next_text_len;
            value_shadow_data[selected_cell_addr_sys] <= edit_value_next_bcd;
            value_unit_shadow_data[selected_cell_addr_sys] <= component_unit_code_from_text(
                edit_value_next_text,
                edit_value_next_text_len
            );
            selected_value_bcd <= edit_value_next_bcd;
            selected_value_digits <= edit_value_next_digits;
            selected_value_text <= edit_value_next_text;
            selected_value_text_len <= edit_value_next_text_len;
            component_store_change_this_cycle = 1'b1;

            if (selected_pair_addr != selected_cell_addr_sys) begin
                pending_pair_value_write <= 1'b1;
                pending_pair_value_addr <= selected_pair_addr;
                pending_pair_value_data <= edit_value_next_bcd;
                pending_pair_value_digits <= edit_value_next_digits;
                pending_pair_value_text <= edit_value_next_text;
                pending_pair_value_text_len <= edit_value_next_text_len;
            end
        end else if (interaction_bg_cmd_valid && interaction_bg_cmd_ready) begin
            if (interaction_bg_cmd_write) begin
                circuit_canvas_ram_w_en <= 1'b1;
                circuit_canvas_ram_w_addr <= interaction_bg_cmd_addr;
                circuit_canvas_ram_w_data <= interaction_bg_cmd_wdata;
                canvas_shadow_data[interaction_bg_cmd_addr] <= interaction_bg_cmd_wdata;
                component_store_change_this_cycle = 1'b1;
                if (interaction_bg_cmd_wdata == 16'd0) begin
                    value_ram_w_en <= 1'b1;
                    value_ram_w_addr <= interaction_bg_cmd_addr;
                    value_ram_w_data <= 12'd0;
                    value_digit_ram_w_data <= 2'd0;
                    value_text_ram_w_data <= 64'd0;
                    value_text_len_ram_w_data <= 4'd0;
                    value_shadow_data[interaction_bg_cmd_addr] <= 12'd0;
                    value_unit_shadow_data[interaction_bg_cmd_addr] <= COMPONENT_UNIT_NONE;
                end
            end else begin
                interaction_bg_rsp_valid <= 1'b1;
                interaction_bg_rsp_rdata <= canvas_shadow_data[interaction_bg_cmd_addr];
            end
        end

        if (component_index_map_pending_pair_write) begin
            component_index_map_w_en <= 1'b1;
            component_index_map_w_addr <= component_index_map_pending_pair_addr;
            component_index_map_w_data <= component_index_map_pending_pair_data;
            component_index_map_pending_pair_write <= 1'b0;
        end else if (component_index_map_clear_active) begin
            component_index_map_w_en <= 1'b1;
            component_index_map_w_addr <= component_index_map_clear_addr;
            component_index_map_w_data <= COMPONENT_INDEX_INVALID;
            if (component_index_map_clear_addr == CANVAS_CELL_COUNT - 1) begin
                component_index_map_clear_active <= 1'b0;
                component_store_rebuild_active <= 1'b1;
                component_store_scan_addr <= {CANVAS_ADDR_W{1'b0}};
                component_store_next_index <= {CANVAS_ADDR_W{1'b0}};
                component_store_count <= {CANVAS_ADDR_W{1'b0}};
            end else begin
                component_index_map_clear_addr <= component_index_map_clear_addr + 1'b1;
            end
        end else if (component_store_rebuild_active) begin
            if (component_store_is_origin(component_store_scan_cell, component_store_scan_sprite) &&
                component_store_scan_needs_index) begin
                component_store_w_en <= 1'b1;
                component_store_w_addr <= component_store_next_index;
                component_store_w_data <= make_component_store_entry(
                    component_store_scan_unit,
                    component_store_next_index,
                    component_store_scan_type,
                    component_store_scan_rotation,
                    component_store_scan_value,
                    component_store_scan_addr
                );
                component_index_map_w_en <= 1'b1;
                component_index_map_w_addr <= component_store_scan_addr;
                component_index_map_w_data <= component_store_next_index;
                if (component_store_scan_is_two_cell &&
                    (component_store_scan_pair_addr != component_store_scan_addr)) begin
                    component_index_map_pending_pair_write <= 1'b1;
                    component_index_map_pending_pair_addr <= component_store_scan_pair_addr;
                    component_index_map_pending_pair_data <= component_store_next_index;
                end
                if (component_store_scan_addr == CANVAS_CELL_COUNT - 1) begin
                    component_store_count <= component_store_next_index + 1'b1;
                    component_store_rebuild_active <= 1'b0;
                end else begin
                    component_store_next_index <= component_store_next_index + 1'b1;
                    component_store_scan_addr <= component_store_scan_addr + 1'b1;
                end
            end else begin
                if (component_store_scan_addr == CANVAS_CELL_COUNT - 1) begin
                    component_store_count <= component_store_next_index;
                    component_store_rebuild_active <= 1'b0;
                end else begin
                    component_store_scan_addr <= component_store_scan_addr + 1'b1;
                end
            end
        end else if (!component_store_change_this_cycle && component_store_dirty) begin
            component_index_map_clear_active <= 1'b1;
            component_index_map_clear_addr <= {CANVAS_ADDR_W{1'b0}};
            component_index_map_pending_pair_write <= 1'b0;
            component_store_dirty <= 1'b0;
        end

        if (component_store_change_this_cycle) begin
            component_store_dirty <= 1'b1;
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

        title_active = 1'b0;
        if (title_active && !dynamic_wave_active) ui_rgb = 12'hFFF;
    end

    always @(posedge clk_pixel) begin
        if (!video_on) begin
            rgb <= BLACK;
        end else if (mouse_display_enable) begin
            rgb <= mouse_rgb;
        end else if (show_component_store_view && component_store_view_rendered) begin
            rgb <= component_store_view_rgb;
        end else if (show_matrix && matrix_rendered) begin
            // 全屏矩阵显示
            rgb <= matrix_rgb;
        end else if (keyboard_region_active) begin
            rgb <= keyboard_rgb;
        end else if (circuit_canvas_rendered) begin
            // 电路显示
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
