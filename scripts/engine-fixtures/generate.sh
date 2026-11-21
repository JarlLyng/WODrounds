#!/bin/sh
# Fill in the expectations in test-fixtures/engine-timelines.json from the Swift engine.
# Run after changing a case, or after an intended change to Shared/WODTimerEngine.swift,
# then run both test suites (Xcode's WODroundsTests and android/ ./gradlew test).
set -e
cd "$(dirname "$0")/../.."
OUT="$(mktemp -d)/engine-fixtures"
xcrun swiftc -O Shared/WODTimerEngine.swift scripts/engine-fixtures/main.swift -o "$OUT"
"$OUT" test-fixtures/engine-timelines.json
