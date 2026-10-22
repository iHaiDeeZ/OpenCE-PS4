# OpenCE PS4: FAQ

Answers to the questions and problems players run into. If yours isn't here,
[open an issue](https://github.com/iHaiDeeZ/OpenCE-PS4/issues).

- [Installing and updating](#installing-and-updating)
- [The game's files](#the-games-files)
- [Speed and stutter](#speed-and-stutter)
- [Crashes, freezes and bug reports](#crashes-freezes-and-bug-reports)

## Installing and updating

**What do I need?**
A jailbroken PS4 with **GoldHEN**, an FTP connection to it (GoldHEN's FTP server on port 2121, with
an FTP client such as FileZilla), and your own copy of Halo: Combat Evolved for the original Xbox.

**Where's the download?**
There isn't one. The package is built from this repository ([Building](docs/BUILDING.md)), and a
package with the maps inside can't be shared.

**How do I install it?**
Copy `OpenCE-vXX.YY.pkg` to the PS4 (a USB drive, or FTP to `/data/pkg`), install it with GoldHEN's
**Package Installer**, then start **Halo: Combat Evolved** from the home screen.

**How do I update?**
Install the newer package on top of the old one. Everything in `/data/OpenCE/` stays.

## The game's files

**Which version of the game?**
The original Xbox release. The retail NTSC 1.0 maps (build 01.10.12.2276) are the ones tested.

**Where do the maps go?**
Either inside the package (the build script does it), or the 24 `.map` files in
`/data/OpenCE/maps/`, or your disc image (`.iso` / `.xiso`) in `/data/OpenCE/`, which the game
extracts at its first start.

**I put the maps in a package and also in `/data/OpenCE/maps`.**
The package's maps are used; the copy in `/data` can be deleted to free 1.8 GB.

**Where are my saves?**
In `/data/OpenCE/save`. Back them up over FTP if you like.

## Speed and stutter

**It hitches the first time I play a level.**
Shaders are compiled the first time they're needed, then kept in `/data/OpenCE/mesa`. The next
time is smoother.

**It slows down in big fights.**
Busy scenes cost the PS4's CPU most. On a PS4 Pro, turn on **Boost Mode** in the PS4's settings.

**It hitches at checkpoints.**
v00.04 writes checkpoints in the background. If it still hitches, send `opence.log`: `slow:` lines
show the file operations that took long.

## Crashes, freezes and bug reports

**The game closes.**
Look for `/data/OpenCE/crash.log` and attach it to an issue with `opence.log`, `boot-trace.log` and
`debug.txt`.

**How do I report a bug?**
[Open an issue](https://github.com/iHaiDeeZ/OpenCE-PS4/issues) with those logs, the version, where
in the game it happened, your PS4 model and firmware.
