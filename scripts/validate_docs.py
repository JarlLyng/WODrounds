#!/usr/bin/env python3
"""
Validate integrity of docs/ marketing site.

Runs five checks:
1. Image references: all images/*.png etc. referenced in HTML exist as files
2. App Store URLs: all apps.apple.com links include the app ID (id6759229877)
3. JSON-LD: all <script type="application/ld+json"> blocks parse as valid JSON
4. Sitemap: all URLs in sitemap.xml correspond to actual HTML files
5. Canonical URLs: each HTML file's canonical URL matches its path

Exits 0 on success, 1 on any failure. Designed to run locally and in CI.

Usage:
    python3 scripts/validate_docs.py
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS = REPO_ROOT / "docs"
SITE_URL = "https://wodrounds.iamjarl.com"
APP_ID = "6759229877"


class Failures:
    """Collect errors and print them in GitHub Actions format when possible."""

    def __init__(self) -> None:
        self.count = 0

    def error(self, message: str, file: Path | None = None) -> None:
        self.count += 1
        if file is not None:
            rel = file.relative_to(REPO_ROOT)
            print(f"::error file={rel}::{message}")
        else:
            print(f"::error::{message}")


def check_image_references(failures: Failures) -> None:
    """All images/*.ext referenced in HTML must exist as files.
    Handles both top-level (`images/...`) and subdirectory (`../images/...`) refs.
    """
    print("→ Checking image references...")
    # Match: src="(../)images/foo.png", or full URL with images/
    pattern = re.compile(
        r'(?:src=|url\(|"|\')(?:https://wodrounds\.iamjarl\.com/|\.\./)?'
        r'(images/[A-Za-z0-9_\-./]+\.(?:png|jpg|jpeg|svg|webp|gif))'
    )
    references: set[tuple[str, Path]] = set()
    for html in DOCS.rglob("*.html"):
        content = html.read_text()
        for match in pattern.finditer(content):
            references.add((match.group(1), html))

    for rel_path, source_file in references:
        full_path = DOCS / rel_path
        if not full_path.exists():
            failures.error(
                f"Missing image: {rel_path}",
                file=source_file,
            )


def check_app_store_urls(failures: Failures) -> None:
    """All apps.apple.com URLs must include /id<digits>.
    URLs referencing our own app must use our specific APP_ID.
    """
    print("→ Checking App Store URLs...")
    url_pattern = re.compile(r"https://apps\.apple\.com/[^\"'\s)]+")
    id_pattern = re.compile(r"/id\d+")
    for html in DOCS.rglob("*.html"):
        content = html.read_text()
        for match in url_pattern.finditer(content):
            url = match.group(0)
            # All App Store URLs must have a /id<digits> segment so analytics
            # and attribution work correctly.
            if not id_pattern.search(url):
                failures.error(
                    f"App Store URL missing /id<digits>: {url}",
                    file=html,
                )
                continue
            # URLs for our own app must use our specific APP_ID.
            if "/wodrounds" in url.lower() and f"id{APP_ID}" not in url:
                failures.error(
                    f"WODrounds App Store URL has wrong app ID (expected id{APP_ID}): {url}",
                    file=html,
                )


def check_json_ld(failures: Failures) -> None:
    """Every <script type="application/ld+json"> block must be valid JSON."""
    print("→ Validating JSON-LD blocks...")
    pattern = re.compile(
        r'<script type="application/ld\+json">\s*(.*?)\s*</script>',
        re.DOTALL,
    )
    for html in DOCS.rglob("*.html"):
        content = html.read_text()
        for idx, match in enumerate(pattern.finditer(content), start=1):
            block = match.group(1)
            try:
                data = json.loads(block)
            except json.JSONDecodeError as exc:
                failures.error(
                    f"JSON-LD block #{idx} is invalid: {exc}",
                    file=html,
                )
                continue
            # Light sanity check: must have @context
            if isinstance(data, dict) and "@context" not in data:
                failures.error(
                    f"JSON-LD block #{idx} missing @context",
                    file=html,
                )


def check_sitemap(failures: Failures) -> None:
    """Every <loc> in sitemap.xml must point to an existing HTML file."""
    print("→ Checking sitemap URLs...")
    sitemap = DOCS / "sitemap.xml"
    if not sitemap.exists():
        failures.error("sitemap.xml not found", file=None)
        return

    content = sitemap.read_text()
    for match in re.finditer(r"<loc>([^<]+)</loc>", content):
        url = match.group(1).strip()
        if not url.startswith(SITE_URL):
            failures.error(
                f"Sitemap URL outside site: {url}",
                file=sitemap,
            )
            continue
        rel = url[len(SITE_URL):].lstrip("/")
        if rel == "":
            rel = "index.html"
        target = DOCS / rel
        if not target.exists():
            failures.error(
                f"Sitemap references missing file: docs/{rel}",
                file=sitemap,
            )


def check_canonical_urls(failures: Failures) -> None:
    """Each HTML file's canonical URL must match its on-disk path.
    Handles subdirectories (e.g. da/emom-timer.html → /da/emom-timer.html).
    """
    print("→ Checking canonical URLs...")
    pattern = re.compile(r'rel="canonical"\s+href="([^"]+)"')
    for html in DOCS.rglob("*.html"):
        content = html.read_text()
        match = pattern.search(content)
        if not match:
            continue  # Not every page needs canonical (e.g. error pages)
        canonical = match.group(1)

        rel = html.relative_to(DOCS)
        if rel.name == "index.html" and rel.parent == Path("."):
            expected_options = {
                f"{SITE_URL}/",
                f"{SITE_URL}/index.html",
            }
        else:
            # Use forward slashes for URL paths (works on Windows too).
            url_path = "/".join(rel.parts)
            expected_options = {f"{SITE_URL}/{url_path}"}

        if canonical not in expected_options:
            failures.error(
                f"Canonical URL mismatch: {canonical} (expected one of: "
                f"{', '.join(sorted(expected_options))})",
                file=html,
            )


def main() -> int:
    if not DOCS.is_dir():
        print(f"::error::docs/ not found at {DOCS}")
        return 1

    failures = Failures()

    check_image_references(failures)
    check_app_store_urls(failures)
    check_json_ld(failures)
    check_sitemap(failures)
    check_canonical_urls(failures)

    print()
    if failures.count:
        print(f"❌ {failures.count} issue(s) found.")
        return 1

    print("✅ All docs integrity checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
