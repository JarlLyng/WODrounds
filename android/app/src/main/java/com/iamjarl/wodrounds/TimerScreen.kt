package com.iamjarl.wodrounds

import android.content.SharedPreferences
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.SystemClock
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.waitForUpOrCancellation
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
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.iamjarl.wodrounds.engine.EngineState
import com.iamjarl.wodrounds.engine.Phase
import com.iamjarl.wodrounds.engine.Snapshot
import com.iamjarl.wodrounds.engine.TimerMode
import com.iamjarl.wodrounds.engine.WODTimerEngine
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlin.math.ceil
import kotlin.math.floor
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

/** The modes, keyed as iOS stores them (`lastTimerMode`). */
private enum class Mode(val label: String, val key: String, val help: String) {
    EMOM("EMOM", "EMOM", "Select the number of rounds, and length of each round."),
    INTERVALS("Intervals", "Intervals", "Set work time, rest time, and number of rounds."),
    FOR_TIME("For Time", "For Time", "The clock counts up. Press Stop when you finish, or set an optional time cap."),
}

// The iOS ranges (ContentView.swift).
private val RoundsRange = 1..120
private val LengthRange = 30..570
private val WorkRange = 5..300
private val RestRange = 0..180
private val IntervalRoundsRange = 1..60
private val CapRange = 0..3600 // 0 = no cap, then 0:30 to 60:00 in 30 s steps
private const val CountInSeconds = 10.0

/** One steady clock for the engine: it keeps counting when the screen is off. */
private fun clock(): Double = SystemClock.elapsedRealtime() / 1000.0

/** As sharedTimeString on iOS: whole seconds rounded up, mm:ss. */
private fun timeString(seconds: Double): String {
    val total = max(0, ceil(seconds).toInt())
    return "%02d:%02d".format(total / 60, total % 60)
}

private fun lengthString(seconds: Int) = "%02d:%02d".format(seconds / 60, seconds % 60)
private fun capString(seconds: Int) = if (seconds == 0) "No cap" else lengthString(seconds)

/** The setup values, remembered between launches under the iOS @AppStorage keys. */
private class Setup(private val prefs: SharedPreferences) {
    var mode by mutableStateOf(Mode.entries.firstOrNull { it.key == prefs.getString("lastTimerMode", null) } ?: Mode.EMOM)
    var emomRounds by mutableIntStateOf(prefs.getInt("emomRounds", 10).coerceIn(RoundsRange))
    var emomLength by mutableIntStateOf(prefs.getInt("emomRoundLengthSeconds", 60).coerceIn(LengthRange))
    var work by mutableIntStateOf(prefs.getInt("intervalsWorkSeconds", 30).coerceIn(WorkRange))
    var rest by mutableIntStateOf(prefs.getInt("intervalsRestSeconds", 15).coerceIn(RestRange))
    var intervalRounds by mutableIntStateOf(prefs.getInt("intervalsRounds", 8).coerceIn(IntervalRoundsRange))
    var cap by mutableIntStateOf(prefs.getInt("forTimeCapSeconds", 0).coerceIn(CapRange))

    fun save() {
        prefs.edit()
            .putString("lastTimerMode", mode.key)
            .putInt("emomRounds", emomRounds).putInt("emomRoundLengthSeconds", emomLength)
            .putInt("intervalsWorkSeconds", work).putInt("intervalsRestSeconds", rest).putInt("intervalsRounds", intervalRounds)
            .putInt("forTimeCapSeconds", cap)
            .apply()
    }

    fun engine(): WODTimerEngine = when (mode) {
        Mode.EMOM -> WODTimerEngine.emom(emomRounds, emomLength)
        Mode.INTERVALS -> WODTimerEngine.intervals(work, rest, intervalRounds)
        Mode.FOR_TIME -> WODTimerEngine.forTime(if (cap == 0) null else cap)
    }
}

