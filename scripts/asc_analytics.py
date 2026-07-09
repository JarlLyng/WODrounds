#!/usr/bin/env python3
"""
App Store Connect **App Analytics** from the command line (impressions, product
page views, conversion, downloads, sessions, retention, ...).

This is separate from scripts/asc_downloads.py, which uses the Sales and Reports
API. Analytics works differently: you first *request* a report for the app (an
enrollment), Apple generates report instances over time, and you then download
the generated segments.

Roles (per Apple): creating a report request the first time needs an **Admin**
key; once it exists, a **Sales and Reports** key can list and download. So:

    enroll   → uses the ADMIN key (ASC_ADMIN_KEY_ID / ASC_ADMIN_PRIVATE_KEY).
               Run once, then you can delete the Admin key.
    requests → list this app's analytics report requests (Sales key is fine).
    reports  → list the report types generated for a request (Sales key).

Credentials come from env vars / a gitignored .env (same loader as
asc_downloads.py). No secrets are stored in this repo.
    ASC_ISSUER_ID          Issuer ID (shared across keys on the team)
    ASC_KEY_ID             Sales key id (for requests/reports)
    ASC_PRIVATE_KEY        Path to the Sales AuthKey .p8 (or single .p8 in root)
    ASC_ADMIN_KEY_ID       Admin key id (for enroll only; temporary)
    ASC_ADMIN_PRIVATE_KEY  Path to the Admin AuthKey .p8 (for enroll only)
    ASC_APP_ID             App's Apple ID (defaults to WODrounds, 6759229877)
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import sys
import time
import urllib.error
import urllib.request

try:
    import jwt  # PyJWT[crypto]
except ImportError:
    sys.exit('Missing dependency. Run:  .venv/bin/pip install "pyjwt[crypto]"')

BASE = "https://api.appstoreconnect.apple.com/v1"
DEFAULT_APP_ID = "6759229877"  # WODrounds


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
    repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    matches = glob.glob(os.path.join(repo_root, "*.p8"))
    return matches[0] if len(matches) == 1 else None


def make_token(key_id: str, issuer_id: str, private_key_path: str) -> str:
    path = os.path.expanduser(private_key_path)
    try:
        with open(path) as handle:
            private_key = handle.read()
    except OSError as error:
        sys.exit(f"Could not read private key at {path}: {error}")
    now = int(time.time())
    payload = {"iss": issuer_id, "iat": now, "exp": now + 19 * 60, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, private_key, algorithm="ES256", headers={"kid": key_id, "typ": "JWT"})


def request(method: str, url: str, token: str, body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    })
    try:
        with urllib.request.urlopen(req) as resp:
            raw = resp.read().decode("utf-8")
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", "replace")
        if error.code in (401, 403):
            sys.exit(f"Auth error {error.code}: this key's role is not allowed for this "
                     f"call. Enroll needs an Admin key; listing needs Sales/Admin.\n{detail}")
        sys.exit(f"API error {error.code} for {method} {url}:\n{detail}")


def issuer() -> str:
    v = os.environ.get("ASC_ISSUER_ID")
    if not v:
        sys.exit("Missing ASC_ISSUER_ID")
    return v


def sales_token() -> str:
    key_id = os.environ.get("ASC_KEY_ID") or sys.exit("Missing ASC_KEY_ID")
    pk = os.environ.get("ASC_PRIVATE_KEY") or autodetect_private_key()
    if not pk:
        sys.exit("Set ASC_PRIVATE_KEY or place a single .p8 in the repo root.")
    return make_token(key_id, issuer(), pk)


def admin_token() -> str:
    key_id = os.environ.get("ASC_ADMIN_KEY_ID")
    pk = os.environ.get("ASC_ADMIN_PRIVATE_KEY")
    if not key_id or not pk:
        sys.exit("Enroll needs ASC_ADMIN_KEY_ID and ASC_ADMIN_PRIVATE_KEY (temporary Admin key).")
    return make_token(key_id, issuer(), pk)


def app_id() -> str:
    return os.environ.get("ASC_APP_ID", DEFAULT_APP_ID)


def cmd_enroll(access_type: str) -> None:
    token = admin_token()
    body = {"data": {
        "type": "analyticsReportRequests",
        "attributes": {"accessType": access_type},
        "relationships": {"app": {"data": {"type": "apps", "id": app_id()}}},
    }}
    result = request("POST", f"{BASE}/analyticsReportRequests", token, body)
    rid = result.get("data", {}).get("id", "?")
    print(f"Created analytics report request ({access_type}): id={rid}")
    print("You can delete the temporary Admin key now. Reports generate over the")
    print("next ~24h+; then run:  scripts/asc_analytics.py reports")


def cmd_requests() -> None:
    token = sales_token()
    result = request("GET", f"{BASE}/apps/{app_id()}/analyticsReportRequests?limit=50", token)
    rows = result.get("data", [])
    if not rows:
        print("No analytics report requests yet. Enroll first (needs an Admin key).")
        return
    print(f"{'Access type':<22}{'Stopped':<9}{'ID'}")
    print("-" * 60)
    for r in rows:
        a = r.get("attributes", {})
        print(f"{a.get('accessType',''):<22}{str(a.get('stoppedDueToInactivity','')):<9}{r.get('id','')}")


def cmd_reports(req_id: str | None) -> None:
    token = sales_token()
    if not req_id:
        result = request("GET", f"{BASE}/apps/{app_id()}/analyticsReportRequests?limit=50", token)
        reqs = result.get("data", [])
        if not reqs:
            print("No report requests yet. Enroll first.")
            return
        req_id = reqs[0]["id"]
        print(f"(using report request {req_id})\n")
    result = request("GET", f"{BASE}/analyticsReportRequests/{req_id}/reports?limit=200", token)
    rows = result.get("data", [])
    if not rows:
        print("No reports generated yet. Apple needs ~24h+ after enrollment. Check back.")
        return
    print(f"{'Category':<26}{'Name'}")
    print("-" * 70)
    for r in rows:
        a = r.get("attributes", {})
        print(f"{a.get('category',''):<26}{a.get('name','')}")
    print(f"\n{len(rows)} report(s). Next step (once data exists): download instances + segments.")


def main() -> None:
    parser = argparse.ArgumentParser(description="App Store Connect App Analytics.")
    sub = parser.add_subparsers(dest="cmd", required=True)
    e = sub.add_parser("enroll", help="request analytics reports for the app (needs Admin key)")
    e.add_argument("--access", choices=["ONGOING", "ONE_TIME_SNAPSHOT"], default="ONGOING")
    sub.add_parser("requests", help="list the app's analytics report requests")
    rp = sub.add_parser("reports", help="list report types generated for a request")
    rp.add_argument("--request-id", help="report request id (defaults to the newest)")
    args = parser.parse_args()

    load_env_file()
    if args.cmd == "enroll":
        cmd_enroll(args.access)
    elif args.cmd == "requests":
        cmd_requests()
    elif args.cmd == "reports":
        cmd_reports(getattr(args, "request_id", None))


if __name__ == "__main__":
    main()
