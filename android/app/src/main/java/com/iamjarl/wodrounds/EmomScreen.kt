package com.iamjarl.wodrounds

import android.content.SharedPreferences
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.SystemClock
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.iamjarl.wodrounds.engine.EngineState
import com.iamjarl.wodrounds.engine.WODTimerEngine
import kotlinx.coroutines.delay
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.roundToInt

// The WODrounds identity from iamjarl-design (dist/identity/wodrounds.css), dark only here.
private val Background = Color(0xFF000000)
private val TextPrimary = Color(0xFFFFFFFF)
private val TextSecondary = Color(0xBFFFFFFF)
private val TextTertiary = Color(0x99FFFFFF)
private val Card = Color(0x0DFFFFFF)
private val Surface = Color(0xFF17191B)
private val Lime = Color(0xFFD0FF00)
private val OnLime = Color(0xFF000000)
private val Danger = Color(0xFFD70015)
private val Mono = FontFamily.Monospace

// The iOS ranges (ContentView.swift): rounds 1-120, round length 0:30-9:30 in 30 s steps.
private val RoundsRange = 1..120
private val LengthRange = 30..570
private const val CountInSeconds = 10.0

/** One steady clock for the engine: it keeps counting when the screen is off. */
private fun clock(): Double = SystemClock.elapsedRealtime() / 1000.0

/** As sharedTimeString on iOS: whole seconds rounded up, mm:ss. */
private fun timeString(seconds: Double): String {
    val total = max(0, ceil(seconds).toInt())
    return "%02d:%02d".format(total / 60, total % 60)
}

private fun lengthString(seconds: Int) = "%02d:%02d".format(seconds / 60, seconds % 60)

@Composable
fun EmomScreen(prefs: SharedPreferences) {
    // Remembered setup, as iOS keeps it in @AppStorage.
    var rounds by remember { mutableIntStateOf(prefs.getInt("emomRounds", 10).coerceIn(RoundsRange)) }
    var length by remember { mutableIntStateOf(prefs.getInt("emomRoundLengthSeconds", 60).coerceIn(LengthRange)) }
    var engine by remember { mutableStateOf(WODTimerEngine.emom(rounds, length)) }
    var countInEnd by remember { mutableStateOf<Double?>(null) }
    var now by remember { mutableDoubleStateOf(clock()) }
    var version by remember { mutableIntStateOf(0) } // bumps on every action, so the UI redraws
    var confirmCancel by remember { mutableStateOf(false) }
    val beeper = remember { Beeper() }
    DisposableEffect(Unit) { onDispose { beeper.release() } }

    fun saveSetup() {
        prefs.edit().putInt("emomRounds", rounds).putInt("emomRoundLengthSeconds", length).apply()
        engine = WODTimerEngine.emom(rounds, length)
        version++
    }

    // The tick: ten times a second, so the readout and the 3-2-1 land on time.
    LaunchedEffect(Unit) {
        while (true) {
            now = clock()
            countInEnd?.let { end ->
                if (now >= end) {
                    engine.start(end) // the workout starts when the count-in ends, not when we noticed
                    countInEnd = null
                    version++
                }
            }
            if (engine.state == EngineState.RUNNING) {
                engine.tick(now)
                beeper.check(engine.snapshot(now))
                if (engine.state == EngineState.FINISHED) version++
            }
            delay(100)
        }
    }

    val snapshot = remember(now, version) { engine.snapshot(now) }
    val active = countInEnd != null || snapshot.state == EngineState.RUNNING || snapshot.state == EngineState.PAUSED

    // Keep the screen on through the count-in and the workout, as iOS does.
    val view = LocalView.current
    DisposableEffect(active) {
        view.keepScreenOn = active
        onDispose { view.keepScreenOn = false }
    }

    Box(Modifier.fillMaxSize().background(Background).safeDrawingPadding().padding(24.dp)) {
        when {
            countInEnd != null -> CountIn(
                remaining = max(0, ceil(countInEnd!! - now).toInt()),
                onCancel = { countInEnd = null; version++ },
            )
            snapshot.state == EngineState.FINISHED -> Done(
                rounds = engine.rounds,
                onReset = { engine.reset(); beeper.reset(); saveSetup() },
            )
            snapshot.state == EngineState.IDLE -> Setup(
                rounds = rounds,
                length = length,
                onRounds = { rounds = it.coerceIn(RoundsRange); saveSetup() },
                onLength = { length = it.coerceIn(LengthRange); saveSetup() },
                onStart = { saveSetup(); beeper.reset(); countInEnd = clock() + CountInSeconds },
            )
            else -> Running(
                time = timeString(snapshot.remainingTimeInPhase),
                roundLabel = "Round ${snapshot.currentRound} / ${engine.rounds} Rounds",
                paused = snapshot.state == EngineState.PAUSED,
                onPauseResume = {
                    val t = clock()
                    if (engine.state == EngineState.PAUSED) engine.resume(t) else engine.pause(t)
                    version++
                },
                onCancel = { confirmCancel = true },
            )
        }
    }

    if (confirmCancel) {
        AlertDialog(
            onDismissRequest = { confirmCancel = false },
            title = { Text("Cancel workout?") },
            text = { Text("You'll return to setup. Current progress will be lost.") },
            confirmButton = {
                TextButton(onClick = {
                    confirmCancel = false
                    engine.reset()
                    beeper.reset()
                    version++
                }) { Text("Cancel workout", color = Danger) }
            },
            dismissButton = { TextButton(onClick = { confirmCancel = false }) { Text("Keep going", color = TextPrimary) } },
            containerColor = Surface,
            titleContentColor = TextPrimary,
            textContentColor = TextSecondary,
        )
    }
}

