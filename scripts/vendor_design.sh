#!/usr/bin/env bash
# Copy the design system's files into the site, checked against the tag's own hashes (#197).
#
#     scripts/vendor_design.sh 1.32.2
#
# The live site serves iamjarl-design from its own origin, not from a CDN
# (iamjarl-design#100). A bump is a new folder next to the old one, never a file edited
# in place: run this with the new version, set DESIGN_VERSION in scripts/build_home.py,
# rebuild (build_home.py, build_pages.py), and delete the old folder.
set -euo pipefail
V="${1:?usage: scripts/vendor_design.sh <version>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/docs/assets/iamjarl-design@v$V"
SRC="$(mktemp -d)"
trap 'rm -rf "$SRC"' EXIT

curl -sfL "https://github.com/JarlLyng/iamjarl-design/archive/refs/tags/v$V.tar.gz" | tar -xz --strip-components=1 -C "$SRC"
mkdir -p "$DEST"
# What the pages load: the files below, every language's white App Store badge, and the
# JetBrains Mono faces the font sheet finds at ../../fonts/.
(cd "$SRC" && tar -cf - \
  dist/css/tokens.css dist/identity/wodrounds.css dist/fonts/jetbrains-mono.css \
  dist/kit/kit.css dist/kit/kit.js dist/components/ij-nav.js dist/components/ij-footer.js \
  badges/app-store-white-{en-us,da-dk,de-de,es-es,fr-fr,no-no,sv-se}.svg \
  fonts/jetbrains-mono-*.woff2) | tar -xf - -C "$DEST"

bad=0
while read -r f; do
  want=$(grep -o "\"$f\": \"sha384-[^\"]*" "$SRC/dist/sri.json" | cut -d'"' -f4)
  got="sha384-$(openssl dgst -sha384 -binary "$DEST/$f" | openssl base64 -A)"
  if [ -n "$want" ] && [ "$want" = "$got" ]; then echo "ok $f"; else echo "MISMATCH $f"; bad=1; fi
done < <(cd "$DEST" && find dist -type f | sort)
[ "$bad" = 0 ] || { echo "Hashes don't match the tag's dist/sri.json; not using this copy." >&2; exit 1; }
du -sh "$DEST"
