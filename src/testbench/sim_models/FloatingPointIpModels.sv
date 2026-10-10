`timescale 1ns / 1ps

// Simulation-only behavioural models of the Xilinx floating-point IP cores that
// src/design/floating_point/fpo_{fma,div}.v wrap (src/ip/*.xci), so the solver
// benches build with Verilator. Fixed latency, one result per valid input.
// Arithmetic is done in double precision and rounded to single precision, so
// fma rounds twice (exact product, double sum, then float); the real IP's
// bit-level behaviour is not modelled. Exception flags are not modelled.

module floating_point_fma #(
    parameter integer LATENCY = 4
) (
    input  wire        aclk,
    input  wire        s_axis_a_tvalid,
    input  wire [31:0] s_axis_a_tdata,
    input  wire        s_axis_b_tvalid,
    input  wire [31:0] s_axis_b_tdata,
    input  wire        s_axis_c_tvalid,
    input  wire [31:0] s_axis_c_tdata,
    output wire        m_axis_result_tvalid,
    output wire [31:0] m_axis_result_tdata,
    output wire [3:0]  m_axis_result_tuser
);
  reg [LATENCY-1:0] valid_pipe = '0;
  reg [31:0] data_pipe [0:LATENCY-1];
  integer k;

  always @(posedge aclk) begin
    valid_pipe <= {valid_pipe[LATENCY-2:0], s_axis_a_tvalid && s_axis_b_tvalid && s_axis_c_tvalid};
    data_pipe[0] <= Fp32SimPkg::real_to_fp32(
        Fp32SimPkg::fp32_to_real(s_axis_a_tdata) * Fp32SimPkg::fp32_to_real(s_axis_b_tdata) +
        Fp32SimPkg::fp32_to_real(s_axis_c_tdata));
    for (k = 1; k < LATENCY; k = k + 1) data_pipe[k] <= data_pipe[k-1];
  end

  assign m_axis_result_tvalid = valid_pipe[LATENCY-1];
  assign m_axis_result_tdata = data_pipe[LATENCY-1];
  assign m_axis_result_tuser = 4'd0;
endmodule

module floating_point_div #(
    parameter integer LATENCY = 6
) (
    input  wire        aclk,
    input  wire        s_axis_a_tvalid,
    input  wire [31:0] s_axis_a_tdata,
    input  wire        s_axis_b_tvalid,
    input  wire [31:0] s_axis_b_tdata,
    output wire        m_axis_result_tvalid,
    output wire [31:0] m_axis_result_tdata,
    output wire [3:0]  m_axis_result_tuser
);
  reg [LATENCY-1:0] valid_pipe = '0;
  reg [31:0] data_pipe [0:LATENCY-1];
  integer k;

  always @(posedge aclk) begin
    valid_pipe <= {valid_pipe[LATENCY-2:0], s_axis_a_tvalid && s_axis_b_tvalid};
    data_pipe[0] <= Fp32SimPkg::real_to_fp32(
        Fp32SimPkg::fp32_to_real(s_axis_a_tdata) / Fp32SimPkg::fp32_to_real(s_axis_b_tdata));
    for (k = 1; k < LATENCY; k = k + 1) data_pipe[k] <= data_pipe[k-1];
  end

  assign m_axis_result_tvalid = valid_pipe[LATENCY-1];
  assign m_axis_result_tdata = data_pipe[LATENCY-1];
  assign m_axis_result_tuser = 4'd0;
endmodule
