# Release Review – WODrounds (Mar 3, 2026)

## Summary

The app is **ready for App Store** across all four platforms: iOS + Watch, macOS, and tvOS. All previously identified blockers have been resolved.

## App Icons (verified)
- **iOS AppIcon**: 1024×1024 with standard, dark, and tinted variants. Single Size format. ✅
- **Watch AppIcon**: All 17 watch sizes including 1024 marketing icon. ✅
- **macOS**: 512×512@2x (AppIcon-Mac.png) in the shared appiconset. ✅
- **tvOS**: App Icon Small (400×240), App Icon Large (1280×768), Top Shelf Image, Top Shelf Image Wide (2320×720 light/dark). ✅

## Previously Identified Blockers — All Resolved

1. **Privacy Manifest (`PrivacyInfo.xcprivacy`)** ✅
   - Added in `WODrounds/PrivacyInfo.xcprivacy`. Declares crash data + performance data (Sentry) and UserDefaults API access. Sentry SPM also bundles its own manifest.

2. **App Store Privacy Labels** ✅
   - Health, Crash Data, and Performance Data configured with "App Functionality" purpose, not linked to identity, not used for tracking.

3. **iPhone ↔ Watch Sync** ✅
   - Migrated from broken App Group UserDefaults to WatchConnectivity (`WCSession.updateApplicationContext`). No App Group required.

4. **Platform Entitlements** ✅
   - iOS: HealthKit enabled (`WODrounds.entitlements`)
   - macOS: App Sandbox only (`WODrounds-Mac.entitlements`)
   - tvOS: Empty entitlements (`WODrounds-tvOS.entitlements`) — no HealthKit (unsupported on tvOS)
   - Watch: Empty entitlements

5. **Sentry Platform Filtering** ✅
   - `platformFilter = ios` on Sentry-Dynamic in pbxproj — Mac and tvOS builds do not bundle Sentry.

6. **Support/Privacy URLs** ✅
   - Live at wodrounds.iamjarl.com

## "Upload Symbols Failed" (Sentry) on upload

When uploading to App Store Connect, Xcode may show **Upload Symbols Failed** for Sentry.framework. This is a known warning with Sentry via SPM: the upload still completes ("with warnings"). Click **Done** — the build will appear on TestFlight. The project uses **Sentry-Dynamic** instead of Sentry (static) to reduce this warning. See `docs/SENTRY.md`.

## Quick Release Checklist

- [ ] Update version/build before submission (currently `1.0 (1)`)
- [ ] Archive → Validate → Upload (iOS + Watch)
- [ ] Archive → Validate → Upload (macOS, destination "Any Mac")
- [ ] Archive → Validate → Upload (tvOS, destination "Any Apple TV")
- [ ] Test on physical iPhone + Watch (timer, HealthKit, sounds, Watch sync)
- [ ] Verify App Store Connect privacy labels match actual data collection
- [ ] Verify support/privacy URLs are live and correct
- [ ] Add screenshots for each platform in App Store Connect
