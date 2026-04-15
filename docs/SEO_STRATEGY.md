# WODrounds SEO Strategy

Site: https://wodrounds.iamjarl.com
Product: Simple CrossFit / HIIT workout timer (paid app, no subscription)

Goal: Generate organic traffic from people searching for workout timers and convert them into App Store downloads.

---

# Status: Implemented

## Content pages (15 total)

| Page | Target keywords | Status |
|------|----------------|--------|
| `/` (homepage) | crossfit timer, wod timer, emom timer | Live |
| `/guide.html` | emom guide, tabata guide, interval timer guide | Live |
| `/emom-timer.html` | emom timer, emom timer app, crossfit emom timer | Live |
| `/tabata-timer.html` | tabata timer, tabata timer app, 20/10 timer | Live |
| `/interval-timer.html` | interval timer, hiit timer, work rest timer | Live |
| `/apple-watch-timer.html` | apple watch workout timer, apple watch emom | Live |
| `/best-crossfit-timer-apps.html` | best crossfit timer app, smartwod vs wodrounds | Live |
| `/emom-workout-examples.html` | emom workout examples, emom workouts | Live |
| `/tabata-workout-examples.html` | tabata workout examples, tabata workouts | Live |
| `/10-minute-hiit-workout.html` | 10 minute hiit workout, quick hiit | Live |
| `/20-minute-hiit-workout.html` | 20 minute hiit workout, 20 min workout | Live |
| `/beginner-hiit-workout.html` | beginner hiit workout, easy hiit, hiit for beginners | Live |
| `/home-gym-hiit-workout.html` | home gym workout, garage gym hiit, home hiit | Live |
| `/privacy.html` | — | Live |
| `/support.html` | — | Live |

## Technical SEO (all done)

- Google Search Console: connected and verified
- Structured data: SoftwareApplication, FAQPage, BreadcrumbList, Article, HowTo
- HowTo JSON-LD schemas on emom-timer, tabata-timer, interval-timer
- Article JSON-LD with author (Jarl Lyng) on all article pages
- Open Graph tags (type, url, title, description, image, image:width, image:height) on all pages
- Twitter Card tags (card, title, description, image) on all pages
- Apple Smart App Banner (`apple-itunes-app` meta) on all pages
- `theme-color` meta on all pages
- Non-render-blocking Google Fonts (`media="print" onload`) on all pages
- Canonical URLs on all pages
- `robots: index, follow` on all pages
- Sitemap.xml with all 15 pages
- Internal linking between all content pages
- Mobile-responsive CSS (header, hero, titles, buttons)
- "By IAMJARL" bylines on all article pages (EEAT signal)
- Author name (Jarl Lyng) in hidden JSON-LD only — not shown on site
- Global link styling (no browser-default blue links)

## Off-site

- Product Hunt: launched
- Reddit r/crossfit: pending
- Reddit r/AppleWatch: pending

---

# 1. Core SEO Positioning

Primary keyword cluster:

- crossfit timer
- wod timer
- hiit timer
- interval workout timer
- emom timer
- tabata timer

Main positioning:

> "A simple and fast WOD timer for CrossFit, EMOM, Tabata and interval workouts."

This wording should appear on:

- homepage title
- meta description
- H1
- GitHub README

Example title tag:

```
WODrounds — EMOM & Interval Timer for CrossFit and HIIT
```

Example meta description:

```
Simple WOD timer for CrossFit, EMOM, Tabata and HIIT workouts. iPhone, Apple Watch, Mac and Apple TV. No accounts or ads. See our Privacy Policy for crash reporting (iOS) and site analytics.
```

---

# 2. Landing Page Improvements

The homepage should target one clear search intent:

"CrossFit / WOD timer"

Recommended structure:

H1

```
The simple WOD timer for CrossFit workouts
```

Sections:

1. What WODrounds is
2. Supported workout formats (EMOM, Tabata, Intervals)
3. Why it's better than typical timers (no ads, no accounts)
4. Apple ecosystem support (iPhone, Watch, Mac, Apple TV)
5. How to use it
6. FAQ

Important keywords to include naturally:

- WOD timer
- CrossFit timer
- interval workout timer
- EMOM timer
- Tabata timer

---

# 3. Workout-Specific Landing Pages

Create additional pages targeting specific timer formats.

Priority pages (all live):

```
/emom-timer.html
/tabata-timer.html
/interval-timer.html
/apple-watch-timer.html
```

