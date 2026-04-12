`timescale 1ns / 1ps

module StampingNetlistStore #(
    parameter integer ELEM_COUNT = 16
) (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        fetchElemKind_start,
    input  wire [15:0] fetchElemKind_idx,
    output reg         fetchElemKind_done,
    output reg  [7:0]  fetchElemKind_result,

    input  wire        fetchElemN0_start,
    input  wire [15:0] fetchElemN0_idx,
    output reg         fetchElemN0_done,
    output reg  [7:0]  fetchElemN0_result,

    input  wire        fetchElemN1_start,
    input  wire [15:0] fetchElemN1_idx,
    output reg         fetchElemN1_done,
    output reg  [7:0]  fetchElemN1_result,

    input  wire        fetchElemN2_start,
    input  wire [15:0] fetchElemN2_idx,
    output reg         fetchElemN2_done,
    output reg  [7:0]  fetchElemN2_result,

    input  wire        fetchElemN3_start,
    input  wire [15:0] fetchElemN3_idx,
    output reg         fetchElemN3_done,
    output reg  [7:0]  fetchElemN3_result,

    input  wire        fetchElemAux_start,
    input  wire [15:0] fetchElemAux_idx,
    output reg         fetchElemAux_done,
    output reg  [7:0]  fetchElemAux_result,

    input  wire        fetchElemVal0_start,
    input  wire [15:0] fetchElemVal0_idx,
    output reg         fetchElemVal0_done,
    output reg  [31:0] fetchElemVal0_result,

    input  wire        fetchElemVal1_start,
    input  wire [15:0] fetchElemVal1_idx,
    output reg         fetchElemVal1_done,
    output reg  [31:0] fetchElemVal1_result,

    input  wire        fetchElemVal2_start,
    input  wire [15:0] fetchElemVal2_idx,
    output reg         fetchElemVal2_done,
    output reg  [31:0] fetchElemVal2_result,

    input  wire        fetchElemVal3_start,
    input  wire [15:0] fetchElemVal3_idx,
    output reg         fetchElemVal3_done,
    output reg  [31:0] fetchElemVal3_result
);

  (* ram_style = "block" *) reg [7:0] kind_mem[0:ELEM_COUNT-1];
  (* ram_style = "block" *) reg [7:0] n0_mem[0:ELEM_COUNT-1];
  (* ram_style = "block" *) reg [7:0] n1_mem[0:ELEM_COUNT-1];
  (* ram_style = "block" *) reg [7:0] n2_mem[0:ELEM_COUNT-1];
  (* ram_style = "block" *) reg [7:0] n3_mem[0:ELEM_COUNT-1];
  (* ram_style = "block" *) reg [7:0] aux_mem[0:ELEM_COUNT-1];
  (* ram_style = "block" *) reg [31:0] v0_mem[0:ELEM_COUNT-1];
  (* ram_style = "block" *) reg [31:0] v1_mem[0:ELEM_COUNT-1];
  (* ram_style = "block" *) reg [31:0] v2_mem[0:ELEM_COUNT-1];
  (* ram_style = "block" *) reg [31:0] v3_mem[0:ELEM_COUNT-1];

  integer idx;

  reg kind_pending;
  reg [15:0] kind_pending_idx;
  reg n0_pending;
  reg [15:0] n0_pending_idx;
  reg n1_pending;
  reg [15:0] n1_pending_idx;
  reg n2_pending;
  reg [15:0] n2_pending_idx;
  reg n3_pending;
  reg [15:0] n3_pending_idx;
  reg aux_pending;
  reg [15:0] aux_pending_idx;
  reg v0_pending;
  reg [15:0] v0_pending_idx;
  reg v1_pending;
  reg [15:0] v1_pending_idx;
  reg v2_pending;
  reg [15:0] v2_pending_idx;
  reg v3_pending;
  reg [15:0] v3_pending_idx;

  initial begin
    for (idx = 0; idx < ELEM_COUNT; idx = idx + 1) begin
      kind_mem[idx] = '0;
      n0_mem[idx] = '0;
      n1_mem[idx] = '0;
      n2_mem[idx] = '0;
      n3_mem[idx] = '0;
      aux_mem[idx] = '0;
      v0_mem[idx] = '0;
      v1_mem[idx] = '0;
      v2_mem[idx] = '0;
      v3_mem[idx] = '0;
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      kind_pending <= 1'b0;
      kind_pending_idx <= '0;
      n0_pending <= 1'b0;
      n0_pending_idx <= '0;
      n1_pending <= 1'b0;
      n1_pending_idx <= '0;
      n2_pending <= 1'b0;
      n2_pending_idx <= '0;
      n3_pending <= 1'b0;
      n3_pending_idx <= '0;
      aux_pending <= 1'b0;
      aux_pending_idx <= '0;
      v0_pending <= 1'b0;
      v0_pending_idx <= '0;
      v1_pending <= 1'b0;
      v1_pending_idx <= '0;
      v2_pending <= 1'b0;
      v2_pending_idx <= '0;
      v3_pending <= 1'b0;
      v3_pending_idx <= '0;
      fetchElemKind_done <= 1'b0;
      fetchElemKind_result <= '0;
      fetchElemN0_done <= 1'b0;
      fetchElemN0_result <= '0;
      fetchElemN1_done <= 1'b0;
      fetchElemN1_result <= '0;
      fetchElemN2_done <= 1'b0;
      fetchElemN2_result <= '0;
      fetchElemN3_done <= 1'b0;
      fetchElemN3_result <= '0;
      fetchElemAux_done <= 1'b0;
      fetchElemAux_result <= '0;
      fetchElemVal0_done <= 1'b0;
      fetchElemVal0_result <= '0;
      fetchElemVal1_done <= 1'b0;
      fetchElemVal1_result <= '0;
      fetchElemVal2_done <= 1'b0;
      fetchElemVal2_result <= '0;
      fetchElemVal3_done <= 1'b0;
      fetchElemVal3_result <= '0;
    end else begin
      fetchElemKind_done <= kind_pending;
      if (kind_pending) begin
        fetchElemKind_result <= (kind_pending_idx < ELEM_COUNT) ? kind_mem[kind_pending_idx] : '0;
      end

      fetchElemN0_done <= n0_pending;
      if (n0_pending) begin
        fetchElemN0_result <= (n0_pending_idx < ELEM_COUNT) ? n0_mem[n0_pending_idx] : '0;
      end

      fetchElemN1_done <= n1_pending;
      if (n1_pending) begin
        fetchElemN1_result <= (n1_pending_idx < ELEM_COUNT) ? n1_mem[n1_pending_idx] : '0;
      end

      fetchElemN2_done <= n2_pending;
      if (n2_pending) begin
        fetchElemN2_result <= (n2_pending_idx < ELEM_COUNT) ? n2_mem[n2_pending_idx] : '0;
      end

      fetchElemN3_done <= n3_pending;
      if (n3_pending) begin
        fetchElemN3_result <= (n3_pending_idx < ELEM_COUNT) ? n3_mem[n3_pending_idx] : '0;
      end

      fetchElemAux_done <= aux_pending;
      if (aux_pending) begin
        fetchElemAux_result <= (aux_pending_idx < ELEM_COUNT) ? aux_mem[aux_pending_idx] : '0;
      end

      fetchElemVal0_done <= v0_pending;
      if (v0_pending) begin
        fetchElemVal0_result <= (v0_pending_idx < ELEM_COUNT) ? v0_mem[v0_pending_idx] : '0;
      end

      fetchElemVal1_done <= v1_pending;
      if (v1_pending) begin
        fetchElemVal1_result <= (v1_pending_idx < ELEM_COUNT) ? v1_mem[v1_pending_idx] : '0;
      end

      fetchElemVal2_done <= v2_pending;
      if (v2_pending) begin
        fetchElemVal2_result <= (v2_pending_idx < ELEM_COUNT) ? v2_mem[v2_pending_idx] : '0;
      end

      fetchElemVal3_done <= v3_pending;
      if (v3_pending) begin
        fetchElemVal3_result <= (v3_pending_idx < ELEM_COUNT) ? v3_mem[v3_pending_idx] : '0;
      end

      kind_pending <= fetchElemKind_start;
      if (fetchElemKind_start) begin
        kind_pending_idx <= fetchElemKind_idx;
      end

      n0_pending <= fetchElemN0_start;
      if (fetchElemN0_start) begin
        n0_pending_idx <= fetchElemN0_idx;
      end

      n1_pending <= fetchElemN1_start;
      if (fetchElemN1_start) begin
        n1_pending_idx <= fetchElemN1_idx;
      end

      n2_pending <= fetchElemN2_start;
      if (fetchElemN2_start) begin
        n2_pending_idx <= fetchElemN2_idx;
      end

      n3_pending <= fetchElemN3_start;
      if (fetchElemN3_start) begin
        n3_pending_idx <= fetchElemN3_idx;
      end

      aux_pending <= fetchElemAux_start;
      if (fetchElemAux_start) begin
        aux_pending_idx <= fetchElemAux_idx;
      end

      v0_pending <= fetchElemVal0_start;
      if (fetchElemVal0_start) begin
        v0_pending_idx <= fetchElemVal0_idx;
      end

      v1_pending <= fetchElemVal1_start;
      if (fetchElemVal1_start) begin
        v1_pending_idx <= fetchElemVal1_idx;
      end

      v2_pending <= fetchElemVal2_start;
      if (fetchElemVal2_start) begin
        v2_pending_idx <= fetchElemVal2_idx;
      end

      v3_pending <= fetchElemVal3_start;
      if (fetchElemVal3_start) begin
        v3_pending_idx <= fetchElemVal3_idx;
      end
    end
  end

endmodule
