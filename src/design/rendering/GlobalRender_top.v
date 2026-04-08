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
    assign SEG = 8'hFF;
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
    wire [11:0] selected_cell_i_sys = selected_cell_i_sys_ff1;
    wire [11:0] selected_cell_j_sys = selected_cell_j_sys_ff1;
    wire        has_selection_sys = has_selection_sys_ff1;
    wire        value_edit_active_sys = value_edit_active_sys_ff1;
    wire [63:0] selected_value_text_ui = selected_value_text_ui_ff1;
    wire [3:0]  selected_value_text_len_ui = selected_value_text_len_ui_ff1;
    wire        mouse_left_rising;
    
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
    wire [CANVAS_ADDR_W-1:0] selected_cell_addr_sys;
    SimpleRam #( .WordWidth(12), .WordCount(CANVAS_CELL_COUNT) ) component_value_ram_inst (
        .clk(CLK100MHZ), .w_en(value_ram_w_en), .w_addr(value_ram_w_addr),
        .r_addr(selected_cell_addr_sys), .d_in(value_ram_w_data), .d_out(value_ram_r_data)
    );
    SimpleRam #( .WordWidth(2), .WordCount(CANVAS_CELL_COUNT) ) component_value_digit_ram_inst (
        .clk(CLK100MHZ), .w_en(value_ram_w_en), .w_addr(value_ram_w_addr),
        .r_addr(selected_cell_addr_sys), .d_in(value_digit_ram_w_data), .d_out(value_digit_ram_r_data)
    );
    SimpleRam #( .WordWidth(64), .WordCount(CANVAS_CELL_COUNT) ) component_value_text_ram_inst (
        .clk(CLK100MHZ), .w_en(value_ram_w_en), .w_addr(value_ram_w_addr),
        .r_addr(selected_cell_addr_sys), .d_in(value_text_ram_w_data), .d_out(value_text_ram_r_data)
    );
    SimpleRam #( .WordWidth(4), .WordCount(CANVAS_CELL_COUNT) ) component_value_text_len_ram_inst (
        .clk(CLK100MHZ), .w_en(value_ram_w_en), .w_addr(value_ram_w_addr),
        .r_addr(selected_cell_addr_sys), .d_in(value_text_len_ram_w_data), .d_out(value_text_len_ram_r_data)
    );

    // =========================================================
    // Component Property Panel - 元件属性显示 (简化版)
    // =========================================================
    assign selected_cell_addr_sys = selected_cell_i_sys + selected_cell_j_sys * CANVAS_GRID_W;

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
    end

    always @(posedge clk_pixel) begin
        selected_cell_data_ff0 <= selected_cell_data_sys;
        selected_cell_data_ff1 <= selected_cell_data_ff0;
        selected_cell_data <= selected_cell_data_ff1;
        selected_value_text_ui_ff0 <= selected_value_text;
        selected_value_text_ui_ff1 <= selected_value_text_ui_ff0;
        selected_value_text_len_ui_ff0 <= selected_value_text_len;
        selected_value_text_len_ui_ff1 <= selected_value_text_len_ui_ff0;
    end
    // 同步鼠标点击 - 记录选中的单元格
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
    wire show_matrix = SW[0];

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
        end else if (init_cycles == CANVAS_CELL_COUNT + 0) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd38;
            circuit_canvas_ram_w_data <= 16'h0083;
            canvas_shadow_data[9'd38] <= 16'h0083;
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
        end else if (init_cycles == CANVAS_CELL_COUNT + 3) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd41;
            circuit_canvas_ram_w_data <= 16'h0103;
            canvas_shadow_data[9'd41] <= 16'h0103;
        end else if (init_cycles == CANVAS_CELL_COUNT + 4) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd56;
            circuit_canvas_ram_w_data <= 16'h0281;
            canvas_shadow_data[9'd56] <= 16'h0281;
        end else if (init_cycles == CANVAS_CELL_COUNT + 5) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd59;
            circuit_canvas_ram_w_data <= 16'h0081;
            canvas_shadow_data[9'd59] <= 16'h0081;
        end else if (init_cycles == CANVAS_CELL_COUNT + 6) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd74;
            circuit_canvas_ram_w_data <= 16'h0285;
            canvas_shadow_data[9'd74] <= 16'h0285;
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
        end else if (init_cycles == CANVAS_CELL_COUNT + 9) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd77;
            circuit_canvas_ram_w_data <= 16'h0185;
            canvas_shadow_data[9'd77] <= 16'h0185;
        end else if (init_cycles == CANVAS_CELL_COUNT + 10) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd92;
            circuit_canvas_ram_w_data <= 16'h0281;
            canvas_shadow_data[9'd92] <= 16'h0281;
        end else if (init_cycles == CANVAS_CELL_COUNT + 11) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd95;
            circuit_canvas_ram_w_data <= 16'h0081;
            canvas_shadow_data[9'd95] <= 16'h0081;
        end else if (init_cycles == CANVAS_CELL_COUNT + 12) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd110;
            circuit_canvas_ram_w_data <= 16'h0003;
            canvas_shadow_data[9'd110] <= 16'h0003;
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
        end else if (init_cycles == CANVAS_CELL_COUNT + 15) begin
            circuit_canvas_ram_w_en <= 1'b1;
            circuit_canvas_ram_w_addr <= 9'd113;
            circuit_canvas_ram_w_data <= 16'h0183;
            canvas_shadow_data[9'd113] <= 16'h0183;
        end else if (pending_pair_value_write) begin
            value_ram_w_en <= 1'b1;
            value_ram_w_addr <= pending_pair_value_addr;
            value_ram_w_data <= pending_pair_value_data;
            value_digit_ram_w_data <= pending_pair_value_digits;
            value_text_ram_w_data <= pending_pair_value_text;
            value_text_len_ram_w_data <= pending_pair_value_text_len;
            pending_pair_value_write <= 1'b0;
        end else if (keyboard_edit_event && edit_value_valid) begin
            value_ram_w_en <= 1'b1;
            value_ram_w_addr <= selected_cell_addr_sys;
            value_ram_w_data <= edit_value_next_bcd;
            value_digit_ram_w_data <= edit_value_next_digits;
            value_text_ram_w_data <= edit_value_next_text;
            value_text_len_ram_w_data <= edit_value_next_text_len;
            selected_value_bcd <= edit_value_next_bcd;
            selected_value_digits <= edit_value_next_digits;
            selected_value_text <= edit_value_next_text;
            selected_value_text_len <= edit_value_next_text_len;

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
                if (interaction_bg_cmd_wdata == 16'd0) begin
                    value_ram_w_en <= 1'b1;
                    value_ram_w_addr <= interaction_bg_cmd_addr;
                    value_ram_w_data <= 12'd0;
                    value_digit_ram_w_data <= 2'd0;
                    value_text_ram_w_data <= 64'd0;
                    value_text_len_ram_w_data <= 4'd0;
                end
            end else begin
                interaction_bg_rsp_valid <= 1'b1;
                interaction_bg_rsp_rdata <= canvas_shadow_data[interaction_bg_cmd_addr];
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

        title_active = 1'b0;
        if (title_active && !dynamic_wave_active) ui_rgb = 12'hFFF;
    end

    always @(posedge clk_pixel) begin
        if (!video_on) begin
            rgb <= BLACK;
        end else if (mouse_display_enable) begin
            rgb <= mouse_rgb;
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
