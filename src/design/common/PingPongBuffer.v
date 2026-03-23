module PingPongBuffer #(
    parameter DATA_WIDTH = 12, // 配合你的 12-bit RGB
    parameter ADDR_WIDTH = 17  // 支援 400x300 = 120,000 深度
) (
    input  wire                  clk,
    input  wire                  rst_n,      // Active-low Reset

    // 狀態切換訊號
    input  wire                  vsync_edge, // 當 VGA 掃描到畫面底部 (VSync) 時給一個 Pulse

    // 寫入端 (你的 Canvas 渲染邏輯)
    input  wire                  wr_en,
    input  wire [ADDR_WIDTH-1:0] wr_addr,
    input  wire [DATA_WIDTH-1:0] wr_data,

    // 讀出端 (VGA 螢幕掃描器)
    input  wire                  rd_en,
    input  wire [ADDR_WIDTH-1:0] rd_addr,
    output wire [DATA_WIDTH-1:0] rd_data
);

    // ========================================================
    // 1. 核心狀態機：切換控制 (The Toggle State)
    // ========================================================
    reg buffer_state; 
    // buffer_state = 0: 寫入 SRAM_A, 讀取 SRAM_B
    // buffer_state = 1: 寫入 SRAM_B, 讀取 SRAM_A

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_state <= 1'b0;
        end else if (vsync_edge) begin
            buffer_state <= ~buffer_state; // 每次 VSync 來臨，瞬間翻轉狀態！
        end
    end

    // ========================================================
    // 2. 輸入多工器 (DIN MUX & ADDR MUX) - 組合邏輯
    // ========================================================
    // SRAM A 的控制線
    wire                  sram_a_wr_en = (buffer_state == 1'b0) ? wr_en : 1'b0;
    wire                  sram_a_rd_en = (buffer_state == 1'b1) ? rd_en : 1'b0;
    wire [ADDR_WIDTH-1:0] sram_a_addr  = (buffer_state == 1'b0) ? wr_addr : rd_addr;
    wire [DATA_WIDTH-1:0] sram_a_din   = wr_data;
    wire [DATA_WIDTH-1:0] sram_a_dout;

    // SRAM B 的控制線
    wire                  sram_b_wr_en = (buffer_state == 1'b1) ? wr_en : 1'b0;
    wire                  sram_b_rd_en = (buffer_state == 1'b0) ? rd_en : 1'b0;
    wire [ADDR_WIDTH-1:0] sram_b_addr  = (buffer_state == 1'b1) ? wr_addr : rd_addr;
    wire [DATA_WIDTH-1:0] sram_b_din   = wr_data;
    wire [DATA_WIDTH-1:0] sram_b_dout;

    // ========================================================
    // 3. 實例化兩塊 Block RAM (SRAM A & SRAM B)
    // ========================================================
    SimpleDualPortRAM #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) sram_A (
        .clk(clk),
        .wr_en(sram_a_wr_en), .wr_addr(sram_a_addr), .din(sram_a_din),
        .rd_en(sram_a_rd_en), .rd_addr(sram_a_addr), .dout(sram_a_dout)
    );

    SimpleDualPortRAM #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) sram_B (
        .clk(clk),
        .wr_en(sram_b_wr_en), .wr_addr(sram_b_addr), .din(sram_b_din),
        .rd_en(sram_b_rd_en), .rd_addr(sram_b_addr), .dout(sram_b_dout)
    );

    // ========================================================
    // 4. 輸出多工器 (DOUT MUX) - 【打一拍的核心邏輯】
    // ========================================================
    reg buffer_state_d1; // 用來記錄「上一個 Clock」的狀態

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_state_d1 <= 1'b0;
        end else begin
            buffer_state_d1 <= buffer_state; // 打一拍 (Delay by 1 clock)
        end
    end

    // 讀出資料時，必須使用「延遲一拍」的狀態來選擇，因為 SRAM 讀取有 1 Clock 延遲！
    assign rd_data = (buffer_state_d1 == 1'b1) ? sram_a_dout : sram_b_dout;

endmodule