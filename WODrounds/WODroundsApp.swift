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
        // Don't report under XCTest/XCUITest — it only pollutes the project with
        // test-harness noise (e.g. false "App Hang" events from the simulator).
        let env = ProcessInfo.processInfo.environment
        if env["XCTestConfigurationFilePath"] != nil || env["XCTestSessionIdentifier"] != nil {
            return
        }

        let dsn = env["SENTRY_DSN"]
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
            // Tag non-release builds so simulator/debug events don't masquerade as
            // production. Only real App Store / TestFlight builds report "production".
            #if targetEnvironment(simulator)
            options.environment = "simulator"
            #elseif DEBUG
            options.environment = "debug"
            #else
            options.environment = "production"
            #endif
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
        // Fits the taller Intervals idle layout (3 steppers); EMOM centres within
        // it. contentMinSize stops the user shrinking it small enough to clip.
        .defaultSize(width: 360, height: 740)
        .windowResizability(.contentMinSize)
        #endif
    }
}
