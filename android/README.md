# WODrounds on Android: a trial

WODrounds on Android. It began as a bounded trial with EMOM only; the owner decided on
2026-11-22 that it goes to Google Play, and it now runs **all three modes**. It reaches the
owner's test phone through Google Play's internal testing, and nothing here touches the iOS app.

## What's here

- `app/src/main/java/com/iamjarl/wodrounds/engine/WODTimerEngine.kt`: a line-for-line Kotlin
  port of `Shared/WODTimerEngine.swift`, all three modes (EMOM, Intervals, For Time), with no
  UI, sound or clock of its own.
- `app/src/main/java/com/iamjarl/wodrounds/TimerScreen.kt`: the three modes in Jetpack
  Compose, with the iOS ranges and texts, remembered between launches under the iOS keys:
  EMOM (rounds and round length), Intervals (work, rest and rounds, with Work or Rest, the ring
  that drains over each phase, and the time left in the workout) and For Time (counts up, an
  optional cap up to 60:00, Stop, "Finished in"). Start, a 10-second Get ready, Pause and
  Resume, Cancel (which asks first) and Done. The steppers repeat while held. A sound switch
  silences the voice and beeps, as iOS's speaker button, and an About screen as iOS's. The
  screen only shows the workout.
  The layout is iOS's (`iOSContentView.swift`), which is the reference: every size follows
  from the space the app has, with iOS's scale rules, so it fits a small phone, the largest
  display size and a tablet alike; two columns when the screen is about as wide as it is
  tall (landscape, a tablet on its side, a foldable's inner screen); labels shrink to fit
  rather than being cut. Light and dark follow the system, in the iamjarl-design colours.
  The type is JetBrains Mono, the WODrounds display face (OFL-1.1, licence in `assets/`),
  converted from iamjarl-design's `fonts/` because Android's own monospace has no bold.
- `Setup.kt`: the setup values under the iOS keys, and `Capture`, which opens a debug build
  on any screen for screenshots, as iOS's SiteCapture (the extras are in its comment).
- `Workout.kt` and `WorkoutService.kt`: the workout, and a foreground service of type
  `specialUse` (with the reason in the manifest, for Play's review) that ticks it ten times a
  second, plays the cues and shows the time in an ongoing notification, so it carries on with the screen off. A partial wake lock keeps the CPU
  running for the workout only (capped at 3 hours), and the service stops itself on Done or
  Cancel. On Android 13+ the app asks for notifications on the first Start; the workout runs
  either way.
- `Cues.kt`: every sound and haptic as iOS plays them. The recorded English voice files
  (Get ready, 10, 5 and 2 rounds left, You did it) from `WODrounds/en.lproj`, "halfway" and
  "ten seconds" in the system voice, the 3-2-1 beep, and haptics on each new round or phase
  and on Done. Mixed with the user's music. Debug builds log each cue (`adb logcat -s
  WODroundsCues`) for checking timing on a device.
- `app/src/main/java/com/iamjarl/wodrounds/Telemetry.kt`: anonymous Sentry crash reports and
  sessions (`docs/SENTRY.md` § Android).
- `app/src/test/.../EngineTimelineTest.kt`: runs `../test-fixtures/engine-timelines.json`, the
  timelines the Swift suite runs too (`WODroundsTests/EngineTimelineTests.swift`). If both pass,
  the two engines report the same state, round, phase and times at every step.

The app ID is `com.iamjarl.wodrounds` (owner, 2026-11-22), permanent from the first upload to
Play; the Play app is created as paid, like iOS. Target and compile SDK 36, min SDK 29
(Android 10).

## Build and run

Needs JDK 17 and the Android SDK (platform 36).

```sh
cd android
./gradlew testDebugUnitTest   # the shared engine timelines
./gradlew assembleDebug       # app/build/outputs/apk/debug/app-debug.apk
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

For Google Play's internal track, `scripts/bundle-release.sh` builds a signed bundle
(`app/build/outputs/bundle/release/app-release.aab`). The upload key is at
`~/.android/keystores/wodrounds-upload.jks` on the owner's Mac, outside the repo, with its
password in the macOS keychain (service `wodrounds-android-upload`). Play App Signing holds the
app signing key, so a lost upload key can be reset in Play Console. Uploads go through the Play
Developer API with the keyless `play-publisher` service account, as Wean's do.

## Changing the engine

The Swift engine is the reference. After an intended change to it, or a new case in
`test-fixtures/engine-timelines.json`, run `scripts/engine-fixtures/generate.sh` to write the
expectations from the Swift engine, then make the Kotlin port pass `./gradlew testDebugUnitTest`.

There's no Gradle job in CI: the trial stays out of the checks `main` needs. The Swift side of
the shared timelines runs in the existing "Unit tests (WODTimerEngine)" job.
