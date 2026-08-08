# CLAUDE.md: WODrounds

Quick-start context for developers and AI assistants. Detailed specs in `docs/`.

## What is WODrounds?

A minimal SwiftUI interval timer for CrossFit — EMOM, Intervals (Tabata) and For Time — across iPhone, iPad, Apple Watch, Mac and Apple TV. A single-purpose tool: **not** social, **not** workout tracking. No accounts, no ads, no subscription. Start a workout on iPhone and follow it on Watch (one workout, one synced state).

- **Developer:** Jarl Lyng / [IAMJARL](https://iamjarl.com)
- **Website:** [wodrounds.iamjarl.com](https://wodrounds.iamjarl.com)
- **App Store:** [apps.apple.com/app/wodrounds/id6759229877](https://apps.apple.com/app/wodrounds/id6759229877)
- **License:** [MIT](LICENSE), open source.
- **Price:** $2.99 USD one-time (no in-app purchases, no subscription, no ads)
- **Platforms:** iPhone, iPad, Apple Watch, Mac, Apple TV (SwiftUI; one target, multiple destinations + an embedded Watch target)

## Strategy lives in a private hub

Target audience, positioning, pricing reasoning, SEO/ASO playbooks, and competitor analysis are **not** in this public repo. They live in a separate private strategy hub. Before doing any audience, positioning, pricing, or marketing-planning work, read that hub's `CONVENTIONS.md` and write results there, not here.

### Voice (read before writing ANY public copy)

All public copy (App Store text, site copy, community posts, replies, release notes) follows the hub's `VOICE.md`, base voice plus this app's overlay. Hard rules: no em-dashes, no bullet lists in public copy, minimal emojis, avoid AI-sounding phrasing, and always pay-once framing (never "free"). WODrounds' overlay is athlete-direct: concrete numbers, features by their real names, no bro-hype and no intensity worship. The maker's first-person story is the proven register. A voice audit of existing copy is tracked in the hub's WODrounds backlog; fold it into the next metadata or site touch.

## App features (be precise; do not invent features that don't exist)

- **EMOM:** set rounds (1–120) and a custom round length (0:30–9:30, 30s steps); round counter + per-round countdown.
- **Intervals:** work / rest / rounds, each adjustable; phase display (Work / Rest). Total = `rounds × work + (rounds − 1) × rest` (no rest after last work).
- **Tabata:** a manual Intervals preset (e.g. 20/10 × 8), not a separate mode.
- **For Time (new in 1.5):** counts up from zero; optional time cap (0:30–60:00, 30s steps; 0 = "No cap"). Uncapped runs until Stop; capped auto-finishes at the cap. Stop freezes the final time; Done screen shows "Finished in MM:SS". No rounds, no in-round cues. Watch follows a synced For Time (no local Watch For Time).
- Start / Pause / Resume / Reset / Cancel; Done screen on completion. For Time uses Stop instead of Pause while running.
- **iPhone → Watch sync** via WatchConnectivity (start on iPhone, follow on Watch).
- **Watch standalone (new in 1.6):** the Watch configures and runs EMOM and Intervals on its own (mode switch + steppers, settings persisted via `@AppStorage`). For Time is still synced-only on the Watch.
- **Date-based timing:** reliable when backgrounded; deterministic engine (`Shared/WODTimerEngine.swift`), no UI/sound in the engine.
- Sound cues (count-in, halfway, 10s, 3-2-1, rounds-remaining), haptics (iOS), HealthKit save as HIIT (iOS only).
- **Localization (new in 1.7):** UI in English, Danish and Spanish (es-MX). Spoken audio cues are recorded English voice files and stay English in every language; do not claim localized audio.

### Features that do NOT exist (common hallucination targets)
- No AMRAP mode; the modes are EMOM, Intervals, and For Time (For Time added in 1.5).
- No workout *tracking* / history / logbook; it's a timer, not a tracker.
- No social, sharing, or accounts.
- No cloud sync or internet dependency.

## Requirements & build
- Open `WODrounds.xcodeproj`; scheme **WODrounds** (iOS) or **WODrounds Watch** (watchOS).
- Tests: `WODroundsTests` uses Swift Testing (**Product → Test** / ⌘U).
- Releasing: Xcode Cloud builds/uploads all platforms when the `release` branch moves (`git push origin main:release`); `main` pushes never build. Do not archive manually. Runbook: `docs/RELEASING.md`.
- Docs: run `python3 scripts/validate_docs.py` before committing docs changes (also enforced by `.github/workflows/docs.yml`).

## Conventions
- Uses `iamjarl-design` tokens via SPM; `DesignTokens.swift` re-exports the package and adds app-specific font sizes; no hardcoded colors.
- Privacy-first: no tracking; HealthKit writes stay on-device.
