package com.iamjarl.wodrounds

import android.content.Context
import io.sentry.Sentry
import io.sentry.SentryEvent
import io.sentry.SentryOptions
import io.sentry.android.core.SentryAndroid
import io.sentry.protocol.User

/*
 * Anonymous crash reports and crash-free sessions, sent to Sentry, as on iOS
 * (WODrounds/Telemetry.swift, docs/SENTRY.md). Anonymous is a recipe, not Sentry's default:
 * out of the box sentry-android sends a random installation ID as the user, as every
 * session's `did` and as the device's ID. Everything here keeps any ID on the device.
 */
object Telemetry {
    /** The one user every install reports as, the same as iOS. */
    const val ANONYMOUS_USER = "anonymous"

    fun start(context: Context) {
        val dsn = BuildConfig.SENTRY_DSN.trim()
        // No DSN (a local build without one), or one cut short: no Sentry at all.
        if (dsn.isEmpty() || !dsn.contains("://") || !dsn.contains("@")) return

        SentryAndroid.init(context) { o ->
            o.dsn = dsn
            o.environment = BuildConfig.SENTRY_ENVIRONMENT
            o.isSendDefaultPii = false
            // Crash reports and sessions only: no performance tracing, and nothing that watches
            // the screen (no screenshot or view hierarchy of the user's workout, no taps).
            o.tracesSampleRate = 0.0
            o.isAttachScreenshot = false
            o.isAttachViewHierarchy = false
            o.isEnableUserInteractionBreadcrumbs = false
            o.isEnableUserInteractionTracing = false
            o.isEnableAutoSessionTracking = true
            // Sessions carry `did`, the installation ID unless set; the shared user instead.
            o.distinctId = ANONYMOUS_USER
            o.beforeSend = SentryOptions.BeforeSendCallback { event, _ -> anonymize(event) }
        }
        // Before any event, so nothing falls back to the installation ID.
        Sentry.setUser(User().apply { id = ANONYMOUS_USER })
    }

    /**
     * One shared user, and no device or vendor ID, on every event. Also no boot time: the
     * exact moment a phone started, with its model, would tell one phone's reports from
     * another's across events.
     */
    fun anonymize(event: SentryEvent): SentryEvent {
        event.user = User().apply { id = ANONYMOUS_USER }
        event.contexts.device?.let {
            it.id = null
            it.bootTime = null
        }
        event.contexts.app?.deviceAppHash = null
        return event
    }
}
