#!/usr/bin/env python3
"""App Store product page header for WODrounds (#158), 3840 x 1646.

The portfolio's pilot for the header Apple added on 2026-10-05. One idea for
someone who has never seen the app: the running timer, digits large enough to
read across a gym. Drawn rather than screenshotted, so it stays sharp at 4K,
in the app's own proportions: the Intervals ring around the digits, digits a
quarter of the ring's diameter, lime while you work.

Safe area, measured from Apple's Photoshop template
(creative_assets-product_page_header_template-static.psd, layer "Art Safe Area"):
x 1097-2743, y 493-1154, so 1646 x 661 centred, insets 1097 left and right,
493 top, 492 bottom. Everything that has to be read sits inside it; the ring
may run past it, since a crop that cuts the ring still leaves a timer.

    python3 scripts/appstore_header.py                 # text-free, appstore/header/header.png
    python3 scripts/appstore_header.py --lang da       # with the localized line
    python3 scripts/appstore_header.py --guides        # draws the safe area, for review only

Needs Pillow. Fonts are the system's: SF Mono for the digits, as in the app,
and SF for the line, as on the screenshots.
"""
from __future__ import annotations

import argparse
import math
import os

from PIL import Image, ImageDraw, ImageFont

W, H = 3840, 1646
SAFE = (1097, 493, 2743, 1154)  # x0, y0, x1, y1

# The poster standard from the hub's tools/appstore_screenshots.py ("dark"), and
# the accent from appstore/manifest.json.
GROUND_TOP, GROUND_BOTTOM = (13, 13, 13), (22, 22, 22)
TEXT = (230, 230, 230)
ACCENT = (0xD0, 0xFF, 0x00)
TRACK = (60, 60, 60)

SF_MONO = "/System/Library/Fonts/SFNSMono.ttf"
SF = "/System/Library/Fonts/SFNS.ttf"

# One short line that adds to the picture rather than describing it. Public copy:
# VOICE.md applies. Same claim as the first screenshot, so the page says one thing.
LINES = {
    "en": "Time your WOD without\ntouching your phone",
    "da": "Tag tid på din WOD uden\nat røre telefonen",
    "es": "Cronometra tu WOD sin\ntocar el teléfono",
}

READOUT = "00:18"
PROGRESS = 18 / 30  # 18 s left of a 30 s work phase


def font(path: str, size: int, weight: str = "Bold") -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(path, size)
    try:
        f.set_variation_by_name(weight)
    except (OSError, ValueError):
        pass
    return f


def ground() -> Image.Image:
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / (H - 1)
        d.line([(0, y), (W, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(GROUND_TOP, GROUND_BOTTOM)))
    return img


def draw_ring(img: Image.Image, cx: float, cy: float, diameter: float) -> None:
    """Track, then the remaining part of the phase from 12 o'clock, clockwise as
    the app's ring drains. Drawn at 2x and scaled down for smooth edges."""
    s = 2
    layer = Image.new("RGBA", (W * s, H * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    r = diameter / 2 * s
    lw = round(diameter / 320 * 6 * s)  # the app: 6 pt on a 320 pt ring
    box = [cx * s - r, cy * s - r, cx * s + r, cy * s + r]
    d.ellipse(box, outline=TRACK + (255,), width=lw)
    start = -90
    end = start + 360 * PROGRESS
    d.arc(box, start=start, end=end, fill=ACCENT + (255,), width=lw)
    # Round caps, as the app's StrokeStyle(lineCap: .round).
    for a in (start, end):
        x = cx * s + (r - lw / 2) * math.cos(math.radians(a))
        y = cy * s + (r - lw / 2) * math.sin(math.radians(a))
        d.ellipse([x - lw / 2, y - lw / 2, x + lw / 2, y + lw / 2], fill=ACCENT + (255,))
    layer = layer.resize((W, H), Image.LANCZOS)
    img.paste(layer, (0, 0), layer)


def draw_centered(d: ImageDraw.ImageDraw, text: str, fnt, cx: float, cy: float, fill) -> None:
    l, t, r, b = d.textbbox((0, 0), text, font=fnt)
    d.text((cx - (r - l) / 2 - l, cy - (b - t) / 2 - t), text, font=fnt, fill=fill)


def render(lang: str | None, guides: bool) -> Image.Image:
    img = ground()
    sx0, sy0, sx1, sy1 = SAFE
    scx, scy = (sx0 + sx1) / 2, (sy0 + sy1) / 2

    if lang is None:
        # Text-free: the ring fills the canvas height and runs past the safe area;
        # the digits, a quarter of its diameter, sit well inside it.
        diameter = 1420
        cx = scx
    else:
        # With a line: the ring inside the safe area's height on the left, the
        # line on the right, both inside the safe area.
        diameter = sy1 - sy0 - 20
        cx = sx0 + diameter / 2 + 10

    draw_ring(img, cx, scy, diameter)
    d = ImageDraw.Draw(img)
    draw_centered(d, READOUT, font(SF_MONO, round(diameter / 4)), cx, scy, TEXT)

    if lang is not None:
        x = cx + diameter / 2 + 100
        lines = LINES[lang].split("\n")
        # The largest size, up to 92 px, at which the longest line ends inside the
        # safe area. The same size in every language would leave Danish, the longest,
        # deciding for all; each language gets its own fit instead.
        size = 92
        while size > 56 and x + max(d.textlength(ln, font=font(SF, size)) for ln in lines) > sx1:
            size -= 2
        fnt = font(SF, size)
        right = x + max(d.textlength(ln, font=fnt) for ln in lines)
        if right > sx1:
            raise SystemExit(f"{lang}: the line runs {right - sx1:.0f} px past the safe area")
        line_h = round(size * 1.28)
        y = scy - line_h * len(lines) / 2
        for ln in lines:
            d.text((x, y), ln, font=fnt, fill=TEXT)
            y += line_h

    if guides:
        d.rectangle(SAFE, outline=(0, 255, 0), width=4)
    return img


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("--lang", choices=sorted(LINES), help="add the localized line")
    p.add_argument("--guides", action="store_true", help="draw the safe area")
    p.add_argument("--out", help="output path (default appstore/header/header[-lang].png)")
    a = p.parse_args()
    out = a.out or os.path.join("appstore", "header",
                                f"header{'-' + a.lang if a.lang else ''}{'-guides' if a.guides else ''}.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    # No alpha channel: Apple rejects headers that have one.
    render(a.lang, a.guides).convert("RGB").save(out, optimize=True)
    print(out)


if __name__ == "__main__":
    main()
