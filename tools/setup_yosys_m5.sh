#!/usr/bin/env bash
# Unpack the pinned Ubuntu Yosys used by the M5 formal checks into a per-user cache
# (no root needed). The proof tools find it via METACIRCUIT_YOSYS, this cache or PATH.
set -euo pipefail
version=0.33-5build2
dir="${METACIRCUIT_TOOLS_CACHE:-$HOME/.cache/metacircuit-m5}/yosys-0.33"
mkdir -p "$dir"
cd "$dir"
[ -f "yosys_${version}_amd64.deb" ] || apt-get download "yosys=${version}"
rm -rf extracted
dpkg -x "yosys_${version}_amd64.deb" extracted
extracted/usr/bin/yosys -V
echo "$dir/extracted/usr/bin/yosys"
