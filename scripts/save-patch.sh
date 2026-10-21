#!/usr/bin/env bash
# Commits the PS4 work in the OpenCE checkout (branch ps4) and exports it as patches/opence-ps4.patch against
# upstream's commit in patches/BASE.txt, and the PS4 Mesa's as patches/mesa-opence.patch.
#   save-patch.sh "<commit message>"
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
MSG="${1:-PS4 port work}"
SRC="${OPENCE_SRC:-$HOME/opence-build/src/OpenCE}"
MESA="$HOME/opence-build/src/mesa"
BASE="$(head -1 "$HERE/../patches/BASE.txt")"
git -C "$SRC" add -A configure.py port source tools
git -C "$SRC" diff --cached --quiet || git -C "$SRC" commit -qm "$MSG"
git -C "$SRC" diff "$BASE" ps4 > "$HERE/../patches/opence-ps4.patch"
echo "opence-ps4.patch: $(wc -l < "$HERE/../patches/opence-ps4.patch") lines against $(git -C "$SRC" rev-parse --short "$BASE")"
if [ -d "$MESA/.git" ]; then
    git -C "$MESA" add -A
    git -C "$MESA" diff --cached --quiet || git -C "$MESA" commit -qm "$MSG"
    git -C "$MESA" format-patch -q --stdout opence-base > "$HERE/../patches/mesa-opence.patch"
    echo "mesa-opence.patch: $(grep -c '^From ' "$HERE/../patches/mesa-opence.patch") commits on SSBU's Mesa"
fi
