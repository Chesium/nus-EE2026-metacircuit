# MetaCircuit - EE2026 Project

NUS EE2026 AY2025-2026 Sem 2 Session 1 (Mon AM) Group 9

A Circuit Simulator built inside an Basys 3 FPGA Board.

## Development

1. Make sure that you have add your Vivado Bin Path to the environment variable `Path` (e.g. `...\Xilinx\Vivado\2018.2\bin`)
2. Open a terminal window in the repo folder, then run `vivado -mode batch -source metacircuit.tcl`
3. Open the generated Vivado project `metacircuit\metacircuit.xpr`

## IDE Tools

- Use VS Code as the main text editor of Vivado : `".../Code.exe" -g [file name]:[line number]`
- VS Code Extension : [`mshr-h.veriloghdl`](https://marketplace.visualstudio.com/items?itemName=mshr-h.VerilogHDL)
  - Ctags: Install [universal-ctags](https://github.com/universal-ctags/ctags)
  - Formatter & Linter & Language Server: Install [verible](https://github.com/chipsalliance/verible)
    - set `verilog.linting.linter` to `verible-verilog-lint`
      - set `verilog.linting.veribleVerilogLint.arguments` to `--rules_config_search`
    - set `verilog.formatting.verilogHDL.formatter` to `verible-verilog-format`
    - enable `verilog.languageServer.veribleVerilogLs.enabled`
      - set `verilog.languageServer.veribleVerilogLs.arguments` to `--rules_config_search`