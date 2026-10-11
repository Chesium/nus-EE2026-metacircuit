// SystemVerilog port of metacircuit's MouseDisplay.vhd (Verilator reads no VHDL).
// Same 28x28 hand cursor sprites and the same one-cycle pipeline as the VHDL.
module MouseDisplay (
    input  wire        pixel_clk,
    input  wire [11:0] xpos,
    input  wire [11:0] ypos,
    input  wire        mouse_left,
    input  wire [11:0] hcount,
    input  wire [11:0] vcount,
    output wire        enable_mouse_display_out,
    output reg  [3:0]  red_out,
    output reg  [3:0]  green_out,
    output reg  [3:0]  blue_out
);
  localparam logic [11:0] CursorSize = 12'd28;

  function automatic logic [27:0] hover_row(input logic [4:0] row);
    case (row)
      5'd2: hover_row = 28'b0000110000000000000000000000;
      5'd3: hover_row = 28'b0011111000000000000000000000;
      5'd4: hover_row = 28'b0011001100000000001000000000;
      5'd5: hover_row = 28'b0011001100110111111110000000;
      5'd6: hover_row = 28'b0001000111111111110110000000;
      5'd7: hover_row = 28'b0001100111001100110011000000;
      5'd8: hover_row = 28'b0000110011001100110001000000;
      5'd9: hover_row = 28'b0000110011000110011001100000;
      5'd10: hover_row = 28'b0000011001100110011000110000;
      5'd11: hover_row = 28'b0000011000100011001000110000;
      5'd12: hover_row = 28'b0000001100110000000000011000;
      5'd13: hover_row = 28'b0000000100010000000000011000;
      5'd14: hover_row = 28'b0000000110000000000000001100;
      5'd15: hover_row = 28'b0000111110000000000000001100;
      5'd16: hover_row = 28'b0001111111000000000000001100;
      5'd17: hover_row = 28'b0011000011100000000000001100;
      5'd18: hover_row = 28'b0001100001000000000000001100;
      5'd19: hover_row = 28'b0000111000000000000000011000;
      5'd20: hover_row = 28'b0000011100000000000000111000;
      5'd21: hover_row = 28'b0000000110000000000001110000;
      5'd22: hover_row = 28'b0000000011100000000111000000;
      5'd23: hover_row = 28'b0000000001110000011110000000;
      5'd24: hover_row = 28'b0000000000011111111000000000;
      5'd25: hover_row = 28'b0000000000000111100000000000;
      default: hover_row = 28'b0;
    endcase
  endfunction

  function automatic logic [27:0] pressed_row(input logic [4:0] row);
    case (row)
      5'd3: pressed_row = 28'b0000000001100110111100000000;
      5'd4: pressed_row = 28'b0000000111111111110110000000;
      5'd5: pressed_row = 28'b0000011111001100110011000000;
      5'd6: pressed_row = 28'b0000110011001100110001000000;
      5'd7: pressed_row = 28'b0000110011000110011001100000;
      5'd8: pressed_row = 28'b0000011001100110011000110000;
      5'd9: pressed_row = 28'b0000011000100011001000110000;
      5'd10: pressed_row = 28'b0000001100110000000000011000;
      5'd11: pressed_row = 28'b0000111100010000000000011000;
      5'd12: pressed_row = 28'b0001101110000000000000001100;
      5'd13: pressed_row = 28'b0011001110000000000000001100;
      5'd14: pressed_row = 28'b0011001111000000000000001100;
      5'd15: pressed_row = 28'b0011000001100000000000001100;
      5'd16: pressed_row = 28'b0001100000100000000000001100;
      5'd17: pressed_row = 28'b0000111000000000000000011000;
      5'd18: pressed_row = 28'b0000011100000000000000111000;
      5'd19: pressed_row = 28'b0000000110000000000001110000;
      5'd20: pressed_row = 28'b0000000011100000000111000000;
      5'd21: pressed_row = 28'b0000000001110000011110000000;
      5'd22: pressed_row = 28'b0000000000011111111000000000;
      5'd23: pressed_row = 28'b0000000000000111100000000000;
      default: pressed_row = 28'b0;
    endcase
  endfunction

  function automatic logic [27:0] pressed_fill_row(input logic [4:0] row);
    case (row)
      5'd4: pressed_fill_row = 28'b0000000000000000001000000000;
      5'd5: pressed_fill_row = 28'b0000000000110011001100000000;
      5'd6: pressed_fill_row = 28'b0000001100110011001110000000;
      5'd7: pressed_fill_row = 28'b0000001100111001100110000000;
      5'd8: pressed_fill_row = 28'b0000000110011001100111000000;
      5'd9: pressed_fill_row = 28'b0000000111011100110111000000;
      5'd10: pressed_fill_row = 28'b0000000011001111111111100000;
      5'd11: pressed_fill_row = 28'b0000000011101111111111100000;
      5'd12: pressed_fill_row = 28'b0000010001111111111111110000;
      5'd13: pressed_fill_row = 28'b0000110001111111111111110000;
      5'd14: pressed_fill_row = 28'b0000110000111111111111110000;
      5'd15: pressed_fill_row = 28'b0000111110011111111111110000;
      5'd16: pressed_fill_row = 28'b0000011111011111111111110000;
      5'd17: pressed_fill_row = 28'b0000000111111111111111100000;
      5'd18: pressed_fill_row = 28'b0000000011111111111111000000;
      5'd19: pressed_fill_row = 28'b0000000001111111111100000000;
      5'd20: pressed_fill_row = 28'b0000000000011111111000000000;
      5'd21: pressed_fill_row = 28'b0000000000001111100000000000;
      default: pressed_fill_row = 28'b0;
    endcase
  endfunction

  function automatic logic [27:0] fill_row(input logic [4:0] row);
    case (row)
      5'd4: fill_row = 28'b0000110000000000000000000000;
      5'd5: fill_row = 28'b0000110000000000000000000000;
      5'd6: fill_row = 28'b0000111000000000001000000000;
      5'd7: fill_row = 28'b0000011000110011001100000000;
      5'd8: fill_row = 28'b0000001100110011001110000000;
      5'd9: fill_row = 28'b0000001100111001100110000000;
      5'd10: fill_row = 28'b0000000110011001100111000000;
      5'd11: fill_row = 28'b0000000111011100110111000000;
      5'd12: fill_row = 28'b0000000011001111111111100000;
      5'd13: fill_row = 28'b0000000011101111111111100000;
      5'd14: fill_row = 28'b0000000001111111111111110000;
      5'd15: fill_row = 28'b0000000001111111111111110000;
      5'd16: fill_row = 28'b0000000000111111111111110000;
      5'd17: fill_row = 28'b0000111100011111111111110000;
      5'd18: fill_row = 28'b0000011110111111111111110000;
      5'd19: fill_row = 28'b0000000111111111111111100000;
      5'd20: fill_row = 28'b0000000011111111111111000000;
      5'd21: fill_row = 28'b0000000001111111111110000000;
      5'd22: fill_row = 28'b0000000000011111111000000000;
      5'd23: fill_row = 28'b0000000000001111100000000000;
      default: fill_row = 28'b0;
    endcase
  endfunction
  wire [11:0] xdiff = hcount - xpos;
  wire [11:0] ydiff = vcount - ypos;
  wire [4:0] x_idx = xdiff[4:0];
  wire [4:0] y_idx = ydiff[4:0];

  reg [1:0] mousepixel = 2'b00;
  reg enable_mouse_display = 1'b0;

  always @(posedge pixel_clk) begin
    logic [27:0] row_bits, fill_bits, pressed_fill_bits;
    if (x_idx < 5'd28 && y_idx < 5'd28) begin
      row_bits = mouse_left ? pressed_row(y_idx) : hover_row(y_idx);
      fill_bits = fill_row(y_idx);
      pressed_fill_bits = pressed_fill_row(y_idx);
      if (row_bits[5'd27 - x_idx]) mousepixel <= 2'b00;
      else if (fill_bits[5'd27 - x_idx] || (mouse_left && pressed_fill_bits[5'd27 - x_idx])) mousepixel <= 2'b01;
      else mousepixel <= 2'b11;
    end else begin
      mousepixel <= 2'b11;
    end
  end

  always @(posedge pixel_clk) begin
    enable_mouse_display <= hcount >= xpos && hcount < xpos + CursorSize &&
                            vcount >= ypos && vcount < ypos + CursorSize &&
                            (mousepixel == 2'b00 || mousepixel == 2'b01);
  end

  assign enable_mouse_display_out = enable_mouse_display;

  always @(posedge pixel_clk) begin
    if (enable_mouse_display) begin
      if (mousepixel == 2'b01) {red_out, green_out, blue_out} <= 12'hFFF;
      else if (mousepixel == 2'b00) {red_out, green_out, blue_out} <= 12'h000;
    end
  end
endmodule
