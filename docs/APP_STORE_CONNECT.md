# App Store Connect – Text for "Prepare for Submission"

Copy into the corresponding fields in App Store Connect. Under **Distribution** you typically have **iOS App**, **Mac App**, and **Apple TV App** (tvOS) — each with its own version and metadata. The descriptions here match the app: EMOM + Intervals timer only, no accounts.

**What you can change once a version is live:** only **Promotional Text**. Subtitle, description,
keywords, screenshots and What's New are version-locked, editable only while a version is being
prepared or is in review. So a copy change you think of the day after release waits for the next
version, and the release-day window is the only chance to get them right.

**SEO:** App Store indexes app name, subtitle, keywords, and description. Subtitle and the first sentence of the description are most important; the keyword field is max 100 characters (comma-separated, no spaces). Do not repeat words already in the app name/subtitle.

---

# iOS App (iPhone, iPad, Watch)

---

## Subtitle (required, max 30 characters)

Shown under the app name and used in search. Keep it short and searchable.

```
EMOM & Intervals Timer
```

Kept unchanged in 1.7 even though it predates For Time. Naming all three modes costs the word
"timer", which is the highest-intent search term and is **not** in the app name, so the trade is
bad. For Time lives in the keyword field instead.

---

## Promotional Text (optional, max 170 characters)

Short line at the top of the product page. It can be edited on a live version without submitting a
build, but **it starts empty on each new version**, so re-paste it every release.

**Promotional Text sells the app; it does not announce the release.** Release news belongs in
What's New, which is already version-locked for it. Through 1.6.1 this field carried news ("Now set
up workouts on your Apple Watch too") and that was wrong. The 1.7 pattern is: what it is, that one
purchase covers every platform, and the close.

EN (149):

```
EMOM, intervals and For Time. One purchase runs on iPhone, iPad, Apple Watch, Mac and Apple TV. No subscription, no ads. The only WOD timer you need.
```

es-MX (166):

```
EMOM, intervalos y For Time. Una compra funciona en iPhone, iPad, Apple Watch, Mac y Apple TV. Sin suscripción, sin anuncios. El único temporizador WOD que necesitas.
```

Danish (160):

```
EMOM, intervaller og For Time. Ét køb kører på iPhone, iPad, Apple Watch, Mac og Apple TV. Intet abonnement, ingen reklamer. Den eneste WOD-timer du skal bruge.
```

"The only WOD timer you need" is a sufficiency claim, not a superiority claim, which is why it
passes where the old "simplest WOD timer" superlative did not. It is also the brand book's line.

## Description (required)

**First 2-3 lines** are shown in search results and previews, so they carry the key terms (interval
timer, EMOM, For Time, CrossFit, HIIT).

Rewritten in prose for 1.7. The bulleted version shipped from launch through 1.6.1, but VOICE.md
rules bullets out of public copy, and CLAUDE.md says to fold the voice audit into the next metadata
touch. This was that touch. The other change is the closing platform line: the listing never said
that one purchase covers all five platforms, which is the thing the two nearest competitors cannot
match.

**Deferred to 1.8:** the English and Spanish descriptions still shipped in 1.7 with the launch-era
bullets. Only the Danish one, written fresh for 1.7, is prose. Both were locked before the prose
rewrite existed, so replace them the next time a version is editable.

```
Interval timer for EMOM, For Time, CrossFit and HIIT. No account, no sign-up. Just time, rounds and room to train.

EMOM runs 1 to 120 rounds with a round length between 0:30 and 9:30. Intervals is work, rest and rounds that you set yourself, so Tabata is 20/10 times 8 whenever you want it. For Time counts up from zero, you press Stop when you finish, and you can set a time cap if you want one.

Start on your iPhone and the watch shows the same time and the same round. You can also set up an EMOM or an interval session on the watch itself and leave the phone in your bag.

Audio cues carry you through: get ready, halfway, ten seconds, 3-2-1 and rounds remaining at ten, five and two. The numbers are big enough to read at a distance, everything works one-handed, and the timer keeps running when the screen goes dark.

One purchase covers iPhone, iPad, Apple Watch, Mac and Apple TV. No subscription, no ads and nothing to buy inside the app.

A timer for training. No logbook, no sharing and no account.
```

## What's New in This Version (release notes)

Update per release. Current — **1.7** (iOS):

```
WODrounds now speaks Danish and Spanish. Every screen, button and help text is translated on iPhone, iPad and Apple Watch. The spoken cues stay in English, because they are recorded voice files.

Those recordings are new this version. VoiceOver now reads the timer controls in your language, and Reduce Motion is respected.
```

