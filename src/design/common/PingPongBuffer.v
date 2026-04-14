module PingPongBuffer #(
    parameter DATA_WIDTH = 12, 
    parameter ADDR_WIDTH = 17  
) (
    input  wire                  clk,
    input  wire                  rst_n,     

    input  wire                  vsync_edge, 


    input  wire                  wr_en,
    input  wire [ADDR_WIDTH-1:0] wr_addr,
    input  wire [DATA_WIDTH-1:0] wr_data,

    input  wire                  rd_en,
    input  wire [ADDR_WIDTH-1:0] rd_addr,
    output wire [DATA_WIDTH-1:0] rd_data
);

    reg buffer_state; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_state <= 1'b0;
        end else if (vsync_edge) begin
            buffer_state <= ~buffer_state;
        end
    end

    wire                  sram_a_wr_en = (buffer_state == 1'b0) ? wr_en : 1'b0;
    wire                  sram_a_rd_en = (buffer_state == 1'b1) ? rd_en : 1'b0;
    wire [ADDR_WIDTH-1:0] sram_a_addr  = (buffer_state == 1'b0) ? wr_addr : rd_addr;
    wire [DATA_WIDTH-1:0] sram_a_din   = wr_data;
    wire [DATA_WIDTH-1:0] sram_a_dout;

    wire                  sram_b_wr_en = (buffer_state == 1'b1) ? wr_en : 1'b0;
    wire                  sram_b_rd_en = (buffer_state == 1'b0) ? rd_en : 1'b0;
    wire [ADDR_WIDTH-1:0] sram_b_addr  = (buffer_state == 1'b1) ? wr_addr : rd_addr;
    wire [DATA_WIDTH-1:0] sram_b_din   = wr_data;
    wire [DATA_WIDTH-1:0] sram_b_dout;

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

    reg buffer_state_d1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_state_d1 <= 1'b0;
        end else begin
            buffer_state_d1 <= buffer_state;
        end
    end

    assign rd_data = (buffer_state_d1 == 1'b1) ? sram_a_dout : sram_b_dout;

endmodule