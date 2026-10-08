#!/usr/bin/env python3
"""Rebuild every page's footer around the shared <ij-footer> (#137).

The cross-links come from the design system's registry, as the pre-rendered
fragment dist/footers/wodrounds.html at a pinned version, so they are in the
served HTML for crawlers that do not run JavaScript. The page's own links, its
language links and its fineprint are kept from the footer already there.

    python3 scripts/update_footer.py            # rewrite docs/**/*.html in place
    python3 scripts/update_footer.py --check    # exit 1 if any page is out of date

To pick up a registry change: bump VERSION (and FOOTER_JS_SRI from the new tag's
dist/sri.json), run this, commit.
"""
from __future__ import annotations

import glob
import re
import sys
import urllib.request

VERSION = "1.18.1"
FOOTER_JS_SRI = "sha384-vbo2o61hGBKT7RZB4taOfO8TxwNA3akt7UBF0X31Xjfk5rZlCXkz6oJ9HqiBglTJ"
BASE = f"https://cdn.jsdelivr.net/gh/jarllyng/iamjarl-design@v{VERSION}"

SCRIPT = (f'  <script type="module" src="{BASE}/dist/components/ij-footer.js"\n'
          f'    integrity="{FOOTER_JS_SRI}" crossorigin="anonymous"></script>\n')

FOOTER_RE = re.compile(r'[ \t]*<footer class="site-footer">.*?</footer>\n', re.S)
A_RE = re.compile(r'<a\b[^>]*>.*?</a>', re.S)


def fragment() -> list[str]:
    with urllib.request.urlopen(f"{BASE}/dist/footers/wodrounds.html", timeout=20) as r:
        text = r.read().decode()
    comments = [ln for ln in text.splitlines() if ln.startswith("<!--")][:2]
    links = [ln for ln in text.splitlines() if 'slot="cross-links"' in ln]
    if not links:
        raise SystemExit("fragment has no cross-links")
    return comments + links


def build(old: str, frag: list[str]) -> str:
    # Each <p class="footer-links"> is either a group of links or the label for
    # the group after it. The first group is the page's own links; a group whose
    # links carry lang= is the language switcher. Cross-link groups are dropped:
    # the fragment replaces them. A footer this script already built is read the
    # same way, from its slots, so running it twice changes nothing.
    paras = re.findall(r'<p class="footer-links[^"]*"[^>]*>(.*?)</p>', old, re.S)
    if "<ij-footer" in old:
        own = [re.sub(r' slot="links"', "", a) for a in A_RE.findall(old) if 'slot="links"' in a]
    else:
        own = A_RE.findall(paras[0]) if paras else []
    languages, label = None, None
    for k, para in enumerate(paras):
        if 'lang="' in para:
            languages = para
            if k > 0 and "<a" not in paras[k - 1]:
                label = paras[k - 1].strip()
    copy = re.search(r'<p (?:class="footer-copy"|slot="fineprint")>(.*?)</p>', old, re.S)

    i = "        "
    out = ['  <footer class="site-footer">', '    <div class="wrap">',
           f'{i[:-2]}<ij-footer app="wodrounds" links-label="WODrounds">']
    out += [f'{i}{a.replace("<a ", "<a slot=\"links\" ", 1)}' for a in own]
    out += [f'{i}{ln}' for ln in frag]
    if copy:
        out.append(f'{i}<p slot="fineprint">{copy.group(1).strip()}</p>')
    # Unslotted: what a visitor sees only if the component never loads.
    out.append(f'{i}<p class="footer-logo">WODrounds</p>')
    out.append(f'{i[:-2]}</ij-footer>')
    if languages is not None:
        out.append(f'{i[:-2]}<p class="footer-links footer-lang-label">{label or "Language"}</p>')
        out.append(f'{i[:-2]}<p class="footer-links">{languages.rstrip()}\n{i[:-2]}</p>')
    out += ['    </div>', '  </footer>']
    return "\n".join(out) + "\n"


def main() -> None:
    check = "--check" in sys.argv
    frag = fragment()
    stale = []
    for path in sorted(glob.glob("docs/**/*.html", recursive=True)):
        page = open(path, encoding="utf-8").read()
        m = FOOTER_RE.search(page)
        if not m:
            continue
        new = page[:m.start()] + build(m.group(0), frag) + page[m.end():]
        new = re.sub(r'  <script type="module" src="https://cdn\.jsdelivr\.net/gh/jarllyng/iamjarl-design@v[\d.]+/dist/components/ij-footer\.js"\n    integrity="[^"]+" crossorigin="anonymous"></script>\n', "", new)
        new = new.replace("</head>", SCRIPT + "</head>", 1)
        if new != page:
            stale.append(path)
            if not check:
                open(path, "w", encoding="utf-8").write(new)
    print(f"{len(stale)} page(s) {'out of date' if check else 'updated'}")
    if check and stale:
        sys.exit(1)


if __name__ == "__main__":
    main()
