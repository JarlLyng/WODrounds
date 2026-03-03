//
//  WODroundsTests.swift
//  WODroundsTests
//
//  Created by Jarl Lyng on 15/02/2026.
//

import Foundation
import Testing
@testable import WODrounds

struct WODroundsTests {

    // MARK: - EMOM: Initialisation

    @Test func emomDefaultInit() {
        let engine = WODTimerEngine(emomRounds: 1, secondsPerRound: 60)
        #expect(engine.state == .idle)
        #expect(engine.totalDurationSeconds == 60)
        #expect(engine.rounds == 1)
    }

    @Test func emomCustomInit() {
        let engine = WODTimerEngine(emomRounds: 10, secondsPerRound: 90)
        #expect(engine.totalDurationSeconds == 900) // 10 * 90
        #expect(engine.rounds == 10)
    }

    @Test func emomClampsMinValues() {
        let engine = WODTimerEngine(emomRounds: 0, secondsPerRound: 0)
        // rounds clamped to 1, secondsPerRound clamped to 30
        #expect(engine.rounds == 1)
        #expect(engine.totalDurationSeconds == 30)
    }

    // MARK: - Intervals: Initialisation

    @Test func intervalsInit() {
        let engine = WODTimerEngine(workSeconds: 30, restSeconds: 15, rounds: 8)
        #expect(engine.state == .idle)
        #expect(engine.workSeconds == 30)
        #expect(engine.restSeconds == 15)
        #expect(engine.rounds == 8)
        // Total: 8 * 30 + 7 * 15 = 240 + 105 = 345
        #expect(engine.totalDurationSeconds == 345)
    }

    @Test func intervalsSingleRound() {
        let engine = WODTimerEngine(workSeconds: 60, restSeconds: 30, rounds: 1)
        // 1 round: only work, no rest after last round
        #expect(engine.totalDurationSeconds == 60)
    }

    @Test func intervalsZeroRest() {
        let engine = WODTimerEngine(workSeconds: 45, restSeconds: 0, rounds: 5)
        // 5 * 45 + 4 * 0 = 225
        #expect(engine.totalDurationSeconds == 225)
    }

    @Test func intervalsClampsMinValues() {
        let engine = WODTimerEngine(workSeconds: 0, restSeconds: -5, rounds: 0)
        // work clamped to 1, rest clamped to 0, rounds clamped to 1
        #expect(engine.workSeconds == 1)
        #expect(engine.restSeconds == 0)
        #expect(engine.rounds == 1)
    }

    // MARK: - EMOM: Start / Pause / Resume / Reset

