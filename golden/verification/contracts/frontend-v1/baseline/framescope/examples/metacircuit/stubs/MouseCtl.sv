// Sim-only replacement for Digilent's VHDL MouseCtl. Position and buttons come
// from framescope virtual inputs (mouse.*) instead of the PS/2 bus, so stimulus
// can move and click the mouse directly.
module MouseCtl #(
    parameter integer SYSCLK_FREQUENCY_HZ = 100_000_000,
    parameter integer CHECK_PERIOD_MS     = 500,
    parameter integer TIMEOUT_PERIOD_MS   = 100
) (
    input  wire        clk,
    input  wire        rst,
    output reg  [11:0] xpos,
    output reg  [11:0] ypos,
    output wire [3:0]  zpos,
    output reg         left,
    output reg         middle,
    output reg         right,
    output reg         new_event,
    input  wire [11:0] value,
    input  wire        setx,
    input  wire        sety,
    input  wire        setmax_x,
    input  wire        setmax_y,
    inout  wire        ps2_clk,
    inout  wire        ps2_data
);
  import framescope_dpi::*;

  int h_x, h_y, h_left, h_middle, h_right;
  initial begin
    h_x = fs_input_handle("mouse.x");
    h_y = fs_input_handle("mouse.y");
    h_left = fs_input_handle("mouse.left");
    h_middle = fs_input_handle("mouse.middle");
    h_right = fs_input_handle("mouse.right");
    xpos = '0;
    ypos = '0;
    {left, middle, right, new_event} = '0;
  end

  assign zpos = 4'd0;

  always @(posedge clk) begin
    logic [11:0] nx, ny;
    logic nl, nm, nr;
    nx = 12'(fs_input_get(h_x));
    ny = 12'(fs_input_get(h_y));
    nl = 1'(fs_input_get(h_left));
    nm = 1'(fs_input_get(h_middle));
    nr = 1'(fs_input_get(h_right));
    new_event <= {nx, ny, nl, nm, nr} != {xpos, ypos, left, middle, right};
    {xpos, ypos, left, middle, right} <= {nx, ny, nl, nm, nr};
  end
endmodule
