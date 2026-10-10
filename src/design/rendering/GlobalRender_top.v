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
    input  wire        RsRx,
    output wire        RsTx,
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
    localparam ENABLE_OLED_CALC  = 1'b0;
    localparam ENABLE_PROP_PANEL = 1'b1;
    localparam ENABLE_WAVEFORMS  = 1'b0;
    localparam ENABLE_BACKEND_FETCH_TEST = 1'b0;
    localparam ENABLE_UART_NETLIST_DEBUG = 1'b1;
    localparam ENABLE_UART_FLOOD_DEBUG   = 1'b0;
    localparam ENABLE_UART_CELL_DEBUG    = 1'b0;
    localparam [3:0] CANVAS_FG_DEFAULT_COLOR_IDX = 4'hF;
    localparam [3:0] CANVAS_BG_DEFAULT_COLOR_IDX = 4'h0;

    // =========================================================
    // 銆愭焙瀹氱敓姝荤殑閬僵绮剧畻銆?
    // 鍦? Top 妯＄祫瑁＄簿婧栧鍛? 155 x 128 鐨勭墿鐞嗙┖闁擄紝闃叉琚垏鏂凤紒
    // 5鍒? * 31瀵? = 155, 4琛? * 32楂? = 128
    // =========================================================
    localparam integer KEYBOARD_SCALE  = 2;
    localparam integer KEY_W           = 31;
    localparam integer KEY_H           = 32;
    localparam integer KEYBOARD_W      = 5 * KEY_W;
    localparam integer KEYBOARD_H      = 4 * KEY_H; 
    localparam integer KEYBOARD_MARGIN = 0;
    localparam integer KEYBOARD_PANEL_PAD = 0;

    localparam integer KEYBOARD_X      = SCREEN_W - RIGHT_BAR_W + 1;
    // 485锛岃畵瀹冪穵璨煎彸鍋撮倞绶?
    localparam integer KEYBOARD_Y      = SCREEN_H - BOTTOM_BAR_H;
    // 352
    
    localparam integer KEYBOARD_REGION_X0 = KEYBOARD_X;
    localparam integer KEYBOARD_REGION_Y0 = KEYBOARD_Y;
    localparam integer KEYBOARD_REGION_X1 = KEYBOARD_X + KEYBOARD_W;
    localparam integer KEYBOARD_REGION_Y1 = KEYBOARD_Y + KEYBOARD_H;
    // =========================================================

    wire clk_pixel, video_on;
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
    wire [7:0]  jc_oled;
    reg  [15:0] oled_data;

    wire [11:0] circuit_canvas_rgb;
    wire        circuit_canvas_rendered;
    reg  [11:0] ui_rgb;
    wire [15:0] hex_display_value;
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
    // Pixel-domain mouse, latched once per frame at the VSYNC leading edge (the
    // same edge the InteractionController samples on), so every pixel of a
    // frame sees the same mouse state.
    reg  [11:0] mouse_xpos_pix_frame = 12'd0;
    reg  [11:0] mouse_ypos_pix_frame = 12'd0;
    reg         mouse_left_pix_frame = 1'b0;
    reg         mouse_middle_pix_frame = 1'b0;
    reg         mouse_right_pix_frame = 1'b0;
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
    reg         circuit_canvas_fg_color_override_w_en = 1'b0;
    reg  [CANVAS_ADDR_W-1:0] circuit_canvas_fg_color_override_w_addr = {CANVAS_ADDR_W{1'b0}};
    reg  [3:0]  circuit_canvas_fg_color_override_w_data = CANVAS_FG_DEFAULT_COLOR_IDX;
    wire        circuit_canvas_fg_color_ram_w_en;
    wire [CANVAS_ADDR_W-1:0] circuit_canvas_fg_color_ram_w_addr;
    wire [3:0]  circuit_canvas_fg_color_ram_w_data;
    wire [3:0]  circuit_canvas_fg_color_ram_r_data;
    reg         circuit_canvas_bg_color_override_w_en = 1'b0;
    reg  [CANVAS_ADDR_W-1:0] circuit_canvas_bg_color_override_w_addr = {CANVAS_ADDR_W{1'b0}};
    reg  [3:0]  circuit_canvas_bg_color_override_w_data = CANVAS_BG_DEFAULT_COLOR_IDX;
    wire        circuit_canvas_bg_color_ram_w_en;
    wire [CANVAS_ADDR_W-1:0] circuit_canvas_bg_color_ram_w_addr;
    wire [3:0]  circuit_canvas_bg_color_ram_w_data;
    wire [3:0]  circuit_canvas_bg_color_ram_r_data;
    localparam [9:0] INIT_DELAY_CYCLES = 10'd1000;
    reg  [9:0]  init_cycles = 10'd0;

    reg         clear_canvas_active = 1'b0;
    reg  [CANVAS_ADDR_W-1:0]  clear_canvas_addr = {CANVAS_ADDR_W{1'b0}};
    wire [11:0] mouse_xpos_pix = mouse_xpos_pix_frame;
    wire [11:0] mouse_ypos_pix = mouse_ypos_pix_frame;
    wire        mouse_left_pix = mouse_left_pix_frame;
    wire        mouse_middle_pix = mouse_middle_pix_frame;
    wire        mouse_right_pix = mouse_right_pix_frame;
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

    function [7:0] ascii_binary_digit;
        input bit_value;
        begin
            ascii_binary_digit = bit_value ? "1" : "0";
        end
    endfunction

    function [4:0] canvas_addr_to_i;
        input [CANVAS_ADDR_W-1:0] addr;
        begin
            canvas_addr_to_i = addr % CANVAS_GRID_W;
        end
    endfunction

    function [3:0] canvas_addr_to_j;
        input [CANVAS_ADDR_W-1:0] addr;
        begin
            canvas_addr_to_j = addr / CANVAS_GRID_W;
        end
    endfunction

    function [3:0] node_result_to_bg_palette_idx;
        input [7:0] node_result;
        reg [7:0] wrapped_node;
        begin
            if (node_result == 8'd0) begin
                node_result_to_bg_palette_idx = CANVAS_BG_DEFAULT_COLOR_IDX;
            end else begin
                wrapped_node = (node_result - 8'd1) % 8'd13;
                node_result_to_bg_palette_idx = 4'd1 + wrapped_node[3:0];
            end
        end
    endfunction

    function [7:0] uart_cell_packet_char;
        input [4:0] char_index;
        input [4:0] cell_i;
        input [3:0] cell_j;
        input [15:0] cell_data;
        input [3:0] cell_p;
        reg [3:0] cell_i_tens;
        reg [3:0] cell_i_ones;
        reg [3:0] cell_j_tens;
        reg [3:0] cell_j_ones;
        begin
            cell_i_tens = (cell_i >= 5'd10) ? 4'd1 : 4'd0;
            cell_i_ones = (cell_i >= 5'd10) ? (cell_i - 5'd10) : cell_i[3:0];
            cell_j_tens = (cell_j >= 4'd10) ? 4'd1 : 4'd0;
            cell_j_ones = (cell_j >= 4'd10) ? (cell_j - 4'd10) : cell_j[3:0];

            case (char_index)
                5'd0: uart_cell_packet_char = "C";
                5'd1: uart_cell_packet_char = "E";
                5'd2: uart_cell_packet_char = "L";
                5'd3: uart_cell_packet_char = "L";
                5'd4: uart_cell_packet_char = " ";
                5'd5: uart_cell_packet_char = "(";
                5'd6: uart_cell_packet_char = ascii_decimal_nibble(cell_i_tens);
                5'd7: uart_cell_packet_char = ascii_decimal_nibble(cell_i_ones);
                5'd8: uart_cell_packet_char = ",";
                5'd9: uart_cell_packet_char = " ";
                5'd10: uart_cell_packet_char = ascii_decimal_nibble(cell_j_tens);
                5'd11: uart_cell_packet_char = ascii_decimal_nibble(cell_j_ones);
                5'd12: uart_cell_packet_char = ")";
                5'd13: uart_cell_packet_char = " ";
                5'd14: uart_cell_packet_char = "=";
                5'd15: uart_cell_packet_char = " ";
                5'd16: uart_cell_packet_char = "0";
                5'd17: uart_cell_packet_char = "x";
                5'd18: uart_cell_packet_char = ascii_hex_nibble(cell_data[15:12]);
                5'd19: uart_cell_packet_char = ascii_hex_nibble(cell_data[11:8]);
                5'd20: uart_cell_packet_char = ascii_hex_nibble(cell_data[7:4]);
                5'd21: uart_cell_packet_char = ascii_hex_nibble(cell_data[3:0]);
                5'd22: uart_cell_packet_char = " ";
                5'd23: uart_cell_packet_char = "P";
                5'd24: uart_cell_packet_char = "=";
                5'd25: uart_cell_packet_char = ascii_binary_digit(cell_p[3]);
                5'd26: uart_cell_packet_char = ascii_binary_digit(cell_p[2]);
                5'd27: uart_cell_packet_char = ascii_binary_digit(cell_p[1]);
                5'd28: uart_cell_packet_char = ascii_binary_digit(cell_p[0]);
                5'd29: uart_cell_packet_char = 8'h0D;
                default: uart_cell_packet_char = 8'h0A;
            endcase
        end
    endfunction

    function [7:0] uart_result_packet_char;
        input [5:0] char_index;
        input [4:0] cell_i;
        input [3:0] cell_j;
        input [7:0] cell_result;
        input [3:0] cell_p;
        input [3:0] cell_bg_idx;
        reg [3:0] cell_i_tens;
        reg [3:0] cell_i_ones;
        reg [3:0] cell_j_tens;
        reg [3:0] cell_j_ones;
        begin
            cell_i_tens = (cell_i >= 5'd10) ? 4'd1 : 4'd0;
            cell_i_ones = (cell_i >= 5'd10) ? (cell_i - 5'd10) : cell_i[3:0];
            cell_j_tens = (cell_j >= 4'd10) ? 4'd1 : 4'd0;
            cell_j_ones = (cell_j >= 4'd10) ? (cell_j - 4'd10) : cell_j[3:0];

            case (char_index)
                6'd0: uart_result_packet_char = "N";
                6'd1: uart_result_packet_char = "O";
                6'd2: uart_result_packet_char = "D";
                6'd3: uart_result_packet_char = "E";
                6'd4: uart_result_packet_char = " ";
                6'd5: uart_result_packet_char = "(";
                6'd6: uart_result_packet_char = ascii_decimal_nibble(cell_i_tens);
                6'd7: uart_result_packet_char = ascii_decimal_nibble(cell_i_ones);
                6'd8: uart_result_packet_char = ",";
                6'd9: uart_result_packet_char = " ";
                6'd10: uart_result_packet_char = ascii_decimal_nibble(cell_j_tens);
                6'd11: uart_result_packet_char = ascii_decimal_nibble(cell_j_ones);
                6'd12: uart_result_packet_char = ")";
                6'd13: uart_result_packet_char = " ";
                6'd14: uart_result_packet_char = "=";
                6'd15: uart_result_packet_char = " ";
                6'd16: uart_result_packet_char = "0";
                6'd17: uart_result_packet_char = "x";
                6'd18: uart_result_packet_char = ascii_hex_nibble(cell_result[7:4]);
                6'd19: uart_result_packet_char = ascii_hex_nibble(cell_result[3:0]);
                6'd20: uart_result_packet_char = " ";
                6'd21: uart_result_packet_char = "P";
                6'd22: uart_result_packet_char = "=";
                6'd23: uart_result_packet_char = ascii_binary_digit(cell_p[3]);
                6'd24: uart_result_packet_char = ascii_binary_digit(cell_p[2]);
                6'd25: uart_result_packet_char = ascii_binary_digit(cell_p[1]);
                6'd26: uart_result_packet_char = ascii_binary_digit(cell_p[0]);
                6'd27: uart_result_packet_char = " ";
                6'd28: uart_result_packet_char = "B";
                6'd29: uart_result_packet_char = "G";
                6'd30: uart_result_packet_char = "=";
                6'd31: uart_result_packet_char = ascii_hex_nibble(cell_bg_idx);
                6'd32: uart_result_packet_char = 8'h0D;
                default: uart_result_packet_char = 8'h0A;
            endcase
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

    function [7:0] uart_netlist_packet_char;
        input [5:0] char_index;
        input [39:0] component_entry;
        input [7:0] node0;
        input [7:0] node1;
        reg [8:0] component_index;
        reg [3:0] component_unit;
        reg [3:0] component_type;
        reg [1:0] component_rotation;
        reg [11:0] component_value;
        reg [4:0] component_x;
        reg [3:0] component_y;
        begin
            component_unit = component_entry[39:36];
            component_index = component_entry[35:27];
            component_type = component_entry[26:23];
            component_rotation = component_entry[22:21];
            component_value = component_entry[20:9];
            component_y = component_entry[8:5];
            component_x = component_entry[4:0];

            case (char_index)
                6'd0: uart_netlist_packet_char = "C";
                6'd1: uart_netlist_packet_char = "M";
                6'd2: uart_netlist_packet_char = "P";
                6'd3: uart_netlist_packet_char = " ";
                6'd4: uart_netlist_packet_char = ascii_hex_nibble({3'd0, component_index[8]});
                6'd5: uart_netlist_packet_char = ascii_hex_nibble(component_index[7:4]);
                6'd6: uart_netlist_packet_char = ascii_hex_nibble(component_index[3:0]);
                6'd7: uart_netlist_packet_char = " ";
                6'd8: uart_netlist_packet_char = "T";
                6'd9: uart_netlist_packet_char = "=";
                6'd10: uart_netlist_packet_char = ascii_hex_nibble(component_type);
                6'd11: uart_netlist_packet_char = " ";
                6'd12: uart_netlist_packet_char = "R";
                6'd13: uart_netlist_packet_char = "=";
                6'd14: uart_netlist_packet_char = ascii_hex_nibble({2'd0, component_rotation});
                6'd15: uart_netlist_packet_char = " ";
                6'd16: uart_netlist_packet_char = "X";
                6'd17: uart_netlist_packet_char = "=";
                6'd18: uart_netlist_packet_char = ascii_hex_nibble({3'd0, component_x[4]});
                6'd19: uart_netlist_packet_char = ascii_hex_nibble(component_x[3:0]);
                6'd20: uart_netlist_packet_char = " ";
                6'd21: uart_netlist_packet_char = "Y";
                6'd22: uart_netlist_packet_char = "=";
                6'd23: uart_netlist_packet_char = "0";
                6'd24: uart_netlist_packet_char = ascii_hex_nibble(component_y);
                6'd25: uart_netlist_packet_char = " ";
                6'd26: uart_netlist_packet_char = "V";
                6'd27: uart_netlist_packet_char = "=";
                6'd28: uart_netlist_packet_char = ascii_hex_nibble(component_value[11:8]);
                6'd29: uart_netlist_packet_char = ascii_hex_nibble(component_value[7:4]);
                6'd30: uart_netlist_packet_char = ascii_hex_nibble(component_value[3:0]);
                6'd31: uart_netlist_packet_char = " ";
                6'd32: uart_netlist_packet_char = "U";
                6'd33: uart_netlist_packet_char = "=";
                6'd34: uart_netlist_packet_char = ascii_hex_nibble(component_unit);
                6'd35: uart_netlist_packet_char = " ";
                6'd36: uart_netlist_packet_char = "N";
                6'd37: uart_netlist_packet_char = "0";
                6'd38: uart_netlist_packet_char = "=";
                6'd39: uart_netlist_packet_char = ascii_hex_nibble(node0[7:4]);
                6'd40: uart_netlist_packet_char = ascii_hex_nibble(node0[3:0]);
                6'd41: uart_netlist_packet_char = " ";
                6'd42: uart_netlist_packet_char = "N";
                6'd43: uart_netlist_packet_char = "1";
                6'd44: uart_netlist_packet_char = "=";
                6'd45: uart_netlist_packet_char = ascii_hex_nibble(node1[7:4]);
                6'd46: uart_netlist_packet_char = ascii_hex_nibble(node1[3:0]);
                6'd47: uart_netlist_packet_char = 8'h0D;
                default: uart_netlist_packet_char = 8'h0A;
            endcase
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

    function [3:0] component_store_type_from_sprite;
        input [5:0] sprite_type;
        begin
            component_store_type_from_sprite = sprite_type[3:0];
        end
    endfunction

    function [7:0] frontend_protocol_kind_from_store_type;
        input [3:0] store_type;
        begin
            case (store_type)
                SPRITE_RES_LEFT[3:0], SPRITE_RES_RIGHT[3:0]:
                    frontend_protocol_kind_from_store_type = 8'h01;
                SPRITE_CURR_LEFT[3:0], SPRITE_CURR_RIGHT[3:0]:
                    frontend_protocol_kind_from_store_type = 8'h02;
                SPRITE_VOLT_LEFT[3:0], SPRITE_VOLT_RIGHT[3:0]:
                    frontend_protocol_kind_from_store_type = 8'h03;
                SPRITE_CAP_LEFT[3:0], SPRITE_CAP_RIGHT[3:0]:
                    frontend_protocol_kind_from_store_type = 8'h04;
                SPRITE_IND_LEFT[3:0], SPRITE_IND_RIGHT[3:0]:
                    frontend_protocol_kind_from_store_type = 8'h05;
                default:
                    frontend_protocol_kind_from_store_type = 8'h00;
            endcase
        end
    endfunction

    function frontend_protocol_kind_supported;
        input [7:0] protocol_kind;
        begin
            case (protocol_kind)
                8'h01, 8'h02, 8'h03: frontend_protocol_kind_supported = 1'b1;
                default: frontend_protocol_kind_supported = 1'b0;
            endcase
        end
    endfunction

    function [7:0] frontend_protocol_unit_from_component_unit;
        input [3:0] unit_code;
        begin
            case (unit_code)
                COMPONENT_UNIT_NONE: frontend_protocol_unit_from_component_unit = 8'h00;
                COMPONENT_UNIT_m:    frontend_protocol_unit_from_component_unit = 8'h01;
                COMPONENT_UNIT_U:    frontend_protocol_unit_from_component_unit = 8'h02;
                COMPONENT_UNIT_N:    frontend_protocol_unit_from_component_unit = 8'h03;
                COMPONENT_UNIT_K:    frontend_protocol_unit_from_component_unit = 8'h04;
                COMPONENT_UNIT_M:    frontend_protocol_unit_from_component_unit = 8'h05;
                default:             frontend_protocol_unit_from_component_unit = 8'hFF;
            endcase
        end
    endfunction

    function frontend_protocol_unit_supported;
        input [7:0] protocol_unit;
        begin
            frontend_protocol_unit_supported = (protocol_unit != 8'hFF);
        end
    endfunction

    function [3:0] component_display_type_from_store_type;
        input [3:0] store_type;
        begin
            case (store_type)
                SPRITE_GROUND[3:0]: component_display_type_from_store_type = COMPONENT_TYPE_GROUND;
                SPRITE_RES_LEFT[3:0], SPRITE_RES_RIGHT[3:0]: component_display_type_from_store_type = COMPONENT_TYPE_RESISTOR;
                SPRITE_CAP_LEFT[3:0], SPRITE_CAP_RIGHT[3:0]: component_display_type_from_store_type = COMPONENT_TYPE_CAPACITOR;
                SPRITE_IND_LEFT[3:0], SPRITE_IND_RIGHT[3:0]: component_display_type_from_store_type = COMPONENT_TYPE_INDUCTOR;
                SPRITE_VOLT_LEFT[3:0], SPRITE_VOLT_RIGHT[3:0]: component_display_type_from_store_type = COMPONENT_TYPE_VOLTAGE;
                SPRITE_CURR_LEFT[3:0], SPRITE_CURR_RIGHT[3:0]: component_display_type_from_store_type = COMPONENT_TYPE_CURRENT;
                default: component_display_type_from_store_type = COMPONENT_TYPE_WIRE;
            endcase
        end
    endfunction

    function [COMPONENT_STORE_ENTRY_W-1:0] make_component_store_entry;
        input [3:0] component_unit;
        input [CANVAS_ADDR_W-1:0] store_index;
        input [3:0] component_store_type;
        input [1:0] component_rotation;
        input [11:0] component_value;
        input [CANVAS_ADDR_W-1:0] cell_addr;
        begin
            make_component_store_entry = {
                component_unit,
                store_index,
                component_store_type,
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
                COMPONENT_TYPE_WIRE,
                COMPONENT_TYPE_GROUND: component_type_needs_index = 1'b0;
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

    // JC 绔彛鐢� OLED 妯″潡椹卞姩锛岀鐢� OLED 鏃朵繚鎸佹媺浣庛€�
    assign JC = ENABLE_OLED_CALC ? jc_oled : 8'h00;
    Hex7SegMux frontend_hex_mux_inst (
        .clk(CLK100MHZ),
        .hex_value(hex_display_value),
        .SEG(SEG),
        .AN(AN)
    );
    ClockDivider #( .FREQ(25_000_000) ) clkdiv_pixel_inst ( .CLK100MHZ(CLK100MHZ), .clk_out(clk_pixel) );

    // =========================================================
    // OLED Clock Divider: 100MHz -> 6.25MHz & 20Hz
    // 鐢熸垚 OLED 鍍忕礌鏃堕挓鍜岃绠楀櫒瀵艰埅鏃堕挓 (鐙珛浜庣郴缁熸椂閽?)
    // =========================================================
    reg [3:0] oled_clk_div_counter = 0;
    reg [22:0] oled_clk_div_20hz = 0;
    reg oled_clk6p25m = 0;
    reg oled_clk20hz = 0;

    always @(posedge CLK100MHZ) begin
        if (ENABLE_OLED_CALC) begin
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
        end else begin
            oled_clk_div_counter <= 4'd0;
            oled_clk_div_20hz <= 23'd0;
            oled_clk6p25m <= 1'b0;
            oled_clk20hz <= 1'b0;
        end
    end

    assign oled_x_pos = ENABLE_OLED_CALC ? (oled_pixel_index % 96) : 7'd0;
    assign oled_y_pos = ENABLE_OLED_CALC ? (oled_pixel_index / 96) : 6'd0;

    always @(posedge oled_clk6p25m) begin
        if (ENABLE_OLED_CALC) begin
            oled_data <= oled_pixel_rgb;
        end else begin
            oled_data <= 16'd0;
        end
    end

    VGAControl vga_ctrl_inst (
        .clk_pixel(clk_pixel), .reset(SW[15]), .rgb(rgb),
        .hsync(HSYNC), .vsync(VSYNC), .video_on(video_on),
        .h_count_reg(x_pos), .v_count_reg(y_pos),
        .vgaRed(VGARED), .vgaGreen(VGAGREEN), .vgaBlue(VGABLUE)
    );
    // 鍚屾鑸囬噸缃▕铏?
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
        if (vsync_edge) begin
            mouse_xpos_pix_frame <= mouse_xpos_pix_ff1;
            mouse_ypos_pix_frame <= mouse_ypos_pix_ff1;
            mouse_left_pix_frame <= mouse_left_pix_ff1;
            mouse_middle_pix_frame <= mouse_middle_pix_ff1;
            mouse_right_pix_frame <= mouse_right_pix_ff1;
        end
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
    SimpleDualClockRam #( .WordWidth(4), .WordCount(CANVAS_CELL_COUNT) ) circuit_canvas_fg_color_ram_inst (
        .wr_clk(CLK100MHZ), .rd_clk(clk_pixel),
        .w_en(circuit_canvas_fg_color_ram_w_en), .w_addr(circuit_canvas_fg_color_ram_w_addr),
        .r_addr(circuit_canvas_ram_r_addr), .d_in(circuit_canvas_fg_color_ram_w_data),
        .d_out(circuit_canvas_fg_color_ram_r_data)
    );
    SimpleDualClockRam #( .WordWidth(4), .WordCount(CANVAS_CELL_COUNT) ) circuit_canvas_bg_color_ram_inst (
        .wr_clk(CLK100MHZ), .rd_clk(clk_pixel),
        .w_en(circuit_canvas_bg_color_ram_w_en), .w_addr(circuit_canvas_bg_color_ram_w_addr),
        .r_addr(circuit_canvas_ram_r_addr), .d_in(circuit_canvas_bg_color_ram_w_data),
        .d_out(circuit_canvas_bg_color_ram_r_data)
    );

    // =========================================================
    // 鍕曟厠闆绘祦鍕曠暙鐢㈢敓鍣? (鍏у缓 1D 鐩镐綅)
    // =========================================================
    // Frame-locked: one phase step every ANIM_FRAMES_PER_STEP frames (30 Hz at
    // 2), advanced at the VSYNC leading edge so a frame never changes phase
    // mid-scan.
    localparam integer ANIM_FRAMES_PER_STEP = 2;
    reg [1:0]  anim_frame_ctr = 0;
    reg [4:0]  global_anim_phase = 0;
    always @(posedge clk_pixel) begin
        if (vsync_edge) begin
            if (anim_frame_ctr == ANIM_FRAMES_PER_STEP - 1) begin
                anim_frame_ctr <= 0;
                global_anim_phase <= global_anim_phase + 1;
            end else begin
                anim_frame_ctr <= anim_frame_ctr + 1;
            end
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
    wire        controller_cmd_valid, controller_cmd_write, controller_cmd_ready;
    wire [CANVAS_ADDR_W-1:0] controller_cmd_addr;
    wire [15:0] controller_cmd_wdata, controller_rsp_rdata;
    wire        controller_rsp_valid, controller_done, command_guard_idle;
    wire        interaction_value_read_en, interaction_copy_value;
    wire [CANVAS_ADDR_W-1:0] interaction_value_read_addr;
    assign interaction_frame_done = controller_done && command_guard_idle;

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
        .incoming_fg_color_idx(circuit_canvas_fg_color_ram_r_data),
        .incoming_bg_color_idx(circuit_canvas_bg_color_ram_r_data),
        .display_grid(1'b1), .mouse_left_click(mouse_left_pix && (selected_toolbar_idx == 4'd0)),
        .anim_phase(global_anim_phase),
        .grid_pos_x_out(circuit_canvas_grid_pos_x),
        .grid_pos_y_out(circuit_canvas_grid_pos_y)
    );
    // Component Property Panel signals 浠ヤ笅涓哄睘鎬ч潰鏉夸緥鍖?
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
    wire        mouse_left_rising;
    
    // 榧犳爣鎮仠妫?娴?
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
    reg         keyboard_event_toggle_pix = 1'b0;
    reg  [7:0]  keyboard_event_ascii_pix = 8'h00;
    (* ASYNC_REG = "TRUE" *) reg         keyboard_event_sync0 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg         keyboard_event_sync1 = 1'b0;
    reg         keyboard_event_seen = 1'b0;
    reg  [11:0] edit_value_next_bcd = 12'd0;
    reg  [1:0]  edit_value_next_digits = 2'd0;
    reg  [63:0] edit_value_next_text = 64'd0;
    reg  [3:0]  edit_value_next_text_len = 4'd0;
    reg         edit_value_valid = 1'b0;
    
    // 绀轰緥鍏冧欢鏁版嵁 (浠? init_cycles 涓鍒?)
    reg  [15:0] canvas_shadow_data [0:CANVAS_CELL_COUNT-1];
    reg  [11:0] value_shadow_data [0:CANVAS_CELL_COUNT-1];
    reg  [3:0]  value_unit_shadow_data [0:CANVAS_CELL_COUNT-1];
    // component_store entry = {unit[3:0], index[8:0], type[3:0], rotation[1:0], value[11:0], position[8:0]}
    // position[8:5] = y, position[4:0] = x
    localparam integer BACKEND_FRAME_CYCLE_BUDGET = 10000;
    localparam integer UART_CELL_PACKET_LEN = 31;
    localparam integer UART_RESULT_PACKET_LEN = 34;
    localparam [1:0] COMPONENT_READ_OWNER_BACKEND = 2'd0;
    localparam [1:0] COMPONENT_READ_OWNER_NETLIST = 2'd1;
    localparam [1:0] FRONTEND_NETLIST_TX_MODE_NB = 2'd0;
    localparam [1:0] FRONTEND_NETLIST_TX_MODE_NC = 2'd1;
    localparam [1:0] FRONTEND_NETLIST_TX_MODE_NE = 2'd2;
    localparam [1:0] FRONTEND_NETLIST_TX_MODE_ER = 2'd3;
    localparam [3:0]
        NETLIST_TX_IDLE = 4'd0,
        NETLIST_TX_EXTRACT_WAIT = 4'd1,
        NETLIST_TX_PRESCAN_REQ = 4'd2,
        NETLIST_TX_PRESCAN_WAIT = 4'd3,
        NETLIST_TX_BEGIN_START = 4'd4,
        NETLIST_TX_BEGIN_WAIT = 4'd5,
        NETLIST_TX_COMP_REQ = 4'd6,
        NETLIST_TX_COMP_WAIT = 4'd7,
        NETLIST_TX_COMP_START = 4'd8,
        NETLIST_TX_COMP_WAIT_SEND = 4'd9,
        NETLIST_TX_END_START = 4'd10,
        NETLIST_TX_END_WAIT = 4'd11,
        NETLIST_TX_ERR_START = 4'd12,
        NETLIST_TX_ERR_WAIT = 4'd13;
    localparam [7:0] FRONTEND_STATUS_OK = 8'h00;
    localparam [7:0] FRONTEND_STATUS_UNSUPPORTED_KIND = 8'h81;
    localparam [7:0] FRONTEND_STATUS_UNSUPPORTED_UNIT = 8'h82;
    localparam [7:0] FRONTEND_STATUS_REPLY_PARSE = 8'h83;
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
    reg         component_store_read_snapshot_pending = 1'b0;
    reg  [1:0]  component_store_read_owner = COMPONENT_READ_OWNER_BACKEND;
    reg  [CANVAS_ADDR_W-1:0] component_store_read_addr_latched = {CANVAS_ADDR_W{1'b0}};
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
    // D-016 snapshot id: netlist-relevant content of a cell write (cell
    // [8:0] = enable/sprite/rotation, value BCD, unit) differs from the
    // shadow copy it replaces. Flow bit 9, [15:10], colour RAMs and the
    // value display text are not netlist content. netlist_content_dirty: the
    // content changed since the last snapshot was extracted (set from boot,
    // so the first snapshot gets id 0001); cleared when an extraction commits.
    reg         netlist_content_change_this_cycle;
    reg         netlist_content_dirty = 1'b1;
    // D-024: complete any in-flight line, then close an interrupted @NB.
    reg         netlist_stream_open = 1'b0;
    reg  [15:0] netlist_stream_lines = 16'd0;
    reg         netlist_abort_pending = 1'b0;
    reg         netlist_abort_sending = 1'b0;
    reg  [15:0] netlist_abort_frame = 16'd0;
    reg  [15:0] netlist_abort_lines = 16'd0;

    reg  [3:0]  netlist_content_new_unit;
    wire        netlist_snapshot_commit;
    wire [15:0] component_store_scan_cell = canvas_shadow_data[component_store_scan_addr];
    wire [5:0]  component_store_scan_sprite = component_store_scan_cell[6:1];
    wire [1:0]  component_store_scan_rotation = component_store_scan_cell[8:7];
    wire [11:0] component_store_scan_value = value_shadow_data[component_store_scan_addr];
    wire [3:0]  component_store_scan_unit = value_unit_shadow_data[component_store_scan_addr];
    wire [3:0]  component_store_scan_component_type = component_type_from_sprite(component_store_scan_sprite);
    wire [3:0]  component_store_scan_store_type = component_store_type_from_sprite(component_store_scan_sprite);
    wire        component_store_scan_needs_index = component_type_needs_index(component_store_scan_component_type);
    wire        component_store_scan_is_two_cell = component_type_uses_two_cells(component_store_scan_component_type);
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
    wire        uart_flood_debug_enable;
    wire        uart_cell_debug_enable;
    reg         uart_cell_fetch_start = 1'b0;
    wire        uart_cell_fetch_busy;
    wire        uart_cell_fetch_done;
    wire [15:0] uart_cell_fetch_result;
    reg         uart_cell_p_fetch_start = 1'b0;
    wire        uart_cell_p_fetch_busy;
    wire        uart_cell_p_fetch_done;
    wire [3:0]  uart_cell_p_fetch_result;
    reg         uart_cell_p_pending = 1'b0;
    wire        uart_cell_fetch_ram_ren;
    wire [CANVAS_ADDR_W-1:0] uart_cell_fetch_ram_addr;
    wire        uart_cell_p_ram_ren;
    wire [CANVAS_ADDR_W-1:0] uart_cell_p_ram_addr;
    wire        uart_cell_ram_ren;
    wire [CANVAS_ADDR_W-1:0] uart_cell_ram_addr;
    reg  [15:0] uart_cell_ram_rdata = 16'd0;
    reg         uart_cell_frame_pending = 1'b0;
    reg  [4:0]  uart_cell_debug_i = 5'd0;
    reg  [3:0]  uart_cell_debug_j = 4'd0;
    reg  [4:0]  uart_cell_fetch_i = 5'd0;
    reg  [3:0]  uart_cell_fetch_j = 4'd0;
    reg  [4:0]  uart_cell_debug_i_snap = 5'd0;
    reg  [3:0]  uart_cell_debug_j_snap = 4'd0;
    reg  [15:0] uart_cell_debug_data_snap = 16'd0;
    reg  [3:0]  uart_cell_debug_p_snap = 4'd0;
    reg         uart_cell_packet_pending = 1'b0;
    reg         uart_cell_packet_sending = 1'b0;
    reg         uart_cell_packet_last_char = 1'b0;
    reg         uart_cell_uart_wait_busy = 1'b0;
    reg  [4:0]  uart_cell_packet_index = 5'd0;
    reg         uart_cell_uart_start = 1'b0;
    reg  [7:0]  uart_cell_uart_data = 8'h00;
    wire        uart_cell_uart_busy;
    wire        uart_cell_uart_tx;
    reg         flood_wrapper_start = 1'b0;
    wire        flood_wrapper_busy;
    wire        flood_wrapper_done;
    wire        flood_fetchP_ram_ren;
    wire [CANVAS_ADDR_W-1:0] flood_fetchP_ram_addr;
    reg  [15:0] flood_fetchP_ram_rdata = 16'd0;
    reg         flood_result_fetch_start = 1'b0;
    reg         flood_color_apply_start = 1'b0;
    wire        flood_wrapper_fetchR_done;
    wire [7:0]  flood_wrapper_fetchR_result;
    wire        flood_result_fetch_done;
    wire [7:0]  flood_result_fetch_result;
    reg         flood_color_apply_active = 1'b0;
    reg         flood_color_apply_fetch_busy = 1'b0;
    reg  [CANVAS_ADDR_W-1:0] flood_color_apply_addr = {CANVAS_ADDR_W{1'b0}};
    reg         flood_colors_ready = 1'b0;
    reg         flood_p_fetch_start = 1'b0;
    wire        flood_p_fetch_busy;
    wire        flood_p_fetch_done;
    wire [3:0]  flood_p_fetch_result;
    wire        flood_p_fetch_ram_ren;
    wire [CANVAS_ADDR_W-1:0] flood_p_fetch_ram_addr;
    reg  [15:0] flood_p_fetch_ram_rdata = 16'd0;
    reg         flood_run_pending = 1'b0;
    reg         flood_results_ready = 1'b0;
    // Frontend UART client (SW[5]) only: a netlist snapshot is extracted from
    // a flood that started after the canvas/ComponentStore settled.
    // flood_run_clean: no canvas or value edit (component_store_busy) since
    // the running flood started. netlist_flood_fresh: the last completed
    // flood (colours applied) was clean and no snapshot has used it yet.
    reg         flood_run_clean = 1'b0;
    reg         netlist_flood_fresh = 1'b0;
    reg         flood_result_fetch_busy = 1'b0;
    reg         flood_p_fetch_busy_reg = 1'b0;
    reg         flood_result_value_ready = 1'b0;
    reg         flood_p_value_ready = 1'b0;
    reg         flood_refresh_pending = 1'b0;
    reg  [4:0]  flood_debug_i = 5'd0;
    reg  [3:0]  flood_debug_j = 4'd0;
    reg  [4:0]  flood_fetch_i = 5'd0;
    reg  [3:0]  flood_fetch_j = 4'd0;
    reg  [4:0]  flood_debug_i_snap = 5'd0;
    reg  [3:0]  flood_debug_j_snap = 4'd0;
    reg  [7:0]  flood_debug_result_snap = 8'd0;
    reg  [3:0]  flood_debug_p_snap = 4'd0;
    reg  [3:0]  flood_debug_bg_idx_snap = CANVAS_BG_DEFAULT_COLOR_IDX;
    reg  [7:0]  flood_debug_result_pending = 8'd0;
    reg  [3:0]  flood_debug_p_pending = 4'd0;
    reg  [3:0]  flood_debug_bg_idx_pending = CANVAS_BG_DEFAULT_COLOR_IDX;
    reg         flood_packet_pending = 1'b0;
    reg         flood_packet_sending = 1'b0;
    reg         flood_packet_last_char = 1'b0;
    reg         flood_uart_wait_busy = 1'b0;
    reg  [5:0]  flood_packet_index = 6'd0;
    reg         flood_uart_start = 1'b0;
    reg  [7:0]  flood_uart_data = 8'h00;
    wire        flood_uart_busy;
    wire        flood_uart_tx;
    wire        uart_netlist_debug_enable;
    reg         netlist_extract_start = 1'b0;
    wire        netlist_extract_busy;
    wire        netlist_extract_done;
    wire        netlist_extract_fetch_type_start;
    wire [15:0] netlist_extract_fetch_type_idx;
    wire        netlist_extract_fetch_type_done;
    wire [7:0]  netlist_extract_fetch_type_result;
    wire [3:0]  netlist_extract_fetch_type_result_raw;
    wire        netlist_extract_fetch_x_start;
    wire [15:0] netlist_extract_fetch_x_idx;
    wire        netlist_extract_fetch_x_done;
    wire [7:0]  netlist_extract_fetch_x_result;
    wire [4:0]  netlist_extract_fetch_x_result_raw;
    wire        netlist_extract_fetch_y_start;
    wire [15:0] netlist_extract_fetch_y_idx;
    wire        netlist_extract_fetch_y_done;
    wire [7:0]  netlist_extract_fetch_y_result;
    wire [3:0]  netlist_extract_fetch_y_result_raw;
    wire        netlist_extract_fetch_rot_start;
    wire [15:0] netlist_extract_fetch_rot_idx;
    wire        netlist_extract_fetch_rot_done;
    wire [1:0]  netlist_extract_fetch_rot_result;
    wire        netlist_extract_fetchR_start;
    wire [7:0]  netlist_extract_fetchR_i;
    wire [7:0]  netlist_extract_fetchR_j;
    reg         netlist_extract_fetchR_done = 1'b0;
    reg  [7:0]  netlist_extract_fetchR_result = 8'd0;
    reg         netlist_extract_fetchR_pending = 1'b0;
    reg         netlist_extract_fetchR_issue = 1'b0;
    reg  [7:0]  netlist_extract_fetchR_req_i = 8'd0;
    reg  [7:0]  netlist_extract_fetchR_req_j = 8'd0;
    wire        netlist_extract_fetchCell_start;
    wire [7:0]  netlist_extract_fetchCell_i;
    wire [7:0]  netlist_extract_fetchCell_j;
    wire        netlist_extract_fetchCell_done;
    wire [15:0] netlist_extract_fetchCell_result;
    wire        netlist_extract_fetchCell_ram_ren;
    wire [8:0]  netlist_extract_fetchCell_ram_addr;
    reg  [15:0] netlist_extract_fetchCell_ram_rdata = 16'd0;
    wire        netlist_extract_storeNode0_start;
    wire [15:0] netlist_extract_storeNode0_idx;
    wire [7:0]  netlist_extract_storeNode0_node_i;
    wire        netlist_extract_storeNode0_done;
    wire        netlist_extract_storeNode1_start;
    wire [15:0] netlist_extract_storeNode1_idx;
    wire [7:0]  netlist_extract_storeNode1_node_i;
    wire        netlist_extract_storeNode1_done;
    wire        netlist_extract_type_comp_ren;
    wire [CANVAS_ADDR_W-1:0] netlist_extract_type_comp_addr;
    wire        netlist_extract_x_comp_ren;
    wire [CANVAS_ADDR_W-1:0] netlist_extract_x_comp_addr;
    wire        netlist_extract_y_comp_ren;
    wire [CANVAS_ADDR_W-1:0] netlist_extract_y_comp_addr;
    wire        netlist_extract_rot_comp_ren;
    wire [CANVAS_ADDR_W-1:0] netlist_extract_rot_comp_addr;
    wire        netlist_extract_comp_ren =
        netlist_extract_type_comp_ren || netlist_extract_x_comp_ren ||
        netlist_extract_y_comp_ren || netlist_extract_rot_comp_ren;
    wire [CANVAS_ADDR_W-1:0] netlist_extract_comp_addr =
        netlist_extract_type_comp_ren ? netlist_extract_type_comp_addr :
        netlist_extract_x_comp_ren ? netlist_extract_x_comp_addr :
        netlist_extract_y_comp_ren ? netlist_extract_y_comp_addr :
        netlist_extract_rot_comp_addr;
    wire        netlist_extract_storeNode0_busy_unused;
    wire        netlist_extract_storeNode1_busy_unused;
    wire        netlist_node0_ram_w_en;
    wire [CANVAS_ADDR_W-1:0] netlist_node0_ram_w_addr;
    wire [7:0]  netlist_node0_ram_w_data;
    wire        netlist_node1_ram_w_en;
    wire [CANVAS_ADDR_W-1:0] netlist_node1_ram_w_addr;
    wire [7:0]  netlist_node1_ram_w_data;
    reg  [CANVAS_ADDR_W-1:0] netlist_node_r_addr = {CANVAS_ADDR_W{1'b0}};
    wire [7:0]  netlist_node0_ram_r_data;
    wire [7:0]  netlist_node1_ram_r_data;
    reg         netlist_frame_pending = 1'b0;
    reg  [CANVAS_ADDR_W-1:0] netlist_dump_idx = {CANVAS_ADDR_W{1'b0}};
    reg  [CANVAS_ADDR_W-1:0] netlist_dump_count = {CANVAS_ADDR_W{1'b0}};
    reg         netlist_component_read_request = 1'b0;
    reg         netlist_component_read_pending = 1'b0;
    reg  [COMPONENT_STORE_ENTRY_W-1:0] netlist_component_entry_snap = {COMPONENT_STORE_ENTRY_W{1'b0}};
    reg  [7:0]  netlist_component_node0_snap = 8'd0;
    reg  [7:0]  netlist_component_node1_snap = 8'd0;
    reg         netlist_component_entry_toggle = 1'b0;
    reg         netlist_component_entry_toggle_seen = 1'b0;
    reg  [3:0]  netlist_tx_state = NETLIST_TX_IDLE;
    reg         netlist_snapshot_ready = 1'b0;
    reg  [7:0]  netlist_protocol_node_count = 8'd0;
    reg  [7:0]  netlist_prescan_max_node = 8'd0;
    reg         netlist_prescan_has_node = 1'b0;
    reg  [7:0]  netlist_error_code = FRONTEND_STATUS_OK;
    reg  [15:0] netlist_error_arg = 16'd0;
    // D-016: id of the current snapshot. It increments when an extraction
    // commits after netlist-relevant content changed (netlist_content_dirty),
    // so idle frames resend the same id; the first snapshot after boot is
    // 0001. frontend_snapshot_id_valid: at least one snapshot was extracted
    // (replies before that are stale).
    reg  [15:0] frontend_snapshot_frame = 16'd0;
    reg         frontend_snapshot_id_valid = 1'b0;
    reg  [15:0] frontend_tx_frame = 16'd0;
    // Observability (RTL-4): frame id of the last snapshot whose @NE line was
    // sent completely, and the number of such snapshots (wraps).
    reg  [15:0] netlist_last_sent_frame = 16'd0;
    reg  [15:0] netlist_sent_count = 16'd0;
    reg         frontend_tx_start = 1'b0;
    reg  [1:0]  frontend_tx_mode = FRONTEND_NETLIST_TX_MODE_NB;
    reg  [7:0]  frontend_tx_elem_count = 8'd0;
    reg  [7:0]  frontend_tx_node_count = 8'd0;
    reg  [7:0]  frontend_tx_component_idx = 8'd0;
    reg  [7:0]  frontend_tx_component_kind = 8'd0;
    reg  [7:0]  frontend_tx_component_n0 = 8'd0;
    reg  [7:0]  frontend_tx_component_n1 = 8'd0;
    reg  [11:0] frontend_tx_component_value_bcd = 12'd0;
    reg  [7:0]  frontend_tx_component_unit = 8'd0;
    reg  [7:0]  frontend_tx_error_code = 8'd0;
    reg  [15:0] frontend_tx_error_arg = 16'd0;
    wire        frontend_tx_busy;
    wire        frontend_tx_done;
    wire        netlist_uart_tx;
    wire        frontend_uart_client_enable;
    wire [7:0]  netlist_snap_component_kind =
        frontend_protocol_kind_from_store_type(netlist_component_entry_snap[26:23]);
    wire [7:0]  netlist_snap_component_unit =
        frontend_protocol_unit_from_component_unit(netlist_component_entry_snap[39:36]);
    wire        netlist_snap_kind_supported =
        frontend_protocol_kind_supported(netlist_snap_component_kind);
    wire        netlist_snap_unit_supported =
        frontend_protocol_unit_supported(netlist_snap_component_unit);
    wire [7:0]  netlist_snap_max_node =
        (netlist_component_node0_snap != 8'hFF && netlist_component_node1_snap != 8'hFF) ?
            ((netlist_component_node0_snap >= netlist_component_node1_snap) ? netlist_component_node0_snap : netlist_component_node1_snap) :
        (netlist_component_node0_snap != 8'hFF) ? netlist_component_node0_snap :
        (netlist_component_node1_snap != 8'hFF) ? netlist_component_node1_snap :
        8'd0;
    wire        netlist_snap_has_node =
        (netlist_component_node0_snap != 8'hFF) || (netlist_component_node1_snap != 8'hFF);
    wire [7:0]  frontend_rx_byte;
    wire        frontend_rx_byte_valid;
    wire        frontend_rx_line_valid;
    wire        frontend_rx_line_overflow;
    wire [7:0]  frontend_rx_line_len;
    wire [48*8-1:0] frontend_rx_line_data;
    wire        frontend_voltage_begin_valid;
    wire [15:0] frontend_voltage_begin_frame;
    wire [7:0]  frontend_voltage_begin_node_count;
    wire [7:0]  frontend_voltage_begin_status;
    wire        frontend_voltage_node_valid;
    wire [15:0] frontend_voltage_node_frame;
    wire [7:0]  frontend_voltage_node_idx;
    wire [31:0] frontend_voltage_node_value_bits;
    wire        frontend_voltage_end_valid;
    wire [15:0] frontend_voltage_end_frame;
    wire [7:0]  frontend_voltage_end_node_count;
    wire [7:0]  frontend_voltage_end_status;
    wire        frontend_error_packet_valid;
    wire [15:0] frontend_error_packet_frame;
    wire [7:0]  frontend_error_packet_code;
    wire [15:0] frontend_error_packet_arg;
    wire        frontend_reply_parse_error;
    wire [7:0]  frontend_reply_parse_error_code;
    wire [15:0] frontend_reply_parse_error_arg;
    reg         frontend_reply_stage_active = 1'b0;
    reg         frontend_reply_stage_bank = 1'b0;
    reg  [15:0] frontend_reply_stage_frame = 16'd0;
    reg  [7:0]  frontend_reply_stage_node_count = 8'd0;
    reg  [7:0]  frontend_reply_stage_status = 8'd0;
    reg  [7:0]  frontend_reply_stage_received_count = 8'd0;
    reg         frontend_reply_valid = 1'b0;
    // D-016 observability: replies (@VB..@VE or @ER) rejected because their
    // frame id is not the current snapshot id (wraps), and the last such id.
    reg  [15:0] frontend_reply_stale_count = 16'd0;
    reg  [15:0] frontend_reply_stale_frame = 16'd0;
    reg         frontend_reply_active_bank = 1'b0;
    reg  [15:0] frontend_reply_frame = 16'd0;
    reg  [7:0]  frontend_reply_node_count = 8'd0;
    reg  [7:0]  frontend_reply_status = 8'd0;
    reg         frontend_reply_ram0_w_en = 1'b0;
    reg         frontend_reply_ram1_w_en = 1'b0;
    reg  [4:0]  frontend_reply_ram_w_addr = 5'd0;
    reg  [31:0] frontend_reply_ram_w_data = 32'd0;
    reg  [4:0]  frontend_reply_view_addr = 5'd0;
    wire [31:0] frontend_reply_ram0_r_data;
    wire [31:0] frontend_reply_ram1_r_data;
    wire [31:0] frontend_reply_view_value =
        frontend_reply_active_bank ? frontend_reply_ram1_r_data : frontend_reply_ram0_r_data;
    reg  [4:0]  frontend_reply_view_node = 5'd0;
    reg         frontend_reply_view_upper = 1'b0;
    reg         btnl_prev = 1'b0;
    reg         btnr_prev = 1'b0;
    reg         btnu_prev = 1'b0;
    reg         btnd_prev = 1'b0;
    reg  [19:0] frontend_rx_led_ctr = 20'd0;
    reg  [19:0] frontend_tx_led_ctr = 20'd0;
    wire        frontend_btnl_rise = BTNL && !btnl_prev;
    wire        frontend_btnr_rise = BTNR && !btnr_prev;
    wire        frontend_btnu_rise = BTNU && !btnu_prev;
    wire        frontend_btnd_rise = BTND && !btnd_prev;
    wire [7:0]  netlist_extract_storeNode0_node_i_norm = netlist_extract_storeNode0_node_i;
    wire [7:0]  netlist_extract_storeNode1_node_i_norm = netlist_extract_storeNode1_node_i;
    wire        flood_feature_enable = !clear_canvas_active && (init_cycles >= INIT_DELAY_CYCLES);
    wire        flood_wrapper_fetchR_start;
    wire [7:0]  flood_wrapper_fetchR_i;
    wire [7:0]  flood_wrapper_fetchR_j;
    wire        flood_color_apply_fetch_done;
    // Hold the flood only while a snapshot is being extracted or sent, so its
    // node indices stay consistent. (It used to hold whenever results were
    // ready, which stopped flooding after the first run: with SW[5] = 1 the
    // node colours and the netlist never followed a connectivity edit.)
    wire        netlist_debug_holds_flood =
        frontend_uart_client_enable &&
        (netlist_extract_busy || netlist_snapshot_ready || netlist_component_read_pending ||
         (netlist_tx_state != NETLIST_TX_IDLE));
    // A pending snapshot request with no fresh flood asks for one at once
    // (not only at the next frame tick), e.g. after an edit dirtied the last.
    wire        netlist_flood_request =
        frontend_uart_client_enable && netlist_frame_pending && !netlist_flood_fresh &&
        (netlist_tx_state == NETLIST_TX_IDLE) && !netlist_extract_busy &&
        !flood_wrapper_start && !flood_wrapper_done;
    wire        netlist_extract_port_active =
        frontend_uart_client_enable || netlist_extract_busy || netlist_component_read_pending ||
        (netlist_tx_state != NETLIST_TX_IDLE);
    wire        netlist_extract_comp_ren_active = netlist_extract_port_active && netlist_extract_comp_ren;
    assign hex_display_value = frontend_uart_client_enable ?
        (frontend_reply_view_upper ? frontend_reply_view_value[31:16] : frontend_reply_view_value[15:0]) :
        (backend_fetch_test_enable ?
            {8'hF0, ~backend_test_active, ~backend_frame_pending, ~component_store_busy, ~component_store_read_busy, 4'h0} :
            {8'h00, frontend_reply_status});
    assign circuit_canvas_fg_color_ram_w_en = circuit_canvas_ram_w_en || circuit_canvas_fg_color_override_w_en;
    assign circuit_canvas_fg_color_ram_w_addr = circuit_canvas_fg_color_override_w_en ?
        circuit_canvas_fg_color_override_w_addr : circuit_canvas_ram_w_addr;
    assign circuit_canvas_fg_color_ram_w_data = circuit_canvas_fg_color_override_w_en ?
        circuit_canvas_fg_color_override_w_data : CANVAS_FG_DEFAULT_COLOR_IDX;
    assign circuit_canvas_bg_color_ram_w_en = circuit_canvas_ram_w_en || circuit_canvas_bg_color_override_w_en;
    assign circuit_canvas_bg_color_ram_w_addr = circuit_canvas_bg_color_override_w_en ?
        circuit_canvas_bg_color_override_w_addr : circuit_canvas_ram_w_addr;
    assign circuit_canvas_bg_color_ram_w_data = circuit_canvas_bg_color_override_w_en ?
        circuit_canvas_bg_color_override_w_data : CANVAS_BG_DEFAULT_COLOR_IDX;
    assign flood_wrapper_fetchR_start = flood_color_apply_start ? 1'b1 :
        (netlist_extract_fetchR_issue ? 1'b1 : flood_result_fetch_start);
    assign flood_wrapper_fetchR_i = flood_color_apply_start ?
        {3'd0, canvas_addr_to_i(flood_color_apply_addr)} :
        (netlist_extract_fetchR_issue ? netlist_extract_fetchR_req_i : {3'd0, flood_fetch_i});
    assign flood_wrapper_fetchR_j = flood_color_apply_start ?
        {4'd0, canvas_addr_to_j(flood_color_apply_addr)} :
        (netlist_extract_fetchR_issue ? netlist_extract_fetchR_req_j : {4'd0, flood_fetch_j});
    assign flood_result_fetch_done = flood_wrapper_fetchR_done && flood_result_fetch_busy;
    assign flood_result_fetch_result = flood_wrapper_fetchR_result;
    assign flood_color_apply_fetch_done = flood_wrapper_fetchR_done && flood_color_apply_fetch_busy;
    assign netlist_extract_fetch_type_result = {4'd0, netlist_extract_fetch_type_result_raw};
    assign netlist_extract_fetch_x_result = {3'd0, netlist_extract_fetch_x_result_raw};
    assign netlist_extract_fetch_y_result = {4'd0, netlist_extract_fetch_y_result_raw};
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
    fetchCell uart_cell_fetch_inst (
        .clk(CLK100MHZ),
        .start(uart_cell_fetch_start),
        .busy(uart_cell_fetch_busy),
        .done(uart_cell_fetch_done),
        .i(uart_cell_fetch_i),
        .j(uart_cell_fetch_j),
        .result(uart_cell_fetch_result),
        .ram_ren(uart_cell_fetch_ram_ren),
        .ram_addr(uart_cell_fetch_ram_addr),
        .ram_rdata(uart_cell_ram_rdata)
    );
    fetchP uart_cell_p_fetch_inst (
        .clk(CLK100MHZ),
        .start(uart_cell_p_fetch_start),
        .busy(uart_cell_p_fetch_busy),
        .done(uart_cell_p_fetch_done),
        .i(uart_cell_fetch_i),
        .j(uart_cell_fetch_j),
        .result(uart_cell_p_fetch_result),
        .ram_ren(uart_cell_p_ram_ren),
        .ram_addr(uart_cell_p_ram_addr),
        .ram_rdata(uart_cell_ram_rdata)
    );
    assign uart_cell_ram_ren = uart_cell_fetch_ram_ren | uart_cell_p_ram_ren;
    assign uart_cell_ram_addr = uart_cell_p_ram_ren ? uart_cell_p_ram_addr : uart_cell_fetch_ram_addr;
    FloodingBackendWrapper #(
        .GRID_WIDTH(CANVAS_GRID_W),
        .GRID_HEIGHT(CANVAS_GRID_H)
    ) flooding_backend_wrapper_inst (
        .clk(CLK100MHZ),
        .rst_n(~BTNC),
        .start(flood_wrapper_start),
        .busy(flood_wrapper_busy),
        .done(flood_wrapper_done),
        .fetchP_ram_ren(flood_fetchP_ram_ren),
        .fetchP_ram_addr(flood_fetchP_ram_addr),
        .fetchP_ram_rdata(flood_fetchP_ram_rdata),
        .fetchR_start(flood_wrapper_fetchR_start),
        .fetchR_i(flood_wrapper_fetchR_i),
        .fetchR_j(flood_wrapper_fetchR_j),
        .fetchR_done(flood_wrapper_fetchR_done),
        .fetchR_result(flood_wrapper_fetchR_result)
    );
    fetchComponentType netlist_extract_fetch_type_inst (
        .clk(CLK100MHZ),
        .start(netlist_extract_fetch_type_start),
        .busy(),
        .done(netlist_extract_fetch_type_done),
        .idx(netlist_extract_fetch_type_idx[CANVAS_ADDR_W-1:0]),
        .result(netlist_extract_fetch_type_result_raw),
        .comp_ren(netlist_extract_type_comp_ren),
        .comp_addr(netlist_extract_type_comp_addr),
        .comp_rdata(component_store_ram_r_data)
    );
    fetchAnchorPositionX netlist_extract_fetch_x_inst (
        .clk(CLK100MHZ),
        .start(netlist_extract_fetch_x_start),
        .busy(),
        .done(netlist_extract_fetch_x_done),
        .idx(netlist_extract_fetch_x_idx[CANVAS_ADDR_W-1:0]),
        .result(netlist_extract_fetch_x_result_raw),
        .comp_ren(netlist_extract_x_comp_ren),
        .comp_addr(netlist_extract_x_comp_addr),
        .comp_rdata(component_store_ram_r_data)
    );
    fetchAnchorPositionY netlist_extract_fetch_y_inst (
        .clk(CLK100MHZ),
        .start(netlist_extract_fetch_y_start),
        .busy(),
        .done(netlist_extract_fetch_y_done),
        .idx(netlist_extract_fetch_y_idx[CANVAS_ADDR_W-1:0]),
        .result(netlist_extract_fetch_y_result_raw),
        .comp_ren(netlist_extract_y_comp_ren),
        .comp_addr(netlist_extract_y_comp_addr),
        .comp_rdata(component_store_ram_r_data)
    );
    fetchComponentRotation netlist_extract_fetch_rot_inst (
        .clk(CLK100MHZ),
        .start(netlist_extract_fetch_rot_start),
        .busy(),
        .done(netlist_extract_fetch_rot_done),
        .idx(netlist_extract_fetch_rot_idx[CANVAS_ADDR_W-1:0]),
        .result(netlist_extract_fetch_rot_result),
        .comp_ren(netlist_extract_rot_comp_ren),
        .comp_addr(netlist_extract_rot_comp_addr),
        .comp_rdata(component_store_ram_r_data)
    );
    fetchCell netlist_extract_fetch_cell_inst (
        .clk(CLK100MHZ),
        .start(netlist_extract_fetchCell_start),
        .busy(),
        .done(netlist_extract_fetchCell_done),
        .i(netlist_extract_fetchCell_i[4:0]),
        .j(netlist_extract_fetchCell_j[3:0]),
        .result(netlist_extract_fetchCell_result),
        .ram_ren(netlist_extract_fetchCell_ram_ren),
        .ram_addr(netlist_extract_fetchCell_ram_addr),
        .ram_rdata(netlist_extract_fetchCell_ram_rdata)
    );
    storeNode0 netlist_extract_store_node0_inst (
        .clk(CLK100MHZ),
        .start(netlist_extract_storeNode0_start),
        .busy(netlist_extract_storeNode0_busy_unused),
        .done(netlist_extract_storeNode0_done),
        .idx(netlist_extract_storeNode0_idx[CANVAS_ADDR_W-1:0]),
        .node_i(netlist_extract_storeNode0_node_i_norm),
        .ram0_wen(netlist_node0_ram_w_en),
        .ram0_addr(netlist_node0_ram_w_addr),
        .ram0_wdata(netlist_node0_ram_w_data)
    );
    storeNode1 netlist_extract_store_node1_inst (
        .clk(CLK100MHZ),
        .start(netlist_extract_storeNode1_start),
        .busy(netlist_extract_storeNode1_busy_unused),
        .done(netlist_extract_storeNode1_done),
        .idx(netlist_extract_storeNode1_idx[CANVAS_ADDR_W-1:0]),
        .node_i(netlist_extract_storeNode1_node_i_norm),
        .ram1_wen(netlist_node1_ram_w_en),
        .ram1_addr(netlist_node1_ram_w_addr),
        .ram1_wdata(netlist_node1_ram_w_data)
    );
    SimpleRam #( .WordWidth(8), .WordCount(CANVAS_CELL_COUNT) ) netlist_node0_ram_inst (
        .clk(CLK100MHZ),
        .w_en(netlist_node0_ram_w_en),
        .w_addr(netlist_node0_ram_w_addr),
        .r_addr(netlist_node_r_addr),
        .d_in(netlist_node0_ram_w_data),
        .d_out(netlist_node0_ram_r_data)
    );
    SimpleRam #( .WordWidth(8), .WordCount(CANVAS_CELL_COUNT) ) netlist_node1_ram_inst (
        .clk(CLK100MHZ),
        .w_en(netlist_node1_ram_w_en),
        .w_addr(netlist_node1_ram_w_addr),
        .r_addr(netlist_node_r_addr),
        .d_in(netlist_node1_ram_w_data),
        .d_out(netlist_node1_ram_r_data)
    );
    extract_component_nodes netlist_extract_inst (
        .clk(CLK100MHZ),
        .rst_n(~BTNC),
        .start(netlist_extract_start),
        .busy(netlist_extract_busy),
        .done(netlist_extract_done),
        .par_elem_n({{(32-CANVAS_ADDR_W){1'b0}}, component_store_count}),
        .grid_height(CANVAS_GRID_H),
        .grid_width(CANVAS_GRID_W),
        .fetchComponentType_start(netlist_extract_fetch_type_start),
        .fetchComponentType_idx(netlist_extract_fetch_type_idx),
        .fetchComponentType_done(netlist_extract_fetch_type_done),
        .fetchComponentType_result(netlist_extract_fetch_type_result),
        .fetchAnchorPositionX_start(netlist_extract_fetch_x_start),
        .fetchAnchorPositionX_idx(netlist_extract_fetch_x_idx),
        .fetchAnchorPositionX_done(netlist_extract_fetch_x_done),
        .fetchAnchorPositionX_result(netlist_extract_fetch_x_result),
        .fetchAnchorPositionY_start(netlist_extract_fetch_y_start),
        .fetchAnchorPositionY_idx(netlist_extract_fetch_y_idx),
        .fetchAnchorPositionY_done(netlist_extract_fetch_y_done),
        .fetchAnchorPositionY_result(netlist_extract_fetch_y_result),
        .fetchComponentRotation_start(netlist_extract_fetch_rot_start),
        .fetchComponentRotation_idx(netlist_extract_fetch_rot_idx),
        .fetchComponentRotation_done(netlist_extract_fetch_rot_done),
        .fetchComponentRotation_result(netlist_extract_fetch_rot_result),
        .fetchR_start(netlist_extract_fetchR_start),
        .fetchR_i(netlist_extract_fetchR_i),
        .fetchR_j(netlist_extract_fetchR_j),
        .fetchR_done(netlist_extract_fetchR_done),
        .fetchR_result(netlist_extract_fetchR_result),
        .fetchCell_start(netlist_extract_fetchCell_start),
        .fetchCell_i(netlist_extract_fetchCell_i),
        .fetchCell_j(netlist_extract_fetchCell_j),
        .fetchCell_done(netlist_extract_fetchCell_done),
        .fetchCell_result(netlist_extract_fetchCell_result),
        .storeNode0_start(netlist_extract_storeNode0_start),
        .storeNode0_idx(netlist_extract_storeNode0_idx),
        .storeNode0_node_i(netlist_extract_storeNode0_node_i),
        .storeNode0_done(netlist_extract_storeNode0_done),
        .storeNode1_start(netlist_extract_storeNode1_start),
        .storeNode1_idx(netlist_extract_storeNode1_idx),
        .storeNode1_node_i(netlist_extract_storeNode1_node_i),
        .storeNode1_done(netlist_extract_storeNode1_done)
    );
    fetchP flood_debug_p_fetch_inst (
        .clk(CLK100MHZ),
        .start(flood_p_fetch_start),
        .busy(flood_p_fetch_busy),
        .done(flood_p_fetch_done),
        .i(flood_fetch_i),
        .j(flood_fetch_j),
        .result(flood_p_fetch_result),
        .ram_ren(flood_p_fetch_ram_ren),
        .ram_addr(flood_p_fetch_ram_addr),
        .ram_rdata(flood_p_fetch_ram_rdata)
    );
    UartTx #(
        .ClkHz(100_000_000),
        .BAUD(115200)
    ) uart_cell_debug_tx_inst (
        .clk(CLK100MHZ),
        .start(uart_cell_uart_start),
        .data(uart_cell_uart_data),
        .tx(uart_cell_uart_tx),
        .busy(uart_cell_uart_busy)
    );
    UartTx #(
        .ClkHz(100_000_000),
        .BAUD(115200)
    ) uart_flood_debug_tx_inst (
        .clk(CLK100MHZ),
        .start(flood_uart_start),
        .data(flood_uart_data),
        .tx(flood_uart_tx),
        .busy(flood_uart_busy)
    );
    FrontendNetlistLineTransmitter #(
        .CLK_FREQ_HZ(100_000_000),
        .BAUD(115200)
    ) frontend_netlist_tx_inst (
        .clk(CLK100MHZ),
        .rst_n(~BTNC),
        .start(frontend_tx_start),
        .mode(frontend_tx_mode),
        .frame(frontend_tx_frame),
        .elem_count(frontend_tx_elem_count),
        .node_count(frontend_tx_node_count),
        .component_idx(frontend_tx_component_idx),
        .component_kind(frontend_tx_component_kind),
        .component_n0(frontend_tx_component_n0),
        .component_n1(frontend_tx_component_n1),
        .component_value_bcd(frontend_tx_component_value_bcd),
        .component_unit(frontend_tx_component_unit),
        .error_code(frontend_tx_error_code),
        .error_arg(frontend_tx_error_arg),
        .tx(netlist_uart_tx),
        .busy(frontend_tx_busy),
        .done(frontend_tx_done)
    );
    UartRx #(
        .CLK_FREQ_HZ(100_000_000),
        .BAUD(115200)
    ) frontend_uart_rx_inst (
        .clk(CLK100MHZ),
        .rst_n(~BTNC),
        .rx(RsRx),
        .data(frontend_rx_byte),
        .data_valid(frontend_rx_byte_valid)
    );
    UartLineAssembler #(
        .MAX_LINE_BYTES(48)
    ) frontend_uart_line_assembler_inst (
        .clk(CLK100MHZ),
        .rst_n(~BTNC),
        .byte_valid(frontend_rx_byte_valid),
        .byte_data(frontend_rx_byte),
        .line_valid(frontend_rx_line_valid),
        .line_overflow(frontend_rx_line_overflow),
        .line_len(frontend_rx_line_len),
        .line_data(frontend_rx_line_data)
    );
    FrontendVoltagePacketParser #(
        .MAX_LINE_BYTES(48),
        .MAX_NODES(32)
    ) frontend_voltage_parser_inst (
        .clk(CLK100MHZ),
        .rst_n(~BTNC),
        .line_valid(frontend_rx_line_valid),
        .line_overflow(frontend_rx_line_overflow),
        .line_len(frontend_rx_line_len),
        .line_data(frontend_rx_line_data),
        .voltage_begin_valid(frontend_voltage_begin_valid),
        .voltage_begin_frame(frontend_voltage_begin_frame),
        .voltage_begin_node_count(frontend_voltage_begin_node_count),
        .voltage_begin_status(frontend_voltage_begin_status),
        .voltage_node_valid(frontend_voltage_node_valid),
        .voltage_node_frame(frontend_voltage_node_frame),
        .voltage_node_idx(frontend_voltage_node_idx),
        .voltage_node_value_bits(frontend_voltage_node_value_bits),
        .voltage_end_valid(frontend_voltage_end_valid),
        .voltage_end_frame(frontend_voltage_end_frame),
        .voltage_end_node_count(frontend_voltage_end_node_count),
        .voltage_end_status(frontend_voltage_end_status),
        .error_packet_valid(frontend_error_packet_valid),
        .error_packet_frame(frontend_error_packet_frame),
        .error_packet_code(frontend_error_packet_code),
        .error_packet_arg(frontend_error_packet_arg),
        .parse_error(frontend_reply_parse_error),
        .parse_error_code(frontend_reply_parse_error_code),
        .parse_error_arg(frontend_reply_parse_error_arg)
    );
    SimpleRam #( .WordWidth(32), .WordCount(32) ) frontend_reply_ram0_inst (
        .clk(CLK100MHZ),
        .w_en(frontend_reply_ram0_w_en),
        .w_addr(frontend_reply_ram_w_addr),
        .r_addr(frontend_reply_view_addr),
        .d_in(frontend_reply_ram_w_data),
        .d_out(frontend_reply_ram0_r_data)
    );
    SimpleRam #( .WordWidth(32), .WordCount(32) ) frontend_reply_ram1_inst (
        .clk(CLK100MHZ),
        .w_en(frontend_reply_ram1_w_en),
        .w_addr(frontend_reply_ram_w_addr),
        .r_addr(frontend_reply_view_addr),
        .d_in(frontend_reply_ram_w_data),
        .d_out(frontend_reply_ram1_r_data)
    );
    assign RsTx = frontend_uart_client_enable ? netlist_uart_tx :
        (uart_flood_debug_enable ? flood_uart_tx : uart_cell_uart_tx);
    SimpleRam #( .WordWidth(12), .WordCount(CANVAS_CELL_COUNT) ) component_value_ram_inst (
        .clk(CLK100MHZ), .w_en(value_ram_w_en), .w_addr(value_ram_w_addr),
        .r_addr(interaction_value_read_en ? interaction_value_read_addr : selected_value_store_addr_sys), .d_in(value_ram_w_data), .d_out(value_ram_r_data)
    );
    SimpleRam #( .WordWidth(2), .WordCount(CANVAS_CELL_COUNT) ) component_value_digit_ram_inst (
        .clk(CLK100MHZ), .w_en(value_ram_w_en), .w_addr(value_ram_w_addr),
        .r_addr(interaction_value_read_en ? interaction_value_read_addr : selected_value_store_addr_sys), .d_in(value_digit_ram_w_data), .d_out(value_digit_ram_r_data)
    );
    SimpleRam #( .WordWidth(64), .WordCount(CANVAS_CELL_COUNT) ) component_value_text_ram_inst (
        .clk(CLK100MHZ), .w_en(value_ram_w_en), .w_addr(value_ram_w_addr),
        .r_addr(interaction_value_read_en ? interaction_value_read_addr : selected_value_store_addr_sys), .d_in(value_text_ram_w_data), .d_out(value_text_ram_r_data)
    );
    SimpleRam #( .WordWidth(4), .WordCount(CANVAS_CELL_COUNT) ) component_value_text_len_ram_inst (
        .clk(CLK100MHZ), .w_en(value_ram_w_en), .w_addr(value_ram_w_addr),
        .r_addr(interaction_value_read_en ? interaction_value_read_addr : selected_value_store_addr_sys), .d_in(value_text_len_ram_w_data), .d_out(value_text_len_ram_r_data)
    );

    always @(posedge CLK100MHZ) begin
        if (component_store_read_snapshot_pending) begin
            component_store_read_snapshot_pending <= 1'b0;
            if (component_store_read_owner == COMPONENT_READ_OWNER_NETLIST) begin
                netlist_component_entry_snap <= component_store_ram_r_data;
                netlist_component_node0_snap <= netlist_node0_ram_r_data;
                netlist_component_node1_snap <= netlist_node1_ram_r_data;
                netlist_component_entry_toggle <= ~netlist_component_entry_toggle;
            end
        end else if (component_store_read_busy) begin
            component_store_read_busy <= 1'b0;
            if (component_store_read_owner == COMPONENT_READ_OWNER_NETLIST) begin
                component_store_read_snapshot_pending <= 1'b1;
            end
        end else if (!component_store_busy) begin
            if (backend_comp_ren || netlist_extract_comp_ren_active) begin
                component_store_ram_r_addr <= backend_comp_ren ? backend_comp_addr : netlist_extract_comp_addr;
                component_store_read_addr_latched <= backend_comp_ren ? backend_comp_addr : netlist_extract_comp_addr;
                component_store_read_owner <= COMPONENT_READ_OWNER_BACKEND;
                component_store_read_busy <= 1'b1;
            end else if (netlist_component_read_request) begin
                component_store_ram_r_addr <= netlist_dump_idx;
                component_store_read_addr_latched <= netlist_dump_idx;
                component_store_read_owner <= COMPONENT_READ_OWNER_NETLIST;
                component_store_read_busy <= 1'b1;
            end
        end
    end

    always @(posedge CLK100MHZ) begin
        if (uart_cell_ram_ren) begin
            uart_cell_ram_rdata <= canvas_shadow_data[uart_cell_ram_addr];
        end
    end

    always @(posedge CLK100MHZ) begin
        if (flood_fetchP_ram_ren) begin
            flood_fetchP_ram_rdata <= canvas_shadow_data[flood_fetchP_ram_addr];
        end
    end

    always @(posedge CLK100MHZ) begin
        if (flood_p_fetch_ram_ren) begin
            flood_p_fetch_ram_rdata <= canvas_shadow_data[flood_p_fetch_ram_addr];
        end
    end

    always @(posedge CLK100MHZ) begin
        if (netlist_extract_fetchCell_ram_ren) begin
            netlist_extract_fetchCell_ram_rdata <= canvas_shadow_data[netlist_extract_fetchCell_ram_addr];
        end
    end

    always @(posedge CLK100MHZ) begin
        netlist_extract_fetchR_issue <= 1'b0;
        netlist_extract_fetchR_done <= 1'b0;

        if (!frontend_uart_client_enable) begin
            netlist_extract_fetchR_pending <= 1'b0;
            netlist_extract_fetchR_result <= 8'd0;
            netlist_extract_fetchR_req_i <= 8'd0;
            netlist_extract_fetchR_req_j <= 8'd0;
        end else begin
            if (!netlist_extract_fetchR_pending && netlist_extract_fetchR_start) begin
                netlist_extract_fetchR_req_i <= netlist_extract_fetchR_i;
                netlist_extract_fetchR_req_j <= netlist_extract_fetchR_j;
                netlist_extract_fetchR_pending <= 1'b1;
                netlist_extract_fetchR_issue <= 1'b1;
            end

            if (netlist_extract_fetchR_pending && flood_wrapper_fetchR_done) begin
                netlist_extract_fetchR_result <= flood_wrapper_fetchR_result;
                netlist_extract_fetchR_done <= 1'b1;
                netlist_extract_fetchR_pending <= 1'b0;
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

    always @(posedge CLK100MHZ) begin
        uart_cell_fetch_start <= 1'b0;
        uart_cell_p_fetch_start <= 1'b0;
        uart_cell_uart_start <= 1'b0;

        if (!uart_cell_debug_enable) begin
            uart_cell_frame_pending <= 1'b0;
            uart_cell_debug_i <= 5'd0;
            uart_cell_debug_j <= 4'd0;
            uart_cell_fetch_i <= 5'd0;
            uart_cell_fetch_j <= 4'd0;
            uart_cell_p_pending <= 1'b0;
            uart_cell_packet_pending <= 1'b0;
            uart_cell_packet_sending <= 1'b0;
            uart_cell_packet_last_char <= 1'b0;
            uart_cell_uart_wait_busy <= 1'b0;
            uart_cell_packet_index <= 5'd0;
        end else begin
            if (interaction_frame_tick && !clear_canvas_active && (init_cycles >= INIT_DELAY_CYCLES)) begin
                uart_cell_frame_pending <= 1'b1;
            end

            if (uart_cell_frame_pending && !uart_cell_p_pending && !uart_cell_packet_pending &&
                !uart_cell_packet_sending && !uart_cell_fetch_busy && !uart_cell_p_fetch_busy) begin
                uart_cell_fetch_i <= uart_cell_debug_i;
                uart_cell_fetch_j <= uart_cell_debug_j;
                uart_cell_fetch_start <= 1'b1;
            end

            if (uart_cell_fetch_done) begin
                uart_cell_debug_data_snap <= uart_cell_fetch_result;
                uart_cell_p_pending <= 1'b1;
            end

            if (uart_cell_p_pending && !uart_cell_fetch_busy && !uart_cell_p_fetch_busy) begin
                uart_cell_p_fetch_start <= 1'b1;
                uart_cell_p_pending <= 1'b0;
            end

            if (uart_cell_p_fetch_done) begin
                uart_cell_debug_i_snap <= uart_cell_fetch_i;
                uart_cell_debug_j_snap <= uart_cell_fetch_j;
                uart_cell_debug_p_snap <= uart_cell_p_fetch_result;
                uart_cell_packet_pending <= 1'b1;
                uart_cell_frame_pending <= 1'b0;

                if (uart_cell_fetch_j == CANVAS_GRID_H - 1) begin
                    uart_cell_debug_j <= 4'd0;
                    if (uart_cell_fetch_i == CANVAS_GRID_W - 1) begin
                        uart_cell_debug_i <= 5'd0;
                    end else begin
                        uart_cell_debug_i <= uart_cell_fetch_i + 1'b1;
                    end
                end else begin
                    uart_cell_debug_j <= uart_cell_fetch_j + 1'b1;
                end
            end

            if (!uart_cell_packet_sending) begin
                uart_cell_packet_last_char <= 1'b0;
                if (uart_cell_packet_pending && !uart_cell_uart_busy && !uart_cell_uart_wait_busy) begin
                    uart_cell_uart_data <= uart_cell_packet_char(
                        5'd0,
                        uart_cell_debug_i_snap,
                        uart_cell_debug_j_snap,
                        uart_cell_debug_data_snap,
                        uart_cell_debug_p_snap
                    );
                    uart_cell_uart_start <= 1'b1;
                    uart_cell_packet_pending <= 1'b0;
                    uart_cell_packet_sending <= 1'b1;
                    uart_cell_packet_index <= 5'd1;
                    uart_cell_packet_last_char <= (UART_CELL_PACKET_LEN == 1);
                    uart_cell_uart_wait_busy <= 1'b1;
                end
            end else if (uart_cell_uart_wait_busy) begin
                if (uart_cell_uart_busy) begin
                    uart_cell_uart_wait_busy <= 1'b0;
                end
            end else if (!uart_cell_uart_busy) begin
                if (uart_cell_packet_last_char) begin
                    uart_cell_packet_sending <= 1'b0;
                    uart_cell_packet_last_char <= 1'b0;
                end else begin
                    uart_cell_uart_data <= uart_cell_packet_char(
                        uart_cell_packet_index,
                        uart_cell_debug_i_snap,
                        uart_cell_debug_j_snap,
                        uart_cell_debug_data_snap,
                        uart_cell_debug_p_snap
                    );
                    uart_cell_uart_start <= 1'b1;
                    uart_cell_packet_last_char <= (uart_cell_packet_index == UART_CELL_PACKET_LEN - 1);
                    uart_cell_packet_index <= uart_cell_packet_index + 1'b1;
                    uart_cell_uart_wait_busy <= 1'b1;
                end
            end
        end
    end

    // D-016: an extraction that completes without an edit aborting it fixes
    // the snapshot's content; its id is decided here (before @NB or @ER).
    assign netlist_snapshot_commit =
        frontend_uart_client_enable && !component_store_busy &&
        netlist_extract_done && (netlist_tx_state == NETLIST_TX_EXTRACT_WAIT);

    always @(posedge CLK100MHZ) begin
        netlist_extract_start <= 1'b0;
        netlist_component_read_request <= 1'b0;
        frontend_tx_start <= 1'b0;

        if (frontend_uart_client_enable && netlist_abort_pending) begin
            // Run even during store rebuilding; retain the interrupted id.
            if (interaction_frame_tick) netlist_frame_pending <= 1'b1;
            if (!netlist_abort_sending && !frontend_tx_busy && !frontend_tx_start) begin
                frontend_tx_start <= 1'b1;
                frontend_tx_mode <= FRONTEND_NETLIST_TX_MODE_ER;
                frontend_tx_frame <= netlist_abort_frame;
                frontend_tx_error_code <= 8'h85;
                frontend_tx_error_arg <= netlist_abort_lines;
                netlist_abort_sending <= 1'b1;
            end else if (netlist_abort_sending && frontend_tx_done) begin
                netlist_abort_pending <= 1'b0;
                netlist_abort_sending <= 1'b0;
            end
        end else if (!frontend_uart_client_enable || component_store_busy) begin
            if (!frontend_uart_client_enable) begin
                netlist_abort_pending <= 1'b0;
                netlist_abort_sending <= 1'b0;
                netlist_stream_open <= 1'b0;
            end else if (netlist_stream_open && netlist_tx_state != NETLIST_TX_END_WAIT) begin
                netlist_abort_pending <= 1'b1;
                netlist_abort_frame <= frontend_snapshot_frame;
                netlist_abort_lines <= netlist_stream_lines;
                netlist_stream_open <= 1'b0;
            end else begin
                netlist_stream_open <= 1'b0;
            end
            // An edit aborts the snapshot in progress (the line being sent
            // still completes). Keep the request, and any frame tick that
            // arrives meanwhile, so a fresh snapshot follows once the
            // ComponentStore and the flood have settled.
            netlist_tx_state <= NETLIST_TX_IDLE;
            netlist_snapshot_ready <= 1'b0;
            netlist_frame_pending <= frontend_uart_client_enable &&
                (netlist_frame_pending || interaction_frame_tick || (netlist_tx_state != NETLIST_TX_IDLE));
            netlist_dump_idx <= {CANVAS_ADDR_W{1'b0}};
            netlist_dump_count <= {CANVAS_ADDR_W{1'b0}};
            netlist_component_read_pending <= 1'b0;
            netlist_component_entry_toggle_seen <= netlist_component_entry_toggle;
            netlist_node_r_addr <= {CANVAS_ADDR_W{1'b0}};
            netlist_protocol_node_count <= 8'd0;
            netlist_prescan_max_node <= 8'd0;
            netlist_prescan_has_node <= 1'b0;
            netlist_error_code <= FRONTEND_STATUS_OK;
            netlist_error_arg <= 16'd0;
        end else begin
            if (interaction_frame_tick) begin
                netlist_frame_pending <= 1'b1;
            end

            // Ignore the completion of an extraction that an edit aborted.
            if (netlist_snapshot_commit) begin
                // D-016: a new id only if the content changed since the last
                // extracted snapshot (netlist_content_dirty is cleared by this
                // commit in the canvas write block).
                if (netlist_content_dirty || !frontend_snapshot_id_valid) begin
                    frontend_snapshot_frame <= frontend_snapshot_frame + 1'b1;
                end
                frontend_snapshot_id_valid <= 1'b1;
                netlist_snapshot_ready <= 1'b1;
                netlist_dump_idx <= {CANVAS_ADDR_W{1'b0}};
                netlist_dump_count <= component_store_count;
                netlist_prescan_max_node <= 8'd0;
                netlist_prescan_has_node <= 1'b0;
                netlist_error_code <= FRONTEND_STATUS_OK;
                netlist_error_arg <= 16'd0;
                if (component_store_count == {CANVAS_ADDR_W{1'b0}}) begin
                    netlist_protocol_node_count <= 8'd0;
                    netlist_tx_state <= NETLIST_TX_BEGIN_START;
                end else begin
                    netlist_tx_state <= NETLIST_TX_PRESCAN_REQ;
                end
            end

            if ((netlist_component_entry_toggle != netlist_component_entry_toggle_seen)) begin
                netlist_component_entry_toggle_seen <= netlist_component_entry_toggle;
                netlist_component_read_pending <= 1'b0;
                case (netlist_tx_state)
                    NETLIST_TX_PRESCAN_WAIT: begin
                        if (!netlist_snap_kind_supported) begin
                            netlist_error_code <= FRONTEND_STATUS_UNSUPPORTED_KIND;
                            netlist_error_arg <= {8'h00, netlist_dump_idx[7:0]};
                            netlist_tx_state <= NETLIST_TX_ERR_START;
                        end else if (!netlist_snap_unit_supported) begin
                            netlist_error_code <= FRONTEND_STATUS_UNSUPPORTED_UNIT;
                            netlist_error_arg <= {4'h0, netlist_component_entry_snap[39:36], netlist_dump_idx[7:0]};
                            netlist_tx_state <= NETLIST_TX_ERR_START;
                        end else begin
                            if (netlist_snap_has_node) begin
                                netlist_prescan_has_node <= 1'b1;
                                if (!netlist_prescan_has_node || (netlist_snap_max_node > netlist_prescan_max_node)) begin
                                    netlist_prescan_max_node <= netlist_snap_max_node;
                                end
                            end
                            if ((netlist_dump_idx + 1'b1) >= netlist_dump_count) begin
                                if (netlist_snap_has_node) begin
                                    netlist_protocol_node_count <=
                                        ((netlist_snap_max_node > netlist_prescan_max_node) || !netlist_prescan_has_node) ?
                                            (netlist_snap_max_node + 1'b1) :
                                            (netlist_prescan_max_node + 1'b1);
                                end else begin
                                    netlist_protocol_node_count <=
                                        netlist_prescan_has_node ? (netlist_prescan_max_node + 1'b1) : 8'd0;
                                end
                                netlist_dump_idx <= {CANVAS_ADDR_W{1'b0}};
                                netlist_tx_state <= NETLIST_TX_BEGIN_START;
                            end else begin
                                netlist_dump_idx <= netlist_dump_idx + 1'b1;
                                netlist_tx_state <= NETLIST_TX_PRESCAN_REQ;
                            end
                        end
                    end
                    NETLIST_TX_COMP_WAIT: begin
                        frontend_tx_component_idx <= netlist_dump_idx[7:0];
                        frontend_tx_component_kind <= netlist_snap_component_kind;
                        frontend_tx_component_n0 <= netlist_component_node0_snap;
                        frontend_tx_component_n1 <= netlist_component_node1_snap;
                        frontend_tx_component_value_bcd <= netlist_component_entry_snap[20:9];
                        frontend_tx_component_unit <= netlist_snap_component_unit;
                        netlist_tx_state <= NETLIST_TX_COMP_START;
                    end
                    default: begin end
                endcase
            end

            case (netlist_tx_state)
                NETLIST_TX_IDLE: begin
                    if (netlist_frame_pending && flood_results_ready && flood_colors_ready &&
                        netlist_flood_fresh && !flood_run_pending &&
                        !flood_wrapper_busy && !flood_color_apply_active && !flood_color_apply_fetch_busy &&
                        !netlist_extract_busy && !netlist_component_read_pending && !component_store_read_busy) begin
                        netlist_extract_start <= 1'b1;
                        netlist_frame_pending <= 1'b0;
                        netlist_tx_state <= NETLIST_TX_EXTRACT_WAIT;
                    end
                end
                NETLIST_TX_EXTRACT_WAIT: begin
                    // wait for netlist_extract_done
                end
                NETLIST_TX_PRESCAN_REQ: begin
                    if (!netlist_component_read_pending && !component_store_read_busy && !flood_wrapper_busy &&
                        !flood_color_apply_active && !flood_color_apply_fetch_busy) begin
                        netlist_component_read_request <= 1'b1;
                        netlist_component_read_pending <= 1'b1;
                        netlist_node_r_addr <= netlist_dump_idx;
                        netlist_tx_state <= NETLIST_TX_PRESCAN_WAIT;
                    end
                end
                NETLIST_TX_PRESCAN_WAIT: begin
                    // wait for component-store snapshot toggle
                end
                NETLIST_TX_BEGIN_START: begin
                    if (!frontend_tx_busy) begin
                        frontend_tx_start <= 1'b1;
                        frontend_tx_mode <= FRONTEND_NETLIST_TX_MODE_NB;
                        netlist_stream_open <= 1'b1;
                        netlist_stream_lines <= 16'd0;
                        frontend_tx_frame <= frontend_snapshot_frame;
                        frontend_tx_elem_count <= component_store_count[7:0];
                        frontend_tx_node_count <= netlist_protocol_node_count;
                        frontend_tx_error_code <= FRONTEND_STATUS_OK;
                        frontend_tx_error_arg <= 16'd0;
                        netlist_tx_state <= NETLIST_TX_BEGIN_WAIT;
                    end
                end
                NETLIST_TX_BEGIN_WAIT: begin
                    if (frontend_tx_done) begin
                        if (component_store_count == {CANVAS_ADDR_W{1'b0}}) begin
                            netlist_tx_state <= NETLIST_TX_END_START;
                        end else begin
                            netlist_dump_idx <= {CANVAS_ADDR_W{1'b0}};
                            netlist_tx_state <= NETLIST_TX_COMP_REQ;
                        end
                    end
                end
                NETLIST_TX_COMP_REQ: begin
                    if (!netlist_component_read_pending && !component_store_read_busy && !flood_wrapper_busy &&
                        !flood_color_apply_active && !flood_color_apply_fetch_busy) begin
                        netlist_component_read_request <= 1'b1;
                        netlist_component_read_pending <= 1'b1;
                        netlist_node_r_addr <= netlist_dump_idx;
                        netlist_tx_state <= NETLIST_TX_COMP_WAIT;
                    end
                end
                NETLIST_TX_COMP_WAIT: begin
                    // wait for component-store snapshot toggle
                end
                NETLIST_TX_COMP_START: begin
                    if (!frontend_tx_busy) begin
                        frontend_tx_start <= 1'b1;
                        frontend_tx_mode <= FRONTEND_NETLIST_TX_MODE_NC;
                        netlist_stream_lines <= netlist_stream_lines + 1'b1;
                        frontend_tx_frame <= frontend_snapshot_frame;
                        frontend_tx_elem_count <= component_store_count[7:0];
                        frontend_tx_node_count <= netlist_protocol_node_count;
                        netlist_tx_state <= NETLIST_TX_COMP_WAIT_SEND;
                    end
                end
                NETLIST_TX_COMP_WAIT_SEND: begin
                    if (frontend_tx_done) begin
                        if ((netlist_dump_idx + 1'b1) >= netlist_dump_count) begin
                            netlist_tx_state <= NETLIST_TX_END_START;
                        end else begin
                            netlist_dump_idx <= netlist_dump_idx + 1'b1;
                            netlist_tx_state <= NETLIST_TX_COMP_REQ;
                        end
                    end
                end
                NETLIST_TX_END_START: begin
                    if (!frontend_tx_busy) begin
                        frontend_tx_start <= 1'b1;
                        frontend_tx_mode <= FRONTEND_NETLIST_TX_MODE_NE;
                        frontend_tx_frame <= frontend_snapshot_frame;
                        frontend_tx_elem_count <= component_store_count[7:0];
                        frontend_tx_node_count <= netlist_protocol_node_count;
                        netlist_tx_state <= NETLIST_TX_END_WAIT;
                    end
                end
                NETLIST_TX_END_WAIT: begin
                    if (frontend_tx_done) begin
                        netlist_stream_open <= 1'b0;
                        netlist_snapshot_ready <= 1'b0;
                        netlist_last_sent_frame <= frontend_tx_frame;
                        netlist_sent_count <= netlist_sent_count + 1'b1;
                        netlist_tx_state <= NETLIST_TX_IDLE;
                    end
                end
                NETLIST_TX_ERR_START: begin
                    if (!frontend_tx_busy) begin
                        frontend_tx_start <= 1'b1;
                        frontend_tx_mode <= FRONTEND_NETLIST_TX_MODE_ER;
                        frontend_tx_frame <= frontend_snapshot_frame;
                        frontend_tx_elem_count <= component_store_count[7:0];
                        frontend_tx_node_count <= 8'd0;
                        frontend_tx_error_code <= netlist_error_code;
                        frontend_tx_error_arg <= netlist_error_arg;
                        netlist_tx_state <= NETLIST_TX_ERR_WAIT;
                    end
                end
                NETLIST_TX_ERR_WAIT: begin
                    if (frontend_tx_done) begin
                        netlist_snapshot_ready <= 1'b0;
                        netlist_tx_state <= NETLIST_TX_IDLE;
                    end
                end
                default: begin
                    netlist_tx_state <= NETLIST_TX_IDLE;
                end
            endcase
        end
    end

    wire        frontend_reply_error_current =
        frontend_snapshot_id_valid && (frontend_error_packet_frame == frontend_snapshot_frame);
    wire        frontend_reply_begin_current =
        frontend_snapshot_id_valid && (frontend_voltage_begin_frame == frontend_snapshot_frame);
    wire        frontend_reply_stage_current =
        frontend_snapshot_id_valid && (frontend_reply_stage_frame == frontend_snapshot_frame);

    always @(posedge CLK100MHZ) begin
        frontend_reply_ram0_w_en <= 1'b0;
        frontend_reply_ram1_w_en <= 1'b0;
        frontend_reply_view_addr <= frontend_reply_view_node;

        btnl_prev <= BTNL;
        btnr_prev <= BTNR;
        btnu_prev <= BTNU;
        btnd_prev <= BTND;

        if (frontend_rx_byte_valid) begin
            frontend_rx_led_ctr <= 20'hFFFFF;
        end else if (frontend_rx_led_ctr != 20'd0) begin
            frontend_rx_led_ctr <= frontend_rx_led_ctr - 1'b1;
        end

        if (frontend_tx_busy || frontend_tx_start) begin
            frontend_tx_led_ctr <= 20'hFFFFF;
        end else if (frontend_tx_led_ctr != 20'd0) begin
            frontend_tx_led_ctr <= frontend_tx_led_ctr - 1'b1;
        end

        if (!frontend_uart_client_enable) begin
            frontend_reply_stage_active <= 1'b0;
            frontend_reply_stage_bank <= 1'b0;
            frontend_reply_stage_frame <= 16'd0;
            frontend_reply_stage_node_count <= 8'd0;
            frontend_reply_stage_status <= 8'd0;
            frontend_reply_stage_received_count <= 8'd0;
            frontend_reply_valid <= 1'b0;
            frontend_reply_active_bank <= 1'b0;
            frontend_reply_frame <= 16'd0;
            frontend_reply_node_count <= 8'd0;
            frontend_reply_status <= 8'd0;
            frontend_reply_view_node <= 5'd0;
            frontend_reply_view_upper <= 1'b0;
        end else begin
            if (frontend_btnl_rise) begin
                if (frontend_reply_view_node != 5'd0) begin
                    frontend_reply_view_node <= frontend_reply_view_node - 1'b1;
                end
            end
            if (frontend_btnr_rise) begin
                if (frontend_reply_view_node + 1'b1 < frontend_reply_node_count[4:0]) begin
                    frontend_reply_view_node <= frontend_reply_view_node + 1'b1;
                end
            end
            if (frontend_btnu_rise) begin
                frontend_reply_view_upper <= 1'b1;
            end
            if (frontend_btnd_rise) begin
                frontend_reply_view_upper <= 1'b0;
            end

            if (frontend_reply_parse_error) begin
                frontend_reply_stage_active <= 1'b0;
                frontend_reply_status <= FRONTEND_STATUS_REPLY_PARSE;
            end

            // D-016: a reply is accepted only if its frame id is the current
            // snapshot id. A stale @ER or @VB is dropped (it also cancels a
            // staged reply) and only counted: the stored voltages,
            // reply_valid, reply_frame and reply_status stay as they are.
            if (frontend_error_packet_valid) begin
                frontend_reply_stage_active <= 1'b0;
                if (frontend_reply_error_current) begin
                    frontend_reply_valid <= 1'b0;
                    frontend_reply_frame <= frontend_error_packet_frame;
                    frontend_reply_status <= frontend_error_packet_code;
                end else begin
                    frontend_reply_stale_count <= frontend_reply_stale_count + 1'b1;
                    frontend_reply_stale_frame <= frontend_error_packet_frame;
                end
            end

            if (frontend_voltage_begin_valid && !frontend_reply_begin_current) begin
                frontend_reply_stage_active <= 1'b0;
                frontend_reply_stale_count <= frontend_reply_stale_count + 1'b1;
                frontend_reply_stale_frame <= frontend_voltage_begin_frame;
            end else if (frontend_voltage_begin_valid) begin
                frontend_reply_stage_active <= 1'b1;
                frontend_reply_stage_bank <= ~frontend_reply_active_bank;
                frontend_reply_stage_frame <= frontend_voltage_begin_frame;
                frontend_reply_stage_node_count <= frontend_voltage_begin_node_count;
                frontend_reply_stage_status <= frontend_voltage_begin_status;
                frontend_reply_stage_received_count <= 8'd0;
            end

            if (frontend_reply_stage_active && frontend_voltage_node_valid &&
                (frontend_voltage_node_frame == frontend_reply_stage_frame) &&
                (frontend_voltage_node_idx < 8'd32)) begin
                frontend_reply_ram_w_addr <= frontend_voltage_node_idx[4:0];
                frontend_reply_ram_w_data <= frontend_voltage_node_value_bits;
                if (frontend_reply_stage_bank) begin
                    frontend_reply_ram1_w_en <= 1'b1;
                end else begin
                    frontend_reply_ram0_w_en <= 1'b1;
                end
                frontend_reply_stage_received_count <= frontend_reply_stage_received_count + 1'b1;
            end

            if (frontend_reply_stage_active && frontend_voltage_end_valid &&
                (frontend_voltage_end_frame == frontend_reply_stage_frame) &&
                (frontend_voltage_end_node_count == frontend_reply_stage_node_count) &&
                (frontend_voltage_end_status == frontend_reply_stage_status) &&
                (frontend_reply_stage_received_count == frontend_reply_stage_node_count) &&
                !frontend_reply_stage_current) begin
                // Complete, but a newer snapshot was extracted meanwhile
                // (D-016): stale, dropped like a stale @VB.
                frontend_reply_stage_active <= 1'b0;
                frontend_reply_stale_count <= frontend_reply_stale_count + 1'b1;
                frontend_reply_stale_frame <= frontend_reply_stage_frame;
            end else if (frontend_reply_stage_active && frontend_voltage_end_valid &&
                (frontend_voltage_end_frame == frontend_reply_stage_frame) &&
                (frontend_voltage_end_node_count == frontend_reply_stage_node_count) &&
                (frontend_voltage_end_status == frontend_reply_stage_status) &&
                (frontend_reply_stage_received_count == frontend_reply_stage_node_count)) begin
                frontend_reply_stage_active <= 1'b0;
                frontend_reply_valid <= 1'b1;
                frontend_reply_active_bank <= frontend_reply_stage_bank;
                frontend_reply_frame <= frontend_reply_stage_frame;
                frontend_reply_node_count <= frontend_reply_stage_node_count;
                frontend_reply_status <= frontend_reply_stage_status;
                if (frontend_reply_view_node >= frontend_reply_stage_node_count[4:0] &&
                    frontend_reply_stage_node_count != 8'd0) begin
                    frontend_reply_view_node <= 5'd0;
                end
            end else if (frontend_reply_stage_active && frontend_voltage_end_valid) begin
                frontend_reply_stage_active <= 1'b0;
                frontend_reply_status <= FRONTEND_STATUS_REPLY_PARSE;
            end
        end
    end

    always @(posedge CLK100MHZ) begin
        circuit_canvas_fg_color_override_w_en <= 1'b0;
        circuit_canvas_fg_color_override_w_addr <= {CANVAS_ADDR_W{1'b0}};
        circuit_canvas_fg_color_override_w_data <= CANVAS_FG_DEFAULT_COLOR_IDX;
        circuit_canvas_bg_color_override_w_en <= 1'b0;
        circuit_canvas_bg_color_override_w_addr <= {CANVAS_ADDR_W{1'b0}};
        circuit_canvas_bg_color_override_w_data <= CANVAS_BG_DEFAULT_COLOR_IDX;
        flood_wrapper_start <= 1'b0;
        flood_result_fetch_start <= 1'b0;
        flood_color_apply_start <= 1'b0;
        flood_p_fetch_start <= 1'b0;
        flood_uart_start <= 1'b0;

        if (!flood_feature_enable) begin
            flood_run_pending <= 1'b0;
            flood_results_ready <= 1'b0;
            flood_color_apply_active <= 1'b0;
            flood_color_apply_fetch_busy <= 1'b0;
            flood_color_apply_addr <= {CANVAS_ADDR_W{1'b0}};
            flood_colors_ready <= 1'b0;
            flood_result_fetch_busy <= 1'b0;
            flood_p_fetch_busy_reg <= 1'b0;
            flood_result_value_ready <= 1'b0;
            flood_p_value_ready <= 1'b0;
            flood_refresh_pending <= 1'b0;
            flood_debug_i <= 5'd0;
            flood_debug_j <= 4'd0;
            flood_fetch_i <= 5'd0;
            flood_fetch_j <= 4'd0;
            flood_debug_result_pending <= 8'd0;
            flood_debug_p_pending <= 4'd0;
            flood_debug_bg_idx_pending <= CANVAS_BG_DEFAULT_COLOR_IDX;
            flood_packet_pending <= 1'b0;
            flood_packet_sending <= 1'b0;
            flood_packet_last_char <= 1'b0;
            flood_uart_wait_busy <= 1'b0;
            flood_packet_index <= 6'd0;
            flood_run_clean <= 1'b0;
            netlist_flood_fresh <= 1'b0;
        end else begin
            if ((interaction_frame_tick || netlist_flood_request) && !flood_wrapper_busy && !flood_run_pending &&
                !flood_color_apply_active && !flood_color_apply_fetch_busy &&
                !netlist_debug_holds_flood &&
                (!uart_flood_debug_enable || !flood_results_ready)) begin
                flood_run_pending <= 1'b1;
            end

            if (flood_run_pending && !flood_wrapper_busy &&
                !flood_color_apply_active && !flood_color_apply_fetch_busy &&
                !(frontend_uart_client_enable && component_store_busy)) begin
                flood_wrapper_start <= 1'b1;
                flood_run_pending <= 1'b0;
                flood_run_clean <= 1'b1;
                netlist_flood_fresh <= 1'b0;
                flood_results_ready <= 1'b0;
                flood_color_apply_active <= 1'b0;
                flood_color_apply_fetch_busy <= 1'b0;
                flood_color_apply_addr <= {CANVAS_ADDR_W{1'b0}};
                flood_colors_ready <= 1'b0;
                flood_debug_i <= 5'd0;
                flood_debug_j <= 4'd0;
                flood_fetch_i <= 5'd0;
                flood_fetch_j <= 4'd0;
                flood_result_value_ready <= 1'b0;
                flood_p_value_ready <= 1'b0;
                flood_refresh_pending <= 1'b0;
            end

            if (flood_wrapper_done) begin
                flood_results_ready <= 1'b1;
                flood_color_apply_active <= 1'b1;
                flood_color_apply_fetch_busy <= 1'b0;
                flood_color_apply_addr <= {CANVAS_ADDR_W{1'b0}};
                flood_colors_ready <= 1'b0;
                flood_debug_i <= 5'd0;
                flood_debug_j <= 4'd0;
            end

            if (flood_color_apply_active && !flood_color_apply_fetch_busy) begin
                flood_color_apply_start <= 1'b1;
                flood_color_apply_fetch_busy <= 1'b1;
            end

            if (flood_color_apply_fetch_done) begin
                circuit_canvas_bg_color_override_w_en <= 1'b1;
                circuit_canvas_bg_color_override_w_addr <= flood_color_apply_addr;
                circuit_canvas_bg_color_override_w_data <= node_result_to_bg_palette_idx(
                    flood_wrapper_fetchR_result
                );
                flood_color_apply_fetch_busy <= 1'b0;
                if (flood_color_apply_addr == CANVAS_CELL_COUNT - 1) begin
                    flood_color_apply_active <= 1'b0;
                    flood_colors_ready <= 1'b1;
                    netlist_flood_fresh <= frontend_uart_client_enable && flood_run_clean &&
                                           !component_store_busy;
                end else begin
                    flood_color_apply_addr <= flood_color_apply_addr + 1'b1;
                end
            end

            if (component_store_busy) begin
                flood_run_clean <= 1'b0;
                netlist_flood_fresh <= 1'b0;
            end
            if (netlist_extract_start) begin
                netlist_flood_fresh <= 1'b0;
            end

            if (!uart_flood_debug_enable) begin
                flood_result_fetch_busy <= 1'b0;
                flood_p_fetch_busy_reg <= 1'b0;
                flood_result_value_ready <= 1'b0;
                flood_p_value_ready <= 1'b0;
                flood_refresh_pending <= 1'b0;
                flood_debug_i <= 5'd0;
                flood_debug_j <= 4'd0;
                flood_fetch_i <= 5'd0;
                flood_fetch_j <= 4'd0;
                flood_debug_result_pending <= 8'd0;
                flood_debug_p_pending <= 4'd0;
                flood_debug_bg_idx_pending <= CANVAS_BG_DEFAULT_COLOR_IDX;
                flood_packet_pending <= 1'b0;
                flood_packet_sending <= 1'b0;
                flood_packet_last_char <= 1'b0;
                flood_uart_wait_busy <= 1'b0;
                flood_packet_index <= 6'd0;
            end else begin
                if (interaction_frame_tick && flood_results_ready && flood_colors_ready &&
                    !flood_color_apply_active && !flood_color_apply_fetch_busy &&
                    !flood_result_fetch_busy && !flood_p_fetch_busy_reg &&
                    !flood_packet_pending && !flood_packet_sending && !flood_wrapper_busy) begin
                    flood_fetch_i <= flood_debug_i;
                    flood_fetch_j <= flood_debug_j;
                    flood_result_fetch_start <= 1'b1;
                    flood_p_fetch_start <= 1'b1;
                    flood_result_fetch_busy <= 1'b1;
                    flood_p_fetch_busy_reg <= 1'b1;
                    flood_result_value_ready <= 1'b0;
                    flood_p_value_ready <= 1'b0;
                end

                if (flood_result_fetch_done) begin
                    flood_result_fetch_busy <= 1'b0;
                    flood_debug_result_pending <= flood_result_fetch_result;
                    flood_debug_bg_idx_pending <= node_result_to_bg_palette_idx(flood_result_fetch_result);
                    flood_result_value_ready <= 1'b1;
                end

                if (flood_p_fetch_done) begin
                    flood_p_fetch_busy_reg <= 1'b0;
                    flood_debug_p_pending <= flood_p_fetch_result;
                    flood_p_value_ready <= 1'b1;
                end

                if (flood_result_value_ready && flood_p_value_ready && !flood_packet_pending) begin
                    flood_debug_i_snap <= flood_fetch_i;
                    flood_debug_j_snap <= flood_fetch_j;
                    flood_debug_result_snap <= flood_debug_result_pending;
                    flood_debug_p_snap <= flood_debug_p_pending;
                    flood_debug_bg_idx_snap <= flood_debug_bg_idx_pending;
                    flood_packet_pending <= 1'b1;
                    flood_result_value_ready <= 1'b0;
                    flood_p_value_ready <= 1'b0;

                    if (flood_fetch_j == CANVAS_GRID_H - 1) begin
                        flood_debug_j <= 4'd0;
                        if (flood_fetch_i == CANVAS_GRID_W - 1) begin
                            flood_debug_i <= 5'd0;
                            flood_refresh_pending <= 1'b1;
                        end else begin
                            flood_debug_i <= flood_fetch_i + 1'b1;
                        end
                    end else begin
                        flood_debug_j <= flood_fetch_j + 1'b1;
                    end
                end

                if (!flood_packet_sending) begin
                    flood_packet_last_char <= 1'b0;
                    if (flood_packet_pending && !flood_uart_busy && !flood_uart_wait_busy) begin
                        flood_uart_data <= uart_result_packet_char(
                            5'd0,
                            flood_debug_i_snap,
                            flood_debug_j_snap,
                            flood_debug_result_snap,
                            flood_debug_p_snap,
                            flood_debug_bg_idx_snap
                        );
                        flood_uart_start <= 1'b1;
                        flood_packet_pending <= 1'b0;
                        flood_packet_sending <= 1'b1;
                        flood_packet_index <= 6'd1;
                        flood_packet_last_char <= (UART_RESULT_PACKET_LEN == 1);
                        flood_uart_wait_busy <= 1'b1;
                    end
                end else if (flood_uart_wait_busy) begin
                    if (flood_uart_busy) begin
                        flood_uart_wait_busy <= 1'b0;
                    end
                end else if (!flood_uart_busy) begin
                    if (flood_packet_last_char) begin
                        flood_packet_sending <= 1'b0;
                        flood_packet_last_char <= 1'b0;
                        if (flood_refresh_pending) begin
                            flood_refresh_pending <= 1'b0;
                            flood_results_ready <= 1'b0;
                            flood_run_pending <= 1'b1;
                        end
                    end else begin
                        flood_uart_data <= uart_result_packet_char(
                            flood_packet_index,
                            flood_debug_i_snap,
                            flood_debug_j_snap,
                            flood_debug_result_snap,
                            flood_debug_p_snap,
                            flood_debug_bg_idx_snap
                        );
                        flood_uart_start <= 1'b1;
                        flood_packet_last_char <= (flood_packet_index == UART_RESULT_PACKET_LEN - 1);
                        flood_packet_index <= flood_packet_index + 1'b1;
                        flood_uart_wait_busy <= 1'b1;
                    end
                end
            end
        end
    end

    // =========================================================
    // Component Property Panel - 鍏冧欢灞炴?ф樉绀? (绠?鍖栫増)
    // =========================================================
    assign selected_cell_addr_sys = selected_cell_i_sys + selected_cell_j_sys * CANVAS_GRID_W;
    assign selected_value_store_addr_sys =
        is_right_half_type(selected_cell_data_sys[6:1]) ?
        pair_addr_for_cell(selected_cell_addr_sys, selected_cell_data_sys[6:1], selected_cell_data_sys[8:7]) :
        selected_cell_addr_sys;

    // 榧犳爣鎮仠浣嶇疆璁＄畻 (Canvas 鍖哄煙锛歑0=64, Y0=64)
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
    
    // 榧犳爣鐐瑰嚮杈规部妫?娴?
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
    end
    // 鍚屾榧犳爣鐐瑰嚮 - 璁板綍閫変腑鐨勫崟鍏冩牸
    always @(posedge clk_pixel) begin
        mouse_left_d <= mouse_left_pix;
        if (mouse_left_rising && canvas_mouse_in_bounds) begin
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

    // 绀轰緥鍏冧欢鏁版嵁鍒濆鍖? (涓? init_cycles 涓殑鏁版嵁鐩稿悓)
    always @(posedge clk_pixel) begin
        // 鍒濆鍖栨墍鏈夊崟鍏冧负 0
        // 鍔犺浇绀轰緥鍏冧欢 (鏇存柊鐐烘柊闆昏矾锛氭墍鏈夎綁瑙?+90搴︼紝Tee L/R缈昏綁)
    
    // 璁＄畻鎮仠鐨勫崟鍏冩牸鍦板潃
    
    // 浠庢湰鍦板瓨鍌ㄨ鍙栭?変腑鍗曞厓鏍肩殑鏁版嵁

    // 渚嬪寲灞炴?ч潰鏉?
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

    integer edit_text_idx;
    reg [7:0] edit_text_char;
    always @(*) begin
        edit_text_char = 8'd0;
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
                    edit_value_valid = 1'b1;
                end
            end else if (keyboard_ascii_sys_ff1 == 8'h7F) begin
                edit_value_next_bcd = 12'd0;
                edit_value_next_digits = 2'd0;
                edit_value_next_text = 64'd0;
                edit_value_next_text_len = 4'd0;
                edit_value_valid = 1'b1;
            end
            if (edit_value_valid) begin
                edit_value_next_bcd = 12'd0;
                edit_value_next_digits = 2'd0;
                for (edit_text_idx = 0; edit_text_idx < 8; edit_text_idx = edit_text_idx + 1) begin
                    edit_text_char = text_char_at8(edit_value_next_text, edit_text_idx[2:0]);
                    if ((edit_text_idx < edit_value_next_text_len) &&
                        (edit_text_char >= "0") && (edit_text_char <= "9")) begin
                        if (selected_is_resistor && (edit_value_next_digits < 2'd3)) begin
                            edit_value_next_bcd = bcd_insert_ltr3(edit_value_next_bcd, edit_text_char - "0", edit_value_next_digits);
                            edit_value_next_digits = edit_value_next_digits + 1'b1;
                        end else if (!selected_is_resistor && (edit_value_next_digits < 2'd2)) begin
                            edit_value_next_bcd = bcd_insert_ltr2(edit_value_next_bcd, edit_text_char - "0", edit_value_next_digits);
                            edit_value_next_digits = edit_value_next_digits + 1'b1;
                        end
                    end
                end
            end
        end
    end

    // The VGA keypad consumes the same frame-latched snapshot as the cursor.
    // Its one-pixel-clock event pulse crosses to the system domain via toggle.
    always @(posedge clk_pixel) begin
        if (keyboard_key_valid) begin
            keyboard_event_ascii_pix <= keyboard_key_ascii;
            keyboard_event_toggle_pix <= ~keyboard_event_toggle_pix;
        end
    end
    always @(posedge CLK100MHZ) begin
        keyboard_ascii_sys_ff0 <= keyboard_event_ascii_pix;
        keyboard_ascii_sys_ff1 <= keyboard_ascii_sys_ff0;
    end

    generate
        if (ENABLE_PROP_PANEL) begin : gen_prop_panel
            ComponentPropertyPanel #(
                .PANEL_X(0),
                .PANEL_Y(0),
                .PANEL_W(640),
                .PANEL_H(64)
            ) u_prop_panel (
                .clk_pixel(clk_pixel),
                .frame_tick(vsync_edge),
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
        end else begin : gen_prop_panel_disabled
            assign prop_panel_rendered = 1'b0;
            assign prop_panel_rgb = 12'h000;
        end
    endgenerate
    //灞炴?ч潰鏉夸緥鍖栫粨鏉?

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
        .frame_start_pulse(interaction_frame_tick),
        .mode_select(interaction_mode_select),
        .mouse_x(mouse_xpos),
        .mouse_y(mouse_ypos),
        .mouse_left(mouse_left),
        .mouse_middle(mouse_middle),
        .mouse_right(mouse_right),
        .grid_pos_x(circuit_canvas_grid_pos_x_sys),
        .grid_pos_y(circuit_canvas_grid_pos_y_sys),
        .bg_cmd_ready(controller_cmd_ready),
        .bg_rsp_valid(controller_rsp_valid),
        .bg_rsp_rdata(controller_rsp_rdata),
        .bg_cmd_valid(controller_cmd_valid),
        .bg_cmd_write(controller_cmd_write),
        .bg_cmd_addr(controller_cmd_addr),
        .bg_cmd_wdata(controller_cmd_wdata),
        .frame_done(controller_done),
        .frame_drop_flag(interaction_frame_drop_flag)
    );

    CanvasCommandGuard #(.AddrWidth(CANVAS_ADDR_W), .DataWidth(16)) canvas_command_guard_inst (
        .clk(CLK100MHZ), .reset(BTNC), .mode_select(interaction_mode_select),
        .controller_done(controller_done),
        .cmd_valid(controller_cmd_valid), .cmd_write(controller_cmd_write),
        .cmd_addr(controller_cmd_addr), .cmd_wdata(controller_cmd_wdata),
        .cmd_ready(controller_cmd_ready), .rsp_valid(controller_rsp_valid), .rsp_rdata(controller_rsp_rdata),
        .bg_cmd_valid(interaction_bg_cmd_valid), .bg_cmd_write(interaction_bg_cmd_write),
        .bg_cmd_addr(interaction_bg_cmd_addr), .bg_cmd_wdata(interaction_bg_cmd_wdata),
        .bg_cmd_ready(interaction_bg_cmd_ready), .bg_rsp_valid(interaction_bg_rsp_valid),
        .bg_rsp_rdata(interaction_bg_rsp_rdata), .idle(command_guard_idle),
        .value_read_en(interaction_value_read_en), .value_read_addr(interaction_value_read_addr),
        .copy_value(interaction_copy_value)
    );

    assign backend_fetch_test_enable = ENABLE_BACKEND_FETCH_TEST && SW[2] && !frontend_uart_client_enable;
    assign frontend_uart_client_enable = ENABLE_UART_NETLIST_DEBUG && SW[5];
    assign uart_netlist_debug_enable = frontend_uart_client_enable;
    assign uart_flood_debug_enable = ENABLE_UART_FLOOD_DEBUG && SW[4] && !frontend_uart_client_enable;
    assign uart_cell_debug_enable = ENABLE_UART_CELL_DEBUG && SW[3] && !uart_flood_debug_enable && !frontend_uart_client_enable;
    assign LED =
        frontend_uart_client_enable ?
            {
                frontend_reply_status,
                frontend_reply_valid,
                (frontend_reply_status != FRONTEND_STATUS_OK),
                frontend_reply_view_upper,
                (netlist_tx_state != NETLIST_TX_IDLE),
                (frontend_tx_led_ctr != 20'd0),
                (frontend_rx_led_ctr != 20'd0),
                frontend_reply_view_node[1:0]
            } :
            SW;

    // =========================================================
    // 銆愰噸榛炲渚嬪寲锛氬偝鍏ユ洿鏂扮殑 KEY_W 鍜? KEY_H銆?
    // 纰轰繚閫欒！鐨勫昂瀵歌垏 Top 鐨勯伄缃╁崁鍩熷畬鍏ㄧ浉鍚?
    // =========================================================
    KeyboardVGA #( 
        .KEY_COUNT(19),
        .FONT_SCALE(KEYBOARD_SCALE), 
        .KEYBOARD_X0(KEYBOARD_X), 
        .KEYBOARD_Y0(KEYBOARD_Y),
        .KEY_W(KEY_W),
        .KEY_H(KEY_H)
    ) keyboard_vga_inst (
        .clk_nav(clk_pixel),
        .mouse_x(mouse_xpos_pix), .mouse_y(mouse_ypos_pix), .mouse_left(mouse_left_pix),
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
    // Calculator on OLED 瀹炰緥鍖? (96x64 OLED)
    // =========================================================
    generate
        if (ENABLE_OLED_CALC) begin : gen_oled_calc
            Calculator #(
                .OLED_W(96),
                .OLED_H(64),
                .DATA_W(10)
            ) calculator_inst (
                .clk(CLK100MHZ),
                .clk_nav(oled_clk20hz),      // 浣跨敤鐙珛鐨? 20Hz 瀵艰埅鏃堕挓
                .btnU(BTNU),
                .btnD(BTND),
                .btnL(BTNL),
                .btnR(BTNR),
                .btnC(BTNC),                 // BTNC 鐢ㄤ綔纭閿?
                .x(oled_x_pos),
                .y(oled_y_pos),
                .pixel_rgb(oled_pixel_rgb)
            );

            Oled_Display oled_inst (
                .clk(oled_clk6p25m),         // 浣跨敤鐙珛鐨? 6.25MHz 鍍忕礌鏃堕挓
                .reset(1'b0),                // OLED 濮嬬粓宸ヤ綔锛屼笉澶嶄綅
                .frame_begin(oled_frame_begin),
                .sending_pixels(oled_sending_pixels),
                .sample_pixel(oled_sample_pixel),
                .pixel_index(oled_pixel_index),
                .pixel_data(oled_data),
                .cs(jc_oled[0]),
                .sdin(jc_oled[1]),
                .sclk(jc_oled[3]),
                .d_cn(jc_oled[4]),
                .resn(jc_oled[5]),
                .vccen(jc_oled[6]),
                .pmoden(jc_oled[7])
            );
        end else begin : gen_oled_calc_disabled
            assign oled_frame_begin = 1'b0;
            assign oled_sending_pixels = 1'b0;
            assign oled_sample_pixel = 1'b0;
            assign oled_pixel_index = 13'd0;
            assign oled_pixel_rgb = 16'd0;
        end
    endgenerate
    assign jc_oled[2] = 1'b0;
    // =========================================================
    // 闆诲娉㈠舰 (X: 0 ~ 241, Y: 352 ~ 479)
    // =========================================================
    wire       v_wr_en;
    wire [7:0] v_wr_addr, v_wr_data;
    wire [7:0] v_rd_addr, v_rd_data;
    wire       is_v_wave, is_v_axis, is_v_text;
    wire [7:0] v_max_val; // 銆愭柊澧炪?戞帴鏀堕浕澹撳嘲鍊?
    wire [11:0] v_local_y_12bit = y_pos - 12'd352;

    // =========================================================
    // 闆绘祦娉㈠舰 (X: 242 ~ 483, Y: 352 ~ 479)
    // =========================================================
    wire       i_wr_en;
    wire [7:0] i_wr_addr, i_wr_data;
    wire [7:0] i_rd_addr, i_rd_data;
    wire       is_i_wave, is_i_axis, is_i_text;
    wire [7:0] i_max_val; // 銆愭柊澧炪?戞帴鏀堕浕娴佸嘲鍊?
    wire [11:0] i_local_x_12bit = x_pos - 12'd242;
    wire [11:0] i_local_y_12bit = y_pos - 12'd352;

    generate
        if (ENABLE_WAVEFORMS) begin : gen_waveforms
            DummyDataGenerate v_gen (
                .clk(clk_pixel), .rst_n(wave_rst_n), .vsync_edge(vsync_edge),
                .wr_en(v_wr_en), .wr_addr(v_wr_addr), .wr_data(v_wr_data),
                .max_out(v_max_val)   // 銆愭柊澧炴帴绶氥??
            );
            PingPongBuffer #( .ADDR_WIDTH(8), .DATA_WIDTH(8) ) v_buffer (
                .clk(clk_pixel), .rst_n(wave_rst_n), .vsync_edge(vsync_edge),
                .wr_en(v_wr_en), .wr_addr(v_wr_addr), .wr_data(v_wr_data),
                .rd_en(1'b1),    .rd_addr(v_rd_addr), .rd_data(v_rd_data)
            );
            WaveformPlot #( .IS_VOLTAGE(1) ) v_plot (
                .clk(clk_pixel), .rst_n(wave_rst_n),
                .local_x((x_pos >= 0 && x_pos < 242) ? (x_pos[7:0] + 8'd1) : 8'd0),
                .local_y((y_pos >= 352 && y_pos < 480) ? v_local_y_12bit[7:0] : 8'd0),
                .rd_addr(v_rd_addr), .rd_data(v_rd_data),
                .is_wave_pixel(is_v_wave), .is_axis_pixel(is_v_axis), .is_text_pixel(is_v_text)
            );

            DummyDataGenerate i_gen (
                .clk(clk_pixel), .rst_n(wave_rst_n), .vsync_edge(vsync_edge),
                .wr_en(i_wr_en), .wr_addr(i_wr_addr), .wr_data(i_wr_data),
                .max_out(i_max_val)   // 銆愭柊澧炴帴绶氥??
            );
            PingPongBuffer #( .ADDR_WIDTH(8), .DATA_WIDTH(8) ) i_buffer (
                .clk(clk_pixel), .rst_n(wave_rst_n), .vsync_edge(vsync_edge),
                .wr_en(i_wr_en), .wr_addr(i_wr_addr), .wr_data(i_wr_data),
                .rd_en(1'b1),    .rd_addr(i_rd_addr), .rd_data(i_rd_data)
            );
            WaveformPlot #( .IS_VOLTAGE(0) ) i_plot (
                .clk(clk_pixel), .rst_n(wave_rst_n),
                .local_x((x_pos >= 242 && x_pos < 484) ? (i_local_x_12bit[7:0] + 8'd1) : 8'd0),
                .local_y((y_pos >= 352 && y_pos < 480) ? i_local_y_12bit[7:0] : 8'd0),
                .rd_addr(i_rd_addr), .rd_data(i_rd_data),
                .is_wave_pixel(is_i_wave), .is_axis_pixel(is_i_axis), .is_text_pixel(is_i_text)
            );
        end else begin : gen_waveforms_disabled
            assign v_wr_en = 1'b0;
            assign v_wr_addr = 8'd0;
            assign v_wr_data = 8'd0;
            assign v_rd_addr = 8'd0;
            assign v_rd_data = 8'd0;
            assign is_v_wave = 1'b0;
            assign is_v_axis = 1'b0;
            assign is_v_text = 1'b0;
            assign v_max_val = 8'd0;
            assign i_wr_en = 1'b0;
            assign i_wr_addr = 8'd0;
            assign i_wr_data = 8'd0;
            assign i_rd_addr = 8'd0;
            assign i_rd_data = 8'd0;
            assign is_i_wave = 1'b0;
            assign is_i_axis = 1'b0;
            assign is_i_text = 1'b0;
            assign i_max_val = 8'd0;
        end
    endgenerate
    // =========================================================
    // 銆愭柊澧炪??8-bit Binary 杞? BCD 杞夋彌鍣? (鐢ㄦ柤 OSD 椤ず宄板??)
    // =========================================================
    wire [3:0] v_max_h = v_max_val / 100;
    wire [3:0] v_max_t = (v_max_val % 100) / 10;
    wire [3:0] v_max_u = v_max_val % 10;
    wire [3:0] i_max_h = i_max_val / 100;
    wire [3:0] i_max_t = (i_max_val % 100) / 10;
    wire [3:0] i_max_u = i_max_val % 10;

    // 銆愭柊澧炪?戝嫊鎱嬪瓧鍏冨紩鎿?
    wire v_dyn_text = 1'b0;
    wire i_dyn_text = 1'b0;
    // =========================================================
    // 娉㈠舰褰卞儚娣峰悎閭忚集 (淇京娉㈠舰婧㈠嚭閭婃鐨勫晱椤?)
    // =========================================================
    wire in_v_region = ENABLE_WAVEFORMS && (x_pos >= 0 && x_pos < 242) && (y_pos >= 352 && y_pos < 480);
    wire in_i_region = ENABLE_WAVEFORMS && (x_pos >= 242 && x_pos < 484) && (y_pos >= 352 && y_pos < 480);
    wire dynamic_wave_active = ENABLE_WAVEFORMS && (in_v_region || in_i_region);

    // 鍔犲叆 4 鍍忕礌鐨勫畨鍏ㄩ伄缃╋紝闃叉娉㈠舰钃嬮亷鍎?琛ㄦ澘鐨勫妗?
    wire v_wave_display = is_v_wave && (x_pos >= 4 && x_pos < 238) && (y_pos >= 356 && y_pos < 476);
    wire i_wave_display = is_i_wave && (x_pos >= 246 && x_pos < 480) && (y_pos >= 356 && y_pos < 476);
    // 绲傛サ娣峰悎锛氬姞鍏? v_dyn_text 鑸? i_dyn_text 鐨勫垽鏂凤紝涓﹂’绀洪潚鑹? (12'h0FF)
    wire [11:0] wave_out_rgb;
    assign wave_out_rgb = ENABLE_WAVEFORMS ?
        (in_v_region ?
            (v_dyn_text ? 12'h0FF : is_v_text ? 12'hFFF : v_wave_display ? 12'h0F0 : is_v_axis ? 12'h444 : 12'h111) :
         in_i_region ?
            (i_dyn_text ? 12'h0FF : is_i_text ? 12'hFFF : i_wave_display ? 12'hFF0 : is_i_axis ? 12'h444 : 12'h111) :
         12'h000) :
        12'h000;

    // RAM 鍒濆鍖栬垏婊戦紶閲嶇疆
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
        keyboard_event_sync0 <= keyboard_event_toggle_pix;
        keyboard_event_sync1 <= keyboard_event_sync0;
        component_store_change_this_cycle = 1'b0;
        // D-016: boot (init_cycles < INIT_DELAY_CYCLES) always counts as a
        // content change; every later write compares with the shadow copies.
        netlist_content_change_this_cycle = (init_cycles < INIT_DELAY_CYCLES);
        netlist_content_new_unit = COMPONENT_UNIT_NONE;

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
            // Clearing an empty cell is no content change.
            if (canvas_shadow_data[clear_canvas_addr][8:0] != 9'd0) begin
                netlist_content_change_this_cycle = 1'b1;
            end

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
            // D-015: the boot voltage source is turned 180 degrees so its +
            // half (the anchor, n0) faces the right rail: partner (sprite 8,
            // rotation 2) at (3,2), anchor (sprite 7, rotation 2) at (4,2).
            // Both cells hold the value 010; flow bit 9 stays 0 (rightward).
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd39;
            circuit_canvas_ram_w_data <= 16'h0111;
            value_ram_w_en <= 1'b1;
            value_ram_w_addr <= 9'd39;
            value_ram_w_data <= 12'h010;
            value_digit_ram_w_data <= 2'd2;
            value_text_ram_w_data <= {"1", "0", 48'd0};
            value_text_len_ram_w_data <= 4'd2;
            canvas_shadow_data[9'd39] <= 16'h0111;
            value_shadow_data[9'd39] <= 12'h010;
            value_unit_shadow_data[9'd39] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 2) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd40;
            circuit_canvas_ram_w_data <= 16'h010F;
            value_ram_w_en <= 1'b1;
            value_ram_w_addr <= 9'd40;
            value_ram_w_data <= 12'h010;
            value_digit_ram_w_data <= 2'd2;
            value_text_ram_w_data <= {"1", "0", 48'd0};
            value_text_len_ram_w_data <= 4'd2;
            canvas_shadow_data[9'd40] <= 16'h010F;
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
            circuit_canvas_ram_w_data <= 16'h0085;
            canvas_shadow_data[9'd110] <= 16'h0085;
            value_shadow_data[9'd110] <= 12'd0;
            value_unit_shadow_data[9'd110] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 13) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd111;
            circuit_canvas_ram_w_data <= 16'h020B;
            value_ram_w_en <= 1'b1;
            value_ram_w_addr <= 9'd111;
            value_ram_w_data <= 12'h100;
            value_digit_ram_w_data <= 2'd3;
            value_text_ram_w_data <= {"1", "0", "0", 40'd0};
            value_text_len_ram_w_data <= 4'd3;
            canvas_shadow_data[9'd111] <= 16'h020B;
            value_shadow_data[9'd111] <= 12'h100;
            value_unit_shadow_data[9'd111] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 14) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd112;
            circuit_canvas_ram_w_data <= 16'h020D;
            value_ram_w_en <= 1'b1;
            value_ram_w_addr <= 9'd112;
            value_ram_w_data <= 12'h100;
            value_digit_ram_w_data <= 2'd3;
            value_text_ram_w_data <= {"1", "0", "0", 40'd0};
            value_text_len_ram_w_data <= 4'd3;
            canvas_shadow_data[9'd112] <= 16'h020D;
            value_shadow_data[9'd112] <= 12'h100;
            value_unit_shadow_data[9'd112] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 15) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd113;
            circuit_canvas_ram_w_data <= 16'h0183;
            canvas_shadow_data[9'd113] <= 16'h0183;
            value_shadow_data[9'd113] <= 12'd0;
            value_unit_shadow_data[9'd113] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (init_cycles == CANVAS_CELL_COUNT + 16) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd128;
            circuit_canvas_ram_w_data <= 16'h009F;
            canvas_shadow_data[9'd128] <= 16'h009F;
            value_shadow_data[9'd128] <= 12'd0;
            value_unit_shadow_data[9'd128] <= COMPONENT_UNIT_NONE;
            component_store_change_this_cycle = 1'b1;
        end else if (pending_pair_value_write) begin
            netlist_content_new_unit = component_unit_code_from_text(
                pending_pair_value_text,
                pending_pair_value_text_len
            );
            if ((value_shadow_data[pending_pair_value_addr] != pending_pair_value_data) ||
                (value_unit_shadow_data[pending_pair_value_addr] != netlist_content_new_unit)) begin
                netlist_content_change_this_cycle = 1'b1;
            end
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
            // Text-only keypad edits (e.g. a literal '.', a fourth digit, DEL
            // of a suffix that keeps the unit) leave BCD and unit unchanged.
            netlist_content_new_unit = component_unit_code_from_text(
                edit_value_next_text,
                edit_value_next_text_len
            );
            if ((value_shadow_data[selected_cell_addr_sys] != edit_value_next_bcd) ||
                (value_unit_shadow_data[selected_cell_addr_sys] != netlist_content_new_unit)) begin
                netlist_content_change_this_cycle = 1'b1;
            end
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
                // Only the cell word matters here: the value copied to a new
                // partner cell or cleared with a cell is not read by the
                // netlist (the ComponentStore takes it from the origin cell).
                if (canvas_shadow_data[interaction_bg_cmd_addr][8:0] != interaction_bg_cmd_wdata[8:0]) begin
                    netlist_content_change_this_cycle = 1'b1;
                end
                if (interaction_copy_value) begin
                    // Rotation moves the partner's value, unit and display text
                    // from the anchor before clearing the vacated cell.
                    value_ram_w_en <= 1'b1;
                    value_ram_w_addr <= interaction_bg_cmd_addr;
                    value_ram_w_data <= value_ram_r_data;
                    value_digit_ram_w_data <= value_digit_ram_r_data;
                    value_text_ram_w_data <= value_text_ram_r_data;
                    value_text_len_ram_w_data <= value_text_len_ram_r_data;
                    value_shadow_data[interaction_bg_cmd_addr] <= value_shadow_data[interaction_value_read_addr];
                    value_unit_shadow_data[interaction_bg_cmd_addr] <= value_unit_shadow_data[interaction_value_read_addr];
                end else if (interaction_bg_cmd_wdata == 16'd0) begin
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
                    component_store_scan_store_type,
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

        // D-016: a change in the commit cycle wins, so the next snapshot gets
        // a new id (the committed one is aborted by component_store_busy).
        if (netlist_content_change_this_cycle) begin
            netlist_content_dirty <= 1'b1;
        end else if (netlist_snapshot_commit) begin
            netlist_content_dirty <= 1'b0;
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
        end else if (keyboard_region_active) begin
            rgb <= keyboard_rgb;
        end else if (circuit_canvas_rendered) begin
            // 鐢佃矾鏄剧ず
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
