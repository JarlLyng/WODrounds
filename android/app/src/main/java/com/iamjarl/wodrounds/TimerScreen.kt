package com.iamjarl.wodrounds

import android.Manifest
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Build
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.waitForUpOrCancellation
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawingPadding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableDoubleStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.compositeOver
import com.iamjarl.design.DesignTokens
import com.iamjarl.design.DesignTokens.ColorToken
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.ExperimentalTextApi
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import androidx.compose.ui.text.style.LineHeightStyle
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
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
import kotlin.math.min

/*
 * The one screen, laid out as iOS lays it out (iOSContentView.swift, SharedTimerViews.swift),
 * which is the reference. Every size follows from the space the app has, never from the
 * device: width earns a larger scale (a tablet, a foldable's inner screen), height caps it so
 * a short screen shrinks the layout instead of pushing Start or Pause off it, and a screen
 * about as wide as it is tall gets two columns. Labels that could still run out of room
 * shrink to fit, as iOS's minimumScaleFactor. Sizes are the iamjarl-design tokens in points,
 * used here as dp, and the user's font size setting doesn't change them (iOS uses fixed
 * sizes too): the layout is measured to fit, and a larger font would break that.
 */

// The iamjarl-design colours, light and dark, as iOS follows the system. All of them come from
// com.iamjarl.design.DesignTokens (dist/kotlin/DesignTokens.kt at the version it names).
class Palette(
    val background: Color,
    val text: Color,
    val textSecondary: Color,
    val textTertiary: Color,
    val card: Color,
    val primary: Color,
    val onPrimary: Color,
    /** The Cancel workout dialog's fill. */
    val dialog: Color,
)

private val Dark = Palette(
    background = ColorToken.Dark.Background.app,
    text = ColorToken.Dark.Text.primary,
    textSecondary = ColorToken.Dark.Text.secondary,
    textTertiary = ColorToken.Dark.Text.tertiary,
    card = ColorToken.Dark.Background.card,
    primary = ColorToken.Dark.primary,
    onPrimary = ColorToken.Dark.onPrimary,
    // No opaque raised surface in dark yet (Surface.default is the screen's black), so the
    // dialog would vanish into it: built from tokens until iamjarl-design#130 adds one.
    dialog = ColorToken.Dark.Border.subtle.compositeOver(ColorToken.Dark.Background.app),
)
private val Light = Palette(
    background = ColorToken.Light.Background.app,
    text = ColorToken.Light.Text.primary,
    textSecondary = ColorToken.Light.Text.secondary,
    textTertiary = ColorToken.Light.Text.tertiary,
    card = ColorToken.Light.Background.card,
    primary = ColorToken.Light.primary,
    onPrimary = ColorToken.Light.onPrimary,
    dialog = ColorToken.Light.Surface.default,
)
// The Cancel fill is the shared state colour, the same in both, as iOS (ColorToken.State).
private val Error = ColorToken.State.error
private val OnError = ColorToken.State.onError
// JetBrains Mono, the WODrounds display face in iamjarl-design (OFL-1.1, licence in assets),
// from its variable font. Android's own monospace has no bold, and the bold digits are the app.
@OptIn(ExperimentalTextApi::class)
private val Mono = FontFamily(
    listOf(FontWeight.Normal, FontWeight.SemiBold, FontWeight.Bold).map { w ->
        Font(R.font.jetbrains_mono, weight = w, variationSettings = FontVariation.Settings(FontVariation.weight(w.weight)))
    }
)

private val LocalPalette = staticCompositionLocalOf { Dark }
private val LocalLayout = staticCompositionLocalOf { Layout(400f, 800f) }

// iamjarl-design sizes. The layout scales them itself, so type sizes are taken as plain numbers
// (points, used as dp, the user's font size left out as on iOS: see the top of this file).
private object T {
    val XS = DesignTokens.Typography.Size.xs.value
    val SM = DesignTokens.Typography.Size.sm.value
    val BASE = DesignTokens.Typography.Size.base.value
    val LG = DesignTokens.Typography.Size.lg.value
    val XL = DesignTokens.Typography.Size.xl.value
    val XXL = DesignTokens.Typography.Size.xxl.value
    val NUMERAL_MD = DesignTokens.Typography.Numeral.md.size.value
    val NUMERAL_LG = DesignTokens.Typography.Numeral.lg.size.value
}
private val S = DesignTokens.Spacing
private val Radius = DesignTokens.Radius

/**
 * The scale of everything, from the space the app has: iOS's fontScale, spacingScale,
 * isTwoColumn and LayoutFit, with the same numbers.
 */
