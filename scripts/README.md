# scripts/

Local utilities for this repo.

## `validate_docs.py` — marketing-site / docs validation

Checks the `docs/` marketing site: image references, App Store URLs, JSON-LD validity,
sitemap integrity, and canonical URLs. Run before committing docs changes:

```bash
python3 scripts/validate_docs.py
```

Also runs in CI on every push to `main` via `.github/workflows/docs.yml`.

## `build_sitemap.py`: true `lastmod` dates

Writes each page's `<lastmod>` in `docs/sitemap.xml` from git (#174): the day of the last
commit that touched the page, or today for a page the branch changes. Run it after changing
any page, and again before merging if the branch merges on a later day:

```bash
python3 scripts/build_sitemap.py
```

`--check` exits 1 if a date is out of date.

## `generate_icons.rb` — app icon asset generation

Generates the app icon assets for all platforms. See `docs/APP_ICONS.md` for the checklist.

## App Store Connect

No App Store Connect tooling or credentials live in this repo. The analytics and download
scripts that used to be here are shared across the IAMJARL apps and kept outside it.
