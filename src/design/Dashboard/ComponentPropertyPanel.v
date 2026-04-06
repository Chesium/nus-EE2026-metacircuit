`timescale 1ns / 1ps
/*
 * ============================================================================
 * ComponentPropertyPanel - 电路元件属性面板模块（增强版）
 * ============================================================================
 *
 * 【功能概述】
 *   在屏幕顶部 640x64 像素区域显示当前选中电路元件的属性信息。
 *   支持从 ComponentStore RAM 读取 40 位元件数据并解析显示。
 *   支持通过 KeyboardVGA 修改元件参数并写回 RAM。
 *
 * 【ComponentStore 数据格式】（40 位）
 *   - type[3:0]     : 4 位元件类型
 *   - position[7:0] : 8 位位置 (Xpos[3:0] + Ypos[3:0]<<4)
 *   - rotation[1:0] : 2 位旋转角度
 *   - value[12:0]   : 13 位数值 (10 位数值 + 3 位单位乘数)
 *   - node1[3:0]    : 4 位节点 1
 *   - node2[3:0]    : 4 位节点 2
 *
 * 【元件类型编码】(4 位 type 字段)
 *   4'b0000 = 线缆 (Wire)
 *   4'b0001 = 接地 (Ground)
 *   4'b0010 = 电阻 (Resistor)
 *   4'b0011 = 电容 (Capacitor)
 *   4'b0100 = 电感 (Inductor)
 *   4'b0101 = 电压源 (Voltage Source)
 *   4'b0110 = 电流源 (Current Source)
 *
 * 【显示内容】
 *   第一行：元件类型名称 (放大 2 倍显示)
 *   第二行：元件参数值（可点击编辑）
 *   第三行：元件坐标位置
 *
 * 【参数编辑流程】
 *   1. 点击元件后，属性面板显示参数
 *   2. 点击参数区域，激活编辑模式
 *   3. 通过 KeyboardVGA 输入新数值
 *   4. 确认后写回 ComponentStore RAM
 *
 * ============================================================================
 */

module ComponentPropertyPanel #(
    parameter integer PANEL_X = 0,          // 面板 X 起始位置
    parameter integer PANEL_Y = 0,          // 面板 Y 起始位置
    parameter integer PANEL_W = 640,        // 面板宽度
    parameter integer PANEL_H = 64,         // 面板高度
    parameter integer MAX_CHARS = 32,       // 最大字符数
    parameter integer COMP_STORE_ADDR_WIDTH = 8  // ComponentStore 地址宽度
)(
    input wire clk_pixel,                   // 像素时钟
    input wire [11:0] hcount,               // 当前像素 X 坐标
    input wire [11:0] vcount,               // 当前像素 Y 坐标
    input wire video_on,                    // 视频使能信号

    // 鼠标位置
    input wire [11:0] mouse_cell_i,         // 鼠标所在单元格行
    input wire [11:0] mouse_cell_j,         // 鼠标所在单元格列
    input wire mouse_click,                 // 鼠标点击信号

    // 选中信息
    input wire has_selection,               // 选中标志
    input wire [11:0] selected_cell_i,      // 选中单元格行坐标
    input wire [11:0] selected_cell_j,      // 选中单元格列坐标

    // ComponentStore RAM 读取接口
    output reg [COMP_STORE_ADDR_WIDTH-1:0] comp_r_addr,   // 读地址
    input wire [39:0] comp_r_data,          // 读数据 (40 位)
    input wire comp_data_valid,             // 数据有效标志

    // ComponentStore RAM 写入接口
    output reg comp_w_en,                   // 写使能
    output reg [COMP_STORE_ADDR_WIDTH-1:0] comp_w_addr,   // 写地址
    output reg [39:0] comp_w_data,          // 写数据

    // KeyboardVGA 接口
    input wire [7:0] key_ascii,             // 键盘 ASCII 输入
    input wire key_valid,                   // 键盘输入有效
    input wire key_is_digit,                // 是否为数字键
    input wire key_is_unit,                 // 是否为单位键 (M/k/m/u/n/p)
    input wire key_is_action,               // 是否为功能键 (./Del/Rst)

    output reg panel_rendered,              // 面板渲染输出
    output reg [11:0] panel_rgb             // 面板 RGB 输出 (12 位 444 格式)
);

    // ========================================================================
    // 内部参数定义
    // ========================================================================
    localparam [11:0] COLOR_BG = 12'hECC;       // 背景色 (浅粉色)
    localparam [11:0] COLOR_BORDER = 12'h888;   // 边框颜色 (灰色)
    localparam [11:0] COLOR_VALUE_HIGHLIGHT = 12'hFFD;  // 参数高亮色 (浅黄色)

    // 元件类型定义 (4 位 type 字段)
    localparam [3:0] TYPE_WIRE     = 4'b0000;  // 线缆
    localparam [3:0] TYPE_GROUND   = 4'b0001;  // 接地
    localparam [3:0] TYPE_RESISTOR = 4'b0010;  // 电阻
    localparam [3:0] TYPE_CAPACITOR = 4'b0011; // 电容
    localparam [3:0] TYPE_INDUCTOR = 4'b0100;  // 电感
    localparam [3:0] TYPE_VOLTAGE  = 4'b0101;  // 电压源
    localparam [3:0] TYPE_CURRENT  = 4'b0110;  // 电流源

    // 面板布局 - 优化为 640x64 像素区域
    localparam integer PANEL_PAD = 8;
    localparam integer LABEL_X = PANEL_X + PANEL_PAD;
    localparam integer LABEL_Y = PANEL_Y + 6;         // 顶部留 6 像素，scale=2 字高 16 像素
    localparam integer VALUE_X = PANEL_X + PANEL_PAD;
    localparam integer VALUE_Y = PANEL_Y + 28;        // LABEL 下方 (6+16+6=28)
    localparam integer VALUE_W = 300;                 // 参数区域宽度（可点击）
    localparam integer COORD_X = PANEL_X + PANEL_PAD;
    localparam integer COORD_Y = PANEL_Y + 50;        // VALUE 下方 (28+8+14=50)

    // ========================================================================
    // ComponentStore 数据解析 (40 位)
    // ========================================================================
    // 40位格式：{type[3:0], position[7:0], rotation[1:0], value[12:0], node1[3:0], node2[3:0]}
    // 注意：comp_r_data 为 40 位，需要正确对齐
    
    wire [3:0]  comp_type = comp_r_data[39:36];     // 元件类型
    wire [7:0]  comp_position = comp_r_data[35:28]; // 位置
    wire [1:0]  comp_rotation = comp_r_data[27:26]; // 旋转
    wire [12:0] comp_value = comp_r_data[25:13];    // 数值 (10位数值 + 3位单位)
    wire [3:0]  comp_node1 = comp_r_data[12:9];     // 节点1
    wire [3:0]  comp_node2 = comp_r_data[8:5];      // 节点2
    
    wire [3:0]  comp_xpos = comp_position[3:0];     // X 位置
    wire [3:0]  comp_ypos = comp_position[7:4];     // Y 位置
    wire [9:0]  comp_value_mag = comp_value[12:3];  // 数值大小 (10位)
    wire [2:0]  comp_value_unit = comp_value[2:0];  // 单位乘数 (3位)

    // 地址生成：根据选中的单元格坐标
    always @(*) begin
        comp_r_addr = selected_cell_i[3:0] + (selected_cell_j[3:0] << 4);
    end

    // 元件类型判断
    reg is_wire, is_ground, is_resistor, is_capacitor, is_inductor, is_voltage, is_current, is_empty;

    always @(*) begin
        is_wire = 1'b0;
        is_ground = 1'b0;
        is_resistor = 1'b0;
        is_capacitor = 1'b0;
        is_inductor = 1'b0;
        is_voltage = 1'b0;
        is_current = 1'b0;
        is_empty = 1'b0;

        if (!has_selection || !comp_data_valid) begin
            is_empty = 1'b1;
        end else if (comp_r_data == 40'hFFFF_FFFF_F) begin
            // 全F标记视为空单元格（CompStoreInit 初始化标记）
            is_empty = 1'b1;
        end else begin
            case (comp_type)
                TYPE_WIRE:     is_wire = 1'b1;
                TYPE_GROUND:   is_ground = 1'b1;
                TYPE_RESISTOR: is_resistor = 1'b1;
                TYPE_CAPACITOR: is_capacitor = 1'b1;
                TYPE_INDUCTOR: is_inductor = 1'b1;
                TYPE_VOLTAGE:  is_voltage = 1'b1;
                TYPE_CURRENT:  is_current = 1'b1;
                default:       is_empty = 1'b1;
            endcase
        end
    end

    // ========================================================================
    // 参数编辑状态机
    // ========================================================================
    reg editing_mode;           // 编辑模式标志
    reg [9:0] edit_value_reg;   // 编辑中的数值 (10位)
    reg [2:0] edit_unit_reg;    // 编辑中的单位 (3位)
    reg [3:0] edit_digit_count; // 已输入数字位数
    
    // 检测区域
    wire in_value_area = (hcount >= VALUE_X) && (hcount < VALUE_X + VALUE_W) &&
                         (vcount >= VALUE_Y) && (vcount < VALUE_Y + 14);

    // 检测参数区域点击（进入编辑模式）
    always @(posedge clk_pixel) begin
        comp_w_en <= 1'b0;  // 默认复位写使能
        
        if (mouse_click && has_selection && !is_empty) begin
            if (in_value_area) begin
                // 点击参数区域，进入编辑模式
                editing_mode <= 1'b1;
                edit_value_reg <= 10'd0;
                edit_unit_reg <= 3'd0;
                edit_digit_count <= 4'd0;
            end else if (editing_mode) begin
                // 编辑模式下点击非参数区域，确认并保存
                comp_w_en <= 1'b1;
                comp_w_addr <= comp_r_addr;
                comp_w_data <= {comp_type, comp_position, comp_rotation,
                               {edit_value_reg, edit_unit_reg}, comp_node1, comp_node2};
                editing_mode <= 1'b0;
            end
        end
    end
    
    // KeyboardVGA 输入处理
    always @(posedge clk_pixel) begin
        if (editing_mode && key_valid) begin
            if (key_is_digit && edit_digit_count < 4'd4) begin
                // 数字输入 (0-9)
                edit_value_reg <= edit_value_reg * 10 + (key_ascii - 8'd48);
                edit_digit_count <= edit_digit_count + 1'b1;
            end else if (key_is_unit) begin
                // 单位输入 (M/k/m/u/n/p)
                case (key_ascii)
                    8'h4D: edit_unit_reg <= 3'd4;  // 'M' - Mega (10^6)
                    8'h6B: edit_unit_reg <= 3'd3;  // 'k' - kilo (10^3)
                    8'h6D: edit_unit_reg <= 3'd5;  // 'm' - milli (10^-3)
                    8'h75: edit_unit_reg <= 3'd1;  // 'u' - micro (10^-6)
                    8'h6E: edit_unit_reg <= 3'd2;  // 'n' - nano (10^-9)
                    8'h70: edit_unit_reg <= 3'd6;  // 'p' - pico (10^-12)
                    default: ;  // 忽略其他键
                endcase
            end else if (key_ascii == 8'h08 || key_ascii == 8'h7F) begin
                // 删除键 (Backspace/Delete) - 退格功能
                if (edit_digit_count > 4'd0) begin
                    edit_value_reg <= edit_value_reg / 10;
                    edit_digit_count <= edit_digit_count - 1'b1;
                end
            end
            // 注意：已移除 Enter 和 Escape 键处理
            // 确认操作改为点击非数据输入区域
        end
    end

    // ========================================================================
    // 数值显示转换
    // ========================================================================
    // 单位乘数显示映射
    function [7:0] unit_to_ascii;
        input [2:0] unit;
        begin
            case (unit)
                3'd0: unit_to_ascii = " ";   // 无单位 (基准)
                3'd1: unit_to_ascii = "u";   // micro
                3'd2: unit_to_ascii = "n";   // nano
                3'd3: unit_to_ascii = "k";   // kilo
                3'd4: unit_to_ascii = "M";   // Mega
                3'd5: unit_to_ascii = "m";   // milli
                3'd6: unit_to_ascii = "p";   // pico
                default: unit_to_ascii = " ";
            endcase
        end
    endfunction
    
    // 坐标数字分解
    wire [3:0] xpos_tens = comp_xpos / 10;
    wire [3:0] xpos_ones = comp_xpos % 10;
    wire [3:0] ypos_tens = comp_ypos / 10;
    wire [3:0] ypos_ones = comp_ypos % 10;

    // 数值分解 (显示用)
    wire [9:0] display_value = editing_mode ? edit_value_reg : comp_value_mag;
    wire [3:0] val_thousands = display_value / 1000;
    wire [3:0] val_hundreds = (display_value % 1000) / 100;
    wire [3:0] val_tens = (display_value % 100) / 10;
    wire [3:0] val_ones = display_value % 10;
    
    wire [2:0] display_unit = editing_mode ? edit_unit_reg : comp_value_unit;

    // ASCII 转换 (48 = '0')
    wire [7:0] ascii_xpos_tens = xpos_tens + 8'd48;
    wire [7:0] ascii_xpos_ones = xpos_ones + 8'd48;
    wire [7:0] ascii_ypos_tens = ypos_tens + 8'd48;
    wire [7:0] ascii_ypos_ones = ypos_ones + 8'd48;

    wire [7:0] ascii_val_thousands = val_thousands + 8'd48;
    wire [7:0] ascii_val_hundreds = val_hundreds + 8'd48;
    wire [7:0] ascii_val_tens = val_tens + 8'd48;
    wire [7:0] ascii_val_ones = val_ones + 8'd48;
    wire [7:0] ascii_unit = unit_to_ascii(display_unit);

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
        coord_data[MAX_CHARS * 8 - 49 -: 8] = ascii_xpos_tens;
        coord_data[MAX_CHARS * 8 - 57 -: 8] = ascii_xpos_ones;
        coord_data[MAX_CHARS * 8 - 65 -: 8] = ",";
        coord_data[MAX_CHARS * 8 - 73 -: 8] = " ";
        coord_data[MAX_CHARS * 8 - 81 -: 8] = ascii_ypos_tens;
        coord_data[MAX_CHARS * 8 - 89 -: 8] = ascii_ypos_ones;
        coord_data[MAX_CHARS * 8 - 97 -: 8] = ")";
        coord_len = 5'd13;

        // 根据元件类型生成标签和值
        if (has_selection && !is_empty) begin
            case (1'b1)
                is_wire: begin
                    // "Wire"
                    label_data[MAX_CHARS * 8 - 1 -: 8] = "W";
                    label_data[MAX_CHARS * 8 - 9 -: 8] = "i";
                    label_data[MAX_CHARS * 8 - 17 -: 8] = "r";
                    label_data[MAX_CHARS * 8 - 25 -: 8] = "e";
                    label_len = 5'd4;
                    // "R: 0 Ohm"
                    value_data[MAX_CHARS * 8 - 1 -: 8] = "R";
                    value_data[MAX_CHARS * 8 - 9 -: 8] = ":";
                    value_data[MAX_CHARS * 8 - 17 -: 8] = " ";
                    value_data[MAX_CHARS * 8 - 25 -: 8] = "0";
                    value_data[MAX_CHARS * 8 - 33 -: 8] = " ";
                    value_data[MAX_CHARS * 8 - 41 -: 8] = "O";
                    value_data[MAX_CHARS * 8 - 49 -: 8] = "h";
                    value_data[MAX_CHARS * 8 - 57 -: 8] = "m";
                    value_len = 5'd8;
                end
                is_ground: begin
                    // "Ground"
                    label_data[MAX_CHARS * 8 - 1 -: 8] = "G";
                    label_data[MAX_CHARS * 8 - 9 -: 8] = "r";
                    label_data[MAX_CHARS * 8 - 17 -: 8] = "o";
                    label_data[MAX_CHARS * 8 - 25 -: 8] = "u";
                    label_data[MAX_CHARS * 8 - 33 -: 8] = "n";
                    label_data[MAX_CHARS * 8 - 41 -: 8] = "d";
                    label_len = 5'd6;
                    // "GND"
                    value_data[MAX_CHARS * 8 - 1 -: 8] = "G";
                    value_data[MAX_CHARS * 8 - 9 -: 8] = "N";
                    value_data[MAX_CHARS * 8 - 17 -: 8] = "D";
                    value_len = 5'd3;
                end
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

                    // 显示数值 + 单位 (如 "Value: 100k Ohm")
                    value_data[MAX_CHARS * 8 - 1 -: 8] = "V";
                    value_data[MAX_CHARS * 8 - 9 -: 8] = "a";
                    value_data[MAX_CHARS * 8 - 17 -: 8] = "l";
                    value_data[MAX_CHARS * 8 - 25 -: 8] = "u";
                    value_data[MAX_CHARS * 8 - 33 -: 8] = "e";
                    value_data[MAX_CHARS * 8 - 41 -: 8] = ":";
                    value_data[MAX_CHARS * 8 - 49 -: 8] = " ";
                    // 数值 (最多4位)
                    if (val_thousands > 0) begin
                        value_data[MAX_CHARS * 8 - 57 -: 8] = ascii_val_thousands;
                        value_data[MAX_CHARS * 8 - 65 -: 8] = ascii_val_hundreds;
                        value_data[MAX_CHARS * 8 - 73 -: 8] = ascii_val_tens;
                        value_data[MAX_CHARS * 8 - 81 -: 8] = ascii_val_ones;
                    end else if (val_hundreds > 0) begin
                        value_data[MAX_CHARS * 8 - 57 -: 8] = ascii_val_hundreds;
                        value_data[MAX_CHARS * 8 - 65 -: 8] = ascii_val_tens;
                        value_data[MAX_CHARS * 8 - 73 -: 8] = ascii_val_ones;
                    end else if (val_tens > 0) begin
                        value_data[MAX_CHARS * 8 - 57 -: 8] = ascii_val_tens;
                        value_data[MAX_CHARS * 8 - 65 -: 8] = ascii_val_ones;
                    end else begin
                        value_data[MAX_CHARS * 8 - 57 -: 8] = ascii_val_ones;
                    end
                    // 单位
                    value_data[MAX_CHARS * 8 - 89 -: 8] = ascii_unit;
                    value_data[MAX_CHARS * 8 - 97 -: 8] = " ";
                    value_data[MAX_CHARS * 8 - 105 -: 8] = "O";
                    value_data[MAX_CHARS * 8 - 113 -: 8] = "h";
                    value_data[MAX_CHARS * 8 - 121 -: 8] = "m";
                    value_len = 5'd15;
                end
                is_capacitor: begin
                    // "Capacitor"
                    label_data[MAX_CHARS * 8 - 1 -: 8] = "C";
                    label_data[MAX_CHARS * 8 - 9 -: 8] = "a";
                    label_data[MAX_CHARS * 8 - 17 -: 8] = "p";
                    label_data[MAX_CHARS * 8 - 25 -: 8] = "a";
                    label_data[MAX_CHARS * 8 - 33 -: 8] = "c";
                    label_data[MAX_CHARS * 8 - 41 -: 8] = "i";
                    label_data[MAX_CHARS * 8 - 49 -: 8] = "t";
                    label_data[MAX_CHARS * 8 - 57 -: 8] = "o";
                    label_data[MAX_CHARS * 8 - 65 -: 8] = "r";
                    label_len = 5'd9;

                    // "Value: XXu F"
                    value_data[MAX_CHARS * 8 - 1 -: 8] = "V";
                    value_data[MAX_CHARS * 8 - 9 -: 8] = "a";
                    value_data[MAX_CHARS * 8 - 17 -: 8] = "l";
                    value_data[MAX_CHARS * 8 - 25 -: 8] = "u";
                    value_data[MAX_CHARS * 8 - 33 -: 8] = "e";
                    value_data[MAX_CHARS * 8 - 41 -: 8] = ":";
                    value_data[MAX_CHARS * 8 - 49 -: 8] = " ";
                    // 数值
                    if (val_tens > 0) begin
                        value_data[MAX_CHARS * 8 - 57 -: 8] = ascii_val_tens;
                        value_data[MAX_CHARS * 8 - 65 -: 8] = ascii_val_ones;
                    end else begin
                        value_data[MAX_CHARS * 8 - 57 -: 8] = ascii_val_ones;
                    end
                    // 单位
                    value_data[MAX_CHARS * 8 - 73 -: 8] = ascii_unit;
                    value_data[MAX_CHARS * 8 - 81 -: 8] = " ";
                    value_data[MAX_CHARS * 8 - 89 -: 8] = "F";
                    value_len = 5'd9;
                end
                is_inductor: begin
                    // "Inductor"
                    label_data[MAX_CHARS * 8 - 1 -: 8] = "I";
                    label_data[MAX_CHARS * 8 - 9 -: 8] = "n";
                    label_data[MAX_CHARS * 8 - 17 -: 8] = "d";
                    label_data[MAX_CHARS * 8 - 25 -: 8] = "u";
                    label_data[MAX_CHARS * 8 - 33 -: 8] = "c";
                    label_data[MAX_CHARS * 8 - 41 -: 8] = "t";
                    label_data[MAX_CHARS * 8 - 49 -: 8] = "o";
                    label_data[MAX_CHARS * 8 - 57 -: 8] = "r";
                    label_len = 5'd8;

                    // "Value: XXm H"
                    value_data[MAX_CHARS * 8 - 1 -: 8] = "V";
                    value_data[MAX_CHARS * 8 - 9 -: 8] = "a";
                    value_data[MAX_CHARS * 8 - 17 -: 8] = "l";
                    value_data[MAX_CHARS * 8 - 25 -: 8] = "u";
                    value_data[MAX_CHARS * 8 - 33 -: 8] = "e";
                    value_data[MAX_CHARS * 8 - 41 -: 8] = ":";
                    value_data[MAX_CHARS * 8 - 49 -: 8] = " ";
                    // 数值
                    if (val_tens > 0) begin
                        value_data[MAX_CHARS * 8 - 57 -: 8] = ascii_val_tens;
                        value_data[MAX_CHARS * 8 - 65 -: 8] = ascii_val_ones;
                    end else begin
                        value_data[MAX_CHARS * 8 - 57 -: 8] = ascii_val_ones;
                    end
                    // 单位
                    value_data[MAX_CHARS * 8 - 73 -: 8] = ascii_unit;
                    value_data[MAX_CHARS * 8 - 81 -: 8] = " ";
                    value_data[MAX_CHARS * 8 - 89 -: 8] = "H";
                    value_len = 5'd9;
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
                    // 数值
                    if (val_tens > 0) begin
                        value_data[MAX_CHARS * 8 - 57 -: 8] = ascii_val_tens;
                        value_data[MAX_CHARS * 8 - 65 -: 8] = ascii_val_ones;
                    end else begin
                        value_data[MAX_CHARS * 8 - 57 -: 8] = ascii_val_ones;
                    end
                    // 单位
                    value_data[MAX_CHARS * 8 - 73 -: 8] = ascii_unit;
                    value_data[MAX_CHARS * 8 - 81 -: 8] = " ";
                    value_data[MAX_CHARS * 8 - 89 -: 8] = "V";
                    value_len = 5'd9;
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
                    // 数值
                    if (val_tens > 0) begin
                        value_data[MAX_CHARS * 8 - 57 -: 8] = ascii_val_tens;
                        value_data[MAX_CHARS * 8 - 65 -: 8] = ascii_val_ones;
                    end else begin
                        value_data[MAX_CHARS * 8 - 57 -: 8] = ascii_val_ones;
                    end
                    // 单位
                    value_data[MAX_CHARS * 8 - 73 -: 8] = ascii_unit;
                    value_data[MAX_CHARS * 8 - 81 -: 8] = " ";
                    value_data[MAX_CHARS * 8 - 89 -: 8] = "A";
                    value_len = 5'd9;
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
            end else if (editing_mode && in_value_area) begin
                // 编辑模式下高亮参数区域
                panel_rgb <= COLOR_VALUE_HIGHLIGHT;
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
