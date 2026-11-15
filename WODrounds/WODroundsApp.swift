//
//  WODroundsApp.swift
//  WODrounds
//
//  Created by Jarl Lyng on 15/02/2026.
//

import SwiftUI

@main
struct WODroundsApp: App {
    init() {
        #if os(iOS)
        WODTimerSync.activate()
        Telemetry.start()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        // Fits the taller Intervals idle layout (3 steppers); EMOM centres within
        // it. contentMinSize stops the user shrinking it small enough to clip.
        .defaultSize(width: 360, height: 740)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .help) {
                Button("Send feedback") {
                    if let url = feedbackMailURL() { NSWorkspace.shared.open(url) }
                }
            }
        }
        #endif
    }
}
