# Changelog

All notable user-facing changes to WODrounds. Newest first.

## Unreleased

- **Added:** the app is now available in **Danish and Spanish (es-MX)**, alongside English. Every screen, button and help text is translated on iPhone, iPad, Mac, Apple TV and Apple Watch.
- **Changed:** new voice recordings for the spoken cues (get ready, rounds remaining, completion). The audio stays English in every language, because these are recorded voice files.
- **Fixed:** a stepper value could run straight through the +/- buttons. The value was pinned to its text's ideal width, which suits "01:00" but not a longer word, so the Danish and Spanish "No cap" overflowed the control. Values now shrink to fit instead.
- **Fixed:** several labels never translated even when a translation existed. SwiftUI shows a plain `String` verbatim, so the mode names, stepper labels, button titles, help text and the round counter were hard-wired to English. They now go through `LocalizedStringKey`.
- **Fixed (iOS):** the review prompt could be lost for good. It matched the completed-workout count exactly (5, 15, 50), so a single skipped count meant that ask never happened. It now asks at the first threshold reached and remembers which ones it has used.
- **Added (macOS):** the Mac app asks for a review too. It never did, so Mac users were never given the chance.
- **Changed (iOS/macOS):** the first review ask moved from 5 completed workouts to 3, with the later ones at 10 and 30 (Apple allows three prompts per year, so this uses them on people who have actually trained with the app rather than saving them for power users). Apple TV cannot ask: the API does not exist on tvOS.
- **Added:** the app now responds to Reduce Motion. Every other animation was already a short crossfade, which is what the setting substitutes for motion anyway; the Apple TV focus effect was the exception and now snaps into place instead of scaling up.
- **Fixed:** VoiceOver read the stepper names and the +/- buttons in English even with the app in Danish or Spanish. The labels went through SwiftUI's non-localizing overload, so the screen said "Rundelængde" while VoiceOver said "Round length".

## 1.6.1 (build 17)

**What's New (App Store copy):**

> Fixed the Apple TV screensaver taking over the screen during a workout.
> Small fixes and polish.

**Details:**