@Composable
fun TimerScreen(prefs: SharedPreferences) {
    val setup = remember { Setup(prefs) }
    var engine by remember { mutableStateOf(setup.engine()) }
    var countInEnd by remember { mutableStateOf<Double?>(null) }
    var now by remember { mutableDoubleStateOf(clock()) }
    var version by remember { mutableIntStateOf(0) } // bumps on every action, so the UI redraws
    var confirmCancel by remember { mutableStateOf(false) }
    val beeper = remember { Beeper() }
    DisposableEffect(Unit) { onDispose { beeper.release() } }

    fun changed() {
        setup.save()
        engine = setup.engine()
        version++
    }

    // The tick: ten times a second, so the readout, the ring and the 3-2-1 land on time.
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
                beeper.check(engine.snapshot(now), engine.mode)
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
                line = if (engine.mode is TimerMode.ForTime) "Finished in ${timeString(floor(snapshot.elapsedTime))}"
                else engine.rounds.let { "You completed $it round${if (it == 1) "" else "s"}" },
                onReset = { engine.reset(); beeper.reset(); changed() },
            )
            snapshot.state == EngineState.IDLE -> SetupView(
                setup = setup,
                onChange = { changed() },
                onStart = { changed(); beeper.reset(); countInEnd = clock() + CountInSeconds },
            )
            else -> Running(
                engine = engine,
                snapshot = snapshot,
                onPrimary = {
                    val t = clock()
                    when {
                        engine.mode is TimerMode.ForTime -> engine.finish(t) // Stop freezes the time
                        engine.state == EngineState.PAUSED -> engine.resume(t)
                        else -> engine.pause(t)
                    }
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
private fun SetupView(setup: Setup, onChange: () -> Unit, onStart: () -> Unit) {
    Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
        ModeSwitch(setup.mode) { setup.mode = it; onChange() }
        Spacer(Modifier.height(12.dp))
        Label(setup.mode.help, TextTertiary, 14.sp)
        Spacer(Modifier.weight(1f))
        when (setup.mode) {
            Mode.EMOM -> {
                Stepper("Rounds", setup.emomRounds.toString(),
                    onMinus = { setup.emomRounds = (setup.emomRounds - 1).coerceIn(RoundsRange); onChange() },
                    onPlus = { setup.emomRounds = (setup.emomRounds + 1).coerceIn(RoundsRange); onChange() })
                Spacer(Modifier.height(32.dp))
                Stepper("Round length", lengthString(setup.emomLength),
                    onMinus = { setup.emomLength = (setup.emomLength - 30).coerceIn(LengthRange); onChange() },
                    onPlus = { setup.emomLength = (setup.emomLength + 30).coerceIn(LengthRange); onChange() })
            }
            Mode.INTERVALS -> {
                Stepper("Work (sec)", setup.work.toString(),
                    onMinus = { setup.work = (setup.work - 1).coerceIn(WorkRange); onChange() },
                    onPlus = { setup.work = (setup.work + 1).coerceIn(WorkRange); onChange() })
                Spacer(Modifier.height(24.dp))
                Stepper("Rest (sec)", setup.rest.toString(),
                    onMinus = { setup.rest = (setup.rest - 1).coerceIn(RestRange); onChange() },
                    onPlus = { setup.rest = (setup.rest + 1).coerceIn(RestRange); onChange() })
                Spacer(Modifier.height(24.dp))
                Stepper("Rounds", setup.intervalRounds.toString(),
                    onMinus = { setup.intervalRounds = (setup.intervalRounds - 1).coerceIn(IntervalRoundsRange); onChange() },
                    onPlus = { setup.intervalRounds = (setup.intervalRounds + 1).coerceIn(IntervalRoundsRange); onChange() })
            }
            Mode.FOR_TIME -> {
                Stepper("Time cap", capString(setup.cap),
                    onMinus = { setup.cap = (setup.cap - 30).coerceIn(CapRange); onChange() },
                    onPlus = { setup.cap = (setup.cap + 30).coerceIn(CapRange); onChange() })
            }
        }
        Spacer(Modifier.weight(1f))
        Primary("Start", onStart)
    }
}

@Composable
private fun ModeSwitch(selected: Mode, onSelect: (Mode) -> Unit) {
    Row(
        Modifier.clip(RoundedCornerShape(10.dp)).background(Card).padding(4.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Mode.entries.forEach { m ->
            val on = m == selected
            Button(
                onClick = { if (!on) onSelect(m) },
                shape = RoundedCornerShape(8.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = if (on) Lime else Color.Transparent,
                    contentColor = if (on) OnLime else TextSecondary,
                ),
                modifier = Modifier.height(40.dp),
            ) { Text(m.label, fontFamily = Mono, fontWeight = if (on) FontWeight.Bold else FontWeight.Normal, fontSize = 15.sp) }
        }
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
private fun Running(engine: WODTimerEngine, snapshot: Snapshot, onPrimary: () -> Unit, onCancel: () -> Unit) {
    val mode = engine.mode
    Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.weight(1f))
        when (mode) {
            is TimerMode.Emom -> {
                Label(timeString(snapshot.remainingTimeInPhase), TextPrimary, 88.sp, FontWeight.Bold)
                Label("Round ${snapshot.currentRound} / ${engine.rounds} Rounds", TextSecondary, 20.sp, FontWeight.SemiBold)
            }
            is TimerMode.Intervals -> {
                val work = snapshot.currentPhase == Phase.WORK
                Label(if (work) "Work" else "Rest", TextSecondary, 22.sp, FontWeight.Bold)
                Spacer(Modifier.height(8.dp))
                Box(contentAlignment = Alignment.Center) {
                    PhaseRing(
                        remaining = snapshot.remainingTimeInPhase,
                        duration = (if (work) mode.workSeconds else mode.restSeconds).toDouble(),
                        tint = if (work) Lime else TextSecondary,
                    )
                    Label(timeString(snapshot.remainingTimeInPhase), TextPrimary, 72.sp, FontWeight.Bold)
                }
                Spacer(Modifier.height(8.dp))
                Label("Round ${snapshot.currentRound} / ${engine.rounds} Rounds", TextSecondary, 20.sp, FontWeight.SemiBold)
                Label("${timeString(snapshot.remainingTime)} left", TextTertiary, 16.sp, FontWeight.SemiBold)
            }
            is TimerMode.ForTime -> {
                // Counts up, floored so the shown time never runs ahead of the athlete.
                Label(timeString(floor(snapshot.elapsedTime)), TextPrimary, 88.sp, FontWeight.Bold)
                mode.capSeconds?.let { Label("Cap ${lengthString(it)}", TextSecondary, 20.sp, FontWeight.SemiBold) }
            }
        }
        Spacer(Modifier.weight(1f))
        Primary(
            when {
                mode is TimerMode.ForTime -> "Stop"
                snapshot.state == EngineState.PAUSED -> "Resume"
                else -> "Pause"
            },
            onPrimary,
        )
        Spacer(Modifier.height(12.dp))
        Secondary("Cancel", onCancel)
    }
}

/** As SharedPhaseRing on iOS: drains clockwise from the top over the current phase. */
@Composable
private fun PhaseRing(remaining: Double, duration: Double, tint: Color) {
    val progress = if (duration > 0) (remaining / duration).coerceIn(0.0, 1.0).toFloat() else 0f
    Canvas(Modifier.size(300.dp)) {
        val stroke = 8.dp.toPx()
        val inset = stroke / 2
        val arcSize = androidx.compose.ui.geometry.Size(size.width - stroke, size.height - stroke)
        val topLeft = androidx.compose.ui.geometry.Offset(inset, inset)
        drawArc(TextTertiary.copy(alpha = 0.25f), 0f, 360f, false, topLeft, arcSize, style = Stroke(stroke))
        drawArc(tint, -90f, 360f * progress, false, topLeft, arcSize, style = Stroke(stroke, cap = StrokeCap.Round))
    }
}

@Composable
private fun Done(line: String, onReset: () -> Unit) {
    Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.weight(1f))
        Box(Modifier.size(72.dp).background(Lime, CircleShape), contentAlignment = Alignment.Center) {
            Label("✓", OnLime, 40.sp, FontWeight.Bold)
        }
        Spacer(Modifier.height(16.dp))
        Label("Done", TextPrimary, 36.sp, FontWeight.Bold)
        Label(line, TextSecondary, 16.sp)
        Spacer(Modifier.weight(1f))
        Primary("Reset", onReset)
    }
}

