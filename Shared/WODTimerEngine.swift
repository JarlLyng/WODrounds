//
//  WODTimerEngine.swift
//  Shared (WODrounds + WODrounds Watch)
//
//  EMOM + Intervals timer engine. Platform-agnostic, Date-based, no UI/sound/haptics.
//

import Foundation

/// Engine state.
enum WODTimerEngineState: Equatable {
    case idle
    case running
    case paused
    case finished
}

/// Current phase within a round (Intervals); EMOM treats all as work.
enum WODTimerPhase: Equatable {
    case work
    case rest
}

/// Snapshot of timer state at a given moment. All values derived from Date.
struct WODTimerEngineSnapshot {
    let state: WODTimerEngineState
    /// Total seconds remaining in the workout (0 when finished or idle).
    let remainingTime: TimeInterval
    /// Current round, 1-based.
    let currentRound: Int
    /// Seconds elapsed within the current minute (EMOM) or N/A (Intervals).
    let secondsIntoCurrentMinute: Int
    /// Work or rest (Intervals); EMOM always .work.
    let currentPhase: WODTimerPhase
    /// Seconds remaining in the current work or rest phase.
    let remainingTimeInPhase: TimeInterval
}

/// Timer mode: EMOM (rounds, secondsPerRound) or Intervals (work/rest/rounds).
enum WODTimerMode: Equatable {
    case emom(rounds: Int, secondsPerRound: Int)
    case intervals(workSeconds: Int, restSeconds: Int, rounds: Int)
}

/// EMOM + Intervals timer engine. Date-based, deterministic.
struct WODTimerEngine {

    var state: WODTimerEngineState = .idle
    var mode: WODTimerMode = .emom(rounds: 1, secondsPerRound: 60)

    private var startDate: Date?
    private var accumulatedPauseDuration: TimeInterval = 0
    private var pausedAt: Date?

    private let secondsPerMinute: TimeInterval = 60

    // MARK: - EMOM

    init(emomRounds: Int = 1, secondsPerRound: Int = 60) {
        self.mode = .emom(rounds: max(1, emomRounds), secondsPerRound: max(30, secondsPerRound))
    }

    /// Total minutes (historical compatibility wrapper, renamed correctly internally) or 0.
    var totalDurationMinutes: Int {
        if case .emom(let r, _) = mode { return r }
        return 0
    }

    // MARK: - Intervals

    init(workSeconds: Int, restSeconds: Int, rounds: Int) {
        self.mode = .intervals(
            workSeconds: max(1, workSeconds),
            restSeconds: max(0, restSeconds),
            rounds: max(1, rounds)
        )
    }

    var workSeconds: Int {
        if case .intervals(let w, _, _) = mode { return w }
        return 0
    }

    var restSeconds: Int {
        if case .intervals(_, let r, _) = mode { return r }
        return 0
    }

    var rounds: Int {
        if case .intervals(_, _, let r) = mode { return r }
        return totalDurationMinutes
    }

    /// Total duration in seconds (for display). EMOM: rounds * secondsPerRound. Intervals: rounds * work + (rounds - 1) * rest.
    var totalDurationSeconds: TimeInterval {
        switch mode {
        case .emom(let r, let spr):
            return TimeInterval(r) * TimeInterval(spr)
        case .intervals(let w, let r, let n):
            return TimeInterval(n) * TimeInterval(w) + TimeInterval(n - 1) * TimeInterval(r)
        }
    }

    // MARK: - Actions

    mutating func start(now: Date) {
        guard totalDurationSeconds > 0 else { return }
        startDate = now
        accumulatedPauseDuration = 0
        pausedAt = nil
        state = .running
    }

    mutating func pause(now: Date) {
        guard state == .running, let start = startDate else { return }
        let elapsed = now.timeIntervalSince(start) - accumulatedPauseDuration
        if elapsed >= totalDurationSeconds {
            state = .finished
            return
        }
        pausedAt = now
        state = .paused
    }

    mutating func resume(now: Date) {
        guard state == .paused, let pauseStart = pausedAt else { return }
        accumulatedPauseDuration += max(0, now.timeIntervalSince(pauseStart))
        pausedAt = nil
        state = .running
    }

