#!/usr/bin/env python3
"""Compare independent golden checkpoint states and pixels with RTL captures."""
import argparse
import datetime
import json
import os
from pathlib import Path
import subprocess
import sys


def decode_pixels(golden, framescope, actual, reference, output, index):
    """Attach semantic cell witnesses to failing pixel reports."""
    sys.path.insert(0, str(framescope / 'src'))
    from framescope import png
    raw_dir = output / 'decoded'
    raw_dir.mkdir()
    frames = []
    for checkpoint in index['checkpoints']:
        frame = checkpoint['frame']
        stem = f'frame_{frame:04d}'
        state = json.loads((reference / 'vga' / (stem + '.ui.json')).read_text())
        entry = {'frame': frame, 'panX': state['panX'], 'panY': state['panY'], 'mouse': state['prevMouse']}
        try:
            for key, directory in [('actualRaw', actual), ('referenceRaw', reference)]:
                img = png.read(directory / 'vga' / (stem + '.png'))
                rgba = bytearray(img.width * img.height * 4)
                rgb = b''.join(img.rows)
                rgba[0::4], rgba[1::4], rgba[2::4] = rgb[0::3], rgb[1::3], rgb[2::3]
                rgba[3::4] = b'\xff' * (img.width * img.height)
                path = raw_dir / (stem + '-' + key + '.rgba')
                path.write_bytes(rgba)
                entry[key] = str(path)
                entry['width'], entry['height'] = img.width, img.height
            frames.append(entry)
        except png.PngError as error:
            print(f'Decoder frame {frame}: {error}', file=sys.stderr)
    manifest = raw_dir / 'manifest.json'
    manifest.write_text(json.dumps({'frames': frames, 'assetsDir': str(golden / 'assets')}))
    return subprocess.run(['npx', 'tsx', 'tools/decode_pixels.ts', str(manifest), '-o', str(output / 'decoded-cells.json')], cwd=golden).returncode


def main():
    golden = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime', choices=['native', 'docker', 'auto'], default='native')
    parser.add_argument('--framescope', type=Path, default=golden.parent.parent / 'framescope')
    parser.add_argument('--out', type=Path)
    parser.add_argument('--scenario', type=Path, default=golden / 'scenarios/m2_full_ui.json')
    parser.add_argument('--actual', type=Path, help='compare an existing run instead of simulating again')
    parser.add_argument('--masks', type=Path, help='override the default full UI report regions')
    args = parser.parse_args()
    output = (args.out or golden / 'out/m2' / (datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d-%H%M%S') + '-' + args.runtime)).resolve()
    output.mkdir(parents=True, exist_ok=False)
    reference, stimulus = output / 'reference', output / 'stim.toml'
    actual = args.actual.resolve() if args.actual else output / 'rtl'
    npm = ['npm', 'run', 'golden', '--']
    scenario = args.scenario.resolve()
    for command in (['run', str(scenario), '--out', str(reference)], ['render', str(scenario), '--out', str(reference)], ['stim', str(scenario), '-o', str(stimulus)]):
        subprocess.run(npm + command, cwd=golden, check=True)
    index = json.loads((reference / 'checkpoints.json').read_text())
    checkpoints = ','.join(str(c['frame']) for c in index['checkpoints'])
    env = {**os.environ, 'METACIRCUIT': str(golden.parent)}
    fs = ['uv', 'run', 'framescope', '--runtime', args.runtime]
    if not args.actual:
        command = fs + ['run', '-c', 'examples/metacircuit', '-n', str(index['frameCount']), '-s', str(stimulus), '--save', checkpoints, '--dump', checkpoints, '-o', str(actual)]
        print(f"Simulating {index['frameCount']} frames; log: {output / 'simulation.log'}", flush=True)
        with (output / 'simulation.log').open('w') as log:
            simulation = subprocess.run(command, cwd=args.framescope.resolve(), env=env, stdout=log, stderr=subprocess.STDOUT)
        if simulation.returncode:
            print((output / 'simulation.log').read_text()[-8000:], file=sys.stderr)
            return simulation.returncode
    state = subprocess.run(npm + ['compare', str(actual), '--reference', str(reference), '-o', str(output / 'state-compare.json')], cwd=golden)
    ui = subprocess.run(npm + ['compare-ui', str(actual), '--reference', str(reference), '-o', str(output / 'ui-compare.json')], cwd=golden)
    masks = (args.masks or golden / 'masks/m2_ui.toml').resolve()
    with (output / 'pixel-compare.log').open('w') as log:
        pixels = subprocess.run(fs + ['compare', str(actual), str(reference), '-m', str(masks), '-o', str(output / 'pixels')], cwd=args.framescope.resolve(), stdout=log, stderr=subprocess.STDOUT)
    pixel_result = json.loads((output / 'pixels/compare.json').read_text()) if (output / 'pixels/compare.json').exists() else None
    if pixels.returncode and (golden / 'tools/decode_pixels.ts').exists():
        decode_pixels(golden, args.framescope.resolve(), actual, reference, output, index)
    result = {'ok': state.returncode == 0 and ui.returncode == 0 and pixels.returncode == 0, 'scenario': index['scenario'], 'runtime': args.runtime,
              'frameCount': index['frameCount'], 'checkpoints': len(index['checkpoints']), 'actual': str(actual), 'reference': str(reference),
              'state': json.loads((output / 'state-compare.json').read_text()), 'ui': json.loads((output / 'ui-compare.json').read_text()), 'pixels': pixel_result}
    (output / 'summary.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'ok': result['ok'], 'pixels': pixel_result['summary'] if pixel_result else None, 'summary': str(output / 'summary.json')}, indent=2))
    return 0 if result['ok'] else 1


if __name__ == '__main__':
    sys.exit(main())
