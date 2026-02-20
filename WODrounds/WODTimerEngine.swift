//
//  WODTimerEngine.swift
//  WODrounds
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

/// Timer mode: EMOM (rounds = minutes) or Intervals (work/rest/rounds).
enum WODTimerMode: Equatable {
    case emom(totalMinutes: Int)
    case intervals(workSeconds: Int, restSeconds: Int, rounds: Int)
}

/// EMOM + Intervals timer engine. Date-based, deterministic.
struct WODTimerEngine {

    var state: WODTimerEngineState = .idle
    var mode: WODTimerMode = .emom(totalMinutes: 1)

    private var startDate: Date?
    private var accumulatedPauseDuration: TimeInterval = 0
    private var pausedAt: Date?

    private let secondsPerMinute: TimeInterval = 60

    // MARK: - EMOM

    init(totalDurationMinutes: Int = 1) {
        self.mode = .emom(totalMinutes: max(1, totalDurationMinutes))
    }

    /// Total minutes (EMOM) or 0 when Intervals.
    var totalDurationMinutes: Int {
        if case .emom(let m) = mode { return m }
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

    /// Total duration in seconds (for display). EMOM: minutes * 60. Intervals: rounds * work + (rounds - 1) * rest.
    var totalDurationSeconds: TimeInterval {
        switch mode {
        case .emom(let m):
            return TimeInterval(m) * secondsPerMinute
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
        case .emom(let m): totalRounds = m
        case .intervals(_, _, let r): totalRounds = r
        }
        return makeSnapshot(state: .finished, remainingTime: 0, currentRound: totalRounds, secondsIntoCurrentMinute: 0, phase: .work, remainingTimeInPhase: 0)
    }

    private func snapshotForActive(elapsed: TimeInterval) -> WODTimerEngineSnapshot {
        switch mode {
        case .emom(let totalMinutes):
            let total = TimeInterval(totalMinutes) * secondsPerMinute
            let remaining = max(0, total - elapsed)
            let round = min(roundFromEMOM(elapsed: elapsed), totalMinutes)
            let intoMinute = elapsed >= total ? 0 : secondsIntoMinuteFrom(elapsed: elapsed)
            let remainingTimeInPhase = TimeInterval(60 - intoMinute)
            return makeSnapshot(state: .running, remainingTime: remaining, currentRound: round, secondsIntoCurrentMinute: intoMinute, phase: .work, remainingTimeInPhase: remainingTimeInPhase)
        case .intervals(let w, let r, let n):
            let total = totalDurationSeconds
            let remaining = max(0, total - elapsed)
            let (round, phase, remainingTimeInPhase) = intervalsPhase(elapsed: elapsed, work: w, rest: r, rounds: n)
            return makeSnapshot(state: .running, remainingTime: remaining, currentRound: round, secondsIntoCurrentMinute: 0, phase: phase, remainingTimeInPhase: remainingTimeInPhase)
        }
    }

    private func snapshotForPaused(elapsed: TimeInterval) -> WODTimerEngineSnapshot {
        switch mode {
        case .emom(let totalMinutes):
            let total = TimeInterval(totalMinutes) * secondsPerMinute
            let remaining = max(0, total - elapsed)
            let round = roundFromEMOM(elapsed: elapsed)
            let intoMinute = secondsIntoMinuteFrom(elapsed: elapsed)
            let remainingTimeInPhase = TimeInterval(60 - intoMinute)
            return makeSnapshot(state: .paused, remainingTime: remaining, currentRound: round, secondsIntoCurrentMinute: intoMinute, phase: .work, remainingTimeInPhase: remainingTimeInPhase)
        case .intervals(let w, let r, let n):
            let total = totalDurationSeconds
            let remaining = max(0, total - elapsed)
            let (round, phase, remainingTimeInPhase) = intervalsPhase(elapsed: elapsed, work: w, rest: r, rounds: n)
            return makeSnapshot(state: .paused, remainingTime: remaining, currentRound: round, secondsIntoCurrentMinute: 0, phase: phase, remainingTimeInPhase: remainingTimeInPhase)
        }
    }

    private func roundFromEMOM(elapsed: TimeInterval) -> Int {
        let minute = Int(elapsed / secondsPerMinute)
        let totalMinutes: Int
        if case .emom(let m) = mode { totalMinutes = m } else { totalMinutes = 1 }
        return min(minute + 1, totalMinutes)
    }

    private func secondsIntoMinuteFrom(elapsed: TimeInterval) -> Int {
        Int(elapsed.truncatingRemainder(dividingBy: secondsPerMinute))
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
}