Each page includes:

- explanation of the workout format
- how to run it using WODrounds (with HowTo schema)
- example workouts
- App Store download CTA
- links to related pages

---

# 4. Comparison Content

A neutral comparison article captures high-intent users evaluating timer apps.

Live page: `/best-crossfit-timer-apps.html`

Covers:

- WODrounds
- SmartWOD
- Seconds
- Box Timer
- others

Focus on honest comparison rather than aggressive "alternative" pages.

---

# 5. App Store SEO (ASO)

App Store optimization influences web visibility because App Store pages often rank in Google results.

**Canonical copy** for subtitles, descriptions, and keywords lives in [APP_STORE_CONNECT.md](APP_STORE_CONNECT.md).

Keyword emphasis:

- crossfit timer
- emom timer
- tabata timer
- hiit timer
- workout timer

---

# 6. Educational Content

The guide page covers EMOM, Tabata and intervals in depth. Separate articles are not needed unless targeting a very specific long-tail keyword not covered by the guide.

> **Note:** Do not create a "what is AMRAP" page — the app does not support AMRAP timing. Do not use AMRAP as a primary keyword for WODrounds-owned pages (comparison articles may mention competitors' AMRAP support).

---

# 7. Programmatic Content Cluster (Workout Examples)

These pages combine two intents:

1. People looking for workout ideas
2. People looking for a timer

### Live pages

```
/emom-workout-examples.html
/tabata-workout-examples.html
/10-minute-hiit-workout.html
/20-minute-hiit-workout.html
/beginner-hiit-workout.html
/home-gym-hiit-workout.html
```

### Potential expansion (create if existing pages gain traction)

```
/15-minute-hiit-workout.html
/30-minute-hiit-workout.html
/bodyweight-hiit-workout.html
/crossfit-wod-of-the-day.html
```

### SEO benefit

This cluster expands topical authority from just "timers" into:

- CrossFit workouts
- HIIT workouts
- EMOM programming
- Home gym training

This increases the total number of keywords the site can rank for.

---

# 8. Backlink Strategy

### Done

- Product Hunt launch

### Pending

- Reddit r/crossfit — genuine value post, not self-promotion
- Reddit r/AppleWatch — "I built a WOD timer for Apple Watch" angle

### Future opportunities

- Guest posts on CrossFit / fitness blogs
- YouTube: short demo video (app walkthrough, 60-90 seconds)
- HARO / journalist outreach (fitness tech angle)
- CrossFit box partnerships (local gyms in Copenhagen)
- Open-source or developer community posts (SwiftUI, multi-platform)

---

# 9. Monitoring

### Google Search Console

- Connected and verified
- Check weekly: impressions, clicks, average position
- Watch for: crawl errors, indexing issues, Core Web Vitals flags

### Umami Analytics

- Site analytics at umami-iamjarl.vercel.app
- Track: page views, referral sources, top pages

### Key metrics to watch

- Which content pages drive the most organic impressions
- Click-through rate on workout example pages vs. timer pages
- Whether new pages get indexed within 1-2 weeks
- Backlink acquisition from Reddit / Product Hunt

---

# 10. Prioritised Roadmap

| Priority | Task | Status |
|----------|------|--------|
| 1 | Update GitHub README with SEO keywords | Done |
| 2 | Create /emom-timer landing page | Done |
| 3 | Create /tabata-timer landing page | Done |
| 4 | Create /interval-timer landing page | Done |
| 5 | Create /apple-watch-timer landing page | Done |
| 6 | Create /emom-workout-examples page | Done |
| 7 | Create /tabata-workout-examples page | Done |
| 8 | Create /10-minute-hiit-workout page | Done |
| 9 | Create /20-minute-hiit-workout page | Done |
| 10 | Create /beginner-hiit-workout page | Done |
| 11 | Create /home-gym-hiit-workout page | Done |
| 12 | Write "best CrossFit timer apps" comparison | Done |
| 13 | Expand guide with more example workouts | Done |
| 14 | Complete technical SEO (meta tags, schemas, fonts) | Done |
| 15 | Mobile-optimize site | Done |
| 16 | Connect Google Search Console | Done |
| 17 | Post on Product Hunt | Done |
| 18 | Post on Reddit r/crossfit | Todo |
| 19 | Post on Reddit r/AppleWatch | Todo |
| 20 | Expand content cluster based on GSC data | Todo |
| 21 | Create short YouTube demo video | Todo |
