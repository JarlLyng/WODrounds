# Sentry (iOS)

Crash reports, crash-free sessions, MetricKit diagnostics and two anonymous feature counts go to **Sentry on iOS only** (not macOS, tvOS, or Watch). The code is `WODrounds/Telemetry.swift`. How the target links `Sentry-Dynamic` and platform filters are documented in [ARCHIVE.md](ARCHIVE.md).

## What is sent, and what isn't

Anonymous is a recipe, not Sentry's default (#225, #226). Out of the box sentry-cocoa sends a random installation ID as the user, as every session's `did` and on every metric, plus `device_app_hash` (a hash of the vendor ID) on every event. `Telemetry.swift` stops all of it:

- **One shared user, `anonymous`,** set right after `SentrySDK.start` and again on every event in `beforeSend`, which in sentry-cocoa 9 also covers MetricKit diagnostics and transactions.
- **No device IDs:** `beforeSend` drops `contexts.app.device_app_hash` and `contexts.device.id`.
- **Sessions without an ID:** sentry-cocoa sets a session's `did` from the `INSTALLATION` file in its cache directory and has no option to change it. The app writes `anonymous` into that file before the SDK starts, so every install reports the same `did`. This relies on SDK internals, so **check it after every sentry-cocoa upgrade** (below).
- **Feature counts:** `workout.started` (after the count-in) and `workout.finished` (the Done screen), each with one attribute, `mode` (`emom`, `intervals` or `fortime`). `beforeSendMetric` keeps only the SDK's coarse facts (SDK, release, environment, OS, device model) and `mode`, and drops everything else, `user.id` included.
- **Off:** `sendDefaultPii`, screenshots, view hierarchy, session replay, and performance tracing in release builds (`tracesSampleRate` 0).
- **Environment:** `simulator`, `debug`, `testflight` (a sandbox receipt) or `production` (App Store builds only).

The `iamjarl` Sentry organisation also strips `user.id`, `contexts.device.id` and `contexts.app.device_app_hash` server-side and stores no IP addresses, as a safety net.

### Checking the envelopes (after every sentry-cocoa upgrade)

Point a Debug build at a local stand-in for Sentry and read what it sends. Run a tiny HTTP server on `127.0.0.1:8969` that saves each POST body (gunzip it if `Content-Encoding: gzip`), then launch with `SIMCTL_CHILD_SENTRY_DSN="http://0123456789abcdef0123456789abcdef@127.0.0.1:8969/1" xcrun simctl launch <sim> com.iamjarl.WODrounds`. Seed `Library/Caches/INSTALLATION` with a fake ID first to stand in for an existing install. Pass when the `session` item's `did` is `anonymous`, the `event` item's `user` is `{"id": "anonymous"}` with no `device_app_hash`, `trace_metric` items carry no `user.*` attribute, and the fake ID appears nowhere. Last checked with sentry-cocoa 9.32.0 on 2026-11-15: passed.

## DSN – Where to Set It

The app reads the DSN in this order: **1)** environment variable `SENTRY_DSN` (e.g. from Scheme), **2)** the `SentryDSN` key in `Info.plist`, which is `$(SENTRY_DSN)` from `Sentry.xcconfig` at build time. (A build setting named `INFOPLIST_KEY_SentryDSN` does nothing: Xcode only turns `INFOPLIST_KEY_` settings into keys for Apple's own keys. Until 2026-11-15 that's how the project tried it, so no build ever carried a DSN.) The app skips Sentry when the DSN is empty or isn't a whole `…://…@…` URL.

### A) Environment Variable (recommended for local testing)

1. In Xcode: **Product → Scheme → Edit Scheme…** (or **⌘<**).
2. Select **Run** on the left → **Arguments** tab.
3. Under **Environment Variables** click **+** and add:
   - **Name:** `SENTRY_DSN`
   - **Value:** your DSN URL (from Sentry → Project Settings → Client Keys (DSN)).
4. Close and run the app on iOS (⌘R). The DSN is used when running from Xcode.

### B) Sentry.xcconfig (for builds/archives)