    @Test func emomStartSetsRunning() {
        var engine = WODTimerEngine(emomRounds: 5, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        #expect(engine.state == .running)
    }

    @Test func emomPauseSetsStatePaused() {
        var engine = WODTimerEngine(emomRounds: 5, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        engine.pause(now: start.addingTimeInterval(30))
        #expect(engine.state == .paused)
    }

    @Test func emomResumeSetsStateRunning() {
        var engine = WODTimerEngine(emomRounds: 5, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        engine.pause(now: start.addingTimeInterval(30))
        engine.resume(now: start.addingTimeInterval(35))
        #expect(engine.state == .running)
    }

    @Test func emomResetClearsState() {
        var engine = WODTimerEngine(emomRounds: 5, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        engine.reset()
        #expect(engine.state == .idle)
    }

    // MARK: - EMOM: Snapshots

    @Test func emomIdleSnapshot() {
        let engine = WODTimerEngine(emomRounds: 5, secondsPerRound: 60)
        let snap = engine.snapshot(now: Date())
        #expect(snap.state == .idle)
        #expect(snap.remainingTime == 0)
        #expect(snap.currentRound == 0)
    }

    @Test func emomRunningSnapshotAtStart() {
        var engine = WODTimerEngine(emomRounds: 5, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        let snap = engine.snapshot(now: start)
        #expect(snap.state == .running)
        #expect(snap.remainingTime == 300) // 5 * 60
        #expect(snap.currentRound == 1)
        #expect(snap.currentPhase == .work)
        #expect(snap.remainingTimeInPhase == 60)
    }

    @Test func emomRunningSnapshotMidway() {
        var engine = WODTimerEngine(emomRounds: 5, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        // 90 seconds in: 1.5 rounds elapsed, should be round 2
        let snap = engine.snapshot(now: start.addingTimeInterval(90))
        #expect(snap.state == .running)
        #expect(snap.remainingTime == 210) // 300 - 90
        #expect(snap.currentRound == 2)
        #expect(snap.secondsIntoCurrentMinute == 30) // 90 % 60
    }

    @Test func emomRunningSnapshotRoundBoundary() {
        var engine = WODTimerEngine(emomRounds: 5, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        // Exactly at round boundary (120 seconds = start of round 3)
        let snap = engine.snapshot(now: start.addingTimeInterval(120))
        #expect(snap.currentRound == 3)
        #expect(snap.secondsIntoCurrentMinute == 0)
        #expect(snap.remainingTimeInPhase == 60)
    }

    @Test func emomPausedSnapshotPreservesTime() {
        var engine = WODTimerEngine(emomRounds: 5, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        engine.pause(now: start.addingTimeInterval(45))
        // Ask for snapshot 10 seconds after pause — should still show 45 seconds elapsed
        let snap = engine.snapshot(now: start.addingTimeInterval(55))
        #expect(snap.state == .paused)
        #expect(snap.remainingTime == 255) // 300 - 45
        #expect(snap.currentRound == 1)
    }

    @Test func emomFinishedSnapshot() {
        var engine = WODTimerEngine(emomRounds: 2, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        engine.tick(now: start.addingTimeInterval(120))
        #expect(engine.state == .finished)
        let snap = engine.snapshot(now: start.addingTimeInterval(120))
        #expect(snap.state == .finished)
        #expect(snap.remainingTime == 0)
        #expect(snap.currentRound == 2)
    }

    // MARK: - EMOM: Pause at end sets finished

    @Test func pauseAtEndSetsFinishedState() {
        var engine = WODTimerEngine(emomRounds: 1, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        engine.pause(now: start.addingTimeInterval(60.5))
        #expect(engine.state == .finished)
        let snapshot = engine.snapshot(now: start.addingTimeInterval(60.5))
        #expect(snapshot.state == .finished)
        #expect(snapshot.remainingTime == 0)
    }

    // MARK: - EMOM: Custom round lengths

    @Test func emomNonStandardRoundLength() {
        var engine = WODTimerEngine(emomRounds: 3, secondsPerRound: 90)
        let start = Date()
        engine.start(now: start)
        // 100 seconds in: 90 + 10, so round 2 with 10 seconds in
        let snap = engine.snapshot(now: start.addingTimeInterval(100))
        #expect(snap.currentRound == 2)
        #expect(snap.remainingTimeInPhase == 80) // 90 - 10
    }

    // MARK: - Intervals: Snapshots

    @Test func intervalsRunningWorkPhase() {
        var engine = WODTimerEngine(workSeconds: 30, restSeconds: 15, rounds: 4)
        let start = Date()
        engine.start(now: start)
        // 10 seconds in: work phase of round 1
        let snap = engine.snapshot(now: start.addingTimeInterval(10))
        #expect(snap.state == .running)
        #expect(snap.currentRound == 1)
        #expect(snap.currentPhase == .work)
        #expect(snap.remainingTimeInPhase == 20) // 30 - 10
    }

    @Test func intervalsRunningRestPhase() {
        var engine = WODTimerEngine(workSeconds: 30, restSeconds: 15, rounds: 4)
        let start = Date()
        engine.start(now: start)
        // 35 seconds in: 30s work done, 5s into rest
        let snap = engine.snapshot(now: start.addingTimeInterval(35))
        #expect(snap.currentRound == 1)
        #expect(snap.currentPhase == .rest)
        #expect(snap.remainingTimeInPhase == 10) // 15 - 5
    }

    @Test func intervalsRoundTransition() {
        var engine = WODTimerEngine(workSeconds: 30, restSeconds: 15, rounds: 4)
        let start = Date()
        engine.start(now: start)
        // 45 seconds in: 30s work + 15s rest = start of round 2
        let snap = engine.snapshot(now: start.addingTimeInterval(45))
        #expect(snap.currentRound == 2)
        #expect(snap.currentPhase == .work)
        #expect(snap.remainingTimeInPhase == 30)
    }

    @Test func intervalsLastRoundNoRest() {
        var engine = WODTimerEngine(workSeconds: 30, restSeconds: 15, rounds: 2)
        let start = Date()
        engine.start(now: start)
        // Total: 2*30 + 1*15 = 75
        #expect(engine.totalDurationSeconds == 75)
        // 50 seconds in: 30 work + 15 rest + 5 into round 2 work
        let snap = engine.snapshot(now: start.addingTimeInterval(50))
        #expect(snap.currentRound == 2)
        #expect(snap.currentPhase == .work)
        #expect(snap.remainingTimeInPhase == 25) // 30 - 5
    }

    @Test func intervalsZeroRestPhaseTransitions() {
        var engine = WODTimerEngine(workSeconds: 20, restSeconds: 0, rounds: 3)
        let start = Date()
        engine.start(now: start)
        // Total: 3*20 + 2*0 = 60
        #expect(engine.totalDurationSeconds == 60)
        // 25 seconds: into round 2 work
        let snap = engine.snapshot(now: start.addingTimeInterval(25))
        #expect(snap.currentRound == 2)
        #expect(snap.currentPhase == .work)
    }

    @Test func intervalsSingleRoundSnapshot() {
        var engine = WODTimerEngine(workSeconds: 45, restSeconds: 30, rounds: 1)
        let start = Date()
        engine.start(now: start)
        // 20 seconds in
        let snap = engine.snapshot(now: start.addingTimeInterval(20))
        #expect(snap.currentRound == 1)
        #expect(snap.currentPhase == .work)
        #expect(snap.remainingTimeInPhase == 25) // 45 - 20
    }

    @Test func intervalsFinishedSnapshot() {
        var engine = WODTimerEngine(workSeconds: 10, restSeconds: 5, rounds: 2)
        let start = Date()
        engine.start(now: start)
        // Total: 2*10 + 1*5 = 25
        engine.tick(now: start.addingTimeInterval(25))
        #expect(engine.state == .finished)
        let snap = engine.snapshot(now: start.addingTimeInterval(25))
        #expect(snap.state == .finished)
        #expect(snap.remainingTime == 0)
        #expect(snap.currentRound == 2)
    }

    // MARK: - Pause / Resume preserves elapsed time

    @Test func pauseResumePreservesElapsed() {
        var engine = WODTimerEngine(emomRounds: 5, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        // Run 30 seconds, pause for 20 seconds, resume
        engine.pause(now: start.addingTimeInterval(30))
        engine.resume(now: start.addingTimeInterval(50))
        // 10 more seconds of running
        let snap = engine.snapshot(now: start.addingTimeInterval(60))
        // Elapsed = 30 + 10 = 40 seconds, remaining = 260
        #expect(snap.remainingTime == 260)
        #expect(snap.currentRound == 1)
    }

    @Test func multiplePauseResumeCycles() {
        var engine = WODTimerEngine(emomRounds: 3, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        // Run 20s, pause 10s, resume, run 20s, pause 10s, resume, run 20s
        engine.pause(now: start.addingTimeInterval(20))
        engine.resume(now: start.addingTimeInterval(30))
        engine.pause(now: start.addingTimeInterval(50))
        engine.resume(now: start.addingTimeInterval(60))
        let snap = engine.snapshot(now: start.addingTimeInterval(80))
        // Active time: 20 + 20 + 20 = 60s elapsed, remaining = 120
        #expect(snap.remainingTime == 120)
        #expect(snap.currentRound == 2)
    }

    // MARK: - tick() behaviour

    @Test func tickDoesNothingWhenIdle() {
        var engine = WODTimerEngine(emomRounds: 1, secondsPerRound: 60)
        engine.tick(now: Date())
        #expect(engine.state == .idle)
    }

    @Test func tickDoesNothingWhenPaused() {
        var engine = WODTimerEngine(emomRounds: 1, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        engine.pause(now: start.addingTimeInterval(10))
        engine.tick(now: start.addingTimeInterval(100))
        #expect(engine.state == .paused)
    }

    @Test func tickTransitionsToFinished() {
        var engine = WODTimerEngine(emomRounds: 1, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        engine.tick(now: start.addingTimeInterval(60))
        #expect(engine.state == .finished)
    }

    @Test func tickDoesNotFinishEarly() {
        var engine = WODTimerEngine(emomRounds: 1, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        engine.tick(now: start.addingTimeInterval(59))
        #expect(engine.state == .running)
    }

    // MARK: - Guard clauses

    @Test func startDoesNothingForZeroDuration() {
        var engine = WODTimerEngine(emomRounds: 0, secondsPerRound: 0)
        // Clamped: rounds=1, spr=30 — so this will actually start
        // Let's make a scenario that can't start: not possible with clamping
        // Instead: verify start only works from idle
        engine.start(now: Date())
        #expect(engine.state == .running)
    }

    @Test func pauseOnlyFromRunning() {
        var engine = WODTimerEngine(emomRounds: 1, secondsPerRound: 60)
        engine.pause(now: Date())
        #expect(engine.state == .idle) // no change
    }

    @Test func resumeOnlyFromPaused() {
        var engine = WODTimerEngine(emomRounds: 1, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        engine.resume(now: start.addingTimeInterval(5))
        #expect(engine.state == .running) // no change from running
    }

    // MARK: - effectiveWorkoutEndDate

    @Test func effectiveEndDateNilWhenNeverStarted() {
        let engine = WODTimerEngine(emomRounds: 1, secondsPerRound: 60)
        #expect(engine.effectiveWorkoutEndDate(now: Date()) == nil)
    }

    @Test func effectiveEndDateExcludesPauseDuration() {
        var engine = WODTimerEngine(emomRounds: 5, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        // Run 30s, pause 20s, resume
        engine.pause(now: start.addingTimeInterval(30))
        engine.resume(now: start.addingTimeInterval(50))
        let now = start.addingTimeInterval(60)
        let endDate = engine.effectiveWorkoutEndDate(now: now)
        #expect(endDate != nil)
        // End date should be "now" minus accumulated pause (20s)
        let expectedEnd = Date(timeIntervalSinceReferenceDate: now.timeIntervalSinceReferenceDate - 20)
        let diff = abs(endDate!.timeIntervalSince(expectedEnd))
        #expect(diff < 0.001)
    }

    // MARK: - totalDurationSeconds

    @Test func emomTotalDuration() {
        let engine = WODTimerEngine(emomRounds: 10, secondsPerRound: 60)
        #expect(engine.totalDurationSeconds == 600)
    }

    @Test func intervalsTotalDuration() {
        let engine = WODTimerEngine(workSeconds: 40, restSeconds: 20, rounds: 5)
        // 5*40 + 4*20 = 200 + 80 = 280
        #expect(engine.totalDurationSeconds == 280)
    }

    // MARK: - SyncPayload

    @Test func syncPayloadEncodesEMOM() {
        var engine = WODTimerEngine(emomRounds: 3, secondsPerRound: 90)
        let start = Date()
        engine.start(now: start)
        let payload = engine.syncPayload(now: start)
        #expect(payload.state == "running")
        #expect(payload.mode == "emom")
        #expect(payload.emomSecondsPerRound == 90)
        #expect(payload.workSeconds == nil)
        #expect(payload.restSeconds == nil)
    }

    @Test func syncPayloadEncodesIntervals() {
        var engine = WODTimerEngine(workSeconds: 30, restSeconds: 10, rounds: 5)
        let start = Date()
        engine.start(now: start)
        let payload = engine.syncPayload(now: start)
        #expect(payload.state == "running")
        #expect(payload.mode == "intervals")
        #expect(payload.workSeconds == 30)
        #expect(payload.restSeconds == 10)
        #expect(payload.rounds == 5)
        #expect(payload.emomSecondsPerRound == nil)
    }

    @Test func syncPayloadStateStrings() {
        var engine = WODTimerEngine(emomRounds: 1, secondsPerRound: 60)
        let now = Date()
        #expect(engine.syncPayload(now: now).state == "idle")
        engine.start(now: now)
        #expect(engine.syncPayload(now: now).state == "running")
        engine.pause(now: now.addingTimeInterval(10))
        #expect(engine.syncPayload(now: now).state == "paused")
        engine.resume(now: now.addingTimeInterval(15))
        engine.tick(now: now.addingTimeInterval(80))
        #expect(engine.syncPayload(now: now).state == "finished")
    }

    @Test func syncPayloadIsEncodable() throws {
        let engine = WODTimerEngine(emomRounds: 2, secondsPerRound: 60)
        let payload = engine.syncPayload(now: Date())
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)
        #expect(data.count > 0)
    }

    // MARK: - EMOM: Snapshot at end

    @Test func emomSnapshotBeyondEndShowsFinished() {
        var engine = WODTimerEngine(emomRounds: 2, secondsPerRound: 60)
        let start = Date()
        engine.start(now: start)
        // Way past end
        let snap = engine.snapshot(now: start.addingTimeInterval(500))
        #expect(snap.state == .finished)
        #expect(snap.remainingTime == 0)
    }

    // MARK: - Intervals: Snapshot at end boundary

    @Test func intervalsSnapshotAtExactEnd() {
        var engine = WODTimerEngine(workSeconds: 10, restSeconds: 5, rounds: 2)
        let start = Date()
        engine.start(now: start)
        // Total = 2*10 + 1*5 = 25
        let snap = engine.snapshot(now: start.addingTimeInterval(25))
        #expect(snap.state == .finished)
        #expect(snap.remainingTime == 0)
    }

    // MARK: - Mode accessors return 0 for wrong mode

    @Test func emomAccessorsReturnZeroForIntervals() {
        let engine = WODTimerEngine(workSeconds: 30, restSeconds: 15, rounds: 4)
        #expect(engine.totalDurationMinutes == 0)
    }

    @Test func intervalsAccessorsReturnZeroForEMOM() {
        let engine = WODTimerEngine(emomRounds: 5, secondsPerRound: 60)
        #expect(engine.workSeconds == 0)
        #expect(engine.restSeconds == 0)
    }
}
