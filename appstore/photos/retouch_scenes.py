#!/usr/bin/env python3
"""The two gym photos on the home page, with the marks and the face taken out (#182).

    python3 appstore/photos/retouch_scenes.py

The photo rule is "no face and no brand". The Unsplash originals, as first committed
(5bd9367), show the lifter's beard, a logo on the shorts and lettering on both wrist wraps
(the barbell), and a logo on the waistband (the kettlebell). This crops the beard and the
shorts off the top of the barbell, paints the marks out, and writes each photo at 960,
1280 and 1920 px wide into docs/images/unsplash/. Needs Pillow, NumPy and OpenCV
(opencv-python-headless).
"""
from __future__ import annotations

import io
import subprocess
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/images/unsplash"
SOURCE_COMMIT = "5bd9367"
WIDTHS = (960, 1280, 1920)

# Coordinates are in the 1920 x 1280 original.
PHOTOS = {
    "victor-freitas-qZ-U9z4TQ6A": {
        "crop_top": 116,  # the beard, the logo on the shorts, a passer-by's shoe
        "marks": [
            # The wrist wraps: the printed band goes the wrap's own black. "light" picks the
            # pale, unsaturated print and leaves the warm skin around it alone.
            {"box": (1246, 244, 1318, 306), "pick": "light", "fill": "dark"},
            {"box": (444, 484, 520, 530), "pick": "light", "fill": "dark"},
            {"box": (450, 482, 482, 513), "pick": "all", "fill": "dark"},  # the red patch, whole
        ],
    },
    "ambitious-studio-rick-barrett-0tQLfwcr5-M": {
        "crop_top": 0,
        "marks": [
            # The waistband logo, in two parts either side of the forearm. Each is covered
            # with the leggings next to it.
            {"poly": [(906, 478), (940, 478), (940, 516), (906, 516)], "fill": ("copy", -34, 0)},
            {"poly": [(1021, 464), (1036, 464), (1036, 508), (1008, 508)], "fill": ("copy", 36, 0)},
        ],
    },
}


def original(name: str) -> np.ndarray:
    data = subprocess.run(
        ["git", "show", f"{SOURCE_COMMIT}:docs/images/unsplash/{name}-1920.jpg"],
        cwd=ROOT, check=True, capture_output=True).stdout
    return cv2.cvtColor(np.array(Image.open(io.BytesIO(data)).convert("RGB")), cv2.COLOR_RGB2BGR)


def mask_for(img: np.ndarray, mark: dict) -> np.ndarray:
    mask = np.zeros(img.shape[:2], np.uint8)
    if "poly" in mark:
        cv2.fillPoly(mask, [np.array(mark["poly"], np.int32)], 255)
        return mask
    x0, y0, x1, y1 = mark["box"]
    hsv = cv2.cvtColor(img[y0:y1, x0:x1], cv2.COLOR_BGR2HSV)
    s, v = hsv[:, :, 1], hsv[:, :, 2]
    if mark["pick"] == "light":
        hit = (v > 75) & (s < 95)
    else:
        hit = np.ones_like(v, bool)
    mask[y0:y1, x0:x1] = hit.astype(np.uint8) * 255
    return cv2.dilate(mask, np.ones((3, 3), np.uint8), iterations=2)


def retouch(img: np.ndarray, marks: list[dict]) -> np.ndarray:
    out = img.astype(np.float32)
    rng = np.random.default_rng(182)
    for mark in marks:
        mask = mask_for(img, mark)
        fill = mark["fill"]
        if fill == "dark":
            # The median of the wrap's own dark pixels, with a little grain to match.
            x0, y0, x1, y1 = mark["box"]
            region = img[y0:y1, x0:x1].reshape(-1, 3)
            dark = region[region.sum(axis=1) < 75]
            base = np.median(dark, axis=0) if len(dark) else np.array([20, 20, 20])
            patch = base + rng.normal(0, 3, img.shape)
        else:
            _, dx, dy = fill
            patch = np.roll(img, (-dy, -dx), axis=(0, 1)).astype(np.float32)
        alpha = cv2.GaussianBlur(mask, (5, 5), 0).astype(np.float32)[:, :, None] / 255
        out = out * (1 - alpha) + patch * alpha
    return np.clip(out, 0, 255).astype(np.uint8)


def main() -> None:
    for name, p in PHOTOS.items():
        img = retouch(original(name), p["marks"])[p["crop_top"]:]
        pil = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
        for w in WIDTHS:
            h = round(pil.height * w / pil.width)
            out = OUT / f"{name}-{w}.jpg"
            pil.resize((w, h), Image.LANCZOS).save(out, quality=72, optimize=True, progressive=True)
            print(out.name, f"{w}x{h}", out.stat().st_size // 1024, "KB")


if __name__ == "__main__":
    main()
