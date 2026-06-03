# Changelog

All notable user-facing changes to WODrounds. Newest first.

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
