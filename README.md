# WODrounds

WODrounds is a minimal, native Apple platform interval timer built with SwiftUI.

The goal is the simplest, most focused WOD timer experience across:
- **iPhone & iPad**
- **macOS**
- **Apple TV**
- **Apple Watch** (companion app, synced with iPhone)

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
6. **Start on iPhone, follow on Watch** — one workout, one state

This is not a social app. This is not a tracking app. This is a tool.

---

## Supported Modes (v1)

### EMOM
- Set number of rounds (1–120) and **custom round length** (0:30–9:30, 30s increments).
- Total time = rounds × custom length (e.g. 10 rounds @ 1:30 → 15:00).
- Round counter; per-round countdown; Start / Pause / Resume / Reset; Cancel during run/pause.

### Intervals
- Work (seconds), rest (seconds), rounds — each with +/− and label above value.
- Total time = `rounds × work + (rounds − 1) × rest` (no rest after last work).
- Phase display (Work / Rest); same Start / Pause / Resume / Reset / Cancel as EMOM.

Tabata (e.g. 20/10 × 8) is a manual Intervals preset.

**In-app flow:** Choose EMOM or Intervals → set rounds (and for Intervals: work/rest) → Start → timer runs → Pause/Resume or Cancel → on completion, Done screen → Reset returns to setup.

---

## Architecture

### Targets

- **WODrounds** — Main app: iOS, iPadOS, macOS, tvOS. One target, multiple destinations.
- **WODrounds Watch** — Embedded Watch App (watchOS). Separate target; bundled inside the iOS app for distribution and TestFlight.

### Main app (WODrounds)

**Core files:**
- **Shared/WODTimerEngine.swift** — Shared with Watch target. State machine for EMOM + Intervals; Date-based, deterministic; no UI/sound/haptics. effectiveWorkoutEndDate(now:) for HealthKit active-time.
- **WODTimerSync.swift** — Writes timer state to App Group so the Watch can display the same workout.
- **DesignTokens.swift** — IAMJARL design tokens (spacing, radius, typography, colors light/dark).
- **ContentView.swift** — Per platform (`#if os(iOS)` etc.). iOS/iPadOS and macOS: full UI; tvOS: full UI; **no watchOS block** (Watch has its own app).
- **SharedTimerViews.swift** — Shared UI components (stepper, primary button, done view, etc.).
- **WODroundsApp.swift** — App entry, `WindowGroup { ContentView() }`.

**Engine behaviour:**
- Platform-agnostic (Foundation only).
- Date-based: elapsed = now − startDate − accumulatedPauseDuration; no frame timers.
- Actions: start(now:), pause(now:), resume(now:), reset(), tick(now:).
- Snapshot: state, remainingTime, currentRound, currentPhase (work/rest), remainingTimeInPhase, secondsIntoCurrentMinute (EMOM).

### Watch app (WODrounds Watch)

**Folder:** `WODroundsWatch/`

