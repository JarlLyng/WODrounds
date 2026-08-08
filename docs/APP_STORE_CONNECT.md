# App Store Connect – Text for "Prepare for Submission"

Copy into the corresponding fields in App Store Connect. Under **Distribution** you typically have **iOS App**, **Mac App**, and **Apple TV App** (tvOS) — each with its own version and metadata. The descriptions here match the app: EMOM + Intervals timer only, no accounts.

**SEO:** App Store indexes app name, subtitle, keywords, and description. Subtitle and the first sentence of the description are most important; the keyword field is max 100 characters (comma-separated, no spaces). Do not repeat words already in the app name/subtitle.

---

# iOS App (iPhone, iPad, Watch)

---

## Subtitle (required, max 30 characters)

Shown under the app name and used in search. Keep it short and searchable.

```
EMOM & Intervals Timer
```

Alternatives: `Interval Timer • iPhone & Watch` (29) or `WOD Timer for iPhone & Watch` (29).

---

## Promotional Text (optional, max 170 characters)

Short line at the top of the product page. It can be edited on a live version without submitting a build, but **it starts empty on each new version**, so re-paste it every release.

```
EMOM, intervals and For Time for CrossFit and HIIT. Now set up workouts on your Apple Watch too, no iPhone needed. One-time purchase, no subscription.
```

---

## Description (required)

**First 2–3 lines** are often shown in search results and previews — make sure they contain key terms (interval timer, workout, EMOM, CrossFit). Then add concrete bullets.

```
Interval timer and workout timer for EMOM, For Time, CrossFit, and HIIT. No accounts, no sign-up. Just time, rounds, and focus.

• EMOM: Set rounds (1–120) and round length (0:30–9:30). Start, pause, resume, reset.
• Intervals: Work, rest, rounds. Perfect for Tabata (20/10 × 8) and any interval workout.
• For Time: The clock counts up. Press Stop when you finish and your time is saved, or set an optional time cap.
• Apple Watch: Start on iPhone and the watch shows the same time and round, or set up and run EMOM and Intervals on the watch by itself.
• Audio cues: "Get ready", halfway and ten-seconds voice cues, a 3-2-1 countdown, rounds remaining (10, 5, 2), and randomized completion sounds.
• Large type, one-handed use, runs in background. Light and dark theme.
• One-time purchase: pay once, own it forever. No subscription, no ads, no in-app purchases.

A focused WOD timer. No database, no sharing. Just timer and rounds.
```

---

## What's New in This Version (release notes)

Update per release. Current — **1.6.1** (iOS):

```
• Crash reports are now diagnostics only, with no screenshot attached.
• Small fixes and polish.
```

**Apple TV variant (1.6.1)** — the screensaver fix is the tvOS story, so say it plainly:

```
• Fixed the Apple TV screensaver taking over the screen during a workout.
• Small fixes and polish.
```

**Mac variant (1.6.1):**

```
• The Mac app now uses the dark app icon.
• Small fixes and polish.
```

**Do these two things with this release** (both are version-locked, so this is the window):
1. **Paste the full Description** from the sections above into ASC (EN + es-MX). The live listing still runs launch-era copy with **For Time missing entirely**; it carries over silently unless re-pasted.
2. **Apply the expanded keyword fields** for iOS and Mac (marked "Apply with the next release" in the Keywords sections below), and confirm whether they already went in with 1.6.

**Promotional Text comes up empty on every new version**, so re-paste it each time from the per-platform Promotional Text sections above (it can also be edited on a live version without submitting a build).

<details><summary>Previous — 1.6 What's New (for reference)</summary>

iOS: "Set up workouts directly on your Apple Watch: choose EMOM or Intervals and adjust rounds, round length, work and rest right on the wrist. No iPhone needed. · The Watch remembers your settings between workouts. · Small fixes and polish." Mac/tvOS were generic ("Small fixes and polish").

</details>

---

## Keywords (required, max 100 characters including commas)

Search terms users may search for. **Do not repeat words from the app name or subtitle** (Apple weights them lower). Prioritize high-intent words; one comma between each, no spaces after commas.

**Apply with the next release** (keywords only update when a new version ships). Expanded field, ~99 of 100 chars (was ~65):

```
interval timer,workout timer,EMOM,Tabata,HIIT,CrossFit,gym,countdown,Apple Watch,functional,WOD,fit
```

---

## Support URL (required)

Use the same URL as in the app’s About screen (both paths return the same page):

```
https://wodrounds.iamjarl.com/support
```

(`https://wodrounds.iamjarl.com/support.html` is equivalent; the sitemap lists the `.html` form.)

---

## Marketing URL (optional)

```
https://wodrounds.iamjarl.com/
```

---

## Copyright (required)

**Update the year and optionally your name**, e.g.:

```
2026 Jarl L
```