es-MX:

```
WODrounds ahora habla español y danés. Cada pantalla, botón y texto de ayuda está traducido en iPhone, iPad y Apple Watch. Las señales habladas siguen en inglés, porque son grabaciones de voz.

Esas grabaciones son nuevas en esta versión. VoiceOver ahora lee los controles del temporizador en tu idioma y se respeta Reducir movimiento.
```

Danish:

```
WODrounds taler nu dansk og spansk. Hver skærm, knap og hjælpetekst er oversat på iPhone, iPad og Apple Watch. De talte cues bliver på engelsk, fordi det er indtalte lydfiler.

Selve lydfilerne er nyindspillede i denne version. VoiceOver læser nu timerens knapper på dit sprog, og Reducer bevægelse bliver respekteret.
```

**Mac (1.7)** drops the Apple Watch line, since the Mac app neither pairs with the watch nor plays
audio cues:

```
WODrounds now speaks Danish and Spanish. Every screen, button and help text is translated.

VoiceOver now reads the timer controls in your language, and Reduce Motion is respected.
```

**Apple TV (1.7):**

```
WODrounds now speaks Danish and Spanish. Every screen, button and help text is translated on Apple TV.

VoiceOver now reads the timer controls in your language, and Reduce Motion is respected.
```

<details><summary>Previous — 1.6.1 What's New (for reference)</summary>

iOS: "Crash reports are now diagnostics only, with no screenshot attached. Small fixes and polish."
Apple TV led with the screensaver fix; Mac led with the dark app icon.

</details>

## Keywords (required, max 100 characters including commas)

Apple already indexes the app name and the subtitle and weights repeats of those words lower, so
every word spent restating them is a wasted character. **WODrounds** spends "WOD" and "rounds";
the subtitle spends "EMOM", "Intervals" and "Timer". Through 1.6.1 the field restated four of those
and burned roughly 35 characters doing it.

Applied with 1.7 (89 of 100):

```
Tabata,HIIT,CrossFit,for time,countdown,stopwatch,gym,workout,functional,fitness,training
```

<details><summary>Previous — the 1.6 field, for reference</summary>

`interval timer,workout timer,EMOM,Tabata,HIIT,CrossFit,gym,countdown,Apple Watch,functional,WOD,fit`

</details>

Keywords only update when a new version ships, so this field is version-locked like What's New.

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

**Current set (`appstore/1.7/`), 21 images.** Dark #0d0d0d ground, lime #D0FF00 accent, the app screen below a short headline. Each language sits in its own folder (`en/`, `da/`, `es/`), so no set is the implicit default. English covers all five platforms: four iPhone (running timer, three-mode setup, Intervals, For Time), one iPad, one Mac, two Apple TV, one Apple Watch. Danish (`da/`) and Spanish (`es/`) repeat the four iPhone shots plus iPad and Watch, which is what the iOS app record needs for a localized listing. Mac and Apple TV are separate app records and stay English only.

Capture rule learned in 1.7: set the simulator's **system** language, not just the app's, before capturing iPad. The iPad status bar renders its date from the system locale, so an app launched with `-AppleLanguages` still showed a Danish date on the English screenshot. `xcrun simctl status_bar` fixes the time but not the date, and it is unsupported on watchOS, so Watch captures show whatever the clock says.

Apple Watch shots stay uncaptioned; the screen is too small for a caption band.

**The two Apple TV shots sit on a photograph** ([`appstore/photos/`](../appstore/photos/), Unsplash, see the README there for the licence check). The landscape canvas leaves room for the gym to read around the screen, which backs the "readable from across the gym" claim with context the UI cannot show. iPhone, iPad and Mac keep the plain brand ground: on a portrait canvas the photo is reduced to slivers at the edges and reads as noise, and the two nearest competitors both ship plain dark grounds, so a photo is a differentiation bet rather than a norm.

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

**The Mac app has no audio cues and no Apple Health.** `WorkoutSoundManager` is `#if os(iOS) || os(tvOS)`
and `HealthKitWorkout` is `#if os(iOS)`, so Mac copy must never promise either, and it cannot claim
the watch follows along (that link is iPhone to Watch). Verified in code for 1.7.

## Subtitle (max 30 characters)

```
EMOM & Intervals Timer
```

## Promotional Text (optional, max 170 characters)

EN (161):

```
EMOM, intervals and For Time on your Mac. One purchase runs on iPhone, iPad, Apple Watch, Mac and Apple TV. No subscription, no ads. The only WOD timer you need.
```

