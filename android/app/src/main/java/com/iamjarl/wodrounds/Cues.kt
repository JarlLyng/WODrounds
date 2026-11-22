package com.iamjarl.wodrounds

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.media.SoundPool
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.speech.tts.TextToSpeech
import android.util.Log
import com.iamjarl.wodrounds.engine.Phase
import com.iamjarl.wodrounds.engine.Snapshot
import com.iamjarl.wodrounds.engine.TimerMode
import java.util.Locale
import kotlin.math.roundToInt

/*
 * Every sound and haptic of a workout, as iOS plays them (WorkoutSoundManager.swift and
 * iOSContentView.checkInRoundCues):
 *
 * - count-in ends: "Get ready, start" and a light tap;
 * - a new EMOM round: a light tap, and "10, 5 or 2 rounds left";
 * - a switch between work and rest: a medium tap, and the rounds left once per round;
 * - halfway through a phase longer than 40 s, and 10 seconds left in one longer than 15 s;
 * - a 3-2-1 beep before every change; For Time has none of the in-round cues;
 * - Done: "You did it" (one of three) and the success haptic.
 *
 * The voice files are the app's recorded English cues; "halfway" and "ten seconds" have no
 * file on iOS either and use the system voice. All of it plays as media and mixes with the
 * user's music (no audio focus taken), as iOS's .mixWithOthers. The sound switch silences
 * the voice and beeps, not the haptics, as on iOS. Sound never stops the timer: anything
 * that fails to start is skipped.
 */
