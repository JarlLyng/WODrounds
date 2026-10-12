#!/usr/bin/env python3
"""Put the 46 guide and timer pages in the homes' frame (#189).

    python3 scripts/build_pages.py            # rewrite the pages in place
    python3 scripts/build_pages.py --check    # exit 1 if a page is out of date

The words on these pages stay as they are: they rank and get linked. What changes is the
frame around them, the same as the homes (scripts/build_home.py), without the kit's
marketing sections:

- the design system's files at the homes' release, with SRI;
- <ij-nav> in place of the old header, and <ij-footer> in place of the old footer;
- the design system's store fragment in place of each hand-made App Store button
  (the white one in the hero, the midpage one lower down).

Each part sits between marker comments, so running this again after a release bump
(DESIGN_VERSION and the hashes in build_home.py) refreshes them and leaves the rest.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from build_home import (CDN, COPY, DESIGN_VERSION, DOCS, LANG_NAMES, LANGS, ROOT, SRI, cross_links,
                        e, fetch, fragment, home_href)

# <html lang> on the pages, to the copy file and the folder it lives in.
LANG_OF = {"en": "en", "da": "da", "de": "de", "es": "es", "fr": "fr", "nb": "nb", "no": "nb", "sv": "sv"}
FOLDER_OF = {l: f for l, f, _ in LANGS}
SKIP = {"en": "Skip to content", "da": "Spring til indhold", "de": "Zum Inhalt springen",
        "es": "Saltar al contenido", "fr": "Aller au contenu", "nb": "Hopp til innhold",
        "sv": "Hoppa till innehåll"}

HEAD_FILES = ["dist/css/tokens.css", "dist/identity/wodrounds.css", "dist/fonts/jetbrains-mono.css",
              "dist/kit/kit.css"]
HEAD_SCRIPTS = ["dist/components/ij-nav.js", "dist/components/ij-footer.js"]

OLD_DS_LINK = re.compile(r'[ \t]*<link rel="stylesheet" href="https://cdn\.jsdelivr\.net/gh/jarllyng/iamjarl-design@[^"]+"[^>]*>\n')
HEAD_BLOCK = re.compile(r'[ \t]*<!-- frame:head -->.*?<!-- /frame:head -->\n', re.S)
STYLE_LINK = re.compile(r'([ \t]*)<link rel="stylesheet" href="(?:\.\./)?style\.css">')
NAV_BLOCK = re.compile(r'<!-- frame:nav -->.*?<!-- /frame:nav -->|[ \t]*<a class="skip-link"[^>]*>[^<]*</a>\s*<header class="site-header">.*?</header>', re.S)
FOOTER_BLOCK = re.compile(r'<!-- frame:footer -->.*?<!-- /frame:footer -->|[ \t]*<footer class="site-footer">.*</footer>', re.S)
STORE_BLOCK = re.compile(r'<!-- store:(hero|midpage) -->.*?<!-- /store -->', re.S)
BUTTON = r'<a href="https://apps\.apple\.com/app/wodrounds/id6759229877[^"]*" class="btn btn-primary[^"]*"[^>]*data-umami-event-placement="(\w+)"[^>]*>[^<]*</a>'
NOTE = r'(?:\s*<span class="cta-note">(.*?)</span>)?'
BUTTON_IN_P = re.compile(r'<p class="(hero-cta|guide-cta)">\s*' + BUTTON + NOTE + r'\s*</p>', re.S)
BUTTON_BARE = re.compile(BUTTON + NOTE, re.S)


def copy_for(lang: str) -> dict:
    return json.loads((COPY / f"{lang}.json").read_text())


def head_block() -> str:
    links = "\n".join(f'<link rel="stylesheet" href="{CDN}/{r}" integrity="{SRI[r]}" crossorigin="anonymous">'
                      for r in HEAD_FILES)
    scripts = "\n".join(f'<script type="module" src="{CDN}/{r}" integrity="{SRI[r]}" crossorigin="anonymous"></script>'
                        for r in HEAD_SCRIPTS)
    return (f"<!-- frame:head -->\n<!-- The homes' design system files, v{DESIGN_VERSION}, without the kit's "
            f"marketing sections (#189). Built by scripts/build_pages.py. -->\n{links}\n{scripts}\n<!-- /frame:head -->\n")


def nav_block(lang: str, folder: str) -> str:
    c = copy_for(lang)
    home = home_href(folder, folder)
    nav = c["nav"]
    cta = fragment(f"dist/store/wodrounds.{lang}.nav.html")
    return f'''<!-- frame:nav -->
<a class="ij-skip" href="#main">{e(SKIP[lang])}</a>
<ij-nav>
  <a slot="brand" href="{home}">WODrounds</a>
  <a slot="links" href="{home}#timers">{e(nav["timers"])}</a>
  <a slot="links" href="{home}#where">{e(nav["where"])}</a>
  <a slot="links" href="{home}#faq">{e(nav["faq"])}</a>
  {cta}
</ij-nav>
<!-- /frame:nav -->'''


def footer_block(lang: str, folder: str, alternates: dict[str, str]) -> str:
    c = copy_for(lang)
    f = c["footer"]
    up = "../" if folder else ""
    en_attr = "" if lang == "en" else ' hreflang="en"'
    own = [(f"{up}guide.html", f["guide"]), (f"{up}about.html", f["about"]),
           (f"{up}privacy.html", f["privacy"]), (f"{up}support.html", f["support"])]
    own_links = "\n".join(f'<a slot="links" href="{h}"{en_attr}>{e(t)}</a>' for h, t in own)
    # The same page in the other languages where it has them, else the other homes.
    langs = []
    for l, fo, _ in LANGS:
        if l == lang:
            continue
        href = alternates.get(l) or home_href(fo, folder)
        langs.append(f'<a slot="links" href="{href}" hreflang="{l}" lang="{l}">{LANG_NAMES[l]}</a>')
    cross = cross_links(lang)
    fallback = " &middot; ".join(f'<a href="{h}"{en_attr}>{e(t)}</a>' for h, t in own)
    return f'''<!-- frame:footer -->
<ij-footer app="wodrounds" links-label="WODrounds">
{own_links}
{chr(10).join(langs)}
{cross}
<p slot="fineprint">{e(f["fineprint"])}</p>
<!-- No slot attribute on purpose: the fallback, shown only if the component never loads. -->
<p>{fallback} &middot; {e(f["fineprint"])}</p>
</ij-footer>
<!-- /frame:footer -->'''


def store_block(lang: str, placement: str, pad: str = "") -> str:
    name = "white" if placement == "hero" else "midpage.white"
    body = f"<!-- store:{placement} -->\n{fragment(f'dist/store/wodrounds.{lang}.{name}.html')}\n<!-- /store -->"
    return "\n".join(pad + ln for ln in body.splitlines())


def frame(path: Path) -> str:
    s = path.read_text()
    lang = LANG_OF[re.search(r'<html lang="([a-z]+)"', s).group(1)]
    folder = path.parent.name if path.parent != DOCS else ""
    alternates = {}
    for hl, href in re.findall(r'<link rel="alternate" hreflang="([a-z-]+)" href="([^"]+)">', s):
        if hl == "x-default":
            continue
        rel = href.replace("https://wodrounds.iamjarl.com/", "")
        alternates[hl] = ("../" if folder else "") + rel

    # Head: drop the old release's files, put the frame block in front of style.css.
    s = OLD_DS_LINK.sub("", s)
    s = HEAD_BLOCK.sub("", s)
    s = STYLE_LINK.sub(lambda m: head_block() + m.group(0), s, count=1)
    s = s.replace('<meta name="theme-color" content="#0a0a0a">', '<meta name="theme-color" content="#0B0C0D">')
    s = s.replace("<body>", '<body class="ij-page">', 1)

    s = NAV_BLOCK.sub(lambda m: nav_block(lang, folder), s, count=1)
    s = FOOTER_BLOCK.sub(lambda m: footer_block(lang, folder, alternates), s, count=1)

    def indent_of(m: re.Match) -> str:
        line = s[s.rfind("\n", 0, m.start()) + 1:m.start()]
        return line if not line.strip() else ""

    def button(m: re.Match, wrapper: str | None, placement_at: int, note_at: int) -> str:
        pad = indent_of(m)
        placement = "hero" if m.group(placement_at) == "hero" else "midpage"
        note = m.group(note_at)
        inner = store_block(lang, placement, pad + ("  " if wrapper else ""))
        if note:
            inner += f'\n{pad}{"  " if wrapper else ""}<p class="cta-note">{note}</p>'
        if wrapper:
            # The paragraph that held the button becomes a div, since the fragment is a div.
            return f'<div class="{wrapper}">\n{inner}\n{pad}</div>'
        return inner.lstrip()

    s = BUTTON_IN_P.sub(lambda m: button(m, m.group(1), 2, 3), s)
    s = BUTTON_BARE.sub(lambda m: button(m, None, 1, 2), s)
    s = STORE_BLOCK.sub(lambda m: store_block(lang, m.group(1), indent_of(m)).lstrip(), s)
    return s


def pages() -> list[Path]:
    sitemap = (DOCS / "sitemap.xml").read_text()
    out = []
    for loc in re.findall(r"<loc>https://wodrounds\.iamjarl\.com/([^<]*)</loc>", sitemap):
        if loc == "" or loc.endswith("index.html") or re.fullmatch(r"[a-z]{2}/", loc):
            continue
        out.append(DOCS / loc)
    return out


def main() -> None:
    check = "--check" in sys.argv
    stale = []
    for path in pages():
        page = frame(path)
        if page != path.read_text():
            stale.append(str(path.relative_to(ROOT)))
            if not check:
                path.write_text(page)
    print(f"{len(stale)} page(s) {'out of date' if check else 'written'}")
    if check and stale:
        sys.exit(1)


if __name__ == "__main__":
    main()
