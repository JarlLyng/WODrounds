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

    @Test func example() async throws {
        // Placeholder for future tests.
    }

    /// Pause at or after end: engine.state and snapshot must be .finished (REVIEW.md anbefaling 1).
    @Test func pauseAtEndSetsFinishedState() async throws {
        var engine = WODTimerEngine(totalDurationMinutes: 1)
        let start = Date()
        engine.start(now: start)
        engine.pause(now: start.addingTimeInterval(60.5))
        #expect(engine.state == .finished)
        let snapshot = engine.snapshot(now: start.addingTimeInterval(60.5))
        #expect(snapshot.state == .finished)
        #expect(snapshot.remainingTime == 0)
    }
}
