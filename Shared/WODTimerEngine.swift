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
    /// Total seconds remaining in the workout (0 when finished or idle; 0 for uncapped For Time).
    let remainingTime: TimeInterval
    /// Seconds elapsed since start, excluding pauses. Frozen at the final time once finished.
    /// The headline value for For Time (count-up); informational for EMOM/Intervals.
    let elapsedTime: TimeInterval
    /// Current round, 1-based.
    let currentRound: Int
    /// Seconds elapsed within the current minute (EMOM) or N/A (Intervals).
    let secondsIntoCurrentMinute: Int
    /// Work or rest (Intervals); EMOM always .work.
    let currentPhase: WODTimerPhase
    /// Seconds remaining in the current work or rest phase.
    let remainingTimeInPhase: TimeInterval
}

/// Timer mode: EMOM (rounds, secondsPerRound), Intervals (work/rest/rounds),
/// or For Time (count-up; capSeconds nil = uncapped).
enum WODTimerMode: Equatable {
    case emom(rounds: Int, secondsPerRound: Int)
    case intervals(workSeconds: Int, restSeconds: Int, rounds: Int)
    case forTime(capSeconds: Int?)
}

/// EMOM + Intervals timer engine. Date-based, deterministic.
struct WODTimerEngine {

    var state: WODTimerEngineState = .idle
    var mode: WODTimerMode = .emom(rounds: 1, secondsPerRound: 60)

    private var startDate: Date?
    private var accumulatedPauseDuration: TimeInterval = 0
    private var pausedAt: Date?
    /// Set by finish(now:) so the final elapsed time is frozen (Done screen, HealthKit).
    private var finishedAt: Date?

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

    // MARK: - For Time

    /// Count-up mode. capSeconds nil = uncapped (runs until the user stops it);
    /// non-nil = auto-finishes when elapsed reaches the cap.
    init(forTimeCapSeconds: Int?) {
        self.mode = .forTime(capSeconds: forTimeCapSeconds.map { max(1, $0) })
    }

    /// Time cap in seconds for For Time (nil when uncapped or not in For Time mode).
    var forTimeCapSeconds: Int? {
        if case .forTime(let cap) = mode { return cap }
        return nil
    }

    /// True for For Time with no cap: the only mode with no fixed total, so every
    /// `elapsed >= totalDurationSeconds` auto-finish comparison must be skipped
    /// (totalDurationSeconds is 0 and would finish instantly).
    private var isUncappedForTime: Bool {
        if case .forTime(let cap) = mode { return cap == nil }
        return false
    }

    /// Total duration in seconds (for display). EMOM: rounds * secondsPerRound.
    /// Intervals: rounds * work + (rounds - 1) * rest. For Time: cap, or 0 when uncapped.
    var totalDurationSeconds: TimeInterval {
        switch mode {
        case .emom(let r, let spr):
            return TimeInterval(r) * TimeInterval(spr)
        case .intervals(let w, let r, let n):
            return TimeInterval(n) * TimeInterval(w) + TimeInterval(n - 1) * TimeInterval(r)
        case .forTime(let cap):
            return TimeInterval(cap ?? 0)
        }
    }

    // MARK: - Actions

    mutating func start(now: Date) {
        // Uncapped For Time deliberately has no total; every other mode needs one.
        guard totalDurationSeconds > 0 || isUncappedForTime else { return }
        startDate = now
        accumulatedPauseDuration = 0
        pausedAt = nil
        finishedAt = nil
        state = .running
    }