class Layout(val width: Float, val height: Float, fontOverride: Float? = null) {
    /** Two columns when the space is about as wide as it is tall, or wider. */
    val twoColumn = width >= 560 && width > height * 0.9f
    val font: Float = fontOverride ?: run {
        val byWidth = min(1.5f, max(1f, 1f + (width - 500) / 400))
        // Two columns: the three Intervals steppers set the height (iOS's LayoutFit). Their
        // column also fits itself to the space it gets (StepperColumn), as type renders
        // a little taller here than on iOS.
        val byHeight = if (twoColumn) (height - 60) / 330
        else if (height >= 748) 1f + (height - 748) / 404 else (height - 180) / 568
        max(0.7f, min(byWidth, byHeight))
    }
    /** Spacing grows more slowly than type on a large display, and shrinks with it on a short one. */
    val spacing: Float = if (font < 1) font else 1f + (font - 1f) * 0.6f
    /** Keeps the steppers within reach on a wide single column. */
    val maxContentWidth: Dp? = if (twoColumn) null else if (font > 1f) 600.dp else null
    val controlsColumnWidth: Dp = min(300 * font, width * 0.35f).dp
}

private fun timeString(seconds: Double): String {
    val total = max(0, ceil(seconds).toInt())
    return "%02d:%02d".format(total / 60, total % 60)
}

private fun lengthString(seconds: Int) = "%02d:%02d".format(seconds / 60, seconds % 60)

@Composable
fun TimerScreen(prefs: SharedPreferences) {
    val context = LocalContext.current
    val setup = remember { Setup(prefs) }
    // The workout itself lives in Workout and is ticked by WorkoutService, which also plays
    // the cues, so it carries on with the screen off. This screen only shows it.
    val version by Workout.changes.collectAsState()
    var now by remember { mutableDoubleStateOf(clock()) }
    var confirmCancel by rememberSaveable { mutableStateOf(false) }
    var showAbout by rememberSaveable { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        Workout.soundOn = setup.soundOn
        Workout.setUp(setup.engine())
        while (true) {
            now = clock()
            delay(100)
        }
    }

    fun changed() {
        setup.save()
        Workout.soundOn = setup.soundOn
        Workout.setUp(setup.engine())
    }

    // Android 13+: the ongoing notification needs this. The workout runs either way.
    val askNotifications = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { }
    fun start() {
        changed()
        if (Build.VERSION.SDK_INT >= 33 &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED &&
            !prefs.getBoolean("askedNotifications", false)
        ) {
            prefs.edit().putBoolean("askedNotifications", true).apply()
            askNotifications.launch(Manifest.permission.POST_NOTIFICATIONS)
        }
        Workout.start(context, setup.engine())
    }

    val engine = Workout.engine
    val countInEnd = Workout.countInEnd
    val snapshot = remember(now, version) { engine.snapshot(now) }
    val running = snapshot.state == EngineState.RUNNING || snapshot.state == EngineState.PAUSED
    val active = countInEnd != null || running

    // Keep the screen on through the count-in and the workout while it's in front, as iOS does.
    val view = LocalView.current
    DisposableEffect(active) {
        view.keepScreenOn = active
        onDispose { view.keepScreenOn = false }
    }

    // A white flash on each new EMOM round and each Intervals work/rest change, as iOS.
    var flash by remember { mutableStateOf(false) }
    var lastRound by remember { mutableStateOf(snapshot.currentRound) }
    var lastPhase by remember { mutableStateOf(snapshot.currentPhase) }
    LaunchedEffect(snapshot.currentRound, snapshot.currentPhase, running) {
        val changedRound = engine.mode is TimerMode.Emom && snapshot.currentRound > lastRound
        val changedPhase = engine.mode is TimerMode.Intervals && snapshot.currentPhase != lastPhase
        lastRound = snapshot.currentRound
        lastPhase = snapshot.currentPhase
        if (running && (changedRound || changedPhase)) {
            flash = true
            delay(350)
            flash = false
        }
    }

    val palette = if (isSystemInDarkTheme()) Dark else Light
    val density = LocalDensity.current
    CompositionLocalProvider(LocalPalette provides palette, LocalDensity provides Density(density.density, 1f)) {
        BackHandler(enabled = showAbout) { showAbout = false }
        if (showAbout) {
            About(onDone = { showAbout = false })
            return@CompositionLocalProvider
        }
        // iOS: the safe area, then 12 around the content view; the space left is what the
        // layout is measured against, and the content is inset another 12 inside it.
        Box(Modifier.fillMaxSize().background(palette.background)) {
        BoxWithConstraints(Modifier.fillMaxSize().safeDrawingPadding().padding(S.md)) {
            val layout = Layout(maxWidth.value, maxHeight.value)
            CompositionLocalProvider(LocalLayout provides layout) {
                Box(Modifier.fillMaxSize().padding(S.md)) {
                    val content: @Composable () -> Unit = {
                        Content(
                            engine = engine,
                            snapshot = snapshot,
                            setup = setup,
                            onChange = { changed() },
                            onPrimary = {
                                when {
                                    snapshot.state == EngineState.IDLE -> start()
                                    snapshot.state == EngineState.FINISHED -> Workout.reset(setup.engine())
                                    engine.mode is TimerMode.ForTime -> Workout.stop()
                                    else -> Workout.pauseOrResume()
                                }
                            },
                            onCancel = { confirmCancel = true },
                        )
                    }
                    if (layout.twoColumn) content()
                    else Box(Modifier.fillMaxSize(), contentAlignment = Alignment.TopCenter) {
                        Box(Modifier.fillMaxHeight().let { m -> layout.maxContentWidth?.let { m.widthIn(max = it) } ?: m.fillMaxWidth() }) { content() }
                    }
                    TopRightControls(
                        soundOn = setup.soundOn,
                        onSound = { setup.soundOn = !setup.soundOn; setup.save(); Workout.soundOn = setup.soundOn },
                        onAbout = { showAbout = true },
                        modifier = Modifier.align(Alignment.TopEnd),
                    )
                }
                if (countInEnd != null) CountIn(max(0, ceil(countInEnd - now).toInt()), onCancel = { Workout.cancelCountIn() })
            }
        }
        // Over the whole screen, the system bars' area included.
        val flashAlpha by animateFloatAsState(if (flash) 0.85f else 0f, tween(350), label = "flash")
        if (flashAlpha > 0f) Box(Modifier.fillMaxSize().alpha(flashAlpha).background(palette.text))
        }

        if (confirmCancel) {
            AlertDialog(
                onDismissRequest = { confirmCancel = false },
                title = { Text(stringResource(R.string.cancel_workout_question)) },
                text = { Text(stringResource(R.string.cancel_workout_message)) },
                confirmButton = {
                    TextButton(onClick = {
                        confirmCancel = false
                        Workout.cancel()
                    }) { Text(stringResource(R.string.cancel_workout), color = Error) }
                },
                dismissButton = { TextButton(onClick = { confirmCancel = false }) { Text(stringResource(R.string.keep_going), color = palette.text) } },
                containerColor = palette.dialog,
                titleContentColor = palette.text,
                textContentColor = palette.textSecondary,
            )
        }
    }
}

