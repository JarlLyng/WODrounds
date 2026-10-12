#!/usr/bin/env python3
"""Site assets for wodrounds.iamjarl.com (#182) from the raw captures.

    python3 appstore/site/make_assets.py <raw-dir> docs/assets/site

Takes what capture.sh wrote and makes, per language (en, da, es):

- tour-{emom,intervals,fortime}-<lang>.jpg: the phone that stays, 602 x 1308, half the
  iPhone 17 Pro capture, sharp at the kit phone's size;
- piece-{ring,emom-round,finished,countin}-<lang>.png: the frameless pieces, cropped
  from the captures at twice their point size;
- tv-intervals-<lang>.jpg: Apple TV at 1920 x 1080;
- watch-intervals-<lang>.png: Apple Watch at display size (416 x 496), with the clock
  set to 9:41 (09.41 in Danish). watchOS has no status bar override, so the clock is
  painted in the system face at the size and place it was measured at.

The hero loop is cut with loopkit.swift; see README.md. Needs Pillow.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

LANGS = ("en", "da", "es")
PT = 3  # iPhone 17 Pro: 3 px per point

TOUR = {"emom": "emom-setup", "intervals": "intervals-running", "fortime": "fortime-done"}
# Crops in points on the 402 x 874 pt screen.
PIECES = {
    "ring": ("intervals-running", (20, 118, 382, 562)),
    "emom-round": ("emom-running", (30, 205, 372, 355)),
    "finished": ("fortime-done", (40, 215, 362, 425)),
    "countin": ("countin", (60, 355, 342, 500)),
}
# The Watch clock on a 46 mm Series 12 capture: SF Pro Medium 33 px, right edge at
# x 383, cap top at y 40. Matched against a real capture of the clock.
WATCH_CLOCK = {"en": "9:41", "da": "09.41", "es": "9:41"}


def main(raw: Path, out: Path) -> None:
    out.mkdir(parents=True, exist_ok=True)
    clock_font = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", 33)
    clock_font.set_variation_by_name("Medium")
    for lang in LANGS:
        for key, src in TOUR.items():
            img = Image.open(raw / f"{src}-{lang}.png").convert("RGB").resize((602, 1308), Image.LANCZOS)
            img.save(out / f"tour-{key}-{lang}.jpg", "JPEG", quality=80, optimize=True, progressive=True)
        for key, (src, (x0, y0, x1, y1)) in PIECES.items():
            img = Image.open(raw / f"{src}-{lang}.png").convert("RGB").crop((x0 * PT, y0 * PT, x1 * PT, y1 * PT))
            img = img.resize((img.width * 2 // PT, img.height * 2 // PT), Image.LANCZOS)
            img.save(out / f"piece-{key}-{lang}.png", optimize=True)
        tv = Image.open(raw / f"tv-intervals-{lang}.png").convert("RGB").resize((1920, 1080), Image.LANCZOS)
        tv.save(out / f"tv-intervals-{lang}.jpg", "JPEG", quality=82, optimize=True, progressive=True)
        watch = Image.open(raw / f"watch-intervals-{lang}.png").convert("RGB")
        d = ImageDraw.Draw(watch)
        d.rectangle((290, 30, 416, 72), fill=(0, 0, 0))
        text = WATCH_CLOCK[lang]
        left, top, right, _ = d.textbbox((0, 0), text, font=clock_font)
        d.text((383 - right, 40 - top), text, font=clock_font, fill=(255, 255, 255))
        watch.save(out / f"watch-intervals-{lang}.png", optimize=True)
        print(lang, "done")


if __name__ == "__main__":
    main(Path(sys.argv[1]), Path(sys.argv[2]))
