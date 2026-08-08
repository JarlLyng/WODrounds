# App Store screenshots

App Store Connect marketing screenshots, versioned per release. These are **not** the
marketing-site images in `docs/images/` (those are web assets served by GitHub Pages and
referenced in the site HTML). These are uploaded to App Store Connect only, at exact device
slot sizes, and are **not** published by Pages (Pages serves `docs/` only).

Text spec (What's New, keywords, descriptions) and the slot-size table live in
[`docs/APP_STORE_CONNECT.md`](../docs/APP_STORE_CONNECT.md).

## Layout

```
appstore/
  <version>/        one folder per release, the uploaded set
```

Current: **`1.7/`** (flat, one file per slot: `iphone-*`, `ipad-1`, `mac-*`, `tvos-*`, `watch-*`).
Archive: **`1.2/`** (the older hand-made set, kept per platform subfolder as it was produced).

Superseded sets are deleted rather than kept forever; git history has them if ever needed.
This folder replaced a separate top-level "App store screens" directory (consolidated 2026-07-29).

## Style

Captioned posters on the brand ground: dark `#0d0d0d`, lime `#D0FF00` accent tick, a short
bold headline, the app screen with rounded corners below. Apple Watch shots are raw (the
screen is too small for a caption band). Captions follow the voice rules in the private
strategy repo (concrete, no em-dashes, pay-once framing) and lead with the wedge: Apple
Watch, multi-device, pay-once.

## Regenerating

**As of 1.7 this uses the portfolio tool**, `tools/appstore_screenshots.py` in the private
`iamjarl-strategy` repo, driven by [`manifest.json`](manifest.json). The standard it implements
(slot sizes, dark/light mode, per-app accent, device bezels, caption rules, ordering) lives in
that repo's `DESIGN.md`. The older local `scripts/compose_screenshots.py` predates it.

```sh
python3 <hub>/tools/appstore_screenshots.py batch appstore/manifest.json
```

Raw captures live in [`raw/`](raw/) so a set can be re-composed without re-shooting. Capture in
**dark mode** (the app's light mode uses a purple accent that clashes with the lime poster ground)
and force the language with `-AppleLanguages '(da)' -AppleLocale da_DK` on launch.

### Older workflow (pre-1.7)


1. **Capture raw screens** per platform. Simulator: `xcrun simctl io <device> screenshot raw.png`
   (set a clean status bar with `xcrun simctl status_bar <device> override --time 09:41 ...`,
   and `xcrun simctl ui <device> appearance dark` so iPad/iPhone match the dark set). Mac:
   `screencapture` the app window. Or capture on a real device.
2. **Compose** each with the shared tool:
   ```sh
   python3 scripts/compose_screenshots.py raw.png "Headline
   second line" appstore/1.7/iphone-1.png 1290 2796
   ```
   (`scripts/compose_screenshots.py` needs Pillow: `pip install Pillow`.)
3. **Upload** the folder's PNGs to App Store Connect per platform.

## Slot sizes

| Slot | Size (px) |
|---|---|
| iPhone 6.9" | 1290 × 2796 |
| iPad 13" | 2064 × 2752 |
| Mac | 2560 × 1600 |
| Apple TV | 1920 × 1080 |
| Apple Watch | 416 × 496 |
