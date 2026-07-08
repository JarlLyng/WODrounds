# Sentry (iOS)

Crash and error reporting uses **Sentry on iOS only** (not macOS, tvOS, or Watch). How the target links `Sentry-Dynamic` and platform filters are documented in [ARCHIVE.md](ARCHIVE.md).

## DSN – Where to Set It

The app reads the DSN in this order: **1)** environment variable `SENTRY_DSN` (e.g. from Scheme), **2)** Info.plist key `SentryDSN` (from `Sentry.xcconfig` at build time).

### A) Environment Variable (recommended for local testing)

1. In Xcode: **Product → Scheme → Edit Scheme…** (or **⌘<**).
2. Select **Run** on the left → **Arguments** tab.
3. Under **Environment Variables** click **+** and add:
   - **Name:** `SENTRY_DSN`
   - **Value:** your DSN URL (from Sentry → Project Settings → Client Keys (DSN)).
4. Close and run the app on iOS (⌘R). The DSN is used when running from Xcode.

### B) Sentry.xcconfig (for builds/archives)

1. **Open `Sentry.xcconfig`** in the project root.
2. Set `SENTRY_DSN = https://your-key@o0.ingest.sentry.io/your-project-id` (with a space after `=`).
3. At build time, Xcode inserts the value into Info.plist as `SentryDSN`, so archives and runs without scheme-env also get the DSN.

**If Sentry still doesn't receive events:** In Debug, the Xcode console will show `[Sentry] No DSN: ...` if no DSN was found. Verify that the environment variable is set under Run, or that `Sentry.xcconfig` is used as base config for the WODrounds target.

### C) Xcode Cloud (archives in CI)

`Sentry.xcconfig` is gitignored, so a fresh Xcode Cloud clone has no config file and the build fails at the xcconfig reference. `ci_scripts/ci_post_clone.sh` recreates it after clone from the `SENTRY_DSN` environment variable.

To set it up: in the Xcode Cloud workflow, add an environment variable named `SENTRY_DSN` (mark it secret) with your real DSN. If it is left unset, the script writes an empty DSN and crash reporting is simply off for that build (the archive still succeeds). Same for GitHub Actions, which copies `Sentry.xcconfig.example` instead (see `.github/workflows/`).

## Adding the Sentry Package (Swift Package)

If you haven't added the package yet:

1. In Xcode: **File → Add Package Dependencies…**
2. Enter URL: `https://github.com/getsentry/sentry-cocoa.git`
3. Select version (e.g. **Up to Next Major** with 9.0.0 or newer).
4. Select the product **Sentry-Dynamic** and link it to the target **WODrounds**. (The project uses Sentry-Dynamic to avoid the "Upload Symbols Failed" warning on archive.)
5. Click **Add Package**.

The app will then build with Sentry, and when running on iOS with the DSN set in `Sentry.xcconfig`, crashes and errors are sent to your Sentry project.

## Sentry MCP (optional)

[Sentry MCP](https://docs.sentry.io/ai/mcp/) gives Cursor (or other AI tools) access to read issues and errors from Sentry. This is **independent** of the DSN in the app: the DSN is only used in the iOS app to send events; MCP uses OAuth with Sentry. Configure MCP in Cursor per the [Sentry MCP documentation](https://docs.sentry.io/ai/mcp/).

## "Upload Symbols Failed" on Archive / TestFlight

When uploading an archive to App Store Connect, Xcode may show: **Upload Symbols Failed – The archive did not include a dSYM for the Sentry.framework**. This is a **known warning** with Sentry via Swift Package Manager. The project uses **Sentry-Dynamic** (dynamic framework) instead of Sentry (static) — this can reduce or eliminate the warning because dynamic frameworks sometimes include dSYM. If the warning still appears: the upload completed ("Upload completed **with warnings**"). Click **Done**; the build should appear on TestFlight. Crashes from **your app code** can still be symbolicated by Sentry via your own app dSYM. See [ARCHIVE.md](ARCHIVE.md) for platform filtering (Sentry is iOS-only in this project).

## Privacy

The app's **Privacy Policy** and App Store **Privacy Labels** declare that crash and performance data is sent to Sentry (third party). See [Sentry privacy](https://docs.sentry.io/product/security/). The privacy manifest (`PrivacyInfo.xcprivacy`) also declares this data collection.
