`timescale 1ns / 1ps

module UartPacketParser_test;
  localparam integer MAX_LINE_BYTES = 48;

  reg clk = 1'b0;
  reg rst_n = 1'b0;
  reg line_valid = 1'b0;
  reg line_overflow = 1'b0;
  reg [7:0] line_len = 8'd0;
  reg [MAX_LINE_BYTES*8-1:0] line_data = '0;

  wire snapshot_begin_valid;
  wire [15:0] snapshot_begin_frame;
  wire [7:0] snapshot_begin_elem_count;
  wire [7:0] snapshot_begin_node_count;
  wire component_valid;
  wire [15:0] component_frame;
  wire [7:0] component_idx;
  wire [7:0] component_kind;
  wire [7:0] component_n0;
  wire [7:0] component_n1;
  wire [11:0] component_value_bcd;
  wire [7:0] component_unit;
  wire snapshot_end_valid;
  wire [15:0] snapshot_end_frame;
  wire [7:0] snapshot_end_elem_count;
  wire [7:0] snapshot_end_node_count;
  wire parse_error;
  wire [7:0] parse_error_code;
  wire [15:0] parse_error_arg;
  wire [15:0] parse_error_frame;

  always #5 clk = ~clk;

  UartPacketParser #(
      .MAX_LINE_BYTES(MAX_LINE_BYTES),
      .MAX_ELEMS(32),
      .MAX_NODES(32)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .line_valid(line_valid),
      .line_overflow(line_overflow),
      .line_len(line_len),
      .line_data(line_data),
      .snapshot_begin_valid(snapshot_begin_valid),
      .snapshot_begin_frame(snapshot_begin_frame),
      .snapshot_begin_elem_count(snapshot_begin_elem_count),
      .snapshot_begin_node_count(snapshot_begin_node_count),
      .component_valid(component_valid),
      .component_frame(component_frame),
      .component_idx(component_idx),
      .component_kind(component_kind),
      .component_n0(component_n0),
      .component_n1(component_n1),
      .component_value_bcd(component_value_bcd),
      .component_unit(component_unit),
      .snapshot_end_valid(snapshot_end_valid),
      .snapshot_end_frame(snapshot_end_frame),
      .snapshot_end_elem_count(snapshot_end_elem_count),
      .snapshot_end_node_count(snapshot_end_node_count),
      .parse_error(parse_error),
      .parse_error_code(parse_error_code),
      .parse_error_arg(parse_error_arg),
      .parse_error_frame(parse_error_frame)
  );

  task automatic drive_line(input string s);
    integer idx;
    begin
      line_data = '0;
      line_len = s.len();
      for (idx = 0; idx < s.len(); idx = idx + 1) begin
        line_data[(idx*8) +: 8] = s[idx];
      end
      @(posedge clk);
      line_valid <= 1'b1;
      @(posedge clk);
      line_valid <= 1'b0;
      line_len <= 8'd0;
      line_data <= '0;
    end
  endtask

  initial begin
    repeat (4) @(posedge clk);
    rst_n = 1'b1;

    drive_line("@NB,0001,03,02*20");
    wait (snapshot_begin_valid);
    if (snapshot_begin_frame !== 16'h0001 || snapshot_begin_elem_count !== 8'h03 || snapshot_begin_node_count !== 8'h02) begin
      $fatal(1, "UartPacketParser_test bad NB decode");
    end

    drive_line("@NC,0001,00,03,00,FF,500,00*16");
    wait (component_valid);
    if (component_idx !== 8'h00 || component_kind !== 8'h03 || component_n0 !== 8'h00 || component_n1 !== 8'hFF || component_value_bcd !== 12'h500) begin
      $fatal(1, "UartPacketParser_test bad NC decode");
    end

    drive_line("@NE,0001,03,02*27");
    wait (parse_error);
    if (parse_error_code !== 8'h01) begin
      $fatal(1, "UartPacketParser_test expected sequence error on early end");
    end

    drive_line("@NB,0002,01,01*22");
    wait (snapshot_begin_valid);
    drive_line("@NC,0002,00,09,00,FF,001,00*1B");
    wait (parse_error);
    if (parse_error_code !== 8'h02) begin
      $fatal(1, "UartPacketParser_test expected unsupported kind error");
    end

    $display("UartPacketParser_test passed.");
    $finish;
  end
endmodule
