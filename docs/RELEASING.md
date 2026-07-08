# Releasing WODrounds

How a release reaches the App Store. Two separate CI systems, one job each:

- **GitHub Actions** runs on pull requests: unit tests, CodeQL, and docs validation. It never builds a release. (Docs-only PRs skip the Swift build and CodeQL via `paths-ignore`; see `.github/workflows/`.)
- **Xcode Cloud** builds and uploads release archives. It runs **only** when the `release` branch moves, so normal pushes and merges to `main` never trigger a build.

## The release flow

1. **Bump the version and build number** in `WODrounds.xcodeproj` (target → General, or edit `project.pbxproj`):
   - `MARKETING_VERSION` (e.g. `1.5.1`) for a user-visible version.
   - `CURRENT_PROJECT_VERSION` (the build number). **Always increase it.** App Store Connect enforces the build number across the whole app record, not per platform, so reusing a number fails with error 90061 even on a platform that never uploaded it. When in doubt, bump.
2. **Update `CHANGELOG.md`** with a new top entry (What's New copy + details).
3. **If anything user-facing changed:** update `docs/APP_STORE_CONNECT.md` (description / keywords / What's New, EN + es-MX) and the marketing site under `docs/`. Run `python3 scripts/validate_docs.py`.
4. **Merge to `main`** via a pull request, as usual. (This does not build anything.)
5. **Trigger the release build** by moving the `release` branch to the new `main`:
   ```sh
   git push origin main:release
   ```
   Xcode Cloud's "Default" workflow archives iOS, macOS and tvOS (build number from step 1), runs `ci_scripts/ci_post_clone.sh` to recreate the gitignored `Sentry.xcconfig`, and uploads all three to App Store Connect.
6. **In App Store Connect:** the builds appear under **TestFlight → Builds**. Test on hardware if you want, then in each platform's **Prepare for Submission** add the build to the version and **submit**. (Xcode Cloud uploads but does not auto-submit to review.)

That is the whole loop. No manual Xcode archives.

## Xcode Cloud configuration (reference)

Configured in App Store Connect → WODrounds → Xcode Cloud → Manage Workflows → **Default**. It is not stored in this repo (only `ci_scripts/` is), so this is the record of how it is set up:

- **Start Condition:** Branch Changes on **`release`** (this is the only condition; there is deliberately no `main` or tag trigger).
- **Actions:** three Archive actions, one each for **iOS**, **macOS** (Build For: Any Mac) and **tvOS**, scheme **WODrounds**, Distribution Preparation = **App Store Connect**.
- **Environment variable:** `SENTRY_DSN` (marked secret) holds the real Sentry DSN. `ci_scripts/ci_post_clone.sh` writes it into `Sentry.xcconfig` after clone. If it were unset the archive still succeeds with crash reporting off (see [SENTRY.md](SENTRY.md)).
- **Post-Actions:** none needed (the Archive action's "App Store Connect" distribution does the upload).

## Why a `release` branch and not a git tag

We first tried triggering on version tags (`v*`). Xcode Cloud's GitHub integration did not pick the tags up for this repo (they never appeared for auto-builds or in the manual Start Build list, even after re-pushing and waiting hours). Branch triggers work reliably here, so the release trigger is a dedicated `release` branch instead. Version tags may still be created as plain markers, but they do not drive CI.

## Fallback: manual archive

If Xcode Cloud is unavailable, you can still release the old way: in Xcode, select the WODrounds scheme and Archive once per destination (Any iOS Device, Any Mac, Any tvOS Device), then Distribute from the Organizer. Make sure the build number is higher than anything already uploaded (see step 1), and pick the newest archive in the Organizer, not a stale one.
