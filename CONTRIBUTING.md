# Contributing to WODrounds

Thanks for your interest. WODrounds is a solo indie project — I (Jarl) build it for myself and ship what makes the app better for the kind of training I do. That shapes how this repo accepts contributions.

## What I welcome

- **Bug reports.** Open an [issue](https://github.com/JarlLyng/WODrounds/issues) with steps to reproduce, expected vs. actual behavior, and the device/OS version. Logs from Sentry-style stack traces are gold.
- **Feature requests.** Open an issue. I'll read everything, but the bar for adding features is intentionally high — see "Design philosophy" below.
- **Documentation fixes.** Typos, broken links, outdated examples in `docs/` — PRs welcome and almost always merged.
- **Forks.** The MIT license means you can fork this repo and ship your own version. If you do something cool with it, I'd love to hear about it.

## What's a harder sell

- **Large feature PRs without a prior issue discussion.** Please open an issue first so we can talk about whether it fits the wedge.
- **Refactors that don't fix a concrete bug or unblock a feature.** The codebase is intentionally small. I'd rather it stay that way.
- **New third-party dependencies.** The app uses zero third-party deps in the timer code. Sentry is opt-in for crash reporting on iOS only. Adding deps requires a strong case.

## Design philosophy

WODrounds is deliberately minimal. The wedge is "the minimal Apple-first EMOM and interval timer for CrossFit and HIIT, with no accounts, no ads, no subscription." Every change is weighed against that wedge.

Things that strengthen the wedge:
- Better timer reliability across platforms
- Tighter Apple Watch integration
- Better accessibility
- Clearer single-task UI

Things that weaken the wedge:
- Feature creep (workout logging, social features, libraries of presets, etc.)
- Cross-platform support (Android, web)
- Accounts or sign-in flows
- Anything that slows down "open app → start timer"

If you're unsure whether something fits, open an issue and ask before writing code.

## Code style

- SwiftUI only. No UIKit unless absolutely necessary (haptics is the current exception on iOS).
- Date-based timer logic. Never frame timers — they break when backgrounded.
- Shared engine in `Shared/` for cross-target use. Platform-specific code in `WODrounds/` (iOS/iPadOS/macOS/tvOS) and `WODroundsWatch/` (watchOS).
- Native Apple frameworks only. No Combine where SwiftUI's built-in state management suffices.
- Tests in `WODroundsTests/`. Engine logic should have unit tests.

## Local setup

1. Clone the repo
2. Open `WODrounds.xcodeproj` in Xcode
3. Optional: copy `Sentry.xcconfig.example` to `Sentry.xcconfig` and add your DSN if you want crash reporting locally. The build works without it.
4. Run `python3 scripts/validate_docs.py` before committing changes to `docs/`. It catches broken image refs, schema issues, and other doc bugs.

## Pull request expectations

- Keep PRs focused. One PR = one logical change.
- Pass the existing tests + add new ones for the new behavior.
- Build cleanly on iOS, watchOS, macOS, and tvOS targets.
- For UI changes: include before/after screenshots in the PR description.
- If your PR touches `docs/`, the CI will validate it — green checkmark required.

## What I don't promise

- Fast review. I have a day job. Issues might sit for weeks.
- Acceptance of every PR. I will be honest if something doesn't fit, but always polite about it.
- Backwards compatibility for forks. If the architecture changes, your fork might need work to merge upstream.

## Reporting security issues

See [SECURITY.md](SECURITY.md). Don't open public issues for security problems — email me directly.

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md).
