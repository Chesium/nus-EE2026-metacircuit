`timescale 1ns / 1ps

module tb_PingPongBuffer;

    // 參數設定 (與你的波形圖需求一致)
    parameter DATA_WIDTH = 9;
    parameter ADDR_WIDTH = 9;

    // 宣告輸入 (reg) 與輸出 (wire)
    reg                   clk;
    reg                   rst_n;
    reg                   vsync_edge;
    
    reg                   wr_en;
    reg  [ADDR_WIDTH-1:0] wr_addr;
    reg  [DATA_WIDTH-1:0] wr_data;
    
    reg                   rd_en;
    reg  [ADDR_WIDTH-1:0] rd_addr;
    wire [DATA_WIDTH-1:0] rd_data;

    // 實例化待測物 (Device Under Test, DUT)
    PingPongBuffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .vsync_edge(vsync_edge),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

    // 產生 100MHz 系統時脈 (週期 10ns)
    always #5 clk = ~clk;

    // 測試劇本 (Test Scenario)
    initial begin
        // [初始化]
        clk = 0;
        rst_n = 0;
        vsync_edge = 0;
        wr_en = 0;
        wr_addr = 0;
        wr_data = 0;
        rd_en = 1;      // VGA 永遠都在讀取
        rd_addr = 0;
        
        // 解除重置
        #20 rst_n = 1;
        #10;

        // ==========================================
        // 階段一：Frame 0 (寫入 SRAM A)
        // ==========================================
        $display("--- Frame 0: Writing to Buffer A ---");
        // 模擬後端在 Address 10 寫入 Data 55
        @(posedge clk);
        wr_en = 1;
        wr_addr = 10;
        wr_data = 55;
        
        @(posedge clk);
        // 模擬後端在 Address 20 寫入 Data 88
        wr_addr = 20;
        wr_data = 88;
        
        @(posedge clk);
        wr_en = 0; // 寫完收工
        #30;

        // ==========================================
        // 階段二：觸發 VSYNC (前後台切換)
        // ==========================================
        $display("--- VSYNC Toggle! ---");
        @(posedge clk);
        vsync_edge = 1;
        @(posedge clk);
        vsync_edge = 0;
        #10;

        // ==========================================
        // 階段三：Frame 1 (讀取 A，同時寫入 B)
        // ==========================================
        $display("--- Frame 1: Reading A, Writing B ---");
        // 前端 (VGA) 去讀取剛剛寫入的 Address 10
        @(posedge clk);
        rd_addr = 10;
        
        // 【同時】後端在 Address 10 寫入新的 Data 99 到 SRAM B
        wr_en = 1;
        wr_addr = 10;
        wr_data = 99;
        
        @(posedge clk);
        // 前端去讀取 Address 20
        rd_addr = 20;
        wr_en = 0;
        #30;

        // ==========================================
        // 階段四：再次觸發 VSYNC
        // ==========================================
        $display("--- VSYNC Toggle! ---");
        @(posedge clk);
        vsync_edge = 1;
        @(posedge clk);
        vsync_edge = 0;
        #10;

        // ==========================================
        // 階段五：Frame 2 (讀取 B)
        // ==========================================
        $display("--- Frame 2: Reading B ---");
        @(posedge clk);
        rd_addr = 10; // 應該要讀到剛剛寫的 99
        
        #50;
        $display("--- Simulation Finished ---");
        $finish;
    end

endmodule