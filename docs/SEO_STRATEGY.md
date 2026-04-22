# WODrounds — SEO & ASO Strategy

**Last Updated:** April 2026
**Owner:** Jarl Lyng / IAMJARL
**App:** Minimal EMOM + interval timer for iPhone, iPad, Apple Watch, Mac, Apple TV

---

## 1. Positioning

**One sentence:** The minimal Apple-first EMOM and interval timer for CrossFit, HIIT and Tabata — no account, no subscription, no ads.

**The wedge we own:**
- "minimal, private, Apple-first timer" — narrow, defensible
- Multi-platform (5 Apple platforms) — hard to replicate
- No-subscription is rare in fitness category — signals trust

**What we don't compete on:**
- Feature breadth (SmartWOD has AMRAP, For Time, more)
- Cross-platform (no Android, no web app)
- Community features (no social, no leaderboards)

Adding breadth weakens the wedge. When in doubt: stay narrow.

---

## 2. Platforms & Build Status

| Platform | Status | Min Version |
|---|---|---|
| iPhone | Live | iOS 17+ |
| iPad | Live | iPadOS 17+ |
| Apple Watch | Live (synced + simple standalone) | watchOS 10+ |
| Mac | Live | macOS 14+ |
| Apple TV | Live | tvOS 17+ |

---

## 3. Keywords

### Primary (App Store + web)
- CrossFit timer
- EMOM timer
- interval timer
- Tabata timer
- HIIT timer
- Apple Watch workout timer
- workout timer app

### Long-tail (already target specific landing pages)
- "best crossfit timer app 2026" — `best-crossfit-timer-apps.html`
- "emom workout examples" — `emom-workout-examples.html`
- "tabata workout examples" — `tabata-workout-examples.html`
- "10 minute hiit workout" — `10-minute-hiit-workout.html`
- "20 minute hiit workout" — `20-minute-hiit-workout.html`
- "beginner hiit workout" — `beginner-hiit-workout.html`
- "home gym hiit workout" — `home-gym-hiit-workout.html`

### App Store Keyword Field (100 chars max, iOS)
```
emom,tabata,hiit,crossfit,interval,workout,timer,wod,functional,home gym,apple watch,fitness
```

---

## 4. App Store Metadata

### iOS / iPadOS
- **Title (30 chars):** `WODrounds – Interval Timer`
- **Subtitle (30 chars):** `EMOM & HIIT, No Signup`
- **Promotional Text (170 chars):** `Minimal EMOM, Tabata and HIIT timer for Apple Watch, iPhone, iPad, Mac and Apple TV. No account, no ads, no subscription. Works offline.`

### Mac (same title, separate listing)
- Emphasize big-screen gym-clock use case in description

### tvOS (separate listing)
- Emphasize garage-gym / box timer use case on a TV

### App Store Description (core template)
```
WODrounds is the timer you need, stripped of everything you don't.

FOR:
• EMOM (Every Minute on the Minute)
• Tabata intervals (20s on, 10s off)
• HIIT and interval training
• CrossFit sessions
• Home gym workouts

FEATURES:
• Minimal UI designed for one-handed use between rounds
• Works offline. No account required.
• Native on iPhone, iPad, Apple Watch, Mac and Apple TV
• Apple Watch syncs with iPhone via WatchConnectivity
• Haptic feedback at round transitions on Watch
• Saves completed workouts to Apple Health (iOS, optional)
• Dark-first design, works in any lighting

WHY:
• No subscription, no ads, no in-app purchases
• No login, no account
• No marketing trackers (optional iOS crash reporting via Sentry)

Built solo in Copenhagen by an indie developer who trains CrossFit.
```