@Composable
private fun Stepper(label: String, value: String, onMinus: () -> Unit, onPlus: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Label(label, TextSecondary, 14.sp)
        Row(verticalAlignment = Alignment.CenterVertically) {
            RepeatButton("−", "Decrease $label", onMinus)
            Label(value, TextPrimary, 52.sp, FontWeight.Bold, Modifier.width(200.dp))
            RepeatButton("+", "Increase $label", onPlus)
        }
    }
}

/** A step button that repeats while held, as iOS's steppers do with a long press. */
@Composable
private fun RepeatButton(symbol: String, description: String, onStep: () -> Unit) {
    val step by rememberUpdatedState(onStep)
    val scope = rememberCoroutineScope()
    Box(
        Modifier
            .size(64.dp)
            .clip(RoundedCornerShape(12.dp))
            .background(Card)
            .semantics {
                role = Role.Button
                contentDescription = description
                onClick { step(); true }
            }
            .pointerInput(Unit) {
                awaitEachGesture {
                    awaitFirstDown()
                    step()
                    val repeat = scope.launch {
                        delay(400)
                        while (true) {
                            step()
                            delay(70)
                        }
                    }
                    waitForUpOrCancellation()
                    repeat.cancel()
                }
            },
        contentAlignment = Alignment.Center,
    ) { Text(symbol, color = TextPrimary, fontFamily = Mono, fontSize = 28.sp) }
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
 * The 3-2-1 before each change, as iOS's checkInRoundCues: one beep at 3, 2 and 1 seconds
 * left in the EMOM round or the work or rest phase, each once. For Time has no cues. The
 * beep is a short 880 Hz tone made here and played as media, so it follows the media volume
 * and the speaker or headphones in use. Sound never stops the timer: if the audio can't
 * start, the beep is skipped.
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
    private var last: Triple<Int, Int, Phase>? = null

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

    fun check(s: Snapshot, mode: TimerMode) {
        if (mode is TimerMode.ForTime) return
        val sec = s.remainingTimeInPhase.roundToInt()
        if (sec !in 1..3) return
        val key = Triple(sec, s.currentRound, s.currentPhase)
        if (key == last) return
        last = key
        beep()
    }

    fun reset() {
        last = null
    }

    fun release() {
        runCatching { track?.release() }
        track = null
    }
}
