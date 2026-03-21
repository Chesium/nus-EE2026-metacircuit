`timescale 1ns / 1ps

module DynamicTextDisplay #(
    parameter TOTAL_BITS = 16,      // 输入数值的总位宽
    parameter FRAC_BITS = 8,        // 小数部分位数 (例如 Q8.8 中为 8)
    parameter MAX_DIGITS = 6,       // 最大显示数字个数 (包括小数点)
    parameter CHAR_W_BASE = 8,
    parameter CHAR_H_BASE = 8
)(
    input wire clk_pixel,
    input wire [11:0] hcount,
    input wire [11:0] vcount,
    
    // 数值输入 (可以是 signed 或 unsigned，这里假设 signed 以支持负数)
    input wire signed [TOTAL_BITS-1:0] value_in,
    
    // 显示控制
    input wire [11:0] start_x,
    input wire [11:0] start_y,
    input wire [3:0]  scale,
    input wire        show_sign,        // 是否显示负号
    input wire        show_leading_zero,// 是否显示前导零 (如 0.5 还是 .5)
    
    output reg text_enable,
    output reg [11:0] text_color,

    // 调试输出（用于仿真验证）
    output wire [4:0] actual_len_dbg,
    output wire [7:0] char0_dbg,
    output wire [7:0] char1_dbg,
    output wire [7:0] char2_dbg,
    output wire [7:0] char3_dbg,
    output wire [7:0] char4_dbg,
    output wire [7:0] char5_dbg
);

    // --- 内部信号 ---
    reg [7:0] char_mem [0:MAX_DIGITS]; // 存储转换后的 ASCII 字符
    reg [4:0] actual_len;              // 实际字符串长度
    reg       is_negative;

    // 调试输出赋值
    assign actual_len_dbg = actual_len;
    assign char0_dbg = char_mem[0];
    assign char1_dbg = char_mem[1];
    assign char2_dbg = char_mem[2];
    assign char3_dbg = char_mem[3];
    assign char4_dbg = char_mem[4];
    assign char5_dbg = char_mem[5];

    // 状态机用于数值转换 (仅在数值变化或初始化时运行，但为了简单，我们在每个时钟周期尝试更新)
    // 注意：除法很慢，如果数值变化快，建议使用流水线或查找表。这里为了代码简洁使用迭代除法。
    // *优化提示*：对于实时渲染，最好在数值变化的瞬间计算一次并存入寄存器，而不是每像素计算。
    // 这里我们采用“数值锁存 + 转换”的模式。
    
    reg [TOTAL_BITS-1:0] last_value;
    reg value_changed;
    
    // 检测数值变化
    always @(posedge clk_pixel) begin
        last_value <= value_in;
        value_changed <= (value_in != last_value);
    end
    
    // --- 核心转换逻辑 (Bin2ASCII) ---
    // 由于 Verilog 中动态除法消耗资源极大且慢，这里采用一种简化的策略：
    // 1. 分离整数和小数部分。
    // 2. 整数部分：通过多次比较/减法转为 ASCII (避免通用除法器)。
    // 3. 小数部分：乘以 10^n 后取整显示。
    
    // 为了简化代码并确保时序，我们使用一个专用的 "转换进程"，只在 value_changed 时触发
    // 但由于 VGA 是流式的，我们需要把转换结果存在 char_mem 里供像素扫描使用。

    integer k;
    reg [7:0] buffer [0:MAX_DIGITS];
    reg [4:0] len;
    reg signed [TOTAL_BITS-1:0] work_val;
    reg [TOTAL_BITS-FRAC_BITS-1:0] i_part;
    reg [FRAC_BITS-1:0] f_part;
    reg [15:0] f_scaled;

    always @(posedge clk_pixel) begin
        // 初始化
        for (k = 0; k < MAX_DIGITS; k = k + 1) begin
            buffer[k] = 8'd0;
        end
        len = 5'd0;
        work_val = value_in;

        // 1. 处理符号
        is_negative = 1'b0;
        if (show_sign && work_val < 0) begin
            is_negative = 1'b1;
            buffer[len] = 8'd45;  // '-'
            len = len + 5'd1;
            work_val = -work_val;
        end

        // 2. 分离整数和小数
        i_part = work_val >> FRAC_BITS;
        f_part = work_val & ((1 << FRAC_BITS) - 1);

        // 3. 转换整数部分 (假设最大 3 位 0-999)
        if (i_part == 0 && !show_leading_zero) begin
            // 如果整数是 0 且不显示前导零，暂时不写
        end else begin
            // 百位
            if (i_part >= 100) begin
                buffer[len] = (i_part / 100) + 8'd48;
                i_part = i_part % 100;
                len = len + 5'd1;
            end
            // 十位
            if (i_part >= 10) begin
                buffer[len] = (i_part / 10) + 8'd48;
                i_part = i_part % 10;
                len = len + 5'd1;
            end
            // 个位
            buffer[len] = i_part + 8'd48;
            len = len + 5'd1;
        end

        // 如果整数部分什么都没写 (值为 0 且无前导零)，补一个 "0"
        if (len == 0 || (len == 1 && is_negative)) begin
            buffer[len] = 8'd48;  // '0'
            len = len + 5'd1;
        end

        // 4. 添加小数点
        buffer[len] = 8'd46;  // '.'
        len = len + 5'd1;

        // 5. 转换小数部分 (显示 2 位)
        f_scaled = (f_part * 100 + (1 << (FRAC_BITS-1))) >> FRAC_BITS;
        if (f_scaled >= 100) f_scaled = 16'd99;

        // 十位和个位 (直接用除法/取模，综合器会优化为减法树)
        buffer[len] = (f_scaled / 10) + 8'd48;
        len = len + 5'd1;

        // 个位
        buffer[len] = (f_scaled % 10) + 8'd48;
        len = len + 5'd1;

        // 6. 保存结果
        actual_len <= len;
        for (k = 0; k < MAX_DIGITS; k = k + 1) begin
            char_mem[k] <= buffer[k];
        end
    end

    // --- 渲染逻辑 (与之前 TextBox 类似) ---
    wire [3:0] effective_scale = (scale == 0) ? 4'd1 : scale;
    wire [11:0] scaled_char_w = CHAR_W_BASE * effective_scale;
    wire [11:0] scaled_char_h = CHAR_H_BASE * effective_scale;
    
    wire [11:0] relative_x = (hcount >= start_x) ? (hcount - start_x) : 12'd4095;
    wire [11:0] relative_y = (vcount >= start_y) ? (vcount - start_y) : 12'd4095;
    
    wire in_bounds = (relative_x < (scaled_char_w * actual_len)) && (relative_y < scaled_char_h);
    
    wire [2:0] shift_amt = (scale == 8) ? 3'd3 : (scale == 4) ? 3'd2 : (scale == 2) ? 3'd1 : 3'd0;
    wire [4:0] char_idx = in_bounds ? (relative_x >> (3 + shift_amt)) : 5'd0;
    wire [11:0] char_mask = (scale == 8) ? 12'd63 : (scale == 4) ? 12'd31 : (scale == 2) ? 12'd15 : 12'd7;

    wire [2:0] font_col = in_bounds ? ((relative_x & char_mask) >> shift_amt) : 3'd0;
    wire [2:0] font_row = in_bounds ? ((relative_y & char_mask) >> shift_amt) : 3'd0;
    
    wire [7:0] current_char = char_mem[char_idx];
    wire is_valid_char = (current_char >= 32) && (current_char <= 126);
    wire [6:0] ascii_addr = is_valid_char ? (current_char - 32) : 7'd0;
    
    wire [7:0] pixel_row;
    FontROM u_font (.char_addr(ascii_addr), .row(font_row), .pixel_data(pixel_row));

    wire is_lit = is_valid_char && in_bounds && pixel_row[7 - 1'b1 - font_col];
    
    always @(posedge clk_pixel) begin
        text_enable <= is_lit;
        text_color  <= 12'b1111_1111_1111;
    end

endmodule