@Composable
private fun Content(
    engine: WODTimerEngine,
    snapshot: Snapshot,
    setup: Setup,
    onChange: () -> Unit,
    onPrimary: () -> Unit,
    onCancel: () -> Unit,
) {
    val l = LocalLayout.current
    val primaryTitle = when (snapshot.state) {
        EngineState.IDLE -> stringResource(R.string.start)
        EngineState.RUNNING -> stringResource(if (engine.mode is TimerMode.ForTime) R.string.stop else R.string.pause)
        EngineState.PAUSED -> stringResource(R.string.resume)
        EngineState.FINISHED -> stringResource(R.string.reset)
    }
    val running = snapshot.state == EngineState.RUNNING || snapshot.state == EngineState.PAUSED
    val controls: @Composable (Modifier) -> Unit = { modifier ->
        Column(modifier, verticalArrangement = Arrangement.spacedBy(S.lg * l.spacing)) {
            PrimaryButton(primaryTitle, onPrimary)
            if (running) CancelButton(onCancel)
        }
    }

    if (l.twoColumn) {
        val gap = S.xxl * l.spacing
        when (snapshot.state) {
            // The header and Start on the left, the steppers on the right.
            EngineState.IDLE -> Row(Modifier.fillMaxSize().padding(bottom = S.lg * l.spacing), horizontalArrangement = Arrangement.spacedBy(gap)) {
                Column(Modifier.weight(1f).fillMaxHeight(), horizontalAlignment = Alignment.CenterHorizontally) {
                    Header(setup, onChange, stacksWhenNarrow = true)
                    Spacer(Modifier.weight(1f))
                    controls(Modifier.fillMaxWidth())
                }
                StepperColumn(setup, onChange, Modifier.weight(1f).fillMaxHeight())
            }
            // The readout takes everything left of the buttons.
            EngineState.RUNNING, EngineState.PAUSED -> Row(Modifier.fillMaxSize(), horizontalArrangement = Arrangement.spacedBy(gap)) {
                BoxWithConstraints(Modifier.weight(1f).fillMaxHeight(), contentAlignment = Alignment.Center) {
                    Readout(engine, snapshot, diameter = min(maxWidth.value, maxHeight.value), fill = true)
                }
                Column(
                    Modifier.width(l.controlsColumnWidth).fillMaxHeight()
                        // The sound and info buttons sit over the top of this column.
                        .padding(top = 44.dp, bottom = S.lg * l.spacing),
                    verticalArrangement = Arrangement.spacedBy(S.lg * l.spacing),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Spacer(Modifier.weight(1f))
                    PhaseLabel(engine, snapshot)
                    ProgressLabels(engine, snapshot)
                    Spacer(Modifier.weight(1f))
                    controls(Modifier.fillMaxWidth())
                }
            }
            EngineState.FINISHED -> Row(Modifier.fillMaxSize(), horizontalArrangement = Arrangement.spacedBy(gap), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.weight(1f), contentAlignment = Alignment.Center) { DoneView(engine, snapshot) }
                controls(Modifier.width(l.controlsColumnWidth))
            }
        }
        return
    }

    // One column: iOS's mainVStack, its spacers and its spacing included.
    Column(
        Modifier.fillMaxSize(),
        verticalArrangement = Arrangement.spacedBy(S.xxxl * l.spacing),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        if (snapshot.state == EngineState.IDLE) Header(setup, onChange, stacksWhenNarrow = false)
        Spacer(Modifier.weight(1f))
        when (snapshot.state) {
            EngineState.FINISHED -> DoneView(engine, snapshot)
            EngineState.RUNNING, EngineState.PAUSED -> Column(
                verticalArrangement = Arrangement.spacedBy(S.lg * l.spacing),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                PhaseLabel(engine, snapshot)
                BoxWithConstraints(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                    Readout(engine, snapshot, diameter = min(T.NUMERAL_LG * l.font * 4f, maxWidth.value - 24f))
                }
                ProgressLabels(engine, snapshot)
            }
            EngineState.IDLE -> {}
        }
        Spacer(Modifier.weight(1f))
        if (snapshot.state == EngineState.IDLE) Steppers(setup, onChange)
        Spacer(Modifier.weight(1f))
        controls(Modifier.fillMaxWidth().padding(horizontal = S.lg).padding(bottom = S.xxl * l.spacing))
    }
}

