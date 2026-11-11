#!/usr/bin/env python3
"""Generates the launcher icon (original artwork: friendly robot + "Aa")."""
import os
from PIL import Image, ImageDraw, ImageFont

SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
FONT = "assets/fonts/Andika-Bold.ttf"


def draw(n):
    s = 1024
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # Rounded background with a blue-violet gradient.
    grad = Image.new("RGBA", (s, s))
    gd = ImageDraw.Draw(grad)
    for y in range(s):
        t = y / s
        c = (int(79 + (122 - 79) * t), int(141 + (92 - 141) * t), int(249 + (240 - 249) * t), 255)
        gd.line([(0, y), (s, y)], fill=c)
    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, s - 1, s - 1], radius=230, fill=255)
    im.paste(grad, (0, 0), mask)
    # Robot head
    d.rounded_rectangle([212, 300, 812, 760], radius=150, fill=(57, 182, 232, 255))
    d.rounded_rectangle([262, 350, 762, 710], radius=110, fill=(234, 248, 255, 255))
    d.line([(512, 300), (512, 190)], fill=(31, 143, 192, 255), width=34)
    d.ellipse([462, 130, 562, 230], fill=(255, 201, 60, 255))
    d.rounded_rectangle([150, 440, 222, 600], radius=30, fill=(255, 201, 60, 255))
    d.rounded_rectangle([802, 440, 874, 600], radius=30, fill=(255, 201, 60, 255))
    font = ImageFont.truetype(FONT, 250)
    d.text((512, 535), "Aa", font=font, fill=(255, 107, 94, 255), anchor="mm")
    d.rounded_rectangle([212, 800, 812, 900], radius=50, fill=(255, 201, 60, 255))
    small = ImageFont.truetype(FONT, 78)
    d.text((512, 850), "ENGLISH", font=small, fill=(38, 50, 74, 255), anchor="mm")
    return im.resize((n, n), Image.LANCZOS)


for k, n in SIZES.items():
    path = f"android/app/src/main/res/mipmap-{k}/ic_launcher.png"
    draw(n).save(path)
draw(512).save("assets/images/app_icon.png")
print("ok")
