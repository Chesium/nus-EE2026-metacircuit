`timescale 1ns / 1ps

module Design2_ComponentProjector_test;

  import CellStorePkg::*;
  import ComponentStorePkg::*;

  reg clk = 1'b0;
  reg rst = 1'b1;
  always #5 clk = ~clk;

  reg start = 1'b0;
  wire busy;
  wire done;

  wire        cell_req_valid;
  wire        cell_req_write;
  wire [9:0]  cell_req_addr;
  wire [15:0] cell_req_wdata;
  reg         cell_rsp_valid = 1'b0;
  reg  [15:0] cell_rsp_rdata = 16'd0;

  wire        comp_req_valid;
  wire        comp_req_write;
  wire [5:0]  comp_req_addr;
  wire [39:0] comp_req_wdata;
  reg         comp_rsp_valid = 1'b0;
  reg  [39:0] comp_rsp_rdata = 40'd0;

  reg [15:0] cell_mem [0:CELL_COUNT-1];
  reg [39:0] comp_mem [0:COMPONENT_COUNT-1];
  reg        cell_read_pending = 1'b0;
  reg [9:0]  cell_read_addr_pending = 10'd0;
  reg        comp_read_pending = 1'b0;
  reg [5:0]  comp_read_addr_pending = 6'd0;

  integer idx;

  ComponentProjector dut (
      .clk(clk),
      .rst(rst),
      .start(start),
      .busy(busy),
      .done(done),
      .cell_req_valid(cell_req_valid),
      .cell_req_write(cell_req_write),
      .cell_req_addr(cell_req_addr),
      .cell_req_wdata(cell_req_wdata),
      .cell_rsp_valid(cell_rsp_valid),
      .cell_rsp_rdata(cell_rsp_rdata),
      .comp_req_valid(comp_req_valid),
      .comp_req_write(comp_req_write),
      .comp_req_addr(comp_req_addr),
      .comp_req_wdata(comp_req_wdata),
      .comp_rsp_valid(comp_rsp_valid),
      .comp_rsp_rdata(comp_rsp_rdata)
  );

  always @(posedge clk) begin
    cell_rsp_valid <= 1'b0;
    comp_rsp_valid <= 1'b0;

    if (cell_req_valid && cell_req_write) begin
      cell_mem[cell_req_addr] <= cell_req_wdata;
    end else if (cell_req_valid) begin
      cell_read_pending <= 1'b1;
      cell_read_addr_pending <= cell_req_addr;
    end

    if (comp_req_valid && !comp_req_write) begin
      comp_read_pending <= 1'b1;
      comp_read_addr_pending <= comp_req_addr;
    end

    if (cell_read_pending) begin
      cell_rsp_valid <= 1'b1;
      cell_rsp_rdata <= cell_mem[cell_read_addr_pending];
      cell_read_pending <= 1'b0;
    end

    if (comp_read_pending) begin
      comp_rsp_valid <= 1'b1;
      comp_rsp_rdata <= comp_mem[comp_read_addr_pending];
      comp_read_pending <= 1'b0;
    end
  end

  task automatic expect_true(input bit cond, input [255:0] msg);
    begin
      if (!cond) begin
        $fatal(1, "Design2_ComponentProjector_test failed: %0s", msg);
      end
    end
  endtask

  initial begin
    for (idx = 0; idx < CELL_COUNT; idx = idx + 1) begin
      cell_mem[idx] = empty_cell();
    end
    for (idx = 0; idx < COMPONENT_COUNT; idx = idx + 1) begin
      comp_mem[idx] = empty_component();
    end

    cell_mem[flatten_addr(5'd1, 5'd1)] = pack_cell(1'b1, SPRITE_WIRE, 2'd0, NON_COMPONENT_IDX, 1'b0);
    cell_mem[flatten_addr(5'd9, 5'd9)] = pack_cell(1'b1, SPRITE_RES_LEFT, 2'd0, 6'd7, 1'b0);

    comp_mem[0] = pack_component(COMP_RESISTOR, 13'd220, NODE_NONE, NODE_NONE, 5'd10, 5'd6, 2'd1, 5'b00001);
    comp_mem[1] = pack_component(COMP_VOLTAGE, 13'd5, NODE_NONE, NODE_NONE, 5'd3, 5'd4, 2'd0, 5'b00001);

    repeat (4) @(negedge clk);
    rst <= 1'b0;

    @(negedge clk);
    start <= 1'b1;
    @(negedge clk);
    start <= 1'b0;

    wait (done === 1'b1);
    @(negedge clk);

    expect_true(cell_valid(cell_mem[flatten_addr(5'd1, 5'd1)]), "manual wire should survive component clear");
    expect_true(cell_sprite(cell_mem[flatten_addr(5'd1, 5'd1)]) == SPRITE_WIRE, "manual wire sprite changed unexpectedly");
    expect_true(!cell_valid(cell_mem[flatten_addr(5'd9, 5'd9)]), "stale component-owned cell was not cleared");

    expect_true(cell_valid(cell_mem[flatten_addr(5'd10, 5'd6)]), "first resistor cell missing");
    expect_true(cell_sprite(cell_mem[flatten_addr(5'd10, 5'd6)]) == SPRITE_RES_LEFT, "first resistor sprite mismatch");
    expect_true(cell_rot(cell_mem[flatten_addr(5'd10, 5'd6)]) == 2'd0, "first resistor rotation should be horizontal");
    expect_true(cell_comp_idx(cell_mem[flatten_addr(5'd10, 5'd6)]) == 6'd0, "first resistor comp_idx mismatch");

    expect_true(cell_valid(cell_mem[flatten_addr(5'd11, 5'd6)]), "second resistor cell missing");
    expect_true(cell_sprite(cell_mem[flatten_addr(5'd11, 5'd6)]) == SPRITE_RES_RIGHT, "second resistor sprite mismatch");
    expect_true(cell_rot(cell_mem[flatten_addr(5'd11, 5'd6)]) == 2'd0, "second resistor rotation should be horizontal");
    expect_true(cell_comp_idx(cell_mem[flatten_addr(5'd11, 5'd6)]) == 6'd0, "second resistor comp_idx mismatch");

    expect_true(cell_valid(cell_mem[flatten_addr(5'd3, 5'd4)]), "first voltage cell missing");
    expect_true(cell_sprite(cell_mem[flatten_addr(5'd3, 5'd4)]) == SPRITE_VOLT_LEFT, "first voltage sprite mismatch");
    expect_true(cell_rot(cell_mem[flatten_addr(5'd3, 5'd4)]) == 2'd1, "first voltage rotation should be vertical");
    expect_true(cell_comp_idx(cell_mem[flatten_addr(5'd3, 5'd4)]) == 6'd1, "first voltage comp_idx mismatch");

    expect_true(cell_valid(cell_mem[flatten_addr(5'd3, 5'd5)]), "second voltage cell missing");
    expect_true(cell_sprite(cell_mem[flatten_addr(5'd3, 5'd5)]) == SPRITE_VOLT_RIGHT, "second voltage sprite mismatch");
    expect_true(cell_rot(cell_mem[flatten_addr(5'd3, 5'd5)]) == 2'd1, "second voltage rotation should be vertical");
    expect_true(cell_comp_idx(cell_mem[flatten_addr(5'd3, 5'd5)]) == 6'd1, "second voltage comp_idx mismatch");

    $display("Design2_ComponentProjector_test passed.");
    $finish;
  end

endmodule
