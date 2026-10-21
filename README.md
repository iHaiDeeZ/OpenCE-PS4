# OpenCE for PS4

[OpenCE](https://github.com/OpenCommunityEdition/OpenCE), the open source port of the Halo: Combat Evolved
decompilation, for jailbroken PS4 consoles (GoldHEN), built the way the SMW port is: the PS4 runtime, toolchain and
Mesa RADV of SMW/SSBU, a package with its own home screen art, logs and crash reports in `/data/OpenCE`.

**Status: v00.01, the first build, untested on a console.** Everything compiles, links and packages; nothing has run
on a PS4 yet.

## How it works

OpenCE's game data (the maps, the saved games) holds 32-bit pointers, so the game has to run as ILP32 code. OpenCE's
Android port already does this with AArch64 code in a 64-bit app; this port does the same on the PS4's x86-64:

- **The guest** is the game, OpenCE's platform layer and a small runtime, compiled by clang as **x32** code (64-bit
  instructions, 32-bit pointers, `x86_64-linux-gnux32`) with musl as its C library, and linked into a static image
  at 0x88000000, right above the Xbox memory window at 0x80000000 (`ninja ps4` in the OpenCE checkout:
  `tools/ps4_build.py`). The Android port's guest runtime is shared as it is.
- **The host** is the eboot (`port/ps4/host` in the checkout, `ps4/CMakeLists.txt` here): it maps the window and the
  image below 4 GB (direct memory; the code in executable system flexible memory), runs the game's threads on stacks
  there, and answers its imports: Linux system calls translated to the PS4's FreeBSD kernel (files, clocks,
  futexes as condition variables), the DualShock 4s (ScePad, one per signed-in user, up to four), sound
  (sceAudioOut), and OpenGL ES.
- **OpenGL ES** is Mesa's **Zink** (OpenGL on Vulkan) on the PS4's **RADV** (Crema's GNM Mesa, as SMW and SSBU use),
  with a small PS4 frontend (`src/gallium/frontends/ps4`) and a Zink swapchain on a headless surface that SSBU's
  Vulkan window system puts on VideoOut (`patches/mesa-opence.patch`). OpenCE's renderer (`d3d8_gl.c`, its OpenGL ES
  path, as on Android) runs unchanged.

## On the console

| Path | What |
|---|---|
| `/data/OpenCE` | the game data: `maps/` (from your disc image), `config.toml` (the settings), `debug.txt` (the game's log) |
| `/data/OpenCE/save` | saved games and profiles |
| `/data/OpenCE` | `opence.log` (the PS4 host's log), `boot-trace.log`, `crash.log`, `mesa/` (the shader cache) |

Title ID `OPCE00001`. Install `out/OpenCE-vXX.YY.pkg` with GoldHEN's Package Installer.

**The game data:** put your own Xbox disc image of Halo: Combat Evolved (`.iso` or `.xiso`, any version) in
`/data/OpenCE` over FTP. At the first start the game extracts its `maps` folder from it (about 1.8 GB); the image can
be deleted afterwards. Nothing of the game's data is in the package.

## Controls

The DualShock 4's buttons are the Xbox controller's at the same places (Cross = A, Circle = B, Square = X,
Triangle = Y, L1 = white, R1 = black, L2/R2 = the triggers, OPTIONS = start, the touchpad's click = back). Every
player signed in on the console has their own controller (split screen up to four).

## Building

In WSL Ubuntu, with the PS4 toolchain of the SMW/SSBU ports in place (`~/ssbu-build`):

```
scripts/seed-build-tree.sh        # ~/opence-build from SSBU's tree (sysroot, PkgTool), ~/opence -> this repo
scripts/clone-opence.sh           # OpenCE at patches/BASE.txt, branch ps4 = patches/opence-ps4.patch
scripts/build-mesa.sh             # Mesa with Zink and the PS4 GL frontend (patches/mesa-opence.patch)
OPENCE_VERSION=00.01 scripts/build-opence.sh   # the guest image, the eboot, out/OpenCE-v00.01.pkg
scripts/save-patch.sh "message"   # commit the checkouts and refresh the patches
```

Upload from Windows (Git Bash): `scripts/upload-to-console.sh out/OpenCE-vXX.YY.pkg`.

## Licence

OpenCE is AGPL-3.0-or-later, and so is this port's change to it (`patches/opence-ps4.patch`) and this repository
([LICENSE](LICENSE)). The PS4 runtime in `port/` and the toolchain scripts come from the SMW, SSBU and Crema ports;
`port/mesa/ac_ps4_drm.c` and `patches/mesa-opence.patch` are Mesa's licence (MIT); `port/third_party` keeps its own
notices. No game data, Microsoft or Sony files are included.
