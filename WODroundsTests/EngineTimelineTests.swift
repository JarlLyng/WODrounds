//
//  EngineTimelineTests.swift
//  WODroundsTests
//
//  Runs the shared timelines in test-fixtures/engine-timelines.json against the Swift
//  engine. The Kotlin port in android/ runs the same file, so a change to either engine
//  that the other doesn't share fails one of the two suites.
//

import Foundation
import Testing
@testable import WODrounds

struct EngineTimelineTests {

    private static let fixtureURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("test-fixtures/engine-timelines.json")

    private static func cases() throws -> [[String: Any]] {
        let data = try Data(contentsOf: fixtureURL)
        let doc = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try #require(doc["cases"] as? [[String: Any]])
    }

    private static func makeEngine(_ mode: [String: Any]) -> WODTimerEngine {
        switch mode["type"] as? String {
        case "emom":
            let r = mode["rounds"] as? Int, s = mode["secondsPerRound"] as? Int
            if r == nil && s == nil { return WODTimerEngine() }
            return WODTimerEngine(emomRounds: r ?? 1, secondsPerRound: s ?? 60)
        case "intervals":
            return WODTimerEngine(workSeconds: mode["workSeconds"] as? Int ?? 0,
                                  restSeconds: mode["restSeconds"] as? Int ?? 0,
                                  rounds: mode["rounds"] as? Int ?? 0)
        default:
            return WODTimerEngine(forTimeCapSeconds: mode["capSeconds"] as? Int)
        }
    }

    private static func name(_ s: WODTimerEngineState) -> String {
        switch s { case .idle: "idle"; case .running: "running"; case .paused: "paused"; case .finished: "finished" }
    }

    private static func number(_ any: Any?) -> Double? { (any as? NSNumber)?.doubleValue }

    @Test("The Swift engine reports every shared timeline as written")
    func sharedTimelines() throws {
        let cases = try Self.cases()
        #expect(cases.count >= 20)
        for c in cases {
            let label = c["name"] as? String ?? "?"
            var engine = Self.makeEngine(c["mode"] as? [String: Any] ?? [:])
            let e = c["engine"] as? [String: Any] ?? [:]
            #expect(engine.rounds == e["rounds"] as? Int, "\(label): rounds")
            #expect(engine.workSeconds == e["workSeconds"] as? Int, "\(label): workSeconds")
            #expect(engine.restSeconds == e["restSeconds"] as? Int, "\(label): restSeconds")
            #expect(engine.forTimeCapSeconds == e["capSeconds"] as? Int, "\(label): capSeconds")
            #expect(abs(engine.totalDurationSeconds - (Self.number(e["totalDurationSeconds"]) ?? -1)) < 1e-6, "\(label): total")

            for event in c["events"] as? [[String: Any]] ?? [] {
                let t = Self.number(event["t"]) ?? 0
                let now = Date(timeIntervalSinceReferenceDate: t)
                if let action = event["do"] as? String {
                    switch action {
                    case "start": engine.start(now: now)
                    case "pause": engine.pause(now: now)
                    case "resume": engine.resume(now: now)
                    case "finish": engine.finish(now: now)
                    case "tick": engine.tick(now: now)
                    case "reset": engine.reset()
                    default: Issue.record("\(label): unknown action \(action)")
                    }
                    continue
                }
                let x = try #require(event["expect"] as? [String: Any], "\(label) @\(t): no expectation; run scripts/engine-fixtures/generate.sh")
                let s = engine.snapshot(now: now)
                let at = "\(label) @\(t)"
                #expect(Self.name(engine.state) == x["engineState"] as? String, "\(at): engine state")
                #expect(Self.name(s.state) == x["state"] as? String, "\(at): state")
                #expect(abs(s.remainingTime - (Self.number(x["remainingTime"]) ?? -1)) < 1e-6, "\(at): remainingTime")
                #expect(abs(s.elapsedTime - (Self.number(x["elapsedTime"]) ?? -1)) < 1e-6, "\(at): elapsedTime")
                #expect(s.currentRound == x["currentRound"] as? Int, "\(at): currentRound")
                #expect(s.secondsIntoCurrentMinute == x["secondsIntoCurrentMinute"] as? Int, "\(at): secondsIntoCurrentMinute")
                #expect((s.currentPhase == .work ? "work" : "rest") == x["currentPhase"] as? String, "\(at): phase")
                #expect(abs(s.remainingTimeInPhase - (Self.number(x["remainingTimeInPhase"]) ?? -1)) < 1e-6, "\(at): remainingTimeInPhase")
                let end = engine.effectiveWorkoutEndDate(now: now)?.timeIntervalSinceReferenceDate
                let expectedEnd = Self.number(x["effectiveEnd"])
                #expect((end == nil) == (expectedEnd == nil), "\(at): effectiveEnd presence")
                if let end, let expectedEnd { #expect(abs(end - expectedEnd) < 1e-6, "\(at): effectiveEnd") }
            }
        }
    }
}
