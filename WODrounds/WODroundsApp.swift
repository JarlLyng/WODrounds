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
        WODTimerSync.activate()
        Self.initSentry()
        #endif
    }

    #if os(iOS)
    private static func initSentry() {
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
            options.tracesSampleRate = 1.0
            #else
            options.tracesSampleRate = 0.2
            #endif
            options.enableAutoSessionTracking = true
            options.attachScreenshot = true
            options.enableMetricKit = true
        }
        #if DEBUG
        print("[Sentry] Initialised with DSN: \(dsnTrimmed.prefix(30))…")
        SentrySDK.capture(message: "WODrounds iOS – Sentry test (Debug build)")
        #endif
    }
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        // Tall enough for the full idle layout (mode switch + steppers + Start)
        // so nothing is clipped at the default size. See issue #47.
        .defaultSize(width: 340, height: 720)
        #endif
    }
}