@Composable
private fun Setup(rounds: Int, length: Int, onRounds: (Int) -> Unit, onLength: (Int) -> Unit, onStart: () -> Unit) {
    Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            "EMOM",
            color = OnLime, fontFamily = Mono, fontWeight = FontWeight.Bold, fontSize = 16.sp,
            modifier = Modifier.background(Lime, RoundedCornerShape(8.dp)).padding(horizontal = 20.dp, vertical = 8.dp),
        )
        Spacer(Modifier.height(12.dp))
        Label("Select the number of rounds, and length of each round.", TextTertiary, 14.sp)
        Spacer(Modifier.weight(1f))
        Stepper("Rounds", rounds.toString(), onMinus = { onRounds(rounds - 1) }, onPlus = { onRounds(rounds + 1) })
        Spacer(Modifier.height(32.dp))
        Stepper("Round length", lengthString(length), onMinus = { onLength(length - 30) }, onPlus = { onLength(length + 30) })
        Spacer(Modifier.weight(1f))
        Primary("Start", onStart)
    }
}

@Composable
private fun CountIn(remaining: Int, onCancel: () -> Unit) {
    Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
        Label("Get ready", TextSecondary, 22.sp, FontWeight.SemiBold)
        Label(remaining.toString(), TextPrimary, 120.sp, FontWeight.Bold)
        Spacer(Modifier.height(32.dp))
        Secondary("Cancel", onCancel)
    }
}

@Composable
private fun Running(time: String, roundLabel: String, paused: Boolean, onPauseResume: () -> Unit, onCancel: () -> Unit) {
    Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.weight(1f))
        Label(time, TextPrimary, 88.sp, FontWeight.Bold)
        Label(roundLabel, TextSecondary, 20.sp, FontWeight.SemiBold)
        Spacer(Modifier.weight(1f))
        Primary(if (paused) "Resume" else "Pause", onPauseResume)
        Spacer(Modifier.height(12.dp))
        Secondary("Cancel", onCancel)
    }
}

@Composable
private fun Done(rounds: Int, onReset: () -> Unit) {
    Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.weight(1f))
        Box(Modifier.size(72.dp).background(Lime, CircleShape), contentAlignment = Alignment.Center) {
            Label("✓", OnLime, 40.sp, FontWeight.Bold)
        }
        Spacer(Modifier.height(16.dp))
        Label("Done", TextPrimary, 36.sp, FontWeight.Bold)
        Label("You completed $rounds round${if (rounds == 1) "" else "s"}", TextSecondary, 16.sp)
        Spacer(Modifier.weight(1f))
        Primary("Reset", onReset)
    }
}

@Composable
private fun Stepper(label: String, value: String, onMinus: () -> Unit, onPlus: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Label(label, TextSecondary, 14.sp)
        Row(verticalAlignment = Alignment.CenterVertically) {
            StepButton("−", onMinus)
            Label(value, TextPrimary, 56.sp, FontWeight.Bold, Modifier.width(200.dp))
            StepButton("+", onPlus)
        }
    }
}

@Composable
private fun StepButton(symbol: String, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        shape = RoundedCornerShape(12.dp),
        colors = ButtonDefaults.buttonColors(containerColor = Card, contentColor = TextPrimary),
        modifier = Modifier.size(64.dp),
    ) { Text(symbol, fontFamily = Mono, fontSize = 28.sp) }
}

@Composable
private fun Primary(title: String, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        shape = RoundedCornerShape(12.dp),
        colors = ButtonDefaults.buttonColors(containerColor = Lime, contentColor = OnLime),
        modifier = Modifier.fillMaxWidth().height(64.dp),
    ) { Text(title, fontFamily = Mono, fontWeight = FontWeight.Bold, fontSize = 24.sp) }
}

@Composable
private fun Secondary(title: String, onClick: () -> Unit) {
    Button(
        onClick = onClick,
        shape = RoundedCornerShape(12.dp),
        colors = ButtonDefaults.buttonColors(containerColor = Danger, contentColor = TextPrimary),
        modifier = Modifier.fillMaxWidth().height(48.dp),
    ) { Text(title, fontFamily = Mono, fontSize = 18.sp) }
}

@Composable
private fun Label(
    text: String,
    color: Color,
    size: TextUnit,
    weight: FontWeight = FontWeight.Normal,
    modifier: Modifier = Modifier,
) {
    Text(text, color = color, fontSize = size, fontWeight = weight, fontFamily = Mono, textAlign = TextAlign.Center, modifier = modifier)
}

/**
 * The 3-2-1 before each new round, as iOS's checkInRoundCues: one beep at 3, 2 and 1
 * seconds left in the round, each once per round. The beep is a short 880 Hz tone made
 * here and played as media, so it follows the media volume and the speaker or headphones
 * in use. Sound never stops the timer: if the audio can't start, the beep is skipped.
 */
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
    private var lastSecond = -1
    private var lastRound = -1

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

    private fun beep() {
        runCatching {
            val t = track() ?: return
            t.stop()
            t.reloadStaticData()
            t.play()
        }
    }

    fun check(s: com.iamjarl.wodrounds.engine.Snapshot) {
        val sec = s.remainingTimeInPhase.roundToInt()
        if (sec !in 1..3) return
        if (sec == lastSecond && s.currentRound == lastRound) return
        lastSecond = sec
        lastRound = s.currentRound
        beep()
    }

    fun reset() {
        lastSecond = -1
        lastRound = -1
    }

    fun release() {
        runCatching { track?.release() }
        track = null
    }
}
