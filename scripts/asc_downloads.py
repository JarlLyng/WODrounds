#!/usr/bin/env python3
"""
Pull App Store Connect download / sales numbers from the command line.

NO secrets are stored in this repository. All credentials are read from
environment variables at runtime, and the private key stays on your machine
outside the repo (or in the repo root, where *.p8 is gitignored).

Required (via env vars, or a gitignored .env file the script auto-loads):
    ASC_KEY_ID         Key ID of your App Store Connect API key
    ASC_ISSUER_ID      Issuer ID (Users and Access -> Integrations)
    ASC_VENDOR_NUMBER  Vendor number (Payments and Financial Reports)
    ASC_PRIVATE_KEY    Path to AuthKey_XXXXXX.p8 (optional if one .p8 is in repo root)
"""

import argparse
import datetime
import gzip
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

try:
    import jwt  # PyJWT (needs the [crypto] extra for ES256)
except ImportError:
    sys.exit('Missing dependency. Run:  pip install "pyjwt[crypto]"')

API_URL = "https://api.appstoreconnect.apple.com/v1/salesReports"

# App Store Connect "Product Type Identifier" codes, split into first-time
# downloads vs. update/redownload installs. The 1-/3-series are first installs
# (iOS, iPad, universal); the 7-series are updates. The "F" prefix is the Mac
# App Store equivalent. Anything not listed (in-app purchases, etc.) falls into
# "other" so it never silently inflates either bucket — the raw per-type
# breakdown is always printed so you can verify the split.
DOWNLOAD_TYPES = {"1", "1F", "1T", "3", "3F", "F1", "F3"}
UPDATE_TYPES = {"7", "7F", "7T", "F7"}


def classify(product_type):
    if product_type in DOWNLOAD_TYPES:
        return "new"
    if product_type in UPDATE_TYPES:
        return "update"
    return "other"


def load_env_file() -> None:
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    for candidate in (os.path.join(os.getcwd(), ".env"), os.path.join(repo_root, ".env")):
        if not os.path.exists(candidate):
            continue
        with open(candidate) as handle:
            for line in handle:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, _, value = line.partition("=")
                os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def autodetect_private_key():
    import glob
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    matches = glob.glob(os.path.join(repo_root, "*.p8"))
    return matches[0] if len(matches) == 1 else None


def require_env(name: str) -> str:
    value = os.environ.get(name)
    if not value:
        sys.exit(f"Missing required environment variable: {name}")
    return value


def make_token(key_id, issuer_id, private_key_path):
    path = os.path.expanduser(private_key_path)
    try:
        with open(path, "r") as handle:
            private_key = handle.read()
    except OSError as error:
        sys.exit(f"Could not read private key at {path}: {error}")
    now = int(time.time())
    payload = {"iss": issuer_id, "iat": now, "exp": now + 19 * 60, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, private_key, algorithm="ES256",
                      headers={"kid": key_id, "typ": "JWT"})


def fetch_report(token, vendor, report_date, frequency="DAILY"):
    params = {
        "filter[frequency]": frequency,
        "filter[reportType]": "SALES",
        "filter[reportSubType]": "SUMMARY",
        "filter[vendorNumber]": vendor,
        "filter[reportDate]": report_date,
        # filter[version] omitted: the API picks the latest per report type
        # (daily SALES is 1_1, monthly is 1_0 — a fixed version 400s).
    }
    url = f"{API_URL}?{urllib.parse.urlencode(params)}"
    retries = 4
    for attempt in range(retries + 1):
        request = urllib.request.Request(
            url,
            headers={"Authorization": f"Bearer {token}", "Accept": "application/a-gzip"},
        )
        try:
            with urllib.request.urlopen(request) as response:
                return gzip.decompress(response.read()).decode("utf-8")
        except urllib.error.HTTPError as error:
            if error.code in (404, 410):  # no report / aged out — skip
                return None
            if error.code in (401, 403):  # bad key / wrong role — won't self-heal
                body = error.read().decode("utf-8", "replace")
                sys.exit(f"Auth error {error.code} for {report_date} — check your API "
                         f"Key ID, Issuer ID, .p8, and that the key has the "
                         f"'Sales and Reports' role:\n{body}")
            transient = error.code == 429 or 500 <= error.code < 600
            if transient and attempt < retries:
                wait = 2 ** attempt
                header_wait = error.headers.get("Retry-After")
                if header_wait and header_wait.isdigit():
                    wait = max(wait, int(header_wait))
                print(f"  {error.code} for {report_date}; retrying in {wait}s "
                      f"({attempt + 1}/{retries})", file=sys.stderr)
                time.sleep(wait)
                continue
            body = error.read().decode("utf-8", "replace")
            sys.exit(f"API error {error.code} for {report_date}: {body}")
        except urllib.error.URLError as error:  # transient network blip
            if attempt < retries:
                wait = 2 ** attempt
                print(f"  network error for {report_date}: {error.reason}; "
                      f"retrying in {wait}s ({attempt + 1}/{retries})", file=sys.stderr)
                time.sleep(wait)
                continue
            sys.exit(f"Network error for {report_date}: {error.reason}")


