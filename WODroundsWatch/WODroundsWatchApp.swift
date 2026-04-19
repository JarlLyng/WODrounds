//
//  WODroundsWatchApp.swift
//  WODrounds Watch App
//
//  Watch App entry; companion to iOS app for TestFlight.
//

import SwiftUI

@main
struct WODroundsWatchApp: App {
    init() {
        WatchSessionManager.shared.activate()
        WatchWorkoutSession.shared.requestAuthorizationIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}
