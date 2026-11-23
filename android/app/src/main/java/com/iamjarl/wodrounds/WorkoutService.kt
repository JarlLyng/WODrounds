package com.iamjarl.wodrounds

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import com.iamjarl.wodrounds.engine.EngineState
import com.iamjarl.wodrounds.engine.TimerMode
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.max

/**
 * Keeps a workout going with the screen off: ticks the engine ten times a second, plays the
 * cues, and shows the time in an ongoing notification. A foreground service of type
 * specialUse: a workout timer is none of Android's named types (it plays short cues, not media,
 * and reads no sensors, as the health type requires). The manifest gives Play the reason. It
 * starts on the user's Start and stops itself on Done or Cancel.
 */
class WorkoutService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var cues: Cues
    private var lastNotified = ""
    // With the screen off a phone may pause the CPU between sounds, and the tick with it.
    // A partial wake lock keeps the CPU (not the screen) running for the workout only, as
    // media players hold one while they play. Capped at 3 hours, released on Done or Cancel.
    private var wakeLock: PowerManager.WakeLock? = null

    private val tick = object : Runnable {
        override fun run() {
            step()
            if (Workout.isActive) handler.postDelayed(this, 100)
        }
    }

    override fun onCreate() {
        super.onCreate()
        cues = Cues(this)
        val channel = NotificationChannel(CHANNEL, "Workout", NotificationManager.IMPORTANCE_LOW).apply {
            description = "The time and round while a workout runs"
            setShowBadge(false)
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        ServiceCompat.startForeground(this, NOTIFICATION, notification(text()), ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
        cues.reset()
        if (wakeLock?.isHeld != true) {
            wakeLock = getSystemService(PowerManager::class.java)
                .newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "WODrounds:workout")
                .apply { setReferenceCounted(false); acquire(3 * 60 * 60 * 1000L) }
        }
        handler.removeCallbacks(tick)
        handler.post(tick)
        // A workout can't be rebuilt after the process is gone, so don't restart empty.
        return START_NOT_STICKY
    }

    private fun step() {
        val now = clock()
        Workout.countInEnd?.let { end ->
            if (now >= end) {
                Workout.countInOver(end)
                cues.countInEnded(Workout.soundOn)
            }
        }
        val engine = Workout.engine
        if (engine.state == EngineState.RUNNING) {
            engine.tick(now)
            if (engine.state == EngineState.FINISHED) {
                cues.finished(Workout.soundOn)
                Workout.changed()
            } else {
                cues.tick(engine.snapshot(now), engine.mode, engine.rounds, Workout.soundOn)
            }
        }
        if (!Workout.isActive) {
            // Done or Cancel: let "You did it" play out, then go.
            handler.postDelayed({ if (!Workout.isActive) finish() }, 3000)
            return
        }
        val text = text()
        if (text != lastNotified) {
            lastNotified = text
            getSystemService(NotificationManager::class.java).notify(NOTIFICATION, notification(text))
        }
    }

    private fun releaseWakeLock() {
        runCatching { if (wakeLock?.isHeld == true) wakeLock?.release() }
        wakeLock = null
    }

    private fun finish() {
        releaseWakeLock()
        ServiceCompat.stopForeground(this, ServiceCompat.STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    /** "EMOM · Round 3 / 10 · 00:42", as the screen shows it. */
    private fun text(): String {
        val now = clock()
        Workout.countInEnd?.let { return "Get ready · ${max(0, ceil(it - now).toInt())}" }
        val e = Workout.engine
        val s = e.snapshot(now)
        val paused = if (s.state == EngineState.PAUSED) " · Paused" else ""
        return when (val m = e.mode) {
            is TimerMode.Emom -> "EMOM · Round ${s.currentRound} / ${e.rounds} · ${time(s.remainingTimeInPhase)}$paused"
            is TimerMode.Intervals -> "${if (s.currentPhase == com.iamjarl.wodrounds.engine.Phase.WORK) "Work" else "Rest"} · Round ${s.currentRound} / ${e.rounds} · ${time(s.remainingTimeInPhase)}$paused"
            is TimerMode.ForTime -> "For Time · ${time(floor(s.elapsedTime))}${m.capSeconds?.let { " / cap " + time(it.toDouble()) } ?: ""}$paused"
        }
    }

    private fun time(seconds: Double): String {
        val t = max(0, ceil(seconds).toInt())
        return "%02d:%02d".format(t / 60, t % 60)
    }

    private fun notification(text: String): Notification {
        val open = PendingIntent.getActivity(this, 0, Workout.openApp(this), PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        return NotificationCompat.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_timer)
            .setContentTitle("WODrounds")
            .setContentText(text)
            .setContentIntent(open)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_STOPWATCH)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        releaseWakeLock()
        cues.release()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        private const val CHANNEL = "workout"
        private const val NOTIFICATION = 1

        fun start(context: Context) {
            ContextCompat.startForegroundService(context, Intent(context, WorkoutService::class.java))
        }
    }
}
