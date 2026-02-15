# WODrounds

WODrounds is a minimal, native Apple platform interval timer built with SwiftUI.

The goal is the simplest, most focused WOD timer experience across:
- iPhone
- iPad
- macOS
- visionOS

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
- Set number of rounds (1–120). Each round = 1 minute.
- Fixed “1:00 per round”; total time = rounds × 1:00 (e.g. 30 rounds → 30:00).
- Round counter; Start / Pause / Resume / Reset; Cancel (with confirmation) during run/pause.

### Intervals
- Work (seconds), rest (seconds), rounds.
- Total time = `rounds × work + (rounds − 1) × rest` (no rest after last work).
- Phase display (Work / Rest); same Start / Pause / Resume / Reset / Cancel as EMOM.

Tabata (e.g. 20/10 × 8) is a manual Intervals preset.

---

## Architecture

Shared timer engine across platforms.

**Core files:**
- **WODTimerEngine.swift** — State machine for EMOM + Intervals. Date-based, deterministic. No UI, sound, or haptics.
- **DesignTokens.swift** — IAMJARL design tokens (spacing, radius, typography, colors light/dark). Mapped from `tokens.json`.
- **ContentView** — Per platform (`#if os(iOS)` etc.). iOS/iPadOS is the main implementation; macOS, visionOS, watchOS, tvOS have minimal or placeholder UIs.
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
- **Per platform:** ContentView behind `#if os(iOS)` / `os(watchOS)` / `os(tvOS)` / `os(macOS)` / `os(visionOS)`.

**Current build:** iOS, iPadOS, macOS, visionOS (SUPPORTED_PLATFORMS: iphoneos, iphonesimulator, macosx, xros, xrsimulator).

**v1 priority:** iPhone → iPad → Apple Watch → Apple TV. iOS/iPadOS is full-featured (EMOM + Intervals, mode switch, cancel); other platforms minimal or placeholder.

---

## Development Rules for Cursor

- Keep logic deterministic and explicit; simple state machines.
- Avoid overengineering and third-party libraries.
- Target iOS 17+; SwiftUI only.
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
- **iOS/iPadOS:** Mode switch (EMOM / Intervals), Rounds selector (+/−, presets 10/12/20/30), Intervals (work/rest/rounds), primary button, Cancel with confirmation, all token-based, light + dark.
- **Design:** IAMJARL tokens only in iOS UI; DesignTokens.swift present.
- **Other platforms:** ContentView exists for watchOS, tvOS, macOS, visionOS; minimal or placeholder.

Build iteratively. Ship small. Stay focused.
