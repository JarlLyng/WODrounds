#!/usr/bin/env python3
"""Build the seven home pages on the design system's marketing kit (#182).

    python3 scripts/build_home.py            # write docs/index.html and docs/<lang>/index.html
    python3 scripts/build_home.py --check    # exit 1 if a page is out of date

The words come from site/copy/<lang>.json, the captures from docs/assets/site/, and
the store buttons, the footer's cross-links and the offer from the design system's
generated fragments at DESIGN_VERSION, which this script inlines so the page needs no
script to show them. To move to a new release: bump DESIGN_VERSION and the hashes from
its release notes, run, commit.
"""
from __future__ import annotations

import html
import json
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
COPY = ROOT / "site" / "copy"
SITE = "https://wodrounds.iamjarl.com"
APP_ID = "6759229877"

DESIGN_VERSION = "1.26.0"
CDN = f"https://cdn.jsdelivr.net/gh/jarllyng/iamjarl-design@v{DESIGN_VERSION}"
SRI = {
    "dist/css/tokens.css": "sha384-PKlt/RFEr/PqV2mjuOAm2tovN6l9sR3RwM+JgU1GP9vJisydnvt6l3h//+ythhEH",
    "dist/identity/wodrounds.css": "sha384-T1dD/e0Jqjg5pYNAiVz7SZOqaPLDUw3CA8IYr5MoFUggVbiruvaU+GijwsUH2DXm",
    "dist/fonts/jetbrains-mono.css": "sha384-4EDegyjW32y0mhvqLdn7Bma8HM6U1AjeQpPGTbtkRE14gKBdlhBJspuOu6qhyBmq",
    "dist/kit/kit.css": "sha384-GbcA6lh/Swuy7rKjPm6Jgnq8nA+uvGv/ItuzZC60OpmgW7hWm7oJb4YR4OOfXLwT",
    "dist/kit/kit.js": "sha384-nz0b4UX8YLqGvm2cAmyEGIvyKslXkjL5bjao3+ItF76Inx4yYbKGW6XpTzVMKunU",
    "dist/components/ij-nav.js": "sha384-WVM/rurI3KnRJKOiwseL9jwHJtTQ5lNwC9JfFlzXqKlUo6a2dkeV5hJvqRV+sLUQ",
    "dist/components/ij-footer.js": "sha384-PerBKUYbLWOcIY2bcVsIp53pRh4d0gpDmMrTPzU5c/dy/Uo/zIqK3A0MKM51tkKU",
}

# Language, its folder under docs/, and its Open Graph locale.
LANGS = [
    ("en", "", "en_US"),
    ("da", "da", "da_DK"),
    ("de", "de", "de_DE"),
    ("es", "es", "es_ES"),
    ("fr", "fr", "fr_FR"),
    ("nb", "no", "nb_NO"),
    ("sv", "sv", "sv_SE"),
]
LANG_NAMES = {"en": "English", "da": "Dansk", "de": "Deutsch", "es": "Español",
              "fr": "Français", "nb": "Norsk", "sv": "Svenska"}

# What the live app runs on. Changes with the iPhone Duo release (#146, #160).
OPERATING_SYSTEM = "iOS 16, iPadOS 16, watchOS 9, macOS 13, tvOS 17"

UMAMI = ('<script defer src="https://umami-iamjarl.vercel.app/script.js" '
         'data-website-id="7a65d61a-b231-4611-b514-3c6cd0a5b7b3" data-do-not-track="true" '
         'data-domains="wodrounds.iamjarl.com"></script>')

_cache: dict[str, str] = {}


def fetch(path: str) -> str:
    if path not in _cache:
        with urllib.request.urlopen(f"{CDN}/{path}", timeout=30) as r:
            _cache[path] = r.read().decode()
    return _cache[path]


def fragment(path: str) -> str:
    """A generated fragment without its leading comment, which names the version anyway."""
    lines = [ln for ln in fetch(path).splitlines() if not ln.startswith("<!--")]
    return "\n".join(lines).strip()


def e(text: str) -> str:
    return html.escape(text, quote=True)


