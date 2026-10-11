"""Generates the framescope_top wrapper (SystemVerilog) and fs_bind() (C++).

The wrapper re-exposes every port of the design under its own name, so tap
expressions can use port names, slices, concatenations and dut.* paths, and
adds one output per monitor tap and two per probe (value, width). Memories to
dump are walked by an exported DPI function, fs_dump_memory(id). The C++
registers clocks, inputs, outputs, virtual inputs, monitors, probes and dumps
on the harness.
"""

from __future__ import annotations

from . import FramescopeError, protocols
from .manifest import IDENT, Manifest
from .ports import Port
from .protocols.base import cpp_str

WRAPPER_TOP = "framescope_top"
_CPP_RESERVED = {
    "and", "asm", "auto", "bool", "break", "case", "catch", "char", "class", "const", "continue",
    "default", "delete", "do", "double", "else", "enum", "explicit", "export", "extern", "false",
    "float", "for", "friend", "goto", "if", "inline", "int", "long", "mutable", "namespace", "new",
    "not", "operator", "or", "private", "protected", "public", "register", "return", "short",
    "signed", "sizeof", "static", "struct", "switch", "template", "this", "throw", "true", "try",
    "typedef", "union", "unsigned", "using", "virtual", "void", "volatile", "while", "xor",
}

_EXPAND8 = """\
    // Scales an n-bit colour channel to 8 bits by bit replication.
    function automatic [7:0] fs_expand8(input [63:0] v, input integer n);
        integer i;
        begin
            fs_expand8 = 8'd0;
            if (n >= 8) fs_expand8 = 8'(v >> (n - 8));
            else for (i = 0; i < 8; i = i + 1) fs_expand8[7 - i] = v[n - 1 - (i % n)];
        end
    endfunction
"""


def tap_port(monitor: str, signal: str) -> str:
    return f"fs_{monitor}_{signal}"


def probe_port(name: str) -> str:
    return f"fs_probe_{name}"


def _dump_function(m: Manifest) -> list[str]:
    """fs_dump_memory(id): pushes every word of dump #id through framescope_dpi."""
    out = [
        "    // Walks one [[dump]] memory for the harness (called via DPI between evals).",
        '    export "DPI-C" function fs_dump_memory;',
        "    function automatic void fs_dump_memory(input int mem);",
        "        case (mem)",
    ]
    for i, d in enumerate(m.dumps):
        first = f"{d.path}[$low({d.path})]"
        out += [
            f"            {i}: begin  // {d.name}",
            f"                framescope_dpi::fs_dump_begin({i}, $bits({first}), $size({d.path}));",
            f"                for (int k = 0; k < $size({d.path}); k++)",
            f"                    for (int c = 0; c < ($bits({first}) + 63) / 64; c++)",
            f"                        framescope_dpi::fs_dump_word({i}, k, c, 64'({d.path}[$low({d.path}) + k] >> (64 * c)));",
            "            end",
        ]
    out += ["            default: ;", "        endcase", "    endfunction", ""]
    return out


def validate(m: Manifest, ports: list[Port]) -> None:
    """Cross-checks the manifest against the design's real ports."""
    by_name = {p.name: p for p in ports}
    for p in ports:
        if not IDENT.match(p.name) or p.name in _CPP_RESERVED or p.name.startswith("fs_"):
            raise FramescopeError(f"port name '{p.name}' is not supported (escaped, C++ keyword, or fs_ prefix)")

    def need(name: str, direction: str, what: str) -> Port:
        p = by_name.get(name)
        if p is None:
            raise FramescopeError(f"{what}: '{name}' is not a port of {m.top}; ports: {sorted(by_name)}")
        if p.direction != direction:
            raise FramescopeError(f"{what}: '{name}' is an {p.direction}, expected {direction}")
        return p

    clock_names = set()
    for c in m.clocks:
        if need(c.name, "input", "clocks").width != 1:
            raise FramescopeError(f"clocks: '{c.name}' must be 1 bit wide")
        clock_names.add(c.name)
    for name in m.inputs:
        if name in clock_names:
            raise FramescopeError(f"inputs: '{name}' is a clock; set it under [clocks] only")
        if need(name, "input", "inputs").width > 64:
            raise FramescopeError(f"inputs: '{name}' is wider than 64 bits")
    if m.reset:
        if need(m.reset.port, "input", "reset").width != 1:
            raise FramescopeError(f"reset: '{m.reset.port}' must be 1 bit wide")
        if m.reset.port in clock_names:
            raise FramescopeError(f"reset: '{m.reset.port}' is a clock")
    for name, mode in m.inouts.items():
        if need(name, "inout", "inouts").width != 1 and mode != "none":
            raise FramescopeError(f"inouts: pulls are only supported on 1-bit ports ('{name}')")
    for mon in m.monitors:
        proto = protocols.get(mon.protocol)
        proto.validate(mon)
        proto.check_ports(mon, by_name, clock_names)


