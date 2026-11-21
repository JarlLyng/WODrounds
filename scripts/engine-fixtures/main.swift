//
//  Writes the expectations in test-fixtures/engine-timelines.json from the Swift engine
//  (Shared/WODTimerEngine.swift). The Kotlin port in android/ is tested against the same
//  file, so both engines must report the same thing at every `t`. Run generate.sh.
//

import Foundation

let path = CommandLine.arguments[1]
let data = try Data(contentsOf: URL(fileURLWithPath: path))
var doc = try JSONSerialization.jsonObject(with: data) as! [String: Any]

func r6(_ x: Double) -> Double { (x * 1_000_000).rounded() / 1_000_000 }
func name(_ s: WODTimerEngineState) -> String {
    switch s { case .idle: "idle"; case .running: "running"; case .paused: "paused"; case .finished: "finished" }
}
func at(_ t: Double) -> Date { Date(timeIntervalSinceReferenceDate: t) }

func makeEngine(_ mode: [String: Any]) -> WODTimerEngine {
    switch mode["type"] as! String {
    case "emom":
        let r = mode["rounds"] as? Int, s = mode["secondsPerRound"] as? Int
        if r == nil && s == nil { return WODTimerEngine() }
        return WODTimerEngine(emomRounds: r ?? 1, secondsPerRound: s ?? 60)
    case "intervals":
        return WODTimerEngine(workSeconds: mode["workSeconds"] as! Int, restSeconds: mode["restSeconds"] as! Int, rounds: mode["rounds"] as! Int)
    default:
        return WODTimerEngine(forTimeCapSeconds: mode["capSeconds"] as? Int)
    }
}

var cases = doc["cases"] as! [[String: Any]]
for i in cases.indices {
    var engine = makeEngine(cases[i]["mode"] as! [String: Any])
    cases[i]["engine"] = [
        "rounds": engine.rounds,
        "workSeconds": engine.workSeconds,
        "restSeconds": engine.restSeconds,
        "capSeconds": engine.forTimeCapSeconds.map { $0 as Any } ?? NSNull(),
        "totalDurationSeconds": r6(engine.totalDurationSeconds),
        "totalDurationMinutes": engine.totalDurationMinutes,
    ] as [String: Any]
    var events = cases[i]["events"] as! [[String: Any]]
    for j in events.indices {
        let t = (events[j]["t"] as! NSNumber).doubleValue
        if let action = events[j]["do"] as? String {
            switch action {
            case "start": engine.start(now: at(t))
            case "pause": engine.pause(now: at(t))
            case "resume": engine.resume(now: at(t))
            case "finish": engine.finish(now: at(t))
            case "tick": engine.tick(now: at(t))
            case "reset": engine.reset()
            default: fatalError("Unknown action \(action)")
            }
            continue
        }
        let s = engine.snapshot(now: at(t))
        let end = engine.effectiveWorkoutEndDate(now: at(t))
        events[j].removeValue(forKey: "check")
        events[j]["expect"] = [
            "engineState": name(engine.state),
            "state": name(s.state),
            "remainingTime": r6(s.remainingTime),
            "elapsedTime": r6(s.elapsedTime),
            "currentRound": s.currentRound,
            "secondsIntoCurrentMinute": s.secondsIntoCurrentMinute,
            "currentPhase": s.currentPhase == .work ? "work" : "rest",
            "remainingTimeInPhase": r6(s.remainingTimeInPhase),
            "effectiveEnd": end.map { r6($0.timeIntervalSinceReferenceDate) as Any } ?? NSNull(),
        ] as [String: Any]
    }
    cases[i]["events"] = events
}
doc["cases"] = cases
let out = try JSONSerialization.data(withJSONObject: doc, options: [.prettyPrinted, .sortedKeys])
try (String(decoding: out, as: UTF8.self) + "\n").write(toFile: path, atomically: true, encoding: .utf8)
print("Wrote \(cases.count) cases to \(path)")
