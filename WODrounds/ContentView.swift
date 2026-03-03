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

enum TimerUIMode: String, CaseIterable {
    case emom = "EMOM"
    case intervals = "Intervals"
}
#endif
