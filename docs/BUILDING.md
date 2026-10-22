# OpenCE PS4: how it works and how to build it

## How it works

OpenCE's game data (the maps, the saved games) holds 32-bit pointers, so the game has to run as
ILP32 code. OpenCE's Android port already does this with AArch64 code in a 64-bit app; this port
does the same on the PS4's x86-64:

- **The guest** is the game, OpenCE's platform layer and a small runtime, compiled by clang as
  **x32** code (64-bit instructions, 32-bit pointers, `x86_64-linux-gnux32`) with musl as its C
  library, and linked into a static image at 0x88000000, right above the Xbox memory window at
  0x80000000 (`ninja ps4` in the OpenCE checkout: `tools/ps4_build.py`). The Android port's guest
  runtime is shared as it is. It's built with OpenCE's profile-guided optimisation profile (clang 22).
- **The host** is the eboot (`port/ps4/host` in the checkout, [`ps4/CMakeLists.txt`](../ps4/CMakeLists.txt)
  here): it maps the window and the image below 4 GB (direct memory; the code in executable system
  flexible memory), runs the game's threads on stacks there, and answers its imports: Linux system
  calls translated to the PS4's FreeBSD kernel (files, clocks, futexes as condition variables; large
  writes on a thread of their own), the DualShock 4s (ScePad, one per signed-in user, up to four),
  sound (sceAudioOut), and OpenGL ES.
- **OpenGL ES** is Mesa's **Zink** (OpenGL on Vulkan) on the PS4's **RADV** (Crema's GNM Mesa, as the
  SMW and SSBU ports use), with a small PS4 frontend (`src/gallium/frontends/ps4`) and a Zink
  swapchain on a headless surface that the PS4 Vulkan window system puts on VideoOut
  ([`patches/mesa-opence.patch`](../patches/mesa-opence.patch)). Gallium's threaded context and
  glthread run on the PS4's spare cores. OpenCE's renderer (`d3d8_gl.c`, its OpenGL ES path, as on
  Android) runs unchanged.

## Building

In WSL Ubuntu, with the PS4 toolchain of the SMW/SSBU ports in place (`~/ssbu-build`), and clang 22
(`clang-22`, `ld.lld-22`, `llvm-ar-22`) for the guest:

```
scripts/seed-build-tree.sh        # ~/opence-build from SSBU's tree (sysroot, PkgTool), ~/opence -> this repo
scripts/clone-opence.sh           # OpenCE at patches/BASE.txt, branch ps4 = patches/opence-ps4.patch
scripts/build-mesa.sh             # Mesa with Zink and the PS4 GL frontend (patches/mesa-opence.patch)
OPENCE_VERSION=00.04 scripts/build-opence.sh   # the guest image, the eboot, out/OpenCE-v00.04.pkg
scripts/save-patch.sh "message"   # commit the checkouts and refresh the patches
```

**The maps:** `build-opence.sh` puts the maps of your own copy in the package (`OPENCE_MAPS`,
default `/mnt/e/OpenCE-data/Halo - Combat Evolved/maps`; set it empty to leave them out). Such a
package is yours alone: never share it. Without them, the game reads `/data/OpenCE/maps`.

**The home screen art:** `scripts/make-art.py` draws the icon and background from the Halo logo in
your own `ui.map` and a background picture (`art/background.png`, from a capture of your own), or
falls back to OpenCE's icon. `art/` is ignored by git.

**Uploading** from Windows (Git Bash): `scripts/upload-to-console.sh out/OpenCE-vXX.YY.pkg`.

Title ID `OPCE00001`.

## Debugging

- `scripts/crashlog.sh` fetches `crash.log`. Host addresses (the `elf` column, rip − 0x400000)
  symbolize against `~/opence-build/oelf/vXX.YY.elf`, guest addresses as they are against
  `vXX.YY.guest.elf`.
- `/data/OpenCE/env.txt` sets environment variables before anything starts (Mesa options such as
  `mesa_glthread=false`, `GALLIUM_THREAD=0`, `ZINK_DEBUG=...`).
- `opence.log` has `hitch: frame N took X ms (c shaders compiled, l programs linked)` for frames of
  50 ms and more, and `slow: system call N ... took X ms` for system calls of 30 ms and more.