    mutating func pause(now: Date) {
        guard state == .running, let start = startDate else { return }
        let elapsed = now.timeIntervalSince(start) - accumulatedPauseDuration
        if !isUncappedForTime, elapsed >= totalDurationSeconds {
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

    /// Explicitly end the workout now (For Time "Stop"). Freezes the final elapsed
    /// time via finishedAt so the Done screen and HealthKit don't keep growing.
    mutating func finish(now: Date) {
        guard state == .running || state == .paused else { return }
        // Fold an open pause into the accumulated total so frozen elapsed excludes it.
        if let pauseStart = pausedAt {
            accumulatedPauseDuration += max(0, now.timeIntervalSince(pauseStart))
            pausedAt = nil
        }
        finishedAt = now
        state = .finished
    }

    mutating func reset() {
        state = .idle
        startDate = nil
        accumulatedPauseDuration = 0
        pausedAt = nil
        finishedAt = nil
    }

    /// End date for a HealthKit workout so duration = active time (excludes pause). Nil if workout never started.
    func effectiveWorkoutEndDate(now: Date) -> Date? {
        guard startDate != nil else { return nil }
        // Exclude both completed pauses and any in-progress pause (when ending while paused),
        // so the active-time duration isn't inflated by an open pause interval.
        var pause = accumulatedPauseDuration
        if let pauseStart = pausedAt {
            pause += max(0, now.timeIntervalSince(pauseStart))
        }
        return Date(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate - pause)
    }

    // MARK: - Query (Date-based)

    func snapshot(now: Date) -> WODTimerEngineSnapshot {
        switch state {
        case .idle:
            return makeSnapshot(state: .idle, remainingTime: 0, elapsedTime: 0, currentRound: 0, secondsIntoCurrentMinute: 0, phase: .work, remainingTimeInPhase: 0)
        case .running:
            let elapsed = elapsedSeconds(now: now)
            let total = totalDurationSeconds
            if !isUncappedForTime, elapsed >= total {
                return makeFinishedSnapshot()
            }
            return snapshotForActive(elapsed: elapsed)
        case .paused:
            let elapsed = elapsedSeconds(now: now)
            if !isUncappedForTime, elapsed >= totalDurationSeconds {
                return makeFinishedSnapshot()
            }
            return snapshotForPaused(elapsed: elapsed)
        case .finished:
            return makeFinishedSnapshot()
        }
    }

    mutating func tick(now: Date) {
        guard state == .running else { return }
        guard !isUncappedForTime else { return } // uncapped For Time never auto-finishes
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

    private func makeSnapshot(state: WODTimerEngineState, remainingTime: TimeInterval, elapsedTime: TimeInterval, currentRound: Int, secondsIntoCurrentMinute: Int, phase: WODTimerPhase, remainingTimeInPhase: TimeInterval) -> WODTimerEngineSnapshot {
        WODTimerEngineSnapshot(
            state: state,
            remainingTime: remainingTime,
            elapsedTime: elapsedTime,
            currentRound: currentRound,
            secondsIntoCurrentMinute: secondsIntoCurrentMinute,
            currentPhase: phase,
            remainingTimeInPhase: remainingTimeInPhase
        )
    }

    /// Final elapsed time once finished. finish(now:) freezes the exact time via
    /// finishedAt; auto-finished workouts (cap/total reached) use the full duration.
    private var finishedElapsedTime: TimeInterval {
        if let finishedAt, let start = startDate {
            return max(0, finishedAt.timeIntervalSince(start) - accumulatedPauseDuration)
        }
        return totalDurationSeconds
    }

    private func makeFinishedSnapshot() -> WODTimerEngineSnapshot {
        let totalRounds: Int
        switch mode {
        case .emom(let r, _): totalRounds = r
        case .intervals(_, _, let r): totalRounds = r
        case .forTime: totalRounds = 1 // For Time has no rounds; UI hides the label
        }
        return makeSnapshot(state: .finished, remainingTime: 0, elapsedTime: finishedElapsedTime, currentRound: totalRounds, secondsIntoCurrentMinute: 0, phase: .work, remainingTimeInPhase: 0)
    }

    private func snapshotForActive(elapsed: TimeInterval) -> WODTimerEngineSnapshot {
        switch mode {
        case .emom(let rounds, let spr):
            let total = TimeInterval(rounds) * TimeInterval(spr)
            let remaining = max(0, total - elapsed)
            let round = min(roundFromEMOM(elapsed: elapsed), rounds)
            let intoRound = elapsed >= total ? 0 : secondsIntoMinuteFrom(elapsed: elapsed)
            let remainingTimeInPhase = TimeInterval(spr - intoRound)
            return makeSnapshot(state: .running, remainingTime: remaining, elapsedTime: elapsed, currentRound: round, secondsIntoCurrentMinute: intoRound, phase: .work, remainingTimeInPhase: remainingTimeInPhase)
        case .intervals(let w, let r, let n):
            let total = totalDurationSeconds
            let remaining = max(0, total - elapsed)
            let (round, phase, remainingTimeInPhase) = intervalsPhase(elapsed: elapsed, work: w, rest: r, rounds: n)
            return makeSnapshot(state: .running, remainingTime: remaining, elapsedTime: elapsed, currentRound: round, secondsIntoCurrentMinute: 0, phase: phase, remainingTimeInPhase: remainingTimeInPhase)
        case .forTime(let cap):
            let remaining = cap.map { max(0, TimeInterval($0) - elapsed) } ?? 0
            return makeSnapshot(state: .running, remainingTime: remaining, elapsedTime: elapsed, currentRound: 1, secondsIntoCurrentMinute: 0, phase: .work, remainingTimeInPhase: remaining)
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
            return makeSnapshot(state: .paused, remainingTime: remaining, elapsedTime: elapsed, currentRound: round, secondsIntoCurrentMinute: intoRound, phase: .work, remainingTimeInPhase: remainingTimeInPhase)
        case .intervals(let w, let r, let n):
            let total = totalDurationSeconds
            let remaining = max(0, total - elapsed)
            let (round, phase, remainingTimeInPhase) = intervalsPhase(elapsed: elapsed, work: w, rest: r, rounds: n)
            return makeSnapshot(state: .paused, remainingTime: remaining, elapsedTime: elapsed, currentRound: round, secondsIntoCurrentMinute: 0, phase: phase, remainingTimeInPhase: remainingTimeInPhase)
        case .forTime(let cap):
            let remaining = cap.map { max(0, TimeInterval($0) - elapsed) } ?? 0
            return makeSnapshot(state: .paused, remainingTime: remaining, elapsedTime: elapsed, currentRound: 1, secondsIntoCurrentMinute: 0, phase: .work, remainingTimeInPhase: remaining)
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
        let mode: String        // "emom" | "intervals" | "forTime"
        let totalMinutes: Int
        let emomSecondsPerRound: Int?
        let workSeconds: Int?
        let restSeconds: Int?
        let rounds: Int?
        /// For Time cap; nil when uncapped or in another mode. Optional so old payloads decode.
        let capSeconds: Int?
        /// When finish(now:) froze the workout; lets the Watch freeze elapsed too.
        let finishedAt: Date?
        let lastUpdated: Date
    }

    func syncPayload(now: Date) -> SyncPayload {
        let (modeStr, totalMin, spr, work, rest, rnds, cap): (String, Int, Int?, Int?, Int?, Int?, Int?) = {
            switch mode {
            case .emom(let m, let s): return ("emom", m, s, nil, nil, nil, nil)
            case .intervals(let w, let r, let n): return ("intervals", 0, nil, w, r, n, nil)
            case .forTime(let c): return ("forTime", 0, nil, nil, nil, nil, c)
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
            capSeconds: cap,
            finishedAt: finishedAt,
            lastUpdated: now
        )
    }
}
