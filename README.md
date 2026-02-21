# WODrounds

WODrounds is a minimal, native Apple platform interval timer built with SwiftUI.

The goal is the simplest, most focused WOD timer experience across:
- iPhone & iPad
- macOS
- Apple TV
- Apple Watch

No accounts. No analytics. No workout database. No noise.
Only timing, rounds, and focus.

---

## Product Vision

Distraction-free workout timer for functional fitness, CrossFit-style training, HIIT, EMOM, and interval sessions.

Core principles:

1. Ultra-minimal interface
2. Large typography
3. One-handed gym usability
4. Reliable timing (Date-based, works when backgrounded)
5. Native-first Apple experience

This is not a social app. This is not a tracking app. This is a tool.

---

## Supported Modes (v1)

### EMOM
- Set number of rounds (1–120) with +/−. Each round = 1 minute.
- Total time = rounds × 1:00 (e.g. 30 rounds → 30:00).
- Round counter; Start / Pause / Resume / Reset; Cancel (with confirmation) during run/pause.

### Intervals
- Work (seconds), rest (seconds), rounds — each with +/− and label above value.
- Total time = `rounds × work + (rounds − 1) × rest` (no rest after last work).
- Phase display (Work / Rest); same Start / Pause / Resume / Reset / Cancel as EMOM.

Tabata (e.g. 20/10 × 8) is a manual Intervals preset.

**In-app flow:** Choose EMOM or Intervals → set rounds (and for Intervals: work/rest) → Start → timer runs → Pause/Resume or Cancel → on completion, Done screen → Reset returns to setup.

---

## Architecture

Shared timer engine across platforms.

**Core files:**
- **WODTimerEngine.swift** — State machine for EMOM + Intervals. Date-based, deterministic. No UI, sound, or haptics.
- **DesignTokens.swift** — IAMJARL design tokens (spacing, radius, typography, colors light/dark). Mapped from `tokens.json`.
- **ContentView** — Per platform (`#if os(iOS)` etc.). iOS/iPadOS and macOS: full UI; tvOS: full UI (DesignTokens, same flow); watchOS: minimal timer + controls.
- **WODroundsApp.swift** — App entry, `WindowGroup { ContentView() }`.

**Engine behaviour:**
- Platform-agnostic (Foundation only).
- Date-based: elapsed = now − startDate − accumulatedPauseDuration; no frame timers.
- Actions: start(now:), pause(now:), resume(now:), reset(), tick(now:).
- Snapshot: state, remainingTime, currentRound, currentPhase (work/rest), remainingTimeInPhase, secondsIntoCurrentMinute (EMOM).

UI is declarative; business logic stays in WODTimerEngine.

---

## Design System (IAMJARL)

This app follows the IAMJARL design system. No hardcoded colors, spacing, radius, or typography in UI.

**Source of truth:**
- Design rules: https://jarllyng.github.io/iamjarl-design/design.md
- Tokens (JSON): https://jarllyng.github.io/iamjarl-design/tokens.json
- SwiftUI template: https://github.com/JarlLyng/iamjarl-design/tree/main/templates/swiftui

**Local mapping:** `DesignTokens.swift` in the app target (spacing, radius, typography sizes/weights, colors for light/dark via `DesignTokens.Common.*(scheme)`).

**Guidelines:**
- Heavy whitespace; large monospaced numbers; clear hierarchy; minimal color; dark-first.
- Primary for main actions; error for destructive (e.g. Cancel).
- Buttons solid and tactile; timer dominates the screen.

---

## Platform Strategy

Multiplatform SwiftUI; one app target, multiple destinations.

- **Shared:** WODTimerEngine, DesignTokens, shared types.
- **Per platform:** ContentView behind `#if os(iOS)` / `os(watchOS)` / `os(tvOS)` / `os(macOS)`.

**Current build:** One app target for iOS, iPadOS, macOS, tvOS, watchOS (`SUPPORTED_PLATFORMS`: iphoneos, iphonesimulator, macosx, appletvos, appletvsimulator, watchos, watchsimulator). No visionOS.

**v1 priority:** iPhone & iPad → macOS → tvOS (all full UI); watchOS (minimal timer + controls).

---

## App Icons & Asset Sizes