/** The mode switch and its help line. The top inset clears the sound and info buttons. */
@Composable
private fun Header(setup: Setup, onChange: () -> Unit, stacksWhenNarrow: Boolean) {
    val l = LocalLayout.current
    val p = LocalPalette.current
    Column(
        Modifier.fillMaxWidth().padding(top = 44.dp),
        verticalArrangement = Arrangement.spacedBy(S.md * l.spacing),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        ModeSwitch(setup.mode, stacksWhenNarrow) { setup.mode = it; onChange() }
        Text(
            stringResource(setup.mode.help),
            color = p.textTertiary,
            fontSize = (T.SM * l.font).sp,
            fontFamily = Mono,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = S.xl),
        )
    }
}

/**
 * Three buttons side by side. A name that doesn't fit shrinks with the others (to 0.7 of
 * its size) rather than wrapping or being cut; in two columns they stack instead, as iOS.
 */
@Composable
private fun ModeSwitch(selected: Mode, stacksWhenNarrow: Boolean, onSelect: (Mode) -> Unit) {
    val l = LocalLayout.current
    val p = LocalPalette.current
    val measurer = rememberTextMeasurer()
    val labels = Mode.entries.associateWith { stringResource(it.label) }
    val hPad = S.md * l.spacing
    val gap = S.sm
    BoxWithConstraints(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
        val style = TextStyle(fontFamily = Mono, fontWeight = FontWeight.SemiBold, fontSize = (T.BASE * l.font).sp)
        val density = LocalDensity.current
        val textWidth = Mode.entries.sumOf { with(density) { measurer.measure(labels.getValue(it), style).size.width.toDp().value.toDouble() } }.toFloat()
        val fixed = (hPad.value * 2 + 1) * Mode.entries.size + gap.value * (Mode.entries.size - 1)
        val fits = textWidth + fixed <= maxWidth.value
        val stack = stacksWhenNarrow && !fits
        val scale = if (fits || stack) 1f else ((maxWidth.value - fixed) / textWidth).coerceIn(0.7f, 1f)

        val button: @Composable (Mode) -> Unit = { m ->
            val on = m == selected
            Box(
                Modifier
                    .clip(RoundedCornerShape(Radius.sm))
                    .background(if (on) p.primary else p.card)
                    .clickable(role = Role.Tab) { if (!on) onSelect(m) }
                    .semantics { this.selected = on }
                    .padding(horizontal = hPad, vertical = S.sm),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    labels.getValue(m),
                    color = if (on) p.onPrimary else p.text,
                    fontSize = (T.BASE * l.font * scale).sp,
                    fontWeight = FontWeight.SemiBold,
                    fontFamily = Mono,
                    maxLines = 1,
                    softWrap = false,
                )
            }
        }
        if (stack) Column(verticalArrangement = Arrangement.spacedBy(gap), horizontalAlignment = Alignment.CenterHorizontally) { Mode.entries.forEach { button(it) } }
        else Row(horizontalArrangement = Arrangement.spacedBy(gap)) { Mode.entries.forEach { button(it) } }
    }
}

/**
 * The steppers in the right-hand column of two columns, at the largest scale (up to the
 * screen's) at which Intervals' three fit the column's height. Scrolls only if even the
 * smallest scale doesn't fit, in a very short window.
 */
@Composable
private fun StepperColumn(setup: Setup, onChange: () -> Unit, modifier: Modifier) {
    val l = LocalLayout.current
    BoxWithConstraints(modifier, contentAlignment = Alignment.Center) {
        // One stepper: its label and the gap under it, a row of 64-point buttons (or the
        // digits, 1.15 x 56 points) with 8 above and below, and the gap to the next.
        fun height(font: Float): Float {
            val spacing = if (font < 1) font else 1f + (font - 1f) * 0.6f
            val row = max(64f * spacing, 56f * font * 1.15f) + 16f
            return 3 * (14f * font * 1.15f + 16f * spacing + row) + 2 * 16f * spacing + 8f
        }
        var font = l.font
        while (font > 0.5f && height(font) > maxHeight.value) font -= 0.02f
        CompositionLocalProvider(LocalLayout provides Layout(l.width, l.height, fontOverride = font)) {
            Box(Modifier.verticalScroll(rememberScrollState())) { Steppers(setup, onChange) }
        }
    }
}

