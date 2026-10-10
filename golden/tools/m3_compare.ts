import { readFileSync } from 'node:fs';
import { compareBackend, type M3Scenario } from '../src/cli/compare-backend.ts';
const [scenario, actual, output] = process.argv.slice(2);
const result = compareBackend(JSON.parse(readFileSync(scenario!, 'utf8')) as M3Scenario, actual!, output!);
console.log(JSON.stringify(result, null, 2));
process.exitCode = result.ok ? 0 : 1;
