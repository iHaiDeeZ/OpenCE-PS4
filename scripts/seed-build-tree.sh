#!/usr/bin/env bash
# One-time: create ~/opence-build from copies of SSBU's build tree (~/ssbu-build, itself seeded from SMW's): the
# libc++ 21 sysroot with the libc overlay, the fixed PkgTool and the .NET SDK it runs on, and a clone of SSBU's PS4
# Mesa (Crema's GNM RADV with the shader cache on) that scripts/build-mesa.sh builds with Zink and OpenGL. This port
# never writes into ~/ssbu-build. Then ~/opence -> this repo.
set -euo pipefail
SSBU="${SSBU:-$HOME/ssbu-build}"
PSB="${PSB:-$HOME/opence-build}"
mkdir -p "$PSB/src" "$PSB/build" "$PSB/out" "$PSB/logs" "$PSB/oelf" "$PSB/third_party" "$PSB/tools" "$PSB/host-tools/bin"
[ -d "$PSB/sysroot" ] || cp -a "$SSBU/sysroot" "$PSB/sysroot"
[ -d "$PSB/host-compat" ] || cp -a "$SSBU/host-compat" "$PSB/host-compat"
PSB="$PSB" bash "$(dirname "$0")/../toolchain/opence-overlay.sh"
[ -d "$PSB/tools/pkgtool-fixed" ] || cp -a "$SSBU/tools/pkgtool-fixed" "$PSB/tools/pkgtool-fixed"
[ -d "$PSB/tools/dotnet" ] || cp -a "$SSBU/tools/dotnet" "$PSB/tools/dotnet"
# Space-free path to this repo: toolchain flags (linker script paths) break on "PS4 Projects".
REPO="$(cd "$(dirname "$0")/.." && pwd)"
[ -e "$HOME/opence" ] || ln -s "$REPO" "$HOME/opence"
du -sh "$PSB"/* 2>/dev/null
