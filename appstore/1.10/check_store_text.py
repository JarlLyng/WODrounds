#!/usr/bin/env python3
"""Count every field in store-text.md against App Store Connect's limits (#199).

    python3 appstore/1.10/check_store_text.py

Each field is a `#### platform · locale · field` heading with a ```text block under it.
The keyword field is counted in UTF-8 bytes, since Apple's limit is 100 bytes and æ, ø, å
and accented letters take two. Exits 1 if a field is over its limit, a keyword field has a
space after a comma, or any public text has an em-dash or "CrossFit".
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

TEXT = Path(__file__).with_name("store-text.md").read_text()

# field name -> (limit, unit)
LIMITS = {
    "keywords": (100, "bytes"),
    "promotional text": (170, "chars"),
    "description": (4000, "chars"),
    "what's new": (4000, "chars"),
    "name": (30, "chars"),
    "short description": (50, "chars"),
    "long description": (120, "chars"),
    "privacy policy": (4000, "chars"),
}

FIELD = re.compile(r"^#### (\S+) · (\S+) · ([^\n(]+?)( \([^\n]*\))?\n```text\n(.*?)\n```", re.M | re.S)

bad = 0
for platform, locale, field, variant, body in FIELD.findall(TEXT):
    field = field.strip()
    kind = "description" if field == "description" else field
    limit, unit = LIMITS.get(kind, (None, None))
    size = len(body.encode()) if unit == "bytes" else len(body)
    problems = []
    if limit and size > limit:
        problems.append(f"over {limit}")
    if field == "keywords" and ", " in body:
        problems.append("space after comma")
    if "—" in body:
        problems.append("em-dash")
    if re.search(r"crossfit", body, re.I):
        problems.append("CrossFit")
    bad += bool(problems)
    shown = f"{size}/{limit} {unit}" if limit else f"{size} chars"
    print(f"{'!!' if problems else 'ok'} {platform:6} {locale:6} {field + variant:34} {shown:16} {' '.join(problems)}")

sys.exit(1 if bad else 0)
