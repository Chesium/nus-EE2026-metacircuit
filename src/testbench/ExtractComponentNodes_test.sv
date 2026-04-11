`timescale 1ns / 1ps

module ExtractComponentNodes_test;
  localparam integer GRID_WIDTH = 6;
  localparam integer GRID_HEIGHT = 6;
  localparam integer CELL_COUNT = GRID_WIDTH * GRID_HEIGHT;
  localparam integer ELEM_COUNT = 8;
  localparam integer MAX_CYCLES = 200000;

  localparam [7:0] TYPE_RL = 8'd5;
  localparam [7:0] TYPE_CL = 8'd13;
  localparam [7:0] TYPE_LL = 8'd11;
  localparam [7:0] TYPE_GROUND = 8'd15;

  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk;

  reg start = 1'b0;
  wire busy;
  wire done;
  reg [31:0] par_elem_n = 32'd0;
  reg [31:0] grid_height = GRID_HEIGHT;
  reg [31:0] grid_width = GRID_WIDTH;

  wire        fetchComponentType_start;
  wire [15:0] fetchComponentType_idx;
  wire        fetchComponentType_done;
  wire [7:0]  fetchComponentType_result;

  wire        fetchAnchorPositionX_start;
  wire [15:0] fetchAnchorPositionX_idx;
  wire        fetchAnchorPositionX_done;
  wire [7:0]  fetchAnchorPositionX_result;

  wire        fetchAnchorPositionY_start;
  wire [15:0] fetchAnchorPositionY_idx;
  wire        fetchAnchorPositionY_done;
  wire [7:0]  fetchAnchorPositionY_result;

  wire        fetchComponentRotation_start;
  wire [15:0] fetchComponentRotation_idx;
  wire        fetchComponentRotation_done;
  wire [1:0]  fetchComponentRotation_result;

  wire        fetchR_start;
  wire [7:0]  fetchR_i;
  wire [7:0]  fetchR_j;
  wire        fetchR_done;
  wire [7:0]  fetchR_result;

  wire        storeNode0_start;
  wire [15:0] storeNode0_idx;
  wire [7:0]  storeNode0_node_i;
  wire        storeNode0_done;

  wire        storeNode1_start;
  wire [15:0] storeNode1_idx;
  wire [7:0]  storeNode1_node_i;
  wire        storeNode1_done;

  reg  [39:0] component_store_mem [0:ELEM_COUNT-1];
  reg  [7:0]  node0_mem [0:ELEM_COUNT-1];
  reg  [7:0]  node1_mem [0:ELEM_COUNT-1];

  wire        fetch_type_busy_unused;
  wire [3:0]  fetch_type_result_raw;
  wire        fetch_type_comp_ren_unused;
  wire [8:0]  fetch_type_comp_addr;
  wire [39:0] fetch_type_comp_rdata;

  wire        fetch_x_busy_unused;
  wire [4:0]  fetch_x_result_raw;
  wire        fetch_x_comp_ren_unused;
  wire [8:0]  fetch_x_comp_addr;
  wire [39:0] fetch_x_comp_rdata;

  wire        fetch_y_busy_unused;
  wire [3:0]  fetch_y_result_raw;
  wire        fetch_y_comp_ren_unused;
  wire [8:0]  fetch_y_comp_addr;
  wire [39:0] fetch_y_comp_rdata;

  wire        fetch_rot_busy_unused;
  wire        fetch_rot_comp_ren_unused;
  wire [8:0]  fetch_rot_comp_addr;
  wire [39:0] fetch_rot_comp_rdata;

  wire        store_node0_busy_unused;
  wire        node0_wen;
  wire [8:0]  node0_addr;
  wire [7:0]  node0_wdata;

  wire        store_node1_busy_unused;
  wire        node1_wen;
  wire [8:0]  node1_addr;
  wire [7:0]  node1_wdata;

  reg         result_clear = 1'b0;
  reg         result_store_start = 1'b0;
  reg  [7:0]  result_store_i = 8'd0;
  reg  [7:0]  result_store_j = 8'd0;
  reg  [7:0]  result_store_v = 8'd0;
  wire        result_store_done_unused;

  integer idx;
  integer cycle_count;

  function automatic [39:0] make_component_store_entry(
      input [8:0] idx_value,
      input [3:0] type_value,
      input [1:0] rotation_value,
      input [4:0] x_value,
      input [3:0] y_value
  );
    begin
      make_component_store_entry = {4'd0, idx_value, type_value, rotation_value, 12'd0, y_value, x_value};
    end
  endfunction

  task automatic clear_component_store;
    begin
      for (idx = 0; idx < ELEM_COUNT; idx = idx + 1) begin
        component_store_mem[idx] = 40'd0;
      end
    end
  endtask

  task automatic clear_node_memories;
    begin
      for (idx = 0; idx < ELEM_COUNT; idx = idx + 1) begin
        node0_mem[idx] = 8'd0;
        node1_mem[idx] = 8'd0;
      end
    end
  endtask

  task automatic pulse_result_clear;
    begin
      @(negedge clk);
      result_clear <= 1'b1;
      @(negedge clk);
      result_clear <= 1'b0;
    end
  endtask

  task automatic store_region(
      input [7:0] x_value,
      input [7:0] y_value,
      input [7:0] region_value
  );
    begin
      @(negedge clk);
      result_store_i <= x_value;
      result_store_j <= y_value;
      result_store_v <= region_value;
      result_store_start <= 1'b1;
      @(negedge clk);
      result_store_start <= 1'b0;
      @(negedge clk);
    end
  endtask

  task automatic run_dut(input integer elem_count_value);
    begin
      par_elem_n <= elem_count_value;
      @(negedge clk);
      start <= 1'b1;
      @(negedge clk);
      start <= 1'b0;

      cycle_count = 0;
      while (done !== 1'b1) begin
        @(posedge clk);
        cycle_count = cycle_count + 1;
        if (cycle_count > MAX_CYCLES) begin
          $fatal(1, "Timeout waiting for extract_component_nodes done");
        end
      end
      @(posedge clk);
    end
  endtask

  task automatic expect_nodes(
      input integer comp_idx,
      input [7:0] expected_node0,
      input [7:0] expected_node1
  );
    begin
      if (node0_mem[comp_idx] !== expected_node0) begin
        $fatal(1, "node0 mismatch for component %0d: got=%0d expected=%0d",
               comp_idx, node0_mem[comp_idx], expected_node0);
      end
      if (node1_mem[comp_idx] !== expected_node1) begin
        $fatal(1, "node1 mismatch for component %0d: got=%0d expected=%0d",
               comp_idx, node1_mem[comp_idx], expected_node1);
      end
    end
  endtask

  task automatic reset_design;
    begin
      rst_n <= 1'b0;
      start <= 1'b0;
      par_elem_n <= 32'd0;
      result_clear <= 1'b0;
      result_store_start <= 1'b0;
      result_store_i <= 8'd0;
      result_store_j <= 8'd0;
      result_store_v <= 8'd0;
      clear_component_store();
      clear_node_memories();
      repeat (4) @(negedge clk);
      rst_n <= 1'b1;
      repeat (2) @(negedge clk);
      pulse_result_clear();
    end
  endtask

  task automatic run_case_ground_and_compaction;
    begin
      reset_design();

      component_store_mem[0] = make_component_store_entry(9'd0, TYPE_GROUND[3:0], 2'd1, 5'd0, 4'd2);
      component_store_mem[1] = make_component_store_entry(9'd1, TYPE_RL[3:0], 2'd2, 5'd2, 4'd1);
      component_store_mem[2] = make_component_store_entry(9'd2, TYPE_CL[3:0], 2'd0, 5'd1, 4'd1);

      store_region(8'd0, 8'd1, 8'd7);
      store_region(8'd3, 8'd1, 8'd11);

      run_dut(3);

      expect_nodes(0, 8'd0, 8'd0);
      expect_nodes(1, 8'd1, 8'd0);
      expect_nodes(2, 8'd0, 8'd1);

      $display("run_case_ground_and_compaction passed.");
    end
  endtask

  task automatic run_case_sparse_without_ground;
    begin
      reset_design();

      component_store_mem[0] = make_component_store_entry(9'd0, TYPE_RL[3:0], 2'd1, 5'd1, 4'd2);
      component_store_mem[1] = make_component_store_entry(9'd1, TYPE_LL[3:0], 2'd0, 5'd3, 4'd3);

      store_region(8'd1, 8'd1, 8'd9);
      store_region(8'd1, 8'd4, 8'd25);
      store_region(8'd2, 8'd3, 8'd25);
      store_region(8'd5, 8'd3, 8'd44);

      run_dut(2);

      expect_nodes(0, 8'd1, 8'd2);
      expect_nodes(1, 8'd2, 8'd3);

      $display("run_case_sparse_without_ground passed.");
    end
  endtask

  task automatic run_case_multiple_ground_regions;
    begin
      reset_design();

      component_store_mem[0] = make_component_store_entry(9'd0, TYPE_GROUND[3:0], 2'd1, 5'd0, 4'd2);
      component_store_mem[1] = make_component_store_entry(9'd1, TYPE_GROUND[3:0], 2'd1, 5'd3, 4'd2);
      component_store_mem[2] = make_component_store_entry(9'd2, TYPE_RL[3:0], 2'd2, 5'd2, 4'd1);
      component_store_mem[3] = make_component_store_entry(9'd3, TYPE_CL[3:0], 2'd1, 5'd2, 4'd2);

      store_region(8'd0, 8'd1, 8'd7);
      store_region(8'd2, 8'd1, 8'd11);
      store_region(8'd3, 8'd1, 8'd11);
      store_region(8'd2, 8'd4, 8'd25);

      run_dut(4);

      expect_nodes(0, 8'd0, 8'd0);
      expect_nodes(1, 8'd0, 8'd0);
      expect_nodes(2, 8'd0, 8'd0);
      expect_nodes(3, 8'd0, 8'd1);

      $display("run_case_multiple_ground_regions passed.");
    end
  endtask

  assign fetch_type_comp_rdata = component_store_mem[fetch_type_comp_addr];
  assign fetch_x_comp_rdata = component_store_mem[fetch_x_comp_addr];
  assign fetch_y_comp_rdata = component_store_mem[fetch_y_comp_addr];
  assign fetch_rot_comp_rdata = component_store_mem[fetch_rot_comp_addr];

  assign fetchComponentType_result = {4'd0, fetch_type_result_raw};
  assign fetchAnchorPositionX_result = {3'd0, fetch_x_result_raw};
  assign fetchAnchorPositionY_result = {4'd0, fetch_y_result_raw};

  always @(posedge clk) begin
    if (node0_wen && (node0_addr < ELEM_COUNT)) begin
      node0_mem[node0_addr] <= node0_wdata;
    end
    if (node1_wen && (node1_addr < ELEM_COUNT)) begin
      node1_mem[node1_addr] <= node1_wdata;
    end
  end

  extract_component_nodes dut (
      .clk(clk),
      .rst_n(rst_n),
      .start(start),
      .busy(busy),
      .done(done),
      .par_elem_n(par_elem_n),
      .grid_height(grid_height),
      .grid_width(grid_width),
      .fetchComponentType_start(fetchComponentType_start),
      .fetchComponentType_idx(fetchComponentType_idx),
      .fetchComponentType_done(fetchComponentType_done),
      .fetchComponentType_result(fetchComponentType_result),
      .fetchAnchorPositionX_start(fetchAnchorPositionX_start),
      .fetchAnchorPositionX_idx(fetchAnchorPositionX_idx),
      .fetchAnchorPositionX_done(fetchAnchorPositionX_done),
      .fetchAnchorPositionX_result(fetchAnchorPositionX_result),
      .fetchAnchorPositionY_start(fetchAnchorPositionY_start),
      .fetchAnchorPositionY_idx(fetchAnchorPositionY_idx),
      .fetchAnchorPositionY_done(fetchAnchorPositionY_done),
      .fetchAnchorPositionY_result(fetchAnchorPositionY_result),
      .fetchComponentRotation_start(fetchComponentRotation_start),
      .fetchComponentRotation_idx(fetchComponentRotation_idx),
      .fetchComponentRotation_done(fetchComponentRotation_done),
      .fetchComponentRotation_result(fetchComponentRotation_result),
      .fetchR_start(fetchR_start),
      .fetchR_i(fetchR_i),
      .fetchR_j(fetchR_j),
      .fetchR_done(fetchR_done),
      .fetchR_result(fetchR_result),
      .storeNode0_start(storeNode0_start),
      .storeNode0_idx(storeNode0_idx),
      .storeNode0_node_i(storeNode0_node_i),
      .storeNode0_done(storeNode0_done),
      .storeNode1_start(storeNode1_start),
      .storeNode1_idx(storeNode1_idx),
      .storeNode1_node_i(storeNode1_node_i),
      .storeNode1_done(storeNode1_done)
  );

  fetchComponentType fetch_type_inst (
      .clk(clk),
      .start(fetchComponentType_start),
      .busy(fetch_type_busy_unused),
      .done(fetchComponentType_done),
      .idx(fetchComponentType_idx[8:0]),
      .result(fetch_type_result_raw),
      .comp_ren(fetch_type_comp_ren_unused),
      .comp_addr(fetch_type_comp_addr),
      .comp_rdata(fetch_type_comp_rdata)
  );

  fetchAnchorPositionX fetch_x_inst (
      .clk(clk),
      .start(fetchAnchorPositionX_start),
      .busy(fetch_x_busy_unused),
      .done(fetchAnchorPositionX_done),
      .idx(fetchAnchorPositionX_idx[8:0]),
      .result(fetch_x_result_raw),
      .comp_ren(fetch_x_comp_ren_unused),
      .comp_addr(fetch_x_comp_addr),
      .comp_rdata(fetch_x_comp_rdata)
  );

  fetchAnchorPositionY fetch_y_inst (
      .clk(clk),
      .start(fetchAnchorPositionY_start),
      .busy(fetch_y_busy_unused),
      .done(fetchAnchorPositionY_done),
      .idx(fetchAnchorPositionY_idx[8:0]),
      .result(fetch_y_result_raw),
      .comp_ren(fetch_y_comp_ren_unused),
      .comp_addr(fetch_y_comp_addr),
      .comp_rdata(fetch_y_comp_rdata)
  );

  fetchComponentRotation fetch_rot_inst (
      .clk(clk),
      .start(fetchComponentRotation_start),
      .busy(fetch_rot_busy_unused),
      .done(fetchComponentRotation_done),
      .idx(fetchComponentRotation_idx[8:0]),
      .result(fetchComponentRotation_result),
      .comp_ren(fetch_rot_comp_ren_unused),
      .comp_addr(fetch_rot_comp_addr),
      .comp_rdata(fetch_rot_comp_rdata)
  );

  ResultMatrixStore #(
      .GRID_WIDTH(GRID_WIDTH),
      .GRID_HEIGHT(GRID_HEIGHT)
  ) result_store (
      .clk(clk),
      .rst_n(rst_n),
      .clear(result_clear),
      .storeR_start(result_store_start),
      .storeR_i(result_store_i),
      .storeR_j(result_store_j),
      .storeR_v(result_store_v),
      .storeR_done(result_store_done_unused),
      .fetchR_start(fetchR_start),
      .fetchR_i(fetchR_i),
      .fetchR_j(fetchR_j),
      .fetchR_done(fetchR_done),
      .fetchR_result(fetchR_result)
  );

  storeNode0 store_node0_inst (
      .clk(clk),
      .start(storeNode0_start),
      .busy(store_node0_busy_unused),
      .done(storeNode0_done),
      .idx(storeNode0_idx[8:0]),
      .node_i(storeNode0_node_i),
      .ram0_wen(node0_wen),
      .ram0_addr(node0_addr),
      .ram0_wdata(node0_wdata)
  );

  storeNode1 store_node1_inst (
      .clk(clk),
      .start(storeNode1_start),
      .busy(store_node1_busy_unused),
      .done(storeNode1_done),
      .idx(storeNode1_idx[8:0]),
      .node_i(storeNode1_node_i),
      .ram1_wen(node1_wen),
      .ram1_addr(node1_addr),
      .ram1_wdata(node1_wdata)
  );

  initial begin
    run_case_ground_and_compaction();
    run_case_sparse_without_ground();
    run_case_multiple_ground_regions();
    $display("ExtractComponentNodes_test passed.");
    $finish;
  end
endmodule
