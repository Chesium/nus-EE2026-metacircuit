`timescale 1ns / 1ps

module FetchCellTb #(
    parameter integer GRID_WIDTH = 18
) (
    input  wire        clk,
    input  wire        start,
    output wire        busy,
    output reg         done,
    input  wire [4:0]  i,
    input  wire [3:0]  j,
    output reg  [15:0] result,
    output reg         ram_ren,
    output reg  [8:0]  ram_addr,
    input  wire [15:0] ram_rdata
);
    localparam [1:0] STATE_IDLE    = 2'd0;
    localparam [1:0] STATE_WAIT    = 2'd1;
    localparam [1:0] STATE_CAPTURE = 2'd2;

    reg [1:0] state = STATE_IDLE;

    assign busy = (state != STATE_IDLE) || start;

    always @(posedge clk) begin
        case (state)
            STATE_IDLE: begin
                done <= 1'b0;
                ram_ren <= 1'b0;
                if (start) begin
                    ram_ren <= 1'b1;
                    ram_addr <= i + (j * GRID_WIDTH);
                    state <= STATE_WAIT;
                end
            end
            STATE_WAIT: begin
                done <= 1'b0;
                ram_ren <= 1'b0;
                state <= STATE_CAPTURE;
            end
            STATE_CAPTURE: begin
                result <= ram_rdata;
                done <= 1'b1;
                ram_ren <= 1'b0;
                state <= STATE_IDLE;
            end
            default: begin
                done <= 1'b0;
                ram_ren <= 1'b0;
                state <= STATE_IDLE;
            end
        endcase
    end
endmodule

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
  wire        fetchCell_start;
  wire [7:0]  fetchCell_i;
  wire [7:0]  fetchCell_j;
  wire        fetchCell_done;
  wire [15:0] fetchCell_result;

  wire        storeNode0_start;
  wire [15:0] storeNode0_idx;
  wire [7:0]  storeNode0_node_i;
  wire        storeNode0_done;

  wire        storeNode1_start;
  wire [15:0] storeNode1_idx;
  wire [7:0]  storeNode1_node_i;
  wire        storeNode1_done;

  reg  [39:0] component_store_mem [0:ELEM_COUNT-1];
  reg  [15:0] cell_mem [0:CELL_COUNT-1];
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
  wire        fetch_cell_busy_unused;
  wire        fetch_cell_ram_ren;
  wire [8:0]  fetch_cell_ram_addr;
  reg  [15:0] fetch_cell_ram_rdata = 16'd0;

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

  function automatic [15:0] make_cell_data(
      input [1:0] rotation_value,
      input [5:0] sprite_value
  );
    begin
      make_cell_data = {7'd0, rotation_value, sprite_value, 1'b1};
    end
  endfunction

  task automatic clear_component_store;
    begin
      for (idx = 0; idx < ELEM_COUNT; idx = idx + 1) begin
        component_store_mem[idx] = 40'd0;
      end
    end
  endtask

  task automatic clear_cell_mem;
    begin
      for (idx = 0; idx < CELL_COUNT; idx = idx + 1) begin
        cell_mem[idx] = 16'd0;
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

  task automatic place_cell(
      input [7:0] x_value,
      input [7:0] y_value,
      input [15:0] cell_value
  );
    integer addr;
    begin
      addr = x_value + (y_value * GRID_WIDTH);
      if (addr >= 0 && addr < CELL_COUNT) begin
        cell_mem[addr] = cell_value;
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
      clear_cell_mem();
      clear_node_memories();
      repeat (4) @(negedge clk);
      rst_n <= 1'b1;
      repeat (2) @(negedge clk);
      pulse_result_clear();
    end
  endtask

  // Cell sprites and rotations. Regions are stored by hand, numbered as
  // flooding would (reciprocal ports), except where a case uses sparse ids.
  localparam [5:0] SPRITE_WIRE = 6'd0;
  localparam [5:0] SPRITE_GROUND = 6'd15;
  localparam [3:0] TYPE_RR = 4'd6;
  localparam [3:0] TYPE_IL = 4'd9;
  localparam [3:0] TYPE_IR = 4'd10;
  localparam [3:0] TYPE_VL = 4'd7;
  localparam [3:0] TYPE_VR = 4'd8;
  localparam [3:0] TYPE_CR = 4'd14;
  localparam [7:0] FF = 8'hFF;

  // A component's two half cells (the anchor and the partner in direction rot).
  task automatic place_component(
      input integer comp_idx,
      input [3:0] left_type,
      input [3:0] right_type,
      input [1:0] rotation_value,
      input [7:0] x_value,
      input [7:0] y_value
  );
    reg [7:0] px;
    reg [7:0] py;
    begin
      component_store_mem[comp_idx] =
          make_component_store_entry(comp_idx[8:0], left_type, rotation_value, x_value[4:0], y_value[3:0]);
      px = x_value + ((rotation_value == 2'd0) ? 8'd1 : (rotation_value == 2'd2) ? 8'hFF : 8'd0);
      py = y_value + ((rotation_value == 2'd1) ? 8'd1 : (rotation_value == 2'd3) ? 8'hFF : 8'd0);
      place_cell(x_value, y_value, make_cell_data(rotation_value, {2'd0, left_type}));
      place_cell(px, py, make_cell_data(rotation_value, {2'd0, right_type}));
    end
  endtask

  task automatic wire_cell(input [7:0] x_value, input [7:0] y_value, input [1:0] rotation_value,
                           input [7:0] region_value);
    begin
      place_cell(x_value, y_value, make_cell_data(rotation_value, SPRITE_WIRE));
      store_region(x_value, y_value, region_value);
    end
  endtask

  task automatic ground_cell(input [7:0] x_value, input [7:0] y_value, input [1:0] rotation_value,
                             input [7:0] region_value);
    begin
      place_cell(x_value, y_value, make_cell_data(rotation_value, SPRITE_GROUND));
      store_region(x_value, y_value, region_value);
    end
  endtask

  // D-021: a ground whose port faces a terminal grounds it (its own region
  // contains the ground cell); the other end joins the facing wire.
  task automatic run_case_ground_facing_component;
    begin
      reset_design();
      ground_cell(8'd0, 8'd1, 2'd2, 8'd1);  // port right
      place_component(0, TYPE_RL[3:0], TYPE_RR, 2'd0, 8'd1, 8'd1);
      wire_cell(8'd3, 8'd1, 2'd0, 8'd2);
      wire_cell(8'd4, 8'd1, 2'd0, 8'd2);

      run_dut(1);

      expect_nodes(0, FF, 8'd0);
      $display("run_case_ground_facing_component passed.");
    end
  endtask

  // D-021 / D-019 / D-015: a vertical wire running past the resistor's anchor
  // end does not connect (floating row), and a current source's n0 is the
  // terminal beyond its partner half.
  task automatic run_case_non_facing_and_floating_rows;
    begin
      reset_design();
      wire_cell(8'd0, 8'd0, 2'd1, 8'd1);
      wire_cell(8'd0, 8'd1, 2'd1, 8'd1);
      wire_cell(8'd0, 8'd2, 2'd1, 8'd1);
      place_component(0, TYPE_RL[3:0], TYPE_RR, 2'd0, 8'd1, 8'd1);
      wire_cell(8'd3, 8'd1, 2'd0, 8'd2);
      wire_cell(8'd4, 8'd1, 2'd0, 8'd2);
      place_component(1, TYPE_IL, TYPE_IR, 2'd0, 8'd2, 8'd4);
      wire_cell(8'd4, 8'd4, 2'd0, 8'd3);
      wire_cell(8'd5, 8'd4, 2'd0, 8'd3);

      run_dut(2);

      // Region rows 0..2 (regions 1, 2, 3); floating rows 3 and 4.
      expect_nodes(0, 8'd3, 8'd1);
      expect_nodes(1, 8'd2, 8'd4);
      $display("run_case_non_facing_and_floating_rows passed.");
    end
  endtask

  // D-021: a ground pointing at a wire that does not point back, or at a
  // component half, grounds nothing; it is a grounded region of its own.
  task automatic run_case_ground_not_reciprocal;
    begin
      reset_design();
      ground_cell(8'd2, 8'd0, 2'd3, 8'd1);  // port down, into a horizontal wire
      wire_cell(8'd0, 8'd1, 2'd0, 8'd2);
      wire_cell(8'd1, 8'd1, 2'd0, 8'd2);
      wire_cell(8'd2, 8'd1, 2'd0, 8'd2);
      place_component(0, TYPE_RL[3:0], TYPE_RR, 2'd0, 8'd3, 8'd1);
      ground_cell(8'd1, 8'd3, 2'd3, 8'd3);  // port down, into the capacitor's anchor half
      wire_cell(8'd0, 8'd4, 2'd0, 8'd4);
      place_component(1, TYPE_CL[3:0], TYPE_CR, 2'd0, 8'd1, 8'd4);
      wire_cell(8'd3, 8'd4, 2'd0, 8'd5);

      run_dut(2);

      // Region rows: 2 -> 0, 4 -> 1, 5 -> 2; the resistor's open end is row 3.
      expect_nodes(0, 8'd0, 8'd3);
      expect_nodes(1, 8'd1, 8'd2);
      $display("run_case_ground_not_reciprocal passed.");
    end
  endtask

  // Grid edges: x - 1 wraps to 255 and x + 1 reaches the width; neither may
  // read a cell. Sparse raw ids are compacted in first-seen row-major order.
  task automatic run_case_grid_edges_and_sparse_ids;
    begin
      reset_design();
      place_component(0, TYPE_RL[3:0], TYPE_RR, 2'd0, 8'd0, 8'd0);
      wire_cell(8'd2, 8'd0, 2'd0, 8'd20);
      wire_cell(8'd5, 8'd0, 2'd0, 8'd9);
      place_component(1, TYPE_VL, TYPE_VR, 2'd2, 8'd5, 8'd5);
      wire_cell(8'd3, 8'd5, 2'd0, 8'd7);

      run_dut(2);

      // Rows: 20 -> 0, 9 -> 1, 7 -> 2; floating rows 3 and 4.
      expect_nodes(0, 8'd3, 8'd0);
      expect_nodes(1, 8'd4, 8'd2);
      $display("run_case_grid_edges_and_sparse_ids passed.");
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
    if (fetch_cell_ram_ren) begin
      fetch_cell_ram_rdata <= cell_mem[fetch_cell_ram_addr];
    end
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
      .fetchCell_start(fetchCell_start),
      .fetchCell_i(fetchCell_i),
      .fetchCell_j(fetchCell_j),
      .fetchCell_done(fetchCell_done),
      .fetchCell_result(fetchCell_result),
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

  FetchCellTb #(
      .GRID_WIDTH(GRID_WIDTH)
  ) fetch_cell_inst (
      .clk(clk),
      .start(fetchCell_start),
      .busy(fetch_cell_busy_unused),
      .done(fetchCell_done),
      .i(fetchCell_i[4:0]),
      .j(fetchCell_j[3:0]),
      .result(fetchCell_result),
      .ram_ren(fetch_cell_ram_ren),
      .ram_addr(fetch_cell_ram_addr),
      .ram_rdata(fetch_cell_ram_rdata)
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
    run_case_ground_facing_component();
    run_case_non_facing_and_floating_rows();
    run_case_ground_not_reciprocal();
    run_case_grid_edges_and_sparse_ids();
    $display("ExtractComponentNodes_test passed.");
    $finish;
  end
endmodule
