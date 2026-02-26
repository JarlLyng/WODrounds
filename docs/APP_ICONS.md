# App-ikoner – status og krav

Kort gennemgang af ikon-assets til WODrounds på tværs af platforme. Brug denne ved opdatering af ikoner eller før App Store-upload.

---

## iOS / iPadOS (WODrounds/Assets.xcassets/AppIcon.appiconset)

| Fil | Forventet | Status |
|-----|-----------|--------|
| AppIcon-Any.png | 1024×1024 | ✅ 1024×1024 |
| AppIcon-Dark.png | 1024×1024 | ✅ 1024×1024 |
| AppIcon-Tinted.png | 1024×1024 | ✅ 1024×1024 |
| AppIcon-Mac.png | 1024×1024 (512pt @2x) | ✅ 1024×1024 |

**Konklusion:** iOS- og Mac-app-ikoner er på plads og i korrekt størrelse.

---

## Apple Watch (WODroundsWatch/Assets.xcassets/AppIcon.appiconset)

- **watch-marketing:** 1024×1024 ✅ (watch-1024.png)
- **notificationCenter:** 24, 27.5, 33 pt @2x (watch-48, 55, 66) ✅
- **companionSettings:** 29 @2x og @3x (watch-58, 87) ✅
- **appLauncher:** 40–54 pt @2x (watch-80, 88, 92, 100, 102, 108) ✅
- **quickLook:** 86–129 pt @2x (watch-172, 196, 216, 234, 258) ✅

Samtlige 17 filer fra Contents.json findes. longLook er ikke i cataloget og er ikke påkrævet til App Store.

---

## tvOS (WODrounds/Assets.xcassets/AppIcon.brandassets)

| Asset | Forventet | Status |
|-------|-----------|--------|
| App Icon – Small | 400×240 | ✅ front_small + back_small |
| App Icon – Large | 1280×768 | ✅ front_large + back_large |
| Top Shelf Image | (flex) | ✅ topshelf.png |
| Top Shelf Image 1 | 1920×720 | ⚠️ Bruger topshelf.png (1920×720) – OK |
| Top Shelf Image Wide | 2320×720 | ✅ topshelf-wide-light.png + topshelf-wide-dark.png (light/dark) |

**Bemærkning:** Top Shelf Image Wide bruger nu dedikerede 2320×720 ikoner med lys/mørk variant i `Top Shelf Image Wide.imageset`.

---

## Hurtig tjekliste før release

- [ ] iOS: 1024×1024 for alle varianter (Any, Dark, Tinted, Mac)
- [ ] Watch: 17 ikoner + 1024×1024 marketing
- [ ] tvOS: Small 400×240, Large 1280×768, Top Shelf (evt. 2320×720 til Wide)
- [ ] Byg og tjek at ingen "Missing asset" eller CompileAssetCatalog-fejl opstår

---

*Sidst tjekket: efter commit med tvOS Top Shelf-fix og Sentry/HealthKit/Watch.*
