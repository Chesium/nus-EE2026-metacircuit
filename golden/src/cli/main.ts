// golden CLI: run scenarios headlessly, compile them to framescope stimulus, expand them.
//   npm run golden -- run scenarios/m1_canvas_tools.json --out out/m1
//   npm run golden -- stim scenarios/m1_canvas_tools.json -o out/m1.stim.toml
//   npm run golden -- expand scenarios/m1_canvas_tools.json
//   npm run golden -- netlist scenarios/m2_node_colours.json --out out/m3/netlist
//   npm run golden -- uart-decode capture.txt

import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { parseArgs } from 'node:util';
import { DEFAULT_CONFIG, makeConfig } from '../core/config.ts';
import { DEFAULT_DUMP_NAMES, type DumpNames } from '../core/export.ts';
import { expandScenario } from '../scenario/expand.ts';
import { runScenario } from '../scenario/run.ts';
import { compileStim } from '../scenario/stim.ts';
import type { Scenario } from '../scenario/types.ts';
import { compareRun } from './compare.ts';
import { renderReferences } from './reference.ts';
import { compareUi } from './compare-ui.ts';
import { decodeUartCapture, netlistReferences, parseFrameList, writeNetlistReferences } from './netlist.ts';

const USAGE = `usage: golden <command> <scenario.json> [options]

commands:
  run     step the golden model through the scenario; per checkpoint write the RAM
          dumps (<NN>_<label>.ram.json, and dumps/<memory>/frame_NNNN.json as
          framescope does) and the decoded state (<NN>_<label>.state.json) into
          --out (default out/<scenario name>)
  stim    compile the scenario to a framescope stimulus TOML (stdout or -o FILE)
  expand  print the canonical per-frame form (JSON)
  render  generate checkpoint reference PNGs from the asset renderer into --out
  compare compare a framescope run directory with --reference golden output
  compare-ui compare property selection/value/keypad probes with pixel references
  netlist extract the golden netlist at each checkpoint (or --frames) and write
          <NN>_<label>.netlist.json and .netlist.uart (uart_link records, CRLF)
          plus netlists.json into --out (default out/<scenario name>/netlist)
  uart-decode parse a uart_link capture (NB/NC/NE, VB/VN/VE, ER) into JSON

options:
  --out DIR            run: output directory
  -o, --output FILE    stim/expand: output file (default stdout)
  --line N             stim: scan line at which inputs change (default 10)
  --frame-offset N     stim: framescope frame = golden frame + N (default 0)
  --latency N          run: input-to-effect latency in frames (default 1, measured; RTL-3)
  --rotate-frames N    run: frames per repeated rotation while held (default 8)
  --names FILE         run: JSON overriding memory names, e.g. {"componentStore": "component_store"}
  --reference DIR      compare: reference output from golden run
  --frames N,M,...     netlist: frames to extract instead of the checkpoints
`;

