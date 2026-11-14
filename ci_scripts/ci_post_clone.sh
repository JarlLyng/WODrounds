#!/bin/sh
# Xcode Cloud runs this immediately after cloning the repository.
#
# Sentry.xcconfig is gitignored (see .gitignore), so a fresh clone has no
# config file and the build fails at the `#include "Sentry.xcconfig"` reference.
# Recreate it here from the SENTRY_DSN environment variable, which you set as a
# (secret) environment variable on the Xcode Cloud workflow.
#
# If SENTRY_DSN is not set, we still write the file with an empty value: the app
# treats an empty DSN as "crash reporting disabled" (see Telemetry.swift), so
# builds and tests still run. An archive without it is stopped by
# ci_pre_xcodebuild.sh, so a release can't ship without crash reports unnoticed. The DSN is a public client credential (it ships in the app binary), so a
# workflow env var is an appropriate place for it.

set -e

CONFIG="${CI_PRIMARY_REPOSITORY_PATH:-..}/Sentry.xcconfig"
printf 'SENTRY_DSN = %s\n' "${SENTRY_DSN}" > "$CONFIG"

if [ -n "${SENTRY_DSN}" ]; then
  echo "ci_post_clone: wrote Sentry.xcconfig with a DSN"
else
  echo "ci_post_clone: wrote Sentry.xcconfig with an empty DSN (crash reporting off)"
fi
