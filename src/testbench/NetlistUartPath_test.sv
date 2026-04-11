`timescale 1ns / 1ps

module NetlistUartPath_test;
  localparam integer CLK_HZ = 100_000_000;
  localparam integer BAUD = 115200;
  localparam integer CLKS_PER_BIT = CLK_HZ / BAUD;
  localparam integer GRID_WIDTH = 6;
  localparam integer GRID_HEIGHT = 6;
  localparam integer CELL_COUNT = GRID_WIDTH * GRID_HEIGHT;
  localparam integer COMPONENT_STORE_COUNT = 8;
  localparam integer PACKET_LEN = 49;

  localparam [1:0] COMPONENT_READ_OWNER_EXTRACT = 2'd0;
  localparam [1:0] COMPONENT_READ_OWNER_DUMP    = 2'd1;

  localparam [7:0] TYPE_RL     = 8'd5;
  localparam [7:0] TYPE_CL     = 8'd13;
  localparam [7:0] TYPE_GROUND = 8'd15;

  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk;

  reg component_store_w_en = 1'b0;
  reg [$clog2(COMPONENT_STORE_COUNT)-1:0] component_store_w_addr = '0;
  reg [39:0] component_store_w_data = 40'd0;
  reg [$clog2(COMPONENT_STORE_COUNT)-1:0] component_store_ram_r_addr = '0;
  wire [39:0] component_store_ram_r_data;

  reg result_clear = 1'b0;
  reg result_store_start = 1'b0;
  reg [7:0] result_store_i = 8'd0;
  reg [7:0] result_store_j = 8'd0;
  reg [7:0] result_store_v = 8'd0;
  wire result_store_done_unused;

  reg start_extract = 1'b0;
  wire extract_busy;
  wire extract_done;

  wire        fetchComponentType_start;
  wire [15:0] fetchComponentType_idx;
  wire        fetchComponentType_done;
  wire [7:0]  fetchComponentType_result;
  wire [3:0]  fetchComponentType_result_raw;
  wire        fetchComponentType_comp_ren;
  wire [$clog2(COMPONENT_STORE_COUNT)-1:0] fetchComponentType_comp_addr;

  wire        fetchAnchorPositionX_start;
  wire [15:0] fetchAnchorPositionX_idx;
  wire        fetchAnchorPositionX_done;
  wire [7:0]  fetchAnchorPositionX_result;
  wire [4:0]  fetchAnchorPositionX_result_raw;
  wire        fetchAnchorPositionX_comp_ren;
  wire [$clog2(COMPONENT_STORE_COUNT)-1:0] fetchAnchorPositionX_comp_addr;

  wire        fetchAnchorPositionY_start;
  wire [15:0] fetchAnchorPositionY_idx;
  wire        fetchAnchorPositionY_done;
  wire [7:0]  fetchAnchorPositionY_result;
  wire [3:0]  fetchAnchorPositionY_result_raw;
  wire        fetchAnchorPositionY_comp_ren;
  wire [$clog2(COMPONENT_STORE_COUNT)-1:0] fetchAnchorPositionY_comp_addr;

  wire        fetchComponentRotation_start;
  wire [15:0] fetchComponentRotation_idx;
  wire        fetchComponentRotation_done;
  wire [1:0]  fetchComponentRotation_result;
  wire        fetchComponentRotation_comp_ren;
  wire [$clog2(COMPONENT_STORE_COUNT)-1:0] fetchComponentRotation_comp_addr;

  wire        fetchR_start;
  wire [7:0]  fetchR_i;
  wire [7:0]  fetchR_j;
  wire        fetchR_done;
  wire [7:0]  fetchR_result;

  wire        storeNode0_start;
  wire [15:0] storeNode0_idx;
  wire [7:0]  storeNode0_node_i;
  wire        storeNode0_done;
  wire        node0_w_en;
  wire [$clog2(COMPONENT_STORE_COUNT)-1:0] node0_w_addr;
  wire [7:0]  node0_w_data;

  wire        storeNode1_start;
  wire [15:0] storeNode1_idx;
  wire [7:0]  storeNode1_node_i;
  wire        storeNode1_done;
  wire        node1_w_en;
  wire [$clog2(COMPONENT_STORE_COUNT)-1:0] node1_w_addr;
  wire [7:0]  node1_w_data;

  reg [$clog2(COMPONENT_STORE_COUNT)-1:0] netlist_node_r_addr = '0;
  wire [7:0] netlist_node0_ram_r_data;
  wire [7:0] netlist_node1_ram_r_data;

  reg component_store_read_busy = 1'b0;
  reg component_store_read_snapshot_pending = 1'b0;
  reg [1:0] component_store_read_owner = COMPONENT_READ_OWNER_EXTRACT;

  wire extract_comp_ren =
      fetchComponentType_comp_ren || fetchAnchorPositionX_comp_ren ||
      fetchAnchorPositionY_comp_ren || fetchComponentRotation_comp_ren;
  wire [$clog2(COMPONENT_STORE_COUNT)-1:0] extract_comp_addr =
      fetchComponentType_comp_ren ? fetchComponentType_comp_addr :
      fetchAnchorPositionX_comp_ren ? fetchAnchorPositionX_comp_addr :
      fetchAnchorPositionY_comp_ren ? fetchAnchorPositionY_comp_addr :
      fetchComponentRotation_comp_addr;

  reg dump_active = 1'b0;
  reg dump_done = 1'b0;
  reg dump_read_request = 1'b0;
  reg dump_read_pending = 1'b0;
  reg [$clog2(COMPONENT_STORE_COUNT)-1:0] dump_idx = '0;

  reg [39:0] netlist_component_entry_snap = 40'd0;
  reg [7:0] netlist_component_node0_snap = 8'd0;
  reg [7:0] netlist_component_node1_snap = 8'd0;
  reg netlist_packet_pending = 1'b0;
  reg netlist_packet_sending = 1'b0;
  reg netlist_packet_last_char = 1'b0;
  reg netlist_uart_wait_busy = 1'b0;
  reg [5:0] netlist_packet_index = 6'd0;
  reg netlist_uart_start = 1'b0;
  reg [7:0] netlist_uart_data = 8'h00;
  wire netlist_uart_busy;
  wire netlist_uart_tx;

  reg [7:0] rx_packet[0:PACKET_LEN-1];
  integer idx;

  function automatic [7:0] ascii_hex_nibble(input [3:0] nibble);
    begin
      ascii_hex_nibble = (nibble < 4'd10) ? (8'd48 + nibble) : (8'd55 + nibble);
    end
  endfunction

  function automatic [39:0] make_component_store_entry(
      input [8:0] idx_value,
      input [3:0] type_value,
      input [1:0] rotation_value,
      input [11:0] value_value,
      input [3:0] unit_value,
      input [4:0] x_value,
      input [3:0] y_value
  );
    begin
      make_component_store_entry = {unit_value, idx_value, type_value, rotation_value, value_value, y_value, x_value};
    end
  endfunction

  function automatic [7:0] uart_netlist_packet_char(
      input [5:0] char_index,
      input [39:0] component_entry,
      input [7:0] node0,
      input [7:0] node1
  );
    reg [8:0] component_index;
    reg [3:0] component_unit;
    reg [3:0] component_type;
    reg [1:0] component_rotation;
    reg [11:0] component_value;
    reg [4:0] component_x;
    reg [3:0] component_y;
    begin
      component_unit = component_entry[39:36];
      component_index = component_entry[35:27];
      component_type = component_entry[26:23];
      component_rotation = component_entry[22:21];
      component_value = component_entry[20:9];
      component_y = component_entry[8:5];
      component_x = component_entry[4:0];

      case (char_index)
        6'd0: uart_netlist_packet_char = "C";
        6'd1: uart_netlist_packet_char = "M";
        6'd2: uart_netlist_packet_char = "P";
        6'd3: uart_netlist_packet_char = " ";
        6'd4: uart_netlist_packet_char = ascii_hex_nibble({3'd0, component_index[8]});
        6'd5: uart_netlist_packet_char = ascii_hex_nibble(component_index[7:4]);
        6'd6: uart_netlist_packet_char = ascii_hex_nibble(component_index[3:0]);
        6'd7: uart_netlist_packet_char = " ";
        6'd8: uart_netlist_packet_char = "T";
        6'd9: uart_netlist_packet_char = "=";
        6'd10: uart_netlist_packet_char = ascii_hex_nibble(component_type);
        6'd11: uart_netlist_packet_char = " ";
        6'd12: uart_netlist_packet_char = "R";
        6'd13: uart_netlist_packet_char = "=";
        6'd14: uart_netlist_packet_char = ascii_hex_nibble({2'd0, component_rotation});
        6'd15: uart_netlist_packet_char = " ";
        6'd16: uart_netlist_packet_char = "X";
        6'd17: uart_netlist_packet_char = "=";
        6'd18: uart_netlist_packet_char = ascii_hex_nibble({3'd0, component_x[4]});
        6'd19: uart_netlist_packet_char = ascii_hex_nibble(component_x[3:0]);
        6'd20: uart_netlist_packet_char = " ";
        6'd21: uart_netlist_packet_char = "Y";
        6'd22: uart_netlist_packet_char = "=";
        6'd23: uart_netlist_packet_char = "0";
        6'd24: uart_netlist_packet_char = ascii_hex_nibble(component_y);
        6'd25: uart_netlist_packet_char = " ";
        6'd26: uart_netlist_packet_char = "V";
        6'd27: uart_netlist_packet_char = "=";
        6'd28: uart_netlist_packet_char = ascii_hex_nibble(component_value[11:8]);
        6'd29: uart_netlist_packet_char = ascii_hex_nibble(component_value[7:4]);
        6'd30: uart_netlist_packet_char = ascii_hex_nibble(component_value[3:0]);
        6'd31: uart_netlist_packet_char = " ";
        6'd32: uart_netlist_packet_char = "U";
        6'd33: uart_netlist_packet_char = "=";
        6'd34: uart_netlist_packet_char = ascii_hex_nibble(component_unit);
        6'd35: uart_netlist_packet_char = " ";
        6'd36: uart_netlist_packet_char = "N";
        6'd37: uart_netlist_packet_char = "0";
        6'd38: uart_netlist_packet_char = "=";
        6'd39: uart_netlist_packet_char = ascii_hex_nibble(node0[7:4]);
        6'd40: uart_netlist_packet_char = ascii_hex_nibble(node0[3:0]);
        6'd41: uart_netlist_packet_char = " ";
        6'd42: uart_netlist_packet_char = "N";
        6'd43: uart_netlist_packet_char = "1";
        6'd44: uart_netlist_packet_char = "=";
        6'd45: uart_netlist_packet_char = ascii_hex_nibble(node1[7:4]);
        6'd46: uart_netlist_packet_char = ascii_hex_nibble(node1[3:0]);
        6'd47: uart_netlist_packet_char = 8'h0D;
        default: uart_netlist_packet_char = 8'h0A;
      endcase
    end
  endfunction

  task automatic component_store_write(
      input integer addr_value,
      input [39:0] data_value
  );
    begin
      @(negedge clk);
      component_store_w_addr <= addr_value[$clog2(COMPONENT_STORE_COUNT)-1:0];
      component_store_w_data <= data_value;
      component_store_w_en <= 1'b1;
      @(negedge clk);
      component_store_w_en <= 1'b0;
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
    end
  endtask

  task automatic uart_recv_byte(output [7:0] data_byte);
    integer bit_idx;
    begin
      while (netlist_uart_tx !== 1'b0) begin
        @(posedge clk);
      end

      repeat (CLKS_PER_BIT / 2) @(posedge clk);
      if (netlist_uart_tx !== 1'b0) begin
        $fatal(1, "UART start bit sampling failed");
      end

      repeat (CLKS_PER_BIT) @(posedge clk);
      for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
        data_byte[bit_idx] = netlist_uart_tx;
        repeat (CLKS_PER_BIT) @(posedge clk);
      end

      if (netlist_uart_tx !== 1'b1) begin
        $fatal(1, "UART stop bit missing");
      end
    end
  endtask

  task automatic uart_recv_packet;
    integer char_idx;
    reg [7:0] rx_byte;
    begin
      for (char_idx = 0; char_idx < PACKET_LEN; char_idx = char_idx + 1) begin
        uart_recv_byte(rx_byte);
        rx_packet[char_idx] = rx_byte;
      end
    end
  endtask

  task automatic expect_packet_nodes(
      input [7:0] expected_idx_lo,
      input [7:0] expected_n0_hi,
      input [7:0] expected_n0_lo,
      input [7:0] expected_n1_hi,
      input [7:0] expected_n1_lo
  );
    begin
      if (rx_packet[6] !== expected_idx_lo) begin
        $fatal(1, "Unexpected component index byte: got %s expected %s", rx_packet[6], expected_idx_lo);
      end
      if ((rx_packet[39] !== expected_n0_hi) || (rx_packet[40] !== expected_n0_lo)) begin
        $fatal(1, "Unexpected N0 bytes: got %s%s expected %s%s",
               rx_packet[39], rx_packet[40], expected_n0_hi, expected_n0_lo);
      end
      if ((rx_packet[45] !== expected_n1_hi) || (rx_packet[46] !== expected_n1_lo)) begin
        $fatal(1, "Unexpected N1 bytes: got %s%s expected %s%s",
               rx_packet[45], rx_packet[46], expected_n1_hi, expected_n1_lo);
      end
    end
  endtask

  SimpleDualClockRam #(
      .WordWidth(40),
      .WordCount(COMPONENT_STORE_COUNT)
  ) component_store_ram_inst (
      .wr_clk(clk),
      .rd_clk(clk),
      .w_en(component_store_w_en),
      .w_addr(component_store_w_addr),
      .r_addr(component_store_ram_r_addr),
      .d_in(component_store_w_data),
      .d_out(component_store_ram_r_data)
  );

  ResultMatrixStore #(
      .GRID_WIDTH(GRID_WIDTH),
      .GRID_HEIGHT(GRID_HEIGHT)
  ) result_store_inst (
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

  fetchComponentType fetch_type_inst (
      .clk(clk),
      .start(fetchComponentType_start),
      .busy(),
      .done(fetchComponentType_done),
      .idx(fetchComponentType_idx[$clog2(COMPONENT_STORE_COUNT)-1:0]),
      .result(fetchComponentType_result_raw),
      .comp_ren(fetchComponentType_comp_ren),
      .comp_addr(fetchComponentType_comp_addr),
      .comp_rdata(component_store_ram_r_data)
  );

  fetchAnchorPositionX fetch_x_inst (
      .clk(clk),
      .start(fetchAnchorPositionX_start),
      .busy(),
      .done(fetchAnchorPositionX_done),
      .idx(fetchAnchorPositionX_idx[$clog2(COMPONENT_STORE_COUNT)-1:0]),
      .result(fetchAnchorPositionX_result_raw),
      .comp_ren(fetchAnchorPositionX_comp_ren),
      .comp_addr(fetchAnchorPositionX_comp_addr),
      .comp_rdata(component_store_ram_r_data)
  );

  fetchAnchorPositionY fetch_y_inst (
      .clk(clk),
      .start(fetchAnchorPositionY_start),
      .busy(),
      .done(fetchAnchorPositionY_done),
      .idx(fetchAnchorPositionY_idx[$clog2(COMPONENT_STORE_COUNT)-1:0]),
      .result(fetchAnchorPositionY_result_raw),
      .comp_ren(fetchAnchorPositionY_comp_ren),
      .comp_addr(fetchAnchorPositionY_comp_addr),
      .comp_rdata(component_store_ram_r_data)
  );

  fetchComponentRotation fetch_rot_inst (
      .clk(clk),
      .start(fetchComponentRotation_start),
      .busy(),
      .done(fetchComponentRotation_done),
      .idx(fetchComponentRotation_idx[$clog2(COMPONENT_STORE_COUNT)-1:0]),
      .result(fetchComponentRotation_result),
      .comp_ren(fetchComponentRotation_comp_ren),
      .comp_addr(fetchComponentRotation_comp_addr),
      .comp_rdata(component_store_ram_r_data)
  );

  storeNode0 store_node0_inst (
      .clk(clk),
      .start(storeNode0_start),
      .busy(),
      .done(storeNode0_done),
      .idx(storeNode0_idx[$clog2(COMPONENT_STORE_COUNT)-1:0]),
      .node_i(storeNode0_node_i),
      .ram0_wen(node0_w_en),
      .ram0_addr(node0_w_addr),
      .ram0_wdata(node0_w_data)
  );

  storeNode1 store_node1_inst (
      .clk(clk),
      .start(storeNode1_start),
      .busy(),
      .done(storeNode1_done),
      .idx(storeNode1_idx[$clog2(COMPONENT_STORE_COUNT)-1:0]),
      .node_i(storeNode1_node_i),
      .ram1_wen(node1_w_en),
      .ram1_addr(node1_w_addr),
      .ram1_wdata(node1_w_data)
  );

  SimpleRam #(
      .WordWidth(8),
      .WordCount(COMPONENT_STORE_COUNT)
  ) node0_ram_inst (
      .clk(clk),
      .w_en(node0_w_en),
      .w_addr(node0_w_addr),
      .r_addr(netlist_node_r_addr),
      .d_in(node0_w_data),
      .d_out(netlist_node0_ram_r_data)
  );

  SimpleRam #(
      .WordWidth(8),
      .WordCount(COMPONENT_STORE_COUNT)
  ) node1_ram_inst (
      .clk(clk),
      .w_en(node1_w_en),
      .w_addr(node1_w_addr),
      .r_addr(netlist_node_r_addr),
      .d_in(node1_w_data),
      .d_out(netlist_node1_ram_r_data)
  );

  extract_component_nodes dut (
      .clk(clk),
      .rst_n(rst_n),
      .start(start_extract),
      .busy(extract_busy),
      .done(extract_done),
      .par_elem_n(32'd3),
      .grid_height(GRID_HEIGHT),
      .grid_width(GRID_WIDTH),
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

  UartTx #(
      .ClkHz(CLK_HZ),
      .BAUD(BAUD)
  ) uart_tx_inst (
      .clk(clk),
      .start(netlist_uart_start),
      .data(netlist_uart_data),
      .tx(netlist_uart_tx),
      .busy(netlist_uart_busy)
  );

  assign fetchComponentType_result = {4'd0, fetchComponentType_result_raw};
  assign fetchAnchorPositionX_result = {3'd0, fetchAnchorPositionX_result_raw};
  assign fetchAnchorPositionY_result = {4'd0, fetchAnchorPositionY_result_raw};

  always @(posedge clk) begin
    if (component_store_read_snapshot_pending) begin
      component_store_read_snapshot_pending <= 1'b0;
      if (component_store_read_owner == COMPONENT_READ_OWNER_DUMP) begin
        netlist_component_entry_snap <= component_store_ram_r_data;
        netlist_component_node0_snap <= netlist_node0_ram_r_data;
        netlist_component_node1_snap <= netlist_node1_ram_r_data;
        netlist_packet_pending <= 1'b1;
        dump_read_pending <= 1'b0;
      end
    end else if (component_store_read_busy) begin
      component_store_read_busy <= 1'b0;
      if (component_store_read_owner == COMPONENT_READ_OWNER_DUMP) begin
        component_store_read_snapshot_pending <= 1'b1;
      end
    end else begin
      if (extract_comp_ren) begin
        component_store_ram_r_addr <= extract_comp_addr;
        component_store_read_owner <= COMPONENT_READ_OWNER_EXTRACT;
        component_store_read_busy <= 1'b1;
      end else if (dump_read_request) begin
        component_store_ram_r_addr <= dump_idx;
        component_store_read_owner <= COMPONENT_READ_OWNER_DUMP;
        component_store_read_busy <= 1'b1;
      end
    end
  end

  always @(posedge clk) begin
    dump_read_request <= 1'b0;
    netlist_uart_start <= 1'b0;

    if (!rst_n) begin
      dump_active <= 1'b0;
      dump_done <= 1'b0;
      dump_read_pending <= 1'b0;
      dump_idx <= '0;
      netlist_node_r_addr <= '0;
      netlist_packet_pending <= 1'b0;
      netlist_packet_sending <= 1'b0;
      netlist_packet_last_char <= 1'b0;
      netlist_uart_wait_busy <= 1'b0;
      netlist_packet_index <= 6'd0;
    end else begin
      if (extract_done) begin
        dump_active <= 1'b1;
        dump_done <= 1'b0;
        dump_idx <= '0;
      end

      if (dump_active && !dump_read_pending && !netlist_packet_pending &&
          !netlist_packet_sending && !component_store_read_busy &&
          !component_store_read_snapshot_pending) begin
        netlist_node_r_addr <= dump_idx;
        dump_read_request <= 1'b1;
        dump_read_pending <= 1'b1;
      end

      if (!netlist_packet_sending) begin
        netlist_packet_last_char <= 1'b0;
        if (netlist_packet_pending && !netlist_uart_busy && !netlist_uart_wait_busy) begin
          netlist_uart_data <= uart_netlist_packet_char(
              6'd0,
              netlist_component_entry_snap,
              netlist_component_node0_snap,
              netlist_component_node1_snap
          );
          netlist_uart_start <= 1'b1;
          netlist_packet_pending <= 1'b0;
          netlist_packet_sending <= 1'b1;
          netlist_packet_index <= 6'd1;
          netlist_packet_last_char <= (PACKET_LEN == 1);
          netlist_uart_wait_busy <= 1'b1;
        end
      end else if (netlist_uart_wait_busy) begin
        if (netlist_uart_busy) begin
          netlist_uart_wait_busy <= 1'b0;
        end
      end else if (!netlist_uart_busy) begin
        if (netlist_packet_last_char) begin
          netlist_packet_sending <= 1'b0;
          netlist_packet_last_char <= 1'b0;
          if (dump_idx == 2) begin
            dump_active <= 1'b0;
            dump_done <= 1'b1;
          end else begin
            dump_idx <= dump_idx + 1'b1;
          end
        end else begin
          netlist_uart_data <= uart_netlist_packet_char(
              netlist_packet_index,
              netlist_component_entry_snap,
              netlist_component_node0_snap,
              netlist_component_node1_snap
          );
          netlist_uart_start <= 1'b1;
          netlist_packet_last_char <= (netlist_packet_index == PACKET_LEN - 1);
          netlist_packet_index <= netlist_packet_index + 1'b1;
          netlist_uart_wait_busy <= 1'b1;
        end
      end
    end
  end

  initial begin
    component_store_w_en = 1'b0;
    component_store_w_addr = '0;
    component_store_w_data = 40'd0;
    result_clear = 1'b0;
    result_store_start = 1'b0;
    start_extract = 1'b0;

    repeat (4) @(negedge clk);
    rst_n <= 1'b1;

    pulse_result_clear();

    component_store_write(0, make_component_store_entry(9'd0, TYPE_GROUND[3:0], 2'd1, 12'h000, 4'd0, 5'd0, 4'd2));
    component_store_write(1, make_component_store_entry(9'd1, TYPE_RL[3:0], 2'd2, 12'h123, 4'd1, 5'd2, 4'd1));
    component_store_write(2, make_component_store_entry(9'd2, TYPE_CL[3:0], 2'd0, 12'h456, 4'd2, 5'd1, 4'd1));

    store_region(8'd0, 8'd1, 8'd7);
    store_region(8'd3, 8'd1, 8'd11);

    @(negedge clk);
    start_extract <= 1'b1;
    @(negedge clk);
    start_extract <= 1'b0;

    uart_recv_packet();
    expect_packet_nodes("0", "0", "0", "0", "0");

    uart_recv_packet();
    expect_packet_nodes("1", "0", "1", "0", "0");

    uart_recv_packet();
    expect_packet_nodes("2", "0", "0", "0", "1");

    wait (dump_done == 1'b1);
    $display("NetlistUartPath_test passed.");
    $finish;
  end
endmodule
