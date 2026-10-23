#!/usr/bin/env python3
"""Write each page's <lastmod> in docs/sitemap.xml from git (#174).

    python3 scripts/build_sitemap.py            # rewrite the dates in place
    python3 scripts/build_sitemap.py --check    # exit 1 if a date is out of date

A page's date is the day of the last commit that touched its file. A page the branch
changes, committed or not, gets today's date instead, because it goes live the day the
branch merges: if that turns out to be a later day, run this again before merging. On
main, with nothing waiting to merge, every date is git's own. The branch is measured
against origin/main, so fetch first.

Google uses lastmod only from sites whose dates it can trust, so never write one by hand
and never stamp the same day on every page.
"""
from __future__ import annotations

import re
import subprocess
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
SITEMAP = DOCS / "sitemap.xml"
BASE = "origin/main"

URL = re.compile(r"(<loc>https://wodrounds\.iamjarl\.com/([^<]*)</loc>\s*<lastmod>)([^<]*)(</lastmod>)")


def git(*args: str) -> str:
    return subprocess.run(["git", *args], cwd=ROOT, check=True, capture_output=True, text=True).stdout.strip()


def file_for(loc: str) -> str:
    path = DOCS / loc / "index.html" if loc == "" or loc.endswith("/") else DOCS / loc
    return str(path.relative_to(ROOT))


def main() -> None:
    check = "--check" in sys.argv
    # What this branch changes since it left main, including what isn't committed yet.
    fork = git("merge-base", BASE, "HEAD")
    changed = set(git("diff", "--name-only", fork, "--", "docs").splitlines())
    today = date.today().isoformat()
    stale = []

    def lastmod(m: re.Match) -> str:
        rel = file_for(m.group(2))
        day = today if rel in changed else git("log", "-1", "--format=%cs", "HEAD", "--", rel)
        if not day:
            sys.exit(f"{rel} is in the sitemap but has no commit")
        if day != m.group(3):
            stale.append(f"{rel}: {m.group(3)} -> {day}")
        return m.group(1) + day + m.group(4)

    sitemap = SITEMAP.read_text()
    out = URL.sub(lastmod, sitemap)
    for line in stale:
        print(line)
    print(f"{len(stale)} date(s) {'out of date' if check else 'written'}")
    if check:
        if stale:
            sys.exit(1)
    elif out != sitemap:
        SITEMAP.write_text(out)


if __name__ == "__main__":
    main()
