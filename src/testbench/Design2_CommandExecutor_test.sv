`timescale 1ns / 1ps

module Design2_CommandExecutor_test;

  import CellStorePkg::*;
  import ComponentStorePkg::*;
  import MetaCommandPkg::*;

  reg clk = 1'b0;
  reg rst = 1'b1;
  always #5 clk = ~clk;

  reg start = 1'b0;
  reg cmd_valid = 1'b0;
  reg [63:0] cmd_payload = 64'd0;
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

  CommandExecutor dut (
      .clk(clk),
      .rst(rst),
      .start(start),
      .cmd_valid(cmd_valid),
      .cmd_payload(cmd_payload),
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

    if (comp_req_valid && comp_req_write) begin
      comp_mem[comp_req_addr] <= comp_req_wdata;
    end else if (comp_req_valid) begin
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

  task automatic kick_command(input [63:0] payload);
    begin
      @(negedge clk);
      cmd_payload <= payload;
      cmd_valid <= 1'b1;
      start <= 1'b1;
      @(negedge clk);
      start <= 1'b0;
      cmd_valid <= 1'b0;
      wait (done === 1'b1);
      @(negedge clk);
    end
  endtask

  task automatic expect_true(input bit cond, input [255:0] msg);
    begin
      if (!cond) begin
        $fatal(1, "Design2_CommandExecutor_test failed: %0s", msg);
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

    repeat (4) @(negedge clk);
    rst <= 1'b0;

    kick_command(pack_command(
        CMD_COMPONENT_CREATE,
        NON_COMPONENT_IDX,
        5'd4,
        5'd5,
        SPRITE_RES_LEFT,
        2'd1,
        COMP_RESISTOR,
        13'd100,
        1'b0,
        8'sd0,
        8'sd0
    ));

    expect_true(component_valid(comp_mem[0]), "component create did not allocate slot 0");
    expect_true(component_type(comp_mem[0]) == COMP_RESISTOR, "component type mismatch after create");
    expect_true(component_anchor_x(comp_mem[0]) == 5'd4, "component anchor_x mismatch after create");
    expect_true(component_anchor_y(comp_mem[0]) == 5'd5, "component anchor_y mismatch after create");
    expect_true(component_rot(comp_mem[0]) == 2'd1, "component rotation mismatch after create");
    expect_true(component_value(comp_mem[0]) == 13'd100, "component value mismatch after create");

    kick_command(pack_command(
        CMD_COMPONENT_UPDATE,
        6'd0,
        5'd0,
        5'd0,
        6'd0,
        2'd0,
        COMP_RESISTOR,
        13'd123,
        1'b0,
        8'sd0,
        8'sd0
    ));

    expect_true(component_value(comp_mem[0]) == 13'd123, "component update did not change value");

    kick_command(pack_command(
        CMD_COMPONENT_ROTATE,
        6'd0,
        5'd0,
        5'd0,
        6'd0,
        2'd0,
        COMP_RESISTOR,
        13'd123,
        1'b0,
        8'sd0,
        8'sd0
    ));

    expect_true(component_rot(comp_mem[0]) == 2'd2, "component rotate did not increment rotation");

    kick_command(pack_command(
        CMD_CELL_WRITE,
        NON_COMPONENT_IDX,
        5'd2,
        5'd3,
        SPRITE_WIRE,
        2'd0,
        4'd0,
        13'd0,
        1'b0,
        8'sd0,
        8'sd0
    ));

    expect_true(cell_valid(cell_mem[flatten_addr(5'd2, 5'd3)]), "cell write did not mark target valid");
    expect_true(cell_sprite(cell_mem[flatten_addr(5'd2, 5'd3)]) == SPRITE_WIRE, "cell write sprite mismatch");

    kick_command(pack_command(
        CMD_ROTATE_TARGET,
        NON_COMPONENT_IDX,
        5'd2,
        5'd3,
        6'd0,
        2'd0,
        4'd0,
        13'd0,
        1'b0,
        8'sd0,
        8'sd0
    ));

    expect_true(cell_rot(cell_mem[flatten_addr(5'd2, 5'd3)]) == 2'd1, "cell rotate target did not update rotation");

    cell_mem[flatten_addr(5'd4, 5'd5)] = pack_cell(1'b1, SPRITE_RES_LEFT, 2'd2, 6'd0, 1'b0);

    kick_command(pack_command(
        CMD_DELETE_TARGET,
        NON_COMPONENT_IDX,
        5'd4,
        5'd5,
        6'd0,
        2'd0,
        4'd0,
        13'd0,
        1'b0,
        8'sd0,
        8'sd0
    ));

    expect_true(!component_valid(comp_mem[0]), "delete target did not clear selected component");

    $display("Design2_CommandExecutor_test passed.");
    $finish;
  end

endmodule