/**
 * All three modes' steppers, the hidden ones invisible: the block is as tall as Intervals'
 * three steppers whichever mode is chosen, so the screen doesn't jump on a switch (iOS).
 */
@Composable
private fun Steppers(setup: Setup, onChange: () -> Unit) {
    val l = LocalLayout.current
    Box(contentAlignment = Alignment.TopCenter) {
        val group: @Composable (Mode, @Composable ColumnScope.(Boolean) -> Unit) -> Unit = { mode, body ->
            val shown = setup.mode == mode
            Column(
                Modifier.alpha(if (shown) 1f else 0f).let { if (shown) it else it.clearAndSetSemantics { } },
                verticalArrangement = Arrangement.spacedBy(S.lg * l.spacing),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) { body(shown) }
        }
        group(Mode.EMOM) { on ->
            Stepper(stringResource(R.string.rounds), setup.emomRounds.toString(), wide = false, enabled = on,
                onMinus = { setup.emomRounds = (setup.emomRounds - 1).coerceIn(RoundsRange); onChange() },
                onPlus = { setup.emomRounds = (setup.emomRounds + 1).coerceIn(RoundsRange); onChange() })
            Stepper(stringResource(R.string.round_length), lengthString(setup.emomLength), wide = true, enabled = on,
                onMinus = { setup.emomLength = (setup.emomLength - 30).coerceIn(LengthRange); onChange() },
                onPlus = { setup.emomLength = (setup.emomLength + 30).coerceIn(LengthRange); onChange() })
        }
        group(Mode.INTERVALS) { on ->
            Stepper(stringResource(R.string.work_sec), setup.work.toString(), wide = false, enabled = on,
                onMinus = { setup.work = (setup.work - 1).coerceIn(WorkRange); onChange() },
                onPlus = { setup.work = (setup.work + 1).coerceIn(WorkRange); onChange() })
            Stepper(stringResource(R.string.rest_sec), setup.rest.toString(), wide = false, enabled = on,
                onMinus = { setup.rest = (setup.rest - 1).coerceIn(RestRange); onChange() },
                onPlus = { setup.rest = (setup.rest + 1).coerceIn(RestRange); onChange() })
            Stepper(stringResource(R.string.rounds), setup.intervalRounds.toString(), wide = false, enabled = on,
                onMinus = { setup.intervalRounds = (setup.intervalRounds - 1).coerceIn(IntervalRoundsRange); onChange() },
                onPlus = { setup.intervalRounds = (setup.intervalRounds + 1).coerceIn(IntervalRoundsRange); onChange() })
        }
        group(Mode.FOR_TIME) { on ->
            // One stepper for both "No cap" (0) and the cap: 0:30, 1:00 ... 60:00.
            Stepper(stringResource(R.string.time_cap), if (setup.cap == 0) stringResource(R.string.no_cap) else lengthString(setup.cap), wide = true, enabled = on,
                onMinus = { setup.cap = (setup.cap - 30).coerceIn(CapRange); onChange() },
                onPlus = { setup.cap = (setup.cap + 30).coerceIn(CapRange); onChange() })
        }
    }
}

/**
 * As SharedStepperView: the label, then − value + with lime buttons. The value takes what's
 * left between the buttons and shrinks to fit (to 0.4), so "No cap" never runs into them.
 */
@Composable
private fun Stepper(label: String, value: String, wide: Boolean, enabled: Boolean, onMinus: () -> Unit, onPlus: () -> Unit) {
    val l = LocalLayout.current
    val p = LocalPalette.current
    val gap = S.lg * l.spacing
    val buttonSize = S.xxxl * 2 * l.spacing
    val valueSize = T.NUMERAL_MD * l.font
    val minValueWidth = if (wide) max(buttonSize.value * 2, valueSize * 1.9f).dp + S.lg * 2 else buttonSize * 2
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(gap)) {
        Fit(label, T.SM * l.font, p.textSecondary, FontWeight.SemiBold)
        Row(Modifier.padding(vertical = S.sm), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(gap)) {
            RepeatButton("−", stringResource(R.string.decrease, label), buttonSize, valueSize * 0.75f, enabled, onMinus)
            Box(Modifier.weight(1f, fill = false).widthIn(min = minValueWidth), contentAlignment = Alignment.Center) {
                Fit(value, valueSize, p.text, FontWeight.Bold, minScale = 0.4f,
                    modifier = Modifier.padding(horizontal = if (wide) S.lg else 0.dp).semantics { contentDescription = "$label, $value" })
            }
            RepeatButton("+", stringResource(R.string.increase, label), buttonSize, valueSize * 0.75f, enabled, onPlus)
        }
    }
}

