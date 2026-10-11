"""Locate external tools used by the M5 formal checks."""
import os
from pathlib import Path
import shutil

CACHED_YOSYS = (Path(os.environ.get('METACIRCUIT_TOOLS_CACHE', Path.home() / '.cache/metacircuit-m5'))
                / 'yosys-0.33/extracted/usr/bin/yosys')


def yosys():
    """METACIRCUIT_YOSYS, then the tools/setup_yosys_m5.sh cache, then PATH."""
    if os.environ.get('METACIRCUIT_YOSYS'):
        return os.environ['METACIRCUIT_YOSYS']
    if CACHED_YOSYS.is_file():
        return str(CACHED_YOSYS)
    return shutil.which('yosys') or str(CACHED_YOSYS)
