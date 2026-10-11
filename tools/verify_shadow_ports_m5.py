#!/usr/bin/env python3
"""Audit a narrowly specified same-edge shadow-write normalization.

This is a source-level inductive argument, not a generic HDL equivalence tool.
The pinned source, exact canonical rewrite, exclusive write paths, unchanged
expressions and unchanged NBA memory updates are all mandatory proof premises.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
from pathlib import Path

BASELINE_SHA = '254c8842d72c6c4801ef015c8c3274687a970c8794f9d09e6d966ced42657a66'
# Separately reviewed A-008 fix: one initialized write-drain register, expanded
# busy expression and one always block delaying release through RAM read refresh.
# Its exact full-source identity is admitted; arbitrary live source hashes are not.
A008_BASELINE_SHA = '4e62e63dd68ba9e946006a86129d48c39dd7570710a73451f0fd1fba68c2bb16'
ARRAYS = [('canvas_shadow_data', 16), ('value_shadow_data', 12), ('value_unit_shadow_data', 4)]
RELATIVE_SOURCE = 'src/design/rendering/GlobalRender_top.v'


def digest(text):
    return hashlib.sha256(text.encode()).hexdigest()


def reviewed_a008_reference(original):
    """Recreate only the three explicitly reviewed write-drain correction hunks."""
    if digest(original) != BASELINE_SHA:
        raise ValueError('A-008 reconstruction requires pinned original')
    replacements = [
        ("    reg         component_store_rebuild_active = 1'b0;\n",
         "    reg         component_store_rebuild_active = 1'b0;\n"
         "    reg         component_store_write_drain = 1'b0;\n"),
        ('        component_store_rebuild_active || component_store_dirty;\n',
         '        component_store_rebuild_active || component_store_dirty ||\n'
         '        component_index_map_w_en || component_store_w_en || component_store_write_drain;\n'),
        ('    always @(posedge CLK100MHZ) begin\n        if (component_store_read_snapshot_pending) begin',
         '    // A-008: registered write strobes retire one edge after rebuild schedules\n'
         '    // them. SimpleRam reads old data on that write edge, so keep consumers busy\n'
         '    // for the following read-refresh edge as well.\n'
         '    always @(posedge CLK100MHZ) begin\n'
         '        component_store_write_drain <= component_index_map_w_en || component_store_w_en;\n'
         '    end\n\n'
         '    always @(posedge CLK100MHZ) begin\n        if (component_store_read_snapshot_pending) begin'),
    ]
    for before, after in replacements:
        if original.count(before) != 1:
            raise ValueError('reviewed A-008 hunk changed')
        original = original.replace(before, after, 1)
    if digest(original) != A008_BASELINE_SHA:
        raise ValueError('reviewed A-008 source identity mismatch')
    return original


def write_pattern(name):
    # One nested packed slice occurs in init_cycles[CANVAS_ADDR_W-1:0].
    return r'\b' + name + r'\[((?:[^\[\]\n]|\[[^\]\n]+\])+)\]\s*<=\s*([^;]+);'


def transform(source):
    result = source
    for name, width in ARRAYS:
        result = re.sub(write_pattern(name), lambda m:
            f"{name}_we = 1'b1;\n            {name}_wa = {m[1]};\n            {name}_wd = {m[2]};", result)
        anchor = '    // component_store entry = '
        decl = (f'    // One same-edge shadow write port; selectors are blocking temporaries.\n'
                f'    reg {name}_we;\n    reg [CANVAS_ADDR_W-1:0] {name}_wa;\n'
                f'    reg [{width-1}:0] {name}_wd;\n')
        if result.count(anchor) != 1:
            raise ValueError('declaration anchor changed')
        result = result.replace(anchor, decl + anchor, 1)
        anchor = "        mouse_set_value <= 12'h000;"
        defaults = (f"        {name}_we = 1'b0;\n"
                    f"        {name}_wa = {{CANVAS_ADDR_W{{1'b0}}}};\n"
                    f"        {name}_wd = {width}'d0;\n")
        if result.count(anchor) != 1:
            raise ValueError('clock/default anchor changed')
        result = result.replace(anchor, defaults + anchor, 1)
        anchor = '        if (component_index_map_pending_pair_write) begin'
        write = f'        if ({name}_we)\n            {name}[{name}_wa] <= {name}_wd;\n\n'
        if result.count(anchor) != 1:
            raise ValueError('final write anchor changed')
        result = result.replace(anchor, write + anchor, 1)
    return result


class Statements:
    """Fail-closed parser for the pinned if/begin/assignment write-decision chain."""
    def __init__(self, text):
        self.text = re.sub(r'/\*.*?\*/|//[^\n]*', '', text, flags=re.S)
        self.pos = 0

    def space(self):
        while self.pos < len(self.text) and self.text[self.pos].isspace():
            self.pos += 1

    def keyword(self, word):
        self.space()
        if re.match(re.escape(word) + r'\b', self.text[self.pos:]):
            self.pos += len(word)
            return True
        return False

    def statement(self):
        self.space()
        if self.keyword('begin'):
            children = []
            while not self.keyword('end'):
                children.append(self.statement())
            return ('block', children)
        if self.keyword('if'):
            self.space()
            if self.text[self.pos] != '(':
                raise ValueError('if condition missing')
            start = self.pos
            depth = 0
            while self.pos < len(self.text):
                char = self.text[self.pos]
                depth += (char == '(') - (char == ')')
                self.pos += 1
                if depth == 0:
                    break
            condition = self.text[start:self.pos]
            yes = self.statement()
            no = self.statement() if self.keyword('else') else ('block', [])
            return ('if', condition, yes, no)
        end = self.text.find(';', self.pos)
        if end < self.pos:
            raise ValueError('unsupported or unterminated statement')
        text = self.text[self.pos:end+1]
        if re.search(r'\b(?:begin|end|for|case|while|always)\b', text):
            raise ValueError('unsupported control structure')
        self.pos = end + 1
        return ('leaf', text)


def max_writes(tree, name):
    if tree[0] == 'leaf':
        return len(re.findall(write_pattern(name), tree[1]))
    if tree[0] == 'block':
        return sum(max_writes(item, name) for item in tree[1])
    return max(max_writes(tree[2], name), max_writes(tree[3], name))


def leaves(tree):
    if tree[0] == 'leaf':
        return [tree[1]]
    if tree[0] == 'block':
        return [leaf for child in tree[1] for leaf in leaves(child)]
    return leaves(tree[2]) + leaves(tree[3])


def audit(reference, candidate):
    if digest(reference) not in (BASELINE_SHA, A008_BASELINE_SHA):
        raise ValueError('reference must be the pinned original or separately reviewed A-008 source')
    if candidate != transform(reference):
        raise ValueError('candidate differs from the sole canonical write-port transformation')
    start = reference.rindex('        if (clear_canvas_active) begin')
    end = reference.index('        if (component_index_map_pending_pair_write) begin', start)
    chain = reference[start:end]
    parser = Statements(chain)
    tree = parser.statement()
    parser.space()
    if parser.pos != len(parser.text):
        raise ValueError('unexpected statements outside exclusive chain')
    rows = []
    for name, width in ARRAYS:
        sites = list(re.finditer(write_pattern(name), reference))
        projected = sum(len(re.findall(write_pattern(name), leaf)) for leaf in leaves(tree))
        if projected != len(sites) or max_writes(tree, name) != 1:
            raise ValueError('writes outside chain or multiple simultaneous writes: ' + name)
        expected = 20 if name == 'canvas_shadow_data' else 23
        if len(sites) != expected:
            raise ValueError('write-site inventory changed: ' + name)
        if len(re.findall(write_pattern(name), candidate)) != 1:
            raise ValueError('candidate does not have exactly one NBA write: ' + name)
        rows.append({'array': name, 'data_width': width, 'address_width': 9,
                     'original_sites': len(sites), 'max_writes_per_edge': 1,
                     'candidate_sites': 1,
                     'expressions': [{'address': m[1], 'data': m[2]} for m in sites]})
    return {'ok': True, 'proof_kind': 'pinned-source structural inductive normalization',
            'reference_sha256': digest(reference), 'candidate_sha256': digest(candidate),
            'reference_identity': 'original' if digest(reference) == BASELINE_SHA else 'reviewed-A-008-write-drain',
            'arrays': rows,
            'scope': 'All clock edges and all two-state input/address/data values; all 512 addresses retained.',
            'initial_state': 'Arbitrary equal array contents; original arrays have no explicit initializer. Boot writes unchanged.',
            'inductive_argument': [
                'The parsed control tree permits at most one write to each array in each edge.',
                'The selected address/data expressions are unchanged and selector widths equal the original write widths.',
                'Selectors use blocking assignment during the same always block; memory updates remain nonblocking on the same edge.',
                'All memory reads and other statements are unchanged; every read in the active event sees the previous contents.',
                'A branch without a write leaves the array unchanged; a branch with a write schedules the same indexed NBA.',
                'Equal pre-edge array contents therefore yield equal post-NBA contents and all unchanged observations by induction.'
            ],
            'limitations': ['Not a generic Verilog parser or a solver-backed whole-design formal proof.',
                            'No four-state X/Z or active-region hierarchical observation equivalence claim.',
                            'Global frontend functional regression and measured FPGA acceptance are separate requirements.']}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reference', type=Path, required=True)
    parser.add_argument('--candidate', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    try:
        report = audit(args.reference.read_text(), args.candidate.read_text())
    except (ValueError, OSError) as error:
        report = {'ok': False, 'error': str(error)}
    report['runner_sha256'] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'ok': report['ok'], 'report': str(args.out), 'error': report.get('error')}))
    return 0 if report['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