    mutating func reset() {
        state = .idle
        startDate = nil
        accumulatedPauseDuration = 0
        pausedAt = nil
    }

    /// End date for a HealthKit workout so duration = active time (excludes pause). Nil if workout never started.
    func effectiveWorkoutEndDate(now: Date) -> Date? {
        guard startDate != nil else { return nil }
        return Date(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate - accumulatedPauseDuration)
    }

    // MARK: - Query (Date-based)

    func snapshot(now: Date) -> WODTimerEngineSnapshot {
        switch state {
        case .idle:
            return makeSnapshot(state: .idle, remainingTime: 0, currentRound: 0, secondsIntoCurrentMinute: 0, phase: .work, remainingTimeInPhase: 0)
        case .running:
            let elapsed = elapsedSeconds(now: now)
            let total = totalDurationSeconds
            if elapsed >= total {
                return makeFinishedSnapshot()
            }
            return snapshotForActive(elapsed: elapsed)
        case .paused:
            let elapsed = elapsedSeconds(now: now)
            if elapsed >= totalDurationSeconds {
                return makeFinishedSnapshot()
            }
            return snapshotForPaused(elapsed: elapsed)
        case .finished:
            return makeFinishedSnapshot()
        }
    }

    mutating func tick(now: Date) {
        guard state == .running else { return }
        let elapsed = elapsedSeconds(now: now)
        if elapsed >= totalDurationSeconds {
            state = .finished
            pausedAt = nil
        }
    }

    // MARK: - Private

    private func elapsedSeconds(now: Date) -> TimeInterval {
        guard let start = startDate else { return 0 }
        let raw: TimeInterval
        switch state {
        case .running:
            raw = now.timeIntervalSince(start) - accumulatedPauseDuration
        case .paused:
            raw = (pausedAt?.timeIntervalSince(start) ?? now.timeIntervalSince(start)) - accumulatedPauseDuration
        default:
            raw = 0
        }
        return max(0, raw)
    }

    private func makeSnapshot(state: WODTimerEngineState, remainingTime: TimeInterval, currentRound: Int, secondsIntoCurrentMinute: Int, phase: WODTimerPhase, remainingTimeInPhase: TimeInterval) -> WODTimerEngineSnapshot {
        WODTimerEngineSnapshot(
            state: state,
            remainingTime: remainingTime,
            currentRound: currentRound,
            secondsIntoCurrentMinute: secondsIntoCurrentMinute,
            currentPhase: phase,
            remainingTimeInPhase: remainingTimeInPhase
        )
    }

    private func makeFinishedSnapshot() -> WODTimerEngineSnapshot {
        let totalRounds: Int
        switch mode {
        case .emom(let r, _): totalRounds = r
        case .intervals(_, _, let r): totalRounds = r
        }
        return makeSnapshot(state: .finished, remainingTime: 0, currentRound: totalRounds, secondsIntoCurrentMinute: 0, phase: .work, remainingTimeInPhase: 0)
    }

    private func snapshotForActive(elapsed: TimeInterval) -> WODTimerEngineSnapshot {
        switch mode {
        case .emom(let rounds, let spr):
            let total = TimeInterval(rounds) * TimeInterval(spr)
            let remaining = max(0, total - elapsed)
            let round = min(roundFromEMOM(elapsed: elapsed), rounds)
            let intoRound = elapsed >= total ? 0 : secondsIntoMinuteFrom(elapsed: elapsed)
            let remainingTimeInPhase = TimeInterval(spr - intoRound)
            return makeSnapshot(state: .running, remainingTime: remaining, currentRound: round, secondsIntoCurrentMinute: intoRound, phase: .work, remainingTimeInPhase: remainingTimeInPhase)
        case .intervals(let w, let r, let n):
            let total = totalDurationSeconds
            let remaining = max(0, total - elapsed)
            let (round, phase, remainingTimeInPhase) = intervalsPhase(elapsed: elapsed, work: w, rest: r, rounds: n)
            return makeSnapshot(state: .running, remainingTime: remaining, currentRound: round, secondsIntoCurrentMinute: 0, phase: phase, remainingTimeInPhase: remainingTimeInPhase)
        }
    }

