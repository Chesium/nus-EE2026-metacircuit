module CanvasBufferRam #(
    parameter integer WordWidth = 16,
    parameter integer WordCount = 256,
    parameter integer AddrWidth = $clog2(WordCount)
) (
    input  wire                 render_clk,
    input  wire [AddrWidth-1:0] render_r_addr,
    output reg  [WordWidth-1:0] render_d_out,

    input  wire                 bg_clk,
    input  wire                 bg_w_en,
    input  wire [AddrWidth-1:0] bg_w_addr,
    input  wire [AddrWidth-1:0] bg_r_addr,
    input  wire [WordWidth-1:0] bg_d_in,
    output reg  [WordWidth-1:0] bg_d_out
);

  (* ram_style = "block" *)
  reg [WordWidth-1:0] mem[WordCount-1:0];

  always @(posedge render_clk) begin
    render_d_out <= mem[render_r_addr];
  end

  always @(posedge bg_clk) begin
    if (bg_w_en) begin
      mem[bg_w_addr] <= bg_d_in;
    end
    bg_d_out <= mem[bg_r_addr];
  end

endmodule