function main(argv: string[]): number {
  const { values, positionals } = parseArgs({
    args: argv,
    allowPositionals: true,
    options: {
      out: { type: 'string' },
      output: { type: 'string', short: 'o' },
      line: { type: 'string' },
      'frame-offset': { type: 'string' },
      latency: { type: 'string' },
      'rotate-frames': { type: 'string' },
      names: { type: 'string' },
      reference: { type: 'string' },
      frames: { type: 'string' },
      help: { type: 'boolean', short: 'h' },
    },
  });
  const [cmd, file] = positionals;
  if (values.help || !cmd || !file) {
    process.stdout.write(USAGE);
    return values.help ? 0 : 2;
  }
  if (cmd === 'compare') {
    if (!values.reference) throw new Error('compare requires --reference DIR');
    return compareRun(file, values.reference, values.output);
  }
  if (cmd === 'compare-ui') {
    if (!values.reference) throw new Error('compare-ui requires --reference DIR');
    return compareUi(file, values.reference, values.output ?? join(file, 'ui-compare.json'));
  }
  if (cmd === 'uart-decode') {
    const text = JSON.stringify(decodeUartCapture(file), null, 1) + '\n';
    if (values.output) writeFileSync(values.output, text);
    else process.stdout.write(text);
    return 0;
  }
  const scenario = JSON.parse(readFileSync(file, 'utf8')) as Scenario;
  const canonical = expandScenario(scenario);
  const int = (v: string | undefined, d: number) => (v === undefined ? d : Number.parseInt(v, 10));
  const emit = (text: string) => {
    if (values.output) writeFileSync(values.output, text);
    else process.stdout.write(text);
  };

  switch (cmd) {
    case 'expand':
      emit(JSON.stringify(canonical, null, 1) + '\n');
      return 0;
    case 'stim':
      emit(compileStim(canonical, { line: int(values.line, 10), frameOffset: int(values['frame-offset'], 0) }));
      return 0;
    case 'run': {
      const cfg = makeConfig({
        inputLatencyFrames: int(values.latency, DEFAULT_CONFIG.inputLatencyFrames),
        rotateFramesPerStep: int(values['rotate-frames'], 8),
      });
      const names: DumpNames = values.names
        ? { ...DEFAULT_DUMP_NAMES, ...JSON.parse(readFileSync(values.names, 'utf8')) }
        : DEFAULT_DUMP_NAMES;
      const outDir = values.out ?? join('out', scenario.name || basename(file, '.json'));
      mkdirSync(outDir, { recursive: true });
      const result = runScenario(canonical, cfg, names);
      const index = result.checkpoints.map((c, i) => {
        const stem = `${String(i).padStart(2, '0')}_${c.label.replace(/[^\w.-]+/g, '_')}`;
        writeFileSync(join(outDir, `${stem}.ram.json`), JSON.stringify(c.dumps, null, 1) + '\n');
        // Same layout as framescope's `run --dump`: dumps/<name>/frame_NNNN.json, one memory per file.
        for (const d of c.dumps) {
          const dir = join(outDir, 'dumps', d.name);
          mkdirSync(dir, { recursive: true });
          writeFileSync(join(dir, `frame_${String(d.frame).padStart(4, '0')}.json`), JSON.stringify(d) + '\n');
        }
        writeFileSync(join(outDir, `${stem}.state.json`), JSON.stringify(c.semantic, null, 1) + '\n');
        return {
          label: c.label, frame: c.frame, ram: `${stem}.ram.json`, state: `${stem}.state.json`,
          cells: c.semantic.cells.length, components: c.semantic.components.length,
        };
      });
      writeFileSync(
        join(outDir, 'checkpoints.json'),
        JSON.stringify({ scenario: canonical.name, frameCount: canonical.frameCount, config: cfg, names, checkpoints: index }, null, 1) + '\n',
      );
      process.stderr.write(`${canonical.name}: ${canonical.frameCount} frames, ${index.length} checkpoints -> ${outDir}\n`);
      for (const c of index) {
        process.stderr.write(`  ${c.label.padEnd(28)} frame ${String(c.frame).padStart(4)}  cells ${c.cells}  components ${c.components}\n`);
      }
      return 0;
    }
    case 'render': {
      const cfg = makeConfig({ inputLatencyFrames: int(values.latency, DEFAULT_CONFIG.inputLatencyFrames), rotateFramesPerStep: int(values['rotate-frames'], 8) });
      const outDir = values.out ?? join('out', canonical.name);
      renderReferences(canonical, outDir, cfg);
      process.stderr.write(`${canonical.name}: ${canonical.checkpoints.length} pixel checkpoints -> ${outDir}\n`);
      return 0;
    }
    case 'netlist': {
      const cfg = makeConfig({ inputLatencyFrames: int(values.latency, DEFAULT_CONFIG.inputLatencyFrames), rotateFramesPerStep: int(values['rotate-frames'], 8) });
      const outDir = values.out ?? join('out', canonical.name || basename(file, '.json'), 'netlist');
      const points = values.frames ? parseFrameList(values.frames) : canonical.checkpoints;
      const refs = netlistReferences(canonical, cfg, points);
      writeNetlistReferences(canonical, outDir, refs);
      process.stderr.write(`${canonical.name}: ${refs.length} netlists -> ${outDir}\n`);
      for (const r of refs) {
        const n = r.result.netlist;
        const tag = r.result.rejection ? `ER ${r.result.rejection.code.toString(16).toUpperCase()}` : `${n.elements.length} elements, ${n.nodeCount} nodes`;
        const issues = r.result.issues.map((x) => x.type).join(' ');
        process.stderr.write(`  ${r.label.padEnd(28)} frame ${String(r.frame).padStart(4)}  ${tag}${issues ? `  [${issues}]` : ''}\n`);
      }
      return 0;
    }
    default:
      process.stderr.write(`unknown command "${cmd}"\n${USAGE}`);
      return 2;
  }
}

process.exitCode = main(process.argv.slice(2));