or just:

```
2026
```

---

## Age Rating

12+ is appropriate (fitness/exercise, no content requiring a higher rating).

---

## Previews and Screenshots

Current sizes (Apple retired the old 5.5"/6.5" slots as the primary requirement). Required upload is the **6.9" iPhone**; one 13" iPad set covers all iPad sizes.

| Slot | Size (px) | Required |
|---|---|---|
| iPhone 6.9" | 1290 × 2796 (or 1320 × 2868) | Yes |
| iPad 13" | 2064 × 2752 | If iPad supported |
| Mac | 2560 × 1600 | Yes for Mac app |
| Apple TV | 1920 × 1080 (or 3840 × 2160) | Yes for tvOS app |
| Apple Watch | 416 × 496 (Series 10/11 46mm) | Optional |

The rendered set lives in [`appstore/1.7/`](../appstore/1.7/), versioned per release and driven by [`appstore/manifest.json`](../appstore/manifest.json). Regenerate with the portfolio compositor in the private strategy repo (`tools/appstore_screenshots.py batch appstore/manifest.json`); see [`appstore/README.md`](../appstore/README.md). Older sets in [`appstore/1.6.1/`](../appstore/1.6.1/) and [`appstore/1.2/`](../appstore/1.2/) are kept for reference.

**Apple TV got three screenshots in 1.6.1** (was one), because the device x territory cross-tab showed Apple TV is the #2 platform at 32% of product page views: running timer (hero), the three-mode setup, and For Time with the time cap. The tvOS canvas uses a larger screen scale (0.82) so the timer stays readable at thumbnail size.

**Current set (`appstore/1.7/`), 21 images.** Dark #0d0d0d ground, lime #D0FF00 accent, the app screen below a short headline. English covers all five platforms: four iPhone (running timer, three-mode setup, Intervals, For Time), one iPad, one Mac, two Apple TV, one Apple Watch. Danish (`da/`) and Spanish (`es/`) repeat the four iPhone shots plus iPad and Watch, which is what the iOS app record needs for a localized listing. Mac and Apple TV are separate app records and stay English only.

Capture rule learned in 1.7: set the simulator's **system** language, not just the app's, before capturing iPad. The iPad status bar renders its date from the system locale, so an app launched with `-AppleLanguages` still showed a Danish date on the English screenshot. `xcrun simctl status_bar` fixes the time but not the date, and it is unsupported on watchOS, so Watch captures show whatever the clock says.

Apple Watch shots stay uncaptioned; the screen is too small for a caption band.

Content to feature, in order: (1) timer running (hero), (2) mode setup showing EMOM / Intervals / For Time, (3) the Apple Watch / multi-device angle.

---

## Build

Select **Add Build** and choose the build you uploaded from Xcode (from TestFlight builds). Without an associated build, you cannot submit for review.

---

## App Review Information

