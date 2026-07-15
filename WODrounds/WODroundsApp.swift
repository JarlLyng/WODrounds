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
            // Crash reports and release health only. No performance tracing in
            // production: it sends transaction/timing data for a share of every
            // session, which a minimal timer doesn't need and which goes beyond
            // the "crash reports" the privacy policy describes.
            options.tracesSampleRate = 0.0
            #endif
            options.enableAutoSessionTracking = true
            // No crash screenshots. A crash on the timer screen would capture the
            // user's workout (rounds, times), and the privacy policy states we do
            // not send workout programming. Keep that promise true in code.
            options.attachScreenshot = false
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
