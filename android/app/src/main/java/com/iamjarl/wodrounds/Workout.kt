package com.iamjarl.wodrounds

import android.content.Context
import android.content.Intent
import android.os.SystemClock
import com.iamjarl.wodrounds.engine.EngineState
import com.iamjarl.wodrounds.engine.WODTimerEngine
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

/** One steady clock for the engine: it keeps counting when the screen is off. */
fun clock(): Double = SystemClock.elapsedRealtime() / 1000.0

/**
 * The workout on screen, shared by the screen and WorkoutService. The screen sets it up and
 * sends the user's actions here; the service ticks it, plays the cues and keeps it going with
 * the screen off. `changes` moves on every change, so the screen redraws.
 */
object Workout {
    const val COUNT_IN_SECONDS = 10.0

    var engine: WODTimerEngine = WODTimerEngine.emom(10, 60)
        private set
    var countInEnd: Double? = null
        private set
    var soundOn: Boolean = true

    private val _changes = MutableStateFlow(0)
    val changes: StateFlow<Int> = _changes

    /** True from Start until Done or Cancel: the time the service runs. */
    val isActive: Boolean
        get() = countInEnd != null || engine.state == EngineState.RUNNING || engine.state == EngineState.PAUSED

    fun changed() { _changes.value++ }

    /**
     * A new setup on the idle screen. Ignored mid-workout, and on the Done screen, which stays
     * until Reset: the screen is rebuilt on a rotation and must not set the workout up again.
     */
    fun setUp(e: WODTimerEngine) {
        if (isActive || engine.state == EngineState.FINISHED) return
        engine = e
        changed()
    }

    fun start(context: Context, e: WODTimerEngine) {
        engine = e
        countInEnd = clock() + COUNT_IN_SECONDS
        changed()
        WorkoutService.start(context)
    }

    /** Called by the service's tick when the count-in is over. */
    fun countInOver(at: Double) {
        countInEnd = null
        engine.start(at) // the workout starts when the count-in ends, not when it was noticed
        changed()
    }

    fun cancelCountIn() {
        countInEnd = null
        changed()
    }

    fun pauseOrResume() {
        val t = clock()
        if (engine.state == EngineState.PAUSED) engine.resume(t) else engine.pause(t)
        changed()
    }

    /** For Time's Stop: freezes the final time. */
    fun stop() {
        engine.finish(clock())
        changed()
    }

    fun cancel() {
        countInEnd = null
        engine.reset()
        changed()
    }

    fun reset(e: WODTimerEngine) {
        engine = e
        changed()
    }

    /** Debug screenshots only (Capture): a workout part-way through, done, or counting in. */
    fun capture(e: WODTimerEngine, elapsed: Double? = null, finished: Boolean = false, countIn: Double? = null) {
        val now = clock()
        engine = e
        countInEnd = countIn?.let { now + it }
        if (elapsed != null) {
            engine.start(now - elapsed)
            if (finished) engine.finish(now)
        }
        changed()
    }

    fun openApp(context: Context): Intent =
        Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
}
