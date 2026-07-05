//
//  WODTimerSync.swift
//  WODrounds Watch App
//
//  Payload struct and snapshot computation for iPhone-synced timer state.
//  Transport is WatchConnectivity (see WatchSessionManager.swift).
//

import Foundation

/// Same shape as WODTimerEngine.SyncPayload on iOS.
struct WODTimerSyncPayload: Codable {
    let state: String
    let startDate: Date?
    let accumulatedPauseDuration: TimeInterval
    let pausedAt: Date?
    let mode: String        // "emom" | "intervals" | "forTime"
    let totalMinutes: Int
    let emomSecondsPerRound: Int?
    let workSeconds: Int?
    let restSeconds: Int?
    let rounds: Int?
    /// For Time cap; nil when uncapped or in another mode. Optional so payloads
    /// from older iPhone app versions still decode.
    let capSeconds: Int?
    /// When the iPhone froze the workout via finish(now:); freezes elapsed here too.
    let finishedAt: Date?
    let lastUpdated: Date
}

enum WODTimerSync {

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
        case "forTime":
            return TimeInterval(payload.capSeconds ?? 0) // 0 = uncapped (no total)
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
        /// Seconds elapsed since start, excluding pauses; frozen once finished.
        /// The headline value for a synced For Time workout (count-up display).
        let elapsedTime: TimeInterval
        let currentRound: Int
        let totalRounds: Int
        let remainingTimeInPhase: TimeInterval
    }

    static func snapshot(from payload: WODTimerSyncPayload, now: Date) -> SyncedSnapshot? {
        switch payload.state {
        case "idle":
            let total = payload.mode == "emom" ? payload.totalMinutes : (payload.rounds ?? 0)
            return SyncedSnapshot(state: .idle, remainingTime: 0, elapsedTime: 0, currentRound: 0, totalRounds: max(1, total), remainingTimeInPhase: 0)
        case "finished":
            let total = payload.mode == "emom" ? payload.totalMinutes : (payload.rounds ?? 0)
            // Frozen elapsed: finishedAt (explicit Stop) beats the mode total, so a
            // stopped For Time shows the real final time instead of growing/zero.
            let frozenElapsed: TimeInterval
            if let finishedAt = payload.finishedAt, let start = payload.startDate {
                frozenElapsed = max(0, finishedAt.timeIntervalSince(start) - payload.accumulatedPauseDuration)
            } else {
                frozenElapsed = totalDurationSeconds(payload: payload)
            }
            return SyncedSnapshot(state: .finished, remainingTime: 0, elapsedTime: frozenElapsed, currentRound: max(1, total), totalRounds: max(1, total), remainingTimeInPhase: 0)
        case "running", "paused":
            guard payload.startDate != nil else { return nil }
            let totalSec = totalDurationSeconds(payload: payload)
            let elapsed = elapsedSeconds(payload: payload, now: now)
            let remaining = max(0, totalSec - elapsed)
            let state: WODTimerEngineState = payload.state == "running" ? .running : .paused
            if payload.mode == "forTime" {
                // Count-up; no rounds. Uncapped (cap nil → totalSec 0) never finishes
                // on its own — the iPhone drives the finished state.
                return SyncedSnapshot(state: state, remainingTime: remaining, elapsedTime: elapsed, currentRound: 1, totalRounds: 1, remainingTimeInPhase: remaining)
            }
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
            return SyncedSnapshot(state: state, remainingTime: remaining, elapsedTime: elapsed, currentRound: round, totalRounds: totalRounds, remainingTimeInPhase: remainingTimeInPhase)
        default:
            return nil
        }
    }
}
