`timescale 1ns / 1ps

module StampingNetlistStore_test;
  localparam integer ELEM_COUNT = 3;

  reg clk = 1'b0;
  reg rst_n = 1'b0;
  always #5 clk = ~clk;

  reg fetchElemKind_start = 1'b0;
  reg [15:0] fetchElemKind_idx = '0;
  wire fetchElemKind_done;
  wire [7:0] fetchElemKind_result;

  reg fetchElemN0_start = 1'b0;
  reg [15:0] fetchElemN0_idx = '0;
  wire fetchElemN0_done;
  wire [15:0] fetchElemN0_result;

  reg fetchElemN1_start = 1'b0;
  reg [15:0] fetchElemN1_idx = '0;
  wire fetchElemN1_done;
  wire [15:0] fetchElemN1_result;

  reg fetchElemN2_start = 1'b0;
  reg [15:0] fetchElemN2_idx = '0;
  wire fetchElemN2_done;
  wire [15:0] fetchElemN2_result;

  reg fetchElemN3_start = 1'b0;
  reg [15:0] fetchElemN3_idx = '0;
  wire fetchElemN3_done;
  wire [15:0] fetchElemN3_result;

  reg fetchElemAux_start = 1'b0;
  reg [15:0] fetchElemAux_idx = '0;
  wire fetchElemAux_done;
  wire [15:0] fetchElemAux_result;

  reg fetchElemVal0_start = 1'b0;
  reg [15:0] fetchElemVal0_idx = '0;
  wire fetchElemVal0_done;
  wire [31:0] fetchElemVal0_result;

  reg fetchElemVal1_start = 1'b0;
  reg [15:0] fetchElemVal1_idx = '0;
  wire fetchElemVal1_done;
  wire [31:0] fetchElemVal1_result;

  reg fetchElemVal2_start = 1'b0;
  reg [15:0] fetchElemVal2_idx = '0;
  wire fetchElemVal2_done;
  wire [31:0] fetchElemVal2_result;

  reg fetchElemVal3_start = 1'b0;
  reg [15:0] fetchElemVal3_idx = '0;
  wire fetchElemVal3_done;
  wire [31:0] fetchElemVal3_result;

  StampingNetlistStore #(
      .ELEM_COUNT(ELEM_COUNT)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .fetchElemKind_start(fetchElemKind_start),
      .fetchElemKind_idx(fetchElemKind_idx),
      .fetchElemKind_done(fetchElemKind_done),
      .fetchElemKind_result(fetchElemKind_result),
      .fetchElemN0_start(fetchElemN0_start),
      .fetchElemN0_idx(fetchElemN0_idx),
      .fetchElemN0_done(fetchElemN0_done),
      .fetchElemN0_result(fetchElemN0_result),
      .fetchElemN1_start(fetchElemN1_start),
      .fetchElemN1_idx(fetchElemN1_idx),
      .fetchElemN1_done(fetchElemN1_done),
      .fetchElemN1_result(fetchElemN1_result),
      .fetchElemN2_start(fetchElemN2_start),
      .fetchElemN2_idx(fetchElemN2_idx),
      .fetchElemN2_done(fetchElemN2_done),
      .fetchElemN2_result(fetchElemN2_result),
      .fetchElemN3_start(fetchElemN3_start),
      .fetchElemN3_idx(fetchElemN3_idx),
      .fetchElemN3_done(fetchElemN3_done),
      .fetchElemN3_result(fetchElemN3_result),
      .fetchElemAux_start(fetchElemAux_start),
      .fetchElemAux_idx(fetchElemAux_idx),
      .fetchElemAux_done(fetchElemAux_done),
      .fetchElemAux_result(fetchElemAux_result),
      .fetchElemVal0_start(fetchElemVal0_start),
      .fetchElemVal0_idx(fetchElemVal0_idx),
      .fetchElemVal0_done(fetchElemVal0_done),
      .fetchElemVal0_result(fetchElemVal0_result),
      .fetchElemVal1_start(fetchElemVal1_start),
      .fetchElemVal1_idx(fetchElemVal1_idx),
      .fetchElemVal1_done(fetchElemVal1_done),
      .fetchElemVal1_result(fetchElemVal1_result),
      .fetchElemVal2_start(fetchElemVal2_start),
      .fetchElemVal2_idx(fetchElemVal2_idx),
      .fetchElemVal2_done(fetchElemVal2_done),
      .fetchElemVal2_result(fetchElemVal2_result),
      .fetchElemVal3_start(fetchElemVal3_start),
      .fetchElemVal3_idx(fetchElemVal3_idx),
      .fetchElemVal3_done(fetchElemVal3_done),
      .fetchElemVal3_result(fetchElemVal3_result)
  );

  task automatic issue_fetch_kind(
      input [15:0] idx,
      input [7:0] expected
  );
    begin
      @(negedge clk);
      fetchElemKind_idx <= idx;
      fetchElemKind_start <= 1'b1;
      @(negedge clk);
      fetchElemKind_start <= 1'b0;
      @(posedge clk);
      #1;
      if (fetchElemKind_done !== 1'b1 || fetchElemKind_result !== expected) begin
        $fatal(1, "fetchElemKind mismatch: idx=%0d got_done=%0d got=%0h expected=%0h",
               idx, fetchElemKind_done, fetchElemKind_result, expected);
      end
    end
  endtask

  task automatic issue_fetch_n0(
      input [15:0] idx,
      input [15:0] expected
  );
    begin
      @(negedge clk);
      fetchElemN0_idx <= idx;
      fetchElemN0_start <= 1'b1;
      @(negedge clk);
      fetchElemN0_start <= 1'b0;
      @(posedge clk);
      #1;
      if (fetchElemN0_done !== 1'b1 || fetchElemN0_result !== expected) begin
        $fatal(1, "fetchElemN0 mismatch: idx=%0d got_done=%0d got=%0h expected=%0h",
               idx, fetchElemN0_done, fetchElemN0_result, expected);
      end
    end
  endtask

  task automatic issue_fetch_n1(
      input [15:0] idx,
      input [15:0] expected
  );
    begin
      @(negedge clk);
      fetchElemN1_idx <= idx;
      fetchElemN1_start <= 1'b1;
      @(negedge clk);
      fetchElemN1_start <= 1'b0;
      @(posedge clk);
      #1;
      if (fetchElemN1_done !== 1'b1 || fetchElemN1_result !== expected) begin
        $fatal(1, "fetchElemN1 mismatch: idx=%0d got_done=%0d got=%0h expected=%0h",
               idx, fetchElemN1_done, fetchElemN1_result, expected);
      end
    end
  endtask

  task automatic issue_fetch_n2(
      input [15:0] idx,
      input [15:0] expected
  );
    begin
      @(negedge clk);
      fetchElemN2_idx <= idx;
      fetchElemN2_start <= 1'b1;
      @(negedge clk);
      fetchElemN2_start <= 1'b0;
      @(posedge clk);
      #1;
      if (fetchElemN2_done !== 1'b1 || fetchElemN2_result !== expected) begin
        $fatal(1, "fetchElemN2 mismatch: idx=%0d got_done=%0d got=%0h expected=%0h",
               idx, fetchElemN2_done, fetchElemN2_result, expected);
      end
    end
  endtask

  task automatic issue_fetch_n3(
      input [15:0] idx,
      input [15:0] expected
  );
    begin
      @(negedge clk);
      fetchElemN3_idx <= idx;
      fetchElemN3_start <= 1'b1;
      @(negedge clk);
      fetchElemN3_start <= 1'b0;
      @(posedge clk);
      #1;
      if (fetchElemN3_done !== 1'b1 || fetchElemN3_result !== expected) begin
        $fatal(1, "fetchElemN3 mismatch: idx=%0d got_done=%0d got=%0h expected=%0h",
               idx, fetchElemN3_done, fetchElemN3_result, expected);
      end
    end
  endtask

  task automatic issue_fetch_aux(
      input [15:0] idx,
      input [15:0] expected
  );
    begin
      @(negedge clk);
      fetchElemAux_idx <= idx;
      fetchElemAux_start <= 1'b1;
      @(negedge clk);
      fetchElemAux_start <= 1'b0;
      @(posedge clk);
      #1;
      if (fetchElemAux_done !== 1'b1 || fetchElemAux_result !== expected) begin
        $fatal(1, "fetchElemAux mismatch: idx=%0d got_done=%0d got=%0h expected=%0h",
               idx, fetchElemAux_done, fetchElemAux_result, expected);
      end
    end
  endtask

  task automatic issue_fetch_v0(
      input [15:0] idx,
      input [31:0] expected
  );
    begin
      @(negedge clk);
      fetchElemVal0_idx <= idx;
      fetchElemVal0_start <= 1'b1;
      @(negedge clk);
      fetchElemVal0_start <= 1'b0;
      @(posedge clk);
      #1;
      if (fetchElemVal0_done !== 1'b1 || fetchElemVal0_result !== expected) begin
        $fatal(1, "fetchElemVal0 mismatch: idx=%0d got_done=%0d got=%0h expected=%0h",
               idx, fetchElemVal0_done, fetchElemVal0_result, expected);
      end
    end
  endtask

  task automatic issue_fetch_v1(
      input [15:0] idx,
      input [31:0] expected
  );
    begin
      @(negedge clk);
      fetchElemVal1_idx <= idx;
      fetchElemVal1_start <= 1'b1;
      @(negedge clk);
      fetchElemVal1_start <= 1'b0;
      @(posedge clk);
      #1;
      if (fetchElemVal1_done !== 1'b1 || fetchElemVal1_result !== expected) begin
        $fatal(1, "fetchElemVal1 mismatch: idx=%0d got_done=%0d got=%0h expected=%0h",
               idx, fetchElemVal1_done, fetchElemVal1_result, expected);
      end
    end
  endtask

  task automatic issue_fetch_v2(
      input [15:0] idx,
      input [31:0] expected
  );
    begin
      @(negedge clk);
      fetchElemVal2_idx <= idx;
      fetchElemVal2_start <= 1'b1;
      @(negedge clk);
      fetchElemVal2_start <= 1'b0;
      @(posedge clk);
      #1;
      if (fetchElemVal2_done !== 1'b1 || fetchElemVal2_result !== expected) begin
        $fatal(1, "fetchElemVal2 mismatch: idx=%0d got_done=%0d got=%0h expected=%0h",
               idx, fetchElemVal2_done, fetchElemVal2_result, expected);
      end
    end
  endtask

  task automatic issue_fetch_v3(
      input [15:0] idx,
      input [31:0] expected
  );
    begin
      @(negedge clk);
      fetchElemVal3_idx <= idx;
      fetchElemVal3_start <= 1'b1;
      @(negedge clk);
      fetchElemVal3_start <= 1'b0;
      @(posedge clk);
      #1;
      if (fetchElemVal3_done !== 1'b1 || fetchElemVal3_result !== expected) begin
        $fatal(1, "fetchElemVal3 mismatch: idx=%0d got_done=%0d got=%0h expected=%0h",
               idx, fetchElemVal3_done, fetchElemVal3_result, expected);
      end
    end
  endtask

  initial begin
    repeat (4) @(negedge clk);
    rst_n <= 1'b1;

    dut.kind_mem[0] = 8'h03;
    dut.n0_mem[0] = 16'h0001;
    dut.n1_mem[0] = 16'hffff;
    dut.n2_mem[0] = 16'h0000;
    dut.n3_mem[0] = 16'h0000;
    dut.aux_mem[0] = 16'h0004;
    dut.v0_mem[0] = $shortrealtobits(5.0);
    dut.v1_mem[0] = $shortrealtobits(0.0);
    dut.v2_mem[0] = $shortrealtobits(1.0);
    dut.v3_mem[0] = $shortrealtobits(0.5);

    dut.kind_mem[1] = 8'h01;
    dut.n0_mem[1] = 16'h0002;
    dut.n1_mem[1] = 16'h0003;
    dut.v0_mem[1] = $shortrealtobits(0.25);
    dut.v1_mem[1] = $shortrealtobits(0.0);
    dut.v2_mem[1] = $shortrealtobits(1.0);
    dut.v3_mem[1] = $shortrealtobits(2.0);

    issue_fetch_kind(16'd0, 8'h03);
    issue_fetch_n0(16'd0, 16'h0001);
    issue_fetch_n1(16'd0, 16'hffff);
    issue_fetch_n2(16'd1, 16'h0000);
    issue_fetch_n3(16'd1, 16'h0000);
    issue_fetch_aux(16'd0, 16'h0004);
    issue_fetch_v0(16'd1, $shortrealtobits(0.25));
    issue_fetch_v1(16'd0, $shortrealtobits(0.0));
    issue_fetch_v2(16'd0, $shortrealtobits(1.0));
    issue_fetch_v3(16'd1, $shortrealtobits(2.0));

    issue_fetch_kind(16'd9, 8'h00);
    issue_fetch_aux(16'd9, 16'h0000);

    $display("StampingNetlistStore_test passed.");
    $finish;
  end
endmodule
