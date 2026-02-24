//
//  WODTimerSync.swift
//  WODrounds Watch App
//
//  Reads timer state from App Group (written by iPhone) so Watch can show the same workout.
//

import Foundation

/// Same shape as WODTimerEngine.SyncPayload on iOS – decode from shared UserDefaults.
struct WODTimerSyncPayload: Codable {
    let state: String
    let startDate: Date?
    let accumulatedPauseDuration: TimeInterval
    let pausedAt: Date?
    let mode: String
    let totalMinutes: Int
    let emomSecondsPerRound: Int?
    let workSeconds: Int?
    let restSeconds: Int?
    let rounds: Int?
    let lastUpdated: Date
}

enum WODTimerSync {
    static let appGroupID = "group.com.iamjarl.WODrounds"
    static let key = "wodrounds.sync.payload"

    static var shared: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func read() -> WODTimerSyncPayload? {
        guard let defaults = shared,
              let data = defaults.data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WODTimerSyncPayload.self, from: data)
    }

    /// Compute elapsed seconds from payload and current date (same logic as engine).
    private static func elapsedSeconds(payload: WODTimerSyncPayload, now: Date) -> TimeInterval {
        guard let start = payload.startDate else { return 0 }
        let raw: TimeInterval
        switch payload.state {
        case "running":
            raw = now.timeIntervalSince(start) - payload.accumulatedPauseDuration
        case "paused":
            let pauseEnd = payload.pausedAt ?? now
            raw = pauseEnd.timeIntervalSince(start) - payload.accumulatedPauseDuration
        default:
            raw = 0
        }
        return max(0, raw)
    }

    private static func totalDurationSeconds(payload: WODTimerSyncPayload) -> TimeInterval {
        switch payload.mode {
        case "emom":
            let spr = payload.emomSecondsPerRound ?? 60
            return TimeInterval(payload.totalMinutes) * TimeInterval(spr)
        case "intervals":
            guard let w = payload.workSeconds, let r = payload.restSeconds, let n = payload.rounds, n > 0 else { return 0 }
            return TimeInterval(n) * TimeInterval(w) + TimeInterval(n - 1) * TimeInterval(r)
        default:
            return 0
        }
    }

    private static func roundFromEMOM(elapsed: TimeInterval, totalMinutes: Int, secondsPerRound: Int) -> Int {
        let current = Int(elapsed / TimeInterval(secondsPerRound))
        return min(current + 1, totalMinutes)
    }

    /// Result to drive Watch UI when synced from iPhone.
    struct SyncedSnapshot {
        let state: WODTimerEngineState
        let remainingTime: TimeInterval
        let currentRound: Int
        let totalRounds: Int
        let remainingTimeInPhase: TimeInterval
    }

    static func snapshot(from payload: WODTimerSyncPayload, now: Date) -> SyncedSnapshot? {
        switch payload.state {
        case "idle":
            let total = payload.mode == "emom" ? payload.totalMinutes : (payload.rounds ?? 0)
            return SyncedSnapshot(state: .idle, remainingTime: 0, currentRound: 0, totalRounds: max(1, total), remainingTimeInPhase: 0)
        case "finished":
            let total = payload.mode == "emom" ? payload.totalMinutes : (payload.rounds ?? 0)
            return SyncedSnapshot(state: .finished, remainingTime: 0, currentRound: max(1, total), totalRounds: max(1, total), remainingTimeInPhase: 0)
        case "running", "paused":
            guard payload.startDate != nil else { return nil }
            let totalSec = totalDurationSeconds(payload: payload)
            let elapsed = elapsedSeconds(payload: payload, now: now)
            let remaining = max(0, totalSec - elapsed)
            let totalRounds: Int = payload.mode == "emom" ? payload.totalMinutes : (payload.rounds ?? 1)
            let round: Int
            let remainingTimeInPhase: TimeInterval
            if payload.mode == "emom" {
                let spr = payload.emomSecondsPerRound ?? 60
                round = min(roundFromEMOM(elapsed: elapsed, totalMinutes: payload.totalMinutes, secondsPerRound: spr), payload.totalMinutes)
                let intoRound = Int(elapsed.truncatingRemainder(dividingBy: TimeInterval(spr)))
                remainingTimeInPhase = TimeInterval(spr - intoRound)
            } else {
                guard let w = payload.workSeconds, let r = payload.restSeconds, let n = payload.rounds, n > 0 else { return nil }
                let cycle = TimeInterval(w + r)
                round = totalSec <= 0 ? n : min(Int(elapsed / cycle), n - 1) + 1
                remainingTimeInPhase = 0
            }
            let state: WODTimerEngineState = payload.state == "running" ? .running : .paused
            return SyncedSnapshot(state: state, remainingTime: remaining, currentRound: round, totalRounds: totalRounds, remainingTimeInPhase: remainingTimeInPhase)
        default:
            return nil
        }
    }
}
