# Security Policy

## Reporting a vulnerability

If you've found a security issue in WODrounds, please **don't open a public issue**. Email me directly:

**jarl@iamjarl.com**

Please include:
- A description of the vulnerability
- Steps to reproduce
- The affected version (App Store version or commit SHA)
- Your contact info if you'd like credit when it's fixed

I'll respond within 7 days. For confirmed issues, I'll work on a patch and ship it as quickly as the App Store review process allows (typically 1–3 days for review, plus development time).

## Scope

In scope:
- WODrounds app code on iOS, iPadOS, watchOS, macOS, tvOS
- The marketing site at `wodrounds.iamjarl.com`
- Build/release scripts in `scripts/`

Out of scope:
- Third-party dependencies (Sentry, IAMJARLDesignTokens) — report to those projects directly
- Apple platform vulnerabilities — report to Apple Product Security
- Issues in forks of this repo

## What WODrounds does and doesn't handle

WODrounds is a single-purpose timer app with a deliberately small attack surface:

- **No backend.** No server, no database, no API endpoints. All workout state is local.
- **No accounts.** No sign-up, no authentication, no password storage.
- **No user data uploaded.** Workouts save to Apple Health on device only. Optional Sentry crash reports on iOS contain stack traces, no personal data.
- **No third-party tracking.** No marketing analytics in the app. The marketing website uses Umami for aggregate page views (no cookies, no fingerprinting).
- **HealthKit write-only.** The app requests write permission for workouts and active energy. No read permissions.

If you find a way to break any of those guarantees, I want to know.

## Past advisories

None to date.
