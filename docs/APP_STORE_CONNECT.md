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

Short line at the top of the product page — can be updated without a new version. Include keywords and value proposition.

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

Update per release. Current — **1.6** (iOS):

```
• Set up workouts directly on your Apple Watch: choose EMOM or Intervals and adjust rounds, round length, work and rest right on the wrist. No iPhone needed.
• The Watch remembers your settings between workouts.
• Small fixes and polish.
```

**Mac / tvOS variant (1.6)** — the Watch feature ships with the iOS listing only; keep Mac/tvOS generic:

```
• Small fixes and polish.
```

**Remember with this release:** apply the expanded keyword fields (marked "Apply with the next release" in the Keywords sections below) for iOS and Mac.

Promotional Text is unchanged from 1.5 (not version-specific): see the per-platform Promotional Text sections above.

<details><summary>Previous — 1.5.1 What's New (for reference)</summary>

iOS: "Fixed the info button overlapping the For Time tab on iPhone. · Tidied up the About screen so the Support and Privacy Policy links sit where they should. · Small fixes and polish." Mac/tvOS dropped the info-button line.

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

The rendered set lives in [`appstore/1.6/`](../appstore/1.6/) (versioned per release; regenerate via `scripts/compose_screenshots.py`, see [`appstore/README.md`](../appstore/README.md)).

**Current set (1.6):** a captioned, brand-styled set was generated for all five platforms (dark #0d0d0d ground, lime #D0FF00 accent, screen shown below a short headline). iPhone: running timer + the three-mode setup. iPad/Mac/Apple TV: setup and running. Apple Watch: raw captures of the new 1.6 standalone config (screen too small for a caption band). Regenerate with the simulator-capture + Pillow compositor workflow; keep the story on the wedge (Apple Watch, multi-device, pay-once) per the private strategy repo.

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

The same minimal WOD timer as on iPhone, Watch, and Mac – no database, no sharing. Just timer and rounds.
```

## Keywords (max 100 characters)

```
interval timer,workout timer,EMOM,Tabata,HIIT,CrossFit,gym,Apple TV,remote,home workout
```

## Screenshots (Apple TV)

tvOS requires 1920 × 1080 or 3840 × 2160. The current set uses 1920 × 1080 (captioned, landscape).

---

# Spanish (es-MX) — iOS

Localization: **Spanish (Mexico)** (serves Latin America + most Spanish-speaking storefronts, incl. US Hispanic). Neutral LatAm vocabulary (e.g. "cuenta regresiva", not the peninsular "cuenta atrás"). App name stays **WODrounds**. In-app strings/audio are still English — this localizes the App Store listing only.

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

## What's New in This Version (1.6) — es-MX

```
• Configura tus entrenamientos directamente en el Apple Watch: elige EMOM o Intervalos y ajusta rondas, duración, trabajo y descanso desde la muñeca. Sin necesidad del iPhone.
• El Watch recuerda tu configuración entre entrenamientos.
• Pequeñas correcciones y mejoras.
```

<details><summary>Anterior — 1.5.1 (referencia)</summary>

"Se corrigió el botón de información que se superponía a la pestaña For Time en el iPhone. · Se ordenó la pantalla Acerca de para que los enlaces de Soporte y Política de privacidad queden en su lugar. · Pequeñas correcciones y mejoras."

</details>

(Mac/tvOS Spanish variants: drop the Apple Watch / Health lines as for English. Add Spanish (Spain) / es-ES later only if Spain shows traction.)
