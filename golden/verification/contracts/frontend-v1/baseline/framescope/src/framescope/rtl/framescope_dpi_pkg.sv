// Lets sim-only stub modules read values driven by framescope stimulus.
//
//   import framescope_dpi::*;
//   int h_x;
//   initial h_x = fs_input_handle("mouse.x");
//   always @(posedge clk) xpos <= 12'(fs_input_get(h_x));
//
// Declare each name under [virtual_inputs] in framescope.toml.
//
// fs_dump_begin/fs_dump_word are used by the generated wrapper's
// fs_dump_memory() to pass [[dump]] memories to the harness, one word in
// 64-bit chunks (least significant first) at a time.
package framescope_dpi;
  import "DPI-C" function int fs_input_handle(input string name);
  import "DPI-C" function longint fs_input_get(input int handle);
  import "DPI-C" function void fs_dump_begin(input int mem, input int width, input int depth);
  import "DPI-C" function void fs_dump_word(input int mem, input int index, input int chunk, input longint value);
endpackage
