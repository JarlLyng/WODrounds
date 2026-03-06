# Archive and Distribution

Quick reference for how archiving works for WODrounds across all platforms.

---

## Destinations

| Destination       | Contents                          | Use                   |
|-------------------|-----------------------------------|-----------------------|
| **Any iOS Device** | iPhone/iPad app + Watch app       | TestFlight, App Store |
| **Any Mac**        | macOS app only (no Watch)         | Mac App Store         |
| **Any Apple TV**   | tvOS app only (no Watch)          | tvOS App Store        |

---

## Why Watch Is Not Included in Mac/tvOS Archives

The Watch app is only relevant with iOS. To ensure Mac and tvOS archives build and sign without errors:

1. **Embed Watch Content** — the build file for `WODrounds Watch.app` has `platformFilter = ios`. The Watch app is only embedded in iOS builds.
2. **Watch target dependency** — `PBXTargetDependency` from WODrounds to WODrounds Watch has `platformFilter = ios`. When building for **Any Mac** or **Any Apple TV**, the Watch target is not built.
3. **SUPPORTED_PLATFORMS** — the WODrounds target includes iphoneos, iphonesimulator, macosx, appletvos, appletvsimulator (no watchos/watchsimulator).

Result: Mac and tvOS archives do not contain `WODrounds.app/Watch`, avoiding the CodeSign "unsealed contents present in the bundle root" error.

---

## Platform-Specific Entitlements

Each platform uses a different entitlements file via SDK-conditional build settings:

| Platform | Entitlements File | Contents |
|----------|-------------------|----------|
| **iOS** (default) | `WODrounds/WODrounds.entitlements` | HealthKit |
| **macOS** (`sdk=macosx*`) | `WODrounds/WODrounds-Mac.entitlements` | App Sandbox only |
| **tvOS** (`sdk=appletvos*`) | `WODrounds/WODrounds-tvOS.entitlements` | Empty (no HealthKit) |

---

## Sentry Platform Filtering

Sentry-Dynamic has `platformFilter = ios` in the project — Mac and tvOS builds do **not** link or bundle the Sentry framework.

---

## Technical Locations in the Project

- **project.pbxproj:**
  - `PBXBuildFile` for "WODrounds Watch.app in Embed Watch Content" → `platformFilter = ios`.
  - `PBXBuildFile` for "Sentry-Dynamic in Frameworks" → `platformFilter = ios`.
  - `PBXTargetDependency` (WODrounds → WODrounds Watch) → `platformFilter = ios`.
  - WODrounds target: `SUPPORTED_PLATFORMS` without watchos/watchsimulator.
- **Entitlements:**
  - `CODE_SIGN_ENTITLEMENTS = WODrounds/WODrounds.entitlements` (default, iOS)
  - `CODE_SIGN_ENTITLEMENTS[sdk=macosx*] = WODrounds/WODrounds-Mac.entitlements`
  - `CODE_SIGN_ENTITLEMENTS[sdk=appletvos*] = WODrounds/WODrounds-tvOS.entitlements`

