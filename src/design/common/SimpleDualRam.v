module SimpleDualPortRAM #(
    parameter DATA_WIDTH = 12,
    parameter ADDR_WIDTH = 17
) (
    input  wire                  clk,
    
    // Write Port
    input  wire                  wr_en,
    input  wire [ADDR_WIDTH-1:0] wr_addr,
    input  wire [DATA_WIDTH-1:0] din,
    
    // Read Port
    input  wire                  rd_en,
    input  wire [ADDR_WIDTH-1:0] rd_addr,
    output reg  [DATA_WIDTH-1:0] dout
);

    // 宣告記憶體陣列
    reg [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];

    // 寫入邏輯
    always @(posedge clk) begin
        if (wr_en) begin
            ram[wr_addr] <= din;
        end
    end

    // 讀取邏輯 (帶有 1 Clock Latency)
    always @(posedge clk) begin
        if (rd_en) begin
            dout <= ram[rd_addr];
        end
    end

endmodule