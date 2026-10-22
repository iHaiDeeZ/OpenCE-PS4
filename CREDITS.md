# Credits

A big thank-you to everyone whose work made OpenCE PS4 possible.

## The port

**ShiroKlein** brought OpenCE to the PS4: the x32 guest, the PS4 host that runs it, OpenGL ES
through Zink on the PS4's GPU, the DualShock 4 support, the packaging and all the testing on real
hardware.

## OpenCE

At the heart of this app is **[OpenCE](https://github.com/OpenCommunityEdition/OpenCE)**, Halo:
Combat Evolved for the original Xbox decompiled and ported to Windows, Linux and Android, licensed
AGPL-3.0. The PS4 version is OpenCE at commit `9662f0f6cb60746444bee9549e4271e387fdc659` plus
[`patches/opence-ps4.patch`](patches/opence-ps4.patch).

Its contributors as GitHub lists them, most active first. More appear in the
[complete contributor graph](https://github.com/OpenCommunityEdition/OpenCE/graphs/contributors).

[cybersecurity](https://github.com/cybersecurity) · [jonas](https://github.com/jonas) · [MrMilenko](https://github.com/MrMilenko) · [xshxdex98](https://github.com/xshxdex98) · [punpckhdq](https://github.com/punpckhdq) · [bnunu](https://github.com/bnunu) · [eltanschauung](https://github.com/eltanschauung) · [startupfoundry](https://github.com/startupfoundry) · [innerhat-dev](https://github.com/innerhat-dev) · [HiIAmMoot](https://github.com/HiIAmMoot) · [hkmodd](https://github.com/hkmodd) · [Berthalamew](https://github.com/Berthalamew) · [addisonbair](https://github.com/addisonbair) · [chestahh](https://github.com/chestahh) · [saulob](https://github.com/saulob) · [thelinkin3000](https://github.com/thelinkin3000) · [RockBooch13624](https://github.com/RockBooch13624) · [BirchWoodGod](https://github.com/BirchWoodGod) · [Tyberious](https://github.com/Tyberious) · [jcompto95-tech](https://github.com/jcompto95-tech) · [HaydnTrigg](https://github.com/HaydnTrigg) · [Englis666](https://github.com/Englis666) · [FDervish](https://github.com/FDervish) · [LWSS](https://github.com/LWSS) · [ficool2](https://github.com/ficool2) · [WhiteI3ulL](https://github.com/WhiteI3ulL) · [kirklandsig](https://github.com/kirklandsig) · [bfenty](https://github.com/bfenty) · [meowsandstuff](https://github.com/meowsandstuff) · [medic-code](https://github.com/medic-code) · [TwistedFlog](https://github.com/TwistedFlog) · [mweekley](https://github.com/mweekley) · [johncranston303](https://github.com/johncranston303) · [GuvenHuso](https://github.com/GuvenHuso) · [FractumSeraph](https://github.com/FractumSeraph) · [FernandolDev](https://github.com/FernandolDev) · [pastudan](https://github.com/pastudan) · [lukerb52](https://github.com/lukerb52) · [bmanturner](https://github.com/bmanturner) · [neopetal](https://github.com/neopetal)

## The PS4 ports

The PS4 runtime (`port/`), the toolchain and the packaging scripts come from the author's
**[SMW](https://github.com/iHaiDeeZ/SMW)**, SSBU and **[Crema](https://github.com/iHaiDeeZ/Crema)**
ports, as does the Mesa back end for the PS4's GPU.

## Libraries and tools

| Project | Used for | Licence |
|---|---|---|
| [Mesa](https://mesa3d.org) (Zink, RADV) | OpenGL ES on Vulkan, and the Vulkan driver, built for the PS4 with a GNM back end ([`port/mesa`](port/mesa), [`patches/mesa-opence.patch`](patches/mesa-opence.patch), Mesa 26.0.8) | MIT and per-file |
| [musl](https://musl.libc.org) | The guest's C library | MIT |
| [dlmalloc](https://gee.cs.oswego.edu/dl/html/malloc.html) by Doug Lea | The PS4 side's memory allocator ([`port/third_party/dlmalloc`](port/third_party/dlmalloc)) | CC0 |
| [zlib](https://zlib.net) | Compression | zlib |
| [Mbed TLS](https://www.trustedfirmware.org/projects/mbed-tls/) and [miniupnpc](https://miniupnp.tuxfamily.org) | OpenCE's networking code, as OpenCE uses them | Apache-2.0 / BSD-3-Clause |
| [OpenOrbis PS4 Toolchain](https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain) | PS4 headers, libraries and `create-fself` | GPL-3.0 (tools) |
| [LLVM](https://llvm.org) (clang, lld) | Building the guest and the eboot | Apache-2.0 with LLVM exception |
| [love-ps4](https://github.com/Mari0/love-ps4) | The reference PS4 setup | MIT |

## Trademarks

Halo and Xbox are trademarks of Microsoft. PlayStation and PS4 are trademarks of Sony Interactive
Entertainment. This project has no ties to either, nor to Bungie, Halo Studios or the OpenCE
project.