- **Fixed (tvOS):** the Apple TV screensaver could take over the screen mid-workout. Nobody touches the remote during an EMOM, so on a longer workout the system screensaver covered the timer. The app now holds it off while a workout is running, paused, or counting in, and releases it as soon as you are back on the setup screen (#98).
- **Changed (iOS, privacy):** crash reporting no longer attaches a screenshot, and performance tracing is off in production. Crash diagnostics now stay device type / OS / app state only, matching what the Privacy Policy describes (never your workout or identity).
- **Changed (macOS):** the Mac app now uses the dark app icon, consistent with the other IAMJARL Mac apps.

## 1.6 (build 16)

**What's New (App Store copy):**

> • Set up workouts directly on your Apple Watch: choose EMOM or Intervals and adjust rounds, round length, work and rest right on the wrist. No iPhone needed.
> • The Watch remembers your settings between workouts.
> • Small fixes and polish.

**Details:**

- **Added (watchOS):** standalone workout configuration (#32, #33). The Watch idle screen is now a setup screen: an EMOM/Intervals mode switch plus steppers for rounds and round length (EMOM) or work, rest and rounds (Intervals), same ranges as iOS. Values persist via `@AppStorage`; previously standalone was hardcoded to 10 × 1:00 EMOM. Synced (iPhone-driven) workouts are unchanged, and there is still no local For Time on the Watch.
- **Added (iOS/macOS):** a discreet "Also from IAMJARL" section on the About screen linking Anvil Workout and Walkful on the App Store. Not on tvOS (no browser hand-off there).
- **Release note:** the expanded App Store keyword fields from `docs/APP_STORE_CONNECT.md` (staged 2026-07-11) apply with this release.

## 1.5.1 (build 15)

**What's New (App Store copy):**

> • Fixed the info button overlapping the For Time tab on iPhone.
> • Tidied the About screen so Support and Privacy Policy sit correctly.

**Details:**

- **Fixed (iOS):** with the third mode added in 1.5, the setup screen's mode switch reached under the pinned top-right controls, so the info icon overlapped the "For Time" tab. The mode switch now clears the controls.
- **Fixed (iOS/macOS/tvOS):** the About screen's Support and Privacy Policy links were left-aligned in a block that then centered as a narrow column, reading as "pushed toward the middle". They now center like the rest of the screen.

## 1.5 (build 13 on iOS; build 14 on macOS/tvOS)

**What's New (App Store copy):**

> • New: For Time mode. The clock counts up from zero; press Stop when you finish and your time is saved. Set an optional time cap and the timer stops there automatically.
> • For Time works on iPhone, iPad, Mac and Apple TV, and your Apple Watch follows along when you start on iPhone.
> • Small fixes and polish.

**Details:**

- **Added:** For Time timer mode (#15): counts up from zero. Two variants: uncapped (runs until you press Stop) and capped (auto-finishes at the cap; 0:30–60:00 in 30s steps via a single "Time cap" stepper whose 0 position reads "No cap"). The Done screen shows "Finished in MM:SS" and the workout saves to Apple Health with the real active time (pauses excluded, time frozen at Stop).
- **Added:** Apple Watch follows a synced For Time workout: elapsed time counts up on the wrist, no round display.
- **Changed:** In For Time the primary button during a run is **Stop** (a For Time clock isn't paused); Cancel still discards the workout. In-round audio cues (halfway, ten-seconds, 3-2-1, rounds-remaining) don't apply to For Time and stay silent; the completion sound still plays.
- **Internal:** Timer engine gained `finish(now:)` (freezes the final time) and an `elapsedTime` snapshot field; the Watch sync payload carries `capSeconds`/`finishedAt`. Full unit-test coverage for the new mode.

## 1.4 (build 12)

**What's New (App Store copy):**

> • Cancel the countdown before a workout starts — no more waiting out the 10-second "Get ready" if you tapped Start by mistake.
> • More accurate workout duration in Apple Health: paused time is no longer counted as active.
> • Fixed a doubled audio announcement during interval workouts.
> • Small fixes and polish.

**Details:**

- **Added:** Cancel button during the 10-second count-in on iPhone, iPad, Mac and Apple TV (#38).
- **Fixed:** HealthKit workout duration was inflated when a workout ended or was cancelled while paused — an in-progress pause is now excluded from active time (#34).
- **Fixed:** "X rounds left" voice cues played twice per round in Intervals mode; they now fire once per round (#35).
- **Changed:** Removed the non-functional sound toggle on macOS (macOS has no audio cues) (#37).
- **Fixed:** macOS — the mode switch and Start button were clipped at the default window size; the window now opens tall enough to show the full layout (#47).
- **Changed:** macOS — tidier idle layout: the setup controls are a compact, vertically-centred cluster (only the active mode's steppers render, so EMOM no longer leaves an empty gap reserved for Intervals' third stepper), and the About sheet's Done button is inset from the sheet edges.
- **Fixed:** tvOS — remote focus could get stuck and the buttons became unreachable. The inactive mode's steppers were hidden with opacity but stayed in the focus engine; they're now only rendered for the active mode, so focus navigation works.
- **Changed:** tvOS — calmer focus appearance. The default system focus drew a large white plate behind the bright buttons; buttons now use a subtle lift (gentle scale + soft shadow) instead. (Requires tvOS 17 — `focusEffectDisabled` isn't available on tvOS 16 — so the tvOS minimum is now 17.0.)
- **Fixed:** tvOS — during the "Get ready" count-in, remote focus could land on the idle controls (mode switch / steppers / Start) still sitting behind the overlay. The underlying controls are now disabled while the count-in is showing, so only its Cancel button is focusable.
- **Internal:** Removed dead code (#36); added unit + UI test coverage; fixed and hardened CI (CodeQL build, Node 24 action upgrades, unit-test workflow) (#39, #43, #44). Sentry no longer reports under XCTest, and debug/simulator events are tagged with their own environment so they don't appear as production.
