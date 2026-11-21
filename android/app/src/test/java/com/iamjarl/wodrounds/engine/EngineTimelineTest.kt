package com.iamjarl.wodrounds.engine

import com.google.gson.JsonObject
import com.google.gson.JsonParser
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * Runs the shared timelines in test-fixtures/engine-timelines.json, the same file the
 * Swift suite (WODroundsTests/EngineTimelineTests.swift) runs. If both pass, the two
 * engines report the same state, round, phase and times at every step.
 */
class EngineTimelineTest {

    private val eps = 1e-6

    private fun cases(): List<JsonObject> {
        val path = System.getProperty("engineTimelines")
            ?: error("engineTimelines is not set; run through Gradle")
        val doc = JsonParser.parseReader(File(path).reader()).asJsonObject
        return doc.getAsJsonArray("cases").map { it.asJsonObject }
    }

    private fun JsonObject.int(key: String): Int? = get(key)?.takeUnless { it.isJsonNull }?.asInt
    private fun JsonObject.dbl(key: String): Double? = get(key)?.takeUnless { it.isJsonNull }?.asDouble
    private fun JsonObject.str(key: String): String? = get(key)?.takeUnless { it.isJsonNull }?.asString

    private fun makeEngine(mode: JsonObject): WODTimerEngine = when (mode.str("type")) {
        "emom" -> {
            val r = mode.int("rounds")
            val s = mode.int("secondsPerRound")
            if (r == null && s == null) WODTimerEngine.emom() else WODTimerEngine.emom(r ?: 1, s ?: 60)
        }
        "intervals" -> WODTimerEngine.intervals(mode.int("workSeconds")!!, mode.int("restSeconds")!!, mode.int("rounds")!!)
        else -> WODTimerEngine.forTime(mode.int("capSeconds"))
    }

    @Test
    fun theKotlinEngineReportsEverySharedTimelineAsWritten() {
        val cases = cases()
        assertTrue("expected the shared timelines", cases.size >= 20)
        var checks = 0
        for (c in cases) {
            val label = c.str("name")
            val engine = makeEngine(c.getAsJsonObject("mode"))
            val e = c.getAsJsonObject("engine")
            assertEquals("$label: rounds", e.int("rounds"), engine.rounds)
            assertEquals("$label: workSeconds", e.int("workSeconds"), engine.workSeconds)
            assertEquals("$label: restSeconds", e.int("restSeconds"), engine.restSeconds)
            assertEquals("$label: capSeconds", e.int("capSeconds"), engine.forTimeCapSeconds)
            assertEquals("$label: totalDurationMinutes", e.int("totalDurationMinutes"), engine.totalDurationMinutes)
            assertEquals("$label: total", e.dbl("totalDurationSeconds")!!, engine.totalDurationSeconds, eps)

            for (ev in c.getAsJsonArray("events").map { it.asJsonObject }) {
                val t = ev.dbl("t")!!
                when (ev.str("do")) {
                    "start" -> { engine.start(t); continue }
                    "pause" -> { engine.pause(t); continue }
                    "resume" -> { engine.resume(t); continue }
                    "finish" -> { engine.finish(t); continue }
                    "tick" -> { engine.tick(t); continue }
                    "reset" -> { engine.reset(); continue }
                    null -> Unit
                    else -> error("$label: unknown action ${ev.str("do")}")
                }
                val x = ev.getAsJsonObject("expect") ?: error("$label @$t: no expectation; run scripts/engine-fixtures/generate.sh")
                val s = engine.snapshot(t)
                val at = "$label @$t"
                assertEquals("$at: engine state", x.str("engineState"), engine.state.name.lowercase())
                assertEquals("$at: state", x.str("state"), s.state.name.lowercase())
                assertEquals("$at: remainingTime", x.dbl("remainingTime")!!, s.remainingTime, eps)
                assertEquals("$at: elapsedTime", x.dbl("elapsedTime")!!, s.elapsedTime, eps)
                assertEquals("$at: currentRound", x.int("currentRound"), s.currentRound)
                assertEquals("$at: secondsIntoCurrentMinute", x.int("secondsIntoCurrentMinute"), s.secondsIntoCurrentMinute)
                assertEquals("$at: phase", x.str("currentPhase"), s.currentPhase.name.lowercase())
                assertEquals("$at: remainingTimeInPhase", x.dbl("remainingTimeInPhase")!!, s.remainingTimeInPhase, eps)
                val end = engine.effectiveWorkoutEnd(t)
                val expectedEnd = x.dbl("effectiveEnd")
                if (expectedEnd == null) assertNull("$at: effectiveEnd", end)
                else assertEquals("$at: effectiveEnd", expectedEnd, end!!, eps)
                checks++
            }
        }
        assertTrue("expected hundreds of checks, ran $checks", checks > 400)
    }
}
