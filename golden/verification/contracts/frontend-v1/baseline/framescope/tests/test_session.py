"""Persistent stepping: cold/run equivalence, atomic poke, reads and JSON errors."""
import io
import json
import tempfile
import unittest
from pathlib import Path

from helpers import EXAMPLES, write
from test_integration import RT, _quiet
from framescope import manifest
from framescope.run import run
from framescope.session import Session, serve


class ServeTest(unittest.TestCase):
    def test_one_response_per_line_including_invalid_json(self):
        class Fake:
            def request(self, req):
                return {"ok": isinstance(req, dict), "id": req.get("id") if isinstance(req, dict) else None}
        sink = io.StringIO()
        serve(Fake(), io.StringIO('{"id":1,"op":"probes"}\noops\n[]\n{"id":NaN}\n'), sink)
        replies = [json.loads(line) for line in sink.getvalue().splitlines()]
        self.assertEqual(len(replies), 4)
        self.assertEqual(replies[0], {"ok": True, "id": 1})
        self.assertTrue(all(not r["ok"] for r in replies[1:]))


@unittest.skipIf(RT is None, "no framescope runtime")
class SessionIntegrationTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(dir=EXAMPLES)
        cls.root = Path(cls.tmp.name)
        write(cls.root / "tiny.sv", '''module tiny(input logic clk, input logic rst_n,
  input logic [3:0] value, output logic hs, vs, de, output logic [3:0] rgb);
  logic [3:0] x=0, y=0;
  logic [3:0] mem[0:1];
  always_ff @(posedge clk) begin
    if (!rst_n) begin x<=0; y<=0; mem[0]<=0; mem[1]<=0; end
    else begin
      if(x==7) begin x<=0; if(y==5) y<=0; else y<=y+1; end else x<=x+1;
      mem[0]<=value; mem[1]<=x;
    end
  end
  assign hs=(x<2); assign vs=(value==15 ? 1'b0 : y<1); assign de=(x>=3 && x<7 && y>=2 && y<5);
  assign rgb=value;
endmodule
''')
        write(cls.root / "framescope.toml", '''[design]
top="tiny"
sources=["tiny.sv"]
[clocks]
clk={freq_hz=1000000}
[reset]
port="rst_n"
active=0
duration_ns=2000
[[monitor]]
name="vga"
protocol="vga"
[monitor.signals]
pclk="clk"
hsync="hs"
vsync="vs"
de="de"
red="rgb"
green="rgb"
blue="rgb"
[probes]
value="value"
x="dut.x"
y="dut.y"
negative={expr="-8'sd3",signed=true}
[[dump]]
name="mem"
path="dut.mem"
''')
        cls.m = manifest.load(cls.root)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def test_repeated_steps_equal_uninterrupted_run_and_memory(self):
        cold = run(self.m, RT, _quiet, frames=3, out=self.root / "cold", sets=["value=2"], save="none", dump="all")
        self.assertTrue(cold["ok"], cold)
        with Session(self.m, RT, _quiet, out=self.root / "session", sets=["value=2"]) as s:
            observed = []
            for i in range(3):
                response = s.request({"op":"step", "id":i})
                self.assertTrue(response["ok"], response)
                self.assertEqual(response["completed_frames"], i+1)
                self.assertEqual(response["probes"]["negative"], -3)
                observed.extend(e for e in response["events"] if e.get("event")=="frame")
                memory = s.request({"op":"memory", "name":"mem"})
                expected = json.loads(Path(cold["dumps"]["mem"][i]["path"]).read_text())
                self.assertEqual(memory["memory"], expected)
            self.assertEqual([e["crc32"] for e in observed], [f["crc32"] for f in cold["monitors"]["vga"]["frames"]])
            self.assertEqual(s.request({"op":"probes"})["t_ps"], response["t_ps"])
            pid = s.proc.pid
            stopped = s.request({"op":"stop", "id":"done"})
            self.assertTrue(stopped["ok"])
            self.assertEqual(stopped["id"], "done")
            self.assertIsNotNone(s.proc.poll(), pid)
            self.assertFalse(s.request({"op":"step"})["ok"])

    def test_invalid_poke_is_atomic_and_changes_are_visible_next_frame(self):
        with Session(self.m, RT, _quiet, out=self.root / "poke") as s:
            first = s.request({"op":"step"})
            for req in ({"op":"poke", "values":{"value":5,"missing":1}}, {"op":"step","frames":True},
                        {"op":"memory","name":"missing"}, {"op":"missing"}, []):
                self.assertFalse(s.request(req)["ok"], req)
            self.assertEqual(s.request({"op":"probes"})["probes"]["value"], 0)
            changed = s.request({"op":"poke", "values":{"value":7}})
            self.assertTrue(changed["ok"], changed)
            self.assertEqual(changed["t_ps"], first["t_ps"])
            self.assertEqual(changed["probes"]["value"], 7)
            stepped = s.request({"op":"step", "frames":2})
            self.assertEqual(stepped["completed_frames"], 3)
            self.assertEqual(s.request({"op":"memory","name":"mem"})["memory"]["words"][0], "0x7")
            self.assertEqual(len([e for e in stepped["events"] if e.get("event")=="frame"]), 2)

    def test_timed_poke_matches_position_stimulus(self):
        stim = write(self.root / "timed.toml", "[[event]]\nframe=1\nline=2\npixel=1\nset={value=9}\n")
        cold = run(self.m, RT, _quiet, frames=3, out=self.root / "timed-cold", stim=stim, save="none")
        with Session(self.m, RT, _quiet, out=self.root / "timed-session") as s:
            a = s.request({"op":"step"})
            queued = s.request({"op":"poke", "values":{"value":9}, "line":2, "pixel":1})
            self.assertTrue(queued["ok"], queued)
            self.assertEqual(queued["probes"]["value"], 0)
            b = s.request({"op":"step", "frames":2})
            frames = [e for e in a["events"]+b["events"] if e.get("event")=="frame"]
            self.assertEqual([e["crc32"] for e in frames], [f["crc32"] for f in cold["monitors"]["vga"]["frames"]])
            events = [e for e in b["events"] if e.get("event")=="stim"]
            self.assertEqual([(e["frame"],e["at_frame"],e["at_line"],e["at_pixel"]) for e in events], [(1,1,2,1)])

    def test_step_time_budget_override(self):
        with Session(self.m, RT, _quiet, out=self.root / "budget", sets=["value=2"]) as s:
            for limit in (0, -1, True, "5", float("nan"), 2e6):
                rejected = s.request({"op":"step", "max_time_ms":limit})
                self.assertFalse(rejected["ok"], limit)
                self.assertIn("max_time_ms", rejected["error"])
            self.assertEqual(s.request({"op":"probes"})["completed_frames"], 0)
            self.assertTrue(s.request({"op":"step", "max_time_ms":500})["ok"])
            short = s.request({"op":"step", "max_time_ms":0.001})
            self.assertFalse(short["ok"], short)
            self.assertIn("max_time", short["error"])

    def test_dead_sync_exits_at_bounded_time(self):
        with Session(self.m, RT, _quiet, out=self.root / "dead-sync", sets=["value=15"]) as s:
            result = s.request({"op":"step"})
            self.assertFalse(result["ok"], result)
            self.assertIn("max_time", result["error"])
            self.assertFalse(s.request({"op":"probes"})["ok"])

    def test_eof_closes_owned_process(self):
        s = Session(self.m, RT, _quiet, out=self.root / "eof")
        with s:
            serve(s, io.StringIO(''), io.StringIO())
        self.assertIsNotNone(s.proc.poll())


if __name__ == "__main__":
    unittest.main()