    private func snapshotForPaused(elapsed: TimeInterval) -> WODTimerEngineSnapshot {
        switch mode {
        case .emom(let rounds, let spr):
            let total = TimeInterval(rounds) * TimeInterval(spr)
            let remaining = max(0, total - elapsed)
            let round = roundFromEMOM(elapsed: elapsed)
            let intoRound = secondsIntoMinuteFrom(elapsed: elapsed)
            let remainingTimeInPhase = TimeInterval(spr - intoRound)
            return makeSnapshot(state: .paused, remainingTime: remaining, currentRound: round, secondsIntoCurrentMinute: intoRound, phase: .work, remainingTimeInPhase: remainingTimeInPhase)
        case .intervals(let w, let r, let n):
            let total = totalDurationSeconds
            let remaining = max(0, total - elapsed)
            let (round, phase, remainingTimeInPhase) = intervalsPhase(elapsed: elapsed, work: w, rest: r, rounds: n)
            return makeSnapshot(state: .paused, remainingTime: remaining, currentRound: round, secondsIntoCurrentMinute: 0, phase: phase, remainingTimeInPhase: remainingTimeInPhase)
        }
    }

    private func roundFromEMOM(elapsed: TimeInterval) -> Int {
        if case .emom(let rounds, let spr) = mode {
            let current = Int(elapsed / TimeInterval(spr))
            return min(current + 1, rounds)
        }
        return 1
    }

    private func secondsIntoMinuteFrom(elapsed: TimeInterval) -> Int {
        if case .emom(_, let spr) = mode {
            return Int(elapsed.truncatingRemainder(dividingBy: TimeInterval(spr)))
        }
        return Int(elapsed.truncatingRemainder(dividingBy: 60))
    }

    /// Returns (currentRound 1-based, phase, remainingSecondsInPhase).
    private func intervalsPhase(elapsed: TimeInterval, work w: Int, rest r: Int, rounds n: Int) -> (Int, WODTimerPhase, TimeInterval) {
        let cycle = TimeInterval(w + r)
        let total = totalDurationSeconds
        guard elapsed < total, n > 0 else {
            return (n, .work, 0)
        }
        if n == 1 {
            let rem = TimeInterval(w) - elapsed
            return (1, .work, max(0, rem))
        }
        let roundIndex = min(Int(elapsed / cycle), n - 1)
        let segmentStart = TimeInterval(roundIndex) * cycle
        let workEnd = segmentStart + TimeInterval(w)
        if elapsed < workEnd {
            return (roundIndex + 1, .work, max(0, workEnd - elapsed))
        }
        if roundIndex == n - 1 {
            return (n, .work, 0)
        }
        let restEnd = segmentStart + cycle
        return (roundIndex + 1, .rest, max(0, restEnd - elapsed))
    }

    // MARK: - Sync (iPhone → Watch via WatchConnectivity)

    /// Payload sent to Watch via WCSession.updateApplicationContext so Watch can show the same timer.
    struct SyncPayload: Codable {
        let state: String       // "idle" | "running" | "paused" | "finished"
        let startDate: Date?
        let accumulatedPauseDuration: TimeInterval
        let pausedAt: Date?
        let mode: String        // "emom" | "intervals"
        let totalMinutes: Int
        let emomSecondsPerRound: Int?
        let workSeconds: Int?
        let restSeconds: Int?
        let rounds: Int?
        let lastUpdated: Date
    }

    func syncPayload(now: Date) -> SyncPayload {
        let (modeStr, totalMin, spr, work, rest, rnds): (String, Int, Int?, Int?, Int?, Int?) = {
            switch mode {
            case .emom(let m, let s): return ("emom", m, s, nil, nil, nil)
            case .intervals(let w, let r, let n): return ("intervals", 0, nil, w, r, n)
            }
        }()
        return SyncPayload(
            state: state == .idle ? "idle" : state == .running ? "running" : state == .paused ? "paused" : "finished",
            startDate: startDate,
            accumulatedPauseDuration: accumulatedPauseDuration,
            pausedAt: pausedAt,
            mode: modeStr,
            totalMinutes: totalMin,
            emomSecondsPerRound: spr,
            workSeconds: work,
            restSeconds: rest,
            rounds: rnds,
            lastUpdated: now
        )
    }
}