def url_for(folder: str) -> str:
    return f"{SITE}/" if not folder else f"{SITE}/{folder}/index.html"


def home_href(folder: str, from_folder: str) -> str:
    up = "../" if from_folder else ""
    return f"{up}index.html" if not folder else f"{up}{folder}/index.html"


def indent(block: str, n: int) -> str:
    pad = " " * n
    return "\n".join(pad + ln if ln.strip() else ln for ln in block.splitlines())


def build(lang: str, folder: str, og_locale: str) -> str:
    c = json.loads((COPY / f"{lang}.json").read_text())
    app = c["appLanguage"]
    up = "../" if folder else ""
    page_url = url_for(folder)
    a = f"/assets/site"  # served from the domain root

    def link(rel: str) -> str:
        return f'<link rel="stylesheet" href="{CDN}/{rel}"\n  integrity="{SRI[rel]}" crossorigin="anonymous">'

    def scene(photo: str, extra: str = "") -> str:
        # The kit makes it black and white, dims it and holds the words at AA over it,
        # so the page adds no filter, overlay or colour of its own.
        src = f"/images/unsplash/{photo}"
        return (f'<img class="ij-scene__photo" src="{src}-960.jpg" '
                f'srcset="{src}-960.jpg 960w, {src}-1920.jpg 1920w" sizes="100vw" '
                f'width="1920" height="1280" alt="" loading="lazy" decoding="async"{extra}>')

    def script(rel: str) -> str:
        return f'<script type="module" src="{CDN}/{rel}"\n  integrity="{SRI[rel]}" crossorigin="anonymous"></script>'

    hreflangs = "\n".join(
        f'<link rel="alternate" hreflang="{l}" href="{url_for(f)}">' for l, f, _ in LANGS
    ) + f'\n<link rel="alternate" hreflang="x-default" href="{url_for("")}">'
    og_alternates = "\n".join(
        f'<meta property="og:locale:alternate" content="{o}">' for l, f, o in LANGS if l != lang
    )

    offer = json.loads(fetch(f"dist/store/wodrounds.{lang}.offer.json"))
    app_ld = {
        "@context": "https://schema.org",
        "@type": "SoftwareApplication",
        "@id": f"{SITE}/#app",
        "name": "WODrounds",
        "applicationCategory": "HealthApplication",
        "operatingSystem": OPERATING_SYSTEM,
        "description": c["meta"]["description"],
        "url": page_url,
        "downloadUrl": f"https://apps.apple.com/app/id{APP_ID}",
        "inLanguage": ["en", "da", "es"],
        "offers": offer,
        "screenshot": [f"{SITE}{a}/tour-{s}-{app}.jpg" for s in ("emom", "intervals", "fortime")],
        "publisher": {"@id": "https://iamjarl.com/#org"},
    }
    org_ld = {"@context": "https://schema.org", "@type": "Organization", "@id": "https://iamjarl.com/#org",
              "name": "IAMJARL", "url": "https://iamjarl.com", "sameAs": ["https://github.com/JarlLyng"]}
    faq_ld = {"@context": "https://schema.org", "@type": "FAQPage", "mainEntity": [
        {"@type": "Question", "name": q["q"], "acceptedAnswer": {"@type": "Answer", "text": q["a"]}}
        for q in c["faq"]]}

    def ld(obj) -> str:
        return '<script type="application/ld+json">\n' + json.dumps(obj, ensure_ascii=False, indent=2) + "\n</script>"

    links = c["links"]
    en_attr = '' if lang == "en" else ' hreflang="en"'

    # 2. Frameless pieces
    piece_dims = {"ring": (362, 444), "emom-round": (342, 150), "finished": (322, 210), "countin": (282, 145)}
    cards = []
    for it in c["pieces"]["items"]:
        w, h = piece_dims[it["id"]]
        cards.append(f'''<div class="ij-card ij-card--half">
  <div class="ij-card__piece"><img src="{a}/piece-{it["id"]}-{app}.png" alt="{e(it["alt"])}" width="{w}" height="{h}" loading="lazy" decoding="async"></div>
  <h3 class="ij-title">{e(it["title"])}</h3>
  <p>{e(it["body"])} <a href="{links[it["link"]]}">{e(it["linkText"])}</a></p>
</div>''')

    # 3. The phone that stays
    tour_screens, tour_steps = [], []
    for i, st in enumerate(c["tour"]["steps"], 1):
        tour_screens.append(f'<div class="ij-phone" data-step="{i}"><div class="ij-phone__screen"><img src="{a}/tour-{st["id"]}-{app}.jpg" alt="{e(st["alt"])}" width="602" height="1308" loading="lazy" decoding="async"></div></div>')
        tour_steps.append(f'<li class="ij-tour__step" data-step="{i}"><h3 class="ij-title">{e(st["title"])}</h3><p>{e(st["body"])}</p></li>')

    # 4. Where it works
    w = c["where"]
    traits = [f'''<div class="ij-trait ij-trait--number">
  <p class="ij-numeral home-five">{e(w["numeral"])}</p>
  <h3 class="ij-title">{e(w["numeralLabel"])}</h3>
  <p>{e(w["lede"])}</p>
</div>''']
    for t in w["traits"]:
        if t["id"] == "tv":
            traits.append(f'''<div class="ij-trait ij-trait--wide">
  <div class="ij-tv" style="--ij-tv-width: 420px"><div class="ij-tv__screen"><img src="{a}/tv-intervals-{app}.jpg" alt="{e(t["alt"])}" width="1920" height="1080" loading="lazy" decoding="async"></div></div>
  <h3 class="ij-title">{e(t["title"])}</h3><p>{e(t["body"])}</p>
</div>''')
        elif t["id"] == "watch":
            traits.append(f'''<div class="ij-trait">
  <div class="ij-watch" style="--ij-watch-width: 130px"><div class="ij-watch__screen"><img src="{a}/watch-intervals-{app}.png" alt="{e(t["alt"])}" width="416" height="496" loading="lazy" decoding="async"></div></div>
  <h3 class="ij-title">{e(t["title"])}</h3><p>{e(t["body"])}</p>
</div>''')
        else:
            traits.append(f'<div class="ij-trait"><h3 class="ij-title">{e(t["title"])}</h3><p>{e(t["body"])}</p></div>')

    # 5. Privacy and price
    s = c["assurances"]
    pl = s["privacyLabel"]
    types = "".join(f"<li>{e(x)}</li>" for x in pl["types"])
    assurances = f'''<div class="ij-assurance"><h3 class="ij-title">{e(s["noAccount"]["title"])}</h3><p>{e(s["noAccount"]["body"])}</p></div>
<div class="ij-assurance"><h3 class="ij-title">{e(s["paidOnce"]["title"])}</h3><p>{e(s["paidOnce"]["body"])}</p></div>
<div class="ij-assurance ij-assurance--label">
  <h3 class="ij-title">{e(pl["category"])}</h3>
  <p class="home-label-intro">{e(pl["intro"])} <span class="home-label-source">{e(pl["heading"])}. {e(pl["source"])}</span></p>
  <p>{e(pl["sentence"])}</p>
  <ul class="home-label-types">{types}</ul>
  <p>{e(pl["note"])}</p>
</div>'''

    faq = "\n".join(
        f'<details><summary>{e(q["q"])}</summary>\n  <p>{e(q["a"])}</p></details>' for q in c["faq"])

    # Footer: the page's own links, every language, the registry's cross-links.
    f = c["footer"]
    own = [(f"{up}guide.html", f["guide"]), (f"{up}about.html", f["about"]),
           (f"{up}privacy.html", f["privacy"]), (f"{up}support.html", f["support"])]
    own_links = "\n".join(f'<a slot="links" href="{h}"{en_attr}>{e(t)}</a>' for h, t in own)
    lang_links = "\n".join(
        f'<a slot="links" href="{home_href(fo, folder)}" hreflang="{l}" lang="{l}">{LANG_NAMES[l]}</a>'
        for l, fo, _ in LANGS if l != lang)
    cross = "\n".join(ln for ln in fetch("dist/footers/wodrounds.html").splitlines() if 'slot="cross-links"' in ln or ln.startswith("<!--"))
    fallback = " &middot; ".join(f'<a href="{h}"{en_attr}>{e(t)}</a>' for h, t in own)

    title = e(c["meta"]["title"])
    desc = e(c["meta"]["description"])
    nav = c["nav"]

    return f'''<!doctype html>
<html lang="{lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<!-- Built by scripts/build_home.py from site/copy/{lang}.json. Edit those, not this file. -->
<meta name="apple-itunes-app" content="app-id={APP_ID}">
<title>{title}</title>
<meta name="description" content="{desc}">
<link rel="canonical" href="{page_url}">
{hreflangs}
<meta name="theme-color" content="#0B0C0D">
<meta name="robots" content="index, follow, max-image-preview:large">
<meta property="og:type" content="website">
<meta property="og:site_name" content="WODrounds">
<meta property="og:title" content="{title}">
<meta property="og:description" content="{desc}">
<meta property="og:url" content="{page_url}">
<meta property="og:image" content="{SITE}/images/og-image.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:locale" content="{og_locale}">
{og_alternates}
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="{title}">
<meta name="twitter:description" content="{desc}">
<meta name="twitter:image" content="{SITE}/images/og-image.png">
<link rel="icon" href="{up}images/favicon-dark.png" type="image/png">
<link rel="apple-touch-icon" href="{up}images/favicon-dark.png">
<!-- The design system's marketing kit and WODrounds' dark identity, all from v{DESIGN_VERSION} (#182). -->
{link("dist/css/tokens.css")}
{link("dist/identity/wodrounds.css")}
{link("dist/fonts/jetbrains-mono.css")}
{link("dist/kit/kit.css")}
<link rel="stylesheet" href="{up}home.css">
{script("dist/kit/kit.js")}
{script("dist/components/ij-nav.js")}
{script("dist/components/ij-footer.js")}
{UMAMI}
{ld(app_ld)}
{ld(org_ld)}
<!-- Mirrors the visible FAQ word for word. -->
{ld(faq_ld)}
</head>
<body class="ij-page">
<a class="skip-link" href="#main">{e({"en": "Skip to content", "da": "Spring til indhold", "de": "Zum Inhalt springen", "es": "Saltar al contenido", "fr": "Aller au contenu", "nb": "Hopp til innhold", "sv": "Hoppa till innehåll"}[lang])}</a>
<ij-nav>
  <a slot="brand" href="{home_href(folder, folder)}">WODrounds</a>
  <a slot="links" href="#timers">{e(nav["timers"])}</a>
  <a slot="links" href="#where">{e(nav["where"])}</a>
  <a slot="links" href="#faq">{e(nav["faq"])}</a>
{indent(fragment(f"dist/store/wodrounds.{lang}.nav.html"), 2)}
</ij-nav>

<main id="main">

  <!-- 1. Hero. On a phone the words and the store button come before the device. -->
  <section class="ij-hero ij-hero--split" id="hero">
    <div class="ij-container ij-hero__inner">
      <div class="ij-hero__text">
        <h1 class="ij-display">{e(c["hero"]["headline"])}</h1>
        <p class="ij-lede">{e(c["hero"]["lede"])}</p>
{indent(fragment(f"dist/store/wodrounds.{lang}.white.html"), 8)}
      </div>
      <div class="ij-hero__media">
        <div class="ij-phone" style="--ij-phone-width: 320px">
          <div class="ij-phone__screen">
            <video class="ij-loop" muted loop playsinline preload="none" poster="{a}/intervals-{app}-poster.jpg"
              width="602" height="1308" aria-label="{e(c["hero"]["loopAlt"])}"><source src="{a}/intervals-{app}.mp4" type="video/mp4"></video>
          </div>
        </div>
      </div>
    </div>
  </section>

  <!-- 2. Frameless pieces of the app, each linking to its timer page -->
  <section class="ij-section ij-section--band" id="timers" aria-labelledby="timers-h">
    <div class="ij-container ij-stack">
      <h2 class="ij-headline" id="timers-h">{e(c["pieces"]["heading"])}</h2>
      <div class="ij-bento">
{indent(chr(10).join(cards), 8)}
      </div>
    </div>
  </section>

  <!-- The gym, for the mood, with nothing written on it. Never in the hero. -->
  <div class="ij-scene" aria-hidden="true">
    {scene("victor-freitas-qZ-U9z4TQ6A", ' style="object-position: 50% 35%"')}
  </div>

  <!-- 3. The phone that stays -->
  <section class="ij-section" aria-labelledby="tour-h">
    <div class="ij-container ij-stack">
      <h2 class="ij-headline" id="tour-h">{e(c["tour"]["heading"])}</h2>
      <div class="ij-tour">
        <div class="ij-tour__screens">
{indent(chr(10).join(tour_screens), 10)}
        </div>
        <ol class="ij-tour__steps">
{indent(chr(10).join(tour_steps), 10)}
        </ol>
      </div>
    </div>
  </section>

  <!-- 4. Where it works: one big number, then the platforms. Each trait is true where it says (#125). -->
  <section class="ij-section ij-section--band" id="where" aria-labelledby="where-h">
    <div class="ij-container ij-stack">
      <h2 class="ij-headline" id="where-h">{e(w["heading"])}</h2>
      <div class="ij-traits">
{indent(chr(10).join(traits), 8)}
      </div>
    </div>
  </section>

  <!-- 5. Privacy and price -->
  <section class="ij-section" aria-labelledby="privacy-h">
    <div class="ij-container ij-stack">
      <h2 class="ij-headline" id="privacy-h">{e(s["heading"])}</h2>
      <div class="ij-assurances">
{indent(assurances, 8)}
      </div>
    </div>
  </section>

  <!-- 6. A note from the maker -->
  <section class="ij-section ij-section--band" aria-label="{e(c["maker"]["label"])}">
    <div class="ij-container">
      <div class="ij-maker">
        <p>{e(c["maker"]["quote"])}</p>
        <p class="ij-maker__sign">{e(c["maker"]["signature"])}</p>
      </div>
    </div>
  </section>

  <!-- 7. FAQ. The FAQPage JSON-LD in the head mirrors this word for word. -->
  <section class="ij-section" id="faq" aria-labelledby="faq-h">
    <div class="ij-container">
      <div class="ij-stack ij-measure">
        <h2 class="ij-headline" id="faq-h">{e(c["faqHeading"])}</h2>
        <div class="faq">
{indent(faq, 10)}
        </div>
      </div>
    </div>
  </section>

  <!-- 8. Closing -->
  <section class="ij-scene" aria-label="{e(c["closing"]["label"])}">
    {scene("ambitious-studio-rick-barrett-0tQLfwcr5-M")}
    <div class="ij-container ij-closing">
      <p class="ij-wordmark" style="--ij-wordmark-em: 5.2">{e(c["closing"]["wordmark"])}</p>
{indent(fragment(f"dist/store/wodrounds.{lang}.footer.white.html"), 6)}
    </div>
  </section>

</main>

<div class="ij-container site-footer">
<ij-footer app="wodrounds" links-label="WODrounds">
{own_links}
{lang_links}
{cross}
<p slot="fineprint">{e(f["fineprint"])}</p>
<!-- No slot attribute on purpose: the fallback, shown only if the component never loads. -->
<p>{fallback} &middot; {e(f["fineprint"])}</p>
</ij-footer>
</div>
</body>
</html>
'''


def main() -> None:
    check = "--check" in sys.argv
    stale = []
    for lang, folder, og in LANGS:
        out = DOCS / folder / "index.html" if folder else DOCS / "index.html"
        page = build(lang, folder, og)
        if not out.exists() or out.read_text() != page:
            stale.append(str(out.relative_to(ROOT)))
            if not check:
                out.write_text(page)
    print(f"{len(stale)} page(s) {'out of date' if check else 'written'}")
    if check and stale:
        sys.exit(1)


if __name__ == "__main__":
    main()