**iOS / iPadOS** (AppIcon.appiconset):
- **1024×1024** @1x — Standard, Dark, Tinted (`luminosity: dark` / `luminosity: tinted`).

**watchOS** (samme AppIcon.appiconset):
- **1024×1024** (watch-marketing, App Store).
- Watch-roles: notificationCenter (24×24, 27.5×27.5), companionSettings (29×29), appLauncher (40×40, 44×44), longLook (44×44), quickLook (86×86, 98×98) — alle @2x, subtype 38mm/42mm hvor relevant.

**tvOS** (AppIcon.brandassets):
- **App Icon – Small:** **400×240** px (Home Screen). Image stack med 2 lag (Front + Back).
- **App Icon – Large:** **1280×768** px (App Store). Samme opbygning.
- **Top Shelf:** **1920×720** px og/eller **2320×720** px (16:9).
- Hvert lag (Front/Back): **Light** og **Dark** i imageset (`luminosity: dark`). Tinted understøttes ikke i tvOS layer-imagesets (Xcode-validering).

---

## Signing & App Store Connect (ét-til-felts opsætning)

For at kunne arkivere og uploade til TestFlight/App Store **uden hacks** skal teamet have mindst én enhed registreret. Det er Apples krav for automatisk signering (development-profiler); distribution bruges ved Archive og kræver ikke enheder.

**Gør én gang:**

1. **Tilføj én enhed** til teamet:
   - Gå til [Certificates, Identifiers & Profiles → Devices](https://developer.apple.com/account/resources/devices/list).
   - Klik **+** og tilføj din iPhone, iPad eller Apple TV (du behøver **UDID** – findes under Finder når enheden er tilsluttet, eller under Indstillinger → Generelt → Om).
   - Eller: tilslut enheden til Mac, vælg den som destination i Xcode, og kør én gang – Xcode kan tilbyde at registrere enheden.

2. **I Xcode:** Signing & Capabilities for target **WODrounds** – “Automatically manage signing” slået til, **Team** valgt (samme som i Developer account).

3. **Ved arkiv:** Vælg destination **Any iOS Device** (eller **My Mac** / **Any tvOS Apple TV** for de andre platforme), derefter **Product → Archive**. Brug **Distribute App** og vælg App Store Connect.

Efter step 1 kan Xcode oprette de nødvendige provisioning profiles; Archive bruger herefter distribution og behøver ikke fysisk enhed.

---

## Development Rules for Cursor

- Keep logic deterministic and explicit; simple state machines.
- Avoid overengineering and third-party libraries.
- Deployment targets are set per platform in the project; SwiftUI only.
- Timer updates from Date (e.g. `TimelineView(.periodic(from:by:))` + `snapshot(now:)` / `tick(now:)`).
- New features: simple, clear, no UI noise. When in doubt, choose the simpler solution.

---

## Future Considerations (Not v1)

- Notifications.swift (local notifications)
- SoundHaptics.swift (audio + haptic cues)
- Live Activities / Dynamic Island
- Apple Watch complication
- Presets library
- Paid “Pro” version

Do not let these drive current architecture.

---

## Current Status

- **Engine:** EMOM + Intervals, Date-based, start/pause/resume/reset/tick, snapshot with phase and remaining times.
- **iOS/iPadOS:** Mode switch (EMOM / Intervals) at top; short help text under mode; timer shown only after Start; Rounds or Intervals (work/rest/rounds) with +/−; primary button at bottom; Cancel with confirmation; Done screen on completion (checkmark + “You completed X rounds” + Reset); About (ⓘ) top-right; haptics (start, EMOM minutes, Intervals phase, finish); idle timer (screen-dimming off during workout); light transitions; all token-based, light + dark.
- **macOS:** Samme feature set som iOS; kompakt vindue; DesignTokens.
- **Design:** IAMJARL DesignTokens i iOS, macOS og tvOS; light/dark via system color scheme.
- **tvOS:** Fuld UI (samme flow som iOS/macOS); DesignTokens; fokusbare knapper. **watchOS:** Minimal timer + Start/Pause/Resume/Reset.
- **App Store:** Export compliance (ITSAppUsesNonExemptEncryption = NO); PrivacyPolicy.md, Support.md; About screen with version/build and privacy line.

Build iteratively. Ship small. Stay focused.