### Scandinavian localizations (track in #3)
See open issue [#3](https://github.com/JarlLyng/WODrounds/issues/3) for Danish, Swedish, Norwegian metadata.

---

## 5. Marketing Site Structure

The site at `wodrounds.iamjarl.com` is served as static HTML via GitHub Pages (`docs/` folder).

### Core pages (all live)
- `index.html` — Hero, features, screenshots, FAQ
- `emom-timer.html` — Intent: "emom timer"
- `tabata-timer.html` — Intent: "tabata timer"
- `interval-timer.html` — Intent: "interval timer"
- `apple-watch-timer.html` — Intent: "apple watch workout timer"
- `best-crossfit-timer-apps.html` — Intent: "best crossfit timer app"
- `guide.html` — When to use EMOM vs intervals vs Tabata

### Workout example pages (all live)
- `emom-workout-examples.html`
- `tabata-workout-examples.html`
- `10-minute-hiit-workout.html`
- `20-minute-hiit-workout.html`
- `beginner-hiit-workout.html`
- `home-gym-hiit-workout.html`

### Supporting pages
- `privacy.html`, `support.html`

All pages have: canonical URLs, Open Graph, Twitter Cards, JSON-LD (Article / BreadcrumbList / SoftwareApplication / FAQPage / HowTo where relevant), non-render-blocking fonts.

---

## 6. Content Principles

### What Google actually asks for
Google explicitly says there are no special technical requirements or markup for inclusion in AI features ([source](https://developers.google.com/search/docs/appearance/ai-features)). That means the path to citability is the same as good SEO: **people-first content that matches the product**.

The principles that guide our content:

1. **First-hand experience** — describe what's actually in the app. No invented features. No aspirational claims.
2. **Specific over generic** — "1–120 rounds" beats "many rounds". "0:30–9:30 round length" beats "customizable".
3. **Structured data must match visible content 1:1** — no schema-only tricks. If the page says X, the schema says X, and the app does X.
4. **Author clarity** — each article-type page has a visible "By IAMJARL" byline and JSON-LD `author: Jarl Lyng` for E-E-A-T signals.
5. **Content depth over breadth** — strengthen the existing 13 pages before adding new ones.

### What we don't do
- ❌ Special "AI markup" beyond standard schema.org
- ❌ Content for content's sake
- ❌ Generic "fitness content farm" pages unrelated to the app
- ❌ Claims that contradict code or App Store description

---

## 7. Outreach & Link Building

Active issues track the outreach pipeline:

- [#4](https://github.com/JarlLyng/WODrounds/issues/4) — Reddit (r/crossfit, r/hiit, r/homegym, r/SideProject, others)
- [#17](https://github.com/JarlLyng/WODrounds/issues/17) — Launch platforms (Show HN, Indie Hackers, Betalist, AlternativeTo, Slant)
- [#18](https://github.com/JarlLyng/WODrounds/issues/18) — Apple blogs (MacStories, The Sweet Setup, iOS Dev Weekly)
- [#19](https://github.com/JarlLyng/WODrounds/issues/19) — CrossFit media (BoxRox, Morning Chalk Up)
- [#12](https://github.com/JarlLyng/WODrounds/issues/12) — YouTube demo video

All have ready-to-use copy posted as comments.

### Cross-linking approach
- Homepage + guide page: keep "More from IAMJARL" footer cross-links (portfolio signal)
- Other pages: remove cross-links (keeps product domain focused, see #31)
- Every page: "Built by IAMJARL" copyright text with link (E-E-A-T signal, no visual noise)

---

## 8. Measurement

### Tools
- **Google Search Console** — organic queries, clicks, impressions, CWV
- **Bing Webmaster Tools** — secondary index, Bing-specific queries
- **Umami** — aggregate page views (wodrounds.iamjarl.com only, no user tracking)

### Metrics we watch
- Organic clicks per week (target: grow month-over-month for first 6 months)
- Top queries driving clicks (informs keyword decisions)
- Pages with 0 impressions (candidates for removal or rewrite)
- Core Web Vitals on all landing pages
- App Store conversions from web (track via utm params on App Store links)

### Metrics we don't chase
- Vanity DA/PA scores (not meaningful for a single-product site)
- Absolute traffic numbers (narrow wedge means small but qualified audience)
- Ranking positions (volatile; focus on clicks)

---

## 9. Roadmap — Deprioritized

We used to have a 90-day roadmap here. It's been superseded by GitHub Issues:

- Open SEO issues: https://github.com/JarlLyng/WODrounds/issues?q=is%3Aissue+is%3Aopen+label%3ASEO
- Open content issues: https://github.com/JarlLyng/WODrounds/issues?q=is%3Aissue+is%3Aopen+label%3Acontent
- Open ASO issues: https://github.com/JarlLyng/WODrounds/issues?q=is%3Aissue+is%3Aopen+label%3AASO

The issue tracker is the single source of truth.

---

## 10. Future Considerations

Not part of current scope — tracked as roadmap, not implemented:

- Apple Watch complications
- Live Activities / Dynamic Island
- Multi-stage intervals
- AMRAP / For Time timer modes
- Siri Shortcuts integration

None of these exist today. Don't write marketing copy that claims they do.