def wrapper_sv(m: Manifest, ports: list[Port]) -> str:
    decls = [f"    {p.direction:<6} wire {p.sv_range:<8} {p.name}" for p in ports if p.direction != "inout"]
    assigns = []
    for mon in m.monitors:
        for tap in protocols.get(mon.protocol).taps(mon):
            name = tap_port(mon.name, tap.signal)
            rng = f"[{tap.width - 1}:0]" if tap.width > 1 else ""
            decls.append(f"    output wire {rng:<8} {name}")
            assigns.append(f"    assign {name} = {tap.expr};")
    for probe in m.probes:
        name = probe_port(probe.name)
        decls.append(f"    output wire {'[63:0]':<8} {name}")
        decls.append(f"    output wire {'[31:0]':<8} {name}_bits")
        assigns.append(f"    assign {name} = 64'($unsigned({probe.expr}));")
        assigns.append(f"    assign {name}_bits = 32'($bits({probe.expr}));")

    out = [
        f"// Generated by framescope from {m.path.name}; do not edit.",
        "`timescale 1ns / 1ps",
        "",
        f"module {WRAPPER_TOP} (",
        ",\n".join(decls),
        ");",
    ]
    inouts = [p for p in ports if p.direction == "inout"]
    for p in inouts:
        out.append(f"    wire {p.sv_range} {p.name};")
        mode = m.inouts.get(p.name, "none")
        if mode != "none":
            out.append(f"    {mode} ({p.name});")
    if inouts:
        out.append("")
    params = ", ".join(f".{k}({v})" for k, v in m.parameters.items())
    out.append(f"    {m.top} {'#(' + params + ') ' if params else ''}dut (")
    out.append(",\n".join(f"        .{p.name}({p.name})" for p in ports))
    out += ["    );", "", _EXPAND8]
    if m.dumps:
        out += _dump_function(m)
    out += assigns
    out += ["endmodule", ""]
    return "\n".join(out)


def bindings_cpp(m: Manifest, ports: list[Port]) -> str:
    clock_names = {c.name for c in m.clocks}
    initial = dict(m.inputs)
    if m.reset and m.reset.port not in initial:
        initial[m.reset.port] = m.reset.active
    headers = sorted({protocols.get(mon.protocol).cpp_header for mon in m.monitors})

    out = ["// Generated by framescope; do not edit.", "#include <memory>", "", '#include "Vframescope_top.h"', '#include "framescope.hpp"']
    if m.dumps:
        out += ['#include "Vframescope_top__Dpi.h"', '#include "svdpi.h"']
    out += [f'#include "{h}"' for h in headers]
    out += ["", "void fs_bind(fs::Harness& h, Vframescope_top& top) {"]
    for c in m.clocks:
        out.append(f"  h.add_clock({cpp_str(c.name)}, fs::port(top.{c.name}, 1), {c.period_ps}ULL, {c.offset_ps}ULL);")
    for p in ports:
        if p.width > 64 or p.direction == "inout" or p.name in clock_names:
            continue
        if p.direction == "input":
            value = initial.get(p.name, 0) & ((1 << p.width) - 1)
            out.append(f"  h.add_input({cpp_str(p.name)}, fs::port(top.{p.name}, {p.width}), {value}ULL);")
        else:
            out.append(f"  h.add_output({cpp_str(p.name)}, fs::port(top.{p.name}, {p.width}));")
    for name, value in m.virtual_inputs.items():
        out.append(f"  h.add_virtual_input({cpp_str(name)}, {value}LL);")
    for mon in m.monitors:
        proto = protocols.get(mon.protocol)
        out.append(proto.cpp_bind(mon, lambda sig, mon=mon: f"top.{tap_port(mon.name, sig)}"))
    for probe in m.probes:
        port = f"top.{probe_port(probe.name)}"
        out.append(f"  h.add_probe({cpp_str(probe.name)}, fs::port({port}, 64), fs::port({port}_bits, 32));")
    if m.dumps:
        for i, d in enumerate(m.dumps):
            out.append(f"  h.add_dump({cpp_str(d.name)}, {i});")
        out += [
            "  h.set_dumper([](int id) {",
            f"    static const svScope scope = svGetScopeFromName({cpp_str('TOP.' + WRAPPER_TOP)});",
            "    svSetScope(scope);",
            "    fs_dump_memory(id);",
            "  });",
        ]
    out += ["}", ""]
    return "\n".join(out)
