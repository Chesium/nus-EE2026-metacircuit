`timescale 1ns / 1ps

module CurrentFlow_top (
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

    localparam [11:0] BLACK      = 12'h000;
    localparam [11:0] BACKGROUND = 12'hECC;
    
    localparam integer CANVAS_X0 = 64;
    localparam integer CANVAS_Y0 = 64;
    localparam integer CANVAS_W  = 420;
    localparam integer CANVAS_H  = 288;

    wire clk_pixel, video_on;
    wire [11:0] x_pos, y_pos;
    reg  [11:0] rgb;

    ClockDivider #( .FREQ(25_000_000) ) clkdiv_pixel_inst ( 
        .CLK100MHZ(CLK100MHZ), 
        .clk_out(clk_pixel) 
    );
    
    VGAControl vga_ctrl_inst (
        .clk_pixel(clk_pixel), .reset(BTNC), .rgb(rgb),
        .hsync(HSYNC), .vsync(VSYNC), .video_on(video_on),
        .h_count_reg(x_pos), .v_count_reg(y_pos),
        .vgaRed(VGARED), .vgaGreen(VGAGREEN), .vgaBlue(VGABLUE)
    );

    // =========================================================
    // 滑鼠控制與指標顯示
    // =========================================================
    wire [11:0] mouse_xpos, mouse_ypos;
    wire [3:0]  mouse_zpos;
    wire        mouse_left, mouse_middle, mouse_right, mouse_new_event;
    reg  [11:0] mouse_set_value = 0;
    reg         mouse_set_max_x = 0, mouse_set_max_y = 0;

    MouseCtl mouse_ctrl_inst (
        .clk(CLK100MHZ), .rst(BTNC), .xpos(mouse_xpos), .ypos(mouse_ypos), .zpos(mouse_zpos),
        .left(mouse_left), .middle(mouse_middle), .right(mouse_right),
        .new_event(mouse_new_event), .value(mouse_set_value), .setx(1'b0), .sety(1'b0),
        .setmax_x(mouse_set_max_x), .setmax_y(mouse_set_max_y), .ps2_clk(PS2CLK), .ps2_data(PS2DATA)
    );

    wire        mouse_display_enable;
    wire [3:0]  mouse_r, mouse_g, mouse_b;
    wire [11:0] mouse_rgb = {mouse_r, mouse_g, mouse_b};

    MouseDisplay mouse_disp_inst (
        .pixel_clk(clk_pixel), .xpos(mouse_xpos), .ypos(mouse_ypos), .mouse_left(mouse_left),
        .hcount(x_pos), .vcount(y_pos), .enable_mouse_display_out(mouse_display_enable),
        .red_out(mouse_r), .green_out(mouse_g), .blue_out(mouse_b)
    );

    // =========================================================
    // 電路畫布 RAM
    // =========================================================
    reg         ram_w_en = 0;
    reg  [7:0]  ram_w_addr = 0;
    reg  [15:0] ram_w_data = 0;
    wire [7:0]  ram_r_addr;
    wire [15:0] ram_r_data;

    SimpleRam #( .WordWidth(16), .WordCount(256) ) circuit_canvas_ram (
        .clk(CLK100MHZ), 
        .w_en(ram_w_en), .w_addr(ram_w_addr), .d_in(ram_w_data),
        .r_addr(ram_r_addr), .d_out(ram_r_data)
    );

    // =========================================================
    // 動畫時間控制器 (1D 拓樸動畫只需單一 Phase)
    // =========================================================
    wire [4:0] global_anim_phase;
    CurrentPhaseController #(
        .CLK_DIV_MAX(1000000), // 調整此值可改變流動速度
        .PHASE_BITS(5)
    ) phase_ctrl_inst (
        .clk_pixel(clk_pixel),
        .rst(BTNC),
        .anim_phase(global_anim_phase)
    );

    // =========================================================
    // 電路畫布實例化 (支援 Panning 與 1D 電流渲染)
    // =========================================================
    wire [11:0] canvas_rgb;
    wire        canvas_rendered;
    wire signed [12:0] canvas_pan_x, canvas_pan_y;

    CircuitCanvas #( 
        .CanvasPosX(CANVAS_X0), .CanvasPosY(CANVAS_Y0), 
        .CanvasWidth(CANVAS_W), .CanvasHeight(CANVAS_H) 
    ) circuit_canvas_inst (
        .clk_pixel(clk_pixel), .x_pos(x_pos), .y_pos(y_pos), 
        
        // --- 傳入全域動畫相位給畫布計算 1D 距離 ---
        .anim_phase(global_anim_phase),
        // ------------------------------------------
        
        .rgb(canvas_rgb), .rendered(canvas_rendered), 
        .mouse_x_pos(mouse_xpos), .mouse_y_pos(mouse_ypos),
        .data_addr(ram_r_addr), .incoming_data(ram_r_data),
        .display_grid(1'b1), 
        .mouse_left_click(mouse_left), // 傳入滑鼠左鍵支援拖曳
        .grid_pos_x_out(canvas_pan_x), .grid_pos_y_out(canvas_pan_y)
    );

    // =========================================================
    // 硬體狀態機：初始化電路網格與物理電流方向
    // 利用 RAM data 的 Bit 9 (0x0200) 控制流向： 1為順向，0為逆向
    // =========================================================
    reg [31:0] init_cycles = 0;

    always @(posedge CLK100MHZ) begin
        if (init_cycles < 1000) init_cycles <= init_cycles + 1;

        if (init_cycles < 256) begin
            ram_w_en <= 1'b1;
            ram_w_addr <= init_cycles[7:0];
            ram_w_data <= 16'd0;
        end else if (init_cycles <= 270) begin
            ram_w_en <= 1'b1;
            case (init_cycles)
                // 左上角 (UL): 逆向
                256: begin ram_w_addr <= 8'd34; ram_w_data <= 16'h0083; end 
                
                // 上方元件 (V-Source): 逆向
                257: begin ram_w_addr <= 8'd35; ram_w_data <= 16'h000F; end // (3,2) V-Source L
                258: begin ram_w_addr <= 8'd36; ram_w_data <= 16'h0011; end // (4,2) V-Source R
                
                // 右上角 (UR): 逆向
                259: begin ram_w_addr <= 8'd37; ram_w_data <= 16'h0103; end 
                
                // 右側元件: 逆向
                260: begin ram_w_addr <= 8'd53; ram_w_data <= 16'h0081; end // (5,3) Wire Vert
                
                // 右下角 (LR): 逆向
                261: begin ram_w_addr <= 8'd69; ram_w_data <= 16'h0183; end 
                
                // 下方元件 (Resistor): 順向 -> 加上 0x0200
                262: begin ram_w_addr <= 8'd68; ram_w_data <= 16'h020D; end // (4,4) Res_R
                263: begin ram_w_addr <= 8'd67; ram_w_data <= 16'h020B; end // (3,4) Res_L
                
                // 左下角 (LL): 逆向
                264: begin ram_w_addr <= 8'd66; ram_w_data <= 16'h0003; end 
                
                // 左側元件: 順向 -> 加上 0x0200
                265: begin ram_w_addr <= 8'd50; ram_w_data <= 16'h0281; end // (2,3) Wire Vert
                
                default: ram_w_en <= 1'b0;
            endcase
        end else begin
            ram_w_en <= 1'b0;
        end
    end

    // =========================================================
    // 影像混合渲染 (嚴格遵守圖層優先級)
    // =========================================================
    always @(posedge clk_pixel) begin
        if (!video_on) begin
            rgb <= BLACK;
        end else if (mouse_display_enable) begin
            rgb <= mouse_rgb;
        end else if (canvas_rendered) begin
            rgb <= canvas_rgb;
        end else begin
            rgb <= BACKGROUND; // 顯示灰色背景
        end
    end

    // 鎖定未使用的接腳
    assign JC  = 8'h00;
    assign SEG = 8'hFF;
    assign AN  = 4'hF;
    assign LED = 16'd0;

endmodule