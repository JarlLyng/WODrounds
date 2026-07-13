#!/usr/bin/env python3
"""
Compose App Store screenshots: an app screen on the brand background with a caption.

Input is a raw device capture (from a simulator or device); output is a poster at an
exact App Store slot size (dark #0d0d0d ground, lime #D0FF00 accent, screen below a short
headline). Apple Watch shots stay raw (the screen is too small for a caption band).

Workflow (see appstore/README.md):
  1. Capture raw screens per platform (simulator `xcrun simctl io <dev> screenshot`, or device).
  2. Run this per screen, e.g.:
       python3 scripts/compose_screenshots.py RAW.png "Headline line one\nline two" OUT.png 1290 2796
  3. Drop the finals in appstore/<version>/ and upload to App Store Connect.

Slot sizes: iPhone 6.9" 1290x2796, iPad 13" 2064x2752, Mac 2560x1600, Apple TV 1920x1080.

No third-party fonts (the caption uses the system San Francisco face). Requires Pillow.
"""
import sys
from PIL import Image, ImageDraw, ImageFont

BG_TOP = (13, 13, 13)      # #0d0d0d
BG_BOTTOM = (22, 22, 22)   # #161616
TEXT = (230, 230, 230)     # #e6e6e6
ACCENT = (208, 255, 0)     # #D0FF00

SFNS = "/System/Library/Fonts/SFNS.ttf"


def font(size, weight="Bold"):
    f = ImageFont.truetype(SFNS, size)
    try:
        f.set_variation_by_name(weight)
    except Exception:
        pass
    return f


def vgradient(w, h):
    img = Image.new("RGB", (w, h), BG_TOP)
    px = img.load()
    for y in range(h):
        t = y / max(1, h - 1)
        row = tuple(int(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = row
    return img


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *img.size], radius=radius, fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0))
    out.putalpha(mask)
    return out


def wrap(draw, text, fnt, max_w):
    lines = []
    for para in text.split("\n"):
        cur = ""
        for word in para.split(" "):
            trial = (cur + " " + word).strip()
            if draw.textlength(trial, font=fnt) <= max_w or not cur:
                cur = trial
            else:
                lines.append(cur)
                cur = word
        lines.append(cur)
    return lines


def compose(raw_path, caption, out_path, canvas, shot_scale=0.82):
    cw, ch = canvas
    portrait = ch >= cw
    bg = vgradient(cw, ch)
    draw = ImageDraw.Draw(bg)

    margin_x = int(cw * 0.08)
    cap_size = int(cw * (0.072 if portrait else 0.045))
    fnt = font(cap_size, "Bold")
    lines = wrap(draw, caption, fnt, cw - 2 * margin_x)
    line_h = int(cap_size * 1.18)
    cap_top = int(ch * (0.06 if portrait else 0.08))
    tick_y = cap_top - int(cap_size * 0.5)
    draw.rounded_rectangle(
        [margin_x, tick_y, margin_x + int(cw * 0.12), tick_y + max(6, int(cw * 0.008))],
        radius=4, fill=ACCENT)
    y = cap_top
    for ln in lines:
        draw.text((margin_x, y), ln, font=fnt, fill=TEXT)
        y += line_h
    cap_bottom = y + int(ch * 0.02)

    shot = Image.open(raw_path).convert("RGB")
    avail_h = ch - cap_bottom - int(ch * 0.05)
    avail_w = int(cw * shot_scale)
    scale = min(avail_w / shot.size[0], avail_h / shot.size[1])
    nw, nh = int(shot.size[0] * scale), int(shot.size[1] * scale)
    shot = rounded(shot.resize((nw, nh), Image.LANCZOS), radius=int(min(nw, nh) * 0.045))
    bg.paste(shot, ((cw - nw) // 2, cap_bottom + (avail_h - nh) // 2), shot)
    bg.save(out_path)
    print(f"{out_path}  ({cw}x{ch})")


if __name__ == "__main__":
    if len(sys.argv) < 6:
        sys.exit("usage: compose_screenshots.py RAW.png CAPTION OUT.png WIDTH HEIGHT [shot_scale]")
    raw, caption, out, W, H = sys.argv[1:6]
    scale = float(sys.argv[6]) if len(sys.argv) > 6 else 0.82
    compose(raw, caption, out, (int(W), int(H)), shot_scale=scale)
