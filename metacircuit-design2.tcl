set origin_dir "."
if { [info exists ::origin_dir_loc] } {
  set origin_dir $::origin_dir_loc
}

set project_name "metacircuit"
if { [info exists ::user_project_name] } {
  set project_name $::user_project_name
}

proc design2_print_help {} {
  set script_name [file tail [info script]]
  puts "\nDescription:"
  puts "Creates the design2 MetaCircuit Vivado project."
  puts "\nUsage:"
  puts "$script_name"
  puts "$script_name -tclargs --origin_dir <path> --project_name <name>"
  puts "$script_name -tclargs --help\n"
  exit 0
}

if { $::argc > 0 } {
  for {set i 0} {$i < $::argc} {incr i} {
    set option [string trim [lindex $::argv $i]]
    switch -regexp -- $option {
      "--origin_dir"   { incr i; set origin_dir [lindex $::argv $i] }
      "--project_name" { incr i; set project_name [lindex $::argv $i] }
      "--help"         { design2_print_help }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option'"
          return 1
        }
      }
    }
  }
}

create_project ${project_name} ./${project_name} -part xc7a35tcpg236-1 -force

set obj [current_project]
set_property default_lib xil_defaultlib $obj
set_property enable_vhdl_2008 1 $obj
set_property simulator_language Mixed $obj

if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}
set src_obj [get_filesets sources_1]
set src_files [list \
  [file normalize "${origin_dir}/src/design2/common/CellStorePkg.sv"] \
  [file normalize "${origin_dir}/src/design2/common/ComponentStorePkg.sv"] \
  [file normalize "${origin_dir}/src/design2/common/MetaCommandPkg.sv"] \
  [file normalize "${origin_dir}/src/design2/ui/common/UiThemePkg.sv"] \
  [file normalize "${origin_dir}/src/design2/ui/common/UiTextPkg.sv"] \
  [file normalize "${origin_dir}/src/design2/ui/toolbar/ToolbarPkg.sv"] \
  [file normalize "${origin_dir}/src/design2/common/ClockDivider.v"] \
  [file normalize "${origin_dir}/src/design2/store/CellStoreBufferRam.sv"] \
  [file normalize "${origin_dir}/src/design2/store/ComponentStoreRam.sv"] \
  [file normalize "${origin_dir}/src/design2/driver/VGAControl.v"] \
  [file normalize "${origin_dir}/src/design2/driver/Ps2Interface.vhd"] \
  [file normalize "${origin_dir}/src/design2/driver/Mouse_Control.vhd"] \
  [file normalize "${origin_dir}/src/design2/rendering/CircuitCanvas.v"] \
  [file normalize "${origin_dir}/src/design2/rendering/MouseDisplay.vhd"] \
  [file normalize "${origin_dir}/src/design2/ui/ComponentPropertyPanel.sv"] \
  [file normalize "${origin_dir}/src/design2/ui/toolbar/ToolbarStateController.sv"] \
  [file normalize "${origin_dir}/src/design2/ui/toolbar/ToolbarRenderer.sv"] \
  [file normalize "${origin_dir}/src/design2/ui/toolbar/CurrentToolLabel.sv"] \
  [file normalize "${origin_dir}/src/design2/ui/text/FontROM.v"] \
  [file normalize "${origin_dir}/src/design2/ui/text/UiTextLineRenderer.sv"] \
  [file normalize "${origin_dir}/src/design2/ui/text/TextDisplay.sv"] \
  [file normalize "${origin_dir}/src/design2/ui/text/TextBox.sv"] \
  [file normalize "${origin_dir}/src/design2/ui/text/DynamicTextBox.sv"] \
  [file normalize "${origin_dir}/src/design2/ui/text/DynamicTextDisplay.sv"] \
  [file normalize "${origin_dir}/src/design2/interaction/InteractionFrameCapture.v"] \
  [file normalize "${origin_dir}/src/design2/interaction/CommandArbiter.sv"] \
  [file normalize "${origin_dir}/src/design2/interaction/CommandExecutor.sv"] \
  [file normalize "${origin_dir}/src/design2/interaction/InteractionCommandController.sv"] \
  [file normalize "${origin_dir}/src/design2/projector/ComponentProjector.sv"] \
  [file normalize "${origin_dir}/src/design2/backend/CanonicalCellPortAdapter.sv"] \
  [file normalize "${origin_dir}/src/design2/backend/CanonicalStampingNetlistStore.sv"] \
  [file normalize "${origin_dir}/src/design2/backend/VisualizationPostProcessor.sv"] \
  [file normalize "${origin_dir}/src/design2/top/MetaCircuit_top.sv"] \
]
add_files -norecurse -fileset $src_obj $src_files
update_compile_order -fileset sources_1
set_property top MetaCircuit_top $src_obj

if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}
set constr_obj [get_filesets constrs_1]
add_files -norecurse -fileset $constr_obj [file normalize "${origin_dir}/src/constraint/basys3.xdc"]

set synth_run [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.TCL.POST [file normalize "${origin_dir}/src/constraint/design2_generated_clocks.tcl"] $synth_run

set impl_run [get_runs impl_1]
set_property STEPS.OPT_DESIGN.TCL.PRE [file normalize "${origin_dir}/src/constraint/design2_generated_clocks.tcl"] $impl_run

if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}
set sim_obj [get_filesets sim_1]
set sim_files [list \
  [file normalize "${origin_dir}/src/testbench/Design2_CommandExecutor_test.sv"] \
  [file normalize "${origin_dir}/src/testbench/Design2_ComponentProjector_test.sv"] \
  [file normalize "${origin_dir}/src/testbench/Design2_TextRender_test.sv"] \
  [file normalize "${origin_dir}/src/testbench/Design2_TextPrimitiveSmoke_test.sv"] \
  [file normalize "${origin_dir}/src/testbench/Design2_Toolbar_test.sv"] \
  [file normalize "${origin_dir}/src/testbench/Design2_ToolbarIntegration_test.sv"] \
  [file normalize "${origin_dir}/src/testbench/Design2_CurrentToolLabel_test.sv"] \
  [file normalize "${origin_dir}/src/testbench/Design2_TopInteractionDebug_test.sv"] \
]
add_files -norecurse -fileset $sim_obj $sim_files
update_compile_order -fileset sim_1
set_property top Design2_CommandExecutor_test $sim_obj

puts "Configured ${project_name} for src/design2/top/MetaCircuit_top.sv"
