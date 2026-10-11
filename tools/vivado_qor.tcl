# Isolated project measurement. Invoke through vivado_qor.py to pin input hashes.
if {$argc != 2} { error "usage: vivado_qor.tcl ROOT RUN_DIR" }
set root [file normalize [lindex $argv 0]]
set out [file normalize [lindex $argv 1]]
source [file join $out manifest.tcl]
cd $out
set_param general.maxThreads 4
create_project qor [file join $out project] -part xc7a35tcpg236-1 -force
set_property target_language Verilog [current_project]
foreach path $qor_sources {
    if {[file extension $path] eq ".vhd"} { read_vhdl $path } elseif {[file extension $path] eq ".mem"} { add_files $path } else { read_verilog -sv $path }
}
foreach path $qor_ips { read_ip $path }
read_xdc [file join $root src/constraint/basys3.xdc]
set_property top GlobalRender_top [get_filesets sources_1]
update_compile_order -fileset sources_1
report_compile_order -used_in synthesis -file [file join $out compile_order.rpt]
if {[llength [get_ips -quiet]]} {
    report_ip_status -file [file join $out ip_status.rpt]
} else {
    set ipfile [open [file join $out ip_status.rpt] w]
    puts $ipfile "No reachable IP; see manifest.json reachability audit."
    close $ipfile
}
# No implicit IP upgrade, timing exception, or replacement primitive.
if {[llength [get_ips -quiet]]} {
    foreach ip [get_ips] {
        if {[get_property IS_LOCKED $ip]} { error "Locked reachable IP: $ip; explicit upgrade qualification required" }
    }
    generate_target all [get_ips]
    create_ip_run [get_ips]
    set ip_runs [get_runs -quiet *_synth_1]
    if {[llength $ip_runs]} {
        launch_runs $ip_runs -jobs 4
        foreach run $ip_runs {
            wait_on_run $run
            if {[get_property PROGRESS $run] ne "100%"} { error "IP synthesis failed: $run" }
        }
    }
}
set settings [open [file join $out settings.txt] w]
puts $settings "tool=[version]"
puts $settings "part=xc7a35tcpg236-1"
puts $settings "top=GlobalRender_top"
puts $settings "synthesis=synth_design defaults; flatten_hierarchy rebuilt"
puts $settings "implementation=opt_design; place_design; phys_opt_design; route_design defaults"
puts $settings "threads=4; seed=not exposed/set by this flow"
close $settings
proc snapshot {stage out} {
    write_checkpoint -force [file join $out ${stage}.dcp]
    report_utilization -file [file join $out ${stage}_utilization.rpt]
    report_utilization -hierarchical -file [file join $out ${stage}_hierarchical.rpt]
    report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file [file join $out ${stage}_timing.rpt]
    report_timing -max_paths 10 -path_type full_clock_expanded -file [file join $out ${stage}_paths.rpt]
    report_clocks -file [file join $out ${stage}_clocks.rpt]
    check_timing -verbose -file [file join $out ${stage}_check_timing.rpt]
    report_cdc -details -file [file join $out ${stage}_cdc.rpt]
    report_drc -file [file join $out ${stage}_drc.rpt]
    set clockfile [open [file join $out ${stage}_clock_periods.tsv] w]
    foreach clk [get_clocks] { puts $clockfile "[get_property NAME $clk]\t[get_property PERIOD $clk]\t[get_property IS_GENERATED $clk]" }
    close $clockfile
}
synth_design -top GlobalRender_top -part xc7a35tcpg236-1 -flatten_hierarchy rebuilt
set black_boxes [get_cells -hierarchical -quiet -filter {IS_BLACKBOX == 1}]
set bbfile [open [file join $out black_boxes.rpt] w]
puts $bbfile "black_box_count=[llength $black_boxes]"
puts $bbfile $black_boxes
close $bbfile
if {[llength $black_boxes]} { error "Unresolved synthesis black boxes: $black_boxes" }
snapshot synth $out
set stamp [open [file join $out synth.complete] w]; puts $stamp complete; close $stamp
if {$qor_stage eq "synth"} { exit }
opt_design
place_design
phys_opt_design
route_design
snapshot routed $out
report_route_status -file [file join $out routed_route_status.rpt]
set stamp [open [file join $out routed.complete] w]; puts $stamp complete; close $stamp
