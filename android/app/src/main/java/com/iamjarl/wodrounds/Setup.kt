package com.iamjarl.wodrounds

import android.content.Intent
import android.content.SharedPreferences
import androidx.annotation.StringRes
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.iamjarl.wodrounds.engine.WODTimerEngine

/** The modes, keyed as iOS stores them (`lastTimerMode`, always the English name). */
enum class Mode(val key: String, @StringRes val label: Int, @StringRes val help: Int) {
    EMOM("EMOM", R.string.mode_emom, R.string.help_emom),
    INTERVALS("Intervals", R.string.mode_intervals, R.string.help_intervals),
    FOR_TIME("For Time", R.string.mode_for_time, R.string.help_for_time),
}

// The iOS ranges (ContentView.swift).
val RoundsRange = 1..120
val LengthRange = 30..570
val WorkRange = 5..300
val RestRange = 0..180
val IntervalRoundsRange = 1..60
val CapRange = 0..3600 // 0 = no cap, then 0:30 to 60:00 in 30 s steps

/** The setup values, remembered between launches under the iOS @AppStorage keys. */
class Setup(private val prefs: SharedPreferences) {
    var mode by mutableStateOf(Mode.entries.firstOrNull { it.key == prefs.getString("lastTimerMode", null) } ?: Mode.EMOM)
    var emomRounds by mutableIntStateOf(prefs.getInt("emomRounds", 10).coerceIn(RoundsRange))
    var emomLength by mutableIntStateOf(prefs.getInt("emomRoundLengthSeconds", 60).coerceIn(LengthRange))
    var work by mutableIntStateOf(prefs.getInt("intervalsWorkSeconds", 30).coerceIn(WorkRange))
    var rest by mutableIntStateOf(prefs.getInt("intervalsRestSeconds", 15).coerceIn(RestRange))
    var intervalRounds by mutableIntStateOf(prefs.getInt("intervalsRounds", 8).coerceIn(IntervalRoundsRange))
    var cap by mutableIntStateOf(prefs.getInt("forTimeCapSeconds", 0).coerceIn(CapRange))
    var soundOn by mutableStateOf(prefs.getBoolean("soundEnabled", true))

    fun save() {
        prefs.edit()
            .putString("lastTimerMode", mode.key)
            .putInt("emomRounds", emomRounds).putInt("emomRoundLengthSeconds", emomLength)
            .putInt("intervalsWorkSeconds", work).putInt("intervalsRestSeconds", rest).putInt("intervalsRounds", intervalRounds)
            .putInt("forTimeCapSeconds", cap)
            .putBoolean("soundEnabled", soundOn)
            .apply()
    }

    fun engine(): WODTimerEngine = when (mode) {
        Mode.EMOM -> WODTimerEngine.emom(emomRounds, emomLength)
        Mode.INTERVALS -> WODTimerEngine.intervals(work, rest, intervalRounds)
        Mode.FOR_TIME -> WODTimerEngine.forTime(if (cap == 0) null else cap)
    }
}

/**
 * Debug builds only, as iOS's SiteCapture: open the app on a given screen for screenshots,
 * without tapping through a workout. The extras are the iOS launch arguments:
 *
 *     adb shell am start -n com.iamjarl.wodrounds/.MainActivity \
 *       -e lastTimerMode Intervals --ei siteElapsed 12        # running, 12 s in
 *       --ez siteFinished true                                # the Done screen
 *       --ei siteCountIn 7                                    # the count-in, 7 s left
 *
 * Any setup key (emomRounds, intervalsWorkSeconds, forTimeCapSeconds, ...) can be passed
 * with --ei as well. A captured workout has no service behind it: no cues, no notification.
 */
object Capture {
    private val intKeys = listOf(
        "emomRounds", "emomRoundLengthSeconds", "intervalsWorkSeconds",
        "intervalsRestSeconds", "intervalsRounds", "forTimeCapSeconds",
    )

    fun apply(intent: Intent?, prefs: SharedPreferences) {
        if (!BuildConfig.DEBUG || intent == null) return
        val edit = prefs.edit()
        intent.getStringExtra("lastTimerMode")?.let { edit.putString("lastTimerMode", it) }
        intKeys.forEach { k -> if (intent.hasExtra(k)) edit.putInt(k, intent.getIntExtra(k, 0)) }
        edit.commit()
        val engine = Setup(prefs).engine()
        when {
            intent.hasExtra("siteCountIn") ->
                Workout.capture(engine, countIn = intent.getIntExtra("siteCountIn", 7).toDouble())
            intent.hasExtra("siteElapsed") ->
                Workout.capture(engine, elapsed = intent.getIntExtra("siteElapsed", 0).toDouble(),
                    finished = intent.getBooleanExtra("siteFinished", false))
        }
    }
}