1. **Open `Sentry.xcconfig`** in the project root.
2. Set `SENTRY_DSN = https:/$()/your-key@o0.ingest.sentry.io/your-project-id` (with a space after `=`). **Write the `//` as `/$()/`:** an xcconfig reads `//` as the start of a comment, so a plain URL is cut to `https:`. `$()` expands to nothing, so the app gets the whole URL.
3. At build time, Xcode puts the value into `Info.plist` as `SentryDSN`, so archives and runs without scheme-env also get the DSN. Check it with `xcodebuild -project WODrounds.xcodeproj -target WODrounds -configuration Release -showBuildSettings | grep SENTRY_DSN`.

**If Sentry still doesn't receive events:** In Debug, the Xcode console will show `[Sentry] No DSN: ...` if no DSN was found. Verify that the environment variable is set under Run, or that `Sentry.xcconfig` is used as base config for the WODrounds target.

### C) Xcode Cloud (archives in CI)

`Sentry.xcconfig` is gitignored, so a fresh Xcode Cloud clone has no config file and the build fails at the xcconfig reference. `ci_scripts/ci_post_clone.sh` recreates it after clone from the `SENTRY_DSN` environment variable, writing each `//` as `/$()/`.

To set it up: in the Xcode Cloud workflow, add an environment variable named `SENTRY_DSN` (mark it secret) with your real DSN. Builds and tests run without it, but **an archive without it fails**: `ci_scripts/ci_pre_xcodebuild.sh` stops the archive when the variable is empty, and `ci_scripts/ci_post_xcodebuild.sh` stops it when the archived app's `SentryDSN` isn't a whole DSN, so a release can't ship with crash reporting silently off. GitHub Actions copies `Sentry.xcconfig.example` instead (see `.github/workflows/`) and never archives.

### D) dSYM upload (readable crashes)

`ci_scripts/ci_post_xcodebuild.sh` uploads the iOS archive's dSYMs to Sentry with a pinned, checksum-checked `sentry-cli`. It needs a second secret on the workflow, `SENTRY_AUTH_TOKEN` (an organisation token from Sentry → Settings → Auth Tokens, with `project:releases` / debug-file upload rights). `SENTRY_ORG` and `SENTRY_PROJECT` default to `iamjarl` and `wodrounds`; set them on the workflow if the slugs differ. Without the token, or if the upload fails, the build still goes on with a warning: the release is fine, only its stack traces are unreadable.

## Adding the Sentry Package (Swift Package)

If you haven't added the package yet:

1. In Xcode: **File → Add Package Dependencies…**
2. Enter URL: `https://github.com/getsentry/sentry-cocoa.git`
3. Select version (**Up to Next Major** from 9.32.0; Application Metrics need 9.12 or newer).
4. Select the product **Sentry-Dynamic** and link it to the target **WODrounds**. (The project uses Sentry-Dynamic to avoid the "Upload Symbols Failed" warning on archive.)
5. Click **Add Package**.

The app will then build with Sentry, and when running on iOS with the DSN set in `Sentry.xcconfig`, crashes and errors are sent to your Sentry project.

## Sentry MCP (optional)

[Sentry MCP](https://docs.sentry.io/ai/mcp/) gives Cursor (or other AI tools) access to read issues and errors from Sentry. This is **independent** of the DSN in the app: the DSN is only used in the iOS app to send events; MCP uses OAuth with Sentry. Configure MCP in Cursor per the [Sentry MCP documentation](https://docs.sentry.io/ai/mcp/).

## "Upload Symbols Failed" on Archive / TestFlight

When uploading an archive to App Store Connect, Xcode may show: **Upload Symbols Failed – The archive did not include a dSYM for the Sentry.framework**. This is a **known warning** with Sentry via Swift Package Manager. The project uses **Sentry-Dynamic** (dynamic framework) instead of Sentry (static) — this can reduce or eliminate the warning because dynamic frameworks sometimes include dSYM. If the warning still appears: the upload completed ("Upload completed **with warnings**"). Click **Done**; the build should appear on TestFlight. Crashes from **your app code** can still be symbolicated by Sentry via your own app dSYM. See [ARCHIVE.md](ARCHIVE.md) for platform filtering (Sentry is iOS-only in this project).

## Privacy

The privacy policy, `PrivacyInfo.xcprivacy` and the App Store label name every kind of data, all not linked to the user and not used for tracking: Crash Data and Performance Data (diagnostics), and Product Interaction (the two feature counts). See [Sentry privacy](https://docs.sentry.io/product/security/).
