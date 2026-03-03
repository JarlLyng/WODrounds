# App Icons – Status and Requirements

Overview of icon assets for WODrounds across all platforms. Use this when updating icons or before App Store upload.

---

## iOS / iPadOS (WODrounds/Assets.xcassets/AppIcon.appiconset)

| File | Expected | Status |
|------|----------|--------|
| AppIcon-Any.png | 1024×1024 | ✅ 1024×1024 |
| AppIcon-Dark.png | 1024×1024 | ✅ 1024×1024 |
| AppIcon-Tinted.png | 1024×1024 | ✅ 1024×1024 |
| AppIcon-Mac.png | 1024×1024 (512pt @2x) | ✅ 1024×1024 |

**Dark icon on home screen:** Apple only shows the dark variant (AppIcon-Dark) on **home screen from iOS 18**. On iOS 17 and older, the light icon (AppIcon-Any) is always used. Make sure to run iOS 18+ if testing the dark icon. In Xcode, App Icon for iOS should be set to **Single Size** (Inspectors → Attributes).

**Summary:** iOS and Mac app icons are complete and correctly sized.

---

## Apple Watch (WODroundsWatch/Assets.xcassets/AppIcon.appiconset)

- **watch-marketing:** 1024×1024 ✅ (watch-1024.png)
- **notificationCenter:** 24, 27.5, 33 pt @2x (watch-48, 55, 66) ✅
- **companionSettings:** 29 @2x and @3x (watch-58, 87) ✅
- **appLauncher:** 40–54 pt @2x (watch-80, 88, 92, 100, 102, 108) ✅
- **quickLook:** 86–129 pt @2x (watch-172, 196, 216, 234, 258) ✅

All 17 files from Contents.json are present. longLook is not in the catalog and is not required for App Store.

---

## tvOS (WODrounds/Assets.xcassets/AppIcon.brandassets)

| Asset | Expected | Status |
|-------|----------|--------|
| App Icon – Small | 400×240 | ✅ front_small + back_small |
| App Icon – Large | 1280×768 | ✅ front_large + back_large |
| Top Shelf Image | (flex) | ✅ topshelf.png |
| Top Shelf Image 1 | 1920×720 | ✅ topshelf.png (1920×720) |
| Top Shelf Image Wide | 2320×720 | ✅ topshelf-wide-light.png + topshelf-wide-dark.png (light/dark) |

**Note:** Top Shelf Image Wide uses dedicated 2320×720 icons with light/dark variants in `Top Shelf Image Wide.imageset`.

---

## Quick Checklist Before Release

- [x] iOS: 1024×1024 for all variants (Any, Dark, Tinted, Mac)
- [x] Watch: 17 icons + 1024×1024 marketing
- [x] tvOS: Small 400×240, Large 1280×768, Top Shelf (incl. 2320×720 Wide)
- [ ] Build and verify no "Missing asset" or CompileAssetCatalog errors appear

---

*Last checked: Mar 3, 2026 — all icons verified complete across all platforms.*
