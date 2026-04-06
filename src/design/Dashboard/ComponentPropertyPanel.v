`timescale 1ns / 1ps
/*
 * ============================================================================
 * ComponentPropertyPanel - 电路元件属性面板模块
 * ============================================================================
 * 
 * 【功能概述】
 *   在屏幕顶部 640x64 像素区域显示当前选中电路元件的属性信息。
 *   支持电阻、电压源、电流源等元件类型的动态属性显示。
 * 
 * 【显示内容】
 *   第一行：元件类型名称 (放大 2 倍显示)
 *          - "Resistor" (电阻)
 *          - "Voltage Source" (电压源)
 *          - "Current Source" (电流源)
 *   第二行：元件参数值
 *          - 电阻："Value: XXX Ohm"
 *          - 电压："Value: X.X V"
 *          - 电流："Value: XX mA"
 *   第三行：元件坐标位置 "Pos: (XX, XX)"
 * 
 * 【元件类型编码】(与 InteractionController 一致)
 *   SPRITE_RES_LEFT   = 6'd5   电阻左端
 *   SPRITE_RES_RIGHT  = 6'd6   电阻右端
 *   SPRITE_VOLT_LEFT  = 6'd7   电压源左端
 *   SPRITE_VOLT_RIGHT = 6'd8   电压源右端
 *   SPRITE_CURR_LEFT  = 6'd9   电流源左端
 *   SPRITE_CURR_RIGHT = 6'd10  电流源右端
 * 
 * 【数据格式】
 *   selected_cell_data[15:0] = {7'b0, rotation[1:0], sprite_type[5:0], enable}
 *   - [15:9]  : 7 位模式 (未使用)
 *   - [8:7]   : 2 位旋转角度
 *   - [6:1]   : 6 位元件类型
 *   - [0]     : 1 位使能标志
 * 
 * 【依赖模块】
 *   - DynamicTextBox : 动态文本显示模块
 *   - FontROM        : 8x8 ASCII 字库
 * 
 * ============================================================================
 * 【例化演示】
 * ============================================================================
 * 
 * // 1. 声明信号
 * wire        prop_panel_rendered;
 * wire [11:0] prop_panel_rgb;
 * reg  [11:0] selected_cell_i;
 * reg  [11:0] selected_cell_j;
 * reg  [15:0] selected_cell_data;
 * reg         has_selection;
 * 
 * // 2. 计算选中单元格 (鼠标点击时)
 * wire [11:0] mouse_cell_i = (mouse_xpos >= CANVAS_X0) ? 
 *                            ((mouse_xpos - CANVAS_X0) / 32) : 12'd0;
 * wire [11:0] mouse_cell_j = (mouse_ypos >= CANVAS_Y0) ? 
 *                            ((mouse_ypos - CANVAS_Y0) / 32) : 12'd0;
 * 
 * always @(posedge clk_pixel) begin
 *     if (mouse_left_rising) begin
 *         selected_cell_i <= mouse_cell_i;
 *         selected_cell_j <= mouse_cell_j;
 *         has_selection <= 1'b1;
 *         selected_cell_data <= component_data[mouse_cell_i + mouse_cell_j * 16];
 *     end
 * end
 * 
 * // 3. 例化模块
 * ComponentPropertyPanel #(
 *     .PANEL_X(0),              // 面板 X 起始位置 (屏幕左上角为 0,0)
 *     .PANEL_Y(0),              // 面板 Y 起始位置 (顶部 64 像素区域)
 *     .PANEL_W(640),            // 面板宽度 (占满屏幕宽度)
 *     .PANEL_H(64),             // 面板高度 (64 像素)
 *     .MAX_CHARS(32)            // 最大字符数 (默认 32)
 * ) u_prop_panel (
 *     .clk_pixel(clk_pixel),            // 像素时钟 (25MHz for 640x480@60Hz)
 *     .hcount(x_pos),                   // 当前像素 X 坐标 (来自 VGA 控制器)
 *     .vcount(y_pos),                   // 当前像素 Y 坐标 (来自 VGA 控制器)
 *     .video_on(video_on),              // 视频使能信号 (消隐期间为低)
 *     .mouse_cell_i(mouse_cell_i),      // 鼠标所在单元格行 (0-15)
 *     .mouse_cell_j(mouse_cell_j),      // 鼠标所在单元格列 (0-15)
 *     .selected_cell_data(selected_cell_data),  // 选中单元格的 16 位数据
 *     .has_selection(has_selection),    // 是否有选中元件标志
 *     .selected_cell_i(selected_cell_i),  // 选中单元格行坐标
 *     .selected_cell_j(selected_cell_j),  // 选中单元格列坐标
 *     .panel_rendered(prop_panel_rendered),   // 面板渲染输出 (用于 RGB 混合)
 *     .panel_rgb(prop_panel_rgb)              // 面板 RGB 输出 (12 位 444 格式)
 * );
 * 
 * // 4. RGB 混合 (在顶层模块中)
 * always @(posedge clk_pixel) begin
 *     if (!video_on)
 *         rgb <= 12'h000;
 *     else if (prop_panel_rendered && video_on)
 *         rgb <= prop_panel_rgb;      // 属性面板优先
 *     else if (circuit_canvas_rendered)
 *         rgb <= circuit_canvas_rgb;  // 电路画布
 *     else
 *         rgb <= ui_rgb;              // UI 背景
 * end
 * 
 * ============================================================================
 * 【扩展新元件类型】
 * ============================================================================
 * 
 * // 1. 添加元件类型参数
 * localparam [5:0] SPRITE_NEW_ELEMENT = 6'dXX;
 * 
 * // 2. 在类型判断中添加
 * case (cell_sprite_type)
 *     SPRITE_NEW_ELEMENT: is_new_element = 1'b1;
 *     ...
 * endcase
 * 
 * // 3. 在显示逻辑中添加
 * is_new_element: begin
 *     // 设置标签 "New Element"
 *     label_data[MAX_CHARS * 8 - 1 -: 8] = "N";
 *     label_data[MAX_CHARS * 8 - 9 -: 8] = "e";
 *     ...
 *     label_len = 5'd11;
 *     
 *     // 设置值 "Value: XXX"
 *     value_data[MAX_CHARS * 8 - 1 -: 8] = "V";
 *     ...
 *     value_len = 5'dXX;
 * end
 * 
 * ============================================================================
 * 【注意事项】
 * ============================================================================
 * 
 * 1. video_on 信号：必须正确连接，确保在视频消隐期间不输出信号
 * 2. 时钟域：使用 clk_pixel (像素时钟)，与 VGA 时序同步
 * 3. 文本长度：MAX_CHARS 必须与 DynamicTextBox 一致
 * 4. 数值来源：当前使用坐标生成模拟值，实际应用需从元件参数 RAM 读取
 * 5. 布局调整：修改 LABEL_Y、VALUE_Y、COORD_Y 可调整文本垂直位置
 * 
 * ============================================================================
 */

module ComponentPropertyPanel #(
    parameter integer PANEL_X = 0,          // 面板 X 起始位置
    parameter integer PANEL_Y = 0,          // 面板 Y 起始位置
    parameter integer PANEL_W = 640,        // 面板宽度
    parameter integer PANEL_H = 64,         // 面板高度
    parameter integer MAX_CHARS = 32        // 最大字符数
)(
    input wire clk_pixel,                   // 像素时钟
    input wire [11:0] hcount,               // 当前像素 X 坐标
    input wire [11:0] vcount,               // 当前像素 Y 坐标
    input wire video_on,                    // 视频使能信号

    input wire [11:0] mouse_cell_i,         // 鼠标所在单元格行
    input wire [11:0] mouse_cell_j,         // 鼠标所在单元格列

    input wire [15:0] selected_cell_data,   // 选中单元格数据 [15:0]
    input wire has_selection,               // 选中标志
    input wire [11:0] selected_cell_i,      // 选中单元格行坐标
    input wire [11:0] selected_cell_j,      // 选中单元格列坐标

    output reg panel_rendered,              // 面板渲染输出
    output reg [11:0] panel_rgb             // 面板 RGB 输出 (12 位 444 格式)
);

    // ========================================================================
    // 内部参数定义
    // ========================================================================
    localparam [11:0] COLOR_BG = 12'hECC;       // 背景色 (浅粉色)
    localparam [11:0] COLOR_BORDER = 12'h888;   // 边框颜色 (灰色)

    // 元件类型定义 (与 InteractionController 一致)
    localparam [5:0] SPRITE_RES_LEFT   = 6'd5;
    localparam [5:0] SPRITE_RES_RIGHT  = 6'd6;
    localparam [5:0] SPRITE_VOLT_LEFT  = 6'd7;
    localparam [5:0] SPRITE_VOLT_RIGHT = 6'd8;
    localparam [5:0] SPRITE_CURR_LEFT  = 6'd9;
    localparam [5:0] SPRITE_CURR_RIGHT = 6'd10;

    // 面板布局 - 优化为 640x64 像素区域
    localparam integer PANEL_PAD = 8;
    localparam integer LABEL_X = PANEL_X + PANEL_PAD;
    localparam integer LABEL_Y = PANEL_Y + 6;         // 顶部留 6 像素，scale=2 字高 16 像素
    localparam integer VALUE_X = PANEL_X + PANEL_PAD;
    localparam integer VALUE_Y = PANEL_Y + 28;        // LABEL 下方 (6+16+6=28)
    localparam integer COORD_X = PANEL_X + PANEL_PAD;
    localparam integer COORD_Y = PANEL_Y + 50;        // VALUE 下方 (28+8+14=50)

    // ========================================================================
    // 解码单元格数据
    // ========================================================================
    // selected_cell_data 格式：{7'b0, rotation[1:0], sprite_type[5:0], enable}
    wire [5:0] cell_sprite_type = selected_cell_data[6:1];
    wire cell_enable = selected_cell_data[0];

    reg is_resistor, is_voltage, is_current, is_empty;

    always @(*) begin
        is_resistor = 1'b0;
        is_voltage = 1'b0;
        is_current = 1'b0;
        is_empty = 1'b0;

        if (!cell_enable || !has_selection) begin
            is_empty = 1'b1;
        end else begin
            case (cell_sprite_type)
                SPRITE_RES_LEFT, SPRITE_RES_RIGHT:  is_resistor = 1'b1;
                SPRITE_VOLT_LEFT, SPRITE_VOLT_RIGHT: is_voltage = 1'b1;
                SPRITE_CURR_LEFT, SPRITE_CURR_RIGHT: is_current = 1'b1;
                default: is_empty = 1'b1;
            endcase
        end
    end

    // ========================================================================
    // 数值计算 (模拟值，实际应用应从 RAM 读取)
    // ========================================================================
    wire [15:0] resistor_value = (selected_cell_i[3:0] + 1) * 100 + (selected_cell_j[3:0] + 1) * 10;
    wire [15:0] voltage_value = (selected_cell_i[3:0] + 1) * 5;
    wire [15:0] current_value = (selected_cell_i[3:0] + 1) * 10;

    // 坐标数字分解
    wire [3:0] sel_i_tens = selected_cell_i / 10;
    wire [3:0] sel_i_ones = selected_cell_i % 10;
    wire [3:0] sel_j_tens = selected_cell_j / 10;
    wire [3:0] sel_j_ones = selected_cell_j % 10;

    // 元件值分解
    wire [3:0] res_hundreds = resistor_value / 100;
    wire [3:0] res_tens = (resistor_value % 100) / 10;
    wire [3:0] res_ones = resistor_value % 10;

    wire [3:0] volt_tens = voltage_value / 10;
    wire [3:0] volt_ones = voltage_value % 10;

    wire [3:0] curr_tens = current_value / 10;
    wire [3:0] curr_ones = current_value % 10;

    // ASCII 转换 (48 = '0')
    wire [7:0] ascii_sel_i_tens = sel_i_tens + 8'd48;
    wire [7:0] ascii_sel_i_ones = sel_i_ones + 8'd48;
    wire [7:0] ascii_sel_j_tens = sel_j_tens + 8'd48;
    wire [7:0] ascii_sel_j_ones = sel_j_ones + 8'd48;

    wire [7:0] ascii_res_hundreds = res_hundreds + 8'd48;
    wire [7:0] ascii_res_tens = res_tens + 8'd48;
    wire [7:0] ascii_res_ones = res_ones + 8'd48;

    wire [7:0] ascii_volt_tens = volt_tens + 8'd48;
    wire [7:0] ascii_volt_ones = volt_ones + 8'd48;

    wire [7:0] ascii_curr_tens = curr_tens + 8'd48;
    wire [7:0] ascii_curr_ones = curr_ones + 8'd48;

    // ========================================================================
    // 文本数据总线 (MAX_CHARS * 8 位扁平化存储)
    // ========================================================================
    reg [MAX_CHARS * 8 - 1:0] label_data;
    reg [4:0] label_len;
    reg [MAX_CHARS * 8 - 1:0] value_data;
    reg [4:0] value_len;
    reg [MAX_CHARS * 8 - 1:0] coord_data;
    reg [4:0] coord_len;
    integer i;
    // 文本生成逻辑
    always @(*) begin
        // 初始化所有数据为 0
        for (i = 0; i < MAX_CHARS * 8; i = i + 8) begin
            label_data[i +: 8] = 8'd0;
            value_data[i +: 8] = 8'd0;
            coord_data[i +: 8] = 8'd0;
        end

        // 坐标字符串 "Pos: (XX, XX)"
        coord_data[MAX_CHARS * 8 - 1 -: 8] = "P";
        coord_data[MAX_CHARS * 8 - 9 -: 8] = "o";
        coord_data[MAX_CHARS * 8 - 17 -: 8] = "s";
        coord_data[MAX_CHARS * 8 - 25 -: 8] = ":";
        coord_data[MAX_CHARS * 8 - 33 -: 8] = " ";
        coord_data[MAX_CHARS * 8 - 41 -: 8] = "(";
        coord_data[MAX_CHARS * 8 - 49 -: 8] = ascii_sel_i_tens;
        coord_data[MAX_CHARS * 8 - 57 -: 8] = ascii_sel_i_ones;
        coord_data[MAX_CHARS * 8 - 65 -: 8] = ",";
        coord_data[MAX_CHARS * 8 - 73 -: 8] = " ";
        coord_data[MAX_CHARS * 8 - 81 -: 8] = ascii_sel_j_tens;
        coord_data[MAX_CHARS * 8 - 89 -: 8] = ascii_sel_j_ones;
        coord_data[MAX_CHARS * 8 - 97 -: 8] = ")";
        coord_len = 5'd13;

        // 根据元件类型生成标签和值
        if (has_selection && !is_empty) begin
            case (1'b1)
                is_resistor: begin
                    // "Resistor"
                    label_data[MAX_CHARS * 8 - 1 -: 8] = "R";
                    label_data[MAX_CHARS * 8 - 9 -: 8] = "e";
                    label_data[MAX_CHARS * 8 - 17 -: 8] = "s";
                    label_data[MAX_CHARS * 8 - 25 -: 8] = "i";
                    label_data[MAX_CHARS * 8 - 33 -: 8] = "s";
                    label_data[MAX_CHARS * 8 - 41 -: 8] = "t";
                    label_data[MAX_CHARS * 8 - 49 -: 8] = "o";
                    label_data[MAX_CHARS * 8 - 57 -: 8] = "r";
                    label_len = 5'd8;

                    // "Value: XXX Ohm"
                    value_data[MAX_CHARS * 8 - 1 -: 8] = "V";
                    value_data[MAX_CHARS * 8 - 9 -: 8] = "a";
                    value_data[MAX_CHARS * 8 - 17 -: 8] = "l";
                    value_data[MAX_CHARS * 8 - 25 -: 8] = "u";
                    value_data[MAX_CHARS * 8 - 33 -: 8] = "e";
                    value_data[MAX_CHARS * 8 - 41 -: 8] = ":";
                    value_data[MAX_CHARS * 8 - 49 -: 8] = " ";
                    value_data[MAX_CHARS * 8 - 57 -: 8] = ascii_res_hundreds;
                    value_data[MAX_CHARS * 8 - 65 -: 8] = ascii_res_tens;
                    value_data[MAX_CHARS * 8 - 73 -: 8] = ascii_res_ones;
                    value_data[MAX_CHARS * 8 - 81 -: 8] = " ";
                    value_data[MAX_CHARS * 8 - 89 -: 8] = "O";
                    value_data[MAX_CHARS * 8 - 97 -: 8] = "h";
                    value_data[MAX_CHARS * 8 - 105 -: 8] = "m";
                    value_len = 5'd13;
                end
                is_voltage: begin
                    // "Voltage Source"
                    label_data[MAX_CHARS * 8 - 1 -: 8] = "V";
                    label_data[MAX_CHARS * 8 - 9 -: 8] = "o";
                    label_data[MAX_CHARS * 8 - 17 -: 8] = "l";
                    label_data[MAX_CHARS * 8 - 25 -: 8] = "t";
                    label_data[MAX_CHARS * 8 - 33 -: 8] = "a";
                    label_data[MAX_CHARS * 8 - 41 -: 8] = "g";
                    label_data[MAX_CHARS * 8 - 49 -: 8] = "e";
                    label_data[MAX_CHARS * 8 - 57 -: 8] = " ";
                    label_data[MAX_CHARS * 8 - 65 -: 8] = "S";
                    label_data[MAX_CHARS * 8 - 73 -: 8] = "o";
                    label_data[MAX_CHARS * 8 - 81 -: 8] = "u";
                    label_data[MAX_CHARS * 8 - 89 -: 8] = "r";
                    label_data[MAX_CHARS * 8 - 97 -: 8] = "c";
                    label_data[MAX_CHARS * 8 - 105 -: 8] = "e";
                    label_len = 5'd14;

                    // "Value: X.X V"
                    value_data[MAX_CHARS * 8 - 1 -: 8] = "V";
                    value_data[MAX_CHARS * 8 - 9 -: 8] = "a";
                    value_data[MAX_CHARS * 8 - 17 -: 8] = "l";
                    value_data[MAX_CHARS * 8 - 25 -: 8] = "u";
                    value_data[MAX_CHARS * 8 - 33 -: 8] = "e";
                    value_data[MAX_CHARS * 8 - 41 -: 8] = ":";
                    value_data[MAX_CHARS * 8 - 49 -: 8] = " ";
                    value_data[MAX_CHARS * 8 - 57 -: 8] = ascii_volt_tens;
                    value_data[MAX_CHARS * 8 - 65 -: 8] = ascii_volt_ones;
                    value_data[MAX_CHARS * 8 - 73 -: 8] = ".";
                    value_data[MAX_CHARS * 8 - 81 -: 8] = "0";
                    value_data[MAX_CHARS * 8 - 89 -: 8] = " ";
                    value_data[MAX_CHARS * 8 - 97 -: 8] = "V";
                    value_len = 5'd12;
                end
                is_current: begin
                    // "Current Source"
                    label_data[MAX_CHARS * 8 - 1 -: 8] = "C";
                    label_data[MAX_CHARS * 8 - 9 -: 8] = "u";
                    label_data[MAX_CHARS * 8 - 17 -: 8] = "r";
                    label_data[MAX_CHARS * 8 - 25 -: 8] = "r";
                    label_data[MAX_CHARS * 8 - 33 -: 8] = "e";
                    label_data[MAX_CHARS * 8 - 41 -: 8] = "n";
                    label_data[MAX_CHARS * 8 - 49 -: 8] = "t";
                    label_data[MAX_CHARS * 8 - 57 -: 8] = " ";
                    label_data[MAX_CHARS * 8 - 65 -: 8] = "S";
                    label_data[MAX_CHARS * 8 - 73 -: 8] = "o";
                    label_data[MAX_CHARS * 8 - 81 -: 8] = "u";
                    label_data[MAX_CHARS * 8 - 89 -: 8] = "r";
                    label_data[MAX_CHARS * 8 - 97 -: 8] = "c";
                    label_data[MAX_CHARS * 8 - 105 -: 8] = "e";
                    label_len = 5'd14;

                    // "Value: XX mA"
                    value_data[MAX_CHARS * 8 - 1 -: 8] = "V";
                    value_data[MAX_CHARS * 8 - 9 -: 8] = "a";
                    value_data[MAX_CHARS * 8 - 17 -: 8] = "l";
                    value_data[MAX_CHARS * 8 - 25 -: 8] = "u";
                    value_data[MAX_CHARS * 8 - 33 -: 8] = "e";
                    value_data[MAX_CHARS * 8 - 41 -: 8] = ":";
                    value_data[MAX_CHARS * 8 - 49 -: 8] = " ";
                    value_data[MAX_CHARS * 8 - 57 -: 8] = ascii_curr_tens;
                    value_data[MAX_CHARS * 8 - 65 -: 8] = ascii_curr_ones;
                    value_data[MAX_CHARS * 8 - 73 -: 8] = " ";
                    value_data[MAX_CHARS * 8 - 81 -: 8] = "m";
                    value_data[MAX_CHARS * 8 - 89 -: 8] = "A";
                    value_len = 5'd11;
                end
                default: begin
                    label_len = 5'd0;
                    value_len = 5'd0;
                end
            endcase
        end else if (has_selection && is_empty) begin
            // "Empty Cell"
            label_data[MAX_CHARS * 8 - 1 -: 8] = "E";
            label_data[MAX_CHARS * 8 - 9 -: 8] = "m";
            label_data[MAX_CHARS * 8 - 17 -: 8] = "p";
            label_data[MAX_CHARS * 8 - 25 -: 8] = "t";
            label_data[MAX_CHARS * 8 - 33 -: 8] = "y";
            label_data[MAX_CHARS * 8 - 41 -: 8] = " ";
            label_data[MAX_CHARS * 8 - 49 -: 8] = "C";
            label_data[MAX_CHARS * 8 - 57 -: 8] = "e";
            label_data[MAX_CHARS * 8 - 65 -: 8] = "l";
            label_data[MAX_CHARS * 8 - 73 -: 8] = "l";
            label_len = 5'd10;
            value_len = 5'd0;
        end else begin
            // "No Selection"
            label_data[MAX_CHARS * 8 - 1 -: 8] = "N";
            label_data[MAX_CHARS * 8 - 9 -: 8] = "o";
            label_data[MAX_CHARS * 8 - 17 -: 8] = " ";
            label_data[MAX_CHARS * 8 - 25 -: 8] = "S";
            label_data[MAX_CHARS * 8 - 33 -: 8] = "e";
            label_data[MAX_CHARS * 8 - 41 -: 8] = "l";
            label_data[MAX_CHARS * 8 - 49 -: 8] = "e";
            label_data[MAX_CHARS * 8 - 57 -: 8] = "c";
            label_data[MAX_CHARS * 8 - 65 -: 8] = "t";
            label_data[MAX_CHARS * 8 - 73 -: 8] = "i";
            label_data[MAX_CHARS * 8 - 81 -: 8] = "o";
            label_data[MAX_CHARS * 8 - 89 -: 8] = "n";
            label_len = 5'd12;
            value_len = 5'd0;
        end
    end

    // ========================================================================
    // DynamicTextBox 例化
    // ========================================================================
    wire label_text_enable;
    wire [11:0] label_text_color;
    wire value_text_enable;
    wire [11:0] value_text_color;
    wire coord_text_enable;
    wire [11:0] coord_text_color;

    // 元件名称标签 (放大 2 倍)
    DynamicTextBox #(
        .MAX_CHARS(MAX_CHARS),
        .CHAR_W_BASE(8),
        .CHAR_H_BASE(8)
    ) u_label_textbox (
        .clk_pixel(clk_pixel),
        .hcount(hcount),
        .vcount(vcount),
        .text_data(label_data),
        .text_len(label_len),
        .start_x({12'd0, LABEL_X}),
        .start_y({12'd0, LABEL_Y}),
        .scale(4'd2),
        .text_enable(label_text_enable),
        .text_color(label_text_color)
    );

    // 元件值标签 (原始大小)
    DynamicTextBox #(
        .MAX_CHARS(MAX_CHARS),
        .CHAR_W_BASE(8),
        .CHAR_H_BASE(8)
    ) u_value_textbox (
        .clk_pixel(clk_pixel),
        .hcount(hcount),
        .vcount(vcount),
        .text_data(value_data),
        .text_len(value_len),
        .start_x({12'd0, VALUE_X}),
        .start_y({12'd0, VALUE_Y}),
        .scale(4'd1),
        .text_enable(value_text_enable),
        .text_color(value_text_color)
    );

    // 坐标标签 (原始大小)
    DynamicTextBox #(
        .MAX_CHARS(MAX_CHARS),
        .CHAR_W_BASE(8),
        .CHAR_H_BASE(8)
    ) u_coord_textbox (
        .clk_pixel(clk_pixel),
        .hcount(hcount),
        .vcount(vcount),
        .text_data(coord_data),
        .text_len(coord_len),
        .start_x({12'd0, COORD_X}),
        .start_y({12'd0, COORD_Y}),
        .scale(4'd1),
        .text_enable(coord_text_enable),
        .text_color(coord_text_color)
    );

    // ========================================================================
    // 面板渲染逻辑
    // ========================================================================
    wire in_panel = (hcount >= PANEL_X) && (hcount < PANEL_X + PANEL_W) &&
                    (vcount >= PANEL_Y) && (vcount < PANEL_Y + PANEL_H);

    wire is_border = in_panel && (
        (hcount == PANEL_X) || (hcount == PANEL_X + PANEL_W - 1) ||
        (vcount == PANEL_Y) || (vcount == PANEL_Y + PANEL_H - 1)
    );

    always @(posedge clk_pixel) begin
        panel_rendered <= 1'b0;
        panel_rgb <= COLOR_BG;

        // video_on 为低时不输出任何信号 (消隐期间)
        if (video_on && in_panel) begin
            panel_rendered <= 1'b1;

            if (is_border) begin
                panel_rgb <= COLOR_BORDER;
            end else if (label_text_enable) begin
                panel_rgb <= label_text_color;
            end else if (value_text_enable) begin
                panel_rgb <= value_text_color;
            end else if (coord_text_enable) begin
                panel_rgb <= coord_text_color;
            end else begin
                panel_rgb <= COLOR_BG;
            end
        end
    end

endmodule
