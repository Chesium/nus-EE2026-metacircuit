`timescale 1ns / 1ps

module WaveformPlot_top (
    input  wire CLK100MHZ,   
    input  wire BTNC,        
    output wire HSYNC,
    output wire VSYNC,
    output wire [3:0] VGARED,
    output wire [3:0] VGAGREEN,
    output wire [3:0] VGABLUE
);

    wire reset = BTNC;       
    wire rst_n = ~reset;     

    reg [1:0] clk_div;
    always @(posedge CLK100MHZ or posedge reset) begin
        if (reset) clk_div <= 2'b00;
        else       clk_div <= clk_div + 1;
    end
    wire clk_pixel = clk_div[1];

    wire [11:0] h_count, v_count;
    wire        video_on;
    wire [11:0] rgb_next;

    VGAControl vga_inst (
        .clk_pixel(clk_pixel), .reset(reset), .rgb(rgb_next),
        .hsync(HSYNC), .vsync(VSYNC), .video_on(video_on),
        .h_count_reg(h_count), .v_count_reg(v_count),
        .vgaRed(VGARED), .vgaGreen(VGAGREEN), .vgaBlue(VGABLUE)
    );

    reg vsync_d;
    always @(posedge clk_pixel) vsync_d <= VSYNC;
    wire vsync_edge = (~VSYNC & vsync_d); 

    // =========================================================
    // 電壓 (Voltage) 管線
    // =========================================================
    wire       v_wr_en;
    wire [7:0] v_wr_addr, v_wr_data;
    wire [7:0] v_rd_addr, v_rd_data;
    wire       is_v_wave, is_v_axis, is_v_text;

    DummyDataGenerate v_gen (
        .clk(clk_pixel), .rst_n(rst_n), .vsync_edge(vsync_edge),
        .wr_en(v_wr_en), .wr_addr(v_wr_addr), .wr_data(v_wr_data)
    );

    PingPongBuffer #( .ADDR_WIDTH(8), .DATA_WIDTH(8) ) v_buffer (
        .clk(clk_pixel), .rst_n(rst_n), .vsync_edge(vsync_edge),
        .wr_en(v_wr_en), .wr_addr(v_wr_addr), .wr_data(v_wr_data),
        .rd_en(1'b1),    .rd_addr(v_rd_addr), .rd_data(v_rd_data)
    );

    // 【修改點】帶入參數 IS_VOLTAGE = 1
    WaveformPlot #( .IS_VOLTAGE(1) ) v_plot (
        .clk(clk_pixel), .rst_n(rst_n),
        .local_x( (h_count >= 0 && h_count < 200) ? (h_count[7:0] + 8'd1) : 8'd0 ),
        .local_y( (v_count >= 300 && v_count < 480) ? (v_count[7:0] - 8'd44) : 8'd0 ), 
        .rd_addr(v_rd_addr), .rd_data(v_rd_data),
        .is_wave_pixel(is_v_wave),
        .is_axis_pixel(is_v_axis),
        .is_text_pixel(is_v_text) // 【修改點】接出字體訊號
    );

    // =========================================================
    // 電流 (Current) 管線
    // =========================================================
    wire       i_wr_en;
    wire [7:0] i_wr_addr, i_wr_data;
    wire [7:0] i_rd_addr, i_rd_data;
    wire       is_i_wave, is_i_axis, is_i_text;

    DummyDataGenerate i_gen (
        .clk(clk_pixel), .rst_n(rst_n), .vsync_edge(vsync_edge),
        .wr_en(i_wr_en), .wr_addr(i_wr_addr), .wr_data(i_wr_data)
    );

    PingPongBuffer #( .ADDR_WIDTH(8), .DATA_WIDTH(8) ) i_buffer (
        .clk(clk_pixel), .rst_n(rst_n), .vsync_edge(vsync_edge),
        .wr_en(i_wr_en), .wr_addr(i_wr_addr), .wr_data(i_wr_data),
        .rd_en(1'b1),    .rd_addr(i_rd_addr), .rd_data(i_rd_data)
    );

    // 【修改點】帶入參數 IS_VOLTAGE = 0
    WaveformPlot #( .IS_VOLTAGE(0) ) i_plot (
        .clk(clk_pixel), .rst_n(rst_n),
        .local_x( (h_count >= 200 && h_count < 400) ? ((h_count[7:0] - 8'd200) + 8'd1) : 8'd0 ),
        .local_y( (v_count >= 300 && v_count < 480) ? (v_count[8:0] - 9'd300) : 8'd0 ),
        .rd_addr(i_rd_addr), .rd_data(i_rd_data),
        .is_wave_pixel(is_i_wave),
        .is_axis_pixel(is_i_axis),
        .is_text_pixel(is_i_text) // 【修改點】接出字體訊號
    );

    // =========================================================
    // 終極影像多工混合器 (Video Mixing Multiplexer)
    // =========================================================
    wire in_v_region = (h_count >= 0   && h_count < 200) && (v_count >= 300 && v_count < 480);
    wire in_i_region = (h_count >= 200 && h_count < 400) && (v_count >= 300 && v_count < 480);

    // 【混合邏輯】：字體最上層 (白) -> 波形第二層 (綠/黃) -> 座標軸第三層 (灰) -> 背景最底層 (深灰)
    assign rgb_next = (video_on) ? (
                        (in_v_region) ? (
                            is_v_text ? 12'hFFF : 
                            is_v_wave ? 12'h0F0 : 
                            is_v_axis ? 12'h444 : 
                            12'h111
                        ) :
                        (in_i_region) ? (
                            is_i_text ? 12'hFFF : 
                            is_i_wave ? 12'hFF0 : 
                            is_i_axis ? 12'h444 : 
                            12'h111
                        ) :
                        12'h000 
                      ) : 12'h000; 

endmodule