# WODrounds on Android: a trial

A bounded trial, not a release: is WODrounds on Android worth building? It runs **one mode
end to end, EMOM**, so there's a working Android version to judge rather than a guess. Nothing
here is on Google Play, and nothing here touches the iOS app.

## What's here

- `app/src/main/java/com/iamjarl/wodrounds/engine/WODTimerEngine.kt`: a line-for-line Kotlin
  port of `Shared/WODTimerEngine.swift`, all three modes (EMOM, Intervals, For Time), with no
  UI, sound or clock of its own.
- `app/src/main/java/com/iamjarl/wodrounds/EmomScreen.kt`: EMOM in Jetpack Compose. Rounds
  (1–120) and round length (0:30–9:30), remembered between launches. Start, a 10-second Get
  ready, the countdown of each round, Round x / n, Pause and Resume, Cancel (which asks first),
  and Done. A 3-2-1 beep before each new round, as a short tone on the media stream. The screen
  stays on during the count-in and the workout.
- `app/src/test/.../EngineTimelineTest.kt`: runs `../test-fixtures/engine-timelines.json`, the
  timelines the Swift suite runs too (`WODroundsTests/EngineTimelineTests.swift`). If both pass,
  the two engines report the same state, round, phase and times at every step.

The app ID is `com.iamjarl.wodrounds.trial`, so it never collides with a future app on Play.
Target and compile SDK 36, min SDK 29 (Android 10).

## Build and run

Needs JDK 17 and the Android SDK (platform 36).

```sh
cd android
./gradlew testDebugUnitTest   # the shared engine timelines
./gradlew assembleDebug       # app/build/outputs/apk/debug/app-debug.apk
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

On a phone, the debug APK installs once "Install unknown apps" is allowed for the app that
opens it (Files, or the browser).

## Changing the engine

The Swift engine is the reference. After an intended change to it, or a new case in
`test-fixtures/engine-timelines.json`, run `scripts/engine-fixtures/generate.sh` to write the
expectations from the Swift engine, then make the Kotlin port pass `./gradlew testDebugUnitTest`.

There's no Gradle job in CI: the trial stays out of the checks `main` needs. The Swift side of
the shared timelines runs in the existing "Unit tests (WODTimerEngine)" job.
