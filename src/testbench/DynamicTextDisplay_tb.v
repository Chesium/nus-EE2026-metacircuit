`timescale 1ns / 1ps

module DynamicTextDisplay_tb;

    // ================================
    // 参数定义
    // ================================
    localparam TOTAL_BITS = 16;
    localparam FRAC_BITS = 8;
    localparam MAX_DIGITS = 6;
    localparam CHAR_W_BASE = 8;
    localparam CHAR_H_BASE = 8;

    // 时钟周期 (25MHz = 40ns)
    localparam CLK_PERIOD = 40;

    // ================================
    // 输入信号
    // ================================
    reg clk_pixel;
    reg [11:0] hcount;
    reg [11:0] vcount;
    reg signed [TOTAL_BITS-1:0] value_in;
    reg [11:0] start_x;
    reg [11:0] start_y;
    reg [3:0] scale;
    reg show_sign;
    reg show_leading_zero;

    // ================================
    // 输出信号
    // ================================
    wire text_enable;
    wire [11:0] text_color;

    // 调试信号（用于观察字符转换结果）
    wire [4:0] actual_len_dbg;
    wire [7:0] char0_dbg, char1_dbg, char2_dbg, char3_dbg, char4_dbg, char5_dbg;

    // ================================
    // 实例化被测模块
    // ================================
    DynamicTextDisplay #(
        .TOTAL_BITS(TOTAL_BITS),
        .FRAC_BITS(FRAC_BITS),
        .MAX_DIGITS(MAX_DIGITS),
        .CHAR_W_BASE(CHAR_W_BASE),
        .CHAR_H_BASE(CHAR_H_BASE)
    ) u_DUT (
        .clk_pixel(clk_pixel),
        .hcount(hcount),
        .vcount(vcount),
        .value_in(value_in),
        .start_x(start_x),
        .start_y(start_y),
        .scale(scale),
        .show_sign(show_sign),
        .show_leading_zero(show_leading_zero),
        .text_enable(text_enable),
        .text_color(text_color),
        // 调试输出
        .actual_len_dbg(actual_len_dbg),
        .char0_dbg(char0_dbg),
        .char1_dbg(char1_dbg),
        .char2_dbg(char2_dbg),
        .char3_dbg(char3_dbg),
        .char4_dbg(char4_dbg),
        .char5_dbg(char5_dbg)
    );

    // ================================
    // 时钟生成
    // ================================
    initial begin
        clk_pixel = 0;
        forever #(CLK_PERIOD/2) clk_pixel = ~clk_pixel;
    end

    // ================================
    // 测试主流程
    // ================================
    initial begin
        // 初始化所有输入
        clk_pixel = 0;
        hcount = 12'd0;
        vcount = 12'd0;
        value_in = 16'sd0;
        start_x = 12'd100;
        start_y = 12'd100;
        scale = 4'd1;
        show_sign = 1'b0;
        show_leading_zero = 1'b0;

        $display("========================================");
        $display("DynamicTextDisplay Testbench");
        $display("========================================");

        #100;  // 等待稳定

        // ----------------------------------------
        // 测试 1: 25.50 (25.5 * 256 = 6528)
        // ----------------------------------------
        $display("\n[Test 1] value = 25.50");
        value_in = 16'sd6528;
        #200;
        print_chars();

        // ----------------------------------------
        // 测试 2: -12.75 (-12.75 * 256 = -3264)
        // ----------------------------------------
        $display("[Test 2] value = -12.75");
        value_in = -16'sd3264;
        show_sign = 1'b1;
        #200;
        print_chars();

        // ----------------------------------------
        // 测试 3: 0.00
        // ----------------------------------------
        $display("[Test 3] value = 0.00");
        value_in = 16'sd0;
        show_sign = 1'b0;
        show_leading_zero = 1'b1;
        #200;
        print_chars();

        // ----------------------------------------
        // 测试 4: 123.45 (123.45 * 256 = 31603)
        // ----------------------------------------
        $display("[Test 4] value = 123.45");
        value_in = 16'sd31603;
        show_leading_zero = 1'b0;
        #200;
        print_chars();

        // ----------------------------------------
        // 测试 5: 0.75 (0.75 * 256 = 192)
        // ----------------------------------------
        $display("[Test 5] value = 0.75");
        value_in = 16'sd192;
        #200;
        print_chars();

        // ----------------------------------------
        // 测试 6: 动态变化 0 -> 1 -> 2 -> 3
        // ----------------------------------------
        $display("[Test 6] value change: 0 -> 1 -> 2 -> 3");
        value_in = 16'sd0;
        #200;
        print_chars();
        
        value_in = 16'sd256;   // 1.00
        #200;
        print_chars();
        
        value_in = 16'sd512;   // 2.00
        #200;
        print_chars();
        
        value_in = 16'sd768;   // 3.00
        #200;
        print_chars();

        // ----------------------------------------
        // 测试 7: scale = 2
        // ----------------------------------------
        $display("[Test 7] scale = 2, value = 42.00");
        value_in = 16'sd10752;  // 42.00
        scale = 4'd2;
        #200;
        print_chars();

        // ----------------------------------------
        // 测试 8: 不同位置
        // ----------------------------------------
        $display("[Test 8] position (200, 150)");
        start_x = 12'd200;
        start_y = 12'd150;
        scale = 4'd1;
        #200;
        print_chars();

        $display("\n========================================");
        $display("Simulation Complete");
        $display("========================================");

        #500;
        $finish;
    end

    // ================================
    // 打印当前字符数组
    // ================================
    task print_chars;
        begin
            $display("  actual_len = %0d", actual_len_dbg);
            $display("  chars: '%c' '%c' '%c' '%c' '%c' '%c'", 
                     char0_dbg, char1_dbg, char2_dbg, char3_dbg, char4_dbg, char5_dbg);
        end
    endtask

    // ================================
    // 模拟 VGA 扫描（用于观察 text_enable 输出）
    // ================================
    integer scan_count;
    initial begin
        #1500;  // 等待主要测试完成

        $display("\n[VGA Scan Simulation]");
        
        // 设置 vcount 到字符行
        vcount = start_y + 4;
        
        // 水平扫描一行
        for (scan_count = 0; scan_count < 600; scan_count = scan_count + 1) begin
            hcount = scan_count;
            #CLK_PERIOD;
            if (text_enable) begin
                $display("  Pixel[%0d, %0d]: ON (color=%b)", hcount, vcount, text_color);
            end
        end
        
        hcount = 12'd0;
        vcount = 12'd0;
    end

    // ================================
    // 波形输出
    // ================================
    initial begin
        $dumpfile("DynamicTextDisplay_tb.vcd");
        $dumpvars(0, DynamicTextDisplay_tb);
    end

endmodule
