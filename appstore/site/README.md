# Site captures

The hero loop, the tour screens, the frameless pieces and the Apple TV and Watch
captures for the redesigned wodrounds.iamjarl.com (#182). The files the site serves are in
`docs/assets/site/`. This folder holds how to make them again.

**Remake them whenever a screen they show changes.** The site is public imagery, and an old
capture advertises an old app.

## What the captures show

Real values, the same moment on every device:

- **A Tabata, 20/10 × 8**, in round 3: 0:14 of work left on the phone (the ring and the tour),
  and the loop from 0:05 of work into rest.
- **An EMOM of 12 × 1:00**: the setup, and round 4 with about 0:38 left.
- **A For Time finished in 12:47**, uncapped.
- **The 10-second count-in** at 8.

English for the en, de, fr, nb and sv pages, Danish for da, Spanish for es. The app's
interface is in those three languages only.

## The app's site mode

A Debug build reads these launch arguments (`SiteCapture` in `WODrounds/ContentView.swift`,
and the Watch's `onAppear`). None of them exist in a release build.

| Argument | Effect |
|---|---|
| `-screen emom\|intervals\|fortime` | Opens in that mode (existing) |
| `-siteElapsed N` | Opens N seconds into the workout, past the count-in |
| `-siteFinished YES` | With `-siteElapsed`, ends it there, for the Done screen |
| `-siteCountIn N` | Opens inside the count-in, N seconds before it ends |
| `-intervalsWorkSeconds 20` and the other setup keys | The stored setup values |

While `-siteElapsed` is set the app also skips the system voice, which stalls the iOS 27
simulator mid-workout, and the full-screen flash at a phase change, which would blink at the
visitor every time the hero loop repeats. Sound stays switched on, so the screen shows the
normal speaker icon.

## Make them

Build Debug for the iOS, tvOS and watchOS simulators into one derived data path, then run
`capture.sh` once per language. It sets the simulator's own locale (or the status bar writes
the time in the wrong language), a dark appearance and a full status bar at 9:41.

```bash
export DD=<derived data path> PHONE=<iPhone 17 Pro UDID> TV=<Apple TV 4K UDID> WATCH=<Watch 46 mm UDID>
for L in en da es; do appstore/site/capture.sh $L raw; done
python3 appstore/site/make_assets.py raw docs/assets/site
```

`make_assets.py` (Pillow) makes the tour screens at 602 × 1308, the pieces, Apple TV at
1920 × 1080 and the Watch at its display size, 416 × 496. watchOS has no status bar override,
so it paints the Watch clock as 9:41 (09.41 in Danish) in the system face, at the size and
place measured from a real capture.

## The loop

`capture.sh` records 26 seconds from round 3. Find the frame where 0:06 turns to 0:05: on a
contact sheet, or by diffing the digits frame by frame (`loopkit.swift frames`). The loop is
the 9 seconds from there: 0:05 to 0:01 of work, then rest from 0:10 to 0:07. Every digit
holds for one second, so the repeat keeps the rhythm.

```bash
swift appstore/site/loopkit.swift sheet  raw/loop-en-raw.mp4 sheet.jpg 10 13 0.1 10
swift appstore/site/loopkit.swift encode raw/loop-en-raw.mp4 docs/assets/site/intervals-en.mp4 11.2 9.0 602 1308 600000
swift appstore/site/loopkit.swift poster docs/assets/site/intervals-en.mp4 docs/assets/site/intervals-en-poster.jpg 0.5 602 1308 0.82
```

`encode` also paints out the Dynamic Island, which a simulator recording draws and a screenshot
doesn't. Each loop comes out at about 45 KB and each poster at about 70 KB. The poster is the
first second of work, so the page reads the same before the video plays, without the script and
under reduce motion.
