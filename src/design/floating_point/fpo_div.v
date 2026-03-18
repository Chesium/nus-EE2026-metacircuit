module fpo_div (
    input wire clk,

    input wire        start,
    input wire [31:0] a,
    input wire [31:0] b,

    output reg        busy,
    output reg        done,
    output reg [31:0] result,
    output reg        exc_underflow,
    output reg        exc_overflow,
    output reg        exc_invalid,
    output reg        exc_div0
);
  localparam integer StateIdle = 2'd0;
  localparam integer StateIssue = 2'd1;
  localparam integer StateWaitRes = 2'd2;

  reg [1:0] state;

  reg [31:0] a_reg, b_reg;

  // -------- AXI-stream to IP --------
  reg         s_axis_a_tvalid;
  reg  [31:0] s_axis_a_tdata;

  reg         s_axis_b_tvalid;
  reg  [31:0] s_axis_b_tdata;

  reg         s_axis_c_tvalid;
  reg  [31:0] s_axis_c_tdata;

  wire        m_axis_result_tvalid;
  wire [31:0] m_axis_result_tdata;
  wire [ 3:0] m_axis_result_tuser;  // 假设只开了3个异常位

  // 仅作为示例：异常位映射
  localparam integer ExcUnderflowBit = 0;
  localparam integer ExcOverflowBit = 1;
  localparam integer ExcInvalidBit = 2;
  localparam integer ExcDiv0Bit = 3;

  floating_point_div div_inst (
      .aclk           (clk),              // input wire aclk
      .s_axis_a_tvalid(s_axis_a_tvalid),  // input wire s_axis_a_tvalid
      .s_axis_a_tdata (s_axis_a_tdata),   // input wire [31 : 0] s_axis_a_tdata

      .s_axis_b_tvalid(s_axis_b_tvalid),  // input wire s_axis_b_tvalid
      .s_axis_b_tdata (s_axis_b_tdata),   // input wire [31 : 0] s_axis_b_tdata

      .m_axis_result_tvalid(m_axis_result_tvalid),  // output wire m_axis_result_tvalid
      .m_axis_result_tdata (m_axis_result_tdata),   // output wire [31 : 0] m_axis_result_tdata
      .m_axis_result_tuser (m_axis_result_tuser)    // output wire [2 : 0] m_axis_result_tuser
  );

  initial begin
    state <= StateIdle;
    busy <= 1'b0;
    done <= 1'b0;

    a_reg <= 32'd0;
    b_reg <= 32'd0;

    s_axis_a_tvalid <= 1'b0;
    s_axis_b_tvalid <= 1'b0;

    s_axis_a_tdata <= 32'd0;
    s_axis_b_tdata <= 32'd0;

    result <= 32'd0;
    exc_underflow <= 1'b0;
    exc_overflow <= 1'b0;
    exc_invalid <= 1'b0;
  end

  always @(posedge clk) begin
    done <= 1'b0;  // 默认单拍脉冲

    case (state)
      StateIdle: begin
        busy <= 1'b0;

        s_axis_a_tvalid <= 1'b0;
        s_axis_b_tvalid <= 1'b0;

        if (start) begin
          // 锁存输入
          a_reg <= a;
          b_reg <= b;

          s_axis_a_tdata <= a;
          s_axis_b_tdata <= b;

          // 开始发数，若tready未就绪则保持tvalid
          s_axis_a_tvalid <= 1'b1;
          s_axis_b_tvalid <= 1'b1;

          busy <= 1'b1;
          state <= StateIssue;
        end
      end

      StateIssue: begin
        busy <= 1'b1;

        s_axis_a_tvalid <= 1'b0;
        s_axis_b_tvalid <= 1'b0;
        state <= StateWaitRes;
      end

      StateWaitRes: begin
        busy <= 1'b1;

        if (m_axis_result_tvalid) begin
          result        <= m_axis_result_tdata;

          exc_underflow <= m_axis_result_tuser[ExcUnderflowBit];
          exc_overflow  <= m_axis_result_tuser[ExcOverflowBit];
          exc_invalid   <= m_axis_result_tuser[ExcInvalidBit];
          exc_div0      <= m_axis_result_tuser[ExcDiv0Bit];

          done          <= 1'b1;
          busy          <= 1'b0;
          state         <= StateIdle;
        end
      end

      default: begin
        state <= StateIdle;
      end
    endcase
  end

endmodule
