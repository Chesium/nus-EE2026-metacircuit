`timescale 1ns / 1ps

module FloodingCore_test;
  localparam integer GRID_WIDTH = 8;
  localparam integer GRID_HEIGHT = 8;
  localparam integer CELL_COUNT = GRID_WIDTH * GRID_HEIGHT;

  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk;

  reg start = 1'b0;
  wire busy;
  wire done;

  wire fetchP_start;
  wire [7:0] fetchP_i;
  wire [7:0] fetchP_j;
  wire fetchP_done;
  wire [3:0] fetchP_result;

  wire getVisited_start;
  wire [7:0] getVisited_i;
  wire [7:0] getVisited_j;
  wire getVisited_done;
  wire getVisited_result;

  wire setVisited_start;
  wire [7:0] setVisited_i;
  wire [7:0] setVisited_j;
  wire setVisited_done;

  wire storeR_start;
  wire [7:0] storeR_i;
  wire [7:0] storeR_j;
  wire [7:0] storeR_v;
  wire storeR_done;

  wire addQueue_start;
  wire [7:0] addQueue_i;
  wire [7:0] addQueue_j;
  wire [31:0] addQueue_d;
  wire addQueue_done;

  wire getQueueLen_start;
  wire getQueueLen_done;
  wire [15:0] getQueueLen_result;

  wire popQueue_start;
  wire popQueue_done;
  wire [17:0] popQueue_result;

  flooding_core dut (
      .clk(clk),
      .rst_n(rst_n),
      .start(start),
      .busy(busy),
      .done(done),
      .grid_height(GRID_HEIGHT),
      .grid_width(GRID_WIDTH),
      .fetchP_start(fetchP_start),
      .fetchP_i(fetchP_i),
      .fetchP_j(fetchP_j),
      .fetchP_done(fetchP_done),
      .fetchP_result(fetchP_result),
      .getVisited_start(getVisited_start),
      .getVisited_i(getVisited_i),
      .getVisited_j(getVisited_j),
      .getVisited_done(getVisited_done),
      .getVisited_result(getVisited_result),
      .setVisited_start(setVisited_start),
      .setVisited_i(setVisited_i),
      .setVisited_j(setVisited_j),
      .setVisited_done(setVisited_done),
      .storeR_start(storeR_start),
      .storeR_i(storeR_i),
      .storeR_j(storeR_j),
      .storeR_v(storeR_v),
      .storeR_done(storeR_done),
      .addQueue_start(addQueue_start),
      .addQueue_i(addQueue_i),
      .addQueue_j(addQueue_j),
      .addQueue_d(addQueue_d),
      .addQueue_done(addQueue_done),
      .getQueueLen_start(getQueueLen_start),
      .getQueueLen_done(getQueueLen_done),
      .getQueueLen_result(getQueueLen_result),
      .popQueue_start(popQueue_start),
      .popQueue_done(popQueue_done),
      .popQueue_result(popQueue_result)
  );

  PortGridStore #(
      .GRID_WIDTH(GRID_WIDTH),
      .GRID_HEIGHT(GRID_HEIGHT)
  ) port_store (
      .clk(clk),
      .rst_n(rst_n),
      .fetchP_start(fetchP_start),
      .fetchP_i(fetchP_i),
      .fetchP_j(fetchP_j),
      .fetchP_done(fetchP_done),
      .fetchP_result(fetchP_result)
  );

  VisitedMatrixStore #(
      .GRID_WIDTH(GRID_WIDTH),
      .GRID_HEIGHT(GRID_HEIGHT)
  ) visited_store (
      .clk(clk),
      .rst_n(rst_n),
      .getVisited_start(getVisited_start),
      .getVisited_i(getVisited_i),
      .getVisited_j(getVisited_j),
      .getVisited_done(getVisited_done),
      .getVisited_result(getVisited_result),
      .setVisited_start(setVisited_start),
      .setVisited_i(setVisited_i),
      .setVisited_j(setVisited_j),
      .setVisited_done(setVisited_done)
  );

  ResultMatrixStore #(
      .GRID_WIDTH(GRID_WIDTH),
      .GRID_HEIGHT(GRID_HEIGHT)
  ) result_store (
      .clk(clk),
      .rst_n(rst_n),
      .storeR_start(storeR_start),
      .storeR_i(storeR_i),
      .storeR_j(storeR_j),
      .storeR_v(storeR_v),
      .storeR_done(storeR_done)
  );

  FloodQueueStore #(
      .DEPTH(CELL_COUNT * 4)
  ) queue_store (
      .clk(clk),
      .rst_n(rst_n),
      .addQueue_start(addQueue_start),
      .addQueue_i(addQueue_i),
      .addQueue_j(addQueue_j),
      .addQueue_d(addQueue_d),
      .addQueue_done(addQueue_done),
      .getQueueLen_start(getQueueLen_start),
      .getQueueLen_done(getQueueLen_done),
      .getQueueLen_result(getQueueLen_result),
      .popQueue_start(popQueue_start),
      .popQueue_done(popQueue_done),
      .popQueue_result(popQueue_result)
  );

  reg [7:0] expected_result[0:CELL_COUNT-1];

  integer idx;
  integer mismatch_count;
  integer expected_visited;
  integer cycle_count;

  function automatic integer flatten_addr(
      input integer i,
      input integer j
  );
    begin
      flatten_addr = j * GRID_WIDTH + i;
    end
  endfunction

  task automatic compare_results;
    integer row;
    integer col;
    begin
      mismatch_count = 0;
      for (idx = 0; idx < CELL_COUNT; idx = idx + 1) begin
        row = idx / GRID_WIDTH;
        col = idx % GRID_WIDTH;
        if (result_store.mem[idx] !== expected_result[idx]) begin
          mismatch_count = mismatch_count + 1;
          $display("Result mismatch at (%0d,%0d): got=%0d expected=%0d",
                   col, row, result_store.mem[idx], expected_result[idx]);
        end
      end

      for (idx = 0; idx < CELL_COUNT; idx = idx + 1) begin
        expected_visited = (expected_result[idx] != 8'd0);
        if (visited_store.mem[idx] !== expected_visited[0]) begin
          mismatch_count = mismatch_count + 1;
          $display("Visited mismatch at idx=%0d: got=%0d expected=%0d",
                   idx, visited_store.mem[idx], expected_visited);
        end
      end

      if (queue_store.count !== 0) begin
        mismatch_count = mismatch_count + 1;
        $display("Queue not empty after completion: count=%0d", queue_store.count);
      end
    end
  endtask

  initial begin
    $readmemb("flooding_ports_8x8.mem", port_store.mem);
    $readmemh("flooding_expected_nodes_8x8.mem", expected_result);

    repeat (4) @(negedge clk);
    rst_n <= 1'b1;

    @(negedge clk);
    start <= 1'b1;
    @(negedge clk);
    start <= 1'b0;

    cycle_count = 0;
    while (done !== 1'b1 && cycle_count < 5000) begin
      @(posedge clk);
      cycle_count = cycle_count + 1;
    end

    if (done !== 1'b1) begin
      $fatal(1, "FloodingCore_test timed out after %0d cycles", cycle_count);
    end

    #1;
    compare_results();

    if (mismatch_count != 0) begin
      $fatal(1, "FloodingCore_test failed with %0d mismatches", mismatch_count);
    end

    $display("FloodingCore_test passed in %0d cycles.", cycle_count);
    $finish;
  end
endmodule
