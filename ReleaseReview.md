# Release Review – WODrounds (Feb 28, 2026)

## Konklusion (kort)
Baseret på repo og build‑setup ser appen **klar til App Store** for iOS + Watch, men der er et par områder, der **kan give afslag** hvis de ikke er afklaret før upload (primært privacy manifest og platform‑ikoner).

## App‑ikoner (kontrol)
- **iOS AppIcon**: `WODrounds/Assets.xcassets/AppIcon.appiconset` indeholder en 1024‑icon samt dark/tinted varianter. Det er ok **hvis** AppIcon‑sættet er sat til “Single Size” i Xcode. Tjek i Xcode at der ikke vises manglende slots.
- **Watch AppIcon**: `WODroundsWatch/Assets.xcassets/AppIcon.appiconset` har alle watch‑størrelser inkl. 1024 marketing – ser komplet ud.
- **macOS**: AppIcon‑sættet har kun én mac‑entry (`512x512@2x`). Hvis du **reelt bygger/shipper macOS** (Catalyst eller macOS target), kan App Store kræve fuldt Mac‑ikon‑sæt. Tjek i Xcode om der er warnings; ellers tilføj fuld Mac‑ikon eller skift til korrekt “Single Size”.
- **tvOS**: **På plads.** `WODrounds/Assets.xcassets/AppIcon.brandassets` indeholder: App Icon Small (400×240), App Icon Large (1280×768), Top Shelf Image, Top Shelf Image 1, Top Shelf Image Wide (2320×720 light/dark). Top Shelf‑billeder er bundet i assets. Se `docs/APP_ICONS.md`.

## Mulige App Store‑blokere
1. **Privacy Manifest (`PrivacyInfo.xcprivacy`)**
   - ✅ Added in `WODrounds/PrivacyInfo.xcprivacy`. Declares crash data + performance data (Sentry) and UserDefaults API access. Sentry SPM also bundles its own manifest.
2. **App Store privacy labels**
   - PrivacyPolicy siger ingen tracking, men **Sentry crash‑data** og **HealthKit data** kræver korrekte labels i App Store Connect. De skal matche den faktiske indsamling.
3. **Platform‑ikoner**
   - Hvis macOS/tvOS reelt er aktive, skal ikoner være fulde og korrekte (se “App‑ikoner”).
4. **Support/privacy URL’er**
   - Sørg for at de publicerede sider er live og matcher indholdet i `PrivacyPolicy.md` og `Support.md`.

## Anbefalinger før release
1. I Xcode: tjek at AppIcon‑sættet ikke viser manglende slots (iOS/Watch/tvOS/Mac er dækket).
2. Verificér privacy manifest‑kravet ved første upload; tilføj `PrivacyInfo.xcprivacy` i app‑targetet hvis App Store beder om det.
3. Gennemgå App Store privacy labels (Diagnostics + Health) så de matcher Sentry + HealthKit.
4. iPhone ↔ Watch sync uses WatchConnectivity (`WCSession.updateApplicationContext`). No App Group required.
5. Opdater version/build før submission (står på `1.0 (1)`).

## "Upload Symbols Failed" (Sentry) ved upload
Ved upload til App Store Connect kan Xcode vise **Upload Symbols Failed** for Sentry.framework. Det er en kendt advarsel ved Sentry (SPM): uploadet er stadig gennemført ("with warnings"). Tryk **Done** – buildet kommer på TestFlight. Projektet bruger **Sentry-Dynamic** i stedet for Sentry (static) i håb om at advarslen forsvinder; hvis den stadig vises, er den ufarlig. Se `docs/SENTRY.md`.

## Hurtig release‑checkliste
- [ ] Archive → Validate → Upload (iOS + Watch).
- [ ] Test på fysisk iPhone + Watch (timer, HealthKit, lyd: countdown, 30 sek, you did it).
- [ ] Tjek AppIcon‑sæt i Xcode for manglende slots (se `docs/APP_ICONS.md`).
- [ ] Gennemgå privacy labels i App Store Connect.
- [ ] Verificér support/privacy URL’er er live og korrekte.
