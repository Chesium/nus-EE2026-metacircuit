read_verilog -sv src/design/common/SimpleRam.v
read_verilog -sv src/design/common/StampingCombPkg.sv
read_verilog -sv src/design/common/StampingNetlistStore.sv
read_verilog -sv src/design/matrix/SolverMatrixStore.sv
read_verilog -sv src/design/matrix/SolverVectorStore.sv
read_verilog -sv src/design/solver/solve_core_dc.sv
read_verilog -sv src/design/solver_board/UartRx.v
read_verilog -sv src/design/solver_board/UartLineAssembler.sv
read_verilog -sv src/design/solver_board/UartPacketParser.sv
read_verilog -sv src/design/solver_board/BcdUnitToFp32Rom.sv
read_verilog -sv src/design/solver_board/SolverUartLineTransmitter.sv
read_verilog -sv src/design/solver_board/SolverDcPipeline.sv
read_verilog -sv src/design/solver_board/SolverBoard_top.sv
read_verilog -sv src/design/uart/UartTx.v
read_verilog -sv src/design/uart/Hex7SegMux.v
read_verilog -sv src/design/floating_point/fpo_div.v
read_verilog -sv src/design/floating_point/fpo_fma.v
read_ip src/ip/floating_point_div/floating_point_div.xci
read_ip src/ip/floating_point_fma/floating_point_fma.xci
read_xdc src/constraint/basys3_solver_board.xdc
synth_design -top SolverBoard_top -part xc7a35tcpg236-1
report_utilization -file solver_board_util_synth.rpt
report_timing_summary -file solver_board_timing_synth.rpt
