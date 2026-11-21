package com.iamjarl.wodrounds.engine

import kotlin.math.max
import kotlin.math.min

/*
 * A line-for-line port of Shared/WODTimerEngine.swift: EMOM, Intervals and For Time.
 * No UI, sound or clock of its own. Every call takes `now` in seconds on one steady
 * clock (the app uses SystemClock.elapsedRealtime), where the Swift engine takes a Date.
 *
 * Both engines run the timelines in test-fixtures/engine-timelines.json, so a change
 * here that the Swift engine doesn't share fails EngineTimelineTest, and the reverse.
 * Keep the two side by side when changing either.
 */

enum class EngineState { IDLE, RUNNING, PAUSED, FINISHED }

/** Work or rest (Intervals); EMOM and For Time are always WORK. */
enum class Phase { WORK, REST }

/** The timer at one moment. Every value is derived from `now`. */
data class Snapshot(
    val state: EngineState,
    /** Seconds left in the workout (0 when idle or finished; 0 for uncapped For Time). */
    val remainingTime: Double,
    /** Seconds since start, without pauses. Frozen at the final time once finished. */
    val elapsedTime: Double,
    /** 1-based. */
    val currentRound: Int,
    /** Whole seconds into the current EMOM round; 0 for the other modes. */
    val secondsIntoCurrentMinute: Int,
    val currentPhase: Phase,
    /** Seconds left in the current work or rest phase. */
    val remainingTimeInPhase: Double,
)

sealed interface TimerMode {
    data class Emom(val rounds: Int, val secondsPerRound: Int) : TimerMode
    data class Intervals(val workSeconds: Int, val restSeconds: Int, val rounds: Int) : TimerMode
    /** capSeconds null = uncapped. */
    data class ForTime(val capSeconds: Int?) : TimerMode
}

class WODTimerEngine private constructor(val mode: TimerMode) {

    var state: EngineState = EngineState.IDLE
        private set

    private var startTime: Double? = null
    private var accumulatedPauseDuration: Double = 0.0
    private var pausedAt: Double? = null
    /** Set by finish() so the final elapsed time is frozen. */
    private var finishedAt: Double? = null

    companion object {
        fun emom(rounds: Int = 1, secondsPerRound: Int = 60) =
            WODTimerEngine(TimerMode.Emom(max(1, rounds), max(30, secondsPerRound)))

        fun intervals(workSeconds: Int, restSeconds: Int, rounds: Int) =
            WODTimerEngine(TimerMode.Intervals(max(1, workSeconds), max(0, restSeconds), max(1, rounds)))

        fun forTime(capSeconds: Int?) =
            WODTimerEngine(TimerMode.ForTime(capSeconds?.let { max(1, it) }))

        /** Round (1-based), phase and seconds left in it. Same as the Swift intervalsPhaseAt. */
        fun intervalsPhaseAt(elapsed: Double, work: Int, rest: Int, rounds: Int): Triple<Int, Phase, Double> {
            val cycle = (work + rest).toDouble()
            val total = rounds.toDouble() * work + (rounds - 1).toDouble() * rest
            if (!(elapsed < total) || rounds <= 0) return Triple(rounds, Phase.WORK, 0.0)
            if (rounds == 1) return Triple(1, Phase.WORK, max(0.0, work - elapsed))
            val roundIndex = min((elapsed / cycle).toInt(), rounds - 1)
            val segmentStart = roundIndex * cycle
            val workEnd = segmentStart + work
            if (elapsed < workEnd) return Triple(roundIndex + 1, Phase.WORK, max(0.0, workEnd - elapsed))
            if (roundIndex == rounds - 1) return Triple(rounds, Phase.WORK, 0.0)
            val restEnd = segmentStart + cycle
            return Triple(roundIndex + 1, Phase.REST, max(0.0, restEnd - elapsed))
        }
    }

    // Accessors, as in Swift.

    val totalDurationMinutes: Int get() = (mode as? TimerMode.Emom)?.rounds ?: 0
    val workSeconds: Int get() = (mode as? TimerMode.Intervals)?.workSeconds ?: 0
    val restSeconds: Int get() = (mode as? TimerMode.Intervals)?.restSeconds ?: 0
    val rounds: Int get() = (mode as? TimerMode.Intervals)?.rounds ?: totalDurationMinutes
    val forTimeCapSeconds: Int? get() = (mode as? TimerMode.ForTime)?.capSeconds

    private val isUncappedForTime: Boolean
        get() = mode is TimerMode.ForTime && mode.capSeconds == null

    val totalDurationSeconds: Double
        get() = when (mode) {
            is TimerMode.Emom -> mode.rounds.toDouble() * mode.secondsPerRound
            is TimerMode.Intervals -> mode.rounds.toDouble() * mode.workSeconds + (mode.rounds - 1).toDouble() * mode.restSeconds
            is TimerMode.ForTime -> (mode.capSeconds ?: 0).toDouble()
        }

    // Actions

    fun start(now: Double) {
        if (!(totalDurationSeconds > 0 || isUncappedForTime)) return
        startTime = now
        accumulatedPauseDuration = 0.0
        pausedAt = null
        finishedAt = null
        state = EngineState.RUNNING
    }

