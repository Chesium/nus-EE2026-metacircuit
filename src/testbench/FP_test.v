`timescale 1ns / 1ps

module FP_test ();

  reg aclk_100m = 0;
  reg aclk_resetn;
  always #5 aclk_100m = ~aclk_100m;  // 10ns => 100MHz

  reg         s_axis_a_tvalid;
  reg  [31:0] s_axis_a_tdata;

  reg         s_axis_b_tvalid;
  reg  [31:0] s_axis_b_tdata;

  wire        m_axis_result_tvalid;
  wire [31:0] m_axis_result_tdata;
  wire [ 2:0] m_axis_result_tuser;

  reg         busy;
  reg  [31:0] res;
  reg  [ 2:0] err;

  initial begin
    s_axis_a_tvalid = 1'b0;  // no valid data placed on the S_AXIS_TDATA yet
    s_axis_b_tvalid = 1'b0;
    aclk_resetn = 1'b0;  // apply reset (active low)

    #10  // hold reset for one cycle

    aclk_resetn = 1'b1;  // release reset

    // A        hex : 40C80000
    // B        hex : 41540000
    // Expected hex : 419C0000
    s_axis_a_tdata  = 32'h40C80000;
    s_axis_b_tdata  = 32'h41540000;
    s_axis_a_tvalid = 1'b1;  // data is ready to be put into the floating point ip
    s_axis_b_tvalid = 1'b1;
    busy            = 1'b1;

    #10 // wait for one clock cycle for ip to capture data

    s_axis_a_tvalid = 1'b0;  // we no longer give any data to the ip
    s_axis_b_tvalid = 1'b0;

    while (busy) begin
      if (m_axis_result_tvalid) begin
        res = m_axis_result_tdata;
        err = m_axis_result_tuser;
        busy = 1'b0;
      end
      #10;
    end

    #10 // wait for one final clock cycle before ending the simulation

    $finish;
  end

  floating_point_0 fp0_inst (
      .aclk                (aclk_100m),             // input wire aclk
      .s_axis_a_tvalid     (s_axis_a_tvalid),       // input wire s_axis_a_tvalid
      .s_axis_a_tdata      (s_axis_a_tdata),        // input wire [31 : 0] s_axis_a_tdata
      .s_axis_b_tvalid     (s_axis_b_tvalid),       // input wire s_axis_b_tvalid
      .s_axis_b_tdata      (s_axis_b_tdata),        // input wire [31 : 0] s_axis_b_tdata
      .m_axis_result_tvalid(m_axis_result_tvalid),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata (m_axis_result_tdata),   // output wire [31 : 0] m_axis_result_tdata
      .m_axis_result_tuser (m_axis_result_tuser)    // output wire [2 : 0] m_axis_result_tuser
  );

endmodule
