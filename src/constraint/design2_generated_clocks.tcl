set pixel_clk_pin [get_pins -quiet -hierarchical *clkdiv_pixel_inst/clk_pixel]
if {[llength $pixel_clk_pin] == 0} {
  set pixel_clk_pin [get_pins -quiet -hierarchical *clkdiv_pixel_inst/clk_out]
}

if {[llength $pixel_clk_pin] > 0} {
  create_generated_clock -name clk_pixel -source [get_ports CLK100MHZ] -divide_by 4 $pixel_clk_pin
} else {
  puts "INFO: design2_generated_clocks.tcl did not find clkdiv_pixel_inst output; skipping clk_pixel generated clock."
}