- **Notes:** Optional. For a simple timer you can write: "WODrounds is a timer-only app. No login required. Test with EMOM (e.g. 5 rounds, 1 min) or Intervals (e.g. 20s work, 10s rest, 8 rounds)."
- **Contact:** Use the email and phone you monitor (e.g. the address on the [Support](https://wodrounds.iamjarl.com/support) page).

---

## Version Release

Choose whether the version should be released manually or automatically after approval — your preference.

---

# Mac App (macOS)

In App Store Connect: **Distribution → Mac App → 1.0 Prepare for Submission**. Support URL and Marketing URL can be the same as for iOS.

## Subtitle (max 30 characters)

```
EMOM & Intervals Timer
```

or: `Interval Timer for Mac` (22).

## Promotional Text (optional, max 170 characters)

```
EMOM, Intervals and For Time on your Mac. The same minimal timer as on iPhone and Watch. One-time purchase, no subscription, no ads.
```

## Description (required)

```
Interval timer and workout timer for EMOM, For Time, CrossFit, and HIIT on Mac. No accounts, no sign-up. Just time, rounds, and focus.

• EMOM: Set rounds (1–120) and round length (0:30–9:30). Start, pause, resume, reset.
• Intervals: Work, rest, rounds. Perfect for Tabata (20/10 × 8) and any interval workout.
• For Time: The clock counts up. Press Stop when you finish and your time is saved, or set an optional time cap.
• Compact window, large type. Runs in background. Light and dark theme.
• One-time purchase: pay once, own it forever. No subscription, no ads, no in-app purchases.

The same minimal WOD timer as on iPhone and Apple Watch. No database, no sharing. Just timer and rounds.
```

## Keywords (max 100 characters)

**Apply with the next release.** Expanded field (~98 of 100 chars):

```
interval timer,workout timer,EMOM,Tabata,HIIT,CrossFit,gym,countdown,Mac,desktop timer,WOD,fitness
```

## Screenshots (Mac)

Mac App Store requires screenshots at 1280 × 800, 1440 × 900, 2560 × 1600, or 2880 × 1800. The current set uses 2560 × 1600 (the compact window centered on the brand background).

---

# Apple TV App (tvOS)

In App Store Connect: **Distribution → Apple TV App → 1.0 Prepare for Submission**. Support URL and Marketing URL same as above.

## Subtitle (max 30 characters)

```
EMOM & Intervals Timer
```

or: `Interval Timer for Apple TV` (28).

## Promotional Text (optional, max 170 characters)

```
EMOM, Intervals and For Time on the big screen. Start, stop and reset with the remote. One-time purchase, no subscription, no ads.
```

## Description (required)

```
Interval timer and workout timer for EMOM, For Time, CrossFit, and HIIT on Apple TV. No accounts, no sign-up. Just time, rounds, and focus.

• EMOM: Set rounds (1–120) and round length (0:30–9:30). Start, pause, resume, reset with the remote.
• Intervals: Work, rest, rounds. Perfect for Tabata (20/10 × 8) and any interval workout.
• For Time: The clock counts up. Press Stop when you finish and your time is saved, or set an optional time cap.
• Large type for the living room. Focus-friendly UI. Light and dark theme.
• One-time purchase: pay once, own it forever. No subscription, no ads, no in-app purchases.

The same minimal WOD timer as on iPhone, Watch, and Mac. No database, no sharing. Just timer and rounds.
```

## Keywords (max 100 characters)

```
interval timer,workout timer,EMOM,Tabata,HIIT,CrossFit,gym,Apple TV,remote,home workout
```

## Screenshots (Apple TV)

tvOS requires 1920 × 1080 or 3840 × 2160. The current set uses 1920 × 1080 (captioned, landscape).

---

# Spanish (es-MX) — iOS

Localization: **Spanish (Mexico)** (serves Latin America + most Spanish-speaking storefronts, incl. US Hispanic). Neutral LatAm vocabulary (e.g. "cuenta regresiva", not the peninsular "cuenta atrás"). App name stays **WODrounds**. As of 1.7 the **app UI is localized too**; only the spoken audio cues stay English (they are recorded voice files).

## Subtitle (max 30 characters)

```
Temporizador HIIT y Tabata
```

## Promotional Text (max 170 characters)

```
EMOM, intervalos y For Time para CrossFit y HIIT. Ahora configura tus entrenamientos también en el Apple Watch, sin necesidad del iPhone. Compra única, sin suscripción.
```

## Description

```
Temporizador de intervalos y de entrenamiento para EMOM, For Time, CrossFit y HIIT. Sin cuentas, sin registro. Solo tiempo, rondas y enfoque.

• EMOM: define las rondas (1–120) y la duración de cada ronda (0:30–9:30). Inicia, pausa, reanuda y reinicia.
• Intervalos: trabajo, descanso y rondas. Perfecto para Tabata (20/10 × 8) y cualquier entrenamiento por intervalos.
• For Time: el reloj cuenta hacia arriba. Pulsa Detener al terminar y tu tiempo queda guardado, o define un límite de tiempo opcional.
• Apple Watch: empieza en el iPhone y el reloj muestra el mismo tiempo y ronda, o configura y ejecuta EMOM e Intervalos en el reloj por sí solo.
• Señales de audio: "Get ready", avisos de voz a la mitad y a los diez segundos, cuenta 3-2-1, rondas restantes (10, 5, 2) y sonidos de finalización aleatorios.
• Texto grande, uso con una mano, funciona en segundo plano. Tema claro y oscuro.
• Compra única: paga una vez y es tuyo para siempre. Sin suscripción, sin anuncios, sin compras dentro de la app.

Un temporizador WOD enfocado. Sin base de datos, sin compartir. Solo cronómetro y rondas.
```

## Keywords (max 100 characters)

Single words, comma-separated, no spaces; excludes terms already in the subtitle (Temporizador/HIIT/Tabata).

```
intervalos,entrenamiento,EMOM,CrossFit,gimnasio,cronómetro,cuenta,regresiva,WOD,rondas,ejercicio
```

## What's New in This Version (1.6.1) — es-MX

```
• Los informes de fallos ahora son solo diagnósticos, sin captura de pantalla adjunta.
• Pequeñas correcciones y mejoras.
```

<details><summary>Anterior — 1.5.1 (referencia)</summary>

"Se corrigió el botón de información que se superponía a la pestaña For Time en el iPhone. · Se ordenó la pantalla Acerca de para que los enlaces de Soporte y Política de privacidad queden en su lugar. · Pequeñas correcciones y mejoras."

</details>

(Mac/tvOS Spanish variants: drop the Apple Watch / Health lines as for English. Add Spanish (Spain) / es-ES later only if Spain shows traction.)
