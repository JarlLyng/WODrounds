//
//  WODroundsApp.swift
//  WODrounds
//
//  Created by Jarl Lyng on 15/02/2026.
//

import SwiftUI
#if os(iOS)
import Sentry
#endif

@main
struct WODroundsApp: App {
    init() {
        #if os(iOS)
        let dsn = ProcessInfo.processInfo.environment["SENTRY_DSN"]
            ?? (Bundle.main.object(forInfoDictionaryKey: "SentryDSN") as? String)
        let dsnTrimmed = dsn?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !dsnTrimmed.isEmpty else {
            #if DEBUG
            print("[Sentry] No DSN: set SENTRY_DSN in Scheme → Run → Environment Variables, or in Sentry.xcconfig")
            #endif
            return
        }
        SentrySDK.start { options in
            options.dsn = dsnTrimmed
            #if DEBUG
            options.debug = true
            #endif
            options.tracesSampleRate = 0.2
        }
        #if DEBUG
        SentrySDK.capture(message: "WODrounds iOS – Sentry test (Debug build)")
        #endif
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 340, height: 560)
        #endif
    }
}
