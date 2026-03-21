module CanvasInteraction (
  input wire clk,
  input wire vsync,

  input wire [7:0] mouse_i,
  input wire [7:0] mouse_j,
  input wire mouse_left,
  
  /* Render Stage Data RAM Handles (Read-Only) */
  output wire [AddrWidth-1:0] data_addr,
  input  wire [DataWidth-1:0] incoming_data
);

  /* 
    takes in which cell the mouse is and whether it's pressed
    and run the FSM to set per-frame command for the CommandEngine
    only be enabled when the mouse is in the canvas area
    otherwise it will just pass through the overide command
  */  

endmodule