/** A step button that repeats while held, as iOS's steppers do with a long press. */
@Composable
private fun RepeatButton(symbol: String, description: String, size: Dp, fontSize: Float, enabled: Boolean, onStep: () -> Unit) {
    val p = LocalPalette.current
    val step by rememberUpdatedState(onStep)
    val scope = rememberCoroutineScope()
    Box(
        Modifier
            .size(size)
            .clip(RoundedCornerShape(Radius.md))
            .background(p.primary)
            .semantics {
                role = Role.Button
                contentDescription = description
                onClick { step(); true }
            }
            .pointerInput(enabled) {
                if (!enabled) return@pointerInput
                awaitEachGesture {
                    awaitFirstDown()
                    step()
                    // iOS: after 0.35 s, a step every 0.35 s, and every 0.12 s once held 0.8 s.
                    val repeat = scope.launch {
                        val start = System.currentTimeMillis()
                        delay(350)
                        while (true) {
                            step()
                            delay(if (System.currentTimeMillis() - start > 800) 120 else 350)
                        }
                    }
                    waitForUpOrCancellation()
                    repeat.cancel()
                }
            },
        contentAlignment = Alignment.Center,
    ) { Fit(symbol, fontSize, p.onPrimary, FontWeight.Bold) }
}

@Composable
private fun PhaseLabel(engine: WODTimerEngine, snapshot: Snapshot) {
    if (engine.mode !is TimerMode.Intervals) return
    val l = LocalLayout.current
    Fit(stringResource(if (snapshot.currentPhase == Phase.WORK) R.string.work else R.string.rest), T.LG * l.font, LocalPalette.current.textSecondary, FontWeight.Bold)
}

/**
 * The digits, and the Intervals ring around them. The digits are a quarter of the ring's
 * diameter, so the two scale together. With `fill` (two columns), EMOM and For Time digits,
 * with no ring to stay inside, take most of the width.
 */
@Composable
private fun Readout(engine: WODTimerEngine, snapshot: Snapshot, diameter: Float, fill: Boolean = false) {
    val p = LocalPalette.current
    val intervals = engine.mode as? TimerMode.Intervals
    // For Time counts up, floored so the shown time never runs ahead of the athlete.
    val shown = if (engine.mode is TimerMode.ForTime) floor(snapshot.elapsedTime) else snapshot.remainingTimeInPhase
    Box(contentAlignment = Alignment.Center) {
        if (intervals != null) {
            val work = snapshot.currentPhase == Phase.WORK
            PhaseRing(
                remaining = snapshot.remainingTimeInPhase,
                duration = (if (work) intervals.workSeconds else intervals.restSeconds).toDouble(),
                tint = if (work) p.primary else p.textSecondary,
                track = p.textTertiary.copy(alpha = 0.25f),
                diameter = diameter,
            )
        }
        val size = if (fill && intervals == null) diameter / 3.2f else diameter / 4f
        Fit(timeString(shown), size, p.text, FontWeight.Bold, minScale = 0.5f,
            modifier = Modifier.widthIn(max = diameter.dp))
    }
}

/** As SharedPhaseRing: drains clockwise from the top over the current phase. */
@Composable
private fun PhaseRing(remaining: Double, duration: Double, tint: Color, track: Color, diameter: Float) {
    val progress = if (duration > 0) (remaining / duration).coerceIn(0.0, 1.0).toFloat() else 0f
    val lineWidth = 6 * max(1f, diameter / 320)
    Canvas(Modifier.size(diameter.dp).clearAndSetSemantics { }) {
        val stroke = lineWidth.dp.toPx()
        val inset = stroke / 2
        val arcSize = Size(size.width - stroke, size.height - stroke)
        val topLeft = Offset(inset, inset)
        drawArc(track, 0f, 360f, false, topLeft, arcSize, style = Stroke(stroke))
        drawArc(tint, -90f, 360f * progress, false, topLeft, arcSize, style = Stroke(stroke, cap = StrokeCap.Round))
    }
}

/** The round line and its context, each on one line, shrinking to fit rather than wrapping. */
@Composable
private fun ProgressLabels(engine: WODTimerEngine, snapshot: Snapshot) {
    val l = LocalLayout.current
    val p = LocalPalette.current
    when (val m = engine.mode) {
        // No rounds in For Time: the cap as context when one is set.
        is TimerMode.ForTime -> m.capSeconds?.let {
            Fit(stringResource(R.string.cap, lengthString(it)), T.LG * l.font, p.textSecondary, FontWeight.SemiBold, minScale = 0.5f)
        }
        else -> {
            Fit(stringResource(R.string.round_of, snapshot.currentRound, engine.rounds), T.LG * l.font, p.textSecondary, FontWeight.SemiBold, minScale = 0.5f)
            if (m is TimerMode.Intervals) {
                Fit(stringResource(R.string.time_left, timeString(snapshot.remainingTime)), T.SM * l.font, p.textTertiary, FontWeight.SemiBold, minScale = 0.5f)
            }
        }
    }
}

