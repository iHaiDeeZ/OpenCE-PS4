#!/usr/bin/env bash
# OpenCE for the PS4: the guest image (the game as x32 code: `ninja ps4` in the OpenCE checkout, branch ps4 =
# patches/opence-ps4.patch) and the eboot (ps4/CMakeLists.txt: the host, Mesa's Zink on RADV, the PS4 layer),
# packaged as OPCE00001.
#   OPENCE_VERSION=00.01 scripts/build-opence.sh        -> out/OpenCE-v00.01.pkg
#   OPENCE_DEBUG=1: the game's debug build (its assertions checked, stopping at the first that fails)
# The game data is not in the package: the maps come from the player's own disc image, in /data/OpenCE.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/ps4-env.sh"
VERSION="${OPENCE_VERSION:?OPENCE_VERSION=XX.YY}"
SRC="$PS4_BUILD_ROOT/src/OpenCE"
MESA="$PS4_BUILD_ROOT/src/mesa"
MESA_BUILD="$PS4_BUILD_ROOT/build/mesa-zink"
BUILD="$PS4_BUILD_ROOT/build/eboot"
[ -f "$MESA_BUILD/src/gallium/frontends/ps4/libps4gl.a" ] || { echo "build Mesa first: scripts/build-mesa.sh" >&2; exit 1; }

# the guest image (and the host's generated sources)
RELEASE="--release"
[ "${OPENCE_DEBUG:-0}" = 1 ] && RELEASE=""
( cd "$SRC" && python3 configure.py $RELEASE --ps4-gl-include "$MESA/include" --ps4-guest-cc clang-21 \
    --ps4-guest-ld ld.lld-21 --ps4-guest-ar llvm-ar-21 > "$PS4_BUILD_ROOT/logs/configure.log" 2>&1 )
rm -f "$SRC/build/ps4/halo_guest.elf"   # (a failed link must not be packaged)
ninja -C "$SRC" ps4
[ -f "$SRC/build/ps4/halo_guest.elf" ] || { echo "no guest image" >&2; exit 1; }

# the eboot
ps4_cmake -S "$HERE/../ps4" -B "$BUILD" -G Ninja \
    -DCMAKE_TOOLCHAIN_FILE="$HERE/../toolchain/ps4-opence.cmake" \
    "-DCMAKE_PROJECT_opence_INCLUDE=$HERE/../toolchain/ps4-love-style.cmake" \
    -DPS4_PAID="${PS4_PAID:-0x3800000000000035}" -DPS4_MESA_BUILD="$MESA_BUILD" \
    -DOPENCE_SRC="$SRC" -DMESA_SRC="$MESA" -DOPENCE_VERSION="$VERSION" > /dev/null
rm -f "$BUILD/eboot_eboot/eboot.bin" "$BUILD/eboot"   # (a failed link must not be packaged)
ninja -C "$BUILD"
EBOOT="$BUILD/eboot_eboot/eboot.bin"
[ -f "$EBOOT" ] || { echo "no eboot.bin" >&2; exit 1; }
llvm-size-21 "$BUILD/eboot" || true

STAGE="$PS4_BUILD_ROOT/build/opence-stage"
rm -rf "$STAGE"
mkdir -p "$STAGE/sce_sys"
cp "$EBOOT" "$STAGE/eboot.bin"
cp "$SRC/build/ps4/halo_guest.elf" "$STAGE/halo_guest.elf"
cp "$SRC/build/ps4/brokers.txt" "$STAGE/brokers.txt"
python3 "$HERE/make-art.py" "$SRC/port/assets/icon/opence-icon-render.png" "$STAGE/sce_sys"
echo "$VERSION" > "$STAGE/version.txt"
find "$STAGE" -type d -empty -delete
PKG="$(SFO_STYLE=plain NO_RIGHT_SPRX=1 DOLPHIN_PS4_MODULES_DIR=/nonexistent "$HERE/make-pkg.sh" "$STAGE" OPCE00001 "OpenCE" "$VERSION" OPENCEPS4 "$PS4_BUILD_ROOT/out" | tail -1)"
mkdir -p "$HERE/../out" "$PS4_BUILD_ROOT/oelf"
NAME="OpenCE-v$VERSION.pkg"
cp "$PKG" "$HERE/../out/$NAME"
# for symbolizing crash reports: the eboot (host addresses) and the guest image (the game's)
cp "$BUILD/eboot_eboot/eboot.oelf" "$PS4_BUILD_ROOT/oelf/v$VERSION.oelf"
cp "$BUILD/eboot" "$PS4_BUILD_ROOT/oelf/v$VERSION.elf"
cp "$SRC/build/ps4/halo_guest.elf" "$PS4_BUILD_ROOT/oelf/v$VERSION.guest.elf"
ls -la "$HERE/../out/$NAME"
echo "now, from Windows (Git Bash): scripts/upload-to-console.sh out/$NAME"