def parse_rows(tsv):
    lines = tsv.splitlines()
    if len(lines) < 2:
        return []
    header = lines[0].split("\t")
    index = {name: i for i, name in enumerate(header)}
    rows = []
    for line in lines[1:]:
        cols = line.split("\t")
        if len(cols) < len(header):
            continue
        def col(name):
            return cols[index[name]] if name in index else ""
        try:
            units = int(col("Units") or 0)
        except ValueError:
            units = 0
        rows.append({"units": units, "type": col("Product Type Identifier"),
                     "country": col("Country Code"), "title": col("Title"),
                     "apple_id": col("Apple Identifier")})
    return rows


def main():
    parser = argparse.ArgumentParser(description="Pull App Store Connect sales/downloads.")
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--days", type=int, default=7, help="recent days to pull (default 7)")
    group.add_argument("--date", help="a single report date, YYYY-MM-DD")
    group.add_argument("--all-time", action="store_true", dest="all_time",
                       help="total since release: monthly reports + current month's daily reports")
    parser.add_argument("--app", help="filter to one app by Apple ID or title substring")
    args = parser.parse_args()

    load_env_file()
    key_id = require_env("ASC_KEY_ID")
    issuer_id = require_env("ASC_ISSUER_ID")
    private_key = os.environ.get("ASC_PRIVATE_KEY") or autodetect_private_key()
    if not private_key:
        sys.exit("Set ASC_PRIVATE_KEY, or place a single .p8 in the repo root.")
    vendor = require_env("ASC_VENDOR_NUMBER")
    token = make_token(key_id, issuer_id, private_key)

    today = datetime.date.today()
    keys = []
    if args.all_time:
        year, month = today.year, today.month
        for _ in range(12):
            month -= 1
            if month == 0:
                year, month = year - 1, 12
            keys.append(("MONTHLY", f"{year:04d}-{month:02d}"))
        keys.reverse()
        for day in range(1, today.day + 1):
            keys.append(("DAILY", datetime.date(today.year, today.month, day).isoformat()))
    elif args.date:
        keys = [("DAILY", args.date)]
    else:
        days = [(today - datetime.timedelta(days=o)).isoformat() for o in range(1, args.days + 1)]
        days.reverse()
        keys = [("DAILY", d) for d in days]

    def matches(row):
        if not args.app:
            return True
        needle = args.app.lower()
        return needle == row["apple_id"].lower() or needle in row["title"].lower()

    per_period, by_type, by_country, by_app = [], {}, {}, {}
    totals = {"new": 0, "update": 0, "other": 0}
    found_any = False
    for frequency, report_date in keys:
        tsv = fetch_report(token, vendor, report_date, frequency)
        if tsv is None:
            per_period.append((report_date, None))
            continue
        found_any = True
        rows = [r for r in parse_rows(tsv) if matches(r)]
        period = {"new": 0, "update": 0, "other": 0}
        for r in rows:
            bucket = classify(r["type"])
            period[bucket] += r["units"]
            totals[bucket] += r["units"]
            by_type[r["type"]] = by_type.get(r["type"], 0) + r["units"]
            if bucket == "new":  # country/app cuts track first-time downloads
                by_country[r["country"]] = by_country.get(r["country"], 0) + r["units"]
                by_app[r["title"]] = by_app.get(r["title"], 0) + r["units"]
        per_period.append((report_date, period))

    if not found_any:
        print("No reports available for the requested range yet (reports lag ~24-48h).")
        return

    print(f"Scope: {'app filter: ' + args.app if args.app else 'whole vendor account (all apps)'}\n")
    print(f"{'Period':<12}{'New':>8}{'Updates':>9}\n" + "-" * 29)
    for label, period in per_period:
        if period is None:
            print(f"{label:<12}{'(no report)':>17}")
        else:
            print(f"{label:<12}{period['new']:>8}{period['update']:>9}")
    print("-" * 29 + f"\n{'TOTAL':<12}{totals['new']:>8}{totals['update']:>9}")
    if totals["other"]:
        print(f"({totals['other']} other unit(s): in-app purchases / unclassified — "
              f"see 'By product type' below)")
    if not args.app:
        print("\nNew downloads — by app:")
        for title, units in sorted(by_app.items(), key=lambda kv: -kv[1]):
            print(f"  {(title or '(blank)')[:34]:<36}{units:>6}")
    print("\nBy product type (raw, all units):")
    for ptype, units in sorted(by_type.items(), key=lambda kv: -kv[1]):
        kind = classify(ptype)
        tag = {"new": "new download", "update": "update", "other": "other"}[kind]
        print(f"  {ptype or '(blank)':<6}{units:>8}   {tag}")
    print("\nTop countries (new downloads):")
    for country, units in sorted(by_country.items(), key=lambda kv: -kv[1])[:10]:
        print(f"  {country or '(blank)':<10}{units:>8}")


if __name__ == "__main__":
    main()
