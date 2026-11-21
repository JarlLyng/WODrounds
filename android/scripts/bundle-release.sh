#!/bin/sh
# Build a signed app bundle for Google Play's internal track.
# The upload key is at ~/.android/keystores/wodrounds-upload.jks, outside the repo, and its
# password is in the macOS keychain (service "wodrounds-android-upload"). Neither is printed.
set -e
cd "$(dirname "$0")/.."
# No build for Play without Sentry's DSN (as ci_pre_xcodebuild.sh on iOS): the environment's
# SENTRY_DSN, else sentry.dsn in local.properties.
if [ -z "$SENTRY_DSN" ] && ! grep -qE '^sentry\.dsn=https://[^@]+@.+/[0-9]+$' local.properties 2>/dev/null; then
    echo "No Sentry DSN: set SENTRY_DSN or sentry.dsn in android/local.properties" >&2
    exit 1
fi
export WODROUNDS_UPLOAD_STORE="$HOME/.android/keystores/wodrounds-upload.jks"
WODROUNDS_UPLOAD_PASSWORD="$(security find-generic-password -s wodrounds-android-upload -w)"
export WODROUNDS_UPLOAD_PASSWORD
./gradlew --no-daemon -q bundleRelease
echo "app/build/outputs/bundle/release/app-release.aab"
