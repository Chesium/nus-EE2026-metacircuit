#!/usr/bin/env python3
"""Exact-source BCD rank rewrite plus arbitrary-input Yosys SAT cone equivalence."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

SOURCE = "src/design/rendering/GlobalRender_top.v"
BASELINE_SHA = "93bc76d3019d3d1e5a8949a00e32d217d934b4ece5289ec26e1421b7a2a001fb"
START = "                for (edit_text_idx = 0; edit_text_idx < 8; edit_text_idx = edit_text_idx + 1) begin"
END = "            end\n        end\n    end\n\n    // The VGA keypad"
ANCHOR = "    integer edit_text_idx;"


def sha(text):
    return hashlib.sha256(text.encode()).hexdigest()


def balanced(items):
    if not items:
        return "4'd0"
    if len(items) == 1:
        return items[0]
    middle = len(items) // 2
    return "(" + balanced(items[:middle]) + " + " + balanced(items[middle:]) + ")"


def function():
    lines = ["    // Exact arbitrary-text BCD scan: parallel prefix ranks replace serial insertion.",
             "    function [13:0] bcd_scan_rank8;", "        input [63:0] text_value;",
             "        input [3:0] text_len;", "        input is_resistor;",
             "        reg [7:0] digit_mask;", "        reg [3:0] rank [0:8];",
             "        reg [3:0] first_digit, second_digit, third_digit;", "        begin"]
    for i in range(8):
        byte = f"text_value[{63-i*8}:{56-i*8}]"
        lines.append(f'            digit_mask[{i}] = (text_len > 4\'d{i}) && ({byte} >= "0") && ({byte} <= "9");')
    for i in range(9):
        expr = balanced(["{3'd0, digit_mask[%d]}" % j for j in range(i)])
        lines.append(f"            rank[{i}] = {expr};")
    for digit,rank in [('first_digit',0), ('second_digit',1), ('third_digit',2)]:
        terms = [f"((digit_mask[{i}] && (rank[{i}] == 4'd{rank})) ? text_value[{59-i*8}:{56-i*8}] : 4'd0)" for i in range(8)]
        lines.append(f"            {digit} = " + " |\n                ".join(terms) + ";")
    lines += ["            if (is_resistor)",
              "                bcd_scan_rank8 = {(rank[8] >= 4'd3 ? 2'd3 : rank[8][1:0]), first_digit, second_digit, third_digit};",
              "            else", "                bcd_scan_rank8 = {(rank[8] >= 4'd2 ? 2'd2 : rank[8][1:0]), 4'd0, first_digit, second_digit};",
              "        end", "    endfunction", ""]
    return "\n".join(lines) + "\n"


def transform(source):
    if sha(source) != BASELINE_SHA:
        raise ValueError("baseline is not the pinned reviewed shadow candidate")
    if source.count(START) != 1 or source.count(END) != 1 or source.count(ANCHOR) != 1:
        raise ValueError("scan boundary changed")
    start, end = source.index(START), source.index(END)
    candidate = source[:start] + "                {edit_value_next_digits, edit_value_next_bcd} = bcd_scan_rank8(edit_value_next_text, edit_value_next_text_len, selected_is_resistor);\n" + source[end:]
    return candidate.replace(ANCHOR, function() + ANCHOR, 1)


def extract_function(source, name):
    matches = re.findall(r"    function[^\n]*\b" + re.escape(name) + r";.*?    endfunction", source, re.S)
    if len(matches) != 1:
        raise ValueError("missing/ambiguous projected function " + name)
    return matches[0]


def projected_module(source, name):
    declarations = """input selected_is_editable, value_edit_active_sys, selected_is_resistor,
    input keyboard_ascii_is_value_char, keyboard_ascii_is_digit,
    input [7:0] keyboard_ascii_sys_ff1, input [3:0] keyboard_ascii_digit,
    input [11:0] selected_value_bcd, input [1:0] selected_value_digits,
    input [63:0] selected_value_text, input [3:0] selected_value_text_len,
    output reg [11:0] edit_value_next_bcd, output reg [1:0] edit_value_next_digits,
    output reg [63:0] edit_value_next_text, output reg [3:0] edit_value_next_text_len,
    output reg edit_value_valid"""
    helper_names = ['text_char_at8', 'text_append8', 'text_delete8', 'bcd_insert_ltr3', 'bcd_insert_ltr2']
    if "function [13:0] bcd_scan_rank8;" in source:
        helper_names.append('bcd_scan_rank8')
    body_start = source.index(ANCHOR)
    body_end = source.index("    // The VGA keypad", body_start)
    return "module " + name + "(" + declarations + ");\n" + "\n".join(extract_function(source, f) for f in helper_names) + "\n" + source[body_start:body_end] + "endmodule\n"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--baseline-root', type=Path, required=True)
    parser.add_argument('--candidate-root', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--yosys', required=True)
    parser.add_argument('--generate', action='store_true')
    parser.add_argument('--negative-control', action='store_true')
    args = parser.parse_args()
    out = args.out.resolve()
    if out.exists() and any(out.iterdir()):
        raise ValueError('proof directory must be empty')
    out.mkdir(parents=True, exist_ok=True)
    baseline = (args.baseline_root / SOURCE).read_text()
    expected = transform(baseline)
    target = args.candidate_root / SOURCE
    if args.generate:
        target.write_text(expected)
    candidate = target.read_text()
    if candidate != expected:
        raise ValueError('candidate is not the exact canonical rewrite')
    projected_candidate = candidate
    if args.negative_control:
        before = "first_digit, second_digit, third_digit};"
        if projected_candidate.count(before) != 1:
            raise ValueError('negative control target changed')
        projected_candidate = projected_candidate.replace(before, "first_digit, second_digit, (third_digit ^ 4'd1)};", 1)
    miter = out / 'projected.v'
    miter.write_text(projected_module(baseline, 'reference') + projected_module(projected_candidate, 'candidate'))
    script = out / 'proof.ys'
    script.write_text('read_verilog -sv "' + str(miter) + '"\nproc\nopt\nmiter -equiv -flatten reference candidate miter\nhierarchy -top miter\nflatten\nopt\nsat -verify -prove trigger 0 -show-inputs -show-outputs\n')
    with (out / 'yosys.log').open('w') as stream:
        result = subprocess.run([args.yosys, '-s', str(script)], stdout=stream, stderr=subprocess.STDOUT, timeout=120)
    log = (out / 'yosys.log').read_text()
    equivalent = result.returncode == 0 and 'SAT proof finished - no model found: SUCCESS!' in log
    detected = result.returncode != 0 and 'proof did fail' in log
    accepted = detected if args.negative_control else equivalent
    report = {'schema': 1, 'accepted': accepted, 'equivalent': equivalent,
        'negative_control': args.negative_control, 'counterexample_detected': detected,
        'baseline_sha256': sha(baseline), 'candidate_sha256': sha(candidate),
        'projected_sha256': sha(miter.read_text()), 'proof_script_sha256': sha(script.read_text()),
        'tool_sha256': hashlib.sha256(Path(args.yosys).read_bytes()).hexdigest(),
        'proof_tool_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'tool_version': subprocess.check_output([args.yosys, '-V'], text=True).strip(),
        'returncode': result.returncode,
        'scope': 'Exact canonical full-source change; SAT proves all 83 output bits of actual-source projected keypad edit combinational cone for every two-state input, including all 64-bit text, all 16 lengths, all ASCII and independently arbitrary decode inputs. No sequential latency or state change; unchanged remainder transfers cone equality. No X/Z equivalence or board timing claim.'}
    (out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    return 0 if accepted else 1


if __name__ == '__main__':
    raise SystemExit(main())