Spanish (170, at the ceiling):

```
EMOM, intervalos y For Time en tu Mac. Una compra funciona en iPhone, iPad, Apple Watch, Mac y Apple TV. Sin suscripción ni anuncios. El único temporizador que necesitas.
```

## Description (required)

```
Interval timer for EMOM, For Time, CrossFit and HIIT, on your Mac. No account, no sign-up. Just time, rounds and room to train.

EMOM runs 1 to 120 rounds with a round length between 0:30 and 9:30. Intervals is work, rest and rounds that you set yourself, so Tabata is 20/10 times 8 whenever you want it. For Time counts up from zero, you press Stop when you finish, and you can set a time cap if you want one.

The window stays compact and the numbers stay large, so you can put it in a corner of the screen and still read it from the mat. It keeps time when the window is behind something else, and it follows your light or dark appearance.

One purchase covers iPhone, iPad, Apple Watch, Mac and Apple TV. No subscription, no ads and nothing to buy inside the app.

A timer for training. No logbook, no sharing and no account.
```

## Keywords (max 100 characters)

Applied with 1.7 (89). Dropped "Mac" and "desktop timer": everything in the Mac App Store is a Mac
app, so the word does no work there.

```
Tabata,HIIT,CrossFit,for time,countdown,stopwatch,gym,workout,functional,fitness,training
```

## Screenshots (Mac)

Mac App Store requires screenshots at 1280 × 800, 1440 × 900, 2560 × 1600, or 2880 × 1800. The current set uses 2560 × 1600 (the compact window centered on the brand background). English only; the Mac record has no localized screenshots.

---

# Apple TV App (tvOS)

**Apple TV does have audio cues** (unlike Mac) and an on-screen mute control, but no Apple Health,
no Watch link, and no review prompt (`requestReview` does not exist on tvOS). Since 1.6.1 the app
also holds off the system screensaver while a workout runs, which is worth saying plainly: it was
the bug people actually hit.

## Subtitle (max 30 characters)

```
EMOM & Intervals Timer
```

## Promotional Text (optional, max 170 characters)

EN (166):

```
EMOM, intervals and For Time on the big screen, with voice cues the whole room can hear. One purchase runs on every Apple device you own. The only WOD timer you need.
```

Spanish (166):

```
EMOM, intervalos y For Time en la pantalla grande, con señales de voz que oye toda la sala. Una compra vale para todos tus dispositivos Apple. El único que necesitas.
```

## Description (required)

```
Interval timer for EMOM, For Time, CrossFit and HIIT, on the TV everyone in the room can see. No account, no sign-up. Just time, rounds and room to train.

EMOM runs 1 to 120 rounds with a round length between 0:30 and 9:30. Intervals is work, rest and rounds that you set yourself, so Tabata is 20/10 times 8 whenever you want it. For Time counts up from zero, you press Stop when you finish, and you can set a time cap if you want one.

The numbers fill the screen, so nobody has to walk over and check the clock. Voice cues carry the room through it: get ready, halfway, ten seconds, 3-2-1 and rounds remaining at ten, five and two. You can mute them from the remote. The screensaver stays out of the way for as long as the workout is running.

One purchase covers iPhone, iPad, Apple Watch, Mac and Apple TV. No subscription, no ads and nothing to buy inside the app.

A timer for training. No logbook, no sharing and no account.
```

## Keywords (max 100 characters)

Applied with 1.7 (89). "box" and "class" are tvOS-only: Apple TV is the one platform where the
buyer is plausibly setting the timer for a room full of people.

```
Tabata,HIIT,CrossFit,for time,countdown,gym,workout,box,functional,fitness,training,class
```

## Screenshots (Apple TV)

1920 × 1080 or 3840 × 2160. Three shots since 1.6.1. The two current ones sit on a gym photograph (see Previews and Screenshots above). English only, so a Spanish listing on tvOS shows the English images until Spanish captures are made.

---

# Spanish — which variant, and where

**Open decision, must be settled before 1.8.** As of 1.7 the store localizations disagree with each
other and with the app:

| Surface | Spanish variant |
|---|---|
| iOS listing | Spanish (Mexico) |
| Mac listing | Spanish (Spain), added 1.7 |
| Apple TV listing | Spanish (Spain), added 1.7 |
| App UI (`es.lproj`) | one bundle, written in Latin American Spanish |

So a buyer in Spain reads peninsular store copy and then opens an app that says "presiona" and
"cuenta regresiva", and a buyer in Mexico sees peninsular copy on Mac and Apple TV. Nothing is
broken, but it is incoherent.

