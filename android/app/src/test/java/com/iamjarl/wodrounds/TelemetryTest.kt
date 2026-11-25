package com.iamjarl.wodrounds

import io.sentry.SentryEvent
import io.sentry.protocol.App
import io.sentry.protocol.Device
import io.sentry.protocol.User
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.util.Date

class TelemetryTest {

    @Test
    fun anEventLeavesWithTheSharedUserAndNoDeviceIdentifiers() {
        val event = SentryEvent().apply {
            user = User().apply { id = "a-real-installation-id"; email = "x@example.com" }
            contexts.setDevice(Device().apply { id = "device-id"; bootTime = Date(); model = "SM-A176B" })
            contexts.setApp(App().apply { deviceAppHash = "hash"; appVersion = "0.1-trial" })
        }
        val out = Telemetry.anonymize(event)
        assertEquals(Telemetry.ANONYMOUS_USER, out.user?.id)
        assertNull(out.user?.email)
        assertNull(out.contexts.device?.id)
        assertNull(out.contexts.device?.bootTime)
        assertNull(out.contexts.app?.deviceAppHash)
        // Coarse facts stay, so crashes can still be told apart by model and version.
        assertEquals("SM-A176B", out.contexts.device?.model)
        assertEquals("0.1-trial", out.contexts.app?.appVersion)
    }
}
