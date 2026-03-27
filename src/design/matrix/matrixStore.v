module matrixStore #(
    parameter integer SIZE = 8,
    parameter integer ELE_COUNT = SIZE * SIZE,
    parameter integer ELE_WIDTH = 32,
    parameter integer MAT_ADDR_WIDTH = $clog2(SIZE),
    parameter integer ADDR_WIDTH = $clog2(ELE_COUNT)
) (
    input wire                       clk,

    input  wire                      fetch_start,
    output wire                      fetch_busy,
    output reg                       fetch_done = 1'b0,
    
    input  wire [MAT_ADDR_WIDTH-1:0] fetch_i, 
    input  wire [MAT_ADDR_WIDTH-1:0] fetch_j,
    output wire [ELE_WIDTH-1:0]      fetch_result,
    
    input  wire                      store_start,
    output wire                      store_busy,
    output reg                       store_done = 1'b0,
    
    input  wire [MAT_ADDR_WIDTH-1:0] store_i, 
    input  wire [MAT_ADDR_WIDTH-1:0] store_j,
    input  wire [ELE_WIDTH-1:0]      store_v
);

  wire  [ADDR_WIDTH-1:0] store_addr;
  assign store_addr = store_j + store_i * SIZE;

  wire  [ADDR_WIDTH-1:0] fetch_addr;
  assign fetch_addr = fetch_j + fetch_i * SIZE;

  assign fetch_busy = 1'b0;
  assign store_busy = 1'b0;

  SimpleRam #(
      .WordWidth(ELE_WIDTH),
      .WordCount(ELE_COUNT)
  ) ram (
      .clk(clk),
      .w_en(store_start),
      .w_addr(store_addr),
      .r_addr(fetch_addr),
      .d_in(store_v),
      .d_out(fetch_result)
  );

  always @(posedge clk) begin
    fetch_done <= fetch_start;
    store_done <= store_start;
  end

endmodule

/*
  reg                      fetch_A_start = 1'b0;
  wire                     fetch_A_busy;
  wire                     fetch_A_done;
  reg [MAT_ADDR_WIDTH-1:0] fetch_A_i; 
  reg [MAT_ADDR_WIDTH-1:0] fetch_A_j;
  wire [ELE_WIDTH-1:0]     fetch_A_result;
  reg                      store_A_start = 1'b0;
  wire                     store_A_busy;
  wire                     store_A_done;
  reg [MAT_ADDR_WIDTH-1:0] store_A_i; 
  reg [MAT_ADDR_WIDTH-1:0] store_A_j;
  reg [ELE_WIDTH-1:0]      store_A_v;

  matrixStore #(
    .SIZE(8),
    .ELE_WIDTH(32)
  ) matrixstore_a_inst (
    .clk(clk),
    .fetch_start(fetch_A_start),
    .fetch_busy(fetch_A_busy),
    .fetch_done(fetch_A_done),
    .fetch_i(fetch_A_i), 
    .fetch_j(fetch_A_j),
    .fetch_result(fetch_A_result),
    .store_start(store_A_start),
    .store_busy(store_A_busy),
    .store_done(store_A_done),
    .store_i(store_A_i), 
    .store_j(store_A_j),
    .store_v(store_A_v)
  );
*/
