`timescale 1ns / 1ps

module CircuitCanvas_left_edge_test ();

  localparam integer GridWidth = 16;
  localparam integer GridHeight = 16;
  localparam integer CellSize = 32;
  localparam integer CellCount = GridWidth * GridHeight;
  localparam integer AddrWidth = $clog2(CellCount);
  localparam integer DataWidth = 16;

  localparam [DataWidth-1:0] Row0Word = 16'b0000000_10_000001_1;
  localparam [DataWidth-1:0] Row1Word = 16'b0000000_01_000010_1;
  localparam [DataWidth-1:0] Row2Word = 16'b0000000_11_001000_1;

  reg clk_pixel = 1'b0;
  always #20 clk_pixel = ~clk_pixel;  // 25 MHz

  reg [11:0] x_pos = 0;
  reg [11:0] y_pos = 0;

  wire [11:0] rgb;
  wire rendered;
  wire [AddrWidth-1:0] data_addr;
  wire [DataWidth-1:0] incoming_data;

  SimpleRam #(
      .WordWidth(DataWidth),
      .WordCount(CellCount)
  ) ram_inst (
      .clk  (clk_pixel),
      .w_en (1'b0),
      .w_addr({AddrWidth{1'b0}}),
      .r_addr(data_addr),
      .d_in ({DataWidth{1'b0}}),
      .d_out(incoming_data)
  );

  CircuitCanvas dut (
      .clk_pixel(clk_pixel),
      .x_pos(x_pos),
      .y_pos(y_pos),
      .rgb(rgb),
      .rendered(rendered),
      .mouse_x_pos(12'd0),
      .mouse_y_pos(12'd0),
      .data_addr(data_addr),
      .incoming_data(incoming_data),
      .display_grid(1'b1),
      .mouse_left_click(1'b0)
  );

  integer failure_count = 0;
  integer sample_x;

  task automatic log_sample;
    input signed [12:0] pan_x;
    input integer row;
    begin
      $display("pan_x=%0d row=%0d x=%0d y=%0d req=(%0d,%0d) req2=(%0d,%0d) data_addr=%0d req_idx=(%0d,%0d) ret_idx=(%0d,%0d) cache_idx=(%0d,%0d) incoming_data=%h cell_data=%h",
               pan_x, row, x_pos, y_pos, dut.required_i, dut.required_j, dut.required_i_2,
               dut.required_j_2, data_addr, dut.requested_data_i, dut.requested_data_j,
               dut.returned_data_i, dut.returned_data_j, dut.cached_data_i,
               dut.cached_data_j, incoming_data, dut.cell_data);
    end
  endtask

  task automatic expect_word;
    input [DataWidth-1:0] got;
    input [DataWidth-1:0] expected;
    input [255:0] message;
    begin
      if (got !== expected) begin
        failure_count = failure_count + 1;
        $display("FAIL: %0s got=%h expected=%h", message, got, expected);
      end
    end
  endtask

  task automatic run_left_edge_case;
    input signed [12:0] pan_x;
    input integer row;
    input [DataWidth-1:0] expected_word;
    integer sample_y;
    begin
      dut.grid_pos_x = pan_x;
      dut.grid_pos_y = 13'sd0;

      sample_y = (row * CellSize) + 8;

      x_pos = 12'd398;
      y_pos = sample_y - 1;
      @(posedge clk_pixel);
      #1;
      log_sample(pan_x, row);

      x_pos = 12'd399;
      y_pos = sample_y - 1;
      @(posedge clk_pixel);
      #1;
      log_sample(pan_x, row);

      for (sample_x = 0; sample_x < 6; sample_x = sample_x + 1) begin
        x_pos = sample_x[11:0];
        y_pos = sample_y;
        @(posedge clk_pixel);
        #1;
        log_sample(pan_x, row);

        if (dut.required_i == 0 && dut.required_j == row) begin
          if (dut.returned_data_i == 0 && dut.returned_data_j == row) begin
            expect_word(incoming_data, expected_word,
                        "incoming_data should match the left-edge sprite word");
          end

          if (sample_x >= 1 || dut.returned_data_i == 0) begin
            expect_word(dut.cell_data, expected_word,
                        "cell_data should settle to the left-edge sprite word");
          end
        end
      end
    end
  endtask

  initial begin
    integer idx;

    for (idx = 0; idx < CellCount; idx = idx + 1) begin
      ram_inst.mem[idx] = 16'd0;
    end

    ram_inst.mem[0] = Row0Word;
    ram_inst.mem[16] = Row1Word;
    ram_inst.mem[32] = Row2Word;

    repeat (6) @(posedge clk_pixel);

    $display("Running left-edge fetch checks with pan_x = 0...");
    run_left_edge_case(13'sd0, 0, Row0Word);
    run_left_edge_case(13'sd0, 1, Row1Word);
    run_left_edge_case(13'sd0, 2, Row2Word);

    $display("Running left-edge fetch checks with pan_x = -8...");
    run_left_edge_case(-13'sd8, 0, Row0Word);
    run_left_edge_case(-13'sd8, 1, Row1Word);
    run_left_edge_case(-13'sd8, 2, Row2Word);

    $display("Running left-edge fetch checks with pan_x = -31...");
    run_left_edge_case(-13'sd31, 0, Row0Word);
    run_left_edge_case(-13'sd31, 1, Row1Word);
    run_left_edge_case(-13'sd31, 2, Row2Word);

    if (failure_count == 0) begin
      $display("CircuitCanvas_left_edge_test completed without reproducing a mismatch.");
      $finish;
    end else begin
      $fatal(1, "CircuitCanvas_left_edge_test reproduced %0d mismatch(es).", failure_count);
    end
  end

endmodule
