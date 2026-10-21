#!/usr/bin/env python3
"""OpenCE's home screen art: sce_sys/icon0.png (512x512) and sce_sys/pic1.png (1920x1080).

From OpenCE's own icon (port/assets/icon/opence-icon-render.png in the checkout, a render the project made) and
"OpenCE" in DejaVu Sans Bold (Bitstream Vera licence) on a dark blue field.

Usage: python3 scripts/make-art.py <opence-icon-render.png> [out dir, default sce_sys]
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_LIGHT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def lerp(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(int(round(a[k] + (b[k] - a[k]) * t)) for k in range(len(a)))


def field(w, h):
    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    top, low = (6, 14, 34), (18, 44, 86)
    for y in range(h):
        d.line([(0, y), (w, y)], fill=lerp(top, low, y / (h - 1)))
    return img


def main():
    icon_path = sys.argv[1]
    out = sys.argv[2] if len(sys.argv) > 2 else "sce_sys"
    os.makedirs(out, exist_ok=True)
    icon = Image.open(icon_path).convert("RGBA")

    # icon0: the icon itself, flattened
    icon0 = field(512, 512)
    small = icon.resize((512, 512), Image.LANCZOS)
    icon0.paste(small, (0, 0), small)
    icon0.save(os.path.join(out, "icon0.png"))

    # pic1: the icon on the right with a glow, the name on the left; the render's square crop faded out at its
    # bottom and right edges
    pic = field(1920, 1080)
    big = icon.resize((860, 860), Image.LANCZOS)
    fade = Image.new("L", big.size, 255)
    fd = ImageDraw.Draw(fade)
    for y in range(600, 860):
        fd.line([(0, y), (859, y)], fill=int(255 * (859 - y) / 259))
    edge = Image.new("L", big.size, 255)
    ed = ImageDraw.Draw(edge)
    for x in range(700, 860):
        ed.line([(x, 0), (x, 859)], fill=int(255 * (859 - x) / 159))
    alpha = big.getchannel("A")
    from PIL import ImageChops
    alpha = ImageChops.multiply(ImageChops.multiply(alpha, fade), edge)
    big.putalpha(alpha)
    glow = Image.new("RGBA", pic.size, (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([980, 150, 1880, 1050], fill=(80, 150, 255, 90))
    glow = glow.filter(ImageFilter.GaussianBlur(90))
    pic.paste(glow, (0, 0), glow)
    pic.paste(big, (1000, 110), big)
    d = ImageDraw.Draw(pic)
    title = ImageFont.truetype(FONT, 170)
    subtitle = ImageFont.truetype(FONT_LIGHT, 54)
    d.text((140, 360), "OpenCE", font=title, fill=(236, 242, 255))
    d.text((148, 570), "Halo: Combat Evolved", font=subtitle, fill=(170, 196, 236))
    d.text((148, 640), "for PS4", font=subtitle, fill=(120, 150, 200))
    pic.save(os.path.join(out, "pic1.png"))
    print(f"art: {out}/icon0.png, {out}/pic1.png")


if __name__ == "__main__":
    main()
