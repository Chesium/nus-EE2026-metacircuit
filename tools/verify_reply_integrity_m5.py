#!/usr/bin/env python3
"""Cold real-UART malformed reply rejection/recovery and all32node view checks."""
from pathlib import Path
import argparse,datetime,hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1];IMAGE='framescope-toolchain:6501155dc903'
P=argparse.ArgumentParser(description=__doc__)
P.add_argument('--runtime',choices=['native','docker'],required=True)
P.add_argument('--design-root',type=Path,default=ROOT/'src/design')
P.add_argument('--out',type=Path,required=True)
A=P.parse_args();D=A.out.resolve();D.mkdir(parents=True,exist_ok=False);S=A.design_root.resolve();rt=A.runtime
sources=sorted(S.rglob('*Pkg.sv'))+sorted(p for p in S.rglob('*') if p.suffix in ('.v','.sv') and not p.name.endswith('Pkg.sv') and 'floating_point' not in p.parts)+[ROOT/'src/testbench/GlobalRenderUartLoop_test.sv',ROOT/'src/testbench/M5ReplyIntegrity_test.sv'];sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();pins={str(p):sha(p) for p in sources}
def path(p):
 if rt=='native':return str(p)
 if p.is_relative_to(S):return '/design/'+str(p.relative_to(S))
 if p.is_relative_to(D):return '/out/'+str(p.relative_to(D))
 return '/source/'+str(p.relative_to(ROOT))
def invoke(cmd,name):
 cid=D/(name+'.cid')
 if rt=='docker':cmd=['docker','run','--rm','--cidfile',str(cid),'-v',str(ROOT)+':/source:ro','-v',str(S)+':/design:ro','-v',str(D)+':/out','-w','/out',IMAGE]+cmd
 (D/(name+'-command.json')).write_text(json.dumps(cmd,indent=2)+'\n')
 with (D/(name+'.log')).open('w') as log:
  try:return subprocess.run(cmd,cwd=D,stdout=log,stderr=subprocess.STDOUT,timeout=240).returncode
  except (OSError,subprocess.TimeoutExpired) as e:
   log.write('\nM5_REPLY_RUNNER_FAILURE '+type(e).__name__+'\n')
   if rt=='docker' and cid.is_file():subprocess.run(['docker','rm','-f',cid.read_text().strip()],capture_output=True,timeout=20)
   return 124
version=invoke(['verilator','--version'],'tool');build=invoke(['verilator','--binary','--timing','--assert','-Wno-fatal','-Wno-lint','-Wno-style','-Wno-MULTIDRIVEN','-j','4','--top-module','M5ReplyIntegrity_test','--Mdir',path(D/'obj'),*[path(p) for p in sources]],'build');normal=negative=None;oracle=None
if build==0:
 normal=invoke([path(D/'obj/VM5ReplyIntegrity_test')],'normal');negative=invoke([path(D/'obj/VM5ReplyIntegrity_test'),'+m5-corrupt-reply-observation'],'negative')
 # Reuse the immutable production golden decoder, with literal expectations
 # for this fixture. No candidate-derived oracle data or checksum parser.
 code='''import {readFileSync} from 'node:fs';
import {parseUartStream} from './src/backend/uart.ts';
const input=process.argv[1];const lines=JSON.parse(input);const expected=['seed','duplicate','duplicate-recovery','range','range-recovery','missing','missing-recovery','reverse-order','capacity-32','empty'];let name='',packet=[];const rows=[];
function finish(){if(!name)return;const r=parseUartStream(packet.join('\\r\\n')+'\\r\\n');const bad=['duplicate','range','missing'].includes(name);rows.push({case:name,lines:packet.length,accepted:r.voltages.length,problems:r.problems,ok:bad?r.voltages.length===0&&r.problems.length>0:r.voltages.length===(name==='capacity-32'?2:1)&&r.problems.length===0});}
for(const line of lines){if(line.startsWith('M5_REPLY_CASE ')){finish();name=line.slice(14).trim();packet=[];}else if(line.startsWith('M5_REPLY_RX '))packet.push(line.slice(12).trim());}finish();const ok=rows.map(r=>r.case).join(',')===expected.join(',')&&rows.every(r=>r.ok);console.log(JSON.stringify({ok,rows}));if(!ok)process.exit(1);'''
 with (D/'oracle.log').open('w') as log:
  oracle=subprocess.run(['npx','tsx','--eval',code,json.dumps((D/'normal.log').read_text().splitlines())],cwd=ROOT/'golden',stdout=log,stderr=subprocess.STDOUT,timeout=60).returncode
text=(D/'normal.log').read_text() if (D/'normal.log').is_file() else '';neg=(D/'negative.log').read_text() if (D/'negative.log').is_file() else '';stable=all(sha(Path(p))==v for p,v in pins.items());oracle_result=None
if (D/'oracle.log').is_file():
 for line in (D/'oracle.log').read_text().splitlines():
  try:
   candidate=json.loads(line)
   if isinstance(candidate,dict) and 'rows' in candidate:oracle_result=candidate
  except ValueError:pass
result={'schema':'metacircuit-reply-integrity/v1','ok':build==0 and version==0 and normal==0 and re.findall(r'M5_REPLY_INTEGRITY_PASS cases=(\d+) lines=(\d+)',text)==[('11','101')] and negative!=0 and 'M5_REPLY_FAILURE accepted value' in neg and oracle==0 and oracle_result and oracle_result['ok'] is True and stable,'runtime':rt,'design_root':str(S),'source_hashes':pins,'source_unchanged':stable,'tool_version':(D/'tool.log').read_text().strip(),'build_exit':build,'normal_exit':normal,'negative_exit':negative,'oracle_exit':oracle,'oracle':oracle_result,'golden_decoder_sha256':sha(ROOT/'golden/src/backend/uart.ts'),'bench_sha256':sha(ROOT/'src/testbench/M5ReplyIntegrity_test.sv'),'runner_sha256':sha(Path(__file__)),'scope':'Actual cold fulltop115200RsRx/UartRx/lineassembler/parser/replybanks plusphysicalBTNR inputs and synchronous view-word checks. Elevenfixtures/101lines, no event/ID/RAMinjection. Unique declared nodes, malformedrejection/recovery, reverseorder,32values/31selections/nonwrap/selectionretention, empty.','unsupported':['Physicalboard/PS2/CDC','General arbitraryUI/reply overlap','Solver numerical accuracy'],'artifacts':{str(p.relative_to(D)):sha(p) for p in D.rglob('*') if p.is_file()},'completed_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat()};(D/'report.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'ok':bool(result['ok']),'report':str(D/'report.json')}));raise SystemExit(0 if result['ok'] else 1)
