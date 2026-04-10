`timescale 1ns / 1ps

// =========================================================================
// 第 1 組：基於空間座標的查詢
// =========================================================================
module fetchCell (
    input  wire        clk,
    input  wire        start,
    output wire        busy,
    output reg         done,
    input  wire [4:0]  i,
    input  wire [3:0]  j,
    output reg  [15:0] result,

    // Interface to Combined Canvas RAM
    output wire        ram_ren,
    output wire [8:0]  ram_addr,
    input  wire [15:0] ram_rdata // Updated to match 16-bit Circuit Canvas RAM
);
    reg state = 1'b0;

    assign busy = (state != 0) || start;
    assign ram_ren = start;
    assign ram_addr = i + (j * 18);

    always @(posedge clk) begin
        if (start && !state) begin
            state <= 1'b1;
            done <= 1'b0;
        end else if (state) begin
            result <= ram_rdata;
            done <= 1'b1;
            state <= 1'b0;
        end else begin
            done <= 1'b0;
        end
    end
endmodule

// =========================================================================
// 第 2 組：基於元件 Index 的查詢 (直接對接 40-bit Component Store RAM)
// =========================================================================
module fetchAnchorPositionX (
    input  wire        clk,
    input  wire        start,
    output wire        busy,
    output reg         done,
    input  wire [8:0]  idx,
    output reg  [4:0]  result,

    // Interface to 40-bit Component Store RAM
    output wire        comp_ren,
    output wire [8:0]  comp_addr,
    input  wire [39:0] comp_rdata
);
    reg state = 1'b0;

    assign busy = (state != 0) || start;
    assign comp_ren = start;
    assign comp_addr = idx;

    always @(posedge clk) begin
        if (start && !state) begin
            state <= 1'b1;
            done <= 1'b0;
        end else if (state) begin
            // X 座標在低 5-bit: [4:0]
            result <= comp_rdata[4:0];
            done <= 1'b1;
            state <= 1'b0;
        end else begin
            done <= 1'b0;
        end
    end
endmodule

module fetchAnchorPositionY (
    input  wire        clk,
    input  wire        start,
    output wire        busy,
    output reg         done,
    input  wire [8:0]  idx,
    output reg  [3:0]  result,

    output wire        comp_ren,
    output wire [8:0]  comp_addr,
    input  wire [39:0] comp_rdata
);
    reg state = 1'b0;

    assign busy = (state != 0) || start;
    assign comp_ren = start;
    assign comp_addr = idx; 

    always @(posedge clk) begin
        if (start && !state) begin
            state <= 1'b1;
            done <= 1'b0;
        end else if (state) begin
            // Y 座標在 [8:5]
            result <= comp_rdata[8:5];
            done <= 1'b1;
            state <= 1'b0;
        end else begin
            done <= 1'b0;
        end
    end
endmodule

module fetchComponentType (
    input  wire        clk,
    input  wire        start,
    output wire        busy,
    output reg         done,
    input  wire [8:0]  idx,
    output reg  [3:0]  result,

    // 讀取 Component Store RAM (1 Cycle Latency)
    output reg         comp_ren,
    output reg  [8:0]  comp_addr,
    input  wire [39:0] comp_rdata
);
    reg state;
    assign busy = (state != 0) || start;
    
    always @(posedge clk) begin
        if (start && state == 0) begin
            comp_ren <= 1'b1;
            comp_addr <= idx;
            state <= 1'b1;
            done <= 1'b0;
        end else if (state == 1'b1) begin
            // Cycle 2: 拿到 40-bit 資料，提取 Type [26:23]
            comp_ren <= 1'b0;
            result <= comp_rdata[26:23];
            
            done <= 1'b1;
            state <= 1'b0;
        end else begin
            done <= 1'b0;
        end
    end
endmodule

// =========================================================================
// 新增：獲取元件 Value 模組
// =========================================================================
module fetchComponentValue (
    input  wire        clk,
    input  wire        start,
    output wire        busy,
    output reg         done,
    input  wire [8:0]  idx,
    output reg  [11:0] result,

    output reg         comp_ren,
    output reg  [8:0]  comp_addr,
    input  wire [39:0] comp_rdata
);
    reg state;
    assign busy = (state != 0) || start;
    
    always @(posedge clk) begin
        if (start && state == 0) begin
            comp_ren <= 1'b1;
            comp_addr <= idx;
            state <= 1'b1;
            done <= 1'b0;
        end else if (state == 1'b1) begin
            comp_ren <= 1'b0;
            // Value 欄位在 [20:9]
            result <= comp_rdata[20:9];
            
            done <= 1'b1;
            state <= 1'b0;
        end else begin
            done <= 1'b0;
        end
    end
endmodule

// =========================================================================
// 第 3 組：網表與拓樸儲存 (對接 Node Topology RAM)
// =========================================================================
// 提示：在底層實作上，Node0 和 Node1 是兩塊獨立的 64-deep x 6-bit RAM
module storeNode0 (
    input  wire       clk,
    input  wire       start,
    output wire       busy,
    output reg        done,
    input  wire [8:0] idx,
    input  wire [5:0] node_i,

    output wire       ram0_wen,
    output wire [5:0] ram0_addr,
    output wire [5:0] ram0_wdata
);
    assign busy = 1'b0;
    assign ram0_wen = start;
    assign ram0_addr = idx[5:0];
    assign ram0_wdata = node_i;
    always @(posedge clk) done <= start;
endmodule

module storeVoltage (
    input  wire        clk,
    input  wire        start,
    output wire        busy,
    output reg         done,
    input  wire [8:0]  idx,
    input  wire [31:0] value,

    // 直接連到 WaveformHistoryBuffer 的寫入埠
    output wire        wave_wen,
    output wire [5:0]  wave_node,
    output wire [31:0] wave_wdata
);
    assign busy = 1'b0;
    assign wave_wen = start;
    assign wave_node = idx[5:0];
    assign wave_wdata = value;
    always @(posedge clk) done <= start;
endmodule

// =========================================================================
// 第 4 組：前端視覺覆寫 (對接 Color Overlay RAM)
// =========================================================================
module setColor (
    input  wire       clk,
    input  wire       start,
    output wire       busy,
    output reg        done,
    input  wire [4:0] i,
    input  wire [3:0] j,
    input  wire [3:0] c1,
    input  wire [3:0] c2,

    output wire       color_wen,
    output wire [8:0] color_addr,
    output wire [7:0] color_wdata
);
    assign busy = 1'b0;
    assign color_wen = start;
    assign color_addr = i + (j * 18);
    assign color_wdata = {c1, c2}; // 高 4-bit 為前景，低 4-bit 為背景
    always @(posedge clk) done <= start;
endmodule