class Cues(context: Context) {
    private val app = context.applicationContext
    private val media = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA)
        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
        .build()

    private val pool = SoundPool.Builder().setMaxStreams(2).setAudioAttributes(media).build()
    private val voice = mapOf(
        "getReadyStart" to R.raw.get_ready_start,
        "tenRoundsLeft" to R.raw.ten_rounds_left,
        "fiveRoundsLeft" to R.raw.five_rounds_left,
        "twoRoundsLeft" to R.raw.two_rounds_left,
        "youDidIt" to R.raw.you_did_it,
        "youDidIt2" to R.raw.you_did_it_2,
        "youDidIt3" to R.raw.you_did_it_3,
    ).mapValues { (_, res) -> runCatching { pool.load(app, res, 1) }.getOrDefault(0) }

    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private val beeper = Beeper()
    private val vibrator: Vibrator? = runCatching {
        (app.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
    }.getOrNull()

    // Which cues have fired, so each fires once, as the iOS state vars do.
    private var lastRound = 0
    private var lastPhase: Phase? = null
    private var lastRoundsRemainingRound = 0
    private var lastHalfway: Pair<Int, Phase>? = null
    private var lastTenSeconds: Pair<Int, Phase>? = null
    private var lastBeep: Triple<Int, Int, Phase>? = null

    init {
        tts = runCatching {
            TextToSpeech(app) { status ->
                if (status == TextToSpeech.SUCCESS) {
                    tts?.language = Locale.US
                    tts?.setAudioAttributes(media)
                    ttsReady = true
                }
            }
        }.getOrNull()
    }

    fun countInEnded(soundOn: Boolean) {
        lastRound = 1
        lastPhase = Phase.WORK
        haptic(Strength.LIGHT)
        if (soundOn) play("getReadyStart")
    }

    /** Call on every tick of a running workout. */
    fun tick(s: Snapshot, mode: TimerMode, totalRounds: Int, soundOn: Boolean) {
        when (mode) {
            is TimerMode.Emom -> if (s.currentRound > lastRound) {
                lastRound = s.currentRound
                haptic(Strength.LIGHT)
                if (soundOn) roundsRemaining(s.currentRound, totalRounds)
            }
            is TimerMode.Intervals -> if (s.currentPhase != lastPhase) {
                lastPhase = s.currentPhase
                haptic(Strength.MEDIUM)
                // A round has two changes (work to rest, rest to work): announce once.
                if (s.currentRound != lastRoundsRemainingRound) {
                    lastRoundsRemainingRound = s.currentRound
                    if (soundOn) roundsRemaining(s.currentRound, totalRounds)
                }
            }
            is TimerMode.ForTime -> return // no rounds, no phases, no in-round cues
        }
        if (!soundOn) return

        val phaseLength = when (mode) {
            is TimerMode.Emom -> mode.secondsPerRound.toDouble()
            is TimerMode.Intervals -> (if (s.currentPhase == Phase.WORK) mode.workSeconds else mode.restSeconds).toDouble()
            else -> 0.0
        }
        val left = s.remainingTimeInPhase
        val key = s.currentRound to s.currentPhase
        if (phaseLength > 40 && left >= phaseLength / 2 - 0.5 && left <= phaseLength / 2 + 0.5 && lastHalfway != key) {
            lastHalfway = key
            speak("halfway")
        }
        if (phaseLength > 15 && left >= 9.5 && left <= 10.5 && lastTenSeconds != key) {
            lastTenSeconds = key
            speak("ten seconds")
        }
        val sec = left.roundToInt()
        if (sec in 1..3) {
            val beep = Triple(sec, s.currentRound, s.currentPhase)
            if (beep != lastBeep) {
                lastBeep = beep
                log("beep $sec (left %.2f, round ${s.currentRound} ${s.currentPhase})".format(left))
                beeper.beep()
            }
        }
    }

    fun finished(soundOn: Boolean) {
        haptic(Strength.SUCCESS)
        if (soundOn) play(listOf("youDidIt", "youDidIt2", "youDidIt3").random())
        reset()
    }

    fun reset() {
        lastRound = 0
        lastPhase = null
        lastRoundsRemainingRound = 0
        lastHalfway = null
        lastTenSeconds = null
        lastBeep = null
    }

    fun release() {
        runCatching { pool.release() }
        runCatching { tts?.shutdown() }
        beeper.release()
    }

    /** As iOS's checkRoundsRemaining: 10 left (if more than 10), 5 left (if more than 5), 2 left. */
    private fun roundsRemaining(round: Int, total: Int) {
        when (total - round) {
            10 -> if (total > 10) play("tenRoundsLeft")
            5 -> if (total > 5) play("fiveRoundsLeft")
            2 -> play("twoRoundsLeft")
        }
    }

    private fun play(name: String) {
        log("voice $name")
        val id = voice[name] ?: return
        if (id != 0) runCatching { pool.play(id, 1f, 1f, 1, 0, 1f) }
    }

    private fun speak(text: String) {
        log("speak $text")
        if (ttsReady) runCatching { tts?.speak(text, TextToSpeech.QUEUE_ADD, null, text) }
    }

    private enum class Strength { LIGHT, MEDIUM, SUCCESS }

    /** Debug builds only: each cue with its moment, for checking timing on a device. */
    private fun log(what: String) {
        if (BuildConfig.DEBUG) Log.d("WODroundsCues", "%.2f %s".format(clock(), what))
    }

    private fun haptic(strength: Strength) {
        log("haptic $strength")
        val v = vibrator ?: return
        val effect = when (strength) {
            Strength.LIGHT -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_CLICK)
            Strength.MEDIUM -> VibrationEffect.createPredefined(VibrationEffect.EFFECT_HEAVY_CLICK)
            Strength.SUCCESS -> VibrationEffect.createWaveform(longArrayOf(0, 60, 80, 120), -1)
        }
        runCatching { v.vibrate(effect) }
    }
}

/** The 3-2-1 beep: a short 880 Hz tone made here, played as media. */
private class Beeper {
    private val sampleRate = 44_100
    private val pcm: ShortArray = ShortArray(sampleRate * 150 / 1000).also { buf ->
        val fade = sampleRate / 200 // 5 ms in and out, so the tone doesn't click
        for (i in buf.indices) {
            val env = minOf(1.0, i / fade.toDouble(), (buf.size - i) / fade.toDouble())
            buf[i] = (Math.sin(2 * Math.PI * 880 * i / sampleRate) * env * 0.8 * Short.MAX_VALUE).toInt().toShort()
        }
    }
    private var track: AudioTrack? = null

    private fun track(): AudioTrack? = track ?: runCatching {
        AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(sampleRate)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build()
            )
            .setTransferMode(AudioTrack.MODE_STATIC)
            .setBufferSizeInBytes(pcm.size * 2)
            .build()
            .also { it.write(pcm, 0, pcm.size) }
    }.getOrNull().also { track = it }

    fun beep() {
        runCatching {
            val t = track() ?: return
            t.stop()
            t.reloadStaticData()
            t.play()
        }
    }

    fun release() {
        runCatching { track?.release() }
        track = null
    }
}
