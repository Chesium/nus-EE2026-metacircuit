import { readFileSync, writeFileSync } from 'node:fs';
import { parseArgs } from 'node:util';
import { generateDirectedStress, generateStress, scenarioFromBlocks, type DirectedCorpus, type StressCase } from '../scenario/stress.ts';

const { values } = parseArgs({ options: {
  seed: { type: 'string', default: '1' }, operations: { type: 'string', default: '16' },
  out: { type: 'string' }, version: { type: 'string', default: '1' }, source: { type: 'string' }, keep: { type: 'string' },
  directed: { type: 'string' },
} });
let result: StressCase;
if (values.source) {
  const original = JSON.parse(readFileSync(values.source, 'utf8')) as StressCase;
  const indices = (values.keep ?? '').split(',').filter(Boolean).map(Number);
  if (indices.some((i) => !Number.isInteger(i) || i < 0 || i >= original.blocks.length)) throw new Error('invalid kept block');
  const blocks = indices.map((i) => original.blocks[i]!);
  result = { ...original, blocks, scenario: scenarioFromBlocks(original.seed, blocks, original.version) };
} else result = values.directed
  ? generateDirectedStress(Number(values.seed), values.directed as DirectedCorpus)
  : generateStress(Number(values.seed), Number(values.operations), Number(values.version) as 1 | 2);
if (!values.out) throw new Error('--out is required');
writeFileSync(values.out, JSON.stringify(result, null, 2) + '\n');
writeFileSync(values.out.replace(/\.json$/, '') + '.scenario.json', JSON.stringify(result.scenario, null, 2) + '\n');