/** As SharedDoneView. */
@Composable
private fun DoneView(engine: WODTimerEngine, snapshot: Snapshot) {
    val l = LocalLayout.current
    val p = LocalPalette.current
    val line = if (engine.mode is TimerMode.ForTime) stringResource(R.string.finished_in, timeString(floor(snapshot.elapsedTime)))
    else pluralStringResource(R.plurals.completed_rounds, engine.rounds, engine.rounds)
    Column(
        Modifier.padding(vertical = S.xxl * l.spacing).semantics(mergeDescendants = true) { },
        verticalArrangement = Arrangement.spacedBy(S.xxl * l.spacing),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        CheckmarkCircle(64 * l.font, p.primary, p.background)
        Fit(stringResource(R.string.done), T.XXL * l.font, p.text, FontWeight.Bold)
        Fit(line, T.BASE * l.font, p.textSecondary, minScale = 0.5f)
    }
}

/** SF Symbols' checkmark.circle.fill: a filled circle with the check cut out of it. */
@Composable
private fun CheckmarkCircle(diameter: Float, fill: Color, check: Color) {
    Canvas(Modifier.size(diameter.dp)) {
        val d = size.width
        drawCircle(fill, radius = d / 2)
        val path = Path().apply {
            moveTo(d * 0.29f, d * 0.52f)
            lineTo(d * 0.44f, d * 0.67f)
            lineTo(d * 0.71f, d * 0.34f)
        }
        drawPath(path, check, style = Stroke(d * 0.085f, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

/** The 10-second count-in, over everything, as iOS's countdownOverlay. */
@Composable
private fun CountIn(remaining: Int, onCancel: () -> Unit) {
    val l = LocalLayout.current
    val countdownLabel = stringResource(R.string.countdown_seconds, remaining)
    val p = LocalPalette.current
    if (remaining <= 0) return
    Column(
        Modifier.fillMaxSize().background(p.background).semantics(mergeDescendants = true) { contentDescription = countdownLabel },
        verticalArrangement = Arrangement.spacedBy(S.lg * l.spacing, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Fit(stringResource(R.string.get_ready), T.LG * l.font, p.textSecondary, FontWeight.SemiBold)
        Fit(remaining.toString(), T.NUMERAL_LG * l.font, p.text, FontWeight.Bold)
        Box(
            Modifier.padding(top = S.xl * l.spacing).padding(horizontal = S.xxxl)
                .let { m -> l.maxContentWidth?.let { m.widthIn(max = it) } ?: m }
        ) { CancelButton(onCancel) }
    }
}

@Composable
private fun PrimaryButton(title: String, onClick: () -> Unit) {
    val l = LocalLayout.current
    val p = LocalPalette.current
    Box(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Radius.md))
            .background(p.primary)
            .clickable(role = Role.Button, onClick = onClick)
            .padding(vertical = S.md * l.spacing, horizontal = S.xl),
        contentAlignment = Alignment.Center,
    ) { Fit(title, T.XXL * l.font, p.onPrimary, FontWeight.Bold, minScale = 0.5f) }
}

@Composable
private fun CancelButton(onClick: () -> Unit) {
    val l = LocalLayout.current
    Box(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(Radius.sm))
            .background(Error)
            .clickable(role = Role.Button, onClickLabel = stringResource(R.string.stops_workout), onClick = onClick)
            .padding(vertical = S.sm * l.spacing, horizontal = S.xl),
        contentAlignment = Alignment.Center,
    ) { Fit(stringResource(R.string.cancel), T.LG * l.font, OnError, FontWeight.SemiBold, minScale = 0.5f) }
}

/** The sound switch and About, top right, as iOS: 44-point targets, tertiary icons. */
@Composable
private fun TopRightControls(soundOn: Boolean, onSound: () -> Unit, onAbout: () -> Unit, modifier: Modifier) {
    val p = LocalPalette.current
    val haptic = LocalHapticFeedback.current
    Row(modifier, horizontalArrangement = Arrangement.spacedBy(S.md)) {
        IconButton(stringResource(if (soundOn) R.string.mute_sound else R.string.unmute_sound), {
            onSound()
            haptic.performHapticFeedback(if (soundOn) HapticFeedbackType.ToggleOff else HapticFeedbackType.ToggleOn)
        }) { SpeakerIcon(soundOn, p.textTertiary) }
        IconButton(stringResource(R.string.about), onAbout) { InfoIcon(p.textTertiary) }
    }
}

@Composable
private fun IconButton(description: String, onClick: () -> Unit, icon: @Composable () -> Unit) {
    Box(
        Modifier.size(44.dp).clip(RoundedCornerShape(Radius.sm))
            .clickable(role = Role.Button, onClick = onClick)
            .semantics { contentDescription = description },
        contentAlignment = Alignment.Center,
    ) { icon() }
}

/** speaker.wave.2 and speaker.slash, drawn: no icon font in the app. */
@Composable
private fun SpeakerIcon(on: Boolean, color: Color) {
    Canvas(Modifier.size(22.dp)) {
        val w = size.width
        val line = Stroke(w * 0.07f, cap = StrokeCap.Round, join = StrokeJoin.Round)
        val body = Path().apply {
            moveTo(w * 0.10f, w * 0.38f); lineTo(w * 0.26f, w * 0.38f); lineTo(w * 0.48f, w * 0.18f)
            lineTo(w * 0.48f, w * 0.82f); lineTo(w * 0.26f, w * 0.62f); lineTo(w * 0.10f, w * 0.62f); close()
        }
        drawPath(body, color, style = line)
        if (on) {
            drawArc(color, -45f, 90f, false, Offset(w * 0.40f, w * 0.30f), Size(w * 0.40f, w * 0.40f), style = line)
            drawArc(color, -50f, 100f, false, Offset(w * 0.34f, w * 0.14f), Size(w * 0.72f, w * 0.72f), style = line)
        } else {
            drawLine(color, Offset(w * 0.08f, w * 0.08f), Offset(w * 0.92f, w * 0.92f), w * 0.07f, StrokeCap.Round)
        }
    }
}

/** info.circle, drawn. */
@Composable
private fun InfoIcon(color: Color) {
    Canvas(Modifier.size(22.dp)) {
        val w = size.width
        drawCircle(color, radius = w * 0.44f, style = Stroke(w * 0.07f))
        drawCircle(color, radius = w * 0.055f, center = Offset(w / 2, w * 0.30f), style = Fill)
        drawLine(color, Offset(w / 2, w * 0.45f), Offset(w / 2, w * 0.72f), w * 0.08f, StrokeCap.Round)
    }
}

/** As iOS's About sheet, without the App Store links to the other apps. */
@Composable
private fun About(onDone: () -> Unit) {
    val p = LocalPalette.current
    val context = LocalContext.current
    val uri = LocalUriHandler.current
    val info = remember { context.packageManager.getPackageInfo(context.packageName, 0) }
    val versionLine = stringResource(R.string.version, info.versionName ?: "", info.longVersionCode.toString())
    val link: @Composable (String, String) -> Unit = { title, url ->
        Text(title, color = p.textTertiary, fontSize = T.SM.sp, fontFamily = Mono,
            modifier = Modifier.clickable(role = Role.Button) { runCatching { uri.openUri(url) } }.padding(4.dp))
    }
    Column(
        Modifier.fillMaxSize().background(p.background).safeDrawingPadding().padding(horizontal = S.lg),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(S.xxl),
    ) {
        Column(Modifier.padding(top = S.xxl), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(S.lg)) {
            Text("WODrounds", color = p.text, fontSize = T.XL.sp, fontWeight = FontWeight.Bold, fontFamily = Mono)
            Text(versionLine, color = p.textSecondary, fontSize = T.SM.sp, fontFamily = Mono)
        }
        Text(
            stringResource(R.string.about_privacy),
            color = p.textSecondary, fontSize = T.BASE.sp, fontFamily = Mono, textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = S.lg),
        )
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(S.sm)) {
            // The user sees the whole mail before anything is sent, as on iOS.
            val subject = android.net.Uri.encode("WODrounds ${info.versionName} feedback")
            val body = android.net.Uri.encode("\n\n\n--\nWODrounds ${info.versionName} (${info.longVersionCode})\nAndroid ${Build.VERSION.RELEASE}")
            link(stringResource(R.string.send_feedback), "mailto:support@iamjarl.com?subject=$subject&body=$body")
            link(stringResource(R.string.support), "https://wodrounds.iamjarl.com/support")
            link(stringResource(R.string.privacy_policy), "https://wodrounds.iamjarl.com/privacy")
        }
        Spacer(Modifier.weight(1f))
        Box(
            Modifier.fillMaxWidth().padding(bottom = S.xxl).clip(RoundedCornerShape(Radius.md)).background(p.primary)
                .clickable(role = Role.Button, onClick = onDone).padding(vertical = S.md),
            contentAlignment = Alignment.Center,
        ) { Text(stringResource(R.string.done), color = p.onPrimary, fontSize = T.BASE.sp, fontWeight = FontWeight.SemiBold, fontFamily = Mono) }
    }
}

/** One line of mono text that shrinks to fit (to minScale) instead of wrapping, as iOS's minimumScaleFactor. */
@Composable
private fun Fit(
    text: String,
    size: Float,
    color: Color,
    weight: FontWeight = FontWeight.Normal,
    minScale: Float = 0.7f,
    modifier: Modifier = Modifier,
) {
    BasicText(
        text = text,
        modifier = modifier,
        // A tight line, as SF Mono's: JetBrains Mono's own is 1.32 of the size, which made a
        // stepper's digits taller than its buttons and the steppers taller than on iOS.
        style = TextStyle(
            color = color, fontSize = size.sp, fontWeight = weight, fontFamily = Mono, textAlign = TextAlign.Center,
            lineHeight = 1.15.em, lineHeightStyle = LineHeightStyle(LineHeightStyle.Alignment.Center, LineHeightStyle.Trim.Both),
        ),
        overflow = TextOverflow.Ellipsis,
        softWrap = false,
        maxLines = 1,
        autoSize = TextAutoSize.StepBased(minFontSize = (size * minScale).sp, maxFontSize = size.sp, stepSize = 0.5.sp),
    )
}
