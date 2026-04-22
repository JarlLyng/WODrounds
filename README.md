# WODrounds — EMOM & Interval Timer for CrossFit and HIIT

Minimal SwiftUI timer for CrossFit, EMOM, Tabata and intervals on iPhone, iPad, Apple Watch, Mac and Apple TV. No accounts, no ads, no subscription — a single-purpose tool (not social, not workout tracking).

**[wodrounds.iamjarl.com](https://wodrounds.iamjarl.com)** · [App Store](https://apps.apple.com/app/wodrounds/id6759229877)

[![Co-created with AI](https://madebyhuman.iamjarl.com/badges/co-created-white.svg)](https://madebyhuman.iamjarl.com)

**Principles:** ultra-minimal UI; large type; one-handed use; Date-based timing (reliable when backgrounded); native Apple stack; **start on iPhone, follow on Watch** (one workout, one synced state).

---

## Supported Modes

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
- **WODrounds Watch** — Embedded Watch App (watchOS). Separate target; bundled inside the iOS app for distribution.

### Main app (WODrounds)

**Core files:**
- **Shared/WODTimerEngine.swift** — Shared with Watch target. State machine for EMOM + Intervals; Date-based, deterministic; no UI/sound/haptics. `effectiveWorkoutEndDate(now:)` for HealthKit active-time.
- **WODTimerSync.swift** — Sends timer state to Watch via WatchConnectivity.
- **DesignTokens.swift** — Re-exports IAMJARL design tokens from SPM package; adds app-specific font sizes.
- **ContentView.swift** — Shared types (ranges, `TimerUIMode` enum) used by all platform views.
- **iOSContentView.swift** — iOS/iPadOS UI: HealthKit, haptics, sounds, countdown, idle timer.
- **macOSContentView.swift** — macOS UI: compact window (340×560), flash overlay.
- **tvOSContentView.swift** — tvOS UI: focus-based navigation, `.buttonStyle(.card)`, large typography, sounds.
- **SharedTimerViews.swift** — Shared UI components (stepper, primary button, done view, etc.).
- **WorkoutSoundManager.swift** — Sound cues for round transitions, 30-second warning, and completion (iOS + tvOS).
- **HealthKitWorkout.swift** — Saves completed workouts to Apple Health as HIIT sessions (iOS only).
- **WODroundsApp.swift** — App entry, `WindowGroup { ContentView() }`.

**Engine behaviour:**
- Platform-agnostic (Foundation only).
- Date-based: elapsed = now − startDate − accumulatedPauseDuration; no frame timers.
- Actions: start(now:), pause(now:), resume(now:), reset(), tick(now:).
- Snapshot: state, remainingTime, currentRound, currentPhase (work/rest), remainingTimeInPhase, secondsIntoCurrentMinute (EMOM).

### Watch app (WODrounds Watch)

**Folder:** `WODroundsWatch/`

- **WODroundsWatchApp.swift** — Watch app entry (`@main`).
- **WatchContentView.swift** — Timer UI: reads synced state from WatchConnectivity when iPhone is running a workout; otherwise local timer.
- **WatchDesign.swift** — Imports colors from IAMJARL package; Watch-scaled spacing and typography.
- **Shared/** — WODTimerEngine shared with the main app target for local-only workouts.
- **WODTimerSync.swift** — Receives synced state from iPhone via WatchConnectivity.
- **WatchSessionManager.swift** — `ObservableObject` + `WCSessionDelegate`; decodes payload from `didReceiveApplicationContext`.

**iPhone → Watch sync:**
- `WCSession.updateApplicationContext` (iPhone → Watch). No App Group needed.
- iPhone sends state (startDate, pause, mode, rounds) on every action and every second while running → Watch shows the same remaining time and round.
- When no synced state, Watch runs its own local timer.

**Apple Health (iOS):**
- HealthKit capability and usage strings in Info.plist.
- Starts an HK workout (HIIT) when the timer starts (after countdown), ends it on Finish / Reset / Cancel. Duration = active time (pauses excluded). Authorization on first Start.

---

## Design System (IAMJARL)

The app follows the IAMJARL design system via SPM package ([iamjarl-design](https://github.com/jarllyng/iamjarl-design)). No hardcoded colors, spacing, radius, or typography in UI.

**Source of truth:**
- Design rules: https://jarllyng.github.io/iamjarl-design/design.md
- Tokens (JSON): https://jarllyng.github.io/iamjarl-design/tokens.json
- SPM package: `https://github.com/jarllyng/iamjarl-design.git` (added to both WODrounds and Watch targets)

**Local mapping:** `DesignTokens.swift` re-exports the package via `@_exported import` and adds app-specific font sizes. `WatchDesign.swift` imports colors from the package and defines Watch-scaled spacing/typography.

**Guidelines:**
- Heavy whitespace; large monospaced numbers; clear hierarchy; minimal color; dark-first.
- Primary for main actions; error for destructive (e.g. Cancel).
- Buttons solid and tactile; timer dominates the screen.

**Localization:** English only.

---

## Build & run

- **Xcode:** Open `WODrounds.xcodeproj`. Select scheme **WODrounds** (iOS) or **WODrounds Watch** (watchOS). Build and run on simulator or device.
- **iOS + Watch:** Use "Any iOS Device" (or a physical iPhone) to run the main app; the Watch app is embedded and installs with the iOS app.
- **Tests:** `WODroundsTests` uses Swift Testing; run tests via **Product → Test** or `⌘U`.
- **Docs validation:** Run `python3 scripts/validate_docs.py` before committing docs changes. Also runs automatically on every push to `main` via `.github/workflows/docs.yml`. Checks image references, App Store URLs, JSON-LD validity, sitemap integrity, and canonical URLs.

---

## Development Rules

- Keep logic deterministic and explicit; simple state machines.
- Avoid overengineering and third-party libraries.
- Deployment targets are set per platform in the project; SwiftUI only.
- Timer updates from Date (e.g. `TimelineView(.periodic(from:by:))` + `snapshot(now:)` / `tick(now:)`).
- New features: simple, clear, no UI noise. When in doubt, choose the simpler solution.

---

## Task Management

All tasks, bugs and feature requests are tracked as **GitHub Issues** on this repo. Labels: `bug`, `ASO`, `SEO`, `content`, `marketing`.

Do not create task-tracking `.md` files — use Issues instead.

---

## Future Considerations

- Live Activities / Dynamic Island
- Apple Watch complication
- Presets library

Do not let these drive current architecture.

---

## Documentation

Detailed reference docs live in `docs/`:

| File | Description |
|------|-------------|
| [ARCHIVE.md](docs/ARCHIVE.md) | Archive destinations, platform filtering, entitlements |
| [APP_ICONS.md](docs/APP_ICONS.md) | Icon asset checklist for all platforms |
| [APP_STORE_CONNECT.md](docs/APP_STORE_CONNECT.md) | App Store text (subtitle, description, keywords) for iOS, Mac, tvOS |
| [SENTRY.md](docs/SENTRY.md) | Crash reporting setup (iOS only) |
| [SEO_STRATEGY.md](docs/SEO_STRATEGY.md) | Marketing site SEO strategy and roadmap |

Other root-level docs:

| File | Description |
|------|-------------|
| [PrivacyPolicy.md](PrivacyPolicy.md) | Privacy policy for App Store / in-app — **keep in sync** with `docs/privacy.html` |
| [Support.md](Support.md) | Support copy for App Store / in-app — **keep in sync** with `docs/support.html` |

---

## Marketing Site

A static marketing site lives in `docs/` and is deployed via GitHub Pages at **[wodrounds.iamjarl.com](https://wodrounds.iamjarl.com)**.

**Pages (15):** Homepage, EMOM timer, Interval timer, Tabata timer, Apple Watch timer, comparison article, workout examples (EMOM, Tabata, 10-min HIIT, 20-min HIIT, beginner HIIT, home gym HIIT), guide, privacy, support.

**Setup:** Repo → Settings → Pages → Source: Deploy from branch → main, /docs.

**Analytics (site only):** [Umami](https://umami.is/) for aggregate page views (script loaded from our Vercel-hosted instance). The app does not use marketing analytics; iOS uses Sentry for crashes — see [PrivacyPolicy.md](PrivacyPolicy.md). **SEO:** Canonical URLs, Open Graph, Twitter Card, JSON-LD, sitemap.xml.
