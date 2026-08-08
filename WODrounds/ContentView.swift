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
    return .emom
}

/// Companion to `initialTimerMode()`: the engine has to start in the same mode, or a
/// screenshot launched with `-screen intervals` shows the Intervals UI while the engine
/// is still the default EMOM (wrong round count, wrong total). Defaults match the
/// per-platform @State values.
func initialEngine() -> WODTimerEngine {
    switch initialTimerMode() {
    case .emom: return WODTimerEngine(emomRounds: 10, secondsPerRound: 60)
    case .intervals: return WODTimerEngine(workSeconds: 30, restSeconds: 15, rounds: 8)
    case .forTime: return WODTimerEngine(forTimeCapSeconds: nil)
    }
}
#endif
