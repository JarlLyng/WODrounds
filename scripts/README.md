# scripts/

Small local utilities. **Nothing here is secret-in-the-repo** — App Store Connect
credentials are read from environment variables / a gitignored `.env`, and the
`.p8` private key is gitignored (`*.p8`). See the root `.gitignore`.

## `asc_downloads.py` — App Store Connect downloads / sales

Pulls download and sales numbers from the App Store Connect Sales and Reports API.

### One-time setup

1. **Create an API key** in App Store Connect → **Users and Access → Integrations →
   App Store Connect API**. Give it the **Sales and Reports** access role (that's all
   this script needs — read-only sales data). Download the `AuthKey_XXXXXX.p8` file.
   Apple lets you download it **once** — keep it safe.
2. Note the three identifiers:
   - **Key ID** — shown next to the key.
   - **Issuer ID** — shown at the top of the Integrations page.
   - **Vendor Number** — in **Payments and Financial Reports** (top-left, next to your
     account name).
3. **Configure credentials locally:**
   ```bash
   cp .env.example .env          # .env is gitignored
   # edit .env and fill in ASC_KEY_ID, ASC_ISSUER_ID, ASC_VENDOR_NUMBER
   ```
4. **Provide the private key** one of two ways:
   - Drop the `AuthKey_XXXXXX.p8` file in the **repo root** — a single `.p8` there is
     auto-detected (and gitignored), or
   - Set `ASC_PRIVATE_KEY=/path/to/AuthKey_XXXXXX.p8` in `.env`.

### Install dependencies (gitignored virtualenv)

```bash
python3 -m venv .venv
.venv/bin/pip install "pyjwt[crypto]"
```

### Usage

```bash
.venv/bin/python scripts/asc_downloads.py --help          # no credentials needed
.venv/bin/python scripts/asc_downloads.py                 # last 7 days (daily)
.venv/bin/python scripts/asc_downloads.py --days 30        # last 30 days
.venv/bin/python scripts/asc_downloads.py --date 2026-06-01
.venv/bin/python scripts/asc_downloads.py --all-time       # since release
.venv/bin/python scripts/asc_downloads.py --all-time --app <APPLE_ID>   # one app only
```

### Output

Each period is split into **New** (first-time downloads) and **Updates**
(update/redownload installs), so the headline numbers aren't conflated:

```
Period           New  Updates
-----------------------------
2026-05           19       27
2026-06-04         1       10
...
-----------------------------
TOTAL             47       54
```

A raw **By product type** table is always printed so you can verify the split,
and the per-app / per-country cuts count **new downloads only**.

### Notes / gotchas

- The Sales report covers your **whole vendor account (all apps)**. Use
  `--app <Apple ID>` to isolate one app (Apple ID is in App Store Connect → your app →
  **App Information**). `--app` also accepts a title substring.
- **Product type codes** distinguish new downloads from updates: iOS `1`/`1F`/`1T`,
  iPad `3`/`3F`, and Mac `F1`/`F3` are new downloads; iOS `7`/`7F`/`7T` and Mac `F7`
  are updates. The mapping lives in `DOWNLOAD_TYPES` / `UPDATE_TYPES` at the top of
  `asc_downloads.py` — edit there if Apple adds a code. Unrecognised codes (in-app
  purchases, etc.) are counted as "other" and never inflate either bucket.
- Transient API failures (`429` rate-limit, `5xx`, network blips) are retried with
  backoff; auth errors (`401`/`403`) fail fast with a hint to check the key/role.
- Reports lag **~24–48h** — the most recent day(s) will show `(no report)`. Normal.
- Apple retains **monthly** reports for 12 months and **daily** reports for 365 days,
  so `--all-time` is approximate beyond those windows.

## `asc_analytics.py` — App Store Connect App Analytics

Pulls **App Analytics** (impressions, product page views, conversion, downloads,
sessions, retention) via the Analytics Reports API. This is separate from the
Sales API above and works differently: you enroll the app once, Apple generates
reports over the following ~24h+, then you list and download them.

### One-time enrollment (needs an Admin key)

Creating the report request the first time requires an **Admin** App Store
Connect API key. After that, the normal Sales and Reports key can list and
download. Create a temporary Admin key, enroll, then delete it:

```bash
# with the temporary Admin key's id + .p8 path (kept outside the repo):
ASC_ADMIN_KEY_ID=XXXX ASC_ADMIN_PRIVATE_KEY=/path/AuthKey_XXXX.p8 \
  .venv/bin/python scripts/asc_analytics.py enroll --access ONE_TIME_SNAPSHOT   # history
ASC_ADMIN_KEY_ID=XXXX ASC_ADMIN_PRIVATE_KEY=/path/AuthKey_XXXX.p8 \
  .venv/bin/python scripts/asc_analytics.py enroll --access ONGOING            # daily going forward
```

Then delete the Admin key in App Store Connect. The report request persists on
Apple's side and the Sales key can read it.

### Reading (normal Sales key)

```bash
.venv/bin/python scripts/asc_analytics.py requests   # list enrollments
.venv/bin/python scripts/asc_analytics.py reports    # list generated report types
```

Reports take ~24h+ to appear after enrollment. Downloading and parsing the
report segments is added once real reports exist (the segment format is easier
to handle against real data than to guess).
