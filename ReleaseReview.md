# Release Review – WODrounds (Feb 27, 2026)

## Konklusion (kort)
Appen ser **næsten klar til release** ud baseret på repo og build‑setup. Der er dog et par vigtige “må‑tjekkes” før App Store submission.

## Opdateringer (efter review)
- **HealthKit-strengene:** Løst. Build settings bruger nu engelsk som default; `WODrounds/en.lproj/InfoPlist.strings` og `WODrounds/da.lproj/InfoPlist.strings` indeholder NSHealthShareUsageDescription og NSHealthUpdateUsageDescription på henholdsvis engelsk og dansk.

## Hvad jeg har tjekket
- Build settings og Info.plist‑generering for hovedtarget (iOS/iPadOS/macOS/tvOS).
- Watch‑target, entitlements og app‑group.
- Sentry‑setup (DSN via `Sentry.xcconfig` og runtime‑init).
- PrivacyPolicy/Support‑dokumenter.
- App‑ikon assets for iOS/tvOS/Watch.

## Anbefalinger før release
1. **Privacy Manifest (`PrivacyInfo.xcprivacy`)**
   - Sentry Cocoa (SPM) leverer eget `PrivacyInfo.xcprivacy` i pakken (crash/performance data). Ved SPM inkluderes det typisk i build. Verificér ved første upload at App Store ikke kræver yderligere app‑niveau manifest; tilføj evt. eget i app‑targetet hvis nødvendigt.

2. ~~**HealthKit‑tilladelsesstrenge**~~ → Lokaliseret (en/da), se “Opdateringer” ovenfor.

3. **Sentry i Debug**
   - Når der er DSN sat i `Sentry.xcconfig`, sender Debug‑builds events (inkl. en test‑event). Det er fint, men overvej en separat DSN for debug/staging eller en build‑flag der slår test‑event fra for at undgå støj.

4. **App Store metadata og links**
   - Appen linker til `https://wodrounds.iamjarl.com/support` og `/privacy`. Sørg for at siderne er live, korrekte og matcher teksten i `PrivacyPolicy.md`/`Support.md`.
   - Bekræft App Store “Privacy Labels” (diagnostics + Health data) matcher Sentry + HealthKit‑brug.

5. **App Groups i Developer Portal**
   - Entitlements bruger `group.com.iamjarl.WODrounds`. Verificér at App Group er oprettet og aktiveret på både iOS‑ og Watch‑App ID.

## Ikke‑blokkerende observationer
- Version/build står til `1.0 (1)` – husk at opdatere inden submission.
- `ITSAppUsesNonExemptEncryption = NO` er sat (godt).
- Watch‑ikon assets ser komplette ud.

## Forslag til “release checkliste” (hurtig)
- [ ] Archive → Validate → Upload (iOS + Watch).
- [ ] Test på fysisk iPhone + Watch (start/pause/resume + sync + Health).
- [ ] Gennemgå privacy labels i App Store Connect (diagnostics/Sentry + Health).
- [ ] Verificér support/privacy URL’er (wodrounds.iamjarl.com) er live og matcher PrivacyPolicy/Support.
- [ ] I Developer Portal: App Group `group.com.iamjarl.WODrounds` aktiveret for både iOS- og Watch‑App ID.
- [ ] Opdater version/build før submission (1.0 (1) er sat nu).

