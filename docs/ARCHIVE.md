# Arkiv og distribution (Archive)

Kort reference til hvordan arkiv fungerer for WODrounds og hvorfor Mac-arkiv ikke inkluderer Watch-appen.

---

## Destinationer

| Destination   | Indhold                          | Brug                    |
|--------------|-----------------------------------|-------------------------|
| **Any iOS**  | iPhone/iPad-app + Watch-app       | TestFlight, App Store  |
| **Any Mac**  | Kun macOS-app (ingen Watch)       | Mac distribution        |

---

## Hvorfor Watch ikke er med i Mac-arkivet

Watch-appen er kun relevant sammen med iOS. For at Mac-arkiv skal bygge og signere uden fejl:

1. **Embed Watch Content** — build-filen for `WODrounds Watch.app` har `platformFilter = ios`. Watch-appen indlejres kun ved iOS-build.
2. **Watch target-afhængighed** — `PBXTargetDependency` fra WODrounds til WODrounds Watch har `platformFilter = ios`. Ved **Any Mac** bygges Watch-targetet ikke.
3. **SUPPORTED_PLATFORMS** — WODrounds-targetet har ikke `watchos`/`watchsimulator`; kun iphoneos, iphonesimulator, macosx, appletvos, appletvsimulator.

Resultat: Mac-arkiv indeholder ikke `WODrounds.app/Watch`, så der opstår ikke CodeSign-fejlen "unsealed contents present in the bundle root", og Watch-validering kører ikke under Mac-arkiv.

---

## Tekniske steder i projektet

- **project.pbxproj:**  
  - `PBXBuildFile` for "WODrounds Watch.app in Embed Watch Content" → `platformFilter = ios`.  
  - `PBXTargetDependency` (WODrounds → WODrounds Watch) → `platformFilter = ios`.  
  - WODrounds target: `SUPPORTED_PLATFORMS` uden watchos/watchsimulator.
- **Mac signering:** WODrounds-target bruger `WODrounds-Mac.entitlements` ved `sdk=macosx*` (kun App Sandbox; HealthKit er iOS-only).

---

## Reference

- README: **Platform Strategy**, **Signing & Distribution**.
- Xcode: WODrounds target → Build Phases → Embed Watch Content; Build Settings → Supported Platforms.
