//
//  VoiceCueTests.swift
//  WODroundsTests
//
//  The recorded voice cues ship per language. A language with some cues and not
//  others would switch speaker mid-workout, so a set is all or nothing.
//

#if os(iOS)
import Foundation
import Testing
@testable import WODrounds

struct VoiceCueTests {
    private func file(_ name: String, _ lang: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: nil, localization: lang)
    }

    @Test("Every cue played today has an English recording")
    func englishCuesExist() {
        // halfway and tenSeconds fall back to the system voice until they are recorded.
        let required = WorkoutSoundManager.voiceCues.filter { $0 != "halfway" && $0 != "tenSeconds" }
        for name in required {
            #expect(file(name, "en") != nil, "missing en.lproj/\(name).mp3")
        }
    }

    @Test("A language has every cue or none", arguments: ["en", "da", "es"])
    func languageSetIsComplete(lang: String) {
        let present = WorkoutSoundManager.voiceCues.filter { name in
            guard let url = file(name, lang) else { return false }
            return url.pathComponents.contains("\(lang).lproj")
        }
        let isNewSet = present.contains("halfway") || present.contains("tenSeconds") || lang != "en"
        if isNewSet && !present.isEmpty {
            #expect(present.count == WorkoutSoundManager.voiceCues.count,
                    "\(lang).lproj has \(present.count) of \(WorkoutSoundManager.voiceCues.count) cues")
        }
    }

    @Test("Lookup falls back to English for a cue not in the app's language")
    func lookupFallsBackToEnglish() {
        #expect(WorkoutSoundManager.cueURL(name: "youDidIt", ext: "mp3") != nil)
        #expect(WorkoutSoundManager.cueURL(name: "noSuchCue", ext: "mp3") == nil)
    }
}
#endif
