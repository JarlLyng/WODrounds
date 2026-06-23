# CLAUDE.md — WODrounds

Quick-start context for developers and AI assistants. Detailed specs in `docs/`.

## What is WODrounds?

A minimal SwiftUI interval timer for CrossFit, EMOM, Tabata and intervals across iPhone, iPad, Apple Watch, Mac and Apple TV. A single-purpose tool — **not** social, **not** workout tracking. No accounts, no ads, no subscription. Start a workout on iPhone and follow it on Watch (one workout, one synced state).

- **Developer:** Jarl Lyng / [IAMJARL](https://iamjarl.com)
- **Website:** [wodrounds.iamjarl.com](https://wodrounds.iamjarl.com)
- **App Store:** [apps.apple.com/app/wodrounds/id6759229877](https://apps.apple.com/app/wodrounds/id6759229877)
- **License:** [MIT](LICENSE) — open source.
- **Price:** $2.99 USD one-time (no in-app purchases, no subscription, no ads)
- **Platforms:** iPhone, iPad, Apple Watch, Mac, Apple TV (SwiftUI; one target, multiple destinations + an embedded Watch target)

## Strategy lives in the private hub

Target audience, positioning, pricing reasoning, SEO/ASO playbooks, and competitor analysis are **not** in this public repo — they're in the private [iamjarl-strategy](https://github.com/JarlLyng/iamjarl-strategy) hub (folder `WODrounds/`). Before doing any audience/positioning/pricing/marketing-planning work, read that repo's `CONVENTIONS.md` and write results there, not here.

## App features (be precise — do not invent features that don't exist)

- **EMOM** — set rounds (1–120) and a custom round length (0:30–9:30, 30s steps); round counter + per-round countdown.
- **Intervals** — work / rest / rounds, each adjustable; phase display (Work / Rest). Total = `rounds × work + (rounds − 1) × rest` (no rest after last work).
- **Tabata** — a manual Intervals preset (e.g. 20/10 × 8), not a separate mode.
- Start / Pause / Resume / Reset / Cancel; Done screen on completion.
- **iPhone → Watch sync** via WatchConnectivity (start on iPhone, follow on Watch).
- **Date-based timing** — reliable when backgrounded; deterministic engine (`Shared/WODTimerEngine.swift`), no UI/sound in the engine.
- Sound cues (count-in, halfway, 10s, 3-2-1, rounds-remaining), haptics (iOS), HealthKit save as HIIT (iOS only).

### Features that do NOT exist (common hallucination targets)
- No workout *tracking* / history / logbook — it's a timer, not a tracker.
- No social, sharing, or accounts.
- No cloud sync or internet dependency.

## Requirements & build
- Open `WODrounds.xcodeproj`; scheme **WODrounds** (iOS) or **WODrounds Watch** (watchOS).
- Tests: `WODroundsTests` uses Swift Testing (**Product → Test** / ⌘U).
- Docs: run `python3 scripts/validate_docs.py` before committing docs changes (also enforced by `.github/workflows/docs.yml`).

## Conventions
- Uses `iamjarl-design` tokens via SPM — `DesignTokens.swift` re-exports the package and adds app-specific font sizes; no hardcoded colors.
- Privacy-first: no tracking; HealthKit writes stay on-device.
