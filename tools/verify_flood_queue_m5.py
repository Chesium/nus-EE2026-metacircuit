#!/usr/bin/env python3
"""Reset-free FIFO lifetime witness at actual and boundary queue depths."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
from verify_solver_m5 import command

ROOT = Path(__file__).resolve().parents[1]
IMAGE = 'framescope-toolchain:6501155dc903'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime', choices=('native', 'docker'), required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    sources = [ROOT/'src/design/common/FloodQueueStore.v', ROOT/'src/testbench/M5FloodQueueLifetime.sv']
    hashes = {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}
    def invoke(argv, name):
        cid = out/(name+'.cid')
        if args.runtime == 'docker':
            argv = ['docker','run','--rm','--cidfile',str(cid),'-v',f'{ROOT}:/source:ro',
                    '-v',f'{out}:/out','-w','/out',IMAGE,*argv]
        result = command(argv, ROOT, out/(name+'.log'), 180)
        if args.runtime == 'docker' and cid.exists() and result.get('returncode') is None:
            subprocess.run(['docker','rm','-f',cid.read_text().strip()], capture_output=True)
        return result
    def path(p):
        if args.runtime == 'native': return str(p)
        return '/out/'+str(p.relative_to(out)) if p.is_relative_to(out) else '/source/'+str(p.relative_to(ROOT))
    version = invoke(['verilator','--version'],'tool')
    runs = []
    for depth in (1,3,4,1152):
        name = 'depth-'+str(depth)
        build = out/(name+'-build')
        result = {'depth':depth,'ok':False,'build':invoke(['verilator','--binary','--timing','--assert',
                  '-Wno-fatal','--top-module','M5FloodQueueLifetime',f'-GDEPTH={depth}',
                  '--Mdir',path(build),*[path(p) for p in sources]],name+'-build')}
        if result['build']['returncode'] == 0:
            result['normal'] = invoke([path(build/'VM5FloodQueueLifetime')],name+'-normal')
            normal = (out/(name+'-normal.log')).read_text()
            result['negative'] = invoke([path(build/'VM5FloodQueueLifetime'),'+m5-corrupt-queue-observation'],name+'-negative')
            negative = (out/(name+'-negative.log')).read_text()
            result['negative_detected'] = bool('M5_QUEUE_FAILURE fifo' in negative and 'sequence=0 ' in negative)
            result['fifo_mismatch'] = bool(re.search(r'M5_QUEUE_FAILURE fifo.*sequence=\d+',normal))
            result['ok'] = (result['normal']['returncode'] == 0 and
                            f'M5_QUEUE_LIFETIME_PASS depth={depth} checks={3*depth+7}' in normal and
                            'M5_QUEUE_FAILURE' not in normal and result['negative_detected'])
        runs.append(result)
    stable = all(hashlib.sha256(p.read_bytes()).hexdigest()==hashes[str(p.relative_to(ROOT))] for p in sources)
    report = {'schema':'metacircuit-flood-queue-lifetime/v1','runtime':args.runtime,
              'ok':stable and version['returncode']==0 and all(r['ok'] for r in runs),
              'source_hashes':hashes,'source_unchanged':stable,
              'runner_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              'tool_version':(out/'tool.log').read_text().strip(),'runs':runs,
              'scope':'Reset-free sequential enqueue/pop FIFO order, acknowledgment and count; DEPTH1/3/4/1152.',
              'unsupported':['integrated reachability of >1152 lifetime enqueues between clears',
                             'simultaneous operations','full/overflow behavior','formal equivalence'],
              'full_m5_ready':False}
    (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({'ok':report['ok'],'report':str(out/'report.json')}))
    return 0 if report['ok'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
