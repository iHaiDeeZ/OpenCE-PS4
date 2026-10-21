#!/usr/bin/env bash
# Upstream OpenCE at patches/BASE.txt into ~/opence-build/src/OpenCE, with the PS4 port (patches/opence-ps4.patch)
# committed on a branch ps4. Then scripts/build-mesa.sh and scripts/build-opence.sh.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PSB="${PSB:-$HOME/opence-build}"
SRC="$PSB/src/OpenCE"
BASE="$(head -1 "$HERE/../patches/BASE.txt")"
mkdir -p "$PSB/src"
[ -d "$SRC/.git" ] || git clone -q https://github.com/OpenCommunityEdition/OpenCE.git "$SRC"
git -C "$SRC" fetch -q origin
if ! git -C "$SRC" rev-parse --verify -q ps4 > /dev/null; then
    git -C "$SRC" checkout -q -b ps4 "$BASE"
    git -C "$SRC" apply "$HERE/../patches/opence-ps4.patch"
    git -C "$SRC" add -A
    git -C "$SRC" -c user.name=opence -c user.email=opence@localhost commit -qm "PS4 port (patches/opence-ps4.patch)"
fi
git -C "$SRC" log --oneline -1
