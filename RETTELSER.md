# Rettelser — WODrounds

Fundet ved gennemgang af docs/ (website) og APP_STORE_CONNECT.md d. 15. april 2026.

---

## 1. SoftwareApplication JSON-LD: tom pris

**Fil:** `docs/index.html` (linje 48–49)

```json
"price": "",
"priceCurrency": "USD"
```

Appen er gratis, men Google forventer `"price": "0"` for gratis apps. En tom streng er ugyldig i Offers-schema og vil blive ignoreret af Rich Results. Ret til:

```json
"price": "0",
"priceCurrency": "USD"
```

---

## 2. App Store URL mangler app-ID

**Filer:** `docs/index.html` (hero CTA linje 159, bund-CTA linje 338)

URL er `https://apps.apple.com/app/wodrounds` — uden ID-suffix. Det virker i dag, men er sårbart over for navnekonflikter og giver ikke App Store Connect analytics-data. Brug den fulde URL:

```
https://apps.apple.com/app/wodrounds/id6759229877
```

(App-ID bekræftet fra `apple-itunes-app` meta-tag: `app-id=6759229877`)

---

## 3. ASO: ~35 ubrugte tegn i keyword-felt

**Fil:** `docs/APP_STORE_CONNECT.md`

iOS-keywords bruger kun ~65 af 100 tegn:

```
interval timer,workout timer,EMOM,Tabata,HIIT,CrossFit,gym,countdown,Apple Watch
```

Der er plads til yderligere 35 tegn med relevante søgeord. Se SEO_STRATEGY.md for anbefalede tilføjelser.

---

## 4. Manglende Article-schema på 5 indholdsider

Følgende sider har kun BreadcrumbList men ingen Article/HowTo-schema, selvom de er artikelagtigt indhold:

- `10-minute-hiit-workout.html` (workout-indhold → Article)
- `emom-workout-examples.html` (workout-eksempler → Article)
- `tabata-workout-examples.html` (workout-eksempler → Article)
- `apple-watch-timer.html` (guide-indhold → Article eller HowTo)
- `best-crossfit-timer-apps.html` (sammenligning → Article)

De nyere sider (20-minute-hiit, beginner-hiit, home-gym-hiit, guide) har allerede Article-schema — de ældre mangler det.

---

## 5. Footer cross-linking

Footeren linker kun til `iamjarl.com`. Der er ingen links til andre IAMJARL-projekter (fx Wean Nicotine, som er et relateret sundhedsprojekt). Cross-linking styrker domæneautoritet og skaber discovery mellem projekterne.
