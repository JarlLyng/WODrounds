# scripts/

Local utilities for this repo.

## `validate_docs.py` — marketing-site / docs validation

Checks the `docs/` marketing site: image references, App Store URLs, JSON-LD validity,
sitemap integrity, and canonical URLs. Run before committing docs changes:

```bash
python3 scripts/validate_docs.py
```

Also runs in CI on every push to `main` via `.github/workflows/docs.yml`.

## `generate_icons.rb` — app icon asset generation

Generates the app icon assets for all platforms. See `docs/APP_ICONS.md` for the checklist.

## App Store Connect analytics / downloads (moved)

The App Store Connect tooling (`asc_downloads.py`, `asc_analytics.py`) has **moved to the
private `iamjarl-strategy` repo** under `tools/`, because it is a portfolio-wide,
vendor-account tool (one Apple key serves every app, isolated with `--app`), and the
numbers it pulls are strategy material. See `DATA_ACCESS.md` in that repo. No App Store
credentials live in this public repo anymore.
