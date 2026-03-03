//
//  WatchSessionManager.swift
//  WODrounds Watch App
//
//  Receives timer state from iPhone via WatchConnectivity.
//

import Foundation
import WatchConnectivity

/// Receives application context from the paired iPhone and publishes
/// the decoded payload for SwiftUI observation.
final class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    @Published var receivedPayload: WODTimerSyncPayload?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error {
            print("[WatchSync] Activation failed: \(error.localizedDescription)")
        }
        // Pick up the latest context sent while the Watch app was not running.
        if activationState == .activated {
            decodeAndPublish(session.receivedApplicationContext)
        }
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext applicationContext: [String: Any]) {
        decodeAndPublish(applicationContext)
    }

    // MARK: - Private

    private func decodeAndPublish(_ context: [String: Any]) {
        guard let data = context["payload"] as? Data, !data.isEmpty else {
            DispatchQueue.main.async { self.receivedPayload = nil }
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let payload = try? decoder.decode(WODTimerSyncPayload.self, from: data) else {
            print("[WatchSync] Failed to decode payload from iPhone")
            DispatchQueue.main.async { self.receivedPayload = nil }
            return
        }
        DispatchQueue.main.async { self.receivedPayload = payload }
    }
}
