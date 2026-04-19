//
//  WODTimerSync.swift
//  WODrounds
//
//  Sends timer state to Watch via WatchConnectivity (iOS).
//  No-op on macOS and tvOS (WatchConnectivity not available).
//

import Foundation
#if os(iOS)
import WatchConnectivity
#endif

enum WODTimerSync {

    #if os(iOS)

    /// Activate WCSession once at app launch. Safe to call multiple times.
    static func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        if session.delegate == nil {
            session.delegate = PhoneSideSessionDelegate.shared
            session.activate()
        }
    }

    static func write(_ payload: WODTimerEngine.SyncPayload) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload) else { return }
        let message = ["payload": data]
        // Always update application context so the Watch has latest state when it opens.
        try? session.updateApplicationContext(message)
        // Also send via sendMessage for immediate delivery if Watch is reachable.
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { _ in
                // Silently ignore — applicationContext is the fallback.
            }
        }
    }

    static func clear() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        let message = ["payload": Data()]
        try? session.updateApplicationContext(message)
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { _ in }
        }
    }

    /// Minimal delegate required by WCSession on the phone side.
    private class PhoneSideSessionDelegate: NSObject, WCSessionDelegate {
        static let shared = PhoneSideSessionDelegate()
        func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
            if let error {
                print("[WatchSync] Phone activation failed: \(error.localizedDescription)")
            }
        }
        func sessionDidBecomeInactive(_ session: WCSession) {}
        func sessionDidDeactivate(_ session: WCSession) {
            // Re-activate for users who switch watches.
            session.activate()
        }
    }

    #else
    // macOS and tvOS: no-ops (WatchConnectivity not available).
    static func activate() {}
    static func write(_ payload: WODTimerEngine.SyncPayload) {}
    static func clear() {}
    #endif
}
