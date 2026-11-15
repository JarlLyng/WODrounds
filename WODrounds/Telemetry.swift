//
//  Telemetry.swift
//  WODrounds
//
//  Anonymous crash reports, crash-free sessions and two feature counts, sent to
//  Sentry from iOS only (#225, #226). Anonymous is a recipe, not Sentry's
//  default: out of the box sentry-cocoa sends a random installation ID as the
//  user, as every session's `did` and on every metric, plus a hash of the vendor
//  ID on every event. Everything here exists to make sure no ID leaves the device.
//

#if os(iOS)
import Foundation
import Sentry

enum Telemetry {
    /// The one user every install reports as.
    static let anonymousUser = "anonymous"

    /// The only attributes a metric may carry: the SDK's coarse facts (version,
    /// OS, device model) plus ours. Anything else, `user.id` included, is dropped.
    static let allowedMetricAttributes: Set<String> = [
        "sentry.sdk.name", "sentry.sdk.version", "sentry.environment", "sentry.release",
        "os.name", "os.version", "device.brand", "device.model", "device.family",
        "mode",
    ]

    /// Starts Sentry if the build has a DSN. Not under XCTest/XCUITest, where it
    /// only pollutes the project with test-harness noise (e.g. false "App Hang"
    /// events from the simulator).
    static func start() {
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

        let options = Options()
        options.dsn = dsnTrimmed
        options.environment = environment
        #if DEBUG
        options.debug = true
        options.tracesSampleRate = 1.0
        #else
        // No performance tracing in production: crash reports, crash-free
        // sessions, MetricKit and the feature counts are what the policy names.
        options.tracesSampleRate = 0.0
        #endif
        options.sendDefaultPii = false
        // Nothing that watches: no screenshot of the timer (it would capture the
        // user's workout) and no view hierarchy.
        options.attachScreenshot = false
        options.attachViewHierarchy = false
        options.enableAutoSessionTracking = true
        options.enableMetricKit = true
        options.beforeSend = { event in
            anonymize(event)
        }
        options.beforeSendMetric = { metric in
            anonymize(metric)
        }

        // Sessions can't be given a user: sentry-cocoa sets every session's `did`
        // from the INSTALLATION file in its cache directory, and creates that file
        // with a random UUID when it's missing. Writing the shared user into the
        // file before the SDK starts makes every install report the same `did`.
        // Checked against the outgoing session envelope with sentry-cocoa 9.32.0;
        // check again after every SDK upgrade (docs/SENTRY.md).
        pinInstallationID(cacheDirectoryPath: options.cacheDirectoryPath)

        SentrySDK.start(options: options)
        // Before any event or metric, so nothing falls back to an installation ID.
        SentrySDK.setUser(User(userId: anonymousUser))

        #if DEBUG
        print("[Sentry] Initialised with DSN: \(dsnTrimmed.prefix(30))…")
        SentrySDK.capture(message: "WODrounds iOS – Sentry test (Debug build)")
        #endif
    }

    // MARK: - Feature counts

    /// A workout's first second, after the count-in.
    static func workoutStarted(_ mode: TimerUIMode) {
        count("workout.started", mode: mode)
    }

    /// A workout that reached its Done screen (For Time: Stop or the cap).
    static func workoutFinished(_ mode: TimerUIMode) {
        count("workout.finished", mode: mode)
    }

    private static func count(_ key: String, mode: TimerUIMode) {
        guard SentrySDK.isEnabled else { return }
        SentrySDK.metrics.count(key, value: 1, options: SentryMetricOptions(attributes: ["mode": modeAttribute(mode)]))
    }

    /// Fixed values only, never anything the user typed or set.
    static func modeAttribute(_ mode: TimerUIMode) -> String {
        switch mode {
        case .emom: "emom"
        case .intervals: "intervals"
        case .forTime: "fortime"
        }
    }

    // MARK: - Anonymizing

    /// `production` only for App Store builds, so simulator, debug and TestFlight
    /// runs aren't read as real crashes. TestFlight installs carry a sandbox receipt.
    static var environment: String {
        #if targetEnvironment(simulator)
        return "simulator"
        #elseif DEBUG
        return "debug"
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" ? "testflight" : "production"
        #endif
    }

    /// Covers errors, crashes, MetricKit diagnostics and (in sentry-cocoa 9)
    /// transactions: one shared user, and no device or vendor-ID hash.
    static func anonymize(_ event: Event) -> Event {
        event.user = User(userId: anonymousUser)
        if var context = event.context {
            context["app"]?.removeValue(forKey: "device_app_hash")
            context["device"]?.removeValue(forKey: "id")
            event.context = context
        }
        return event
    }

    static func anonymize(_ metric: SentryMetric) -> SentryMetric {
        var metric = metric
        metric.attributes = metric.attributes.filter { allowedMetricAttributes.contains($0.key) }
        return metric
    }

    static func pinInstallationID(cacheDirectoryPath: String) {
        let url = URL(fileURLWithPath: cacheDirectoryPath).appendingPathComponent("INSTALLATION")
        let pinned = Data(anonymousUser.utf8)
        guard (try? Data(contentsOf: url)) != pinned else { return }
        try? pinned.write(to: url, options: .atomic)
    }
}
#endif
