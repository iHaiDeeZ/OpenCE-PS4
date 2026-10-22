#!/usr/bin/env python3
"""OpenCE's home screen art: sce_sys/icon0.png (512x512) and sce_sys/pic1.png (1920x1080).

Made from art/ (not in the repository: it is your game's): art/halo_logo.png, the HALO logo of your own ui.map
(ui\\shell\\main_menu\\halo_logo, 1024x256 DXT5: scripts/make-art.py --logo <ui.map> extracts it), and
art/background.png, a 1920x1080 picture of the game (a frame of your own PS4 clip). Without them it falls back to
OpenCE's own icon (port/assets/icon/opence-icon-render.png in the checkout).

Usage: python3 scripts/make-art.py <art dir> [out dir, default sce_sys]
       python3 scripts/make-art.py --logo <ui.map> <art dir>
"""
import os
import struct
import sys
import zlib

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

FONT_LIGHT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
CHECKOUT_ICON = os.path.expanduser("~/opence-build/src/OpenCE/port/assets/icon/opence-icon-render.png")


def extract_logo(ui_map, art):
    """the HALO logo out of an Xbox ui.map (cache version 5, zlib after the 2 KB header)"""
    raw = open(ui_map, "rb").read()
    data = raw[:0x800] + zlib.decompress(raw[0x800:])
    tag_offset = struct.unpack_from("<I", data, 0x10)[0]
    base = 0x803A6000

    def at(pointer):
        return pointer - base + tag_offset

    tags, _, _, count = struct.unpack_from("<IIII", data, tag_offset)
    for index in range(count):
        group, _, _, _, name, tag = struct.unpack_from("<4s4s4sIII", data, at(tags) + index * 32)
        end = data.index(b"\0", at(name))
        if group[::-1] == b"bitm" and data[at(name):end] == b"ui\\shell\\main_menu\\halo_logo":
            bitmaps = struct.unpack_from("<I", data, at(tag) + 0x64)[0]
            _, width, height, _, _, fmt, _, _, _, _, _, offset, size = struct.unpack_from("<4sHHHHHHhhHHII", data,
                                                                                        at(bitmaps))
            if fmt != 16:
                sys.exit(f"halo_logo: format {fmt}, not DXT5")
            logo = Image.frombytes("RGBA", (width, height), data[offset:offset + size], "bcn", 3)
            os.makedirs(art, exist_ok=True)
            logo.crop(logo.getbbox()).save(os.path.join(art, "halo_logo.png"))
            print(f"art: {art}/halo_logo.png ({width}x{height})")
            return
    sys.exit("no ui\\shell\\main_menu\\halo_logo in " + ui_map)


def cover(image, size, anchor=0.5):
    """image scaled and cropped to fill size (anchor: where the crop sits across, 0 left .. 1 right)"""
    scale = max(size[0] / image.width, size[1] / image.height)
    image = image.resize((round(image.width * scale), round(image.height * scale)), Image.LANCZOS)
    left, top = round((image.width - size[0]) * anchor), (image.height - size[1]) // 2
    return image.crop((left, top, left + size[0], top + size[1]))


def fade(size, top, bottom, strength):
    """a black gradient mask: transparent above top, strength at bottom"""
    mask = Image.new("L", size, 0)
    d = ImageDraw.Draw(mask)
    for y in range(top, size[1]):
        d.line([(0, y), (size[0], y)], fill=int(strength * (y - top) / max(1, bottom - top)) if y < bottom else strength)
    return mask


def halo_art(art, out):
    logo = Image.open(os.path.join(art, "halo_logo.png")).convert("RGBA")
    background = Image.open(os.path.join(art, "background.png")).convert("RGB")
    # the cinematic's black bars off: the picture is the band with something in it
    box = background.convert("L").point(lambda v: 255 if v > 12 else 0).getbbox()
    if box:
        background = background.crop((0, box[1], background.width, box[3]))

    # pic1: the picture (its left part: the subject off to the right), darker at the top left for the logo
    pic = cover(background, (1920, 1080), 0.0)
    pic = ImageEnhance.Brightness(pic).enhance(0.9)
    shade = Image.new("L", (1920, 1080), 0)
    ImageDraw.Draw(shade).ellipse([-500, -420, 1300, 560], fill=190)
    shade = shade.filter(ImageFilter.GaussianBlur(120))
    pic.paste((4, 8, 20), (0, 0), shade)
    big = logo.resize((820, round(logo.height * 820 / logo.width)), Image.LANCZOS)
    glow = Image.new("RGBA", pic.size, (0, 0, 0, 0))
    glow.paste((90, 150, 255, 255), (70, 90), big.getchannel("A"))
    glow = glow.filter(ImageFilter.GaussianBlur(18))
    pic = pic.convert("RGBA")
    pic.alpha_composite(Image.eval(glow, lambda v: v // 2))
    pic.alpha_composite(big, (70, 90))
    pic.convert("RGB").save(os.path.join(out, "pic1.png"))

    # icon0: the picture's middle, the logo across its foot
    icon = cover(background, (512, 512)) if background.width / background.height < 1.4 else \
        cover(background.crop((background.width // 2 - background.height // 2, 0,
                               background.width // 2 + background.height // 2, background.height)), (512, 512))
    icon = ImageEnhance.Brightness(icon).enhance(0.95).convert("RGBA")
    icon.paste((2, 6, 16, 255), (0, 0), fade((512, 512), 250, 470, 235))
    small = logo.resize((470, round(logo.height * 470 / logo.width)), Image.LANCZOS)
    icon.alpha_composite(small, (21, 512 - small.height - 34))
    icon.convert("RGB").save(os.path.join(out, "icon0.png"))
    print(f"art: {out}/icon0.png, {out}/pic1.png (the game's)")


def fallback_art(out):
    """OpenCE's icon, when art/ has nothing"""
    icon = Image.open(CHECKOUT_ICON).convert("RGBA").resize((512, 512), Image.LANCZOS)
    flat = Image.new("RGBA", (512, 512), (6, 14, 34, 255))
    flat.alpha_composite(icon)
    flat.convert("RGB").save(os.path.join(out, "icon0.png"))
    pic = Image.new("RGB", (1920, 1080), (6, 14, 34))
    pic.paste(flat.resize((900, 900)).convert("RGB"), (510, 90))
    pic.save(os.path.join(out, "pic1.png"))
    print(f"art: {out}/icon0.png, {out}/pic1.png (OpenCE's icon)")


def main():
    if sys.argv[1] == "--logo":
        extract_logo(sys.argv[2], sys.argv[3])
        return
    art = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else "sce_sys"
    os.makedirs(out, exist_ok=True)
    if os.path.isfile(os.path.join(art, "halo_logo.png")) and os.path.isfile(os.path.join(art, "background.png")):
        halo_art(art, out)
    else:
        fallback_art(out)


if __name__ == "__main__":
    main()
