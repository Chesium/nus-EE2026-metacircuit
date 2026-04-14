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

    reg [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk) begin
        if (wr_en) begin
            ram[wr_addr] <= din;
        end
    end

    always @(posedge clk) begin
        if (rd_en) begin
            dout <= ram[rd_addr];
        end
    end

endmodule

module SimpleDualClockRam #(
    parameter integer WordWidth = 32,
    parameter integer WordCount = 16,
    parameter integer AddrWidth = $clog2(WordCount)
) (
    input  wire                 wr_clk,
    input  wire                 rd_clk,
    input  wire                 w_en,
    input  wire [AddrWidth-1:0] w_addr,
    input  wire [AddrWidth-1:0] r_addr,
    input  wire [WordWidth-1:0] d_in,
    output reg  [WordWidth-1:0] d_out
);

    // Infer a true dual-port RAM with independent write/read clocks.
    (* ram_style = "block" *)
    reg [WordWidth-1:0] mem[0:WordCount-1];

    always @(posedge wr_clk) begin
        if (w_en) begin
            mem[w_addr] <= d_in;
        end
    end

    always @(posedge rd_clk) begin
        d_out <= mem[r_addr];
    end

endmodule
