# SEO, ASO & GEO Strategy — WODrounds

Site: https://wodrounds.iamjarl.com  
App Store: https://apps.apple.com/app/wodrounds/id6759229877  
Google Search Console: Connected  
Umami Analytics: Connected  
Last updated: 2026-04-15

---

## 1. Product positioning

WODrounds er en minimal EMOM- og interval-timer til CrossFit, HIIT og Tabata. Gratis, native på iPhone, iPad, Apple Watch, Mac og Apple TV. Ingen konti, ingen reklamer, ingen abonnementer.

SEO positioning: **den multi-platform WOD timer** — differentierer fra SmartWOD, Seconds, Box Timer via Apple TV + Mac support, nul-konto design og Apple Watch-sync.

---

## 2. Hvad der allerede er på plads

### Website technical SEO (done)

- [x] Statisk HTML, GitHub Pages
- [x] `robots.txt` + `sitemap.xml` (15 URL'er, manuelt vedligeholdt)
- [x] `SoftwareApplication` + `FAQPage` JSON-LD på homepage
- [x] OG tags, Twitter cards, canonical URL'er, `apple-itunes-app` meta — alle sider
- [x] `meta name="keywords"` med relevante søgeord per side
- [x] Google Fonts med `preconnect` + non-render-blocking load
- [x] Scroll reveal med `prefers-reduced-motion` respekt
- [x] Google Search Console connected
- [x] Umami analytics

### Homepage (done)

- [x] H1: "The only WOD timer you need."
- [x] 7-item FAQ med FAQPage JSON-LD
- [x] Feature-sektion, multi-platform showcase, principper-sektion
- [x] Hero screenshot + App Store CTA

### SEO landing pages — 15 sider (done)

| Side | Schema(er) |
|------|-----------|
| `emom-timer.html` | BreadcrumbList + HowTo |
| `interval-timer.html` | BreadcrumbList + HowTo |
| `tabata-timer.html` | BreadcrumbList + HowTo |
| `guide.html` | BreadcrumbList + Article + HowTo |
| `20-minute-hiit-workout.html` | BreadcrumbList + Article |
| `beginner-hiit-workout.html` | BreadcrumbList + Article |
| `home-gym-hiit-workout.html` | BreadcrumbList + Article |
| `emom-workout-examples.html` | BreadcrumbList |
| `tabata-workout-examples.html` | BreadcrumbList |
| `10-minute-hiit-workout.html` | BreadcrumbList |
| `apple-watch-timer.html` | BreadcrumbList |
| `best-crossfit-timer-apps.html` | BreadcrumbList |

### Off-site (done)

- [x] Product Hunt lanceret

---

## 3. DU SKAL: Ret fejl i koden

Se `RETTELSER.md` i projektets rod. Opsummering:

1. **SoftwareApplication JSON-LD pris** → `"price": ""` er ugyldig. Ret til `"price": "0"` i `index.html`
2. **App Store URL** → Hero og bund-CTA bruger `https://apps.apple.com/app/wodrounds` uden app-ID. Ret til `https://apps.apple.com/app/wodrounds/id6759229877`
3. **Article-schema mangler på 5 ældre sider** → Tilføj Article JSON-LD til: `10-minute-hiit-workout.html`, `emom-workout-examples.html`, `tabata-workout-examples.html`, `apple-watch-timer.html`, `best-crossfit-timer-apps.html`

---

## 4. ASO — App Store Optimization

### Nuværende metadata (fra APP_STORE_CONNECT.md)

**App name:** WODrounds  
**Subtitle:** `EMOM & Intervals Timer` (22 tegn)  
**Keywords iOS:** 65/100 tegn brugt  

### DU SKAL: Udvid keyword-felter

**iOS (anbefalet — ~99 tegn):**
```
interval timer,workout timer,EMOM,Tabata,HIIT,CrossFit,gym,countdown,Apple Watch,functional,WOD,fit
```

**Mac (anbefalet — ~98 tegn):**
```
interval timer,workout timer,EMOM,Tabata,HIIT,CrossFit,gym,countdown,Mac,desktop timer,WOD,fitness
```

**Apple TV** er allerede 90 tegn — OK som den er.

### DU SKAL: Tilføj skandinaviske keyword-felter

**Dansk (DK):**
```
trænings timer,interval timer,EMOM,Tabata,HIIT,CrossFit,WOD,Apple Watch,træningstimer,funktionel
```

**Svensk (SE):**
```
tränings timer,intervall timer,EMOM,Tabata,HIIT,CrossFit,WOD,Apple Watch,träningstimer,funktionell
```

**Norsk (NO):**
```
trenings timer,intervall timer,EMOM,Tabata,HIIT,CrossFit,WOD,Apple Watch,treningstimer,funksjonell
```

### Screenshots-strategi

Apple's AI-genererede Tags læser metadata + screenshots. Anbefalede captions:

- Screenshot 1: "EMOM timer — set rounds and round length"
- Screenshot 2: "Interval timer — work, rest, rounds"
- Screenshot 3: "Start on iPhone, follow on Apple Watch"
- Screenshot 4: "Native on Mac and Apple TV"
- Screenshot 5: "No accounts. No ads. Just timer."

---

## 5. Keyword-strategi

### Tier 1 — Højeste relevans

- emom timer app
- interval timer app / workout interval timer
- crossfit timer app / wod timer
- tabata timer app

### Tier 2 — Informationelle (dækket af landing pages)

- emom workout examples
- tabata workout examples
- 10/20 minute hiit workout
- best crossfit timer apps
- apple watch workout timer
- beginner hiit workout

### Tier 3 — Differentiering

- free crossfit timer no subscription
- emom timer apple tv
- workout timer no account
- interval timer mac

### Tier 4 — Skandinavisk (lav konkurrence)

- crossfit timer app (DA/SV/NO)
- træningstimer / träningstimer / trenings timer
- emom timer (søges på alle tre sprog)

---

## 6. DU SKAL: Udvid cross-linking

### Footer-links til andre IAMJARL-projekter

Tilføj på alle sider:

- [Wean Nicotine](https://weannicotine.iamjarl.com) — relateret sundhedsapp
- [Made by Human](https://madebyhuman.iamjarl.com) — IAMJARL brand
- [iamjarl.com](https://iamjarl.com) — allerede til stede

### Intern cross-linking

Siderne mangler "Related articles"-links. Tilføj i bunden af hver landing page:

- `emom-timer.html` → `emom-workout-examples.html`, `guide.html`
- `tabata-timer.html` → `tabata-workout-examples.html`, `interval-timer.html`
- `10-minute-hiit-workout.html` → `20-minute-hiit-workout.html`, `beginner-hiit-workout.html`
- `best-crossfit-timer-apps.html` → `emom-timer.html`, `interval-timer.html`
- Workout-eksempler → relaterede timer-sider

---

## 7. GEO — Generative Engine Optimization

### Hvad der er på plads

Homepage FAQ er velstruktureret til AI-ekstraktion (7 spørgsmål med direkte svar, FAQPage JSON-LD). HowTo-schema på timer-siderne giver step-by-step indhold til AI-motorer.

### DU SKAL: Optimér for AI-passage-ekstraktion

Hver landing page bør have:

1. En direkte, faktuel åbningssætning (svarer på søgeforespørgslen)
2. Selvstændige sektioner
3. Mindst ét konkret datapunkt per sektion

**Target queries for AI-citation:**

- "What is the best EMOM timer app?" → `emom-timer.html`
- "Best free CrossFit timer app" → `best-crossfit-timer-apps.html`
- "How do I do a Tabata workout?" → `tabata-timer.html`
- "Apple Watch workout timer" → `apple-watch-timer.html`

### DU SKAL: Tilføj konkrete datapunkter

- "WODrounds supports 1–120 rounds with round lengths from 30 seconds to 9 minutes 30 seconds"
- "Available on 5 Apple platforms: iPhone, iPad, Apple Watch, Mac, and Apple TV"
- "Tabata protocol: 20 seconds work, 10 seconds rest, 8 rounds — developed by Dr. Izumi Tabata in 1996"
- "No subscription, no in-app purchases, no account required"

---

## 8. Indhold der stadig mangler

### P2 — Denne måned

- **Skandinaviske landing pages**: `da/`, `sv/`, `no/` versioner af emom-timer og interval-timer. Lavt konkurrence-marked, høj intent. Kræver hreflang-tags.
- **AMRAP timer landing page**: Populært CrossFit-format. Bemærk: eksisterende strategi siger "do not create AMRAP page" — men en informationel side om AMRAP-formatet der linker til intervaltimeren kan stadig fange søgninger.

### P3 — Nice to have

- **"For Time" timer page**: Endnu et CrossFit-format.
- **Comparison pages**: WODrounds vs. SmartWOD, WODrounds vs. Seconds — high intent.
- **YouTube demo video**: 60-90 sekunders app walkthrough.
- **Yderligere workout-sider** (baseret på GSC-data): 15/30-minute HIIT, bodyweight HIIT.

---

## 9. Where to make noise

### Reddit

- **r/crossfit** (~400k) — svar på timer-tråde
- **r/HIIT** (~100k) — Tabata og interval-indhold
- **r/homegym** (~600k) — "what timer do you use" tråde
- **r/AppleWatch** (~500k) — workout-apps for Watch
- **r/SideProject** — indie dev-vinkel

### Andre kanaler

- **Product Hunt** — allerede lanceret
- **Indie Hackers** — "how I built a multi-platform SwiftUI app"
- **Hacker News** — Show HN: SwiftUI on 5 Apple platforms
- **AlternativeTo.com** — alternativ til SmartWOD Timer, Seconds, Box Timer
- **CrossFit-forummer og Facebook-grupper** — timer-anbefalinger
- **Twitter/X** — #buildinpublic, #indiedev, #crossfit, #swiftui

---

## 10. Monitoring

- **Google Search Console**: Tjek ugentligt — impressions, clicks, average position, crawl errors
- **Umami Analytics**: Sidevisninger, referral sources, top sider
- **Nøgletal**: Hvilke indholdssider driver mest organisk trafik, CTR på workout-sider vs. timer-sider, indekseringstid for nye sider
