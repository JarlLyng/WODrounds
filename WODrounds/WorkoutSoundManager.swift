//
//  WorkoutSoundManager.swift
//  WODrounds
//
//  Plays countdown and workout sounds. iOS and tvOS only. Uses .playback so sounds are audible even in silent mode.
//

#if os(iOS) || os(tvOS)
import AVFoundation
import AudioToolbox
import Foundation

enum WorkoutSoundManager {
    /// Every recorded voice cue, by file name (`.mp3`, in `en.lproj`, `da.lproj`,
    /// `es.lproj`). The lines and how they are made are in docs/VOICE_CUES.md.
    static let voiceCues = [
        "getReadyStart", "halfway", "tenSeconds",
        "tenRoundsLeft", "fiveRoundsLeft", "twoRoundsLeft",
        "youDidIt", "youDidIt2", "youDidIt3",
    ]

    private static var currentPlayer: AVAudioPlayer?
    private static let synthesizer = AVSpeechSynthesizer()

    /// User-controlled sound on/off. Defaults to `true` (sounds enabled). Read directly from
    /// UserDefaults so non-View contexts can check it. Mirrors `@AppStorage("soundEnabled")`
    /// in the SwiftUI views.
    static var isSoundEnabled: Bool {
        // Treat missing key as "enabled" (sound on by default).
        guard UserDefaults.standard.object(forKey: "soundEnabled") != nil else { return true }
        return UserDefaults.standard.bool(forKey: "soundEnabled")
    }

    // MARK: - Voice cues (TTS)

    /// "Halfway" voice cue — fires when half of the current round/phase is left.
    static func speakHalfway() {
        if !play(name: "halfway", ext: "mp3") { speak("halfway") }
    }

    /// "Ten seconds" voice cue — fires at 10 seconds left in the round/phase.
    static func speakTenSecondsLeft() {
        if !play(name: "tenSeconds", ext: "mp3") { speak("ten seconds") }
    }

    /// The system voice, only for a cue whose recorded file is missing. It is a
    /// different speaker from the recordings, so every cue should have a file.
    private static func speak(_ text: String) {
        guard isSoundEnabled else { return }
        configureAudioSession()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    // MARK: - 3-2-1 countdown beep

    /// Short beep used for the 3-2-1 ramp at the end of each round/phase.
    static func playCountdownBeep() {
        guard isSoundEnabled else { return }
        configureAudioSession()
        // System sound 1057 is a short "tink" — quick enough to fire 3 times in 3 seconds.
        AudioServicesPlaySystemSound(1057)
    }

    private static func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[Sound] Audio session setup failed: \(error.localizedDescription)")
        }
    }

    /// Plays the "get ready / start" sound when the 10-second countdown reaches zero (before workout).
    static func playGetReadyStart() {
        play(name: "getReadyStart", ext: "mp3")
    }

    /// Plays a random "you did it" sound when the workout is complete.
    static func playYouDidIt() {
        let variants = ["youDidIt", "youDidIt2", "youDidIt3"]
        let name = variants.randomElement()!
        play(name: name, ext: "mp3")
    }

    /// Plays "10 rounds left" announcement.
    static func playTenRoundsLeft() {
        play(name: "tenRoundsLeft", ext: "mp3")
    }

    /// Plays "5 rounds left" announcement.
    static func playFiveRoundsLeft() {
        play(name: "fiveRoundsLeft", ext: "mp3")
    }

    /// Plays "2 rounds left" announcement.
    static func playTwoRoundsLeft() {
        play(name: "twoRoundsLeft", ext: "mp3")
    }

    /// Checks if a rounds-remaining sound should play and plays it.
    /// Call this when `currentRound` changes. `totalRounds` is the total number of rounds in the workout.
    static func checkRoundsRemaining(currentRound: Int, totalRounds: Int) {
        let roundsLeft = totalRounds - currentRound
        switch roundsLeft {
        case 10 where totalRounds > 10:
            playTenRoundsLeft()
        case 5 where totalRounds > 5:
            playFiveRoundsLeft()
        case 2:
            playTwoRoundsLeft()
        default:
            break
        }
    }

    /// The recorded cue in the app's language: `da.lproj/halfway.mp3` for an app
    /// running in Danish, and so on. A cue not recorded in that language falls back
    /// to English, so a missing translation is heard in English rather than not at all.
    static func cueURL(name: String, ext: String, bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: name, withExtension: ext)
            ?? bundle.url(forResource: name, withExtension: ext, subdirectory: nil, localization: "en")
    }

    /// Plays a recorded cue. Returns false when there is no file for it, so a caller
    /// can fall back; true when it played or sound is off (nothing else should play).
    @discardableResult
    private static func play(name: String, ext: String) -> Bool {
        // Respect the user's sound on/off preference (toggle in the main UI).
        guard isSoundEnabled else { return true }
        guard let url = cueURL(name: name, ext: ext) else {
            print("[Sound] File not found: \(name).\(ext)")
            return false
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[Sound] Audio session setup failed: \(error.localizedDescription)")
            return true
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            currentPlayer = player
            player.play()
        } catch {
            print("[Sound] Failed to play \(name).\(ext): \(error.localizedDescription)")
        }
        return true
    }
}
#endif
