#!/usr/bin/env bash
# OpenGL for the PS4: Mesa's Zink (OpenGL on Vulkan) on RADV, statically linked. The Mesa is SSBU's (Crema's PS4 Mesa,
# the GNM layer src/amd/common/ac_ps4_drm.c, with the shader cache on) plus patches/mesa-opence.patch (Zink's PS4
# loader and swapchain, the PS4 frontend src/gallium/frontends/ps4), cloned to ~/opence-build/src/mesa and built as
# the static libraries the eboot links (ps4/CMakeLists.txt: opence_link_mesa) in ~/opence-build/build/mesa-zink.
#   scripts/build-mesa.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PSB="${PSB:-$HOME/opence-build}"
SSBU_MESA="${SSBU_MESA:-$HOME/ssbu-build/src/mesa}"
# the shader cache's identity (RADV's and Zink's): a build whose shader code differs needs a new id
BUILD_ID=0c4e5a1b9d3f7e2a6c8b0d4f1e3a5c7b9d2f4e6a
SRC="$PSB/src/mesa"
B="$PSB/build/mesa-zink"
# meson and mako from Crema's venv, glslangValidator (Mesa's built-in shaders)
export PATH="$PSB/host-tools/bin:$HOME/cemups4-build/mesa-venv/bin:$PATH"
[ -x "$PSB/host-tools/bin/glslangValidator" ] || cp "$HOME/cemups4-build/host-tools/bin/glslangValidator" "$PSB/host-tools/bin/"
mkdir -p "$PSB/logs"

if [ ! -d "$SRC/.git" ]; then
    git clone -q "$SSBU_MESA" "$SRC"
    git -C "$SRC" checkout -q -b opence origin/ps4
    git -C "$SRC" tag opence-base
    if [ -f "$HERE/../patches/mesa-opence.patch" ]; then
        git -C "$SRC" -c user.name=opence -c user.email=opence@localhost am -q "$HERE/../patches/mesa-opence.patch"
    fi
fi
# Crema's cross file with the system's lld (PacBrew's needs a libxml2 this Ubuntu no longer has; only meson's
# checks link anything: Mesa is built as static libraries)
sed 's#-fuse-ld=/opt/pacbrew/ps4/openorbis/bin/ld.lld#-fuse-ld=/usr/bin/ld.lld-21#g' \
    "$HOME/cemups4-build/mesa-ps4-cross.ini" > "$PSB/mesa-ps4-cross.ini"
if [ ! -f "$B/build.ninja" ]; then
    meson setup "$B" "$SRC" -Dbuildtype=release -Db_ndebug=true -Ddefault_library=static -Dvulkan-drivers=amd \
        -Dgallium-drivers=zink -Dplatforms= -Dllvm=disabled -Damd-use-llvm=false -Dopengl=true -Dgles1=disabled \
        -Dgles2=enabled -Dglx=disabled -Degl=disabled -Dgbm=disabled -Dglvnd=disabled -Dzstd=disabled \
        -Dexpat=disabled -Dxmlconfig=disabled -Dvalgrind=disabled -Dlibunwind=disabled -Dlmsensors=disabled \
        -Dbuild-tests=false -Dshader-cache=enabled -Dvulkan-layers= -Dtools= -Dvideo-codecs= \
        -Dspirv-tools=disabled -Dperfetto=false -Dselinux=false -Dgallium-va=disabled -Dgallium-rusticl=false \
        -Dgallium-extra-hud=false -Dps4-gl=true -Dradv-build-id=$BUILD_ID --cross-file="$PSB/mesa-ps4-cross.ini" \
        > "$PSB/logs/mesa-zink-setup.log" 2>&1 || { tail -30 "$PSB/logs/mesa-zink-setup.log"; exit 1; }
fi
# the libraries only (Mesa's tools do not link for the PS4)
LIBS=(
    src/gallium/frontends/ps4/libps4gl.a
    src/gallium/drivers/zink/libzink.a src/gallium/auxiliary/libgallium.a src/mesa/libmesa.a
    src/mesa/libmesa_sse41.a src/mesa/glapi/glapi/libglapi_bridge.a src/mesa/glapi/shared-glapi/libglapi.a src/compiler/glsl/libglsl.a src/compiler/glsl/glcpp/libglcpp.a
    src/amd/vulkan/libvulkan_radeon.a src/amd/common/libamd_common.a src/amd/compiler/libaco.a
    src/amd/addrlib/libaddrlib.a src/vulkan/util/libvulkan_util.a src/vulkan/runtime/libvulkan_lite_runtime.a
    src/compiler/spirv/libvtn.a src/compiler/nir/libnir.a src/compiler/libcompiler.a
    src/util/libmesa_util.a src/util/libmesa_util_simd.a src/util/libmesa_util_clflush.a
    src/util/libmesa_util_clflushopt.a src/util/libparson.a src/util/libxmlconfig.a src/util/blake3/libblake3.a
    src/c11/impl/libmesa_util_c11.a
)
# (the target list in a file first: grep -q closing the pipe early would fail it under pipefail)
ninja -C "$B" -t targets all 2>/dev/null | cut -d: -f1 > "$B/.targets"
avail=()
for l in "${LIBS[@]}"; do
    if grep -qx "$l" "$B/.targets"; then avail+=("$l"); else echo "(no target $l)"; fi
done
ninja -C "$B" "${avail[@]}"
# the patch, kept with the port
git -C "$SRC" format-patch -q --stdout opence-base > "$HERE/../patches/mesa-opence.patch"
echo "mesa-opence.patch: $(grep -c '^From ' "$HERE/../patches/mesa-opence.patch") commits on SSBU's Mesa"
