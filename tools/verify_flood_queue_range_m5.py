#!/usr/bin/env python3
from pathlib import Path
import datetime, hashlib, json, subprocess

import argparse
P=argparse.ArgumentParser(description='Actual-source FIFO reset base and one-step range/count induction; original-source counterexamples required.')
P.add_argument('--source',type=Path,required=True);P.add_argument('--reference',type=Path,required=True);P.add_argument('--out',type=Path,required=True);P.add_argument('--yosys',default='/tmp/m5-qor-yosys-tools/extracted/usr/bin/yosys')
A=P.parse_args();O=A.out.resolve();O.mkdir(parents=True,exist_ok=False);Y=A.yosys
(O/'reference.v').write_bytes(A.reference.read_bytes());(O/'FloodQueueStore.v').write_bytes(A.source.read_bytes());(O/'prove.py').write_bytes(Path(__file__).read_bytes())
version=subprocess.check_output([Y,'-V'],text=True).strip()
if not version.startswith('Yosys 0.33 '):raise SystemExit('Expected qualified Yosys0.33')
rows = []
for variant in ['reference', 'candidate']:
    source = (O / ('reference.v' if variant == 'reference' else 'FloodQueueStore.v')).read_text()
    assert source.count('output reg  [17:0] popQueue_result') == 1
    instrumented = source.replace('output reg  [17:0] popQueue_result', 'output reg  [17:0] popQueue_result, output wire range_ok')
    anchor = '  wire do_pop = popQueue_start && (count != 0);'
    assert instrumented.count(anchor) == 1
    instrumented = instrumented.replace(anchor, anchor + '\n  assign range_ok = count <= DEPTH && head_ptr < DEPTH && tail_ptr < DEPTH;')
    for depth in [1, 3, 4, 1152]:
        d = O / f'proof-{variant}-{depth}'
        d.mkdir()
        wrapper = f'''module proof(input clk,rst_n,clear,add_start,pop_start,len_start,output range_ok);
FloodQueueStore #(.DEPTH({depth})) dut(.clk(clk),.rst_n(rst_n),.clear(clear),.addQueue_start(add_start),.addQueue_i(8'd0),.addQueue_j(8'd0),.addQueue_d(32'd0),.getQueueLen_start(len_start),.popQueue_start(pop_start),.range_ok(range_ok));
endmodule
'''
        sv = d / 'instrumented.v'
        sv.write_text(instrumented + wrapper)
        for kind in ['reset-base', 'induction']:
            setup = '-set-at 1 rst_n 0' if kind == 'reset-base' else '-set-at 1 range_ok 1'
            ys = d / (kind + '.ys')
            ys.write_text(f'read_verilog -sv "{sv}"\nhierarchy -top proof\nproc\nflatten\nopt\nmemory_map\nopt\nsat -seq 2 -set-def-inputs {setup} -prove range_ok 1 -prove-skip 1 -verify -show-inputs -show-outputs\n')
            with (d / (kind + '.log')).open('w') as log:
                run = subprocess.run([Y, '-s', str(ys)], stdout=log, stderr=subprocess.STDOUT, timeout=120)
            log = (d / (kind + '.log')).read_text()
            expect_pass = kind == 'reset-base' or variant == 'candidate' or depth == 4
            accepted = run.returncode == 0 and 'SUCCESS!' in log if expect_pass else run.returncode != 0 and 'proof did fail' in log
            row = dict(variant=variant, depth=depth, kind=kind, expected_pass=expect_pass, accepted=accepted, returncode=run.returncode, input_sha256=hashlib.sha256(sv.read_bytes()).hexdigest())
            rows.append(row)
            print(json.dumps(row), flush=True)
            (O / 'proof-checkpoint.json').write_text(json.dumps(rows, indent=2) + '\n')
report = dict(ok=all(x['accepted'] for x in rows) and A.source.read_bytes()==(O/'FloodQueueStore.v').read_bytes() and A.reference.read_bytes()==(O/'reference.v').read_bytes(), rows=rows, completed_at_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(), scope='Actual-source one-step induction: any valid count/head/tail state remains valid after arbitrary add/pop/length/reset/clear inputs. Reset/clear base proved from arbitrary prior state. Neither initial powerup validity nor FIFO data-order/latency is proved here.', tool=Y, tool_version=version, source_unchanged=(A.source.read_bytes()==(O/'FloodQueueStore.v').read_bytes() and A.reference.read_bytes()==(O/'reference.v').read_bytes()), source_hashes={n:hashlib.sha256((O/n).read_bytes()).hexdigest() for n in ['reference.v','FloodQueueStore.v','prove.py']})
(O / 'proof-report.json').write_text(json.dumps(report, indent=2) + '\n')
raise SystemExit(0 if report['ok'] else 1)
