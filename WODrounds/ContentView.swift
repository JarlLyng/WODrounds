//
//  ContentView.swift
//  WODrounds
//
//  Shared types and ranges used by all platform ContentViews.
//  Platform-specific ContentView implementations are in:
//    iOSContentView.swift, tvOSContentView.swift, macOSContentView.swift
//

import SwiftUI

// MARK: - Shared (iOS + macOS + tvOS)

#if os(iOS) || os(macOS) || os(tvOS)
let roundsRange = 1 ... 120
let emomLengthRange = 30 ... 570
let intervalsWorkRange = 5 ... 300
let intervalsRestRange = 0 ... 180
let intervalsRoundsRange = 1 ... 60
/// For Time cap stepper range. 0 is the "No cap" sentinel; real caps run
/// 0:30–60:00 in 30s steps, so a single stepper covers both (0 ↔ 0:30 ↔ 1:00 …).
let forTimeCapRange = 0 ... 3600
let forTimeCapStep = 30

/// Stepper display for the For Time cap: the 0 sentinel reads "No cap".
func forTimeCapDisplay(_ seconds: Int) -> String {
    seconds == 0 ? String(localized: "No cap") : sharedFormatEmomLength(seconds)
}

/// Engine cap value from the stepper value (0 sentinel → nil = uncapped).
func forTimeEngineCap(_ seconds: Int) -> Int? {
    seconds == 0 ? nil : seconds
}

enum TimerUIMode: String, CaseIterable {
    case emom = "EMOM"
    case intervals = "Intervals"
    case forTime = "For Time"
}

/// Screenshot support: `-screen emom|intervals|fortime` launches straight into that mode,
/// so App Store captures are reproducible instead of depending on a synthetic tap landing
/// on the right segment. DEBUG-only, so it cannot affect a shipped build. The portfolio
/// screenshot recipe asks for exactly this hook.
func initialTimerMode() -> TimerUIMode {
    #if DEBUG
    let args = ProcessInfo.processInfo.arguments
    if let i = args.firstIndex(of: "-screen"), i + 1 < args.count {
        switch args[i + 1] {
        case "emom": return .emom
        case "intervals": return .intervals
        case "fortime": return .forTime
        default: break
        }
    }
    #endif
    // Reopen in the mode last used. The Watch has always done this
    // (`watchTimerMode`); the phone, Mac and TV forgot every launch. The
    // screenshot argument above still wins, so captures stay reproducible.
    if let raw = UserDefaults.standard.string(forKey: lastTimerModeKey),
       let mode = TimerUIMode(rawValue: raw) {
        return mode
    }
    return .emom
}

/// Key for the last mode used, shared by the three non-Watch views.
let lastTimerModeKey = "lastTimerMode"

/// Companion to `initialTimerMode()`: the engine has to start in the same mode, or a
/// screenshot launched with `-screen intervals` shows the Intervals UI while the engine
/// is still the default EMOM (wrong round count, wrong total).
///
/// The numbers here are only a first guess. Now that the setup values persist, they can
/// differ from what the steppers will show, so each view calls `syncEngineIfIdle` on
/// appear to rebuild the engine from the restored values. Without that, the screen would
/// show your numbers while Start ran these.
func initialEngine() -> WODTimerEngine {
    #if DEBUG
    if let engine = SiteCapture.engine(mode: initialTimerMode()) { return engine }
    #endif
    switch initialTimerMode() {
    case .emom: return WODTimerEngine(emomRounds: 10, secondsPerRound: 60)
    case .intervals: return WODTimerEngine(workSeconds: 30, restSeconds: 15, rounds: 8)
    case .forTime: return WODTimerEngine(forTimeCapSeconds: nil)
    }
}

#if DEBUG
/// Site and App Store captures (#182). `-siteElapsed N` opens the app N seconds into a
/// workout, past the count-in, so a capture shows a real moment, such as round 4 of 12
/// or seven seconds of rest, without timing it live. `-siteFinished` then ends it, for
/// the Done screen. The workout uses the stored setup values, which a launch argument can
/// set too (`-intervalsWorkSeconds 20`). DEBUG only, like `-screen`.
enum SiteCapture {
    static var elapsed: TimeInterval? {
        UserDefaults.standard.object(forKey: "siteElapsed") == nil
            ? nil : UserDefaults.standard.double(forKey: "siteElapsed")
    }
    static var isActive: Bool { elapsed != nil }

    /// `-siteCountIn N` opens the setup screen inside the 10-second count-in, N seconds
    /// before it ends, so the count-in can be captured without tapping Start.
    static var countInEnd: Date? {
        UserDefaults.standard.object(forKey: "siteCountIn") == nil
            ? nil : Date().addingTimeInterval(UserDefaults.standard.double(forKey: "siteCountIn"))
    }

    static func engine(mode: TimerUIMode) -> WODTimerEngine? {
        guard let elapsed else { return nil }
        let d = UserDefaults.standard
        func value(_ key: String, _ fallback: Int) -> Int {
            d.object(forKey: key) == nil ? fallback : d.integer(forKey: key)
        }
        var e: WODTimerEngine
        switch mode {
        case .emom:
            e = WODTimerEngine(emomRounds: value("emomRounds", 10),
                               secondsPerRound: value("emomRoundLengthSeconds", 60))
        case .intervals:
            e = WODTimerEngine(workSeconds: value("intervalsWorkSeconds", 30),
                               restSeconds: value("intervalsRestSeconds", 15),
                               rounds: value("intervalsRounds", 8))
        case .forTime:
            e = WODTimerEngine(forTimeCapSeconds: forTimeEngineCap(value("forTimeCapSeconds", 0)))
        }
        let now = Date()
        e.start(now: now.addingTimeInterval(-elapsed))
        if d.bool(forKey: "siteFinished") { e.finish(now: now) }
        return e
    }
}
#endif

/// When to ask for an App Store review, shared by every platform so the cadence
/// is decided in one place.
///
/// Apple shows at most three prompts per 365 days and silently drops the rest, so
/// there is no value in asking often; the thresholds just need to land on people who
/// have actually used the app. The first ask is deliberately early (a few finished
/// workouts is roughly a first week of training) because a small user base cannot
/// afford to wait for power users that may never arrive.
///
/// iOS and macOS only: `requestReview` is unavailable on tvOS, and watchOS has no
/// Done-screen moment worth interrupting, so Apple TV workouts are never asked.
enum ReviewPrompt {
    /// Completed-workout counts at which to ask. Each is asked at most once.
    static let thresholds = [3, 10, 30]

    /// Delay before the system dialog, so the Done screen is on screen first.
    static let delay: TimeInterval = 1.5

    /// The threshold to ask at now, or nil if there is nothing to ask for.
    ///
    /// Uses `>=` plus the highest threshold already asked, rather than an exact
    /// match on the count. An exact match silently loses the ask if the counter ever
    /// skips a value (a double-counted finish, or a restore onto a device that was
    /// already past the number), and skipping is exactly the failure you never notice.
    static func thresholdToAsk(completed: Int, lastAsked: Int) -> Int? {
        thresholds.first { completed >= $0 && lastAsked < $0 }
    }
}
#endif
