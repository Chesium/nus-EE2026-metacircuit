import tempfile
import unittest
from pathlib import Path

from helpers import write

from framescope import FramescopeError
from framescope.ports import parse_json, parse_xml

XML = """<?xml version="1.0" ?>
<verilator_xml>
  <netlist>
    <module name="top" origName="top" topModule="1">
      <var name="CLK" dtype_id="1" dir="input" pinIndex="1" vartype="logic" origName="CLK"/>
      <var name="LED" dtype_id="2" dir="output" pinIndex="3" vartype="logic" origName="LED"/>
      <var name="SW" dtype_id="3" dir="input" pinIndex="2" vartype="logic" origName="SW"/>
      <var name="PS2" dtype_id="1" dir="inout" pinIndex="4" vartype="logic" origName="PS2"/>
      <var name="internal" dtype_id="2" vartype="logic" origName="internal"/>
      <func name="f"><var name="arg" dtype_id="2" dir="input" vartype="logic"/></func>
    </module>
    <typetable>
      <basicdtype id="1" name="logic"/>
      <basicdtype id="2" name="logic" left="15" right="0"/>
      <refdtype id="3" name="sw_t" sub_dtype_id="4"/>
      <basicdtype id="4" name="logic" left="3" right="0"/>
      <structdtype id="5" name="s"/>
    </typetable>
  </netlist>
</verilator_xml>
"""

# Trimmed from Verilator 5.046 --json-only: the top is the level-1 MODULE, ports
# are VARs with isPrimaryIO in declaration order, typedefs are REFDTYPE chains.
JSON = """{"type": "NETLIST", "modulesp": [
  {"type": "MODULE", "name": "top", "level": 1, "stmtsp": [
    {"type": "VAR", "name": "CLK", "dtypep": "(A)", "isPrimaryIO": true, "direction": "INPUT"},
    {"type": "VAR", "name": "SW", "dtypep": "(C)", "isPrimaryIO": true, "direction": "INPUT"},
    {"type": "VAR", "name": "LED", "dtypep": "(B)", "isPrimaryIO": true, "direction": "OUTPUT"},
    {"type": "VAR", "name": "PS2", "dtypep": "(A)", "isPrimaryIO": true, "direction": "INOUT"},
    {"type": "VAR", "name": "internal", "dtypep": "(B)", "varType": "WIRE"},
    {"type": "FUNC", "name": "f", "stmtsp": [
      {"type": "VAR", "name": "arg", "dtypep": "(B)", "direction": "INPUT", "varType": "PORT"}]}]},
  {"type": "MODULE", "name": "sub", "level": 2, "stmtsp": [
    {"type": "VAR", "name": "x", "dtypep": "(A)", "isPrimaryIO": true, "direction": "INPUT"}]}],
 "miscsp": [{"type": "TYPETABLE", "typesp": [
  {"type": "BASICDTYPE", "name": "logic", "addr": "(A)"},
  {"type": "BASICDTYPE", "name": "logic", "addr": "(B)", "range": "15:0"},
  {"type": "REFDTYPE", "name": "sw_t", "addr": "(C)", "refDTypep": "(D)"},
  {"type": "BASICDTYPE", "name": "logic", "addr": "(D)", "range": "3:0"},
  {"type": "STRUCTDTYPE", "name": "s", "addr": "(E)"}]}]}
"""


class PortsTest(unittest.TestCase):
    def test_parses_top_ports_in_pin_order(self):
        with tempfile.TemporaryDirectory() as tmp:
            ports = parse_xml(write(Path(tmp) / "v.xml", XML), "top")
        self.assertEqual([(p.name, p.direction, p.width) for p in ports],
                         [("CLK", "input", 1), ("SW", "input", 4), ("LED", "output", 16), ("PS2", "inout", 1)])
        self.assertEqual(ports[0].sv_range, "")
        self.assertEqual(ports[2].sv_range, "[15:0]")

    def test_unsupported_type(self):
        xml = XML.replace('dtype_id="3" dir="input"', 'dtype_id="5" dir="input"')
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaisesRegex(FramescopeError, "cannot map"):
                parse_xml(write(Path(tmp) / "v.xml", xml), "top")

    def test_parses_json_top_ports_in_declaration_order(self):
        with tempfile.TemporaryDirectory() as tmp:
            ports = parse_json(write(Path(tmp) / "v.json", JSON), "top")
        self.assertEqual([(p.name, p.direction, p.width) for p in ports],
                         [("CLK", "input", 1), ("SW", "input", 4), ("LED", "output", 16), ("PS2", "inout", 1)])
        self.assertEqual(ports[0].sv_range, "")
        self.assertEqual(ports[2].sv_range, "[15:0]")

    def test_json_unsupported_type(self):
        text = JSON.replace('"dtypep": "(C)"', '"dtypep": "(E)"')
        with tempfile.TemporaryDirectory() as tmp:
            with self.assertRaisesRegex(FramescopeError, "cannot map"):
                parse_json(write(Path(tmp) / "v.json", text), "top")


if __name__ == "__main__":
    unittest.main()
