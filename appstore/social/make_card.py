#!/usr/bin/env python3
"""The social card for wodrounds.iamjarl.com (#182): the site's og:image and the repo's
GitHub social preview, one design at two sizes.

    python3 appstore/social/make_card.py <jetbrains-mono.woff2>

The woff2 is the design system's (fonts/jetbrains-mono-latin-wght-normal.woff2 at the
release the site loads). Writes docs/images/og-image.png (1200 x 630) and
docs/images/github-social-preview.png (1280 x 640). Needs Pillow.

The hub's rule (DESIGN.md, "Social cards"): the name, one line of outcome, and a real
product screen, on the site's own ground and accent. No superlative, so the card says
what the app does rather than the site's headline.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SCREEN = ROOT / "docs/assets/site/tour-intervals-en.jpg"  # a Tabata, round 3, 0:14 of work

# WODrounds' identity, iamjarl-design v1.25.0.
GROUND = (0x0B, 0x0C, 0x0D)
TEXT = (0xF2, 0xF3, 0xEF)
TEXT_2 = (0xC4, 0xC5, 0xC2)
TEXT_3 = (0xAD, 0xAE, 0xAB)
ACCENT = (0xD0, 0xFF, 0x00)
EDGE = (0x2E, 0x30, 0x33)

SF = "/System/Library/Fonts/SFNS.ttf"
OUTCOME = "EMOM, intervals and For Time, with digits you can read mid-set."
FACTS = "iPhone, iPad, Apple Watch, Mac and Apple TV. Paid for once."
URL = "wodrounds.iamjarl.com"


def font(path: str, size: int, weight: str) -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(path, size)
    f.set_variation_by_name(weight)
    return f


def wrap(d: ImageDraw.ImageDraw, text: str, f, width: int) -> list[str]:
    lines, cur = [], ""
    for word in text.split():
        trial = f"{cur} {word}".strip()
        if d.textlength(trial, font=f) <= width or not cur:
            cur = trial
        else:
            lines.append(cur)
            cur = word
    return lines + [cur]


def phone(width: int, screen: Image.Image) -> Image.Image:
    """The kit's plain phone: a black body, a thin edge, the screen inset. No island."""
    s = 2
    w = width * s
    sh = round(screen.height * (w - 2 * 14 * s) / screen.width)
    h = sh + 2 * 14 * s
    body = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(body)
    d.rounded_rectangle((0, 0, w - 1, h - 1), radius=58 * s, fill=(0, 0, 0, 255), outline=EDGE + (255,), width=3 * s)
    scr = screen.resize((w - 28 * s, sh), Image.LANCZOS).convert("RGBA")
    mask = Image.new("L", scr.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, scr.width - 1, scr.height - 1), radius=46 * s, fill=255)
    body.paste(scr, (14 * s, 14 * s), mask)
    return body.resize((width, round(h / s)), Image.LANCZOS)


def card(size: tuple[int, int], mono_path: str) -> Image.Image:
    W, H = size
    k = W / 1200
    img = Image.new("RGB", size, GROUND)

    # A faint lime glow behind the phone, the accent at low opacity.
    glow = Image.new("RGB", size, GROUND)
    gd = ImageDraw.Draw(glow)
    cx, cy = int(W * 0.78), int(H * 0.62)
    gd.ellipse((cx - 260 * k, cy - 260 * k, cx + 260 * k, cy + 260 * k), fill=(0x2A, 0x33, 0x05))
    img = Image.blend(img, glow.filter(ImageFilter.GaussianBlur(120 * k)), 0.9)

    d = ImageDraw.Draw(img)
    x = int(80 * k)
    text_w = int(W * 0.52)

    mono = font(mono_path, int(84 * k), "Bold")
    d.rectangle((x, int(150 * k), x + int(64 * k), int(156 * k)), fill=ACCENT)
    d.text((x, int(176 * k)), "WODrounds", font=mono, fill=TEXT)

    body = font(SF, int(34 * k), "Medium")
    y = int(300 * k)
    for ln in wrap(d, OUTCOME, body, text_w):
        d.text((x, y), ln, font=body, fill=TEXT_2)
        y += int(46 * k)

    small = font(SF, int(24 * k), "Regular")
    y += int(18 * k)
    for ln in wrap(d, FACTS, small, text_w):
        d.text((x, y), ln, font=small, fill=TEXT_3)
        y += int(34 * k)

    url = font(mono_path, int(24 * k), "Medium")
    d.text((x, H - int(78 * k)), URL, font=url, fill=ACCENT)

    # The phone, bleeding off the bottom edge so the digits sit high in the frame.
    p = phone(int(390 * k), Image.open(SCREEN).convert("RGB"))
    img.paste(p, (W - p.width - int(80 * k), int(64 * k)), p)
    return img


def main(mono_path: str) -> None:
    out = ROOT / "docs/images"
    card((1200, 630), mono_path).save(out / "og-image.png", optimize=True)
    card((1280, 640), mono_path).save(out / "github-social-preview.png", optimize=True)
    for f in ("og-image.png", "github-social-preview.png"):
        print(f, (out / f).stat().st_size // 1024, "KB")


if __name__ == "__main__":
    main(sys.argv[1])