- **WODroundsWatchApp.swift** — Watch app entry (`@main`), `WindowGroup { WatchContentView() }`.
- **WatchContentView.swift** — Timer UI: reads synced state from App Group when iPhone is running a workout; otherwise local timer with Start/Pause/Resume/Reset.
- **WatchDesign.swift** — Design tokens for Watch (colors, spacing, typography) aligned with main app (green accent, light/dark).
- **Shared/** — WODTimerEngine is shared with the main app target; Watch uses it for local-only workouts.
- **WODTimerSync.swift** — Reads shared state from App Group; computes remaining time and round from iPhone’s payload.
- **Assets.xcassets** — AppIcon (all watchOS roles) and AccentColor.

**iPhone ↔ Watch sync:**
- **App Group:** `group.com.iamjarl.WODrounds` (entitlements on both iOS and Watch targets).
- **Flow:** User starts workout on iPhone → app writes state (startDate, pause, mode, rounds) to shared UserDefaults every second and on every action → Watch reads it and shows the same remaining time and round (“Følger iPhone”). Pause/Resume/Reset on iPhone updates the Watch immediately.
- **Watch-only:** If no synced state (or idle/finished), Watch shows its own timer; user can Start locally on the Watch.

**Apple Health (iOS):**
- **HealthKit** capability and usage strings in Info.plist (`NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`).
- **HealthKitWorkout.swift** — Starts an HK workout (HIIT) when the timer starts (after countdown), ends it on Finish / Reset / Cancel. Duration in Health = active time (pauses excluded, via `effectiveWorkoutEndDate`). Authorization on first Start; workouts appear in the Health app and in Activity.

---

## Design System (IAMJARL)

The main app follows the IAMJARL design system. No hardcoded colors, spacing, radius, or typography in UI.

**Source of truth:**
- Design rules: https://jarllyng.github.io/iamjarl-design/design.md
- Tokens (JSON): https://jarllyng.github.io/iamjarl-design/tokens.json
- SwiftUI template: https://github.com/JarlLyng/iamjarl-design/tree/main/templates/swiftui

**Local mapping:** `DesignTokens.swift` in the main app (spacing, radius, typography, colors for light/dark via `DesignTokens.Common.*(scheme)`). The Watch app uses `WatchDesign.swift` with the same color semantics (primary green, background, text hierarchy).

**Guidelines:**
- Heavy whitespace; large monospaced numbers; clear hierarchy; minimal color; dark-first.
- Primary for main actions; error for destructive (e.g. Cancel).
- Buttons solid and tactile; timer dominates the screen.

**Localization:** Main app and Watch have `en.lproj` and `da.lproj` with Localizable.strings. Development language is English; Danish translations for key UI strings (dialogs, buttons, "Following iPhone" on Watch).

---

## Platform Strategy

- **WODrounds target:** iPhone, iPad, macOS, Apple TV. `SUPPORTED_PLATFORMS`: iphoneos, iphonesimulator, macosx, appletvos, appletvsimulator (no watchOS).
- **WODrounds Watch target:** watchOS only. Embedded in the iOS app via “Embed Watch Content” build phase; one iOS archive includes both iPhone and Watch app for TestFlight/App Store. **Embed and Watch target dependency use `platformFilter = ios`** so Mac archives do not build or embed the Watch app (avoids CodeSign “unsealed contents” on macOS). See `docs/ARCHIVE.md` for details.

**v1:** iPhone & iPad (full UI + sync to Watch) → Watch (synced + local timer) → macOS → tvOS (full UI). No visionOS.

---

## App Icons & Asset Sizes

**iOS / iPadOS** (WODrounds/Assets.xcassets/AppIcon.appiconset):
- 1024×1024 @1x — Standard, Dark, Tinted.

**Watch** (WODroundsWatch/Assets.xcassets/AppIcon.appiconset):
- 1024×1024 (watch-marketing).
- All roles: notificationCenter (24, 27.5, 33), companionSettings (29 @2x/@3x), appLauncher (40–54), longLook (44, 50), quickLook (86–129). Required for App Store validation.

**tvOS** (WODrounds/Assets.xcassets/AppIcon.brandassets):
- App Icon – Small: 400×240 px. App Icon – Large: 1280×768 px. Top Shelf: 1920×720 / 2320×720 px. Layer images: Light + Dark.

---

## Signing & Distribution

**Automatic signing:** Signing & Capabilities for both **WODrounds** and **WODrounds Watch** with “Automatically manage signing” and the same Team. Each target has an entitlements file:

- **WODrounds:** `WODrounds/WODrounds.entitlements` — App Group `group.com.iamjarl.WODrounds`, HealthKit.
- **WODrounds Watch:** `WODroundsWatch/WODroundsWatch.entitlements` — same App Group.

**Apple Developer:** Ensure the App Group `group.com.iamjarl.WODrounds` exists under Identifiers → App Groups, and that it is enabled for both the main app’s App ID and the Watch app’s App ID. Xcode can add the App Group when you first build with the entitlements. Enable **HealthKit** for the main app's App ID if needed (Signing & Capabilities).

**TestFlight / App Store (iOS + Watch):**
1. Destination **Any iOS Device**.
2. **Product → Archive**.
3. **Distribute App** → App Store Connect. One archive contains both the iPhone app and the Watch app; TestFlight will offer the Watch build to testers with an Apple Watch.

**Før TestFlight:** DSN i `Sentry.xcconfig` (så arkiv får crash reporting); ingen test-knapper i UI. Privacy Policy og Support nævner Sentry. Se `docs/ARCHIVE.md` for arkiv-destinationer.

**Mac archive:** Use destination **Any Mac** to produce a macOS-only archive (no Watch app). Signing uses `WODrounds-Mac.entitlements`; Watch is not built or embedded for this destination.

---

## Development Rules for Cursor

- Keep logic deterministic and explicit; simple state machines.
- Avoid overengineering and third-party libraries.
- Deployment targets are set per platform in the project; SwiftUI only.
- Timer updates from Date (e.g. `TimelineView(.periodic(from:by:))` + `snapshot(now:)` / `tick(now:)`).
- New features: simple, clear, no UI noise. When in doubt, choose the simpler solution.

---

## Future Considerations (Not v1)

- Notifications (local reminders)
- Sound + haptic cues
- Live Activities / Dynamic Island
- Apple Watch complication
- Presets library
- Paid “Pro” version

Do not let these drive current architecture.

---

## Current Status

- **Engine:** EMOM + Intervals, Date-based, start/pause/resume/reset/tick, snapshot with phase and remaining times. Single shared engine in `Shared/WODTimerEngine.swift`; both main app and Watch target use it.
- **iOS/iPadOS:** Full UI (mode switch, steppers, primary button, Cancel, Done, About). Writes sync state to App Group on every timer action and every second while running. **Apple Health:** HIIT workouts saved to Health when user grants permission (first Start); duration = active time (pauses excluded). End on Finish / Reset / Cancel. Haptics, idle timer off during workout, DesignTokens, light/dark.
- **Watch:** Embedded Watch App. Reads App Group; when iPhone has a running/paused workout, Watch shows same time and round (“Følger iPhone”). Otherwise local timer with Start/Pause/Resume/Reset. WatchDesign (green accent, light/dark). All required Watch icon roles for store validation.
- **macOS:** Same feature set as iOS; compact window; DesignTokens.
- **tvOS:** Full UI, DesignTokens, focusable controls.
- **App Store:** Export compliance (ITSAppUsesNonExemptEncryption = NO); PrivacyPolicy.md, Support.md; About screen with version/build and privacy line. **Sentry** for crash/error reporting on iOS only (DSN via `Sentry.xcconfig`; see `docs/SENTRY.md`). Klar til TestFlight.

Build iteratively. Ship small. Stay focused.

---

## Build & run

- **Xcode:** Open `WODrounds.xcodeproj`. Select scheme **WODrounds** (iOS) or **WODrounds Watch** (watchOS). Build and run on simulator or device.
- **iOS + Watch:** Use “Any iOS Device” (or a physical iPhone) to run the main app; the Watch app is embedded and installs with the iOS app. For Watch-only runs, choose the Watch scheme and a watchOS simulator/device.
- **Tests:** `WODroundsTests` uses Swift Testing; run tests via **Product → Test** or `⌘U`.

---

## For reviewers

- **Entry points:** `WODroundsApp.swift` (main), `ContentView.swift` (platform UI), `Shared/WODTimerEngine.swift` (core timer logic).
- **Sync:** App Group key `group.com.iamjarl.WODrounds`; write in `WODTimerSync.swift` (iOS), read in `WODroundsWatch/WODTimerSync.swift`.
- **Health:** `HealthKitWorkout.swift` (iOS only); authorization on first Start, workout start/end tied to timer in `ContentView.swift` (`#if os(iOS)`).
- **Design:** `DesignTokens.swift` (main app), `WatchDesign.swift` (Watch); no hardcoded colors/spacing in UI.
- **Docs:** This README; `PrivacyPolicy.md` and `Support.md` for store/support.

---

## Marketing site (GitHub Pages)

A static marketing site lives in **`docs/`** (index.html + style.css) for use with GitHub Pages.

**Enable:** Repo → **Settings → Pages** → Source: **Deploy from a branch** → Branch: **main**, Folder: **/docs** → Save.  
The site will be available at `https://<username>.github.io/WODrounds/` (e.g. `https://jarllyng.github.io/WODrounds/`).

**Content:** Hero, app screenshots (iPhone + Watch), features, principles, CTA. Privacy and Support are own pages; no public repo links. Add your screenshots as `docs/images/iphone.png` and `docs/images/watch.png` (see `docs/images/README.txt`). Replace the App Store URL in `docs/index.html` when the app is published.

**SEO:** Canonical URLs, Open Graph and Twitter Card meta, `robots` index/follow, JSON-LD `SoftwareApplication` on the homepage. Update the base URL in meta tags if you use a custom domain. **Animationer:** Hero fade-in med stagger, sektioner fader ind ved scroll (Intersection Observer); respekterer `prefers-reduced-motion`.