    fun pause(now: Double) {
        val start = startTime
        if (state != EngineState.RUNNING || start == null) return
        val elapsed = now - start - accumulatedPauseDuration
        if (!isUncappedForTime && elapsed >= totalDurationSeconds) {
            state = EngineState.FINISHED
            return
        }
        pausedAt = now
        state = EngineState.PAUSED
    }

    fun resume(now: Double) {
        val pauseStart = pausedAt
        if (state != EngineState.PAUSED || pauseStart == null) return
        accumulatedPauseDuration += max(0.0, now - pauseStart)
        pausedAt = null
        state = EngineState.RUNNING
    }

    /** End the workout now (For Time Stop). Freezes the final elapsed time. */
    fun finish(now: Double) {
        if (state != EngineState.RUNNING && state != EngineState.PAUSED) return
        pausedAt?.let {
            accumulatedPauseDuration += max(0.0, now - it)
            pausedAt = null
        }
        finishedAt = now
        state = EngineState.FINISHED
    }

    fun reset() {
        state = EngineState.IDLE
        startTime = null
        accumulatedPauseDuration = 0.0
        pausedAt = null
        finishedAt = null
    }

    /** `now` less every pause, open or closed; null if never started. Swift: effectiveWorkoutEndDate. */
    fun effectiveWorkoutEnd(now: Double): Double? {
        if (startTime == null) return null
        var pause = accumulatedPauseDuration
        pausedAt?.let { pause += max(0.0, now - it) }
        return now - pause
    }

    // Query

    fun snapshot(now: Double): Snapshot = when (state) {
        EngineState.IDLE -> Snapshot(EngineState.IDLE, 0.0, 0.0, 0, 0, Phase.WORK, 0.0)
        EngineState.RUNNING -> {
            val elapsed = elapsedSeconds(now)
            if (!isUncappedForTime && elapsed >= totalDurationSeconds) finishedSnapshot()
            else activeSnapshot(EngineState.RUNNING, elapsed)
        }
        EngineState.PAUSED -> {
            val elapsed = elapsedSeconds(now)
            if (!isUncappedForTime && elapsed >= totalDurationSeconds) finishedSnapshot()
            else activeSnapshot(EngineState.PAUSED, elapsed)
        }
        EngineState.FINISHED -> finishedSnapshot()
    }

    fun tick(now: Double) {
        if (state != EngineState.RUNNING) return
        if (isUncappedForTime) return
        if (elapsedSeconds(now) >= totalDurationSeconds) {
            state = EngineState.FINISHED
            pausedAt = null
        }
    }

    // Private

    private fun elapsedSeconds(now: Double): Double {
        val start = startTime ?: return 0.0
        val raw = when (state) {
            EngineState.RUNNING -> now - start - accumulatedPauseDuration
            EngineState.PAUSED -> (pausedAt ?: now) - start - accumulatedPauseDuration
            else -> 0.0
        }
        return max(0.0, raw)
    }

    private val finishedElapsedTime: Double
        get() {
            val f = finishedAt
            val s = startTime
            if (f != null && s != null) return max(0.0, f - s - accumulatedPauseDuration)
            return totalDurationSeconds
        }

    private fun finishedSnapshot(): Snapshot {
        val totalRounds = when (mode) {
            is TimerMode.Emom -> mode.rounds
            is TimerMode.Intervals -> mode.rounds
            is TimerMode.ForTime -> 1
        }
        return Snapshot(EngineState.FINISHED, 0.0, finishedElapsedTime, totalRounds, 0, Phase.WORK, 0.0)
    }

    /**
     * Running and paused differ in one place: a running EMOM caps the round at the
     * last and reports 0 seconds into it at the very end, as the Swift engine does.
     */
    private fun activeSnapshot(s: EngineState, elapsed: Double): Snapshot = when (mode) {
        is TimerMode.Emom -> {
            val total = mode.rounds.toDouble() * mode.secondsPerRound
            val remaining = max(0.0, total - elapsed)
            val round = if (s == EngineState.RUNNING) min(roundFromEmom(elapsed), mode.rounds) else roundFromEmom(elapsed)
            val intoRound = if (s == EngineState.RUNNING && elapsed >= total) 0 else secondsIntoRound(elapsed)
            Snapshot(s, remaining, elapsed, round, intoRound, Phase.WORK, (mode.secondsPerRound - intoRound).toDouble())
        }
        is TimerMode.Intervals -> {
            val remaining = max(0.0, totalDurationSeconds - elapsed)
            val (round, phase, inPhase) = intervalsPhaseAt(elapsed, mode.workSeconds, mode.restSeconds, mode.rounds)
            Snapshot(s, remaining, elapsed, round, 0, phase, inPhase)
        }
        is TimerMode.ForTime -> {
            val remaining = mode.capSeconds?.let { max(0.0, it - elapsed) } ?: 0.0
            Snapshot(s, remaining, elapsed, 1, 0, Phase.WORK, remaining)
        }
    }

    private fun roundFromEmom(elapsed: Double): Int {
        val m = mode as? TimerMode.Emom ?: return 1
        return min((elapsed / m.secondsPerRound).toInt() + 1, m.rounds)
    }

    private fun secondsIntoRound(elapsed: Double): Int {
        val spr = (mode as? TimerMode.Emom)?.secondsPerRound ?: 60
        return (elapsed % spr).toInt()
    }
}