Two clean ways out. Either move Mac and Apple TV to **Spanish (Mexico)**, which matches iOS and the
app and covers Latin America plus US Hispanic storefronts, or keep Spain on those two and neutralise
the handful of Latin American words in `es.lproj` so one bundle reads acceptably in both.
Recommendation is the first: it is a metadata change rather than a code change, and the strategy
repo's territory data shows the Spanish traffic that actually exists is Mexican.

Note also that the strategy repo argues **against** a localized tvOS listing at all: Apple TV traffic
is 78% English-speaking and Mexico is 9 page views over four months, against a per-release metadata
cost that recurs forever. That analysis predates the 1.7 decision to add one; revisit it rather than
treating it as settled.

## iOS (es-MX)

Neutral Latin American vocabulary ("cuenta regresiva", not the peninsular "cuenta atrás"). App name
stays **WODrounds**. As of 1.7 the app UI is localized too; only the spoken audio cues stay English,
and the description now says so, because a Spanish-speaking buyer would otherwise reasonably expect
Spanish audio.

### Subtitle (30 of 30)

```
Temporizador EMOM e intervalos
```

### Description

```
Temporizador de intervalos para EMOM, For Time, CrossFit y HIIT. Sin cuenta, sin registro. Solo tiempo, rondas y espacio para entrenar.

EMOM corre de 1 a 120 rondas con una duración de ronda entre 0:30 y 9:30. Intervalos son trabajo, descanso y rondas que tú defines, así que Tabata es 20/10 por 8 cuando quieras. For Time cuenta desde cero, presionas Detener al terminar, y puedes poner un límite de tiempo si lo quieres.

Empieza en tu iPhone y el reloj muestra el mismo tiempo y la misma ronda. También puedes configurar un EMOM o una sesión de intervalos en el reloj y dejar el teléfono en la mochila.

Las señales de audio te llevan: prepárate, a la mitad, diez segundos, 3-2-1 y rondas restantes en diez, cinco y dos. Están grabadas en inglés. Los números se leen a distancia, todo funciona con una mano, y el temporizador sigue corriendo con la pantalla apagada.

Una compra cubre iPhone, iPad, Apple Watch, Mac y Apple TV. Sin suscripción, sin anuncios y nada que comprar dentro de la app.

Un temporizador para entrenar. Sin bitácora, sin compartir y sin cuenta.
```

### Keywords (97)

```
HIIT,Tabata,CrossFit,gimnasio,cronómetro,cuenta regresiva,entrenamiento,for time,ejercicio,fuerza
```

---

# Danish (da) — iOS

New in 1.7, and the highest-value addition in the release: Danish is the **second-largest language
area** at 16% of page views with no localized listing before now, and Denmark is the strongest sales
territory. iPhone is 54% of page views, so iOS is where it belongs. Danish screenshots exist for
iPhone, iPad and Apple Watch (`appstore/1.7/da/`); Mac and Apple TV have none, so those records stay
English.

Written in prose from the start, per VOICE.md.

## Subtitle (21 of 30)

```
EMOM og intervaltimer
```

## Description

```
Intervaltimer til EMOM, For Time, CrossFit og HIIT. Ingen konto og ingen oprettelse. Bare tid, runder og ro til at træne.

EMOM kører 1 til 120 runder med en rundelængde mellem 0:30 og 9:30. Intervaller er arbejde, hvile og runder som du selv sætter, så Tabata er bare 20/10 gange 8. For Time tæller op fra nul, du trykker Stop når du er færdig, og du kan sætte en tidsgrænse hvis du vil have en.

Start på din iPhone, og uret viser samme tid og samme runde. Du kan også sætte en EMOM eller et intervalpas op direkte på uret og lade telefonen blive i tasken.

Undervejs får du lydcues: gør dig klar, halvvejs, ti sekunder, 3-2-1 og runder tilbage ved ti, fem og to. De er indtalt på engelsk. Tallene er store nok til at læse på afstand, alt kan betjenes med én hånd, og timeren kører videre når skærmen slukker.

Ét køb dækker iPhone, iPad, Apple Watch, Mac og Apple TV. Intet abonnement, ingen reklamer og intet at købe inde i appen.

En timer til træning. Ingen logbog, ingen deling og ingen konto.
```

## Keywords (99)

```
crossfit,tabata,hiit,træning,nedtælling,stopur,fitness,cirkeltræning,styrketræning,apple watch,puls
```
